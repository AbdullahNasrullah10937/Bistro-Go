# 🍽️ Bistro Go — Cafe & Restaurant Mobile Ordering App

**Bistro Go** is a premium, full-featured mobile ordering app built with **Flutter**, **Supabase** (Postgres, Auth, Realtime, Storage, RLS), **Groq API** (Llama 3.3 70B AI Assistant), and **Material 3 Design System**.

---

## 🔑 Authentication Guide & Admin Credentials

### 1. How Email / Password Authentication Works
- **Customer Sign Up**: Users can register on the Signup Screen (`/signup`).
- **Automatic Profile Creation**: A database trigger (`on_auth_user_created` in `001_initial_schema.sql`) automatically creates a user profile in `public.profiles` with `role = 'customer'`.
- **Email Confirmation Note**: If **"Confirm email"** is enabled in your Supabase Dashboard (`Authentication -> Providers -> Email`), Supabase sends a confirmation email before allowing login. To allow instant sign-in during local testing, toggle **"Confirm email" OFF** in the Supabase Dashboard.

---

### 2. Admin & Staff Credentials (How to Set Up Admin Login)

Admin and Staff users sign in at the **Staff Portal** (`/admin/login`). Role permissions (`customer`, `staff`, `admin`) are controlled by the `public.profiles.role` column and guarded by Supabase Row Level Security (RLS).

#### To Create Your First Admin Account:
1. **Option A: Sign up in the App**
   - Open the app and sign up at `/signup` with your desired admin email (e.g., `admin@bistrogo.com`).
   
2. **Elevate Role to Admin**:
   - Open your **Supabase Dashboard** ➔ **SQL Editor** and run:
   ```sql
   UPDATE public.profiles
   SET role = 'admin'
   WHERE id = (
     SELECT id FROM auth.users WHERE email = 'admin@bistrogo.com'
   );
   ```

3. **Log in to Staff Portal**:
   - Go to `/admin/login` in the app.
   - Enter `admin@bistrogo.com` and your password.
   - You now have full access to the **Admin Kitchen Dashboard**, **Realtime Order Management**, and **Menu CRUD**.

---

### 3. Google Sign-In Configuration

Google Sign-In uses **Supabase OAuth** with custom deep linking (`io.supabase.bistro-go://login-callback`).

#### Setup Steps in Supabase & Google Cloud Console:
1. **Google Cloud Console**:
   - Create an **OAuth 2.0 Web Application Client ID** in Google Cloud Console.
   - Add Authorized Redirect URI:
     `https://tadfgzdhytlqmaqevswv.supabase.co/auth/v1/callback`

2. **Supabase Dashboard**:
   - Navigate to **Authentication ➔ Providers ➔ Google**.
   - Enable Google Sign-In and paste your **Client ID** and **Client Secret**.

3. **Android Deep Link Scheme**:
   - The deep link filter is already added to `android/app/src/main/AndroidManifest.xml`:
     ```xml
     <intent-filter>
         <action android:name="android.intent.action.VIEW" />
         <category android:name="android.intent.category.DEFAULT" />
         <category android:name="android.intent.category.BROWSABLE" />
         <data android:scheme="io.supabase.bistro-go" android:host="login-callback" />
     </intent-filter>
     ```

---

## 🗄️ Database & Backend Installation Steps

1. **Apply Schema**:
   - Run [`supabase/migrations/001_initial_schema.sql`](file:///d:/Internship/Cibus%20Click/cibus/supabase/migrations/001_initial_schema.sql) in your Supabase SQL Editor.

2. **Apply Seed Data**:
   - Run [`supabase/seed.sql`](file:///d:/Internship/Cibus%20Click/cibus/supabase/seed.sql) to populate 6 categories, 14 menu items with images, and add-ons.

3. **Create Storage Buckets**:
   - Create public bucket `menu-images` for dish photos.
   - Create bucket `avatars` for user profile photos.

4. **Enable Realtime**:
   - In Supabase Dashboard ➔ **Database ➔ Replication**, enable Realtime for the `orders` table.

---

## 🚀 Building & Running the App

```bash
# Run on connected device/emulator
flutter run

# Build Debug APK
flutter build apk --debug
```
*APK output path*: `build/app/outputs/flutter-apk/app-debug.apk`
