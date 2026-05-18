import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutriguide_mobile/core/storage/storage_providers.dart';
import 'package:nutriguide_mobile/core/supabase/supabase_providers.dart';
import 'package:nutriguide_mobile/features/profile/data/profile_repository_impl.dart';
import 'package:nutriguide_mobile/features/profile/domain/profile_repository.dart';

/// Provides the [ProfileRepositoryImpl] wired to [sharedPreferencesProvider]
/// and [supabaseClientProvider].
///
/// Typed as [ProfileRepository] (abstract interface) so callers depend on
/// the contract, not the implementation — follows AD-27, AD-51.
///
/// Both [sharedPreferencesProvider] and [supabaseClientProvider] MUST be
/// available in [ProviderScope] before [runApp].
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    sharedPreferences: ref.read(sharedPreferencesProvider),
    supabaseClient: ref.read(supabaseClientProvider),
  );
});
