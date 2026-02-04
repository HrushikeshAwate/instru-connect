// features/home/screens/home_student.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instru_connect/config/routes/route_names.dart';
import 'package:instru_connect/config/theme/ui_colors.dart';
import 'package:instru_connect/features/auth/screens/log_out_screens.dart';
import 'package:instru_connect/features/complaints/screens/create_complaint_screen.dart';
import 'package:instru_connect/features/home/screens/home_image_carousel.dart';
import 'package:instru_connect/features/notices/screens/notice_list_screen.dart';
// ADDED THIS IMPORT
import 'package:instru_connect/features/timetable/screens/timetable_screen.dart';

class HomeStudent extends StatelessWidget {
  const HomeStudent({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId =
        FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: UIColors.background,
      body: Stack(
        children: [
          // =========================
          // HERO GRADIENT HEADER
          // =========================
          Container(
            height: 260,
            decoration: const BoxDecoration(
              gradient: UIColors.heroGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(42),
                bottomRight: Radius.circular(42),
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
                            'Student Portal',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Instrumentation & Control',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.person_outline,
                            color: Colors.white),
                        onPressed: () =>
                            Navigator.pushNamed(context, Routes.profile),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded,
                            color: Colors.white),
                        onPressed: () => showLogoutDialog(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                const HomeImageCarousel(),
                const SizedBox(height: 28),

                // =========================
                // ATTENDANCE (LIVE)
                // =========================
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUserId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData ||
                        !snapshot.data!.exists) {
                      return const SizedBox.shrink();
                    }

                    final data =
                    snapshot.data!.data() as Map<String, dynamic>;
                    final int total = data['totalClasses'] ?? 0;
                    final int attended =
                        data['attendedClasses'] ?? 0;
                    final double percentage = total == 0
                        ? 0
                        : (attended / total) * 100;
                    final bool isLow = percentage < 75;

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: isLow
                            ? UIColors.errorGradient
                            : UIColors.successGradient,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color:
                            Colors.black.withOpacity(0.22),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 56,
                                width: 56,
                                child: CircularProgressIndicator(
                                  value: percentage / 100,
                                  strokeWidth: 6,
                                  backgroundColor:
                                  Colors.white24,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'My Attendance',
                                      style: TextStyle(
                                        fontWeight:
                                        FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      '$attended / $total Classes Attended',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          if (isLow) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding:
                              const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withOpacity(0.18),
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons
                                        .warning_amber_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Low Attendance: Below 75%',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight:
                                        FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 36),

                const _SectionHeader(
                  title: 'Quick Actions',
                  subtitle: 'Academic & support essentials',
                ),
                const SizedBox(height: 16),

                // =========================
                // ACTION GRID
                // =========================
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  shrinkWrap: true,
                  physics:
                  const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.3,
                  children: [
                    _ActionCard(
                      icon: Icons.campaign_outlined,
                      label: 'Notices',
                      gradient: UIColors.primaryGradient,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const NoticeListScreen(),
                        ),
                      ),
                    ),
                    _ActionCard(
                      icon: Icons.menu_book_outlined,
                      label: 'Resources',
                      gradient: UIColors.secondaryGradient,
                      onTap: () =>
                          Navigator.pushNamed(
                              context, Routes.resources),
                    ),
                    _ActionCard(
                      icon: Icons.schedule_outlined,
                      label: 'Timetable',
                      gradient: UIColors.secondaryGradient,
                      // FIXED: Added Navigation logic
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TimetableScreen(),
                          ),
                        );
                      },
                    ),
                    _ActionCard(
                      icon: Icons.report_problem_outlined,
                      label: 'Support',
                      gradient: UIColors.warningGradient,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const CreateComplaintScreen(),
                        ),
                      ),
                    ),
                    _ActionCard(
                      icon: Icons.calendar_month,
                      label: 'Event Calendar',
                      gradient: UIColors.primaryGradient,
                      onTap: () => Navigator.pushNamed(
                          context, Routes.eventCalendar),
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                const _SectionHeader(
                  title: "Today's Schedule",
                  subtitle: 'Instrumentation Dept.',
                ),
                const SizedBox(height: 16),

                // =========================
                // TIMETABLE PREVIEW
                // =========================
                Container(
                  decoration: BoxDecoration(
                    color: UIColors.surface,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color:
                        Colors.black.withOpacity(0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      _TimetableTile(
                        time: '10:00 AM',
                        subject: 'Control Systems',
                        room: 'Lab 101',
                      ),
                      Divider(height: 1),
                      _TimetableTile(
                        time: '11:15 AM',
                        subject: 'Microprocessors',
                        room: 'Class 204',
                      ),
                      Divider(height: 1),
                      _TimetableTile(
                        time: '02:00 PM',
                        subject: 'Industrial Automation',
                        room: 'Lab 103',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// UI COMPONENTS
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
            color: Colors.black.withOpacity(0.22),
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

class _TimetableTile extends StatelessWidget {
  final String time;
  final String subject;
  final String room;
  const _TimetableTile(
      {required this.time,
        required this.subject,
        required this.room});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      leading: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: UIColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          time,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: UIColors.primary,
          ),
        ),
      ),
      title: Text(
        subject,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        room,
        style: const TextStyle(
          fontSize: 12,
          color: UIColors.textSecondary,
        ),
      ),
    );
  }
}