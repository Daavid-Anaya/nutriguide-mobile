// Spec: MEAL-UI-005 sc1–sc3
// TDD: T-49 [RED] — MealPlanDayScreen widget tests.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';
import 'package:nutriguide_mobile/features/home/domain/meal.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/meal_plan_day.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/weekly_meal_plan.dart';
import 'package:nutriguide_mobile/features/meal_plan/presentation/meal_plan_day_screen.dart';
import 'package:nutriguide_mobile/features/meal_plan/presentation/providers/meal_plan_notifier.dart';
import 'package:nutriguide_mobile/features/meal_plan/presentation/widgets/macro_summary_card.dart';
import 'package:nutriguide_mobile/features/meal_plan/presentation/widgets/meal_plan_card.dart';

// ---------------------------------------------------------------------------
// Fake notifiers for testing
// ---------------------------------------------------------------------------

class FakeMealPlanNotifier extends MealPlanNotifier {
  FakeMealPlanNotifier(this._seeded);

  final MealPlanState _seeded;

  @override
  Future<MealPlanState> build() async => _seeded;
}

/// Notifier that captures toggleMealCompletion and generateShoppingList calls.
class _CapturingDayScreenNotifier extends MealPlanNotifier {
  _CapturingDayScreenNotifier({required this.seedState});

  final MealPlanState seedState;

  String? lastToggledMealId;
  bool? lastToggledValue;
  bool generateShoppingListCalled = false;

  @override
  Future<MealPlanState> build() async => seedState;

  @override
  Future<void> toggleMealCompletion(String mealId, bool isCompleted) async {
    lastToggledMealId = mealId;
    lastToggledValue = isCompleted;
    // Update state to reflect the toggle
    final current = state;
    if (current is AsyncData<MealPlanState>) {
      final data = current.value;
      if (data is MealPlanData) {
        final updatedDays = data.weeklyPlan.days.map((day) {
          final updatedMeals = day.meals.map((meal) {
            if (meal.id == mealId) return meal.copyWith(isCompleted: isCompleted);
            return meal;
          }).toList();
          return day.copyWith(meals: updatedMeals);
        }).toList();
        final updatedPlan = data.weeklyPlan.copyWith(days: updatedDays);
        state = AsyncData(
          MealPlanData(
            weeklyPlan: updatedPlan,
            selectedDate: data.selectedDate,
          ),
        );
      }
    }
  }

  @override
  Future<void> generateShoppingList() async {
    generateShoppingListCalled = true;
  }
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

/// Creates a [MealPlanDay] for '2026-05-18' with 3 meals.
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
        isCompleted: false,
      ),
      const Meal(
        id: 'meal-2',
        name: 'Pollo y Arroz',
        mealType: 'lunch',
        calories: 500,
        proteins: 35.0,
        carbs: 55.0,
        fats: 12.0,
        isCompleted: false,
      ),
      const Meal(
        id: 'meal-3',
        name: 'Ensalada Mediterránea',
        mealType: 'dinner',
        calories: 400,
        proteins: 18.0,
        carbs: 30.0,
        fats: 15.0,
        isCompleted: false,
      ),
    ],
  );
}

MealPlanData _makeMealPlanData() {
  final day = _makeDay();
  final plan = WeeklyMealPlan.create(
    id: 'plan-1',
    weekStartDate: DateTime(2026, 5, 18),
    days: [day],
  );
  return MealPlanData(
    weeklyPlan: plan,
    selectedDate: DateTime(2026, 5, 18),
  );
}

// ---------------------------------------------------------------------------
// Helper — wraps MealPlanDayScreen in ProviderScope + MaterialApp
// ---------------------------------------------------------------------------

Widget buildSubject(MealPlanState seedState, {String date = '2026-05-18'}) {
  return ProviderScope(
    overrides: [
      mealPlanNotifierProvider
          .overrideWith(() => FakeMealPlanNotifier(seedState)),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: MealPlanDayScreen(date: date),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('MealPlanDayScreen', () {
    // Scenario 1: Screen renders daily meals with MacroSummaryCard + MealPlanCards
    testWidgets(
      'sc1: renders MacroSummaryCard and 3 MealPlanCard widgets for 2026-05-18',
      (tester) async {
        final state = _makeMealPlanData();
        await tester.pumpWidget(buildSubject(state, date: '2026-05-18'));
        await tester.pump();

        // MacroSummaryCard shown
        expect(find.byType(MacroSummaryCard), findsOneWidget);

        // 3 MealPlanCards shown
        expect(find.byType(MealPlanCard), findsNWidgets(3));

        // Meal names visible
        expect(find.text('Avena con frutas'), findsOneWidget);
        expect(find.text('Pollo y Arroz'), findsOneWidget);
        expect(find.text('Ensalada Mediterránea'), findsOneWidget);
      },
    );

    // Scenario 2: Shopping list FAB visible and triggers generateShoppingList
    testWidgets(
      'sc2: FAB is visible and tapping it calls generateShoppingList',
      (tester) async {
        final seedState = _makeMealPlanData();
        late _CapturingDayScreenNotifier captured;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              mealPlanNotifierProvider.overrideWith(() {
                captured = _CapturingDayScreenNotifier(seedState: seedState);
                return captured;
              }),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const MealPlanDayScreen(date: '2026-05-18'),
            ),
          ),
        );
        await tester.pump();

        // FAB should be visible
        expect(find.byType(FloatingActionButton), findsOneWidget);

        // Tap the FAB
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump();

        expect(captured.generateShoppingListCalled, isTrue);
      },
    );

    // Scenario 3: Completion toggle fires toggleMealCompletion
    testWidgets(
      'sc3: tapping first checkbox calls toggleMealCompletion with correct mealId',
      (tester) async {
        final seedState = _makeMealPlanData();
        late _CapturingDayScreenNotifier captured;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              mealPlanNotifierProvider.overrideWith(() {
                captured = _CapturingDayScreenNotifier(seedState: seedState);
                return captured;
              }),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const MealPlanDayScreen(date: '2026-05-18'),
            ),
          ),
        );
        await tester.pump();

        // Find first Checkbox (first MealPlanCard)
        final checkboxFinder = find.byType(Checkbox);
        expect(checkboxFinder, findsNWidgets(3));

        // Tap the first checkbox
        await tester.tap(checkboxFinder.first);
        await tester.pump();

        // toggleMealCompletion should have been called
        expect(captured.lastToggledMealId, 'meal-1');
        expect(captured.lastToggledValue, true);
      },
    );
  });
}
