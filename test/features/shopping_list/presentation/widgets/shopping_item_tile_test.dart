// Spec: SHOPPING-LIST-002 sc2, sc3
// TDD: T-4.3 [RED] — Tests FAIL until shopping_item_tile.dart is created (T-4.4).
// Design: AD-22

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_item.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_list.dart';
import 'package:nutriguide_mobile/features/shopping_list/presentation/providers/shopping_list_notifier.dart';
import 'package:nutriguide_mobile/features/shopping_list/presentation/widgets/shopping_item_tile.dart';

// ---------------------------------------------------------------------------
// Fake notifier — tracks calls to toggleItem / removeItem
// ---------------------------------------------------------------------------

class FakeShoppingListNotifier extends ShoppingListNotifier {
  final List<String> toggledIds = [];
  final List<String> removedIds = [];

  @override
  Future<ShoppingListState> build() async {
    return ShoppingListData(
      ShoppingList(
        id: 'list-1',
        name: 'Mi lista de compras',
        items: const [],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
  }

  @override
  Future<void> toggleItem(String itemId) async {
    toggledIds.add(itemId);
  }

  @override
  Future<void> removeItem(String itemId) async {
    removedIds.add(itemId);
  }
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

final _item = ShoppingItem(
  id: 'item-1',
  name: 'Leche',
  quantity: 2.0,
  unit: 'L',
  estimatedPrice: 45.0,
  isChecked: false,
);

final _minimalItem = ShoppingItem(
  id: 'item-2',
  name: 'Pan',
);

// ---------------------------------------------------------------------------
// Helper — pumps ShoppingItemTile with ProviderScope override
// ---------------------------------------------------------------------------

Widget buildSubject(
  ShoppingItem item,
  FakeShoppingListNotifier fakeNotifier,
) {
  return ProviderScope(
    overrides: [
      shoppingListNotifierProvider.overrideWith(() => fakeNotifier),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: ShoppingItemTile(item: item),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ShoppingItemTile', () {
    late FakeShoppingListNotifier fakeNotifier;

    setUp(() {
      fakeNotifier = FakeShoppingListNotifier();
    });

    // ── SHOPPING-LIST-002 sc2 ──────────────────────────────────────────────
    // Checkbox tap calls toggleItem()
    testWidgets(
      'sc2 — tapping checkbox calls toggleItem() with correct id',
      (tester) async {
        await tester.pumpWidget(buildSubject(_item, fakeNotifier));
        await tester.pump();

        // Tap the checkbox
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        expect(fakeNotifier.toggledIds, contains('item-1'));
      },
    );

    // TRIANGULATE sc2: tapping item name also toggles (CheckboxListTile behavior)
    testWidgets(
      'triangulate sc2 — tapping tile title also calls toggleItem()',
      (tester) async {
        await tester.pumpWidget(buildSubject(_item, fakeNotifier));
        await tester.pump();

        // Tap the title text — CheckboxListTile fires onChanged
        await tester.tap(find.text('Leche'));
        await tester.pump();

        expect(fakeNotifier.toggledIds, contains('item-1'));
      },
    );

    // ── SHOPPING-LIST-002 sc3 ──────────────────────────────────────────────
    // Swipe dismiss calls removeItem()
    testWidgets(
      'sc3 — swiping item end-to-start calls removeItem() with correct id',
      (tester) async {
        await tester.pumpWidget(buildSubject(_item, fakeNotifier));
        await tester.pump();

        // Swipe end-to-start to dismiss
        await tester.drag(
          find.byType(Dismissible),
          const Offset(-500, 0),
        );
        await tester.pumpAndSettle();

        expect(fakeNotifier.removedIds, contains('item-1'));
      },
    );

    // ── Subtitle shows quantity + price ───────────────────────────────────
    testWidgets(
      'subtitle shows quantity, unit, and price when all provided',
      (tester) async {
        await tester.pumpWidget(buildSubject(_item, fakeNotifier));
        await tester.pump();

        // The subtitle renders as a single Text widget: "2.0 L · $45.00"
        expect(find.textContaining('2.0 L'), findsOneWidget);
        expect(find.textContaining('45.00'), findsOneWidget);
      },
    );

    // TRIANGULATE: minimal item (no quantity/price) shows no subtitle
    testWidgets(
      'triangulate — minimal item (name only) renders no subtitle',
      (tester) async {
        await tester.pumpWidget(buildSubject(_minimalItem, fakeNotifier));
        await tester.pump();

        expect(find.text('Pan'), findsOneWidget);
        // No price or quantity text
        expect(find.textContaining(r'$'), findsNothing);
      },
    );
  });
}
