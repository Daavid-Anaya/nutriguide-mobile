// Spec: SHOPPING-LIST-002 sc2, sc3 | Design: AD-22
// TDD: T-4.4 [GREEN] — Implements ShoppingItemTile to pass shopping_item_tile_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutriguide_mobile/core/theme/app_spacing.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_item.dart';
import 'package:nutriguide_mobile/features/shopping_list/presentation/providers/shopping_list_notifier.dart';

/// A single item row in the shopping list.
///
/// Renders a [Dismissible] (swipe end-to-start → delete) wrapping a
/// [CheckboxListTile] (tap → toggle). Shows quantity, unit, and price in
/// the subtitle when available.
///
/// Spec: SHOPPING-LIST-002 sc2, sc3 | Design: AD-22.
class ShoppingItemTile extends ConsumerWidget {
  const ShoppingItemTile({super.key, required this.item});

  final ShoppingItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(shoppingListNotifierProvider.notifier);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => notifier.removeItem(item.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        color: Theme.of(context).colorScheme.error,
        child: Icon(
          Icons.delete,
          color: Theme.of(context).colorScheme.onError,
        ),
      ),
      child: CheckboxListTile(
        value: item.isChecked,
        onChanged: (_) => notifier.toggleItem(item.id),
        title: Text(
          item.name,
          style: item.isChecked
              ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )
              : Theme.of(context).textTheme.bodyLarge,
        ),
        subtitle: _buildSubtitle(context),
      ),
    );
  }

  /// Builds the subtitle with quantity/unit and price.
  ///
  /// Returns null if neither quantity nor price is available (no subtitle row).
  Widget? _buildSubtitle(BuildContext context) {
    final parts = <String>[];

    if (item.quantity != null) {
      final qty = item.quantity!;
      final qtyStr = qty == qty.truncate()
          ? qty.toStringAsFixed(1) // e.g. 2.0
          : qty.toString();
      if (item.unit != null) {
        parts.add('$qtyStr ${item.unit}');
      } else {
        parts.add(qtyStr);
      }
    }

    if (item.estimatedPrice != null) {
      parts.add('\$${item.estimatedPrice!.toStringAsFixed(2)}');
    }

    if (parts.isEmpty) return null;

    return Text(
      parts.join(' · '),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
