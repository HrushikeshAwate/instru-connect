import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../config/theme/ui_colors.dart';
import '../../batches/services/batch_service.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final String batchId;
  final String subjectName;
  final bool isEditing;
  final String? docId;
  final List<String>? initialAbsentees;

  const MarkAttendanceScreen({
    super.key,
    required this.batchId,
    required this.subjectName,
    this.isEditing = false,
    this.docId,
    this.initialAbsentees,
  });

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final BatchService _batchService = BatchService();
  final TextEditingController _searchController = TextEditingController();

  final Map<String, bool> absentStatus = {};
  bool _isSaving = false;
  bool _hasInitialized = false;
  String _searchQuery = '';

  int _compareStudents(
    QueryDocumentSnapshot<Object?> a,
    QueryDocumentSnapshot<Object?> b,
  ) {
    final aData = a.data() as Map<String, dynamic>;
    final bData = b.data() as Map<String, dynamic>;

    final aMis = (aData['MIS No'] ?? aData['mis'] ?? '').toString().trim();
    final bMis = (bData['MIS No'] ?? bData['mis'] ?? '').toString().trim();
    final aName = (aData['Name'] ?? aData['name'] ?? '').toString().trim();
    final bName = (bData['Name'] ?? bData['name'] ?? '').toString().trim();

    final aHasMis = aMis.isNotEmpty;
    final bHasMis = bMis.isNotEmpty;

    if (aHasMis && bHasMis) {
      final misCompare = aMis.toLowerCase().compareTo(bMis.toLowerCase());
      if (misCompare != 0) return misCompare;
    } else if (aHasMis != bHasMis) {
      return aHasMis ? -1 : 1;
    }

    final nameCompare = aName.toLowerCase().compareTo(bName.toLowerCase());
    if (nameCompare != 0) return nameCompare;

    return a.id.compareTo(b.id);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final allUids = absentStatus.keys.toList();
    final absentUids = absentStatus.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (allUids.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No students are available to mark attendance.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.isEditing && widget.docId != null) {
        await _batchService.updateAttendance(
          batchId: widget.batchId,
          docId: widget.docId!,
          subjectName: widget.subjectName,
          newAbsentUids: absentUids,
          allStudentUids: allUids,
        );
      } else {
        await _batchService.submitAttendance(
          batchId: widget.batchId,
          subjectName: widget.subjectName,
          absentStudentUids: absentUids,
          allStudentUids: allUids,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Container(
            height: 240,
            decoration: BoxDecoration(
              gradient: widget.isEditing
                  ? UIColors.warningGradient
                  : UIColors.heroGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
          ),
          SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('batchId', isEqualTo: widget.batchId)
                  .where('role', whereIn: ['student', 'cr'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.toList()..sort(_compareStudents);

                if (!_hasInitialized) {
                  for (final doc in docs) {
                    absentStatus[doc.id] =
                        widget.isEditing &&
                        widget.initialAbsentees != null &&
                        widget.initialAbsentees!.contains(doc.id);
                  }
                  _hasInitialized = true;
                }

                final query = _searchQuery.toLowerCase();
                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['Name'] ?? data['name'] ?? '')
                      .toString()
                      .toLowerCase();
                  final mis = (data['MIS No'] ?? data['mis'] ?? '')
                      .toString()
                      .toLowerCase();
                  return name.contains(query) || mis.contains(query);
                }).toList();

                final total = docs.length;
                final absent = absentStatus.values.where((value) => value).length;
                final present = total - absent;

                return Column(
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
                          Expanded(
                            child: Text(
                              widget.isEditing
                                  ? 'Edit Attendance'
                                  : 'Mark Attendance',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isDark
                                      ? colorScheme.outline.withValues(
                                          alpha: 0.34,
                                        )
                                      : colorScheme.outline.withValues(
                                          alpha: 0.12,
                                        ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? Colors.black.withValues(alpha: 0.16)
                                        : Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.subjectName,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.isEditing
                                        ? 'Update the absent list for this saved session.'
                                        : 'Tap students to mark them absent. Everyone else stays present.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withValues(alpha: 0.82),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _SummaryChip(
                                          label: 'Present',
                                          value: present.toString(),
                                          icon: Icons.check_circle_outline,
                                          color: UIColors.success,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _SummaryChip(
                                          label: 'Absent',
                                          value: absent.toString(),
                                          icon: Icons.person_off_outlined,
                                          color: UIColors.error,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _SummaryChip(
                                          label: 'Total',
                                          value: total.toString(),
                                          icon: Icons.groups_2_outlined,
                                          color: UIColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _searchController,
                              onChanged: (value) =>
                                  setState(() => _searchQuery = value),
                              decoration: InputDecoration(
                                hintText: 'Search by name or MIS',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchQuery.isEmpty
                                    ? null
                                    : IconButton(
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                        icon: const Icon(Icons.close),
                                      ),
                                filled: true,
                                fillColor: colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? colorScheme.outline.withValues(
                                            alpha: 0.34,
                                          )
                                        : colorScheme.outline.withValues(
                                            alpha: 0.12,
                                          ),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: UIColors.primary,
                                    width: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: isDark ? 0.42 : 0.7),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: UIColors.error,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Selected students are absent.',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: filtered.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No students match your search.',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.only(bottom: 96),
                                      itemCount: filtered.length,
                                      itemBuilder: (context, index) {
                                        final doc = filtered[index];
                                        final data =
                                            doc.data() as Map<String, dynamic>;
                                        final uid = doc.id;
                                        final isAbsent =
                                            absentStatus[uid] ?? false;

                                        return _StudentCard(
                                          name:
                                              data['Name'] ??
                                              data['name'] ??
                                              'Unknown',
                                          mis: (data['MIS No'] ??
                                                  data['mis'] ??
                                                  'N/A')
                                              .toString(),
                                          isAbsent: isAbsent,
                                          onTap: () {
                                            setState(() {
                                              absentStatus[uid] = !isAbsent;
                                            });
                                          },
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isEditing
                    ? UIColors.warning
                    : UIColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: _isSaving ? null : _handleSave,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.isEditing
                          ? 'UPDATE ATTENDANCE'
                          : 'CONFIRM ATTENDANCE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final String name;
  final String mis;
  final bool isAbsent;
  final VoidCallback onTap;

  const _StudentCard({
    required this.name,
    required this.mis,
    required this.isAbsent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final color = isAbsent ? UIColors.error : UIColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isAbsent
              ? color.withValues(alpha: 0.30)
              : (isDark
                    ? colorScheme.outline.withValues(alpha: 0.34)
                    : colorScheme.outline.withValues(alpha: 0.12)),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.12)
                : color.withValues(alpha: isAbsent ? 0.12 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(
                  isAbsent ? Icons.person_off : Icons.person,
                  color: color,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MIS: $mis',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isAbsent ? 'Absent' : 'Present',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(label, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
