-- supabase/migrations/007_add_delivery_address_to_orders.sql
-- Add delivery_address text column to orders table to store formatted address string alongside address_id

alter table public.orders
add column if not exists delivery_address text;
