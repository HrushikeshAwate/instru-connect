import 'package:flutter/material.dart';
import 'package:instru_connect/config/routes/route_names.dart';
import 'package:instru_connect/config/theme/ui_colors.dart';
import 'package:instru_connect/features/admin/screens/admin_user_management_screen.dart';
import 'package:instru_connect/features/auth/screens/log_out_screens.dart';
import 'package:instru_connect/features/complaints/screens/complaint_list_screen.dart';
import 'package:instru_connect/features/complaints/services/complaint_service.dart';
import 'package:instru_connect/features/home/screens/home_image_carousel.dart';
import 'package:instru_connect/features/notices/screens/create_notice_screen.dart';

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

      // ✅ FLOATING PREVIEW BUTTON
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.swap_horiz),
        label: const Text('Preview'),
        onPressed: () => _openPreviewSwitcher(context),
      ),

      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // =================================================
          // TOP CAROUSEL
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
                // QUICK ACTIONS
                // ---------------------------------------------
                const _SectionHeader(
                  title: 'Quick Actions',
                  subtitle: 'Administrative controls',
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
                            builder: (_) =>
                                const AdminUserManagementScreen(),
                          ),
                        );
                      },
                    ),
                    _ActionCard(
                      icon: Icons.groups_outlined,
                      label: 'Manage Batches',
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          Routes.manageBatches,
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

                // ---------------------------------------------
                // SYSTEM OVERVIEW
                // ---------------------------------------------
                const _SectionHeader(
                  title: 'System Overview',
                  subtitle: 'Platform statistics',
                ),
                const SizedBox(height: 14),

                Row(
                  children: const [
                    Expanded(
                      child: _OverviewCard(
                        title: 'Total Users',
                        value: '—',
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: _OverviewCard(
                        title: 'Pending Complaints',
                        value: '—',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  children: const [
                    Expanded(
                      child: _OverviewCard(
                        title: 'Active Notices',
                        value: '—',
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: _OverviewCard(
                        title: 'Events',
                        value: '—',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                // ---------------------------------------------
                // ATTENTION REQUIRED
                // ---------------------------------------------
                const _SectionHeader(
                  title: 'Attention Required',
                  subtitle: 'Immediate action needed',
                ),
                const SizedBox(height: 14),

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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // PREVIEW ROLE SWITCHER
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
              leading: Icon(
                index == 0
                    ? Icons.admin_panel_settings
                    : Icons.person_outline,
              ),
              title: Text(_previewRoles[index]),
              trailing:
                  index == _previewIndex ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, index),
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _previewIndex = selected;
      });

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
        break; // Admin → stay here
    }
  }
}

// =======================================================
// SUPPORTING WIDGETS (UNCHANGED)
// =======================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

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
              Icon(icon,
                  size: 30,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 14),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final String value;

  const _OverviewCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 10),
            Text(value,
                style: Theme.of(context).textTheme.headlineSmall),
          ],
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
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: UIColors.iceBlue.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const ListTile(
          title: Text('Pending complaints'),
          subtitle: Text('Tap to review and assign'),
          trailing: Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
