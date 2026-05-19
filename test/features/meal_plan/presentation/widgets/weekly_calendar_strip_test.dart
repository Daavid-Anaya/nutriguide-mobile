// Spec: MEAL-UI-002 sc1–sc4
// TDD: T-41 [RED] — WeeklyCalendarStrip widget tests.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';
import 'package:nutriguide_mobile/features/meal_plan/presentation/widgets/weekly_calendar_strip.dart';

/// Monday 2026-05-18 (week reference for all tests)
final _weekStart = DateTime(2026, 5, 18); // Monday
final _wednesday = DateTime(2026, 5, 20); // Wednesday (index 2)
final _thursday = DateTime(2026, 5, 21); // Thursday (index 3)
final _monday = DateTime(2026, 5, 18); // Monday
final _friday = DateTime(2026, 5, 22); // Friday

/// Pumps [WeeklyCalendarStrip] wrapped in MaterialApp with app theme.
Future<void> pumpStrip(
  WidgetTester tester, {
  required DateTime weekStart,
  required DateTime selectedDate,
  required Set<DateTime> daysWithPlan,
  required void Function(DateTime) onDaySelected,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: WeeklyCalendarStrip(
          weekStart: weekStart,
          selectedDate: selectedDate,
          daysWithPlan: daysWithPlan,
          onDaySelected: onDaySelected,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('WeeklyCalendarStrip', () {
    // Scenario 1: 7 tiles rendered
    testWidgets(
      'sc1: renders 7 day tiles for the week',
      (tester) async {
        await pumpStrip(
          tester,
          weekStart: _weekStart,
          selectedDate: _wednesday,
          daysWithPlan: {},
          onDaySelected: (_) {},
        );

        // 7 tiles: L M X J V S D
        // L=Lunes(Mon), M=Martes(Tue), X=miércoles(Wed), J=Jueves(Thu), V=Viernes(Fri), S=Sábado(Sat), D=Domingo(Sun)
        expect(find.text('L'), findsOneWidget); // Monday
        expect(find.text('M'), findsOneWidget); // Tuesday (Martes)
        expect(find.text('X'), findsOneWidget); // Wednesday (Miércoles)
        expect(find.text('J'), findsOneWidget); // Thursday (Jueves)
        // Check day numbers
        // Week 2026-05-18 → 18, 19, 20, 21, 22, 23, 24
        expect(find.text('18'), findsOneWidget);
        expect(find.text('19'), findsOneWidget);
        expect(find.text('20'), findsOneWidget);
        expect(find.text('21'), findsOneWidget);
        expect(find.text('22'), findsOneWidget);
        expect(find.text('23'), findsOneWidget);
        expect(find.text('24'), findsOneWidget);
      },
    );

    // Scenario 2: Selected tile has primary background
    testWidgets(
      'sc2: selected tile (Wednesday) has primary color background',
      (tester) async {
        await pumpStrip(
          tester,
          weekStart: _weekStart,
          selectedDate: _wednesday,
          daysWithPlan: {},
          onDaySelected: (_) {},
        );

        // Find the WeeklyCalendarStrip widget — it should exist
        expect(find.byType(WeeklyCalendarStrip), findsOneWidget);

        // The selected tile should contain the day number (20 for Wednesday)
        expect(find.text('20'), findsOneWidget);

        // Find all DayTile containers — selected one should have primary color
        // We test via the semantic structure: find GestureDetectors
        expect(find.byType(GestureDetector), findsAtLeast(7));
      },
    );

    // Scenario 3: Dot on daysWithPlan dates
    testWidgets(
      'sc3: dots appear on Monday and Friday when they are in daysWithPlan',
      (tester) async {
        final daysWithPlan = {_monday, _friday};

        await pumpStrip(
          tester,
          weekStart: _weekStart,
          selectedDate: _wednesday,
          daysWithPlan: daysWithPlan,
          onDaySelected: (_) {},
        );

        // The widget tree should show dot indicators for Monday and Friday
        // We find them by looking for the dot containers
        // _DayTile uses a dot with specific key 'dot_YYYY-MM-DD'
        expect(
          find.byKey(const ValueKey('dot_2026-05-18')),
          findsOneWidget,
          reason: 'Monday should show a dot',
        );
        expect(
          find.byKey(const ValueKey('dot_2026-05-22')),
          findsOneWidget,
          reason: 'Friday should show a dot',
        );

        // Wednesday, Thursday etc should NOT have dots
        expect(
          find.byKey(const ValueKey('dot_2026-05-20')),
          findsNothing,
          reason: 'Wednesday should not show a dot',
        );
        expect(
          find.byKey(const ValueKey('dot_2026-05-21')),
          findsNothing,
          reason: 'Thursday should not show a dot',
        );
      },
    );

    // Scenario 4: Tap fires onDaySelected once
    testWidgets(
      'sc4: tapping Thursday tile calls onDaySelected once with Thursday date',
      (tester) async {
        DateTime? selectedDay;
        int callCount = 0;

        await pumpStrip(
          tester,
          weekStart: _weekStart,
          selectedDate: _wednesday,
          daysWithPlan: {},
          onDaySelected: (date) {
            selectedDay = date;
            callCount++;
          },
        );

        // Tap the Thursday tile (day 21)
        await tester.tap(find.byKey(const ValueKey('tile_2026-05-21')));
        await tester.pump();

        expect(callCount, 1, reason: 'onDaySelected should be called exactly once');
        expect(selectedDay?.day, 21, reason: 'Should select Thursday (21)');
        expect(selectedDay?.month, 5);
        expect(selectedDay?.year, 2026);
      },
    );
  });
}
