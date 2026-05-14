// Spec: SCANNER-WIDGET-001 sc3, sc4; SCANNER-UI-002 sc5
// Design: AD-17 — always-visible Card with 8 nutrient rows. Null → "—".

import 'package:flutter/material.dart';
import 'package:nutriguide_mobile/core/extensions/context_extensions.dart';
import 'package:nutriguide_mobile/core/theme/app_shapes.dart';
import 'package:nutriguide_mobile/features/scanner/domain/nutritional_info.dart';

/// Card displaying a product's nutritional information per 100g.
///
/// Renders 8 rows (energy, fat, saturated fat, carbohydrates, sugars,
/// proteins, salt, fiber). Each row shows label on left, value+unit on right.
///
/// When [nutritionalInfo] is `null` or a specific field is `null`, that
/// row's value displays "—". The card is ALWAYS rendered (never hidden).
class NutritionalInfoCard extends StatelessWidget {
  const NutritionalInfoCard({
    super.key,
    required this.nutritionalInfo,
  });

  /// Nutritional data to display. May be `null` — card still renders.
  final NutritionalInfo? nutritionalInfo;

  @override
  Widget build(BuildContext context) {
    final info = nutritionalInfo;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppShapes.containerRadius),
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información nutricional',
              style: context.textTheme.titleMedium,
            ),
            SizedBox(height: context.spacing.sm),
            _NutrientRow(label: 'Energía', value: info?.energy, unit: 'kcal'),
            _NutrientRow(label: 'Grasas', value: info?.fat, unit: 'g'),
            _NutrientRow(
              label: 'Grasas saturadas',
              value: info?.saturatedFat,
              unit: 'g',
            ),
            _NutrientRow(
              label: 'Carbohidratos',
              value: info?.carbohydrates,
              unit: 'g',
            ),
            _NutrientRow(label: 'Azúcares', value: info?.sugars, unit: 'g'),
            _NutrientRow(label: 'Proteínas', value: info?.proteins, unit: 'g'),
            _NutrientRow(label: 'Sal', value: info?.salt, unit: 'g'),
            _NutrientRow(label: 'Fibra', value: info?.fiber, unit: 'g'),
          ],
        ),
      ),
    );
  }
}

/// A single label + value row inside [NutritionalInfoCard].
///
/// Extracted as a private widget for clarity. Not part of public API.
class _NutrientRow extends StatelessWidget {
  const _NutrientRow({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final double? value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final displayValue =
        value != null ? '${value!.toStringAsFixed(1)} $unit' : '—';

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: context.textTheme.bodyMedium),
          Text(
            displayValue,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
