// Spec: HOME-UI-002 sc1–sc4
// TDD: T-07 [RED] — HomeHeader widget tests (written before implementation exists).

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';
import 'package:nutriguide_mobile/features/home/presentation/widgets/home_header.dart';

/// Pumps [HomeHeader] in a minimal MaterialApp with the app theme.
Future<void> pumpHeader(
  WidgetTester tester, {
  String? avatarUrl,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: HomeHeader(avatarUrl: avatarUrl),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('HomeHeader', () {
    // sc1: Avatar shows CachedNetworkImage when avatarUrl is non-null
    testWidgets(
      'avatarUrl non-null → CachedNetworkImage is present in the widget tree',
      (tester) async {
        await pumpHeader(tester, avatarUrl: 'https://example.com/avatar.jpg');

        expect(find.byType(CachedNetworkImage), findsOneWidget);
        expect(find.text('NutriGuide'), findsOneWidget);
      },
    );

    // sc2: Avatar shows person icon when avatarUrl is null
    testWidgets(
      'avatarUrl null → Icon(Icons.person) is displayed inside a CircleAvatar',
      (tester) async {
        await pumpHeader(tester, avatarUrl: null);

        expect(find.byIcon(Icons.person), findsOneWidget);
        expect(find.byType(CachedNetworkImage), findsNothing);
        expect(find.text('NutriGuide'), findsOneWidget);
      },
    );

    // sc3: The widget renders a CircleAvatar
    testWidgets(
      'CircleAvatar is always present in the widget tree',
      (tester) async {
        await pumpHeader(tester, avatarUrl: null);

        expect(find.byType(CircleAvatar), findsOneWidget);
      },
    );

    // sc4: No bell icon present (AD-30)
    testWidgets(
      'no bell or notification icon is present in the widget tree',
      (tester) async {
        await pumpHeader(tester, avatarUrl: null);

        expect(find.byIcon(Icons.notifications), findsNothing);
        expect(find.byIcon(Icons.notifications_outlined), findsNothing);
        expect(find.byIcon(Icons.notification_add), findsNothing);
        expect(find.byIcon(Icons.doorbell), findsNothing);
      },
    );
  });
}
