// Spec: HOME-STATE-001 sc1–sc4
// TDD: T-05 [RED] — Tests FAIL until home_notifier.dart is created (T-06).
// Design: AD-31, AD-33, AD-35

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/home/data/home_providers.dart';
import 'package:nutriguide_mobile/features/home/domain/home_repository.dart';
import 'package:nutriguide_mobile/features/home/domain/meal.dart';
import 'package:nutriguide_mobile/features/home/domain/meal_plan.dart';
import 'package:nutriguide_mobile/features/home/domain/wellness_summary.dart';
import 'package:nutriguide_mobile/features/home/presentation/providers/home_notifier.dart';
import 'package:nutriguide_mobile/features/profile/data/profile_providers.dart';
import 'package:nutriguide_mobile/features/profile/domain/profile_repository.dart';
import 'package:nutriguide_mobile/features/profile/domain/user_profile.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------
class MockHomeRepository extends Mock implements HomeRepository {}
class MockProfileRepository extends Mock implements ProfileRepository {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------
final _stubWellness = WellnessSummary(
  healthScore: 70,
  streak: 0,
  budgetSpent: 55.0,
  budgetTotal: 200.0,
);

final _stubMealPlan = MealPlan(
  id: 'stub-today',
  date: DateTime(2026, 5, 15),
  meals: [
    const Meal(
      id: 'meal-1',
      name: 'Avena con frutas',
      mealType: MealType.breakfast,
      calories: 350,
      tags: ['Alto en fibra'],
      isCompleted: false,
    ),
    const Meal(
      id: 'meal-2',
      name: 'Ensalada mediterránea',
      mealType: MealType.lunch,
      calories: 480,
      tags: ['Proteína'],
      isCompleted: false,
    ),
    const Meal(
      id: 'meal-3',
      name: 'Salmón con verduras',
      mealType: MealType.dinner,
      calories: 520,
      tags: ['Omega-3'],
      isCompleted: false,
    ),
  ],
);

final _stubProfile = UserProfile(
  id: '',
  name: 'Usuario',
  email: '',
  avatarUrl: null,
);

// ---------------------------------------------------------------------------
// Helper — ProviderContainer with mock repos injected
// ---------------------------------------------------------------------------
ProviderContainer _makeContainer({
  required MockHomeRepository homeRepo,
  required MockProfileRepository profileRepo,
}) {
  return ProviderContainer(
    overrides: [
      homeRepositoryProvider.overrideWithValue(homeRepo),
      profileRepositoryProvider.overrideWithValue(profileRepo),
    ],
  );
}

void main() {
  // ---------------------------------------------------------------------------
  // HomeState sealed class — structural tests (AD-33)
  // ---------------------------------------------------------------------------
  group('HomeState sealed class', () {
    test('HomeLoading is a valid HomeState instance', () {
      const state = HomeLoading();

      expect(state, isA<HomeState>());
      expect(state, isA<HomeLoading>());
    });

    test('HomeData holds wellness, mealPlan, and profile', () {
      final state = HomeData(
        wellness: _stubWellness,
        mealPlan: _stubMealPlan,
        profile: _stubProfile,
      );

      expect(state, isA<HomeState>());
      expect(state.wellness.healthScore, equals(70));
      expect(state.mealPlan.meals, hasLength(3));
      expect(state.profile.name, equals('Usuario'));
    });

    test('HomeError holds a non-empty message', () {
      const state = HomeError('Error al cargar datos');

      expect(state, isA<HomeState>());
      expect(state.message, equals('Error al cargar datos'));
    });

    test('sealed class switch is exhaustive over all 3 variants', () {
      final states = <HomeState>[
        const HomeLoading(),
        HomeData(
          wellness: _stubWellness,
          mealPlan: _stubMealPlan,
          profile: _stubProfile,
        ),
        const HomeError('fail'),
      ];

      final labels = states.map((s) => switch (s) {
            HomeLoading() => 'loading',
            HomeData(:final profile) => 'data:${profile.name}',
            HomeError(:final message) => 'error:$message',
          }).toList();

      expect(labels, equals(['loading', 'data:Usuario', 'error:fail']));
    });
  });

  // ---------------------------------------------------------------------------
  // HomeNotifier — behavior tests
  // ---------------------------------------------------------------------------
  group('HomeNotifier', () {
    late MockHomeRepository mockHomeRepo;
    late MockProfileRepository mockProfileRepo;
    late ProviderContainer container;

    setUp(() {
      mockHomeRepo = MockHomeRepository();
      mockProfileRepo = MockProfileRepository();
      container = _makeContainer(
        homeRepo: mockHomeRepo,
        profileRepo: mockProfileRepo,
      );
    });

    tearDown(() => container.dispose());

    // -------------------------------------------------------------------------
    // HOME-STATE-001 sc1 — build() resolves to HomeData on success (AD-31)
    // -------------------------------------------------------------------------
    test('sc1 — build() resolves to HomeData when all 3 sources return Right', () async {
      when(() => mockHomeRepo.getWellnessSummary())
          .thenAnswer((_) async => Right(_stubWellness));
      when(() => mockHomeRepo.getTodayMealPlan())
          .thenAnswer((_) async => Right(_stubMealPlan));
      when(() => mockProfileRepo.getProfile())
          .thenAnswer((_) async => Right(_stubProfile));

      final asyncValue =
          await container.read(homeNotifierProvider.future);

      expect(asyncValue, isA<HomeData>());
      final data = asyncValue as HomeData;
      expect(data.wellness.healthScore, equals(70));
      expect(data.mealPlan.meals, hasLength(3));
      expect(data.profile.name, equals('Usuario'));
    });

    // TRIANGULATE sc1: build() produces HomeData with the actual data from repos
    test('sc1 triangulate — HomeData contains the exact values from each source', () async {
      final differentWellness = WellnessSummary(
        healthScore: 50,
        streak: 3,
        budgetSpent: 120.0,
        budgetTotal: 200.0,
      );
      final differentProfile = UserProfile(
        id: '',
        name: 'Ana',
        email: '',
        avatarUrl: 'https://example.com/ana.jpg',
      );

      when(() => mockHomeRepo.getWellnessSummary())
          .thenAnswer((_) async => Right(differentWellness));
      when(() => mockHomeRepo.getTodayMealPlan())
          .thenAnswer((_) async => Right(_stubMealPlan));
      when(() => mockProfileRepo.getProfile())
          .thenAnswer((_) async => Right(differentProfile));

      final asyncValue = await container.read(homeNotifierProvider.future);

      expect(asyncValue, isA<HomeData>());
      final data = asyncValue as HomeData;
      expect(data.wellness.healthScore, equals(50));
      expect(data.wellness.streak, equals(3));
      expect(data.profile.name, equals('Ana'));
      expect(data.profile.avatarUrl, equals('https://example.com/ana.jpg'));
    });

    // -------------------------------------------------------------------------
    // HOME-STATE-001 sc2 — build() → HomeError when getWellnessSummary fails
    // -------------------------------------------------------------------------
    test('sc2 — build() resolves to HomeError when getWellnessSummary returns Left', () async {
      when(() => mockHomeRepo.getWellnessSummary())
          .thenAnswer((_) async => const Left(CacheFailure('disk error')));
      when(() => mockHomeRepo.getTodayMealPlan())
          .thenAnswer((_) async => Right(_stubMealPlan));
      when(() => mockProfileRepo.getProfile())
          .thenAnswer((_) async => Right(_stubProfile));

      final asyncValue = await container.read(homeNotifierProvider.future);

      expect(asyncValue, isA<HomeError>());
      final error = asyncValue as HomeError;
      expect(error.message, isNotEmpty);
    });

    // -------------------------------------------------------------------------
    // HOME-STATE-001 sc4 — Partial failure (one source fails) triggers HomeError
    // -------------------------------------------------------------------------
    test('sc4 — build() resolves to HomeError when getTodayMealPlan returns Left', () async {
      when(() => mockHomeRepo.getWellnessSummary())
          .thenAnswer((_) async => Right(_stubWellness));
      when(() => mockHomeRepo.getTodayMealPlan())
          .thenAnswer((_) async => const Left(CacheFailure('no plan')));
      when(() => mockProfileRepo.getProfile())
          .thenAnswer((_) async => Right(_stubProfile));

      final asyncValue = await container.read(homeNotifierProvider.future);

      expect(asyncValue, isA<HomeError>());
      final error = asyncValue as HomeError;
      expect(error.message, isNotEmpty);
    });

    // TRIANGULATE sc2/sc4: getProfile failure also produces HomeError
    test('sc4 triangulate — build() resolves to HomeError when getProfile returns Left', () async {
      when(() => mockHomeRepo.getWellnessSummary())
          .thenAnswer((_) async => Right(_stubWellness));
      when(() => mockHomeRepo.getTodayMealPlan())
          .thenAnswer((_) async => Right(_stubMealPlan));
      when(() => mockProfileRepo.getProfile())
          .thenAnswer((_) async => const Left(CacheFailure('no profile')));

      final asyncValue = await container.read(homeNotifierProvider.future);

      expect(asyncValue, isA<HomeError>());
    });

    // -------------------------------------------------------------------------
    // HOME-STATE-001 sc3 — toggleMeal(mealId) flips isCompleted in state (AD-35)
    // -------------------------------------------------------------------------
    test('sc3 — toggleMeal() flips isCompleted for the targeted meal', () async {
      when(() => mockHomeRepo.getWellnessSummary())
          .thenAnswer((_) async => Right(_stubWellness));
      when(() => mockHomeRepo.getTodayMealPlan())
          .thenAnswer((_) async => Right(_stubMealPlan));
      when(() => mockProfileRepo.getProfile())
          .thenAnswer((_) async => Right(_stubProfile));

      // Wait for build()
      await container.read(homeNotifierProvider.future);

      // Initial state: meal-1 is NOT completed
      final beforeState =
          container.read(homeNotifierProvider).value as HomeData;
      expect(
        beforeState.mealPlan.meals.firstWhere((m) => m.id == 'meal-1').isCompleted,
        isFalse,
      );

      // Toggle meal-1
      container.read(homeNotifierProvider.notifier).toggleMeal('meal-1');

      final afterState =
          container.read(homeNotifierProvider).value as HomeData;
      expect(
        afterState.mealPlan.meals.firstWhere((m) => m.id == 'meal-1').isCompleted,
        isTrue,
      );
      // Other meals are unchanged
      expect(
        afterState.mealPlan.meals.firstWhere((m) => m.id == 'meal-2').isCompleted,
        isFalse,
      );
    });

    // TRIANGULATE sc3: toggle twice restores original state (in-memory only, AD-35)
    test('sc3 triangulate — toggleMeal() twice restores original isCompleted', () async {
      when(() => mockHomeRepo.getWellnessSummary())
          .thenAnswer((_) async => Right(_stubWellness));
      when(() => mockHomeRepo.getTodayMealPlan())
          .thenAnswer((_) async => Right(_stubMealPlan));
      when(() => mockProfileRepo.getProfile())
          .thenAnswer((_) async => Right(_stubProfile));

      await container.read(homeNotifierProvider.future);

      final notifier = container.read(homeNotifierProvider.notifier);
      notifier.toggleMeal('meal-2');
      notifier.toggleMeal('meal-2');

      final state = container.read(homeNotifierProvider).value as HomeData;
      expect(
        state.mealPlan.meals.firstWhere((m) => m.id == 'meal-2').isCompleted,
        isFalse,
      );
    });

    // -------------------------------------------------------------------------
    // HOME-STATE-001 sc3 — retry() re-runs build() (AD-31)
    // -------------------------------------------------------------------------
    test('sc3 — retry() re-invokes build() and produces HomeData on success', () async {
      // First call: wellness fails → HomeError
      when(() => mockHomeRepo.getWellnessSummary())
          .thenAnswer((_) async => const Left(CacheFailure('initial error')));
      when(() => mockHomeRepo.getTodayMealPlan())
          .thenAnswer((_) async => Right(_stubMealPlan));
      when(() => mockProfileRepo.getProfile())
          .thenAnswer((_) async => Right(_stubProfile));

      final errorState = await container.read(homeNotifierProvider.future);
      expect(errorState, isA<HomeError>());

      // Second call: all succeed → HomeData
      when(() => mockHomeRepo.getWellnessSummary())
          .thenAnswer((_) async => Right(_stubWellness));

      await container.read(homeNotifierProvider.notifier).retry();

      final successState = container.read(homeNotifierProvider).value;
      expect(successState, isA<HomeData>());
    });

    // TRIANGULATE sc3: retry() after success still calls all 3 repos again
    test('sc3 triangulate — retry() re-calls all 3 sources', () async {
      when(() => mockHomeRepo.getWellnessSummary())
          .thenAnswer((_) async => Right(_stubWellness));
      when(() => mockHomeRepo.getTodayMealPlan())
          .thenAnswer((_) async => Right(_stubMealPlan));
      when(() => mockProfileRepo.getProfile())
          .thenAnswer((_) async => Right(_stubProfile));

      await container.read(homeNotifierProvider.future);
      await container.read(homeNotifierProvider.notifier).retry();

      // Each source called twice: once by build(), once by retry()
      verify(() => mockHomeRepo.getWellnessSummary()).called(2);
      verify(() => mockHomeRepo.getTodayMealPlan()).called(2);
      verify(() => mockProfileRepo.getProfile()).called(2);
    });
  });
}
