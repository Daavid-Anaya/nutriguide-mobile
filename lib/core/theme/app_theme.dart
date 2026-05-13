import 'package:flutter/material.dart';
import 'package:nutriguide_mobile/core/theme/app_colors.dart';
import 'package:nutriguide_mobile/core/theme/app_shapes.dart';
import 'package:nutriguide_mobile/core/theme/app_typography.dart';

/// Builds the Material 3 [ThemeData] for NutriGuide.
///
/// Design decisions (AD-04):
/// - [ColorScheme] is MANUALLY constructed — NOT fromSeed — to match
///   DESIGN.md hex tokens exactly.
/// - [TextTheme] uses Manrope (headlines) + Inter (body) via google_fonts.
/// - Component themes (Card, AppBar, ElevatedButton) use [AppShapes] and
///   [AppColors] constants — NO hardcoded values.
abstract final class AppTheme {
  /// Returns the light [ThemeData] for NutriGuide.
  ///
  /// Always use [MaterialApp(theme: AppTheme.light)] — never pass raw
  /// ThemeData literals in widget files.
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          primaryContainer: AppColors.primaryContainer,
          onPrimaryContainer: AppColors.onPrimaryContainer,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onSecondary,
          secondaryContainer: AppColors.secondaryContainer,
          onSecondaryContainer: AppColors.onSecondaryContainer,
          tertiary: AppColors.tertiary,
          onTertiary: AppColors.onTertiary,
          tertiaryContainer: AppColors.tertiaryContainer,
          onTertiaryContainer: AppColors.onTertiaryContainer,
          error: AppColors.error,
          onError: AppColors.onError,
          errorContainer: AppColors.errorContainer,
          onErrorContainer: AppColors.onErrorContainer,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
          onSurfaceVariant: AppColors.onSurfaceVariant,
          outline: AppColors.outline,
          outlineVariant: AppColors.outlineVariant,
          shadow: Colors.black,
          scrim: Colors.black,
          inverseSurface: AppColors.inverseSurface,
          onInverseSurface: AppColors.inverseOnSurface,
          inversePrimary: AppColors.inversePrimary,
          surfaceTint: AppColors.surfaceTint,
        ),
        textTheme: buildTextTheme(),
        // ── Card ──────────────────────────────────────────────────────────
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppShapes.containerRadius,
            side: const BorderSide(
              color: AppColors.outlineVariant,
              width: 1,
            ),
          ),
          color: AppColors.surfaceContainerLowest,
        ),
        // ── AppBar ────────────────────────────────────────────────────────
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.onSurface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        // ── ElevatedButton ────────────────────────────────────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: AppShapes.buttonRadius,
            ),
            minimumSize: const Size(double.infinity, 56),
          ),
        ),
        // ── OutlinedButton ────────────────────────────────────────────────
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: AppShapes.buttonRadius,
            ),
            minimumSize: const Size(double.infinity, 56),
          ),
        ),
        // ── Input ─────────────────────────────────────────────────────────
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceContainerLowest,
          border: OutlineInputBorder(
            borderRadius: AppShapes.buttonRadius,
            borderSide: const BorderSide(color: AppColors.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppShapes.buttonRadius,
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        // ── Chip ──────────────────────────────────────────────────────────
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: AppShapes.chipRadius,
          ),
        ),
        // ── BottomNavigationBar / NavigationBar ───────────────────────────
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: AppColors.surfaceContainerLowest,
          indicatorColor: AppColors.primaryContainer,
        ),
      );
}
