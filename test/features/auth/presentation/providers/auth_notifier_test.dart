import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/auth/domain/auth_repository.dart';
import 'package:nutriguide_mobile/features/auth/data/auth_providers.dart';
import 'package:nutriguide_mobile/features/auth/presentation/providers/auth_notifier.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

// Create a fake User for tests
User _createFakeUser({String id = 'user-123', String email = 'test@test.com'}) {
  return User(
    id: id,
    appMetadata: {},
    userMetadata: {'name': 'Test User'},
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
    email: email,
  );
}

void main() {
  late MockAuthRepository mockRepo;
  late ProviderContainer container;
  late StreamController<User?> authStreamController;

  setUp(() {
    mockRepo = MockAuthRepository();
    authStreamController = StreamController<User?>.broadcast();

    when(() => mockRepo.authStateChanges())
        .thenAnswer((_) => authStreamController.stream);

    container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(mockRepo),
    ]);
  });

  tearDown(() {
    container.dispose();
    authStreamController.close();
  });

  group('AuthNotifier', () {
    test('build returns User when session is active', () async {
      final fakeUser = _createFakeUser();
      when(() => mockRepo.currentUser).thenReturn(fakeUser);
      final user = await container.read(authNotifierProvider.future);
      expect(user, isNotNull);
      expect(user?.id, 'user-123');
    });

    test('build returns null when no session', () async {
      when(() => mockRepo.currentUser).thenReturn(null);
      final user = await container.read(authNotifierProvider.future);
      expect(user, isNull);
    });

    test('signInWithEmail on success updates state to User', () async {
      final fakeUser = _createFakeUser();
      when(() => mockRepo.currentUser).thenReturn(null);
      when(() => mockRepo.signInWithEmail(any(), any()))
          .thenAnswer((_) async => Right(fakeUser));

      await container.read(authNotifierProvider.future);
      await container
          .read(authNotifierProvider.notifier)
          .signInWithEmail('test@test.com', 'password123');

      final state = container.read(authNotifierProvider);
      expect(state.value, isNotNull);
      expect(state.value?.id, 'user-123');
    });

    test('signInWithEmail on failure sets error', () async {
      when(() => mockRepo.currentUser).thenReturn(null);
      when(() => mockRepo.signInWithEmail(any(), any()))
          .thenAnswer((_) async => const Left(AuthFailure('Credenciales inválidas')));

      await container.read(authNotifierProvider.future);
      await container
          .read(authNotifierProvider.notifier)
          .signInWithEmail('test@test.com', 'wrong');

      final state = container.read(authNotifierProvider);
      expect(state, isA<AsyncError<User?>>());
    });

    test('signUp on success updates state to User', () async {
      final fakeUser = _createFakeUser();
      when(() => mockRepo.currentUser).thenReturn(null);
      when(
        () => mockRepo.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          name: any(named: 'name'),
        ),
      ).thenAnswer((_) async => Right(fakeUser));

      await container.read(authNotifierProvider.future);
      await container.read(authNotifierProvider.notifier).signUp(
            email: 'new@test.com',
            password: 'password123',
            name: 'New User',
          );

      final state = container.read(authNotifierProvider);
      expect(state.value, isNotNull);
    });

    test('signOut clears user state', () async {
      final fakeUser = _createFakeUser();
      when(() => mockRepo.currentUser).thenReturn(fakeUser);
      when(() => mockRepo.signOut())
          .thenAnswer((_) async => const Right(null));

      await container.read(authNotifierProvider.future);
      await container.read(authNotifierProvider.notifier).signOut();

      final state = container.read(authNotifierProvider);
      expect(state.value, isNull);
    });
  });
}
