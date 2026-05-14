// Spec: SCANNER-WIDGET-001 sc5, sc6; SCANNER-UI-002 sc6
// Design: AD-17 — CachedNetworkImage with placeholder, cache chip.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nutriguide_mobile/core/extensions/context_extensions.dart';
import 'package:nutriguide_mobile/core/theme/app_shapes.dart';
import 'package:nutriguide_mobile/features/scanner/domain/product.dart';

/// Displays the product image, name, brand, and optionally a "datos locales"
/// cache badge.
///
/// - When [product.imageUrl] is non-null, renders a [CachedNetworkImage].
/// - When [product.imageUrl] is null (or on load error), renders
///   [Icon(Icons.image_not_supported)] as placeholder.
/// - When [product.brands] is null, the brands line is omitted.
/// - When [isFromCache] is `true`, a [Chip(label: Text('datos locales'))]
///   is shown below the name/brands.
class ProductHeader extends StatelessWidget {
  const ProductHeader({
    super.key,
    required this.product,
    this.isFromCache = false,
  });

  /// The product whose information is displayed.
  final Product product;

  /// Whether the product was loaded from the local cache fallback.
  ///
  /// When `true`, a "datos locales" [Chip] is rendered.
  final bool isFromCache;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Product image ───────────────────────────────────────────────────
        ClipRRect(
          borderRadius: AppShapes.containerRadius,
          child: product.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: product.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorWidget: (ctx, url, err) => _placeholder(ctx),
                  placeholder: (ctx, url) => _placeholder(ctx),
                )
              : _placeholder(context),
        ),

        SizedBox(height: context.spacing.md),

        // ── Product name ────────────────────────────────────────────────────
        Text(
          product.name,
          style: context.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),

        // ── Brand (omitted when null) ────────────────────────────────────────
        if (product.brands != null) ...[
          SizedBox(height: context.spacing.xs),
          Text(
            product.brands!,
            style: context.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],

        // ── Cache badge (only when from cache) ──────────────────────────────
        if (isFromCache) ...[
          SizedBox(height: context.spacing.sm),
          const Chip(label: Text('datos locales')),
        ],
      ],
    );
  }

  /// Fallback placeholder shown when imageUrl is null or image fails to load.
  Widget _placeholder(BuildContext context) {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          size: 64,
          color: context.colorScheme.onSurface.withAlpha(100),
        ),
      ),
    );
  }
}
