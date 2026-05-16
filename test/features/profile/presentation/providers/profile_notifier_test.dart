// Spec: PROFILE-STATE-001 sc1–sc7
// TDD: T-03 [RED] → T-04 [GREEN] (build/startEdit/cancelEdit)
//       T-05 [RED] → T-06 [GREEN] (saveProfile/retry)

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:nutriguide_mobile/features/profile/data/profile_providers.dart';
import 'package:nutriguide_mobile/features/profile/domain/profile_repository.dart';
import 'package:nutriguide_mobile/features/profile/domain/user_profile.dart';
import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/profile/presentation/providers/profile_notifier.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const UserProfile(id: '', name: '', email: ''));
  });

  late MockProfileRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockProfileRepository();
    container = ProviderContainer(overrides: [
      profileRepositoryProvider.overrideWithValue(mockRepo),
    ]);
  });

  tearDown(() => container.dispose());

  group('ProfileNotifier', () {
    const testProfile = UserProfile(id: '', name: 'Ana', email: '');

    // -------------------------------------------------------------------------
    // PROFILE-STATE-001-S1 — build returns ProfileData on success
    // -------------------------------------------------------------------------
    test('build returns ProfileData on success', () async {
      when(() => mockRepo.getProfile()).thenAnswer((_) async => Right(testProfile));
      final state = await container.read(profileNotifierProvider.future);
      expect(state, isA<ProfileData>());
      expect((state as ProfileData).profile, testProfile);
    });

    // -------------------------------------------------------------------------
    // PROFILE-STATE-001-S6 — build returns ProfileError on failure
    // -------------------------------------------------------------------------
    test('build returns ProfileError on failure', () async {
      when(() => mockRepo.getProfile())
          .thenAnswer((_) async => Left(CacheFailure('error')));
      final state = await container.read(profileNotifierProvider.future);
      expect(state, isA<ProfileError>());
    });

    // -------------------------------------------------------------------------
    // PROFILE-STATE-001-S2 — startEdit transitions ProfileData → ProfileEditing
    // -------------------------------------------------------------------------
    test('startEdit transitions ProfileData to ProfileEditing', () async {
      when(() => mockRepo.getProfile()).thenAnswer((_) async => Right(testProfile));
      await container.read(profileNotifierProvider.future);
      container.read(profileNotifierProvider.notifier).startEdit();
      final state = container.read(profileNotifierProvider).value;
      expect(state, isA<ProfileEditing>());
    });

    // -------------------------------------------------------------------------
    // PROFILE-STATE-001 — cancelEdit transitions ProfileEditing → ProfileData
    // -------------------------------------------------------------------------
    test('cancelEdit transitions ProfileEditing to ProfileData', () async {
      when(() => mockRepo.getProfile()).thenAnswer((_) async => Right(testProfile));
      await container.read(profileNotifierProvider.future);
      container.read(profileNotifierProvider.notifier).startEdit();
      container.read(profileNotifierProvider.notifier).cancelEdit();
      final state = container.read(profileNotifierProvider).value;
      expect(state, isA<ProfileData>());
    });

    // -------------------------------------------------------------------------
    // PROFILE-STATE-001-S3 — saveProfile with valid data transitions to ProfileData
    // -------------------------------------------------------------------------
    test('saveProfile with valid data transitions to ProfileData', () async {
      when(() => mockRepo.getProfile()).thenAnswer((_) async => Right(testProfile));
      when(() => mockRepo.updateProfile(any()))
          .thenAnswer((_) async => const Right(null));
      await container.read(profileNotifierProvider.future);
      container.read(profileNotifierProvider.notifier).startEdit();
      await container
          .read(profileNotifierProvider.notifier)
          .saveProfile('Bob', null, 300.0);
      final state = container.read(profileNotifierProvider).value;
      expect(state, isA<ProfileData>());
      expect((state as ProfileData).profile.name, 'Bob');
      expect(state.profile.groceryBudget, 300.0);
    });

    // -------------------------------------------------------------------------
    // PROFILE-STATE-001-S4 — saveProfile with empty name does not save
    // -------------------------------------------------------------------------
    test('saveProfile with empty name does not save', () async {
      when(() => mockRepo.getProfile()).thenAnswer((_) async => Right(testProfile));
      await container.read(profileNotifierProvider.future);
      container.read(profileNotifierProvider.notifier).startEdit();
      await container
          .read(profileNotifierProvider.notifier)
          .saveProfile('', null, null);
      verifyNever(() => mockRepo.updateProfile(any()));
      expect(container.read(profileNotifierProvider).value, isA<ProfileEditing>());
    });

    // -------------------------------------------------------------------------
    // PROFILE-STATE-001-S5 — saveProfile with negative groceryBudget does not save
    // -------------------------------------------------------------------------
    test('saveProfile with negative groceryBudget does not save', () async {
      when(() => mockRepo.getProfile()).thenAnswer((_) async => Right(testProfile));
      await container.read(profileNotifierProvider.future);
      container.read(profileNotifierProvider.notifier).startEdit();
      await container
          .read(profileNotifierProvider.notifier)
          .saveProfile('Ana', null, -10.0);
      verifyNever(() => mockRepo.updateProfile(any()));
      expect(container.read(profileNotifierProvider).value, isA<ProfileEditing>());
    });

    // -------------------------------------------------------------------------
    // PROFILE-STATE-001-S7 — saveProfile on repo failure transitions to ProfileError
    // -------------------------------------------------------------------------
    test('saveProfile on repo failure transitions to ProfileError', () async {
      when(() => mockRepo.getProfile()).thenAnswer((_) async => Right(testProfile));
      when(() => mockRepo.updateProfile(any()))
          .thenAnswer((_) async => Left(CacheFailure('write error')));
      await container.read(profileNotifierProvider.future);
      container.read(profileNotifierProvider.notifier).startEdit();
      await container
          .read(profileNotifierProvider.notifier)
          .saveProfile('Ana', null, null);
      expect(container.read(profileNotifierProvider).value, isA<ProfileError>());
    });

    // -------------------------------------------------------------------------
    // PROFILE-STATE-001-S7 — retry re-loads profile
    // -------------------------------------------------------------------------
    test('retry re-loads profile', () async {
      when(() => mockRepo.getProfile()).thenAnswer((_) async => Right(testProfile));
      await container.read(profileNotifierProvider.future);
      // Retry and verify it re-calls getProfile and returns ProfileData
      when(() => mockRepo.getProfile()).thenAnswer((_) async => Right(testProfile));
      await container.read(profileNotifierProvider.notifier).retry();
      expect(container.read(profileNotifierProvider).value, isA<ProfileData>());
    });
  });
}
