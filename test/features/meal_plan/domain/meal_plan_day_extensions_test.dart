// TDD: T-12 [RED] — MealPlanDay extension totals
//
// Spec: MEAL-DOMAIN-002
// - totalCalories: sums correctly
// - totalProteins: treats null as 0
// - all-null macros → totalProteins/totalCarbs/totalFats all 0.0
// - hasMacros: false when all null, true when any non-null

import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/features/home/domain/meal.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/meal_plan_day.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/meal_plan_day_extensions.dart';

void main() {
  final testDate = DateTime(2026, 5, 18);

  group('MealPlanDayTotals extension — MEAL-DOMAIN-002', () {
    group('totalCalories', () {
      test('sums calories from all meals', () {
        final day = MealPlanDay(
          date: testDate,
          meals: [
            const Meal(id: 'm1', name: 'A', mealType: 'breakfast', calories: 500),
            const Meal(id: 'm2', name: 'B', mealType: 'lunch', calories: 300),
            const Meal(id: 'm3', name: 'C', mealType: 'dinner', calories: 400),
          ],
        );

        expect(day.totalCalories, equals(1200));
      });

      test('treats null calories as 0', () {
        final day = MealPlanDay(
          date: testDate,
          meals: [
            const Meal(id: 'm1', name: 'A', mealType: 'breakfast', calories: 500),
            const Meal(id: 'm2', name: 'B', mealType: 'lunch'), // null calories
          ],
        );

        expect(day.totalCalories, equals(500));
      });

      test('returns 0 for empty meals', () {
        final day = MealPlanDay(date: testDate);

        expect(day.totalCalories, equals(0));
      });
    });

    group('totalProteins', () {
      test('sums proteins treating null as 0', () {
        final day = MealPlanDay(
          date: testDate,
          meals: [
            const Meal(
              id: 'm1',
              name: 'A',
              mealType: 'breakfast',
              proteins: 20.0,
            ),
            const Meal(
              id: 'm2',
              name: 'B',
              mealType: 'lunch',
            ), // null proteins
            const Meal(
              id: 'm3',
              name: 'C',
              mealType: 'dinner',
              proteins: 15.0,
            ),
          ],
        );

        expect(day.totalProteins, equals(35.0));
      });

      test('returns 0.0 when all meals have null proteins', () {
        final day = MealPlanDay(
          date: testDate,
          meals: [
            const Meal(id: 'm1', name: 'A', mealType: 'breakfast'),
            const Meal(id: 'm2', name: 'B', mealType: 'lunch'),
          ],
        );

        expect(day.totalProteins, equals(0.0));
      });
    });

    group('totalCarbs', () {
      test('sums carbs treating null as 0', () {
        final day = MealPlanDay(
          date: testDate,
          meals: [
            const Meal(
              id: 'm1',
              name: 'A',
              mealType: 'breakfast',
              carbs: 50.0,
            ),
            const Meal(id: 'm2', name: 'B', mealType: 'lunch'), // null
            const Meal(
              id: 'm3',
              name: 'C',
              mealType: 'dinner',
              carbs: 30.0,
            ),
          ],
        );

        expect(day.totalCarbs, equals(80.0));
      });

      test('returns 0.0 when all meals have null carbs', () {
        final day = MealPlanDay(
          date: testDate,
          meals: [
            const Meal(id: 'm1', name: 'A', mealType: 'breakfast'),
          ],
        );

        expect(day.totalCarbs, equals(0.0));
      });
    });

    group('totalFats', () {
      test('sums fats treating null as 0', () {
        final day = MealPlanDay(
          date: testDate,
          meals: [
            const Meal(
              id: 'm1',
              name: 'A',
              mealType: 'breakfast',
              fats: 10.0,
            ),
            const Meal(
              id: 'm2',
              name: 'B',
              mealType: 'lunch',
              fats: 5.5,
            ),
          ],
        );

        expect(day.totalFats, equals(15.5));
      });

      test('returns 0.0 when all meals have null fats', () {
        final day = MealPlanDay(
          date: testDate,
          meals: [
            const Meal(id: 'm1', name: 'A', mealType: 'lunch'),
          ],
        );

        expect(day.totalFats, equals(0.0));
      });
    });

    group('hasMacros', () {
      test('returns false when all meals have all-null macros', () {
        final day = MealPlanDay(
          date: testDate,
          meals: [
            const Meal(id: 'm1', name: 'A', mealType: 'breakfast'),
            const Meal(id: 'm2', name: 'B', mealType: 'lunch'),
          ],
        );

        expect(day.hasMacros, isFalse);
      });

      test('returns true when at least one meal has non-null proteins', () {
        final day = MealPlanDay(
          date: testDate,
          meals: [
            const Meal(id: 'm1', name: 'A', mealType: 'breakfast'),
            const Meal(
              id: 'm2',
              name: 'B',
              mealType: 'lunch',
              proteins: 20.0,
            ),
          ],
        );

        expect(day.hasMacros, isTrue);
      });

      test('returns true when at least one meal has non-null carbs', () {
        final day = MealPlanDay(
          date: testDate,
          meals: [
            const Meal(id: 'm1', name: 'A', mealType: 'breakfast', carbs: 45.0),
          ],
        );

        expect(day.hasMacros, isTrue);
      });

      test('returns true when at least one meal has non-null fats', () {
        final day = MealPlanDay(
          date: testDate,
          meals: [
            const Meal(id: 'm1', name: 'A', mealType: 'breakfast', fats: 8.0),
          ],
        );

        expect(day.hasMacros, isTrue);
      });

      test('returns false for empty meals list', () {
        final day = MealPlanDay(date: testDate);

        expect(day.hasMacros, isFalse);
      });
    });

    group('all-null macros scenario (spec: MEAL-DOMAIN-002)', () {
      test('all totals are 0.0 when all macros null', () {
        final day = MealPlanDay(
          date: testDate,
          meals: [
            const Meal(id: 'm1', name: 'A', mealType: 'breakfast'),
            const Meal(id: 'm2', name: 'B', mealType: 'lunch'),
            const Meal(id: 'm3', name: 'C', mealType: 'dinner'),
          ],
        );

        expect(day.totalProteins, equals(0.0));
        expect(day.totalCarbs, equals(0.0));
        expect(day.totalFats, equals(0.0));
      });
    });
  });
}
