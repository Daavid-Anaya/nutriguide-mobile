// Spec: SHOPPING-LIST-006 | Design: AD-21
// TDD: T-3.2 [GREEN] — Implements ShoppingListNotifier to pass notifier tests.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutriguide_mobile/features/shopping_list/data/shopping_list_providers.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_item.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_list_repository.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_list.dart';

// ── State ────────────────────────────────────────────────────────────────────

/// Sealed state hierarchy for the shopping list feature.
///
/// Three variants (AD-21):
/// - [ShoppingListLoading] — intermediate state during an async mutation.
/// - [ShoppingListData]    — list loaded and available.
/// - [ShoppingListEmpty]   — repo returned a failure; no list available.
sealed class ShoppingListState {
  const ShoppingListState();
}

class ShoppingListLoading extends ShoppingListState {
  const ShoppingListLoading();
}

class ShoppingListData extends ShoppingListState {
  const ShoppingListData(this.list);

  final ShoppingList list;
}

class ShoppingListEmpty extends ShoppingListState {
  const ShoppingListEmpty();
}

// ── Provider ─────────────────────────────────────────────────────────────────

/// AsyncNotifierProvider for the single active shopping list.
///
/// NOT a family — MVP has exactly one active list at a time (AD-21).
final shoppingListNotifierProvider =
    AsyncNotifierProvider<ShoppingListNotifier, ShoppingListState>(
  ShoppingListNotifier.new,
);

// ── Notifier ─────────────────────────────────────────────────────────────────

/// Manages the active [ShoppingList] state.
///
/// Calls [ShoppingListRepository.getOrCreateDefaultList] on [build],
/// guaranteeing the state always resolves to [ShoppingListData] (the
/// auto-create ensures [ShoppingListEmpty] is only returned on repo failure).
///
/// Every mutation (add, remove, toggle, clear) follows the pattern:
///   1. Get current list via [_currentList].
///   2. Modify items immutably via `copyWith`.
///   3. Sort via [_sortedList] (unchecked first, checked last).
///   4. Persist via [_saveAndUpdate].
///
/// Spec: SHOPPING-LIST-006 | Design: AD-21.
class ShoppingListNotifier extends AsyncNotifier<ShoppingListState> {
  ShoppingListRepository get _repo =>
      ref.read(shoppingListRepositoryProvider);

  @override
  Future<ShoppingListState> build() async {
    final result = await _repo.getOrCreateDefaultList();
    return result.fold(
      (_) => const ShoppingListEmpty(),
      (list) => ShoppingListData(_sortedList(list)),
    );
  }

  // ── Public mutations ───────────────────────────────────────────────────────

  /// Appends [item] to the active list and persists.
  Future<void> addItem(ShoppingItem item) async {
    final current = _currentList;
    if (current == null) return;

    final updated = current.copyWith(
      items: [...current.items, item],
      updatedAt: DateTime.now(),
    );
    await _saveAndUpdate(updated);
  }

  /// Removes the item with [itemId] from the active list and persists.
  Future<void> removeItem(String itemId) async {
    final current = _currentList;
    if (current == null) return;

    final updated = current.copyWith(
      items: current.items.where((i) => i.id != itemId).toList(),
      updatedAt: DateTime.now(),
    );
    await _saveAndUpdate(updated);
  }

  /// Flips [isChecked] on the item with [itemId] and re-sorts.
  Future<void> toggleItem(String itemId) async {
    final current = _currentList;
    if (current == null) return;

    final updated = current.copyWith(
      items: current.items.map((i) {
        if (i.id == itemId) return i.copyWith(isChecked: !i.isChecked);
        return i;
      }).toList(),
      updatedAt: DateTime.now(),
    );
    await _saveAndUpdate(updated);
  }

  /// Removes all checked items from the active list and persists.
  Future<void> clearChecked() async {
    final current = _currentList;
    if (current == null) return;

    final updated = current.copyWith(
      items: current.items.where((i) => !i.isChecked).toList(),
      updatedAt: DateTime.now(),
    );
    await _saveAndUpdate(updated);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Returns the [ShoppingList] from the current [AsyncData] state, or null.
  ///
  /// Uses Dart pattern matching on [AsyncData] because Riverpod 3 does NOT
  /// expose a `.valueOrNull` getter on [AsyncValue] (AD-21, task note).
  ShoppingList? get _currentList {
    if (state case AsyncData(:final value)) {
      return value is ShoppingListData ? value.list : null;
    }
    return null;
  }

  /// Returns a new [ShoppingList] with items sorted: unchecked first (insertion
  /// order within each group), checked last (insertion order within each group).
  ///
  /// O(n) two-pass partition — adequate for typical shopping list sizes (<100).
  ShoppingList _sortedList(ShoppingList list) {
    final unchecked = list.items.where((i) => !i.isChecked).toList();
    final checked = list.items.where((i) => i.isChecked).toList();
    return list.copyWith(items: [...unchecked, ...checked]);
  }

  /// Sorts [list], persists it, and updates [state] atomically.
  Future<void> _saveAndUpdate(ShoppingList list) async {
    final sorted = _sortedList(list);
    await _repo.saveList(sorted);
    state = AsyncData(ShoppingListData(sorted));
  }
}
