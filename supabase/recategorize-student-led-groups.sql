-- Retires the "Student-Led Group" category. Every group that was bucketed
-- there moves into whichever of the real categories fits what it actually
-- does, plus a new "Sports & Recreation" category (created here) for the
-- handful of clubs -- student-led and official -- that are about a sport
-- rather than an academic/arts/culture/service focus.
--
-- A new is_student_led flag records which clubs came from that old bucket,
-- so the site can still show a small "student-organized group" tag on them
-- without needing a category to do it. Paste into the Supabase SQL editor
-- and run once.

alter table clubs add column if not exists is_student_led boolean not null default false;

-- Flag every current student-led group before their category changes below.
update clubs set is_student_led = true where category = 'Student-Led Group';

-- ---- Academic Competition ----
update clubs set category = 'Academic Competition'
where id = 'wayzata-inventors-group' and category = 'Student-Led Group';

-- ---- CTE ----
update clubs set category = 'CTE'
where id in (
  'aerospace-and-aeronautical-group',
  'human-anatomy',
  'nurses-of-tomorrow',
  'youth-in-medicine',
  'educators-rising',
  'the-bizmark-exchange',
  'wayzata-real-estate-team',
  'wayzata-investment-competition-wic',
  'wayzata-she-leads',
  'r-i-s-e-group'
) and category = 'Student-Led Group';

-- ---- Language & Culture ----
update clubs set category = 'Language & Culture'
where id in (
  'club-utsaav',
  'gsa',
  'hindu-student-association',
  'jewish-student-union',
  'latino-student-union',
  'muslim-student-association-msa',
  'wayzata-k-pop-group',
  'trojan-of-god',
  'we-have-spirit-bible-study'
) and category = 'Student-Led Group';

-- ---- Service & Leadership ----
update clubs set category = 'Service & Leadership'
where id in (
  'beads-of-serenity',
  'club-unified-students-us',
  'crafted-with-care',
  'earthrise',
  'forget-me-not-organization',
  'girls-learn-international',
  'kids-scholarship-fund',
  'knots-of-kindness',
  'letters-of-love',
  'origami-for-good',
  'our-right-to-learn',
  'wayzata-red-cross',
  'spec-student-political-engagement-center',
  'women-in-government',
  'stress-management',
  'wave-wayzata-actively-valuing-empathy'
) and category = 'Student-Led Group';

-- ---- Visual & Written Arts ----
update clubs set category = 'Visual & Written Arts'
where id in (
  'crochet-group',
  'sustainable-swag-ss',
  'trojan-tribune',
  'sports-promotional-team'
) and category = 'Student-Led Group';

-- ---- Performance Arts ----
update clubs set category = 'Performance Arts'
where id = 'the-elite-pressure-line' and category = 'Student-Led Group';

-- ---- Sports & Recreation (new category) ----
-- Cricket Group and Sports Talk Group (student-led) plus Esports and Trap &
-- Skeet Club (already official, moving out of CTE) -- none of these are
-- academic, arts, culture, or service clubs, they're just sport/rec.
update clubs set category = 'Sports & Recreation'
where id in ('cricket-group', 'sports-talk-group')
  and category = 'Student-Led Group';

update clubs set category = 'Sports & Recreation'
where id in ('esports', 'trap-and-skeet-club')
  and category = 'CTE';

-- Sanity check -- should return 0 rows once every group above has matched.
select id, name from clubs where category = 'Student-Led Group';