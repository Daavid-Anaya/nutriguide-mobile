// Spec: MEAL-GEN-001 sc1–sc4
// Design: AD-66, AD-68
// TDD: Phase 3 [GREEN] — Edge Function → local fallback generator service

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/meal_plan/data/local_meal_templates.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/weekly_meal_plan.dart';
import 'package:nutriguide_mobile/features/profile/domain/user_profile.dart';

/// AI meal plan generator — tries Edge Function first, falls back to local
/// templates on any failure (AD-66, AD-68).
///
/// Stateless service; the Supabase client is injected via constructor (AD-60
/// pattern). [localFallback] is a protected-style method overridable in tests.
///
/// Timeout: 8 seconds for the Edge Function call (spec MEAL-GEN-001).
/// On non-200 response, the status is treated as an error and local fallback
/// is triggered (spec MEAL-GEN-001 sc3).
class MealPlanGeneratorService {
  MealPlanGeneratorService({required SupabaseClient supabase})
      : _supabase = supabase;

  final SupabaseClient _supabase;

  /// Timeout for Edge Function call (spec MEAL-GEN-001: 8s).
  static const _timeout = Duration(seconds: 8);

  /// Generates a [WeeklyMealPlan] for the current week.
  ///
  /// Strategy:
  /// 1. Invoke Supabase Edge Function `generate-meal-plan` (with 8s timeout).
  /// 2. On success (status == 200): parse JSON → return `Right(plan)` with
  ///    `isLocalFallback: false`.
  /// 3. On any failure (timeout, non-200, exception): call [localFallback].
  /// 4. If [localFallback] itself throws: return `Left(GenerationFailure)`.
  Future<Either<Failure, WeeklyMealPlan>> generate({
    required UserProfile profile,
    required List<Map<String, dynamic>> inventory,
  }) async {
    try {
      return await _tryEdgeFunction(profile, inventory);
    } catch (_) {
      return _safeLocalFallback(profile);
    }
  }

  /// Calls the Edge Function and returns the parsed plan.
  ///
  /// Throws on any failure (timeout, network error, non-200 response).
  Future<Either<Failure, WeeklyMealPlan>> _tryEdgeFunction(
    UserProfile profile,
    List<Map<String, dynamic>> inventory,
  ) async {
    final weekStart = _currentMonday();

    final response = await _supabase.functions
        .invoke(
          'generate-meal-plan',
          body: {
            'weekStart': weekStart.toIso8601String().substring(0, 10),
            'profile': {
              'dietaryRestrictions': profile.dietaryRestrictions,
              'primaryGoal': profile.primaryGoal,
            },
            'inventory': inventory
                .map(
                  (p) => {
                    'name': p['name'] as String? ?? '',
                    'nutriscoreGrade':
                        p['nutriscoreGrade'] as String? ?? '',
                  },
                )
                .toList(),
          },
        )
        .timeout(_timeout);

    if (response.status != 200) {
      throw Exception(
        'Edge Function returned status ${response.status}',
      );
    }

    final json = response.data as Map<String, dynamic>;
    return Right(
      WeeklyMealPlan.fromJson(json).copyWith(isLocalFallback: false),
    );
  }

  /// Wraps [localFallback] in a try/catch so exceptions become
  /// `Left(GenerationFailure)`.
  Either<Failure, WeeklyMealPlan> _safeLocalFallback(UserProfile profile) {
    try {
      return localFallback(profile);
    } catch (e) {
      return Left(GenerationFailure(e.toString()));
    }
  }

  /// Generates a local plan from bundled templates.
  ///
  /// Overridable in tests to simulate local fallback failure.
  Either<Failure, WeeklyMealPlan> localFallback(UserProfile profile) {
    final plan = LocalMealTemplates.generate(
      weekStart: _currentMonday(),
      dietaryRestrictions: profile.dietaryRestrictions,
    );
    return Right(plan.copyWith(isLocalFallback: true));
  }

  /// Returns the Monday of the current week (time stripped).
  DateTime _currentMonday() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }
}
