-- Authentication, roles, and row-level security.
--
-- Adds: app_role/club_role enums, profiles, memberships, announcements, events,
-- resources, audit_log; a signup trigger; three helper functions; and RLS on
-- every table including the pre-existing `clubs`.
--
-- Design notes:
--   * `club_id` is `text`, not `uuid` -- clubs.id is a slug ('key-club').
--   * Every function is `security definer` with `set search_path = ''` and
--     fully-qualified names. The helpers MUST be definer: RLS policies on
--     `profiles` and `memberships` call them, and an invoker-rights function
--     reading those tables would re-enter its own policy and recurse.
--   * A client-supplied role is never trusted. Signup always writes 'student';
--     only an admin can move anyone off it, and only through RLS.
--   * Reversal lives in supabase/rollback/20260821000100_auth_roles_down.sql.
-- Generated 2026-08-21.

-- ---------------------------------------------------------------- 1. enums --

do $$
begin
  create type public.app_role as enum ('student', 'advisor', 'admin');
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  create type public.club_role as enum ('member', 'officer', 'advisor');
exception
  when duplicate_object then null;
end
$$;

-- --------------------------------------------------------------- 2. tables --

create table if not exists public.profiles (
  id         uuid primary key references auth.users (id) on delete cascade,
  email      text,
  full_name  text,
  role       public.app_role not null default 'student',
  created_at timestamptz not null default now()
);

create table if not exists public.memberships (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  club_id    text not null references public.clubs (id) on delete cascade,
  role       public.club_role not null default 'member',
  created_at timestamptz not null default now(),
  constraint memberships_user_club_key unique (user_id, club_id)
);

create index if not exists memberships_club_id_idx on public.memberships (club_id);
create index if not exists memberships_user_id_idx on public.memberships (user_id);

