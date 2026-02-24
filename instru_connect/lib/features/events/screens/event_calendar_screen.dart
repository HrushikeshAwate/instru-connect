// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  bool _canEditEvents = false;
  bool _loadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadRolePermission();
  }

  Future<void> _loadRolePermission() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        setState(() => _loadingRole = false);
      }
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final role = (userDoc.data()?['role'] ?? '').toString().toLowerCase();
      if (!mounted) return;
      setState(() {
        _canEditEvents = role == 'faculty' || role == 'admin';
        _loadingRole = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingRole = false);
    }
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  List<EventModel> _getEvents(DateTime day) => _events[_normalize(day)] ?? [];

  Future<void> _showEventEditor({EventModel? event}) async {
    if (!_canEditEvents) return;

    final titleCtrl = TextEditingController(text: event?.title ?? '');
    final detailsCtrl = TextEditingController(text: event?.details ?? '');
    DateTime pickedDate = event?.date ?? _selectedDay;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event == null ? 'Add Event' : 'Edit Event',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Event title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: detailsCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Event details',
                      hintText: 'Agenda, venue, notes...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final selected = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        initialDate: pickedDate,
                      );
                      if (selected != null) {
                        setModalState(() => pickedDate = selected);
                      }
                    },
                    icon: const Icon(Icons.event),
                    label: Text(
                      'Date: ${pickedDate.day}-${pickedDate.month}-${pickedDate.year}',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final title = titleCtrl.text.trim();
                        if (title.isEmpty) return;

                        try {
                          if (event == null) {
                            await _eventService.addEvent(
                              title: title,
                              details: detailsCtrl.text.trim(),
                              date: pickedDate,
                            );
                          } else {
                            await _eventService.updateEvent(
                              eventId: event.id,
                              title: title,
                              details: detailsCtrl.text.trim(),
                              date: pickedDate,
                            );
                          }
                          if (mounted) Navigator.pop(context);
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to save event: $e')),
                          );
                        }
                      },
                      child: Text(event == null ? 'Add Event' : 'Save Changes'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _shiftEvent(EventModel event, int days) async {
    if (!_canEditEvents) return;
    try {
      await _eventService.shiftEventDate(event: event, days: days);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update date: $e')));
    }
  }

  Future<int?> _askShiftDays({required bool isPostpone}) async {
    final ctrl = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isPostpone ? 'Postpone Event' : 'Prepone Event'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Number of days',
            hintText: 'Enter days (e.g. 3)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(ctrl.text.trim());
              if (value == null || value <= 0) return;
              Navigator.pop(context, value);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent(EventModel event) async {
    if (!_canEditEvents) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _eventService.deleteEvent(event.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete event: $e')));
    }
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text(
              'Academic Calendar',
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
          floatingActionButton: _loadingRole || !_canEditEvents
              ? null
              : FloatingActionButton(
                  backgroundColor: UIColors.primary,
                  onPressed: _showEventEditor,
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
                          'No events for this date',
                          style: TextStyle(color: UIColors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _getEvents(_selectedDay).length,
                        itemBuilder: (_, index) {
                          final event = _getEvents(_selectedDay)[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(event.title),
                              subtitle: event.details.trim().isEmpty
                                  ? null
                                  : Text(event.details.trim()),
                              trailing: !_canEditEvents
                                  ? null
                                  : PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _showEventEditor(event: event);
                                          return;
                                        }
                                        if (value == 'postpone') {
                                          _askShiftDays(isPostpone: true).then((
                                            days,
                                          ) {
                                            if (days != null) {
                                              _shiftEvent(event, days);
                                            }
                                          });
                                          return;
                                        }
                                        if (value == 'prepone') {
                                          _askShiftDays(isPostpone: false).then(
                                            (days) {
                                              if (days != null) {
                                                _shiftEvent(event, -days);
                                              }
                                            },
                                          );
                                          return;
                                        }
                                        if (value == 'delete') {
                                          _deleteEvent(event);
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit details/date'),
                                        ),
                                        PopupMenuItem(
                                          value: 'postpone',
                                          child: Text('Postpone by N days'),
                                        ),
                                        PopupMenuItem(
                                          value: 'prepone',
                                          child: Text('Prepone by N days'),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    ),
                            ),
                          );
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
