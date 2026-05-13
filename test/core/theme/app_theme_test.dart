import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/theme/app_colors.dart';
import 'package:nutriguide_mobile/core/theme/app_shapes.dart';
import 'package:nutriguide_mobile/core/theme/app_spacing.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';

/// Tests for AppTheme, AppColors, AppSpacing, AppShapes.
///
/// Strategy: Tests that call [AppTheme.light] must use [testWidgets] because
/// [google_fonts] performs async font loading that requires the Flutter
/// test binding to be initialized. Pure constant tests use plain [test].
void main() {
  group('AppTheme (THEME-SYSTEM-001)', () {
    // ── Material 3 flag ────────────────────────────────────────────────────
    testWidgets('sc3 — useMaterial3 is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const SizedBox()),
      );
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme!.useMaterial3, isTrue);
    });

    // ── ColorScheme tokens (THEME-SYSTEM-001 sc3) ─────────────────────────
    testWidgets('sc3 — colorScheme.primary matches #00450D', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const SizedBox()),
      );
      final theme = tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
      expect(theme.colorScheme.primary, equals(const Color(0xFF00450D)));
    });

    testWidgets('sc3 — colorScheme.onPrimary is white', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const SizedBox()),
      );
      final theme = tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
      expect(theme.colorScheme.onPrimary, equals(const Color(0xFFFFFFFF)));
    });

    testWidgets('sc3 — colorScheme.surface matches #F7FBF1', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const SizedBox()),
      );
      final theme = tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
      expect(theme.colorScheme.surface, equals(const Color(0xFFF7FBF1)));
    });

    testWidgets('sc3 — colorScheme.secondary matches #556158', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const SizedBox()),
      );
      final theme = tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
      expect(theme.colorScheme.secondary, equals(const Color(0xFF556158)));
    });

    testWidgets('sc3 — colorScheme.error matches #BA1A1A', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const SizedBox()),
      );
      final theme = tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
      expect(theme.colorScheme.error, equals(const Color(0xFFBA1A1A)));
    });

    // ── Typography (THEME-SYSTEM-001 sc2) ─────────────────────────────────
    testWidgets(
      'sc2 — textTheme.displayLarge fontSize is 48',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.light, home: const SizedBox()),
        );
        final theme =
            tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
        expect(theme.textTheme.displayLarge!.fontSize, equals(48.0));
      },
    );

    testWidgets(
      'sc2 — textTheme.displayLarge fontWeight is w700',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.light, home: const SizedBox()),
        );
        final theme =
            tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
        expect(
          theme.textTheme.displayLarge!.fontWeight,
          equals(FontWeight.w700),
        );
      },
    );

    testWidgets(
      'sc2 — textTheme.displayLarge fontFamily contains Manrope',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.light, home: const SizedBox()),
        );
        final theme =
            tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
        expect(theme.textTheme.displayLarge!.fontFamily, contains('Manrope'));
      },
    );

    testWidgets(
      'sc2 — textTheme.headlineMedium fontSize is 32',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.light, home: const SizedBox()),
        );
        final theme =
            tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
        expect(theme.textTheme.headlineMedium!.fontSize, equals(32.0));
      },
    );

    testWidgets(
      'sc2 — textTheme.bodyMedium fontFamily contains Inter',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.light, home: const SizedBox()),
        );
        final theme =
            tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
        expect(theme.textTheme.bodyMedium!.fontFamily, contains('Inter'));
      },
    );

    testWidgets('sc2 — textTheme.labelLarge fontSize is 12', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const SizedBox()),
      );
      final theme = tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
      expect(theme.textTheme.labelLarge!.fontSize, equals(12.0));
    });
  });

  // ── AppColors — pure constant tests (no flutter binding needed) ──────────
  group('AppColors', () {
    test('primary constant matches #00450D', () {
      expect(AppColors.primary, equals(const Color(0xFF00450D)));
    });

    test('surface constant matches #F7FBF1', () {
      expect(AppColors.surface, equals(const Color(0xFFF7FBF1)));
    });

    test('error constant matches #BA1A1A', () {
      expect(AppColors.error, equals(const Color(0xFFBA1A1A)));
    });

    test('secondary constant matches #556158', () {
      expect(AppColors.secondary, equals(const Color(0xFF556158)));
    });

    test('onPrimary is white', () {
      expect(AppColors.onPrimary, equals(const Color(0xFFFFFFFF)));
    });

    test('outline matches #717A6D', () {
      expect(AppColors.outline, equals(const Color(0xFF717A6D)));
    });
  });

  // ── AppSpacing — pure constant tests ─────────────────────────────────────
  group('AppSpacing', () {
    test('xs is 4', () {
      expect(AppSpacing.xs, equals(4.0));
    });

    test('sm is 8', () {
      expect(AppSpacing.sm, equals(8.0));
    });

    test('md is 16', () {
      expect(AppSpacing.md, equals(16.0));
    });

    test('lg is 24', () {
      expect(AppSpacing.lg, equals(24.0));
    });

    test('xl is 40', () {
      expect(AppSpacing.xl, equals(40.0));
    });

    test('xxl is 64', () {
      expect(AppSpacing.xxl, equals(64.0));
    });
  });

  // ── AppShapes — pure constant tests ──────────────────────────────────────
  group('AppShapes', () {
    test('containerRadius is BorderRadius.circular(16)', () {
      expect(AppShapes.containerRadius, equals(BorderRadius.circular(16)));
    });

    test('chipRadius is BorderRadius.circular(100) — pill', () {
      expect(AppShapes.chipRadius, equals(BorderRadius.circular(100)));
    });

    test('buttonRadius is BorderRadius.circular(8)', () {
      expect(AppShapes.buttonRadius, equals(BorderRadius.circular(8)));
    });

    test('smallRadius is BorderRadius.circular(4)', () {
      expect(AppShapes.smallRadius, equals(BorderRadius.circular(4)));
    });

    test('largeRadius is BorderRadius.circular(24)', () {
      expect(AppShapes.largeRadius, equals(BorderRadius.circular(24)));
    });
  });
}
