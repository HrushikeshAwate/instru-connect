import 'package:flutter/material.dart';
import 'package:instru_connect/config/routes/route_names.dart';

// EXISTING SCREENS

import 'package:instru_connect/features/complaints/screens/complaint_list_screen.dart';
import 'package:instru_connect/features/notices/screens/create_notice_screen.dart';

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===============================
            // QUICK ACTIONS
            // ===============================
            Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _ActionTile(
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
                _ActionTile(
                  icon: Icons.report_problem_outlined,
                  label: 'View Complaints',
                  onTap: () {
                    Navigator.pushNamed(context, Routes.complaints);
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ===============================
            // SYSTEM OVERVIEW
            // ===============================
            Text(
              'System Overview',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            Row(
              children: const [
                Expanded(
                  child: _OverviewCard(
                    title: 'Total Users',
                    value: '—',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _OverviewCard(
                    title: 'Pending Complaints',
                    value: '—',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: const [
                Expanded(
                  child: _OverviewCard(
                    title: 'Active Notices',
                    value: '—',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _OverviewCard(
                    title: 'Events',
                    value: '—',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ===============================
            // ATTENTION REQUIRED
            // ===============================
            Text(
              'Attention Required',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pending complaints'),
              subtitle: const Text('Tap to review'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ComplaintListScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // ===============================
            // RECENT ACTIVITY
            // ===============================
            Text(
              'Recent Activity',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            const _ActivityItem(text: 'Notice published'),
            const _ActivityItem(text: 'Complaint resolved'),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// LOCAL HELPER WIDGETS (NO NEW FILES)
// =======================================================

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
            ),
          ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String text;

  const _ActivityItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text('• $text'),
    );
  }
}
