// NOTE: This test file is the TDD "red" phase.
// Tests WILL NOT compile until `dart run build_runner build` is run (T-16).
// That is intentional — write the spec now, generate the code in T-16.
//
// Spec: CORE-MODELS-001 sc1, sc2 — fromJson/toJson round-trip for UserProfile.

import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/features/profile/domain/user_profile.dart';

const Map<String, dynamic> kUserProfileJson = {
  'id': 'user-001',
  'name': 'María García',
  'email': 'maria@example.com',
  'avatarUrl': 'https://example.com/avatar.jpg',
  'dietaryRestrictions': ['gluten-free', 'dairy-free'],
  'primaryGoal': 'lose_weight',
  'groceryBudget': 150.0,
};

const Map<String, dynamic> kMinimalUserProfileJson = {
  'id': 'user-002',
  'name': 'John Doe',
  'email': 'john@example.com',
  'avatarUrl': null,
  'dietaryRestrictions': <String>[],
  'primaryGoal': null,
  'groceryBudget': null,
};

void main() {
  group('UserProfile', () {
    group('CORE-MODELS-001 sc2 — fromJson', () {
      test('parses all fields correctly', () {
        final profile = UserProfile.fromJson(kUserProfileJson);

        expect(profile.id, equals('user-001'));
        expect(profile.name, equals('María García'));
        expect(profile.email, equals('maria@example.com'));
        expect(profile.avatarUrl, equals('https://example.com/avatar.jpg'));
        expect(profile.dietaryRestrictions, equals(['gluten-free', 'dairy-free']));
        expect(profile.primaryGoal, equals('lose_weight'));
        expect(profile.groceryBudget, equals(150.0));
      });

      test('parses minimal profile with all nullable fields as null', () {
        final profile = UserProfile.fromJson(kMinimalUserProfileJson);

        expect(profile.id, equals('user-002'));
        expect(profile.name, equals('John Doe'));
        expect(profile.email, equals('john@example.com'));
        expect(profile.avatarUrl, isNull);
        expect(profile.dietaryRestrictions, isEmpty);
        expect(profile.primaryGoal, isNull);
        expect(profile.groceryBudget, isNull);
      });

      test('dietaryRestrictions defaults to empty list', () {
        const profile = UserProfile(
          id: 'x',
          name: 'Test',
          email: 'test@example.com',
        );

        expect(profile.dietaryRestrictions, isEmpty);
      });
    });

    group('CORE-MODELS-001 sc1 — toJson', () {
      test('serializes all fields including nullable ones', () {
        const profile = UserProfile(
          id: 'user-001',
          name: 'María García',
          email: 'maria@example.com',
          avatarUrl: 'https://example.com/avatar.jpg',
          dietaryRestrictions: ['gluten-free'],
          primaryGoal: 'lose_weight',
          groceryBudget: 150.0,
        );

        final json = profile.toJson();

        expect(json['id'], equals('user-001'));
        expect(json['name'], equals('María García'));
        expect(json['email'], equals('maria@example.com'));
        expect(json['avatarUrl'], equals('https://example.com/avatar.jpg'));
        expect(json['dietaryRestrictions'], equals(['gluten-free']));
        expect(json['primaryGoal'], equals('lose_weight'));
        expect(json['groceryBudget'], equals(150.0));
      });

      test('serializes null fields', () {
        const profile = UserProfile(
          id: 'x',
          name: 'Test',
          email: 'test@example.com',
        );

        final json = profile.toJson();

        expect(json['avatarUrl'], isNull);
        expect(json['primaryGoal'], isNull);
        expect(json['groceryBudget'], isNull);
      });

      test('round-trip: fromJson → toJson preserves all values', () {
        final original = UserProfile.fromJson(kUserProfileJson);
        final roundTripped = UserProfile.fromJson(original.toJson());

        expect(roundTripped, equals(original));
      });

      test('round-trip preserves empty dietaryRestrictions', () {
        final original = UserProfile.fromJson(kMinimalUserProfileJson);
        final roundTripped = UserProfile.fromJson(original.toJson());

        expect(roundTripped.dietaryRestrictions, isEmpty);
      });

      test('round-trip preserves dietary restrictions list', () {
        final original = UserProfile.fromJson(kUserProfileJson);
        final roundTripped = UserProfile.fromJson(original.toJson());

        expect(roundTripped.dietaryRestrictions, equals(['gluten-free', 'dairy-free']));
      });
    });

    group('UserProfile value equality (Freezed ==)', () {
      test('two profiles with same data are equal', () {
        const p1 = UserProfile(id: 'x', name: 'Alice', email: 'alice@example.com');
        const p2 = UserProfile(id: 'x', name: 'Alice', email: 'alice@example.com');

        expect(p1, equals(p2));
      });

      test('profiles with different emails are not equal', () {
        const p1 = UserProfile(id: 'x', name: 'Alice', email: 'alice1@example.com');
        const p2 = UserProfile(id: 'x', name: 'Alice', email: 'alice2@example.com');

        expect(p1, isNot(equals(p2)));
      });

      test('copyWith updates groceryBudget', () {
        const original = UserProfile(id: 'x', name: 'Alice', email: 'alice@example.com');
        final updated = original.copyWith(groceryBudget: 200.0);

        expect(updated.groceryBudget, equals(200.0));
        expect(updated.name, equals('Alice'));
      });

      test('copyWith adds dietary restrictions', () {
        const original = UserProfile(id: 'x', name: 'Alice', email: 'alice@example.com');
        final updated = original.copyWith(dietaryRestrictions: ['vegan']);

        expect(updated.dietaryRestrictions, equals(['vegan']));
      });
    });
  });
}
