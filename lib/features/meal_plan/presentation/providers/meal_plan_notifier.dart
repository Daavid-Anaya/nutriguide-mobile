// Spec: MEAL-STATE-001, MEAL-SHOP-001
// Design: AD-70, AD-69
// TDD: Phase 4 [GREEN] — MealPlanState sealed class + MealPlanNotifier

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:nutriguide_mobile/core/storage/storage_providers.dart';
import 'package:nutriguide_mobile/features/meal_plan/data/meal_plan_providers.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/weekly_meal_plan.dart';
import 'package:nutriguide_mobile/features/profile/domain/user_profile.dart';
import 'package:nutriguide_mobile/features/shopping_list/data/shopping_list_providers.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_item.dart';

// ---------------------------------------------------------------------------
// State — sealed class hierarchy (AD-70, consistent with HomeState AD-33)
// ---------------------------------------------------------------------------

/// Sealed state for the meal plan feature.
///
/// Four variants for exhaustive switch in the UI layer:
/// - [MealPlanLoading] — explicit in-progress during loadWeek() transitions
/// - [MealPlanData] — plan loaded successfully; carries the data + selected date
/// - [MealPlanGenerating] — AI generation in progress (distinct from loading: AD-70)
/// - [MealPlanError] — load or generation error; carries the message
sealed class MealPlanState {
  const MealPlanState();
}

/// Explicit in-progress state during [MealPlanNotifier.loadWeek].
///
/// Distinct from [AsyncLoading] (which wraps build()). Used for
/// in-state transitions when the notifier needs to signal loading
/// without re-running build().
class MealPlanLoading extends MealPlanState {
  const MealPlanLoading();
}

/// Plan loaded successfully — carries the weekly plan and the currently
/// selected day (spec MEAL-STATE-001).
class MealPlanData extends MealPlanState {
  const MealPlanData({
    required this.weeklyPlan,
    required this.selectedDate,
  });

  final WeeklyMealPlan weeklyPlan;
  final DateTime selectedDate;
}

/// AI generation is in progress (spec MEAL-STATE-001 sc3).
///
/// Distinct from [MealPlanLoading] — the UI shows a generation-specific
/// overlay ("Generando tu plan...") rather than a generic spinner.
class MealPlanGenerating extends MealPlanState {
  const MealPlanGenerating();
}

/// A load or generation error occurred.
class MealPlanError extends MealPlanState {
  const MealPlanError(this.message);

