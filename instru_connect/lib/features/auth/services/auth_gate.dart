import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 1. Correct path to Login
import '../screens/login_screen.dart';
// 2. Correct path to RoleLoadingScreen (the bridge between Auth and Home)
import '../screens/role_loading_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If logged in, go to RoleLoadingScreen.
        // This screen will use your HomeRouter.routeForRole logic to find the right department.
        if (snapshot.hasData) {
          return const RoleLoadingScreen();
        }

        return const LoginScreen();
      },
    );
  }
}