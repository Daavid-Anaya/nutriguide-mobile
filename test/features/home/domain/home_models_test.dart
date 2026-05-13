// NOTE: This test file is the TDD "red" phase.
// Tests WILL NOT compile until `dart run build_runner build` is run (T-16).
// That is intentional — write the spec now, generate the code in T-16.
//
// Spec: CORE-MODELS-001 sc1, sc2 — fromJson/toJson round-trip for home domain models.

import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/features/home/domain/meal.dart';
import 'package:nutriguide_mobile/features/home/domain/meal_plan.dart';
import 'package:nutriguide_mobile/features/home/domain/wellness_summary.dart';

const Map<String, dynamic> kMealJson = {
  'id': 'meal-001',
  'name': 'Oatmeal with fruit',
  'mealType': 'breakfast',
  'calories': 350,
  'tags': ['vegan', 'gluten-free'],
  'isCompleted': false,
};

const Map<String, dynamic> kMealNullCaloriesJson = {
  'id': 'meal-002',
  'name': 'Home cooked soup',
  'mealType': 'lunch',
  'calories': null,
  'tags': <String>[],
  'isCompleted': true,
};

Map<String, dynamic> kMealPlanJson({String? id}) => {
      'id': id ?? 'plan-001',
      'date': '2026-05-12T00:00:00.000',
      'meals': [kMealJson],
    };

const Map<String, dynamic> kWellnessSummaryJson = {
  'healthScore': 85,
  'streak': 7,
  'budgetSpent': 45.50,
  'budgetTotal': 120.00,
};

