// Spec: PROFILE-DATA-001 sc1–sc4
// TDD: T-01 [RED] — Tests FAIL until profile_repository_impl.dart is created (T-02).

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/profile/data/profile_repository_impl.dart';
import 'package:nutriguide_mobile/features/profile/domain/user_profile.dart';

void main() {
  late ProfileRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repository = ProfileRepositoryImpl(sharedPreferences: prefs);
  });

  // ---------------------------------------------------------------------------
  // PROFILE-DATA-001 sc1 — Load profile when no data stored returns defaults
  // ---------------------------------------------------------------------------
  group('getProfile', () {
    test('sc1 — returns Right(UserProfile) with defaults when no data stored', () async {
      // SharedPrefs is empty (setMockInitialValues({}))
      final result = await repository.getProfile();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right but got Left'),
        (profile) {
          expect(profile.name, equals('Usuario'));
          expect(profile.avatarUrl, isNull);
        },
      );
    });

    // PROFILE-DATA-001 sc2 — Load profile with stored values
    test('sc2 — returns stored name and avatarUrl when both keys are present', () async {
      SharedPreferences.setMockInitialValues({
        'user_name': 'Ana',
        'user_avatar_url': 'https://example.com/ana.jpg',
      });
      final prefs = await SharedPreferences.getInstance();
      repository = ProfileRepositoryImpl(sharedPreferences: prefs);

      final result = await repository.getProfile();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right but got Left'),
        (profile) {
          expect(profile.name, equals('Ana'));
          expect(profile.avatarUrl, equals('https://example.com/ana.jpg'));
        },
      );
    });
  });

  // ---------------------------------------------------------------------------
  // PROFILE-DATA-001 sc3 — Save profile persists both keys
  // ---------------------------------------------------------------------------
  group('updateProfile', () {
    test('sc3 — persists name to SharedPrefs and returns Right(null)', () async {
      const profile = UserProfile(
        id: '',
        name: 'Carlos',
        email: '',
        avatarUrl: null,
      );

      final result = await repository.updateProfile(profile);

      expect(result.isRight(), isTrue);

      // Verify the value was actually stored
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_name'), equals('Carlos'));
      // avatarUrl is null → key should be absent
      expect(prefs.getString('user_avatar_url'), isNull);
    });

    test('persists avatarUrl when non-null', () async {
      const profile = UserProfile(
        id: '',
        name: 'Lucía',
        email: '',
        avatarUrl: 'https://example.com/lucia.jpg',
      );

      final result = await repository.updateProfile(profile);

      expect(result.isRight(), isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_name'), equals('Lucía'));
      expect(prefs.getString('user_avatar_url'), equals('https://example.com/lucia.jpg'));
    });
  });

  // ---------------------------------------------------------------------------
  // PROFILE-PERSIST-001 sc1–sc4 — grocery_budget persistence (T-01)
  // ---------------------------------------------------------------------------
  group('grocery_budget persistence', () {
    test('saves groceryBudget to SharedPreferences', () async {
      const profile = UserProfile(
        id: '',
        name: 'Ana',
        email: '',
        groceryBudget: 350.0,
      );

      await repository.updateProfile(profile);
      final result = await repository.getProfile();

      result.fold(
        (_) => fail('Expected Right but got Left'),
        (loaded) => expect(loaded.groceryBudget, equals(350.0)),
      );
    });

    test('loads null groceryBudget when key absent', () async {
      // Fresh prefs (setMockInitialValues({}) in setUp)
      final result = await repository.getProfile();

      result.fold(
        (_) => fail('Expected Right but got Left'),
        (profile) => expect(profile.groceryBudget, isNull),
      );
    });

    test('removes groceryBudget key when null is passed', () async {
      // Save 350.0 first
      await repository.updateProfile(const UserProfile(
        id: '',
        name: 'Ana',
        email: '',
        groceryBudget: 350.0,
      ));
      // Now update with null budget
      await repository.updateProfile(const UserProfile(
        id: '',
        name: 'Ana',
        email: '',
        groceryBudget: null,
      ));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('grocery_budget'), isNull);
    });

    test('preserves existing name/avatarUrl when updating groceryBudget', () async {
      // Save name + avatarUrl first
      await repository.updateProfile(const UserProfile(
        id: '',
        name: 'Ana',
        email: '',
        avatarUrl: 'https://example.com/ana.jpg',
      ));
      // Now update with same profile + new budget
      await repository.updateProfile(const UserProfile(
        id: '',
        name: 'Ana',
        email: '',
        avatarUrl: 'https://example.com/ana.jpg',
        groceryBudget: 350.0,
      ));
      final result = await repository.getProfile();

      result.fold(
        (_) => fail('Expected Right but got Left'),
        (profile) {
          expect(profile.name, equals('Ana'));
          expect(profile.avatarUrl, equals('https://example.com/ana.jpg'));
          expect(profile.groceryBudget, equals(350.0));
        },
      );
    });
  });

  // ---------------------------------------------------------------------------
  // PROFILE-DATA-001 sc4 — CacheFailure on SharedPreferences error
  // Uses a fake SharedPreferences implementation that always throws.
  // ---------------------------------------------------------------------------
  group('CacheFailure wrapping', () {
    test('sc4 — getProfile returns Left(CacheFailure) on exception', () async {
      final prefs = _ThrowingSharedPreferences();
      final throwingRepo = ProfileRepositoryImpl(sharedPreferences: prefs);

      final result = await throwingRepo.getProfile();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('Expected Left but got Right'),
      );
    });

    test('sc4 — updateProfile returns Left(CacheFailure) on exception', () async {
      final prefs = _ThrowingSharedPreferences();
      final throwingRepo = ProfileRepositoryImpl(sharedPreferences: prefs);
      const profile = UserProfile(id: '', name: 'Test', email: '');

      final result = await throwingRepo.updateProfile(profile);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('Expected Left but got Right'),
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Test helper: fake SharedPreferences that always throws
// Used to force CacheFailure path in ProfileRepositoryImpl.
// ---------------------------------------------------------------------------
class _ThrowingSharedPreferences implements SharedPreferences {
  @override
  String? getString(String key) => throw Exception('SharedPreferences error');

  @override
  Future<bool> setString(String key, String value) =>
      throw Exception('SharedPreferences error');

  @override
  Future<bool> remove(String key) => throw Exception('SharedPreferences error');

  // Unused in tests — minimal stubs below
  @override
  Set<String> getKeys() => {};
  @override
  Object? get(String key) => null;
  @override
  bool? getBool(String key) => null;
  @override
  int? getInt(String key) => null;
  @override
  double? getDouble(String key) => null;
  @override
  List<String>? getStringList(String key) => null;
  @override
  Future<bool> setBool(String key, bool value) async => true;
  @override
  Future<bool> setInt(String key, int value) async => true;
  @override
  Future<bool> setDouble(String key, double value) async => true;
  @override
  Future<bool> setStringList(String key, List<String> value) async => true;
  @override
  bool containsKey(String key) => false;
  @override
  Future<bool> clear() async => true;
  @override
  Future<void> reload() async {}
  @override
  Future<bool> commit() async => true;
}
