import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:nutriguide_mobile/core/storage/hive_registrar.dart';

/// Tests for [registerHiveAdapters] and [openHiveBoxes] — T-11 / AD-08.
///
/// NOTE: [openHiveBoxes] uses [Hive.initFlutter] internally in production;
/// here we call [Hive.init(tempDir)] so that platform channels are not needed.
/// The test exercises the box-open logic via [openHiveBoxes] after seeding
/// [Hive] with a temp path — same approach used in storage_service_test.dart.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_registrar_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('registerHiveAdapters', () {
    test('completes without throwing', () {
      // registerHiveAdapters() has an empty body for now —
      // adapters will be registered here after codegen models are added.
      expect(() => registerHiveAdapters(), returnsNormally);
    });
  });

  group('openHiveBoxes — AD-08', () {
    test('opens "products" box', () async {
      await openHiveBoxes();
      expect(Hive.box<dynamic>('products').isOpen, isTrue);
    });

    test('opens "shopping_lists" box', () async {
      await openHiveBoxes();
      expect(Hive.box<dynamic>('shopping_lists').isOpen, isTrue);
    });

    test('opens "user_preferences" box', () async {
      await openHiveBoxes();
      expect(Hive.box<dynamic>('user_preferences').isOpen, isTrue);
    });

    test('opens all three boxes concurrently without error', () async {
      await openHiveBoxes();

      expect(Hive.box<dynamic>('products').isOpen, isTrue);
      expect(Hive.box<dynamic>('shopping_lists').isOpen, isTrue);
      expect(Hive.box<dynamic>('user_preferences').isOpen, isTrue);
    });
  });
}
