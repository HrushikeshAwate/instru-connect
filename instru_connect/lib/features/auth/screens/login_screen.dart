import 'package:flutter/material.dart';
import 'package:instru_connect/core/services/auth/auth_service.dart';

// import '../../../core/services/auth_service.dart';
import '../../../core/widgets/loading_view.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  bool _loading = false;

  Future<void> _loginWithMicrosoft() async {
    setState(() => _loading = true);

    try {
      await _authService.signInWithMicrosoft();
      // ⛔ NO NAVIGATION
      // SplashScreen listens to authStateChanges
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingView(message: 'Signing in...');
    }

    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: _loginWithMicrosoft,
          child: const Text('Sign in with College Email'),
        ),
      ),
    );
  }
}
