import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:instru_connect/config/routes/route_names.dart';
import 'package:instru_connect/core/demo/demo_account.dart';
import 'package:instru_connect/core/services/auth/auth_service.dart';
import 'package:instru_connect/core/services/session_cache_service.dart';
import 'package:instru_connect/core/widgets/animated_splash_loader.dart';
import 'package:instru_connect/features/profile/screens/profile_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  void _handleNavigation(User? user) {
    if (_navigated || !mounted) return;
    _navigated = true;

    Future<void>(() async {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<User?>(
        stream: AuthService().authStateChanges(),
        builder: (context, snapshot) {
          // ================= LOADING =================
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AnimatedSplashLoader();
          }

          if (kDebugMode) {
            debugPrint('SPLASH: user = ${snapshot.data}');
          }

          // ================= NAVIGATION =================
          _handleNavigation(snapshot.data);

          // ================= FALLBACK UI =================
          return const AnimatedSplashLoader();
        },
      ),
    );
  }
}
