import 'package:flutter/material.dart';
import 'package:instru_connect/config/routes/route_names.dart';
import 'package:instru_connect/config/theme/ui_colors.dart';
// import 'package:instru_connect/core/bootstrap/user_context.dart';
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
      appBar: AppBar(
        title: const Text('CR Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => showLogoutDialog(context),
          ),

          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.pushNamed(context, Routes.profile);
            },
          ),
        ],
      ),

      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // =================================================
          // TOP IMAGE CAROUSEL
          // =================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: const HomeImageCarousel(),
          ),

          // =================================================
          // CONTENT
          // =================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------------------------------------
                // CLASS ACTIONS
                // ---------------------------------------------
                const _SectionHeader(
                  title: 'Class Actions',
                  subtitle: 'Manage and represent your class',
                ),
                const SizedBox(height: 14),

                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _ActionCard(
  icon: Icons.campaign_outlined,
  label: 'Create Class Notice',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateNoticeScreen(
          fixedBatchIds: [?batchId],   // 🔒 CR batch
          showBatchSelector: false,   // ❌ no selector
        ),
      ),
    );
  },
),
                    _ActionCard(
                      icon: Icons.campaign_outlined,
                      label: 'View Notices',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NoticeListScreen(),
                          ),
                        );
                      },
                    ),
                    _ActionCard(
                      icon: Icons.report_problem_outlined,
                      label: 'View Complaints',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ComplaintListScreen(
                              stream: ComplaintService().fetchAllComplaints(),
                            ),
                          ),
                        );
                      },
                    ),

                    // 🆕 RAISE COMPLAINT (ADDED)
                    _ActionCard(
                      icon: Icons.add_circle_outline,
                      label: 'Raise Complaint',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateComplaintScreen(),
                          ),
                        );
                      },
                    ),

                    _ActionCard(
                      icon: Icons.schedule_outlined,
                      label: 'Timetable',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Timetable coming soon'),
                          ),
                        );
                      },
                    ),
                    _ActionCard(
                      icon: Icons.menu_book_outlined,
                      label: 'Study Resources',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Study resources coming soon'),
                          ),
                        );
                      },
                    ),
                    _ActionCard(
                      icon: Icons.event_outlined,
                      label: 'Events',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Events coming soon')),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                // ---------------------------------------------
                // CLASS OVERVIEW
                // ---------------------------------------------
                const _SectionHeader(
                  title: 'Class Overview',
                  subtitle: 'Current class status',
                ),
                const SizedBox(height: 14),

                Row(
                  children: const [
                    Expanded(
                      child: _StatCard(
                        title: 'Pending Complaints',
                        value: '2',
                        color: UIColors.skyBlue,
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: _StatCard(
                        title: 'Active Notices',
                        value: '4',
                        color: UIColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 30,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 14),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(title),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
