// Spec: HOME-STATE-001 sc1–sc4
// Design: AD-31, AD-33, AD-35
// TDD: T-06 [GREEN] — Implements HomeState + HomeNotifier to pass T-05 tests.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutriguide_mobile/features/home/data/home_providers.dart';
import 'package:nutriguide_mobile/features/home/domain/home_repository.dart';
import 'package:nutriguide_mobile/features/home/domain/meal_plan.dart';
import 'package:nutriguide_mobile/features/home/domain/wellness_summary.dart';
import 'package:nutriguide_mobile/features/profile/data/profile_providers.dart';
import 'package:nutriguide_mobile/features/profile/domain/profile_repository.dart';
import 'package:nutriguide_mobile/features/profile/domain/user_profile.dart';

// ---------------------------------------------------------------------------
// State — sealed class (AD-33)
// Three variants for exhaustive switch in the UI layer.
// ---------------------------------------------------------------------------

/// Home screen state sealed hierarchy — exhaustive switch enforced by Dart.
///
/// Three variants (AD-33):
/// - [HomeLoading] — intermediate state during initial build (reserved for
///   explicit in-progress flags; AsyncNotifier wraps loading in [AsyncLoading]).
/// - [HomeData] — all 3 sources loaded successfully; carries the data.
/// - [HomeError] — at least one source returned a [Failure]; carries the message.
sealed class HomeState {
  const HomeState();
}

/// Intermediate loading state — used when an explicit HomeState-level loading
/// flag is needed (e.g. after toggleMeal during a slow persistence call).
///
/// In the standard flow, [AsyncNotifier] wraps the build() Future in
/// [AsyncLoading] automatically; this class covers in-state transitions.
class HomeLoading extends HomeState {
  const HomeLoading();
}

/// All 3 data sources resolved successfully.
class HomeData extends HomeState {
  const HomeData({
    required this.wellness,
    required this.mealPlan,
    required this.profile,
  });

  final WellnessSummary wellness;
  final MealPlan mealPlan;
  final UserProfile profile;
}

/// At least one data source returned a [Failure].
class HomeError extends HomeState {
  const HomeError(this.message);

  final String message;
}

// ---------------------------------------------------------------------------
// Provider (AD-31)
// ---------------------------------------------------------------------------

/// Provides [HomeNotifier] as an [AsyncNotifierProvider].
///
/// Override in tests with [ProviderContainer] overrides for
/// [homeRepositoryProvider] and [profileRepositoryProvider].
final homeNotifierProvider =
    AsyncNotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);

// ---------------------------------------------------------------------------
// Notifier (AD-31, AD-35)
// ---------------------------------------------------------------------------

/// Manages Home dashboard state.
///
/// [build] loads all 3 sources in parallel via [Future.wait]:
/// - [HomeRepository.getWellnessSummary]
/// - [HomeRepository.getTodayMealPlan]
/// - [ProfileRepository.getProfile]
///
/// If ANY source returns [Left(Failure)] → [HomeError].
/// All succeed → [HomeData].
///
/// [retry]: re-runs [build] to recover from [HomeError].
/// [toggleMeal]: in-memory meal completion toggle — no persistence (AD-35).
class HomeNotifier extends AsyncNotifier<HomeState> {
  HomeRepository get _homeRepo => ref.read(homeRepositoryProvider);
  ProfileRepository get _profileRepo => ref.read(profileRepositoryProvider);

  @override
  Future<HomeState> build() async {
    final results = await Future.wait([
      _homeRepo.getWellnessSummary(),
      _homeRepo.getTodayMealPlan(),
      _profileRepo.getProfile(),
    ]);

    final wellnessResult = results[0];
    final mealPlanResult = results[1];
    final profileResult = results[2];

    // If ANY source fails → HomeError with the first failure's message.
    if (wellnessResult.isLeft() ||
        mealPlanResult.isLeft() ||
        profileResult.isLeft()) {
      final message = wellnessResult.swap().toNullable()?.message ??
          mealPlanResult.swap().toNullable()?.message ??
          profileResult.swap().toNullable()?.message ??
          'Error al cargar datos';
      return HomeError(message.isEmpty ? 'Error al cargar datos' : message);
    }

    return HomeData(
      wellness: wellnessResult.toNullable()! as WellnessSummary,
      mealPlan: mealPlanResult.toNullable()! as MealPlan,
      profile: profileResult.toNullable()! as UserProfile,
    );
  }

  /// Re-invokes [build] to recover from [HomeError] or refresh data.
  ///
  /// Transitions through [AsyncLoading] before resolving to [HomeData] or
  /// a new [HomeError] — follows the spec HOME-STATE-001 sc3.
  Future<void> retry() async {
    state = const AsyncLoading();
    state = AsyncData(await build());
  }

  /// Toggles [isCompleted] on the meal with [mealId] in the current [HomeData].
  ///
  /// Pure in-memory mutation — no persistence (AD-35). No-op when state is not
  /// [HomeData] (e.g. during loading or error).
  void toggleMeal(String mealId) {
    if (state case AsyncData(:final value)) {
      if (value is! HomeData) return;
      final updatedMeals = value.mealPlan.meals.map((m) {
        if (m.id == mealId) return m.copyWith(isCompleted: !m.isCompleted);
        return m;
      }).toList();
      final updatedPlan = value.mealPlan.copyWith(meals: updatedMeals);
      state = AsyncData(
        HomeData(
          wellness: value.wellness,
          mealPlan: updatedPlan,
          profile: value.profile,
        ),
      );
    }
  }
}
