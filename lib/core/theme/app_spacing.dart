/// Spacing constants from DESIGN.md — 4px base unit.
///
/// Usage: always prefer [AppSpacing] constants over magic numbers.
/// Widgets consume via [context.spacing] extension or directly.
///
/// Design token reference:
///   xs=4, sm=8, md=16, lg=24, xl=40, xxl=64
abstract final class AppSpacing {
  /// 4px — micro gap, icon padding
  static const double xs = 4;

  /// 8px — tight spacing between related elements
  static const double sm = 8;

  /// 16px — standard internal padding (cards, inputs)
  static const double md = 16;

  /// 24px — section breathing room; minimum card internal padding
  static const double lg = 24;

  /// 40px — large gap between distinct UI blocks
  static const double xl = 40;

  /// 64px — premium section separator; heroic whitespace
  static const double xxl = 64;
}
