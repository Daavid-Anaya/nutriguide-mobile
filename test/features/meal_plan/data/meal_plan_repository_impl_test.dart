// Spec: MEAL-REPO-001 sc1–sc4
// TDD: Phase 2 [RED→GREEN] — Tests drive MealPlanRepositoryImpl
// Supabase primary + Hive write-through cache (AD-65, AD-74)

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/home/domain/meal.dart';
import 'package:nutriguide_mobile/features/home/domain/meal_plan.dart';
import 'package:nutriguide_mobile/features/meal_plan/data/meal_plan_repository_impl.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/meal_plan_day.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/weekly_meal_plan.dart';

import '../../../helpers/mock_supabase.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------
class MockBox extends Mock implements Box<dynamic> {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

/// A Supabase response row for a meal_plans record with nested meals.
Map<String, dynamic> _makePlanRow({
  String id = 'plan-uuid-1',
  String date = '2026-05-18',
  String userId = 'user-123',
  List<Map<String, dynamic>>? meals,
}) =>
    {
      'id': id,
      'user_id': userId,
      'date': date,
      'created_at': '2026-05-18T00:00:00.000Z',
      'meals': meals ?? <Map<String, dynamic>>[],
    };

Map<String, dynamic> _makeMealRow({
  String id = 'meal-uuid-1',
  String name = 'Avena con frutas',
  String mealType = 'breakfast',
  int calories = 350,
  double proteins = 12.0,
  double carbs = 55.0,
  double fats = 8.0,
}) =>
    {
      'id': id,
      'name': name,
      'meal_type': mealType,
      'calories': calories,
      'proteins': proteins,
      'carbs': carbs,
      'fats': fats,
      'tags': <String>[],
      'is_completed': false,
    };

/// Creates a simple [WeeklyMealPlan] for Hive cache testing.
WeeklyMealPlan _makeWeeklyPlan({
  String id = 'plan-cached',
  DateTime? weekStart,
}) {
  final ws = weekStart ?? DateTime(2026, 5, 18);
  return WeeklyMealPlan.create(
    id: id,
    weekStartDate: ws,
    days: [
      MealPlanDay(
        date: ws,
        meals: [
          const Meal(
            id: 'meal-1',
            name: 'Avena',
            mealType: 'breakfast',
            calories: 300,
          ),
        ],
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Supabase mock wiring helper
// ---------------------------------------------------------------------------
class _SupabaseMocks {
  _SupabaseMocks() {
    mealPlansQueryBuilder = MockSupabaseQueryBuilder();
    selectFilterBuilder =
        MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
    mealsQueryBuilder = MockSupabaseQueryBuilder();
    mealsUpdateFilter = MockPostgrestFilterBuilder<void>();
  }

  late MockSupabaseQueryBuilder mealPlansQueryBuilder;
  late MockPostgrestFilterBuilder<List<Map<String, dynamic>>>
      selectFilterBuilder;
  late MockSupabaseQueryBuilder mealsQueryBuilder;
  late MockPostgrestFilterBuilder<void> mealsUpdateFilter;

  /// Wire getWeeklyPlan() chain: from → select → eq (user) → gte → lte → order → await
  void wireGetWeeklyPlan(
    MockSupabaseClient mockSupabase,
    String userId, {
    required List<Map<String, dynamic>> response,
  }) {
    when(() => mockSupabase.from('meal_plans'))
        .thenAnswer((_) => mealPlansQueryBuilder);

    when(() => mealPlansQueryBuilder.select('*, meals(*)'))
        .thenAnswer((_) => selectFilterBuilder);
    when(() => selectFilterBuilder.eq('user_id', userId))
        .thenAnswer((_) => selectFilterBuilder);
    when(() => selectFilterBuilder.gte('date', any<String>()))
        .thenAnswer((_) => selectFilterBuilder);
    when(() => selectFilterBuilder.lte('date', any<String>()))
        .thenAnswer((_) => selectFilterBuilder);
    when(() => selectFilterBuilder.order('date'))
        .thenAnswer((_) => selectFilterBuilder);

    when(
      () => selectFilterBuilder.then<dynamic>(
        any(),
        onError: any(named: 'onError'),
      ),
    ).thenAnswer((inv) {
      final onValue = inv.positionalArguments[0] as Function;
      return Future<List<Map<String, dynamic>>>.value(response)
          .then((v) => onValue(v));
    });
  }

  /// Wire meals.update().eq() chain for toggleMealCompletion
  void wireToggle(MockSupabaseClient mockSupabase) {
    when(() => mockSupabase.from('meals'))
        .thenAnswer((_) => mealsQueryBuilder);
    when(
      () => mealsQueryBuilder.update(any<Map<String, dynamic>>()),
    ).thenAnswer((_) => mealsUpdateFilter);
    when(() => mealsUpdateFilter.eq('id', any<String>()))
        .thenAnswer((_) => mealsUpdateFilter);
    when(
      () => mealsUpdateFilter.then<dynamic>(
        any(),
        onError: any(named: 'onError'),
      ),
    ).thenAnswer((inv) {
      final onValue = inv.positionalArguments[0] as Function;
      return Future<void>.value().then((_) => onValue(null));
    });
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late MockBox mockBox;
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late MealPlanRepositoryImpl repository;

  final weekStart = DateTime(2026, 5, 18); // Monday
  final weekKey = '2026-05-18';

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(<dynamic>[]);
    registerFallbackValue(<Map<String, dynamic>>[]);
  });

  setUp(() {
    mockBox = MockBox();
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockSupabase.auth).thenAnswer((_) => mockAuth);

    repository = MealPlanRepositoryImpl(
      supabase: mockSupabase,
      mealPlansBox: mockBox,
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 1: getWeeklyPlan() — unauthenticated
  // ─────────────────────────────────────────────────────────────────────────
  group('getWeeklyPlan() — unauthenticated', () {
    test('returns Left(CacheFailure) without calling Supabase', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final result = await repository.getWeeklyPlan(weekStart);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('Expected Left'),
      );
      verifyNever(() => mockSupabase.from(any()));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 2: getWeeklyPlan() — authenticated + Supabase OK
  // ─────────────────────────────────────────────────────────────────────────
  group('getWeeklyPlan() — authenticated + Supabase OK', () {
    test(
        'returns Right(WeeklyMealPlan) and writes JSON to Hive box',
        () async {
      final fakeUser = createFakeUser();
      when(() => mockAuth.currentUser).thenReturn(fakeUser);

      final mealRow = _makeMealRow();
      final planRow = _makePlanRow(
        date: '2026-05-18',
        userId: fakeUser.id,
        meals: [mealRow],
      );

      final mocks = _SupabaseMocks()
        ..wireGetWeeklyPlan(
          mockSupabase,
          fakeUser.id,
          response: [planRow],
        );

      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      final result = await repository.getWeeklyPlan(weekStart);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (plan) {
          expect(plan, isA<WeeklyMealPlan>());
          expect(plan.days, hasLength(1));
          expect(plan.days.first.meals, hasLength(1));
          expect(plan.days.first.meals.first.name, equals('Avena con frutas'));
        },
      );

      // Verify Hive cache write-through (AD-74)
      verify(() => mockBox.put(weekKey, any<String>())).called(1);
    });

    test(
        'triangulate — multiple days are grouped correctly into WeeklyMealPlan',
        () async {
      final fakeUser = createFakeUser();
      when(() => mockAuth.currentUser).thenReturn(fakeUser);

      final rows = [
        _makePlanRow(
          id: 'plan-1',
          date: '2026-05-18',
          userId: fakeUser.id,
          meals: [_makeMealRow(id: 'meal-1', name: 'Desayuno Lunes')],
        ),
        _makePlanRow(
          id: 'plan-2',
          date: '2026-05-19',
          userId: fakeUser.id,
          meals: [_makeMealRow(id: 'meal-2', name: 'Desayuno Martes')],
        ),
      ];

      _SupabaseMocks()
        ..wireGetWeeklyPlan(mockSupabase, fakeUser.id, response: rows);
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      final result = await repository.getWeeklyPlan(weekStart);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (plan) {
          expect(plan.days, hasLength(2));
        },
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 3: getWeeklyPlan() — Supabase throws + Hive has cached data
  // ─────────────────────────────────────────────────────────────────────────
  group('getWeeklyPlan() — Supabase throws + Hive fallback', () {
    test('returns Right(cached WeeklyMealPlan) from Hive when Supabase fails',
        () async {
      final fakeUser = createFakeUser();
      when(() => mockAuth.currentUser).thenReturn(fakeUser);

      // Supabase throws
      when(() => mockSupabase.from('meal_plans'))
          .thenThrow(Exception('Network error'));

      // Hive has cached plan
      final cachedPlan = _makeWeeklyPlan();
      when(() => mockBox.get(weekKey))
          .thenReturn(jsonEncode(cachedPlan.toJson()));

      final result = await repository.getWeeklyPlan(weekStart);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right from cache'),
        (plan) {
          expect(plan, isA<WeeklyMealPlan>());
          expect(plan.id, equals('plan-cached'));
        },
      );
    });

    test(
        'returns Left(CacheFailure) when Supabase throws and Hive is empty',
        () async {
      final fakeUser = createFakeUser();
      when(() => mockAuth.currentUser).thenReturn(fakeUser);

      when(() => mockSupabase.from('meal_plans'))
          .thenThrow(Exception('Network error'));
      when(() => mockBox.get(weekKey)).thenReturn(null);

      final result = await repository.getWeeklyPlan(weekStart);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 4: getMealPlanForDate() — T-20
  // ─────────────────────────────────────────────────────────────────────────
  group('getMealPlanForDate()', () {
    test('unauthenticated → Left(CacheFailure)', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final result = await repository.getMealPlanForDate(weekStart);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('Expected Left'),
      );
      verifyNever(() => mockSupabase.from(any()));
    });

    test('authenticated + Supabase OK → Right(MealPlan) for specific date',
        () async {
      final fakeUser = createFakeUser();
      when(() => mockAuth.currentUser).thenReturn(fakeUser);

      final mealRow = _makeMealRow(name: 'Pollo con arroz', mealType: 'lunch');
      final planRow = _makePlanRow(
        date: '2026-05-18',
        userId: fakeUser.id,
        meals: [mealRow],
      );

      // For getMealPlanForDate we query the same endpoint
      final mocks = _SupabaseMocks()
        ..wireGetWeeklyPlan(
          mockSupabase,
          fakeUser.id,
          response: [planRow],
        );
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      final result =
          await repository.getMealPlanForDate(DateTime(2026, 5, 18));

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (plan) {
          expect(plan, isA<MealPlan>());
          expect(plan.meals, hasLength(1));
          expect(plan.meals.first.name, equals('Pollo con arroz'));
        },
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 5: saveMealPlan() — T-22
  // ─────────────────────────────────────────────────────────────────────────
  group('saveMealPlan()', () {
    test('unauthenticated → Left(CacheFailure)', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      final plan = _makeWeeklyPlan();

      final result = await repository.saveMealPlan(plan);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('Expected Left'),
      );
      verifyNever(() => mockSupabase.from(any()));
    });

    test('authenticated → upserts to Supabase + writes to Hive', () async {
      final fakeUser = createFakeUser();
      when(() => mockAuth.currentUser).thenReturn(fakeUser);

      // Set up mocks for upsert + delete + insert chain
      final mealPlansQB = MockSupabaseQueryBuilder();
      final mealsQB = MockSupabaseQueryBuilder();
      final upsertFilter = MockPostgrestFilterBuilder<void>();
      final deleteFilter = MockPostgrestFilterBuilder<void>();
      final insertFilter = MockPostgrestFilterBuilder<void>();

      when(() => mockSupabase.from('meal_plans'))
          .thenAnswer((_) => mealPlansQB);
      when(() => mealPlansQB.upsert(any<Map<String, dynamic>>()))
          .thenAnswer((_) => upsertFilter);
      when(
        () => upsertFilter.then<dynamic>(any(), onError: any(named: 'onError')),
      ).thenAnswer((inv) {
        final onValue = inv.positionalArguments[0] as Function;
        return Future<void>.value().then((_) => onValue(null));
      });

      when(() => mockSupabase.from('meals'))
          .thenAnswer((_) => mealsQB);
      when(() => mealsQB.delete()).thenAnswer((_) => deleteFilter);
      when(() => deleteFilter.eq('plan_id', any<String>()))
          .thenAnswer((_) => deleteFilter);
      when(
        () => deleteFilter.then<dynamic>(any(), onError: any(named: 'onError')),
      ).thenAnswer((inv) {
        final onValue = inv.positionalArguments[0] as Function;
        return Future<void>.value().then((_) => onValue(null));
      });

      when(() => mealsQB.insert(any<List<Map<String, dynamic>>>()))
          .thenAnswer((_) => insertFilter);
      when(
        () => insertFilter.then<dynamic>(any(), onError: any(named: 'onError')),
      ).thenAnswer((inv) {
        final onValue = inv.positionalArguments[0] as Function;
        return Future<void>.value().then((_) => onValue(null));
      });

      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      final plan = _makeWeeklyPlan();
      final result = await repository.saveMealPlan(plan);

      expect(result.isRight(), isTrue);
      // Verify Hive write
      verify(() => mockBox.put(weekKey, any<String>())).called(1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 6: toggleMealCompletion() — T-24
  // ─────────────────────────────────────────────────────────────────────────
  group('toggleMealCompletion()', () {
    test('unauthenticated → Left(CacheFailure) without Supabase call',
        () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final result = await repository.toggleMealCompletion('meal-1', true);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('Expected Left'),
      );
      verifyNever(() => mockSupabase.from(any()));
    });

    test('authenticated → calls Supabase update + returns Right(unit)',
        () async {
      final fakeUser = createFakeUser();
      when(() => mockAuth.currentUser).thenReturn(fakeUser);

      final mocks = _SupabaseMocks()..wireToggle(mockSupabase);

      final result = await repository.toggleMealCompletion('meal-abc', true);

      expect(result.isRight(), isTrue);
      verify(
        () => mockSupabase.from('meals'),
      ).called(1);
    });

    test(
        'triangulate — toggleMealCompletion with isCompleted=false also returns Right',
        () async {
      final fakeUser = createFakeUser();
      when(() => mockAuth.currentUser).thenReturn(fakeUser);

      final mocks = _SupabaseMocks()..wireToggle(mockSupabase);

      final result = await repository.toggleMealCompletion('meal-xyz', false);

      expect(result.isRight(), isTrue);
    });
  });
}
