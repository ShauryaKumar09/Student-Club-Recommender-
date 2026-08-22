-- Reverses supabase/migrations/20260822000100_saved_clubs.sql.
-- Run before the 20260821000100 rollback, which drops profiles.
-- Generated 2026-08-22.

begin;
drop table if exists public.saved_clubs;
commit;
