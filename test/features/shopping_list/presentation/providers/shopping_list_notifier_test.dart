// Spec: SHOPPING-LIST-006 sc1–sc5
// TDD: T-3.1 [RED] — Tests FAIL until shopping_list_notifier.dart is created (T-3.2).
// Design: AD-21

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/shopping_list/data/shopping_list_providers.dart';
import 'package:nutriguide_mobile/features/shopping_list/data/shopping_list_repository_impl.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_item.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_list.dart';
import 'package:nutriguide_mobile/features/shopping_list/presentation/providers/shopping_list_notifier.dart';

// ---------------------------------------------------------------------------
// Mock + Fake (required by mocktail for any() with custom types)
// ---------------------------------------------------------------------------
class MockShoppingListRepo extends Mock implements ShoppingListRepositoryImpl {}

/// Fake used to register a fallback value for [ShoppingList] with mocktail.
/// Required whenever `any()` is used as an argument matcher for a parameter
/// of type [ShoppingList] (e.g., in `when(() => mockRepo.saveList(any()))`).
class _FakeShoppingList extends Fake implements ShoppingList {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------
ShoppingItem _makeItem({
  String id = 'item-1',
  String name = 'Leche',
  bool isChecked = false,
  double? estimatedPrice,
}) =>
    ShoppingItem(
      id: id,
      name: name,
      isChecked: isChecked,
      estimatedPrice: estimatedPrice,
    );

ShoppingList _makeList({
  String id = 'list-1',
  String name = 'Mi lista de compras',
  List<ShoppingItem>? items,
}) =>
    ShoppingList(
      id: id,
      name: name,
      items: items ?? [],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

// ---------------------------------------------------------------------------
// Helper — ProviderContainer with mock repo injected
// ---------------------------------------------------------------------------
ProviderContainer _makeContainer(MockShoppingListRepo mockRepo) {
  return ProviderContainer(
    overrides: [
      shoppingListRepositoryProvider.overrideWithValue(mockRepo),
    ],
  );
}

void main() {
  // Register fallback value for ShoppingList so mocktail any() works with it.
  setUpAll(() {
    registerFallbackValue(_FakeShoppingList());
  });

  // ---------------------------------------------------------------------------
  // State variants — sealed class structural tests
  // ---------------------------------------------------------------------------
  group('ShoppingListState sealed class', () {
    test('ShoppingListLoading is a valid ShoppingListState instance', () {
      const state = ShoppingListLoading();

      expect(state, isA<ShoppingListState>());
      expect(state, isA<ShoppingListLoading>());
    });

    test('ShoppingListData holds a ShoppingList', () {
      final list = _makeList();
      final state = ShoppingListData(list);

      expect(state, isA<ShoppingListState>());
      expect(state.list, equals(list));
    });

    test('ShoppingListEmpty is a valid ShoppingListState instance', () {
      const state = ShoppingListEmpty();

      expect(state, isA<ShoppingListState>());
      expect(state, isA<ShoppingListEmpty>());
    });

    test('sealed class switch is exhaustive over all 3 variants', () {
      final list = _makeList();
      final states = <ShoppingListState>[
        const ShoppingListLoading(),
        ShoppingListData(list),
        const ShoppingListEmpty(),
      ];

      final labels = states.map((s) => switch (s) {
            ShoppingListLoading() => 'loading',
            ShoppingListData(:final list) => 'data:${list.name}',
            ShoppingListEmpty() => 'empty',
          }).toList();

      expect(
        labels,
        equals(['loading', 'data:Mi lista de compras', 'empty']),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // ShoppingListNotifier — behavior tests
  // ---------------------------------------------------------------------------
  group('ShoppingListNotifier', () {
    late MockShoppingListRepo mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockShoppingListRepo();
      container = _makeContainer(mockRepo);
    });

    tearDown(() => container.dispose());

    // -------------------------------------------------------------------------
    // SHOPPING-LIST-006 sc1 — build() resolves to ShoppingListData after auto-create
    // -------------------------------------------------------------------------
    test('sc1 — build() resolves to ShoppingListData with list from repo', () async {
      final list = _makeList(name: 'Mi lista de compras');
      when(() => mockRepo.getOrCreateDefaultList())
          .thenAnswer((_) async => Right(list));

      final asyncValue =
          await container.read(shoppingListNotifierProvider.future);

      expect(asyncValue, isA<ShoppingListData>());
      final data = asyncValue as ShoppingListData;
      expect(data.list.name, equals('Mi lista de compras'));
    });

    // TRIANGULATE: on repo failure, build() resolves to ShoppingListEmpty
    test('build() resolves to ShoppingListEmpty when repo returns failure', () async {
      when(() => mockRepo.getOrCreateDefaultList())
          .thenAnswer((_) async => const Left(CacheFailure('disk error')));

      final asyncValue =
          await container.read(shoppingListNotifierProvider.future);

      expect(asyncValue, isA<ShoppingListEmpty>());
    });

    // -------------------------------------------------------------------------
    // SHOPPING-LIST-006 sc2 — addItem() updates state + calls saveList()
    // -------------------------------------------------------------------------
    test('sc2 — addItem() appends item to state and calls saveList()', () async {
      final initialList = _makeList(items: []);
      final newItem = _makeItem(id: 'item-new', name: 'Pan');

      when(() => mockRepo.getOrCreateDefaultList())
          .thenAnswer((_) async => Right(initialList));
      when(() => mockRepo.saveList(any()))
          .thenAnswer((_) async => const Right(null));

      // Wait for build()
      await container.read(shoppingListNotifierProvider.future);

      // Call addItem
      await container
          .read(shoppingListNotifierProvider.notifier)
          .addItem(newItem);

      final asyncValue = container.read(shoppingListNotifierProvider);
      expect(asyncValue, isA<AsyncData<ShoppingListState>>());
      final data = asyncValue.value as ShoppingListData;
      expect(data.list.items, hasLength(1));
      expect(data.list.items.first.name, equals('Pan'));

      // Verify saveList was called once (after addItem)
      verify(() => mockRepo.saveList(any())).called(1);
    });

    // TRIANGULATE sc2: addItem() with two items accumulates correctly
    test('sc2 triangulate — addItem() with two calls accumulates 2 items', () async {
      final initialList = _makeList(items: []);
      final item1 = _makeItem(id: 'i1', name: 'Leche');
      final item2 = _makeItem(id: 'i2', name: 'Manteca');

      when(() => mockRepo.getOrCreateDefaultList())
          .thenAnswer((_) async => Right(initialList));
      when(() => mockRepo.saveList(any()))
          .thenAnswer((_) async => const Right(null));

      await container.read(shoppingListNotifierProvider.future);

      final notifier = container.read(shoppingListNotifierProvider.notifier);
      await notifier.addItem(item1);
      await notifier.addItem(item2);

      final data = container.read(shoppingListNotifierProvider).value as ShoppingListData;
      expect(data.list.items, hasLength(2));
      expect(data.list.items.map((i) => i.name), containsAllInOrder(['Leche', 'Manteca']));
    });

    // -------------------------------------------------------------------------
    // SHOPPING-LIST-006 sc3 — toggleItem() re-sorts (unchecked first, checked last)
    // -------------------------------------------------------------------------
    test('sc3 — toggleItem() moves item to checked group and re-sorts', () async {
      // Initial: A(unchecked), B(unchecked), C(checked)
      final itemA = _makeItem(id: 'A', name: 'A', isChecked: false);
      final itemB = _makeItem(id: 'B', name: 'B', isChecked: false);
      final itemC = _makeItem(id: 'C', name: 'C', isChecked: true);
      final initialList = _makeList(items: [itemA, itemB, itemC]);

      when(() => mockRepo.getOrCreateDefaultList())
          .thenAnswer((_) async => Right(initialList));
      when(() => mockRepo.saveList(any()))
          .thenAnswer((_) async => const Right(null));

      await container.read(shoppingListNotifierProvider.future);

      // Toggle A → checked
      await container
          .read(shoppingListNotifierProvider.notifier)
          .toggleItem('A');

      final data = container.read(shoppingListNotifierProvider).value as ShoppingListData;
      final itemIds = data.list.items.map((i) => i.id).toList();
      // Expected sort: B(unchecked), A(checked), C(checked)
      expect(itemIds, equals(['B', 'A', 'C']));
      // A is now checked
      final toggledA = data.list.items.firstWhere((i) => i.id == 'A');
      expect(toggledA.isChecked, isTrue);
    });

    // TRIANGULATE sc3: toggling a checked item moves it back to unchecked group
    test('sc3 triangulate — toggleItem() unchecked item moves to front group', () async {
      final itemA = _makeItem(id: 'A', name: 'A', isChecked: false);
      final itemB = _makeItem(id: 'B', name: 'B', isChecked: true);
      final initialList = _makeList(items: [itemA, itemB]);

      when(() => mockRepo.getOrCreateDefaultList())
          .thenAnswer((_) async => Right(initialList));
      when(() => mockRepo.saveList(any()))
          .thenAnswer((_) async => const Right(null));

      await container.read(shoppingListNotifierProvider.future);

      // Toggle B → unchecked
      await container
          .read(shoppingListNotifierProvider.notifier)
          .toggleItem('B');

      final data = container.read(shoppingListNotifierProvider).value as ShoppingListData;
      final itemIds = data.list.items.map((i) => i.id).toList();
      // Both unchecked — insertion order: A first (was already first), B second
      expect(itemIds, equals(['A', 'B']));
      final toggledB = data.list.items.firstWhere((i) => i.id == 'B');
      expect(toggledB.isChecked, isFalse);
    });

    // -------------------------------------------------------------------------
    // SHOPPING-LIST-006 sc4 — removeItem() updates state correctly
    // -------------------------------------------------------------------------
    test('sc4 — removeItem() removes item from state and leaves the rest', () async {
      final itemA = _makeItem(id: 'A', name: 'A', estimatedPrice: 20.0);
      final itemB = _makeItem(id: 'B', name: 'B', estimatedPrice: 35.0);
      final initialList = _makeList(items: [itemA, itemB]);

      when(() => mockRepo.getOrCreateDefaultList())
          .thenAnswer((_) async => Right(initialList));
      when(() => mockRepo.saveList(any()))
          .thenAnswer((_) async => const Right(null));

      await container.read(shoppingListNotifierProvider.future);

      await container
          .read(shoppingListNotifierProvider.notifier)
          .removeItem('A');

      final data = container.read(shoppingListNotifierProvider).value as ShoppingListData;
      expect(data.list.items, hasLength(1));
      expect(data.list.items.first.id, equals('B'));
      expect(data.list.items.first.estimatedPrice, equals(35.0));
    });

    // TRIANGULATE sc4: removing last item leaves empty items list
    test('sc4 triangulate — removeItem() on last item leaves empty items list', () async {
      final itemA = _makeItem(id: 'A', name: 'A');
      final initialList = _makeList(items: [itemA]);

      when(() => mockRepo.getOrCreateDefaultList())
          .thenAnswer((_) async => Right(initialList));
      when(() => mockRepo.saveList(any()))
          .thenAnswer((_) async => const Right(null));

      await container.read(shoppingListNotifierProvider.future);

      await container
          .read(shoppingListNotifierProvider.notifier)
          .removeItem('A');

      final data = container.read(shoppingListNotifierProvider).value as ShoppingListData;
      expect(data.list.items, isEmpty);
    });

    // -------------------------------------------------------------------------
    // SHOPPING-LIST-006 sc5 — clearChecked() removes all checked items
    // -------------------------------------------------------------------------
    test('sc5 — clearChecked() removes all checked items, keeps unchecked', () async {
      final itemA = _makeItem(id: 'A', name: 'A', isChecked: false);
      final itemB = _makeItem(id: 'B', name: 'B', isChecked: true);
      final itemC = _makeItem(id: 'C', name: 'C', isChecked: true);
      final initialList = _makeList(items: [itemA, itemB, itemC]);

      when(() => mockRepo.getOrCreateDefaultList())
          .thenAnswer((_) async => Right(initialList));
      when(() => mockRepo.saveList(any()))
          .thenAnswer((_) async => const Right(null));

      await container.read(shoppingListNotifierProvider.future);

      await container
          .read(shoppingListNotifierProvider.notifier)
          .clearChecked();

      final data = container.read(shoppingListNotifierProvider).value as ShoppingListData;
      expect(data.list.items, hasLength(1));
      expect(data.list.items.first.id, equals('A'));
      expect(data.list.items.first.isChecked, isFalse);
    });

    // TRIANGULATE sc5: clearChecked() on all-unchecked list changes nothing
    test('sc5 triangulate — clearChecked() keeps all items when none are checked', () async {
      final itemA = _makeItem(id: 'A', name: 'A', isChecked: false);
      final itemB = _makeItem(id: 'B', name: 'B', isChecked: false);
      final initialList = _makeList(items: [itemA, itemB]);

      when(() => mockRepo.getOrCreateDefaultList())
          .thenAnswer((_) async => Right(initialList));
      when(() => mockRepo.saveList(any()))
          .thenAnswer((_) async => const Right(null));

      await container.read(shoppingListNotifierProvider.future);

      await container
          .read(shoppingListNotifierProvider.notifier)
          .clearChecked();

      final data = container.read(shoppingListNotifierProvider).value as ShoppingListData;
      expect(data.list.items, hasLength(2));
    });

    // -------------------------------------------------------------------------
    // Sort invariant — every mutation maintains unchecked-first order
    // -------------------------------------------------------------------------
    test('sort order invariant — addItem() inserts unchecked at correct position', () async {
      // Start with: A(checked)
      final itemA = _makeItem(id: 'A', name: 'A', isChecked: true);
      final initialList = _makeList(items: [itemA]);
      final newItem = _makeItem(id: 'B', name: 'B', isChecked: false);

      when(() => mockRepo.getOrCreateDefaultList())
          .thenAnswer((_) async => Right(initialList));
      when(() => mockRepo.saveList(any()))
          .thenAnswer((_) async => const Right(null));

      await container.read(shoppingListNotifierProvider.future);
      await container.read(shoppingListNotifierProvider.notifier).addItem(newItem);

      final data = container.read(shoppingListNotifierProvider).value as ShoppingListData;
      final itemIds = data.list.items.map((i) => i.id).toList();
      // B(unchecked) should come before A(checked) after sorting
      expect(itemIds, equals(['B', 'A']));
    });
  });
}
