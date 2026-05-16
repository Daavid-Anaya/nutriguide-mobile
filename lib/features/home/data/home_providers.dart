import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutriguide_mobile/core/storage/storage_providers.dart';
import 'package:nutriguide_mobile/features/home/data/home_repository_impl.dart';
import 'package:nutriguide_mobile/features/home/domain/home_repository.dart';
import 'package:nutriguide_mobile/features/profile/data/profile_providers.dart';
import 'package:nutriguide_mobile/features/shopping_list/data/shopping_list_providers.dart';

/// Provides [HomeRepositoryImpl] wired to its dependencies.
///
/// Typed as [HomeRepository] (abstract interface) so callers depend on the
/// contract, not the implementation — follows AD-34.
///
/// Dependencies injected via constructor (AD-34, AD-41):
/// - [shoppingListRepositoryProvider]: provides [ShoppingListRepositoryImpl]
///   for budget computation via [getOrCreateDefaultList].
/// - [productsBoxProvider]: provides the Hive box of scanned products for
///   health score computation.
/// - [profileRepositoryProvider]: provides [ProfileRepository] for reading
///   [UserProfile.groceryBudget] to set [WellnessSummary.budgetTotal].
final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl(
    shoppingListRepo: ref.read(shoppingListRepositoryProvider),
    productsBox: ref.read(productsBoxProvider),
    profileRepo: ref.read(profileRepositoryProvider),
  );
});
