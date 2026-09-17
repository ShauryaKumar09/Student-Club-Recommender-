-- Saving a club joins it; no request, no approval
--
-- Joining took a request the student filed and an advisor approved. For a
-- school activities directory that is the wrong shape: these are clubs you
-- turn up to, not applications. Saving a club from the directory is now the
-- whole of joining it.
--
-- Two tables described one idea -- saved_clubs said "on my dashboard" and
-- memberships said "on the roster" -- and nothing kept them in step. Both
-- writes happen inside one function now, so they cannot drift.
--
-- join_club and leave_club already existed, from 20260821000200, and were
-- already granted to authenticated -- they were simply never wired to the
-- button. Two things had to change:
--
--   * join_club only wrote memberships, so joining never showed on the
--     dashboard, which reads saved_clubs.
--   * leave_club deleted ANY membership for the caller, advisor and officer
--     rows included. Harmless while nothing called it; now that unsaving
--     does, an advisor clicking the star on their own club would have
--     deleted their own advisorship. It only removes 'member' rows now.
--
-- join_club keeps its uuid return type: Postgres will not change the return
-- type of an existing function on replace, and callers may rely on it.

-- --------------------------------------------------------------- join_club --

create or replace function public.join_club(target_club text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $fn$
declare
  me uuid := (select auth.uid());
  membership_id uuid;
begin
  if me is null then
    raise exception 'sign in to join a club' using errcode = '42501';
  end if;

  if not exists (select 1 from public.clubs c where c.id = join_club.target_club) then
    raise exception 'no club called %', join_club.target_club using errcode = 'P0002';
  end if;

  -- Already an advisor or officer? Then they are on the roster in a way this
  -- must not overwrite; just make sure it shows on their dashboard.
  insert into public.memberships (user_id, club_id, role)
  values (me, join_club.target_club, 'member')
  on conflict (user_id, club_id) do nothing
  returning id into membership_id;

  if membership_id is null then
    select m.id into membership_id
      from public.memberships m
     where m.user_id = me and m.club_id = join_club.target_club;
  end if;

  -- The half that was missing: the dashboard reads saved_clubs, so a join
  -- that only wrote memberships never showed up.
  insert into public.saved_clubs (user_id, club_id)
  values (me, join_club.target_club)
  on conflict (user_id, club_id) do nothing;

  return membership_id;
end;
$fn$;

revoke all on function public.join_club(text) from public;
grant execute on function public.join_club(text) to authenticated;

-- -------------------------------------------------------------- leave_club --

create or replace function public.leave_club(target_club text)
returns void
language plpgsql
security definer
set search_path = ''
as $fn$
declare
  me uuid := (select auth.uid());
begin
  if me is null then
    raise exception 'sign in first' using errcode = '42501';
  end if;

  delete from public.saved_clubs
   where user_id = me and club_id = leave_club.target_club;

  -- Only ever removes a plain membership. An advisor or officer unsaving a
  -- club keeps their post -- losing it by clicking a star would be a nasty
  -- surprise, and only an advisor may change those.
  delete from public.memberships
   where user_id = me
     and club_id = leave_club.target_club
     and role = 'member';
end;
$fn$;

revoke all on function public.leave_club(text) from public;
grant execute on function public.leave_club(text) to authenticated;

-- ------------------------------------------------- existing saves and requests --
--
-- Everyone who had already saved a club meant to be in it under the new rule,
-- and everyone with a request pending was waiting for permission that is no
-- longer required. Both become memberships rather than being stranded.

insert into public.memberships (user_id, club_id, role)
select s.user_id, s.club_id, 'member'
  from public.saved_clubs s
 where exists (select 1 from public.clubs c where c.id = s.club_id)
on conflict (user_id, club_id) do nothing;

insert into public.memberships (user_id, club_id, role)
select r.user_id, r.club_id, 'member'
  from public.join_requests r
 where r.status = 'pending'
   and exists (select 1 from public.clubs c where c.id = r.club_id)
on conflict (user_id, club_id) do nothing;

insert into public.saved_clubs (user_id, club_id)
select r.user_id, r.club_id
  from public.join_requests r
 where r.status = 'pending'
   and exists (select 1 from public.clubs c where c.id = r.club_id)
on conflict (user_id, club_id) do nothing;

update public.join_requests
   set status = 'approved'
 where status = 'pending';

-- request_to_join_club and decide_join_request are left in place, unused, and
-- join_requests keeps its history. Dropping them is a separate decision from
-- taking the feature off the screen, and this migration should be reversible
-- by putting the buttons back.
