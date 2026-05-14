// Spec: SCANNER-STATE-001 sc2, sc3, sc4; SCANNER-UI-002 sc1, sc2, sc3, sc4
// Phase 1 (T-02): State model assertions.
// Phase 2 (T-05): ProductDetailNotifier behavior tests (network-first + cache fallback).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/scanner/data/scanner_providers.dart';
import 'package:nutriguide_mobile/features/scanner/domain/product.dart';
import 'package:nutriguide_mobile/features/scanner/domain/scanner_repository.dart';
import 'package:nutriguide_mobile/features/scanner/presentation/providers/product_detail_notifier.dart';

// ---------------------------------------------------------------------------
// Mock — ScannerRepository
// ---------------------------------------------------------------------------
class MockScannerRepository extends Mock implements ScannerRepository {}

// ---------------------------------------------------------------------------
// Test fixture — a minimal Product for ProductDetailData assertions.
// Product uses Freezed; the generated code exists (build_runner was already run
// for the base architecture). We use the const factory directly.
// ---------------------------------------------------------------------------
final _testProduct = Product(
  barcode: '3017620425035',
  name: 'Nutella',
  brands: 'Ferrero',
);

// ---------------------------------------------------------------------------
// Helper — builds a ProviderContainer with the mock repository injected.
// ---------------------------------------------------------------------------
ProviderContainer _makeContainer(MockScannerRepository mockRepo) {
  return ProviderContainer(
    overrides: [
      scannerRepositoryProvider.overrideWithValue(mockRepo),
    ],
  );
}

