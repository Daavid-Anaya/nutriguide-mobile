import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';
import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/home/domain/home_repository.dart';
import 'package:nutriguide_mobile/features/home/domain/meal.dart';
import 'package:nutriguide_mobile/features/home/domain/meal_plan.dart';
import 'package:nutriguide_mobile/features/home/domain/wellness_summary.dart';
import 'package:nutriguide_mobile/features/shopping_list/data/shopping_list_repository_impl.dart';

/// Offline-first implementation of [HomeRepository].
///
/// [getWellnessSummary] computes real wellness metrics from local data:
/// - [WellnessSummary.budgetSpent]: sum of [ShoppingItem.estimatedPrice] in the
///   active shopping list (null prices count as 0).
/// - [WellnessSummary.budgetTotal]: hardcoded default 200.0 (no UserProfile
///   budget stored in current profile implementation).
/// - [WellnessSummary.healthScore]: average of nutriscore grades from the Hive
///   products box using the heuristic A=90, B=70, C=50, D=30, E=10.
///   Empty box → 0. Unknown/null grades are skipped.
/// - [WellnessSummary.streak]: hardcoded stub (0) — no backend tracking.
///
/// [getTodayMealPlan] returns a hardcoded stub [MealPlan] with 3 meals
/// covering breakfast, lunch, and dinner.
///
/// All errors are wrapped in [Left(CacheFailure())].
/// Spec: HOME-DATA-001 | Design: AD-28, AD-29, AD-34.
class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({
    required ShoppingListRepositoryImpl shoppingListRepo,
    required Box<dynamic> productsBox,
  })  : _shoppingListRepo = shoppingListRepo,
        _productsBox = productsBox;

  final ShoppingListRepositoryImpl _shoppingListRepo;
  final Box<dynamic> _productsBox;

  /// Nutriscore grade → health score heuristic (AD-29).
  static const _nutriScoreMap = {
    'a': 90,
    'b': 70,
    'c': 50,
    'd': 30,
    'e': 10,
  };

  /// Default budget total when no UserProfile budget is configured (AD-28).
  static const _defaultBudgetTotal = 200.0;

  @override
  Future<Either<Failure, WellnessSummary>> getWellnessSummary() async {
    try {
      // 1. Budget spent from active shopping list
      final listResult = await _shoppingListRepo.getOrCreateDefaultList();
      final budgetSpent = listResult.fold(
        (_) => 0.0,
        (list) => list.items.fold(
          0.0,
          (sum, item) => sum + (item.estimatedPrice ?? 0.0),
        ),
      );

      // 2. Budget total — default 200.0 (no UserProfile.groceryBudget persisted yet)
      const budgetTotal = _defaultBudgetTotal;

      // 3. Health score from Hive products box
      final healthScore = _computeHealthScore();

      return Right(WellnessSummary(
        healthScore: healthScore,
        streak: 0,
        budgetSpent: budgetSpent,
        budgetTotal: budgetTotal,
      ));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Computes average health score from all products in the Hive box.
  ///
  /// Returns 0 when the box is empty or all grades are unknown/null.
  /// Unknown and null grades are skipped (not counted toward the average).
  int _computeHealthScore() {
    if (_productsBox.isEmpty) return 0;

    final scores = <int>[];
    for (final raw in _productsBox.values) {
      final map = Map<String, dynamic>.from(raw as Map);
      final grade = (map['nutriscoreGrade'] as String?)?.toLowerCase();
      final score = _nutriScoreMap[grade];
      if (score != null) scores.add(score);
    }

    if (scores.isEmpty) return 0;
    return (scores.reduce((a, b) => a + b) / scores.length).round();
  }

  @override
  Future<Either<Failure, MealPlan>> getTodayMealPlan() async {
    return Right(MealPlan(
      id: 'stub-today',
      date: DateTime.now(),
      meals: _stubMeals,
    ));
  }

  /// Hardcoded stub meal plan covering breakfast, lunch, and dinner (AD-28).
  ///
  /// No image URLs — [CachedNetworkImage] will show fallback icon (AD-32 decision
  /// at implementation time: null → offline-safe placeholder).
  static final _stubMeals = [
    const Meal(
      id: 'meal-1',
      name: 'Avena con frutas',
      mealType: MealType.breakfast,
      calories: 350,
      tags: ['Alto en fibra'],
      isCompleted: false,
    ),
    const Meal(
      id: 'meal-2',
      name: 'Ensalada mediterránea',
      mealType: MealType.lunch,
      calories: 480,
      tags: ['Proteína', 'Bajo en grasas'],
      isCompleted: false,
    ),
    const Meal(
      id: 'meal-3',
      name: 'Salmón con verduras',
      mealType: MealType.dinner,
      calories: 520,
      tags: ['Omega-3', 'Proteína'],
      isCompleted: false,
    ),
  ];
}
