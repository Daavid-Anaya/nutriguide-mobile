// Spec: PROFILE-UI-003 (S1, S2, S3, S4)
// Design: AD-38 — ProfileAvatar widget with CachedNetworkImage + Icon fallback
// TDD: T-07 [RED] — failing tests for ProfileAvatar (widget doesn't exist yet)

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';
import 'package:nutriguide_mobile/features/profile/presentation/widgets/profile_avatar.dart';

Widget buildSubject(String? avatarUrl, {double radius = 48}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: ProfileAvatar(avatarUrl: avatarUrl, radius: radius),
    ),
  );
}

void main() {
  group('ProfileAvatar', () {
    // S1: null avatarUrl → fallback Icon(Icons.person)
    testWidgets('shows Icon(Icons.person) when avatarUrl is null', (tester) async {
      await tester.pumpWidget(buildSubject(null));
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    // S2: valid URL → CachedNetworkImage
    testWidgets('shows CachedNetworkImage when avatarUrl is non-null', (tester) async {
      await tester.pumpWidget(buildSubject('https://example.com/avatar.jpg'));
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    // S3: empty string → fallback Icon(Icons.person)
    testWidgets('shows Icon(Icons.person) when avatarUrl is empty string', (tester) async {
      await tester.pumpWidget(buildSubject(''));
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    // S4: default radius 48 → diameter 96dp ≥ 80dp
    testWidgets('has diameter of at least 80dp with default radius', (tester) async {
      await tester.pumpWidget(buildSubject(null));
      final circleFinder = find.byType(CircleAvatar);
      expect(circleFinder, findsOneWidget);
      final avatar = tester.widget<CircleAvatar>(circleFinder);
      expect(avatar.radius, greaterThanOrEqualTo(40.0)); // radius ≥ 40 → diameter ≥ 80
    });
  });
}
