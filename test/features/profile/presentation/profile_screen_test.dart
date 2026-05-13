// Spec: AD-01 (T-20) — Profile placeholder screen
// Verifies: Scaffold renders without error, AppBar shows 'Profile', body shows 'Profile'.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/features/profile/presentation/profile_screen.dart';

void main() {
  group('ProfileScreen', () {
    Widget buildSubject() => const MaterialApp(home: ProfileScreen());

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows AppBar with title "Profile"', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.widgetWithText(AppBar, 'Profile'), findsOneWidget);
    });

    testWidgets('shows body text "Profile"', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('Profile'), findsAtLeastNWidgets(2));
    });
  });
}
