import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:instru_connect/config/routes/route_names.dart';
import 'package:instru_connect/config/theme/ui_colors.dart';
import 'package:instru_connect/features/auth/screens/log_out_screens.dart';

import 'package:instru_connect/features/complaints/screens/complaint_list_screen.dart';
import 'package:instru_connect/features/complaints/services/complaint_service.dart';
import 'package:instru_connect/features/home/screens/home_image_carousel.dart';

import 'package:instru_connect/features/notices/models/notice_model.dart';
import 'package:instru_connect/features/notices/screens/create_notice_screen.dart';
import 'package:instru_connect/features/notices/screens/notice_detail_screen.dart';
import 'package:instru_connect/features/notices/screens/notice_list_screen.dart';
import 'package:instru_connect/features/notices/services/notice_service.dart';


class HomeFaculty extends StatelessWidget {
  const HomeFaculty({super.key});

  // static const String _departmentId = 'Instrumentation'; // 🔑 SAME SOURCE EVERYWHERE

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showLogoutDialog();
            },
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
          // HERO SECTION
          // =================================================
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  UIColors.primaryBlue.withOpacity(0.15),
                  UIColors.iceBlue.withOpacity(0.4),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: const [HomeImageCarousel(), SizedBox(height: 20)],
            ),
          ),

          // =================================================
          // CONTENT
          // =================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------------------------------------
                // QUICK ACTIONS
                // ---------------------------------------------
                const _SectionHeader(
                  title: 'Quick Actions',
                  subtitle: 'Frequently used faculty tools',
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
                      title: 'Create Notice',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateNoticeScreen(),
                          ),
                        );
                      },
                    ),
                    _ActionCard(
                      icon: Icons.menu_book_outlined,
                      title: 'Study Resources',
                      onTap: () {
                        Navigator.pushNamed(context, Routes.resources);
                      },
                    ),
                    _ActionCard(
                      icon: Icons.upload_file_outlined,
                      title: 'Add Resource',
                      onTap: () {
                        Navigator.pushNamed(context, Routes.addResource);
                      },
                    ),
                    _ActionCard(
                      icon: Icons.groups_outlined,
                      title: 'Manage Batches',
                      onTap: () {
                        Navigator.pushNamed(context, Routes.manageBatches);
                      },
                    ),
                    _ActionCard(
                      icon: Icons.report_problem_outlined,
                      title: 'Complaints',
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
                  ],
                ),

                const SizedBox(height: 36),

                // ---------------------------------------------
                // RECENT NOTICES (REAL DATA)
                // ---------------------------------------------
                const _SectionHeader(
                  title: 'Recent Notices',
                  subtitle: 'Latest academic announcements',
                ),
                const SizedBox(height: 14),

                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: FutureBuilder<List<Notice>>(
                    future: NoticeService().fetchRecentNotices(
                      // departmentId: _departmentId,
                      limit: 3,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('No recent notices'),
                        );
                      }

                      final notices = snapshot.data!;

                      return Column(
                        children: [
                          for (int i = 0; i < notices.length; i++) ...[
                            _NoticeTile(
                              title: notices[i].title,
                              subtitle: 'Tap to view',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        NoticeDetailScreen(notice: notices[i]),
                                  ),
                                );
                              },
                            ),
                            if (i != notices.length - 1)
                              const Divider(height: 1),
                          ],
                        ],
                      );
                    },
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NoticeListScreen(),
                        ),
                      );
                    },
                    child: const Text('View all notices'),
                  ),
                ),

                const SizedBox(height: 36),

                // ---------------------------------------------
                // COMPLAINTS OVERVIEW
                // ---------------------------------------------
                const _SectionHeader(
                  title: 'Complaints Overview',
                  subtitle: 'Current issue status',
                ),
                const SizedBox(height: 14),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('complaints')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Pending',
                              value: '—',
                              color: UIColors.skyBlue,
                            ),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: _StatCard(
                              label: 'Resolved',
                              value: '—',
                              color: UIColors.primaryBlue,
                            ),
                          ),
                        ],
                      );
                    }

                    final docs = snapshot.data!.docs;

                    final pendingCount = docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final status = data['status'] ?? 'submitted';
                      return status != 'resolved';
                    }).length;

                    final resolvedCount = docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return data['status'] == 'resolved';
                    }).length;

                    return Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Pending',
                            value: pendingCount.toString(),
                            color: UIColors.skyBlue,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _StatCard(
                            label: 'Resolved',
                            value: resolvedCount.toString(),
                            color: UIColors.primaryBlue,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================
// LOCAL WIDGETS
// =======================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(subtitle, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
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
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
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
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
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
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NoticeTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
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
            Text(label),
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
