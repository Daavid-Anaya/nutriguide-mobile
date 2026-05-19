// Spec: MEAL-STATE-001 sc1, sc2, sc3, sc4 | MEAL-SHOP-001 sc1–sc3
// TDD: Phase 4 [RED→GREEN] — Tests drive MealPlanNotifier

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/home/domain/meal.dart';
import 'package:nutriguide_mobile/features/home/domain/meal_plan.dart';
import 'package:nutriguide_mobile/features/meal_plan/data/meal_plan_providers.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/meal_plan_day.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/meal_plan_repository.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/weekly_meal_plan.dart';
import 'package:nutriguide_mobile/features/meal_plan/data/meal_plan_generator_service.dart';
import 'package:nutriguide_mobile/features/meal_plan/presentation/providers/meal_plan_notifier.dart';
import 'package:nutriguide_mobile/features/profile/domain/user_profile.dart';
import 'package:nutriguide_mobile/features/shopping_list/data/shopping_list_providers.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_list.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_list_repository.dart';
import 'package:nutriguide_mobile/core/storage/storage_providers.dart';
import 'package:hive_ce/hive.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockMealPlanRepository extends Mock implements MealPlanRepository {}

class MockMealPlanGeneratorService extends Mock
    implements MealPlanGeneratorService {}

class MockShoppingListRepository extends Mock
    implements ShoppingListRepository {}

