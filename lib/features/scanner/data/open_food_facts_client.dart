import 'package:dio/dio.dart';

/// HTTP client for the Open Food Facts API v2.
///
/// Wraps [Dio] to provide a typed interface for product lookups.
/// Error handling (mapping [DioException] to domain [Failure]s) is the
/// responsibility of the repository layer — this client lets exceptions propagate.
class OpenFoodFactsClient {
  /// Creates an [OpenFoodFactsClient] using the provided [Dio] instance.
  ///
  /// The [Dio] instance should already be configured with base timeouts and
  /// any desired interceptors (auth, logging) by the caller (e.g., via
  /// [dioProvider]).
  const OpenFoodFactsClient(this._dio);

  final Dio _dio;

  static const _baseUrl = 'https://world.openfoodfacts.org/api/v2';

  /// Fetches raw product data from Open Food Facts by [barcode].
  ///
  /// Returns the full `response.data` map (the parsed JSON body).
  /// The caller is responsible for extracting `response['product']` and
  /// mapping to domain models.
  ///
  /// Throws [DioException] on any network or HTTP error — the repository
  /// layer is responsible for mapping these to domain [Failure]s.
  Future<Map<String, dynamic>> getProductByBarcode(String barcode) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_baseUrl/product/$barcode.json',
    );
    return response.data as Map<String, dynamic>;
  }
}
