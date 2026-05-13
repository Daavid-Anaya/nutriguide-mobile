import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Box name constants — single source of truth for Hive box identifiers.
///
/// Use these when opening boxes and when reading from providers.
const String kProductsBox = 'products';
const String kShoppingListsBox = 'shopping_lists';
const String kUserPreferencesBox = 'user_preferences';

/// Initialises Hive and opens all application boxes.
///
/// Must be called from [main()] before [runApp()]:
/// ```dart
/// await initStorage();
/// runApp(...);
/// ```
///
/// Boxes are opened with raw `dynamic` values — no TypeAdapters required at
/// this stage because Freezed models are serialised to/from `Map<String, dynamic>`
/// and stored as JSON maps.
Future<void> initStorage() async {
  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox<dynamic>(kProductsBox),
    Hive.openBox<dynamic>(kShoppingListsBox),
    Hive.openBox<dynamic>(kUserPreferencesBox),
  ]);
}
