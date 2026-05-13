// Spec: AD-01 (T-20) — Home placeholder screen
// Verifies: Scaffold renders without error, AppBar shows 'Home', body shows 'Home'.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/features/home/presentation/home_screen.dart';

void main() {
  group('HomeScreen', () {
    Widget buildSubject() => const MaterialApp(home: HomeScreen());

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows AppBar with title "Home"', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.widgetWithText(AppBar, 'Home'), findsOneWidget);
    });

    testWidgets('shows body text "Home"', (tester) async {
      await tester.pumpWidget(buildSubject());
      // AppBar and body both contain 'Home' — find at least two occurrences.
      expect(find.text('Home'), findsAtLeastNWidgets(2));
    });
  });
}
