import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/storage/storage_providers.dart';

/// Tests for constants defined in storage_providers.dart — T-11 / AD-08.
///
/// The Riverpod providers (sharedPreferencesProvider, productsBoxProvider, etc.)
/// are NOT tested here — they are override-only and will be exercised in T-14
/// integration tests via ProviderScope overrides.
///
/// This file validates the key-constant contract from OFFLINE-STORAGE-001.
void main() {
  group('storage_providers — SharedPreferences key constants', () {
    test('kOnboardingComplete is "onboarding_complete"', () {
      expect(kOnboardingComplete, 'onboarding_complete');
    });

    test('kLastSync is "last_sync"', () {
      expect(kLastSync, 'last_sync');
    });

    test('constants are distinct (no accidental collision)', () {
      expect(kOnboardingComplete, isNot(equals(kLastSync)));
    });
  });
}
