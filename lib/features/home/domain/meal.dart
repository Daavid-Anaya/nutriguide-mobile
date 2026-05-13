import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal.freezed.dart';
part 'meal.g.dart';

/// Valid meal type identifiers.
///
/// Used to categorise meals within a [MealPlan].
/// Values match the API contract: 'breakfast', 'lunch', 'dinner', 'snack'.
abstract final class MealType {
  static const String breakfast = 'breakfast';
  static const String lunch = 'lunch';
  static const String dinner = 'dinner';
  static const String snack = 'snack';
}

/// A single meal entry within a [MealPlan].
///
/// [mealType] should be one of the constants in [MealType].
/// [calories] is nullable because calorie data may not be available for all meals.
@freezed
abstract class Meal with _$Meal {
  const factory Meal({
    required String id,
    required String name,
    required String mealType,
    int? calories,
    @Default([]) List<String> tags,
    @Default(false) bool isCompleted,
  }) = _Meal;

  factory Meal.fromJson(Map<String, dynamic> json) => _$MealFromJson(json);
}
