import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nutriguide_mobile/features/home/domain/meal.dart';

part 'meal_plan_day.freezed.dart';
part 'meal_plan_day.g.dart';

/// A single day's meal schedule within a [WeeklyMealPlan].
///
/// [date] is the calendar date for this day's meals.
/// [meals] defaults to an empty list — not all days may have meals loaded.
///
/// Computed totals (totalCalories, totalProteins, etc.) are available via
/// the [MealPlanDayTotals] extension in meal_plan_day_extensions.dart (AD-73).
@freezed
abstract class MealPlanDay with _$MealPlanDay {
  const factory MealPlanDay({
    required DateTime date,
    @Default([]) List<Meal> meals,
  }) = _MealPlanDay;

  factory MealPlanDay.fromJson(Map<String, dynamic> json) =>
      _$MealPlanDayFromJson(json);
}
