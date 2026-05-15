// Spec: HOME-UI-004 sc1–sc3
// TDD: T-11 [RED] — WellnessBudgetCard widget tests (written before implementation exists).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';
import 'package:nutriguide_mobile/features/home/domain/wellness_summary.dart';
import 'package:nutriguide_mobile/features/home/presentation/widgets/wellness_budget_card.dart';

/// Pumps [WellnessBudgetCard] in a minimal MaterialApp with app theme.
Future<void> pumpCard(
  WidgetTester tester, {
  required double budgetSpent,
  required double budgetTotal,
}) async {
  final wellness = WellnessSummary(
    healthScore: 70,
    streak: 0,
    budgetSpent: budgetSpent,
    budgetTotal: budgetTotal,
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: WellnessBudgetCard(wellness: wellness),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('WellnessBudgetCard', () {
    // sc1: Budget displays correct values
    testWidgets(
      'displays "PRESUPUESTO SEMANAL" label',
      (tester) async {
        await pumpCard(tester, budgetSpent: 55.0, budgetTotal: 200.0);

        expect(find.text('PRESUPUESTO SEMANAL'), findsOneWidget);
      },
    );

    testWidgets(
      'displays budget values formatted as currency',
      (tester) async {
        await pumpCard(tester, budgetSpent: 55.0, budgetTotal: 200.0);

        // Must show $55.00 / $200.00 (or locale equivalent with $ symbol)
        expect(find.textContaining('\$55'), findsOneWidget);
        expect(find.textContaining('\$200'), findsOneWidget);
      },
    );

    testWidgets(
      'LinearProgressIndicator value is 0.275 when spent=55 total=200',
      (tester) async {
        await pumpCard(tester, budgetSpent: 55.0, budgetTotal: 200.0);

        final progressFinder = find.byType(LinearProgressIndicator);
        expect(progressFinder, findsOneWidget);

        final progress = tester.widget<LinearProgressIndicator>(progressFinder);
        expect(progress.value, closeTo(0.275, 0.001));
      },
    );

    // sc2: Progress clamped when spent exceeds total
    testWidgets(
      'LinearProgressIndicator value is clamped to 1.0 when spent exceeds total',
      (tester) async {
        await pumpCard(tester, budgetSpent: 250.0, budgetTotal: 200.0);

        final progressFinder = find.byType(LinearProgressIndicator);
        final progress = tester.widget<LinearProgressIndicator>(progressFinder);
        expect(progress.value, closeTo(1.0, 0.001));
      },
    );

    // sc3: Zero budget shows zero progress
    testWidgets(
      'LinearProgressIndicator value is 0.0 when budgetSpent is 0',
      (tester) async {
        await pumpCard(tester, budgetSpent: 0.0, budgetTotal: 200.0);

        final progressFinder = find.byType(LinearProgressIndicator);
        final progress = tester.widget<LinearProgressIndicator>(progressFinder);
        expect(progress.value, closeTo(0.0, 0.001));
      },
    );
  });
}
