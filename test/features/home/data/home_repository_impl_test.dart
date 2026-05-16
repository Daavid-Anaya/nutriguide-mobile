// Spec: HOME-DATA-001 sc1–sc5
// TDD: T-03 [RED] — Tests FAIL until home_repository_impl.dart is created (T-04).
// TDD: T-19 [RED] — Tests for HomeRepositoryImpl budget wiring via ProfileRepository.

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/home/data/home_repository_impl.dart';
import 'package:nutriguide_mobile/features/home/domain/meal.dart';
import 'package:nutriguide_mobile/features/profile/domain/profile_repository.dart';
import 'package:nutriguide_mobile/features/profile/domain/user_profile.dart';
import 'package:nutriguide_mobile/features/shopping_list/data/shopping_list_repository_impl.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_item.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_list.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------
class _MockShoppingListRepo extends Mock
    implements ShoppingListRepositoryImpl {}

class _MockBox extends Mock implements Box<dynamic> {}

class _MockProfileRepository extends Mock implements ProfileRepository {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

/// Creates a [ShoppingItem] with the given [estimatedPrice].
ShoppingItem _item({String id = 'i1', String name = 'Item', double? price}) =>
    ShoppingItem(id: id, name: name, estimatedPrice: price);

/// Creates a [ShoppingList] with the given [items].
ShoppingList _list({required List<ShoppingItem> items}) => ShoppingList(
      id: 'list-1',
      name: 'Mi lista de compras',
      items: items,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

/// Builds a raw product map as stored in the Hive products box.
Map<String, dynamic> _productMap({required String? nutriscoreGrade}) => {
      'barcode': '123',
      'name': 'Product',
      'nutriscoreGrade': nutriscoreGrade,
    };

void main() {
  late _MockShoppingListRepo mockShoppingListRepo;
  late _MockBox mockProductsBox;
  late _MockProfileRepository mockProfileRepo;
  late HomeRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      const UserProfile(id: '', name: '', email: ''),
    );
  });

  setUp(() {
    mockShoppingListRepo = _MockShoppingListRepo();
    mockProductsBox = _MockBox();
    mockProfileRepo = _MockProfileRepository();
    // Default: profile returns no groceryBudget → budgetTotal falls back to 200.0
    when(() => mockProfileRepo.getProfile()).thenAnswer(
      (_) async => const Right(UserProfile(id: '', name: 'Usuario', email: '')),
    );
    repository = HomeRepositoryImpl(
      shoppingListRepo: mockShoppingListRepo,
      productsBox: mockProductsBox,
      profileRepo: mockProfileRepo,
    );
  });

  // ---------------------------------------------------------------------------
  // HOME-DATA-001 sc1 — WellnessSummary computed from real data
  // ---------------------------------------------------------------------------
  group('getWellnessSummary', () {
    test(
      'sc1 — budgetSpent sums item prices, budgetTotal=200.0 (default), '
      'healthScore averages A and C grades (90+50)/2=70',
      () async {
        // Shopping list with [20.0, null, 35.0]
        when(() => mockShoppingListRepo.getOrCreateDefaultList()).thenAnswer(
          (_) async => Right(
            _list(items: [
              _item(id: 'i1', price: 20.0),
              _item(id: 'i2', price: null),
              _item(id: 'i3', price: 35.0),
            ]),
          ),
        );

        // Products box: grades A and C → scores 90 and 50 → avg 70
        when(() => mockProductsBox.isEmpty).thenReturn(false);
        when(() => mockProductsBox.values).thenReturn([
          _productMap(nutriscoreGrade: 'a'),
          _productMap(nutriscoreGrade: 'c'),
        ]);

        final result = await repository.getWellnessSummary();

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (summary) {
            expect(summary.budgetSpent, equals(55.0));
            expect(summary.budgetTotal, equals(200.0));
            expect(summary.healthScore, equals(70));
            expect(summary.streak, equals(0));
          },
        );
      },
    );

    // HOME-DATA-001 sc2 — healthScore=0 when products box is empty
    test('sc2 — healthScore is 0 when products box is empty', () async {
      when(() => mockShoppingListRepo.getOrCreateDefaultList()).thenAnswer(
        (_) async => Right(_list(items: [])),
      );
      when(() => mockProductsBox.isEmpty).thenReturn(true);

      final result = await repository.getWellnessSummary();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right but got Left'),
        (summary) => expect(summary.healthScore, equals(0)),
      );
    });

    // HOME-DATA-001 sc3 — budgetTotal defaults to 200.0 when groceryBudget is null
    // (default UserProfile has no groceryBudget — confirmed by getProfile returning UserProfile)
    // This is validated via the sc1 test above (no profile override → default 200.0).
    // Additional triangulation: budgetSpent=0 when all items have null price.
    test(
      'sc5 — budgetSpent is 0.0 when all items have null estimatedPrice',
      () async {
        when(() => mockShoppingListRepo.getOrCreateDefaultList()).thenAnswer(
          (_) async => Right(
            _list(items: [
              _item(id: 'i1', price: null),
              _item(id: 'i2', price: null),
            ]),
          ),
        );
        when(() => mockProductsBox.isEmpty).thenReturn(true);

        final result = await repository.getWellnessSummary();

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (summary) => expect(summary.budgetSpent, equals(0.0)),
        );
      },
    );

    // HOME-DATA-001 sc5 (CacheFailure) — wraps exception in Left(CacheFailure)
    test('sc5 — returns Left(CacheFailure) when shoppingListRepo throws', () async {
      when(() => mockShoppingListRepo.getOrCreateDefaultList())
          .thenThrow(Exception('Hive read error'));

      final result = await repository.getWellnessSummary();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('Expected Left but got Right'),
      );
    });

    // T-19: reads groceryBudget from profile for budgetTotal
    test(
      'T-19 — reads groceryBudget from profile and uses it as budgetTotal',
      () async {
        when(() => mockShoppingListRepo.getOrCreateDefaultList()).thenAnswer(
          (_) async => Right(_list(items: [])),
        );
        when(() => mockProductsBox.isEmpty).thenReturn(true);
        when(() => mockProfileRepo.getProfile()).thenAnswer(
          (_) async => Right(
            const UserProfile(
              id: '',
              name: 'Usuario',
              email: '',
              groceryBudget: 350.0,
            ),
          ),
        );

        final result = await repository.getWellnessSummary();

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (summary) => expect(summary.budgetTotal, equals(350.0)),
        );
      },
    );

    // T-19: falls back to 200.0 when groceryBudget is null
    test(
      'T-19 — falls back to 200.0 when profile.groceryBudget is null',
      () async {
        when(() => mockShoppingListRepo.getOrCreateDefaultList()).thenAnswer(
          (_) async => Right(_list(items: [])),
        );
        when(() => mockProductsBox.isEmpty).thenReturn(true);
        when(() => mockProfileRepo.getProfile()).thenAnswer(
          (_) async => const Right(
            UserProfile(id: '', name: 'Usuario', email: ''),
          ),
        );

        final result = await repository.getWellnessSummary();

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (summary) => expect(summary.budgetTotal, equals(200.0)),
        );
      },
    );

    // T-19: falls back to 200.0 when profileRepo returns Left failure
    test(
      'T-19 — falls back to 200.0 when profileRepo returns Left(CacheFailure)',
      () async {
        when(() => mockShoppingListRepo.getOrCreateDefaultList()).thenAnswer(
          (_) async => Right(_list(items: [])),
        );
        when(() => mockProductsBox.isEmpty).thenReturn(true);
        when(() => mockProfileRepo.getProfile()).thenAnswer(
          (_) async => const Left(CacheFailure('no profile')),
        );

        final result = await repository.getWellnessSummary();

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (summary) => expect(summary.budgetTotal, equals(200.0)),
        );
      },
    );

    // T-19: budgetSpent calculation is unchanged by profile wiring
    test(
      'T-19 — budgetSpent calculation is unchanged when profileRepo is wired',
      () async {
        when(() => mockShoppingListRepo.getOrCreateDefaultList()).thenAnswer(
          (_) async => Right(
            _list(items: [
              _item(id: 'i1', price: 42.5),
              _item(id: 'i2', price: null),
            ]),
          ),
        );
        when(() => mockProductsBox.isEmpty).thenReturn(true);
        when(() => mockProfileRepo.getProfile()).thenAnswer(
          (_) async => const Right(
            UserProfile(id: '', name: 'Usuario', email: '', groceryBudget: 300.0),
          ),
        );

        final result = await repository.getWellnessSummary();

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (summary) {
            expect(summary.budgetSpent, equals(42.5));
            expect(summary.budgetTotal, equals(300.0));
          },
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // HOME-DATA-001 sc4 — getTodayMealPlan returns 3 stub meals
  // ---------------------------------------------------------------------------
  group('getTodayMealPlan', () {
    test('sc4 — returns Right(MealPlan) with exactly 3 meals', () async {
      final result = await repository.getTodayMealPlan();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right but got Left'),
        (plan) {
          expect(plan.meals, hasLength(3));
        },
      );
    });

    test('sc4 — meal types are breakfast, lunch, and dinner', () async {
      final result = await repository.getTodayMealPlan();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right but got Left'),
        (plan) {
          final types = plan.meals.map((m) => m.mealType).toList();
          expect(types, contains(MealType.breakfast));
          expect(types, contains(MealType.lunch));
          expect(types, contains(MealType.dinner));
        },
      );
    });

    test('sc4 — all stub meals have non-empty names and are not completed', () async {
      final result = await repository.getTodayMealPlan();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right but got Left'),
        (plan) {
          for (final meal in plan.meals) {
            expect(meal.name, isNotEmpty);
            expect(meal.isCompleted, isFalse);
          }
        },
      );
    });
  });
}
