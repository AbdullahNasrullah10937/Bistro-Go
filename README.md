<div align="center">

# 🍽️ Bistro Go

### Premium Café & Restaurant Mobile Ordering App

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)](https://supabase.com)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

*A full-stack Flutter app with real-time order tracking, AI-powered menu assistance, and a complete admin dashboard — powered by Supabase and Groq.*

</div>

---

## ✨ Features

### 🛒 Customer App
- **Onboarding & Auth** — Email/password sign up, login, forgot password, Google Sign-In (OAuth)
- **Menu Browsing** — Category filters, search, item detail with add-ons
- **Smart Cart** — Persistent per-user cart with quantity management and quick-add
- **Checkout** — 3-way order type toggle: Delivery, Takeaway, Dine-In; delivery fee waived for non-delivery
- **Order Tracking** — Real-time status stepper (Placed → Confirmed → Preparing → Ready → Completed)
- **Order History** — Full history with per-order detail view
- **AI Menu Assistant** — Conversational chat powered by Groq (Llama 3.3 70B); recommends real menu items as tappable product cards inline in chat
- **Profile Management** — Edit name, phone; manage delivery addresses

### 👨‍🍳 Admin / Staff App
- **Kitchen Dashboard** — Live order feed with real-time updates via Supabase Realtime
- **Status Management** — Advance orders through valid transitions only, enforced server-side
- **Menu CRUD** — Add, edit, delete menu items; toggle availability; upload images to Supabase Storage
- **Order Detail** — View full order breakdown, customer info, status history

---

## 🏗️ Tech Stack

| Layer | Technology |
|---|---|
| **Mobile** | Flutter 3.x (Dart) |
| **State Management** | Riverpod (providers + async state) |
| **Navigation** | GoRouter |
| **Backend / Database** | Supabase (PostgreSQL + RLS) |
| **Auth** | Supabase Auth (Email + Google OAuth) |
| **Realtime** | Supabase Realtime (order status updates) |
| **Storage** | Supabase Storage (menu images, avatars) |
| **Edge Functions** | Deno / TypeScript (order placement, status updates, AI assistant) |
| **AI** | Groq API — Llama 3.3 70B Versatile |
| **Image Caching** | `cached_network_image` |

---

## 📁 Project Structure

```
cibus/
├── lib/
│   ├── core/
│   │   ├── constants/          # App colors, spacing, text styles, shadows
│   │   ├── providers/          # Riverpod providers (auth, cart, menu, orders)
│   │   ├── router/             # GoRouter configuration & route names
│   │   └── utils/              # Currency formatter, helpers
│   ├── features/
│   │   ├── admin/              # Admin dashboard, order management, menu CRUD
│   │   ├── ai_assistant/       # AI menu chat screen
│   │   ├── auth/               # Login, signup, forgot password
│   │   ├── cart/               # Cart screen
│   │   ├── checkout/           # Checkout with order type selection
│   │   ├── home/               # Home feed, menu grid, shell layout
│   │   ├── item_detail/        # Item detail with add-ons
│   │   ├── onboarding/         # Onboarding flow
│   │   ├── order_history/      # My orders list & detail
│   │   ├── order_tracking/     # Real-time status tracking
│   │   ├── profile/            # User profile & address management
│   │   └── splash/             # Splash screen
│   ├── models/                 # Data models (Order, MenuItem, CartItem, etc.)
│   ├── services/               # API service layer (auth, menu, order, FCM)
│   └── shared_widgets/         # Reusable widgets (cards, skeletons, buttons)
├── supabase/
│   ├── functions/
│   │   ├── place-order/        # Edge Function: validates, prices & places orders
│   │   ├── update-order-status/ # Edge Function: role-gated status transitions
│   │   └── menu-assistant/     # Edge Function: AI chat with live menu context
│   └── migrations/             # SQL migration files (apply in order)
└── assets/                     # Fonts (Sora, Inter), images
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- A [Supabase](https://supabase.com) project
- A [Groq](https://console.groq.com) API key (for the AI assistant)
- [Supabase CLI](https://supabase.com/docs/guides/cli) (for deploying Edge Functions)

### 1. Clone the Repository

```bash
git clone https://github.com/AbdullahNasrullah10937/Bistro-Go.git
cd Bistro-Go
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Configure Supabase

Create a `.env` file or set the following values in `lib/main.dart`:

```dart
// Replace with your own Supabase project credentials
await Supabase.initialize(
  url: 'YOUR_SUPABASE_PROJECT_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

> ⚠️ **Never commit real credentials.** Add `.env` to `.gitignore`.

### 4. Apply Database Migrations

Run each file in your **Supabase SQL Editor** in order:

```
supabase/migrations/001_initial_schema.sql
supabase/migrations/002_fix_rls_recursion.sql
supabase/migrations/003_add_order_type.sql
supabase/migrations/004_fix_order_items_rls.sql
supabase/migrations/005_fix_order_status_history_rls.sql
```

### 5. Seed Menu Data

Run `supabase/seed.sql` in the SQL Editor to populate categories, menu items, and add-ons.

### 6. Set Up Storage Buckets

In your Supabase Dashboard → Storage, create two **public** buckets:
- `menu-images` — for dish photos
- `avatars` — for user profile photos

### 7. Enable Realtime

Dashboard → Database → Replication → enable Realtime for the `orders` table.

### 8. Deploy Edge Functions

```bash
supabase login
supabase functions deploy place-order --project-ref YOUR_PROJECT_REF
supabase functions deploy update-order-status --project-ref YOUR_PROJECT_REF
supabase functions deploy menu-assistant --project-ref YOUR_PROJECT_REF

# Set the Groq API key secret for the AI assistant
supabase secrets set GROQ_API_KEY=your_groq_api_key --project-ref YOUR_PROJECT_REF
```

### 9. Configure Google Sign-In (Optional)

1. Create an **OAuth 2.0 Web Client ID** in [Google Cloud Console](https://console.cloud.google.com).
2. Add your Supabase callback URL as an Authorized Redirect URI.
3. In Supabase Dashboard → Authentication → Providers → Google, enable it and add your Client ID & Secret.
4. The Android deep link scheme `io.supabase.bistro-go://login-callback` is already configured in `AndroidManifest.xml`.

### 10. Run the App

```bash
flutter run
```

---

## 🗄️ Database Schema Overview

| Table | Purpose |
|---|---|
| `profiles` | Extended user info (name, phone, role, avatar) |
| `categories` | Menu item categories |
| `menu_items` | Dishes with name, price, description, tags, add-ons |
| `cart_items` | Per-user cart, isolated by RLS |
| `orders` | Orders with type (delivery/takeaway/dine-in), status, totals |
| `order_items` | Line items per order |
| `order_status_history` | Audit log of every status change |
| `addresses` | Saved delivery addresses per user |

---

## 🔐 Admin Access

1. Sign up in the app with your desired admin email.
2. In Supabase SQL Editor, promote the account:

```sql
UPDATE public.profiles
SET role = 'admin'
WHERE id = (
  SELECT id FROM auth.users WHERE email = 'your-email@example.com'
);
```

3. Log in at the **Staff Portal** (accessible from the app's admin login route).

---

## 🧱 Architecture Highlights

- **Row Level Security (RLS)** — Every table is protected. Customers only see their own data. Admins use a `SECURITY DEFINER` function to avoid recursive policy checks.
- **Edge Functions as API Layer** — Order placement, status updates, and AI chat happen server-side. The client never writes directly to sensitive tables.
- **Riverpod State Management** — Auth state changes automatically invalidate user-scoped providers (cart, orders, profile), preventing data leaks between sessions.
- **Two-Query Profile Pattern** — Customer names are fetched separately from orders to avoid PostgREST relationship errors (no direct FK between `orders` and `profiles`).

---

## 📸 Screenshots

> *Coming soon — add screenshots of Home, AI Chat, Order Tracking, and Admin Dashboard here.*

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
