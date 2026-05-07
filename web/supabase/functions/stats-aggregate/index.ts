import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.10.0";

serve(async (req) => {
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
  };

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      throw new Error("Missing Authorization header");
    }

    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: userError } = await supabaseClient.auth.getUser();
    if (userError || !user) throw new Error("Unauthorized");

    const { period } = await req.json(); // e.g., 'week', 'month'

    // Mocking the aggregate query since exact SQL depends on further development.
    // In actual implementation, we would query the history_logs table.
    const { data, error } = await supabaseClient
      .from('history_logs')
      .select('calories, protein, carbs, fat, date_group')
      .eq('user_id', user.id)
      .limit(30);

    if (error) throw error;

    // Process data to compute trend averages (placeholder logic)
    const aggregated = {
        total_calories: data.reduce((acc: number, row: any) => acc + (row.calories || 0), 0),
        trends: data, // Could group by date
    };

    return new Response(JSON.stringify({ data: aggregated }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
