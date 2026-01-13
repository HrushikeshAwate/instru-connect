import 'package:flutter/material.dart';
import 'package:instru_connect/config/routes/route_names.dart';
import 'package:instru_connect/config/theme/ui_colors.dart';
import 'package:instru_connect/features/auth/screens/log_out_screens.dart';
import 'package:instru_connect/features/complaints/screens/complaint_list_screen.dart';
import 'package:instru_connect/features/complaints/screens/create_complaint_screen.dart';
import 'package:instru_connect/features/complaints/services/complaint_service.dart';
import 'package:instru_connect/features/home/screens/home_image_carousel.dart';
import 'package:instru_connect/features/notices/screens/notice_list_screen.dart';

class HomeStudent extends StatelessWidget {
  const HomeStudent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
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

      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // =================================================
          // TOP CAROUSEL (SAME ACROSS ALL ROLES)
          // =================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              children: const [HomeImageCarousel(), SizedBox(height: 20)],
            ),
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
                  subtitle: 'Common student activities',
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
                      label: 'Notices',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NoticeListScreen(),
                          ),
                        );
                      },
                    ),
                    _ActionCard(
                      icon: Icons.schedule_outlined,
                      label: 'Timetable',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Timetable coming soon'),
                          ),
                        );
                      },
                    ),
                    _ActionCard(
                      icon: Icons.menu_book_outlined,
                      label: 'Study Resources',
                      onTap: () {
                        Navigator.pushNamed(context, Routes.resources);
                      },
                    ),
                    _ActionCard(
                      icon: Icons.report_problem_outlined,
                      label: 'Complaints',
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
                      icon: Icons.event_outlined,
                      label: 'Events',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Events coming soon')),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                // ---------------------------------------------
                // TODAY'S TIMETABLE
                // ---------------------------------------------
                const _SectionHeader(
                  title: "Today's Timetable",
                  subtitle: 'Your classes for today',
                ),
                const SizedBox(height: 14),

                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: const [
                      _TimetableTile(
                        time: '10:00 – 11:00',
                        subject: 'Control Systems',
                      ),
                      Divider(height: 1),
                      _TimetableTile(
                        time: '11:15 – 12:15',
                        subject: 'Instrumentation',
                      ),
                      Divider(height: 1),
                      _TimetableTile(
                        time: '2:00 – 4:00',
                        subject: 'Lab Session',
                      ),
                    ],
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Open full timetable')),
                      );
                    },
                    child: const Text('View full timetable'),
                  ),
                ),

                const SizedBox(height: 36),

                // ---------------------------------------------
                // STUDY RESOURCES
                // ---------------------------------------------
                const _SectionHeader(
                  title: 'Study Resources',
                  subtitle: 'Recently added materials',
                ),
                const SizedBox(height: 14),

                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: const [
                      _ResourceTile(
                        title: 'Control Systems – Unit 3 Notes',
                        subtitle: 'PDF • Uploaded yesterday',
                      ),
                      Divider(height: 1),
                      _ResourceTile(
                        title: 'Instrumentation Lab Manual',
                        subtitle: 'PDF • Updated this week',
                      ),
                      Divider(height: 1),
                      _ResourceTile(
                        title: 'Signals & Systems – Reference Book',
                        subtitle: 'Link • Google Drive',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // ---------------------------------------------
                // LATEST NOTICES
                // ---------------------------------------------
                const _SectionHeader(
                  title: 'Latest Notices',
                  subtitle: 'Important announcements',
                ),
                const SizedBox(height: 14),

                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: const [
                      _NoticeTile(
                        title: 'Mid-semester exam schedule',
                        subtitle: 'Published today',
                      ),
                      Divider(height: 1),
                      _NoticeTile(
                        title: 'Workshop on AI & ML',
                        subtitle: 'Tomorrow',
                      ),
                    ],
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
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
                ),

                const SizedBox(height: 36),

                // ---------------------------------------------
                // SUPPORT
                // ---------------------------------------------
                const _SectionHeader(title: 'Support', subtitle: 'Need help?'),
                const SizedBox(height: 14),

                _SupportCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateComplaintScreen(),
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

class _TimetableTile extends StatelessWidget {
  final String time;
  final String subject;

  const _TimetableTile({required this.time, required this.subject});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.class_outlined),
      title: Text(subject),
      subtitle: Text(time),
    );
  }
}

class _ResourceTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ResourceTile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.description_outlined),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _NoticeTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _NoticeTile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _SupportCard extends StatelessWidget {
  final VoidCallback onTap;

  const _SupportCard({required this.onTap});

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
          leading: Icon(Icons.help_outline),
          title: Text('Need help?'),
          subtitle: Text('Raise a complaint or report an issue'),
          trailing: Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
