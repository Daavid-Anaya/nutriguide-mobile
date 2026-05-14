// Spec: SCANNER-WIDGET-001 sc3, sc4; SCANNER-UI-002 sc5
// T-07: NutritionalInfoCard — 8-row nutrient card with null handling.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';
import 'package:nutriguide_mobile/features/scanner/domain/nutritional_info.dart';
import 'package:nutriguide_mobile/features/scanner/presentation/widgets/nutritional_info_card.dart';

/// Pumps the NutritionalInfoCard wrapped in a minimal MaterialApp.
Future<void> pumpCard(WidgetTester tester, NutritionalInfo? info) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: NutritionalInfoCard(nutritionalInfo: info),
        ),
      ),
    ),
  );
}

void main() {
  group('NutritionalInfoCard', () {
    // RED → GREEN sc3: null NutritionalInfo → all 8 rows show "—"
    testWidgets('null nutritionalInfo → all 8 rows show "—"', (tester) async {
      await pumpCard(tester, null);

      // Card is always visible
      expect(find.byType(Card), findsOneWidget);

      // All 8 dash values must be present
      // There are 8 rows, each showing "—"
      expect(find.text('—'), findsNWidgets(8));
    });

    // TRIANGULATE sc4: complete data → each row shows numeric value with unit
    testWidgets('complete nutritionalInfo → rows show correct values with units',
        (tester) async {
      const info = NutritionalInfo(
        energy: 250,
        fat: 10.5,
        saturatedFat: 3.2,
        carbohydrates: 30.0,
        sugars: 12.1,
        proteins: 5.2,
        salt: 0.8,
        fiber: 2.3,
      );

      await pumpCard(tester, info);

      // Energy: integer value with no trailing zero
      expect(find.text('250.0 kcal'), findsOneWidget);
      // Fat
      expect(find.text('10.5 g'), findsOneWidget);
      // Saturated fat
      expect(find.text('3.2 g'), findsOneWidget);
      // Carbohydrates
      expect(find.text('30.0 g'), findsOneWidget);
      // Sugars
      expect(find.text('12.1 g'), findsOneWidget);
      // Proteins
      expect(find.text('5.2 g'), findsOneWidget);
      // Salt
      expect(find.text('0.8 g'), findsOneWidget);
      // Fiber
      expect(find.text('2.3 g'), findsOneWidget);

      // No dashes — all values present
      expect(find.text('—'), findsNothing);
    });

    // TRIANGULATE sc4 partial: energy provided, fat null → energy shows, fat "—"
    testWidgets('partial nulls → non-null fields show values, null fields show "—"',
        (tester) async {
      const info = NutritionalInfo(
        energy: 150,
        // fat → null
        // saturatedFat → null
        carbohydrates: 20.0,
        // sugars → null
        proteins: 8.0,
        // salt → null
        // fiber → null
      );

      await pumpCard(tester, info);

      // Non-null fields
      expect(find.text('150.0 kcal'), findsOneWidget);
      expect(find.text('20.0 g'), findsOneWidget);
      expect(find.text('8.0 g'), findsOneWidget);

      // Null fields → "—" (5 null fields: fat, saturatedFat, sugars, salt, fiber)
      expect(find.text('—'), findsNWidgets(5));
    });

    // TRIANGULATE: card is always present even with null info
    testWidgets('Card widget is always rendered regardless of null info',
        (tester) async {
      // Null info
      await pumpCard(tester, null);
      expect(find.byType(Card), findsOneWidget);

      // Also present with complete info (pump again)
      await pumpCard(
        tester,
        const NutritionalInfo(energy: 100, proteins: 5),
      );
      expect(find.byType(Card), findsOneWidget);
    });
  });
}
