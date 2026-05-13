/// Sealed failure hierarchy for railway-oriented error handling.
///
/// All repositories return [Either<Failure, T>] (fpdart) instead of throwing.
/// The sealed class enables exhaustive switch expressions at call sites,
/// guaranteeing the Dart analyzer catches any unhandled subtype.
sealed class Failure {
  const Failure([this.message = '']);

  final String message;
}

/// Failure caused by absence or degraded network connectivity.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message]);
}

/// Failure caused by a local cache miss or cache read/write error.
class CacheFailure extends Failure {
  const CacheFailure([super.message]);
}

/// Failure caused by an authentication or authorization issue
/// (expired token, missing credentials, forbidden response).
class AuthFailure extends Failure {
  const AuthFailure([super.message]);
}

/// Failure caused by a known API-level error response.
///
/// [statusCode] carries the HTTP status code when available.
class ApiFailure extends Failure {
  const ApiFailure([super.message, this.statusCode]);

  final int? statusCode;
}
