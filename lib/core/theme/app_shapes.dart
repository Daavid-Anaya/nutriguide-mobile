import 'package:flutter/material.dart';

/// Border radius constants from DESIGN.md — "Organic Geometric" shape language.
///
/// | Token          | Value | Usage                                          |
/// |---------------|-------|------------------------------------------------|
/// | smallRadius   | 4     | Tight UI elements (badges, tags)               |
/// | buttonRadius  | 8     | Buttons and inputs (rounded-md)                |
/// | containerRadius| 16   | Cards, sections, image containers (rounded-xl) |
/// | largeRadius   | 24    | Modals, bottom sheets (rounded-2xl)            |
/// | chipRadius    | 100   | Chips, search bars, filters (pill)             |
abstract final class AppShapes {
  /// 4px — small elements, badges (rounded-sm)
  static final BorderRadius smallRadius = BorderRadius.circular(4);

  /// 8px — buttons and inputs (rounded-md per DESIGN.md "base radius")
  static final BorderRadius buttonRadius = BorderRadius.circular(8);

  /// 16px — cards, sections, image containers (rounded-xl per DESIGN.md)
  static final BorderRadius containerRadius = BorderRadius.circular(16);

  /// 24px — large containers, modals (rounded-2xl)
  static final BorderRadius largeRadius = BorderRadius.circular(24);

  /// 100px — chips, search bars (pill per DESIGN.md)
  static final BorderRadius chipRadius = BorderRadius.circular(100);

  // ── Convenience Radius values (for ClipRRect, decoration etc.) ────────────

  /// 4px as [Radius] — use in [RoundedRectangleBorder]
  static const Radius small = Radius.circular(4);

  /// 8px as [Radius]
  static const Radius button = Radius.circular(8);

  /// 16px as [Radius]
  static const Radius container = Radius.circular(16);

  /// 24px as [Radius]
  static const Radius large = Radius.circular(24);

  /// 100px as [Radius]
  static const Radius chip = Radius.circular(100);
}
