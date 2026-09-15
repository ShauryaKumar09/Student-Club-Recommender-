-- Student officers who can actually run their club.
--
-- club_role already had 'officer' in it, but nothing consulted it: every
-- policy and every function asked is_club_advisor(), which matches only
-- 'advisor'. An officer was a label on a roster row and nothing more.
--
-- What an officer gets: the same day-to-day control of their own club as its
-- advisor -- edit the listing, post announcements, add events and links, read
-- the roster, decide join requests.
--
-- What an officer does NOT get: appointing people. Advisors and admins name
-- officers and advisors; officers name nobody. The whole point of the request
-- is that an advisor decides who becomes an officer, and that is not a
-- decision worth much if the officers they appoint can appoint each other --
-- or promote themselves to advisor, which grant_club_advisor would otherwise
-- allow. So membership writes and the two grant/revoke functions keep asking
-- is_club_advisor(); everything else moves to can_manage_club().
--
-- Reversal: supabase/rollback/20260915000000_club_officers_down.sql
-- Generated 2026-09-15.

-- ------------------------------------------------------------ 1. helper --

-- Advisor-or-officer of this club, and admins for every club. Definer for the
-- same reason is_club_advisor() is: the RLS policies that call it read the
-- very table it looks in.
create or replace function public.can_manage_club(club_id text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $fn$
  select coalesce(
    public.auth_role() = 'admin'
    or exists (
      select 1
      from public.memberships m
      where m.user_id = (select auth.uid())
        and m.club_id = can_manage_club.club_id
        and m.role in ('advisor', 'officer')
    ),
    false
  );
$fn$;

revoke all on function public.can_manage_club(text) from public;
grant execute on function public.can_manage_club(text) to authenticated;

-- ------------------------------------------------- 2. naming an officer --

-- Moves somebody between 'member' and 'officer' on one club. Deliberately
-- cannot write 'advisor': that is grant_club_advisor's job, and letting this
-- function set it would hand any advisor a second, unaudited path to it.
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
  -- Advisors and admins only. An officer calling this is refused.
  if not public.is_club_advisor(set_club_role.target_club) then
    raise exception 'not authorised to change roles for %', set_club_role.target_club
      using errcode = '42501';
  end if;

  if set_club_role.new_role not in ('member', 'officer') then
    raise exception 'set_club_role only moves people between member and officer'
      using errcode = '22023';
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

  if membership_id is null then
    raise exception 'that person is not on the roster for %', set_club_role.target_club
      using errcode = 'P0002';
  end if;

  return membership_id;
end;
$fn$;

revoke all on function public.set_club_role(uuid, text, public.club_role) from public;
grant execute on function public.set_club_role(uuid, text, public.club_role) to authenticated;

-- --------------------------------------------- 3. policies officers pass --

-- The club listing itself.
drop policy if exists "club advisors update their club" on public.clubs;
create policy "club advisors update their club"
  on public.clubs for update to authenticated
  using (public.can_manage_club(id))
  with check (public.can_manage_club(id));

-- Reading the roster. Writing it stays advisor-only, below.
drop policy if exists "advisors read their club roster" on public.memberships;
create policy "advisors read their club roster"
  on public.memberships for select to authenticated
  using (public.can_manage_club(club_id));

-- Announcements.
drop policy if exists "advisors write announcements" on public.announcements;
create policy "advisors write announcements"
  on public.announcements for insert to authenticated
  with check (public.can_manage_club(club_id));

drop policy if exists "advisors edit announcements" on public.announcements;
create policy "advisors edit announcements"
  on public.announcements for update to authenticated
  using (public.can_manage_club(club_id))
  with check (public.can_manage_club(club_id));

drop policy if exists "advisors delete announcements" on public.announcements;
create policy "advisors delete announcements"
  on public.announcements for delete to authenticated
  using (public.can_manage_club(club_id));

-- Events.
drop policy if exists "advisors write events" on public.events;
create policy "advisors write events"
  on public.events for insert to authenticated
  with check (public.can_manage_club(club_id));

drop policy if exists "advisors edit events" on public.events;
create policy "advisors edit events"
  on public.events for update to authenticated
  using (public.can_manage_club(club_id))
  with check (public.can_manage_club(club_id));

drop policy if exists "advisors delete events" on public.events;
create policy "advisors delete events"
  on public.events for delete to authenticated
  using (public.can_manage_club(club_id));

-- Resources.
drop policy if exists "advisors write resources" on public.resources;
create policy "advisors write resources"
  on public.resources for insert to authenticated
  with check (public.can_manage_club(club_id));

drop policy if exists "advisors edit resources" on public.resources;
create policy "advisors edit resources"
  on public.resources for update to authenticated
  using (public.can_manage_club(club_id))
  with check (public.can_manage_club(club_id));

drop policy if exists "advisors delete resources" on public.resources;
create policy "advisors delete resources"
  on public.resources for delete to authenticated
  using (public.can_manage_club(club_id));

-- Join requests: seeing them and deciding them.
drop policy if exists "advisors read requests for their club" on public.join_requests;
create policy "advisors read requests for their club"
  on public.join_requests for select to authenticated
  using (public.can_manage_club(club_id));

drop policy if exists "advisors decide requests for their club" on public.join_requests;
create policy "advisors decide requests for their club"
  on public.join_requests for update to authenticated
  using (public.can_manage_club(club_id))
  with check (public.can_manage_club(club_id));

-- decide_join_request creates the membership, so it has to agree with the
-- policy above or an officer would see a request they cannot act on.
create or replace function public.decide_join_request(
  request_id uuid,
  approve    boolean
)
returns public.request_status
language plpgsql
security definer
set search_path = ''
as $fn$
declare
  req        public.join_requests;
  club_name  text;
  new_status public.request_status;
begin
  select * into req from public.join_requests r where r.id = decide_join_request.request_id;

  if not found then
    raise exception 'no join request %', decide_join_request.request_id
      using errcode = 'P0002';
  end if;

  if not public.can_manage_club(req.club_id) then
    raise exception 'not authorised to decide requests for %', req.club_id
      using errcode = '42501';
  end if;

  if req.status <> 'pending' then
    raise exception 'request % is already %', decide_join_request.request_id, req.status
      using errcode = 'P0001';
  end if;

  new_status := case when decide_join_request.approve then 'approved' else 'denied' end;

  update public.join_requests
     set status = new_status,
         decided_by = (select auth.uid()),
         decided_at = now()
   where id = decide_join_request.request_id;

  if decide_join_request.approve then
    insert into public.memberships (user_id, club_id, role)
    values (req.user_id, req.club_id, 'member')
    on conflict (user_id, club_id) do nothing;
  end if;

  select c.name into club_name from public.clubs c where c.id = req.club_id;

  perform public.notify_user(
    req.user_id,
    case when decide_join_request.approve
         then 'You are in: ' || coalesce(club_name, req.club_id)
         else 'Update on your request to join ' || coalesce(club_name, req.club_id) end,
    case when decide_join_request.approve
         then 'Your request was approved. The club now shows on your dashboard.'
         else 'Your request was not approved this time.' end,
    case when decide_join_request.approve then 'success' else 'info' end,
    '/club/' || req.club_id
  );

  return new_status;
end;
$fn$;

revoke all on function public.decide_join_request(uuid, boolean) from public;
grant execute on function public.decide_join_request(uuid, boolean) to authenticated;

-- An officer needs the names on their own roster for the same reason an
-- advisor does, or every student renders as "Unknown".
create or replace function public.can_see_profile(target uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $fn$
  select
    target = (select auth.uid())
    or public.auth_role() = 'admin'
    or exists (
      select 1 from public.memberships m
      where m.user_id = target and public.can_manage_club(m.club_id)
    )
    or exists (
      select 1 from public.join_requests r
      where r.user_id = target
        and r.status = 'pending'
        and public.can_manage_club(r.club_id)
    );
$fn$;

-- ------------------------------------------ 4. what stays advisor-only --
--
-- Left alone on purpose, all still gated on is_club_advisor():
--   * memberships insert / update / delete  -- direct roster writes
--   * grant_club_advisor / revoke_club_advisor
--   * set_club_role, above
--
-- So an officer can run their club and decide who joins it, and cannot
-- change who runs it.
