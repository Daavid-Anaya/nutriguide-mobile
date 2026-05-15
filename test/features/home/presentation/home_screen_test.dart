// Spec: HOME-UI-001 sc1–sc4
// Design: AD-31, AD-33, AD-35
// TDD: T-17 [RED] → T-18 [GREEN] — Replaces placeholder tests with full HomeScreen integration tests.
//
// Testing strategy (AD-18 / AD-26):
// Override homeNotifierProvider via FakeHomeNotifier that returns a preset HomeState.
// All tests use ProviderScope with the override + AppTheme.light.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';
import 'package:nutriguide_mobile/core/widgets/loading_indicator.dart';
import 'package:nutriguide_mobile/features/home/domain/meal.dart';
import 'package:nutriguide_mobile/features/home/domain/meal_plan.dart';
import 'package:nutriguide_mobile/features/home/domain/wellness_summary.dart';
import 'package:nutriguide_mobile/features/home/presentation/home_screen.dart';
import 'package:nutriguide_mobile/features/home/presentation/providers/home_notifier.dart';
import 'package:nutriguide_mobile/features/home/presentation/widgets/greeting_section.dart';
import 'package:nutriguide_mobile/features/home/presentation/widgets/health_stats_row.dart';
import 'package:nutriguide_mobile/features/home/presentation/widgets/home_header.dart';
import 'package:nutriguide_mobile/features/home/presentation/widgets/todays_plan_section.dart';
import 'package:nutriguide_mobile/features/home/presentation/widgets/wellness_budget_card.dart';
import 'package:nutriguide_mobile/features/profile/domain/user_profile.dart';

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

final _testWellness = WellnessSummary(
  healthScore: 75,
  streak: 5,
  budgetSpent: 55.0,
  budgetTotal: 200.0,
);

final _testProfile = UserProfile(
  id: 'user-1',
  name: 'Lucía',
  email: 'lucia@test.com',
  avatarUrl: null,
);

final _testMealPlan = MealPlan(
  id: 'plan-1',
  date: DateTime(2026, 5, 15),
  meals: [
    Meal(
      id: 'meal-1',
      name: 'Avocado Toast',
      mealType: MealType.breakfast,
      calories: 350,
    ),
    Meal(
      id: 'meal-2',
      name: 'Quinoa Bowl',
      mealType: MealType.lunch,
      calories: 520,
    ),
    Meal(
      id: 'meal-3',
      name: 'Grilled Salmon',
      mealType: MealType.dinner,
      calories: 480,
    ),
  ],
);

final _testHomeData = HomeData(
  wellness: _testWellness,
  mealPlan: _testMealPlan,
  profile: _testProfile,
);

// ---------------------------------------------------------------------------
// FakeHomeNotifier — seeds state without invoking the real build()
// ---------------------------------------------------------------------------

class FakeHomeNotifier extends HomeNotifier {
  FakeHomeNotifier(this._seeded);

  final HomeState _seeded;

  @override
  Future<HomeState> build() async => _seeded;

  @override
  Future<void> retry() async {
    state = AsyncData(_seeded);
  }
}

// ---------------------------------------------------------------------------
// _CapturingHomeNotifier — records retry() calls for pull-to-refresh test
// ---------------------------------------------------------------------------

class _CapturingHomeNotifier extends HomeNotifier {
  _CapturingHomeNotifier({required this.onRetry}) : retryCalled = false;

  bool retryCalled;
  final VoidCallback onRetry;

  @override
  Future<HomeState> build() async => _testHomeData;

  @override
  Future<void> retry() async {
    retryCalled = true;
    onRetry();
    state = AsyncData(_testHomeData);
  }
}

// ---------------------------------------------------------------------------
// Helper — builds HomeScreen with homeNotifierProvider overridden
// ---------------------------------------------------------------------------

