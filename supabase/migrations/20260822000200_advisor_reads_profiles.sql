-- Let an advisor see the names of people in their own club.
--
-- 20260821000100 gave profiles three read policies: your own row, and every
-- row if you are an admin. That left an advisor unable to read the profile of
-- anyone on their own roster, so the Members panel and the join-request queue
-- both rendered every student as "Unknown".
--
-- The visibility is deliberately narrow: an advisor can read a profile only
-- while that person is a member of, or has a request pending for, a club that
-- advisor actually runs. It does not open the wider directory.
--
-- can_see_profile() is security definer so the membership and join_requests
-- lookups inside it are not themselves filtered by RLS -- otherwise the policy
-- would depend on the very rows it is deciding access to.
-- Generated 2026-08-22.

create or replace function public.can_see_profile(target uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    target = (select auth.uid())
    or public.auth_role() = 'admin'
    or exists (
      select 1 from public.memberships m
      where m.user_id = target and public.is_club_advisor(m.club_id)
    )
    or exists (
      select 1 from public.join_requests r
      where r.user_id = target
        and r.status = 'pending'
        and public.is_club_advisor(r.club_id)
    );
$$;

revoke all on function public.can_see_profile(uuid) from public;
grant execute on function public.can_see_profile(uuid) to authenticated;

drop policy if exists "advisors read profiles in their clubs" on public.profiles;
create policy "advisors read profiles in their clubs"
  on public.profiles for select to authenticated
  using (public.can_see_profile(id));
