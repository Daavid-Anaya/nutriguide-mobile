// Spec: HTTP-CLIENT-001 sc3, sc4 | OFFLINE-STORAGE-001 sc2 | CORE-MODELS-001 sc4
// TDD note: tests that use Product.fromJson WON'T compile until build_runner runs (T-16).
// Tests for OpenFoodFactsClient and error mapping CAN run now (no Freezed dependency).

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hive_ce/hive.dart';
import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/scanner/data/open_food_facts_client.dart';
import 'package:nutriguide_mobile/features/scanner/data/scanner_repository_impl.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------
class _MockDio extends Mock implements Dio {}

class _MockBox extends Mock implements Box<dynamic> {}

class _MockOpenFoodFactsClient extends Mock implements OpenFoodFactsClient {}

// ---------------------------------------------------------------------------
// Fake response data matching Open Food Facts API v2 structure
// { "code": "...", "product": { ... }, "status": 1 }
// ---------------------------------------------------------------------------
const kNutellaBarcode = '3017620425035';

final kOFFApiResponse = {
  'code': kNutellaBarcode,
  'status': 1,
  'product': {
    'id': kNutellaBarcode,
    'product_name': 'Nutella',
    'brands': 'Ferrero',
    'image_front_url': 'https://images.openfoodfacts.org/images/products/301/762/042/5035/front_en.jpg',
    'nutriscore_grade': 'e',
    'nutriments': {
      'energy_100g': 2252.0,
      'fat_100g': 30.9,
      'saturated-fat_100g': 10.6,
      'carbohydrates_100g': 57.5,
      'sugars_100g': 56.3,
      'proteins_100g': 6.3,
      'salt_100g': 0.107,
      'fiber_100g': null,
    },
  },
};

// ---------------------------------------------------------------------------
// The "normalized" product map that ScannerRepositoryImpl builds from the
// OFF response before calling Product.fromJson. Must match the field names
// that the Freezed Product model expects.
// ---------------------------------------------------------------------------
final kNormalizedProductMap = {
  'id': kNutellaBarcode,
  'barcode': kNutellaBarcode,
  'name': 'Nutella',
  'brands': 'Ferrero',
  'imageUrl': 'https://images.openfoodfacts.org/images/products/301/762/042/5035/front_en.jpg',
  'nutriscoreGrade': 'e',
  'nutriments': {
    'energy': 2252.0,
    'fat': 30.9,
    'saturatedFat': 10.6,
    'carbohydrates': 57.5,
    'sugars': 56.3,
    'proteins': 6.3,
    'salt': 0.107,
    'fiber': null,
  },
};

