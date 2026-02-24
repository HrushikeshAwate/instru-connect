// ignore_for_file: use_build_context_synchronously
// features/admin/screens/admin_dashboard_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instru_connect/config/routes/route_names.dart';
import 'package:instru_connect/config/theme/ui_colors.dart';
import 'package:instru_connect/features/admin/screens/admin_user_management_screen.dart';
import 'package:instru_connect/features/complaints/models/complaint_model.dart';
import 'package:instru_connect/features/complaints/screens/complaint_list_screen.dart';
import 'package:instru_connect/features/complaints/services/complaint_service.dart';
import 'package:instru_connect/features/home/screens/home_image_carousel.dart';
import 'package:instru_connect/features/notices/screens/create_notice_screen.dart';
import 'package:instru_connect/features/admin/services/admin_service.dart';
import 'package:instru_connect/features/home/screens/home_cr.dart';
import 'package:instru_connect/features/home/screens/home_faculty.dart';
import 'package:instru_connect/features/home/screens/home_staff.dart';
import 'package:instru_connect/features/home/screens/home_student.dart';
import 'package:instru_connect/features/profile/services/achievement_service.dart';
import 'package:instru_connect/core/widgets/notification_bell.dart';
import 'package:instru_connect/core/widgets/fade_slide_in.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  int _previewIndex = 0;
  bool _exportingAchievements = false;

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

  Future<void> _exportAchievements() async {
    if (_exportingAchievements) return;
    setState(() => _exportingAchievements = true);

    try {
      final filePath = await AchievementService().exportAllAchievementsCsv();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export downloaded to: $filePath')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _exportingAchievements = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'InstruConnect',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Admin',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
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
                        future: AdminService().getTotalUsers(),
                        builder: (context, snapshot) {
                          return _MetricCard(
                            title: 'Total Users',
                            value:
                                snapshot.connectionState ==
                                    ConnectionState.waiting
                                ? '—'
                                : snapshot.hasError
                                ? 'ERR'
                                : (snapshot.data ?? 0).toString(),
                            icon: Icons.people_outline_rounded,
                            gradient: UIColors.tileGradient(1),
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
                              : snapshot.data!.docs
                                    .where((doc) {
                                      final data =
                                          doc.data() as Map<String, dynamic>;
                                      return (data['status'] ?? 'submitted') !=
                                          'resolved';
                                    })
                                    .length
                                    .toString();

                          return _MetricCard(
                            title: 'Pending',
                            value: pending,
                            icon: Icons.hourglass_empty_rounded,
                            gradient: UIColors.tileGradient(3),
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
                            gradient: UIColors.tileGradient(0),
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
                                    .where((c) => c.status == 'resolved')
                                    .length
                                    .toString();

                          return _MetricCard(
                            title: 'Resolved',
                            value: resolved,
                            icon: Icons.check_circle_outline_rounded,
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
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.25,
                  children: [
                    _ActionCard(
                      icon: Icons.campaign_outlined,
                      label: 'Create Notice',
                      gradient: UIColors.tileGradient(0),
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
                      icon: Icons.manage_accounts_outlined,
                      label: 'Manage Users',
                      gradient: UIColors.tileGradient(1),
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
                      icon: Icons.layers_outlined,
                      label: 'Manage Batches',
                      gradient: UIColors.tileGradient(2),
                      onTap: () {
                        Navigator.pushNamed(context, Routes.manageBatches);
                      },
                    ),
                    _ActionCard(
                      icon: Icons.report_gmailerrorred_outlined,
                      label: 'View Complaints',
                      gradient: UIColors.tileGradient(3),
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
                    _ActionCard(
                      icon: _exportingAchievements
                          ? Icons.hourglass_bottom_rounded
                          : Icons.file_download_outlined,
                      label: _exportingAchievements
                          ? 'Exporting...'
                          : 'Export Achievements',
                      gradient: UIColors.tileGradient(4),
                      onTap: _exportingAchievements
                          ? () {}
                          : () => _exportAchievements(),
                    ),
                    _ActionCard(
                      icon: Icons.calendar_today_outlined,
                      label: 'Event Calendar',
                      gradient: UIColors.tileGradient(5),
                      onTap: () =>
                          Navigator.pushNamed(context, Routes.eventCalendar),
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
                          stream: ComplaintService().fetchAllComplaints(),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Role Preview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
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
                      ? const Icon(Icons.check_circle, color: UIColors.primary)
                      : null,
                  onTap: () => Navigator.pop(context, index),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      if (!mounted) return;
      setState(() => _previewIndex = selected);
      await _navigateToPreview(context, selected);
      if (!mounted) return;
      setState(() => _previewIndex = 0);
    }
  }

  Future<void> _navigateToPreview(BuildContext context, int index) async {
    Widget? previewScreen;
    String role = '';
    switch (index) {
      case 1:
        previewScreen = const HomeStudent();
        role = 'Student';
        break;
      case 2:
        previewScreen = const HomeCr();
        role = 'CR';
        break;
      case 3:
        previewScreen = const HomeFaculty();
        role = 'Faculty';
        break;
      case 4:
        previewScreen = const HomeStaff();
        role = 'Staff';
        break;
      default:
        break;
    }

    if (previewScreen == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PreviewScaffold(role: role, child: previewScreen!),
      ),
    );
  }
}

class _PreviewScaffold extends StatefulWidget {
  final String role;
  final Widget child;

  const _PreviewScaffold({required this.role, required this.child});

  @override
  State<_PreviewScaffold> createState() => _PreviewScaffoldState();
}

class _PreviewScaffoldState extends State<_PreviewScaffold> {
  double? _left;
  double? _top;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final safeTop = MediaQuery.of(context).padding.top;
    _left ??= size.width - 132;
    _top ??= safeTop + 8;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: widget.child),
          Positioned(
            left: _left,
            top: _top,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  final nextLeft = (_left ?? 0) + details.delta.dx;
                  final nextTop = (_top ?? 0) + details.delta.dy;
                  _left = nextLeft.clamp(8.0, size.width - 124.0);
                  _top = nextTop.clamp(safeTop + 8.0, size.height - 60.0);
                });
              },
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(20),
                color: Colors.black.withValues(alpha: 0.75),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.role,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 28),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Back',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// UI COMPONENTS (ADVANCED, COLORFUL)
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
    final delay = Duration(milliseconds: 70 + (title.hashCode.abs() % 5) * 55);
    return FadeSlideIn(
      delay: delay,
      child: Container(
        padding: const EdgeInsets.all(20),
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
    final delay = Duration(milliseconds: 120 + (label.hashCode.abs() % 6) * 45);
    return FadeSlideIn(
      delay: delay,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
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

class _AttentionCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AttentionCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      delay: const Duration(milliseconds: 280),
      child: Container(
        decoration: BoxDecoration(
          gradient: UIColors.tileGradient(3),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 8,
          ),
          title: const Text(
            'Pending Complaints',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            'Review and resolve issues',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}
