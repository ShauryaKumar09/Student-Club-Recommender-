-- Tables behind the dashboard panels that had no backing store.
--
-- The multi-role UI ships four panels driven by hard-coded sample data:
-- student join requests, notifications, the admin club-approval queue, and the
-- admin bug-report queue. This gives each one a real table, RLS consistent
-- with 20260821000100, and named functions for the decisions that matter.
--
-- Bug reports currently go to a Google Sheet through an Apps Script web app.
-- This table does not remove that path; it gives the admin queue something
-- real to read once the form is pointed here.
-- Generated 2026-08-22.

-- ---------------------------------------------------------------- 1. enums --

do $$ begin
  create type public.request_status as enum ('pending', 'approved', 'denied');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.bug_status as enum ('new', 'triaged', 'fixed');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.bug_severity as enum ('low', 'medium', 'high');
exception when duplicate_object then null; end $$;

-- --------------------------------------------------------------- 2. tables --

create table if not exists public.join_requests (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  club_id    text not null references public.clubs (id) on delete cascade,
  status     public.request_status not null default 'pending',
  message    text,
  decided_by uuid references public.profiles (id) on delete set null,
  decided_at timestamptz,
  created_at timestamptz not null default now()
);

-- One live request per person per club; resolved ones may pile up as history.
create unique index if not exists join_requests_one_pending_idx
  on public.join_requests (user_id, club_id)
  where status = 'pending';

create index if not exists join_requests_club_idx on public.join_requests (club_id, status);

create table if not exists public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  title      text not null,
  body       text,
  kind       text not null default 'info',
  link       text,
  read       boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists notifications_user_idx
  on public.notifications (user_id, created_at desc);

create table if not exists public.club_submissions (
  id               uuid primary key default gen_random_uuid(),
  submitted_by     uuid references public.profiles (id) on delete set null,
  name             text not null,
  category         text,
  club_type        text,
  advisor_name     text,
  advisor_email    text,
  meeting_days     text,
  meeting_time     text,
  meeting_location text,
  description      text,
  detailed_description text,
  target_audience  text,
  interests        text[] not null default '{}'::text[],
  status           public.request_status not null default 'pending',
  reviewed_by      uuid references public.profiles (id) on delete set null,
  reviewed_at      timestamptz,
  review_note      text,
  created_at       timestamptz not null default now()
);

create index if not exists club_submissions_status_idx
  on public.club_submissions (status, created_at desc);

create table if not exists public.bug_reports (
  id          uuid primary key default gen_random_uuid(),
  reporter_id uuid references public.profiles (id) on delete set null,
  email       text,
  body        text not null,
  page        text,
  severity    public.bug_severity not null default 'medium',
  status      public.bug_status not null default 'new',
  triaged_by  uuid references public.profiles (id) on delete set null,
  resolved_at timestamptz,
  created_at  timestamptz not null default now()
);

create index if not exists bug_reports_status_idx
  on public.bug_reports (status, created_at desc);

-- ------------------------------------------------------------ 3. functions --

