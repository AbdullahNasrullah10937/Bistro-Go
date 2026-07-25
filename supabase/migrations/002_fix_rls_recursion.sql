-- supabase/migrations/002_fix_rls_recursion.sql
-- Fix: "infinite recursion detected in policy for relation profiles" (code: 42P17)
--
-- Root Cause:
--   The "Admin can view all profiles" policy on public.profiles contained a
--   subquery that SELECTs from public.profiles itself, causing Postgres to
--   infinitely evaluate the RLS policy during that subquery.
--
-- Fix:
--   1. Create a SECURITY DEFINER helper function that reads the role column
--      WITHOUT triggering RLS (runs as the function owner, not the caller).
--   2. Replace every policy that sub-queried public.profiles with a call to
--      this helper function instead.

-- ─── Step 1: Helper function (bypasses RLS via SECURITY DEFINER) ─────────────
create or replace function public.current_user_role()
returns text
language sql
security definer
stable
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

-- ─── Step 2: Fix policies on public.profiles (the recursion source) ──────────
drop policy if exists "Admin can view all profiles" on public.profiles;
drop policy if exists "Users and admins can view profiles" on public.profiles;

-- Users see their own row; admins/staff see all — no recursive subquery
create policy "Users and admins can view profiles"
  on public.profiles for select
  using (
    auth.uid() = id
    or public.current_user_role() in ('admin', 'staff')
  );

drop policy if exists "Users can insert their own profile" on public.profiles;
create policy "Users can insert their own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id or public.current_user_role() in ('admin', 'staff'));


-- ─── Step 3: Replace subquery-based admin policies on other tables ────────────
-- (These don't cause recursion but using the function is faster & consistent)

-- categories
drop policy if exists "Admin can manage categories" on public.categories;
create policy "Admin can manage categories"
  on public.categories for all
  using (public.current_user_role() in ('admin', 'staff'));

-- menu_items
drop policy if exists "Admin can manage menu items" on public.menu_items;
create policy "Admin can manage menu items"
  on public.menu_items for all
  using (public.current_user_role() in ('admin', 'staff'));

-- item_addons
drop policy if exists "Admin can manage addons" on public.item_addons;
create policy "Admin can manage addons"
  on public.item_addons for all
  using (public.current_user_role() in ('admin', 'staff'));

-- orders
drop policy if exists "Admin can view all orders" on public.orders;
create policy "Admin can view all orders"
  on public.orders for select
  using (
    auth.uid() = user_id
    or public.current_user_role() in ('admin', 'staff')
  );

drop policy if exists "Admin can update order status" on public.orders;
create policy "Admin can update order status"
  on public.orders for update
  using (public.current_user_role() in ('admin', 'staff'));

-- order_items
drop policy if exists "Admin can view all order items" on public.order_items;
create policy "Admin can view all order items"
  on public.order_items for select
  using (public.current_user_role() in ('admin', 'staff'));

-- order_status_history
drop policy if exists "Admin can view all status history" on public.order_status_history;
create policy "Admin can view all status history"
  on public.order_status_history for select
  using (public.current_user_role() in ('admin', 'staff'));

-- ─── Also allow authenticated users to INSERT orders ─────────────────────────
drop policy if exists "Users can place orders" on public.orders;
create policy "Users can place orders"
  on public.orders for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can insert order items" on public.order_items;
create policy "Users can insert order items"
  on public.order_items for insert
  with check (
    exists (
      select 1 from public.orders o
      where o.id = order_id and o.user_id = auth.uid()
    )
  );
