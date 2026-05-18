// Spec: SHOPPING-LIST-001 sc1–sc7 | SHOPPING-LIST-SYNC-001 S1–S7
// TDD: Phase 3 [RED→GREEN] — Tests drive ShoppingListRepositoryImpl
// to use Supabase + Hive write-through.

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/shopping_list/data/shopping_list_repository_impl.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_item.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_list.dart';
import '../../../helpers/mock_supabase.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------
class MockBox extends Mock implements Box<dynamic> {}

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

// Raw Supabase row data (simulates PostgREST response)
Map<String, dynamic> _makeListRow({
  String id = 'list-uuid-1',
  String name = 'Mi lista',
  List<Map<String, dynamic>>? items,
}) =>
    {
      'id': id,
      'name': name,
      'user_id': 'user-123',
      'created_at': '2026-01-01T00:00:00.000Z',
      'updated_at': '2026-01-01T00:00:00.000Z',
      'shopping_items': items ?? <Map<String, dynamic>>[],
    };

Map<String, dynamic> _makeItemRow({
  String id = 'item-uuid-1',
  String name = 'Leche',
}) =>
    {
      'id': id,
      'list_id': 'list-uuid-1',
      'name': name,
      'quantity': null,
      'unit': null,
      'estimated_price': null,
      'is_checked': false,
      'product_barcode': null,
    };

// ---------------------------------------------------------------------------
// Mock instances (shared across stub helpers so the same instance is reused
// when from() is called with the same table name)
// ---------------------------------------------------------------------------

// These are created fresh per test via the helper functions below.
// We use factory functions to allow per-test wiring.

/// A comprehensive mock setup for shopping_list operations.
///
/// CRITICAL (Phase 1 gotcha): ALL PostgREST builders implement Future<T>.
/// MUST use thenAnswer (NOT thenReturn) for ALL builder stubs.
class _SupabaseMocks {
  _SupabaseMocks() {
    // shopping_lists query builder + filter + transform
    listsQueryBuilder = MockSupabaseQueryBuilder();
    listsFilterBuilder = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
    listsTransformBuilder = MockPostgrestTransformBuilder<List<Map<String, dynamic>>>();
    listsUpsertFilter = MockPostgrestFilterBuilder<void>();
    listsDeleteFilter = MockPostgrestFilterBuilder<void>();

    // shopping_items builder + filter
    itemsQueryBuilder = MockSupabaseQueryBuilder();
    itemsDeleteFilter = MockPostgrestFilterBuilder<void>();
    itemsInsertFilter = MockPostgrestFilterBuilder<void>();
  }

  late MockSupabaseQueryBuilder listsQueryBuilder;
  late MockPostgrestFilterBuilder<List<Map<String, dynamic>>> listsFilterBuilder;
  late MockPostgrestTransformBuilder<List<Map<String, dynamic>>> listsTransformBuilder;
  late MockPostgrestFilterBuilder<void> listsUpsertFilter;
  late MockPostgrestFilterBuilder<void> listsDeleteFilter;

  late MockSupabaseQueryBuilder itemsQueryBuilder;
  late MockPostgrestFilterBuilder<void> itemsDeleteFilter;
  late MockPostgrestFilterBuilder<void> itemsInsertFilter;

