import 'package:flutter/material.dart';

/// Shopping list screen placeholder.
///
/// Simple scaffold with AppBar — skeleton so the router can navigate here.
/// Full shopping list UI will be implemented in a future phase.
class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Shopping List')),
      body: const Center(child: Text('Shopping List')),
    );
  }
}