create table if not exists public.announcements (
  id         uuid primary key default gen_random_uuid(),
  club_id    text not null references public.clubs (id) on delete cascade,
  author_id  uuid references public.profiles (id) on delete set null,
  title      text not null,
  body       text,
  pinned     boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists announcements_club_id_idx on public.announcements (club_id, created_at desc);

create table if not exists public.events (
  id          uuid primary key default gen_random_uuid(),
  club_id     text not null references public.clubs (id) on delete cascade,
  title       text not null,
  description text,
  location    text,
  starts_at   timestamptz not null,
  ends_at     timestamptz,
  created_at  timestamptz not null default now(),
  constraint events_ends_after_starts check (ends_at is null or ends_at >= starts_at)
);

create index if not exists events_club_id_idx on public.events (club_id, starts_at);

create table if not exists public.resources (
  id         uuid primary key default gen_random_uuid(),
  club_id    text not null references public.clubs (id) on delete cascade,
  title      text not null,
  url        text not null,
  kind       text,
  created_at timestamptz not null default now()
);

create index if not exists resources_club_id_idx on public.resources (club_id);

create table if not exists public.audit_log (
  id           bigint generated always as identity primary key,
  actor_id     uuid references public.profiles (id) on delete set null,
  action       text not null,
  target_table text,
  target_id    text,
  metadata     jsonb not null default '{}'::jsonb,
  created_at   timestamptz not null default now()
);

create index if not exists audit_log_created_at_idx on public.audit_log (created_at desc);

-- ------------------------------------------------------------ 3. functions --

-- The caller's app_role, read past RLS so policies on `profiles` can call it
-- without recursing. `stable` matters for the profiles UPDATE policy: within a
-- statement it sees the pre-update snapshot, which is what lets the `with
-- check` below compare the incoming role against the existing one.
create or replace function public.auth_role()
returns public.app_role
language sql
stable
security definer
set search_path = ''
as $$
  select p.role
  from public.profiles p
  where p.id = (select auth.uid());
$$;

-- True when the caller is an admin, or holds an 'advisor' membership for this
-- club. Admins pass for every club, so policies only ever need this one call.
create or replace function public.is_club_advisor(club_id text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    public.auth_role() = 'admin'
    or exists (
      select 1
      from public.memberships m
      where m.user_id = (select auth.uid())
        and m.club_id = is_club_advisor.club_id
        and m.role = 'advisor'
    ),
    false
  );
$$;

-- The only write path into audit_log; the table has no INSERT policy at all.
create or replace function public.log_audit_event(
  action       text,
  target_table text  default null,
  target_id    text  default null,
  metadata     jsonb default '{}'::jsonb
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_id bigint;
begin
  if (select auth.uid()) is null then
    raise exception 'log_audit_event requires an authenticated caller'
      using errcode = '42501';
  end if;

  insert into public.audit_log (actor_id, action, target_table, target_id, metadata)
  values (
    (select auth.uid()),
    log_audit_event.action,
    log_audit_event.target_table,
    log_audit_event.target_id,
    coalesce(log_audit_event.metadata, '{}'::jsonb)
  )
  returning id into new_id;

  return new_id;
end;
$$;

revoke all on function public.log_audit_event(text, text, text, jsonb) from public;
grant execute on function public.log_audit_event(text, text, text, jsonb) to authenticated;

-- ---------------------------------------------------- 4. signup trigger ----

-- Mirrors every auth.users row into public.profiles. `role` is deliberately
-- left to its 'student' default and is NOT read from raw_user_meta_data --
-- that field is client-controlled at signup and would be a privilege
-- escalation if trusted.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, email, full_name)
  values (
    new.id,
    new.email,
    nullif(trim(coalesce(new.raw_user_meta_data ->> 'full_name', '')), '')
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();

-- --------------------------------------------------------------- 5. grants --

grant select, insert, update, delete on public.memberships   to authenticated;
grant select, insert, update, delete on public.announcements to authenticated;
grant select, insert, update, delete on public.events        to authenticated;
grant select, insert, update, delete on public.resources     to authenticated;
grant select, update, delete         on public.profiles      to authenticated;
grant select                         on public.audit_log     to authenticated;
grant insert, update, delete         on public.clubs         to authenticated;

-- anon gets nothing beyond the public clubs read granted in the baseline.

-- ---------------------------------------------------------- 6. enable RLS --

alter table public.profiles      enable row level security;
alter table public.memberships   enable row level security;
alter table public.announcements enable row level security;
alter table public.events        enable row level security;
alter table public.resources     enable row level security;
alter table public.audit_log     enable row level security;

-- ------------------------------------------------------------ 7. policies --

-- clubs -----------------------------------------------------------------
-- SELECT stays as the baseline left it (anon + authenticated, unrestricted).

drop policy if exists "club advisors update their club" on public.clubs;
create policy "club advisors update their club"
  on public.clubs for update to authenticated
  using (public.is_club_advisor(id))
  with check (public.is_club_advisor(id));

drop policy if exists "admins insert clubs" on public.clubs;
create policy "admins insert clubs"
  on public.clubs for insert to authenticated
  with check (public.auth_role() = 'admin');

drop policy if exists "admins delete clubs" on public.clubs;
create policy "admins delete clubs"
  on public.clubs for delete to authenticated
  using (public.auth_role() = 'admin');

-- profiles --------------------------------------------------------------

drop policy if exists "users read their own profile" on public.profiles;
create policy "users read their own profile"
  on public.profiles for select to authenticated
  using (id = (select auth.uid()));

drop policy if exists "admins read all profiles" on public.profiles;
create policy "admins read all profiles"
  on public.profiles for select to authenticated
  using (public.auth_role() = 'admin');

-- Self-service edits, minus the role column. auth_role() is `stable` and
-- definer, so it returns the row's committed role for the whole statement;
-- an UPDATE that changes `role` therefore fails this check.
drop policy if exists "users update their own profile" on public.profiles;
create policy "users update their own profile"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (
    id = (select auth.uid())
    and role = public.auth_role()
  );

drop policy if exists "admins update any profile" on public.profiles;
create policy "admins update any profile"
  on public.profiles for update to authenticated
  using (public.auth_role() = 'admin')
  with check (public.auth_role() = 'admin');

drop policy if exists "admins delete profiles" on public.profiles;
create policy "admins delete profiles"
  on public.profiles for delete to authenticated
  using (public.auth_role() = 'admin');

-- No INSERT policy on purpose: rows arrive only via handle_new_user().

-- memberships -----------------------------------------------------------

drop policy if exists "users read their own memberships" on public.memberships;
create policy "users read their own memberships"
  on public.memberships for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists "advisors read their club roster" on public.memberships;
create policy "advisors read their club roster"
  on public.memberships for select to authenticated
  using (public.is_club_advisor(club_id));

drop policy if exists "advisors add members" on public.memberships;
create policy "advisors add members"
  on public.memberships for insert to authenticated
  with check (public.is_club_advisor(club_id));

drop policy if exists "advisors update members" on public.memberships;
create policy "advisors update members"
  on public.memberships for update to authenticated
  using (public.is_club_advisor(club_id))
  with check (public.is_club_advisor(club_id));

drop policy if exists "advisors remove members" on public.memberships;
create policy "advisors remove members"
  on public.memberships for delete to authenticated
  using (public.is_club_advisor(club_id));

-- announcements ---------------------------------------------------------

drop policy if exists "announcements readable when signed in" on public.announcements;
create policy "announcements readable when signed in"
  on public.announcements for select to authenticated
  using (true);

drop policy if exists "advisors write announcements" on public.announcements;
create policy "advisors write announcements"
  on public.announcements for insert to authenticated
  with check (public.is_club_advisor(club_id));

drop policy if exists "advisors edit announcements" on public.announcements;
create policy "advisors edit announcements"
  on public.announcements for update to authenticated
  using (public.is_club_advisor(club_id))
  with check (public.is_club_advisor(club_id));

drop policy if exists "advisors delete announcements" on public.announcements;
create policy "advisors delete announcements"
  on public.announcements for delete to authenticated
  using (public.is_club_advisor(club_id));

-- events ----------------------------------------------------------------

drop policy if exists "events readable when signed in" on public.events;
create policy "events readable when signed in"
  on public.events for select to authenticated
  using (true);

drop policy if exists "advisors write events" on public.events;
create policy "advisors write events"
  on public.events for insert to authenticated
  with check (public.is_club_advisor(club_id));

drop policy if exists "advisors edit events" on public.events;
create policy "advisors edit events"
  on public.events for update to authenticated
  using (public.is_club_advisor(club_id))
  with check (public.is_club_advisor(club_id));

drop policy if exists "advisors delete events" on public.events;
create policy "advisors delete events"
  on public.events for delete to authenticated
  using (public.is_club_advisor(club_id));

-- resources -------------------------------------------------------------

drop policy if exists "resources readable when signed in" on public.resources;
create policy "resources readable when signed in"
  on public.resources for select to authenticated
  using (true);

drop policy if exists "advisors write resources" on public.resources;
create policy "advisors write resources"
  on public.resources for insert to authenticated
  with check (public.is_club_advisor(club_id));

drop policy if exists "advisors edit resources" on public.resources;
create policy "advisors edit resources"
  on public.resources for update to authenticated
  using (public.is_club_advisor(club_id))
  with check (public.is_club_advisor(club_id));

drop policy if exists "advisors delete resources" on public.resources;
create policy "advisors delete resources"
  on public.resources for delete to authenticated
  using (public.is_club_advisor(club_id));

-- audit_log -------------------------------------------------------------
-- Read: admins only. Write: no policy exists, so every direct INSERT/UPDATE/
-- DELETE is refused; public.log_audit_event() is the only way in.

drop policy if exists "admins read the audit log" on public.audit_log;
create policy "admins read the audit log"
  on public.audit_log for select to authenticated
  using (public.auth_role() = 'admin');
