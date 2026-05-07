import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const PYTHON_BACKEND_URL = Deno.env.get("PYTHON_BACKEND_URL") || "http://localhost:8000";

serve(async (req) => {
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { query } = await req.json();

    if (!query) {
      return new Response(JSON.stringify({ error: "Missing query" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Proxy request to the Python Nutrition Vector DB Service
    const response = await fetch(`${PYTHON_BACKEND_URL}/search`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ text: query })
    });

    if (!response.ok) {
      throw new Error("Failed to fetch from Python Backend");
    }

    const data = await response.json();

    return new Response(JSON.stringify({ data }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
