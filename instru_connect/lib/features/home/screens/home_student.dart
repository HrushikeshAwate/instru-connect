import 'package:flutter/material.dart';
import 'package:instru_connect/core/widgets/quick_actions/quick_action_tile.dart';
import 'package:instru_connect/features/complaints/screens/complaint_list_screen.dart';
import 'package:instru_connect/features/notices/screens/notice_list_screen.dart';
import 'package:instru_connect/features/profile/screens/profile_screen.dart';

class HomeStudent extends StatelessWidget {
  const HomeStudent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
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
            icon: Icons.campaign,
            title: 'Notices',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NoticeListScreen()),
              );
            },
          ),

          QuickActionTile(
            icon: Icons.schedule,
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
            icon: Icons.menu_book,
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
            icon: Icons.report_problem,
            title: 'Complaints',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ComplaintListScreen()),
              );
            },
          ),

          QuickActionTile(
            icon: Icons.event,
            title: 'Events',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Events coming soon')),
              );
            },
          ),

          const SizedBox(height: 24),

          // ===============================
          // TODAY'S TIMETABLE PREVIEW
          // ===============================
          const _SectionHeader(title: "Today's Timetable"),
          const SizedBox(height: 8),

          _TimetablePreviewTile(
            time: '10:00 – 11:00',
            subject: 'Control Systems',
          ),
          _TimetablePreviewTile(
            time: '11:15 – 12:15',
            subject: 'Instrumentation',
          ),
          _TimetablePreviewTile(time: '2:00 – 4:00', subject: 'Lab Session'),

          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Open full timetable')),
              );
            },
            child: const Text('View full timetable'),
          ),

          const SizedBox(height: 24),

          const SizedBox(height: 24),

          // ===============================
          // STUDY RESOURCES PREVIEW
          // ===============================
          const _SectionHeader(title: 'Study Resources'),
          const SizedBox(height: 8),

          _ResourcePreviewTile(
            title: 'Control Systems – Unit 3 Notes',
            subtitle: 'PDF • Uploaded yesterday',
          ),
          _ResourcePreviewTile(
            title: 'Instrumentation Lab Manual',
            subtitle: 'PDF • Updated this week',
          ),
          _ResourcePreviewTile(
            title: 'Signals & Systems – Reference Book',
            subtitle: 'Link • Google Drive',
          ),

          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Open all study resources')),
              );
            },
            child: const Text('View all resources'),
          ),

          // ===============================
          // LATEST NOTICES PREVIEW
          // ===============================
          const _SectionHeader(title: 'Latest Notices'),
          const SizedBox(height: 8),

          _NoticePreviewTile(
            title: 'Mid-semester exam schedule',
            subtitle: 'Published today',
          ),
          _NoticePreviewTile(
            title: 'Workshop on AI & ML',
            subtitle: 'Tomorrow',
          ),

          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NoticeListScreen()),
              );
            },
            child: const Text('View all notices'),
          ),

          const SizedBox(height: 24),

          // ===============================
          // SUPPORT
          // ===============================
          const _SectionHeader(title: 'Support'),
          const SizedBox(height: 12),

          QuickActionTile(
            icon: Icons.help_outline,
            title: 'Need help? Raise a complaint',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ComplaintListScreen()),
              );
            },
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
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _NoticePreviewTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _NoticePreviewTile({required this.title, required this.subtitle});

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
          MaterialPageRoute(builder: (_) => const NoticeListScreen()),
        );
      },
    );
  }
}

class _TimetablePreviewTile extends StatelessWidget {
  final String time;
  final String subject;

  const _TimetablePreviewTile({required this.time, required this.subject});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.class_),
      title: Text(subject),
      subtitle: Text(time),
    );
  }
}

class _ResourcePreviewTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ResourcePreviewTile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.description),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Open resource')));
      },
    );
  }
}
