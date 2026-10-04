// ignore_for_file: use_build_context_synchronously
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instru_connect/core/providers/app_providers.dart';
import 'package:instru_connect/features/auth/domain/repositories/auth_repository.dart';
import 'package:instru_connect/core/widgets/loading_view.dart';

import '../../../config/routes/route_names.dart';
import '../../../config/theme/ui_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final AuthRepository _authService;
  StreamSubscription<User?>? _authSubscription;
  bool _loading = false;
  bool _redirecting = false;

  @override
  void initState() {
    super.initState();
    _authService = ref.read(authRepositoryProvider);
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
      if (e.code == 'missing-initial-state') {
        _redirecting = false;
      }
      final cert = await _certInfo();
      _showSignInError(
        '${e.message ?? 'Could not sign in. Please try again in a moment.'}'
        '\n\n$cert',
      );
    } catch (e) {
      final cert = await _certInfo();
      _showSignInError('Could not sign in right now.\n\n[diag] $e\n\n$cert');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const MethodChannel _certChannel = MethodChannel('app_cert_info');

  Future<String> _certInfo() async {
    try {
      final sha256 = await _certChannel.invokeMethod<String>('getSigningSha256');
      final sha1 = await _certChannel.invokeMethod<String>('getSigningSha1');
      return '[installed cert]\nSHA-256: $sha256\nSHA-1: $sha1';
    } catch (e) {
      return '[installed cert] could not read: $e';
    }
  }

  void _showSignInError(String message) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign-in error'),
        content: SingleChildScrollView(child: SelectableText(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _loginWithDemoMode({
    required String id,
    required String password,
  }) async {
    if (_loading || _redirecting) return;
    setState(() => _loading = true);
    try {
      await _authService.signInWithDemoMode(id: id, password: password);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? 'Demo Mode could not start. Please try again.',
          ),
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo Mode could not start right now.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showDemoSignInDialog() async {
    if (_loading || _redirecting) return;

    final credentials = await showDialog<_DemoCredentials>(
      context: context,
      builder: (_) => const _DemoSignInDialog(),
    );

    if (credentials == null) return;

    await _loginWithDemoMode(
      id: credentials.id,
      password: credentials.password,
    );
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
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text(
                              'Sign in with Demo Account',
                              style: TextStyle(fontSize: 15),
                            ),
                            onPressed: _showDemoSignInDialog,
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

class _DemoCredentials {
  const _DemoCredentials({required this.id, required this.password});

  final String id;
  final String password;
}

class _DemoSignInDialog extends StatefulWidget {
  const _DemoSignInDialog();

  @override
  State<_DemoSignInDialog> createState() => _DemoSignInDialogState();
}

class _DemoSignInDialogState extends State<_DemoSignInDialog> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      _DemoCredentials(
        id: _idController.text,
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Demo Account'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'Demo ID or email',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Enter demo ID or email';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (value) {
                if ((value ?? '').isEmpty) {
                  return 'Enter password';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Sign in')),
      ],
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
        'assets/logo/ic_logo_runtime.png',
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
