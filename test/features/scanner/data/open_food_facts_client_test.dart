// Spec: HTTP-CLIENT-001 sc3, sc4 — OpenFoodFactsClient behavior
// This test file ONLY tests OpenFoodFactsClient — no Freezed dependency.
// Runs immediately (no build_runner required).

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutriguide_mobile/features/scanner/data/open_food_facts_client.dart';

class _MockDio extends Mock implements Dio {}

const kNutellaBarcode = '3017620425035';

final kOFFApiResponse = <String, dynamic>{
  'code': kNutellaBarcode,
  'status': 1,
  'product': {
    'product_name': 'Nutella',
    'brands': 'Ferrero',
    'image_front_url': 'https://images.openfoodfacts.org/images/products/301/762/042/5035/front_en.jpg',
    'nutriscore_grade': 'e',
    'nutriments': {
      'energy_100g': 2252.0,
      'fat_100g': 30.9,
    },
  },
};

void main() {
  late _MockDio mockDio;
  late OpenFoodFactsClient client;

  setUp(() {
    mockDio = _MockDio();
    client = OpenFoodFactsClient(mockDio);
    registerFallbackValue(RequestOptions(path: ''));
  });

  group('OpenFoodFactsClient', () {
    // -----------------------------------------------------------------------
    // HTTP-CLIENT-001 sc3 — Open Food Facts returns product data
    // GIVEN barcode "3017620425035" exists in Open Food Facts
    // WHEN getProductByBarcode is called
    // THEN the response status is 200 AND response.data['product'] is non-null
    // -----------------------------------------------------------------------
    group('sc3 — getProductByBarcode returns raw API response', () {
      test('returns the full response data map on success', () async {
        when(() => mockDio.get<Map<String, dynamic>>(any())).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: kOFFApiResponse,
          ),
        );

        final result = await client.getProductByBarcode(kNutellaBarcode);

        expect(result, equals(kOFFApiResponse));
        expect(result['product'], isNotNull);
        expect((result['product'] as Map<String, dynamic>)['product_name'], equals('Nutella'));
      });

      test('calls the correct OFF API v2 URL for the given barcode', () async {
        when(() => mockDio.get<Map<String, dynamic>>(any())).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: kOFFApiResponse,
          ),
        );

        await client.getProductByBarcode(kNutellaBarcode);

        verify(() => mockDio.get<Map<String, dynamic>>(
          'https://world.openfoodfacts.org/api/v2/product/$kNutellaBarcode.json',
        )).called(1);
      });

      test('constructs a different URL for a different barcode', () async {
        const barcode = '5000159461122';
        when(() => mockDio.get<Map<String, dynamic>>(any())).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: {'code': barcode, 'status': 1, 'product': <String, dynamic>{}},
          ),
        );

        await client.getProductByBarcode(barcode);

        verify(() => mockDio.get<Map<String, dynamic>>(
          'https://world.openfoodfacts.org/api/v2/product/$barcode.json',
        )).called(1);
      });
    });

    // -----------------------------------------------------------------------
    // HTTP-CLIENT-001 sc4 — DioException propagates (error mapping is repo's job)
    // -----------------------------------------------------------------------
    group('sc4 — DioException propagates on network error', () {
      test('throws DioException on connectionError', () async {
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

      test('throws DioException on receiveTimeout', () async {
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

      test('throws DioException on 404 response', () async {
        when(() => mockDio.get<Map<String, dynamic>>(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 404,
            ),
          ),
        );

        await expectLater(
          () => client.getProductByBarcode(kNutellaBarcode),
          throwsA(isA<DioException>()),
        );
      });
    });
  });
}
