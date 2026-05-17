import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutriguide_mobile/core/storage/storage_providers.dart';
import 'package:nutriguide_mobile/features/shopping_list/data/shopping_list_repository_impl.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_list_repository.dart';

/// Provides [ShoppingListRepository] (abstract interface) backed by
/// [ShoppingListRepositoryImpl] wired to [shoppingListsBoxProvider].
///
/// Typed as [ShoppingListRepository] so callers depend on the contract, not
/// the implementation — follows AD-50.
final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  return ShoppingListRepositoryImpl(
    shoppingListsBox: ref.read(shoppingListsBoxProvider),
  );
});
