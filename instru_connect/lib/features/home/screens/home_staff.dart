import 'package:flutter/material.dart';

import 'package:instru_connect/core/widgets/quick_actions/quick_action_tile.dart';
import 'package:instru_connect/features/complaints/screens/complaint_list_screen.dart';
import 'package:instru_connect/features/notices/screens/notice_list_screen.dart';
import 'package:instru_connect/features/profile/screens/profile_screen.dart';
// import 'package:icconnect/features/timetable/screens/timetable_screen.dart';

class HomeStaff extends StatelessWidget {
  const HomeStaff({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===============================
          // QUICK ACTIONS
          // ===============================
          const _SectionHeader(title: 'Staff Panel'),
          const SizedBox(height: 12),

          QuickActionTile(
            icon: Icons.report_problem,
            title: 'Assigned Complaints',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ComplaintListScreen(),
                ),
              );
            },
          ),

          QuickActionTile(
            icon: Icons.campaign,
            title: 'View Notices',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NoticeListScreen(),
                ),
              );
            },
          ),

          QuickActionTile(
            icon: Icons.schedule,
            title: 'Timetable',
            onTap: () {
              // Navigator.push(context,
              //   MaterialPageRoute(builder: (_) => const TimetableScreen()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Timetable coming soon')),
              );
            },
          ),

          const SizedBox(height: 24),

          // ===============================
          // WORK OVERVIEW
          // ===============================
          const _SectionHeader(title: 'Work Overview'),
          const SizedBox(height: 8),

          _StatusTile(title: 'Pending Tasks', value: '5'),
          _StatusTile(title: 'Resolved Tasks', value: '18'),
        ],
      ),
    );
  }
}

// =======================================================
// LOCAL SUPPORT WIDGETS
// =======================================================

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}

class _StatusTile extends StatelessWidget {
  final String title;
  final String value;

  const _StatusTile({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
