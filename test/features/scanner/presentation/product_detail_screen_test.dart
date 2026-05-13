// Spec: AD-01 (T-20) — ProductDetail placeholder screen
// Verifies: Scaffold renders, AppBar shows 'Product: <barcode>', body shows detail text.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/features/scanner/presentation/product_detail_screen.dart';

void main() {
  const testBarcode = '7501055300627';

  group('ProductDetailScreen', () {
    Widget buildSubject() =>
        const MaterialApp(home: ProductDetailScreen(barcode: testBarcode));

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows AppBar with "Product: <barcode>" title', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(
        find.widgetWithText(AppBar, 'Product: $testBarcode'),
        findsOneWidget,
      );
    });

    testWidgets('shows body detail text with barcode', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(
        find.text('Product details for $testBarcode'),
        findsOneWidget,
      );
    });
  });
}
