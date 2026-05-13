// Spec: AD-01 (T-20) — Scanner placeholder screen
// Verifies: Scaffold renders without error, AppBar shows 'Scanner', body shows 'Scanner'.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/features/scanner/presentation/scanner_screen.dart';

void main() {
  group('ScannerScreen', () {
    Widget buildSubject() => const MaterialApp(home: ScannerScreen());

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows AppBar with title "Scanner"', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.widgetWithText(AppBar, 'Scanner'), findsOneWidget);
    });

    testWidgets('shows body text "Scanner"', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('Scanner'), findsAtLeastNWidgets(2));
    });
  });
}
