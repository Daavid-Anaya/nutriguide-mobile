// Spec: AD-01 (T-20) — Shopping List placeholder screen
// Verifies: Scaffold renders without error, AppBar shows 'Shopping List', body shows text.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/features/shopping_list/presentation/shopping_list_screen.dart';

void main() {
  group('ShoppingListScreen', () {
    Widget buildSubject() => const MaterialApp(home: ShoppingListScreen());

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows AppBar with title "Shopping List"', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.widgetWithText(AppBar, 'Shopping List'), findsOneWidget);
    });

    testWidgets('shows body text "Shopping List"', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('Shopping List'), findsAtLeastNWidgets(2));
    });
  });
}
