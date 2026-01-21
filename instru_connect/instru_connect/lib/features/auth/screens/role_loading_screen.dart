import 'package:flutter/material.dart';
import 'package:instru_connect/core/services/auth/auth_service.dart';
import 'package:instru_connect/core/services/firestore_service.dart';
import 'package:instru_connect/core/services/role_service.dart';
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

      final role = await roleService.fetchUserRole(user.uid);

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        HomeRouter.routeForRole(role),
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
