-- Migration: 002_meal_macros
-- Adds macronutrient columns to the meals table.
-- All columns are NULLABLE to maintain backward compatibility with existing
-- meal rows that predate this migration (spec MEAL-DOMAIN-001).

ALTER TABLE public.meals
  ADD COLUMN IF NOT EXISTS proteins DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS carbs DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS fats DOUBLE PRECISION;
