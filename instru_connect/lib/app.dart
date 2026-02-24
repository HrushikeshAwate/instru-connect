import 'package:flutter/material.dart';
import 'package:instru_connect/config/theme/app_theme.dart';
import 'package:instru_connect/config/routes/app_router.dart';
import 'package:instru_connect/core/services/theme_controller.dart';
import 'features/auth/services/auth_gate.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          darkTheme: buildDarkAppTheme(),
          themeMode: ThemeController.instance.themeMode,
          home: const AuthGate(),
          onGenerateRoute: AppRouter.generate,
        );
      },
    );
  }
}
