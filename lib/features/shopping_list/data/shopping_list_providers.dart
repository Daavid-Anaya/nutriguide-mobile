import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutriguide_mobile/core/storage/storage_providers.dart';
import 'package:nutriguide_mobile/features/shopping_list/data/shopping_list_repository_impl.dart';

/// Provides the [ShoppingListRepositoryImpl] wired to the [shoppingListsBoxProvider].
///
/// Provider type is [ShoppingListRepositoryImpl] (not the abstract
/// [ShoppingListRepository]) so callers can access `getOrCreateDefaultList()`
/// which lives on the impl class only (AD-20).
///
/// Callers that only need the abstract interface can type-erase locally.
final shoppingListRepositoryProvider = Provider<ShoppingListRepositoryImpl>((ref) {
  return ShoppingListRepositoryImpl(
    shoppingListsBox: ref.read(shoppingListsBoxProvider),
  );
});
