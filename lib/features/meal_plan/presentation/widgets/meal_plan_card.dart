// Spec: MEAL-UI-004
// Design: pure StatelessWidget with Meal + onToggle callback
// TDD: T-46 [GREEN] — MealPlanCard widget

import 'package:flutter/material.dart';
import 'package:nutriguide_mobile/core/extensions/context_extensions.dart';
import 'package:nutriguide_mobile/core/theme/app_spacing.dart';
import 'package:nutriguide_mobile/features/home/domain/meal.dart';

/// A card displaying a single [Meal] with type label, name, macros, and
/// a completion [Checkbox].
///
/// Displays mealType in uppercase [labelSmall], meal name in [titleSmall],
/// calories when non-null, and a macros row (P/C/F in grams) when at least
/// one macro is non-null. Null individual macros in the row show "—".
///
/// [onToggle] is called with the new boolean value when the user taps the
/// checkbox. If null, the checkbox is disabled.
///
/// Pure [StatelessWidget] — no provider reads (spec MEAL-UI-004).
class MealPlanCard extends StatelessWidget {
  const MealPlanCard({
    super.key,
    required this.meal,
    this.onToggle,
  });

  final Meal meal;

  /// Called with the new completion state when the checkbox is tapped.
  final void Function(bool)? onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildContent(context)),
            _buildCheckbox(context),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // MealType label in uppercase
        Text(
          meal.mealType.toUpperCase(),
          style: context.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
            color: context.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Meal name
        Text(
          meal.name,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        // Calories — only when non-null
        if (meal.calories != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${meal.calories} kcal',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        // Macros row — always shown, individual values are "—" when null
        const SizedBox(height: AppSpacing.xs),
        _buildMacrosRow(context),
      ],
    );
  }

  Widget _buildMacrosRow(BuildContext context) {
    final proteinText = meal.proteins != null
        ? '${meal.proteins!.toStringAsFixed(0)}g'
        : '—';
    final carbText =
        meal.carbs != null ? '${meal.carbs!.toStringAsFixed(0)}g' : '—';
    final fatText =
        meal.fats != null ? '${meal.fats!.toStringAsFixed(0)}g' : '—';

    return Row(
      children: [
        Text(
          'P: $proteinText',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'C: $carbText',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'F: $fatText',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckbox(BuildContext context) {
    return Checkbox(
      value: meal.isCompleted,
      onChanged: onToggle != null ? (v) => onToggle!(v!) : null,
      activeColor: context.colorScheme.primary,
    );
  }
}
