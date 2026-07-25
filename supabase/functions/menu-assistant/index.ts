// supabase/functions/menu-assistant/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const GROQ_ENDPOINT = "https://api.groq.com/openai/v1/chat/completions";
const GROQ_MODEL = "llama-3.3-70b-versatile";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ── Auth ─────────────────────────────────────────────────────────────────
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: { user }, error: authError } = await supabase.auth.getUser(
      authHeader.replace("Bearer ", "")
    );
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Invalid token" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Request body ─────────────────────────────────────────────────────────
    const body = await req.json();
    const { message, conversation_history = [] } = body as {
      message: string;
      conversation_history: Array<{ role: "user" | "assistant"; content: string }>;
    };

    if (!message || typeof message !== "string" || message.trim().length === 0) {
      return new Response(JSON.stringify({ error: "message is required" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Fetch live menu from Supabase ─────────────────────────────────────────
    const { data: menuItems, error: menuErr } = await supabase
      .from("menu_items")
      .select("id, name, description, price, tags, category_id")
      .eq("is_available", true)
      .order("name");

    if (menuErr) {
      console.error("Menu fetch error:", menuErr);
      return new Response(JSON.stringify({ error: "Failed to load menu" }), {
        status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Build a compact menu context string with IDs embedded
    const menuContext = (menuItems ?? [])
      .map((item: any) => {
        const tags = Array.isArray(item.tags) && item.tags.length > 0
          ? ` [${item.tags.join(", ")}]`
          : "";
        const desc = item.description ? ` — ${item.description}` : "";
        return `• ${item.name} | $${Number(item.price).toFixed(2)}${desc}${tags} | ID:${item.id}`;
      })
      .join("\n");

    // ── System prompt ─────────────────────────────────────────────────────────
    const systemPrompt = `You are the friendly AI menu assistant for Bistro Go, a premium café and restaurant.
Your role is to help customers discover dishes, suggest items based on mood/budget/dietary preferences, 
explain ingredients, and recommend pairings.

## LIVE MENU
${menuContext}

## INSTRUCTIONS
- Always ground your recommendations in the menu above. Never invent dishes.
- When you recommend specific items, include their ID tag inline like this: **[ITEM_ID:uuid-here]**
  Example: "I'd suggest our Avocado Toast **[ITEM_ID:a1b2c3d4-...]** — it's light and fresh."
- You may recommend up to 4 items per response.
- Keep responses friendly, concise (2–4 sentences), and conversational.
- If asked about something not on the menu, politely say so and offer the closest alternative.
- Format currency as dollars (e.g. $12.99).`;

    // ── Call Groq API ─────────────────────────────────────────────────────────
    const groqApiKey = Deno.env.get("GROQ_API_KEY");
    if (!groqApiKey) {
      return new Response(JSON.stringify({ error: "GROQ_API_KEY not configured" }), {
        status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const messages = [
      { role: "system", content: systemPrompt },
      ...conversation_history.slice(-10), // keep last 10 turns for context
      { role: "user", content: message },
    ];

    const groqRes = await fetch(GROQ_ENDPOINT, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${groqApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: GROQ_MODEL,
        messages,
        max_tokens: 512,
        temperature: 0.7,
      }),
    });

    if (!groqRes.ok) {
      const groqErr = await groqRes.text();
      console.error("Groq API error:", groqErr);
      return new Response(JSON.stringify({ error: "AI service unavailable. Please try again." }), {
        status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const groqData = await groqRes.json();
    const rawReply: string = groqData?.choices?.[0]?.message?.content ?? "";

    // ── Parse recommended item IDs from the reply ─────────────────────────────
    const idRegex = /\[ITEM_ID:([a-zA-Z0-9\-]+)\]/g;
    const recommendedIds: string[] = [];
    let match;
    while ((match = idRegex.exec(rawReply)) !== null) {
      if (!recommendedIds.includes(match[1])) {
        recommendedIds.push(match[1]);
      }
    }

    // Remove the [ITEM_ID:...] tags from the displayed text
    const cleanReply = rawReply.replace(/\s*\[ITEM_ID:[a-zA-Z0-9\-]+\]/g, "").trim();

    // ── Return structured response ─────────────────────────────────────────────
    return new Response(
      JSON.stringify({
        reply: cleanReply,
        recommended_item_ids: recommendedIds,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );

  } catch (err) {
    console.error("Unexpected error:", err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
