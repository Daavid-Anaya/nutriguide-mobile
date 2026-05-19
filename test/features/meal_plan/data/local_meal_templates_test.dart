// Spec: MEAL-GEN-003 sc1–sc3
// TDD: Phase 3 [RED→GREEN] — Tests drive LocalMealTemplates.generate()

import 'package:flutter_test/flutter_test.dart';

import 'package:nutriguide_mobile/features/meal_plan/data/local_meal_templates.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/weekly_meal_plan.dart';

void main() {
  /// A fixed Monday for determinism tests.
  final fixedMonday = DateTime(2026, 5, 18);

  // ─────────────────────────────────────────────────────────────────────────
  // Group 1: 7-day plan structure
  // ─────────────────────────────────────────────────────────────────────────
  group('LocalMealTemplates.generate() — basic structure', () {
    test('returns 7-day plan (7 MealPlanDay entries)', () {
      final plan = LocalMealTemplates.generate(
        weekStart: fixedMonday,
        dietaryRestrictions: [],
      );

      expect(plan, isA<WeeklyMealPlan>());
      expect(plan.days, hasLength(7));
    });

    test('each day has at least 3 meals (breakfast, lunch, dinner)', () {
      final plan = LocalMealTemplates.generate(
        weekStart: fixedMonday,
        dietaryRestrictions: [],
      );

      for (final day in plan.days) {
        expect(
          day.meals.length,
          greaterThanOrEqualTo(3),
          reason: 'Day ${day.date} has ${day.meals.length} meals (expected ≥ 3)',
        );
      }
    });

    test('isLocalFallback is true', () {
      final plan = LocalMealTemplates.generate(
        weekStart: fixedMonday,
        dietaryRestrictions: [],
      );

      expect(plan.isLocalFallback, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 2: Vegetarian filter (MEAL-GEN-003 sc1)
  // ─────────────────────────────────────────────────────────────────────────
  group('LocalMealTemplates.generate() — dietary filter', () {
    test(
        'vegetarian restriction → all meals have vegetarian tag',
        () {
      final plan = LocalMealTemplates.generate(
        weekStart: fixedMonday,
        dietaryRestrictions: ['vegetarian'],
      );

      for (final day in plan.days) {
        for (final meal in day.meals) {
          expect(
            meal.tags.any(
              (tag) => tag.toLowerCase().contains('vegetarian'),
            ),
            isTrue,
            reason:
                'Meal "${meal.name}" on ${day.date} is missing vegetarian tag; tags: ${meal.tags}',
          );
        }
      }
    });

    test('no restrictions → plan still has 7 days with ≥ 3 meals each', () {
      final plan = LocalMealTemplates.generate(
        weekStart: fixedMonday,
        dietaryRestrictions: [],
      );

      expect(plan.days, hasLength(7));
      for (final day in plan.days) {
        expect(day.meals.length, greaterThanOrEqualTo(3));
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 3: Degraded mode (MEAL-GEN-003 sc2)
  // ─────────────────────────────────────────────────────────────────────────
  group('LocalMealTemplates.generate() — degraded mode', () {
    test(
        'overly restrictive diet that matches no templates → falls back to unfiltered, still 7 days',
        () {
      // A restriction that no template will ever satisfy
      final plan = LocalMealTemplates.generate(
        weekStart: fixedMonday,
        dietaryRestrictions: ['xyzzy-nonexistent-restriction'],
      );

      // Should still produce a valid 7-day plan (not crash or return empty)
      expect(plan.days, hasLength(7));
      for (final day in plan.days) {
        expect(
          day.meals.length,
          greaterThanOrEqualTo(3),
          reason: 'Degraded mode still needs ≥ 3 meals per day',
        );
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 4: Determinism (MEAL-GEN-003 sc3)
  // ─────────────────────────────────────────────────────────────────────────
  group('LocalMealTemplates.generate() — deterministic output', () {
    test(
        'same weekStart + same restrictions → identical output on two calls',
        () {
      final plan1 = LocalMealTemplates.generate(
        weekStart: fixedMonday,
        dietaryRestrictions: [],
      );
      final plan2 = LocalMealTemplates.generate(
        weekStart: fixedMonday,
        dietaryRestrictions: [],
      );

      expect(plan1.days.length, equals(plan2.days.length));

      for (var i = 0; i < plan1.days.length; i++) {
        final day1 = plan1.days[i];
        final day2 = plan2.days[i];
        expect(day1.meals.length, equals(day2.meals.length));
        for (var j = 0; j < day1.meals.length; j++) {
          expect(
            day1.meals[j].name,
            equals(day2.meals[j].name),
            reason: 'Day $i, meal $j differs between calls',
          );
        }
      }
    });

    test(
        'different weekStart → may produce different plan (no hard crash)',
        () {
      final differentMonday = DateTime(2026, 5, 25);
      final plan1 = LocalMealTemplates.generate(
        weekStart: fixedMonday,
        dietaryRestrictions: [],
      );
      final plan2 = LocalMealTemplates.generate(
        weekStart: differentMonday,
        dietaryRestrictions: [],
      );

      // Both must be valid 7-day plans (no crash)
      expect(plan1.days, hasLength(7));
      expect(plan2.days, hasLength(7));
    });
  });
}
