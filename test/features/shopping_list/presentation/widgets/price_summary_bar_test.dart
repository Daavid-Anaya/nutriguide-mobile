// Spec: SHOPPING-LIST-004 sc1, sc4
// TDD: T-4.1 [RED] — Tests FAIL until price_summary_bar.dart is created (T-4.2).
// Design: AD-24
//
// PriceSummaryBar is a pure StatelessWidget — no mocks needed.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_item.dart';
import 'package:nutriguide_mobile/features/shopping_list/presentation/widgets/price_summary_bar.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

ShoppingItem _makeItem({
  required String id,
  double? estimatedPrice,
}) =>
    ShoppingItem(
      id: id,
      name: 'Item $id',
      estimatedPrice: estimatedPrice,
    );

// ---------------------------------------------------------------------------
// Helper — pumps PriceSummaryBar in minimal MaterialApp
// ---------------------------------------------------------------------------

Future<void> pumpBar(
  WidgetTester tester,
  List<ShoppingItem> items,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: PriceSummaryBar(items: items),
      ),
    ),
  );
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PriceSummaryBar', () {
    // ── SHOPPING-LIST-004 sc1 ──────────────────────────────────────────────
    // Total with prices: 20.0 + 35.5 + null = 55.50
    testWidgets(
      'sc1 — renders \$55.50 for items with prices 20.0 + 35.5 + null',
      (tester) async {
        final items = [
          _makeItem(id: 'a', estimatedPrice: 20.0),
          _makeItem(id: 'b', estimatedPrice: 35.5),
          _makeItem(id: 'c', estimatedPrice: null),
        ];

        await pumpBar(tester, items);

        expect(find.text(r'$55.50'), findsOneWidget);
      },
    );

    // TRIANGULATE sc1: two items with prices
    testWidgets(
      'triangulate — renders \$10.00 for single item with price 10.0',
      (tester) async {
        final items = [
          _makeItem(id: 'a', estimatedPrice: 10.0),
        ];

        await pumpBar(tester, items);

        expect(find.text(r'$10.00'), findsOneWidget);
      },
    );

    // ── SHOPPING-LIST-004 sc4 ──────────────────────────────────────────────
    // All null prices → $0.00
    testWidgets(
      'sc4 — renders \$0.00 when all prices are null',
      (tester) async {
        final items = [
          _makeItem(id: 'a', estimatedPrice: null),
          _makeItem(id: 'b', estimatedPrice: null),
        ];

        await pumpBar(tester, items);

        expect(find.text(r'$0.00'), findsOneWidget);
      },
    );

    // TRIANGULATE sc4: empty list → $0.00
    testWidgets(
      'triangulate — renders \$0.00 for empty items list',
      (tester) async {
        await pumpBar(tester, []);

        expect(find.text(r'$0.00'), findsOneWidget);
      },
    );

    // Label visible
    testWidgets(
      'renders "Total estimado" label',
      (tester) async {
        await pumpBar(tester, []);

        expect(find.text('Total estimado'), findsOneWidget);
      },
    );
  });
}
