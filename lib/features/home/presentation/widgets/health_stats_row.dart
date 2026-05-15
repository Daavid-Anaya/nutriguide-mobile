// Spec: HOME-UI-005 sc1–sc3
// Design: AD-36 — HealthScoreCard uses CustomPaint arc ring (not ScoreBadge).
//         Color semaphore: 0-40=error, 41-70=secondary, 71-100=primary.
// TDD: T-14 [GREEN] — Implements HealthStatsRow (HealthScoreCard + StreakCard) to pass T-13 tests.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nutriguide_mobile/core/extensions/context_extensions.dart';
import 'package:nutriguide_mobile/core/theme/app_spacing.dart';

/// Horizontal row containing [HealthScoreCard] and [StreakCard] side by side.
///
/// Each card takes equal flex width (Expanded). Spec: HOME-UI-005.
class HealthStatsRow extends StatelessWidget {
  const HealthStatsRow({
    super.key,
    required this.healthScore,
    required this.streak,
  });

  /// Health score in range [0, 100].
  final int healthScore;

  /// Consecutive active days streak.
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: HealthScoreCard(healthScore: healthScore)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: StreakCard(streak: streak)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// HealthScoreCard
// ---------------------------------------------------------------------------

/// Card displaying the user's health score with a [CustomPaint] circular arc.
///
/// Arc color follows score semaphore (AD-36):
/// - 0–40 → error color
/// - 41–70 → secondary color
/// - 71–100 → primary color
class HealthScoreCard extends StatelessWidget {
  const HealthScoreCard({super.key, required this.healthScore});

  final int healthScore;

  @override
  Widget build(BuildContext context) {
    final arcColor = _arcColor(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CustomPaint(
                painter: _ScoreRingPainter(
                  score: healthScore,
                  color: arcColor,
                  trackColor: context.colorScheme.surfaceContainerHigh,
                ),
                child: Center(
                  child: Text(
                    '$healthScore',
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: arcColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'HEALTH SCORE',
              style: context.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _arcColor(BuildContext context) {
    if (healthScore <= 40) return context.colorScheme.error;
    if (healthScore <= 70) return context.colorScheme.secondary;
    return context.colorScheme.primary;
  }
}

// ---------------------------------------------------------------------------
// StreakCard
// ---------------------------------------------------------------------------

/// Card displaying the user's consecutive day streak.
///
/// Renders [Icons.local_fire_department], "{streak} Days", and "STREAK" label.
class StreakCard extends StatelessWidget {
  const StreakCard({super.key, required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              size: 40,
              color: context.colorScheme.tertiary,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$streak Days',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'STREAK',
              style: context.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CustomPainter — circular arc ring
// ---------------------------------------------------------------------------

/// Paints a circular arc ring representing a score from 0 to 100.
///
/// Track (background ring) is always drawn; arc fills proportionally.
/// Spec: HOME-UI-005 | Design: AD-36.
class _ScoreRingPainter extends CustomPainter {
  const _ScoreRingPainter({
    required this.score,
    required this.color,
    required this.trackColor,
  });

  final int score;
  final Color color;
  final Color trackColor;

  static const double _strokeWidth = 8.0;
  static const double _startAngle = -math.pi / 2; // top
  static const double _fullSweep = 2 * math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - _strokeWidth / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw background track
    canvas.drawArc(rect, 0, _fullSweep, false, trackPaint);

    // Draw score arc — proportional sweep
    if (score > 0) {
      final sweep = _fullSweep * (score.clamp(0, 100) / 100.0);
      canvas.drawArc(rect, _startAngle, sweep, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) {
    return old.score != score || old.color != color || old.trackColor != trackColor;
  }
}


