import 'package:dio/dio.dart';

/// Dio interceptor that attaches the JWT token from auth state to outgoing requests.
///
/// Uses a [tokenProvider] function instead of taking a direct Riverpod [Ref]
/// dependency, which makes this class independently testable without Riverpod.
/// The wiring to the auth state provider happens at the provider-composition
/// level (e.g., in [dioProvider] or a dedicated [authInterceptorProvider]).
///
/// Behavior:
/// - If [tokenProvider] returns a non-null token → adds `Authorization: Bearer <token>`.
/// - If [tokenProvider] returns null → request passes through with no `Authorization` header.
class AuthInterceptor extends Interceptor {
  /// Creates an [AuthInterceptor] with the given [tokenProvider].
  ///
  /// [tokenProvider] is called on every request so it always reflects the
  /// current auth state without needing to reconstruct the interceptor.
  const AuthInterceptor({required this.tokenProvider});

  /// Synchronous supplier of the current JWT token.
  ///
  /// Returns `null` when the user is unauthenticated.
  final String? Function() tokenProvider;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = tokenProvider();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
