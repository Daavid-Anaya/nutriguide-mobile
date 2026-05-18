// Spec: SHOPPING-LIST-006 | SHOPPING-LIST-SYNC-002
// Design: AD-21, AD-57 — Realtime in Notifier (not repo), lifecycle via ref.onDispose
// TDD: Phase 4 [GREEN] — Adds Realtime subscription in build()

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutriguide_mobile/core/supabase/supabase_providers.dart';
import 'package:nutriguide_mobile/features/shopping_list/data/shopping_list_providers.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_item.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_list_repository.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
/// Also opens a Realtime subscription to `shopping_items` changes when the
/// user is authenticated (AD-57). The channel is closed via [ref.onDispose].
///
/// Every mutation (add, remove, toggle, clear) follows the pattern:
///   1. Get current list via [_currentList].
///   2. Modify items immutably via `copyWith`.
///   3. Sort via [_sortedList] (unchecked first, checked last).
///   4. Persist via [_saveAndUpdate].
///
/// Spec: SHOPPING-LIST-006 | SHOPPING-LIST-SYNC-002 | Design: AD-21, AD-57.
class ShoppingListNotifier extends AsyncNotifier<ShoppingListState> {
  ShoppingListRepository get _repo =>
      ref.read(shoppingListRepositoryProvider);

  @override
  Future<ShoppingListState> build() async {
    final result = await _repo.getOrCreateDefaultList();

    // AD-57: Open Realtime subscription when authenticated.
    // The repo stays stateless — the notifier owns the channel lifecycle.
    final supabaseClient = ref.read(supabaseClientProvider);
    final currentUser = supabaseClient.auth.currentUser;

    if (currentUser != null) {
      final channel = supabaseClient
          .channel('shopping_items_changes_${currentUser.id}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'shopping_items',
            callback: (payload) => _onRealtimeChange(payload),
          )
          .subscribe();

      // Cleanup when notifier is disposed (screen change, logout) — AD-57, S5
      ref.onDispose(() => supabaseClient.removeChannel(channel));
    }

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

  /// Called when a Realtime postgres change arrives (AD-57).
  ///
  /// Re-fetches all lists from Supabase to get consistent state.
  /// Idempotent — at most one extra fetch per change.
  void _onRealtimeChange(PostgresChangePayload payload) {
    _refreshLists();
  }

  /// Re-fetches the active list from the repository and updates state.
  Future<void> _refreshLists() async {
    final result = await _repo.getOrCreateDefaultList();
    state = AsyncData(result.fold(
      (_) => const ShoppingListEmpty(),
      (list) => ShoppingListData(_sortedList(list)),
    ));
  }

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
