import 'package:flutter/material.dart';
import 'package:instru_connect/core/services/auth/auth_service.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../config/theme/ui_colors.dart';

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
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
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
      backgroundColor: UIColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ================= LOGO =================
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: UIColors.heroGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_outlined,
                  size: 42,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              // ================= TITLE =================
              Text(
                'InstruConnect',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              Text(
                'Instrumentation Department',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: UIColors.textSecondary),
              ),

              const SizedBox(height: 40),

              // ================= BUTTON =================
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text(
                    'Sign in with College Email',
                    style: TextStyle(fontSize: 15),
                  ),
                  onPressed: _loginWithMicrosoft,
                ),
              ),

              const SizedBox(height: 16),

              // ================= FOOTER =================
              Text(
                'Use your official Microsoft college account',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: UIColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
