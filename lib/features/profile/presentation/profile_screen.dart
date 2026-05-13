import 'package:flutter/material.dart';

/// Profile screen placeholder.
///
/// Simple scaffold with AppBar — skeleton so the router can navigate here.
/// Full profile UI will be implemented in a future phase.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Profile')),
    );
  }
}
