import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instru_connect/config/theme/app_theme.dart';

void main() {
  testWidgets('builds the themed app shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: Text('InstruConnect')),
      ),
    );

    expect(find.text('InstruConnect'), findsOneWidget);
  });
}
