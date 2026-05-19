// Spec: MEAL-GEN-001 sc1–sc4
// TDD: Phase 3 [RED→GREEN] — Tests drive MealPlanGeneratorService.generate()

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/meal_plan/data/meal_plan_generator_service.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/weekly_meal_plan.dart';
import 'package:nutriguide_mobile/features/profile/domain/user_profile.dart';

import '../../../helpers/mock_supabase.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

/// Minimal [UserProfile] for tests.
UserProfile _makeProfile({
  List<String> dietaryRestrictions = const [],
  String? primaryGoal,
}) =>
    UserProfile(
      id: 'user-123',
      name: 'Test User',
      email: 'test@nutriguide.app',
      dietaryRestrictions: dietaryRestrictions,
      primaryGoal: primaryGoal,
    );

/// Valid Edge Function response JSON that can be decoded as [WeeklyMealPlan].
///
/// weekStartDate must be a Monday; uses 2026-05-18.
Map<String, dynamic> _validEdgeFunctionResponse() {
  final weekStart = DateTime(2026, 5, 18);
  final days = List.generate(7, (i) {
    final date = weekStart.add(Duration(days: i));
    return {
      'date': date.toIso8601String(),
      'meals': [
        {
          'id': 'meal-bf-$i',
          'name': 'Desayuno día $i',
          'mealType': 'breakfast',
          'calories': 350,
          'proteins': 12.0,
          'carbs': 55.0,
          'fats': 8.0,
          'tags': ['vegetarian'],
          'isCompleted': false,
        },
        {
          'id': 'meal-ln-$i',
          'name': 'Almuerzo día $i',
          'mealType': 'lunch',
          'calories': 480,
          'proteins': 25.0,
          'carbs': 60.0,
          'fats': 14.0,
          'tags': ['pollo'],
          'isCompleted': false,
        },
        {
          'id': 'meal-dn-$i',
          'name': 'Cena día $i',
          'mealType': 'dinner',
          'calories': 420,
          'proteins': 30.0,
          'carbs': 40.0,
          'fats': 16.0,
          'tags': [],
          'isCompleted': false,
        },
      ],
    };
  });

  return {
    'id': 'plan-from-edge-fn',
    'weekStartDate': weekStart.toIso8601String(),
    'days': days,
    'isLocalFallback': false,
  };
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late MockSupabaseClient mockSupabase;
  late MockFunctionsClient mockFunctions;
  late MealPlanGeneratorService service;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockFunctions = MockFunctionsClient();
    when(() => mockSupabase.functions).thenReturn(mockFunctions);

    service = MealPlanGeneratorService(supabase: mockSupabase);
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 1: Edge Function succeeds (MEAL-GEN-001 sc1)
  // ─────────────────────────────────────────────────────────────────────────
  group('MealPlanGeneratorService.generate() — Edge Function OK', () {
    test(
        'Edge Function returns 200 → Right(WeeklyMealPlan) with isLocalFallback == false',
        () async {
      final validJson = _validEdgeFunctionResponse();

      when(
        () => mockFunctions.invoke(
          'generate-meal-plan',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => FunctionResponse(data: validJson, status: 200),
      );

      final profile = _makeProfile();
      final result = await service.generate(
        profile: profile,
        inventory: [],
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (plan) {
          expect(plan, isA<WeeklyMealPlan>());
          expect(plan.isLocalFallback, isFalse);
          expect(plan.days, hasLength(7));
        },
      );
    });

    test('triangulate — Edge Function plan has meals in each day', () async {
      final validJson = _validEdgeFunctionResponse();

      when(
        () => mockFunctions.invoke(
          'generate-meal-plan',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => FunctionResponse(data: validJson, status: 200),
      );

      final profile = _makeProfile(dietaryRestrictions: ['vegetarian']);
      final result = await service.generate(
        profile: profile,
        inventory: [
          {'name': 'Arroz', 'nutriscoreGrade': 'a'},
        ],
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (plan) {
          for (final day in plan.days) {
            expect(day.meals.length, greaterThan(0));
          }
        },
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 2: Edge Function times out (MEAL-GEN-001 sc2)
  // ─────────────────────────────────────────────────────────────────────────
  group('MealPlanGeneratorService.generate() — Edge Function timeout', () {
    test(
        'Edge Function times out → falls back to local → Right(isLocalFallback == true)',
        () async {
      when(
        () => mockFunctions.invoke(
          'generate-meal-plan',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async {
        // Simulate timeout by throwing TimeoutException
        throw TimeoutException('Timeout', const Duration(seconds: 8));
      });

      final profile = _makeProfile();
      final result = await service.generate(
        profile: profile,
        inventory: [],
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right from local fallback'),
        (plan) {
          expect(plan.isLocalFallback, isTrue);
          expect(plan.days, hasLength(7));
        },
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 3: Edge Function returns 500 (MEAL-GEN-001 sc3)
  // ─────────────────────────────────────────────────────────────────────────
  group('MealPlanGeneratorService.generate() — Edge Function 500', () {
    test(
        'Edge Function returns 500 → falls back to local → Right(isLocalFallback == true)',
        () async {
      when(
        () => mockFunctions.invoke(
          'generate-meal-plan',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => FunctionResponse(data: null, status: 500),
      );

      final profile = _makeProfile();
      final result = await service.generate(
        profile: profile,
        inventory: [],
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right from local fallback'),
        (plan) {
          expect(plan.isLocalFallback, isTrue);
        },
      );
    });

    test('triangulate — 429 rate limit also triggers local fallback', () async {
      when(
        () => mockFunctions.invoke(
          'generate-meal-plan',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => FunctionResponse(data: null, status: 429),
      );

      final profile = _makeProfile();
      final result = await service.generate(
        profile: profile,
        inventory: [],
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right from local fallback'),
        (plan) => expect(plan.isLocalFallback, isTrue),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 4: Both Edge Function and local fallback fail (MEAL-GEN-001 sc4)
  // ─────────────────────────────────────────────────────────────────────────
  group(
      'MealPlanGeneratorService.generate() — both Edge Function and local fail',
      () {
    test(
        'Edge Function throws AND local fallback also throws → Left(GenerationFailure)',
        () async {
      // Edge Function throws
      when(
        () => mockFunctions.invoke(
          'generate-meal-plan',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => throw Exception('Network unreachable'));

      // We cannot "break" LocalMealTemplates directly (it's pure Dart constants),
      // so we verify the service handles the edge function failure gracefully
      // and only returns Left when the local fallback itself throws.
      // In production: if LocalMealTemplates.generate() throws (e.g. out-of-memory),
      // the catch block wraps it in Left(GenerationFailure).
      //
      // For this test, we verify that the error path is reachable by passing
      // a profile and confirming the result is still a valid WeeklyMealPlan
      // from local fallback (since LocalMealTemplates never throws in practice).
      //
      // To test Left(GenerationFailure) we use a testable service subclass.
      final throwingService = _ThrowingLocalFallbackService(
        supabase: mockSupabase,
      );

      final profile = _makeProfile();
      final result = await throwingService.generate(
        profile: profile,
        inventory: [],
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<GenerationFailure>()),
        (_) => fail('Expected Left(GenerationFailure)'),
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Test helper — a service where local fallback always throws
// ---------------------------------------------------------------------------

/// A test-only subclass that overrides local fallback to throw.
///
/// Used to test the Left(GenerationFailure) path without having to
/// break the pure-Dart LocalMealTemplates class.
class _ThrowingLocalFallbackService extends MealPlanGeneratorService {
  _ThrowingLocalFallbackService({required super.supabase});

  @override
  Either<Failure, WeeklyMealPlan> localFallback(UserProfile profile) {
    throw Exception('Simulated local fallback failure');
  }
}
