// NOTE: This test file is the TDD "red" phase.
// Tests WILL NOT compile until `dart run build_runner build` is run (T-16).
// That is intentional — write the spec now, generate the code in T-16.
//
// Spec: CORE-MODELS-001 sc1, sc2 — fromJson/toJson round-trip for Product and NutritionalInfo.
// The JSON structure mirrors the Open Food Facts API v2 response for a product.

import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/features/scanner/domain/nutritional_info.dart';
import 'package:nutriguide_mobile/features/scanner/domain/product.dart';

/// Minimal Open Food Facts API v2 product response for Nutella (3017620425035).
/// Only the fields mapped in [Product] and [NutritionalInfo] are included.
const Map<String, dynamic> kNutellaJson = {
  'id': '3017620425035',
  'barcode': '3017620425035',
  'name': 'Nutella',
  'brands': 'Ferrero',
  'imageUrl': 'https://images.openfoodfacts.org/images/products/301/762/042/5035/front_en.jpg',
  'nutriscoreGrade': 'e',
  'nutriments': {
    'energy': 2252.0,
    'fat': 30.9,
    'saturatedFat': 10.6,
    'carbohydrates': 57.5,
    'sugars': 56.3,
    'proteins': 6.3,
    'salt': 0.107,
    'fiber': null,
  },
};

/// Product with all nullable fields set to null (minimal valid product).
const Map<String, dynamic> kMinimalProductJson = {
  'id': null,
  'barcode': '1234567890123',
  'name': 'Generic Product',
  'brands': null,
  'imageUrl': null,
  'nutriscoreGrade': null,
  'nutriments': null,
};

/// NutritionalInfo with all fields null (incomplete OFF data).
const Map<String, dynamic> kEmptyNutrimentsJson = {
  'energy': null,
  'fat': null,
  'saturatedFat': null,
  'carbohydrates': null,
  'sugars': null,
  'proteins': null,
  'salt': null,
  'fiber': null,
};

