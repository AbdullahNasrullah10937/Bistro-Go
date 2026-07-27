<div align="center">

# 🍽️ Bistro Go

### Premium Café & Restaurant Mobile Ordering App

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)](https://supabase.com)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Tests](https://img.shields.io/badge/Tests-18%20Passing-brightgreen.svg)](test/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

*A full-stack Flutter app with real-time order tracking, AI-powered menu assistance, Stripe PaymentSheet integration, and a complete admin dashboard — powered by Supabase and Groq.*

</div>

---

## 📱 Quick Reviewer Links & APK Installation

- **Download Release APK**: [`app-release.apk`](https://github.com/AbdullahNasrullah10937/Bistro-Go/releases/latest) (Download and install directly on any Android device or emulator)
- **GitHub Repository**: [https://github.com/AbdullahNasrullah10937/Bistro-Go](https://github.com/AbdullahNasrullah10937/Bistro-Go)
- **Live Supabase Project Reference**: `wpxfvhqfvwjfgxkyqgze` (US East)
- **Admin Portal Test Credentials**:
  - **URL Route**: Navigate to `/admin/login` from app login screen
  - **Email**: `admin@bistrogo.com`
  - **Password**: `Admin@123456`

---

## ✨ Features

### 🛒 Customer App
- **Onboarding & Auth** — Email/password sign up, login, forgot password with deep link recovery (`/update-password`), Google Sign-In (OAuth).
- **Menu Browsing** — Category filters, live search, item detail with customizable add-ons.
- **Smart Cart** — Persistent per-user cart with real-time subtotal, tax (8.5%), and delivery fee calculations ($4.99 standard, free over $30).
- **Saved Address Selector** — Saved address management with default selection and on-the-fly address creation during checkout.
- **3 Order Modes** — Toggle between **Delivery**, **Takeaway**, and **Dine-In** (Table #); delivery fees automatically waived for non-delivery orders.
- **Production Payment Options** — Cash on Delivery (COD) and two-phase server-verified **Stripe PaymentSheet** checkout.
- **Live Order Tracking** — Real-time 5-stage status timeline (**Placed** → **Confirmed** → **Preparing** → **Ready** → **Completed**) streamed via Supabase Realtime WebSockets.
- **AI Menu Assistant** — Conversational assistant powered by **Groq Llama 3.3 70B** via serverless Deno Edge Function; renders interactive menu cards inline in chat.

### 👨‍🍳 Kitchen & Admin Management Portal
- **Kitchen Dashboard** — Live order feed with real-time WebSocket updates, order filtering, and audio alerts.
- **Status Machine** — Advance orders through valid transitions enforced server-side.
- **Menu Management CRUD** — Add, edit, delete menu items, toggle availability, adjust prices, and upload dish photos to Supabase Storage.
- **Admin Settings** — Store opening toggle, auto-accept switch, and kitchen preferences.

---

## 🤖 AI Tools & Engineering Reflection

Full breakdown available in [`BUILD_LOG.md`](file:///d:/Internship/Cibus%20Click/cibus/BUILD_LOG.md).

### AI Tools Utilized
- **Antigravity AI Coding Assistant by Google DeepMind**: Primary agentic assistant for full-stack pair programming, Riverpod 2.0 provider refactoring, Deno TypeScript function authoring, and SQL schema migrations.
- **Claude 3.5 Sonnet**: System architecture design, database normalization, and state management planning.
- **Groq API (Llama 3.3 70B)**: Live LLM powering the in-app AI Menu Assistant.

### Key Learnings & Engineering Overrides
1. **Windows Kotlin Incremental Compiler Fix**: Solved `this and base files have different roots` cross-drive Gradle build failure by adding `kotlin.incremental=false` to `android/gradle.properties`.
2. **2-Phase Server-Verified Payments**: Implemented Stripe `PaymentSheet` verification via Edge Functions to ensure zero orphaned transactions before clearing user carts.
3. **RLS Recursion Fix**: Implemented a `SECURITY DEFINER` function (`public.current_user_role()`) to eliminate infinite recursion in Supabase PostgreSQL policies.

---

## 🧪 Automated Test Suite

Run the test suite with:

```bash
flutter test
```

### Test Suite Highlights (18 Passing Tests):
- `test/unit/cart_calculator_test.dart` — Verifies 8.5% tax rate, $30 free delivery threshold, and order-type fee waivers.
- `test/unit/order_model_test.dart` — Verifies `OrderStatus` display names, JSON deserialization, and state machine transition rules (`canTransitionTo`).
- `test/unit/currency_formatter_test.dart` — Verifies compact USD string formatting.
- `test/widget/primary_button_test.dart` — Verifies button widget states, loading indicators, and tap callbacks.
- `test/widget/empty_state_test.dart` — Verifies empty and error UI states.

---

## 🏗️ Tech Stack

| Layer | Technology |
|---|---|
| **Mobile** | Flutter 3.x (Dart) |
| **State Management** | Riverpod 2.0 (providers + async state) |
| **Navigation** | GoRouter |
| **Backend / Database** | Supabase (PostgreSQL + RLS) |
| **Auth** | Supabase Auth (Email + Google OAuth + Deep Link Recovery) |
| **Realtime** | Supabase Realtime (WebSockets) |
| **Storage** | Supabase Storage (`menu-images`, `avatars`) |
| **Edge Functions** | Deno / TypeScript (`place-order`, `update-order-status`, `menu-assistant`, `create-payment-intent`, `confirm-order-payment`) |
| **Payments** | Stripe PaymentSheet (Test Mode) |
| **AI** | Groq API — Llama 3.3 70B Versatile |

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
│   │   ├── admin/              # Admin dashboard, order management, menu CRUD, settings
│   │   ├── ai_assistant/       # AI menu chat screen
│   │   ├── auth/               # Login, signup, forgot password, update password
│   │   ├── cart/               # Cart screen
│   │   ├── checkout/           # Checkout with order type & address selection
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
├── test/
│   ├── unit/                   # Business logic, calculator & serialization unit tests
│   └── widget/                 # Flutter UI widget tests
├── supabase/
│   ├── functions/              # 5 Deno TypeScript Edge Functions
│   └── migrations/             # 8 SQL migration files
└── assets/                     # Fonts (Sora, Inter), images
```

---

## 🚀 Quick 2-Minute Reviewer Setup

### Option A: Run Pre-Built APK (Fastest)
1. Download `app-release.apk` from [GitHub Releases](https://github.com/AbdullahNasrullah10937/Bistro-Go/releases/latest).
2. Install on Android device or emulator (`adb install app-release.apk`).
3. Launch and test immediately against live Supabase backend.

### Option B: Run Source Code Locally
```bash
# 1. Clone repository
git clone https://github.com/AbdullahNasrullah10937/Bistro-Go.git
cd Bistro-Go

# 2. Install dependencies
flutter pub get

# 3. Run unit tests
flutter test

# 4. Launch app
flutter run
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
