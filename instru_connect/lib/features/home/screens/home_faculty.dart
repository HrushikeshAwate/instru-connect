import 'package:flutter/material.dart';
import 'package:instru_connect/core/widgets/quick_actions/quick_action_tile.dart';
import 'package:instru_connect/features/complaints/screens/complaint_list_screen.dart';
import 'package:instru_connect/features/notices/screens/create_notice_screen.dart';
import 'package:instru_connect/features/notices/screens/notice_list_screen.dart';
import 'package:instru_connect/features/profile/screens/profile_screen.dart';
// import 'package:icconnect/features/resources/screens/study_resources_screen.dart';
// import 'package:icconnect/features/timetable/screens/timetable_screen.dart';

class HomeFaculty extends StatelessWidget {
  const HomeFaculty({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Home'),
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
          const _SectionHeader(title: 'Quick Actions'),
          const SizedBox(height: 12),

          QuickActionTile(
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

          QuickActionTile(
            icon: Icons.folder_outlined,
            title: 'Study Resources',
            onTap: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (_) => const StudyResourcesScreen(),
              //   ),
              // );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Study resources coming soon')),
              );
            },
          ),

          QuickActionTile(
            icon: Icons.schedule_outlined,
            title: 'Timetable',
            onTap: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (_) => const TimetableScreen(),
              //   ),
              // );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Timetable coming soon')),
              );
            },
          ),

          QuickActionTile(
            icon: Icons.report_problem_outlined,
            title: 'Complaints',
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
          // RECENT NOTICES
          // ===============================
          const _SectionHeader(title: 'Recent Notices'),
          const SizedBox(height: 8),

          _NoticePreviewTile(
            title: 'Assignment submission deadline',
            subtitle: 'Posted today',
          ),
          _NoticePreviewTile(
            title: 'Internal assessment schedule',
            subtitle: 'This week',
          ),

          TextButton(
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

          const SizedBox(height: 24),

          // ===============================
          // COMPLAINTS OVERVIEW
          // ===============================
          const _SectionHeader(title: 'Complaints Overview'),
          const SizedBox(height: 8),

          _StatusTile(
            title: 'Pending Complaints',
            value: '3',
          ),
          _StatusTile(
            title: 'Resolved Complaints',
            value: '12',
          ),
        ],
      ),
    );
  }
}

// =======================================================
// LOCAL SUPPORTING WIDGETS
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

class _NoticePreviewTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _NoticePreviewTile({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const NoticeListScreen(),
          ),
        );
      },
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
