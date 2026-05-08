import 'dart:async';

import 'package:flutter/material.dart';
// import 'package:instru_connect/core/bootstrap/user_context.dart';
import 'package:instru_connect/core/services/auth/auth_service.dart';
import 'package:instru_connect/core/services/firestore_service.dart';
import 'package:instru_connect/core/services/session_cache_service.dart';
import 'package:instru_connect/core/services/role_service.dart';
import 'package:instru_connect/core/sessioin/current_user.dart';
import 'package:instru_connect/core/widgets/error_view.dart';
import 'package:instru_connect/core/widgets/animated_splash_loader.dart';
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

      final user = auth.currentUser;
      if (user == null) {
        throw Exception('Your session expired. Please sign in again.');
      }
      final email = user.email?.trim().toLowerCase();
      if (!AuthService.isAllowedCollegeEmail(email)) {
        await auth.signOut();
        throw Exception('Only official college email accounts are allowed.');
      }

      await firestore.getOrCreateUser(firebaseUser: auth.currentUser ?? user);

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

      final incomplete = await _isProfileIncomplete(user.uid, role);
      if (!mounted) return;

      await SessionCacheService.instance.saveResolvedSession(
        uid: user.uid,
        role: role,
        batchId: CurrentUser.batchId,
        academicYear: CurrentUser.academicYear,
        email: CurrentUser.email,
        name: CurrentUser.name,
        homeRoute: homeRoute,
        profileComplete: !incomplete,
      );

      unawaited(_registerNotificationToken(user.uid));

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
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ErrorView(message: e.toString())),
      );
    }
  }

  Future<void> _registerNotificationToken(String uid) async {
    try {
      await NotificationTokenService().registerToken(uid);
    } catch (_) {
      // Notifications should never block a successful login.
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
    final contactNo = (data['contactNo'] ?? '').toString().trim();
    final misNo = (data['misNo'] ?? '').toString().trim();
    final parentContactNo = (data['parentContactNo'] ?? '').toString().trim();

    final needsStudentFields = role == 'student' || role == 'cr';

    if (department.isEmpty || contactNo.isEmpty) {
      return true;
    }

    if (needsStudentFields && (misNo.isEmpty || parentContactNo.isEmpty)) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AnimatedSplashLoader(),
    );
  }
}
