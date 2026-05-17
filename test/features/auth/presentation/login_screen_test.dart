// Spec: AUTH-EMAIL-002 — Email/password login screen
// TDD: Phase 4 [RED] — LoginScreen implementation

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';
import 'package:nutriguide_mobile/features/auth/presentation/login_screen.dart';
import 'package:nutriguide_mobile/features/auth/presentation/providers/auth_notifier.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Fake that seeds a specific initial state without subscribing to auth stream
class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._initialUser);
  final User? _initialUser;

  @override
  Future<User?> build() async => _initialUser;
}

Widget buildSubject({User? seedUser}) {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => FakeAuthNotifier(seedUser)),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const LoginScreen(),
    ),
  );
}

void main() {
  group('LoginScreen', () {
    testWidgets('renders email field', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.byType(TextFormField), findsAtLeast(2)); // email + password
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('renders password field', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.text('Contraseña'), findsOneWidget);
    });

    testWidgets('renders submit button', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.text('Iniciar sesión'), findsOneWidget);
    });

    testWidgets('renders link to Register', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.textContaining('Registrarse'), findsOneWidget);
    });

    testWidgets('shows validation error for empty email', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();
      expect(find.textContaining('email'), findsAtLeast(1));
    });

    testWidgets('shows validation error for empty password', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      // Enter email but leave password empty
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@test.com');
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();
      expect(find.textContaining('contraseña'), findsAtLeast(1));
    });
  });
}
