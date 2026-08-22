-- Baseline of the existing `clubs` table so the local stack matches production.
--
-- Production's `clubs` was created by hand in the Supabase SQL editor and was
-- never captured as a migration, so `supabase db reset` had nothing to build.
-- Columns and types here are reconstructed from what the repo actually writes:
-- the INSERT in insert-key-club-2026-08-20.sql, the `ARRAY[...]::text[]` and
-- `::jsonb` casts across the update scripts, and the row shape in
-- uploads/clubs.json. `id` is a text slug ('key-club'), NOT a uuid.
--
-- Every statement is `if not exists` / `drop ... if exists` guarded, so running
-- this against production would be a no-op rather than a change. No column is
-- altered or dropped.
-- Generated 2026-08-21.

create table if not exists public.clubs (
  id                   text primary key,
  name                 text not null,
  category             text,
  advisor              text,
  description          text,
  target_audience      text,
  detailed_description text,
  meeting_location     text,
  meeting_days         text,
  meeting_time         text,
  is_student_led       boolean not null default false,
  interests            text[] not null default '{}'::text[],
  scores               jsonb  not null default '{}'::jsonb,
  photos               jsonb  not null default '[]'::jsonb,
  instagram            text,
  email                text,
  phone                text
);

create index if not exists clubs_category_idx on public.clubs (category);

alter table public.clubs enable row level security;

-- The live site reads this table with the publishable key and no session
-- (index.html:1652). Anonymous read MUST stay open or the public site breaks.
drop policy if exists "clubs are readable by everyone" on public.clubs;
create policy "clubs are readable by everyone"
  on public.clubs
  for select
  to anon, authenticated
  using (true);

grant select on public.clubs to anon, authenticated;
