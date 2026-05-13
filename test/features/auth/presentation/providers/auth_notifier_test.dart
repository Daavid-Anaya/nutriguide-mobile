import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutriguide_mobile/features/auth/data/auth_providers.dart';
import 'package:nutriguide_mobile/features/auth/data/secure_storage_service.dart';

// NOTE: The import below will fail until T-16 (build_runner generates auth_notifier.g.dart).
// These tests are intentionally TDD "red" pre-codegen. They will turn green once
// `dart run build_runner build --delete-conflicting-outputs` is executed.
import 'package:nutriguide_mobile/features/auth/presentation/providers/auth_notifier.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSecureStorageService extends Mock implements SecureStorageService {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a [ProviderContainer] with [SecureStorageService] overridden by the
/// provided mock. Registers [addTearDown] automatically.
ProviderContainer makeContainer(MockSecureStorageService mockStorage) {
  final container = ProviderContainer(
    overrides: [
      secureStorageServiceProvider.overrideWithValue(mockStorage),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AuthNotifier', () {
    late MockSecureStorageService mockStorage;

    setUp(() {
      mockStorage = MockSecureStorageService();
    });

    // AUTH-001 sc1 — Token persisted across app restarts
    test(
      'AUTH-001 sc1: build() resolves to stored token when one exists',
      () async {
        when(() => mockStorage.readToken())
            .thenAnswer((_) async => 'stored-jwt-token');

        final container = makeContainer(mockStorage);

        final token = await container.read(authProvider.future);

        expect(token, equals('stored-jwt-token'));
        verify(() => mockStorage.readToken()).called(1);
      },
    );

    test(
      'AUTH-001 sc1: build() resolves to null when no token is stored',
      () async {
        when(() => mockStorage.readToken()).thenAnswer((_) async => null);

        final container = makeContainer(mockStorage);

        final token = await container.read(authProvider.future);

        expect(token, isNull);
        verify(() => mockStorage.readToken()).called(1);
      },
    );

    // AUTH-001 sc2 — Logout clears token and state becomes null
    test(
      'AUTH-001 sc2: logout() deletes token and state becomes AsyncData(null)',
      () async {
        when(() => mockStorage.readToken())
            .thenAnswer((_) async => 'existing-token');
        when(() => mockStorage.deleteToken()).thenAnswer((_) async {});

        final container = makeContainer(mockStorage);

        // Wait for initial build to complete.
        await container.read(authProvider.future);

        // Perform logout.
        await container.read(authProvider.notifier).logout();

        final stateAfterLogout = container.read(authProvider);
        expect(stateAfterLogout, equals(const AsyncData<String?>(null)));
        verify(() => mockStorage.deleteToken()).called(1);
      },
    );

    // AUTH-001 sc3 — Notifier starts in loading state during build()
    test(
      'AUTH-001 sc3: state is AsyncLoading before build() resolves',
      () async {
        // Use a Completer to control when readToken completes.
        var readTokenCalled = false;

        when(() => mockStorage.readToken()).thenAnswer((_) async {
          readTokenCalled = true;
          // Return after a brief delay to keep loading state observable.
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return 'delayed-token';
        });

        final container = makeContainer(mockStorage);

        // Read the provider synchronously — should be loading initially.
        final initialState = container.read(authProvider);
        expect(initialState, isA<AsyncLoading<String?>>());

        // Now await resolution.
        final resolvedToken = await container.read(authProvider.future);
        expect(resolvedToken, equals('delayed-token'));
        expect(readTokenCalled, isTrue);
      },
    );

    // login() — writes token and updates state
    test(
      'login() writes token to storage and updates state to AsyncData(token)',
      () async {
        when(() => mockStorage.readToken()).thenAnswer((_) async => null);
        when(
          () => mockStorage.writeToken(any()),
        ).thenAnswer((_) async {});

        final container = makeContainer(mockStorage);

        // Wait for initial build.
        await container.read(authProvider.future);

        await container
            .read(authProvider.notifier)
            .login('new-jwt-token');

        final stateAfterLogin = container.read(authProvider);
        expect(
          stateAfterLogin,
          equals(const AsyncData<String?>('new-jwt-token')),
        );
        verify(() => mockStorage.writeToken('new-jwt-token')).called(1);
      },
    );
  });
}
