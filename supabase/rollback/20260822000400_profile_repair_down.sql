-- Reverses 20260822000400_profile_repair.sql.
--
-- The backfilled profile rows are deliberately left in place: deleting them
-- would cascade into memberships and saved_clubs and lose real data. Only the
-- function is dropped.
drop function if exists public.ensure_profile();
