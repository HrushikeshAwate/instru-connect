import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../config/theme/ui_colors.dart';
import '../models/event_model.dart';
import '../services/events_service.dart';

class EventCalendarScreen extends StatefulWidget {
  const EventCalendarScreen({super.key});

  @override
  State<EventCalendarScreen> createState() => _EventCalendarScreenState();
}

class _EventCalendarScreenState extends State<EventCalendarScreen> {
  final EventService _eventService = EventService();

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  Map<DateTime, List<EventModel>> _events = {};

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  List<EventModel> _getEvents(DateTime day) {
    return _events[_normalize(day)] ?? [];
  }

  void _showAddEventDialog() {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Add Event", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Text(
                "Date: ${_selectedDay.day}-${_selectedDay.month}-${_selectedDay.year}",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: UIColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: "Event title"),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (controller.text.trim().isNotEmpty) {
                      await _eventService.addEvent(
                        title: controller.text.trim(),
                        date: _selectedDay,
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: const Text("Add Event"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<DateTime, List<EventModel>>>(
      stream: _eventService.streamEvents(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _events = snapshot.data!;
        }

        return Scaffold(
          backgroundColor: UIColors.background,
          appBar: AppBar(
            title: const Text(
              "Academic Calendar",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            flexibleSpace: Container(
              decoration: const BoxDecoration(gradient: UIColors.heroGradient),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: UIColors.primary,
            onPressed: _showAddEventDialog,
            child: const Icon(Icons.add),
          ),
          body: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2035, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: _getEvents,
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                ),
              ),
              Expanded(
                child: _getEvents(_selectedDay).isEmpty
                    ? const Center(
                        child: Text(
                          "No events for this date",
                          style: TextStyle(color: UIColors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _getEvents(_selectedDay).length,
                        itemBuilder: (_, index) {
                          final event = _getEvents(_selectedDay)[index];
                          return ListTile(title: Text(event.title));
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
