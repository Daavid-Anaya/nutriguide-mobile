import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nutriguide_mobile/core/supabase/supabase_providers.dart';
import 'package:nutriguide_mobile/features/auth/data/secure_storage_service.dart';
import 'package:nutriguide_mobile/features/auth/data/supabase_auth_repository.dart';
import 'package:nutriguide_mobile/features/auth/domain/auth_repository.dart';

/// Provider for [AuthRepository] backed by Supabase.
/// Override in tests with MockAuthRepository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(client: ref.read(supabaseClientProvider));
});

// ---------------------------------------------------------------------------
// Deprecated providers — kept for backward compatibility during migration.
// Will be removed once all usages are migrated to authRepositoryProvider.
// ---------------------------------------------------------------------------

/// @deprecated Use [authRepositoryProvider] instead.
/// Supabase manages session persistence — FlutterSecureStorage is no longer
/// needed for auth (AD-49).
@Deprecated('Use authRepositoryProvider — Supabase manages sessions')
final flutterSecureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

/// @deprecated Use [authRepositoryProvider] instead.
@Deprecated('Use authRepositoryProvider — Supabase manages sessions')
final secureStorageServiceProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(ref.read(flutterSecureStorageProvider)),
);
