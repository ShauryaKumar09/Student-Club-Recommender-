-- Let clubs upload their own images, and describe their resource sections
--
-- Two things people running clubs asked for and could not do.
--
-- 1. Images. The club-photos bucket exists and is public to read, but it has
--    no write policies at all, so it was fillable only by the service-role
--    script that seeded it. An advisor could not add a photo of their own
--    club, attach one to an announcement, or replace a logo.
--
-- 2. Resource sections were a name and nothing else. An advisor naming a
--    section "Competitions" had nowhere to say what belongs in it or what a
--    student should do there.

-- --------------------------------------------------- 1. storage write access --
--
-- Everything a club uploads goes under its own club id:  <club_id>/<file>
-- The seeded photos sit flat at the bucket root and are left alone -- they
-- stay readable, and no policy here matches them, so nobody can overwrite
-- them from the browser either.

drop policy if exists "club managers upload club photos" on storage.objects;
create policy "club managers upload club photos"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'club-photos'
    and array_length(storage.foldername(name), 1) >= 1
    and public.can_manage_club((storage.foldername(name))[1])
  );

drop policy if exists "club managers replace club photos" on storage.objects;
create policy "club managers replace club photos"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'club-photos'
    and array_length(storage.foldername(name), 1) >= 1
    and public.can_manage_club((storage.foldername(name))[1])
  );

drop policy if exists "club managers delete club photos" on storage.objects;
create policy "club managers delete club photos"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'club-photos'
    and array_length(storage.foldername(name), 1) >= 1
    and public.can_manage_club((storage.foldername(name))[1])
  );

-- The bucket is public, so reads need no policy. Cap the size and the types
-- here rather than trusting the browser: a 40MB camera JPEG uploaded by
-- accident is the likeliest failure, not an attack.
update storage.buckets
   set file_size_limit = 5242880,
       allowed_mime_types = array['image/png', 'image/jpeg', 'image/webp', 'image/gif']
 where id = 'club-photos';

-- ------------------------------------------------- 2. images on announcements --

alter table public.announcements
  add column if not exists image_url text;

-- ------------------------------------------------------ 3. resource sections --
--
-- A section is still just the `kind` string its resources share -- that stays
-- true, and a section with no row here simply has no description. This table
-- only carries what an advisor writes about one.

create table if not exists public.club_modules (
  id         uuid primary key default gen_random_uuid(),
  club_id    text not null references public.clubs (id) on delete cascade,
  name       text not null,
  blurb      text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists club_modules_club_name_idx
  on public.club_modules (club_id, name);

alter table public.club_modules enable row level security;

drop policy if exists "anyone reads club modules" on public.club_modules;
create policy "anyone reads club modules"
  on public.club_modules for select to anon, authenticated
  using (true);

drop policy if exists "club managers write club modules" on public.club_modules;
create policy "club managers write club modules"
  on public.club_modules for insert to authenticated
  with check (public.can_manage_club(club_id));

drop policy if exists "club managers update club modules" on public.club_modules;
create policy "club managers update club modules"
  on public.club_modules for update to authenticated
  using (public.can_manage_club(club_id))
  with check (public.can_manage_club(club_id));

drop policy if exists "club managers delete club modules" on public.club_modules;
create policy "club managers delete club modules"
  on public.club_modules for delete to authenticated
  using (public.can_manage_club(club_id));
