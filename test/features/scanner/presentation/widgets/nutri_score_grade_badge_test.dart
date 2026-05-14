// Spec: SCANNER-WIDGET-001 sc1, sc2
// T-06: NutriScoreGradeBadge — color badge for NutriScore grades A–E.
// Tests written FIRST (strict TDD — RED phase before implementation exists).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';
import 'package:nutriguide_mobile/features/scanner/presentation/widgets/nutri_score_grade_badge.dart';

/// Pumps the widget under test wrapped in a minimal MaterialApp.
Future<void> pumpBadge(WidgetTester tester, String? grade) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(child: NutriScoreGradeBadge(grade: grade)),
      ),
    ),
  );
}

void main() {
  group('NutriScoreGradeBadge', () {
    // ── Happy-path: each grade renders the correct color and letter ──────────

    // RED → GREEN sc1: grade 'a' → dark green badge + letter "A"
    testWidgets('grade "a" renders badge with color #1B7D2C and text "A"',
        (tester) async {
      await pumpBadge(tester, 'a');

      // Badge container must be present
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.color, equals(const Color(0xFF1B7D2C)));
      expect(decoration.shape, equals(BoxShape.circle));
      expect(find.text('A'), findsOneWidget);
    });

    // TRIANGULATE sc2: grade 'b' → light green badge + letter "B"
    testWidgets('grade "b" renders badge with color #97BF30 and text "B"',
        (tester) async {
      await pumpBadge(tester, 'b');

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.color, equals(const Color(0xFF97BF30)));
      expect(decoration.shape, equals(BoxShape.circle));
      expect(find.text('B'), findsOneWidget);
    });

    // TRIANGULATE: grade 'c' → yellow badge + letter "C"
    testWidgets('grade "c" renders badge with color #FECB02 and text "C"',
        (tester) async {
      await pumpBadge(tester, 'c');

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.color, equals(const Color(0xFFFECB02)));
      expect(decoration.shape, equals(BoxShape.circle));
      expect(find.text('C'), findsOneWidget);
    });

    // TRIANGULATE: grade 'd' → orange badge + letter "D"
    testWidgets('grade "d" renders badge with color #EE7F1A and text "D"',
        (tester) async {
      await pumpBadge(tester, 'd');

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.color, equals(const Color(0xFFEE7F1A)));
      expect(decoration.shape, equals(BoxShape.circle));
      expect(find.text('D'), findsOneWidget);
    });

    // TRIANGULATE: grade 'e' → red badge + letter "E"
    testWidgets('grade "e" renders badge with color #E63E11 and text "E"',
        (tester) async {
      await pumpBadge(tester, 'e');

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.color, equals(const Color(0xFFE63E11)));
      expect(decoration.shape, equals(BoxShape.circle));
      expect(find.text('E'), findsOneWidget);
    });

    // ── Edge cases: null / unrecognized grade → SizedBox.shrink ─────────────

    // RED → GREEN sc2: null grade → no badge rendered
    testWidgets('grade null renders SizedBox.shrink — no badge visible',
        (tester) async {
      await pumpBadge(tester, null);

      // No text and no colored container — only SizedBox.shrink
      expect(find.byType(Container), findsNothing);
      // SizedBox.shrink is present instead
      expect(
        find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == 0.0 && w.height == 0.0,
        ),
        findsOneWidget,
      );
    });

    // TRIANGULATE: unrecognized grade 'x' → no badge rendered
    testWidgets('grade "x" (unrecognized) renders SizedBox.shrink',
        (tester) async {
      await pumpBadge(tester, 'x');

      expect(find.byType(Container), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == 0.0 && w.height == 0.0,
        ),
        findsOneWidget,
      );
    });

    // TRIANGULATE: case-insensitivity — uppercase 'A' works the same as 'a'
    testWidgets('grade "A" (uppercase) renders same as "a"', (tester) async {
      await pumpBadge(tester, 'A');

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.color, equals(const Color(0xFF1B7D2C)));
      expect(find.text('A'), findsOneWidget);
    });
  });
}
