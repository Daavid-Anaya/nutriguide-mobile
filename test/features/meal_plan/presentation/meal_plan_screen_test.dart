// Spec: MEAL-UI-001 sc1–sc3, MEAL-UI-006 sc1
// TDD: T-47 [RED] — MealPlanScreen widget tests.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';
import 'package:nutriguide_mobile/features/home/domain/meal.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/meal_plan_day.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/weekly_meal_plan.dart';
import 'package:nutriguide_mobile/features/meal_plan/presentation/meal_plan_screen.dart';
import 'package:nutriguide_mobile/features/meal_plan/presentation/providers/meal_plan_notifier.dart';
import 'package:nutriguide_mobile/features/meal_plan/presentation/widgets/macro_summary_card.dart';
import 'package:nutriguide_mobile/features/meal_plan/presentation/widgets/meal_plan_card.dart';
import 'package:nutriguide_mobile/features/meal_plan/presentation/widgets/weekly_calendar_strip.dart';

// ---------------------------------------------------------------------------
// Fake MealPlanNotifier — seeds state without invoking real build()
// ---------------------------------------------------------------------------

class FakeMealPlanNotifier extends MealPlanNotifier {
  FakeMealPlanNotifier(this._seeded);

  final MealPlanState _seeded;

  @override
  Future<MealPlanState> build() async => _seeded;
}

/// Fake notifier that tracks whether loadWeek was called.
class _CapturingMealPlanNotifier extends MealPlanNotifier {
  _CapturingMealPlanNotifier({required this.seedState});

  final MealPlanState seedState;
  bool loadWeekCalled = false;

  @override
  Future<MealPlanState> build() async => seedState;

  @override
  Future<void> loadWeek() async {
    loadWeekCalled = true;
    state = AsyncData(seedState);
  }
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

WeeklyMealPlan _makeWeeklyPlan({List<MealPlanDay> days = const []}) {
  return WeeklyMealPlan.create(
    id: 'plan-1',
    weekStartDate: DateTime(2026, 5, 18),
    days: days,
  );
}

MealPlanDay _makeDay() {
  return MealPlanDay(
    date: DateTime(2026, 5, 18),
    meals: [
      const Meal(
        id: 'meal-1',
        name: 'Avena con frutas',
        mealType: 'breakfast',
        calories: 350,
        proteins: 20.0,
        carbs: 45.0,
        fats: 8.0,
      ),
      const Meal(
        id: 'meal-2',
        name: 'Pollo y Arroz',
        mealType: 'lunch',
        calories: 500,
        proteins: 35.0,
        carbs: 55.0,
        fats: 12.0,
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Helper — wraps MealPlanScreen in ProviderScope + MaterialApp
// ---------------------------------------------------------------------------

Widget buildSubject(MealPlanState seedState) {
  return ProviderScope(
    overrides: [
      mealPlanNotifierProvider
          .overrideWith(() => FakeMealPlanNotifier(seedState)),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const MealPlanScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('MealPlanScreen', () {
    // Scenario 1: Loading state shown
    testWidgets(
      'sc1: shows CircularProgressIndicator when state is MealPlanLoading',
      (tester) async {
        await tester.pumpWidget(buildSubject(const MealPlanLoading()));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsAtLeast(1));
        expect(find.byType(WeeklyCalendarStrip), findsNothing);
      },
    );

    // Scenario 2: MealPlanData renders WeeklyCalendarStrip + MacroSummaryCard + MealPlanCard list
    testWidgets(
      'sc2: MealPlanData renders WeeklyCalendarStrip, MacroSummaryCard, MealPlanCard list',
      (tester) async {
        final day = _makeDay();
        final plan = _makeWeeklyPlan(days: [day]);
        final state = MealPlanData(
          weeklyPlan: plan,
          selectedDate: DateTime(2026, 5, 18),
        );

        await tester.pumpWidget(buildSubject(state));
        await tester.pump();

        expect(find.byType(WeeklyCalendarStrip), findsOneWidget);
        expect(find.byType(MacroSummaryCard), findsOneWidget);
        expect(find.byType(MealPlanCard), findsWidgets);
        // Verify meal names are shown
        expect(find.text('Avena con frutas'), findsOneWidget);
      },
    );

    // Scenario 3: Empty state CTA visible when days list is empty
    testWidgets(
      'sc3: shows empty state with Generar CTA when days list is empty',
      (tester) async {
        final plan = _makeWeeklyPlan(days: []); // empty
        final state = MealPlanData(
          weeklyPlan: plan,
          selectedDate: DateTime(2026, 5, 18),
        );

        await tester.pumpWidget(buildSubject(state));
        await tester.pump();

        // Should show some "Generar" text for generating a plan
        expect(find.textContaining('Generar'), findsAtLeast(1));
        // WeeklyCalendarStrip may still be shown in empty state
        // But no MealPlanCard should be present
        expect(find.byType(MealPlanCard), findsNothing);
      },
    );

    // Scenario 4: Pull-to-refresh calls loadWeek
    testWidgets(
      'sc4: pull-to-refresh calls loadWeek on notifier',
      (tester) async {
        final day = _makeDay();
        final plan = _makeWeeklyPlan(days: [day]);
        final seedState = MealPlanData(
          weeklyPlan: plan,
          selectedDate: DateTime(2026, 5, 18),
        );

        late _CapturingMealPlanNotifier capturedNotifier;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              mealPlanNotifierProvider.overrideWith(() {
                capturedNotifier = _CapturingMealPlanNotifier(
                  seedState: seedState,
                );
                return capturedNotifier;
              }),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const MealPlanScreen(),
            ),
          ),
        );
        await tester.pump();

        // Pull to refresh — use first SingleChildScrollView (the outer one from RefreshIndicator)
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, 300),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(capturedNotifier.loadWeekCalled, isTrue);
      },
    );

    // Scenario 5: MealPlanGenerating → overlay visible
    testWidgets(
      'sc5: MealPlanGenerating state shows generating overlay text',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(const MealPlanGenerating()),
        );
        await tester.pump();

        expect(find.textContaining('Generando'), findsAtLeast(1));
      },
    );
  });
}
