import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';
import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_list.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_list_repository.dart';

/// Offline-first implementation of [ShoppingListRepository] backed by Hive.
///
/// Each [ShoppingList] is stored as a `Map<String, dynamic>` (via [toJson])
/// keyed by its [ShoppingList.id]. Hive stores maps as `Map<dynamic, dynamic>`
/// internally — all reads cast with [Map.from] before passing to [fromJson].
///
/// Follows the same storage pattern as [ScannerRepositoryImpl] (AD-08).
/// Spec: SHOPPING-LIST-001 | Design: AD-20.
class ShoppingListRepositoryImpl implements ShoppingListRepository {
  ShoppingListRepositoryImpl({required Box<dynamic> shoppingListsBox})
      : _box = shoppingListsBox;

  final Box<dynamic> _box;

  // ---------------------------------------------------------------------------
  // ShoppingListRepository — abstract interface
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, List<ShoppingList>>> getAllLists() async {
    try {
      final lists = _box.values
          .map((e) => ShoppingList.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return Right(lists);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ShoppingList>> getListById(String id) async {
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
    try {
      await _box.put(list.id, list.toJson());
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteList(String id) async {
    try {
      await _box.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // Convenience method (not on abstract interface — AD-20)
  // ---------------------------------------------------------------------------

  /// Returns the first existing list, or creates and saves a default one.
  ///
  /// Auto-creates `"Mi lista de compras"` when the box is empty.
  /// The new list's [ShoppingList.id] is generated from the current epoch
  /// milliseconds — no external UUID package required (AD-20).
  @override
  Future<Either<Failure, ShoppingList>> getOrCreateDefaultList() async {
    final allResult = await getAllLists();
    return allResult.fold(
      (failure) => Left(failure),
      (lists) async {
        if (lists.isNotEmpty) return Right(lists.first);

        final now = DateTime.now();
        final newList = ShoppingList(
          id: now.millisecondsSinceEpoch.toString(),
          name: 'Mi lista de compras',
          items: const [],
          createdAt: now,
          updatedAt: now,
        );

        final saveResult = await saveList(newList);
        return saveResult.fold(
          (failure) => Left(failure),
          (_) => Right(newList),
        );
      },
    );
  }
}
