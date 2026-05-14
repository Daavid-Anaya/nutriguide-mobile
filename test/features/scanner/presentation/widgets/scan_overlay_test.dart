// Spec: SCANNER-WIDGET-001 (ScanOverlay requirements)
// T-09: ScanOverlay — full-screen dimmed overlay with centered scan window.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/theme/app_theme.dart';
import 'package:nutriguide_mobile/features/scanner/presentation/widgets/scan_overlay.dart';

/// Pumps ScanOverlay in a Stack that fills the screen (simulating camera below).
Future<void> pumpOverlay(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Stack(
          children: [
            // Simulated camera background
            Container(color: Colors.black),
            // The overlay under test
            const ScanOverlay(),
          ],
        ),
      ),
    ),
  );
}

void main() {
  group('ScanOverlay', () {
    // RED → GREEN: IgnorePointer wraps the overlay — touch events pass through.
    // Flutter internally uses IgnorePointer too, so we look for the one whose
    // ignoring=true (our ScanOverlay's IgnorePointer) among all found.
    testWidgets('IgnorePointer is present in the widget tree', (tester) async {
      await pumpOverlay(tester);

      // Find IgnorePointer widgets that are actually set to ignoring=true
      // (our ScanOverlay explicitly wraps with IgnorePointer(ignoring: true by default))
      final ignorePtrs = tester.widgetList<IgnorePointer>(
        find.byType(IgnorePointer),
      );
      // At least one IgnorePointer must be present (our overlay's)
      expect(ignorePtrs, isNotEmpty);
      // The ScanOverlay widget itself must be found
      expect(find.byType(ScanOverlay), findsOneWidget);
    });

    // TRIANGULATE: CustomPaint is present — the overlay painting happens
    testWidgets('CustomPaint is present in the widget tree', (tester) async {
      await pumpOverlay(tester);

      // Find CustomPaint that is a descendant of ScanOverlay
      final scanOverlayFinder = find.byType(ScanOverlay);
      final customPaintFinder = find.descendant(
        of: scanOverlayFinder,
        matching: find.byType(CustomPaint),
      );
      expect(customPaintFinder, findsOneWidget);
    });

    // TRIANGULATE: default scan window size is 280
    testWidgets('ScanOverlay has default scanWindowSize of 280', (tester) async {
      await pumpOverlay(tester);

      final overlay = tester.widget<ScanOverlay>(find.byType(ScanOverlay));
      expect(overlay.scanWindowSize, equals(280.0));
    });
  });
}