  /// Wire all stubs onto [mockSupabase].
  ///
  /// [getAllListsResponse] is what the `.select().eq().order()` chain returns.
  void wireAll(
    MockSupabaseClient mockSupabase,
    String userId, {
    List<Map<String, dynamic>>? getAllListsResponse,
  }) {
    // ── shopping_lists ────────────────────────────────────────────────────
    when(() => mockSupabase.from('shopping_lists'))
        .thenAnswer((_) => listsQueryBuilder);

    // getAllLists chain: select → eq → order → await
    when(() => listsQueryBuilder.select('*, shopping_items(*)'))
        .thenAnswer((_) => listsFilterBuilder);
    when(() => listsFilterBuilder.eq('user_id', userId))
        .thenAnswer((_) => listsFilterBuilder);
    when(() => listsFilterBuilder.order('created_at'))
        .thenAnswer((_) => listsTransformBuilder);

    final responseData =
        getAllListsResponse ?? <Map<String, dynamic>>[];
    when(
      () => listsTransformBuilder.then<dynamic>(
        any(),
        onError: any(named: 'onError'),
      ),
    ).thenAnswer((inv) {
      final onValue = inv.positionalArguments[0] as Function;
      // Pass as List<Map<String, dynamic>> — the impl casts it as List<dynamic>
      return Future<List<Map<String, dynamic>>>.value(responseData)
          .then((v) => onValue(v));
    });

    // saveList: upsert chain
    when(() => listsQueryBuilder.upsert(any<Map<String, dynamic>>()))
        .thenAnswer((_) => listsUpsertFilter);
    when(
      () => listsUpsertFilter.then<dynamic>(
        any(),
        onError: any(named: 'onError'),
      ),
    ).thenAnswer((inv) {
      final onValue = inv.positionalArguments[0] as Function;
      return Future<void>.value().then((_) => onValue(null));
    });

    // deleteList: delete chain  
    when(() => listsQueryBuilder.delete())
        .thenAnswer((_) => listsDeleteFilter);
    when(() => listsDeleteFilter.eq('id', any<String>()))
        .thenAnswer((_) => listsDeleteFilter);
    when(
      () => listsDeleteFilter.then<dynamic>(
        any(),
        onError: any(named: 'onError'),
      ),
    ).thenAnswer((inv) {
      final onValue = inv.positionalArguments[0] as Function;
      return Future<void>.value().then((_) => onValue(null));
    });

    // ── shopping_items ────────────────────────────────────────────────────
    when(() => mockSupabase.from('shopping_items'))
        .thenAnswer((_) => itemsQueryBuilder);

    // delete items chain
    when(() => itemsQueryBuilder.delete())
        .thenAnswer((_) => itemsDeleteFilter);
    when(() => itemsDeleteFilter.eq('list_id', any<String>()))
        .thenAnswer((_) => itemsDeleteFilter);
    when(
      () => itemsDeleteFilter.then<dynamic>(
        any(),
        onError: any(named: 'onError'),
      ),
    ).thenAnswer((inv) {
      final onValue = inv.positionalArguments[0] as Function;
      return Future<void>.value().then((_) => onValue(null));
    });

    // insert items chain
    when(() => itemsQueryBuilder.insert(any<List<Map<String, dynamic>>>()))
        .thenAnswer((_) => itemsInsertFilter);
    when(
      () => itemsInsertFilter.then<dynamic>(
        any(),
        onError: any(named: 'onError'),
      ),
    ).thenAnswer((inv) {
      final onValue = inv.positionalArguments[0] as Function;
      return Future<void>.value().then((_) => onValue(null));
    });
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late MockBox mockBox;
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late ShoppingListRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(<dynamic>[]);
    registerFallbackValue(<Map<String, dynamic>>[]);
  });

  setUp(() {
    mockBox = MockBox();
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockSupabase.auth).thenAnswer((_) => mockAuth);

    repository = ShoppingListRepositoryImpl(
      box: mockBox,
      supabaseClient: mockSupabase,
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 1: getAllLists() — authenticated → Supabase + Hive update
  // ─────────────────────────────────────────────────────────────────────────
  group('getAllLists() — authenticated fetches from Supabase + updates Hive', () {
    test('S1 — returns lists from Supabase and updates Hive cache', () async {
      final fakeUser = createFakeUser();
      when(() => mockAuth.currentUser).thenReturn(fakeUser);

      final listRow = _makeListRow(items: [_makeItemRow(name: 'Pan')]);
      final mocks = _SupabaseMocks()
        ..wireAll(mockSupabase, fakeUser.id, getAllListsResponse: [listRow]);

      when(() => mockBox.clear()).thenAnswer((_) async => 0);
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      final result = await repository.getAllLists();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right but got Left'),
        (lists) {
          expect(lists, hasLength(1));
          expect(lists.first.name, equals('Mi lista'));
          expect(lists.first.items, hasLength(1));
          expect(lists.first.items.first.name, equals('Pan'));
        },
      );

      verify(() => mockBox.clear()).called(1);
      verify(() => mockBox.put(any(), any())).called(1);
    });

    test('S1 triangulate — multiple lists are all returned and cached', () async {
      final fakeUser = createFakeUser();
      when(() => mockAuth.currentUser).thenReturn(fakeUser);

      final rows = [
        _makeListRow(id: 'list-1', name: 'Lista A'),
        _makeListRow(id: 'list-2', name: 'Lista B'),
      ];
      final mocks = _SupabaseMocks()
        ..wireAll(mockSupabase, fakeUser.id, getAllListsResponse: rows);

      when(() => mockBox.clear()).thenAnswer((_) async => 0);
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      final result = await repository.getAllLists();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (lists) => expect(lists, hasLength(2)),
      );
      verify(() => mockBox.put(any(), any())).called(2);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 2: getAllLists() — unauthenticated → Hive only
  // ─────────────────────────────────────────────────────────────────────────
  group('getAllLists() — unauthenticated reads from Hive only', () {
    test('S2 — unauthenticated: reads from Hive, NEVER calls Supabase', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final list = _makeList();
      when(() => mockBox.values).thenReturn([list.toJson()]);

      final result = await repository.getAllLists();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (lists) {
          expect(lists, hasLength(1));
          expect(lists.first.id, equals('list-1'));
        },
      );

      verifyNever(() => mockSupabase.from(any()));
    });

    test('S2 triangulate — unauthenticated + empty Hive returns Right([])', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      when(() => mockBox.values).thenReturn([]);

      final result = await repository.getAllLists();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (lists) => expect(lists, isEmpty),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 3: saveList() — authenticated → upsert Supabase + Hive
  // ─────────────────────────────────────────────────────────────────────────
  group('saveList() — authenticated upserts to Supabase + updates Hive', () {
    test('S3 — upserts list, deletes + inserts items, calls Hive.put()', () async {
      final fakeUser = createFakeUser();
      when(() => mockAuth.currentUser).thenReturn(fakeUser);

      // List with a valid UUID id so saveList doesn't regenerate it
      final list = _makeList(
        id: '11111111-1111-4111-8111-111111111111',
        items: [_makeItem()],
      );

      final mocks = _SupabaseMocks()
        ..wireAll(mockSupabase, fakeUser.id);
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      final result = await repository.saveList(list);

      expect(result.isRight(), isTrue);
      // Hive.put must be called with the list's id
      verify(() => mockBox.put('11111111-1111-4111-8111-111111111111', any()))
          .called(1);
    });

    test('S3 unauthenticated — only updates Hive, no Supabase', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      final list = _makeList(id: '11111111-1111-4111-8111-111111111111');
      final result = await repository.saveList(list);

      expect(result.isRight(), isTrue);
      verifyNever(() => mockSupabase.from(any()));
      verify(() => mockBox.put(any(), any())).called(1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 4: deleteList() — authenticated → Supabase + Hive
  // ─────────────────────────────────────────────────────────────────────────
  group('deleteList() — authenticated deletes from Supabase + Hive', () {
    test('S4 — deletes from Supabase and calls Hive.delete()', () async {
      final fakeUser = createFakeUser();
      when(() => mockAuth.currentUser).thenReturn(fakeUser);

      final mocks = _SupabaseMocks()
        ..wireAll(mockSupabase, fakeUser.id);
      when(() => mockBox.delete(any())).thenAnswer((_) async {});

      final result = await repository.deleteList('list-id-123');

      expect(result.isRight(), isTrue);
      verify(() => mockBox.delete('list-id-123')).called(1);
    });

    test('S4 unauthenticated — only deletes from Hive, no Supabase', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      when(() => mockBox.delete(any())).thenAnswer((_) async {});

      final result = await repository.deleteList('list-1');

      expect(result.isRight(), isTrue);
      verifyNever(() => mockSupabase.from(any()));
      verify(() => mockBox.delete('list-1')).called(1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 5: UUID format validation
  // ─────────────────────────────────────────────────────────────────────────
  group('UUID format — IDs are valid UUID v4', () {
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    test('S5 — getOrCreateDefaultList() creates list with UUID v4 id', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      when(() => mockBox.values).thenReturn([]);
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      final result = await repository.getOrCreateDefaultList();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (list) {
          expect(
            uuidRegex.hasMatch(list.id),
            isTrue,
            reason: 'List ID "${list.id}" is not a valid UUID v4',
          );
        },
      );
    });

    test('S6 — two new lists get different UUID ids', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      when(() => mockBox.values).thenReturn([]);
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      final r1 = await repository.getOrCreateDefaultList();
      when(() => mockBox.values).thenReturn([]); // reset for second call
      final r2 = await repository.getOrCreateDefaultList();

      final id1 = r1.getRight().toNullable()!.id;
      final id2 = r2.getRight().toNullable()!.id;

      expect(uuidRegex.hasMatch(id1), isTrue);
      expect(uuidRegex.hasMatch(id2), isTrue);
      expect(id1, isNot(equals(id2)));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 6: getOrCreateDefaultList() — authenticated, no lists → creates
  // ─────────────────────────────────────────────────────────────────────────
  group('getOrCreateDefaultList() — authenticated with no lists creates in Supabase', () {
    test('S7 — creates and upserts a new default list when none exist', () async {
      final fakeUser = createFakeUser();
      when(() => mockAuth.currentUser).thenReturn(fakeUser);

      // getAllLists returns empty; saveList upserts + clears items
      final mocks = _SupabaseMocks()
        ..wireAll(mockSupabase, fakeUser.id, getAllListsResponse: []);

      when(() => mockBox.clear()).thenAnswer((_) async => 0);
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      final result = await repository.getOrCreateDefaultList();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (list) {
          expect(list, isA<ShoppingList>());
          expect(list.name, isNotEmpty);
          expect(list.id, isNotEmpty);
        },
      );

      // Hive.put must be called at least once (from saveList)
      verify(() => mockBox.put(any(), any())).called(greaterThanOrEqualTo(1));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 7: getListById — local-only Hive read
  // ─────────────────────────────────────────────────────────────────────────
  group('getListById', () {
    test('returns Right(list) when id exists in Hive', () async {
      final list = _makeList(id: 'abc');
      when(() => mockBox.get('abc')).thenReturn(list.toJson());

      final result = await repository.getListById('abc');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (found) => expect(found.id, equals('abc')),
      );
    });

    test('returns Left(CacheFailure) when id not in Hive', () async {
      when(() => mockBox.get(any())).thenReturn(null);

      final result = await repository.getListById('nonexistent');

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });
}
