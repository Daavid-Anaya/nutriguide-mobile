// Spec: BUGFIX-001 sc1 — All Hive box providers accessible after app launch
// TDD note: T-1.1 [RED] — Tests FAIL until main.dart is patched (T-1.2).
// Tests verify that ProviderScope overrides wire the opened Hive boxes so that
// no provider throws UnimplementedError when read.

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:nutriguide_mobile/core/storage/storage_providers.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('main_hive_overrides_test_');
    Hive.init(tempDir.path);

    // Open all three boxes — mirrors what openHiveBoxes() does in main.dart
    await Future.wait([
      Hive.openBox<dynamic>('products'),
      Hive.openBox<dynamic>('shopping_lists'),
      Hive.openBox<dynamic>('user_preferences'),
    ]);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  // ---------------------------------------------------------------------------
  // Helper: build a ProviderContainer with the same overrides as main.dart
  // after the fix (T-1.2).
  // ---------------------------------------------------------------------------
  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [
        productsBoxProvider.overrideWithValue(Hive.box('products')),
        shoppingListsBoxProvider.overrideWithValue(Hive.box('shopping_lists')),
        userPreferencesBoxProvider.overrideWithValue(Hive.box('user_preferences')),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // BUGFIX-001 sc1 — All Hive box providers accessible after app launch
  // ---------------------------------------------------------------------------
  group('BUGFIX-001 sc1 — Hive box providers accessible via ProviderScope overrides', () {
    test('productsBoxProvider does not throw UnimplementedError when overridden', () {
      final container = buildContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(productsBoxProvider),
        returnsNormally,
      );
    });

    test('shoppingListsBoxProvider does not throw UnimplementedError when overridden', () {
      final container = buildContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(shoppingListsBoxProvider),
        returnsNormally,
      );
    });

    test('userPreferencesBoxProvider does not throw UnimplementedError when overridden', () {
      final container = buildContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(userPreferencesBoxProvider),
        returnsNormally,
      );
    });

    test('productsBoxProvider returns the opened Box<dynamic>("products")', () {
      final container = buildContainer();
      addTearDown(container.dispose);

      final box = container.read(productsBoxProvider);
      expect(box.name, equals('products'));
      expect(box.isOpen, isTrue);
    });

    test('shoppingListsBoxProvider returns the opened Box<dynamic>("shopping_lists")', () {
      final container = buildContainer();
      addTearDown(container.dispose);

      final box = container.read(shoppingListsBoxProvider);
      expect(box.name, equals('shopping_lists'));
      expect(box.isOpen, isTrue);
    });

    test('userPreferencesBoxProvider returns the opened Box<dynamic>("user_preferences")', () {
      final container = buildContainer();
      addTearDown(container.dispose);

      final box = container.read(userPreferencesBoxProvider);
      expect(box.name, equals('user_preferences'));
      expect(box.isOpen, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // BUGFIX-001 sc2 (negative) — Missing override causes ProviderException
  // (Riverpod 3 wraps the UnimplementedError inside a ProviderException)
  // ---------------------------------------------------------------------------
  group('BUGFIX-001 sc2 — Missing override throws (regression guard)', () {
    test('productsBoxProvider throws when NOT overridden', () {
      // Container with NO overrides — simulates the pre-fix state of main.dart
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Riverpod 3 wraps provider build errors in a ProviderException
      expect(
        () => container.read(productsBoxProvider),
        throwsA(
          predicate<Object>((e) =>
              e is ProviderException &&
              e.exception is UnimplementedError),
        ),
      );
    });

    test('shoppingListsBoxProvider throws when NOT overridden', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(shoppingListsBoxProvider),
        throwsA(
          predicate<Object>((e) =>
              e is ProviderException &&
              e.exception is UnimplementedError),
        ),
      );
    });

    test('userPreferencesBoxProvider throws when NOT overridden', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(userPreferencesBoxProvider),
        throwsA(
          predicate<Object>((e) =>
              e is ProviderException &&
              e.exception is UnimplementedError),
        ),
      );
    });
  });
}
