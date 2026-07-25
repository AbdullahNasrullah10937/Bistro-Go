// supabase/functions/place-order/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
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

    // Get user from JWT
    const { data: { user }, error: authError } = await supabase.auth.getUser(
      authHeader.replace("Bearer ", "")
    );
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Invalid token" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await req.json();
    const { idempotency_key, cart_items, address_id, table_number, notes, payment_method, order_type } = body;

    if (!cart_items || cart_items.length === 0) {
      return new Response(JSON.stringify({ error: "Cart is empty" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Check idempotency
    if (idempotency_key) {
      const { data: existing } = await supabase
        .from("orders")
        .select("id")
        .eq("idempotency_key", idempotency_key)
        .single();
      if (existing) {
        return new Response(JSON.stringify({ order_id: existing.id }), {
          status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
    }

    // Fetch menu items to get current prices
    const menuItemIds = cart_items.map((i: any) => i.menu_item_id);
    const { data: menuItems, error: menuErr } = await supabase
      .from("menu_items")
      .select("id, name, price, is_available")
      .in("id", menuItemIds);

    if (menuErr || !menuItems) {
      return new Response(JSON.stringify({ error: "Failed to fetch menu items" }), {
        status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Validate availability
    const unavailable = menuItems.filter((m: any) => !m.is_available);
    if (unavailable.length > 0) {
      return new Response(JSON.stringify({
        error: `These items are currently unavailable: ${unavailable.map((m: any) => m.name).join(", ")}`,
      }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    // Calculate totals
    const TAX_RATE = 0.08;
    const resolvedOrderType = order_type || (table_number ? "dine_in" : "delivery");
    const DELIVERY_FEE = resolvedOrderType === "delivery" ? 2.99 : 0;
    let subtotal = 0;

    const orderItemsPayload = cart_items.map((ci: any) => {
      const menuItem = menuItems.find((m: any) => m.id === ci.menu_item_id);
      const lineTotal = (menuItem?.price || 0) * ci.quantity;
      subtotal += lineTotal;
      return {
        menu_item_id: ci.menu_item_id,
        item_name: menuItem?.name || "Item",
        quantity: ci.quantity,
        unit_price: menuItem?.price || 0,
        selected_addons: ci.selected_addons || [],
      };
    });

    const tax = +(subtotal * TAX_RATE).toFixed(2);
    const total = +(subtotal + tax + DELIVERY_FEE).toFixed(2);

    // Create order
    const { data: order, error: orderErr } = await supabase
      .from("orders")
      .insert({
        user_id: user.id,
        status: "placed",
        order_type: resolvedOrderType,
        subtotal: +subtotal.toFixed(2),
        tax,
        delivery_fee: DELIVERY_FEE,
        total,
        address_id: address_id || null,
        table_number: table_number || null,
        notes: notes || null,
        payment_method: payment_method || "cash",
        idempotency_key: idempotency_key || null,
      })
      .select("id")
      .single();


    if (orderErr || !order) {
      console.error("Order creation error:", orderErr);
      return new Response(JSON.stringify({ error: "Failed to create order" }), {
        status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Insert order items
    const { error: itemsErr } = await supabase
      .from("order_items")
      .insert(orderItemsPayload.map((item: any) => ({ ...item, order_id: order.id })));

    if (itemsErr) {
      // Rollback: delete the order
      await supabase.from("orders").delete().eq("id", order.id);
      return new Response(JSON.stringify({ error: "Failed to create order items" }), {
        status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Clear the user's cart
    await supabase.from("cart_items").delete().eq("user_id", user.id);

    // Log status history
    await supabase.from("order_status_history").insert({
      order_id: order.id,
      new_status: "placed",
      changed_by: user.id,
    });

    return new Response(JSON.stringify({ order_id: order.id }), {
      status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("Unexpected error:", err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
