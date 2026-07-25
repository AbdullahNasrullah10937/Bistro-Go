-- supabase/migrations/008_add_stripe_fields_to_orders.sql
-- Add pending_payment and payment_failed to order_status enum
-- Add payment_intent_id and payment_status to public.orders

alter type public.order_status add value if not exists 'pending_payment' before 'placed';
alter type public.order_status add value if not exists 'payment_failed';

alter table public.orders
add column if not exists payment_intent_id text,
add column if not exists payment_status text default 'pending';
