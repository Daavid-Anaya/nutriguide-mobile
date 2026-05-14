// Spec: SCANNER-UI-001 sc1, sc2, sc3, sc4
// AD-15 + AD-18: ScannerScreen widget tests.
//
// Testing strategy (AD-18):
// MobileScanner is a native plugin — it CANNOT initialize in flutter_test.
// We test the extracted sub-widgets (ScannerPermissionDeniedBody,
// ScannerTorchButton) directly, and test navigation via FakeScannerNotifier.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutriguide_mobile/features/scanner/presentation/providers/scanner_notifier.dart';
import 'package:nutriguide_mobile/features/scanner/presentation/scanner_screen.dart';

// ---------------------------------------------------------------------------
// Fakes / Mocks
// ---------------------------------------------------------------------------

class MockMobileScannerController extends Mock
    implements MobileScannerController {}

/// A ScannerNotifier that starts in a configurable state.
class FakeScannerNotifier extends ScannerNotifier {
  FakeScannerNotifier(this._initial);

  final ScannerState _initial;

  @override
  ScannerState build() => _initial;

  @override
  void onBarcodeDetected(String barcode) {
    state = ScannerDetected(barcode);
  }

  @override
  void reset() => state = const ScannerIdle();

  @override
  void toggleTorch() {}

  @override
  void startScanning() => state = const ScannerScanning();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockMobileScannerController mockController;

  setUp(() {
    mockController = MockMobileScannerController();
    // MobileScannerController extends ValueNotifier<MobileScannerState>.
    // We must stub addListener/removeListener for ValueListenableBuilder.
    when(() => mockController.value).thenReturn(
      MobileScannerState.uninitialized(CameraFacing.back),
    );
    when(() => mockController.autoStart).thenReturn(false);
    when(() => mockController.addListener(any())).thenReturn(null);
    when(() => mockController.removeListener(any())).thenReturn(null);
    when(() => mockController.start()).thenAnswer((_) async {});
    when(() => mockController.stop()).thenAnswer((_) async {});
    when(() => mockController.dispose()).thenAnswer((_) async {});
  });

  // ── Test 1 ─────────────────────────────────────────────────────────────
  // Spec SCANNER-UI-001 sc2: permission denied → error message + button.
  // Tested via the extracted ScannerPermissionDeniedBody widget.
  testWidgets(
    'ScannerPermissionDeniedBody shows error message and "Abrir configuración"',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScannerPermissionDeniedBody()),
        ),
      );

      expect(find.text('Se necesita acceso a la cámara'), findsOneWidget);
      expect(find.text('Abrir configuración'), findsOneWidget);
    },
  );

  // ── Test 2 ─────────────────────────────────────────────────────────────
  // Spec SCANNER-UI-001 sc3: torch IconButton is present (flash_off by default).
  testWidgets(
    'ScannerTorchButton shows flash_off icon when torch is off',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannerTorchButton(
              torchState: TorchState.off,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.flash_off), findsOneWidget);
    },
  );

  // ── Test 3 ─────────────────────────────────────────────────────────────
  // Spec SCANNER-UI-001 sc3: torch icon toggles to flash_on when torch is on.
  testWidgets(
    'ScannerTorchButton shows flash_on icon when torch is on',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannerTorchButton(
              torchState: TorchState.on,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.flash_on), findsOneWidget);
      expect(find.byIcon(Icons.flash_off), findsNothing);
    },
  );

  // ── Test 4 ─────────────────────────────────────────────────────────────
  // Spec SCANNER-UI-001 sc1: ScannerDetected state triggers navigation.
  // We render the full ScannerScreen with overridden providers and trigger
  // state change programmatically.
  testWidgets(
    'ScannerDetected state triggers context.push to product detail route',
    (tester) async {
      FakeScannerNotifier? capturedNotifier;

      final router = GoRouter(
        initialLocation: '/scanner',
        routes: [
          GoRoute(
            path: '/scanner',
            builder: (context, _) => ProviderScope(
              overrides: [
                mobileScannerControllerProvider
                    .overrideWithValue(mockController),
                scannerNotifierProvider.overrideWith(() {
                  capturedNotifier = FakeScannerNotifier(const ScannerIdle());
                  return capturedNotifier!;
                }),
              ],
              child: const ScannerScreen(),
            ),
          ),
          GoRoute(
            path: '/scanner/product/:barcode',
            builder: (_, state) => Scaffold(
              body: Text('product:${state.pathParameters['barcode']}'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      // Trigger barcode detection on the notifier.
      capturedNotifier!.onBarcodeDetected('3017620425035');
      await tester.pumpAndSettle();

      // The router should have navigated to product detail.
      expect(find.text('product:3017620425035'), findsOneWidget);
    },
  );
}
