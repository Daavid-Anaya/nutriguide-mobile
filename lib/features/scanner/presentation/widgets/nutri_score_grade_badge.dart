// Spec: SCANNER-WIDGET-001 sc1, sc2 — NutriScore grade A–E color badge.
// Design: AD-17 — Stateless widget, grade-to-color mapping via private map.

import 'package:flutter/material.dart';

/// Circular colored badge that displays a NutriScore grade letter (A–E).
///
/// Accepts a [grade] string (case-insensitive, values: 'a'–'e').
/// When [grade] is `null` or unrecognized, renders [SizedBox.shrink()].
///
/// Color mapping (per SCANNER-WIDGET-001 spec):
/// | Grade | Color     |
/// |-------|-----------|
/// | A     | #1B7D2C   |
/// | B     | #97BF30   |
/// | C     | #FECB02   |
/// | D     | #EE7F1A   |
/// | E     | #E63E11   |
class NutriScoreGradeBadge extends StatelessWidget {
  const NutriScoreGradeBadge({
    super.key,
    required this.grade,
    this.size = 48,
  });

  /// NutriScore grade letter ('a'–'e', case-insensitive). Null → hidden.
  final String? grade;

  /// Badge diameter in logical pixels. Defaults to 48.
  final double size;

  /// Grade-to-color mapping per SCANNER-WIDGET-001 spec.
  ///
  /// Pure constant map — extracted for direct testability (AD-17 pattern).
  static const Map<String, Color> gradeColors = {
    'a': Color(0xFF1B7D2C),
    'b': Color(0xFF97BF30),
    'c': Color(0xFFFECB02),
    'd': Color(0xFFEE7F1A),
    'e': Color(0xFFE63E11),
  };

  @override
  Widget build(BuildContext context) {
    final normalizedGrade = grade?.toLowerCase();
    final color = gradeColors[normalizedGrade];

    // Null or unrecognized grade → render nothing (spec sc2).
    if (color == null) return const SizedBox.shrink();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      alignment: Alignment.center,
      child: Text(
        normalizedGrade!.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
