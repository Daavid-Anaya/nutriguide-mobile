// Spec: SHOPPING-LIST-INTERFACE-001
// TDD: 1.1 [RED] — verifies getOrCreateDefaultList() is on the abstract interface.
// Design: AD-50

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_list.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_list_repository.dart';

// ---------------------------------------------------------------------------
// Mock — uses the ABSTRACT interface as the target type (AD-50)
// ---------------------------------------------------------------------------
class MockShoppingListRepository extends Mock implements ShoppingListRepository {}

void main() {
  late MockShoppingListRepository mockRepo;

  setUp(() {
    mockRepo = MockShoppingListRepository();
  });

  // SHOPPING-LIST-INTERFACE-001: getOrCreateDefaultList() exists on the abstract interface
  group('ShoppingListRepository abstract interface', () {
    test(
      'sc1 — getOrCreateDefaultList() is callable on ShoppingListRepository typed variable',
      () async {
        // Arrange: abstract-typed variable so we test the CONTRACT not the impl
        final ShoppingListRepository repo = mockRepo;

        final stubList = ShoppingList(
          id: 'list-1',
          name: 'Mi lista de compras',
          items: const [],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        );
        when(() => repo.getOrCreateDefaultList())
            .thenAnswer((_) async => Right(stubList));

        // Act — called through abstract type
        final result = await repo.getOrCreateDefaultList();

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (list) {
            expect(list.id, equals('list-1'));
            expect(list.name, equals('Mi lista de compras'));
          },
        );
        verify(() => repo.getOrCreateDefaultList()).called(1);
      },
    );

    // Triangulate: Left(failure) path is also reachable via abstract type
    test(
      'sc1 triangulate — getOrCreateDefaultList() returning Left is callable on abstract type',
      () async {
        final ShoppingListRepository repo = mockRepo;

        when(() => repo.getOrCreateDefaultList())
            .thenAnswer((_) async => const Left(CacheFailure('no storage')));

        final result = await repo.getOrCreateDefaultList();

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      },
    );
  });
}
