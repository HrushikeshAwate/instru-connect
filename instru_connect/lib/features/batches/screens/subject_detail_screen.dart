import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:instru_connect/features/attendance/screens/attendance_history_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../config/theme/ui_colors.dart';
import '../../attendance/screens/mark_attendance_screen.dart';

class SubjectDetailScreen extends StatelessWidget {
  final String subjectName;
  final String batchId;

  const SubjectDetailScreen({
    super.key,
    required this.subjectName,
    required this.batchId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIColors.background,

      body: Stack(
        children: [
          // ================= HEADER =================
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
                // ================= APP BAR =================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          subjectName,
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
                        icon: const Icon(Icons.history,
                            color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AttendanceHistoryScreen(
                                batchId: batchId,
                                subjectName: subjectName,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ================= STUDENT LIST =================
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', whereIn: ['student', 'cr'])
                        .where('batchId', isEqualTo: batchId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text('No students found'));
                      }

                      final students = snapshot.data!.docs;

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                            16, 16, 16, 100),
                        itemCount: students.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final data = students[index].data()
                                  as Map<String, dynamic>? ??
                              {};

                          final String name =
                              data['Name'] ??
                                  data['name'] ??
                                  'Unnamed Student';
                          final String mis =
                              (data['MIS No'] ??
                                      data['mis'] ??
                                      'N/A')
                                  .toString();

                          final Map<String, dynamic>
                              subjectsMap =
                              data['subjects'] ?? {};
                          final Map<String, dynamic>
                              stats =
                              subjectsMap[subjectName] ??
                                  {};

                          final int total =
                              stats['total'] ?? 0;
                          final int attended =
                              stats['attended'] ?? 0;
                          final double percentage =
                              total == 0
                                  ? 0
                                  : (attended / total) * 100;

                          final bool low =
                              percentage < 75 && total > 0;

                          return _StudentAttendanceCard(
                            name: name,
                            mis: mis,
                            attended: attended,
                            total: total,
                            percentage: percentage,
                            isLow: low,
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

      // ================= FAB =================
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: UIColors.primary,
        icon: const Icon(Icons.fact_check),
        label: const Text('Mark Attendance'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MarkAttendanceScreen(
                batchId: batchId,
                subjectName: subjectName,
              ),
            ),
          );
        },
      ),
    );
  }
}

// =======================================================
// STUDENT CARD (MATCHES NOTICE / RESOURCE)
// =======================================================

class _StudentAttendanceCard extends StatelessWidget {
  final String name;
  final String mis;
  final int attended;
  final int total;
  final double percentage;
  final bool isLow;

  const _StudentAttendanceCard({
    required this.name,
    required this.mis,
    required this.attended,
    required this.total,
    required this.percentage,
    required this.isLow,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent =
        isLow ? UIColors.error : UIColors.success;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            // LEFT STRIP
            Container(
              width: 6,
              height: 60,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 14),

            // INFO
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'MIS: $mis',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                            color: UIColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$attended / $total classes attended',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall,
                  ),
                  if (isLow)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        '⚠ LOW ATTENDANCE (<75%)',
                        style: TextStyle(
                          color: UIColors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // PERCENT
            CircleAvatar(
              backgroundColor: accent,
              radius: 22,
              child: Text(
                '${percentage.toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