  final String message;
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Provides [MealPlanNotifier] as an [AsyncNotifierProvider].
///
/// Override in tests via [ProviderContainer] overrides for
/// [mealPlanRepositoryProvider] and [mealPlanGeneratorServiceProvider].
final mealPlanNotifierProvider =
    AsyncNotifierProvider<MealPlanNotifier, MealPlanState>(
  MealPlanNotifier.new,
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Manages meal plan feature state.
///
/// [build] loads the current week's [WeeklyMealPlan] from the repository.
/// On success → [MealPlanData]. On failure → [MealPlanError].
///
/// Methods:
/// - [selectDay]: pure in-memory date switch — no repo call (spec MEAL-STATE-001 sc2)
/// - [loadWeek]: reload from repository
/// - [generatePlan]: AI generation flow (spec MEAL-STATE-001 sc3)
/// - [toggleMealCompletion]: persists to Supabase + updates in-memory state
/// - [generateShoppingList]: diffs meal tags vs Hive products, appends to list (spec MEAL-SHOP-001)
class MealPlanNotifier extends AsyncNotifier<MealPlanState> {
  @override
  Future<MealPlanState> build() async {
    final weekStart = _currentMonday();
    final result =
        await ref.read(mealPlanRepositoryProvider).getWeeklyPlan(weekStart);
    return result.fold(
      (failure) => MealPlanError(failure.message),
      (plan) => MealPlanData(
        weeklyPlan: plan,
        selectedDate: _today(),
      ),
    );
  }

  /// Selects [date] as the active day — no repository call (spec MEAL-STATE-001 sc2).
  ///
  /// No-op when current state is not [MealPlanData].
  void selectDay(DateTime date) {
    final current = state;
    if (current is AsyncData<MealPlanState>) {
      final data = current.value;
      if (data is MealPlanData) {
        state = AsyncData(
          MealPlanData(weeklyPlan: data.weeklyPlan, selectedDate: date),
        );
      }
    }
  }

  /// Reloads the current week's plan from the repository.
  ///
  /// Transitions through [MealPlanLoading] before resolving.
  Future<void> loadWeek() async {
    state = const AsyncData(MealPlanLoading());
    final weekStart = _currentMonday();
    final result =
        await ref.read(mealPlanRepositoryProvider).getWeeklyPlan(weekStart);
    state = AsyncData(result.fold(
      (failure) => MealPlanError(failure.message),
      (plan) => MealPlanData(
        weeklyPlan: plan,
        selectedDate: _today(),
      ),
    ));
  }

  /// Generates a new weekly plan via AI (Edge Function → local fallback).
  ///
  /// Flow:
  /// 1. Transitions to [MealPlanGenerating].
  /// 2. Calls [MealPlanGeneratorService.generate].
  /// 3. On success: saves plan via repository, transitions to [MealPlanData].
  /// 4. On failure: transitions to [MealPlanError].
  Future<void> generatePlan({
    required UserProfile profile,
    required List<Map<String, dynamic>> inventory,
  }) async {
    // Signal generation in progress
    state = const AsyncData(MealPlanGenerating());

    final result = await ref
        .read(mealPlanGeneratorServiceProvider)
        .generate(profile: profile, inventory: inventory);

    await result.fold(
      (failure) async {
        state = AsyncData(MealPlanError(failure.message));
      },
      (newPlan) async {
        // Best-effort save — swallow repo errors (plan is still usable)
        await ref.read(mealPlanRepositoryProvider).saveMealPlan(newPlan);
        state = AsyncData(
          MealPlanData(weeklyPlan: newPlan, selectedDate: _today()),
        );
      },
    );
  }

  /// Toggles the [isCompleted] flag on meal [mealId] in Supabase and
  /// updates the in-memory state.
  ///
  /// Best-effort: no-op when state is not [MealPlanData].
  Future<void> toggleMealCompletion(String mealId, bool isCompleted) async {
    // 1. Persist to Supabase (best-effort — swallow errors)
    await ref
        .read(mealPlanRepositoryProvider)
        .toggleMealCompletion(mealId, isCompleted);

    // 2. Update in-memory state
    final current = state;
    if (current is AsyncData<MealPlanState>) {
      final data = current.value;
      if (data is MealPlanData) {
        final updatedDays = data.weeklyPlan.days.map((day) {
          final updatedMeals = day.meals.map((meal) {
            if (meal.id == mealId) return meal.copyWith(isCompleted: isCompleted);
            return meal;
          }).toList();
          return day.copyWith(meals: updatedMeals);
        }).toList();

        final updatedPlan = data.weeklyPlan.copyWith(days: updatedDays);
        state = AsyncData(
          MealPlanData(weeklyPlan: updatedPlan, selectedDate: data.selectedDate),
        );
      }
    }
  }

  /// Generates a shopping list from the current weekly plan (spec MEAL-SHOP-001).
  ///
  /// Algorithm (AD-69):
  /// 1. Collect all meal.tags from the weekly plan.
  /// 2. Read Hive 'products' box — extract lowercased product names.
  /// 3. Diff: tags NOT found (case-insensitively) in inventory.
  /// 4. Append missing items to the default shopping list.
  ///
  /// Best-effort: shopping list errors are swallowed.
  /// No-op when state is not [MealPlanData] or no tags exist.
  Future<void> generateShoppingList() async {
    final current = state;
    if (current is! AsyncData<MealPlanState>) return;
    final data = current.value;
    if (data is! MealPlanData) return;

    // 1. Extract all tags from all meals in the weekly plan
    final allTags = data.weeklyPlan.days
        .expand((day) => day.meals)
        .expand((meal) => meal.tags)
        .toSet();

    if (allTags.isEmpty) return;

    // 2. Read products inventory (Hive box) — lowercased names
    final productsBox = ref.read(productsBoxProvider);
    final inventoryNames = productsBox.values
        .cast<Map>()
        .map((p) => (p['name'] as String? ?? '').toLowerCase())
        .toSet();

    // 3. Diff: tags not matched by any inventory name (substring match)
    final missingIngredients = allTags.where((tag) {
      final lowerTag = tag.toLowerCase();
      return !inventoryNames.any(
        (name) => name.contains(lowerTag) || lowerTag.contains(name),
      );
    }).toList();

    if (missingIngredients.isEmpty) return;

    // 4. Get current default list and append missing items
    const uuid = Uuid();
    final shoppingListRepo = ref.read(shoppingListRepositoryProvider);
    final listResult = await shoppingListRepo.getOrCreateDefaultList();

    await listResult.fold(
      (failure) async {
        // Best effort — swallow shopping list errors
      },
      (currentList) async {
        final newItems = missingIngredients
            .map(
              (ingredient) => ShoppingItem(
                id: uuid.v4(),
                name: ingredient,
              ),
            )
            .toList();

        final updatedList = currentList.copyWith(
          items: [...currentList.items, ...newItems],
        );
        await shoppingListRepo.saveList(updatedList);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Returns the Monday of the current week (time stripped).
  DateTime _currentMonday() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  /// Returns today's date with time stripped.
  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
