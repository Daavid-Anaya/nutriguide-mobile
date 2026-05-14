// Spec: SHOPPING-LIST-003 sc1, sc2, sc3
// TDD: T-4.5 [RED] — Tests FAIL until add_item_sheet.dart is created (T-4.6).
// Design: AD-23

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_item.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_list.dart';
import 'package:nutriguide_mobile/features/shopping_list/presentation/providers/shopping_list_notifier.dart';
import 'package:nutriguide_mobile/features/shopping_list/presentation/widgets/add_item_sheet.dart';

// ---------------------------------------------------------------------------
// Fake notifier — captures addItem() calls
// ---------------------------------------------------------------------------

class FakeShoppingListNotifier extends ShoppingListNotifier {
  final List<ShoppingItem> addedItems = [];

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
  Future<void> addItem(ShoppingItem item) async {
    addedItems.add(item);
  }
}

// ---------------------------------------------------------------------------
// Helper — pumps AddItemSheet inside a full Navigator / Scaffold tree
// so that Navigator.pop() works correctly.
// ---------------------------------------------------------------------------

Widget buildSubject(FakeShoppingListNotifier fakeNotifier) {
  return ProviderScope(
    overrides: [
      shoppingListNotifierProvider.overrideWith(() => fakeNotifier),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => ProviderScope(
                // Re-expose overrides inside the bottom sheet's scope
                overrides: [
                  shoppingListNotifierProvider.overrideWith(
                    () => fakeNotifier,
                  ),
                ],
                child: const AddItemSheet(),
              ),
            ),
            child: const Text('Open Sheet'),
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AddItemSheet', () {
    late FakeShoppingListNotifier fakeNotifier;

    setUp(() {
      fakeNotifier = FakeShoppingListNotifier();
    });

    // Helper: open the bottom sheet
    Future<void> openSheet(WidgetTester tester) async {
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();
    }

    // ── SHOPPING-LIST-003 sc3 ──────────────────────────────────────────────
    // Empty name shows validation error
    testWidgets(
      'sc3 — empty name shows validation error, no item added',
      (tester) async {
        await tester.pumpWidget(buildSubject(fakeNotifier));
        await openSheet(tester);

        // Tap Agregar without entering a name
        await tester.tap(find.text('Agregar'));
        await tester.pumpAndSettle();

        expect(find.text('El nombre es requerido'), findsOneWidget);
        expect(fakeNotifier.addedItems, isEmpty);
      },
    );

    // ── SHOPPING-LIST-003 sc1 ──────────────────────────────────────────────
    // Valid submission calls addItem() and pops sheet
    testWidgets(
      'sc1 — valid submission calls addItem() and dismisses sheet',
      (tester) async {
        await tester.pumpWidget(buildSubject(fakeNotifier));
        await openSheet(tester);

        // Fill the name field
        await tester.enterText(find.widgetWithText(TextFormField, 'Nombre *'), 'Leche');
        await tester.pumpAndSettle();

        // Tap submit
        await tester.tap(find.text('Agregar'));
        await tester.pumpAndSettle();

        // addItem should have been called
        expect(fakeNotifier.addedItems, hasLength(1));
        expect(fakeNotifier.addedItems.first.name, equals('Leche'));

        // Sheet should be dismissed
        expect(find.text('Agregar producto'), findsNothing);
      },
    );

    // ── SHOPPING-LIST-003 sc2 ──────────────────────────────────────────────
    // Minimal form (name only) creates item with null fields
    testWidgets(
      'sc2 — name-only form creates item with null quantity/unit/price',
      (tester) async {
        await tester.pumpWidget(buildSubject(fakeNotifier));
        await openSheet(tester);

        // Fill name only
        await tester.enterText(find.widgetWithText(TextFormField, 'Nombre *'), 'Pan');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Agregar'));
        await tester.pumpAndSettle();

        expect(fakeNotifier.addedItems, hasLength(1));
        final item = fakeNotifier.addedItems.first;
        expect(item.name, equals('Pan'));
        expect(item.quantity, isNull);
        expect(item.unit, isNull);
        expect(item.estimatedPrice, isNull);
        expect(item.isChecked, isFalse);
      },
    );

    // TRIANGULATE sc1: full form submission passes all fields
    testWidgets(
      'triangulate sc1 — full form creates item with all fields',
      (tester) async {
        await tester.pumpWidget(buildSubject(fakeNotifier));
        await openSheet(tester);

        await tester.enterText(find.widgetWithText(TextFormField, 'Nombre *'), 'Leche');
        await tester.enterText(find.widgetWithText(TextFormField, 'Cantidad'), '2');
        await tester.enterText(find.widgetWithText(TextFormField, 'Unidad'), 'L');
        await tester.enterText(find.widgetWithText(TextFormField, 'Precio estimado'), '45.0');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Agregar'));
        await tester.pumpAndSettle();

        expect(fakeNotifier.addedItems, hasLength(1));
        final item = fakeNotifier.addedItems.first;
        expect(item.name, equals('Leche'));
        expect(item.quantity, equals(2.0));
        expect(item.unit, equals('L'));
        expect(item.estimatedPrice, equals(45.0));
      },
    );
  });
}
