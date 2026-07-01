// features/home/screens/home_faculty.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instru_connect/config/routes/route_names.dart';
import 'package:instru_connect/config/theme/ui_colors.dart';
import 'package:instru_connect/core/providers/app_providers.dart';
import 'package:instru_connect/core/widgets/app_ui.dart';
import 'package:instru_connect/features/complaints/screens/create_complaint_screen.dart';
import 'package:instru_connect/features/complaints/screens/complaint_list_screen.dart';
import 'package:instru_connect/features/home/screens/home_image_carousel.dart';
import 'package:instru_connect/features/notices/models/notice_model.dart';
import 'package:instru_connect/features/notices/screens/create_notice_screen.dart';
import 'package:instru_connect/features/notices/screens/notice_detail_screen.dart';
import 'package:instru_connect/features/notices/screens/notice_list_screen.dart';
// ADDED THIS IMPORT
import 'package:instru_connect/features/timetable/screens/timetable_screen.dart';
import 'package:instru_connect/core/widgets/notification_bell.dart';
import 'package:instru_connect/core/widgets/fade_slide_in.dart';

class HomeFaculty extends ConsumerWidget {
  const HomeFaculty({super.key});

  Future<void> _exportAchievements(BuildContext context, WidgetRef ref) async {
    try {
      final filePath = await ref
          .read(achievementServiceProvider)
          .exportAllAchievementsCsv();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export downloaded to: $filePath')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestore = ref.watch(firebaseFirestoreProvider);
    final noticeService = ref.watch(noticeServiceProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const AppHeroBackground(height: 232),

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
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'InstruConnect',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Faculty',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
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
                // COMPLAINTS OVERVIEW
                // =========================
                StreamBuilder<QuerySnapshot>(
                  stream: firestore.collection('complaints').snapshots(),
                  builder: (context, snapshot) {
                    final pending = !snapshot.hasData
                        ? '—'
                        : snapshot.data!.docs
                              .where(
                                (d) =>
                                    (d.data() as Map)['status'] != 'resolved',
                              )
                              .length
                              .toString();

                    final resolved = !snapshot.hasData
                        ? '—'
                        : snapshot.data!.docs
                              .where(
                                (d) =>
                                    (d.data() as Map)['status'] == 'resolved',
                              )
                              .length
                              .toString();

                    return Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Pending',
                            value: pending,
                            icon: Icons.pending_outlined,
                            gradient: UIColors.tileGradient(3),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _StatCard(
                            label: 'Resolved',
                            value: resolved,
                            icon: Icons.check_circle_outline,
                            gradient: UIColors.successGradient,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 36),

                // =========================
                // QUICK ACTIONS
                // =========================
                const AppSectionHeader(
                  title: 'Quick Actions',
                  subtitle: 'Academic & management tools',
                ),
                const SizedBox(height: 16),

                AppActionGrid(
                  children: [
                    AppActionTile(
                      icon: Icons.add_alert_outlined,
                      label: 'Create Notice',
                      gradient: UIColors.tileGradient(0),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateNoticeScreen(
                            fixedBatchIds: null,
                            showBatchSelector: true,
                          ),
                        ),
                      ),
                    ),
                    AppActionTile(
                      icon: Icons.calendar_today_outlined,
                      label: 'Event Calendar',
                      gradient: UIColors.tileGradient(1),
                      onTap: () =>
                          Navigator.pushNamed(context, Routes.eventCalendar),
                    ),
                    AppActionTile(
                      icon: Icons.library_books_outlined,
                      label: 'Resources',
                      gradient: UIColors.tileGradient(2),
                      onTap: () =>
                          Navigator.pushNamed(context, Routes.resources),
                    ),
                    // ADDED TIMETABLE CARD
                    AppActionTile(
                      icon: Icons.assignment_late_outlined,
                      label: 'Complaints',
                      gradient: UIColors.tileGradient(3),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ComplaintListScreen(),
                        ),
                      ),
                    ),
                    AppActionTile(
                      icon: Icons.add_comment_outlined,
                      label: 'Raise Complaint',
                      gradient: UIColors.tileGradient(4),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateComplaintScreen(),
                        ),
                      ),
                    ),
                    AppActionTile(
                      icon: Icons.calendar_month_outlined,
                      label: 'Timetable',
                      gradient: UIColors.tileGradient(5),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TimetableScreen(),
                          ),
                        );
                      },
                    ),
                    AppActionTile(
                      icon: Icons.group_work_outlined,
                      label: 'Manage Batches',
                      gradient: UIColors.tileGradient(0),
                      onTap: () =>
                          Navigator.pushNamed(context, Routes.manageBatches),
                    ),
                    AppActionTile(
                      icon: Icons.file_download_outlined,
                      label: 'Export Achievements',
                      gradient: UIColors.tileGradient(1),
                      onTap: () => _exportAchievements(context, ref),
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                // =========================
                // RECENT NOTICES
                // =========================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const AppSectionHeader(
                      title: 'Recent Notices',
                      subtitle: 'Latest announcements',
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NoticeListScreen(),
                        ),
                      ),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: FutureBuilder<List<Notice>>(
                    future: noticeService.fetchRecentNotices(limit: 3),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No notices found'),
                        );
                      }

                      return Column(
                        children: snapshot.data!.asMap().entries.map((entry) {
                          final isLast = entry.key == snapshot.data!.length - 1;
                          return Column(
                            children: [
                              _NoticeTile(
                                notice: entry.value,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        NoticeDetailScreen(notice: entry.value),
                                  ),
                                ),
                              ),
                              if (!isLast) const Divider(height: 1),
                            ],
                          );
                        }).toList(),
                      );
                    },
                  ),
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
// Screen-specific UI components
// ===================================================================

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Gradient gradient;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final delay = Duration(milliseconds: 70 + (label.hashCode.abs() % 5) * 55);
    return FadeSlideIn(
      delay: delay,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeTile extends StatelessWidget {
  final Notice notice;
  final VoidCallback onTap;

  const _NoticeTile({required this.notice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      title: Text(
        notice.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: const Text(
        'Tap to view details',
        style: TextStyle(fontSize: 12),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }
}
