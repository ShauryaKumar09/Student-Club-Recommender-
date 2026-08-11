-- Reconciles the third batch of club-info Google Form responses
-- ("TrojanMatch Club information Collection 2.csv", submissions dated
-- 2026-08-11) against what's live.
--
-- Responses through 8/10 were already applied in update-form-submissions.sql
-- and update-form-submissions-2.sql. Of the five submissions dated 8/11,
-- Crafted With Care matched what was already live with nothing new to add;
-- this migration is the other three, which were missing an advisor, contact
-- email, or meeting time entirely. Paste into the Supabase SQL editor and run
-- once.

-- ---- DECA ----
-- Form named two advisors ("Paul Kimbler & Michelle Jacklitch"); only Paul was
-- stored. Club email and both advisor emails were missing entirely. Meeting
-- cadence has no fixed room/day (two dates a month, checked via Google
-- Calendar), so -- matching how Business Professionals of America's
-- informational meeting was handled in update-form-submissions-2.sql -- it's
-- folded into detailed_description rather than the meeting_* columns.
update clubs set
  advisor = 'Michelle Jacklitch, Paul Kimbler',
  detailed_description = 'DECA prepares students for careers in marketing, finance, hospitality, and entrepreneurship through role-play case-study competitions and business plan events. It overlaps with BPA but leans more toward marketing and entrepreneurship than office/IT skills. Wayzata DECA holds monthly meetings in the forum rooms, with both a morning and an evening session each month -- check the chapter''s Google Calendar for specific dates.',
  email = 'wayzata.deca@gmail.com, paul.kimbler@wayzataschools.org, michelle.jacklitch@wayzataschools.org'
where id = 'deca';

-- ---- Wayzata Red Cross ----
-- Form gave the advisor's full name, plus the VP's school email and the
-- advisor's email, neither of which was stored (site only had a personal
-- gmail for the president). Meeting info already matched what was live.
update clubs set
  advisor = 'Jennifer Reynolds',
  email = 'lpelkola20@icloud.com, kodthaar000@isd284.com, jennifer.reynolds@wayzataschools.org'
where id = 'wayzata-red-cross';

-- ---- Creative Writing Club / The Voice Literary Magazine ----
-- Two submissions (Creative Writing Club and WHS Literary Magazine) share this
-- one row on the site and gave identical meeting info and club email, neither
-- of which was stored yet.
update clubs set
  meeting_location = 'C221',
  meeting_days = 'Every Thursday',
  meeting_time = '3:20-4:20 p.m.',
  email = 'cwc.whs@gmail.com, colleen.regnier@wayzataschools.org'
where id = 'creative-writing-club';
