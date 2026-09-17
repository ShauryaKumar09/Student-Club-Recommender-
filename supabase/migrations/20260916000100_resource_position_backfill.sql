-- Give existing resources distinct positions
--
-- 20260915000100 added resources.position with `default 0`, which is right for
-- the column but leaves every row that already existed tied at 0. The reorder
-- arrows swapped two rows' stored positions, so with everything on 0 they
-- swapped 0 for 0 and the list never moved. The frontend renumbers a section
-- on each move now; this numbers what is already there so the first click has
-- something sane to work from.
--
-- Ordering within a club follows what the list already showed: creation date.

with ordered as (
  select id,
         row_number() over (
           partition by club_id
           order by created_at, id
         ) - 1 as pos
    from public.resources
)
update public.resources r
   set position = ordered.pos
  from ordered
 where r.id = ordered.id
   and r.position is distinct from ordered.pos
   -- Only touch clubs where nobody has ordered anything yet; a club whose
   -- rows already carry distinct positions has been arranged by hand.
   and r.club_id in (
     select club_id
       from public.resources
      group by club_id
     having count(distinct position) <= 1
   );
