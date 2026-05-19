// Spec: MEAL-UI-003
// Design: AD-73 (extension methods for computed totals)
// TDD: T-44 [GREEN] — MacroSummaryCard widget

import 'package:flutter/material.dart';
import 'package:nutriguide_mobile/core/extensions/context_extensions.dart';
import 'package:nutriguide_mobile/core/theme/app_spacing.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/meal_plan_day.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/meal_plan_day_extensions.dart';

/// A card displaying macro summary totals for a [MealPlanDay].
///
/// Shows 4 columns in a horizontal row: Calorías (kcal), Proteínas (g),
/// Carbos (g), Grasas (g).
///
/// Displays "—" (em dash) for proteins, carbs, and fats when no meal in
/// the day has any non-null macro value ([MealPlanDayTotals.hasMacros] is
/// false — spec MEAL-UI-003 sc2).
///
/// Pure [StatelessWidget] — receives [MealPlanDay] via constructor.
class MacroSummaryCard extends StatelessWidget {
  const MacroSummaryCard({super.key, required this.day});

  final MealPlanDay day;

  @override
  Widget build(BuildContext context) {
    final hasMacros = day.hasMacros;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _MacroColumn(
              label: 'Calorías',
              value: '${day.totalCalories} kcal',
            ),
            _MacroColumn(
              label: 'Proteínas',
              value: hasMacros
                  ? '${day.totalProteins.toStringAsFixed(0)} g'
                  : '—',
            ),
            _MacroColumn(
              label: 'Carbos',
              value: hasMacros
                  ? '${day.totalCarbs.toStringAsFixed(0)} g'
                  : '—',
            ),
            _MacroColumn(
              label: 'Grasas',
              value: hasMacros
                  ? '${day.totalFats.toStringAsFixed(0)} g'
                  : '—',
            ),
          ],
        ),
      ),
    );
  }
}

/// A single metric column in [MacroSummaryCard].
///
/// Renders [label] in small text above [value] in bold medium text.
class _MacroColumn extends StatelessWidget {
  const _MacroColumn({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
