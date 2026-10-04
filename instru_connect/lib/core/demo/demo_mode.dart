import 'package:firebase_auth/firebase_auth.dart';
import 'package:instru_connect/core/demo/demo_account.dart';
import 'package:instru_connect/core/session/current_user.dart';

class DemoMode {
  static bool get isActive {
    return DemoAccount.isDemoEmail(FirebaseAuth.instance.currentUser?.email) ||
        DemoAccount.isDemoEmail(CurrentUser.email);
  }

  static void ensureCanWrite() {
    if (isActive) {
      throw Exception('App Review Demo is view-only.');
    }
  }
}
