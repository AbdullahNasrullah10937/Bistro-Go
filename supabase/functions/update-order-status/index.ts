// supabase/functions/update-order-status/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Valid order statuses
const VALID_STATUSES = ["placed", "confirmed", "preparing", "ready", "completed", "cancelled"] as const;
type OrderStatus = typeof VALID_STATUSES[number];

// Allowed state transitions — terminal states ('completed', 'cancelled') have no outgoing transitions
const ALLOWED_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  placed:     ["confirmed", "cancelled"],
  confirmed:  ["preparing", "cancelled"],
  preparing:  ["ready", "cancelled"],
  ready:      ["completed"],
  completed:  [],   // terminal
  cancelled:  [],   // terminal
};

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

    // Verify JWT and get calling user
    const { data: { user }, error: authError } = await supabase.auth.getUser(
      authHeader.replace("Bearer ", "")
    );
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Invalid token" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Role Check: must be admin or staff ───────────────────────────────────
    const { data: profile, error: profileErr } = await supabase
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .single();

    if (profileErr || !profile) {
      return new Response(JSON.stringify({ error: "Profile not found" }), {
        status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (!["admin", "staff"].includes(profile.role)) {
      return new Response(JSON.stringify({ error: "Forbidden: admin or staff role required" }), {
        status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Request body ─────────────────────────────────────────────────────────
    const body = await req.json();
    const { order_id, new_status } = body;

    if (!order_id || typeof order_id !== "string") {
      return new Response(JSON.stringify({ error: "order_id is required" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (!new_status || !VALID_STATUSES.includes(new_status as OrderStatus)) {
      return new Response(JSON.stringify({
        error: `Invalid status. Must be one of: ${VALID_STATUSES.join(", ")}`,
      }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    // ── Fetch current order ───────────────────────────────────────────────────
    const { data: order, error: fetchErr } = await supabase
      .from("orders")
      .select("id, status")
      .eq("id", order_id)
      .single();

    if (fetchErr || !order) {
      return new Response(JSON.stringify({ error: "Order not found" }), {
        status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const currentStatus = order.status as OrderStatus;
    const targetStatus = new_status as OrderStatus;

    // ── Validate transition ───────────────────────────────────────────────────
    const allowedNext = ALLOWED_TRANSITIONS[currentStatus];

    if (allowedNext.length === 0) {
      return new Response(JSON.stringify({
        error: `Order is already in a terminal state: '${currentStatus}'. No further updates allowed.`,
      }), { status: 422, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    if (!allowedNext.includes(targetStatus)) {
      return new Response(JSON.stringify({
        error: `Invalid transition from '${currentStatus}' to '${targetStatus}'. Allowed next statuses: ${allowedNext.join(", ")}`,
      }), { status: 422, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    // ── Update orders table ───────────────────────────────────────────────────
    const { error: updateErr } = await supabase
      .from("orders")
      .update({
        status: targetStatus,
        updated_at: new Date().toISOString(),
      })
      .eq("id", order_id);

    if (updateErr) {
      console.error("Order update error:", updateErr);
      return new Response(JSON.stringify({ error: "Failed to update order status" }), {
        status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Insert status history row ─────────────────────────────────────────────
    const { error: historyErr } = await supabase
      .from("order_status_history")
      .insert({
        order_id,
        old_status: currentStatus,
        new_status: targetStatus,
        changed_by: user.id,
      });

    if (historyErr) {
      // Non-fatal — log but don't fail the response
      console.error("Status history insert error:", historyErr);
    }

    // ── Return updated order ──────────────────────────────────────────────────
    const { data: updatedOrder, error: refetchErr } = await supabase
      .from("orders")
      .select("*, order_items(*)")
      .eq("id", order_id)
      .single();

    if (refetchErr || !updatedOrder) {
      // Status was updated successfully; return minimal confirmation
      return new Response(JSON.stringify({ order_id, status: targetStatus }), {
        status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify(updatedOrder), {
      status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (err) {
    console.error("Unexpected error:", err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
