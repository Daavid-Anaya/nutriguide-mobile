import 'package:flutter/material.dart';

/// Login screen placeholder.
///
/// No UI implementation — skeleton scaffold so the router can navigate here.
/// Full login form UI will be implemented in a future iteration.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: const Center(
        child: Text('Login'),
      ),
    );
  }
}
