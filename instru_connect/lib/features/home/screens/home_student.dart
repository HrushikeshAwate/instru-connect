import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    // Get the current user ID to fetch attendance live
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
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
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 1. TOP CAROUSEL
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              children: const [HomeImageCarousel(), SizedBox(height: 20)],
            ),
          ),

          // 2. LIVE ATTENDANCE TRACKER
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUserId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const SizedBox.shrink();
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final int total = data['totalClasses'] ?? 0;
              final int attended = data['attendedClasses'] ?? 0;
              final double percentage = total == 0 ? 0.0 : (attended / total) * 100;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey.shade200,
                              color: percentage < 75 ? Colors.red : Colors.green,
                            ),
                            const Icon(Icons.percent, size: 12),
                          ],
                        ),
                        title: const Text(
                          "Your Attendance",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("$attended / $total Classes Attended"),
                        trailing: Text(
                          "${percentage.toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: percentage < 75 ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                    ),
                    if (total > 0 && percentage < 75)
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.warning_amber_rounded, color: Colors.red),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Warning: Below 75%! Please attend classes regularly.",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),

          // 3. CONTENT
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
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
                          MaterialPageRoute(builder: (_) => const NoticeListScreen()),
                        );
                      },
                    ),
                    _ActionCard(
                      icon: Icons.schedule_outlined,
                      label: 'Timetable',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Timetable coming soon')),
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
                const _SectionHeader(
                  title: "Today's Timetable",
                  subtitle: 'Your classes for today',
                ),
                const SizedBox(height: 14),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: const [
                      _TimetableTile(time: '10:00 – 11:00', subject: 'Control Systems'),
                      Divider(height: 1),
                      _TimetableTile(time: '11:15 – 12:15', subject: 'Instrumentation'),
                      Divider(height: 1),
                      _TimetableTile(time: '2:00 – 4:00', subject: 'Lab Session'),
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
                const _SectionHeader(
                  title: 'Support',
                  subtitle: 'Need help?',
                ),
                const SizedBox(height: 14),
                _SupportCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CreateComplaintScreen()),
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

// --- Helper classes ---

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
  const _ActionCard({required this.icon, required this.label, required this.onTap});
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
              Icon(icon, size: 30, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 14),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
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