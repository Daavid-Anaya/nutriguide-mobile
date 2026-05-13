import 'package:flutter/material.dart';

/// Color constants mapped 1:1 from DESIGN.md tokens.
///
/// Widgets MUST consume these via [Theme.of(context).colorScheme] —
/// never reference [AppColors] directly in widget files.
/// [AppColors] is only used to build [AppTheme.light].
abstract final class AppColors {
  // ── Primary ──────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF00450D);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF1B5E20);
  static const Color onPrimaryContainer = Color(0xFF90D689);
  static const Color inversePrimary = Color(0xFF91D78A);

  // ── Primary fixed ────────────────────────────────────────────────────────
  static const Color primaryFixed = Color(0xFFACF4A4);
  static const Color primaryFixedDim = Color(0xFF91D78A);
  static const Color onPrimaryFixed = Color(0xFF002203);
  static const Color onPrimaryFixedVariant = Color(0xFF0C5216);

  // ── Secondary ────────────────────────────────────────────────────────────
  static const Color secondary = Color(0xFF556158);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFD9E6DA);
  static const Color onSecondaryContainer = Color(0xFF5B675E);

  // ── Secondary fixed ──────────────────────────────────────────────────────
  static const Color secondaryFixed = Color(0xFFD9E6DA);
  static const Color secondaryFixedDim = Color(0xFFBDCABE);
  static const Color onSecondaryFixed = Color(0xFF131E17);
  static const Color onSecondaryFixedVariant = Color(0xFF3E4A41);

  // ── Tertiary ─────────────────────────────────────────────────────────────
  static const Color tertiary = Color(0xFF2F3D45);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF46545D);
  static const Color onTertiaryContainer = Color(0xFFB9C8D2);

  // ── Tertiary fixed ───────────────────────────────────────────────────────
  static const Color tertiaryFixed = Color(0xFFD6E5EF);
  static const Color tertiaryFixedDim = Color(0xFFBAC9D3);
  static const Color onTertiaryFixed = Color(0xFF0F1D25);
  static const Color onTertiaryFixedVariant = Color(0xFF3B4951);

  // ── Error ────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ── Surface / Background ─────────────────────────────────────────────────
  static const Color surface = Color(0xFFF7FBF1);
  static const Color surfaceDim = Color(0xFFD8DBD2);
  static const Color surfaceBright = Color(0xFFF7FBF1);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F5EC);
  static const Color surfaceContainer = Color(0xFFECEFE6);
  static const Color surfaceContainerHigh = Color(0xFFE6E9E0);
  static const Color surfaceContainerHighest = Color(0xFFE0E4DB);
  static const Color onSurface = Color(0xFF191D17);
  static const Color onSurfaceVariant = Color(0xFF41493E);
  static const Color inverseSurface = Color(0xFF2D322C);
  static const Color inverseOnSurface = Color(0xFFEFF2E9);
  static const Color surfaceVariant = Color(0xFFE0E4DB);
  static const Color surfaceTint = Color(0xFF2A6B2C);

  // ── Background ───────────────────────────────────────────────────────────
  // background == surface in M3 tokens
  static const Color background = Color(0xFFF7FBF1);
  static const Color onBackground = Color(0xFF191D17);

  // ── Outline ──────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFF717A6D);
  static const Color outlineVariant = Color(0xFFC0C9BB);
}
