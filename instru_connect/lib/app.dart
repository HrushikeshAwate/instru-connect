import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instru_connect/config/theme/app_theme.dart';
import 'package:instru_connect/config/routes/app_router.dart';
import 'package:instru_connect/core/providers/app_providers.dart';
import 'package:instru_connect/features/auth/screens/splash_screen.dart';
import 'package:instru_connect/features/legal/widgets/terms_acceptance_gate.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeController = ref.watch(themeControllerProvider);

    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          darkTheme: buildDarkAppTheme(),
          themeMode: themeController.themeMode,
          home: const TermsAcceptanceGate(child: SplashScreen()),
          onGenerateRoute: AppRouter.generate,
        );
      },
    );
  }
}
