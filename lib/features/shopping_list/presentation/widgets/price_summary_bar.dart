// Spec: SHOPPING-LIST-004 | Design: AD-24
// TDD: T-4.2 [GREEN] — Implements PriceSummaryBar to pass price_summary_bar_test.dart.

import 'package:flutter/material.dart';
import 'package:nutriguide_mobile/core/theme/app_spacing.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_item.dart';

/// Bottom bar that displays the total estimated cost of all items in the list.
///
/// Stateless — receives [items] directly and computes the total inline via
/// [fold]. Items with null [ShoppingItem.estimatedPrice] count as 0 (AD-24).
///
/// Spec: SHOPPING-LIST-004.
class PriceSummaryBar extends StatelessWidget {
  const PriceSummaryBar({super.key, required this.items});

  final List<ShoppingItem> items;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(
      0.0,
      (sum, item) => sum + (item.estimatedPrice ?? 0.0),
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total estimado',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
