import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:nutriguide_mobile/core/storage/storage_service.dart';

/// Tests for storage initialisation — OFFLINE-STORAGE-001 sc1.
///
/// NOTE: Tests use [Hive.init(tempDir)] (not [Hive.initFlutter]) because
/// Flutter platform channels are unavailable in unit tests.
/// [initStorage()] uses [Hive.initFlutter] which is the production path;
/// the test environment exercises the same box-open logic via a temp path.
void main() {
  late Directory tempDir;

  setUp(() async {
    // Create a fresh temp directory for each test so Hive state is isolated.
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    // Close all boxes and delete the temp directory.
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Storage service — box names', () {
    test('kProductsBox constant is "products"', () {
      expect(kProductsBox, 'products');
    });

    test('kShoppingListsBox constant is "shopping_lists"', () {
      expect(kShoppingListsBox, 'shopping_lists');
    });

    test('kUserPreferencesBox constant is "user_preferences"', () {
      expect(kUserPreferencesBox, 'user_preferences');
    });
  });

  // OFFLINE-STORAGE-001 sc1: "Hive boxes open on first launch"
  group('OFFLINE-STORAGE-001 sc1 — Hive boxes open on first launch', () {
    test('products box opens without error', () async {
      final box = await Hive.openBox<dynamic>(kProductsBox);
      expect(box.isOpen, isTrue);
    });

    test('shopping_lists box opens without error', () async {
      final box = await Hive.openBox<dynamic>(kShoppingListsBox);
      expect(box.isOpen, isTrue);
    });

    test('user_preferences box opens without error', () async {
      final box = await Hive.openBox<dynamic>(kUserPreferencesBox);
      expect(box.isOpen, isTrue);
    });

    test('all three boxes open concurrently without error', () async {
      await Future.wait([
        Hive.openBox<dynamic>(kProductsBox),
        Hive.openBox<dynamic>(kShoppingListsBox),
        Hive.openBox<dynamic>(kUserPreferencesBox),
      ]);

      expect(Hive.box<dynamic>(kProductsBox).isOpen, isTrue);
      expect(Hive.box<dynamic>(kShoppingListsBox).isOpen, isTrue);
      expect(Hive.box<dynamic>(kUserPreferencesBox).isOpen, isTrue);
    });
  });

  group('Storage service — boxes are writable', () {
    test('products box accepts dynamic write and read-back', () async {
      final box = await Hive.openBox<dynamic>(kProductsBox);

      final product = {
        'barcode': '3017620425035',
        'name': 'Nutella',
        'brands': 'Ferrero',
      };

      await box.put('3017620425035', product);

      final retrieved = box.get('3017620425035') as Map?;
      expect(retrieved, isNotNull);
      expect(retrieved!['name'], 'Nutella');
    });

    test('shopping_lists box accepts dynamic write and read-back', () async {
      final box = await Hive.openBox<dynamic>(kShoppingListsBox);

      final list = {
        'id': 'list-001',
        'name': 'Supermercado',
        'items': [],
      };

      await box.put('list-001', list);

      final retrieved = box.get('list-001') as Map?;
      expect(retrieved, isNotNull);
      expect(retrieved!['name'], 'Supermercado');
    });

    test('user_preferences box accepts dynamic write and read-back', () async {
      final box = await Hive.openBox<dynamic>(kUserPreferencesBox);

      await box.put('theme', 'light');

      expect(box.get('theme'), 'light');
    });

    test('products box survives close and reopen (persistence check)', () async {
      final box = await Hive.openBox<dynamic>(kProductsBox);
      await box.put('persist-key', 'persist-value');
      await box.close();

      // Reopen and verify the data is still there.
      final reopened = await Hive.openBox<dynamic>(kProductsBox);
      expect(reopened.get('persist-key'), 'persist-value');
    });

    test('box.delete() removes a previously written entry', () async {
      final box = await Hive.openBox<dynamic>(kProductsBox);
      await box.put('to-delete', 'data');
      expect(box.get('to-delete'), 'data');

      await box.delete('to-delete');
      expect(box.get('to-delete'), isNull);
    });
  });

  group('Storage service — box is empty on first open', () {
    test('products box is empty on fresh open', () async {
      final box = await Hive.openBox<dynamic>(kProductsBox);
      expect(box.isEmpty, isTrue);
    });

    test('shopping_lists box is empty on fresh open', () async {
      final box = await Hive.openBox<dynamic>(kShoppingListsBox);
      expect(box.isEmpty, isTrue);
    });
  });
}
