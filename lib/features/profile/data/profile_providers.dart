import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutriguide_mobile/core/storage/storage_providers.dart';
import 'package:nutriguide_mobile/features/profile/data/profile_repository_impl.dart';
import 'package:nutriguide_mobile/features/profile/domain/profile_repository.dart';

/// Provides the [ProfileRepositoryImpl] wired to [sharedPreferencesProvider].
///
/// Typed as [ProfileRepository] (abstract interface) so callers depend on
/// the contract, not the implementation — follows AD-27.
///
/// The [sharedPreferencesProvider] MUST be overridden in [ProviderScope]
/// before [runApp] (see storage_providers.dart for override pattern).
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    sharedPreferences: ref.read(sharedPreferencesProvider),
  );
});
