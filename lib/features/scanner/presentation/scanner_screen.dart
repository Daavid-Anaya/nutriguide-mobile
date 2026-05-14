// Spec: SCANNER-UI-001 sc1, sc2, sc3, sc4
// AD-15: Full-screen MobileScanner with ScanOverlay, torch toggle, and
//        permission-denied error state. No NutriAppBar — camera is fullscreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nutriguide_mobile/features/scanner/presentation/providers/scanner_notifier.dart';
import 'package:nutriguide_mobile/features/scanner/presentation/widgets/scan_overlay.dart';

// ---------------------------------------------------------------------------
// ScannerScreen
// ---------------------------------------------------------------------------

/// Full-screen barcode scanner screen.
///
/// - No [AppBar] — camera preview is full screen (spec SCANNER-UI-001).
/// - Renders [ScanOverlay] on top of the camera preview.
/// - Torch toggle [IconButton] in the top-right corner.
/// - Navigates to `/scanner/product/:barcode` on first valid detection.
/// - On camera permission denied, renders [ScannerPermissionDeniedBody].
class ScannerScreen extends ConsumerWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(scannerNotifierProvider.notifier);
    final controller = ref.watch(mobileScannerControllerProvider);

    // Navigate on detection (spec sc1) — then reset so back-nav works.
    ref.listen<ScannerState>(scannerNotifierProvider, (prev, next) {
      if (next is ScannerDetected) {
        context.push('/scanner/product/${next.barcode}');
        notifier.reset();
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera preview ──────────────────────────────────────────────
          MobileScanner(
            controller: controller,
            onDetect: (BarcodeCapture capture) {
              final barcode = capture.barcodes.firstOrNull?.rawValue;
              if (barcode != null) {
                notifier.onBarcodeDetected(barcode);
              }
            },
            // Spec sc2: permission denied → show error body.
            errorBuilder: (context, error, child) {
              return const ScannerPermissionDeniedBody();
            },
          ),

          // ── Scan window overlay ─────────────────────────────────────────
          const ScanOverlay(),

          // ── Torch toggle ────────────────────────────────────────────────
          // AD-15: top-right position, outside SafeArea padding.
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: ValueListenableBuilder<MobileScannerState>(
                valueListenable: controller,
                builder: (context, scannerState, _) {
                  return ScannerTorchButton(
                    torchState: scannerState.torchState,
                    onTap: () => notifier.toggleTorch(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ScannerPermissionDeniedBody
// Extracted as a public widget so it can be tested without MobileScanner.
// ---------------------------------------------------------------------------

/// Shown inside [MobileScanner.errorBuilder] when camera permission is denied.
///
/// Public so widget tests can instantiate it directly without triggering the
/// native MobileScanner plugin.
///
/// Spec: SCANNER-UI-001 sc2
class ScannerPermissionDeniedBody extends StatelessWidget {
  const ScannerPermissionDeniedBody({
    super.key,
    this.onOpenSettings,
  });

  /// Called when the user taps "Abrir configuración".
  ///
  /// Defaults to a no-op. Override in tests to verify the callback is invoked.
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Se necesita acceso a la cámara',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Permita el acceso a la cámara para escanear productos.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onOpenSettings ?? () {},
              child: const Text('Abrir configuración'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ScannerTorchButton
// Extracted as a public widget so torch icon logic can be tested without
// instantiating MobileScanner.
// ---------------------------------------------------------------------------

/// Torch toggle [IconButton] that shows flash_on / flash_off based on state.
///
/// Public for testability. Rendered in the top-right of [ScannerScreen].
///
/// Spec: SCANNER-UI-001 sc3
class ScannerTorchButton extends StatelessWidget {
  const ScannerTorchButton({
    super.key,
    required this.torchState,
    required this.onTap,
  });

  /// Current torch state from [MobileScannerController.value.torchState].
  final TorchState torchState;

  /// Called when the user taps the torch button.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isOn = torchState == TorchState.on;

    return IconButton(
      icon: Icon(
        isOn ? Icons.flash_on : Icons.flash_off,
        color: Colors.white,
      ),
      tooltip: isOn ? 'Apagar linterna' : 'Encender linterna',
      onPressed: onTap,
    );
  }
}
