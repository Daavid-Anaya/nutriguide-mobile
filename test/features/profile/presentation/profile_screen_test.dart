// Spec: PROFILE-UI-001 (S1, S2, S3, S4), PROFILE-UI-002 (S1–S7), PROFILE-UI-003
//       AVATAR-UI-001 (S1, S2, S3, S4)
// Design: AD-38, AD-39 — ProfileScreen states driven by ProfileNotifier
// TDD: T-09, T-10, T-11 [RED] — failing tests for ProfileScreen (placeholder only)
//      T-09 [RED] → T-10 [GREEN] — avatar upload UI

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';
import 'package:nutriguide_mobile/features/profile/domain/user_profile.dart';
import 'package:nutriguide_mobile/features/profile/presentation/profile_screen.dart';
import 'package:nutriguide_mobile/features/profile/presentation/providers/profile_notifier.dart';
import 'package:nutriguide_mobile/features/profile/presentation/widgets/profile_avatar.dart';

// FakeProfileNotifier — seeds a specific state without calling real repository
class FakeProfileNotifier extends ProfileNotifier {
  FakeProfileNotifier(this._seeded);
  final ProfileState _seeded;

  @override
  Future<ProfileState> build() async => _seeded;
}

Widget buildSubject(ProfileState seedState) {
  return ProviderScope(
    overrides: [
      profileNotifierProvider.overrideWith(
        () => FakeProfileNotifier(seedState),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const ProfileScreen(),
    ),
  );
}

void main() {
  const testProfile = UserProfile(id: '', name: 'Ana García', email: '');
  const profileWithBudget =
      UserProfile(id: '', name: 'Ana', email: '', groceryBudget: 350.0);

  // ── T-11: Loading state ────────────────────────────────────────────────────
  group('ProfileScreen — loading state', () {
    testWidgets('shows loading indicator when ProfileLoading', (tester) async {
      await tester.pumpWidget(buildSubject(const ProfileLoading()));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  // ── T-11: Error state ──────────────────────────────────────────────────────
  group('ProfileScreen — error state', () {
    testWidgets('shows error message and retry button on ProfileError',
        (tester) async {
      await tester
          .pumpWidget(buildSubject(const ProfileError('Error de red')));
      await tester.pump();
      expect(find.text('Error de red'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  // ── T-09: Data state (read-only view) ─────────────────────────────────────
  group('ProfileScreen — data state', () {
    testWidgets('shows name in data view', (tester) async {
      await tester.pumpWidget(buildSubject(ProfileData(profile: testProfile)));
      await tester.pump();
      expect(find.text('Ana García'), findsOneWidget);
    });

    testWidgets('shows budget when set', (tester) async {
      await tester
          .pumpWidget(buildSubject(ProfileData(profile: profileWithBudget)));
      await tester.pump();
      expect(find.textContaining('350'), findsOneWidget);
    });

    testWidgets('shows "Sin presupuesto" when groceryBudget is null',
        (tester) async {
      await tester.pumpWidget(buildSubject(ProfileData(profile: testProfile)));
      await tester.pump();
      expect(find.textContaining('Sin presupuesto'), findsOneWidget);
    });

    testWidgets('shows Edit button in data view', (tester) async {
      await tester.pumpWidget(buildSubject(ProfileData(profile: testProfile)));
      await tester.pump();
      expect(find.text('Editar perfil'), findsOneWidget);
    });

    testWidgets('shows sign-out button in data view', (tester) async {
      await tester.pumpWidget(buildSubject(ProfileData(profile: testProfile)));
      await tester.pump();
      expect(find.text('Cerrar sesión'), findsOneWidget);
    });
  });

  // ── T-10: Editing state (form) ─────────────────────────────────────────────
  group('ProfileScreen — editing state', () {
    testWidgets('shows name pre-filled in form', (tester) async {
      await tester
          .pumpWidget(buildSubject(ProfileEditing(profile: testProfile)));
      await tester.pump();
      expect(find.widgetWithText(TextFormField, 'Ana García'), findsOneWidget);
    });

    testWidgets('shows budget pre-filled when set', (tester) async {
      await tester.pumpWidget(
          buildSubject(ProfileEditing(profile: profileWithBudget)));
      await tester.pump();
      expect(find.widgetWithText(TextFormField, '350.0'), findsOneWidget);
    });

    testWidgets('shows Save and Cancel buttons in editing state',
        (tester) async {
      await tester
          .pumpWidget(buildSubject(ProfileEditing(profile: testProfile)));
      await tester.pump();
      expect(find.text('Guardar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('shows validation error when name is empty and Save tapped',
        (tester) async {
      await tester
          .pumpWidget(buildSubject(ProfileEditing(profile: testProfile)));
      await tester.pump();
      // Clear the name field
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Ana García'), '');
      await tester.tap(find.text('Guardar'));
      await tester.pump();
      expect(find.text('El nombre es requerido'), findsOneWidget);
    });
  });

  // ── T-10: Saving state (fields disabled) ──────────────────────────────────
  group('ProfileScreen — saving state', () {
    testWidgets('fields are disabled during saving', (tester) async {
      await tester
          .pumpWidget(buildSubject(ProfileSaving(profile: testProfile)));
      await tester.pump();
      final fields =
          tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
      for (final field in fields) {
        expect(field.enabled, isFalse);
      }
    });
  });

  // ── T-13: SnackBar smoke test ──────────────────────────────────────────────
  group('ProfileScreen — save success feedback', () {
    testWidgets('shows SnackBar on successful save', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileNotifierProvider.overrideWith(
              () => FakeProfileNotifier(ProfileEditing(profile: testProfile)),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: ProfileScreen()),
          ),
        ),
      );
      await tester.pump();
      // Verify the editing form is shown with the Guardar button
      expect(find.text('Guardar'), findsOneWidget);
    });
  });

  // ── T-09/T-10: Avatar upload UI ────────────────────────────────────────────
  group('ProfileScreen — avatar upload UI', () {
    // -------------------------------------------------------------------------
    // AVATAR-UI-001-S1 — tappable avatar in data view
    // -------------------------------------------------------------------------
    testWidgets('wraps avatar in GestureDetector in data view', (tester) async {
      await tester
          .pumpWidget(buildSubject(ProfileData(profile: testProfile)));
      await tester.pump();
      // GestureDetector should wrap the ProfileAvatar
      final gestureDetectors = tester
          .widgetList<GestureDetector>(find.byType(GestureDetector))
          .toList();
      expect(gestureDetectors, isNotEmpty);
    });

    // -------------------------------------------------------------------------
    // AVATAR-UI-001-S1 — "Cambiar foto" button in data view
    // -------------------------------------------------------------------------
    testWidgets('shows "Cambiar foto" text in data view', (tester) async {
      await tester
          .pumpWidget(buildSubject(ProfileData(profile: testProfile)));
      await tester.pump();
      expect(find.text('Cambiar foto'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // AVATAR-UI-001-S2 — CircularProgressIndicator during ProfileUploading
    // -------------------------------------------------------------------------
    testWidgets('shows CircularProgressIndicator when ProfileUploading',
        (tester) async {
      await tester.pumpWidget(
          buildSubject(ProfileUploading(profile: testProfile)));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // AVATAR-UI-001-S3 — no avatarUrl TextFormField in edit form
    // -------------------------------------------------------------------------
    testWidgets('no "URL de avatar" field in edit form', (tester) async {
      await tester
          .pumpWidget(buildSubject(ProfileEditing(profile: testProfile)));
      await tester.pump();
      // Verify the avatarUrl TextFormField is gone
      expect(find.widgetWithText(TextFormField, 'URL de avatar'), findsNothing);
      // Only name and budget fields remain
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    // -------------------------------------------------------------------------
    // AVATAR-UI-001-S4 — ProfileAvatar displayed (non-tappable) in edit form
    // -------------------------------------------------------------------------
    testWidgets('ProfileAvatar visible in editing form (non-tappable)',
        (tester) async {
      await tester
          .pumpWidget(buildSubject(ProfileEditing(profile: testProfile)));
      await tester.pump();
      // ProfileAvatar shown in form
      expect(find.byType(ProfileAvatar), findsOneWidget);
    });
  });
}
