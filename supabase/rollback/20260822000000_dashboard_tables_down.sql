-- Reverses supabase/migrations/20260822000000_dashboard_tables.sql.
--
-- Run BEFORE the 20260821000200 and 20260821000100 rollbacks: the functions
-- here call is_club_advisor() and auth_role(), and the tables reference
-- profiles and clubs.
-- Generated 2026-08-22.

begin;

drop function if exists public.decide_club_submission(uuid, boolean, text);
drop function if exists public.decide_join_request(uuid, boolean);
drop function if exists public.request_to_join_club(text, text);
drop function if exists public.mark_notification_read(uuid);
drop function if exists public.notify_user(uuid, text, text, text, text);

drop table if exists public.bug_reports;
drop table if exists public.club_submissions;
drop table if exists public.notifications;
drop table if exists public.join_requests;

drop type if exists public.bug_severity;
drop type if exists public.bug_status;
drop type if exists public.request_status;

commit;
