import 'package:fpdart/fpdart.dart';
import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/home/domain/meal_plan.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/weekly_meal_plan.dart';

/// Abstract contract for meal plan persistence operations (MEAL-REPO-001).
///
/// All methods return [Either<Failure, T>] — Left for errors, Right for success.
/// Concrete implementations use Supabase as primary source with Hive
/// 'meal_plans' box as a write-through offline cache (AD-65).
///
/// Auth semantics: unauthenticated callers receive [CacheFailure] on any
/// method that requires user identity — no Supabase call is made.
abstract class MealPlanRepository {
  /// Returns the [MealPlan] for the given [date] (daily view).
  ///
  /// Used by [HomeRepositoryImpl.getTodayMealPlan()] to delegate to the
  /// single source of truth for meal plan data (AD-71).
  ///
  /// Returns [CacheFailure] when the user is unauthenticated or no data
  /// exists for [date].
  Future<Either<Failure, MealPlan>> getMealPlanForDate(DateTime date);

  /// Returns the [WeeklyMealPlan] for the week containing [weekStart].
  ///
  /// [weekStart] should be a Monday date (normalized by [WeeklyMealPlan.create]).
  /// On Supabase success, result is written to Hive under [weekStart] key.
  /// On Supabase failure, falls back to Hive cache.
  ///
  /// Returns [CacheFailure] when the user is unauthenticated, or when both
  /// Supabase and Hive have no data for the given week.
  Future<Either<Failure, WeeklyMealPlan>> getWeeklyPlan(DateTime weekStart);

  /// Persists [plan] to Supabase and writes to Hive cache (write-through).
  ///
  /// Upserts each day's `meal_plans` row. On Supabase success, also stores
  /// the serialized plan in Hive under the plan's weekStartDate key.
  ///
  /// Returns [CacheFailure] when the user is unauthenticated.
  Future<Either<Failure, Unit>> saveMealPlan(WeeklyMealPlan plan);

  /// Updates the `is_completed` flag for [mealId] in Supabase.
  ///
  /// Does not update the Hive cache directly — the next [getWeeklyPlan]
  /// call will refresh the cache.
  ///
  /// Returns [CacheFailure] when the user is unauthenticated.
  Future<Either<Failure, Unit>> toggleMealCompletion(
    String mealId,
    bool isCompleted,
  );
}
