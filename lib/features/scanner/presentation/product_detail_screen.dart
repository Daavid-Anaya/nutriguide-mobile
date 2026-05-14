// Spec: SCANNER-UI-002 sc1, sc2, sc3, sc4, sc5, sc6, sc7
//       SHOPPING-LIST-005 sc1, sc2, sc3
// AD-16 + AD-25: ProductDetailScreen — ConsumerWidget switching on AsyncValue<ProductDetailState>.
// Receives [barcode] from route path parameter.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutriguide_mobile/core/extensions/context_extensions.dart';
import 'package:nutriguide_mobile/core/widgets/loading_indicator.dart';
import 'package:nutriguide_mobile/core/widgets/nutri_app_bar.dart';
import 'package:nutriguide_mobile/features/scanner/domain/product.dart';
import 'package:nutriguide_mobile/features/scanner/presentation/providers/product_detail_notifier.dart';
import 'package:nutriguide_mobile/features/scanner/presentation/widgets/nutri_score_grade_badge.dart';
import 'package:nutriguide_mobile/features/scanner/presentation/widgets/nutritional_info_card.dart';
import 'package:nutriguide_mobile/features/scanner/presentation/widgets/product_header.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_item.dart';
import 'package:nutriguide_mobile/features/shopping_list/presentation/providers/shopping_list_notifier.dart';

/// Displays the full product detail for the scanned [barcode].
///
/// - Uses [NutriAppBar] at the top (spec SCANNER-UI-002).
/// - Watches [productDetailNotifierProvider(barcode)] and switches on the
///   [AsyncValue<ProductDetailState>] to render loading / data / error views.
/// - The "Agregar a lista" button calls [shoppingListNotifierProvider.addItem]
///   and shows a SnackBar on success (spec SHOPPING-LIST-005 / SCANNER-UI-002 sc7).
class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.barcode});

  /// EAN/UPC barcode string extracted from the route path parameter.
  final String barcode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(productDetailNotifierProvider(barcode));

    return Scaffold(
      appBar: const NutriAppBar(title: 'Detalle del producto'),
      body: asyncState.when(
        // Async loading (provider is building).
        loading: () => const LoadingIndicator(),
        // Async error (unexpected exception from build).
        error: (error, _) => _NetworkErrorView(
          onRetry: () => ref
              .read(productDetailNotifierProvider(barcode).notifier)
              .retry(),
        ),
        // Async data — switch on the sealed ProductDetailState.
        data: (detailState) => switch (detailState) {
          ProductDetailLoading() => const LoadingIndicator(),
          ProductDetailNotFound() => const _NotFoundView(),
          ProductDetailNetworkError() => _NetworkErrorView(
              onRetry: () => ref
                  .read(productDetailNotifierProvider(barcode).notifier)
                  .retry(),
            ),
          ProductDetailData(:final product, :final isFromCache) =>
            _ProductView(product: product, isFromCache: isFromCache),
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ProductView
// Rendered when product data is available (AsyncData + ProductDetailData).
// ---------------------------------------------------------------------------

/// Displays the product details and an active "Agregar a lista" button.
///
/// Changed from [StatelessWidget] to [ConsumerWidget] (AD-25) to watch
/// [shoppingListNotifierProvider] for loading state and call [addItem].
class _ProductView extends ConsumerWidget {
  const _ProductView({
    required this.product,
    required this.isFromCache,
  });

  final Product product;
  final bool isFromCache;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingListAsyncState = ref.watch(shoppingListNotifierProvider);
    final isShoppingListLoading = shoppingListAsyncState is AsyncLoading;

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Product image, name, brand, optional cache chip ──────────────
          ProductHeader(product: product, isFromCache: isFromCache),

          SizedBox(height: context.spacing.md),

          // ── NutriScore badge — only when grade is non-null (spec sc1) ────
          if (product.nutriscoreGrade != null) ...[
            Center(
              child: NutriScoreGradeBadge(grade: product.nutriscoreGrade),
            ),
            SizedBox(height: context.spacing.md),
          ],

          // ── Nutritional info card ────────────────────────────────────────
          NutritionalInfoCard(nutritionalInfo: product.nutriments),

          SizedBox(height: context.spacing.lg),

          // ── "Agregar a lista" — active button (AD-25, SHOPPING-LIST-005) ─
          // When shoppingListNotifierProvider is loading: button is disabled
          // and shows a CircularProgressIndicator. Otherwise: tapping creates
          // a ShoppingItem from the product and calls addItem(), then shows
          // a SnackBar confirmation. No navigation occurs after adding.
          ElevatedButton(
            onPressed: isShoppingListLoading
                ? null
                : () {
                    final item = ShoppingItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: product.name,
                      productBarcode: product.barcode,
                    );
                    ref
                        .read(shoppingListNotifierProvider.notifier)
                        .addItem(item);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Agregado a Mi lista de compras'),
                      ),
                    );
                  },
            child: isShoppingListLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Agregar a lista'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _NotFoundView
// Rendered when ProductDetailNotFound (API returned 404 / product missing).
// ---------------------------------------------------------------------------

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 64,
              color: context.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: context.spacing.md),
            Text(
              'Producto no encontrado',
              style: context.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.spacing.sm),
            Text(
              'Este producto no está en la base de datos de Open Food Facts.',
              style: context.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _NetworkErrorView
// Rendered when ProductDetailNetworkError (no network + no cache).
// ---------------------------------------------------------------------------

class _NetworkErrorView extends StatelessWidget {
  const _NetworkErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_outlined,
              size: 64,
              color: context.colorScheme.error,
            ),
            SizedBox(height: context.spacing.md),
            Text(
              'Sin conexión',
              style: context.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.spacing.sm),
            Text(
              'No se pudo cargar el producto. Verificá tu conexión e intentá de nuevo.',
              style: context.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.spacing.lg),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
