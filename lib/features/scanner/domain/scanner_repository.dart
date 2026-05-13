import 'package:fpdart/fpdart.dart';
import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/scanner/domain/product.dart';

/// Abstract contract for scanner-related data operations.
///
/// All methods return [Either<Failure, T>] — Left for errors, Right for success.
/// Concrete implementations live in the data layer.
abstract class ScannerRepository {
  /// Fetches product data from the Open Food Facts API by [barcode].
  ///
  /// Returns [NetworkFailure] on connectivity issues, [ApiFailure] when the
  /// product is not found or the API responds with an error.
  Future<Either<Failure, Product>> getProductByBarcode(String barcode);

  /// Retrieves a previously cached product from local storage by [barcode].
  ///
  /// Returns [CacheFailure] when the product is not in the local cache.
  Future<Either<Failure, Product>> getCachedProduct(String barcode);

  /// Fetches alternative products for a given [barcode].
  ///
  /// Alternatives are products in the same category with a better Nutri-Score.
  /// Returns an empty list (not a failure) when no alternatives are found.
  Future<Either<Failure, List<Product>>> getAlternatives(String barcode);
}
