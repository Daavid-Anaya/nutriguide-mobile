// Spec: HOME-UI-007 sc1–sc5
// TDD: T-15b [RED] — MealCard widget tests.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';
import 'package:nutriguide_mobile/features/home/domain/meal.dart';
import 'package:nutriguide_mobile/features/home/presentation/widgets/meal_card.dart';

/// A complete meal stub for testing.
const _avocadoToast = Meal(
  id: 'meal-1',
  name: 'Avocado Toast',
  mealType: MealType.breakfast,
  calories: 350,
  tags: ['High Fiber'],
  isCompleted: false,
);

/// Pumps [MealCard] in a minimal MaterialApp with app theme.
Future<void> pumpCard(
  WidgetTester tester,
  Meal meal, {
  VoidCallback? onToggle,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: MealCard(meal: meal, onToggle: onToggle),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('MealCard', () {
    // sc1: Meal card renders all fields
    testWidgets(
      'renders mealType label in uppercase (BREAKFAST)',
      (tester) async {
        await pumpCard(tester, _avocadoToast);

        expect(find.text('BREAKFAST'), findsOneWidget);
      },
    );

    testWidgets(
      'renders meal name "Avocado Toast"',
      (tester) async {
        await pumpCard(tester, _avocadoToast);

        expect(find.text('Avocado Toast'), findsOneWidget);
      },
    );

    testWidgets(
      'renders "350 kcal" when calories is 350',
      (tester) async {
        await pumpCard(tester, _avocadoToast);

        expect(find.textContaining('350'), findsAtLeast(1));
        expect(find.textContaining('kcal'), findsOneWidget);
      },
    );

    testWidgets(
      'renders tags text "High Fiber"',
      (tester) async {
        await pumpCard(tester, _avocadoToast);

        expect(find.textContaining('High Fiber'), findsOneWidget);
      },
    );

    testWidgets(
      'renders unchecked Checkbox when isCompleted=false',
      (tester) async {
        await pumpCard(tester, _avocadoToast);

        final checkboxFinder = find.byType(Checkbox);
        expect(checkboxFinder, findsOneWidget);
        final checkbox = tester.widget<Checkbox>(checkboxFinder);
        expect(checkbox.value, false);
      },
    );

    // sc2: Completed meal shows checked checkbox
    testWidgets(
      'Checkbox is checked when meal.isCompleted=true',
      (tester) async {
        final completedMeal = _avocadoToast.copyWith(isCompleted: true);
        await pumpCard(tester, completedMeal);

        final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
        expect(checkbox.value, true);
      },
    );

    // sc3: Toggle calls onToggle exactly once
    testWidgets(
      'tapping the Checkbox calls onToggle exactly once',
      (tester) async {
        int callCount = 0;
        await pumpCard(
          tester,
          _avocadoToast,
          onToggle: () => callCount++,
        );

        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        expect(callCount, 1);
      },
    );

    // sc4: Null calories hides calorie text
    testWidgets(
      'no "kcal" text when meal.calories is null',
      (tester) async {
        final noCalorieMeal = _avocadoToast.copyWith(calories: null);
        await pumpCard(tester, noCalorieMeal);

        expect(find.textContaining('kcal'), findsNothing);
      },
    );

    // sc5: Null image shows placeholder icon
    testWidgets(
      'placeholder icon shown and no CachedNetworkImage when meal has no imageUrl',
      (tester) async {
        // All test meals have no imageUrl field — MealCard uses placeholder
        await pumpCard(tester, _avocadoToast);

        expect(find.byType(CachedNetworkImage), findsNothing);
        // A placeholder icon (e.g. Icons.restaurant) must be present
        expect(find.byIcon(Icons.restaurant), findsOneWidget);
      },
    );

    // TRIANGULATE: LUNCH meal type renders correctly
    testWidgets(
      'renders "LUNCH" label for lunch mealType',
      (tester) async {
        final lunchMeal = _avocadoToast.copyWith(
          mealType: MealType.lunch,
          name: 'Quinoa Bowl',
        );
        await pumpCard(tester, lunchMeal);

        expect(find.text('LUNCH'), findsOneWidget);
        expect(find.text('Quinoa Bowl'), findsOneWidget);
      },
    );

    // T-53: Macros row rendered when proteins/carbs/fats are non-null
    // Spec: HOME-INTEGRATION-001 sc3 — MealCard shows macros when available
    testWidgets(
      'shows macros row text when proteins/carbs/fats are non-null',
      (tester) async {
        final mealWithMacros = _avocadoToast.copyWith(
          proteins: 25.0,
          carbs: 40.0,
          fats: 10.0,
        );
        await pumpCard(tester, mealWithMacros);

        // At least one macro label should be visible
        expect(find.textContaining('P:'), findsOneWidget);
        expect(find.textContaining('25'), findsAtLeast(1));
      },
    );

    testWidgets(
      'shows C: and F: labels in macros row',
      (tester) async {
        final mealWithMacros = _avocadoToast.copyWith(
          proteins: 25.0,
          carbs: 40.0,
          fats: 10.0,
        );
        await pumpCard(tester, mealWithMacros);

        expect(find.textContaining('C:'), findsOneWidget);
        expect(find.textContaining('F:'), findsOneWidget);
      },
    );

    // T-53: Macros row absent when all macros are null
    // Spec: HOME-INTEGRATION-001 sc4 — MealCard hides macros when all null
    testWidgets(
      'macros row is absent when proteins, carbs, and fats are all null',
      (tester) async {
        // _avocadoToast has null proteins/carbs/fats by default
        await pumpCard(tester, _avocadoToast);

        expect(find.textContaining('P:'), findsNothing);
        expect(find.textContaining('C:'), findsNothing);
        expect(find.textContaining('F:'), findsNothing);
      },
    );
  });
}
