// features/home/screens/home_faculty.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instru_connect/config/routes/route_names.dart';
import 'package:instru_connect/config/theme/ui_colors.dart';
import 'package:instru_connect/features/auth/screens/log_out_screens.dart';
import 'package:instru_connect/features/home/screens/home_image_carousel.dart';
import 'package:instru_connect/features/notices/models/notice_model.dart';
import 'package:instru_connect/features/notices/screens/create_notice_screen.dart';
import 'package:instru_connect/features/notices/screens/notice_detail_screen.dart';
import 'package:instru_connect/features/notices/screens/notice_list_screen.dart';
import 'package:instru_connect/features/notices/services/notice_service.dart';
// ADDED THIS IMPORT
import 'package:instru_connect/features/timetable/screens/timetable_screen.dart';
import 'package:instru_connect/features/profile/services/achievement_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:instru_connect/core/widgets/notification_bell.dart';

class HomeFaculty extends StatelessWidget {
  const HomeFaculty({super.key});

  Future<void> _exportAchievements(BuildContext context) async {
    try {
      final filePath = await AchievementService().exportAllAchievementsCsv();
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Achievements export',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIColors.background,
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
                      if (Navigator.canPop(context))
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Faculty Portal',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Academic Session 2025–26',
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
                        icon: const Icon(Icons.person_outline,
                            color: Colors.white),
                        onPressed: () =>
                            Navigator.pushNamed(context, Routes.profile),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded,
                            color: Colors.white),
                        onPressed: () => showLogoutDialog(context),
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
                  stream: FirebaseFirestore.instance
                      .collection('complaints')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final pending = !snapshot.hasData
                        ? '—'
                        : snapshot.data!.docs
                        .where((d) =>
                    (d.data() as Map)['status'] != 'resolved')
                        .length
                        .toString();

                    final resolved = !snapshot.hasData
                        ? '—'
                        : snapshot.data!.docs
                        .where((d) =>
                    (d.data() as Map)['status'] == 'resolved')
                        .length
                        .toString();

                    return Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Pending',
                            value: pending,
                            icon: Icons.pending_outlined,
                            gradient: UIColors.warningGradient,
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
                const _SectionHeader(
                  title: 'Quick Actions',
                  subtitle: 'Academic & management tools',
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
                      icon: Icons.add_alert_outlined,
                      title: 'Create Notice',
                      gradient: UIColors.primaryGradient,
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
                    _ActionCard(
                      icon: Icons.calendar_today_outlined,
                      title: 'Event Calendar',
                      gradient: UIColors.secondaryGradient,
                      onTap: () =>
                          Navigator.pushNamed(context, Routes.eventCalendar),
                    ),
                    _ActionCard(
                      icon: Icons.library_books_outlined,
                      title: 'Resources',
                      gradient: UIColors.secondaryGradient,
                      onTap: () =>
                          Navigator.pushNamed(context, Routes.resources),
                    ),
                    // ADDED TIMETABLE CARD
                    _ActionCard(
                      icon: Icons.calendar_month_outlined,
                      title: 'Timetable',
                      gradient: UIColors.warningGradient,
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
                      icon: Icons.group_work_outlined,
                      title: 'Manage Batches',
                      gradient: UIColors.secondaryGradient,
                      onTap: () =>
                          Navigator.pushNamed(context, Routes.manageBatches),
                    ),
                    _ActionCard(
                      icon: Icons.file_download_outlined,
                      title: 'Export Achievements',
                      gradient: UIColors.secondaryGradient,
                      onTap: () => _exportAchievements(context),
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
                    const _SectionHeader(
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
                    color: UIColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: FutureBuilder<List<Notice>>(
                    future: NoticeService().fetchRecentNotices(limit: 3),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No notices found'),
                        );
                      }

                      return Column(
                        children: snapshot.data!
                            .asMap()
                            .entries
                            .map((entry) {
                          final isLast =
                              entry.key == snapshot.data!.length - 1;
                          return Column(
                            children: [
                              _NoticeTile(
                                notice: entry.value,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => NoticeDetailScreen(
                                      notice: entry.value,
                                    ),
                                  ),
                                ),
                              ),
                              if (!isLast)
                                const Divider(height: 1),
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
// UI COMPONENTS (No changes below this line)
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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: UIColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: UIColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
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
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
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
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
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
    );
  }
}

class _NoticeTile extends StatelessWidget {
  final Notice notice;
  final VoidCallback onTap;

  const _NoticeTile({
    required this.notice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
      trailing:
      const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }
}
