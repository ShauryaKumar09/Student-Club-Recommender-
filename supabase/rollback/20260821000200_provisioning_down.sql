-- Reverses supabase/migrations/20260821000200_provisioning.sql.
--
-- Run this BEFORE 20260821000100_auth_roles_down.sql -- the triggers here sit
-- on profiles and memberships, and the provisioning functions call
-- auth_role() and is_club_advisor(), all of which that script drops.
-- Generated 2026-08-21.

begin;

drop trigger  if exists on_profile_role_changed on public.profiles;
drop trigger  if exists on_membership_changed   on public.memberships;

drop function if exists public.audit_profile_role_change();
drop function if exists public.audit_membership_change();

drop function if exists public.set_user_role(uuid, public.app_role);
drop function if exists public.grant_club_advisor(uuid, text);
drop function if exists public.revoke_club_advisor(uuid, text);
drop function if exists public.join_club(text);
drop function if exists public.leave_club(text);

commit;
