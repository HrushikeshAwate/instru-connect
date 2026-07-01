import 'package:flutter/material.dart';
import 'package:instru_connect/features/admin/screens/admin_dashboard.dart';
import 'package:instru_connect/features/batches/screens/manage_batches_screen.dart';
import 'package:instru_connect/features/complaints/screens/complaint_list_screen.dart';
import 'package:instru_connect/features/events/screens/event_calendar_screen.dart';
import 'package:instru_connect/features/home/screens/home_staff.dart';
import 'package:instru_connect/features/notices/screens/create_notice_screen.dart';
import 'package:instru_connect/features/profile/screens/profile_screen.dart';
import 'package:instru_connect/features/resources/screens/add_resource_screen.dart';
import 'package:instru_connect/features/resources/screens/resource_detail_screen.dart';
import 'package:instru_connect/features/resources/screens/resource_list_screen.dart';
import 'package:instru_connect/features/notifications/screens/notifications_screen.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/role_loading_screen.dart';

import '../../features/home/screens/home_student.dart';
import '../../features/home/screens/home_cr.dart';
import '../../features/home/screens/home_faculty.dart';

import 'route_names.dart';

class AppRouter {
  static bool isKnownRoute(String? routeName) {
    return routeName == Routes.splash ||
        routeName == Routes.login ||
        routeName == Routes.roleLoading ||
        routeName == Routes.homeStudent ||
        routeName == Routes.homeCr ||
        routeName == Routes.homeFaculty ||
        routeName == Routes.homeAdmin ||
        routeName == Routes.homeStaff ||
        routeName == Routes.profile ||
        routeName == Routes.createNotice ||
        routeName == Routes.eventCalendar ||
        routeName == Routes.complaints ||
        routeName == Routes.notifications ||
        routeName == Routes.resources ||
        routeName == Routes.resourceDetail ||
        routeName == Routes.addResource ||
        routeName == Routes.manageBatches;
  }

  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      // ─── AUTH ────────────────────────────────
      case Routes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case Routes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case Routes.roleLoading:
        return MaterialPageRoute(builder: (_) => const RoleLoadingScreen());

      // ─── HOMES ───────────────────────────────
      case Routes.homeStudent:
        return MaterialPageRoute(builder: (_) => const HomeStudent());

      case Routes.homeCr:
        return MaterialPageRoute(builder: (_) => const HomeCr());

      case Routes.homeFaculty:
        return MaterialPageRoute(builder: (_) => const HomeFaculty());

      case Routes.homeAdmin:
        return MaterialPageRoute(builder: (_) => const AdminDashboardView());
      case Routes.homeStaff:
        return MaterialPageRoute(builder: (_) => const HomeStaff());
      case Routes.profile:
        return MaterialPageRoute(builder: (_) => ProfileScreen());

      case Routes.createNotice:
        return MaterialPageRoute(
          builder: (_) => CreateNoticeScreen(showBatchSelector: true),
        );

      case Routes.eventCalendar:
        return MaterialPageRoute(builder: (_) => const EventCalendarScreen());

      case Routes.complaints:
        return MaterialPageRoute(builder: (_) => const ComplaintListScreen());

      case Routes.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      // Resources routes can be added here
      case Routes.resources:
        return MaterialPageRoute(builder: (_) => ResourceListScreen());

      case Routes.resourceDetail:
        return MaterialPageRoute(
          builder: (_) => const ResourceDetailScreen(),
          settings: settings, // 🔥 REQUIRED (keeps arguments)
        );

      case Routes.addResource:
        return MaterialPageRoute(builder: (_) => AddResourceScreen());

      // ─── BATCHES ─────────────────────────────
      case Routes.manageBatches:
        return MaterialPageRoute(builder: (_) => ManageBatchesScreen());

      // ─── FALLBACK ────────────────────────────
      default:
        return MaterialPageRoute(builder: (_) => const RoleLoadingScreen());
    }
  }
}
