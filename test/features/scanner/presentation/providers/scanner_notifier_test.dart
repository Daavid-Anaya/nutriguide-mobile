// Spec: SCANNER-STATE-001 sc1; SCANNER-UI-001 sc3, sc4
// Phase 1 (T-01): State model assertions.
// Phase 2 (T-04): ScannerNotifier behavior tests.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutriguide_mobile/features/scanner/presentation/providers/scanner_notifier.dart';

// ---------------------------------------------------------------------------
// Mock — MobileScannerController cannot run native plugins in flutter_test.
// We implement the interface so every method returns a completed Future.
// ---------------------------------------------------------------------------
class MockMobileScannerController extends Mock
    implements MobileScannerController {}

// ---------------------------------------------------------------------------
// Helper — builds a ProviderContainer with the mock controller injected.
// ---------------------------------------------------------------------------
ProviderContainer _makeContainer(MockMobileScannerController mock) {
  return ProviderContainer(
    overrides: [
      mobileScannerControllerProvider.overrideWithValue(mock),
    ],
  );
}

void main() {
  group('ScannerState sealed class', () {
    // RED → GREEN: ScannerIdle is a valid initial state (structural assertion)
    test('ScannerIdle is a valid ScannerState instance', () {
      const state = ScannerIdle();

      expect(state, isA<ScannerState>());
      expect(state, isA<ScannerIdle>());
    });

    // RED → GREEN + TRIANGULATE: ScannerDetected carries barcode string
    test('ScannerDetected holds the scanned barcode string', () {
      const barcode = '3017620425035';
      const state = ScannerDetected(barcode);

      expect(state, isA<ScannerState>());
      expect(state.barcode, equals(barcode));
    });

    // TRIANGULATE: different barcode — ensures barcode field is not hardcoded
    test('ScannerDetected holds a different barcode string correctly', () {
      const barcode = '5000159461122';
      const state = ScannerDetected(barcode);

      expect(state.barcode, equals(barcode));
    });

    // TRIANGULATE: ScannerScanning is also a valid state
    test('ScannerScanning is a valid ScannerState instance', () {
      const state = ScannerScanning();

      expect(state, isA<ScannerState>());
      expect(state, isA<ScannerScanning>());
    });

    // Exhaustive switch — all 3 variants covered by sealed class contract
    test('sealed class switch is exhaustive over all 3 variants', () {
      const states = <ScannerState>[
        ScannerIdle(),
        ScannerScanning(),
        ScannerDetected('abc'),
      ];

      final labels = states.map((s) => switch (s) {
            ScannerIdle() => 'idle',
            ScannerScanning() => 'scanning',
            ScannerDetected(:final barcode) => 'detected:$barcode',
          }).toList();

      expect(labels, equals(['idle', 'scanning', 'detected:abc']));
    });
  });

  // ---------------------------------------------------------------------------
  // T-04: ScannerNotifier behavior tests
  // ---------------------------------------------------------------------------
  group('ScannerNotifier', () {
    late MockMobileScannerController mockController;
    late ProviderContainer container;

    setUp(() {
      mockController = MockMobileScannerController();
      // start() and stop() return Future<void> — stub them.
      when(() => mockController.start()).thenAnswer((_) async {});
      when(() => mockController.stop()).thenAnswer((_) async {});
      when(() => mockController.toggleTorch()).thenAnswer((_) async {});
      container = _makeContainer(mockController);
    });

    tearDown(() => container.dispose());

    // RED → GREEN: startScanning() transitions to ScannerScanning
    test('startScanning() transitions state to ScannerScanning', () {
      final notifier = container.read(scannerNotifierProvider.notifier);

      notifier.startScanning();

      expect(container.read(scannerNotifierProvider), isA<ScannerScanning>());
    });

    // RED → GREEN: onBarcodeDetected() stops controller and transitions to ScannerDetected
    test(
      'onBarcodeDetected() calls controller.stop() and transitions to ScannerDetected',
      () async {
        const barcode = '3017620425035';
        final notifier = container.read(scannerNotifierProvider.notifier);

        notifier.onBarcodeDetected(barcode);

        // State must be ScannerDetected with the correct barcode.
        final state = container.read(scannerNotifierProvider);
        expect(state, isA<ScannerDetected>());
        expect((state as ScannerDetected).barcode, equals(barcode));
        // Controller must have been told to stop.
        verify(() => mockController.stop()).called(1);
      },
    );

    // TRIANGULATE: debounce — second onBarcodeDetected() when already
    // ScannerDetected is silently ignored (controller.stop not called again).
    test(
      'onBarcodeDetected() is ignored when state is already ScannerDetected',
      () async {
        const barcode = '3017620425035';
        final notifier = container.read(scannerNotifierProvider.notifier);

        // First detection — allowed.
        notifier.onBarcodeDetected(barcode);
        // Second detection — must be ignored.
        notifier.onBarcodeDetected('9999999999999');

        // State must still be the first barcode.
        final state = container.read(scannerNotifierProvider);
        expect(state, isA<ScannerDetected>());
        expect((state as ScannerDetected).barcode, equals(barcode));
        // stop() must have been called exactly once (only for the first detection).
        verify(() => mockController.stop()).called(1);
      },
    );

    // RED → GREEN: reset() transitions back to ScannerIdle
    test('reset() transitions state back to ScannerIdle', () {
      final notifier = container.read(scannerNotifierProvider.notifier);
      notifier.onBarcodeDetected('3017620425035');

      notifier.reset();

      expect(container.read(scannerNotifierProvider), isA<ScannerIdle>());
    });

    // RED → GREEN: toggleTorch() delegates to controller.toggleTorch()
    test('toggleTorch() delegates to controller.toggleTorch()', () async {
      final notifier = container.read(scannerNotifierProvider.notifier);

      notifier.toggleTorch();

      verify(() => mockController.toggleTorch()).called(1);
    });
  });
}
