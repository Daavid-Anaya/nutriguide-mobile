// Spec: NAVIGATION-001
// Tasks: T-17 (route_constants.dart, app_router.dart) + T-18 (ScaffoldWithNavBar)
// TDD RED phase: all tests written before production code exists.
//
// Test layers:
// - Routes constants   → unit test (pure constants, no Flutter context)
// - redirect logic     → unit test (pure function extracted for testability)
// - ScaffoldWithNavBar → testWidgets (real GoRouter integration, widget tree)
//
// NOTE: Tests that touch widgets MUST use `testWidgets` (not `test`) because
// the Flutter test binding must be initialized.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nutriguide_mobile/router/app_router.dart';
import 'package:nutriguide_mobile/router/route_constants.dart';
import 'package:nutriguide_mobile/router/scaffold_with_nav_bar.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a minimal GoRouter that shows [ScaffoldWithNavBar] at "/".
///
/// This uses the real [StatefulShellRoute.indexedStack] so that a real
/// [StatefulNavigationShell] is created and passed to [ScaffoldWithNavBar].
/// Branches use [SizedBox] placeholders — we only test the shell chrome.
GoRouter _buildTestRouter({int initialBranchIndex = 0}) {
  return GoRouter(
    initialLocation: initialBranchIndex == 0
        ? '/'
        : initialBranchIndex == 1
            ? '/scanner'
            : initialBranchIndex == 2
                ? '/lists'
                : '/profile',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (_, _) => const SizedBox()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/scanner',
              builder: (_, _) => const SizedBox(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/lists', builder: (_, _) => const SizedBox()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, _) => const SizedBox()),
          ]),
        ],
      ),
    ],
  );
}

