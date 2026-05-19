// Spec: HOME-UI-007 sc1–sc5
// Design: AD-32 — CachedNetworkImage with fallback Icon(Icons.restaurant).
//         MealType label uppercase labelSmall. Checkbox for isCompleted.
// TDD: T-16 [GREEN] — Implements MealCard to pass T-15b tests.

import 'package:flutter/material.dart';
import 'package:nutriguide_mobile/core/extensions/context_extensions.dart';
import 'package:nutriguide_mobile/core/theme/app_shapes.dart';
import 'package:nutriguide_mobile/core/theme/app_spacing.dart';
import 'package:nutriguide_mobile/features/home/domain/meal.dart';

/// A card displaying a single [Meal] entry.
///
/// Renders a meal thumbnail (CachedNetworkImage or placeholder), the meal type
/// label in uppercase, the meal name, optional calorie display, tags as
/// bullet-separated text, and a [Checkbox] reflecting [meal.isCompleted].
///
/// [onToggle] is called when the user taps the checkbox.
///
/// Spec: HOME-UI-007 | Design: AD-32.
class MealCard extends StatelessWidget {
  const MealCard({
    super.key,
    required this.meal,
    this.onToggle,
  });

  final Meal meal;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(context),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildContent(context)),
            _buildCheckbox(context),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    // Meal domain model has no imageUrl field — always use placeholder (stub data).
    return ClipRRect(
      borderRadius: AppShapes.smallRadius,
      child: SizedBox(
        width: 60,
        height: 60,
        child: Container(
          color: context.colorScheme.surfaceContainerHigh,
          child: Center(
            child: Icon(
              Icons.restaurant,
              size: 28,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meal type in uppercase
        Text(
          meal.mealType.toUpperCase(),
          style: context.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
            color: context.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Meal name
        Text(
          meal.name,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        // Calories — only when non-null
        if (meal.calories != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${meal.calories} kcal',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        // Tags — only when non-empty
        if (meal.tags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            meal.tags.join(' • '),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        // Macros row — only when at least one macro is non-null (AD-64)
        if (meal.proteins != null ||
            meal.carbs != null ||
            meal.fats != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'P: ${meal.proteins?.toStringAsFixed(0) ?? '—'}g  '
            'C: ${meal.carbs?.toStringAsFixed(0) ?? '—'}g  '
            'F: ${meal.fats?.toStringAsFixed(0) ?? '—'}g',
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCheckbox(BuildContext context) {
    return Checkbox(
      value: meal.isCompleted,
      onChanged: onToggle != null ? (_) => onToggle!() : null,
      activeColor: context.colorScheme.primary,
    );
  }
}
