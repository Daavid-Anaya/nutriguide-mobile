// Design: AD-81
// Setup: T-26 — wire MealPlanRepository + MealPlanGeneratorService providers

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nutriguide_mobile/core/storage/storage_providers.dart';
import 'package:nutriguide_mobile/core/supabase/supabase_providers.dart';
import 'package:nutriguide_mobile/features/meal_plan/data/meal_plan_generator_service.dart';
import 'package:nutriguide_mobile/features/meal_plan/data/meal_plan_repository_impl.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/meal_plan_repository.dart';

/// Provides [MealPlanRepository] (abstract interface) backed by
/// [MealPlanRepositoryImpl] wired to [mealPlansBoxProvider] (Hive)
/// and [supabaseClientProvider] (Supabase).
///
/// Typed as [MealPlanRepository] so callers depend on the contract, not
/// the implementation — consistent with AD-65, AD-81.
final mealPlanRepositoryProvider = Provider<MealPlanRepository>((ref) {
  return MealPlanRepositoryImpl(
    supabase: ref.watch(supabaseClientProvider),
    mealPlansBox: ref.watch(mealPlansBoxProvider),
  );
});

/// Provides [MealPlanGeneratorService] with Supabase client injected.
///
/// Service is stateless — tries Edge Function first, falls back to
/// [LocalMealTemplates] on any failure (AD-66, AD-68).
final mealPlanGeneratorServiceProvider =
    Provider<MealPlanGeneratorService>((ref) {
  return MealPlanGeneratorService(
    supabase: ref.watch(supabaseClientProvider),
  );
});
