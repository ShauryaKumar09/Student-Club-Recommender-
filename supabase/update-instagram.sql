-- Instagram handles for the clubs that have one.
-- Run in the Supabase SQL editor (writes are blocked for the anon key by RLS).
--
-- Handles are stored WITHOUT the leading '@'; the frontend adds it for display
-- and uses the bare handle to build the instagram.com link.
--
-- Clubs not listed here have no Instagram account. Their handle is set to NULL
-- and the frontend hides the Instagram row entirely for them, rather than
-- showing a "Not added yet" placeholder.

-- Clear everything first, so a club that loses its account is not left with a
-- stale handle on a re-run.
update public.clubs set instagram = null;

update public.clubs set instagram = case id
  when 'science-bowl'                      then 'wayzatasb'
  when 'science-olympiad'                  then 'wayzataso'
  when 'quiz-bowl'                         then 'wayzataquizbowl'
  when 'speech'                            then 'wayzataspeech'
  when 'business-professionals-of-america' then 'wayzatabpa'
  when 'deca'                              then 'wayzatadeca'
  when 'hosa-future-health-professionals'  then 'wayzatahosa'
  when 'robotics'                          then 'wayzatarobotics'
  when 'student-council'                   then 'wayzatastuco'
  when 'volunteer-club'                    then 'whsvolunteerclub'
  when 'drama-club-and-theatre'            then 'whs.theatre'
  when 'trojan-tribune-journalism-club'    then 'trojantribune'
  when 'wayako-yearbook'                   then 'wayzatayearbook'
end
where id in (
  'science-bowl',
  'science-olympiad',
  'quiz-bowl',
  'speech',
  'business-professionals-of-america',
  'deca',
  'hosa-future-health-professionals',
  'robotics',
  'student-council',
  'volunteer-club',
  'drama-club-and-theatre',
  'trojan-tribune-journalism-club',
  'wayako-yearbook'
);

-- Expect 13 rows with a handle, 25 without.
select
  count(*) filter (where instagram is not null) as with_handle,
  count(*) filter (where instagram is null)     as without_handle
from public.clubs;
