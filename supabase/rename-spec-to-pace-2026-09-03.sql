-- 2026-09-03: SPEC rebrands to PACE.
--
-- Run in the Supabase SQL editor -- writes are blocked for the anon key by RLS.
-- Requested by Ameya Choudhary (advisor Jonathon Zetzman) via email: the group
-- kept its description, advisor, student contact, and room, and only changed
-- its name from SPEC (Student Political Engagement Center) to PACE (Political
-- Activism Center for Education). The description/detailed_description prose
-- referred to the group by its old acronym ("SPEC Wayzata fosters...",
-- "Joining SPEC allows..."), so those are updated to say PACE too, for
-- consistency with the new name.
--
-- Keeps the existing `id` (spec-student-political-engagement-center) --
-- club-photos storage filenames and any saved/join records key off of it.

begin;

update clubs
set
  name = 'PACE: Political Activism Center for Education',
  description = 'PACE Wayzata fosters civic engagement through education and structured discussion. Joining PACE allows students to get access to information about political engagement opportunities, a national network of like-minded peers, leadership opportunities on a national scale, and similar activities to encourage civic involvement.',
  detailed_description = 'PACE Wayzata fosters civic engagement through education and structured discussion. Joining PACE allows students to get access to information about political engagement opportunities, a national network of like-minded peers, leadership opportunities on a national scale, and similar activities to encourage civic involvement.'
where id = 'spec-student-political-engagement-center';

commit;

-- Verify:
select id, name, description, detailed_description from clubs
where id = 'spec-student-political-engagement-center';
