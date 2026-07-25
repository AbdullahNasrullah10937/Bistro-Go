-- supabase/migrations/006_add_storage_policies.sql
-- Add storage.objects RLS policies for menu-images and avatars buckets

-- ─── 1. MENU-IMAGES BUCKET POLICIES (Public Read, Admin/Staff Write) ─────────


drop policy if exists "Public menu-images read" on storage.objects;
create policy "Public menu-images read"
  on storage.objects for select
  using (bucket_id = 'menu-images');

drop policy if exists "Admin staff menu-images insert" on storage.objects;
create policy "Admin staff menu-images insert"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'menu-images'
    and public.current_user_role() in ('admin', 'staff')
  );

drop policy if exists "Admin staff menu-images update" on storage.objects;
create policy "Admin staff menu-images update"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'menu-images'
    and public.current_user_role() in ('admin', 'staff')
  );

drop policy if exists "Admin staff menu-images delete" on storage.objects;
create policy "Admin staff menu-images delete"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'menu-images'
    and public.current_user_role() in ('admin', 'staff')
  );

-- ─── 2. AVATARS BUCKET POLICIES (Owner-Only Access via {user_id}/filename) ───

drop policy if exists "User avatars read" on storage.objects;
create policy "User avatars read"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "User avatars insert" on storage.objects;
create policy "User avatars insert"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "User avatars update" on storage.objects;
create policy "User avatars update"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "User avatars delete" on storage.objects;
create policy "User avatars delete"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
