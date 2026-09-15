-- Reverses 20260915000000_club_officers.sql.
--
-- Puts every policy and function back to is_club_advisor(), so an officer is
-- once again a label on a roster row with no powers. Taken verbatim from the
-- migrations that first defined them.


drop policy if exists "club advisors update their club" on public.clubs;
create policy "club advisors update their club"
  on public.clubs for update to authenticated
  using (public.is_club_advisor(id))
  with check (public.is_club_advisor(id));

drop policy if exists "admins insert clubs" on public.clubs;
create policy "admins insert clubs"
  on public.clubs for insert to authenticated
  with check (public.auth_role() = 'admin');

drop policy if exists "admins delete clubs" on public.clubs;
create policy "admins delete clubs"
  on public.clubs for delete to authenticated
  using (public.auth_role() = 'admin');

drop policy if exists "advisors read their club roster" on public.memberships;
create policy "advisors read their club roster"
  on public.memberships for select to authenticated
  using (public.is_club_advisor(club_id));

drop policy if exists "advisors write announcements" on public.announcements;
create policy "advisors write announcements"
  on public.announcements for insert to authenticated
  with check (public.is_club_advisor(club_id));

drop policy if exists "advisors edit announcements" on public.announcements;
create policy "advisors edit announcements"
  on public.announcements for update to authenticated
  using (public.is_club_advisor(club_id))
  with check (public.is_club_advisor(club_id));

drop policy if exists "advisors delete announcements" on public.announcements;
create policy "advisors delete announcements"
  on public.announcements for delete to authenticated
  using (public.is_club_advisor(club_id));

drop policy if exists "advisors write events" on public.events;
create policy "advisors write events"
  on public.events for insert to authenticated
  with check (public.is_club_advisor(club_id));

drop policy if exists "advisors edit events" on public.events;
create policy "advisors edit events"
  on public.events for update to authenticated
  using (public.is_club_advisor(club_id))
  with check (public.is_club_advisor(club_id));

drop policy if exists "advisors delete events" on public.events;
create policy "advisors delete events"
  on public.events for delete to authenticated
  using (public.is_club_advisor(club_id));

drop policy if exists "advisors write resources" on public.resources;
create policy "advisors write resources"
  on public.resources for insert to authenticated
  with check (public.is_club_advisor(club_id));

drop policy if exists "advisors edit resources" on public.resources;
create policy "advisors edit resources"
  on public.resources for update to authenticated
  using (public.is_club_advisor(club_id))
  with check (public.is_club_advisor(club_id));

drop policy if exists "advisors delete resources" on public.resources;
create policy "advisors delete resources"
  on public.resources for delete to authenticated
  using (public.is_club_advisor(club_id));

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

revoke all on function public.decide_join_request(uuid, boolean) from public;
grant execute on function public.decide_join_request(uuid, boolean) to authenticated;

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


drop function if exists public.set_club_role(uuid, text, public.club_role);
drop function if exists public.can_manage_club(text);
