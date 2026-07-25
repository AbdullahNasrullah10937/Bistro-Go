// supabase/functions/confirm-order-payment/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Stripe from "https://esm.sh/stripe@14.21.0?target=deno";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ── Auth Check ───────────────────────────────────────────────────────────
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

    // ── Request Body ─────────────────────────────────────────────────────────
    const body = await req.json();
    const { order_id, payment_intent_id } = body;
    if (!order_id || !payment_intent_id) {
      return new Response(JSON.stringify({ error: "order_id and payment_intent_id are required" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Stripe Verification ──────────────────────────────────────────────────
    const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY");
    if (!stripeSecretKey) {
      return new Response(JSON.stringify({ error: "STRIPE_SECRET_KEY not configured" }), {
        status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    const stripe = new Stripe(stripeSecretKey, {
      apiVersion: "2023-10-16",
      httpClient: Stripe.createFetchHttpClient(),
    });

    const paymentIntent = await stripe.paymentIntents.retrieve(payment_intent_id);

    if (!paymentIntent) {
      return new Response(JSON.stringify({ error: "PaymentIntent not found on Stripe" }), {
        status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (paymentIntent.status !== "succeeded") {
      return new Response(JSON.stringify({
        error: `Payment has not succeeded. Current status: ${paymentIntent.status}`
      }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    // Verify metadata and ownership
    if (paymentIntent.metadata.order_id !== order_id) {
      return new Response(JSON.stringify({ error: "PaymentIntent order_id mismatch" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (paymentIntent.metadata.user_id !== user.id) {
      return new Response(JSON.stringify({ error: "PaymentIntent user_id mismatch" }), {
        status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Update Order Status in Database ──────────────────────────────────────
    const { error: updateErr } = await supabase
      .from("orders")
      .update({
        status: "placed",
        payment_status: "succeeded",
        payment_intent_id: payment_intent_id,
        updated_at: new Date().toISOString(),
      })
      .eq("id", order_id)
      .eq("user_id", user.id);

    if (updateErr) {
      console.error("Order payment update error:", updateErr);
      return new Response(JSON.stringify({ error: "Failed to update order payment status" }), {
        status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Insert status history row
    await supabase.from("order_status_history").insert({
      order_id: order_id,
      old_status: "pending_payment",
      new_status: "placed",
      changed_by: user.id,
    });

    // Clear cart items for this customer now that payment is confirmed
    await supabase.from("cart_items").delete().eq("user_id", user.id);

    return new Response(JSON.stringify({ success: true, order_id, status: "placed" }), {
      status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (err) {
    console.error("Unexpected error in confirm-order-payment:", err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
