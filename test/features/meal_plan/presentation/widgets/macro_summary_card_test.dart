// Spec: MEAL-UI-003 sc1–sc2
// TDD: T-43 [RED] — MacroSummaryCard widget tests.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';
import 'package:nutriguide_mobile/features/home/domain/meal.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/meal_plan_day.dart';
import 'package:nutriguide_mobile/features/meal_plan/presentation/widgets/macro_summary_card.dart';

/// Creates a [MealPlanDay] with two meals having full macro data.
MealPlanDay _makeDayWithMacros() {
  return MealPlanDay(
    date: DateTime(2026, 5, 18),
    meals: [
      const Meal(
        id: 'meal-1',
        name: 'Avena',
        mealType: 'breakfast',
        calories: 600,
        proteins: 30.0,
        carbs: 75.0,
        fats: 20.0,
      ),
      const Meal(
        id: 'meal-2',
        name: 'Pollo y Arroz',
        mealType: 'lunch',
        calories: 600,
        proteins: 30.0,
        carbs: 75.0,
        fats: 20.0,
      ),
    ],
  );
}

/// Creates a [MealPlanDay] where all meals have null macros.
MealPlanDay _makeDayWithNullMacros() {
  return MealPlanDay(
    date: DateTime(2026, 5, 18),
    meals: [
      const Meal(
        id: 'meal-1',
        name: 'Mystery Food',
        mealType: 'breakfast',
        calories: 0,
        // proteins, carbs, fats all null (default)
      ),
    ],
  );
}

/// Pumps [MacroSummaryCard] in a minimal MaterialApp with app theme.
Future<void> pumpCard(
  WidgetTester tester,
  MealPlanDay day,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: MacroSummaryCard(day: day),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('MacroSummaryCard', () {
    // Scenario 1: All macros present → values shown
    testWidgets(
      'sc1: shows 1200 kcal, 60g protein, 150g carbs, 40g fats when macros present',
      (tester) async {
        final day = _makeDayWithMacros();
        await pumpCard(tester, day);

        // Calories: 600 + 600 = 1200 kcal
        expect(find.textContaining('1200'), findsAtLeast(1));
        expect(find.textContaining('kcal'), findsAtLeast(1));

        // Proteins: 30 + 30 = 60 g
        expect(find.textContaining('60'), findsAtLeast(1));

        // Carbs: 75 + 75 = 150 g
        expect(find.textContaining('150'), findsAtLeast(1));

        // Fats: 20 + 20 = 40 g
        expect(find.textContaining('40'), findsAtLeast(1));

        // Labels
        expect(find.text('Calorías'), findsOneWidget);
        expect(find.text('Proteínas'), findsOneWidget);
        expect(find.text('Carbos'), findsOneWidget);
        expect(find.text('Grasas'), findsOneWidget);
      },
    );

    // Scenario 2: All-null macros → "—" displayed
    testWidgets(
      'sc2: shows "—" for proteins, carbs, fats when all macros are null',
      (tester) async {
        final day = _makeDayWithNullMacros();
        await pumpCard(tester, day);

        // Should show em dash for null macros (at least 3 dashes for P, C, F)
        expect(find.text('—'), findsNWidgets(3));

        // Calories still shown (even if 0)
        expect(find.text('Calorías'), findsOneWidget);

        // Proteins/Carbs/Fats labels still present
        expect(find.text('Proteínas'), findsOneWidget);
        expect(find.text('Carbos'), findsOneWidget);
        expect(find.text('Grasas'), findsOneWidget);

        // No 'g' units shown for null macros
        expect(find.textContaining(' g'), findsNothing);
      },
    );
  });
}
