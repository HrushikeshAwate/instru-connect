import 'package:flutter/material.dart';
// import 'package:instru_connect/core/bootstrap/user_context.dart';
import 'package:instru_connect/core/services/auth/auth_service.dart';
import 'package:instru_connect/core/services/firestore_service.dart';
import 'package:instru_connect/core/services/role_service.dart';
import 'package:instru_connect/core/sessioin/current_user.dart';
import 'package:instru_connect/core/widgets/error_view.dart';
import 'package:instru_connect/core/widgets/loading_view.dart';
import 'package:instru_connect/core/services/notification_token_service.dart';
import 'package:instru_connect/features/home/home_router.dart';
import 'package:instru_connect/features/profile/screens/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      final role = (userDoc['role'] ?? '').toString().toLowerCase();
      final homeRoute = HomeRouter.routeForRole(userDoc['role']);

      // 🔑 STORE SESSION DATA
      CurrentUser.uid = user.uid;
      CurrentUser.role = role;
      CurrentUser.batchId = userDoc['batchId'];
      CurrentUser.academicYear = userDoc['academicYear'];
      CurrentUser.email = userDoc['email'];
      CurrentUser.name = userDoc['name'];

      await NotificationTokenService().registerToken(user.uid);

      if (!mounted) return;

      final incomplete = await _isProfileIncomplete(user.uid, role);
      if (!mounted) return;

      if (incomplete) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(
              forceCompletion: true,
              completionRoute: homeRoute,
            ),
          ),
        );
        return;
      }

      Navigator.pushReplacementNamed(context, homeRoute);
    } catch (e) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ErrorView(message: e.toString())),
      );
    }
  }

  Future<bool> _isProfileIncomplete(String uid, String role) async {
    final profileRef = FirebaseFirestore.instance
        .collection('profiles')
        .doc(uid);
    final profileDoc = await profileRef.get();

    if (!profileDoc.exists) {
      await profileRef.set({
        'uid': uid,
        'name': CurrentUser.name ?? '',
        'email': CurrentUser.email ?? '',
        'misNo': null,
        'department': null,
        'batchId': CurrentUser.batchId,
        'coCurricular': null,
        'contactNo': null,
        'parentContactNo': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    }

    final data = profileDoc.data() ?? <String, dynamic>{};
    final department = (data['department'] ?? '').toString().trim();
    final coCurricular = (data['coCurricular'] ?? '').toString().trim();
    final contactNo = (data['contactNo'] ?? '').toString().trim();
    final misNo = (data['misNo'] ?? '').toString().trim();
    final parentContactNo = (data['parentContactNo'] ?? '').toString().trim();

    final needsStudentFields = role == 'student' || role == 'cr';

    if (department.isEmpty || coCurricular.isEmpty || contactNo.isEmpty) {
      return true;
    }

    if (needsStudentFields && (misNo.isEmpty || parentContactNo.isEmpty)) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return const LoadingView(message: 'Setting things up...');
  }
}
