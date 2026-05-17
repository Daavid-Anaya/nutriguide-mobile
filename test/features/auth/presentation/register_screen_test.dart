// Spec: AUTH-EMAIL-001 — Email/password registration screen
// TDD: Phase 5 [RED] — RegisterScreen implementation

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';
import 'package:nutriguide_mobile/features/auth/presentation/register_screen.dart';
import 'package:nutriguide_mobile/features/auth/presentation/providers/auth_notifier.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Fake without stream subscription
class FakeAuthNotifier extends AuthNotifier {
  @override
  Future<User?> build() async => null;
}

Widget buildSubject() {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => FakeAuthNotifier()),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const RegisterScreen(),
    ),
  );
}

void main() {
  group('RegisterScreen', () {
    testWidgets('renders name field', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.text('Nombre'), findsOneWidget);
    });

    testWidgets('renders email field', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('renders password field', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.text('Contraseña'), findsOneWidget);
    });

    testWidgets('renders confirm password field', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.text('Confirmar contraseña'), findsOneWidget);
    });

    testWidgets('shows validation error for empty name', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      // Tap the FilledButton (submit), not the title Text
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(find.textContaining('nombre'), findsAtLeast(1));
    });

    testWidgets('shows validation error for passwords that do not match',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      // Fill all fields, mismatched passwords
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Test User'); // name
      await tester.enterText(fields.at(1), 'test@test.com'); // email
      await tester.enterText(fields.at(2), 'password1'); // password
      await tester.enterText(fields.at(3), 'password2'); // confirm
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(find.textContaining('no coinciden'), findsOneWidget);
    });

    testWidgets('shows validation error for password less than 6 chars',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Test User');
      await tester.enterText(fields.at(1), 'test@test.com');
      await tester.enterText(fields.at(2), '12345'); // only 5 chars
      await tester.enterText(fields.at(3), '12345');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(find.textContaining('6'), findsAtLeast(1));
    });

    testWidgets('renders link to Login', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.textContaining('Iniciar sesión'), findsOneWidget);
    });
  });
}
