// Spec: MEAL-UI-002
// Design: AD-78 — full-screen push, no bottom nav shell
// TDD: T-42 [GREEN] — WeeklyCalendarStrip widget

import 'package:flutter/material.dart';
import 'package:nutriguide_mobile/core/extensions/context_extensions.dart';
import 'package:nutriguide_mobile/core/theme/app_spacing.dart';

/// A horizontally scrollable strip of 7 day tiles (Mon–Sun).
///
/// Each tile shows the day abbreviation (L/M/X/J/V/S/D) and day number.
/// The selected date tile is highlighted with [ColorScheme.primary] fill.
/// Dates present in [daysWithPlan] show a colored dot indicator.
///
/// Pure [StatelessWidget] — no provider reads. All state is passed via
/// constructor parameters (spec MEAL-UI-002).
class WeeklyCalendarStrip extends StatelessWidget {
  const WeeklyCalendarStrip({
    super.key,
    required this.weekStart,
    required this.selectedDate,
    required this.daysWithPlan,
    required this.onDaySelected,
  });

  /// The Monday of the week to display.
  final DateTime weekStart;

  /// The currently selected date (highlighted tile).
  final DateTime selectedDate;

  /// Set of dates that have a meal plan — these tiles show a dot indicator.
  final Set<DateTime> daysWithPlan;

  /// Called when a tile is tapped with the tapped date.
  final void Function(DateTime) onDaySelected;

  /// Day abbreviations in Spanish (Mon–Sun, ISO weekday 1–7).
  static const _dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: List.generate(7, (index) {
          final date = weekStart.add(Duration(days: index));
          final normalizedDate = DateTime(date.year, date.month, date.day);
          final normalizedSelected = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
          );
          final isSelected = normalizedDate == normalizedSelected;
          final hasPlan = daysWithPlan.contains(normalizedDate);

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: _DayTile(
              date: date,
              label: _dayLabels[index],
              isSelected: isSelected,
              hasPlan: hasPlan,
              onTap: () => onDaySelected(normalizedDate),
            ),
          );
        }),
      ),
    );
  }
}

/// A single day tile within [WeeklyCalendarStrip].
///
/// Shows the day abbreviation, day number, and an optional plan dot.
/// When [isSelected], renders with a [ColorScheme.primary] filled background.
class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.date,
    required this.label,
    required this.isSelected,
    required this.hasPlan,
    required this.onTap,
  });

  final DateTime date;
  final String label;
  final bool isSelected;
  final bool hasPlan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return GestureDetector(
      key: ValueKey('tile_$dateKey'),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 68,
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Day abbreviation
            Text(
              label,
              style: tt.labelSmall?.copyWith(
                color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Day number
            Text(
              '${date.day}',
              style: tt.titleSmall?.copyWith(
                color: isSelected ? cs.onPrimary : cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Plan dot indicator
            if (hasPlan)
              Container(
                key: ValueKey('dot_$dateKey'),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? cs.onPrimary : cs.tertiary,
                ),
              )
            else
              // Invisible placeholder to keep consistent tile height
              const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
