import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nutriguide_mobile/features/home/domain/meal.dart';

part 'meal_plan.freezed.dart';
part 'meal_plan.g.dart';

/// A collection of meals planned for a specific [date].
///
/// Each day has exactly one [MealPlan] containing all scheduled meals
/// (breakfast, lunch, dinner, and any snacks).
@freezed
abstract class MealPlan with _$MealPlan {
  const factory MealPlan({
    required String id,
    required DateTime date,
    @Default([]) List<Meal> meals,
  }) = _MealPlan;

  factory MealPlan.fromJson(Map<String, dynamic> json) =>
      _$MealPlanFromJson(json);
}
