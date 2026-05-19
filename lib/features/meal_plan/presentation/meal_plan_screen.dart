// Spec: MEAL-UI-001, MEAL-UI-006
// Design: AD-63, AD-70, AD-78, AD-79
// TDD: T-48 [GREEN] — MealPlanScreen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutriguide_mobile/core/extensions/context_extensions.dart';
import 'package:nutriguide_mobile/core/storage/storage_providers.dart';
import 'package:nutriguide_mobile/core/theme/app_spacing.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/meal_plan_day.dart';
import 'package:nutriguide_mobile/features/meal_plan/presentation/providers/meal_plan_notifier.dart';
import 'package:nutriguide_mobile/features/meal_plan/presentation/widgets/macro_summary_card.dart';
import 'package:nutriguide_mobile/features/meal_plan/presentation/widgets/meal_plan_card.dart';
import 'package:nutriguide_mobile/features/meal_plan/presentation/widgets/weekly_calendar_strip.dart';
import 'package:nutriguide_mobile/features/profile/data/profile_providers.dart';

/// Weekly meal plan screen — the main entry point for the meal plan feature.
///
/// Watches [mealPlanNotifierProvider] and renders:
/// - [MealPlanLoading] → [CircularProgressIndicator]
/// - [MealPlanGenerating] → full-screen overlay "Generando tu plan..."
/// - [MealPlanError] → error + retry button
/// - [MealPlanData] with days → [WeeklyCalendarStrip] + [MacroSummaryCard] + [MealPlanCard] list
/// - [MealPlanData] with empty days → empty-state CTA to generate plan
///
/// Pull-to-refresh triggers [MealPlanNotifier.loadWeek].
/// FAB triggers plan generation (spec MEAL-UI-001).
///
/// Spec: MEAL-UI-001, MEAL-UI-006 | Design: AD-63, AD-70, AD-78.
class MealPlanScreen extends ConsumerWidget {
  const MealPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(mealPlanNotifierProvider);
    final notifier = ref.read(mealPlanNotifierProvider.notifier);

