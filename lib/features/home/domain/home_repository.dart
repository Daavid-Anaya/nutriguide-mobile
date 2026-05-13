import 'package:fpdart/fpdart.dart';
import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/home/domain/meal_plan.dart';
import 'package:nutriguide_mobile/features/home/domain/wellness_summary.dart';

/// Abstract contract for home dashboard data operations.
///
/// All methods return [Either<Failure, T>] — Left for errors, Right for success.
/// The home feature uses an online-primary + stale Hive cache strategy: attempt
/// API call first, fall back to last cached values when offline.
abstract class HomeRepository {
  /// Returns the wellness summary for the current user.
  ///
  /// Returns [NetworkFailure] when offline with no cache, [CacheFailure] when
  /// the local cache is empty.
  Future<Either<Failure, WellnessSummary>> getWellnessSummary();

  /// Returns the meal plan for today.
  ///
  /// Returns [NetworkFailure] when offline with no cache, [CacheFailure] when
  /// no plan exists for today.
  Future<Either<Failure, MealPlan>> getTodayMealPlan();
}
