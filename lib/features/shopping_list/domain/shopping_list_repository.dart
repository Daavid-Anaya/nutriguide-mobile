import 'package:fpdart/fpdart.dart';
import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_list.dart';

/// Abstract contract for shopping list persistence operations.
///
/// All methods return [Either<Failure, T>] — Left for errors, Right for success.
/// Concrete implementations use an offline-first strategy: write to Hive
/// immediately, then sync to the backend when connectivity is available.
abstract class ShoppingListRepository {
  /// Returns all shopping lists for the current user.
  ///
  /// Reads from local Hive cache first; returns [CacheFailure] if cache is
  /// empty and no connection is available.
  Future<Either<Failure, List<ShoppingList>>> getAllLists();

  /// Returns the shopping list with the given [id].
  ///
  /// Returns [CacheFailure] when the list is not found in local storage.
  Future<Either<Failure, ShoppingList>> getListById(String id);

  /// Persists [list] to local storage and queues a background sync.
  ///
  /// Returns [CacheFailure] on a write error.
  Future<Either<Failure, void>> saveList(ShoppingList list);

  /// Deletes the shopping list identified by [id].
  ///
  /// Returns [CacheFailure] when the list does not exist.
  Future<Either<Failure, void>> deleteList(String id);

  /// Returns the first existing list, or creates and saves a default one.
  ///
  /// Auto-creates a default list when no lists exist.
  /// Design: AD-50 — promotes this method from impl-only to the abstract contract.
  Future<Either<Failure, ShoppingList>> getOrCreateDefaultList();
}
