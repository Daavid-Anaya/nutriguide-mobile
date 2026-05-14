// Spec: SCANNER-UI-002 sc1, sc2, sc3, sc4, sc5, sc6, sc7
//       SHOPPING-LIST-005 sc1, sc2, sc3
// AD-16 + AD-18 + AD-25: ProductDetailScreen widget tests.
//
// Testing strategy (AD-18 / AD-26):
// Override productDetailNotifierProvider(barcode) using FakeProductDetailNotifier.
// Override shoppingListNotifierProvider using FakeShoppingListNotifier.
// All tests use ProviderScope with both overrides.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide_mobile/core/widgets/loading_indicator.dart';
import 'package:nutriguide_mobile/features/scanner/domain/nutritional_info.dart';
import 'package:nutriguide_mobile/features/scanner/domain/product.dart';
import 'package:nutriguide_mobile/features/scanner/presentation/product_detail_screen.dart';
import 'package:nutriguide_mobile/features/scanner/presentation/providers/product_detail_notifier.dart';
import 'package:nutriguide_mobile/features/scanner/presentation/widgets/nutri_score_grade_badge.dart';
import 'package:nutriguide_mobile/features/scanner/presentation/widgets/nutritional_info_card.dart';
import 'package:nutriguide_mobile/features/scanner/presentation/widgets/product_header.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_item.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_list.dart';
import 'package:nutriguide_mobile/features/shopping_list/presentation/providers/shopping_list_notifier.dart';

// ---------------------------------------------------------------------------
// Test fixture
// ---------------------------------------------------------------------------

const _barcode = '3017620425035';

final _testProduct = Product(
  barcode: _barcode,
  name: 'Nutella',
  brands: 'Ferrero',
  nutriscoreGrade: 'e',
  nutriments: NutritionalInfo(
    energy: 530.0,
    fat: 30.9,
    proteins: 6.3,
    carbohydrates: 57.5,
    sugars: 56.3,
    saturatedFat: 10.6,
    salt: 0.107,
    fiber: 0.0,
  ),
);

final _testProductNoGrade = Product(
  barcode: _barcode,
  name: 'Mystery Product',
  brands: 'Unknown',
  // nutriscoreGrade: null — intentionally absent
);

// ---------------------------------------------------------------------------
// FakeProductDetailNotifier
//
// Allows us to seed a fixed ProductDetailState without running the real async build.
// ---------------------------------------------------------------------------

class FakeProductDetailNotifier extends ProductDetailNotifier {
  FakeProductDetailNotifier(this._seeded) : super(_barcode);

  final ProductDetailState _seeded;

  @override
  Future<ProductDetailState> build() async => _seeded;

  @override
  Future<void> retry() async {
    state = AsyncData(_seeded);
  }
}

// ---------------------------------------------------------------------------
// FakeShoppingListNotifier
//
// Seeds ShoppingListState so shopping list provider resolves without a repo.
// ---------------------------------------------------------------------------

class FakeShoppingListNotifier extends ShoppingListNotifier {
  FakeShoppingListNotifier(this._seedState);

  final ShoppingListState _seedState;

  @override
  Future<ShoppingListState> build() async => _seedState;

  /// No-op addItem — avoids real repo access in tests that only need
  /// the notifier to resolve without side-effects.
  @override
  Future<void> addItem(ShoppingItem item) async {
    // State already resolved; just pretend we added.
  }
}

// ---------------------------------------------------------------------------
// _CapturingShoppingListNotifier
//
// Like FakeShoppingListNotifier but also captures the ShoppingItem passed to
// addItem() so tests can assert the correct fields were used.
// ---------------------------------------------------------------------------

class _CapturingShoppingListNotifier extends ShoppingListNotifier {
  _CapturingShoppingListNotifier(
    this._seedState, {
    required this.onAdd,
  });

  final ShoppingListState _seedState;
  final void Function(ShoppingItem item) onAdd;

  @override
  Future<ShoppingListState> build() async => _seedState;

  @override
  Future<void> addItem(ShoppingItem item) async {
    onAdd(item);
    // Don't actually mutate state — the test only cares about the argument.
  }
}

// ---------------------------------------------------------------------------
// Fixtures for ShoppingList
// ---------------------------------------------------------------------------

