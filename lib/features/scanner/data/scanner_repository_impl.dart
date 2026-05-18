import 'dart:async' show unawaited;

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/scanner/data/open_food_facts_client.dart';
import 'package:nutriguide_mobile/features/scanner/domain/product.dart';
import 'package:nutriguide_mobile/features/scanner/domain/scanner_repository.dart';

/// Concrete implementation of [ScannerRepository].
///
/// Data strategy: **Online primary + Hive cache on success** (AD-08).
/// - [getProductByBarcode]: calls Open Food Facts API, caches result on success.
///   When authenticated, a fire-and-forget upsert to Supabase is triggered (AD-53).
/// - [getCachedProduct]: reads from Hive box without hitting the network.
/// - [getAlternatives]: stub returning an empty list (AI scoring API not yet available).
class ScannerRepositoryImpl implements ScannerRepository {
  const ScannerRepositoryImpl({
    required OpenFoodFactsClient client,
    required Box<dynamic> productsBox,
    SupabaseClient? supabaseClient,
  })  : _client = client,
        _productsBox = productsBox,
        _supabaseClient = supabaseClient;

  final OpenFoodFactsClient _client;
  final Box<dynamic> _productsBox;
  // nullable — backward compatible; null means no Supabase sync (AD-53)
  final SupabaseClient? _supabaseClient;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, Product>> getProductByBarcode(String barcode) async {
    try {
      final responseData = await _client.getProductByBarcode(barcode);
      final productMap = _normalizeOFFResponse(barcode, responseData);
      // NOTE: Product.fromJson will compile correctly after build_runner (T-16).
      // Until then, this line causes compile errors — intentional TDD "red" state.
      final product = Product.fromJson(productMap);
      await _productsBox.put(barcode, productMap);
      // AD-53: fire-and-forget upsert — does not affect scan result
      unawaited(_upsertToSupabase(product, barcode));
      return Right(product);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    }
  }

  /// Fire-and-forget upsert to Supabase [scanned_products] table.
  ///
  /// Skips silently when no client is provided, when unauthenticated, or
  /// on any Supabase error (AD-53: write-only, non-blocking).
  Future<void> _upsertToSupabase(Product product, String barcode) async {
    final userId = _supabaseClient?.auth.currentUser?.id;
    if (userId == null) return; // not authenticated or no client

    try {
      await _supabaseClient!.from('scanned_products').upsert({
        'barcode': barcode,
        'user_id': userId,
        'name': product.name,
        'brands': product.brands,
        'image_url': product.imageUrl,
        'nutriscore_grade': product.nutriscoreGrade,
        'energy': product.nutriments?.energy,
        'fat': product.nutriments?.fat,
        'saturated_fat': product.nutriments?.saturatedFat,
        'carbohydrates': product.nutriments?.carbohydrates,
        'sugars': product.nutriments?.sugars,
        'proteins': product.nutriments?.proteins,
        'salt': product.nutriments?.salt,
        'fiber': product.nutriments?.fiber,
        'scanned_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Fire-and-forget: swallow errors silently (AD-53)
    }
  }

  @override
  Future<Either<Failure, Product>> getCachedProduct(String barcode) async {
    final cached = _productsBox.get(barcode);
    if (cached == null) {
      return const Left(CacheFailure('Product not found in cache'));
    }
    // NOTE: Product.fromJson will compile correctly after build_runner (T-16).
    final product = Product.fromJson(Map<String, dynamic>.from(cached as Map));
    return Right(product);
  }

  @override
  Future<Either<Failure, List<Product>>> getAlternatives(String barcode) async {
    // Stub: real implementation requires AI scoring API (not yet available).
    return const Right([]);
  }

  // ---------------------------------------------------------------------------
  // Private helpers — pure functions, easy to test
  // ---------------------------------------------------------------------------

  /// Maps a [DioException] to the appropriate domain [Failure].
  Failure _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = statusCode == 404 ? 'Product not found' : (e.message ?? 'API error');
        return ApiFailure(message, statusCode);
      default:
        return ApiFailure(e.message ?? 'Unknown error');
    }
  }

  /// Normalizes an Open Food Facts API v2 response map to the field schema
  /// expected by [Product.fromJson].
  ///
  /// OFF uses snake_case with `_100g` suffixes (e.g., `energy_100g`).
  /// The [Product] Freezed model uses camelCase (e.g., `imageUrl`, `nutriscoreGrade`).
  static Map<String, dynamic> _normalizeOFFResponse(
    String barcode,
    Map<String, dynamic> data,
  ) {
    final product = data['product'] as Map<String, dynamic>? ?? {};
    final offNutriments = product['nutriments'] as Map<String, dynamic>?;

    return {
      'id': product['id'] as String?,
      'barcode': barcode,
      'name': (product['product_name'] as String?) ?? '',
      'brands': product['brands'] as String?,
      'imageUrl': product['image_front_url'] as String?,
      'nutriscoreGrade': product['nutriscore_grade'] as String?,
      'nutriments': offNutriments != null ? _normalizeNutriments(offNutriments) : null,
    };
  }

  /// Converts OFF nutriments map (snake_case with `_100g`) to the schema
  /// expected by [NutritionalInfo.fromJson] (camelCase, no suffix).
  static Map<String, dynamic> _normalizeNutriments(Map<String, dynamic> raw) {
    return {
      'energy': raw['energy_100g'],
      'fat': raw['fat_100g'],
      'saturatedFat': raw['saturated-fat_100g'],
      'carbohydrates': raw['carbohydrates_100g'],
      'sugars': raw['sugars_100g'],
      'proteins': raw['proteins_100g'],
      'salt': raw['salt_100g'],
      'fiber': raw['fiber_100g'],
    };
  }
}
