import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Builds the [TextTheme] from DESIGN.md typography specs.
///
/// Manrope → displayLarge/Medium/Small, headlineLarge/Medium/Small
/// Inter   → bodyLarge/Medium/Small, labelLarge/Medium/Small
///
/// Letter spacing in Flutter uses LOGICAL PIXELS, not em units.
/// Conversion: letterSpacing (px) = fontSize * em value
///   e.g. display-lg: -0.02em * 48px = -0.96px
TextTheme buildTextTheme() {
  return TextTheme(
    // ── Display — Manrope ─────────────────────────────────────────────────
    displayLarge: GoogleFonts.manrope(
      fontSize: 48,
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: -0.02 * 48, // = -0.96px
    ),
    displayMedium: GoogleFonts.manrope(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      height: 1.1,
    ),
    displaySmall: GoogleFonts.manrope(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.15,
    ),

    // ── Headline — Manrope ────────────────────────────────────────────────
    headlineLarge: GoogleFonts.manrope(
      fontSize: 36,
      fontWeight: FontWeight.w600,
      height: 1.2,
    ),
    headlineMedium: GoogleFonts.manrope(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: -0.01 * 32, // = -0.32px
    ),
    headlineSmall: GoogleFonts.manrope(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),

    // ── Title — Manrope (semi-bold, used for screen titles) ───────────────
    titleLarge: GoogleFonts.manrope(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    titleMedium: GoogleFonts.manrope(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    titleSmall: GoogleFonts.manrope(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),

    // ── Body — Inter ──────────────────────────────────────────────────────
    bodyLarge: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      height: 1.6,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),

    // ── Label — Inter ─────────────────────────────────────────────────────
    labelLarge: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: 0.05 * 12, // = 0.6px
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      height: 1.0,
      letterSpacing: 0.1 * 11, // = 1.1px
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      height: 1.2,
    ),
  );
}
