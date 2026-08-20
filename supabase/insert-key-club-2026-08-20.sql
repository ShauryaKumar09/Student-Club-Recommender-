-- Adds Key Club, which was not yet on the site (checked uploads/clubs.json
-- and grepped for "key club" -- no match, 87 clubs before this addition).
--
-- Run in the Supabase SQL editor -- writes are blocked for the anon key by RLS.
-- Step 1 is a manual existence check: if it returns any rows, stop and
-- reconcile before inserting. Step 2 is INSERT-only with ON CONFLICT DO
-- NOTHING as a safety net, so it's safe to re-run.
--
-- Meeting location/days/time and phone were not provided, so they're left
-- null -- fill in once known. Advisor name is inferred from the email
-- (melissa.bast@wayzataschools.org -> "Melissa Bast"); confirm the spelling.
-- Interests and scores are inferred from the description (leadership +
-- community service) and should be reviewed.
-- Generated 2026-08-20.

-- 1. Existence check -- run this first. Expect zero rows.
select id, name from clubs where id = 'key-club' or name ilike 'key club';

-- 2. Insert (only run once step 1 confirms no existing row).
begin;

insert into clubs (
  id, name, category, advisor, description,
  target_audience, detailed_description,
  meeting_location, meeting_days, meeting_time, is_student_led,
  interests, scores, instagram, email, phone
) values (
  'key-club',
  'Key Club',
  'Service & Leadership',
  'Melissa Bast',
  'Student led organization exemplifying leadership and service to our community (school and beyond) by providing students with accessible volunteering opportunities while supporting our local community (service projects include: DIYs, fundraising, volunteering).',
  'Students interested in leadership and community service.',
  'Key Club is a student-led organization exemplifying leadership and service to the community, both at school and beyond, by providing students with accessible volunteering opportunities while supporting the local community through service projects such as DIYs, fundraising, and volunteering.',
  null,
  null,
  null,
  true,
  ARRAY['Leadership', 'Community service', 'Volunteering', 'DIY projects', 'Fundraising']::text[],
  '{"science_stem": 0, "arts_creative": 0, "health_medical": 0, "competitiveness": 0, "time_commitment": 2, "world_languages": 0, "trades_technical": 0, "community_service": 5, "cultural_identity": 0, "sports_recreation": 0, "team_vs_individual": 3, "academic_competition": 0, "computer_science_tech": 0, "leadership_government": 2, "leadership_opportunity": 4, "social_special_interest": 1, "public_speaking_emphasis": 1, "writing_media_journalism": 0, "business_entrepreneurship": 0, "environmental_sustainability": 0}'::jsonb,
  'WayzataStudentsInService',
  'WayzataTrojanKeyClub@gmail.com',
  null
)
on conflict (id) do nothing;

commit;

-- Verify: expect 87 existing + 1 new = 88 total.
select count(*) as total_clubs from clubs;
select id, name, category, advisor from clubs where id = 'key-club';