Widget _wrapInApp(GoRouter router) {
  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // T-17a: Routes constants
  // NAVIGATION-001 — all route paths must have the specified values.
  // Triangulation skipped: pure constants, single correct value per constant.
  // =========================================================================
  group('Routes constants', () {
    test('Routes.home equals "/"', () {
      expect(Routes.home, equals('/'));
    });

    test('Routes.scanner equals "/scanner"', () {
      expect(Routes.scanner, equals('/scanner'));
    });

    test('Routes.scannerProduct equals "/scanner/product/:barcode"', () {
      expect(Routes.scannerProduct, equals('/scanner/product/:barcode'));
    });

    test('Routes.lists equals "/lists"', () {
      expect(Routes.lists, equals('/lists'));
    });

    test('Routes.profile equals "/profile"', () {
      expect(Routes.profile, equals('/profile'));
    });

    test('Routes.login equals "/login"', () {
      expect(Routes.login, equals('/login'));
    });

    test('Routes.register equals "/register"', () {
      expect(Routes.register, equals('/register'));
    });
  });

  // =========================================================================
  // T-17b: redirect logic (pure function extracted for testability)
  // NAVIGATION-001:
  //   - Unauthenticated user on protected route → redirect to /login
  //   - Authenticated user on protected route → no redirect (null)
  //   - Authenticated user on /login → redirect to /
  //   - Unauthenticated user on /login → no redirect (null)
  //
  // `evaluateRedirect` is exported from app_router.dart as a pure function.
  // This removes ALL mocking — pure input/output test, zero dependencies.
  // =========================================================================
  group('evaluateRedirect (pure redirect logic)', () {
    // --- unauthenticated + protected route → /login ---

    test(
      'unauthenticated user on home route is redirected to /login',
      () {
        final result = evaluateRedirect(
          isAuthenticated: false,
          location: Routes.home,
        );
        expect(result, equals(Routes.login));
      },
    );

    test(
      'unauthenticated user on /lists is redirected to /login',
      () {
        final result = evaluateRedirect(
          isAuthenticated: false,
          location: Routes.lists,
        );
        expect(result, equals(Routes.login));
      },
    );

    test(
      'unauthenticated user on /profile is redirected to /login',
      () {
        final result = evaluateRedirect(
          isAuthenticated: false,
          location: Routes.profile,
        );
        expect(result, equals(Routes.login));
      },
    );

    // --- unauthenticated + auth route → no redirect ---

    test(
      'unauthenticated user on /login is NOT redirected (null)',
      () {
        final result = evaluateRedirect(
          isAuthenticated: false,
          location: Routes.login,
        );
        expect(result, isNull);
      },
    );

    test(
      'unauthenticated user on /register is NOT redirected (null)',
      () {
        final result = evaluateRedirect(
          isAuthenticated: false,
          location: Routes.register,
        );
        expect(result, isNull);
      },
    );

    // --- authenticated + protected route → no redirect ---

    test(
      'authenticated user on home route is NOT redirected (null)',
      () {
        final result = evaluateRedirect(
          isAuthenticated: true,
          location: Routes.home,
        );
        expect(result, isNull);
      },
    );

    test(
      'authenticated user on /scanner is NOT redirected (null)',
      () {
        final result = evaluateRedirect(
          isAuthenticated: true,
          location: Routes.scanner,
        );
        expect(result, isNull);
      },
    );

    // --- authenticated + auth route → redirect to home ---

    test(
      'authenticated user on /login is redirected to /',
      () {
        final result = evaluateRedirect(
          isAuthenticated: true,
          location: Routes.login,
        );
        expect(result, equals(Routes.home));
      },
    );

    test(
      'authenticated user on /register is redirected to /',
      () {
        final result = evaluateRedirect(
          isAuthenticated: true,
          location: Routes.register,
        );
        expect(result, equals(Routes.home));
      },
    );
  });

  // =========================================================================
  // T-17c: appRouterProvider resolves to a GoRouter
  // =========================================================================
  group('appRouterProvider', () {
    test('returns a non-null GoRouter instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);

      expect(router, isA<GoRouter>());
    });
  });

  // =========================================================================
  // T-18: ScaffoldWithNavBar widget
  // NAVIGATION-001:
  //   - Shell scaffold has 4 NavigationDestination widgets
  //   - Shell scaffold has a FloatingActionButton
  //   - NavigationBar selectedIndex reflects navigationShell.currentIndex
  //   - NavigationDestination labels are correct
  //
  // Uses a real StatefulShellRoute.indexedStack via _buildTestRouter()
  // so that GoRouter provides a real StatefulNavigationShell.
  // =========================================================================
  group('ScaffoldWithNavBar', () {
    testWidgets(
      'renders exactly 4 NavigationDestination widgets',
      (tester) async {
        await tester.pumpWidget(_wrapInApp(_buildTestRouter()));
        await tester.pumpAndSettle();

        final destinations = tester.widgetList<NavigationDestination>(
          find.byType(NavigationDestination),
        );
        expect(destinations.length, equals(4));
      },
    );

    testWidgets(
      'renders a FloatingActionButton',
      (tester) async {
        await tester.pumpWidget(_wrapInApp(_buildTestRouter()));
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsOneWidget);
      },
    );

    testWidgets(
      'FAB has qr_code_scanner icon',
      (tester) async {
        await tester.pumpWidget(_wrapInApp(_buildTestRouter()));
        await tester.pumpAndSettle();

        final fab = tester.widget<FloatingActionButton>(
          find.byType(FloatingActionButton),
        );
        final icon = fab.child as Icon;
        expect(icon.icon, equals(Icons.qr_code_scanner));
      },
    );

    testWidgets(
      'NavigationDestination labels are Home, Scan, Lists, Profile',
      (tester) async {
        await tester.pumpWidget(_wrapInApp(_buildTestRouter()));
        await tester.pumpAndSettle();

        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Scan'), findsOneWidget);
        expect(find.text('Lists'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);
      },
    );

    testWidgets(
      'NavigationBar selectedIndex is 0 when on home branch',
      (tester) async {
        await tester.pumpWidget(_wrapInApp(_buildTestRouter(initialBranchIndex: 0)));
        await tester.pumpAndSettle();

        final navBar = tester.widget<NavigationBar>(
          find.byType(NavigationBar),
        );
        expect(navBar.selectedIndex, equals(0));
      },
    );

    testWidgets(
      'NavigationBar selectedIndex is 2 when on lists branch',
      (tester) async {
        await tester.pumpWidget(_wrapInApp(_buildTestRouter(initialBranchIndex: 2)));
        await tester.pumpAndSettle();

        final navBar = tester.widget<NavigationBar>(
          find.byType(NavigationBar),
        );
        expect(navBar.selectedIndex, equals(2));
      },
    );
  });
}
