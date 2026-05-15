// Spec: HOME-UI-003 sc1–sc2
// Design: displaySmall Manrope for greeting, bodyMedium for subtitle.
// TDD: T-10 [GREEN] — Implements GreetingSection to pass T-09 tests.

import 'package:flutter/material.dart';
import 'package:nutriguide_mobile/core/extensions/context_extensions.dart';
import 'package:nutriguide_mobile/core/theme/app_spacing.dart';

/// Greeting section for the Home screen.
///
/// Displays "Hola, {userName}" in [displaySmall] Manrope typography and
/// a subtitle "Tu resumen de bienestar de hoy" in [bodyMedium] style.
///
/// Spec: HOME-UI-003 | Design: typography tokens from AD-04.
class GreetingSection extends StatelessWidget {
  const GreetingSection({
    super.key,
    required this.userName,
  });

  /// The user's display name. Appended to "Hola, ".
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hola, $userName',
          style: context.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Tu resumen de bienestar de hoy',
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
