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

/// Failure caused by an AI meal plan generation error.
///
/// Raised when both the Edge Function and the local fallback algorithm fail
/// to produce a valid [WeeklyMealPlan]. Enables the UI to show a
/// generation-specific error message distinct from generic network errors.
class GenerationFailure extends Failure {
  const GenerationFailure([super.message]);
}
