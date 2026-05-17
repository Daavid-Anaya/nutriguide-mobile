import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nutriguide_mobile/features/auth/data/auth_providers.dart';
import 'package:nutriguide_mobile/features/auth/domain/auth_repository.dart';

/// Manages authentication state reactively via Supabase's auth stream.
///
/// State: `AsyncValue<User?>` — `User` when authenticated, `null` when not.
/// Listens to `authStateChanges()` for reactive updates.
class AuthNotifier extends AsyncNotifier<User?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);
  StreamSubscription<User?>? _subscription;

  @override
  Future<User?> build() async {
    _subscription?.cancel();
    _subscription = _repo.authStateChanges().listen((user) {
      state = AsyncData(user);
    });
    ref.onDispose(() => _subscription?.cancel());
    return _repo.currentUser;
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    final result = await _repo.signInWithEmail(email, password);
    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (user) => AsyncData(user),
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AsyncLoading();
    final result =
        await _repo.signUp(email: email, password: password, name: name);
    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (user) => AsyncData(user),
    );
  }

  Future<void> signOut() async {
    final result = await _repo.signOut();
    result.fold(
      (failure) => state = AsyncError(failure.message, StackTrace.current),
      (_) => state = const AsyncData(null),
    );
  }
}

/// Provider for [AuthNotifier].
/// Declared manually (no @riverpod codegen) to support StreamSubscription lifecycle.
final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);
