import 'dart:io';
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
    // Defined a consistent primary blue for the dashboard
    final Color primaryBlue = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Soft background to make cards pop
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
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

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryBlue,
        icon: const Icon(Icons.swap_horiz, color: Colors.white),
        label: const Text('Preview', style: TextStyle(color: Colors.white)),
        onPressed: () => _openPreviewSwitcher(context),
      ),

      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: const HomeImageCarousel(),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(
                  title: 'System Overview',
                  subtitle: 'Current platform status',
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: FutureBuilder<int>(
                        future: AdminService().getTotalUsers().then((value) => value ?? 0),
                        builder: (context, snapshot) {
                          return _MetricCard(
                            title: 'Total Users',
                            value: snapshot.connectionState == ConnectionState.waiting ? '—' : snapshot.data.toString(),
                            icon: Icons.people_alt_rounded,
                            accentColor: primaryBlue,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('complaints').snapshots(),
                        builder: (context, snapshot) {
                          final pendingCount = !snapshot.hasData ? '—' : snapshot.data!.docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return (data['status'] ?? 'submitted') != 'resolved';
                          }).length.toString();

                          return _MetricCard(
                            title: 'Pending',
                            value: pendingCount,
                            icon: Icons.pending_actions_rounded,
                            accentColor: Colors.orange[700]!, // Keeping functional colors for alerts
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: FutureBuilder<int>(
                        future: _fetchNoticeCount(),
                        builder: (context, snapshot) {
                          return _MetricCard(
                            title: 'Notices',
                            value: !snapshot.hasData ? '—' : snapshot.data!.toString(),
                            icon: Icons.campaign_rounded,
                            accentColor: Colors.blue[800]!,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StreamBuilder<List<ComplaintModel>>(
                        stream: ComplaintService().fetchAllComplaints(),
                        builder: (context, snapshot) {
                          final resolvedCount = !snapshot.hasData ? '—' : snapshot.data!.where((c) => c.status == 'resolved').length.toString();
                          return _MetricCard(
                            title: 'Resolved',
                            value: resolvedCount,
                            icon: Icons.check_circle_rounded,
                            accentColor: Colors.green[700]!,
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                const _SectionHeader(
                  title: 'Quick Actions',
                  subtitle: 'Administrative tasks',
                ),
                const SizedBox(height: 16),

                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.1,
                  children: [
                    _ActionCard(
                      icon: Icons.campaign_rounded,
                      label: 'Create Notice',
                      color: primaryBlue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateNoticeScreen(
                              fixedBatchIds: null,
                              showBatchSelector: true,
                            ),
                          ),
                        );
                      },
                    ),
                    _ActionCard(
                      icon: Icons.manage_accounts_rounded,
                      label: 'Manage Users',
                      color: primaryBlue,
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
                      icon: Icons.groups_rounded,
                      label: 'Manage Batches',
                      color: primaryBlue,
                      onTap: () {
                        Navigator.pushNamed(context, Routes.manageBatches);
                      },
                    ),
                    _ActionCard(
                      icon: Icons.report_problem_rounded,
                      label: 'View Complaints',
                      color: primaryBlue,
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

                const SizedBox(height: 32),
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

  void _openPreviewSwitcher(BuildContext context) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Role Preview', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.blue[900])),
              const Divider(),
              ...List.generate(
                _previewRoles.length,
                    (index) => ListTile(
                  leading: Icon(Icons.person_pin_rounded, color: index == _previewIndex ? Colors.blue : Colors.grey),
                  title: Text(_previewRoles[index], style: TextStyle(fontWeight: index == _previewIndex ? FontWeight.bold : FontWeight.normal)),
                  trailing: index == _previewIndex ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                  onTap: () => Navigator.pop(context, index),
                ),
              ),
            ],
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
      case 1: Navigator.pushNamed(context, Routes.homeStudent); break;
      case 2: Navigator.pushNamed(context, Routes.homeCr); break;
      case 3: Navigator.pushNamed(context, Routes.homeFaculty); break;
      case 4: Navigator.pushNamed(context, Routes.homeStaff); break;
      default: break;
    }
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: accentColor.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
                Icon(icon, color: accentColor.withOpacity(0.5), size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[900]),
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
  final Color color;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue[900]),
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
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900])),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      ],
    );
  }
}

class _AttentionCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AttentionCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[900]!, Colors.blue[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: const Text('Pending Complaints', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: const Text('Review and resolve issues', style: TextStyle(color: Colors.white70)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white),
      ),
    );
  }
}