import 'package:flutter/material.dart';
import 'package:instru_connect/config/theme/app_theme.dart';

import 'config/routes/app_router.dart';
import 'config/routes/route_names.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.splash,
      theme: buildAppTheme(),
      onGenerateRoute: AppRouter.generate,
    );
  }
}
