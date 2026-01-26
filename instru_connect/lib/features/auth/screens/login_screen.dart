import 'package:flutter/material.dart';
import 'package:instru_connect/core/services/auth/auth_service.dart';
import 'package:instru_connect/core/widgets/loading_view.dart';
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
      // Navigation handled by SplashScreen
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleDummyAction() async {
    setState(() => _loading = true);
  try {
    await _authService.signInWithGoogleAdminOnly();
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
      body: Stack(
        children: [
          // ================= HEADER =================
          Container(
            height: 260,
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

                // ================= CARD =================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: UIColors.primary.withOpacity(0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // ================= LOGO =================
                        _AppLogo(),

                        const SizedBox(height: 20),

                        Text(
                          'InstruConnect',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'Instrumentation Department',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: UIColors.textSecondary),
                        ),

                        const SizedBox(height: 32),

                        // ================= MICROSOFT =================
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

                        const SizedBox(height: 14),

                        // ================= GOOGLE (DUMMY) =================
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.g_mobiledata, size: 28),
                            label: const Text(
                              'Sign in with Google',
                              style: TextStyle(fontSize: 15),
                            ),
                            onPressed: _googleDummyAction,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ================= ADMIN NOTE =================
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: UIColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Google sign-in is available for Admins only',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: UIColors.textMuted),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'Use your official college account',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: UIColors.textMuted),
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

/// =======================================================
/// APP ICON (SAFE ASSET HANDLING)
/// =======================================================
class _AppLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      width: 92,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: UIColors.background,
        boxShadow: [
          BoxShadow(color: UIColors.primary.withOpacity(0.15), blurRadius: 16),
        ],
      ),
      child: Image.asset(
        'assets/logo/ic_logo.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          return Icon(Icons.school_outlined, size: 40, color: UIColors.primary);
        },
      ),
    );
  }
}
