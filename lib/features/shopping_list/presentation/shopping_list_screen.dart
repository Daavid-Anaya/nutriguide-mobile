// Spec: SHOPPING-LIST-002 | Design: AD-22
// TDD: T-4.8 [GREEN] — Replaces placeholder with full ConsumerWidget screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutriguide_mobile/core/theme/app_spacing.dart';
import 'package:nutriguide_mobile/core/widgets/loading_indicator.dart';
import 'package:nutriguide_mobile/core/widgets/nutri_app_bar.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_list.dart';
import 'package:nutriguide_mobile/features/shopping_list/presentation/providers/shopping_list_notifier.dart';
import 'package:nutriguide_mobile/features/shopping_list/presentation/widgets/add_item_sheet.dart';
import 'package:nutriguide_mobile/features/shopping_list/presentation/widgets/price_summary_bar.dart';
import 'package:nutriguide_mobile/features/shopping_list/presentation/widgets/shopping_item_tile.dart';

/// Full shopping list screen.
///
/// Watches [shoppingListNotifierProvider] and uses [AsyncValue.when] to switch
/// between loading / error / data states. Within the data state, delegates to
/// either [_EmptyStateView] (no items) or [_ShoppingListBody] (has items).
///
/// Spec: SHOPPING-LIST-002 | Design: AD-22.
class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(shoppingListNotifierProvider);

    return Scaffold(
      appBar: const NutriAppBar(title: 'Mi lista de compras'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemSheet(context),
        child: const Icon(Icons.add),
      ),
      body: asyncState.when(
        loading: () => const LoadingIndicator(),
        error: (_, __) =>
            const Center(child: Text('Error al cargar la lista')),
        data: (listState) => switch (listState) {
          ShoppingListLoading() => const LoadingIndicator(),
          ShoppingListEmpty() => const _EmptyStateView(),
          ShoppingListData(:final list) => list.items.isEmpty
              ? const _EmptyStateView()
              : _ShoppingListBody(list: list),
        },
      ),
    );
  }

  void _showAddItemSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddItemSheet(),
    );
  }
}

// ---------------------------------------------------------------------------
// _ShoppingListBody
// ---------------------------------------------------------------------------

class _ShoppingListBody extends StatelessWidget {
  const _ShoppingListBody({required this.list});

  final ShoppingList list;

  @override
  Widget build(BuildContext context) {
    final items = list.items;
    final checkedCount = items.where((i) => i.isChecked).length;
    final progress = items.isEmpty ? 0.0 : checkedCount / items.length;

    return Column(
      children: [
        // Progress indicator
        LinearProgressIndicator(value: progress),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            '$checkedCount de ${items.length} completados',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        // Items list
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ShoppingItemTile(item: item);
            },
          ),
        ),
        // Price summary pinned at bottom
        PriceSummaryBar(items: items),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _EmptyStateView
// ---------------------------------------------------------------------------

class _EmptyStateView extends StatelessWidget {
  const _EmptyStateView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Tu lista está vacía',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tocá + para agregar productos',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