final _testShoppingList = ShoppingList(
  id: 'list-1',
  name: 'Mi lista de compras',
  items: const [],
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

// ---------------------------------------------------------------------------
// Helper — builds ProductDetailScreen with both providers overridden.
// [shoppingListSeedState] defaults to ShoppingListData (list ready).
// ---------------------------------------------------------------------------

Widget buildSubject(
  ProductDetailState seedState, {
  ShoppingListState? shoppingListSeedState,
}) {
  final listState =
      shoppingListSeedState ?? ShoppingListData(_testShoppingList);

  return ProviderScope(
    overrides: [
      productDetailNotifierProvider(_barcode).overrideWith(
        () => FakeProductDetailNotifier(seedState),
      ),
      shoppingListNotifierProvider.overrideWith(
        () => FakeShoppingListNotifier(listState),
      ),
    ],
    child: const MaterialApp(
      home: ProductDetailScreen(barcode: _barcode),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── Test 1 ──────────────────────────────────────────────────────────────
  // Spec SCANNER-UI-002: AsyncLoading / ProductDetailLoading → LoadingIndicator.
  testWidgets(
    'loading state → LoadingIndicator is visible',
    (tester) async {
      await tester.pumpWidget(
        buildSubject(const ProductDetailLoading()),
      );

      // ProductDetailLoading inside AsyncData resolves synchronously.
      await tester.pump();

      expect(find.byType(LoadingIndicator), findsOneWidget);
      expect(find.byType(ProductHeader), findsNothing);
    },
  );

  // ── Test 2 ──────────────────────────────────────────────────────────────
  // Spec SCANNER-UI-002 sc1: ProductDetailData (network, isFromCache: false)
  // → ProductHeader + NutriScoreGradeBadge + NutritionalInfoCard visible.
  testWidgets(
    'ProductDetailData (isFromCache: false) → product sections visible, no cache chip',
    (tester) async {
      await tester.pumpWidget(
        buildSubject(ProductDetailData(_testProduct, isFromCache: false)),
      );
      // First pump: product detail notifier resolves (AsyncData<ProductDetailState>).
      // Second pump: shoppingListNotifierProvider resolves (AsyncData<ShoppingListState>).
      await tester.pump();
      await tester.pump();

      expect(find.byType(ProductHeader), findsOneWidget);
      expect(find.byType(NutriScoreGradeBadge), findsOneWidget);
      expect(find.byType(NutritionalInfoCard), findsOneWidget);
      expect(find.text('Agregar a lista'), findsOneWidget);
      // No cache chip.
      expect(find.text('datos locales'), findsNothing);
    },
  );

  // ── Test 3 ──────────────────────────────────────────────────────────────
  // Spec SCANNER-UI-002 sc2: ProductDetailData (isFromCache: true)
  // → "datos locales" Chip visible in ProductHeader.
  testWidgets(
    'ProductDetailData (isFromCache: true) → "datos locales" chip is visible',
    (tester) async {
      await tester.pumpWidget(
        buildSubject(ProductDetailData(_testProduct, isFromCache: true)),
      );
      await tester.pump();

      expect(find.text('datos locales'), findsOneWidget);
    },
  );

  // ── Test 4 ──────────────────────────────────────────────────────────────
  // Spec SCANNER-UI-002 sc3: ProductDetailNotFound → empty state message.
  testWidgets(
    'ProductDetailNotFound → "Producto no encontrado" visible, no product widgets',
    (tester) async {
      await tester.pumpWidget(buildSubject(const ProductDetailNotFound()));
      await tester.pump();

      expect(find.text('Producto no encontrado'), findsOneWidget);
      expect(find.byType(ProductHeader), findsNothing);
      expect(find.byType(NutriScoreGradeBadge), findsNothing);
      expect(find.byType(NutritionalInfoCard), findsNothing);
    },
  );

  // ── Test 5 ──────────────────────────────────────────────────────────────
  // Spec SCANNER-UI-002 sc4: ProductDetailNetworkError → "Sin conexión" + retry.
  testWidgets(
    'ProductDetailNetworkError → "Sin conexión" message and retry button visible',
    (tester) async {
      await tester.pumpWidget(buildSubject(const ProductDetailNetworkError()));
      await tester.pump();

      expect(find.text('Sin conexión'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    },
  );

  // ── Test 6 ──────────────────────────────────────────────────────────────
  // Spec SHOPPING-LIST-005 sc1 / SCANNER-UI-002 sc7:
  // "Agregar a lista" button is enabled (not disabled) when shoppingListNotifierProvider resolves.
  testWidgets(
    'sc7 — "Agregar a lista" button is enabled when shoppingListNotifierProvider resolves',
    (tester) async {
      await tester.pumpWidget(
        buildSubject(ProductDetailData(_testProduct, isFromCache: false)),
      );
      // pump 1: product detail notifier resolves (FakeProductDetailNotifier.build())
      // pump 2: shopping list notifier resolves (FakeShoppingListNotifier.build())
      await tester.pump();
      await tester.pump();

      // Scroll the button into view.
      await tester.scrollUntilVisible(
        find.text('Agregar a lista'),
        100,
      );
      await tester.pump();

      // The ElevatedButton must have an active onPressed (not null).
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Agregar a lista'),
      );
      expect(button.onPressed, isNotNull);
    },
  );

  // ── Test 8 ──────────────────────────────────────────────────────────────
  // Spec SHOPPING-LIST-005 sc1 / SCANNER-UI-002 sc7:
  // Tapping "Agregar a lista" shows SnackBar "Agregado a Mi lista de compras".
  testWidgets(
    'sc7 — tapping "Agregar a lista" shows SnackBar "Agregado a Mi lista de compras"',
    (tester) async {
      await tester.pumpWidget(
        buildSubject(ProductDetailData(_testProduct, isFromCache: false)),
      );
      await tester.pump();
      await tester.pump();

      // Scroll the button into view.
      await tester.scrollUntilVisible(
        find.text('Agregar a lista'),
        100,
      );
      await tester.pump();

      await tester.tap(find.text('Agregar a lista'));
      await tester.pump();

      expect(find.text('Agregado a Mi lista de compras'), findsOneWidget);
    },
  );

  // ── Test 9 ──────────────────────────────────────────────────────────────
  // Spec SHOPPING-LIST-005 sc1 + sc3:
  // Tapping "Agregar a lista" passes a ShoppingItem with correct name and barcode.
  testWidgets(
    'sc7 — tapping button builds ShoppingItem with product name and barcode',
    (tester) async {
      ShoppingItem? capturedItem;

      // Use a custom FakeShoppingListNotifier that captures the addItem argument.
      final capturingNotifier = _CapturingShoppingListNotifier(
        ShoppingListData(_testShoppingList),
        onAdd: (item) => capturedItem = item,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productDetailNotifierProvider(_barcode).overrideWith(
              () => FakeProductDetailNotifier(
                ProductDetailData(_testProduct, isFromCache: false),
              ),
            ),
            shoppingListNotifierProvider.overrideWith(
              () => capturingNotifier,
            ),
          ],
          child: const MaterialApp(
            home: ProductDetailScreen(barcode: _barcode),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.scrollUntilVisible(find.text('Agregar a lista'), 100);
      await tester.pump();

      await tester.tap(find.text('Agregar a lista'));
      await tester.pump();

      expect(capturedItem, isNotNull);
      expect(capturedItem!.name, equals(_testProduct.name));
      expect(capturedItem!.productBarcode, equals(_testProduct.barcode));
      expect(capturedItem!.isChecked, isFalse);
      expect(capturedItem!.quantity, isNull);
      expect(capturedItem!.estimatedPrice, isNull);
    },
  );

  // ── Test 10 ─────────────────────────────────────────────────────────────
  // Spec SHOPPING-LIST-005 sc1:
  // After tapping "Agregar a lista", user STAYS on ProductDetailScreen (no pop/navigation).
  testWidgets(
    'sc7 — after tapping button, user stays on ProductDetailScreen (no navigation)',
    (tester) async {
      await tester.pumpWidget(
        buildSubject(ProductDetailData(_testProduct, isFromCache: false)),
      );
      await tester.pump();
      await tester.pump();

      await tester.scrollUntilVisible(find.text('Agregar a lista'), 100);
      await tester.pump();

      await tester.tap(find.text('Agregar a lista'));
      await tester.pump();

      // ProductHeader is still visible — we haven't navigated away.
      expect(find.byType(ProductHeader), findsOneWidget);
      // The screen's AppBar title is still "Detalle del producto".
      expect(find.text('Detalle del producto'), findsOneWidget);
    },
  );

  // ── Test 7 ──────────────────────────────────────────────────────────────
  // Spec SCANNER-UI-002 sc1: nutriscoreGrade null → NutriScoreGradeBadge absent.
  testWidgets(
    'nutriscoreGrade null → NutriScoreGradeBadge not visible (SizedBox.shrink)',
    (tester) async {
      await tester.pumpWidget(
        buildSubject(ProductDetailData(_testProductNoGrade, isFromCache: false)),
      );
      await tester.pump();

      // ProductHeader and NutritionalInfoCard should still be there.
      expect(find.byType(ProductHeader), findsOneWidget);
      // NutriScoreGradeBadge renders SizedBox.shrink for null grade.
      // The widget is still in the tree via conditional — but for null grade
      // it renders SizedBox.shrink (0 size). We verify no colored badge appears
      // by checking no Container with NutriScoreGradeBadge colors:
      // The simplest check: since grade is null, the badge should have no
      // visible content. We verify widget type is present but renders empty.
      // NutriScoreGradeBadge is not in the conditional — it's always passed.
      // The screen wraps it in `if (product.nutriscoreGrade != null)`,
      // so with null grade the widget itself doesn't appear.
      expect(find.byType(NutriScoreGradeBadge), findsNothing);
    },
  );
}
