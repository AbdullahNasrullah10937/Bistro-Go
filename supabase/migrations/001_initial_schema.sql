-- supabase/migrations/001_initial_schema.sql
-- Bistro Go — Full Database Schema with RLS
-- Run this in your Supabase SQL editor or apply via CLI

-- ────────────────────────────────────────────────────────────────────────────
-- EXTENSIONS
-- ────────────────────────────────────────────────────────────────────────────
create extension if not exists "uuid-ossp";

-- ────────────────────────────────────────────────────────────────────────────
-- PROFILES
-- ────────────────────────────────────────────────────────────────────────────
create table if not exists public.profiles (
  id          uuid primary key references auth.users on delete cascade,
  name        text,
  phone       text,
  role        text not null default 'customer'
                check (role in ('customer', 'staff', 'admin')),
  avatar_url  text,
  fcm_token   text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Users can view own profile"
  on public.profiles for select using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update using (auth.uid() = id);

create policy "Admin can view all profiles"
  on public.profiles for select
  using (exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role in ('admin', 'staff')
  ));

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, name, phone, role)
  values (
    new.id,
    new.raw_user_meta_data->>'name',
    new.raw_user_meta_data->>'phone',
    coalesce(new.raw_user_meta_data->>'role', 'customer')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ────────────────────────────────────────────────────────────────────────────
-- CATEGORIES
-- ────────────────────────────────────────────────────────────────────────────
create table if not exists public.categories (
  id          uuid primary key default uuid_generate_v4(),
  name        text not null unique,
  sort_order  int  not null default 0,
  icon_url    text,
  created_at  timestamptz not null default now()
);

alter table public.categories enable row level security;

create policy "Everyone can view categories"
  on public.categories for select using (true);

create policy "Admin can manage categories"
  on public.categories for all
  using (exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role in ('admin', 'staff')
  ));

-- ────────────────────────────────────────────────────────────────────────────
-- MENU ITEMS
-- ────────────────────────────────────────────────────────────────────────────
create table if not exists public.menu_items (
  id           uuid primary key default uuid_generate_v4(),
  category_id  uuid not null references public.categories on delete cascade,
  name         text not null,
  description  text not null default '',
  price        numeric(10,2) not null check (price >= 0),
  image_url    text,
  is_available boolean not null default true,
  tags         text[] not null default '{}',
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

alter table public.menu_items enable row level security;

create policy "Everyone can view available menu items"
  on public.menu_items for select using (true);

create policy "Admin can manage menu items"
  on public.menu_items for all
  using (exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role in ('admin', 'staff')
  ));

-- ────────────────────────────────────────────────────────────────────────────
-- ITEM ADD-ONS
-- ────────────────────────────────────────────────────────────────────────────
create table if not exists public.item_addons (
  id           uuid primary key default uuid_generate_v4(),
  menu_item_id uuid not null references public.menu_items on delete cascade,
  name         text not null,
  extra_price  numeric(10,2) not null default 0 check (extra_price >= 0),
  created_at   timestamptz not null default now()
);

alter table public.item_addons enable row level security;

create policy "Everyone can view addons"
  on public.item_addons for select using (true);

create policy "Admin can manage addons"
  on public.item_addons for all
  using (exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role in ('admin', 'staff')
  ));

-- ────────────────────────────────────────────────────────────────────────────
-- ADDRESSES
-- ────────────────────────────────────────────────────────────────────────────
create table if not exists public.addresses (
  id            uuid primary key default uuid_generate_v4(),
  user_id       uuid not null references auth.users on delete cascade,
  label         text not null default 'Home',
  address_line  text not null,
  city          text not null default '',
  is_default    boolean not null default false,
  created_at    timestamptz not null default now()
);

alter table public.addresses enable row level security;

