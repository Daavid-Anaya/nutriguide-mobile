// Spec: SCANNER-WIDGET-001 sc5, sc6; SCANNER-UI-002 sc6
// T-08: ProductHeader — product image/name/brand/cache chip widget.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';
import 'package:nutriguide_mobile/features/scanner/domain/product.dart';
import 'package:nutriguide_mobile/features/scanner/presentation/widgets/product_header.dart';

/// A product stub with all required fields.
const _baseProduct = Product(
  barcode: '3017620425035',
  name: 'Nutella',
  brands: 'Ferrero',
  imageUrl: 'https://example.com/nutella.jpg',
);

/// Pumps ProductHeader in a minimal MaterialApp.
Future<void> pumpHeader(
  WidgetTester tester,
  Product product, {
  bool isFromCache = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ProductHeader(product: product, isFromCache: isFromCache),
        ),
      ),
    ),
  );
  // Let CachedNetworkImage settle — it will fall back gracefully in test env.
  await tester.pump();
}

void main() {
  group('ProductHeader', () {
    // RED → GREEN sc5: null imageUrl → placeholder Icon visible, name still visible
    testWidgets(
      'imageUrl null → placeholder Icon(Icons.image_not_supported) is shown',
      (tester) async {
        final product = _baseProduct.copyWith(imageUrl: null);

        await pumpHeader(tester, product);

        // Placeholder icon must be present
        expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
        // CachedNetworkImage must NOT be present
        expect(find.byType(CachedNetworkImage), findsNothing);
        // Product name still visible
        expect(find.text('Nutella'), findsOneWidget);
      },
    );

    // TRIANGULATE sc5: non-null imageUrl → CachedNetworkImage is rendered
    // NOTE: In test env CachedNetworkImage can't load the image (HTTP returns 400),
    // so the placeholder callback fires. We verify the CachedNetworkImage WIDGET
    // is present in the tree and that the product name is still visible.
    testWidgets(
      'imageUrl non-null → CachedNetworkImage widget is present in the tree',
      (tester) async {
        await pumpHeader(tester, _baseProduct);

        // CachedNetworkImage widget must be present (actual loading not tested)
        expect(find.byType(CachedNetworkImage), findsOneWidget);
        // Name still visible
        expect(find.text('Nutella'), findsOneWidget);
      },
    );

    // RED → GREEN sc6: isFromCache true → "datos locales" Chip visible
    testWidgets(
      'isFromCache true → Chip with label "datos locales" is shown',
      (tester) async {
        final product = _baseProduct.copyWith(imageUrl: null);

        await pumpHeader(tester, product, isFromCache: true);

        // Chip must be present with the correct label
        expect(find.byType(Chip), findsOneWidget);
        expect(find.text('datos locales'), findsOneWidget);
      },
    );

    // TRIANGULATE sc6: isFromCache false → no Chip; also brands null → no brands text
    testWidgets(
      'isFromCache false → no Chip; brands null → brands text absent',
      (tester) async {
        final product = _baseProduct.copyWith(
          imageUrl: null,
          brands: null,
        );

        await pumpHeader(tester, product);

        // No Chip when not from cache
        expect(find.byType(Chip), findsNothing);
        expect(find.text('datos locales'), findsNothing);
        // brands text is absent
        expect(find.text('Ferrero'), findsNothing);
        // Name still present
        expect(find.text('Nutella'), findsOneWidget);
      },
    );
  });
}