    // Listen for state changes to show post-generation feedback (MEAL-UI-006)
    ref.listen<AsyncValue<MealPlanState>>(mealPlanNotifierProvider,
        (previous, next) {
      final MealPlanState? prev = switch (previous) {
        AsyncData(:final value) => value,
        _ => null,
      };
      final MealPlanState? curr = switch (next) {
        AsyncData(:final value) => value,
        _ => null,
      };

      // Transition from Generating → Data: show success feedback
      if (prev is MealPlanGenerating && curr is MealPlanData) {
        final messenger = ScaffoldMessenger.of(context);
        if (curr.weeklyPlan.isLocalFallback) {
          // sc3: local fallback banner (MEAL-UI-006)
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Plan generado localmente (modo sin conexión)'),
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          // sc2: remote success toast (MEAL-UI-006)
          messenger.showSnackBar(
            const SnackBar(
              content: Text('¡Plan generado!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      // Transition from Generating → Error: show retry dialog (sc4 MEAL-UI-006)
      if (prev is MealPlanGenerating && curr is MealPlanError) {
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error al generar el plan'),
            content: Text(curr.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _triggerGeneration(context, ref, notifier);
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Semanal'),
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () => notifier.loadWeek(),
        ),
        data: (state) => switch (state) {
          MealPlanLoading() => const Center(child: CircularProgressIndicator()),
          MealPlanGenerating() => const _GeneratingOverlay(),
          MealPlanError(:final message) => _ErrorView(
              message: message,
              onRetry: () => notifier.loadWeek(),
            ),
          MealPlanData() => _MealPlanDataView(
              state: state,
              onRefresh: () => notifier.loadWeek(),
              onDaySelected: (date) => notifier.selectDay(date),
              onToggleMeal: (mealId, isCompleted) =>
                  notifier.toggleMealCompletion(mealId, isCompleted),
              onGeneratePlan: () =>
                  _triggerGeneration(context, ref, notifier),
            ),
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _triggerGeneration(context, ref, notifier),
        tooltip: 'Generar Plan IA',
        child: const Icon(Icons.auto_awesome),
      ),
    );
  }

  /// Loads profile + inventory, then calls [MealPlanNotifier.generatePlan].
  Future<void> _triggerGeneration(
    BuildContext context,
    WidgetRef ref,
    MealPlanNotifier notifier,
  ) async {
    // Load UserProfile
    final profileResult =
        await ref.read(profileRepositoryProvider).getProfile();
    final profile = profileResult.fold((_) => null, (p) => p);
    if (profile == null) return;

    // Load inventory from products Hive box
    final productsBox = ref.read(productsBoxProvider);
    final inventory = productsBox.values
        .cast<Map>()
        .map((p) => <String, dynamic>{
              'name': p['name'] as String? ?? '',
              'nutriscoreGrade': p['nutriscoreGrade'] as String? ?? '',
            })
        .toList();

    await notifier.generatePlan(profile: profile, inventory: inventory);
  }

}

// ---------------------------------------------------------------------------
// _MealPlanDataView — main content when MealPlanData is active
// ---------------------------------------------------------------------------

class _MealPlanDataView extends StatelessWidget {
  const _MealPlanDataView({
    required this.state,
    required this.onRefresh,
    required this.onDaySelected,
    required this.onToggleMeal,
    required this.onGeneratePlan,
  });

  final MealPlanData state;
  final Future<void> Function() onRefresh;
  final void Function(DateTime) onDaySelected;
  final void Function(String mealId, bool isCompleted) onToggleMeal;
  final VoidCallback onGeneratePlan;

  DateTime _currentMonday() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  @override
  Widget build(BuildContext context) {
    final weekStart = _currentMonday();
    final daysWithPlan = state.weeklyPlan.days
        .map((d) => DateTime(d.date.year, d.date.month, d.date.day))
        .toSet();

    // If no days exist, show empty state
    if (state.weeklyPlan.days.isEmpty) {
      return _EmptyStateView(onGeneratePlan: onGeneratePlan);
    }

    final selectedDay = state.weeklyPlan.dayFor(state.selectedDate);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Weekly calendar strip at the top
            WeeklyCalendarStrip(
              weekStart: weekStart,
              selectedDate: state.selectedDate,
              daysWithPlan: daysWithPlan,
              onDaySelected: onDaySelected,
            ),
            const SizedBox(height: AppSpacing.sm),
            // Day content
            if (selectedDay != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: MacroSummaryCard(day: selectedDay),
              ),
              const SizedBox(height: AppSpacing.sm),
              ..._buildMealCards(context, selectedDay),
            ] else ...[
              // Day selected but no meals planned
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: Text(
                    'No hay comidas planificadas para este día',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMealCards(BuildContext context, MealPlanDay day) {
    return day.meals.map((meal) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: MealPlanCard(
          meal: meal,
          onToggle: (v) => onToggleMeal(meal.id, v),
        ),
      );
    }).toList();
  }
}

// ---------------------------------------------------------------------------
// _EmptyStateView — shown when no weekly plan exists
// ---------------------------------------------------------------------------

class _EmptyStateView extends StatelessWidget {
  const _EmptyStateView({required this.onGeneratePlan});

  final VoidCallback onGeneratePlan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 72,
              color: context.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No tienes un plan semanal todavía',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Genera tu plan personalizado con IA',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: onGeneratePlan,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generar Plan IA'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _GeneratingOverlay — shown during AI generation (MealPlanGenerating state)
// ---------------------------------------------------------------------------

class _GeneratingOverlay extends StatelessWidget {
  const _GeneratingOverlay();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Semi-transparent background
        Container(
          color: context.colorScheme.surface.withValues(alpha: 0.85),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Generando tu plan...',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Esto puede tardar unos segundos',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _ErrorView — shown on MealPlanError state
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: context.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: context.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
