import 'package:nutriguide_mobile/features/meal_plan/domain/meal_plan_day.dart';

/// Computed aggregate totals for a [MealPlanDay] (AD-73).
///
/// Implemented as extension methods rather than Freezed `@late` getters
/// for independent testability and to avoid codegen conflicts.
extension MealPlanDayTotals on MealPlanDay {
  /// Sum of [Meal.calories] for all meals; null calories treated as 0.
  int get totalCalories => meals.fold(0, (sum, m) => sum + (m.calories ?? 0));

  /// Sum of [Meal.proteins] for all meals; null proteins treated as 0.
  double get totalProteins =>
      meals.fold(0.0, (sum, m) => sum + (m.proteins ?? 0.0));

  /// Sum of [Meal.carbs] for all meals; null carbs treated as 0.
  double get totalCarbs =>
      meals.fold(0.0, (sum, m) => sum + (m.carbs ?? 0.0));

  /// Sum of [Meal.fats] for all meals; null fats treated as 0.
  double get totalFats =>
      meals.fold(0.0, (sum, m) => sum + (m.fats ?? 0.0));

  /// True when at least one meal has a non-null macro value.
  ///
  /// Used to determine whether to display \"—\" or actual values in
  /// [MacroSummaryCard] (spec MEAL-UI-003).
  bool get hasMacros => meals.any(
        (m) => m.proteins != null || m.carbs != null || m.fats != null,
      );
}
