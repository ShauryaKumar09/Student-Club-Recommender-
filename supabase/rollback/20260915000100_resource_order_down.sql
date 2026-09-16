-- Reverses 20260915000100_resource_order.sql.
-- Ordering falls back to created_at, which is where it was.
drop index if exists public.resources_club_position_idx;
alter table public.resources drop column if exists position;
