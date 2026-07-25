# 📡 Supabase Edge Functions API Documentation

This document describes the API contracts, request payloads, response shapes, and error handling for the custom Supabase Edge Functions deployed for **Bistro Go**.

---

## 1. `place-order`

Computes real item prices, tax, delivery fee, checks item availability server-side, verifies idempotency, creates the order and order items, clears the customer's cart, and logs status history.

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
  "table_number": "optional-string",
  "notes": "Optional delivery instructions",
  "payment_method": "cash",
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
  "order_id": "b11b437c-9471-4acf-92d2-e60123456789"
}
```

### Error Responses
- `401 Unauthorized`: Missing or invalid JWT
- `400 Bad Request`: Cart is empty or items unavailable
- `500 Internal Server Error`: Database insertion failed

---

## 2. `update-order-status`

Validates admin/staff role permissions and enforces valid order state machine transitions. Updates `orders.status` and logs audit trail to `order_status_history`.

- **URL**: `https://<PROJECT_REF>.supabase.co/functions/v1/update-order-status`
- **Method**: `POST`
- **Headers**:
  - `Authorization`: `Bearer <ADMIN_JWT>`
  - `Content-Type`: `application/json`

### Allowed Transitions State Machine
```
placed     → confirmed | cancelled
confirmed  → preparing | cancelled
preparing  → ready     | cancelled
ready      → completed
completed  → (terminal state)
cancelled  → (terminal state)
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
  "updated_at": "2026-07-25T18:00:00Z"
}
```

### Error Responses
- `401 Unauthorized`: Missing or invalid JWT
- `403 Forbidden`: User profile role is not `admin` or `staff`
- `422 Unprocessable Entity`: Invalid status transition (e.g. `placed` → `completed`)

---

## 3. `menu-assistant`

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
  "reply": "I highly recommend our Full English Breakfast! It features fresh eggs, sausages, and beans.",
  "recommended_item_ids": [
    "550e8400-e29b-41d4-a716-446655440000"
  ]
}
```

### Error Responses
- `401 Unauthorized`: Missing or invalid JWT
- `400 Bad Request`: Message string is empty
- `502 Bad Gateway`: Groq API error or quota limit
