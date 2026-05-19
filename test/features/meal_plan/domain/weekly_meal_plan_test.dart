// TDD: T-14 [RED] — WeeklyMealPlan Freezed model
//
// Spec: MEAL-DOMAIN-002
// - WeeklyMealPlan.create normalizes Wednesday 2026-05-20 → Monday 2026-05-18
// - dayFor(date) returns correct MealPlanDay
// - dayFor(missing date) returns null
// - fromJson roundtrip

import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/features/home/domain/meal.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/meal_plan_day.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/weekly_meal_plan.dart';

void main() {
  // Spec: Wednesday 2026-05-20 → Monday 2026-05-18
  final wednesday = DateTime(2026, 5, 20);
  final monday = DateTime(2026, 5, 18);

  group('WeeklyMealPlan — MEAL-DOMAIN-002', () {
    group('WeeklyMealPlan.create factory', () {
      test('normalizes Wednesday to Monday', () {
        final plan = WeeklyMealPlan.create(
          id: 'plan-1',
          weekStartDate: wednesday,
        );

        expect(plan.weekStartDate, equals(monday));
      });

      test('normalizes Sunday to Monday of same week', () {
        final sunday = DateTime(2026, 5, 24);
        final expectedMonday = DateTime(2026, 5, 18);

        final plan = WeeklyMealPlan.create(
          id: 'plan-1',
          weekStartDate: sunday,
        );

        expect(plan.weekStartDate, equals(expectedMonday));
      });

      test('Monday stays Monday', () {
        final plan = WeeklyMealPlan.create(
          id: 'plan-1',
          weekStartDate: monday,
        );

        expect(plan.weekStartDate, equals(monday));
      });

      test('strips time component from weekStartDate', () {
        final wednesdayWithTime = DateTime(2026, 5, 20, 14, 30, 0);
        final plan = WeeklyMealPlan.create(
          id: 'plan-1',
          weekStartDate: wednesdayWithTime,
        );

        expect(plan.weekStartDate.hour, equals(0));
        expect(plan.weekStartDate.minute, equals(0));
        expect(plan.weekStartDate.second, equals(0));
      });

      test('preserves id', () {
        final plan = WeeklyMealPlan.create(
          id: 'my-plan-id',
          weekStartDate: monday,
        );

        expect(plan.id, equals('my-plan-id'));
      });

      test('default days is empty list', () {
        final plan = WeeklyMealPlan.create(
          id: 'plan-1',
          weekStartDate: monday,
        );

        expect(plan.days, isEmpty);
      });

      test('default isLocalFallback is false', () {
        final plan = WeeklyMealPlan.create(
          id: 'plan-1',
          weekStartDate: monday,
        );

        expect(plan.isLocalFallback, isFalse);
      });

      test('accepts days and isLocalFallback', () {
        final day = MealPlanDay(date: monday);
        final plan = WeeklyMealPlan.create(
          id: 'plan-1',
          weekStartDate: monday,
          days: [day],
          isLocalFallback: true,
        );

        expect(plan.days, hasLength(1));
        expect(plan.isLocalFallback, isTrue);
      });
    });

    group('dayFor()', () {
      late WeeklyMealPlan plan;
      late MealPlanDay mondayDay;
      late MealPlanDay wednesdayDay;

      setUp(() {
        mondayDay = MealPlanDay(
          date: monday,
          meals: [
            const Meal(
              id: 'm1',
              name: 'Avena',
              mealType: 'breakfast',
              calories: 350,
            ),
          ],
        );
        wednesdayDay = MealPlanDay(date: wednesday);

        plan = WeeklyMealPlan.create(
          id: 'plan-1',
          weekStartDate: monday,
          days: [mondayDay, wednesdayDay],
        );
      });

      test('returns correct MealPlanDay for Monday', () {
        final result = plan.dayFor(monday);

        expect(result, isNotNull);
        expect(result!.meals, hasLength(1));
        expect(result.meals.first.id, equals('m1'));
      });

      test('returns correct MealPlanDay for Wednesday', () {
        final result = plan.dayFor(wednesday);

        expect(result, isNotNull);
        expect(
          DateTime(
            result!.date.year,
            result.date.month,
            result.date.day,
          ),
          equals(wednesday),
        );
      });

      test('returns null for date not in plan', () {
        final friday = DateTime(2026, 5, 22);
        final result = plan.dayFor(friday);

        expect(result, isNull);
      });

      test('matches by date ignoring time component', () {
        // dayFor should match even if the stored date has no time
        // and the queried date has a time component
        final mondayWithTime = DateTime(2026, 5, 18, 12, 30, 0);
        final result = plan.dayFor(mondayWithTime);

        expect(result, isNotNull);
      });
    });

    group('fromJson / toJson roundtrip', () {
      test('roundtrip preserves id', () {
        final original = WeeklyMealPlan.create(
          id: 'test-plan-id',
          weekStartDate: monday,
        );
        final json = original.toJson();
        final restored = WeeklyMealPlan.fromJson(json);

        expect(restored.id, equals('test-plan-id'));
      });

      test('roundtrip preserves weekStartDate', () {
        final original = WeeklyMealPlan.create(
          id: 'plan-1',
          weekStartDate: monday,
        );
        final json = original.toJson();
        final restored = WeeklyMealPlan.fromJson(json);

        expect(
          DateTime(
            restored.weekStartDate.year,
            restored.weekStartDate.month,
            restored.weekStartDate.day,
          ),
          equals(monday),
        );
      });

      test('roundtrip preserves days', () {
        final day = MealPlanDay(date: monday);
        final original = WeeklyMealPlan.create(
          id: 'plan-1',
          weekStartDate: monday,
          days: [day],
        );
        final json = original.toJson();
        final restored = WeeklyMealPlan.fromJson(json);

        expect(restored.days, hasLength(1));
      });

      test('roundtrip preserves isLocalFallback', () {
        final original = WeeklyMealPlan.create(
          id: 'plan-1',
          weekStartDate: monday,
          isLocalFallback: true,
        );
        final json = original.toJson();
        final restored = WeeklyMealPlan.fromJson(json);

        expect(restored.isLocalFallback, isTrue);
      });

      test('toJson includes required keys', () {
        final plan = WeeklyMealPlan.create(
          id: 'plan-1',
          weekStartDate: monday,
        );
        final json = plan.toJson();

        expect(json.containsKey('id'), isTrue);
        expect(json.containsKey('weekStartDate'), isTrue);
        expect(json.containsKey('days'), isTrue);
        expect(json.containsKey('isLocalFallback'), isTrue);
      });
    });

    group('value equality (Freezed ==)', () {
      test('copyWith updates days', () {
        final original = WeeklyMealPlan.create(
          id: 'plan-1',
          weekStartDate: monday,
        );
        final day = MealPlanDay(date: monday);
        final updated = original.copyWith(days: [day]);

        expect(updated.days, hasLength(1));
        expect(updated.id, equals('plan-1'));
      });

      test('copyWith updates isLocalFallback', () {
        final original = WeeklyMealPlan.create(
          id: 'plan-1',
          weekStartDate: monday,
        );
        final updated = original.copyWith(isLocalFallback: true);

        expect(updated.isLocalFallback, isTrue);
        expect(updated.id, equals('plan-1'));
      });
    });
  });
}
