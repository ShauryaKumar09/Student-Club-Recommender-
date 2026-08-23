-- Security hardening, from an audit of the live API on 2026-08-23.
--
-- Each item below was confirmed against production with the publishable key
-- and with a throwaway student account, not read off these files. What already
-- held is listed at the bottom so a future reader does not re-test it blind.
--
-- Reversal: supabase/rollback/20260823000000_security_hardening_down.sql
-- Generated 2026-08-23.

-- -------------------------------------------- 1. profiles.email is not mine --
--
-- CONFIRMED: a student could PATCH their own profiles row and set `email` to
-- anything. It stuck. profiles.email is what the advisor roster, the admin
-- "Users and roles" table and every notification address are read from, so a
-- student could appear on a roster as principal@wayzataschools.org.
--
-- `role` was already protected, by comparing the incoming value against
-- auth_role() -- a stable security-definer read that sees the pre-update
-- snapshot. The same trick works for email.

create or replace function public.auth_profile_email()
returns text
language sql
stable
security definer
set search_path = ''
as $fn$
  select p.email
  from public.profiles p
  where p.id = (select auth.uid());
$fn$;

revoke all on function public.auth_profile_email() from public;
grant execute on function public.auth_profile_email() to authenticated;

drop policy if exists "users update their own profile" on public.profiles;
create policy "users update their own profile"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (
    id = (select auth.uid())
    and role = public.auth_role()
    and email is not distinct from public.auth_profile_email()
  );

-- full_name stays editable: it is display-only and the person it names owns it.
--
-- ensure_profile() and handle_new_user() are security definer and owned by the
-- table owner, so they still keep profiles.email in step with auth.users. The
-- address can only ever change by changing it in auth, which needs the inbox.

-- -------------------------------------------------- 2. bug report forgery --
--
-- CONFIRMED: the insert policy was `with check (true)` for anon. Filing a
-- report with reporter_id set to a real admin's uuid, status 'fixed' and
-- severity 'high' was accepted, HTTP 201. A forged report therefore lands in
-- the admin queue attributed to someone who never sent it, already marked
-- resolved. The probe row was deleted.
--
-- Reporting stays open to anonymous visitors: the footer form is the main way
-- anyone tells us something is broken, and requiring an account would lose
-- most reports. What closes is claiming to be someone else, and pre-deciding
-- your own report's triage state.

drop policy if exists "anyone may file a bug report" on public.bug_reports;
create policy "anyone may file a bug report"
  on public.bug_reports for insert to anon, authenticated
  with check (
    -- Triage belongs to an admin, not to the reporter.
    status = 'new'
    and triaged_by is null
    and resolved_at is null
    -- Anonymous reports are unattributed; a signed-in reporter is themselves.
    and (reporter_id is null or reporter_id = (select auth.uid()))
    -- Bounds, so one POST cannot store a megabyte.
    and length(body) between 1 and 5000
    and length(coalesce(email, '')) <= 320
    and length(coalesce(page,  '')) <= 500
  );

-- ------------------------------------------- 3. resource links are http(s) --
--
-- resources.url is advisor-written free text with no scheme check. Nothing
-- renders it as an href today, so this is not yet exploitable -- but the day
-- one template does, `javascript:...` in that column is stored XSS against
-- every member of the club. Cheaper to make the column incapable of holding
-- one than to remember the rule in every future template.

alter table public.resources
  drop constraint if exists resources_url_scheme;
alter table public.resources
  add constraint resources_url_scheme
  check (url ~* '^(https?://|mailto:)') not valid;

-- `not valid` so the migration cannot fail on rows written before it. The
-- table is empty on production today; validate when convenient with:
--   alter table public.resources validate constraint resources_url_scheme;

-- ---------------------------------------- 4. bootstrap admin is one-time --
--
-- bootstrap_admins grants 'admin' to anyone who signs up with a listed
-- address. That is a standing rule, not a bootstrap: it stays armed forever,
-- so if one of those accounts is ever deleted, whoever can next receive mail
-- at that address becomes an administrator. Email confirmation is the only
-- thing standing in front of it. The list is also readable in the deployed
-- copy of this repo unless supabase/ is excluded from the build, which names
-- the two inboxes worth attacking.
--
-- Gated now on there being no administrator yet, which is what "bootstrap"
-- means. Both real admins already exist, so this closes the door on
-- production while a fresh local stack still gets its first admin
-- automatically.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $fn$
declare
  addr        text := lower(coalesce(new.email, ''));
  addr_domain text := split_part(addr, '@', 2);
  assigned    public.app_role := 'student';
begin
  if exists (select 1 from public.allowed_signup_domains)
     and not exists (
       select 1 from public.allowed_signup_domains d
       where lower(d.domain) = addr_domain
     )
  then
    raise exception 'Accounts are limited to school email addresses.'
      using errcode = '22023';
  end if;

  -- Only while the project has no administrator at all.
  if not exists (select 1 from public.profiles p where p.role = 'admin')
     and exists (select 1 from public.bootstrap_admins b where lower(b.email) = addr)
  then
    assigned := 'admin';
  end if;

  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    nullif(trim(coalesce(new.raw_user_meta_data ->> 'full_name', '')), ''),
    assigned
  )
  on conflict (id) do nothing;

  return new;
end;
$fn$;

-- ----------------------------------------------------- what already held --
--
-- Re-tested live, all refused. Recorded so the next audit starts here:
--   * a student PATCHing their own role to 'admin'                      403
--   * set_user_role / grant_club_advisor / decide_club_submission
--     called by a student                                               403
--   * a student inserting a memberships row naming themselves advisor   403
--   * an advisor writing scores, category, is_student_led or photos on
--     their OWN club                                            400 P0001
--     (a trigger on production enforces this; it is NOT in any migration
--     in this repo, so `supabase db reset` would silently drop it.
--     Capture it -- see the note in the pull request.)
--   * an advisor editing a club they do not advise                  0 rows
--   * anon or student SELECT on profiles, memberships, notifications,
--     saved_clubs, audit_log, bootstrap_admins, club_submissions and
--     bug_reports                                            0 rows each
--   * anon INSERT / UPDATE / DELETE on clubs and profiles               401
