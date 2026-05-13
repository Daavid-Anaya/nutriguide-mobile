import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/theme/app_colors.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';
import 'package:nutriguide_mobile/core/widgets/score_badge.dart';

void main() {
  /// Convenience: builds a widget inside a themed MaterialApp.
  Widget buildInTheme(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: child)),
    );
  }

  // ── colorForScore pure function tests (no widget needed) ─────────────────
  group('ScoreBadge.colorForScore — pure function', () {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      error: AppColors.error,
      onError: AppColors.onError,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
    );

    test('score 0 returns error color (red)', () {
      expect(
        ScoreBadge.colorForScore(0, colorScheme),
        equals(AppColors.error),
      );
    });

    test('score 40 (boundary) returns error color', () {
      expect(
        ScoreBadge.colorForScore(40, colorScheme),
        equals(AppColors.error),
      );
    });

    test('score 41 (above low boundary) returns amber color', () {
      final color = ScoreBadge.colorForScore(41, colorScheme);
      expect(color, equals(const Color(0xFFF59E0B)));
    });

    test('score 70 (boundary) returns amber color', () {
      final color = ScoreBadge.colorForScore(70, colorScheme);
      expect(color, equals(const Color(0xFFF59E0B)));
    });

    test('score 71 (above mid boundary) returns primary/green', () {
      expect(
        ScoreBadge.colorForScore(71, colorScheme),
        equals(AppColors.primary),
      );
    });

    test('score 100 returns primary/green', () {
      expect(
        ScoreBadge.colorForScore(100, colorScheme),
        equals(AppColors.primary),
      );
    });

    test('score 55 (mid range) returns amber', () {
      final color = ScoreBadge.colorForScore(55, colorScheme);
      expect(color, equals(const Color(0xFFF59E0B)));
    });

    test('score 85 (high range) returns primary green', () {
      expect(
        ScoreBadge.colorForScore(85, colorScheme),
        equals(AppColors.primary),
      );
    });

    test('score 20 (low range) returns error red', () {
      expect(
        ScoreBadge.colorForScore(20, colorScheme),
        equals(AppColors.error),
      );
    });
  });

  // ── Widget rendering tests ────────────────────────────────────────────────
  group('ScoreBadge widget', () {
    testWidgets('renders score text inside a circle', (tester) async {
      await tester.pumpWidget(buildInTheme(const ScoreBadge(score: 85)));
      expect(find.text('85'), findsOneWidget);
    });

    testWidgets('renders correct score for low value', (tester) async {
      await tester.pumpWidget(buildInTheme(const ScoreBadge(score: 20)));
      expect(find.text('20'), findsOneWidget);
    });

    testWidgets('default size is 48', (tester) async {
      await tester.pumpWidget(buildInTheme(const ScoreBadge(score: 75)));
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ScoreBadge),
          matching: find.byType(Container),
        ),
      );
      expect(container.constraints?.maxWidth, equals(48.0));
    });

    testWidgets('custom size is respected', (tester) async {
      await tester.pumpWidget(buildInTheme(const ScoreBadge(score: 75, size: 64)));
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ScoreBadge),
          matching: find.byType(Container),
        ),
      );
      expect(container.constraints?.maxWidth, equals(64.0));
    });
  });
}
