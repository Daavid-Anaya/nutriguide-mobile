import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface GenerateRequest {
  weekStart: string; // ISO8601 date "YYYY-MM-DD"
  profile: {
    dietaryRestrictions: string[];
    primaryGoal: string | null;
  };
  inventory: Array<{ name: string; nutriscoreGrade: string }>;
}

interface MealResponse {
  id: string;
  name: string;
  mealType: "breakfast" | "lunch" | "dinner" | "snack";
  calories: number;
  proteins: number;
  carbs: number;
  fats: number;
  tags: string[];
  isCompleted: boolean;
}

interface DayResponse {
  date: string;
  meals: MealResponse[];
}

interface WeeklyMealPlanResponse {
  id: string;
  weekStartDate: string;
  days: DayResponse[];
  isLocalFallback: boolean;
}

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------

serve(async (req: Request) => {
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
  };

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // 1. Auth: extract JWT from Authorization header
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(
      JSON.stringify({ error: "Missing Authorization header" }),
      { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const { data: { user }, error: authError } = await supabase.auth.getUser(
    authHeader.replace("Bearer ", ""),
  );

  if (authError || !user) {
    return new Response(
      JSON.stringify({ error: "Unauthorized" }),
      { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  // 2. Rate limit: check last generation timestamp from meal_plans table
  const { data: lastPlan } = await supabase
    .from("meal_plans")
    .select("created_at")
    .eq("user_id", user.id)
    .order("created_at", { ascending: false })
    .limit(1)
    .single();

  if (lastPlan) {
    const lastGenTime = new Date(lastPlan.created_at);
    const hoursSinceLast =
      (Date.now() - lastGenTime.getTime()) / (1000 * 60 * 60);
    if (hoursSinceLast < 24) {
      return new Response(
        JSON.stringify({ error: "Rate limit: 1 generation per day" }),
        { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }
  }

  // 3. Parse body
  let body: GenerateRequest;
  try {
    body = await req.json();
  } catch {
    return new Response(
      JSON.stringify({ error: "Invalid JSON body" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const { weekStart, profile, inventory } = body;

  // 4. Call Gemini 2.0 Flash with JSON response schema
  const geminiApiKey = Deno.env.get("GEMINI_API_KEY");
  if (!geminiApiKey) {
    return new Response(
      JSON.stringify({ error: "Gemini API key not configured" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const prompt = `Eres un nutricionista experto. Genera un plan de comidas de 7 días en JSON.
Cada día debe tener exactamente 3 comidas (breakfast, lunch, dinner).
Cada comida debe incluir:
- name (string en español, nombre del plato)
- mealType (exactamente uno de: breakfast, lunch, dinner)
- calories (integer, kilocalorías)
- proteins (float, gramos de proteína)
- carbs (float, gramos de carbohidratos)
- fats (float, gramos de grasas)
- tags (array de strings con ingredientes clave en español, mínimo 3)

weekStart: ${weekStart}
Restricciones dietéticas: ${profile.dietaryRestrictions.join(", ") || "ninguna"}
Objetivo principal: ${profile.primaryGoal ?? "salud general"}
Ingredientes disponibles en inventario: ${inventory.map((i) => i.name).join(", ") || "ninguno"}

Respeta las restricciones dietéticas, usa ingredientes del inventario cuando sea posible.
El plan debe ser nutricionalmente balanceado y variado. Usa fechas YYYY-MM-DD empezando desde ${weekStart}.

Devuelve SOLO el JSON con este formato exacto:
{
  "days": [
    {
      "date": "YYYY-MM-DD",
      "meals": [
        {
          "name": "...",
          "mealType": "breakfast",
          "calories": 350,
          "proteins": 15.0,
          "carbs": 45.0,
          "fats": 10.0,
          "tags": ["huevo", "avena", "leche"]
        }
      ]
    }
  ]
}`;

  const geminiUrl =
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${geminiApiKey}`;

  const geminiResponse = await fetch(geminiUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ role: "user", parts: [{ text: prompt }] }],
      generationConfig: {
        responseMimeType: "application/json",
        temperature: 0.7,
        maxOutputTokens: 4096,
      },
    }),
  });

  if (!geminiResponse.ok) {
    const errorBody = await geminiResponse.text();
    console.error("Gemini error:", errorBody);
    return new Response(
      JSON.stringify({ error: "LLM service error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const geminiData = await geminiResponse.json();
  const rawContent =
    geminiData.candidates?.[0]?.content?.parts?.[0]?.text;

  if (!rawContent) {
    return new Response(
      JSON.stringify({ error: "Empty LLM response" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  // 5. Parse and validate structure
  let planJson: { days: Array<{ date: string; meals: unknown[] }> };
  try {
    planJson = JSON.parse(rawContent);
  } catch {
    return new Response(
      JSON.stringify({ error: "Invalid JSON from LLM" }),
      { status: 422, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  if (!planJson.days || !Array.isArray(planJson.days) || planJson.days.length !== 7) {
    return new Response(
      JSON.stringify({ error: "Invalid LLM response: expected 7 days" }),
      { status: 422, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  // 6. Assign UUIDs and build typed response
  const planId = crypto.randomUUID();
  const response: WeeklyMealPlanResponse = {
    id: planId,
    weekStartDate: weekStart,
    days: planJson.days.map((day) => ({
      date: day.date,
      meals: (day.meals as Array<Record<string, unknown>>).map((meal) => ({
        id: crypto.randomUUID(),
        name: (meal.name as string) ?? "",
        mealType: (meal.mealType as MealResponse["mealType"]) ?? "breakfast",
        calories: Number(meal.calories) || 0,
        proteins: Number(meal.proteins) || 0,
        carbs: Number(meal.carbs) || 0,
        fats: Number(meal.fats) || 0,
        tags: Array.isArray(meal.tags) ? (meal.tags as string[]) : [],
        isCompleted: false,
      })),
    })),
    isLocalFallback: false,
  };

  return new Response(JSON.stringify(response), {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
