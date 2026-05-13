import 'package:flutter/material.dart';

/// Centered [CircularProgressIndicator] using the primary theme color.
///
/// Usage:
/// ```dart
/// if (isLoading) const LoadingIndicator()
/// ```
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
