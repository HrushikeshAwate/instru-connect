// features/home/screens/home_staff.dart

import 'package:flutter/material.dart';
import 'package:instru_connect/config/routes/route_names.dart';
import 'package:instru_connect/config/theme/ui_colors.dart';
import 'package:instru_connect/core/widgets/app_ui.dart';
import 'package:instru_connect/features/complaints/screens/create_complaint_screen.dart';
import 'package:instru_connect/features/complaints/screens/complaint_list_screen.dart';
import 'package:instru_connect/features/home/screens/home_image_carousel.dart';
import 'package:instru_connect/features/notices/screens/notice_list_screen.dart';
// ADDED THIS IMPORT
import 'package:instru_connect/features/timetable/screens/timetable_screen.dart';
import 'package:instru_connect/core/widgets/notification_bell.dart';

class HomeStaff extends StatelessWidget {
  const HomeStaff({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const AppHeroBackground(height: 232),

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
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'InstruConnect',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Staff',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
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

                const SizedBox(height: 36),

                const AppSectionHeader(
                  title: 'Staff Panel',
                  subtitle: 'Assigned responsibilities & updates',
                ),
                const SizedBox(height: 16),

                AppActionGrid(
                  children: [
                    AppActionTile(
                      icon: Icons.build_circle_outlined,
                      label: 'Complaints',
                      gradient: UIColors.tileGradient(0),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ComplaintListScreen(),
                        ),
                      ),
                    ),
                    AppActionTile(
                      icon: Icons.add_comment_outlined,
                      label: 'Raise Complaint',
                      gradient: UIColors.tileGradient(1),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateComplaintScreen(),
                        ),
                      ),
                    ),
                    AppActionTile(
                      icon: Icons.campaign_outlined,
                      label: 'Notices',
                      gradient: UIColors.tileGradient(2),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NoticeListScreen(),
                        ),
                      ),
                    ),
                    // FIXED: UPDATED TIMETABLE ACTION
                    AppActionTile(
                      icon: Icons.calendar_month_rounded,
                      label: 'Timetable',
                      gradient: UIColors.tileGradient(3),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TimetableScreen(),
                          ),
                        );
                      },
                    ),
                    AppActionTile(
                      icon: Icons.folder_open_rounded,
                      label: 'Resources',
                      gradient: UIColors.tileGradient(4),
                      onTap: () =>
                          Navigator.pushNamed(context, Routes.resources),
                    ),
                    AppActionTile(
                      icon: Icons.calendar_today_outlined,
                      label: 'Event Calendar',
                      gradient: UIColors.tileGradient(5),
                      onTap: () =>
                          Navigator.pushNamed(context, Routes.eventCalendar),
                    ),
                  ],
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
