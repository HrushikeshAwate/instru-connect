import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:instru_connect/config/routes/route_names.dart';
import 'package:instru_connect/core/demo/demo_account.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instru_connect/core/providers/app_providers.dart';
import 'package:instru_connect/core/services/session_cache_service.dart';
import 'package:instru_connect/core/widgets/animated_splash_loader.dart';
import 'package:instru_connect/features/profile/screens/profile_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const Duration _minimumSplashDuration = Duration(milliseconds: 1200);

  late final DateTime _startedAt;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
  }

  void _scheduleNavigation(User? user) {
    if (_navigated || !mounted) return;
    _navigated = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_handleNavigation(user));
    });
  }

  Future<void> _handleNavigation(User? user) async {
    await _waitForMinimumSplash();
    if (!mounted) return;
    if (user == null) {
      Navigator.pushReplacementNamed(context, Routes.login);
      return;
    }

    if (DemoAccount.isDemoEmail(user.email)) {
      Navigator.pushReplacementNamed(context, Routes.roleLoading);
      return;
    }

    final cachedSession = await SessionCacheService.instance.loadForUid(
      user.uid,
    );
    if (!mounted) return;

    if (cachedSession == null) {
      Navigator.pushReplacementNamed(context, Routes.roleLoading);
      return;
    }

    cachedSession.applyToCurrentUser();

    if (cachedSession.profileComplete) {
      Navigator.pushReplacementNamed(context, cachedSession.homeRoute);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          forceCompletion: true,
          completionRoute: cachedSession.homeRoute,
        ),
      ),
    );
  }

  Future<void> _waitForMinimumSplash() async {
    final elapsed = DateTime.now().difference(_startedAt);
    final remaining = _minimumSplashDuration - elapsed;
    if (!remaining.isNegative) {
      await Future<void>.delayed(remaining);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: authState.when(
        data: (user) {
          if (kDebugMode) {
            debugPrint('SPLASH: user = $user');
          }

          _scheduleNavigation(user);
          return const AnimatedSplashLoader();
        },
        loading: () => const AnimatedSplashLoader(),
        error: (_, __) => const AnimatedSplashLoader(),
      ),
    );
  }
}
