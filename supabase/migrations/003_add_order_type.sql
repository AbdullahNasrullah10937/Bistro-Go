-- supabase/migrations/003_add_order_type.sql
-- Add order_type column to public.orders table with check constraint

alter table public.orders
add column if not exists order_type text not null default 'delivery'
check (order_type in ('delivery', 'dine_in', 'takeaway'));
