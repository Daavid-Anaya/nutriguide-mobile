import 'package:flutter/material.dart';

/// Product detail screen placeholder.
///
/// Displays product info for the given [barcode] EAN/UPC.
/// Full product UI will be implemented in a future phase.
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.barcode});

  /// EAN/UPC barcode string extracted from the route path parameter.
  final String barcode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text('Product: $barcode')),
      body: Center(child: Text('Product details for $barcode')),
    );
  }
}
