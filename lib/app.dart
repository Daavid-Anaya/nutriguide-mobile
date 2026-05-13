import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';
import 'package:nutriguide_mobile/router/app_router.dart';

/// Root application widget.
///
/// A [ConsumerWidget] that assembles [MaterialApp.router] with:
/// - [AppTheme.light] as the theme (Material 3, no hardcoded colours)
/// - [appRouterProvider] for the GoRouter configuration
/// - [debugShowCheckedModeBanner] disabled
///
/// Spec: ENTRYPOINT-001 | Design: AD-03
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'NutriGuide',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
