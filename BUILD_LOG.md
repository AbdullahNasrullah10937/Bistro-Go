# 🪵 BUILD_LOG.md — Bistro Go Architecture & Implementation Log

**Developer**: Abdullah Nasrullah  
**Project**: Bistro Go — Café & Restaurant Mobile Ordering App  
**Core Stack**: Flutter, Supabase (PostgreSQL, Auth, RLS, Storage, Realtime, Edge Functions), Stripe (Test Mode), Groq API (Llama 3.3 70B)  
**Development Timeline**: Built & Completed end-to-end in **2 Days**

---

## 1. Executive Summary & Deliverables

- **GitHub Repository**: [https://github.com/AbdullahNasrullah10937/Bistro-Go](https://github.com/AbdullahNasrullah10937/Bistro-Go)
- **Live Supabase Project Ref**: `wpxfvhqfvwjfgxkyqgze` (US East)
- **Automated Test Suite**: 18 tests passing (`flutter test`)
- **Release APK**: Included in [GitHub Releases](https://github.com/AbdullahNasrullah10937/Bistro-Go/releases) (`app-release.apk`)

---

## 2. AI Tools Usage & Engineering Reflection

> *"We grade learning, not just output."*

### AI Tools Utilized
1. **Antigravity AI Coding Assistant by Google DeepMind**: Used as the primary agentic pair programmer for iterative code generation, refactoring, and debugging across Dart/Flutter, TypeScript/Deno, and SQL migrations.
2. **Claude 3.5 Sonnet**: Utilized for architecture design, Riverpod 2.0 state provider structuring, and Deno Edge Function API contract definitions.
3. **Groq API (Llama 3.3 70B Versatile)**: Embedded into the live mobile application as the backend LLM powering the interactive conversational AI Menu Assistant.

### How AI Tools Were Leveraged
- **Rapid Scaffolding**: Generated strongly-typed Dart models (`Order`, `MenuItem`, `Profile`, `CartItem`) and Riverpod `AsyncNotifier` providers.
- **Edge Function Boilerplate**: Drafted TypeScript handlers for serverless payment intent creation, order verification, and Groq LLM prompt formatting.
- **SQL Migration Generation**: Drafted database schemas, foreign key constraints, triggers (`handle_new_user`), and initial Row Level Security (RLS) policies.

### Key Learnings & Architectural Overrides (Human Engineering)

| Challenge / Discovery | Root Cause | AI Guidance vs Human Decision / Resolution |
|---|---|---|
| **Windows Kotlin Cross-Drive Bug** | Gradle failed during Android compilation with `this and base files have different roots` because the project was on `D:` drive while pub cache was on `C:`. | AI initially suggested updating Kotlin versions. Human developer diagnosed the cross-drive path calculation limit on Windows and fixed it by adding `kotlin.incremental=false` to `android/gradle.properties`. |
| **Stripe Orphan Payments Risk** | Initial naive flow created orders before payment confirmation, risking abandoned database rows if card payment failed. | Designed a robust 2-phase architecture: Orders are created in `pending_payment` state via serverless Edge Function, verified with Stripe API, and cart is cleared only upon verified payment success. |
| **PostgREST RLS Recursion (`PGRST200`)** | Policies querying `public.profiles` while checking roles triggered infinite policy loops. | Replaced naive RLS checks with a `SECURITY DEFINER` Postgres function (`public.current_user_role()`) that bypasses RLS during role evaluation. |
| **Decoupled Relational Joins** | Direct PostgREST table joins threw errors due to lack of direct foreign key links between `orders` and `profiles`. | Implemented an application-level two-query join inside `OrderService` to securely stitch customer profiles without modifying database normalization. |

---

## 3. What Was Built

### Customer Mobile Experience
- **Authentication & Security**: Email/Password login + signup, Google OAuth with custom deep linking scheme (`io.supabase.bistro-go://login-callback`), forgot password flow with deep link recovery screen (`/update-password`), and automatic JWT session restoration on app relaunch.
- **Interactive Menu**: Category tabs, live keyword search, price & dietary tag filtering, high-resolution product photography, item detail view with custom add-ons and quantity steppers.
- **Smart Cart**: Per-user isolated cart with real-time subtotal, tax (8.5%), delivery fee calculation ($4.99 standard, free over $30), and empty state illustrations.
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
- **Admin Settings**: Store opening status toggle, auto-accept switch, kitchen alert toggles, and store preferences.

---

## 4. Automated Testing Suite

The repository contains an automated test suite under `test/` covering unit logic, serialization, currency formatting, and UI widgets:

```bash
flutter test
```

### Test Coverage Summary (18 Tests):
1. **`test/unit/cart_calculator_test.dart`**:
   - Accurately computes 8.5% sales tax.
   - Calculates $4.99 standard delivery fee for delivery under $30.
   - Waives delivery fee for orders over $30.
   - Waives delivery fee for Dine-In and Takeaway orders regardless of subtotal.
   - Verifies subtotal + tax + delivery fee grand totals.
2. **`test/unit/order_model_test.dart`**:
   - Tests `OrderStatus` human-readable display names and string parsing fallbacks.
   - Validates server state machine transition rules (`canTransitionTo`).
   - Asserts terminal states (`isTerminal` for `completed` and `cancelled`).
   - Verifies `Order.fromJson` parsing with nested `order_items` and joined customer profile data.
3. **`test/unit/currency_formatter_test.dart`**:
   - Tests compact USD string formatting (`$12.50`, `$0.00`).
4. **`test/widget/primary_button_test.dart`**:
   - Verifies button label rendering and tap callback triggers.
   - Verifies `CircularProgressIndicator` display and tap prevention during loading states.
   - Verifies icon rendering when provided.
5. **`test/widget/empty_state_test.dart`**:
   - Tests `EmptyState` title, subtitle, icon, and action button callbacks.
   - Tests `ErrorState` message rendering and retry callback triggers.

---

## 5. Production Readiness & Security Verification

- [x] **Row Level Security (RLS)**: Enabled with default-deny on all 8 tables + `storage.objects`.
- [x] **Server-Side API Layer**: 5 Edge Functions deployed (`place-order`, `update-order-status`, `menu-assistant`, `create-payment-intent`, `confirm-order-payment`).
- [x] **Credential Hygiene**: `STRIPE_SECRET_KEY` and `GROQ_API_KEY` stored exclusively as Edge Function secrets. No sensitive keys embedded in Flutter code.
- [x] **Git Cleanliness**: `git status` verified (`working tree clean`). All migration files, Edge Functions, and tests committed to repository `main`.
