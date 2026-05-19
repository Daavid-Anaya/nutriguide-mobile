// Spec: HOME-UI-006 sc1–sc3, HOME-INTEGRATION-001 sc1
// TDD: T-15a [RED] — TodaysPlanSection widget tests.
// TDD: T-55 [RED] — Navigation tests for "Ver Todo" button.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';
import 'package:nutriguide_mobile/features/home/domain/meal.dart';
import 'package:nutriguide_mobile/features/home/domain/meal_plan.dart';
import 'package:nutriguide_mobile/features/home/presentation/widgets/meal_card.dart';
import 'package:nutriguide_mobile/features/home/presentation/widgets/todays_plan_section.dart';
import 'package:nutriguide_mobile/router/route_constants.dart';

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

/// Pumps [TodaysPlanSection] with a real [GoRouter] to test navigation.
///
/// Uses the same pattern as scanner_screen_test.dart — wraps the widget
/// in a GoRouter so [context.push] calls are observable.
Future<GoRouter> pumpSectionWithRouter(
  WidgetTester tester,
  MealPlan mealPlan,
) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: SingleChildScrollView(
            child: TodaysPlanSection(mealPlan: mealPlan),
          ),
        ),
      ),
      GoRoute(
        path: Routes.mealPlan,
        builder: (_, __) => const Scaffold(
          body: Text('MealPlanScreen'),
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: router,
    ),
  );
  await tester.pump();
  return router;
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

    // T-56: SnackBar removed — navigation now replaces it (HOME-INTEGRATION-001)
    // Tapping "Ver Todo" no longer shows a "Próximamente" SnackBar.
    // Navigation test is in the 'TodaysPlanSection — navigation' group below.
    testWidgets(
      'tapping "Ver Todo" does NOT show SnackBar (navigation replaced it)',
      (tester) async {
        await pumpSection(tester, _mealPlanWith(0));

        // Tap the TextButton — this will fail/throw because context.push requires
        // a GoRouter above it. The simple MaterialApp wrapper does not have one,
        // so we only verify the SnackBar is NOT shown when the router IS present.
        // Navigation behavior is tested in the 'navigation' group below.
        // This test pumps with a minimal router to avoid the exception.
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => Scaffold(
                body: TodaysPlanSection(mealPlan: _mealPlanWith(0)),
              ),
            ),
            GoRoute(
              path: Routes.mealPlan,
              builder: (_, __) =>
                  const Scaffold(body: Text('MealPlanScreen')),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        );
        await tester.pump();

        await tester.tap(find.byType(TextButton));
        await tester.pumpAndSettle();

        // No SnackBar shown — navigation happened instead
        expect(find.text('Próximamente'), findsNothing);
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

  // T-55: Navigation tests for "Ver Todo" button
  // Spec: HOME-INTEGRATION-001 sc1 — "Ver Todo" navigates to /meal-plan
  group('TodaysPlanSection — navigation', () {
    testWidgets(
      'tapping "Ver Todo" navigates to /meal-plan route',
      (tester) async {
        await pumpSectionWithRouter(tester, _mealPlanWith(0));

        // Tap the "Ver Todo" button
        await tester.tap(find.byType(TextButton));
        await tester.pumpAndSettle();

        // The router should have navigated to MealPlanScreen
        expect(find.text('MealPlanScreen'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping "Ver Todo" does NOT show SnackBar with "Próximamente"',
      (tester) async {
        await pumpSectionWithRouter(tester, _mealPlanWith(0));

        await tester.tap(find.byType(TextButton));
        await tester.pump();

        expect(find.text('Próximamente'), findsNothing);
      },
    );
  });
}
