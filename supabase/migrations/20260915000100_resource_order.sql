-- Let an advisor put their resources in a deliberate order.
--
-- resources came back ordered by created_at, so the list was "newest first"
-- and nothing could change it. A club whose handbook matters most had no way
-- to put the handbook first.
--
-- A plain integer, lowest first, created_at breaking ties. New rows get a
-- position past the end of that club's list rather than 0, so adding
-- something does not silently jump it to the top.
--
-- Reversal: supabase/rollback/20260915000100_resource_order_down.sql
-- Generated 2026-09-15.

alter table public.resources
  add column if not exists position integer not null default 0;

create index if not exists resources_club_position_idx
  on public.resources (club_id, position, created_at);

-- Existing rows all sit at 0, which would order them arbitrarily. Number them
-- by the order they already appeared in, so nothing visibly moves the first
-- time this runs.
with ordered as (
  select id, row_number() over (partition by club_id order by created_at) - 1 as n
  from public.resources
)
update public.resources r
   set position = ordered.n
  from ordered
 where r.id = ordered.id
   and r.position = 0;

-- No policy changes: position is an ordinary column on a table whose update
-- policy already asks can_manage_club(), so whoever may edit a resource may
-- reorder it, and nobody else may.
