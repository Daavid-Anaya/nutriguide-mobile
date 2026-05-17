import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/auth/domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({required SupabaseClient client}) : _client = client;
  final SupabaseClient _client;

  @override
  Stream<User?> authStateChanges() {
    return _client.auth.onAuthStateChange.map((event) => event.session?.user);
  }

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Future<Either<Failure, User>> signInWithEmail(
      String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) return const Left(AuthFailure('No se pudo iniciar sesión'));
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(_mapAuthError(e.message)));
    } catch (e) {
      return const Left(NetworkFailure('Error de conexión'));
    }
  }

  @override
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      final user = response.user;
      if (user == null) return const Left(AuthFailure('No se pudo crear la cuenta'));
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(_mapAuthError(e.message)));
    } catch (e) {
      return const Left(NetworkFailure('Error de conexión'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _client.auth.signOut();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return const Left(NetworkFailure('Error de conexión'));
    }
  }

  String _mapAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Email o contraseña incorrectos';
    }
    if (message.contains('User already registered')) {
      return 'Este email ya está registrado';
    }
    if (message.contains('Email not confirmed')) {
      return 'Debés confirmar tu email antes de iniciar sesión';
    }
    return message;
  }
}
