import 'package:flutter/material.dart';
import 'package:instru_connect/config/theme/app_theme.dart';
import 'package:instru_connect/config/routes/app_router.dart';
import 'features/auth/services/auth_gate.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AuthGate(),
      // This matches your AppRouter.generate function perfectly
      onGenerateRoute: AppRouter.generate,
    );
  }
}




