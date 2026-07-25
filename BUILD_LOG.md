# 🪵 BUILD_LOG.md — Bistro Go Architecture & Implementation Log

**Developer**: Abdullah Nasrullah  
**Project**: Bistro Go — Café & Restaurant Mobile Ordering App  
**Core Stack**: Flutter, Supabase (Postgres, Auth, RLS, Storage, Realtime, Edge Functions), Groq API (Llama 3.3 70B)

---

## 1. What I Built

### Customer Application
- **Authentication**: Email/Password login + signup, Google OAuth with deep linking (`io.supabase.bistro-go://login-callback`), forgot password.
- **Menu Experience**: Category tabs, search filter, item detail page with custom add-ons and quantity selectors.
- **Cart & Checkout**: Isolated per-user cart, 3-way toggle (Delivery, Takeaway, Dine-In), auto-waived delivery fees for non-delivery orders.
- **Order Placement**: Client sends payload to `place-order` Edge Function which verifies real prices from `menu_items`, calculates tax/delivery fee, checks idempotency key, and inserts order + order_items atomically.
- **Live Order Tracking**: Realtime status timeline (Placed → Confirmed → Preparing → Ready → Completed) with auto-updates.
- **AI Assistant**: Groq Llama 3.3 70B powered menu assistant calling `menu-assistant` Edge Function. Renders live tappable `MenuItemCard` widgets directly inline in the chat bubble.

### Admin / Kitchen Portal
- **Role-Gated Portal**: `/admin/login` route guarded by `public.profiles.role` (`admin` / `staff`).
- **Kitchen Dashboard**: Realtime list of incoming orders, filtered views, one-tap status transition actions.
- **State Machine Enforcement**: Status transitions validated server-side via `update-order-status` Edge Function.
- **Menu Management CRUD**: Full control over menu items (Add, Edit, Delete, Toggle Availability, Image Upload).

---

## 2. Architecture & Design Patterns

### Why Supabase over Firebase?
- **Real Relational Data**: Strong foreign key constraints between `orders`, `order_items`, `profiles`, and `categories`.
- **Row Level Security (RLS)**: Access rules enforced at the database level (`auth.uid() = user_id`) rather than fragile app code.
- **Serverless API Layer**: Edge Functions allow server-side price validation, key secrecy (Groq API key never exposed to client), and strict transition logic.

### Solved Technical Challenges
1. **RLS Recursion Fix**: Implemented `SECURITY DEFINER` function `public.current_user_role()` to resolve recursive policy evaluation on `public.profiles`.
2. **PostgREST Unlinked FK Join Fix**: Solved PostgREST `PGRST200` relationship error when joining `orders` and `profiles` by adopting a clean, decoupled two-query pattern in `OrderService`.
3. **Cart Session Isolation**: Subscribed `authStateListenerProvider` to Supabase `onAuthStateChange` to automatically clear/invalidate user-scoped providers on logout/login.

---

## 3. AI Tooling Usage Log

- **Claude / Cursor / Gemini**: Used to scaffold Edge Functions (`place-order`, `update-order-status`, `menu-assistant`), generate migration scripts (`001` through `005`), and debug RLS policies.
- **Key Override**: Handled edge case where PostgREST couldn't join `orders` and `profiles` due to unlinked foreign keys by refactoring `OrderService` to use a two-query application-level join instead of relying on PostgREST auto-embedding.

---

## 4. Production Readiness Summary

- [x] **RLS Enabled & Default-Deny**: All 8 tables protected with explicit policies.
- [x] **Database Migrations**: 5 SQL migration files committed in sequence under `supabase/migrations/`.
- [x] **Edge Functions**: 3 Deno TypeScript Edge Functions created under `supabase/functions/`.
- [x] **Clean Credentials**: `google-services.json`, `.env`, and project secrets excluded via `.gitignore`. `README.md` free of sensitive URLs.
- [x] **Static Analysis**: `flutter analyze` clean with 0 compilation errors.
