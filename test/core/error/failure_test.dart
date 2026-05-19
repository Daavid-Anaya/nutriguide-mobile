import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/error/failure.dart';

void main() {
  group('Failure sealed class', () {
    group('CORE-MODELS-001 sc3 — exhaustive switch on all Failure subtypes', () {
      test('switch on NetworkFailure returns correct label', () {
        const Failure failure = NetworkFailure();
        final result = switch (failure) {
          NetworkFailure() => 'network',
          CacheFailure() => 'cache',
          AuthFailure() => 'auth',
          ApiFailure() => 'api',
          GenerationFailure() => 'generation',
        };
        expect(result, equals('network'));
      });

      test('switch on CacheFailure returns correct label', () {
        const Failure failure = CacheFailure();
        final result = switch (failure) {
          NetworkFailure() => 'network',
          CacheFailure() => 'cache',
          AuthFailure() => 'auth',
          ApiFailure() => 'api',
          GenerationFailure() => 'generation',
        };
        expect(result, equals('cache'));
      });

      test('switch on AuthFailure returns correct label', () {
        const Failure failure = AuthFailure();
        final result = switch (failure) {
          NetworkFailure() => 'network',
          CacheFailure() => 'cache',
          AuthFailure() => 'auth',
          ApiFailure() => 'api',
          GenerationFailure() => 'generation',
        };
        expect(result, equals('auth'));
      });

      test('switch on ApiFailure returns correct label', () {
        const Failure failure = ApiFailure('Server error', 500);
        final result = switch (failure) {
          NetworkFailure() => 'network',
          CacheFailure() => 'cache',
          AuthFailure() => 'auth',
          ApiFailure() => 'api',
          GenerationFailure() => 'generation',
        };
        expect(result, equals('api'));
      });

      test('switch on GenerationFailure returns correct label', () {
        const Failure failure = GenerationFailure('AI generation failed');
        final result = switch (failure) {
          NetworkFailure() => 'network',
          CacheFailure() => 'cache',
          AuthFailure() => 'auth',
          ApiFailure() => 'api',
          GenerationFailure() => 'generation',
        };
        expect(result, equals('generation'));
      });
    });

    group('Failure type identity', () {
      test('NetworkFailure is a Failure', () {
        const Failure failure = NetworkFailure();
        expect(failure, isA<NetworkFailure>());
      });

      test('CacheFailure is a Failure', () {
        const Failure failure = CacheFailure();
        expect(failure, isA<CacheFailure>());
      });

      test('AuthFailure is a Failure', () {
        const Failure failure = AuthFailure();
        expect(failure, isA<AuthFailure>());
      });

      test('ApiFailure is a Failure with message and statusCode', () {
        const Failure failure = ApiFailure('Not found', 404);
        expect(failure, isA<ApiFailure>());
        final apiFailure = failure as ApiFailure;
        expect(apiFailure.message, equals('Not found'));
        expect(apiFailure.statusCode, equals(404));
      });

      test('ApiFailure statusCode is nullable', () {
        const Failure failure = ApiFailure('Unknown error');
        final apiFailure = failure as ApiFailure;
        expect(apiFailure.statusCode, isNull);
      });
    });

    group('Failure message', () {
      test('NetworkFailure has default empty message', () {
        const failure = NetworkFailure();
        expect(failure.message, equals(''));
      });

      test('NetworkFailure accepts custom message', () {
        const failure = NetworkFailure('No internet connection');
        expect(failure.message, equals('No internet connection'));
      });

      test('CacheFailure accepts custom message', () {
        const failure = CacheFailure('Cache miss');
        expect(failure.message, equals('Cache miss'));
      });

      test('AuthFailure accepts custom message', () {
        const failure = AuthFailure('Token expired');
        expect(failure.message, equals('Token expired'));
      });
    });
  });
}
