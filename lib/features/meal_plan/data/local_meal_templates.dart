// Spec: MEAL-GEN-003 sc1–sc3
// Design: AD-68, AD-76
// TDD: Phase 3 [GREEN] — offline fallback plan generation from bundled templates

import 'package:nutriguide_mobile/features/home/domain/meal.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/meal_plan_day.dart';
import 'package:nutriguide_mobile/features/meal_plan/domain/weekly_meal_plan.dart';

/// Offline-first meal template library (AD-68, AD-76).
///
/// Provides 21+ pre-defined meal templates organized by type (breakfast,
/// lunch, dinner) and annotated with dietary tags. The [generate] method
/// produces a deterministic 7-day [WeeklyMealPlan] without any network call.
///
/// Dietary filter: templates are filtered by [dietaryRestrictions]. If no
/// templates match (degraded mode — spec MEAL-GEN-003 sc2), the full
/// unfiltered list is used instead.
///
/// Determinism: selection uses `weekStart.day + weekStart.month` as a seed
/// so the same inputs always produce the same output (spec MEAL-GEN-003 sc3).
abstract final class LocalMealTemplates {
  // ── Template library ─────────────────────────────────────────────────────
  // 21+ templates covering breakfast/lunch/dinner.
  // Each template has: name, mealType, calories, proteins, carbs, fats, tags.
  // 'tags' drives both dietary filtering and shopping list generation (AD-69).
  static const List<Map<String, dynamic>> _templates = [
    // ── Breakfasts (vegetarian, alto en fibra) ──────────────────────────
    {
      'name': 'Avena con frutas y miel',
      'mealType': MealType.breakfast,
      'calories': 350,
      'proteins': 12.0,
      'carbs': 55.0,
      'fats': 8.0,
      'tags': ['vegetarian', 'avena', 'frutas', 'miel', 'alto en fibra'],
    },
    {
      'name': 'Yogur con granola y berries',
      'mealType': MealType.breakfast,
      'calories': 320,
      'proteins': 14.0,
      'carbs': 48.0,
      'fats': 7.0,
      'tags': ['vegetarian', 'yogur', 'granola', 'berries'],
    },
    {
      'name': 'Tostadas con aguacate y huevo',
      'mealType': MealType.breakfast,
      'calories': 410,
      'proteins': 18.0,
      'carbs': 35.0,
      'fats': 20.0,
      'tags': ['vegetarian', 'pan', 'aguacate', 'huevo'],
    },
    {
      'name': 'Batido verde de espinaca y banana',
      'mealType': MealType.breakfast,
      'calories': 280,
      'proteins': 8.0,
      'carbs': 52.0,
      'fats': 4.0,
      'tags': ['vegetarian', 'espinaca', 'banana', 'leche'],
    },
    {
      'name': 'Pancakes de avena con maple',
      'mealType': MealType.breakfast,
      'calories': 390,
      'proteins': 10.0,
      'carbs': 65.0,
      'fats': 9.0,
      'tags': ['vegetarian', 'avena', 'maple', 'huevo'],
    },
    {
      'name': 'Tortilla de huevos con verduras',
      'mealType': MealType.breakfast,
      'calories': 360,
      'proteins': 22.0,
      'carbs': 15.0,
      'fats': 22.0,
      'tags': ['vegetarian', 'huevo', 'verduras', 'tomate', 'pimiento'],
    },
    {
      'name': 'Pollo a la plancha con tostadas',
      'mealType': MealType.breakfast,
      'calories': 430,
      'proteins': 35.0,
      'carbs': 30.0,
      'fats': 12.0,
      'tags': ['pollo', 'pan', 'proteína'],
    },
    // ── Lunches (mixed dietary) ─────────────────────────────────────────
    {
      'name': 'Ensalada de quinoa con verduras',
      'mealType': MealType.lunch,
      'calories': 420,
      'proteins': 18.0,
      'carbs': 55.0,
      'fats': 12.0,
      'tags': ['vegetarian', 'quinoa', 'verduras', 'lechuga', 'tomate'],
    },
    {
      'name': 'Lentejas guisadas con arroz',
      'mealType': MealType.lunch,
      'calories': 480,
      'proteins': 22.0,
      'carbs': 72.0,
      'fats': 6.0,
      'tags': ['vegetarian', 'lentejas', 'arroz', 'zanahoria', 'cebolla'],
    },
    {
      'name': 'Wrap de vegetales con hummus',
      'mealType': MealType.lunch,
      'calories': 380,
      'proteins': 14.0,
      'carbs': 48.0,
      'fats': 14.0,
      'tags': ['vegetarian', 'tortilla', 'hummus', 'pimiento', 'zanahoria'],
    },
    {
      'name': 'Pollo al horno con batata',
      'mealType': MealType.lunch,
      'calories': 520,
      'proteins': 38.0,
      'carbs': 45.0,
      'fats': 14.0,
      'tags': ['pollo', 'batata', 'romero'],
    },
    {
      'name': 'Salmón con ensalada mediterránea',
      'mealType': MealType.lunch,
      'calories': 550,
      'proteins': 42.0,
      'carbs': 20.0,
      'fats': 28.0,
      'tags': ['salmón', 'lechuga', 'tomate', 'aceitunas', 'limón'],
    },
    {
      'name': 'Pasta integral con salsa de tomate y albahaca',
      'mealType': MealType.lunch,
      'calories': 460,
      'proteins': 16.0,
      'carbs': 78.0,
      'fats': 8.0,
      'tags': ['vegetarian', 'pasta', 'tomate', 'albahaca', 'ajo'],
    },
    {
      'name': 'Arroz con frijoles y aguacate',
      'mealType': MealType.lunch,
      'calories': 500,
      'proteins': 20.0,
      'carbs': 70.0,
      'fats': 16.0,
      'tags': ['vegetarian', 'arroz', 'frijoles', 'aguacate'],
    },
    // ── Dinners (mixed dietary) ─────────────────────────────────────────
    {
      'name': 'Crema de calabaza con pan integral',
      'mealType': MealType.dinner,
      'calories': 340,
      'proteins': 10.0,
      'carbs': 50.0,
      'fats': 10.0,
      'tags': ['vegetarian', 'calabaza', 'pan', 'cebolla', 'ajo'],
    },
    {
      'name': 'Revuelto de tofu con verduras salteadas',
      'mealType': MealType.dinner,
      'calories': 360,
      'proteins': 24.0,
      'carbs': 28.0,
      'fats': 16.0,
      'tags': ['vegetarian', 'tofu', 'pimiento', 'espinaca', 'ajo'],
    },
    {
      'name': 'Gazpacho con tostada de aguacate',
      'mealType': MealType.dinner,
      'calories': 290,
      'proteins': 8.0,
      'carbs': 32.0,
      'fats': 14.0,
      'tags': ['vegetarian', 'tomate', 'pepino', 'pimiento', 'aguacate', 'pan'],
    },
    {
      'name': 'Pechuga de pollo con brócoli al vapor',
      'mealType': MealType.dinner,
      'calories': 420,
      'proteins': 40.0,
      'carbs': 18.0,
      'fats': 16.0,
      'tags': ['pollo', 'brócoli', 'limón'],
    },
    {
      'name': 'Merluza al horno con espárragos',
      'mealType': MealType.dinner,
      'calories': 380,
      'proteins': 36.0,
      'carbs': 14.0,
      'fats': 14.0,
      'tags': ['merluza', 'espárragos', 'limón', 'ajo'],
    },
    {
      'name': 'Curry de garbanzos con arroz basmati',
      'mealType': MealType.dinner,
      'calories': 490,
      'proteins': 20.0,
      'carbs': 68.0,
      'fats': 14.0,
      'tags': ['vegetarian', 'garbanzos', 'arroz', 'curry', 'coco'],
    },
    {
      'name': 'Pizza integral de verduras',
      'mealType': MealType.dinner,
      'calories': 440,
      'proteins': 18.0,
      'carbs': 60.0,
      'fats': 14.0,
      'tags': ['vegetarian', 'masa', 'tomate', 'pimiento', 'queso'],
    },
    {
      'name': 'Sopa de pollo con fideos',
      'mealType': MealType.dinner,
      'calories': 380,
      'proteins': 30.0,
      'carbs': 40.0,
      'fats': 8.0,
      'tags': ['pollo', 'fideos', 'zanahoria', 'cebolla', 'ajo'],
    },
  ];

