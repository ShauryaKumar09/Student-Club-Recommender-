-- Repair path for accounts that exist in auth.users but have no profile row.
--
-- Why this is needed: accounts created before 20260821000100_auth_roles.sql
-- was pushed to a project never went through handle_new_user(), so they have
-- no public.profiles row. Signing in works -- GoTrue issues a session -- but
-- every dashboard query returns nothing and the client can only say "signed
-- in, but no profile exists for this account yet". One real account
-- (menonnay000@isd284.com, created 2026-08-20) was in exactly that state on
-- production.
--
-- Two parts:
--   1. A one-off backfill for rows already in that state.
--   2. ensure_profile(), so the client can repair itself instead of dead-
--      ending. It is idempotent and cannot invent an account: it only ever
--      writes a row for auth.uid(), which means the caller already holds a
--      valid session for a confirmed address.
--
-- The role is NOT taken from anything the client sends, exactly as in
-- handle_new_user(). Every repaired profile starts as 'student'.
--
-- Reversal: supabase/rollback/20260822000400_profile_repair_down.sql
-- Generated 2026-08-22.

-- ------------------------------------------------------------- 1. backfill --

insert into public.profiles (id, email, full_name)
select
  u.id,
  u.email,
  nullif(trim(coalesce(u.raw_user_meta_data ->> 'full_name', '')), '')
from auth.users u
where not exists (select 1 from public.profiles p where p.id = u.id)
on conflict (id) do nothing;

-- ------------------------------------------------------- 2. ensure_profile --

-- Returns the caller's profile, creating it first if it is missing. Security
-- definer because `authenticated` has no INSERT grant on profiles -- and it
-- should not get one, since the whole point is that a client cannot choose the
-- id, the email or the role. All three come from auth.uid() and auth.users.
create or replace function public.ensure_profile()
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid  uuid := (select auth.uid());
  row  public.profiles;
begin
  if uid is null then
    raise exception 'ensure_profile requires an authenticated caller'
      using errcode = '42501';
  end if;

  insert into public.profiles (id, email, full_name)
  select
    u.id,
    u.email,
    nullif(trim(coalesce(u.raw_user_meta_data ->> 'full_name', '')), '')
  from auth.users u
  where u.id = uid
  on conflict (id) do nothing;

  -- Keep the email in step if the account's address was changed in auth after
  -- the profile was written. Never touches role or full_name.
  update public.profiles p
     set email = u.email
    from auth.users u
   where p.id = uid
     and u.id = uid
     and p.email is distinct from u.email;

  select * into row from public.profiles p where p.id = uid;
  return row;
end;
$$;

revoke all on function public.ensure_profile() from public;
grant execute on function public.ensure_profile() to authenticated;
