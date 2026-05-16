// Spec: HOME-UI-001 sc1–sc4
// Design: AD-31, AD-33, AD-35, AD-42
// TDD: T-18 [GREEN] — Replaces placeholder with full ConsumerWidget dashboard.
// TDD: T-18 [GREEN] — Wires onTap on HomeHeader → context.go(Routes.profile).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nutriguide_mobile/core/extensions/context_extensions.dart';
import 'package:nutriguide_mobile/core/theme/app_spacing.dart';
import 'package:nutriguide_mobile/core/widgets/loading_indicator.dart';
import 'package:nutriguide_mobile/features/home/domain/meal_plan.dart';
import 'package:nutriguide_mobile/features/home/domain/wellness_summary.dart';
import 'package:nutriguide_mobile/features/home/presentation/providers/home_notifier.dart';
import 'package:nutriguide_mobile/features/home/presentation/widgets/greeting_section.dart';
import 'package:nutriguide_mobile/features/home/presentation/widgets/health_stats_row.dart';
import 'package:nutriguide_mobile/features/home/presentation/widgets/home_header.dart';
import 'package:nutriguide_mobile/features/home/presentation/widgets/todays_plan_section.dart';
import 'package:nutriguide_mobile/features/home/presentation/widgets/wellness_budget_card.dart';
import 'package:nutriguide_mobile/features/profile/domain/user_profile.dart';
import 'package:nutriguide_mobile/router/route_constants.dart';

/// Full Home screen — wellness dashboard.
///
/// ConsumerWidget that watches [homeNotifierProvider] and switches on the
/// [AsyncValue<HomeState>] to render loading / error / data views.
///
/// No AppBar — custom [HomeHeader] is the first widget inside the scroll view.
/// Supports pull-to-refresh via [RefreshIndicator] calling [HomeNotifier.retry].
///
/// Spec: HOME-UI-001 | Design: AD-31, AD-33.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(homeNotifierProvider);

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: asyncState.when(
        // Async loading (provider building for the first time).
        loading: () => const LoadingIndicator(),
        // Async error (unexpected exception from build — should not normally happen).
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.read(homeNotifierProvider.notifier).retry(),
        ),
        // Async data — switch on the sealed HomeState.
        data: (homeState) => switch (homeState) {
          HomeLoading() => const LoadingIndicator(),
          HomeError(:final message) => _ErrorView(
              message: message,
              onRetry: () => ref.read(homeNotifierProvider.notifier).retry(),
            ),
          HomeData(:final profile, :final wellness, :final mealPlan) =>
            _DashboardView(
              wellness: wellness,
              mealPlan: mealPlan,
              profile: profile,
              onRefresh: () =>
                  ref.read(homeNotifierProvider.notifier).retry(),
              onToggleMeal: (mealId) =>
                  ref.read(homeNotifierProvider.notifier).toggleMeal(mealId),
            ),
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _DashboardView
// Rendered when HomeData is available — the full wellness dashboard.
// ---------------------------------------------------------------------------

class _DashboardView extends StatelessWidget {
  const _DashboardView({
    required this.wellness,
    required this.mealPlan,
    required this.profile,
    required this.onRefresh,
    required this.onToggleMeal,
  });

  final WellnessSummary wellness;
  final MealPlan mealPlan;
  final UserProfile profile;
  final Future<void> Function() onRefresh;
  final void Function(String mealId) onToggleMeal;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + AppSpacing.md,
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Custom header (no AppBar — AD-31) ────────────────────────
            HomeHeader(
              avatarUrl: profile.avatarUrl,
              // AD-42: inject navigation callback; pure widget, no router dep.
              onTap: () => context.go(Routes.profile),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Greeting section ─────────────────────────────────────────
            GreetingSection(userName: profile.name),
            const SizedBox(height: AppSpacing.lg),

            // ── Budget card ──────────────────────────────────────────────
            WellnessBudgetCard(wellness: wellness),
            const SizedBox(height: AppSpacing.md),

            // ── Health stats row (HealthScoreCard + StreakCard) ──────────
            HealthStatsRow(
              healthScore: wellness.healthScore,
              streak: wellness.streak,
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Today's plan section ─────────────────────────────────────
            TodaysPlanSection(
              mealPlan: mealPlan,
              onToggleMeal: onToggleMeal,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ErrorView
// Rendered when HomeError — error message + retry ElevatedButton.
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
        padding: EdgeInsets.all(context.spacing.lg),
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
