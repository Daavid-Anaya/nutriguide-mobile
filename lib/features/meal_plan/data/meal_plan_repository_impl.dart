// Spec: MEAL-REPO-001 sc1–sc4
// Design: AD-65, AD-74
// TDD: Phase 2 [GREEN] — Supabase primary + Hive write-through implementation

import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/home/domain/meal.dart';
import 'package:nutriguide_mobile/features/home/domain/meal_plan.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/meal_plan_day.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/meal_plan_repository.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/weekly_meal_plan.dart';

/// Supabase-backed implementation of [MealPlanRepository] with Hive cache.
///
/// Pattern: **read Supabase → update Hive → return** (AD-65).
/// Falls back to Hive when Supabase fails (AD-74).
/// Returns [CacheFailure] for all operations when user is unauthenticated
/// (spec MEAL-REPO-001).
///
/// Hive key strategy: ISO-8601 Monday date string (e.g. "2026-05-18").
/// Value: JSON-encoded [WeeklyMealPlan] string (AD-74).
class MealPlanRepositoryImpl implements MealPlanRepository {
  MealPlanRepositoryImpl({
    required SupabaseClient supabase,
    required Box<dynamic> mealPlansBox,
  })  : _supabase = supabase,
        _box = mealPlansBox;

  final SupabaseClient _supabase;
  final Box<dynamic> _box;

  User? get _currentUser => _supabase.auth.currentUser;

  // ── MealPlanRepository — abstract interface ──────────────────────────────

  @override
  Future<Either<Failure, WeeklyMealPlan>> getWeeklyPlan(
    DateTime weekStart,
  ) async {
    if (_currentUser == null) {
      return const Left(CacheFailure('Authentication required'));
    }

    final weekKey = _weekKey(weekStart);
    final weekEnd = weekStart.add(const Duration(days: 6));

    try {
      final response = await _supabase
          .from('meal_plans')
          .select('*, meals(*)')
          .eq('user_id', _currentUser!.id)
          .gte('date', _dateStr(weekStart))
          .lte('date', _dateStr(weekEnd))
          .order('date');

      final rows = response as List<dynamic>;
      final plan = _buildWeeklyPlan(rows.cast(), weekStart);

      // Write-through cache (AD-74)
      await _box.put(weekKey, jsonEncode(plan.toJson()));

      return Right(plan);
    } catch (_) {
      // Fallback to Hive cache
      return _readWeeklyPlanFromHive(weekKey);
    }
  }

  @override
  Future<Either<Failure, MealPlan>> getMealPlanForDate(DateTime date) async {
    if (_currentUser == null) {
      return const Left(CacheFailure('Authentication required'));
    }

    final weekStart = _mondayOf(date);
    final result = await getWeeklyPlan(weekStart);

    return result.fold(
      Left.new,
      (weeklyPlan) {
        final day = weeklyPlan.dayFor(date);
        if (day == null) {
          return const Left(CacheFailure('No meal plan for requested date'));
        }
        return Right(
          MealPlan(
            id: '${weeklyPlan.id}-${_dateStr(date)}',
            date: date,
            meals: day.meals,
          ),
        );
      },
    );
  }

  @override
  Future<Either<Failure, Unit>> saveMealPlan(WeeklyMealPlan plan) async {
    if (_currentUser == null) {
      return const Left(CacheFailure('Authentication required'));
    }

    try {
      final userId = _currentUser!.id;

      for (final day in plan.days) {
        final planId = '${plan.id}-${_dateStr(day.date)}';

        // Upsert meal_plans row
        await _supabase.from('meal_plans').upsert({
          'id': planId,
          'user_id': userId,
          'date': _dateStr(day.date),
          'created_at': DateTime.now().toIso8601String(),
        });

        // Delete existing meals + re-insert (same pattern as shopping_list — AD-52 note)
        await _supabase
            .from('meals')
            .delete()
            .eq('plan_id', planId);

        if (day.meals.isNotEmpty) {
          await _supabase.from('meals').insert(
            day.meals
                .map(
                  (m) => {
                    'id': m.id,
                    'plan_id': planId,
                    'name': m.name,
                    'meal_type': m.mealType,
                    'calories': m.calories,
                    'proteins': m.proteins,
                    'carbs': m.carbs,
                    'fats': m.fats,
                    'tags': m.tags,
                    'is_completed': m.isCompleted,
                  },
                )
                .toList(),
          );
        }
      }

      // Write-through Hive cache
      final weekKey = _weekKey(plan.weekStartDate);
      await _box.put(weekKey, jsonEncode(plan.toJson()));

      return const Right(unit);
    } on Exception catch (e) {
      return Left(CacheFailure('Failed to save meal plan: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> toggleMealCompletion(
    String mealId,
    bool isCompleted,
  ) async {
    if (_currentUser == null) {
      return const Left(CacheFailure('Authentication required'));
    }

    try {
      await _supabase
          .from('meals')
          .update({'is_completed': isCompleted})
          .eq('id', mealId);

      return const Right(unit);
    } on Exception catch (e) {
      return Left(CacheFailure('Failed to toggle meal completion: $e'));
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Build a [WeeklyMealPlan] from Supabase rows.
  ///
  /// Groups rows by date and maps nested meals into [MealPlanDay] entries.
  WeeklyMealPlan _buildWeeklyPlan(
    List<Map<String, dynamic>> rows,
    DateTime weekStart,
  ) {
    final days = rows.map((row) {
      final mealsData = row['meals'] as List<dynamic>? ?? [];
      final meals = mealsData
          .map((e) => _mapToMeal(e as Map<String, dynamic>))
          .toList();

      return MealPlanDay(
        date: DateTime.parse(row['date'] as String),
        meals: meals,
      );
    }).toList();

    return WeeklyMealPlan.create(
      id: rows.isNotEmpty ? (rows.first['id'] as String? ?? '') : '',
      weekStartDate: weekStart,
      days: days,
    );
  }

  /// Map a Supabase meal row to a [Meal] domain model.
  Meal _mapToMeal(Map<String, dynamic> row) {
    return Meal(
      id: row['id'] as String,
      name: row['name'] as String,
      mealType: row['meal_type'] as String,
      calories: row['calories'] as int?,
      proteins: (row['proteins'] as num?)?.toDouble(),
      carbs: (row['carbs'] as num?)?.toDouble(),
      fats: (row['fats'] as num?)?.toDouble(),
      tags: List<String>.from(row['tags'] as List? ?? []),
      isCompleted: row['is_completed'] as bool? ?? false,
    );
  }

  /// Read [WeeklyMealPlan] from Hive for the given [weekKey].
  Either<Failure, WeeklyMealPlan> _readWeeklyPlanFromHive(String weekKey) {
    try {
      final cached = _box.get(weekKey);
      if (cached == null) {
        return const Left(CacheFailure('No cached plan for this week'));
      }
      final json = jsonDecode(cached as String) as Map<String, dynamic>;
      return Right(WeeklyMealPlan.fromJson(json));
    } catch (e) {
      return Left(CacheFailure('Failed to read from cache: $e'));
    }
  }

  /// ISO-8601 date string (YYYY-MM-DD) for Supabase queries and Hive keys.
  String _dateStr(DateTime date) => date.toIso8601String().substring(0, 10);

  /// Hive cache key — always the Monday of the given week.
  String _weekKey(DateTime weekStart) => _dateStr(_mondayOf(weekStart));

  /// Normalizes any date to its Monday (same logic as [WeeklyMealPlan.create]).
  DateTime _mondayOf(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }
}
