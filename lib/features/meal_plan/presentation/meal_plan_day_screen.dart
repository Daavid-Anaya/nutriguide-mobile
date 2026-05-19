// Spec: MEAL-UI-005
// Design: AD-63, AD-70, AD-77, AD-78, AD-79
// TDD: T-50 [GREEN] — MealPlanDayScreen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutriguide_mobile/core/extensions/context_extensions.dart';
import 'package:nutriguide_mobile/core/theme/app_spacing.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/meal_plan_day.dart';
import 'package:nutriguide_mobile/features/meal_plan/presentation/providers/meal_plan_notifier.dart';
import 'package:nutriguide_mobile/features/meal_plan/presentation/widgets/macro_summary_card.dart';
import 'package:nutriguide_mobile/features/meal_plan/presentation/widgets/meal_plan_card.dart';

/// Daily meal plan detail screen.
///
/// Receives [date] as an ISO8601 string from the route parameter
/// (e.g., '2026-05-18') and renders:
/// - [MacroSummaryCard] for the day's macro totals
/// - A list of [MealPlanCard] widgets for each meal
/// - A FAB to generate the shopping list (spec MEAL-UI-005, MEAL-SHOP-001)
///
/// Each [MealPlanCard] checkbox calls
/// [MealPlanNotifier.toggleMealCompletion] when tapped.
///
/// Spec: MEAL-UI-005 | Design: AD-63, AD-70, AD-77.
class MealPlanDayScreen extends ConsumerWidget {
  const MealPlanDayScreen({super.key, required this.date});

  /// ISO8601 date string from route parameter (e.g., '2026-05-18').
  final String date;

  static final _dateFormatter = DateFormat('EEEE d \'de\' MMMM', 'es');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parsedDate = DateTime.parse(date);
    final asyncState = ref.watch(mealPlanNotifierProvider);
    final notifier = ref.read(mealPlanNotifierProvider.notifier);

    // Format the AppBar title: 'Lunes 18 de mayo'
    String formattedDate;
    try {
      formattedDate = _dateFormatter.format(parsedDate);
      // Capitalize first letter
      if (formattedDate.isNotEmpty) {
        formattedDate =
            formattedDate[0].toUpperCase() + formattedDate.substring(1);
      }
    } catch (_) {
      formattedDate = date;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(formattedDate),
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: context.colorScheme.error,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  error.toString(),
                  style: context.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (state) {
          if (state is! MealPlanData) {
            return const Center(child: CircularProgressIndicator());
          }

          final day = state.weeklyPlan.dayFor(parsedDate);

          if (day == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'No hay comidas planificadas para este día',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return _DayContent(
            day: day,
            onToggleMeal: (mealId, isCompleted) =>
                notifier.toggleMealCompletion(mealId, isCompleted),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => notifier.generateShoppingList(),
        icon: const Icon(Icons.shopping_cart),
        label: const Text('Generar lista de compras'),
        tooltip: 'Generar lista de compras',
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _DayContent — rendered when a MealPlanDay is available
// ---------------------------------------------------------------------------

class _DayContent extends StatelessWidget {
  const _DayContent({
    required this.day,
    required this.onToggleMeal,
  });

  final MealPlanDay day;
  final void Function(String mealId, bool isCompleted) onToggleMeal;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Macro summary at the top
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: MacroSummaryCard(day: day),
          ),
          // Meal cards
          ...day.meals.map((meal) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: MealPlanCard(
                meal: meal,
                onToggle: (v) => onToggleMeal(meal.id, v),
              ),
            );
          }),
        ],
      ),
    );
  }
}