class MockBox extends Mock implements Box<dynamic> {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

/// Minimal [UserProfile] for tests.
UserProfile _makeProfile() => const UserProfile(
      id: 'user-1',
      name: 'Test User',
      email: 'test@example.com',
    );

/// Minimal [WeeklyMealPlan] for tests.
WeeklyMealPlan _makeWeeklyPlan({
  String id = 'plan-1',
  List<MealPlanDay> days = const [],
  bool isLocalFallback = false,
}) {
  return WeeklyMealPlan.create(
    id: id,
    weekStartDate: DateTime(2026, 5, 18), // a Monday
    days: days,
    isLocalFallback: isLocalFallback,
  );
}

/// Minimal [MealPlan] (legacy home model) for tests.
MealPlan _makeMealPlan() => MealPlan(
      id: 'meal-plan-1',
      date: DateTime(2026, 5, 18),
      meals: [],
    );

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// Creates a [ProviderContainer] with all meal_plan providers overridden.
ProviderContainer _makeContainer({
  required MockMealPlanRepository mockRepo,
  required MockMealPlanGeneratorService mockGenerator,
  MockShoppingListRepository? mockShoppingRepo,
  MockBox? mockProductsBox,
}) {
  final container = ProviderContainer(
    overrides: [
      mealPlanRepositoryProvider.overrideWithValue(mockRepo),
      mealPlanGeneratorServiceProvider.overrideWithValue(mockGenerator),
      if (mockShoppingRepo != null)
        shoppingListRepositoryProvider.overrideWithValue(mockShoppingRepo),
      if (mockProductsBox != null)
        productsBoxProvider.overrideWithValue(mockProductsBox),
    ],
  );
  return container;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockMealPlanRepository mockRepo;
  late MockMealPlanGeneratorService mockGenerator;

  setUpAll(() {
    registerFallbackValue(_makeWeeklyPlan());
    registerFallbackValue(_makeProfile());
    registerFallbackValue(<Map<String, dynamic>>[]);
    registerFallbackValue(
      ShoppingList(
        id: 'list-1',
        name: 'Lista',
        items: const [],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    mockRepo = MockMealPlanRepository();
    mockGenerator = MockMealPlanGeneratorService();

    // Default: getWeeklyPlan returns a plan (happy path)
    when(() => mockRepo.getWeeklyPlan(any()))
        .thenAnswer((_) async => Right(_makeWeeklyPlan()));

    // Default: getMealPlanForDate returns a meal plan
    when(() => mockRepo.getMealPlanForDate(any()))
        .thenAnswer((_) async => Right(_makeMealPlan()));
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 1: build() — MEAL-STATE-001 sc1 and sc4
  // ─────────────────────────────────────────────────────────────────────────
  group('MealPlanNotifier.build()', () {
    test(
        'sc1: success — state is AsyncData(MealPlanData) with selectedDate today',
        () async {
      final container = _makeContainer(
        mockRepo: mockRepo,
        mockGenerator: mockGenerator,
      );
      addTearDown(container.dispose);

      // Trigger build() and wait for completion
      await container.read(mealPlanNotifierProvider.future);

      final state = container.read(mealPlanNotifierProvider);

      expect(state, isA<AsyncData<MealPlanState>>());
      final value = (state as AsyncData<MealPlanState>).value;
      expect(value, isA<MealPlanData>());

      final data = value as MealPlanData;
      expect(data.weeklyPlan, isA<WeeklyMealPlan>());

      // selectedDate should be today (date only — year/month/day)
      final today = DateTime.now();
      expect(data.selectedDate.year, today.year);
      expect(data.selectedDate.month, today.month);
      expect(data.selectedDate.day, today.day);
    });

    test('sc4: repo failure — state is AsyncData(MealPlanError)', () async {
      when(() => mockRepo.getWeeklyPlan(any()))
          .thenAnswer((_) async => Left(CacheFailure('no data')));

      final container = _makeContainer(
        mockRepo: mockRepo,
        mockGenerator: mockGenerator,
      );
      addTearDown(container.dispose);

      await container.read(mealPlanNotifierProvider.future);
      final state = container.read(mealPlanNotifierProvider);

      expect(state, isA<AsyncData<MealPlanState>>());
      final value = (state as AsyncData<MealPlanState>).value;
      expect(value, isA<MealPlanError>());

      final error = value as MealPlanError;
      expect(error.message, contains('no data'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 2: selectDay() — MEAL-STATE-001 sc2
  // ─────────────────────────────────────────────────────────────────────────
  group('MealPlanNotifier.selectDay()', () {
    test(
        'sc2: selectDay(Wednesday) updates selectedDate, weeklyPlan unchanged, no extra repo call',
        () async {
      final monday = DateTime(2026, 5, 18);
      final wednesday = DateTime(2026, 5, 20);
      final plan = _makeWeeklyPlan();

      when(() => mockRepo.getWeeklyPlan(any()))
          .thenAnswer((_) async => Right(plan));

      final container = _makeContainer(
        mockRepo: mockRepo,
        mockGenerator: mockGenerator,
      );
      addTearDown(container.dispose);

      // Wait for build() to complete
      await container.read(mealPlanNotifierProvider.future);

      // Verify only one getWeeklyPlan call (from build())
      verify(() => mockRepo.getWeeklyPlan(any())).called(1);

      // Get the notifier and call selectDay
      final notifier =
          container.read(mealPlanNotifierProvider.notifier);
      notifier.selectDay(wednesday);

      // Check state after selectDay
      final state = container.read(mealPlanNotifierProvider);
      expect(state, isA<AsyncData<MealPlanState>>());
      final value = (state as AsyncData<MealPlanState>).value;
      expect(value, isA<MealPlanData>());

      final data = value as MealPlanData;
      expect(data.selectedDate.day, wednesday.day);
      expect(data.selectedDate.month, wednesday.month);
      expect(data.selectedDate.year, wednesday.year);
      expect(data.weeklyPlan.id, plan.id);

      // No additional getWeeklyPlan calls made
      verifyNever(() => mockRepo.getWeeklyPlan(any()));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 3: generatePlan() — MEAL-STATE-001 sc3a, sc3b, sc3c
  // ─────────────────────────────────────────────────────────────────────────
  group('MealPlanNotifier.generatePlan()', () {
    test(
        'sc3a: success (EF) — state transitions through Generating → MealPlanData',
        () async {
      final newPlan = _makeWeeklyPlan(id: 'new-plan', isLocalFallback: false);
      final profile = _makeProfile();

      when(() => mockGenerator.generate(
                profile: any(named: 'profile'),
                inventory: any(named: 'inventory'),
              ))
          .thenAnswer((_) async => Right(newPlan));

      when(() => mockRepo.saveMealPlan(any()))
          .thenAnswer((_) async => const Right(unit));

      final container = _makeContainer(
        mockRepo: mockRepo,
        mockGenerator: mockGenerator,
      );
      addTearDown(container.dispose);

      await container.read(mealPlanNotifierProvider.future);

      final notifier =
          container.read(mealPlanNotifierProvider.notifier);

      await notifier.generatePlan(profile: profile, inventory: []);

      final state = container.read(mealPlanNotifierProvider);
      expect(state, isA<AsyncData<MealPlanState>>());
      final value = (state as AsyncData<MealPlanState>).value;
      expect(value, isA<MealPlanData>());

      final data = value as MealPlanData;
      expect(data.weeklyPlan.id, 'new-plan');
      expect(data.weeklyPlan.isLocalFallback, isFalse);

      verify(() => mockRepo.saveMealPlan(any())).called(1);
    });

    test('sc3b: local fallback — isLocalFallback == true in state', () async {
      final localPlan =
          _makeWeeklyPlan(id: 'local-plan', isLocalFallback: true);
      final profile = _makeProfile();

      when(() => mockGenerator.generate(
                profile: any(named: 'profile'),
                inventory: any(named: 'inventory'),
              ))
          .thenAnswer((_) async => Right(localPlan));

      when(() => mockRepo.saveMealPlan(any()))
          .thenAnswer((_) async => const Right(unit));

      final container = _makeContainer(
        mockRepo: mockRepo,
        mockGenerator: mockGenerator,
      );
      addTearDown(container.dispose);

      await container.read(mealPlanNotifierProvider.future);

      final notifier =
          container.read(mealPlanNotifierProvider.notifier);

      await notifier.generatePlan(profile: profile, inventory: []);

      final state = container.read(mealPlanNotifierProvider);
      final value = (state as AsyncData<MealPlanState>).value as MealPlanData;
      expect(value.weeklyPlan.isLocalFallback, isTrue);
    });

    test('sc3c: generator error — state is MealPlanError', () async {
      final profile = _makeProfile();

      when(() => mockGenerator.generate(
                profile: any(named: 'profile'),
                inventory: any(named: 'inventory'),
              ))
          .thenAnswer(
              (_) async => Left(GenerationFailure('generation failed')));

      final container = _makeContainer(
        mockRepo: mockRepo,
        mockGenerator: mockGenerator,
      );
      addTearDown(container.dispose);

      await container.read(mealPlanNotifierProvider.future);

      final notifier =
          container.read(mealPlanNotifierProvider.notifier);

      await notifier.generatePlan(profile: profile, inventory: []);

      final state = container.read(mealPlanNotifierProvider);
      final value = (state as AsyncData<MealPlanState>).value;
      expect(value, isA<MealPlanError>());

      final error = value as MealPlanError;
      expect(error.message, contains('generation failed'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 4: toggleMealCompletion()
  // ─────────────────────────────────────────────────────────────────────────
  group('MealPlanNotifier.toggleMealCompletion()', () {
    test(
        'toggles meal isCompleted in state and calls repo.toggleMealCompletion',
        () async {
      const meal = Meal(
        id: 'meal-1',
        name: 'Desayuno',
        mealType: 'breakfast',
        isCompleted: false,
      );
      final day = MealPlanDay(
        date: DateTime(2026, 5, 18),
        meals: [meal],
      );
      final plan = _makeWeeklyPlan(days: [day]);

      when(() => mockRepo.getWeeklyPlan(any()))
          .thenAnswer((_) async => Right(plan));

      when(() => mockRepo.toggleMealCompletion(any(), any()))
          .thenAnswer((_) async => const Right(unit));

      final container = _makeContainer(
        mockRepo: mockRepo,
        mockGenerator: mockGenerator,
      );
      addTearDown(container.dispose);

      await container.read(mealPlanNotifierProvider.future);

      final notifier =
          container.read(mealPlanNotifierProvider.notifier);

      await notifier.toggleMealCompletion('meal-1', true);

      // Verify repo was called
      verify(() => mockRepo.toggleMealCompletion('meal-1', true)).called(1);

      // Verify in-memory state updated
      final state = container.read(mealPlanNotifierProvider);
      final value = (state as AsyncData<MealPlanState>).value as MealPlanData;
      final updatedDay = value.weeklyPlan.days.first;
      expect(updatedDay.meals.first.isCompleted, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 5: generateShoppingList() — MEAL-SHOP-001 sc1–sc3
  // ─────────────────────────────────────────────────────────────────────────
  group('MealPlanNotifier.generateShoppingList()', () {
    test(
        'sc1: missing ingredients added — pollo and limón added, arroz NOT added',
        () async {
      const meal = Meal(
        id: 'meal-1',
        name: 'Pollo con Arroz',
        mealType: 'lunch',
        tags: ['pollo', 'arroz', 'limón'],
      );
      final day = MealPlanDay(
        date: DateTime(2026, 5, 18),
        meals: [meal],
      );
      final plan = _makeWeeklyPlan(days: [day]);

      when(() => mockRepo.getWeeklyPlan(any()))
          .thenAnswer((_) async => Right(plan));

      final mockShoppingRepo = MockShoppingListRepository();
      final mockBox = MockBox();

      // Products box: one product matching 'arroz' (case-insensitively)
      final productData = <dynamic>[
        {'name': 'Arroz Integral'},
      ];
      when(() => mockBox.values).thenReturn(productData);

      final existingList = ShoppingList(
        id: 'list-1',
        name: 'Lista Principal',
        items: const [],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      when(() => mockShoppingRepo.getOrCreateDefaultList())
          .thenAnswer((_) async => Right(existingList));

      when(() => mockShoppingRepo.saveList(any()))
          .thenAnswer((_) async => const Right(null));

      final container = _makeContainer(
        mockRepo: mockRepo,
        mockGenerator: mockGenerator,
        mockShoppingRepo: mockShoppingRepo,
        mockProductsBox: mockBox,
      );
      addTearDown(container.dispose);

      await container.read(mealPlanNotifierProvider.future);
      final notifier = container.read(mealPlanNotifierProvider.notifier);

      await notifier.generateShoppingList();

      // saveList must have been called with 'pollo' and 'limón', but NOT 'arroz'
      final captured = verify(
        () => mockShoppingRepo.saveList(captureAny()),
      ).captured;

      expect(captured, hasLength(1));
      final savedList = captured.first as ShoppingList;
      final itemNames = savedList.items.map((i) => i.name).toList();

      expect(itemNames, contains('pollo'));
      expect(itemNames, contains('limón'));
      expect(itemNames, isNot(contains('arroz')));
    });

    test('sc2: all ingredients in inventory — saveList NOT called', () async {
      const meal = Meal(
        id: 'meal-2',
        name: 'Arroz con Pollo',
        mealType: 'lunch',
        tags: ['pollo', 'arroz'],
      );
      final day = MealPlanDay(
        date: DateTime(2026, 5, 18),
        meals: [meal],
      );
      final plan = _makeWeeklyPlan(days: [day]);

      when(() => mockRepo.getWeeklyPlan(any()))
          .thenAnswer((_) async => Right(plan));

      final mockShoppingRepo = MockShoppingListRepository();
      final mockBox = MockBox();

      // Products box: both ingredients are present
      final productData = <dynamic>[
        {'name': 'Pollo Entero'},
        {'name': 'Arroz Integral'},
      ];
      when(() => mockBox.values).thenReturn(productData);

      final container = _makeContainer(
        mockRepo: mockRepo,
        mockGenerator: mockGenerator,
        mockShoppingRepo: mockShoppingRepo,
        mockProductsBox: mockBox,
      );
      addTearDown(container.dispose);

      await container.read(mealPlanNotifierProvider.future);
      final notifier = container.read(mealPlanNotifierProvider.notifier);

      await notifier.generateShoppingList();

      // saveList must NOT have been called
      verifyNever(() => mockShoppingRepo.saveList(any()));
    });

    test('sc3: empty tags — no items created, saveList NOT called', () async {
      const meal = Meal(
        id: 'meal-3',
        name: 'Desayuno',
        mealType: 'breakfast',
        tags: [], // empty tags
      );
      final day = MealPlanDay(
        date: DateTime(2026, 5, 18),
        meals: [meal],
      );
      final plan = _makeWeeklyPlan(days: [day]);

      when(() => mockRepo.getWeeklyPlan(any()))
          .thenAnswer((_) async => Right(plan));

      final mockShoppingRepo = MockShoppingListRepository();
      final mockBox = MockBox();
      when(() => mockBox.values).thenReturn(<dynamic>[]);

      final container = _makeContainer(
        mockRepo: mockRepo,
        mockGenerator: mockGenerator,
        mockShoppingRepo: mockShoppingRepo,
        mockProductsBox: mockBox,
      );
      addTearDown(container.dispose);

      await container.read(mealPlanNotifierProvider.future);
      final notifier = container.read(mealPlanNotifierProvider.notifier);

      await notifier.generateShoppingList();

      verifyNever(() => mockShoppingRepo.saveList(any()));
    });
  });
}