Widget buildSubject(HomeState seedState) {
  return ProviderScope(
    overrides: [
      homeNotifierProvider.overrideWith(() => FakeHomeNotifier(seedState)),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const HomeScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests — HOME-UI-001 sc1–sc4
// ---------------------------------------------------------------------------

void main() {
  group('HomeScreen', () {
    // ── HOME-UI-001 sc2 ────────────────────────────────────────────────────
    // HomeData → all sections visible (HomeHeader, GreetingSection,
    // WellnessBudgetCard, HealthStatsRow, TodaysPlanSection)
    testWidgets(
      'sc2 — HomeData state renders all 5 sections',
      (tester) async {
        await tester.pumpWidget(buildSubject(_testHomeData));
        await tester.pump(); // FakeHomeNotifier.build() resolves

        expect(find.byType(HomeHeader), findsOneWidget);
        expect(find.byType(GreetingSection), findsOneWidget);
        expect(find.byType(WellnessBudgetCard), findsOneWidget);
        expect(find.byType(HealthStatsRow), findsOneWidget);
        expect(find.byType(TodaysPlanSection), findsOneWidget);
      },
    );

    // TRIANGULATE sc2 — specific content from data is rendered
    testWidgets(
      'sc2 triangulate — HomeData renders user name and budget values',
      (tester) async {
        await tester.pumpWidget(buildSubject(_testHomeData));
        await tester.pump();

        // GreetingSection renders "Hola, Lucía"
        expect(find.text('Hola, Lucía'), findsOneWidget);
        // WellnessBudgetCard renders budget text
        expect(find.textContaining('55'), findsAtLeastNWidgets(1));
      },
    );

    // ── HOME-UI-001 sc1 ────────────────────────────────────────────────────
    // AsyncLoading → LoadingIndicator centered, no section widgets
    testWidgets(
      'sc1 — AsyncLoading state shows LoadingIndicator and hides sections',
      (tester) async {
        // Seed HomeLoading — the notifier returns HomeLoading as its HomeState.
        // FakeHomeNotifier wraps it in AsyncData(HomeLoading()) synchronously.
        await tester.pumpWidget(buildSubject(const HomeLoading()));
        await tester.pump();

        expect(find.byType(LoadingIndicator), findsOneWidget);
        expect(find.byType(HomeHeader), findsNothing);
        expect(find.byType(WellnessBudgetCard), findsNothing);
      },
    );

    // TRIANGULATE sc1 — verify LoadingIndicator (not a section widget) is the
    // root content when state is HomeLoading
    testWidgets(
      'sc1 triangulate — HomeLoading shows CircularProgressIndicator (inside LoadingIndicator)',
      (tester) async {
        await tester.pumpWidget(buildSubject(const HomeLoading()));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(TodaysPlanSection), findsNothing);
      },
    );

    // ── HOME-UI-001 sc3 ────────────────────────────────────────────────────
    // HomeError → error message + ElevatedButton retry visible
    testWidgets(
      'sc3 — HomeError state shows error message and retry button',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(const HomeError('Error al cargar datos')),
        );
        await tester.pump();

        expect(find.text('Error al cargar datos'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
      },
    );

    // TRIANGULATE sc3 — retry button text is "Reintentar"
    testWidgets(
      'sc3 triangulate — retry ElevatedButton has text "Reintentar"',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(const HomeError('Error al cargar datos')),
        );
        await tester.pump();

        expect(
          find.widgetWithText(ElevatedButton, 'Reintentar'),
          findsOneWidget,
        );
        expect(find.byType(HomeHeader), findsNothing);
      },
    );

    // ── HOME-UI-001 sc4 ────────────────────────────────────────────────────
    // Pull-to-refresh calls notifier.retry()
    testWidgets(
      'sc4 — pull-to-refresh triggers homeNotifier.retry()',
      (tester) async {
        bool retryCalled = false;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              homeNotifierProvider.overrideWith(
                () => _CapturingHomeNotifier(
                  onRetry: () => retryCalled = true,
                ),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const HomeScreen(),
            ),
          ),
        );
        await tester.pump(); // build() resolves to HomeData

        // Pull down to trigger RefreshIndicator
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, 300),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(retryCalled, isTrue);
      },
    );
  });
}
