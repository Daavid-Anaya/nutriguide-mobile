// ignore_for_file: comment_references
// Spec: SCANNER-STATE-001 sc1; SCANNER-UI-001 sc3, sc4
// AD-13: ScannerState sealed class + mobileScannerControllerProvider + ScannerNotifier
// Phase 1 (T-01): state classes + controller provider.
// Phase 2 (T-04): ScannerNotifier class added.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// ---------------------------------------------------------------------------
// State — sealed class (AD-13)
// Three variants for exhaustive switch in the UI layer.
// ---------------------------------------------------------------------------

/// Camera state sealed class — exhaustive switch enforced by Dart compiler.
sealed class ScannerState {
  const ScannerState();
}

/// Initial state — camera not yet started.
class ScannerIdle extends ScannerState {
  const ScannerIdle();
}

/// Camera is active and scanning for barcodes.
class ScannerScanning extends ScannerState {
  const ScannerScanning();
}

/// A barcode has been detected. Camera should stop (debounce).
class ScannerDetected extends ScannerState {
  const ScannerDetected(this.barcode);

  /// The raw barcode string returned by MobileScanner.
  final String barcode;
}

// ---------------------------------------------------------------------------
// Provider — MobileScannerController (AD-13)
// Separate provider for testability: tests can override this with a mock
// without needing to mock the entire ScannerNotifier.
// autoStart: false — the screen starts scanning explicitly via startScanning().
// ---------------------------------------------------------------------------

/// Provides a [MobileScannerController] with autoStart disabled.
///
/// Override in tests with [MockMobileScannerController] via
/// [ProviderScope] overrides to avoid native plugin initialization.
final mobileScannerControllerProvider = Provider<MobileScannerController>(
  (ref) {
    final controller = MobileScannerController(autoStart: false);
    ref.onDispose(controller.dispose);
    return controller;
  },
);

// ---------------------------------------------------------------------------
// Notifier — ScannerNotifier (AD-13, T-04)
// Manages camera scan lifecycle: idle → scanning → detected(barcode).
// ---------------------------------------------------------------------------

/// Manages camera scan state transitions.
///
/// - [startScanning]: activates the camera feed.
/// - [onBarcodeDetected]: stops the camera and emits detected barcode.
///   Ignores duplicate detections (debounce — spec SCANNER-UI-001 sc4).
/// - [reset]: returns to idle (called when leaving the scanner screen).
/// - [toggleTorch]: delegates torch toggle to [MobileScannerController].
final scannerNotifierProvider =
    NotifierProvider<ScannerNotifier, ScannerState>(
  ScannerNotifier.new,
);

class ScannerNotifier extends Notifier<ScannerState> {
  @override
  ScannerState build() => const ScannerIdle();

  /// Returns the [MobileScannerController] from its dedicated provider.
  MobileScannerController get _controller =>
      ref.read(mobileScannerControllerProvider);

  /// Starts the camera feed and transitions state to [ScannerScanning].
  void startScanning() {
    _controller.start();
    state = const ScannerScanning();
  }

  /// Called when a barcode is detected by [MobileScanner].
  ///
  /// Stops the camera (native debounce) and transitions to [ScannerDetected].
  /// If the state is already [ScannerDetected], this call is ignored —
  /// preventing double-navigation from rapid consecutive detections.
  void onBarcodeDetected(String barcode) {
    if (state is ScannerDetected) return; // debounce
    _controller.stop();
    state = ScannerDetected(barcode);
  }

  /// Resets state to [ScannerIdle].
  ///
  /// Call this when the user navigates back from the product detail screen.
  void reset() => state = const ScannerIdle();

  /// Toggles the device flashlight via [MobileScannerController].
  void toggleTorch() => _controller.toggleTorch();
}
