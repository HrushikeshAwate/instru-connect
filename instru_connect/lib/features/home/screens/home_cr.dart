// features/home/screens/home_cr.dart

import 'package:flutter/material.dart';
import 'package:instru_connect/config/routes/route_names.dart';
import 'package:instru_connect/config/theme/ui_colors.dart';
import 'package:instru_connect/core/sessioin/current_user.dart';
import 'package:instru_connect/features/complaints/screens/complaint_list_screen.dart';
import 'package:instru_connect/features/complaints/services/complaint_service.dart';
import 'package:instru_connect/features/home/screens/home_image_carousel.dart';
import 'package:instru_connect/features/notices/screens/create_notice_screen.dart';
import 'package:instru_connect/features/notices/screens/notice_list_screen.dart';
// ADDED THIS IMPORT
import 'package:instru_connect/features/timetable/screens/timetable_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instru_connect/core/widgets/notification_bell.dart';
import 'package:instru_connect/core/widgets/fade_slide_in.dart';

class HomeCr extends StatelessWidget {
  const HomeCr({super.key});

  Future<String> _resolveBatchName(String? batchId) async {
    if (batchId == null || batchId.trim().isEmpty) return 'CR';
    final batchDoc = await FirebaseFirestore.instance
        .collection('batches')
        .doc(batchId)
        .get();
    final batchName = (batchDoc.data()?['name'] ?? '').toString().trim();
    if (batchName.isEmpty) return 'CR';
    return batchName;
  }

  @override
  Widget build(BuildContext context) {
    final String? batchId = CurrentUser.batchId;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // =========================
          // HERO GRADIENT HEADER
          // =========================
          Container(
            height: 240,
            decoration: const BoxDecoration(
              gradient: UIColors.heroGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // =========================
                // TOP BAR
                // =========================
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'InstruConnect',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            FutureBuilder<String>(
                              future: _resolveBatchName(batchId),
                              builder: (context, snapshot) {
                                return Text(
                                  snapshot.data ?? 'CR',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const NotificationBell(),
                      IconButton(
                        icon: const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                        ),
                        onPressed: () =>
                            Navigator.pushNamed(context, Routes.profile),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const HomeImageCarousel(),
                const SizedBox(height: 28),

                // =========================
                // SUBJECT ATTENDANCE
                // =========================
                const _SectionHeader(
                  title: 'My Attendance',
                  subtitle: 'Per-subject performance',
                ),
                const SizedBox(height: 12),

                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const _SubjectAttendanceError();
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const SizedBox.shrink();
                    }

                    final rawData = snapshot.data!.data();
                    if (rawData is! Map<String, dynamic>) {
                      return const _SubjectAttendanceError();
                    }
                    final subjects = _toStringDynamicMap(rawData['subjects']);
                    final subjectEntries = subjects.entries.toList()
                      ..sort((a, b) => a.key.compareTo(b.key));

                    if (subjectEntries.isEmpty) {
                      return const _EmptySubjectAttendance();
                    }

                    final cardWidth = MediaQuery.of(context).size.width * 0.84;
                    return SizedBox(
                      height: 150,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(right: 12),
                        itemCount: subjectEntries.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final entry = subjectEntries[index];
                          final stats = _toStringDynamicMap(entry.value);
                          final int total = _asInt(stats['total']);
                          final int attended = _asInt(stats['attended']);
                          final double percentage = total == 0
                              ? 0
                              : (attended / total) * 100;

                          return SizedBox(
                            width: cardWidth,
                            child: _SubjectAttendanceCard(
                              subject: entry.key,
                              attended: attended,
                              total: total,
                              percentage: percentage,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                const SizedBox(height: 36),

                // =========================
                // CLASS ACTIONS
                // =========================
                const _SectionHeader(
                  title: 'Class Actions',
                  subtitle: 'Manage and represent your batch',
                ),
                const SizedBox(height: 16),

                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.25,
                  children: [
                    _ActionCard(
                      icon: Icons.add_comment_rounded,
                      label: 'Create Notice',
                      gradient: UIColors.tileGradient(0),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateNoticeScreen(
                            fixedBatchIds: batchId != null ? [batchId] : null,
                            showBatchSelector: false,
                          ),
                        ),
                      ),
                    ),
                    _ActionCard(
                      icon: Icons.campaign_outlined,
                      label: 'View Notices',
                      gradient: UIColors.tileGradient(1),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NoticeListScreen(),
                        ),
                      ),
                    ),
                    _ActionCard(
                      icon: Icons.assignment_late_outlined,
                      label: 'View Complaints',
                      gradient: UIColors.tileGradient(2),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ComplaintListScreen(
                            stream: ComplaintService().fetchAllComplaints(),
                          ),
                        ),
                      ),
                    ),
                    _ActionCard(
                      icon: Icons.calendar_month_outlined,
                      label: 'Event Calendar',
                      gradient: UIColors.tileGradient(3),
                      onTap: () =>
                          Navigator.pushNamed(context, Routes.eventCalendar),
                    ),
                    // FIXED: UPDATED TIMETABLE ACTION
                    _ActionCard(
                      icon: Icons.calendar_today_outlined,
                      label: 'Timetable',
                      gradient: UIColors.tileGradient(4),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TimetableScreen(),
                          ),
                        );
                      },
                    ),
                    _ActionCard(
                      icon: Icons.folder_open_rounded,
                      label: 'Resources',
                      gradient: UIColors.tileGradient(5),
                      onTap: () {
                        Navigator.pushNamed(context, Routes.resources);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// UI COMPONENTS
// ===================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final delay = Duration(milliseconds: 120 + (label.hashCode.abs() % 6) * 45);
    return FadeSlideIn(
      delay: delay,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.white,
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

class _SubjectAttendanceCard extends StatelessWidget {
  final String subject;
  final int attended;
  final int total;
  final double percentage;

  const _SubjectAttendanceCard({
    required this.subject,
    required this.attended,
    required this.total,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLow = percentage < 75;
    final delay = Duration(
      milliseconds: 80 + (subject.hashCode.abs() % 7) * 40,
    );
    return FadeSlideIn(
      delay: delay,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isLow ? UIColors.errorGradient : UIColors.successGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              height: 50,
              width: 50,
              child: CircularProgressIndicator(
                value: percentage / 100,
                strokeWidth: 6,
                backgroundColor: Colors.white24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$attended / $total classes',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySubjectAttendance extends StatelessWidget {
  const _EmptySubjectAttendance();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'No subject attendance yet',
        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
      ),
    );
  }
}

class _SubjectAttendanceError extends StatelessWidget {
  const _SubjectAttendanceError();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Unable to load subject attendance',
        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
      ),
    );
  }
}

Map<String, dynamic> _toStringDynamicMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return Map<String, dynamic>.fromEntries(
      value.entries.map((e) => MapEntry(e.key.toString(), e.value)),
    );
  }
  return <String, dynamic>{};
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
