-- Reverses supabase/migrations/20260821000100_auth_roles.sql.
--
-- Supabase migrations have no native `down`, so this is kept alongside and run
-- by hand. Order is the inverse of the migration: policies, then the trigger,
-- then functions, then tables, then enums. `clubs` is left standing with its
-- baseline anon-read policy intact -- only the policies this migration added
-- to it are removed.
-- Generated 2026-08-21.

begin;

-- policies added to the pre-existing clubs table
drop policy if exists "club advisors update their club" on public.clubs;
drop policy if exists "admins insert clubs"             on public.clubs;
drop policy if exists "admins delete clubs"             on public.clubs;

revoke insert, update, delete on public.clubs from authenticated;

-- trigger before the function it calls
drop trigger  if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();

-- tables (policies and grants go with them)
drop table if exists public.audit_log;
drop table if exists public.resources;
drop table if exists public.events;
drop table if exists public.announcements;
drop table if exists public.memberships;

-- profiles goes before the helpers, not after: its policies call auth_role(),
-- so dropping the function first fails with "cannot drop function auth_role()
-- because other objects depend on it". Dropping the table takes its policies
-- with it and clears the dependency.
drop table if exists public.profiles;

drop function if exists public.log_audit_event(text, text, text, jsonb);
drop function if exists public.is_club_advisor(text);
drop function if exists public.auth_role();

drop type if exists public.club_role;
drop type if exists public.app_role;

commit;
