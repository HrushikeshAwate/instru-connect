import '../../config/routes/route_names.dart';
import '../../core/constants/app_roles.dart';

class HomeRouter {
  static String routeForRole(String role) {
    switch (role) {
      case AppRoles.student:
        return Routes.homeStudent;
      case AppRoles.cr:
        return Routes.homeCr;
      case AppRoles.faculty:
        return Routes.homeFaculty;
      case AppRoles.staff:
        return Routes.homeStaff;
      case AppRoles.admin:
        return Routes.homeAdmin;
      default:
        return Routes.homeStudent; // SAFE fallback
    }
  }
}
