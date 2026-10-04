import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instru_connect/core/constants/app_roles.dart';
import 'package:instru_connect/core/providers/app_providers.dart';
import 'package:instru_connect/core/session/current_user.dart';
import 'package:instru_connect/core/widgets/app_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _selectedTimetableYearKey = 'selected_timetable_year';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key, this.showUploadAction = false});

  final bool showUploadAction;

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  String _selectedYear = 'SY';
  final List<String> _years = ['SY', 'TY', 'BTech'];
  bool _loadingSource = true;
  StreamSubscription<Map<String, Map<String, dynamic>>>? _cellsSubscription;
  late Map<String, List<_ClassEntry?>> _schedule;

  bool get _canEditTimetable {
    final role = (CurrentUser.role ?? '').trim().toLowerCase();
    return role == AppRoles.faculty || role == AppRoles.admin;
  }

  _TimetableData get _data => _timetableData[_selectedYear]!;

  @override
  void initState() {
    super.initState();
    _schedule = _copySchedule(_data.schedule);
    _loadSavedYear();
  }

  Future<void> _loadSavedYear() async {
    final prefs = await SharedPreferences.getInstance();
    final savedYear = prefs.getString(_selectedTimetableYearKey);
    if (!mounted) return;

    if (savedYear != null && _years.contains(savedYear)) {
      setState(() {
        _selectedYear = savedYear;
        _schedule = _copySchedule(_timetableData[savedYear]!.schedule);
      });
    }

    await _loadSourceInfo();
  }

  Future<void> _saveSelectedYear(String year) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedTimetableYearKey, year);
  }

  Future<void> _loadSourceInfo() async {
    await _cellsSubscription?.cancel();
    setState(() => _loadingSource = true);
    final year = _selectedYear;
    _cellsSubscription = ref
        .read(timetableServiceProvider)
        .streamTimetableCells(year)
        .listen(
          (cells) {
            if (!mounted || year != _selectedYear) return;
            setState(() {
              _schedule = _scheduleWithFirebaseCells(year, cells);
              _loadingSource = false;
            });
          },
          onError: (_) {
            if (!mounted || year != _selectedYear) return;
            setState(() {
              _schedule = _copySchedule(_timetableData[year]!.schedule);
              _loadingSource = false;
            });
          },
        );
  }

  Map<String, List<_ClassEntry?>> _scheduleWithFirebaseCells(
    String year,
    Map<String, Map<String, dynamic>> cells,
  ) {
    final schedule = _copySchedule(_timetableData[year]!.schedule);
    for (final cell in cells.values) {
      final day = (cell['day'] ?? '').toString().trim().toUpperCase();
      final slotIndex = cell['slotIndex'];
      if (!_days.contains(day) || slotIndex is! int) continue;
      if (slotIndex < 0 || slotIndex >= _timeSlots.length) continue;
      final title = (cell['title'] ?? '').toString();
      final type = (cell['type'] ?? _EntryType.lecture.key).toString();
      schedule[day]![slotIndex] = _ClassEntry.fromType(title, type);
    }
    return schedule;
  }

  Future<void> _editCell(String day, int slotIndex, _ClassEntry? entry) async {
    if (!_canEditTimetable) return;

    final result = await showDialog<_CellEditResult>(
      context: context,
      builder: (_) => _TimetableCellDialog(
        day: day,
        timeSlot: _timeSlots[slotIndex].replaceAll('\n', ' '),
        entry: entry,
      ),
    );
    if (result == null) return;

    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    final role = (CurrentUser.role ?? '').trim().toLowerCase();
    final previous = _schedule[day]![slotIndex];
    setState(() {
      _schedule[day]![slotIndex] = result.title.trim().isEmpty
          ? null
          : _ClassEntry.fromType(result.title, result.type.key);
    });

    try {
      await ref
          .read(timetableServiceProvider)
          .updateTimetableCell(
            year: _selectedYear,
            day: day,
            slotIndex: slotIndex,
            title: result.title,
            type: result.type.key,
            uid: user.uid,
            role: role,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Timetable updated')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _schedule[day]![slotIndex] = previous);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = _data;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          const AppHeroBackground(height: 174),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Official Timetable',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _YearMenu(
                        selectedYear: _selectedYear,
                        years: _years,
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() {
                            _selectedYear = val;
                            _schedule = _copySchedule(
                              _timetableData[val]!.schedule,
                            );
                          });
                          _saveSelectedYear(val);
                          _loadSourceInfo();
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    children: [
                      _HeaderCard(data: data),
                      const SizedBox(height: 12),
                      if (_loadingSource)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: const LinearProgressIndicator(minHeight: 3),
                        )
                      else
                        _EditHintBanner(canEdit: _canEditTimetable),
                      const SizedBox(height: 12),
                      const _LegendBar(),
                      const SizedBox(height: 18),
                      AppSectionHeader(
                        title: 'Weekly Schedule',
                        subtitle: _canEditTimetable
                            ? 'Tap any tile to edit. Swipe sideways to see the full day.'
                            : 'Swipe sideways to see the full day.',
                        trailing: Icon(
                          Icons.swipe_left_alt_outlined,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _TimetableGrid(
                        schedule: _schedule,
                        canEdit: _canEditTimetable,
                        onEditCell: _editCell,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cellsSubscription?.cancel();
    super.dispose();
  }
}

class _YearMenu extends StatelessWidget {
  const _YearMenu({
    required this.selectedYear,
    required this.years,
    required this.onChanged,
  });

  final String selectedYear;
  final List<String> years;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: 12, right: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedYear,
          dropdownColor: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
          selectedItemBuilder: (context) => years
              .map(
                (year) => Center(
                  child: Text(
                    year,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
              .toList(),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white,
          ),
          items: years
              .map(
                (year) => DropdownMenuItem(
                  value: year,
                  child: Text(
                    year,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.data});

  final _TimetableData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.calendar_month_outlined,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Department of Instrumentation and Control Engineering',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(icon: Icons.school_outlined, text: data.className),
              _InfoChip(icon: Icons.meeting_room_outlined, text: data.room),
              _InfoChip(icon: Icons.event_outlined, text: data.effectiveFrom),
              _InfoChip(icon: Icons.auto_stories_outlined, text: data.term),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditHintBanner extends StatelessWidget {
  const _EditHintBanner({required this.canEdit});

  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: canEdit
            ? colorScheme.primary.withValues(alpha: 0.1)
            : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: canEdit
              ? colorScheme.primary.withValues(alpha: 0.22)
              : const Color(0xFFA7F3D0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            canEdit ? Icons.edit_calendar_outlined : Icons.verified,
            color: canEdit ? colorScheme.primary : const Color(0xFF047857),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              canEdit
                  ? 'Faculty and admins can tap any timetable tile to edit it.'
                  : 'Showing the official department timetable.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: canEdit ? colorScheme.primary : const Color(0xFF065F46),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendBar extends StatelessWidget {
  const _LegendBar();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _legendItems
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _LegendChip(item: item),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.item});

  final _LegendItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: item.color.withValues(alpha: 0.36)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 15, color: item.color),
          const SizedBox(width: 6),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: item.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimetableGrid extends StatelessWidget {
  const _TimetableGrid({
    required this.schedule,
    required this.canEdit,
    required this.onEditCell,
  });

  static const double _dayWidth = 74;
  static const double _slotWidth = 126;
  static const double _rowHeight = 106;

  final Map<String, List<_ClassEntry?>> schedule;
  final bool canEdit;
  final void Function(String day, int slotIndex, _ClassEntry? entry) onEditCell;

  @override
  Widget build(BuildContext context) {
    final totalWidth = _dayWidth + (_slotWidth * _timeSlots.length);
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.12),
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth,
            child: Column(
              children: [
                Row(
                  children: [
                    const _HeaderCell(label: 'Day', width: _dayWidth),
                    ..._timeSlots.map(
                      (slot) => _HeaderCell(label: slot, width: _slotWidth),
                    ),
                  ],
                ),
                ..._days.map(
                  (day) => Row(
                    children: [
                      _DayCell(
                        label: day,
                        width: _dayWidth,
                        height: _rowHeight,
                      ),
                      ...List.generate(_timeSlots.length, (index) {
                        final entry = schedule[day]?[index];
                        return _ScheduleCell(
                          entry: entry,
                          width: _slotWidth,
                          height: _rowHeight,
                          canEdit: canEdit,
                          onTap: () => onEditCell(day, index, entry),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.label, required this.width});

  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: 66,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          height: 1.25,
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.label,
    required this.width,
    required this.height,
  });

  final String label;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isToday = _weekdayLabel(DateTime.now()) == label;
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = colorScheme.outline.withValues(alpha: 0.12);
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isToday
            ? colorScheme.primary.withValues(alpha: 0.14)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
        border: Border(
          right: BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isToday ? colorScheme.primary : colorScheme.onSurface,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ScheduleCell extends StatelessWidget {
  const _ScheduleCell({
    required this.entry,
    required this.width,
    required this.height,
    required this.canEdit,
    required this.onTap,
  });

  final _ClassEntry? entry;
  final double width;
  final double height;
  final bool canEdit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final item = entry;
    final colorScheme = Theme.of(context).colorScheme;
    final cellBorder = BoxDecoration(
      color: colorScheme.surface,
      border: Border(
        right: BorderSide(color: colorScheme.outline.withValues(alpha: 0.12)),
        bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
    );
    if (item == null) {
      return _EditableCellShell(
        width: width,
        height: height,
        decoration: cellBorder,
        canEdit: canEdit,
        onTap: onTap,
        child: canEdit
            ? Icon(
                Icons.add_rounded,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
              )
            : const SizedBox.shrink(),
      );
    }

    // For filled entries (like break), use the entry's text color (white).
    // For non-filled entries, use theme-aware color for dark mode visibility.
    final textColor = item.filled
        ? item.textColor
        : colorScheme.onSurface;

    return _EditableCellShell(
      width: width,
      height: height,
      decoration: cellBorder,
      canEdit: canEdit,
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: item.filled ? 1 : 0.16),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: item.color.withValues(alpha: 0.42)),
        ),
        child: Text(
          item.title,
          textAlign: TextAlign.center,
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _EditableCellShell extends StatelessWidget {
  const _EditableCellShell({
    required this.width,
    required this.height,
    required this.decoration,
    required this.canEdit,
    required this.onTap,
    required this.child,
  });

  final double width;
  final double height;
  final Decoration decoration;
  final bool canEdit;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: canEdit ? onTap : null, child: child),
      ),
    );
  }
}

class _TimetableCellDialog extends StatefulWidget {
  const _TimetableCellDialog({
    required this.day,
    required this.timeSlot,
    required this.entry,
  });

  final String day;
  final String timeSlot;
  final _ClassEntry? entry;

  @override
  State<_TimetableCellDialog> createState() => _TimetableCellDialogState();
}

class _TimetableCellDialogState extends State<_TimetableCellDialog> {
  late final TextEditingController _titleController;
  late _EntryType _type;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _type = widget.entry?.type ?? _EntryType.lecture;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(
      context,
    ).pop(_CellEditResult(title: _titleController.text, type: _type));
  }

  void _clear() {
    Navigator.of(
      context,
    ).pop(_CellEditResult(title: '', type: _EntryType.lecture));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Edit Timetable Tile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.day} • ${widget.timeSlot}',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _titleController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Tile text',
              prefixIcon: Icon(Icons.notes_outlined),
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<_EntryType>(
            initialValue: _type,
            decoration: const InputDecoration(
              labelText: 'Tile type',
              prefixIcon: Icon(Icons.category_outlined),
              border: OutlineInputBorder(),
            ),
            items: _EntryType.values
                .map(
                  (type) =>
                      DropdownMenuItem(value: type, child: Text(type.label)),
                )
                .toList(),
            onChanged: (type) {
              if (type != null) setState(() => _type = type);
            },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _clear, child: const Text('Clear')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _CellEditResult {
  const _CellEditResult({required this.title, required this.type});

  final String title;
  final _EntryType type;
}

class _TimetableData {
  const _TimetableData({
    required this.title,
    required this.className,
    required this.room,
    required this.effectiveFrom,
    required this.term,
    required this.schedule,
  });

  final String title;
  final String className;
  final String room;
  final String effectiveFrom;
  final String term;
  final Map<String, List<_ClassEntry?>> schedule;
}

enum _EntryType {
  lecture('lecture', 'Lecture', _lecture, Icons.menu_book_outlined),
  lab('lab', 'Lab', _lab, Icons.science_outlined),
  elective('elective', 'Elective', _elective, Icons.star_outline),
  mdm('mdm', 'MDM', _mdm, Icons.eco_outlined),
  honour('honour', 'Honour/Minor', _honour, Icons.workspace_premium_outlined),
  event('event', 'Event', _event, Icons.campaign_outlined),
  breakTime('break', 'Break', _breakColor, Icons.free_breakfast_outlined);

  const _EntryType(this.key, this.label, this.color, this.icon);

  final String key;
  final String label;
  final Color color;
  final IconData icon;

  static _EntryType fromKey(String value) {
    final normalized = value.trim().toLowerCase();
    return _EntryType.values.firstWhere(
      (type) => type.key == normalized,
      orElse: () => _EntryType.lecture,
    );
  }
}

class _ClassEntry {
  const _ClassEntry(
    this.title,
    this.color, [
    this.textColor = const Color(0xFF111827),
    this.filled = false,
  ]);

  factory _ClassEntry.fromType(String title, String typeKey) {
    final type = _EntryType.fromKey(typeKey);
    final isBreak = type == _EntryType.breakTime;
    return _ClassEntry(
      title,
      type.color,
      isBreak ? Colors.white : const Color(0xFF111827),
      isBreak,
    );
  }

  final String title;
  final Color color;
  final Color textColor;
  final bool filled;

  _EntryType get type => _entryTypeForColor(color);
}

class _LegendItem {
  const _LegendItem({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

const _lecture = Color(0xFF2563EB);
const _lab = Color(0xFF7C3AED);
const _elective = Color(0xFFEAB308);
const _mdm = Color(0xFF65A30D);
const _honour = Color(0xFFF97316);
const _event = Color(0xFF0284C7);
const _breakColor = Color(0xFFEF4444);

const _legendItems = [
  _LegendItem(
    label: 'Lecture',
    color: _lecture,
    icon: Icons.menu_book_outlined,
  ),
  _LegendItem(label: 'Lab', color: _lab, icon: Icons.science_outlined),
  _LegendItem(label: 'Elective', color: _elective, icon: Icons.star_outline),
  _LegendItem(label: 'MDM', color: _mdm, icon: Icons.eco_outlined),
  _LegendItem(
    label: 'Honour/Minor',
    color: _honour,
    icon: Icons.workspace_premium_outlined,
  ),
  _LegendItem(label: 'Event', color: _event, icon: Icons.campaign_outlined),
];

const _timeSlots = [
  '8.30 am\nTo\n9.30 am',
  '9.30 am\nTo\n10.30 am',
  '10.30 am\nTo\n11.30 am',
  '11.30 am\nTo\n12.30 pm',
  '12.30 pm\nTo\n1.30 pm',
  '1.30 pm\nTo\n2.30 pm',
  '2.30 pm\nTo\n3.30 pm',
  '3.30 pm\nTo\n4.30 pm',
  '4.30 pm\nTo\n5.30 pm',
  '5.30 pm\nTo\n6.30 pm',
];

const _days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
const _brk = _ClassEntry('LUNCH\nBRK', _breakColor, Colors.white, true);
const _honourMinor = _ClassEntry('Honour/\nMinor', _honour);
final _emptyDay = List<_ClassEntry?>.filled(10, null);

Map<String, List<_ClassEntry?>> _copySchedule(
  Map<String, List<_ClassEntry?>> schedule,
) {
  return {
    for (final entry in schedule.entries) entry.key: List.of(entry.value),
  };
}

_EntryType _entryTypeForColor(Color color) {
  if (color == _lab) return _EntryType.lab;
  if (color == _elective) return _EntryType.elective;
  if (color == _mdm) return _EntryType.mdm;
  if (color == _honour) return _EntryType.honour;
  if (color == _event) return _EntryType.event;
  if (color == _breakColor) return _EntryType.breakTime;
  return _EntryType.lecture;
}

final Map<String, _TimetableData> _timetableData = {
  'SY': _TimetableData(
    title: 'S. Y. B. Tech',
    className: 'Class: S. Y. B. Tech',
    room: 'PG Classroom (NT-15)',
    effectiveFrom: 'From: 06/07/2026',
    term: 'Academic Year: 2026-27, Term I',
    schedule: {
      'MON': [
        null,
        const _ClassEntry('MDCP', _lecture),
        const _ClassEntry('S&S\n(NT-15)\n(RAB)', _lecture),
        _brk,
        const _ClassEntry('AE\n(NT-15)\n(SS)', _lecture),
        const _ClassEntry('AE Lab-A;\nS & T Lab-B;\nNM Lab-C', _lab),
        const _ClassEntry('AE Lab-A;\nS & T Lab-B;\nNM Lab-C', _lab),
        const _ClassEntry('Language', _event),
        const _ClassEntry('Language', _event),
        null,
      ],
      'TUE': [
        null,
        const _ClassEntry('MDCP', _lecture),
        null,
        _brk,
        null,
        const _ClassEntry('S & T\n(NT-15)\n(RPM)', _lecture),
        const _ClassEntry('S & T\n(NT-15)\n(RPM)', _lecture),
        const _ClassEntry('AE Lab-B;\nS & T Lab-C;\nNM Lab-D', _lab),
        const _ClassEntry('AE Lab-B;\nS & T Lab-C;\nNM Lab-D', _lab),
        null,
      ],
      'WED': [
        null,
        const _ClassEntry('MDCP', _lecture),
        const _ClassEntry('AE\n(NT-15)\n(RAB)', _lecture),
        _brk,
        const _ClassEntry('S&S\n(NT-15)\n(RAB)', _lecture),
        const _ClassEntry('S & T\n(NT-15)\n(RPM)', _lecture),
        null,
        null,
        null,
        null,
      ],
      'THU': [
        const _ClassEntry('Entrepreneurship', _elective),
        const _ClassEntry('S&A-OEC-\n(NC-09)\n(PPM)', _elective),
        const _ClassEntry('NM Tut-\n(NT-15)\n(NLP)', _lecture),
        _brk,
        const _ClassEntry('AE\n(NT-15)\n(SS)', _lecture),
        const _ClassEntry('AE Lab-D;\nS & T Lab-A;\nNM Lab-B', _lab),
        const _ClassEntry('AE Lab-D;\nS & T Lab-A;\nNM Lab-B', _lab),
        null,
        null,
        _honourMinor,
      ],
      'FRI': [
        null,
        const _ClassEntry('S&A-OEC-\n(NC-09)\n(PPM)', _elective),
        null,
        _brk,
        const _ClassEntry('s', _lecture),
        null,
        const _ClassEntry('AE Lab-C;\nS & T Lab-D;\nNM Lab-A', _lab),
        const _ClassEntry('AE Lab-C;\nS & T Lab-D;\nNM Lab-A', _lab),
        _honourMinor,
        _honourMinor,
      ],
      'SAT': _emptyDay,
    },
  ),
  'TY': _TimetableData(
    title: 'T. Y. B. Tech',
    className: 'Class: T. Y. B. Tech',
    room: 'Seminar Hall-II (NS-02)',
    effectiveFrom: 'From: 06/07/2026',
    term: 'Academic Year: 2026-27, Term I',
    schedule: {
      'MON': [
        const _ClassEntry('MDM', _mdm),
        const _ClassEntry('MDM', _mdm),
        const _ClassEntry('PLC\n(NS-02)\n(MAK)', _lecture),
        _brk,
        const _ClassEntry('CSD\n(NS-02)\n(SPH)', _lecture),
        const _ClassEntry('DSP-A;\nCSD-B;\nPLC-C', _lab),
        const _ClassEntry('DSP-A;\nCSD-B;\nPLC-C', _lab),
        null,
        null,
        null,
      ],
      'TUE': [
        const _ClassEntry('MDM', _mdm),
        const _ClassEntry('MDM', _mdm),
        const _ClassEntry('PLC\n(NS-02)\n(MAK)', _lecture),
        _brk,
        const _ClassEntry('CSD\n(NS-02)\n(SPH)', _lecture),
        const _ClassEntry('DSP-B;\nCSD-C;\nPLC-A', _lab),
        const _ClassEntry('DSP-B;\nCSD-C;\nPLC-A', _lab),
        null,
        null,
        null,
      ],
      'WED': [
        null,
        const _ClassEntry('DSP\n(NS-02)\n(GVL)', _lecture),
        const _ClassEntry('PPO / S&DA\n(AE Lab)', _lab),
        _brk,
        const _ClassEntry('CSD\n(NS-02)\n(SPH)', _lecture),
        const _ClassEntry('DSP-C;\nCSD-A;\nPLC-B', _lab),
        const _ClassEntry('DSP-C;\nCSD-A;\nPLC-B', _lab),
        null,
        null,
        const _ClassEntry('Expert\nLecture', _event),
      ],
      'THU': [
        const _ClassEntry('DSP\n(NS-02)\n(GVL)', _lecture),
        const _ClassEntry('IA-OEC-\n(NC-09)\n(MAK)', _elective),
        const _ClassEntry('PPO / S&DA\n(AE Lab)', _lab),
        _brk,
        const _ClassEntry('Project\nStage I\n(NS-02)\n(SS)', _event),
        const _ClassEntry('Project\nStage I\n(NS-02)\n(SS)', _event),
        const _ClassEntry('DSP-Tut-\n(NS-02)\n(GVL)', _lecture),
        null,
        _honourMinor,
        _honourMinor,
      ],
      'FRI': _emptyDay,
      'SAT': _emptyDay,
    },
  ),
  'BTech': _TimetableData(
    title: 'B. Tech',
    className: 'Class: B. Tech',
    room: 'Seminar Hall-I (NS-01)',
    effectiveFrom: 'From: 06/07/2026',
    term: 'Academic Year: 2026-27, Term I',
    schedule: {
      'MON': [
        null,
        const _ClassEntry('BPC\n(NS-01)\n(Emerson)', _lecture),
        const _ClassEntry('BPC\n(NS-01)\nEmerson', _lecture),
        _brk,
        const _ClassEntry('RM\n(NS-01)\n(SLP)', _lecture),
        const _ClassEntry('PC\n(NS-01)-\n(ASD)', _lecture),
        const _ClassEntry('PC Lab-C\n(ASD)', _lab),
        const _ClassEntry('PC Lab-C\n(ASD)', _lab),
        const _ClassEntry('MDM', _mdm),
        const _ClassEntry('MDM', _mdm),
      ],
      'TUE': [
        null,
        const _ClassEntry('BPC\n(NS-01)\n(Emerson)', _lecture),
        const _ClassEntry('ICS\n(NS-01)\nEmerson', _lecture),
        _brk,
        const _ClassEntry('BA\n(NS-01)\n(KAG)', _lecture),
        const _ClassEntry('PEM Lab\n(MR)', _lab),
        const _ClassEntry('PEM Lab\n(MR)', _lab),
        const _ClassEntry('RM\n(NS-01)\n(SLP)', _lecture),
        const _ClassEntry('MDM', _mdm),
        null,
      ],
      'WED': [
        null,
        const _ClassEntry('ICS\n(NS-01)\n(Emerson)', _lecture),
        const _ClassEntry('ICS\n(NS-01)\nEmerson', _lecture),
        _brk,
        const _ClassEntry('PC Lab-A\n(ASD)', _lab),
        const _ClassEntry('PC Lab-A\n(ASD)', _lab),
        const _ClassEntry('BA\n(NS-01)\n(KAG)', _lecture),
        const _ClassEntry('PC\n(NS-01)-\nASD', _lecture),
        const _ClassEntry('Project\nStage 3\n(NS-01)', _event),
        const _ClassEntry('Expert\nLecture', _event),
      ],
      'THU': [
        null,
        const _ClassEntry('Project\nStage 3\n(NS-01)', _event),
        const _ClassEntry('Project\nStage 3\n(NS-01)', _event),
        _brk,
        const _ClassEntry('PC Lab-B\n(ASD)', _lab),
        const _ClassEntry('PC Lab-B\n(ASD)', _lab),
        const _ClassEntry('BA\n(NS-01)\n(KAG)', _lecture),
        const _ClassEntry('PC\n(NS-01)-\nASD', _lecture),
        _honourMinor,
        _honourMinor,
      ],
      'FRI': [
        null,
        const _ClassEntry('PEM\n(NS-01)\n(MR)', _lecture),
        const _ClassEntry('PEM\n(NS-01)\n(MR)', _lecture),
        const _ClassEntry('PEM-Tut\n(NS-01)\n(MR)', _lecture),
        _brk,
        const _ClassEntry('AOML\n(NS-01)\n(RK)', _lecture),
        const _ClassEntry('AOML\n(NS-01)\n(RK)', _lecture),
        const _ClassEntry('AOML\n(NS-01)\n(RK)', _lecture),
        _honourMinor,
        _honourMinor,
      ],
      'SAT': _emptyDay,
    },
  ),
};

String _weekdayLabel(DateTime value) {
  switch (value.weekday) {
    case DateTime.monday:
      return 'MON';
    case DateTime.tuesday:
      return 'TUE';
    case DateTime.wednesday:
      return 'WED';
    case DateTime.thursday:
      return 'THU';
    case DateTime.friday:
      return 'FRI';
    case DateTime.saturday:
      return 'SAT';
    default:
      return '';
  }
}
