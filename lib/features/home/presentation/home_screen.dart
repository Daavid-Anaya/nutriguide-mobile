import 'package:flutter/material.dart';

/// Home screen placeholder.
///
/// Simple scaffold with AppBar — skeleton so the router can navigate here.
/// Full home screen UI will be implemented in a future phase.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Home')),
    );
  }
}
