/// Route path constants for the NutriGuide navigation system.
///
/// All route paths are defined here to provide a single source of truth.
/// Use these constants in [AppRouter] and in any code that performs
/// programmatic navigation via GoRouter.
///
/// Spec: NAVIGATION-001
abstract final class Routes {
  /// Home tab — the main dashboard screen.
  static const home = '/';

  /// Scanner tab root.
  static const scanner = '/scanner';

  /// Nested product detail route under scanner.
  /// The `:barcode` path parameter holds the EAN/UPC barcode string.
  static const scannerProduct = '/scanner/product/:barcode';

  /// Shopping lists tab.
  static const lists = '/lists';

  /// User profile tab.
  static const profile = '/profile';

  /// Login screen (outside the shell navigation).
  static const login = '/login';

  /// Registration screen (outside the shell navigation).
  static const register = '/register';

  /// Meal plan weekly view (outside the shell navigation — full-screen push).
  /// Spec: HOME-INTEGRATION-001 | Design: AD-78, AD-79.
  static const mealPlan = '/meal-plan';

  /// Meal plan daily detail view.
  /// The `:date` path parameter holds an ISO8601 date string (e.g. '2026-05-18').
  /// Spec: MEAL-UI-005 | Design: AD-78.
  static const mealPlanDay = '/meal-plan/:date';
}
