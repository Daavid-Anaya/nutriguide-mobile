// Spec: SCANNER-WIDGET-001 (ScanOverlay requirements)
// Design: AD-17 — full-screen IgnorePointer + CustomPainter dim with transparent window.

import 'package:flutter/material.dart';

/// Full-screen scan overlay drawn on top of the camera preview.
///
/// Renders a semi-transparent black dimming layer ([Colors.black54])
/// everywhere except a centered transparent rectangle (the scan window).
/// Wrapped in [IgnorePointer] so touch events pass through to the camera.
///
/// The scan window defaults to 280×280 logical pixels (spec SCANNER-WIDGET-001).
/// Corner has [scanWindowRadius] px rounding (default 8px).
class ScanOverlay extends StatelessWidget {
  const ScanOverlay({
    super.key,
    this.scanWindowSize = 280,
    this.scanWindowRadius = 8,
  });

  /// Side length of the transparent scan window in logical pixels.
  final double scanWindowSize;

  /// Corner radius of the scan window rectangle.
  final double scanWindowRadius;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ScanOverlayPainter(
          scanWindowSize: scanWindowSize,
          scanWindowRadius: scanWindowRadius,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Paints a semi-transparent black layer with a transparent centered rectangle.
///
/// Uses [PathOperation.difference] to cut the scan window out of the dim layer,
/// leaving it fully transparent. Corner brackets are drawn for visual feedback.
class _ScanOverlayPainter extends CustomPainter {
  const _ScanOverlayPainter({
    required this.scanWindowSize,
    required this.scanWindowRadius,
  });

  final double scanWindowSize;
  final double scanWindowRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final windowRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanWindowSize,
      height: scanWindowSize,
    );

    final rrect = RRect.fromRectAndRadius(
      windowRect,
      Radius.circular(scanWindowRadius),
    );

    // ── Dim layer with transparent scan window (difference path) ──────────
    final dimPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()..addRRect(rrect),
    );

    canvas.drawPath(
      dimPath,
      Paint()..color = Colors.black54,
    );

    // ── White border around the scan window ────────────────────────────────
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // ── Corner bracket accents (visual feedback) ───────────────────────────
    _drawCornerBrackets(canvas, windowRect);
  }

  /// Draws short L-shaped corner brackets at the four corners of [rect].
  void _drawCornerBrackets(Canvas canvas, Rect rect) {
    const bracketLength = 20.0;
    const bracketStroke = 3.0;
    final bracketPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = bracketStroke
      ..strokeCap = StrokeCap.round;

    final corners = [
      // Top-left
      (rect.topLeft, Offset(rect.left + bracketLength, rect.top),
          Offset(rect.left, rect.top + bracketLength)),
      // Top-right
      (rect.topRight, Offset(rect.right - bracketLength, rect.top),
          Offset(rect.right, rect.top + bracketLength)),
      // Bottom-left
      (rect.bottomLeft, Offset(rect.left + bracketLength, rect.bottom),
          Offset(rect.left, rect.bottom - bracketLength)),
      // Bottom-right
      (rect.bottomRight, Offset(rect.right - bracketLength, rect.bottom),
          Offset(rect.right, rect.bottom - bracketLength)),
    ];

    for (final (corner, hEnd, vEnd) in corners) {
      canvas.drawLine(corner, hEnd, bracketPaint);
      canvas.drawLine(corner, vEnd, bracketPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter old) =>
      old.scanWindowSize != scanWindowSize ||
      old.scanWindowRadius != scanWindowRadius;
}
