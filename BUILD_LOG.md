# 🪵 BUILD_LOG.md — Bistro Go Architecture & Implementation Log

**Developer**: Abdullah Nasrullah  
**Project**: Bistro Go — Café & Restaurant Mobile Ordering App  
**Core Stack**: Flutter, Supabase (PostgreSQL, Auth, RLS, Storage, Realtime, Edge Functions), Stripe (Test Mode), Groq API (Llama 3.3 70B)

---

## 1. What Was Built

### Customer Mobile Experience
- **Authentication & Security**: Email/Password login + signup, Google OAuth with custom deep linking scheme (`io.supabase.bistro-go://login-callback`), forgot password flow, and automatic JWT session restoration on app relaunch.
- **Interactive Menu**: Category tabs, live keyword search, price & dietary tag filtering, high-resolution product photography, item detail view with custom add-ons and quantity steppers.
- **Cart Management**: Per-user isolated cart with real-time subtotal, tax, delivery fee calculation, and empty state illustrations.
- **Saved Address Selector**: Full address management allowing users to save, edit, set defaults, and select delivery addresses during checkout via bottom-sheet modal or add new addresses on the fly.
- **Flexible Order Modes**: 3-way toggle (**Delivery**, **Takeaway**, **Dine-In**), dynamically adjusting UI inputs (address selector vs. table number) and automatically waiving delivery fees for non-delivery orders.
- **Production-Grade Payment Integration**:
  - **Cash on Delivery (COD)**: Instant order placement.
  - **Stripe Card Payments**: Two-phase payment architecture using native Stripe `PaymentSheet` via Deno serverless Edge Functions (`create-payment-intent`, `confirm-order-payment`). Leaves cart intact during payment attempts and only clears upon server-verified payment success.
- **Live Order Tracking**: Supabase Realtime WebSocket stream rendering an interactive 5-stage status timeline (**Placed** → **Confirmed** → **Preparing** → **Ready** → **Completed**).
- **AI Menu Assistant**: AI recommendation engine powered by Groq Llama 3.3 70B called server-side via `menu-assistant` Edge Function. Renders live, interactive `MenuItemCard` widgets directly inline in the chat bubble.

### Kitchen & Admin Management Portal
- **Database Role-Gated Access**: `/admin/login` portal guarded by `public.profiles.role` (`admin` / `staff`) enforced directly at the Postgres RLS layer.
- **Live Orders Kitchen Dashboard**: Realtime WebSocket feed of active orders with new-order alert toasts, status filters, and detail modals.
- **Enforced State Machine**: Order status transitions validated server-side via `update-order-status` Edge Function to block illegal status changes (e.g. `placed` → `completed`).
- **Menu Management CRUD**: Complete control over menu items and categories (Add, Edit, Delete, Toggle Availability, Price adjustment, Image Upload to Supabase Storage).

---

## 2. Architecture & Database Design

### Database Schema & Migrations (`supabase/migrations/`)
- `001_initial_schema.sql`: Initial 8 tables (`profiles`, `categories`, `menu_items`, `item_addons`, `cart_items`, `orders`, `order_items`, `order_status_history`, `addresses`, `payments`).
- `002_fix_rls_recursion.sql`: Created `SECURITY DEFINER` function `public.current_user_role()` to resolve recursive RLS policy evaluation loops on `public.profiles`.
- `003_add_order_type.sql`: Added `order_type` enum (`delivery`, `dine_in`, `takeaway`).
- `005_fix_order_status_history_rls.sql`: Granted RLS permissions for staff/admin to log audit history entries.
- `006_add_storage_policies.sql`: Configured RLS policies for `storage.objects` on `menu-images` (public read, admin write) and `avatars` (owner write).
- `007_add_delivery_address_to_orders.sql`: Added `delivery_address text` snapshot column to `public.orders`.
- `008_add_stripe_fields_to_orders.sql`: Added `pending_payment` & `payment_failed` enum values + `payment_intent_id` & `payment_status` columns.

### Solved Technical Challenges
1. **Windows Kotlin Incremental Compiler Drive Limits**: Resolved cross-drive compilation crash (`this and base files have different roots`) when building Flutter plugins on Windows by adding `kotlin.incremental=false` and setting Java 21 JDK in `android/gradle.properties`.
2. **PostgREST Unlinked FK Relational Joins**: Bypassed `PGRST200` schema relationship limits by adopting a clean, decoupled two-query application-level join in `OrderService`.
3. **Stripe Payment Consistency**: Guaranteed that zero orphan payments exist without orders by initializing orders as `pending_payment` and verifying Stripe `PaymentIntent` server-side before marking orders as `placed` and clearing user carts.

---

## 3. AI Tooling Usage Log

- **Claude / Cursor / Gemini**: Used for initial scaffolding of Riverpod providers, Deno Edge Function boilerplate, and SQL migration drafts.
- **Key Overrides & Human Debugging**:
  - Rewrote PostgREST query logic in `OrderService` to prevent runtime `PGRST200` exceptions when fetching customer profile data alongside order objects.
  - Configured custom RLS policies for Supabase Storage buckets to resolve `403 StorageException` errors on menu image uploads.
  - Implemented client-side fallback and error bounds for Stripe PaymentSheet cancel events.

---

## 4. Production Readiness Verification

- [x] **Row Level Security (RLS)**: Enabled with default-deny on all 8 tables + `storage.objects`.
- [x] **Server-Side API Layer**: 5 Edge Functions deployed (`place-order`, `update-order-status`, `menu-assistant`, `create-payment-intent`, `confirm-order-payment`).
- [x] **Credential Hygiene**: `STRIPE_SECRET_KEY` and `GROQ_API_KEY` stored exclusively as Edge Function secrets. No sensitive keys embedded in Flutter code.
- [x] **Git Cleanliness**: `git status` verified (`working tree clean`). All 7 migration files and 5 Edge Functions committed to repository `main`.