-- Internal only: no role is granted EXECUTE, so notifications can be created
-- solely by the definer functions and triggers below. That keeps one user from
-- spamming another's notification feed.
create or replace function public.notify_user(
  target_user uuid,
  title       text,
  body        text default null,
  kind        text default 'info',
  link        text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_id uuid;
begin
  insert into public.notifications (user_id, title, body, kind, link)
  values (notify_user.target_user, notify_user.title, notify_user.body,
          notify_user.kind, notify_user.link)
  returning id into new_id;

  return new_id;
end;
$$;

-- A student asking to join a club that vets its members.
create or replace function public.request_to_join_club(
  target_club text,
  message     text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_id uuid;
begin
  if (select auth.uid()) is null then
    raise exception 'request_to_join_club requires an authenticated caller'
      using errcode = '42501';
  end if;

  if not exists (select 1 from public.clubs c where c.id = request_to_join_club.target_club) then
    raise exception 'no club with id %', request_to_join_club.target_club
      using errcode = 'P0002';
  end if;

  if exists (
    select 1 from public.memberships m
    where m.user_id = (select auth.uid()) and m.club_id = request_to_join_club.target_club
  ) then
    raise exception 'already a member of %', request_to_join_club.target_club
      using errcode = 'P0001';
  end if;

  insert into public.join_requests (user_id, club_id, message)
  values ((select auth.uid()), request_to_join_club.target_club, request_to_join_club.message)
  returning id into new_id;

  return new_id;
end;
$$;

-- Approve or deny. Approving creates the membership; either way the student
-- gets a notification, so the decision is never silent.
create or replace function public.decide_join_request(
  request_id uuid,
  approve    boolean
)
returns public.request_status
language plpgsql
security definer
set search_path = ''
as $$
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

  if not public.is_club_advisor(req.club_id) then
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
$$;

-- Admin decision on a proposed club. Approving creates the real clubs row,
-- deriving the slug id the rest of the app expects.
create or replace function public.decide_club_submission(
  submission_id uuid,
  approve       boolean,
  note          text default null
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  sub     public.club_submissions;
  new_id  text;
begin
  if public.auth_role() is distinct from 'admin' then
    raise exception 'only an admin may decide club submissions'
      using errcode = '42501';
  end if;

  select * into sub from public.club_submissions s where s.id = decide_club_submission.submission_id;

  if not found then
    raise exception 'no submission %', decide_club_submission.submission_id
      using errcode = 'P0002';
  end if;

  if sub.status <> 'pending' then
    raise exception 'submission % is already %', decide_club_submission.submission_id, sub.status
      using errcode = 'P0001';
  end if;

  update public.club_submissions
     set status = (case when decide_club_submission.approve
                        then 'approved' else 'denied' end)::public.request_status,
         reviewed_by = (select auth.uid()),
         reviewed_at = now(),
         review_note = decide_club_submission.note
   where id = decide_club_submission.submission_id;

  if decide_club_submission.approve then
    -- Slug in the same shape as the existing ids: lowercase, non-alphanumerics
    -- collapsed to single hyphens, trimmed.
    new_id := trim(both '-' from regexp_replace(lower(sub.name), '[^a-z0-9]+', '-', 'g'));

    insert into public.clubs (
      id, name, category, advisor, description, target_audience,
      detailed_description, meeting_location, meeting_days, meeting_time,
      is_student_led, interests, email
    ) values (
      new_id, sub.name, sub.category, sub.advisor_name, sub.description,
      sub.target_audience, sub.detailed_description, sub.meeting_location,
      sub.meeting_days, sub.meeting_time,
      coalesce(sub.club_type, '') = 'Student Organized Group',
      sub.interests, sub.advisor_email
    )
    on conflict (id) do nothing;

    if sub.submitted_by is not null then
      perform public.notify_user(
        sub.submitted_by,
        sub.name || ' was approved',
        'Your club is now listed in the directory.',
        'success',
        '/club/' || new_id
      );
    end if;
  elsif sub.submitted_by is not null then
    perform public.notify_user(
      sub.submitted_by,
      'Update on ' || sub.name,
      coalesce(decide_club_submission.note, 'Your submission was not approved.'),
      'info',
      null
    );
  end if;

  return new_id;
end;
$$;

-- Marking one's own notification read. Kept as a function so the `read` flag
-- is the only field a user can ever move.
create or replace function public.mark_notification_read(notification_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.notifications
     set read = true
   where id = mark_notification_read.notification_id
     and user_id = (select auth.uid());
end;
$$;

-- --------------------------------------------------------------- 4. grants --

grant select, insert         on public.join_requests    to authenticated;
grant select, update, delete on public.join_requests    to authenticated;
grant select                 on public.notifications    to authenticated;
grant select, insert         on public.club_submissions to authenticated;
grant update                 on public.club_submissions to authenticated;
grant select, insert         on public.bug_reports      to authenticated;
grant update                 on public.bug_reports      to authenticated;

-- The bug form on the public site is usable without an account, matching how
-- the existing Apps Script endpoint behaves. Insert only -- anon can never
-- read the queue back.
grant insert on public.bug_reports to anon;

revoke all on function public.notify_user(uuid, text, text, text, text) from public;

revoke all on function public.request_to_join_club(text, text)            from public;
revoke all on function public.decide_join_request(uuid, boolean)          from public;
revoke all on function public.decide_club_submission(uuid, boolean, text) from public;
revoke all on function public.mark_notification_read(uuid)                from public;

grant execute on function public.request_to_join_club(text, text)            to authenticated;
grant execute on function public.decide_join_request(uuid, boolean)          to authenticated;
grant execute on function public.decide_club_submission(uuid, boolean, text) to authenticated;
grant execute on function public.mark_notification_read(uuid)                to authenticated;

-- ------------------------------------------------------------------ 5. RLS --

alter table public.join_requests    enable row level security;
alter table public.notifications    enable row level security;
alter table public.club_submissions enable row level security;
alter table public.bug_reports      enable row level security;

-- join_requests ---------------------------------------------------------

drop policy if exists "users read their own join requests" on public.join_requests;
create policy "users read their own join requests"
  on public.join_requests for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists "advisors read requests for their club" on public.join_requests;
create policy "advisors read requests for their club"
  on public.join_requests for select to authenticated
  using (public.is_club_advisor(club_id));

-- Self-service, and only ever for yourself, only ever pending.
drop policy if exists "users create their own join requests" on public.join_requests;
create policy "users create their own join requests"
  on public.join_requests for insert to authenticated
  with check (user_id = (select auth.uid()) and status = 'pending');

-- Withdrawing a request you made.
drop policy if exists "users withdraw their own pending requests" on public.join_requests;
create policy "users withdraw their own pending requests"
  on public.join_requests for delete to authenticated
  using (user_id = (select auth.uid()) and status = 'pending');

drop policy if exists "advisors decide requests for their club" on public.join_requests;
create policy "advisors decide requests for their club"
  on public.join_requests for update to authenticated
  using (public.is_club_advisor(club_id))
  with check (public.is_club_advisor(club_id));

-- notifications ---------------------------------------------------------
-- Read-only to their owner. Creation is exclusively notify_user().

drop policy if exists "users read their own notifications" on public.notifications;
create policy "users read their own notifications"
  on public.notifications for select to authenticated
  using (user_id = (select auth.uid()));

-- club_submissions ------------------------------------------------------

drop policy if exists "submitters read their own submissions" on public.club_submissions;
create policy "submitters read their own submissions"
  on public.club_submissions for select to authenticated
  using (submitted_by = (select auth.uid()));

drop policy if exists "admins read all submissions" on public.club_submissions;
create policy "admins read all submissions"
  on public.club_submissions for select to authenticated
  using (public.auth_role() = 'admin');

drop policy if exists "anyone signed in may propose a club" on public.club_submissions;
create policy "anyone signed in may propose a club"
  on public.club_submissions for insert to authenticated
  with check (submitted_by = (select auth.uid()) and status = 'pending');

drop policy if exists "admins update submissions" on public.club_submissions;
create policy "admins update submissions"
  on public.club_submissions for update to authenticated
  using (public.auth_role() = 'admin')
  with check (public.auth_role() = 'admin');

-- bug_reports -----------------------------------------------------------

drop policy if exists "reporters read their own bug reports" on public.bug_reports;
create policy "reporters read their own bug reports"
  on public.bug_reports for select to authenticated
  using (reporter_id = (select auth.uid()));

drop policy if exists "admins read all bug reports" on public.bug_reports;
create policy "admins read all bug reports"
  on public.bug_reports for select to authenticated
  using (public.auth_role() = 'admin');

drop policy if exists "anyone may file a bug report" on public.bug_reports;
create policy "anyone may file a bug report"
  on public.bug_reports for insert to anon, authenticated
  with check (true);

drop policy if exists "admins triage bug reports" on public.bug_reports;
create policy "admins triage bug reports"
  on public.bug_reports for update to authenticated
  using (public.auth_role() = 'admin')
  with check (public.auth_role() = 'admin');