void main() {
  group('ProductDetailState sealed class', () {
    // RED → GREEN: ProductDetailLoading is a valid state
    test('ProductDetailLoading is a valid ProductDetailState instance', () {
      const state = ProductDetailLoading();

      expect(state, isA<ProductDetailState>());
      expect(state, isA<ProductDetailLoading>());
    });

    // RED → GREEN: ProductDetailData holds product + isFromCache defaults to false
    test('ProductDetailData holds product and isFromCache defaults to false', () {
      final state = ProductDetailData(_testProduct);

      expect(state, isA<ProductDetailState>());
      expect(state.product, equals(_testProduct));
      expect(state.isFromCache, isFalse);
    });

    // TRIANGULATE: isFromCache can be set to true
    test('ProductDetailData isFromCache can be explicitly set to true', () {
      final state = ProductDetailData(_testProduct, isFromCache: true);

      expect(state.product, equals(_testProduct));
      expect(state.isFromCache, isTrue);
    });

    // RED → GREEN: ProductDetailNotFound is a valid state
    test('ProductDetailNotFound is a valid ProductDetailState instance', () {
      const state = ProductDetailNotFound();

      expect(state, isA<ProductDetailState>());
      expect(state, isA<ProductDetailNotFound>());
    });

    // TRIANGULATE: ProductDetailNetworkError is a valid state
    test('ProductDetailNetworkError is a valid ProductDetailState instance', () {
      const state = ProductDetailNetworkError();

      expect(state, isA<ProductDetailState>());
      expect(state, isA<ProductDetailNetworkError>());
    });

    // Exhaustive switch — all 4 variants covered by sealed class contract
    test('sealed class switch is exhaustive over all 4 variants', () {
      final states = <ProductDetailState>[
        const ProductDetailLoading(),
        ProductDetailData(_testProduct),
        const ProductDetailNotFound(),
        const ProductDetailNetworkError(),
      ];

      final labels = states.map((s) => switch (s) {
            ProductDetailLoading() => 'loading',
            ProductDetailData(:final product) => 'data:${product.name}',
            ProductDetailNotFound() => 'not-found',
            ProductDetailNetworkError() => 'network-error',
          }).toList();

      expect(
        labels,
        equals(['loading', 'data:Nutella', 'not-found', 'network-error']),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // T-05: ProductDetailNotifier behavior tests
  // ---------------------------------------------------------------------------
  group('ProductDetailNotifier', () {
    const barcode = '3017620425035';
    late MockScannerRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockScannerRepository();
      container = _makeContainer(mockRepo);
    });

    tearDown(() => container.dispose());

    // RED → GREEN: network success → ProductDetailData(product, isFromCache: false)
    test('network success returns ProductDetailData with isFromCache false',
        () async {
      when(() => mockRepo.getProductByBarcode(barcode))
          .thenAnswer((_) async => Right(_testProduct));

      // Reading the provider triggers build().
      final asyncValue =
          await container.read(productDetailNotifierProvider(barcode).future);

      expect(asyncValue, isA<ProductDetailData>());
      final data = asyncValue as ProductDetailData;
      expect(data.product, equals(_testProduct));
      expect(data.isFromCache, isFalse);
      // getCachedProduct must NOT have been called (network succeeded).
      verifyNever(() => mockRepo.getCachedProduct(any()));
    });

    // RED → GREEN + TRIANGULATE: NetworkFailure + cache hit → ProductDetailData(isFromCache: true)
    test(
      'NetworkFailure with cache hit returns ProductDetailData with isFromCache true',
      () async {
        when(() => mockRepo.getProductByBarcode(barcode))
            .thenAnswer((_) async => const Left(NetworkFailure()));
        when(() => mockRepo.getCachedProduct(barcode))
            .thenAnswer((_) async => Right(_testProduct));

        final asyncValue =
            await container.read(productDetailNotifierProvider(barcode).future);

        expect(asyncValue, isA<ProductDetailData>());
        final data = asyncValue as ProductDetailData;
        expect(data.product, equals(_testProduct));
        expect(data.isFromCache, isTrue);
      },
    );

    // TRIANGULATE: NetworkFailure + CacheFailure → ProductDetailNetworkError
    test(
      'NetworkFailure with CacheFailure returns ProductDetailNetworkError',
      () async {
        when(() => mockRepo.getProductByBarcode(barcode))
            .thenAnswer((_) async => const Left(NetworkFailure()));
        when(() => mockRepo.getCachedProduct(barcode))
            .thenAnswer((_) async => const Left(CacheFailure('not in cache')));

        final asyncValue =
            await container.read(productDetailNotifierProvider(barcode).future);

        expect(asyncValue, isA<ProductDetailNetworkError>());
      },
    );

    // TRIANGULATE: ApiFailure → ProductDetailNotFound
    test('ApiFailure returns ProductDetailNotFound', () async {
      when(() => mockRepo.getProductByBarcode(barcode))
          .thenAnswer((_) async => const Left(ApiFailure('not found', 404)));

      final asyncValue =
          await container.read(productDetailNotifierProvider(barcode).future);

      expect(asyncValue, isA<ProductDetailNotFound>());
      // Cache must NOT be attempted on ApiFailure.
      verifyNever(() => mockRepo.getCachedProduct(any()));
    });

    // RED → GREEN: retry() re-triggers build (invalidates self)
    test('retry() re-triggers build by calling ref.invalidateSelf()', () async {
      // First call: network failure + no cache.
      when(() => mockRepo.getProductByBarcode(barcode))
          .thenAnswer((_) async => const Left(NetworkFailure()));
      when(() => mockRepo.getCachedProduct(barcode))
          .thenAnswer((_) async => const Left(CacheFailure()));

      // Force the provider to build.
      await container.read(productDetailNotifierProvider(barcode).future);

      // Second call (after retry): network succeeds.
      when(() => mockRepo.getProductByBarcode(barcode))
          .thenAnswer((_) async => Right(_testProduct));

      // Trigger retry — this invalidates and rebuilds the notifier.
      await container
          .read(productDetailNotifierProvider(barcode).notifier)
          .retry();

      final asyncValue =
          await container.read(productDetailNotifierProvider(barcode).future);

      expect(asyncValue, isA<ProductDetailData>());
      expect((asyncValue as ProductDetailData).isFromCache, isFalse);
    });
  });
}
