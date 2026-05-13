import 'package:flutter/material.dart';

/// Scanner screen placeholder.
///
/// Simple scaffold with AppBar — skeleton so the router can navigate here.
/// Full barcode scanner UI will be implemented in a future phase.
class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Scanner')),
      body: const Center(child: Text('Scanner')),
    );
  }
}
