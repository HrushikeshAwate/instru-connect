import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:instru_connect/config/routes/route_names.dart';
import 'package:instru_connect/core/services/auth/auth_service.dart';
import 'package:instru_connect/core/widgets/animated_splash_loader.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  void _handleNavigation(BuildContext context, User? user) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (user == null) {
        Navigator.pushReplacementNamed(context, Routes.login);
      } else {
        Navigator.pushReplacementNamed(context, Routes.roleLoading);
      }
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
          _handleNavigation(context, snapshot.data);

          // ================= FALLBACK UI =================
          return const AnimatedSplashLoader();
        },
      ),
    );
  }
}
