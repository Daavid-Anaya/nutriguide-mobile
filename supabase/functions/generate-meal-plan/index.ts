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
    return new Response(JSON.stringify({ error: "Missing Authorization header" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser(authHeader.replace("Bearer ", ""));

  if (authError || !user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
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
    const now = new Date();
    const hoursSinceLast =
      (now.getTime() - lastGenTime.getTime()) / (1000 * 60 * 60);
    if (hoursSinceLast < 24) {
      return new Response(
        JSON.stringify({ error: "Rate limit: 1 generation per day" }),
        {
          status: 429,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }
  }

  // 3. Parse body
  let body: GenerateRequest;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const { weekStart, profile, inventory } = body;

  // 4. Call OpenAI gpt-4o-mini with JSON mode
  const openaiApiKey = Deno.env.get("OPENAI_API_KEY");
  if (!openaiApiKey) {
    return new Response(JSON.stringify({ error: "OpenAI API key not configured" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const openaiResponse = await fetch(
    "https://api.openai.com/v1/chat/completions",
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${openaiApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        response_format: { type: "json_object" },
        messages: [
          {
            role: "system",
            content: `Eres un nutricionista experto. Genera un plan de comidas de 7 días en JSON.
Cada día debe tener exactamente 3 comidas (breakfast, lunch, dinner).
Cada comida debe incluir:
- name (string en español)
- mealType (exactamente uno de: breakfast, lunch, dinner, snack)
- calories (integer)
- proteins (float en gramos)
- carbs (float en gramos)
- fats (float en gramos)
- tags (array de strings con ingredientes clave en español, mínimo 3)

Formato de salida requerido:
{
  "days": [
    {
      "date": "YYYY-MM-DD",
      "meals": [...]
    }
  ]
}

Respeta las restricciones dietéticas y usa los ingredientes del inventario cuando sea posible.
El plan debe ser nutricionalmente balanceado y variado.`,
          },
          {
            role: "user",
            content: JSON.stringify({
              weekStart,
              dietaryRestrictions: profile.dietaryRestrictions,
              primaryGoal: profile.primaryGoal,
              availableIngredients: inventory.map((i) => i.name),
            }),
          },
        ],
        temperature: 0.7,
        max_tokens: 4000,
      }),
    },
  );

  if (!openaiResponse.ok) {
    const errorBody = await openaiResponse.text();
    console.error("OpenAI error:", errorBody);
    return new Response(JSON.stringify({ error: "LLM service error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const llmData = await openaiResponse.json();
  const rawContent = llmData.choices?.[0]?.message?.content;

  if (!rawContent) {
    return new Response(JSON.stringify({ error: "Empty LLM response" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // 5. Parse and validate minimal structure
  let planJson: { days: Array<{ date: string; meals: unknown[] }> };
  try {
    planJson = JSON.parse(rawContent);
  } catch {
    return new Response(
      JSON.stringify({ error: "Invalid JSON from LLM" }),
      {
        status: 422,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  if (
    !planJson.days ||
    !Array.isArray(planJson.days) ||
    planJson.days.length !== 7
  ) {
    return new Response(
      JSON.stringify({ error: "Invalid LLM response structure: expected 7 days" }),
      {
        status: 422,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
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
        calories: (meal.calories as number) ?? 0,
        proteins: (meal.proteins as number) ?? 0,
        carbs: (meal.carbs as number) ?? 0,
        fats: (meal.fats as number) ?? 0,
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
