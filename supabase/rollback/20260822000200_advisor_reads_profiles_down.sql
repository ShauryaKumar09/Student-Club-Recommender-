-- Reverses supabase/migrations/20260822000200_advisor_reads_profiles.sql.
-- Generated 2026-08-22.

begin;
drop policy   if exists "advisors read profiles in their clubs" on public.profiles;
drop function if exists public.can_see_profile(uuid);
commit;
