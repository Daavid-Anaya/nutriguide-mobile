import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:postgrest/postgrest.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fpdart/fpdart.dart';
import 'package:nutriguide_mobile/features/profile/data/profile_repository_impl.dart';
import 'package:nutriguide_mobile/features/profile/domain/user_profile.dart';
import '../../../helpers/mock_supabase.dart';

// ── Important: ALL Supabase builder types implement Future<T>, so they need
// thenAnswer (not thenReturn) in stubs. SupabaseQueryBuilder, PostgrestFilterBuilder,
// and PostgrestTransformBuilder all extend PostgrestBuilder which implements Future<T>.

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockPostgrestFilterBuilder<PostgrestList> mockFilterList;
  late ProfileRepositoryImpl repository;

  const fakeUserId = 'user-123';
  const fakeEmail = 'test@nutriguide.app';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockFilterList = MockPostgrestFilterBuilder<PostgrestList>();

    // GoTrueClient is NOT a Future, thenReturn is safe here
    when(() => mockClient.auth).thenReturn(mockAuth);

    repository = ProfileRepositoryImpl(
      sharedPreferences: prefs,
      supabaseClient: mockClient,
    );
  });

  // ── getProfile ─────────────────────────────────────────────────────────

  group('getProfile()', () {
    test('S1 — authenticated: reads from Supabase, populates id+email', () async {
      final fakeRow = <String, dynamic>{
        'id': fakeUserId,
        'name': 'Ana García',
        'email': fakeEmail,
        'avatar_url': null,
        'dietary_restrictions': <String>[],
        'primary_goal': null,
        'grocery_budget': 350.0,
      };

      // .single() returns PostgrestTransformBuilder<PostgrestMap>
      // Wrap real Future so await works correctly
      final fakeSingle = FakePostgrestTransformBuilder<PostgrestMap>(
        Future.value(fakeRow),
      );

      when(() => mockAuth.currentUser).thenReturn(createFakeUser());
      // from() returns SupabaseQueryBuilder (a Future) → thenAnswer
      when(() => mockClient.from('profiles')).thenAnswer((_) => mockQueryBuilder);
      // select() returns PostgrestFilterBuilder (a Future) → thenAnswer
      when(() => mockQueryBuilder.select(any())).thenAnswer((_) => mockFilterList);
      // eq() returns PostgrestFilterBuilder (a Future) → thenAnswer
      when(() => mockFilterList.eq(any(), any())).thenAnswer((_) => mockFilterList);
      // single() returns PostgrestTransformBuilder (a Future) → thenAnswer with Fake
      when(() => mockFilterList.single()).thenAnswer((_) => fakeSingle);

      final result = await repository.getProfile();

      expect(result.isRight(), isTrue);
      final profile = result.toNullable()!;
      expect(profile.id, fakeUserId);
      expect(profile.email, fakeEmail);
      expect(profile.name, 'Ana García');
      expect(profile.groceryBudget, 350.0);
    });

    test('S2 — unauthenticated: reads from SharedPreferences', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final result = await repository.getProfile();

      expect(result.isRight(), isTrue);
      final profile = result.toNullable()!;
      expect(profile.id, '');
      expect(profile.email, '');
      verifyNever(() => mockClient.from(any()));
    });

    test('S3 — Supabase error falls back to SharedPrefs cache', () async {
      final fakeError = FakePostgrestTransformBuilder<PostgrestMap>(
        Future.error(Exception('network error')),
      );

      when(() => mockAuth.currentUser).thenReturn(createFakeUser());
      when(() => mockClient.from('profiles')).thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.select(any())).thenAnswer((_) => mockFilterList);
      when(() => mockFilterList.eq(any(), any())).thenAnswer((_) => mockFilterList);
      when(() => mockFilterList.single()).thenAnswer((_) => fakeError);

      final result = await repository.getProfile();

      // Should NOT throw, falls back to local
      expect(result.isRight(), isTrue);
      final profile = result.toNullable()!;
      expect(profile.name, 'Usuario'); // default from SharedPrefs
    });
  });

  // ── updateProfile ──────────────────────────────────────────────────────

  group('updateProfile()', () {
    test('S4 — authenticated: upserts to Supabase + updates SharedPrefs', () async {
      final updatedProfile = UserProfile(
        id: fakeUserId,
        name: 'Ana Updated',
        email: fakeEmail,
        groceryBudget: 400.0,
      );

      // upsert() returns PostgrestFilterBuilder<dynamic> (also a Future)
      final fakeUpsert = FakePostgrestFilterBuilder<dynamic>(
        Future.value(<dynamic>[]),
      );

      when(() => mockAuth.currentUser).thenReturn(createFakeUser());
      // from() is a Future → thenAnswer
      when(() => mockClient.from('profiles')).thenAnswer((_) => mockQueryBuilder);
      // upsert() is a Future → thenAnswer with Fake
      when(() => mockQueryBuilder.upsert(any())).thenAnswer((_) => fakeUpsert);

      final result = await repository.updateProfile(updatedProfile);

      expect(result.isRight(), isTrue);
      // Verify Supabase was called
      verify(() => mockClient.from('profiles')).called(greaterThanOrEqualTo(1));
    });

    test('S5 — unauthenticated: writes to SharedPrefs only', () async {
      const updatedProfile = UserProfile(
        id: '',
        name: 'Local User',
        email: '',
      );

      when(() => mockAuth.currentUser).thenReturn(null);

      final result = await repository.updateProfile(updatedProfile);

      expect(result.isRight(), isTrue);
      verifyNever(() => mockClient.from(any()));
    });
  });
}
