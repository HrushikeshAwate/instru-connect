// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instru_connect/core/providers/app_providers.dart';
import 'package:instru_connect/core/widgets/destructive_confirmation_dialog.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../config/theme/ui_colors.dart';
import '../models/event_model.dart';
import '../services/events_service.dart';

class EventCalendarScreen extends ConsumerStatefulWidget {
  const EventCalendarScreen({super.key});

  @override
  ConsumerState<EventCalendarScreen> createState() =>
      _EventCalendarScreenState();
}

class _EventCalendarScreenState extends ConsumerState<EventCalendarScreen> {
  late final EventService _eventService;
  final Set<String> _selectedEventIds = <String>{};

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<EventModel>> _events = {};

  bool _canEditEvents = false;
  bool _loadingRole = true;
  bool _selectionMode = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _eventService = ref.read(eventServiceProvider);
    _loadRolePermission();
  }

  Future<void> _loadRolePermission() async {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        setState(() => _loadingRole = false);
      }
      return;
    }

    try {
      final userDoc = await ref
          .read(firebaseFirestoreProvider)
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

  void _toggleSelection(EventModel event) {
    if (!_canEditEvents) return;
    setState(() {
      _selectionMode = true;
      if (_selectedEventIds.contains(event.id)) {
        _selectedEventIds.remove(event.id);
      } else {
        _selectedEventIds.add(event.id);
      }
      if (_selectedEventIds.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selectedEventIds.clear();
    });
  }

  void _startSelectionMode() {
    if (!_canEditEvents) return;
    setState(() {
      _selectionMode = true;
      _selectedEventIds.clear();
    });
  }

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
    final confirmed = await showDestructiveConfirmationDialog(
      context: context,
      title: 'Delete Event?',
      message:
          'The event "${event.title}" will be permanently deleted and cannot be recovered.',
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

  Future<void> _deleteSelectedEvents(List<EventModel> events) async {
    final selected = events
        .where((event) => _selectedEventIds.contains(event.id))
        .toList();
    if (selected.isEmpty) return;

    final confirmed = await showDestructiveConfirmationDialog(
      context: context,
      title: 'Delete Events?',
      message:
          'You are about to permanently delete ${selected.length} selected event(s). They will not be recoverable after deletion.',
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      for (final event in selected) {
        await _eventService.deleteEvent(event.id);
      }
      if (!mounted) return;
      _clearSelection();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selected.length} event(s) deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete events: $e')));
    } finally {
      if (mounted) setState(() => _deleting = false);
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

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final surfaceColor = Theme.of(context).colorScheme.surface;
        final borderColor = isDark
            ? const Color(0xFF243244)
            : const Color(0xFFE2E8F0);
        final mutedTextColor =
            Theme.of(context).textTheme.bodyMedium?.color ?? UIColors.textMuted;
        final shadowColor = isDark
            ? Colors.black.withValues(alpha: 0.24)
            : Colors.black.withValues(alpha: 0.08);

        final selectedDayEvents = _getEvents(_selectedDay);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              _selectionMode
                  ? '${_selectedEventIds.length} selected'
                  : 'Academic Calendar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            leading: _selectionMode
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: _clearSelection,
                  )
                : null,
            actions: _selectionMode
                ? [
                    IconButton(
                      onPressed: _deleting
                          ? null
                          : () => _deleteSelectedEvents(selectedDayEvents),
                      icon: _deleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.delete_outline_rounded),
                    ),
                  ]
                : _canEditEvents
                ? [
                    IconButton(
                      onPressed: _startSelectionMode,
                      icon: const Icon(Icons.delete_outline_rounded),
                      tooltip: 'Select events to delete',
                    ),
                  ]
                : null,
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
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
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
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    titleTextStyle:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ) ??
                        const TextStyle(fontWeight: FontWeight.w700),
                    leftChevronIcon: Icon(
                      Icons.chevron_left_rounded,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color: mutedTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                    weekendStyle: TextStyle(
                      color: mutedTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    defaultTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    weekendTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    outsideTextStyle: TextStyle(
                      color: mutedTextColor.withValues(alpha: 0.55),
                    ),
                    todayDecoration: BoxDecoration(
                      color: UIColors.primary.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: UIColors.primary,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: UIColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: selectedDayEvents.isEmpty
                    ? Center(
                        child: Text(
                          'No events for this date',
                          style: TextStyle(color: mutedTextColor),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: selectedDayEvents.length,
                        itemBuilder: (_, index) {
                          final event = selectedDayEvents[index];
                          final selected = _selectedEventIds.contains(event.id);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            color: surfaceColor,
                            shape: selected
                                ? RoundedRectangleBorder(
                                    side: const BorderSide(
                                      color: UIColors.primary,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  )
                                : null,
                            child: InkWell(
                              onTap: () {
                                if (_selectionMode && _canEditEvents) {
                                  _toggleSelection(event);
                                }
                              },
                              onLongPress: _canEditEvents
                                  ? () => _toggleSelection(event)
                                  : null,
                              child: ListTile(
                                leading: _selectionMode
                                    ? Checkbox(
                                        value: selected,
                                        onChanged: (_) =>
                                            _toggleSelection(event),
                                      )
                                    : null,
                                title: Text(event.title),
                                subtitle: event.details.trim().isEmpty
                                    ? null
                                    : Text(
                                        event.details.trim(),
                                        style: TextStyle(color: mutedTextColor),
                                      ),
                                trailing: _selectionMode || !_canEditEvents
                                    ? null
                                    : PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _showEventEditor(event: event);
                                            return;
                                          }
                                          if (value == 'postpone') {
                                            _askShiftDays(
                                              isPostpone: true,
                                            ).then((days) {
                                              if (days != null) {
                                                _shiftEvent(event, days);
                                              }
                                            });
                                            return;
                                          }
                                          if (value == 'prepone') {
                                            _askShiftDays(
                                              isPostpone: false,
                                            ).then((days) {
                                              if (days != null) {
                                                _shiftEvent(event, -days);
                                              }
                                            });
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
