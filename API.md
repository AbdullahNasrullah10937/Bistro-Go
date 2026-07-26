# 📡 Supabase Edge Functions API Documentation

This document describes the API contracts, request payloads, response shapes, and error handling for all 5 custom Supabase Edge Functions deployed for **Bistro Go**.

---

## 1. `place-order`

Computes real item prices, tax, and delivery fee server-side, checks item availability, verifies idempotency, creates the order and order items, and logs status history. 
- **Cash Orders (`payment_method: "cash"`)**: Sets status to `placed` and clears the user's cart immediately.
- **Card Orders (`payment_method: "card"`)**: Sets status to `pending_payment` and preserves the cart until payment confirmation.

- **URL**: `https://<PROJECT_REF>.supabase.co/functions/v1/place-order`
- **Method**: `POST`
- **Headers**:
  - `Authorization`: `Bearer <USER_JWT>`
  - `Content-Type`: `application/json`

### Request Body
```json
{
  "idempotency_key": "uuid-v4-string",
  "order_type": "delivery", // "delivery" | "dine_in" | "takeaway"
  "address_id": "550e8400-e29b-41d4-a716-446655440000",
  "delivery_address": "House 123, Street 5, DHA Phase 6, Lahore",
  "table_number": null,
  "notes": "Please leave at front door",
  "payment_method": "card", // "cash" | "card"
  "cart_items": [
    {
      "menu_item_id": "550e8400-e29b-41d4-a716-446655440000",
      "quantity": 2,
      "selected_addons": ["addon-uuid-1"]
    }
  ]
}
```

### Success Response (`200 OK`)
```json
{
  "order_id": "b11b437c-9471-4acf-92d2-e60123456789",
  "total": 32.98,
  "status": "pending_payment"
}
```

### Error Responses
- `401 Unauthorized`: Missing or invalid JWT session.
- `400 Bad Request`: Cart is empty or items unavailable.
- `500 Internal Server Error`: Database insertion failure.

---

## 2. `create-payment-intent`

Fetches the server-calculated order total directly from `public.orders` and creates a Stripe `PaymentIntent` via the Deno Stripe SDK. The `STRIPE_SECRET_KEY` stays strictly server-side.

- **URL**: `https://<PROJECT_REF>.supabase.co/functions/v1/create-payment-intent`
- **Method**: `POST`
- **Headers**:
  - `Authorization`: `Bearer <USER_JWT>`
  - `Content-Type`: `application/json`

### Request Body
```json
{
  "order_id": "b11b437c-9471-4acf-92d2-e60123456789"
}
```

### Success Response (`200 OK`)
```json
{
  "client_secret": "pi_3MtwBwLkdIwHu7ix08aD5sM_secret_35987158971",
  "payment_intent_id": "pi_3MtwBwLkdIwHu7ix08aD5sM"
}
```

### Error Responses
- `401 Unauthorized`: Missing or invalid JWT.
- `404 Not Found`: Order ID does not exist.
- `403 Forbidden`: Authenticated user does not own the target order.
- `500 Internal Server Error`: Stripe secret key missing or API error.

---

## 3. `confirm-order-payment`

Verifies with Stripe server-side that the `PaymentIntent` has `succeeded` and metadata (`order_id`, `user_id`) matches. Transitions order status to `placed`, updates `payment_status` to `succeeded`, logs `order_status_history`, and clears the customer's cart.

- **URL**: `https://<PROJECT_REF>.supabase.co/functions/v1/confirm-order-payment`
- **Method**: `POST`
- **Headers**:
  - `Authorization`: `Bearer <USER_JWT>`
  - `Content-Type`: `application/json`

### Request Body
```json
{
  "order_id": "b11b437c-9471-4acf-92d2-e60123456789",
  "payment_intent_id": "pi_3MtwBwLkdIwHu7ix08aD5sM"
}
```

### Success Response (`200 OK`)
```json
{
  "success": true,
  "order_id": "b11b437c-9471-4acf-92d2-e60123456789",
  "status": "placed"
}
```

### Error Responses
- `401 Unauthorized`: Missing or invalid JWT.
- `400 Bad Request`: PaymentIntent status is not `succeeded` or metadata mismatch.
- `500 Internal Server Error`: Database update failure.

---

## 4. `update-order-status`

Validates admin/staff role permissions and enforces valid order state machine transitions. Updates `orders.status` and logs audit trail to `order_status_history`.

- **URL**: `https://<PROJECT_REF>.supabase.co/functions/v1/update-order-status`
- **Method**: `POST`
- **Headers**:
  - `Authorization`: `Bearer <ADMIN_JWT>`
  - `Content-Type`: `application/json`

### Allowed State Machine Transitions
```
pending_payment → placed    | cancelled
placed          → confirmed | cancelled
confirmed       → preparing | cancelled
preparing       → ready     | cancelled
ready           → completed
completed       → (terminal state)
cancelled       → (terminal state)
```

### Request Body
```json
{
  "order_id": "b11b437c-9471-4acf-92d2-e60123456789",
  "new_status": "confirmed" // "placed" | "confirmed" | "preparing" | "ready" | "completed" | "cancelled"
}
```

### Success Response (`200 OK`)
```json
{
  "id": "b11b437c-9471-4acf-92d2-e60123456789",
  "status": "confirmed",
  "subtotal": 14.99,
  "tax": 1.20,
  "delivery_fee": 2.99,
  "total": 19.18,
  "updated_at": "2026-07-26T09:00:00Z"
}
```

### Error Responses
- `401 Unauthorized`: Missing or invalid JWT.
- `403 Forbidden`: User profile role is not `admin` or `staff`.
- `422 Unprocessable Entity`: Invalid status transition (e.g., `placed` → `completed`).

---

## 5. `menu-assistant`

Fetches live available menu items from Supabase, grounds the system prompt in real items with prices and tags, calls Groq API (Llama 3.3 70B Versatile), and returns a structured response with recommended menu item IDs for inline tappable product cards.

- **URL**: `https://<PROJECT_REF>.supabase.co/functions/v1/menu-assistant`
- **Method**: `POST`
- **Headers**:
  - `Authorization`: `Bearer <USER_JWT>`
  - `Content-Type`: `application/json`

### Request Body
```json
{
  "message": "Recommend something light for breakfast under $15",
  "conversation_history": [
    {"role": "user", "content": "Hi"},
    {"role": "assistant", "content": "Welcome to Bistro Go!"}
  ]
}
```

### Success Response (`200 OK`)
```json
{
  "reply": "I highly recommend our Artisan Avocado Toast! It features smashed avocado, poached egg, sourdough, and microgreens.",
  "recommended_item_ids": [
    "550e8400-e29b-41d4-a716-446655440000"
  ]
}
```

### Error Responses
- `401 Unauthorized`: Missing or invalid JWT.
- `400 Bad Request`: Message string is empty.
- `502 Bad Gateway`: Groq API error or quota limit.