void main() {
  group('WellnessSummary', () {
    group('CORE-MODELS-001 sc2 — fromJson', () {
      test('parses all fields correctly', () {
        final summary = WellnessSummary.fromJson(kWellnessSummaryJson);

        expect(summary.healthScore, equals(85));
        expect(summary.streak, equals(7));
        expect(summary.budgetSpent, equals(45.50));
        expect(summary.budgetTotal, equals(120.00));
      });

      test('parses zero values correctly', () {
        final summary = WellnessSummary.fromJson({
          'healthScore': 0,
          'streak': 0,
          'budgetSpent': 0.0,
          'budgetTotal': 0.0,
        });

        expect(summary.healthScore, equals(0));
        expect(summary.streak, equals(0));
        expect(summary.budgetSpent, equals(0.0));
        expect(summary.budgetTotal, equals(0.0));
      });
    });

    group('CORE-MODELS-001 sc1 — toJson', () {
      test('serializes all fields', () {
        const summary = WellnessSummary(
          healthScore: 85,
          streak: 7,
          budgetSpent: 45.50,
          budgetTotal: 120.00,
        );

        final json = summary.toJson();

        expect(json['healthScore'], equals(85));
        expect(json['streak'], equals(7));
        expect(json['budgetSpent'], equals(45.50));
        expect(json['budgetTotal'], equals(120.00));
      });

      test('round-trip: fromJson → toJson preserves all values', () {
        final original = WellnessSummary.fromJson(kWellnessSummaryJson);
        final roundTripped = WellnessSummary.fromJson(original.toJson());

        expect(roundTripped, equals(original));
      });
    });

    group('WellnessSummary value equality (Freezed ==)', () {
      test('two summaries with same data are equal', () {
        const s1 = WellnessSummary(healthScore: 80, streak: 3, budgetSpent: 50.0, budgetTotal: 100.0);
        const s2 = WellnessSummary(healthScore: 80, streak: 3, budgetSpent: 50.0, budgetTotal: 100.0);

        expect(s1, equals(s2));
      });
    });
  });

  group('Meal', () {
    group('CORE-MODELS-001 sc2 — fromJson', () {
      test('parses all fields including tags list', () {
        final meal = Meal.fromJson(kMealJson);

        expect(meal.id, equals('meal-001'));
        expect(meal.name, equals('Oatmeal with fruit'));
        expect(meal.mealType, equals('breakfast'));
        expect(meal.calories, equals(350));
        expect(meal.tags, equals(['vegan', 'gluten-free']));
        expect(meal.isCompleted, isFalse);
      });

      test('parses meal with null calories and empty tags', () {
        final meal = Meal.fromJson(kMealNullCaloriesJson);

        expect(meal.calories, isNull);
        expect(meal.tags, isEmpty);
        expect(meal.isCompleted, isTrue);
      });

      test('isCompleted defaults to false', () {
        const meal = Meal(id: 'x', name: 'Pasta', mealType: 'dinner');

        expect(meal.isCompleted, isFalse);
      });

      test('tags defaults to empty list', () {
        const meal = Meal(id: 'x', name: 'Pasta', mealType: 'dinner');

        expect(meal.tags, isEmpty);
      });
    });

    group('CORE-MODELS-001 sc1 — toJson', () {
      test('serializes all fields', () {
        const meal = Meal(
          id: 'meal-001',
          name: 'Oatmeal',
          mealType: 'breakfast',
          calories: 350,
          tags: ['vegan'],
        );

        final json = meal.toJson();

        expect(json['id'], equals('meal-001'));
        expect(json['name'], equals('Oatmeal'));
        expect(json['mealType'], equals('breakfast'));
        expect(json['calories'], equals(350));
        expect(json['tags'], equals(['vegan']));
        expect(json['isCompleted'], isFalse);
      });

      test('round-trip: fromJson → toJson preserves all values', () {
        final original = Meal.fromJson(kMealJson);
        final roundTripped = Meal.fromJson(original.toJson());

        expect(roundTripped, equals(original));
      });
    });

    group('MealType constants', () {
      test('MealType.breakfast equals "breakfast"', () {
        expect(MealType.breakfast, equals('breakfast'));
      });

      test('MealType.lunch equals "lunch"', () {
        expect(MealType.lunch, equals('lunch'));
      });

      test('MealType.dinner equals "dinner"', () {
        expect(MealType.dinner, equals('dinner'));
      });

      test('MealType.snack equals "snack"', () {
        expect(MealType.snack, equals('snack'));
      });
    });
  });

  group('MealPlan', () {
    group('CORE-MODELS-001 sc2 — fromJson', () {
      test('parses plan with meals correctly', () {
        final plan = MealPlan.fromJson(kMealPlanJson());

        expect(plan.id, equals('plan-001'));
        expect(plan.date, equals(DateTime.parse('2026-05-12T00:00:00.000')));
        expect(plan.meals, hasLength(1));
        expect(plan.meals.first.name, equals('Oatmeal with fruit'));
      });

      test('parses empty meal plan', () {
        final plan = MealPlan.fromJson({
          'id': 'plan-002',
          'date': '2026-05-12T00:00:00.000',
          'meals': <Map<String, dynamic>>[],
        });

        expect(plan.meals, isEmpty);
      });

      test('meals defaults to empty list', () {
        final plan = MealPlan(
          id: 'x',
          date: DateTime(2026, 5, 12),
        );

        expect(plan.meals, isEmpty);
      });
    });

    group('CORE-MODELS-001 sc1 — toJson', () {
      test('serializes id, date, and nested meals', () {
        final plan = MealPlan.fromJson(kMealPlanJson());
        final json = plan.toJson();

        expect(json['id'], equals('plan-001'));
        expect(json['date'], isNotNull);
        expect(json['meals'], isA<List>());
        expect((json['meals'] as List).length, equals(1));
      });

      test('round-trip: fromJson → toJson preserves all values', () {
        final original = MealPlan.fromJson(kMealPlanJson());
        final roundTripped = MealPlan.fromJson(original.toJson());

        expect(roundTripped, equals(original));
      });

      test('round-trip preserves nested meals', () {
        final original = MealPlan.fromJson(kMealPlanJson());
        final roundTripped = MealPlan.fromJson(original.toJson());

        expect(roundTripped.meals.first, equals(original.meals.first));
      });
    });

    group('MealPlan value equality (Freezed ==)', () {
      test('copyWith updates meals', () {
        final date = DateTime(2026, 5, 12);
        final original = MealPlan(id: 'x', date: date);
        const newMeal = Meal(id: 'm1', name: 'Salad', mealType: 'lunch');
        final updated = original.copyWith(meals: [newMeal]);

        expect(updated.meals, hasLength(1));
        expect(updated.date, equals(date));
      });
    });
  });
}
