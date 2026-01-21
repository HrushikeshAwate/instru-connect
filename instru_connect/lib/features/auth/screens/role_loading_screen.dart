import 'package:flutter/material.dart';
// import 'package:instru_connect/core/bootstrap/user_context.dart';
import 'package:instru_connect/core/services/auth/auth_service.dart';
import 'package:instru_connect/core/services/firestore_service.dart';
import 'package:instru_connect/core/services/role_service.dart';
import 'package:instru_connect/core/sessioin/current_user.dart';
import 'package:instru_connect/core/widgets/error_view.dart';
import 'package:instru_connect/core/widgets/loading_view.dart';
import 'package:instru_connect/features/home/home_router.dart';

class RoleLoadingScreen extends StatefulWidget {
  const RoleLoadingScreen({super.key});

  @override
  State<RoleLoadingScreen> createState() => _RoleLoadingScreenState();
}

class _RoleLoadingScreenState extends State<RoleLoadingScreen> {
  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
  try {
    final auth = AuthService();
    final firestore = FirestoreService();
    final roleService = RoleService();

    final user = auth.currentUser!;
    await firestore.getOrCreateUser(firebaseUser: user);

    final userDoc = await roleService.fetchFullUser(user.uid);

    // 🔑 STORE SESSION DATA
    CurrentUser.uid = user.uid;
    CurrentUser.role = userDoc['role'];
    CurrentUser.batchId = userDoc['batchId'];
    CurrentUser.academicYear = userDoc['academicYear'];
    CurrentUser.email = userDoc['email'];
    CurrentUser.name = userDoc['name'];

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      HomeRouter.routeForRole(userDoc['role']),
    );
  } catch (e) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ErrorView(message: e.toString()),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return const LoadingView(
      message: 'Setting things up...',
    );
  }
}
