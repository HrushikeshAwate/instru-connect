import 'package:flutter/material.dart';

import 'package:instru_connect/core/widgets/quick_actions/quick_action_tile.dart';
import 'package:instru_connect/features/complaints/screens/complaint_list_screen.dart';
import 'package:instru_connect/features/notices/screens/create_notice_screen.dart';
import 'package:instru_connect/features/profile/screens/profile_screen.dart';
// import 'package:icconnect/features/timetable/screens/timetable_screen.dart';
// import 'package:icconnect/features/resources/screens/study_resources_screen.dart';

class HomeCr extends StatelessWidget {
  const HomeCr({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CR Home'),
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
          const _SectionHeader(title: 'Class Actions'),
          const SizedBox(height: 12),

          QuickActionTile(
            icon: Icons.campaign_outlined,
            title: 'Create Class Notice',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateNoticeScreen(),
                ),
              );
            },
          ),

          QuickActionTile(
            icon: Icons.report_problem_outlined,
            title: 'View Complaints',
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
            icon: Icons.schedule_outlined,
            title: 'Timetable',
            onTap: () {
              // Navigator.push(context,
              //   MaterialPageRoute(builder: (_) => const TimetableScreen()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Timetable coming soon')),
              );
            },
          ),

          QuickActionTile(
            icon: Icons.menu_book_outlined,
            title: 'Study Resources',
            onTap: () {
              // Navigator.push(context,
              //   MaterialPageRoute(builder: (_) => const StudyResourcesScreen()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Study resources coming soon')),
              );
            },
          ),

          const SizedBox(height: 24),

          // ===============================
          // CLASS OVERVIEW
          // ===============================
          const _SectionHeader(title: 'Class Overview'),
          const SizedBox(height: 8),

          _StatusTile(title: 'Pending Complaints', value: '2'),
          _StatusTile(title: 'Active Notices', value: '4'),
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
