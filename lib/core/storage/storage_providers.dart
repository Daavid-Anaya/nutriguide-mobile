import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// SharedPreferences key constants
// ---------------------------------------------------------------------------

/// Persists whether the user has completed the onboarding flow.
const String kOnboardingComplete = 'onboarding_complete';

/// ISO-8601 timestamp of the last successful server sync.
const String kLastSync = 'last_sync';

// ---------------------------------------------------------------------------
// Providers
//
// These use the "override" pattern: each provider throws [UnimplementedError]
// by default and MUST be overridden in the root [ProviderScope] inside
// main.dart with the real instance obtained during bootstrap.
//
// Example in main.dart:
// ```dart
// final sharedPrefs = await SharedPreferences.getInstance();
// await initStorage();
// runApp(
//   ProviderScope(
//     overrides: [
//       sharedPreferencesProvider.overrideWithValue(sharedPrefs),
//       productsBoxProvider.overrideWithValue(Hive.box(kProductsBox)),
//       shoppingListsBoxProvider.overrideWithValue(Hive.box(kShoppingListsBox)),
//       userPreferencesBoxProvider.overrideWithValue(Hive.box(kUserPreferencesBox)),
//     ],
//     child: const App(),
//   ),
// );
// ```
// ---------------------------------------------------------------------------

/// Provides the [SharedPreferences] instance.
///
/// Override in [ProviderScope] with the pre-loaded instance before [runApp].
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope. '
    'Call SharedPreferences.getInstance() in main() and override before runApp().',
  ),
);

/// Provides the Hive box used to cache scanned products.
///
/// Override in [ProviderScope] after [initStorage()] has been called.
final productsBoxProvider = Provider<Box<dynamic>>(
  (ref) => throw UnimplementedError(
    'productsBoxProvider must be overridden in ProviderScope. '
    'Call initStorage() in main() and override before runApp().',
  ),
);

/// Provides the Hive box used for offline-first shopping lists.
///
/// Override in [ProviderScope] after [initStorage()] has been called.
final shoppingListsBoxProvider = Provider<Box<dynamic>>(
  (ref) => throw UnimplementedError(
    'shoppingListsBoxProvider must be overridden in ProviderScope. '
    'Call initStorage() in main() and override before runApp().',
  ),
);

/// Provides the Hive box used for user preference data.
///
/// Override in [ProviderScope] after [initStorage()] has been called.
final userPreferencesBoxProvider = Provider<Box<dynamic>>(
  (ref) => throw UnimplementedError(
    'userPreferencesBoxProvider must be overridden in ProviderScope. '
    'Call initStorage() in main() and override before runApp().',
  ),
);
