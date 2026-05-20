import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../config/theme/ui_colors.dart';
import '../../../core/widgets/destructive_confirmation_dialog.dart';
import '../../batches/services/batch_service.dart';
import 'mark_attendance_screen.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final String batchId;
  final String subjectName;

  const AttendanceHistoryScreen({
    super.key,
    required this.batchId,
    required this.subjectName,
  });

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  String? _cachedRole;
  bool _exporting = false;

  Future<String> _getUserRole() async {
    if (_cachedRole != null) return _cachedRole!;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'student';

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    _cachedRole = (doc.data()?['role'] ?? 'student').toString();
    return _cachedRole!;
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
            height: 180,
            decoration: const BoxDecoration(
              gradient: UIColors.heroGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
          ),
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
                      Expanded(
                        child: Text(
                          '${widget.subjectName} Sessions',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: _exporting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.file_download_outlined,
                                color: Colors.white,
                              ),
                        onPressed: _exporting ? null : _exportAttendance,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<String>(
                    future: _getUserRole(),
                    builder: (context, roleSnapshot) {
                      if (!roleSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final userRole = roleSnapshot.data!;
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('sessions')
                            .where('batchId', isEqualTo: widget.batchId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }

                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final docs =
                              snapshot.data!.docs.where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final subjectName = (data['subjectName'] ?? '')
                                    .toString()
                                    .trim();
                                return subjectName == widget.subjectName.trim();
                              }).toList()..sort((a, b) {
                                final aData = a.data() as Map<String, dynamic>;
                                final bData = b.data() as Map<String, dynamic>;
                                final aCreatedAt =
                                    aData['createdAt'] as Timestamp?;
                                final bCreatedAt =
                                    bData['createdAt'] as Timestamp?;

                                if (aCreatedAt != null && bCreatedAt != null) {
                                  return bCreatedAt.compareTo(aCreatedAt);
                                }
                                if (aCreatedAt != null) return -1;
                                if (bCreatedAt != null) return 1;
                                return b.id.compareTo(a.id);
                              });
                          if (docs.isEmpty) {
                            return const _EmptyState();
                          }

                          return Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  10,
                                ),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: isDark
                                        ? colorScheme.outline.withValues(
                                            alpha: 0.34,
                                          )
                                        : colorScheme.outline.withValues(
                                            alpha: 0.12,
                                          ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _HistorySummaryChip(
                                        label: 'Sessions',
                                        value: docs.length.toString(),
                                        icon: Icons.history_toggle_off_rounded,
                                        color: UIColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _HistorySummaryChip(
                                        label: 'Subject',
                                        value: widget.subjectName,
                                        icon: Icons.menu_book_rounded,
                                        color: UIColors.tertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    24,
                                  ),
                                  itemCount: docs.length,
                                  itemBuilder: (context, index) {
                                    final doc = docs[index];
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    final absentees = List<String>.from(
                                      data['absentStudentIds'] ?? <String>[],
                                    );

                                    final canEditAttendance =
                                        userRole == 'faculty' ||
                                        userRole == 'admin';

                                    return _AttendanceCard(
                                      date: (data['date'] ?? 'N/A').toString(),
                                      sessionNumber:
                                          (data['sessionNumber'] as num?)
                                              ?.toInt() ??
                                          1,
                                      absentCount:
                                          (data['absentCount'] as num?)
                                              ?.toInt() ??
                                          absentees.length,
                                      presentCount:
                                          (data['presentCount'] as num?)
                                              ?.toInt() ??
                                          0,
                                      totalStudents:
                                          (data['totalStudents'] as num?)
                                              ?.toInt() ??
                                          0,
                                      onEdit: canEditAttendance
                                          ? () => _navigateToEdit(
                                              doc.id,
                                              absentees,
                                            )
                                          : null,
                                      onDelete: canEditAttendance
                                          ? () => _confirmDelete(doc.id)
                                          : null,
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAttendance() async {
    setState(() => _exporting = true);
    try {
      final role = await _getUserRole();
      if (role != 'faculty' && role != 'admin') {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Not authorized')));
        }
        return;
      }

      final usersSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('batchId', isEqualTo: widget.batchId)
          .where('role', whereIn: ['student', 'cr'])
          .get();

      final rows = <List<dynamic>>[
        ['Subject', 'Name', 'MIS No', 'Attended', 'Total', 'Percentage'],
      ];

      for (final doc in usersSnap.docs) {
        final data = doc.data();
        final name = (data['name'] ?? data['Name'] ?? '').toString();
        final mis = (data['mis'] ?? data['MIS No'] ?? '').toString();
        final subjects = (data['subjects'] ?? {}) as Map<String, dynamic>;
        final stats =
            (subjects[widget.subjectName] ?? {}) as Map<String, dynamic>;
        final total = (stats['total'] as num?)?.toInt() ?? 0;
        final attended = (stats['attended'] as num?)?.toInt() ?? 0;
        final percentage = total == 0 ? 0 : (attended / total) * 100;

        rows.add([
          widget.subjectName,
          name,
          mis,
          attended,
          total,
          percentage.toStringAsFixed(1),
        ]);
      }

      final csv = const ListToCsvConverter().convert(rows);
      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/attendance_${widget.subjectName}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(filePath);
      await file.writeAsString(csv);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          text: 'Attendance - ${widget.subjectName}',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _navigateToEdit(String sessionId, List<String> absentees) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarkAttendanceScreen(
          batchId: widget.batchId,
          subjectName: widget.subjectName,
          isEditing: true,
          docId: sessionId,
          initialAbsentees: absentees,
        ),
      ),
    );
  }

  void _confirmDelete(String sessionId) async {
    final confirmed = await showDestructiveConfirmationDialog(
      context: context,
      title: 'Delete Attendance Session?',
      message:
          'This will permanently delete the attendance session and all linked attendance records. The deleted data cannot be undone or recovered.',
    );
    if (confirmed != true) return;

    await BatchService().deleteAttendance(widget.batchId, sessionId);
  }
}

class _AttendanceCard extends StatelessWidget {
  final String date;
  final int sessionNumber;
  final int absentCount;
  final int presentCount;
  final int totalStudents;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _AttendanceCard({
    required this.date,
    required this.sessionNumber,
    required this.absentCount,
    required this.presentCount,
    required this.totalStudents,
    required this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? colorScheme.outline.withValues(alpha: 0.34)
              : colorScheme.outline.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.16)
                : UIColors.primary.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 64,
              decoration: BoxDecoration(
                gradient: UIColors.primaryGradient,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$date • Session $sessionNumber',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$presentCount present • $absentCount absent • $totalStudents students',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, color: UIColors.primary),
                onPressed: onEdit,
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

class _HistorySummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _HistorySummaryChip({
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: UIColors.secondaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_edu, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'No attendance sessions found',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
