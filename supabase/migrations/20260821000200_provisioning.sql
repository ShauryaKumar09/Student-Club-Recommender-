-- Provisioning entry points and audit wiring.
--
-- 20260821000100 set up who may do what. This adds the paths by which people
-- actually get their roles, plus triggers so privilege changes are recorded
-- whatever route they take.
--
-- Why functions when RLS already permits these writes:
--   * set_user_role() refuses to remove the last admin. A bare UPDATE through
--     the admins-update-any-profile policy would happily lock everyone out.
--   * join_club() / leave_club() close a real gap -- `memberships` has no
--     self-service INSERT policy, so before this a student could not join
--     anything without an advisor doing it for them.
--   * grant/revoke_club_advisor() give appointment a name in the audit log
--     instead of an anonymous membership UPDATE.
--
-- The triggers are the belt to those braces: an admin dashboard that PATCHes
-- public.profiles straight through PostgREST never calls set_user_role(), and
-- that privilege change still has to be recorded.
-- Generated 2026-08-21.

-- ------------------------------------------------------------- 1. triggers --

-- Writes directly to audit_log rather than calling log_audit_event(), because
-- that function requires an authenticated caller and these triggers must also
-- survive seed/migration-time writes where auth.uid() is null.
create or replace function public.audit_profile_role_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.role is distinct from old.role then
    insert into public.audit_log (actor_id, action, target_table, target_id, metadata)
    values (
      (select auth.uid()),
      'profile.role_changed',
      'profiles',
      new.id::text,
      jsonb_build_object('from', old.role, 'to', new.role)
    );
  end if;

  return new;
end;
$$;

drop trigger if exists on_profile_role_changed on public.profiles;
create trigger on_profile_role_changed
  after update of role on public.profiles
  for each row
  execute function public.audit_profile_role_change();

create or replace function public.audit_membership_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  affected public.memberships := coalesce(new, old);
begin
  insert into public.audit_log (actor_id, action, target_table, target_id, metadata)
  values (
    (select auth.uid()),
    'membership.' || lower(tg_op),
    'memberships',
    affected.id::text,
    jsonb_build_object(
      'user_id',  affected.user_id,
      'club_id',  affected.club_id,
      'old_role', case when tg_op = 'INSERT' then null else old.role end,
      'new_role', case when tg_op = 'DELETE' then null else new.role end
    )
  );

  return coalesce(new, old);
end;
$$;

drop trigger if exists on_membership_changed on public.memberships;
create trigger on_membership_changed
  after insert or update or delete on public.memberships
  for each row
  execute function public.audit_membership_change();

-- --------------------------------------------------- 2. role provisioning --

-- Admin-only. Refuses to demote the last remaining admin, which is the one
-- way this system can be permanently locked out of its own administration.
create or replace function public.set_user_role(
  target_user uuid,
  new_role    public.app_role
)
returns public.app_role
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_role_value public.app_role;
begin
  if public.auth_role() is distinct from 'admin' then
    raise exception 'only an admin may change a role'
      using errcode = '42501';
  end if;

  select p.role into current_role_value
  from public.profiles p
  where p.id = set_user_role.target_user;

  if not found then
    raise exception 'no profile for user %', set_user_role.target_user
      using errcode = 'P0002';
  end if;

  if current_role_value = 'admin'
     and set_user_role.new_role is distinct from 'admin'
     and (select count(*) from public.profiles p where p.role = 'admin') <= 1
  then
    raise exception 'cannot demote the last remaining admin'
      using errcode = 'P0001';
  end if;

  -- The on_profile_role_changed trigger records this.
  update public.profiles
     set role = set_user_role.new_role
   where id = set_user_role.target_user;

  return set_user_role.new_role;
end;
$$;

-- ---------------------------------------------------- 3. club provisioning --

-- Gated on is_club_advisor(), matching the memberships RLS policies exactly:
-- an admin may appoint anywhere, an existing advisor only within their club.
create or replace function public.grant_club_advisor(
  target_user uuid,
  target_club text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  membership_id uuid;
begin
  if not public.is_club_advisor(grant_club_advisor.target_club) then
    raise exception 'not authorised to appoint advisors for %', grant_club_advisor.target_club
      using errcode = '42501';
  end if;

  if not exists (select 1 from public.profiles p where p.id = grant_club_advisor.target_user) then
    raise exception 'no profile for user %', grant_club_advisor.target_user
      using errcode = 'P0002';
  end if;

  insert into public.memberships (user_id, club_id, role)
  values (grant_club_advisor.target_user, grant_club_advisor.target_club, 'advisor')
  on conflict (user_id, club_id) do update set role = 'advisor'
  returning id into membership_id;

  return membership_id;
end;
$$;

-- Demotes to 'member' rather than deleting: losing advisor rights should not
-- silently drop someone out of the club roster.
create or replace function public.revoke_club_advisor(
  target_user uuid,
  target_club text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_club_advisor(revoke_club_advisor.target_club) then
    raise exception 'not authorised to revoke advisors for %', revoke_club_advisor.target_club
      using errcode = '42501';
  end if;

  update public.memberships
     set role = 'member'
   where user_id = revoke_club_advisor.target_user
     and club_id = revoke_club_advisor.target_club
     and role = 'advisor';
end;
$$;

-- ------------------------------------------------- 4. self-service joining --

-- Always 'member'. The role is hardcoded rather than taken as an argument so
-- there is no shape of this call that self-appoints an advisor. An existing
-- advisor row is left alone by the DO NOTHING.
create or replace function public.join_club(target_club text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  membership_id uuid;
begin
  if (select auth.uid()) is null then
    raise exception 'join_club requires an authenticated caller'
      using errcode = '42501';
  end if;

  if not exists (select 1 from public.clubs c where c.id = join_club.target_club) then
    raise exception 'no club with id %', join_club.target_club
      using errcode = 'P0002';
  end if;

  insert into public.memberships (user_id, club_id, role)
  values ((select auth.uid()), join_club.target_club, 'member')
  on conflict (user_id, club_id) do nothing
  returning id into membership_id;

  if membership_id is null then
    select m.id into membership_id
    from public.memberships m
    where m.user_id = (select auth.uid())
      and m.club_id = join_club.target_club;
  end if;

  return membership_id;
end;
$$;

-- Only ever removes the caller's own row.
create or replace function public.leave_club(target_club text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then
    raise exception 'leave_club requires an authenticated caller'
      using errcode = '42501';
  end if;

  delete from public.memberships
   where user_id = (select auth.uid())
     and club_id = leave_club.target_club;
end;
$$;

-- ---------------------------------------------------------------- 5. grants --

revoke all on function public.set_user_role(uuid, public.app_role)      from public;
revoke all on function public.grant_club_advisor(uuid, text)            from public;
revoke all on function public.revoke_club_advisor(uuid, text)           from public;
revoke all on function public.join_club(text)                           from public;
revoke all on function public.leave_club(text)                          from public;

grant execute on function public.set_user_role(uuid, public.app_role)   to authenticated;
grant execute on function public.grant_club_advisor(uuid, text)         to authenticated;
grant execute on function public.revoke_club_advisor(uuid, text)        to authenticated;
grant execute on function public.join_club(text)                        to authenticated;
grant execute on function public.leave_club(text)                       to authenticated;
