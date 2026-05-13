import 'package:flutter/material.dart';
import 'package:nutriguide_mobile/core/theme/app_spacing.dart';

/// [BuildContext] extensions for quick access to Material theme tokens.
///
/// Widgets should use these extensions instead of calling
/// [Theme.of(context)] directly, keeping widget trees clean.
///
/// Usage:
/// ```dart
/// Container(color: context.colorScheme.surface)
/// Text('Hello', style: context.textTheme.bodyMedium)
/// SizedBox(height: context.spacing.md)
/// ```
extension ThemeExtension on BuildContext {
  /// Access the current [ColorScheme] from the nearest [MaterialApp] theme.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Access the current [TextTheme] from the nearest [MaterialApp] theme.
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Access [AppSpacing] constants for consistent spacing.
  ///
  /// Returns [AppSpacingProxy] which exposes all [AppSpacing] constants.
  AppSpacingProxy get spacing => const AppSpacingProxy();
}

/// Proxy that exposes [AppSpacing] constants via [context.spacing.md] syntax.
///
/// Returned by [ThemeExtension.spacing] — not intended to be instantiated
/// directly.
class AppSpacingProxy {
  const AppSpacingProxy();

  double get xs => AppSpacing.xs;
  double get sm => AppSpacing.sm;
  double get md => AppSpacing.md;
  double get lg => AppSpacing.lg;
  double get xl => AppSpacing.xl;
  double get xxl => AppSpacing.xxl;
}
