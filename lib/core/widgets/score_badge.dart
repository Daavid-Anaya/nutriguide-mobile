import 'package:flutter/material.dart';

/// Circular score badge widget for NutriGuide nutrition scores.
///
/// Color changes based on score range:
/// - 0–40  → [ColorScheme.error] (red — poor nutritional profile)
/// - 41–70 → amber warning color  (moderate — use caution)
/// - 71–100 → [ColorScheme.primary] (green — healthy choice)
///
/// Usage:
/// ```dart
/// ScoreBadge(score: 85, size: 56)
/// ```
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({
    required this.score,
    super.key,
    this.size = 48,
  }) : assert(score >= 0 && score <= 100, 'score must be between 0 and 100');

  final int score;
  final double size;

  /// Returns the appropriate [Color] for the given [score].
  ///
  /// Pure function — extracted for direct testability.
  static Color colorForScore(int score, ColorScheme colorScheme) {
    if (score <= 40) return colorScheme.error;
    if (score <= 70) return const Color(0xFFF59E0B); // amber-500
    return colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scoreColor = colorForScore(score, colorScheme);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scoreColor,
      ),
      alignment: Alignment.center,
      child: Text(
        '$score',
        style: textTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
