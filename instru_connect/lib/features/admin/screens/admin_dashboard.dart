// features/admin/screens/admin_dashboard_view.dart

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
    final snapshot =
        await FirebaseFirestore.instance.collection('notices').get();
    return snapshot.docs.length;
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
                            'Admin Dashboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'System Control Center',
                            style: TextStyle(
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
                // SYSTEM OVERVIEW
                // =========================
                const _SectionHeader(
                  title: 'System Overview',
                  subtitle: 'Live platform metrics',
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: FutureBuilder<int>(
                        future: AdminService()
                            .getTotalUsers()
                            .then((v) => v ?? 0),
                        builder: (context, snapshot) {
                          return _MetricCard(
                            title: 'Total Users',
                            value: snapshot.connectionState ==
                                    ConnectionState.waiting
                                ? '—'
                                : snapshot.data.toString(),
                            icon: Icons.people_outline_rounded,
                            gradient: UIColors.secondaryGradient,
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
                          final pending = !snapshot.hasData
                              ? '—'
                              : snapshot.data!.docs.where((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  return (data['status'] ?? 'submitted') !=
                                      'resolved';
                                }).length.toString();

                          return _MetricCard(
                            title: 'Pending',
                            value: pending,
                            icon: Icons.hourglass_empty_rounded,
                            gradient: UIColors.warningGradient,
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
                          return _MetricCard(
                            title: 'Notices',
                            value: !snapshot.hasData
                                ? '—'
                                : snapshot.data.toString(),
                            icon: Icons.campaign_outlined,
                            gradient: UIColors.primaryGradient,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: StreamBuilder<List<ComplaintModel>>(
                        stream: ComplaintService().fetchAllComplaints(),
                        builder: (context, snapshot) {
                          final resolved = !snapshot.hasData
                              ? '—'
                              : snapshot.data!
                                  .where(
                                      (c) => c.status == 'resolved')
                                  .length
                                  .toString();

                          return _MetricCard(
                            title: 'Resolved',
                            value: resolved,
                            icon:
                                Icons.check_circle_outline_rounded,
                            gradient: UIColors.successGradient,
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                // =========================
                // QUICK ACTIONS
                // =========================
                const _SectionHeader(
                  title: 'Quick Actions',
                  subtitle: 'Administrative control center',
                ),
                const SizedBox(height: 16),

                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.25,
                  children: [
                    _ActionCard(
                      icon: Icons.campaign_outlined,
                      label: 'Create Notice',
                      gradient: UIColors.primaryGradient,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const CreateNoticeScreen(
                              fixedBatchIds: null,
                              showBatchSelector: true,
                            ),
                          ),
                        );
                      },
                    ),
                    _ActionCard(
                      icon: Icons.manage_accounts_outlined,
                      label: 'Manage Users',
                      gradient: UIColors.secondaryGradient,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AdminUserManagementScreen(),
                          ),
                        );
                      },
                    ),
                    _ActionCard(
                      icon: Icons.layers_outlined,
                      label: 'Manage Batches',
                      gradient: UIColors.primaryGradient,
                      onTap: () {
                        Navigator.pushNamed(
                            context, Routes.manageBatches);
                      },
                    ),
                    _ActionCard(
                      icon:
                          Icons.report_gmailerrorred_outlined,
                      label: 'View Complaints',
                      gradient: UIColors.warningGradient,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ComplaintListScreen(
                              stream: ComplaintService()
                                  .fetchAllComplaints(),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                const _SectionHeader(
                  title: 'Attention Required',
                  subtitle: 'Items needing priority review',
                ),
                const SizedBox(height: 16),

                _AttentionCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ComplaintListScreen(
                          stream: ComplaintService()
                              .fetchAllComplaints(),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: UIColors.primary,
        icon: const Icon(Icons.remove_red_eye_outlined),
        label: const Text(
          'Preview Mode',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => _openPreviewSwitcher(context),
      ),
    );
  }

  void _openPreviewSwitcher(BuildContext context) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Role Preview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: UIColors.textPrimary,
                ),
              ),
              const Divider(),
              ...List.generate(
                _previewRoles.length,
                (index) => ListTile(
                  leading: Icon(
                    Icons.person_pin_rounded,
                    color: index == _previewIndex
                        ? UIColors.primary
                        : Colors.grey,
                  ),
                  title: Text(
                    _previewRoles[index],
                    style: TextStyle(
                      fontWeight: index == _previewIndex
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: index == _previewIndex
                      ? const Icon(Icons.check_circle,
                          color: UIColors.primary)
                      : null,
                  onTap: () =>
                      Navigator.pop(context, index),
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
}

// ===================================================================
// UI COMPONENTS (ADVANCED, COLORFUL)
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

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Gradient gradient;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
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
            color: Colors.black.withOpacity(0.2),
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

class _AttentionCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AttentionCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: UIColors.warningGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        title: const Text(
          'Pending Complaints',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text(
          'Review and resolve issues',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}
