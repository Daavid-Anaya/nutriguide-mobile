// TDD: T-10 [RED] — MealPlanDay Freezed model
//
// Spec: MEAL-DOMAIN-002
// - MealPlanDay constructor with date + meals
// - fromJson / toJson roundtrip
// - Default meals is empty list

import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/features/home/domain/meal.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/meal_plan_day.dart';

void main() {
  group('MealPlanDay — MEAL-DOMAIN-002', () {
    final testDate = DateTime(2026, 5, 18);
    const testMeal = Meal(
      id: 'meal-1',
      name: 'Avena',
      mealType: 'breakfast',
      calories: 350,
      proteins: 12.0,
      carbs: 55.0,
      fats: 8.0,
    );

    group('constructor', () {
      test('creates with required date and optional meals', () {
        final day = MealPlanDay(date: testDate);

        expect(day.date, equals(testDate));
        expect(day.meals, isEmpty);
      });

      test('creates with date and meals list', () {
        final day = MealPlanDay(date: testDate, meals: [testMeal]);

        expect(day.date, equals(testDate));
        expect(day.meals, hasLength(1));
        expect(day.meals.first, equals(testMeal));
      });

      test('default meals is empty list', () {
        final day = MealPlanDay(date: testDate);

        expect(day.meals, equals(const <Meal>[]));
        expect(day.meals, isEmpty);
      });
    });

    group('fromJson / toJson roundtrip', () {
      test('roundtrip preserves date', () {
        final original = MealPlanDay(date: testDate);
        final json = original.toJson();
        final restored = MealPlanDay.fromJson(json);

        expect(
          DateTime(
            restored.date.year,
            restored.date.month,
            restored.date.day,
          ),
          equals(
            DateTime(testDate.year, testDate.month, testDate.day),
          ),
        );
      });

      test('roundtrip preserves meals list', () {
        final original = MealPlanDay(date: testDate, meals: [testMeal]);
        final json = original.toJson();
        final restored = MealPlanDay.fromJson(json);

        expect(restored.meals, hasLength(1));
        expect(restored.meals.first.id, equals('meal-1'));
        expect(restored.meals.first.name, equals('Avena'));
        expect(restored.meals.first.proteins, equals(12.0));
      });

      test('toJson includes date key', () {
        final day = MealPlanDay(date: testDate);
        final json = day.toJson();

        expect(json.containsKey('date'), isTrue);
      });

      test('toJson includes meals key', () {
        final day = MealPlanDay(date: testDate, meals: [testMeal]);
        final json = day.toJson();

        expect(json.containsKey('meals'), isTrue);
        expect(json['meals'], isA<List>());
        expect((json['meals'] as List).length, equals(1));
      });

      test('empty meals list roundtrips correctly', () {
        final original = MealPlanDay(date: testDate);
        final restored = MealPlanDay.fromJson(original.toJson());

        expect(restored.meals, isEmpty);
      });
    });

    group('value equality (Freezed ==)', () {
      test('two days with same data are equal', () {
        final day1 = MealPlanDay(date: testDate, meals: [testMeal]);
        final day2 = MealPlanDay(date: testDate, meals: [testMeal]);

        expect(day1, equals(day2));
      });

      test('copyWith updates meals', () {
        final original = MealPlanDay(date: testDate);
        final updated = original.copyWith(meals: [testMeal]);

        expect(updated.meals, hasLength(1));
        expect(updated.date, equals(testDate));
      });
    });
  });
}