create policy "Users can manage own addresses"
  on public.addresses for all using (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────────────────────
-- CART ITEMS
-- ────────────────────────────────────────────────────────────────────────────
create table if not exists public.cart_items (
  id               uuid primary key default uuid_generate_v4(),
  user_id          uuid not null references auth.users on delete cascade,
  menu_item_id     uuid not null references public.menu_items on delete cascade,
  quantity         int  not null default 1 check (quantity > 0),
  selected_addons  uuid[] not null default '{}',
  notes            text,
  created_at       timestamptz not null default now()
);

alter table public.cart_items enable row level security;

create policy "Users can manage own cart"
  on public.cart_items for all using (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────────────────────
-- ORDERS
-- ────────────────────────────────────────────────────────────────────────────
create type order_status as enum (
  'placed', 'confirmed', 'preparing', 'ready', 'completed', 'cancelled'
);

create table if not exists public.orders (
  id               uuid primary key default uuid_generate_v4(),
  user_id          uuid not null references auth.users on delete restrict,
  status           order_status not null default 'placed',
  subtotal         numeric(10,2) not null,
  tax              numeric(10,2) not null,
  delivery_fee     numeric(10,2) not null default 0,
  total            numeric(10,2) not null,
  address_id       uuid references public.addresses,
  table_number     text,
  notes            text,
  payment_method   text not null default 'cash',
  idempotency_key  uuid unique,
  placed_at        timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

alter table public.orders enable row level security;

create policy "Users can view own orders"
  on public.orders for select using (auth.uid() = user_id);

create policy "Admin can view all orders"
  on public.orders for select
  using (exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role in ('admin', 'staff')
  ));

create policy "Admin can update order status"
  on public.orders for update
  using (exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role in ('admin', 'staff')
  ));

-- ────────────────────────────────────────────────────────────────────────────
-- ORDER ITEMS
-- ────────────────────────────────────────────────────────────────────────────
create table if not exists public.order_items (
  id               uuid primary key default uuid_generate_v4(),
  order_id         uuid not null references public.orders on delete cascade,
  menu_item_id     uuid not null references public.menu_items on delete restrict,
  item_name        text not null,
  quantity         int  not null check (quantity > 0),
  unit_price       numeric(10,2) not null,
  selected_addons  text[] not null default '{}',
  created_at       timestamptz not null default now()
);

alter table public.order_items enable row level security;

create policy "Users can view own order items"
  on public.order_items for select
  using (exists (
    select 1 from public.orders o
    where o.id = order_id and o.user_id = auth.uid()
  ));

create policy "Admin can view all order items"
  on public.order_items for select
  using (exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role in ('admin', 'staff')
  ));

-- ────────────────────────────────────────────────────────────────────────────
-- ORDER STATUS HISTORY (audit log)
-- ────────────────────────────────────────────────────────────────────────────
create table if not exists public.order_status_history (
  id          uuid primary key default uuid_generate_v4(),
  order_id    uuid not null references public.orders on delete cascade,
  old_status  order_status,
  new_status  order_status not null,
  changed_by  uuid references auth.users,
  changed_at  timestamptz not null default now(),
  notes       text
);

alter table public.order_status_history enable row level security;

create policy "Users can view own order history"
  on public.order_status_history for select
  using (exists (
    select 1 from public.orders o
    where o.id = order_id and o.user_id = auth.uid()
  ));

create policy "Admin can view all status history"
  on public.order_status_history for select
  using (exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role in ('admin', 'staff')
  ));

-- ────────────────────────────────────────────────────────────────────────────
-- STORAGE BUCKETS
-- ────────────────────────────────────────────────────────────────────────────
-- Run these in Supabase dashboard → Storage → New Bucket
-- OR via SQL if you have storage schema access:
-- insert into storage.buckets (id, name, public) values ('menu-images', 'menu-images', true) on conflict do nothing;
-- insert into storage.buckets (id, name, public) values ('avatars', 'avatars', false) on conflict do nothing;

-- ────────────────────────────────────────────────────────────────────────────
-- REALTIME
-- ────────────────────────────────────────────────────────────────────────────
-- Enable realtime on orders table in Supabase dashboard → Database → Replication
-- OR via SQL:
-- alter publication supabase_realtime add table public.orders;

-- ────────────────────────────────────────────────────────────────────────────
-- UPDATED_AT TRIGGER (auto-update timestamps)
-- ────────────────────────────────────────────────────────────────────────────
create or replace function public.update_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger update_profiles_updated_at
  before update on public.profiles
  for each row execute procedure public.update_updated_at();

create trigger update_menu_items_updated_at
  before update on public.menu_items
  for each row execute procedure public.update_updated_at();

create trigger update_orders_updated_at
  before update on public.orders
  for each row execute procedure public.update_updated_at();
