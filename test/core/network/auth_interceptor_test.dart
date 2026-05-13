// Spec: HTTP-CLIENT-001 sc1, sc2 — Auth interceptor behavior
// TDD "red" phase: tests reference AuthInterceptor which will be created in GREEN step.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/network/auth_interceptor.dart';

// ---------------------------------------------------------------------------
// Test double: a minimal RequestInterceptorHandler that captures whether
// next() was called and stores the final RequestOptions for inspection.
// ---------------------------------------------------------------------------
class _CapturingHandler extends RequestInterceptorHandler {
  RequestOptions? capturedOptions;
  bool nextCalled = false;

  @override
  void next(RequestOptions options) {
    capturedOptions = options;
    nextCalled = true;
  }

  @override
  void reject(DioException error, [bool callFollowingErrorInterceptor = false]) {
    // Not used in these tests.
  }
}

// Helper: builds a minimal RequestOptions for testing.
RequestOptions _buildOptions({String path = '/test'}) {
  return RequestOptions(path: path);
}

void main() {
  group('AuthInterceptor', () {
    // -----------------------------------------------------------------------
    // HTTP-CLIENT-001 sc1 — Auth interceptor attaches JWT
    // GIVEN the auth state has token "abc123"
    // WHEN a request is made via the Dio instance
    // THEN request headers contain Authorization: Bearer abc123
    // -----------------------------------------------------------------------
    group('sc1 — attaches Authorization header when token is present', () {
      test('adds Bearer token to request headers', () {
        const token = 'abc123';
        final interceptor = AuthInterceptor(tokenProvider: () => token);
        final handler = _CapturingHandler();
        final options = _buildOptions();

        interceptor.onRequest(options, handler);

        expect(handler.nextCalled, isTrue);
        expect(
          handler.capturedOptions?.headers['Authorization'],
          equals('Bearer abc123'),
        );
      });

      test('uses the exact token value returned by tokenProvider', () {
        const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.payload.signature';
        final interceptor = AuthInterceptor(tokenProvider: () => token);
        final handler = _CapturingHandler();
        final options = _buildOptions();

        interceptor.onRequest(options, handler);

        expect(
          handler.capturedOptions?.headers['Authorization'],
          equals('Bearer $token'),
        );
      });
    });

    // -----------------------------------------------------------------------
    // HTTP-CLIENT-001 sc2 — Auth interceptor skips header when unauthenticated
    // GIVEN auth state is null
    // WHEN a request is made
    // THEN no Authorization header is added
    // -----------------------------------------------------------------------
    group('sc2 — skips Authorization header when token is null', () {
      test('does not add Authorization header when tokenProvider returns null', () {
        final interceptor = AuthInterceptor(tokenProvider: () => null);
        final handler = _CapturingHandler();
        final options = _buildOptions();

        interceptor.onRequest(options, handler);

        expect(handler.nextCalled, isTrue);
        expect(handler.capturedOptions?.headers.containsKey('Authorization'), isFalse);
      });

      test('passes the request through unmodified when token is null', () {
        final interceptor = AuthInterceptor(tokenProvider: () => null);
        final handler = _CapturingHandler();
        final options = _buildOptions(path: '/products/123');
        options.headers['X-Custom'] = 'value';

        interceptor.onRequest(options, handler);

        // Existing headers should be preserved
        expect(handler.capturedOptions?.headers['X-Custom'], equals('value'));
        // No Authorization added
        expect(handler.capturedOptions?.headers.containsKey('Authorization'), isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // Triangulation: verify the interceptor calls handler.next() in both paths
    // -----------------------------------------------------------------------
    test('always calls handler.next() regardless of token presence', () {
      for (final token in <String?>[null, 'some-token']) {
        final interceptor = AuthInterceptor(tokenProvider: () => token);
        final handler = _CapturingHandler();
        interceptor.onRequest(_buildOptions(), handler);
        expect(handler.nextCalled, isTrue, reason: 'token=$token');
      }
    });
  });
}
