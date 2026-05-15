// Spec: HOME-UI-003 sc1–sc2
// TDD: T-09 [RED] — GreetingSection widget tests (written before implementation exists).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';
import 'package:nutriguide_mobile/features/home/presentation/widgets/greeting_section.dart';

/// Pumps [GreetingSection] in a minimal MaterialApp with app theme.
Future<void> pumpGreeting(
  WidgetTester tester, {
  required String userName,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: GreetingSection(userName: userName),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('GreetingSection', () {
    // sc1: Greeting shows user name with "Hola, " prefix
    testWidgets(
      'renders "Hola, Lucía" when userName is "Lucía"',
      (tester) async {
        await pumpGreeting(tester, userName: 'Lucía');

        expect(find.text('Hola, Lucía'), findsOneWidget);
      },
    );

    // TRIANGULATE sc1: different name
    testWidgets(
      'renders "Hola, Carlos" when userName is "Carlos"',
      (tester) async {
        await pumpGreeting(tester, userName: 'Carlos');

        expect(find.text('Hola, Carlos'), findsOneWidget);
      },
    );

    // sc2: Subtitle is always visible
    testWidgets(
      'subtitle text is visible below the greeting',
      (tester) async {
        await pumpGreeting(tester, userName: 'Ana');

        // The subtitle must be a non-empty Text widget below the greeting.
        // We verify the specific subtitle from the spec.
        final subtitleFinder = find.text(
          'Tu resumen de bienestar de hoy',
        );
        expect(subtitleFinder, findsOneWidget);
      },
    );

    // Both texts render as separate Text widgets
    testWidgets(
      'greeting and subtitle are both Text widgets',
      (tester) async {
        await pumpGreeting(tester, userName: 'Usuario');

        expect(find.text('Hola, Usuario'), findsOneWidget);
        // At least 2 Text widgets in total (greeting + subtitle)
        expect(find.byType(Text), findsAtLeast(2));
      },
    );
  });
}
