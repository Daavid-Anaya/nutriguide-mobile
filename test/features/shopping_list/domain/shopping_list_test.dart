// NOTE: This test file is the TDD "red" phase.
// Tests WILL NOT compile until `dart run build_runner build` is run (T-16).
// That is intentional — write the spec now, generate the code in T-16.
//
// Spec: CORE-MODELS-001 sc1, sc2 — fromJson/toJson round-trip for ShoppingList and ShoppingItem.

import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_item.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_list.dart';

const Map<String, dynamic> kShoppingItemJson = {
  'id': 'item-001',
  'name': 'Whole milk',
  'quantity': 2.0,
  'unit': 'L',
  'estimatedPrice': 3.49,
  'isChecked': false,
  'productBarcode': '5449000000996',
};

const Map<String, dynamic> kMinimalShoppingItemJson = {
  'id': 'item-002',
  'name': 'Salt',
  'quantity': null,
  'unit': null,
  'estimatedPrice': null,
  'isChecked': true,
  'productBarcode': null,
};

Map<String, dynamic> kShoppingListJson({String? id}) => {
      'id': id ?? 'list-001',
      'name': 'Weekly Groceries',
      'items': [kShoppingItemJson],
      'createdAt': '2026-05-12T10:00:00.000',
      'updatedAt': '2026-05-12T10:30:00.000',
    };

const Map<String, dynamic> kEmptyShoppingListJson = {
  'id': 'list-002',
  'name': 'Empty List',
  'items': <Map<String, dynamic>>[],
  'createdAt': '2026-05-12T08:00:00.000',
  'updatedAt': '2026-05-12T08:00:00.000',
};

void main() {
  group('ShoppingItem', () {
    group('CORE-MODELS-001 sc2 — fromJson', () {
      test('parses all fields correctly', () {
        final item = ShoppingItem.fromJson(kShoppingItemJson);

        expect(item.id, equals('item-001'));
        expect(item.name, equals('Whole milk'));
        expect(item.quantity, equals(2.0));
        expect(item.unit, equals('L'));
        expect(item.estimatedPrice, equals(3.49));
        expect(item.isChecked, isFalse);
        expect(item.productBarcode, equals('5449000000996'));
      });

      test('parses minimal item with all nullable fields as null', () {
        final item = ShoppingItem.fromJson(kMinimalShoppingItemJson);

        expect(item.id, equals('item-002'));
        expect(item.name, equals('Salt'));
        expect(item.quantity, isNull);
        expect(item.unit, isNull);
        expect(item.estimatedPrice, isNull);
        expect(item.isChecked, isTrue);
        expect(item.productBarcode, isNull);
      });

      test('isChecked defaults to false when not provided via constructor', () {
        const item = ShoppingItem(id: 'x', name: 'Bread');

        expect(item.isChecked, isFalse);
      });
    });

    group('CORE-MODELS-001 sc1 — toJson', () {
      test('serializes all fields including nullable ones', () {
        const item = ShoppingItem(
          id: 'item-001',
          name: 'Whole milk',
          quantity: 2.0,
          unit: 'L',
          estimatedPrice: 3.49,
          productBarcode: '5449000000996',
        );

        final json = item.toJson();

        expect(json['id'], equals('item-001'));
        expect(json['name'], equals('Whole milk'));
        expect(json['quantity'], equals(2.0));
        expect(json['unit'], equals('L'));
        expect(json['estimatedPrice'], equals(3.49));
        expect(json['isChecked'], isFalse);
        expect(json['productBarcode'], equals('5449000000996'));
      });

      test('round-trip: fromJson → toJson preserves all values', () {
        final original = ShoppingItem.fromJson(kShoppingItemJson);
        final roundTripped = ShoppingItem.fromJson(original.toJson());

        expect(roundTripped, equals(original));
      });

      test('round-trip preserves null fields', () {
        final original = ShoppingItem.fromJson(kMinimalShoppingItemJson);
        final roundTripped = ShoppingItem.fromJson(original.toJson());

        expect(roundTripped, equals(original));
        expect(roundTripped.quantity, isNull);
        expect(roundTripped.unit, isNull);
      });
    });

    group('ShoppingItem value equality (Freezed ==)', () {
      test('two items with same data are equal', () {
        const i1 = ShoppingItem(id: 'x', name: 'Bread');
        const i2 = ShoppingItem(id: 'x', name: 'Bread');

        expect(i1, equals(i2));
      });

      test('copyWith updates isChecked', () {
        const item = ShoppingItem(id: 'x', name: 'Bread');
        final checked = item.copyWith(isChecked: true);

        expect(checked.isChecked, isTrue);
        expect(checked.name, equals('Bread'));
      });
    });
  });

  group('ShoppingList', () {
    group('CORE-MODELS-001 sc2 — fromJson', () {
      test('parses list with items correctly', () {
        final list = ShoppingList.fromJson(kShoppingListJson());

        expect(list.id, equals('list-001'));
        expect(list.name, equals('Weekly Groceries'));
        expect(list.items, hasLength(1));
        expect(list.items.first.name, equals('Whole milk'));
        expect(list.createdAt, equals(DateTime.parse('2026-05-12T10:00:00.000')));
        expect(list.updatedAt, equals(DateTime.parse('2026-05-12T10:30:00.000')));
      });

      test('parses empty list correctly', () {
        final list = ShoppingList.fromJson(kEmptyShoppingListJson);

        expect(list.id, equals('list-002'));
        expect(list.name, equals('Empty List'));
        expect(list.items, isEmpty);
      });

      test('items default to empty list when not provided via constructor', () {
        final list = ShoppingList(
          id: 'x',
          name: 'Test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(list.items, isEmpty);
      });
    });

    group('CORE-MODELS-001 sc1 — toJson', () {
      test('serializes id, name, and items', () {
        final list = ShoppingList.fromJson(kShoppingListJson());
        final json = list.toJson();

        expect(json['id'], equals('list-001'));
        expect(json['name'], equals('Weekly Groceries'));
        expect(json['items'], isA<List>());
        expect((json['items'] as List).length, equals(1));
      });

      test('serializes DateTime fields', () {
        final list = ShoppingList.fromJson(kShoppingListJson());
        final json = list.toJson();

        // json_serializable serializes DateTime as ISO 8601 string
        expect(json['createdAt'], isNotNull);
        expect(json['updatedAt'], isNotNull);
      });

      test('round-trip: fromJson → toJson preserves all values', () {
        final original = ShoppingList.fromJson(kShoppingListJson());
        final roundTripped = ShoppingList.fromJson(original.toJson());

        expect(roundTripped, equals(original));
      });

      test('round-trip preserves nested items', () {
        final original = ShoppingList.fromJson(kShoppingListJson());
        final roundTripped = ShoppingList.fromJson(original.toJson());

        expect(roundTripped.items.first, equals(original.items.first));
      });
    });

    group('ShoppingList value equality (Freezed ==)', () {
      test('two lists with same data are equal', () {
        final now = DateTime(2026, 5, 12);
        final l1 = ShoppingList(id: 'x', name: 'List', createdAt: now, updatedAt: now);
        final l2 = ShoppingList(id: 'x', name: 'List', createdAt: now, updatedAt: now);

        expect(l1, equals(l2));
      });

      test('copyWith updates name', () {
        final now = DateTime(2026, 5, 12);
        final original = ShoppingList(id: 'x', name: 'Old', createdAt: now, updatedAt: now);
        final updated = original.copyWith(name: 'New');

        expect(updated.name, equals('New'));
        expect(updated.id, equals('x'));
      });
    });
  });
}
