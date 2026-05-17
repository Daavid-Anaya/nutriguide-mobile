-- =============================================================================
-- NutriGuide Mobile — Initial Schema
-- supabase-core change | 2026-05-16
-- =============================================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ---------------------------------------------------------------------------
-- 1. profiles (1:1 with auth.users)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT 'Usuario',
  email TEXT NOT NULL DEFAULT '',
  avatar_url TEXT,
  dietary_restrictions TEXT[] DEFAULT '{}',
  primary_goal TEXT,
  grocery_budget DOUBLE PRECISION,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- ---------------------------------------------------------------------------
-- 2. shopping_lists
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.shopping_lists (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT 'Mi lista',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.shopping_lists ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can CRUD own lists" ON public.shopping_lists
  FOR ALL USING (auth.uid() = user_id);

CREATE INDEX idx_shopping_lists_user ON public.shopping_lists(user_id);

-- ---------------------------------------------------------------------------
-- 3. shopping_items
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.shopping_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  list_id UUID NOT NULL REFERENCES public.shopping_lists(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  quantity DOUBLE PRECISION,
  unit TEXT,
  estimated_price DOUBLE PRECISION,
  is_checked BOOLEAN NOT NULL DEFAULT false,
  product_barcode TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.shopping_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can CRUD own items" ON public.shopping_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.shopping_lists sl
      WHERE sl.id = shopping_items.list_id AND sl.user_id = auth.uid()
    )
  );

CREATE INDEX idx_shopping_items_list ON public.shopping_items(list_id);

-- ---------------------------------------------------------------------------
-- 4. scanned_products
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.scanned_products (
  barcode TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  brands TEXT,
  image_url TEXT,
  nutriscore_grade TEXT,
  energy DOUBLE PRECISION,
  fat DOUBLE PRECISION,
  saturated_fat DOUBLE PRECISION,
  carbohydrates DOUBLE PRECISION,
  sugars DOUBLE PRECISION,
  proteins DOUBLE PRECISION,
  salt DOUBLE PRECISION,
  fiber DOUBLE PRECISION,
  scanned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (barcode, user_id)
);

ALTER TABLE public.scanned_products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can CRUD own products" ON public.scanned_products
  FOR ALL USING (auth.uid() = user_id);

CREATE INDEX idx_scanned_products_user ON public.scanned_products(user_id);

-- ---------------------------------------------------------------------------
-- 5. meal_plans
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.meal_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.meal_plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can CRUD own plans" ON public.meal_plans
  FOR ALL USING (auth.uid() = user_id);

CREATE INDEX idx_meal_plans_user_date ON public.meal_plans(user_id, date);

-- ---------------------------------------------------------------------------
-- 6. meals
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.meals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  plan_id UUID NOT NULL REFERENCES public.meal_plans(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  meal_type TEXT NOT NULL CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
  calories INT,
  tags TEXT[] DEFAULT '{}',
  is_completed BOOLEAN NOT NULL DEFAULT false
);

ALTER TABLE public.meals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can CRUD own meals" ON public.meals
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.meal_plans mp
      WHERE mp.id = meals.plan_id AND mp.user_id = auth.uid()
    )
  );

CREATE INDEX idx_meals_plan ON public.meals(plan_id);

-- ---------------------------------------------------------------------------
-- 7. Trigger: auto-create profile on signup
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, created_at, updated_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', 'Usuario'),
    COALESCE(NEW.email, ''),
    NOW(),
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER create_profile_on_signup
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ---------------------------------------------------------------------------
-- 8. updated_at auto-refresh for profiles
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE OR REPLACE TRIGGER shopping_lists_updated_at
  BEFORE UPDATE ON public.shopping_lists
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