  // ── Meal types to assign per day ─────────────────────────────────────────
  static const _mealTypes = [
    MealType.breakfast,
    MealType.lunch,
    MealType.dinner,
  ];

  /// Generates a deterministic 7-day [WeeklyMealPlan] from bundled templates.
  ///
  /// Filters [_templates] by [dietaryRestrictions] — a template is included
  /// when ALL restrictions match at least one of its tags (substring, case-
  /// insensitive). If no templates survive the filter (degraded mode), the
  /// full unfiltered list is used instead (spec MEAL-GEN-003 sc2).
  ///
  /// Selection is deterministic: uses `weekStart.day + weekStart.month` as a
  /// seed so the same inputs always return the same plan (spec MEAL-GEN-003 sc3).
  static WeeklyMealPlan generate({
    required DateTime weekStart,
    required List<String> dietaryRestrictions,
  }) {
    // 1. Filter templates by dietary restrictions
    var pool = _filterByRestrictions(_templates, dietaryRestrictions);

    // 2. Degraded mode: fall back to unfiltered if no templates match
    if (pool.isEmpty) pool = _templates;

    // 3. Deterministic seed (spec MEAL-GEN-003 sc3)
    final seed = weekStart.day + weekStart.month;

    // 4. Build 7 days
    final days = List.generate(7, (dayIndex) {
      final dayDate = weekStart.add(Duration(days: dayIndex));
      final meals = <Meal>[];

      for (final mealType in _mealTypes) {
        final typePool =
            pool.where((t) => t['mealType'] == mealType).toList();
        if (typePool.isNotEmpty) {
          final idx = (seed + dayIndex + _mealTypeIndex(mealType)) %
              typePool.length;
          final template = typePool[idx];
          meals.add(_mealFromTemplate(template, dayDate, mealType));
        }
      }

      return MealPlanDay(date: dayDate, meals: meals);
    });

    return WeeklyMealPlan.create(
      id: 'local-${weekStart.toIso8601String().substring(0, 10)}',
      weekStartDate: weekStart,
      days: days,
      isLocalFallback: true,
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static List<Map<String, dynamic>> _filterByRestrictions(
    List<Map<String, dynamic>> templates,
    List<String> restrictions,
  ) {
    if (restrictions.isEmpty) return templates;

    return templates.where((template) {
      final tags = List<String>.from(template['tags'] as List);
      return restrictions.every(
        (restriction) => tags.any(
          (tag) => tag.toLowerCase().contains(restriction.toLowerCase()),
        ),
      );
    }).toList();
  }

  static Meal _mealFromTemplate(
    Map<String, dynamic> template,
    DateTime date,
    String mealType,
  ) {
    final dateStr = date.toIso8601String().substring(0, 10);
    return Meal(
      id: 'local-$dateStr-$mealType',
      name: template['name'] as String,
      mealType: mealType,
      calories: template['calories'] as int?,
      proteins: (template['proteins'] as num?)?.toDouble(),
      carbs: (template['carbs'] as num?)?.toDouble(),
      fats: (template['fats'] as num?)?.toDouble(),
      tags: List<String>.from(template['tags'] as List),
    );
  }

  static int _mealTypeIndex(String mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return 0;
      case MealType.lunch:
        return 1;
      case MealType.dinner:
        return 2;
      default:
        return 3;
    }
  }
}
