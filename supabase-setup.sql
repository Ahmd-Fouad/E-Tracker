-- English Growth Tracker cloud state and profile avatars
-- Run this file in the Supabase SQL Editor as the project owner.

create table if not exists public.tracker_state (
  user_id uuid primary key references auth.users(id) on delete cascade,
  state jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.tracker_state enable row level security;
alter table public.tracker_state force row level security;

-- Anonymous API requests receive no table privileges. Authenticated requests
-- still have to satisfy the ownership policies below.
revoke all on table public.tracker_state from anon;
grant select, insert, update, delete on table public.tracker_state to authenticated;

drop policy if exists "Users can select their own tracker state" on public.tracker_state;
create policy "Users can select their own tracker state"
on public.tracker_state
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert their own tracker state" on public.tracker_state;
create policy "Users can insert their own tracker state"
on public.tracker_state
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update their own tracker state" on public.tracker_state;
create policy "Users can update their own tracker state"
on public.tracker_state
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own tracker state" on public.tracker_state;
create policy "Users can delete their own tracker state"
on public.tracker_state
for delete
to authenticated
using (auth.uid() = user_id);

-- Public profile-image delivery with authenticated, owner-scoped writes.
-- The application converts accepted JPG/PNG/WebP input to avatar.webp before upload.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars',
  'avatars',
  true,
  2097152,
  array['image/jpeg', 'image/png', 'image/webp']::text[]
)
on conflict (id) do update set
  name = excluded.name,
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Users can read their own avatar objects" on storage.objects;
create policy "Users can read their own avatar objects"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists "Users can upload their own avatar objects" on storage.objects;
create policy "Users can upload their own avatar objects"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists "Users can update their own avatar objects" on storage.objects;
create policy "Users can update their own avatar objects"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
)
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists "Users can delete their own avatar objects" on storage.objects;
create policy "Users can delete their own avatar objects"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);
