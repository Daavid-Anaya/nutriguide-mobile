import 'package:flutter/material.dart';

/// Register screen placeholder.
///
/// No UI implementation — skeleton scaffold so the router can navigate here.
/// Full registration form UI will be implemented in a future iteration.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: const Center(
        child: Text('Register'),
      ),
    );
  }
}
