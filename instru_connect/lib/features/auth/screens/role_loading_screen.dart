import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:instru_connect/core/bootstrap/user_context.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instru_connect/config/routes/route_names.dart';
import 'package:instru_connect/core/constants/app_roles.dart';
import 'package:instru_connect/core/demo/demo_account.dart';
import 'package:instru_connect/core/providers/app_providers.dart';
import 'package:instru_connect/core/services/auth/auth_service.dart';
import 'package:instru_connect/core/services/session_cache_service.dart';
import 'package:instru_connect/core/session/current_user.dart';
import 'package:instru_connect/core/widgets/error_view.dart';
import 'package:instru_connect/core/widgets/animated_splash_loader.dart';
import 'package:instru_connect/features/home/home_router.dart';
import 'package:instru_connect/features/profile/screens/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoleLoadingScreen extends ConsumerStatefulWidget {
  const RoleLoadingScreen({super.key});

  @override
  ConsumerState<RoleLoadingScreen> createState() => _RoleLoadingScreenState();
}

class _RoleLoadingScreenState extends ConsumerState<RoleLoadingScreen> {
  static const Duration _minimumLoadingDuration = Duration(milliseconds: 1000);
  static const Duration _authSettleTimeout = Duration(seconds: 3);

  late final DateTime _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _resolve();
  }

  Future<void> _resolve() async {
    try {
      final auth = ref.read(authServiceProvider);
      final firestore = ref.read(userBootstrapRepositoryProvider);
      final roleService = ref.read(roleServiceProvider);

      final user = auth.currentUser ?? await _waitForSignedInUser();
      if (user == null) {
        await _waitForMinimumLoading();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, Routes.login, (_) => false);
        return;
      }
      final email = user.email?.trim().toLowerCase();
      if (!AuthService.isAllowedCollegeEmail(email)) {
        await auth.signOut();
        throw Exception('Only official college email accounts are allowed.');
      }

      final isDemoAccount = DemoAccount.isDemoEmail(email);
      final bootstrappedUserDoc = await firestore.getOrCreateUser(
        firebaseUser: auth.currentUser ?? user,
      );

      final userDoc = isDemoAccount
          ? bootstrappedUserDoc
          : await roleService.fetchFullUser(user.uid);
      final role = (userDoc['role'] ?? '').toString().toLowerCase();
      final homeRoute = HomeRouter.routeForRole(
        isDemoAccount ? AppRoles.admin : role,
      );

      // 🔑 STORE SESSION DATA
      CurrentUser.uid = user.uid;
      CurrentUser.role = role;
      CurrentUser.batchId = userDoc['batchId'];
      CurrentUser.academicYear = userDoc['academicYear'];
      CurrentUser.email = userDoc['email'];
      CurrentUser.name = userDoc['name'];

      if (isDemoAccount) {
        await _ensureDemoProfile(user.uid);
      }

      final incomplete = isDemoAccount
          ? false
          : await _isProfileIncomplete(user.uid, role);
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
      if (!mounted) return;

      unawaited(_registerNotificationToken(user.uid));
      await _waitForMinimumLoading();
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
      if (!mounted) return;
      await _waitForMinimumLoading();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ErrorView(message: e.toString())),
      );
    }
  }

  Future<User?> _waitForSignedInUser() async {
    try {
      return await ref
          .read(authServiceProvider)
          .authStateChanges()
          .firstWhere((user) => user != null)
          .timeout(_authSettleTimeout);
    } on TimeoutException {
      return ref.read(authServiceProvider).currentUser;
    }
  }

  Future<void> _registerNotificationToken(String uid) async {
    try {
      await ref.read(notificationTokenServiceProvider).registerToken(uid);
    } catch (_) {
      // Notifications should never block a successful login.
    }
  }

  Future<void> _waitForMinimumLoading() async {
    final elapsed = DateTime.now().difference(_startedAt);
    final remaining = _minimumLoadingDuration - elapsed;
    if (!remaining.isNegative) {
      await Future<void>.delayed(remaining);
    }
  }

  Future<void> _ensureDemoProfile(String uid) async {
    final profileRef = ref
        .read(firebaseFirestoreProvider)
        .collection('profiles')
        .doc(uid);

    await profileRef.set({
      'uid': uid,
      'name': DemoAccount.name,
      'email': DemoAccount.email,
      'misNo': DemoAccount.misNo,
      'department': DemoAccount.department,
      'batchId': CurrentUser.batchId,
      'coCurricular': 'Demo profile for App Review',
      'contactNo': DemoAccount.contactNo,
      'parentContactNo': DemoAccount.parentContactNo,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> _isProfileIncomplete(String uid, String role) async {
    final profileRef = ref
        .read(firebaseFirestoreProvider)
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
    return const Scaffold(body: AnimatedSplashLoader());
  }
}
