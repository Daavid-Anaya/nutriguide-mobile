// Spec: HOME-UI-006 sc1–sc3, HOME-INTEGRATION-001 sc1
// Design: AD-30 (updated) — "Ver Todo" → context.push(Routes.mealPlan) (AD-79).
// TDD: T-16 [GREEN] — Implements TodaysPlanSection to pass T-15a tests.
// TDD: T-56 [GREEN] — Replaces SnackBar with navigation to /meal-plan.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nutriguide_mobile/core/extensions/context_extensions.dart';
import 'package:nutriguide_mobile/core/theme/app_spacing.dart';
import 'package:nutriguide_mobile/features/home/domain/meal_plan.dart';
import 'package:nutriguide_mobile/features/home/presentation/widgets/meal_card.dart';
import 'package:nutriguide_mobile/router/route_constants.dart';

/// Section displaying today's meal plan.
///
/// Shows a "Plan de Hoy" header with a "Ver Todo" [TextButton] that navigates
/// to [Routes.mealPlan] via [context.push] (AD-79 — preserves shell state).
/// When [mealPlan.meals] is empty, an empty-state message is shown.
///
/// Each meal is rendered as a [MealCard]. [onToggleMeal] is forwarded to
/// each card's [MealCard.onToggle] callback.
///
/// Spec: HOME-UI-006, HOME-INTEGRATION-001 | Design: AD-79.
class TodaysPlanSection extends StatelessWidget {
  const TodaysPlanSection({
    super.key,
    required this.mealPlan,
    this.onToggleMeal,
  });

  final MealPlan mealPlan;
  final void Function(String mealId)? onToggleMeal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: AppSpacing.md),
        if (mealPlan.meals.isEmpty)
          _buildEmptyState(context)
        else
          _buildMealList(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Plan de Hoy',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        TextButton(
          onPressed: () => context.push(Routes.mealPlan),
          child: const Text('Ver Todo'),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Text(
          'No hay comidas para hoy',
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildMealList(BuildContext context) {
    return Column(
      children: mealPlan.meals.map((meal) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: MealCard(
            meal: meal,
            onToggle: onToggleMeal != null ? () => onToggleMeal!(meal.id) : null,
          ),
        );
      }).toList(),
    );
  }
}
