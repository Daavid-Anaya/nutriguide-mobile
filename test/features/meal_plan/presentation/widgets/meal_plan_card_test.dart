// Spec: MEAL-UI-004 sc1–sc6
// TDD: T-45 [RED] — MealPlanCard widget tests.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';
import 'package:nutriguide_mobile/features/home/domain/meal.dart';
import 'package:nutriguide_mobile/features/meal_plan/presentation/widgets/meal_plan_card.dart';

/// Base meal stub for testing.
const _breakfastMeal = Meal(
  id: 'meal-1',
  name: 'Avena con frutas',
  mealType: 'breakfast',
  calories: 350,
  proteins: 25.0,
  carbs: 40.0,
  fats: 10.0,
  isCompleted: false,
);

/// Pumps [MealPlanCard] in a minimal MaterialApp with app theme.
Future<void> pumpCard(
  WidgetTester tester,
  Meal meal, {
  void Function(bool)? onToggle,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: MealPlanCard(meal: meal, onToggle: onToggle),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('MealPlanCard', () {
    // Scenario 1: mealType label and name shown
    testWidgets(
      'sc1: shows mealType uppercased and meal name',
      (tester) async {
        await pumpCard(tester, _breakfastMeal);

        expect(find.text('BREAKFAST'), findsOneWidget);
        expect(find.text('Avena con frutas'), findsOneWidget);
      },
    );

    // Scenario 2: Macros row shown when proteins non-null
    testWidgets(
      'sc2: shows macros row with P, C, F values when proteins non-null',
      (tester) async {
        await pumpCard(tester, _breakfastMeal);

        // Should show protein value
        expect(find.textContaining('25'), findsAtLeast(1));
        // Should show carbs value
        expect(find.textContaining('40'), findsAtLeast(1));
        // Should show fats value
        expect(find.textContaining('10'), findsAtLeast(1));
        // Should have macro labels
        expect(find.textContaining('P:'), findsOneWidget);
        expect(find.textContaining('C:'), findsOneWidget);
        expect(find.textContaining('F:'), findsOneWidget);
      },
    );

    // Scenario 3: Null macros → "—" in macros row
    testWidgets(
      'sc3: shows "—" when proteins/carbs/fats are all null',
      (tester) async {
        const nullMacroMeal = Meal(
          id: 'meal-2',
          name: 'Mystery Meal',
          mealType: 'lunch',
          calories: 300,
          // proteins, carbs, fats all null
        );
        await pumpCard(tester, nullMacroMeal);

        // The macros row shows dashes for null values
        // P: —  C: —  F: —
        expect(find.textContaining('—'), findsAtLeast(1));
      },
    );

    // Scenario 4: Uncompleted → checkbox unchecked
    testWidgets(
      'sc4: checkbox is unchecked when isCompleted=false',
      (tester) async {
        await pumpCard(tester, _breakfastMeal);

        final checkboxFinder = find.byType(Checkbox);
        expect(checkboxFinder, findsOneWidget);
        final checkbox = tester.widget<Checkbox>(checkboxFinder);
        expect(checkbox.value, false);
      },
    );

    // Scenario 5: Tap checkbox fires onToggle(true)
    testWidgets(
      'sc5: tapping checkbox calls onToggle(true) when isCompleted=false',
      (tester) async {
        bool? toggledValue;
        int callCount = 0;

        await pumpCard(
          tester,
          _breakfastMeal,
          onToggle: (v) {
            toggledValue = v;
            callCount++;
          },
        );

        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        expect(callCount, 1);
        expect(toggledValue, true);
      },
    );

    // Scenario 6: Completed meal → checked checkbox
    testWidgets(
      'sc6: checkbox is checked when isCompleted=true',
      (tester) async {
        const completedMeal = Meal(
          id: 'meal-1',
          name: 'Avena con frutas',
          mealType: 'breakfast',
          isCompleted: true,
        );
        await pumpCard(tester, completedMeal);

        final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
        expect(checkbox.value, true);
      },
    );
  });
}
