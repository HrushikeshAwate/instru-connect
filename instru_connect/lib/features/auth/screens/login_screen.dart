import 'package:flutter/material.dart';
import 'package:instru_connect/core/services/auth/auth_service.dart';
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // =============================================
            // APP / DEPARTMENT IDENTITY
            // =============================================
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),

            Text(
              'InstruConnect',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),

            Text(
              'Department App',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 40),

            // =============================================
            // LOGIN BUTTON
            // =============================================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loginWithMicrosoft,
                child: const Text('Sign in with College Email'),
              ),
            ),

            const SizedBox(height: 16),

            // =============================================
            // HELPER TEXT
            // =============================================
            Text(
              'Use your official college Microsoft account',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
