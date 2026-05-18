// Spec: SHOPPING-LIST-001 | SHOPPING-LIST-SYNC-001
// Design: AD-52, AD-54, AD-55, AD-56
// TDD: Phase 3 [GREEN] — Supabase + Hive write-through implementation

import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_item.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_list.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_list_repository.dart';

/// Supabase-backed implementation of [ShoppingListRepository] with Hive cache.
///
/// Pattern: **read Supabase → update Hive → return** (AD-52).
/// Falls back to Hive when unauthenticated (AD-56) or on Supabase error.
/// All Supabase queries are scoped by RLS — no explicit userId filtering
/// beyond the initial `eq('user_id', ...)` for `getAllLists` (AD-54).
/// Client-side UUID via `uuid` package for new list/item IDs (AD-55).
///
/// Spec: SHOPPING-LIST-001 | SHOPPING-LIST-SYNC-001 | Design: AD-52.
class ShoppingListRepositoryImpl implements ShoppingListRepository {
  ShoppingListRepositoryImpl({
    required Box<dynamic> box,
    required SupabaseClient supabaseClient,
  })  : _box = box,
        _supabase = supabaseClient;

  final Box<dynamic> _box;
  final SupabaseClient _supabase;
  static const _uuid = Uuid();

  // ── ShoppingListRepository — abstract interface ───────────────────────────

  @override
  Future<Either<Failure, List<ShoppingList>>> getAllLists() async {
    final userId = _supabase.auth.currentUser?.id;

    // AD-56: Unauthenticated — read from Hive only
    if (userId == null) {
      return _readFromHive();
    }

    try {
      final response = await _supabase
          .from('shopping_lists')
          .select('*, shopping_items(*)')
          .eq('user_id', userId)
          .order('created_at');

      final lists = (response as List<dynamic>)
          .map((e) => _mapToShoppingList(e as Map<String, dynamic>))
          .toList();

      // Server wins — clear Hive and repopulate (AD-52)
      await _box.clear();
      for (final list in lists) {
        await _box.put(list.id, list.toJson());
      }

      return Right(lists);
    } catch (_) {
      // Fall back to Hive on any error
      return _readFromHive();
    }
  }

  @override
  Future<Either<Failure, ShoppingList>> getListById(String id) async {
    // Local-only read — used by internal callers
    try {
      final raw = _box.get(id);
      if (raw == null) return const Left(CacheFailure('List not found'));
      return Right(
        ShoppingList.fromJson(Map<String, dynamic>.from(raw as Map)),
      );
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveList(ShoppingList list) async {
    final userId = _supabase.auth.currentUser?.id;

    // Ensure list has a valid UUID id (AD-55)
    final listToSave = list.id.isEmpty || !_isUuid(list.id)
        ? list.copyWith(id: _uuid.v4())
        : list;

    // Always update Hive cache first
    await _box.put(listToSave.id, listToSave.toJson());

    if (userId == null) return const Right(null); // AD-56: local-only

    try {
      // Upsert list row
      await _supabase.from('shopping_lists').upsert({
        'id': listToSave.id,
        'user_id': userId,
        'name': listToSave.name,
        'created_at': listToSave.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Delete existing items + re-insert (simpler than diffing — AD-52 note)
      await _supabase
          .from('shopping_items')
          .delete()
          .eq('list_id', listToSave.id);

      if (listToSave.items.isNotEmpty) {
        await _supabase.from('shopping_items').insert(
          listToSave.items
              .map((item) => _itemToMap(item, listToSave.id))
              .toList(),
        );
      }

      return const Right(null);
    } on Exception catch (e) {
      return Left(CacheFailure('Failed to save list: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteList(String id) async {
    await _box.delete(id);

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return const Right(null); // AD-56: local-only

    try {
      await _supabase.from('shopping_lists').delete().eq('id', id);
      return const Right(null);
    } on Exception catch (e) {
      return Left(CacheFailure('Failed to delete list: $e'));
    }
  }

  @override
  Future<Either<Failure, ShoppingList>> getOrCreateDefaultList() async {
    final result = await getAllLists();
    return result.fold(
      Left.new,
      (lists) async {
        if (lists.isNotEmpty) return Right(lists.first);

        final now = DateTime.now();
        final defaultList = ShoppingList(
          id: _uuid.v4(), // AD-55: client-side UUID
          name: 'Mi lista',
          items: const [],
          createdAt: now,
          updatedAt: now,
        );

        final saveResult = await saveList(defaultList);
        return saveResult.fold(Left.new, (_) => Right(defaultList));
      },
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Either<Failure, List<ShoppingList>> _readFromHive() {
    try {
      final lists = _box.values
          .map(
            (e) => ShoppingList.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
      return Right(lists);
    } catch (e) {
      return Left(CacheFailure('Failed to read from cache: $e'));
    }
  }

  ShoppingList _mapToShoppingList(Map<String, dynamic> row) {
    final itemsData = row['shopping_items'] as List<dynamic>? ?? [];
    final items = itemsData
        .map((e) => _mapToShoppingItem(e as Map<String, dynamic>))
        .toList();

    return ShoppingList(
      id: row['id'] as String,
      name: row['name'] as String,
      items: items,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  ShoppingItem _mapToShoppingItem(Map<String, dynamic> row) {
    return ShoppingItem(
      id: row['id'] as String,
      name: row['name'] as String,
      quantity: (row['quantity'] as num?)?.toDouble(),
      unit: row['unit'] as String?,
      estimatedPrice: (row['estimated_price'] as num?)?.toDouble(),
      isChecked: row['is_checked'] as bool? ?? false,
      productBarcode: row['product_barcode'] as String?,
    );
  }

  Map<String, dynamic> _itemToMap(ShoppingItem item, String listId) {
    // Ensure item also has UUID id (AD-55)
    final itemId =
        item.id.isEmpty || !_isUuid(item.id) ? _uuid.v4() : item.id;
    return {
      'id': itemId,
      'list_id': listId,
      'name': item.name,
      'quantity': item.quantity,
      'unit': item.unit,
      'estimated_price': item.estimatedPrice,
      'is_checked': item.isChecked,
      'product_barcode': item.productBarcode,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    ).hasMatch(value);
  }
}
