-- Reverses 20260823000000_security_hardening.sql.
--
-- Restores the weaker policies exactly as they were. Only useful if one of
-- them turns out to block a legitimate flow; each is a real hole otherwise.

drop policy if exists "users update their own profile" on public.profiles;
create policy "users update their own profile"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (
    id = (select auth.uid())
    and role = public.auth_role()
  );

drop function if exists public.auth_profile_email();

drop policy if exists "anyone may file a bug report" on public.bug_reports;
create policy "anyone may file a bug report"
  on public.bug_reports for insert to anon, authenticated
  with check (true);

alter table public.resources drop constraint if exists resources_url_scheme;

-- handle_new_user() is deliberately left as the hardened version: reverting it
-- re-arms a permanent email-to-admin rule. If that is genuinely wanted, copy
-- the body back from 20260822000300_signup_controls.sql by hand.
