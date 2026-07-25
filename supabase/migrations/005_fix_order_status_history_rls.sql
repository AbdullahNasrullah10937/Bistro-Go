-- supabase/migrations/005_fix_order_status_history_rls.sql
-- Immediate fix: allow admin/staff to INSERT into order_status_history
-- (Long-term: this is also written server-side by update-order-status Edge Function using service role)

drop policy if exists "Admin and staff can insert status history" on public.order_status_history;

create policy "Admin and staff can insert status history"
  on public.order_status_history for insert
  with check (public.current_user_role() in ('admin', 'staff'));

-- Also allow customers to view their own order's status history
drop policy if exists "Users can view own order history" on public.order_status_history;
create policy "Users can view own order history"
  on public.order_status_history for select
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_status_history.order_id
        and o.user_id = auth.uid()
    )
    or public.current_user_role() in ('admin', 'staff')
  );
