// features/home/screens/home_cr.dart

import 'package:flutter/material.dart';
import 'package:instru_connect/config/routes/route_names.dart';
import 'package:instru_connect/config/theme/ui_colors.dart';
import 'package:instru_connect/core/sessioin/current_user.dart';
import 'package:instru_connect/features/auth/screens/log_out_screens.dart';
import 'package:instru_connect/features/complaints/screens/complaint_list_screen.dart';
import 'package:instru_connect/features/complaints/screens/create_complaint_screen.dart';
import 'package:instru_connect/features/complaints/services/complaint_service.dart';
import 'package:instru_connect/features/home/screens/home_image_carousel.dart';
import 'package:instru_connect/features/notices/screens/create_notice_screen.dart';
import 'package:instru_connect/features/notices/screens/notice_list_screen.dart';

class HomeCr extends StatelessWidget {
  const HomeCr({super.key});

  @override
  Widget build(BuildContext context) {
    final String? batchId = CurrentUser.batchId;

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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CR Dashboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Batch: ${batchId ?? "Not Assigned"}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                        ),
                        onPressed: () =>
                            Navigator.pushNamed(context, Routes.profile),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => showLogoutDialog(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const HomeImageCarousel(),
                const SizedBox(height: 28),

                // =========================
                // CLASS OVERVIEW
                // =========================
                const _SectionHeader(
                  title: 'Class Overview',
                  subtitle: 'Real-time batch metrics',
                ),
                const SizedBox(height: 14),

                Row(
                  children: const [
                    Expanded(
                      child: _StatCard(
                        title: 'Pending',
                        value: '2',
                        icon: Icons.hourglass_top_rounded,
                        gradient: UIColors.warningGradient,
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: _StatCard(
                        title: 'Active Notices',
                        value: '4',
                        icon: Icons.notifications_active_outlined,
                        gradient: UIColors.primaryGradient,
                      ),
                    ),
                  ],
                ),

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
                      gradient: UIColors.primaryGradient,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateNoticeScreen(
                            fixedBatchIds:
                                batchId != null ? [batchId] : null,
                            showBatchSelector: false,
                          ),
                        ),
                      ),
                    ),
                    _ActionCard(
                      icon: Icons.campaign_outlined,
                      label: 'View Notices',
                      gradient: UIColors.secondaryGradient,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NoticeListScreen(),
                        ),
                      ),
                    ),
                    _ActionCard(
                      icon: Icons.assignment_late_outlined,
                      label: 'Complaints',
                      gradient: UIColors.warningGradient,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ComplaintListScreen(
                            stream: ComplaintService()
                                .fetchAllComplaints(),
                          ),
                        ),
                      ),
                    ),
                    _ActionCard(
                      icon: Icons.add_moderator_outlined,
                      label: 'Raise Issue',
                      gradient: UIColors.errorGradient,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const CreateComplaintScreen(),
                        ),
                      ),
                    ),
                    _ActionCard(
                      icon: Icons.calendar_today_outlined,
                      label: 'Timetable',
                      gradient: UIColors.secondaryGradient,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Timetable coming soon'),
                          ),
                        );
                      },
                    ),
                    _ActionCard(
                      icon: Icons.folder_open_rounded,
                      label: 'Resources',
                      gradient: UIColors.primaryGradient,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Resources coming soon'),
                          ),
                        );
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
  const _SectionHeader(
      {required this.title, required this.subtitle});

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
  final String title;
  final String value;
  final IconData icon;
  final Gradient gradient;

  const _StatCard({
    required this.title,
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
            title,
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
    );
  }
}
