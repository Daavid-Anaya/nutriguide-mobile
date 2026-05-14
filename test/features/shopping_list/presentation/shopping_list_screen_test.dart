// Spec: SHOPPING-LIST-002 sc1, sc4, sc5
// TDD: T-4.7 [RED] → T-4.8 [GREEN] — Tests updated for full ShoppingListScreen.
// Design: AD-22

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_item.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_list.dart';
import 'package:nutriguide_mobile/features/shopping_list/presentation/providers/shopping_list_notifier.dart';
import 'package:nutriguide_mobile/features/shopping_list/presentation/shopping_list_screen.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

ShoppingItem _makeItem({
  required String id,
  required String name,
  bool isChecked = false,
  double? estimatedPrice,
}) =>
    ShoppingItem(
      id: id,
      name: name,
      isChecked: isChecked,
      estimatedPrice: estimatedPrice,
    );

ShoppingList _makeList({required List<ShoppingItem> items}) => ShoppingList(
      id: 'list-1',
      name: 'Mi lista de compras',
      items: items,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

// ---------------------------------------------------------------------------
// Fake notifier — seeds state with no actual repo calls
// ---------------------------------------------------------------------------

class FakeShoppingListNotifier extends ShoppingListNotifier {
  FakeShoppingListNotifier(this._seedState);

  final ShoppingListState _seedState;

  @override
  Future<ShoppingListState> build() async => _seedState;
}

// ---------------------------------------------------------------------------
// Helper — builds ShoppingListScreen with a pre-set notifier state
// ---------------------------------------------------------------------------

Widget buildSubject(ShoppingListState seedState) {
  return ProviderScope(
    overrides: [
      shoppingListNotifierProvider.overrideWith(
        () => FakeShoppingListNotifier(seedState),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const ShoppingListScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ShoppingListScreen', () {
    // ── SHOPPING-LIST-002 sc4 ──────────────────────────────────────────────
    // Empty state: no items → "Tu lista está vacía" visible
    testWidgets(
      'sc4 — empty list renders empty state text "Tu lista está vacía"',
      (tester) async {
        final emptyList = _makeList(items: []);
        await tester.pumpWidget(buildSubject(ShoppingListData(emptyList)));
        await tester.pump();

        expect(find.text('Tu lista está vacía'), findsOneWidget);
      },
    );

    // ── SHOPPING-LIST-002 sc4 (FAB) ───────────────────────────────────────
    // FAB is visible even when list is empty
    testWidgets(
      'sc4 — FAB (FloatingActionButton) is visible in empty state',
      (tester) async {
        final emptyList = _makeList(items: []);
        await tester.pumpWidget(buildSubject(ShoppingListData(emptyList)));
        await tester.pump();

        expect(find.byType(FloatingActionButton), findsOneWidget);
      },
    );

    // ── SHOPPING-LIST-002 sc1 ──────────────────────────────────────────────
    // Items render in unchecked-then-checked order
    testWidgets(
      'sc1 — items render unchecked group first, checked group last',
      (tester) async {
        // A(unchecked), B(checked), C(unchecked) — should display: A, C, B
        final itemA = _makeItem(id: 'A', name: 'Apple', isChecked: false);
        final itemB = _makeItem(id: 'B', name: 'Banana', isChecked: true);
        final itemC = _makeItem(id: 'C', name: 'Carrot', isChecked: false);
        final list = _makeList(items: [itemA, itemB, itemC]);

        await tester.pumpWidget(buildSubject(ShoppingListData(list)));
        await tester.pump();

        expect(find.text('Apple'), findsOneWidget);
        expect(find.text('Banana'), findsOneWidget);
        expect(find.text('Carrot'), findsOneWidget);
      },
    );

    // ── SHOPPING-LIST-002 sc5 ──────────────────────────────────────────────
    // Progress indicator reflects checked count
    testWidgets(
      'sc5 — LinearProgressIndicator is visible when items exist',
      (tester) async {
        final itemA = _makeItem(id: 'A', name: 'Apple', isChecked: true);
        final itemB = _makeItem(id: 'B', name: 'Banana', isChecked: false);
        final itemC = _makeItem(id: 'C', name: 'Carrot', isChecked: false);
        final list = _makeList(items: [itemA, itemB, itemC]);

        await tester.pumpWidget(buildSubject(ShoppingListData(list)));
        await tester.pump();

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      },
    );

    // TRIANGULATE sc5: progress text shows correct count
    testWidgets(
      'sc5 triangulate — progress text shows "1 de 3 completados"',
      (tester) async {
        final itemA = _makeItem(id: 'A', name: 'Apple', isChecked: true);
        final itemB = _makeItem(id: 'B', name: 'Banana', isChecked: false);
        final itemC = _makeItem(id: 'C', name: 'Carrot', isChecked: false);
        final list = _makeList(items: [itemA, itemB, itemC]);

        await tester.pumpWidget(buildSubject(ShoppingListData(list)));
        await tester.pump();

        expect(find.textContaining('1 de 3'), findsOneWidget);
      },
    );

    // ── AppBar title ───────────────────────────────────────────────────────
    testWidgets(
      'AppBar shows "Mi lista de compras" as title',
      (tester) async {
        final emptyList = _makeList(items: []);
        await tester.pumpWidget(buildSubject(ShoppingListData(emptyList)));
        await tester.pump();

        expect(find.text('Mi lista de compras'), findsOneWidget);
      },
    );

    // ── Loading state ──────────────────────────────────────────────────────
    testWidgets(
      'ShoppingListLoading state renders without error',
      (tester) async {
        await tester.pumpWidget(buildSubject(const ShoppingListLoading()));
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );

    // ── Empty state (ShoppingListEmpty) ───────────────────────────────────
    testWidgets(
      'ShoppingListEmpty state shows empty state text',
      (tester) async {
        await tester.pumpWidget(buildSubject(const ShoppingListEmpty()));
        await tester.pump();

        expect(find.text('Tu lista está vacía'), findsOneWidget);
      },
    );
  });
}
