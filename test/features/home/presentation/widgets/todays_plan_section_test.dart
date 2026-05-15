// Spec: HOME-UI-006 sc1–sc3
// TDD: T-15a [RED] — TodaysPlanSection widget tests.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';
import 'package:nutriguide_mobile/features/home/domain/meal.dart';
import 'package:nutriguide_mobile/features/home/domain/meal_plan.dart';
import 'package:nutriguide_mobile/features/home/presentation/widgets/meal_card.dart';
import 'package:nutriguide_mobile/features/home/presentation/widgets/todays_plan_section.dart';

/// Creates a stub [MealPlan] with [count] meals.
MealPlan _mealPlanWith(int count) {
  final meals = List.generate(
    count,
    (i) => Meal(
      id: 'meal-$i',
      name: 'Meal $i',
      mealType: MealType.breakfast,
      calories: 300 + i * 50,
      tags: const ['Healthy'],
      isCompleted: false,
    ),
  );
  return MealPlan(
    id: 'plan-1',
    date: DateTime(2026),
    meals: meals,
  );
}

/// Pumps [TodaysPlanSection] wrapped in a [MaterialApp] + [Scaffold].
Future<void> pumpSection(
  WidgetTester tester,
  MealPlan mealPlan, {
  void Function(String)? onToggleMeal,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: TodaysPlanSection(
            mealPlan: mealPlan,
            onToggleMeal: onToggleMeal,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('TodaysPlanSection', () {
    // sc1: "View All" shows Próximamente SnackBar
    testWidgets(
      '"Ver Todo" / "View All" button is visible',
      (tester) async {
        await pumpSection(tester, _mealPlanWith(1));

        // The button must be present
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is TextButton &&
                (w.child is Text) &&
                ((w.child as Text).data?.contains('Ver') == true ||
                    (w.child as Text).data?.contains('All') == true ||
                    (w.child as Text).data?.contains('Ver Todo') == true),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'tapping "Ver Todo" shows a SnackBar with "Próximamente"',
      (tester) async {
        await pumpSection(tester, _mealPlanWith(0));

        // Tap the TextButton
        await tester.tap(find.byType(TextButton));
        await tester.pump(); // pump to trigger SnackBar

        expect(find.text('Próximamente'), findsOneWidget);
      },
    );

    // sc2: Meal list renders one MealCard per meal
    testWidgets(
      'renders one MealCard per meal when mealPlan has 3 meals',
      (tester) async {
        await pumpSection(tester, _mealPlanWith(3));

        expect(find.byType(MealCard), findsNWidgets(3));
      },
    );

    // TRIANGULATE: different count
    testWidgets(
      'renders exactly one MealCard when mealPlan has 1 meal',
      (tester) async {
        await pumpSection(tester, _mealPlanWith(1));

        expect(find.byType(MealCard), findsOneWidget);
      },
    );

    // sc3: Empty state shown when no meals
    testWidgets(
      'shows empty state message when mealPlan.meals is empty',
      (tester) async {
        await pumpSection(tester, _mealPlanWith(0));

        expect(find.byType(MealCard), findsNothing);
        // Some empty-state text must be visible
        expect(
          find.textContaining('hoy', findRichText: true),
          findsWidgets,
        );
      },
    );

    // sc1 header: "Plan de Hoy" header is visible
    testWidgets(
      'section header "Plan de Hoy" is visible',
      (tester) async {
        await pumpSection(tester, _mealPlanWith(0));

        expect(find.text('Plan de Hoy'), findsOneWidget);
      },
    );
  });
}