void main() {
  late _MockDio mockDio;
  late _MockBox mockBox;
  late _MockOpenFoodFactsClient mockClient;
  late ScannerRepositoryImpl repository;

  setUp(() {
    mockDio = _MockDio();
    mockBox = _MockBox();
    mockClient = _MockOpenFoodFactsClient();
    repository = ScannerRepositoryImpl(client: mockClient, productsBox: mockBox);

    // Register fallback values required by mocktail
    registerFallbackValue(RequestOptions(path: ''));
  });

  // -------------------------------------------------------------------------
  // OpenFoodFactsClient tests — these do NOT use Freezed, run now
  // -------------------------------------------------------------------------
  group('OpenFoodFactsClient', () {
    late OpenFoodFactsClient client;

    setUp(() {
      client = OpenFoodFactsClient(mockDio);
    });

    // HTTP-CLIENT-001 sc3 — Open Food Facts returns product data
    group('sc3 — getProductByBarcode returns raw response data', () {
      test('returns the full response data map on 200 success', () async {
        when(() => mockDio.get<Map<String, dynamic>>(any())).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: kOFFApiResponse,
          ),
        );

        final result = await client.getProductByBarcode(kNutellaBarcode);

        expect(result, equals(kOFFApiResponse));
        verify(() => mockDio.get<Map<String, dynamic>>(
          'https://world.openfoodfacts.org/api/v2/product/$kNutellaBarcode.json',
        )).called(1);
      });

      test('calls the correct URL with the provided barcode', () async {
        const barcode = '5000159461122';
        when(() => mockDio.get<Map<String, dynamic>>(any())).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: {'code': barcode, 'status': 1, 'product': {}},
          ),
        );

        await client.getProductByBarcode(barcode);

        verify(() => mockDio.get<Map<String, dynamic>>(
          'https://world.openfoodfacts.org/api/v2/product/$barcode.json',
        )).called(1);
      });
    });

    // HTTP-CLIENT-001 sc4 — Network failure propagates as DioException
    group('sc4 — DioException propagates on network error', () {
      test('throws DioException on connection error', () async {
        when(() => mockDio.get<Map<String, dynamic>>(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionError,
            message: 'No internet',
          ),
        );

        await expectLater(
          () => client.getProductByBarcode(kNutellaBarcode),
          throwsA(isA<DioException>()),
        );
      });

      test('throws DioException on receive timeout', () async {
        when(() => mockDio.get<Map<String, dynamic>>(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.receiveTimeout,
          ),
        );

        await expectLater(
          () => client.getProductByBarcode(kNutellaBarcode),
          throwsA(isA<DioException>()),
        );
      });
    });
  });

  // -------------------------------------------------------------------------
  // ScannerRepositoryImpl — error-mapping tests (no Freezed needed)
  // -------------------------------------------------------------------------
  group('ScannerRepositoryImpl', () {
    // HTTP-CLIENT-001 sc4 — NetworkFailure on connection error
    group('sc4 — getProductByBarcode returns NetworkFailure on no internet', () {
      test('returns Left(NetworkFailure) on DioExceptionType.connectionError', () async {
        when(() => mockClient.getProductByBarcode(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionError,
          ),
        );

        final result = await repository.getProductByBarcode(kNutellaBarcode);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('returns Left(NetworkFailure) on receiveTimeout', () async {
        when(() => mockClient.getProductByBarcode(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.receiveTimeout,
          ),
        );

        final result = await repository.getProductByBarcode(kNutellaBarcode);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('returns Left(NetworkFailure) on connectTimeout', () async {
        when(() => mockClient.getProductByBarcode(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        final result = await repository.getProductByBarcode(kNutellaBarcode);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });
    });

    // HTTP-CLIENT-001 sc4 — ApiFailure on 404
    group('sc4 — getProductByBarcode returns ApiFailure on 404', () {
      test('returns Left(ApiFailure) with statusCode 404 when product not found', () async {
        when(() => mockClient.getProductByBarcode(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 404,
            ),
          ),
        );

        final result = await repository.getProductByBarcode(kNutellaBarcode);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ApiFailure>());
            expect((failure as ApiFailure).statusCode, equals(404));
            expect(failure.message, equals('Product not found'));
          },
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('returns Left(ApiFailure) with status code for other HTTP errors', () async {
        when(() => mockClient.getProductByBarcode(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 500,
            ),
            message: 'Internal Server Error',
          ),
        );

        final result = await repository.getProductByBarcode(kNutellaBarcode);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ApiFailure>());
            expect((failure as ApiFailure).statusCode, equals(500));
          },
          (_) => fail('Expected Left but got Right'),
        );
      });
    });

    // -----------------------------------------------------------------------
    // OFFLINE-STORAGE-001 sc2 — Product cached after successful scan
    // NOTE: This test uses Product.fromJson → will be TDD "red" until T-16.
    // The test is written now as required by TDD spec.
    // -----------------------------------------------------------------------
    group('OFFLINE-STORAGE-001 sc2 — product cached after successful scan', () {
      test('caches normalized product map in Hive box after successful API call', () async {
        when(() => mockClient.getProductByBarcode(any())).thenAnswer(
          (_) async => kOFFApiResponse,
        );
        when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

        // This call uses Product.fromJson internally — will fail pre-codegen (T-16)
        await repository.getProductByBarcode(kNutellaBarcode);

        // Verify Hive box received a write with the barcode as key
        verify(() => mockBox.put(kNutellaBarcode, any())).called(1);
      });
    });

    // -----------------------------------------------------------------------
    // CORE-MODELS-001 sc4 — Repository returns failure on cache miss
    // OFFLINE-STORAGE-001 sc2 complement: getCachedProduct on empty box
    // -----------------------------------------------------------------------
    group('CORE-MODELS-001 sc4 — getCachedProduct returns CacheFailure on miss', () {
      test('returns Left(CacheFailure) when barcode not in Hive box', () async {
        when(() => mockBox.get(any())).thenReturn(null);

        final result = await repository.getCachedProduct('unknown-barcode');

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('returns Left(CacheFailure) for any unknown barcode', () async {
        when(() => mockBox.get(any())).thenReturn(null);

        for (final barcode in ['999', 'abc', '0000000000000']) {
          final result = await repository.getCachedProduct(barcode);
          expect(result.isLeft(), isTrue, reason: 'barcode=$barcode');
          result.fold(
            (f) => expect(f, isA<CacheFailure>(), reason: 'barcode=$barcode'),
            (_) => fail('Expected Left for $barcode'),
          );
        }
      });
    });

    // -----------------------------------------------------------------------
    // getAlternatives — stub always returns Right([])
    // -----------------------------------------------------------------------
    group('getAlternatives — returns empty list (stub)', () {
      test('returns Right([]) for any barcode', () async {
        final result = await repository.getAlternatives(kNutellaBarcode);

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (alternatives) => expect(alternatives, isEmpty),
        );
      });
    });
  });
}
