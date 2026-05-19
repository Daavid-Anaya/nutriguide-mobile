import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Registers all Hive TypeAdapters for the application.
///
/// **Call order in [main()]:**
/// ```dart
/// await Hive.initFlutter();
/// registerHiveAdapters(); // before openHiveBoxes()
/// await openHiveBoxes();
/// ```
///
/// Adapters will be registered here once Hive CE codegen models are added
/// (hive_ce_generator phase). The body is intentionally empty for now.
void registerHiveAdapters() {
  // Adapters registered here after codegen generates them.
  // Example (generated adapter):
  //   Hive.registerAdapter(ProductHiveAdapter());
}

/// Opens all application Hive boxes concurrently.
///
/// Must be called after [Hive.initFlutter] and [registerHiveAdapters].
/// All three boxes are opened in parallel via [Future.wait] for performance.
///
/// Boxes use raw [dynamic] values — Freezed models are serialised to
/// [Map<String, dynamic>] and stored as JSON maps (no TypeAdapters needed
/// at this stage).
Future<void> openHiveBoxes() async {
  await Future.wait([
    Hive.openBox<dynamic>('products'),
    Hive.openBox<dynamic>('shopping_lists'),
    Hive.openBox<dynamic>('user_preferences'),
    Hive.openBox<dynamic>('meal_plans'),
  ]);
}