void main() {
  group('NutritionalInfo', () {
    group('CORE-MODELS-001 sc2 — fromJson', () {
      test('parses all numeric fields correctly', () {
        final nutriments = NutritionalInfo.fromJson({
          'energy': 2252.0,
          'fat': 30.9,
          'saturatedFat': 10.6,
          'carbohydrates': 57.5,
          'sugars': 56.3,
          'proteins': 6.3,
          'salt': 0.107,
          'fiber': 3.5,
        });

        expect(nutriments.energy, equals(2252.0));
        expect(nutriments.fat, equals(30.9));
        expect(nutriments.saturatedFat, equals(10.6));
        expect(nutriments.carbohydrates, equals(57.5));
        expect(nutriments.sugars, equals(56.3));
        expect(nutriments.proteins, equals(6.3));
        expect(nutriments.salt, equals(0.107));
        expect(nutriments.fiber, equals(3.5));
      });

      test('parses all fields as null when data is missing (incomplete OFF data)', () {
        final nutriments = NutritionalInfo.fromJson(kEmptyNutrimentsJson);

        expect(nutriments.energy, isNull);
        expect(nutriments.fat, isNull);
        expect(nutriments.saturatedFat, isNull);
        expect(nutriments.carbohydrates, isNull);
        expect(nutriments.sugars, isNull);
        expect(nutriments.proteins, isNull);
        expect(nutriments.salt, isNull);
        expect(nutriments.fiber, isNull);
      });

      test('parses partial data — some fields present, some null', () {
        final nutriments = NutritionalInfo.fromJson({
          'energy': 1600.0,
          'fat': null,
          'saturatedFat': null,
          'carbohydrates': 40.0,
          'sugars': null,
          'proteins': 8.0,
          'salt': null,
          'fiber': null,
        });

        expect(nutriments.energy, equals(1600.0));
        expect(nutriments.fat, isNull);
        expect(nutriments.carbohydrates, equals(40.0));
        expect(nutriments.proteins, equals(8.0));
      });
    });

    group('CORE-MODELS-001 sc1 — toJson', () {
      test('serializes all fields including nulls', () {
        const nutriments = NutritionalInfo(
          energy: 2252.0,
          fat: 30.9,
          saturatedFat: 10.6,
          carbohydrates: 57.5,
          sugars: 56.3,
          proteins: 6.3,
          salt: 0.107,
          fiber: null,
        );

        final json = nutriments.toJson();

        expect(json['energy'], equals(2252.0));
        expect(json['fat'], equals(30.9));
        expect(json['saturatedFat'], equals(10.6));
        expect(json['carbohydrates'], equals(57.5));
        expect(json['sugars'], equals(56.3));
        expect(json['proteins'], equals(6.3));
        expect(json['salt'], equals(0.107));
        expect(json['fiber'], isNull);
      });

      test('round-trip: fromJson → toJson preserves all values', () {
        final original = NutritionalInfo.fromJson({
          'energy': 500.0,
          'fat': 20.0,
          'saturatedFat': 5.0,
          'carbohydrates': 60.0,
          'sugars': 30.0,
          'proteins': 10.0,
          'salt': 1.5,
          'fiber': 2.0,
        });

        final roundTripped = NutritionalInfo.fromJson(original.toJson());

        expect(roundTripped, equals(original));
      });
    });
  });

  group('Product', () {
    group('CORE-MODELS-001 sc2 — fromJson with Open Food Facts structure', () {
      test('parses full product with all fields set', () {
        final product = Product.fromJson(kNutellaJson);

        expect(product.id, equals('3017620425035'));
        expect(product.barcode, equals('3017620425035'));
        expect(product.name, equals('Nutella'));
        expect(product.brands, equals('Ferrero'));
        expect(product.imageUrl, contains('openfoodfacts.org'));
        expect(product.nutriscoreGrade, equals('e'));
        expect(product.nutriments, isNotNull);
        expect(product.nutriments!.energy, equals(2252.0));
        expect(product.nutriments!.fat, equals(30.9));
      });

      test('parses product with null id (OFF product without assigned id)', () {
        final product = Product.fromJson(kMinimalProductJson);

        expect(product.id, isNull);
        expect(product.barcode, equals('1234567890123'));
        expect(product.name, equals('Generic Product'));
        expect(product.brands, isNull);
        expect(product.imageUrl, isNull);
        expect(product.nutriscoreGrade, isNull);
        expect(product.nutriments, isNull);
      });

      test('parses product with nested null nutriments', () {
        final product = Product.fromJson({
          ...kMinimalProductJson,
          'nutriments': kEmptyNutrimentsJson,
        });

        expect(product.nutriments, isNotNull);
        expect(product.nutriments!.energy, isNull);
        expect(product.nutriments!.proteins, isNull);
      });
    });

    group('CORE-MODELS-001 sc1 — toJson', () {
      test('serializes required fields correctly', () {
        const product = Product(
          barcode: '3017620425035',
          name: 'Nutella',
        );

        final json = product.toJson();

        expect(json['barcode'], equals('3017620425035'));
        expect(json['name'], equals('Nutella'));
        expect(json.containsKey('id'), isTrue);
        expect(json.containsKey('brands'), isTrue);
        expect(json.containsKey('imageUrl'), isTrue);
        expect(json.containsKey('nutriscoreGrade'), isTrue);
        expect(json.containsKey('nutriments'), isTrue);
      });

      test('serializes nested NutritionalInfo', () {
        const product = Product(
          barcode: '123',
          name: 'Test',
          nutriments: NutritionalInfo(energy: 200.0, proteins: 5.0),
        );

        final json = product.toJson();
        final nutrimentsJson = json['nutriments'] as Map<String, dynamic>;

        expect(nutrimentsJson['energy'], equals(200.0));
        expect(nutrimentsJson['proteins'], equals(5.0));
      });

      test('round-trip: fromJson → toJson preserves all values', () {
        final original = Product.fromJson(kNutellaJson);
        final roundTripped = Product.fromJson(original.toJson());

        expect(roundTripped, equals(original));
      });
    });

    group('Product value equality (Freezed ==)', () {
      test('two products with same data are equal', () {
        const p1 = Product(barcode: '123', name: 'Apple');
        const p2 = Product(barcode: '123', name: 'Apple');

        expect(p1, equals(p2));
      });

      test('products with different barcodes are not equal', () {
        const p1 = Product(barcode: '111', name: 'Apple');
        const p2 = Product(barcode: '222', name: 'Apple');

        expect(p1, isNot(equals(p2)));
      });

      test('copyWith produces updated product', () {
        const original = Product(barcode: '123', name: 'Apple');
        final updated = original.copyWith(name: 'Green Apple');

        expect(updated.barcode, equals('123'));
        expect(updated.name, equals('Green Apple'));
      });
    });
  });
}
