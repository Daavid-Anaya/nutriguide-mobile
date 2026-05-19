import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:postgrest/postgrest.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// FunctionsClient is re-exported from supabase_flutter (no separate import needed)

// ── Client mocks ──────────────────────────────────────────────────────────
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}

// ── Edge Functions client mock ────────────────────────────────────────────
/// Mock for [FunctionsClient] used to test [MealPlanGeneratorService].
///
/// Usage:
/// ```dart
/// final mockFunctions = MockFunctionsClient();
/// when(() => mockClient.functions).thenReturn(mockFunctions);
/// when(() => mockFunctions.invoke('generate-meal-plan', body: any(named: 'body')))
///     .thenAnswer((_) async => FunctionResponse(data: {...}, status: 200));
/// ```
class MockFunctionsClient extends Mock implements FunctionsClient {}

// ── Realtime mocks ───────────────────────────────────────────────────────
class MockRealtimeChannel extends Mock implements RealtimeChannel {}

/// Fake for use as fallback value in registerFallbackValue.
class FakeRealtimeChannel extends Fake implements RealtimeChannel {}

// ── PostgREST builder chain mocks ─────────────────────────────────────────
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}
class MockPostgrestFilterBuilder<T> extends Mock
    implements PostgrestFilterBuilder<T> {}
class MockPostgrestTransformBuilder<T> extends Mock
    implements PostgrestTransformBuilder<T> {}

// ── Awaitable fake builder ────────────────────────────────────────────────
// Use these when you need `await builder` to return a specific value.
// They wrap a real Future so the await works transparently.

class FakePostgrestTransformBuilder<T> extends Fake
    implements PostgrestTransformBuilder<T> {
  FakePostgrestTransformBuilder(this._future);
  final Future<T> _future;

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function? onError}) {
    return _future.then(onValue, onError: onError);
  }

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) =>
      _future.catchError(onError, test: test);

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) =>
      _future.whenComplete(action);

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) =>
      _future.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Stream<T> asStream() => _future.asStream();
}

class FakePostgrestFilterBuilder<T> extends Fake
    implements PostgrestFilterBuilder<T> {
  FakePostgrestFilterBuilder(this._future);
  final Future<T> _future;

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function? onError}) {
    return _future.then(onValue, onError: onError);
  }

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) =>
      _future.catchError(onError, test: test);

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) =>
      _future.whenComplete(action);

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) =>
      _future.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Stream<T> asStream() => _future.asStream();
}

// ── Fake User helper ──────────────────────────────────────────────────────
User createFakeUser({
  String id = 'user-123',
  String email = 'test@nutriguide.app',
}) {
  return User(
    id: id,
    appMetadata: {},
    userMetadata: {'name': 'Test User'},
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
    email: email,
  );
}
