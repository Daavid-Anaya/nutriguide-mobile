// Spec: HOME-UI-004 sc1–sc3
// Design: AD-37 — intl NumberFormat.currency() for formatting. LinearProgressIndicator clamped [0,1].
// TDD: T-12 [GREEN] — Implements WellnessBudgetCard to pass T-11 tests.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutriguide_mobile/core/extensions/context_extensions.dart';
import 'package:nutriguide_mobile/core/theme/app_shapes.dart';
import 'package:nutriguide_mobile/core/theme/app_spacing.dart';
import 'package:nutriguide_mobile/features/home/domain/wellness_summary.dart';

/// Card displaying the weekly grocery budget with a progress indicator.
///
/// Shows "PRESUPUESTO SEMANAL" label, budget as "$spent / $total" in
/// currency format, and a [LinearProgressIndicator] clamped to [0.0, 1.0].
///
/// Spec: HOME-UI-004 | Design: AD-37 (intl currency formatting).
class WellnessBudgetCard extends StatelessWidget {
  const WellnessBudgetCard({
    super.key,
    required this.wellness,
  });

  /// The wellness summary providing [budgetSpent] and [budgetTotal].
  final WellnessSummary wellness;

  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    final progress = (wellness.budgetTotal > 0)
        ? (wellness.budgetSpent / wellness.budgetTotal).clamp(0.0, 1.0)
        : 0.0;

    final spentFormatted = _currencyFormat.format(wellness.budgetSpent);
    final totalFormatted = _currencyFormat.format(wellness.budgetTotal);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PRESUPUESTO SEMANAL',
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$spentFormatted / $totalFormatted',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppShapes.chipRadius,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                color: context.colorScheme.primary,
                backgroundColor: context.colorScheme.surfaceContainerHigh,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
