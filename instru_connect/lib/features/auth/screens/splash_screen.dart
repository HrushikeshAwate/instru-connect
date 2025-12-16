import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:instru_connect/config/routes/route_names.dart';
import 'package:instru_connect/core/services/auth/auth_service.dart';
import 'package:instru_connect/core/widgets/loading_view.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }
        if (kDebugMode) {
          print('SPLASH: snapshot.connectionState = ${snapshot.connectionState}');
        }
        if (snapshot.data == null) {
          Future.microtask(() {
            Navigator.pushReplacementNamed(context, Routes.login);
          });
        } else {
          Future.microtask(() {
            Navigator.pushReplacementNamed(
              context,
              Routes.roleLoading,
            );
          });
        }
        if (kDebugMode) {
          print('SPLASH: snapshot.user = ${snapshot.data}');
        }


        return const SizedBox.shrink();
      },
    );
  }
}
