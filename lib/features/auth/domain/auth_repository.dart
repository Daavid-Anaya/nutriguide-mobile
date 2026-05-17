import 'package:fpdart/fpdart.dart';
import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Abstract contract for authentication operations.
/// Implementations: SupabaseAuthRepository (production), MockAuthRepository (tests).
abstract class AuthRepository {
  /// Stream of auth state changes. Emits `User` when authenticated, `null` when not.
  Stream<User?> authStateChanges();

  /// Sign in with email and password. Returns `User` on success.
  Future<Either<Failure, User>> signInWithEmail(String email, String password);

  /// Register a new user with email, password, and display name.
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    required String name,
  });

  /// Sign out the current user.
  Future<Either<Failure, void>> signOut();

  /// The currently authenticated user, or `null`.
  User? get currentUser;
}
