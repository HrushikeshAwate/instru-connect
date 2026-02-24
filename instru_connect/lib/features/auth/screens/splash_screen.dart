import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:instru_connect/config/routes/route_names.dart';
import 'package:instru_connect/core/services/auth/auth_service.dart';
import 'package:instru_connect/config/theme/ui_colors.dart';

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
            return _SplashUI();
          }

          if (kDebugMode) {
            debugPrint('SPLASH: user = ${snapshot.data}');
          }

          // ================= NAVIGATION =================
          _handleNavigation(context, snapshot.data);

          // ================= FALLBACK UI =================
          return _SplashUI();
        },
      ),
    );
  }
}

// =======================================================
// SPLASH UI (VISIBLE WHILE AUTH RESOLVES)
// =======================================================

class _SplashUI extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ================= LOGO =================
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              gradient: UIColors.heroGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school_outlined,
              size: 46,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 24),

          // ================= TITLE =================
          Text(
            'InstruConnect',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          Text(
            'Instrumentation Department',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),

          const SizedBox(height: 32),

          // ================= LOADER =================
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }
}
