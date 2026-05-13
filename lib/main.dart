import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nutriguide_mobile/app.dart';
import 'package:nutriguide_mobile/core/storage/hive_registrar.dart';
import 'package:nutriguide_mobile/core/storage/storage_providers.dart';

/// Application entry point.
///
/// Bootstrap order per AD-03:
/// 1. [WidgetsFlutterBinding.ensureInitialized] — Flutter engine is ready
///    before any async work.
/// 2. [Hive.initFlutter] — initialise Hive CE with the Flutter documents dir.
/// 3. [registerHiveAdapters] — register TypeAdapters before opening boxes.
/// 4. [openHiveBoxes] — open all boxes concurrently.
/// 5. [SharedPreferences.getInstance] — pre-load so we can override
///    [sharedPreferencesProvider] synchronously inside [ProviderScope].
/// 6. [runApp] with [ProviderScope] + sync overrides.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Hive init + register adapters + open boxes
  await Hive.initFlutter();
  registerHiveAdapters();
  await openHiveBoxes();

  // 2. SharedPreferences (pre-load for sync override)
  final sharedPrefs = await SharedPreferences.getInstance();

  // 3. Riverpod scope with sync overrides
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: const App(),
    ),
  );
}
