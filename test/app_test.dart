// Spec: ENTRYPOINT-001
// Task: T-19 (app.dart — App widget)
// TDD RED phase: tests written before lib/app.dart exists.
//
// Test layer: testWidgets — touches MaterialApp.router and Theme (requires
// Flutter test binding). Use `testWidgets` throughout (NOT `test`).
//
// Strategy:
//   - Override `appRouterProvider` with a stub GoRouter that renders a simple
//     Text widget on '/'. This avoids real Supabase calls (authNotifierProvider).
//   - Override `authNotifierProvider` with AsyncData(null) so the router redirect
//     guard stays predictable (unauthenticated → stays on /login stub).
//   - Use ProviderScope(overrides: [...]) wrapper for all widget tests.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nutriguide_mobile/app.dart';
import 'package:nutriguide_mobile/features/auth/presentation/providers/auth_notifier.dart';
import 'package:nutriguide_mobile/router/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Stub GoRouter — renders a Text on every route so we can pump the tree
// without touching secure storage or real screens.
// ---------------------------------------------------------------------------

GoRouter _stubRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(
          body: Center(child: Text('stub home')),
        ),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Helper: wraps App in ProviderScope with stub overrides.
// ---------------------------------------------------------------------------

Widget _buildApp() {
  return ProviderScope(
    overrides: [
      // Provide a stub router — avoids real authNotifierProvider reads inside GoRouter.
      appRouterProvider.overrideWithValue(_stubRouter()),
      // Override authNotifierProvider so its build() is never called (no Supabase).
      authNotifierProvider.overrideWith(() => _StubAuthNotifier()),
    ],
    child: const App(),
  );
}

/// Stub notifier — always returns AsyncData(null) (unauthenticated), never
/// calls Supabase.
class _StubAuthNotifier extends AuthNotifier {
  @override
  Future<User?> build() async => null;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // T-19a: App renders a MaterialApp.router
  //
  // Spec: ENTRYPOINT-001 — the root widget must use MaterialApp.router
  // (not MaterialApp) so GoRouter controls the navigator.
  // =========================================================================
  group('App widget', () {
    testWidgets(
      'renders a MaterialApp widget (MaterialApp.router is a MaterialApp subtype)',
      (tester) async {
        await tester.pumpWidget(_buildApp());
        await tester.pumpAndSettle();

        // MaterialApp.router builds a MaterialApp internally — find it.
        expect(find.byType(MaterialApp), findsOneWidget);
      },
    );

    // =========================================================================
    // T-19b: Theme uses Material 3
    //
    // Spec: ENTRYPOINT-001 — theme must be AppTheme.light which sets
    // useMaterial3: true.
    // =========================================================================
    testWidgets(
      'theme has useMaterial3 set to true',
      (tester) async {
        await tester.pumpWidget(_buildApp());
        await tester.pumpAndSettle();

        final MaterialApp app = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(app.theme?.useMaterial3, isTrue);
      },
    );

    // =========================================================================
    // T-19c: debugShowCheckedModeBanner is false
    //
    // Spec: ENTRYPOINT-001 — banner must be hidden in all modes.
    // =========================================================================
    testWidgets(
      'debugShowCheckedModeBanner is false',
      (tester) async {
        await tester.pumpWidget(_buildApp());
        await tester.pumpAndSettle();

        final MaterialApp app = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(app.debugShowCheckedModeBanner, isFalse);
      },
    );

    // =========================================================================
    // T-19d: App title is 'NutriGuide'
    //
    // Spec: ENTRYPOINT-001 — MaterialApp.router title must be 'NutriGuide'.
    // =========================================================================
    testWidgets(
      'app title is "NutriGuide"',
      (tester) async {
        await tester.pumpWidget(_buildApp());
        await tester.pumpAndSettle();

        final MaterialApp app = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(app.title, equals('NutriGuide'));
      },
    );
  });
}
