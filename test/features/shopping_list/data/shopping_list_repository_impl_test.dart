// Spec: SHOPPING-LIST-001 sc1–sc5
// TDD: T-2.1 [RED] — Tests FAIL until shopping_list_repository_impl.dart is created (T-2.2).

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/shopping_list/data/shopping_list_repository_impl.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_item.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_list.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------
class _MockBox extends Mock implements Box<dynamic> {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------
ShoppingItem _makeItem({String id = 'item-1', String name = 'Leche'}) =>
    ShoppingItem(id: id, name: name);

ShoppingList _makeList({
  String id = 'list-1',
  String name = 'Mi lista',
  List<ShoppingItem>? items,
}) =>
    ShoppingList(
      id: id,
      name: name,
      items: items ?? [_makeItem()],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  late _MockBox mockBox;
  late ShoppingListRepositoryImpl repository;

  setUp(() {
    mockBox = _MockBox();
    repository = ShoppingListRepositoryImpl(shoppingListsBox: mockBox);
  });

  // ---------------------------------------------------------------------------
  // SHOPPING-LIST-001 sc2 — getAllLists returns empty list when box is empty
  // ---------------------------------------------------------------------------
  group('getAllLists', () {
    test('sc2 — returns Right([]) when box has no entries', () async {
      when(() => mockBox.values).thenReturn([]);

      final result = await repository.getAllLists();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right but got Left'),
        (lists) => expect(lists, isEmpty),
      );
    });

    test('returns Right(lists) with one entry when box has one list', () async {
      final list = _makeList();
      when(() => mockBox.values).thenReturn([list.toJson()]);

      final result = await repository.getAllLists();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right but got Left'),
        (lists) {
          expect(lists, hasLength(1));
          expect(lists.first.id, equals('list-1'));
          expect(lists.first.name, equals('Mi lista'));
        },
      );
    });

    test('returns Left(CacheFailure) when box.values throws', () async {
      when(() => mockBox.values).thenThrow(Exception('box read error'));

      final result = await repository.getAllLists();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('Expected Left but got Right'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // SHOPPING-LIST-001 sc1 — saveList + getListById round-trip
  // ---------------------------------------------------------------------------
  group('saveList + getListById round-trip', () {
    test('sc1 — saveList stores JSON and getListById retrieves correct list', () async {
      final list = _makeList(id: 'abc');
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
      when(() => mockBox.get('abc')).thenReturn(list.toJson());

      final saveResult = await repository.saveList(list);
      final getResult = await repository.getListById('abc');

      expect(saveResult.isRight(), isTrue);
      expect(getResult.isRight(), isTrue);
      getResult.fold(
        (_) => fail('Expected Right but got Left'),
        (found) {
          expect(found.id, equals('abc'));
          expect(found.items, hasLength(1));
        },
      );
    });

    test('getListById returns Left(CacheFailure) when id not in box', () async {
      when(() => mockBox.get(any())).thenReturn(null);

      final result = await repository.getListById('nonexistent');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('Expected Left but got Right'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // SHOPPING-LIST-001 sc5 — saveList wraps exception in Left(CacheFailure)
  // ---------------------------------------------------------------------------
  group('saveList', () {
    test('sc5 — returns Left(CacheFailure) when box.put throws', () async {
      when(() => mockBox.put(any(), any())).thenThrow(Exception('disk full'));

      final list = _makeList();
      final result = await repository.saveList(list);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('Expected Left but got Right'),
      );
    });

    test('returns Right(null) on successful put', () async {
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      final list = _makeList();
      final result = await repository.saveList(list);

      expect(result.isRight(), isTrue);
      verify(() => mockBox.put(list.id, any())).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // deleteList
  // ---------------------------------------------------------------------------
  group('deleteList', () {
    test('returns Right(null) on successful delete', () async {
      when(() => mockBox.delete(any())).thenAnswer((_) async {});

      final result = await repository.deleteList('list-1');

      expect(result.isRight(), isTrue);
      verify(() => mockBox.delete('list-1')).called(1);
    });

    test('returns Left(CacheFailure) when box.delete throws', () async {
      when(() => mockBox.delete(any())).thenThrow(Exception('delete failed'));

      final result = await repository.deleteList('list-1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('Expected Left but got Right'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // SHOPPING-LIST-001 sc3 — getOrCreateDefaultList auto-creates when box empty
  // ---------------------------------------------------------------------------
  group('getOrCreateDefaultList', () {
    test('sc3 — auto-creates "Mi lista de compras" when box is empty', () async {
      when(() => mockBox.values).thenReturn([]);
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      final result = await repository.getOrCreateDefaultList();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right but got Left'),
        (list) {
          expect(list.name, equals('Mi lista de compras'));
          expect(list.items, isEmpty);
          expect(list.id, isNotEmpty);
        },
      );
      // Verify that saveList was called (box.put)
      verify(() => mockBox.put(any(), any())).called(1);
    });

    test('sc4 — returns existing list without creating when box has one', () async {
      final existingList = _makeList(id: 'existing', name: 'Mi lista de compras');
      when(() => mockBox.values).thenReturn([existingList.toJson()]);

      final result = await repository.getOrCreateDefaultList();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right but got Left'),
        (list) {
          expect(list.id, equals('existing'));
          expect(list.name, equals('Mi lista de compras'));
        },
      );
      // Verify that box.put was NOT called (no new list created)
      verifyNever(() => mockBox.put(any(), any()));
    });

    test('returns Left(CacheFailure) when getAllLists throws', () async {
      when(() => mockBox.values).thenThrow(Exception('box error'));

      final result = await repository.getOrCreateDefaultList();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('Expected Left but got Right'),
      );
    });

    test('returns Left(CacheFailure) when auto-created list save fails', () async {
      when(() => mockBox.values).thenReturn([]);
      when(() => mockBox.put(any(), any())).thenThrow(Exception('write failed'));

      final result = await repository.getOrCreateDefaultList();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('Expected Left but got Right'),
      );
    });
  });
}
