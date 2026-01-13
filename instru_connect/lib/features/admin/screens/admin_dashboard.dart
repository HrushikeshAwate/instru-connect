import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instru_connect/config/routes/route_names.dart';
import 'package:instru_connect/config/theme/ui_colors.dart';
import 'package:instru_connect/features/admin/screens/admin_user_management_screen.dart';
import 'package:instru_connect/features/auth/screens/log_out_screens.dart';
import 'package:instru_connect/features/complaints/models/complaint_model.dart';
import 'package:instru_connect/features/complaints/screens/complaint_list_screen.dart';
import 'package:instru_connect/features/complaints/services/complaint_service.dart';
import 'package:instru_connect/features/home/screens/home_image_carousel.dart';
import 'package:instru_connect/features/notices/screens/create_notice_screen.dart';
import 'package:instru_connect/features/admin/services/admin_service.dart';
import 'package:instru_connect/features/admin/services/admin_service.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  int _previewIndex = 0;

  final List<String> _previewRoles = [
    'Admin',
    'Student',
    'CR',
    'Faculty',
    'Staff',
  ];

  Future<int> _fetchNoticeCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('notices')
        .get();

    return snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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

      // 🔁 ROLE PREVIEW
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.swap_horiz),
        label: const Text('Preview'),
        onPressed: () => _openPreviewSwitcher(context),
      ),

      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // =================================================
          // HERO / CAROUSEL
          // =================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: const HomeImageCarousel(),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =============================================
                // SYSTEM OVERVIEW (FIRST)
                // =============================================
                const _SectionHeader(
                  title: 'System Overview',
                  subtitle: 'Current platform status',
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: FutureBuilder<int>(
                        future: AdminService().getTotalUsers().then(
                          (value) => value ?? 0,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const _MetricCard(
                              title: 'Total Users',
                              value: '—',
                            );
                          }

                          if (snapshot.hasError) {
                            return const _MetricCard(
                              title: 'Total Users',
                              value: 'Error',
                            );
                          }

                          return _MetricCard(
                            title: 'Total Users',
                            value: snapshot.data.toString(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('complaints')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const _MetricCard(
                              title: 'Pending Complaints',
                              value: '—',
                            );
                          }

                          final docs = snapshot.data!.docs;

                          final pendingCount = docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final status = data['status'] ?? 'submitted';
                            return status != 'resolved';
                          }).length;

                          return _MetricCard(
                            title: 'Pending',
                            value: pendingCount.toString(),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: FutureBuilder<int>(
                        future: _fetchNoticeCount(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const _MetricCard(
                              title: 'Active Notices',
                              value: '—',
                            );
                          }

                          return _MetricCard(
                            title: 'Active Notices',
                            value: snapshot.data!.toString(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: StreamBuilder<List<ComplaintModel>>(
                        stream: ComplaintService().fetchAllComplaints(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const _MetricCard(
                              title: 'Resolved',
                              value: '—',
                            );
                          }

                          final complaints = snapshot.data!;
                          final resolvedCount = complaints.where((complaint) {
                            final status = complaint.status ?? 'submitted';
                            return status == 'resolved';
                          }).length;

                          return _MetricCard(
                            title: 'Resolved',
                            value: resolvedCount.toString(),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // =============================================
                // QUICK ACTIONS
                // =============================================
                const _SectionHeader(
                  title: 'Quick Actions',
                  subtitle: 'Administrative tasks',
                ),
                const SizedBox(height: 16),

                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _ActionCard(
                      icon: Icons.campaign_outlined,
                      label: 'Create Notice',
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
                      icon: Icons.manage_accounts_outlined,
                      label: 'Manage Users',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminUserManagementScreen(),
                          ),
                        );
                      },
                    ),
                    _ActionCard(
                      icon: Icons.groups_outlined,
                      label: 'Manage Batches',
                      onTap: () {
                        Navigator.pushNamed(context, Routes.manageBatches);
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
                  ],
                ),

                const SizedBox(height: 40),

                // =============================================
                // ATTENTION REQUIRED
                // =============================================
                const _SectionHeader(
                  title: 'Attention Required',
                  subtitle: 'Items needing review',
                ),
                const SizedBox(height: 16),

                _AttentionCard(
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
          ),
        ],
      ),
    );
  }

  // =====================================================
  // PREVIEW SWITCHER
  // =====================================================

  void _openPreviewSwitcher(BuildContext context) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return ListView(
          shrinkWrap: true,
          children: List.generate(
            _previewRoles.length,
            (index) => ListTile(
              title: Text(_previewRoles[index]),
              trailing: index == _previewIndex ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, index),
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() => _previewIndex = selected);
      _navigateToPreview(context, selected);
    }
  }

  void _navigateToPreview(BuildContext context, int index) {
    switch (index) {
      case 1:
        Navigator.pushNamed(context, Routes.homeStudent);
        break;
      case 2:
        Navigator.pushNamed(context, Routes.homeCr);
        break;
      case 3:
        Navigator.pushNamed(context, Routes.homeFaculty);
        break;
      case 4:
        Navigator.pushNamed(context, Routes.homeStaff);
        break;
      default:
        break;
    }
  }

  // Future<int> getTotalUsers() async {
  //   final adminService = AdminService();
  //   final totalUsers = await adminService.getTotalUsers();
  //   return totalUsers ?? 0;
  // }
}

// =======================================================
// UI COMPONENTS
// =======================================================

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;

  const _MetricCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
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
          padding: const EdgeInsets.symmetric(vertical: 22),
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

class _AttentionCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AttentionCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: UIColors.iceBlue.withOpacity(0.45),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const ListTile(
          title: Text('Pending Complaints'),
          subtitle: Text('Tap to review and assign'),
          trailing: Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
