// Spec: HOME-UI-005 sc1–sc3
// TDD: T-13 [RED] — HealthStatsRow (HealthScoreCard + StreakCard) widget tests.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';
import 'package:nutriguide_mobile/features/home/presentation/widgets/health_stats_row.dart';

/// Pumps [HealthStatsRow] in a minimal MaterialApp with app theme.
Future<void> pumpRow(
  WidgetTester tester, {
  required int healthScore,
  required int streak,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: HealthStatsRow(healthScore: healthScore, streak: streak),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('HealthStatsRow', () {
    // sc1: HealthScoreCard renders score and label
    testWidgets(
      'HealthScoreCard renders score "85" and "HEALTH SCORE" label',
      (tester) async {
        await pumpRow(tester, healthScore: 85, streak: 0);

        expect(find.text('85'), findsOneWidget);
        expect(find.text('HEALTH SCORE'), findsOneWidget);
      },
    );

    // sc2: StreakCard renders flame icon, days, and label
    testWidgets(
      'StreakCard renders flame icon, "12 Days" text, and "STREAK" label',
      (tester) async {
        await pumpRow(tester, healthScore: 0, streak: 12);

        expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
        expect(find.text('12 Days'), findsOneWidget);
        expect(find.text('STREAK'), findsOneWidget);
      },
    );

    // sc3: HealthScoreCard handles score=0 (new user — no crash)
    testWidgets(
      'HealthScoreCard renders "0" with no exception when healthScore=0',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: HealthStatsRow(healthScore: 0, streak: 0),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('0'), findsOneWidget);
      },
    );

    // TRIANGULATE: both cards co-exist in the same Row
    testWidgets(
      'both HealthScoreCard score and StreakCard days are visible together',
      (tester) async {
        await pumpRow(tester, healthScore: 72, streak: 5);

        expect(find.text('72'), findsOneWidget);
        expect(find.text('5 Days'), findsOneWidget);
        expect(find.text('HEALTH SCORE'), findsOneWidget);
        expect(find.text('STREAK'), findsOneWidget);
      },
    );
  });
}
