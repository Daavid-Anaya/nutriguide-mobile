import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nutriguide_mobile/app.dart';
import 'package:nutriguide_mobile/core/storage/hive_registrar.dart';
import 'package:nutriguide_mobile/core/storage/storage_providers.dart';

/// Application entry point.
///
/// Bootstrap order per AD-03 (updated for supabase-core):
/// 1. [WidgetsFlutterBinding.ensureInitialized] — Flutter engine is ready
///    before any async work.
/// 2. [dotenv.load] — load environment variables from `.env` asset.
/// 3. Fail-fast validation — throw [StateError] if credentials are missing.
/// 4. [Supabase.initialize] — init Supabase SDK before any other services.
/// 5. [Hive.initFlutter] — initialise Hive CE with the Flutter documents dir.
/// 6. [registerHiveAdapters] — register TypeAdapters before opening boxes.
/// 7. [openHiveBoxes] — open all boxes concurrently.
/// 8. [SharedPreferences.getInstance] — pre-load so we can override
///    [sharedPreferencesProvider] synchronously inside [ProviderScope].
/// 9. [runApp] with [ProviderScope] + sync overrides.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load environment variables — MUST be first async operation
  await dotenv.load(fileName: '.env');

  // 2. Fail-fast if Supabase credentials are missing (SUPABASE-CONFIG-001-S2/S3)
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl == null || supabaseUrl.isEmpty) {
    throw StateError('Missing SUPABASE_URL in .env');
  }
  if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
    throw StateError('Missing SUPABASE_ANON_KEY in .env');
  }

  // 3. Initialize Supabase SDK
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // 4. Hive init + register adapters + open boxes
  await Hive.initFlutter();
  registerHiveAdapters();
  await openHiveBoxes();

  // 5. SharedPreferences (pre-load for sync override)
  final sharedPrefs = await SharedPreferences.getInstance();

  // 6. Riverpod scope with sync overrides
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        productsBoxProvider.overrideWithValue(Hive.box('products')),
        shoppingListsBoxProvider.overrideWithValue(Hive.box('shopping_lists')),
        userPreferencesBoxProvider.overrideWithValue(Hive.box('user_preferences')),
      ],
      child: const App(),
    ),
  );
}
