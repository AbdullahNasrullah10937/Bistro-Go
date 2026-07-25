# 📡 Supabase Edge Functions API Documentation

This document describes the API contracts, request payloads, response shapes, and error handling for the custom Supabase Edge Functions deployed for **Bistro Go**.

---

## 1. `place-order`

Computes real item prices, tax, delivery fee, checks item availability server-side, verifies idempotency, creates the order and order items, and logs status history. For cash orders, clears cart immediately; for card orders, sets status to `pending_payment` and leaves cart intact until payment confirmation.

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
  "address_id": "optional-uuid",
  "delivery_address": "House 123, Street 5, DHA Phase 6, Lahore",
  "table_number": "optional-string",
  "notes": "Optional delivery instructions",
  "payment_method": "card", // "cash" | "card"
  "cart_items": [
    {
      "menu_item_id": "550e8400-e29b-41d4-a716-446655440000",
      "quantity": 2,
      "selected_addons": ["addon-id-1"]
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

---

## 2. `create-payment-intent`

Fetches the server-calculated order total directly from the database and creates a Stripe `PaymentIntent` via the Deno Stripe SDK.

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

---

## 3. `confirm-order-payment`

Verifies with Stripe server-side that the `PaymentIntent` has `succeeded` and metadata matches. Transitions order status to `placed`, logs `order_status_history`, and clears the customer's cart.

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

---

## 4. `update-order-status`

Validates admin/staff role permissions and enforces valid order state machine transitions.

- **URL**: `https://<PROJECT_REF>.supabase.co/functions/v1/update-order-status`
- **Method**: `POST`
- **Headers**:
  - `Authorization`: `Bearer <ADMIN_JWT>`
  - `Content-Type`: `application/json`

---

## 5. `menu-assistant`

AI menu recommendations powered by Groq Llama 3.3 70B.

- **URL**: `https://<PROJECT_REF>.supabase.co/functions/v1/menu-assistant`
- **Method**: `POST`
