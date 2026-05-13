import 'package:nutriguide_mobile/features/auth/data/auth_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_notifier.g.dart';

/// Riverpod async notifier that manages the JWT auth state.
///
/// State is `String?` where:
/// - `null`        → unauthenticated
/// - non-null      → the stored JWT token (authenticated)
///
/// Lifecycle:
/// 1. `build()` starts in [AsyncLoading] while reading from [SecureStorageService].
/// 2. Resolves to [AsyncData(token)] if a token is stored, otherwise [AsyncData(null)].
/// 3. [login] writes the token to secure storage and updates state to [AsyncData(token)].
/// 4. [logout] deletes the token from secure storage and updates state to [AsyncData(null)].
///
/// The notifier does NOT depend on [AuthInterceptor] directly — the interceptor
/// is wired to read auth state via a plain `() => String?` callback in main.dart (T-19).
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<String?> build() async {
    final storageService = ref.read(secureStorageServiceProvider);
    return storageService.readToken();
  }

  /// Stores [token] in secure storage and transitions auth state to authenticated.
  Future<void> login(String token) async {
    final storageService = ref.read(secureStorageServiceProvider);
    await storageService.writeToken(token);
    state = AsyncData(token);
  }

  /// Clears the stored token and transitions auth state to unauthenticated.
  Future<void> logout() async {
    final storageService = ref.read(secureStorageServiceProvider);
    await storageService.deleteToken();
    state = const AsyncData(null);
  }
}
