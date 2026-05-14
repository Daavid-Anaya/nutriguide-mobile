// Spec: SCANNER-STATE-001 sc2, sc3, sc4; SCANNER-UI-002 sc1, sc2, sc3, sc4
// AD-14: ProductDetailState sealed class + ProductDetailNotifier
// Phase 1 (T-02): state classes.
// Phase 2 (T-05): ProductDetailNotifier class added.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/scanner/data/scanner_providers.dart';
import 'package:nutriguide_mobile/features/scanner/domain/product.dart';

// ---------------------------------------------------------------------------
// State — sealed class (AD-14)
// Plain Dart sealed class (NOT Freezed) — no toJson/copyWith needed.
// Four variants for exhaustive switch in the UI layer.
// ---------------------------------------------------------------------------

/// Product detail state sealed class — exhaustive switch enforced by compiler.
sealed class ProductDetailState {
  const ProductDetailState();
}

/// Data is being fetched from the network (or falling back to cache).
class ProductDetailLoading extends ProductDetailState {
  const ProductDetailLoading();
}

/// Product data is available.
///
/// [isFromCache] is `true` when the data came from local Hive storage
/// (network was unavailable but cache held the product).
class ProductDetailData extends ProductDetailState {
  const ProductDetailData(this.product, {this.isFromCache = false});

  final Product product;

  /// Whether this product data was served from the local cache.
  /// Defaults to `false` (network result is the primary source).
  final bool isFromCache;
}

/// Product was not found in the Open Food Facts database (API returned 404
/// or equivalent not-found response).
class ProductDetailNotFound extends ProductDetailState {
  const ProductDetailNotFound();
}

/// Network request failed AND no cached version is available.
/// The UI should offer a retry action.
class ProductDetailNetworkError extends ProductDetailState {
  const ProductDetailNetworkError();
}

// ---------------------------------------------------------------------------
// Provider — ProductDetailNotifier (AD-14, T-05)
// Family keyed by barcode — Riverpod caches per-barcode state.
// Network-first strategy with Hive cache fallback (AD-08).
// ---------------------------------------------------------------------------

/// Family provider keyed by barcode.
///
/// Riverpod maintains a separate notifier per barcode, so navigating to the
/// same product twice reuses the already-loaded state (spec SCANNER-STATE-001 sc3).
///
/// Usage: `ref.watch(productDetailNotifierProvider('1234567890'))`
final productDetailNotifierProvider = AsyncNotifierProvider.family<
    ProductDetailNotifier, ProductDetailState, String>(
  ProductDetailNotifier.new,
);

/// Loads product data with a network-first + cache-fallback strategy.
///
/// - Network success → [ProductDetailData] with `isFromCache: false`
/// - [NetworkFailure] + cache hit → [ProductDetailData] with `isFromCache: true`
/// - [NetworkFailure] + [CacheFailure] → [ProductDetailNetworkError]
/// - [ApiFailure] → [ProductDetailNotFound]
/// - Any other failure → [ProductDetailNetworkError]
class ProductDetailNotifier extends AsyncNotifier<ProductDetailState> {
  ProductDetailNotifier(this.barcode);

  /// The barcode used as the family argument.
  final String barcode;

  @override
  Future<ProductDetailState> build() async {
    final repo = ref.read(scannerRepositoryProvider);

    // Network-first (AD-08).
    final networkResult = await repo.getProductByBarcode(barcode);

    return networkResult.fold(
      // Left — network or API error.
      (failure) async {
        if (failure is NetworkFailure) {
          // Attempt cache fallback.
          final cacheResult = await repo.getCachedProduct(barcode);
          return cacheResult.fold(
            (_) => const ProductDetailNetworkError(), // double failure
            (product) => ProductDetailData(product, isFromCache: true),
          );
        }
        if (failure is ApiFailure) {
          return const ProductDetailNotFound();
        }
        // Any other failure (AuthFailure, etc.) → network error state.
        return const ProductDetailNetworkError();
      },
      // Right — success.
      (product) => ProductDetailData(product),
    );
  }

  /// Reloads product data by invalidating this provider instance.
  ///
  /// Triggers [build] to run again with the same barcode.
  Future<void> retry() async {
    ref.invalidateSelf();
    // Wait for the new build to complete so callers can await this.
    await future;
  }
}
