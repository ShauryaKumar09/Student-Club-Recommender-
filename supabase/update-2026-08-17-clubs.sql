-- 2026-08-17 club roster pass: two renames, two removals, two new groups.
--
-- Run in the Supabase SQL editor -- writes are blocked for the anon key by RLS.
-- Wrapped in a transaction and written to be re-runnable (updates are
-- idempotent, deletes are no-ops once the rows are gone, the insert uses
-- ON CONFLICT DO NOTHING). Generated from uploads/clubs.json, which stays the
-- source of truth.
--
-- Column types differ between the two array-ish columns, so the casts are not
-- interchangeable: `interests` is text[] (write ARRAY[...]::text[]) while
-- `scores` is jsonb (write '{...}'::jsonb).
--
-- Renames keep the existing `id` values (`club-utsaav`, `gsa`). The ids are
-- referenced by the club-photos storage filenames, so renaming the display name
-- must not renumber them.
--
-- Removals:
--   * Sports Talk Group -- the group decided not to run this year.
--   * Wayako Yearbook -- yearbook is a class, not a club; you have to be
--     enrolled to be on staff, so it does not belong in the directory.
--
-- The Pediatric Cancer Awareness sponsor was submitted as "Miriuam Lejonvarn"
-- and is stored as "Miriam Lejonvarn"; confirm the spelling with the sponsor.
--
-- Student leader names are collected but deliberately not stored (no column,
-- and they go stale yearly) -- Munee Song and Phoebe Zheng for UNICEF, Rachel
-- Frank and Jack Reither for PCA. Where a group gave two contacts, the first
-- student's school address is stored. No phone numbers are stored at all -- see
-- update-form-submissions-2.sql.
--
-- `photos` is deliberately left out of the insert column list: neither new
-- group has photos yet, and the app guards on Array.isArray(club.photos), so
-- the column default is fine.
-- Generated 2026-08-17.

begin;

-- 1. Renames: spell out what each group actually is, so the browse list and
--    search hit "South Asian" and "Gay Straight Alliance" directly.
update clubs set name = 'Utsaav: South Asian Student Group' where id = 'club-utsaav';
update clubs set name = 'GSA: Gay Straight Alliance'        where id = 'gsa';

-- 2. Removals.
delete from clubs where id in ('sports-talk-group', 'wayako-yearbook');

-- 3. New groups.
insert into clubs (
  id, name, category, advisor, description,
  target_audience, detailed_description,
  meeting_location, meeting_days, meeting_time, is_student_led,
  interests, scores, instagram, email, phone
) values
  ('pediatric-cancer-awareness', 'Pediatric Cancer Awareness (PCA)', 'Service & Leadership', 'Miriam Lejonvarn', 'Helping children with cancer and their families.', 'Students interested in supporting children with cancer and their families.', 'Pediatric Cancer Awareness (PCA) works to help children with cancer and their families, raising awareness of pediatric cancer alongside its service work.', 'C122', 'Second Tuesday of each month', 'Before school, 7:40-8:10 a.m.', true, ARRAY['Supporting children with cancer', 'Supporting families', 'Pediatric cancer awareness', 'Community service', 'Health and medicine']::text[], '{"science_stem": 0, "arts_creative": 0, "health_medical": 3, "competitiveness": 0, "time_commitment": 1, "world_languages": 0, "trades_technical": 0, "community_service": 5, "cultural_identity": 0, "sports_recreation": 0, "team_vs_individual": 3, "academic_competition": 0, "computer_science_tech": 0, "leadership_government": 0, "leadership_opportunity": 2, "social_special_interest": 1, "public_speaking_emphasis": 1, "writing_media_journalism": 0, "business_entrepreneurship": 0, "environmental_sustainability": 0}'::jsonb, null, 'frankrac000@isd284.com', null),
  ('wayzata-unicef', 'Wayzata UNICEF', 'Service & Leadership', 'Timothy Masters', 'The purpose is to educate, advocate, and fundraise to support UNICEF''s global mission of protecting children''s rights.', 'Students interested in children''s rights, global issues, and fundraising.', 'Wayzata UNICEF educates, advocates, and fundraises in support of UNICEF''s global mission of protecting children''s rights.', 'C409', 'Third Wednesday of the month', 'After school, 3:10-4:10 p.m.', true, ARRAY['Children''s rights', 'Global issues', 'Advocacy', 'Fundraising', 'Community service']::text[], '{"science_stem": 0, "arts_creative": 0, "health_medical": 1, "competitiveness": 0, "time_commitment": 1, "world_languages": 0, "trades_technical": 0, "community_service": 5, "cultural_identity": 0, "sports_recreation": 0, "team_vs_individual": 3, "academic_competition": 0, "computer_science_tech": 0, "leadership_government": 3, "leadership_opportunity": 2, "social_special_interest": 1, "public_speaking_emphasis": 2, "writing_media_journalism": 0, "business_entrepreneurship": 0, "environmental_sustainability": 0}'::jsonb, null, 'songmun000@isd284.com', null)
on conflict (id) do nothing;

commit;

-- Verify: 87 before, minus 2 removed, plus 2 added = 87, matching
-- uploads/clubs.json.
select count(*) as total_clubs from clubs;
select id, name, category, advisor from clubs
where id in (
  'club-utsaav', 'gsa', 'pediatric-cancer-awareness', 'wayzata-unicef'
) order by id;
-- Expect zero rows:
select id, name from clubs where id in ('sports-talk-group', 'wayako-yearbook');
