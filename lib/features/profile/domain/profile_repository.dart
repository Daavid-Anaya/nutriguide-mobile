import 'package:fpdart/fpdart.dart';
import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/profile/domain/user_profile.dart';

/// Abstract contract for user profile data operations.
///
/// All methods return [Either<Failure, T>] — Left for errors, Right for success.
/// The profile feature uses a local-read + sync-on-save strategy: profile is
/// read from local Hive/SharedPreferences cache and synced to the server on save.
abstract class ProfileRepository {
  /// Returns the current user's profile.
  ///
  /// Returns [CacheFailure] when no local profile exists and [NetworkFailure]
  /// when the API is unreachable on a fresh install.
  Future<Either<Failure, UserProfile>> getProfile();

  /// Persists [profile] changes and triggers a background sync to the server.
  ///
  /// Returns [NetworkFailure] when the sync fails (local write still succeeds).
  Future<Either<Failure, void>> updateProfile(UserProfile profile);
}
