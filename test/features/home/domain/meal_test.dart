// TDD: T-08 [RED] — Meal macro fields (proteins, carbs, fats)
//
// Spec: MEAL-DOMAIN-001
// - Meal.fromJson with proteins/carbs/fats present → correct double values
// - Meal.fromJson without macro keys (legacy) → all null, no exception

import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/features/home/domain/meal.dart';

void main() {
  group('Meal — MEAL-DOMAIN-001: Macronutrient fields', () {
    group('fromJson with macros present', () {
      test('parses proteins, carbs, fats as doubles', () {
        final json = {
          'id': '1',
          'name': 'Pollo a la plancha',
          'mealType': 'lunch',
          'calories': 350,
          'proteins': 25.0,
          'carbs': 40.0,
          'fats': 10.0,
          'tags': <String>[],
          'isCompleted': false,
        };

        final meal = Meal.fromJson(json);

        expect(meal.proteins, equals(25.0));
        expect(meal.carbs, equals(40.0));
        expect(meal.fats, equals(10.0));
      });

      test('parses integer macro values as doubles', () {
        final json = {
          'id': '2',
          'name': 'Arroz integral',
          'mealType': 'dinner',
          'proteins': 8,
          'carbs': 45,
          'fats': 2,
        };

        final meal = Meal.fromJson(json);

        // JSON numbers deserialized via num?.toDouble() — verify correct coercion
        expect(meal.proteins, isA<double?>());
        expect(meal.carbs, isA<double?>());
        expect(meal.fats, isA<double?>());
      });
    });

    group('fromJson legacy (no macro keys)', () {
      test('proteins is null when key absent', () {
        final json = {
          'id': 'meal-001',
          'name': 'Oatmeal with fruit',
          'mealType': 'breakfast',
          'calories': 350,
          'tags': ['vegan', 'gluten-free'],
          'isCompleted': false,
        };

        final meal = Meal.fromJson(json);

        expect(meal.proteins, isNull);
      });

      test('carbs is null when key absent', () {
        final json = {
          'id': 'meal-001',
          'name': 'Oatmeal with fruit',
          'mealType': 'breakfast',
          'calories': 350,
        };

        final meal = Meal.fromJson(json);

        expect(meal.carbs, isNull);
      });

      test('fats is null when key absent', () {
        final json = {
          'id': 'meal-001',
          'name': 'Oatmeal with fruit',
          'mealType': 'breakfast',
        };

        final meal = Meal.fromJson(json);

        expect(meal.fats, isNull);
      });

      test('no exception thrown on legacy JSON', () {
        final json = {
          'id': 'meal-002',
          'name': 'Home cooked soup',
          'mealType': 'lunch',
          'calories': null,
          'tags': <String>[],
          'isCompleted': true,
        };

        // Must not throw
        expect(() => Meal.fromJson(json), returnsNormally);
        final meal = Meal.fromJson(json);
        expect(meal.proteins, isNull);
        expect(meal.carbs, isNull);
        expect(meal.fats, isNull);
      });
    });

    group('constructor defaults', () {
      test('macros default to null', () {
        const meal = Meal(id: 'x', name: 'Pasta', mealType: 'dinner');

        expect(meal.proteins, isNull);
        expect(meal.carbs, isNull);
        expect(meal.fats, isNull);
      });
    });

    group('toJson roundtrip', () {
      test('macros preserved in roundtrip', () {
        const original = Meal(
          id: 'meal-x',
          name: 'Salmon',
          mealType: 'dinner',
          proteins: 30.5,
          carbs: 5.0,
          fats: 15.2,
        );

        final json = original.toJson();
        final roundTripped = Meal.fromJson(json);

        expect(roundTripped.proteins, equals(30.5));
        expect(roundTripped.carbs, equals(5.0));
        expect(roundTripped.fats, equals(15.2));
      });

      test('null macros preserved in roundtrip', () {
        const original = Meal(id: 'y', name: 'Salad', mealType: 'lunch');

        final json = original.toJson();
        final roundTripped = Meal.fromJson(json);

        expect(roundTripped.proteins, isNull);
        expect(roundTripped.carbs, isNull);
        expect(roundTripped.fats, isNull);
      });
    });
  });
}
