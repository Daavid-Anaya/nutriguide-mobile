import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nutriguide_mobile/features/auth/presentation/login_screen.dart';
import 'package:nutriguide_mobile/features/auth/presentation/providers/auth_notifier.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nutriguide_mobile/features/auth/presentation/register_screen.dart';
import 'package:nutriguide_mobile/features/home/presentation/home_screen.dart';
import 'package:nutriguide_mobile/features/profile/presentation/profile_screen.dart';
import 'package:nutriguide_mobile/features/scanner/presentation/product_detail_screen.dart';
import 'package:nutriguide_mobile/features/scanner/presentation/scanner_screen.dart';
import 'package:nutriguide_mobile/features/shopping_list/presentation/shopping_list_screen.dart';
import 'package:nutriguide_mobile/router/route_constants.dart';
import 'package:nutriguide_mobile/router/scaffold_with_nav_bar.dart';

// ---------------------------------------------------------------------------
// Pure redirect logic — extracted for testability (no GoRouter dependency)
// ---------------------------------------------------------------------------

/// Evaluates whether a navigation redirect is needed.
///
/// Pure function — deterministic, no side effects, easy to unit-test.
///
/// Returns:
/// - [Routes.login] when the user is unauthenticated and the [location] is
///   a protected route (anything that is NOT [Routes.login] or [Routes.register]).
/// - [Routes.home] when the user is authenticated and navigating to an auth
///   route ([Routes.login] or [Routes.register]).
/// - `null` when no redirect is required.
///
/// Spec: NAVIGATION-001
String? evaluateRedirect({
  required bool isAuthenticated,
  required String location,
}) {
  final isAuthRoute =
      location == Routes.login || location == Routes.register;

  if (!isAuthenticated && !isAuthRoute) {
    return Routes.login;
  }
  if (isAuthenticated && isAuthRoute) {
    return Routes.home;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Riverpod → Listenable bridge
// ---------------------------------------------------------------------------

/// A [ChangeNotifier] that watches Riverpod's [authNotifierProvider] and calls
/// [notifyListeners] whenever the auth state changes.
///
/// GoRouter requires a [Listenable] for its [GoRouter.refreshListenable] so
/// that it re-evaluates the redirect guard on every auth state change.
/// [ChangeNotifier] is the canonical bridge between Riverpod and GoRouter.
class _RouterChangeNotifier extends ChangeNotifier {
  _RouterChangeNotifier(this._ref) {
    // Listen to authNotifierProvider changes and notify GoRouter to re-evaluate redirects.
    _ref.listen<AsyncValue<User?>>(
      authNotifierProvider,
      (_, _) => notifyListeners(),
    );
  }

  final Ref _ref;
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

/// Riverpod provider that creates and configures the application-wide [GoRouter].
///
/// Uses [StatefulShellRoute.indexedStack] with 4 branches:
///   0 → Home `/`
///   1 → Scanner `/scanner` (with nested `/scanner/product/:barcode`)
///   2 → Lists `/lists`
///   3 → Profile `/profile`
///
/// Auth routes (`/login`, `/register`) live outside the shell so they don't
/// show the bottom navigation bar.
///
/// The [GoRouter.refreshListenable] is wired to [authProvider] via
/// [_RouterChangeNotifier], so every auth state change triggers a re-evaluation
/// of the redirect guard.
///
/// Spec: NAVIGATION-001 | Design: AD-05
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterChangeNotifier(ref);

  final router = GoRouter(
    initialLocation: Routes.home,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      // hasValue: the async build() has completed (not loading/error).
      // value != null: a Supabase User is present (authenticated).
      final isAuthenticated = authState.hasValue && authState.value != null;
      return evaluateRedirect(
        isAuthenticated: isAuthenticated,
        location: state.matchedLocation,
      );
    },
    routes: [
      // Auth screens — outside the shell (no bottom nav)
      GoRoute(
        path: Routes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (_, _) => const RegisterScreen(),
      ),

      // Shell with bottom navigation bar
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          // Branch 0 — Home
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.home,
              builder: (_, _) => const HomeScreen(),
            ),
          ]),
          // Branch 1 — Scanner (with nested product detail)
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.scanner,
              builder: (_, _) => const ScannerScreen(),
              routes: [
                GoRoute(
                  path: 'product/:barcode',
                  builder: (_, state) => ProductDetailScreen(
                    barcode: state.pathParameters['barcode']!,
                  ),
                ),
              ],
            ),
          ]),
          // Branch 2 — Shopping Lists
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.lists,
              builder: (_, _) => const ShoppingListScreen(),
            ),
          ]),
          // Branch 3 — Profile
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.profile,
              builder: (_, _) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
    ],
  );

  // Dispose the ChangeNotifier when the provider is disposed to avoid leaks.
  ref.onDispose(() {
    notifier.dispose();
    router.dispose();
  });

  return router;
});
