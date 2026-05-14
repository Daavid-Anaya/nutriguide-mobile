// Spec: SCANNER-UI-002 sc1, sc2, sc3, sc4, sc5, sc6, sc7
// AD-16 + AD-18: ProductDetailScreen widget tests.
//
// Testing strategy (AD-18):
// Override productDetailNotifierProvider(barcode) using FakeProductDetailNotifier.
// All 7 tests use ProviderScope with overrides.

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
// Allows us to seed a fixed state without running the real async build.
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
// Helper — builds ProductDetailScreen with a seeded state.
// ---------------------------------------------------------------------------

Widget buildSubject(ProductDetailState seedState) {
  return ProviderScope(
    overrides: [
      productDetailNotifierProvider(_barcode).overrideWith(
        () => FakeProductDetailNotifier(seedState),
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
  // Spec SCANNER-UI-002 sc7: Tap GestureDetector on disabled button → SnackBar.
  testWidgets(
    'tapping GestureDetector on disabled "Agregar a lista" button shows "Próximamente" snackbar',
    (tester) async {
      await tester.pumpWidget(
        buildSubject(ProductDetailData(_testProduct, isFromCache: false)),
      );
      await tester.pump();

      // Scroll to bring the button into view (it's below the fold).
      await tester.scrollUntilVisible(
        find.text('Agregar a lista'),
        100,
      );
      await tester.pump();

      // The disabled button is wrapped in a GestureDetector.
      // We tap on the text directly — the GestureDetector above it intercepts
      // because the ElevatedButton is disabled (onPressed: null).
      await tester.tap(find.text('Agregar a lista'));
      await tester.pump();

      expect(find.text('Próximamente'), findsOneWidget);
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
