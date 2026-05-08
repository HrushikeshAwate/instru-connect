// ignore_for_file: use_build_context_synchronously
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instru_connect/core/services/auth/auth_service.dart';
import 'package:instru_connect/core/widgets/loading_view.dart';

import '../../../config/routes/route_names.dart';
import '../../../config/theme/ui_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  StreamSubscription<User?>? _authSubscription;
  bool _loading = false;
  bool _redirecting = false;

  @override
  void initState() {
    super.initState();
    _redirectIfAuthenticated(_authService.currentUser);
    _authSubscription = _authService.authStateChanges().listen(
      _redirectIfAuthenticated,
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _redirectIfAuthenticated(User? user) {
    if (_redirecting || !mounted || user == null) return;
    _redirecting = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.roleLoading,
        (route) => false,
      );
    });
  }

  Future<void> _loginWithMicrosoft() async {
    if (_loading || _redirecting) return;
    setState(() => _loading = true);
    try {
      await _authService.signInWithMicrosoft();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? 'Could not sign in. Please try again in a moment.',
          ),
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not sign in right now. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (_loading || _redirecting) {
      return const LoadingView(message: 'Signing in...');
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Container(
            height: 280,
            decoration: const BoxDecoration(
              gradient: UIColors.heroGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(48),
                bottomRight: Radius.circular(48),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark
                            ? colorScheme.outline.withValues(alpha: 0.35)
                            : colorScheme.outline.withValues(alpha: 0.14),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.22)
                              : UIColors.primary.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const _AppLogo(),
                        const SizedBox(height: 20),
                        Text(
                          'InstruConnect',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Instrumentation Department',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: isDark ? 0.36 : 0.55),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.verified_user_outlined,
                                color: UIColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Use your official college Microsoft account. If you already have an active session, one tap should take you through.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.school_outlined),
                            label: const Text(
                              'Sign in with College Email',
                              style: TextStyle(fontSize: 15),
                            ),
                            onPressed: _loginWithMicrosoft,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Use your official college account',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: UIColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 92,
      width: 92,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF102033) : UIColors.background,
        boxShadow: [
          BoxShadow(
            color: UIColors.primary.withValues(alpha: isDark ? 0.22 : 0.15),
            blurRadius: 16,
          ),
        ],
      ),
      child: Image.asset(
        'assets/logo/ic_logo.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          return const Icon(
            Icons.school_outlined,
            size: 40,
            color: UIColors.primary,
          );
        },
      ),
    );
  }
}
