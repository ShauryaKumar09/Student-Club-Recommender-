-- Naming an officer should not require the student to join first
--
-- set_club_role only UPDATEd an existing memberships row, so making a student
-- an officer took three steps across two people: the student had to find the
-- club and ask to join, an advisor had to approve the request, and only then
-- could anyone promote them. If they had not joined, the call failed with
-- "that person is not on the roster".
--
-- grant_club_advisor has always created the membership when there was none.
-- The two calls sit side by side in the admin UI -- Advisor works in one step,
-- Officer did not -- so this was an inconsistency rather than a rule.
--
-- Nothing here widens who may appoint: both functions stay advisor-or-admin.
-- An advisor can already write their own club's roster directly, so adding
-- somebody as an officer is a door onto power they had, not a new power.
--
-- Neither function touches profiles.role. A club officer is a role on one
-- membership; the person's account stays whatever it was, normally 'student'.

-- ----------------------------------------------------------- set_club_role --

create or replace function public.set_club_role(
  target_user uuid,
  target_club text,
  new_role    public.club_role
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $fn$
declare
  membership_id uuid;
begin
  if not public.is_club_advisor(set_club_role.target_club) then
    raise exception 'not authorised to change roles for %', set_club_role.target_club
      using errcode = '42501';
  end if;

  if set_club_role.new_role not in ('member', 'officer') then
    raise exception 'set_club_role only moves people between member and officer'
      using errcode = '22023';
  end if;

  if not exists (select 1 from public.profiles p where p.id = set_club_role.target_user) then
    raise exception 'no account for that person'
      using errcode = 'P0002';
  end if;

  -- Never silently demote an advisor through the officer control.
  if exists (
    select 1 from public.memberships m
    where m.user_id = set_club_role.target_user
      and m.club_id = set_club_role.target_club
      and m.role = 'advisor'
  ) then
    raise exception 'that person is an advisor of this club; remove the advisor assignment first'
      using errcode = 'P0001';
  end if;

  update public.memberships
     set role = set_club_role.new_role
   where user_id = set_club_role.target_user
     and club_id = set_club_role.target_club
  returning id into membership_id;

  -- The change from the previous version: no roster row means create one,
  -- rather than refusing. Demoting somebody who was never on the roster is
  -- still a no-op -- there is nothing to move down to member.
  if membership_id is null and set_club_role.new_role = 'officer' then
    insert into public.memberships (user_id, club_id, role)
    values (set_club_role.target_user, set_club_role.target_club, 'officer')
    returning id into membership_id;
  end if;

  if membership_id is null then
    raise exception 'that person is not on the roster for %', set_club_role.target_club
      using errcode = 'P0002';
  end if;

  return membership_id;
end;
$fn$;

revoke all on function public.set_club_role(uuid, text, public.club_role) from public;
grant execute on function public.set_club_role(uuid, text, public.club_role) to authenticated;

-- ------------------------------------------------ add_club_officer_by_email --
--
-- For advisors. An advisor can only read profiles of people already on their
-- roster (can_see_profile), so they cannot search the school for a student to
-- promote -- and widening that to let them browse every student's profile
-- would be a much bigger change than this request needs. Naming the exact
-- address they already know keeps the directory shut.

create or replace function public.add_club_officer_by_email(
  target_email text,
  target_club  text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $fn$
declare
  found_id uuid;
begin
  if not public.is_club_advisor(add_club_officer_by_email.target_club) then
    raise exception 'not authorised to name officers for %', add_club_officer_by_email.target_club
      using errcode = '42501';
  end if;

  select p.id into found_id
    from public.profiles p
   where lower(p.email) = lower(trim(add_club_officer_by_email.target_email));

  if found_id is null then
    raise exception 'no TrojanMatch account for %; they need to sign up first',
      trim(add_club_officer_by_email.target_email)
      using errcode = 'P0002';
  end if;

  return public.set_club_role(found_id, add_club_officer_by_email.target_club, 'officer');
end;
$fn$;

revoke all on function public.add_club_officer_by_email(text, text) from public;
grant execute on function public.add_club_officer_by_email(text, text) to authenticated;
