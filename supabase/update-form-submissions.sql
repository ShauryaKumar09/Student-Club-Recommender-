-- Reconciles the club-info Google Form export ("TrojanMatch Club information
-- Collection.csv", responses collected 2026-08-06/07) against what's live.
-- Most of the form had already been folded into the site; this migration is
-- just the gap: missing Instagram handles, two explicitly-requested contact
-- emails, one advisor-requested clarification, three fields where the form
-- disagreed with what was live (resolved per site owner's call), and two
-- brand new groups the form introduced that weren't on the site at all.
-- Paste into the Supabase SQL editor and run once.

-- ---- Missing Instagram handles (form gave one, site had none) ----
update clubs set instagram = 'wayzatautsaav' where id = 'club-utsaav' and instagram is null;
update clubs set instagram = 'spec.wayzata' where id = 'spec-student-political-engagement-center' and instagram is null;
update clubs set instagram = 'wayzatainventors88' where id = 'wayzata-inventors-group' and instagram is null;
update clubs set instagram = 'forgetmenot.global' where id = 'forget-me-not-organization' and instagram is null;
update clubs set instagram = 'wayzata_wic' where id = 'wayzata-investment-competition-wic' and instagram is null;
update clubs set instagram = 'cryamerica.minnesota' where id = 'our-right-to-learn' and instagram is null;
update clubs set instagram = 'thebizmarkexchange' where id = 'the-bizmark-exchange' and instagram is null;
update clubs set instagram = 'wayzatawave' where id = 'wave-wayzata-actively-valuing-empathy' and instagram is null;
update clubs set instagram = 'wayzataaerospaceandnauticgroup' where id = 'aerospace-and-aeronautical-group' and instagram is null;
update clubs set instagram = 'wayzatasclubunified' where id = 'club-unified-students' and instagram is null;

-- ---- Explicitly-requested contact emails ----
-- Mock Trial's advisor: "you can put my email down for contact info on the group."
update clubs set email = 'Tyler.Trimberger@wayzataschools.org' where id = 'mock-trial' and email is null;
-- Quiz Bowl gave a dedicated club contact address in the form's "Other" field.
update clubs set email = 'wayzataquizbowl@gmail.com' where id = 'quiz-bowl' and email is null;

-- ---- Advisor-requested clarification ----
-- "I get a lot of middle school parents emailing me" -- Science Bowl advisor
-- asked that the listing make clear this is the high school team.
update clubs set
  description = 'Fast-paced, buzzer-based Q&A quiz competition (DOE-sponsored) across physical science, math, biology, earth science. This is the Wayzata High School team.',
  detailed_description = 'Science Bowl is a DOE-sponsored, buzzer-based quiz competition testing quick recall across physical science, math, biology, and earth science. It''s a fast-paced format that rewards breadth of knowledge and speed. This listing is for the Wayzata High School team specifically.'
where id = 'science-bowl';

-- ---- Real conflicts between the form and what was live (resolved per site owner) ----
-- Aerospace and Aeronautical Group: form says room C406, site said C403.
update clubs set
  meeting_location = 'C406',
  meeting_time = 'After school, 3:30-4:30 p.m.'
where id = 'aerospace-and-aeronautical-group';

-- Wayzata Inventors Group: no room conflict, but the site only had the
-- generic placeholder time -- the form gives the group's real meeting time.
update clubs set meeting_time = 'After school, 3:30-5:00 p.m.'
where id = 'wayzata-inventors-group';

-- Women In Government: form says "every other week on Mondays", site said
-- "Once a week Thursday".
update clubs set meeting_days = 'Every other Monday'
where id = 'women-in-government';

-- WAVE: replacing the clinical paraphrase with the group's own submitted
-- voice.
update clubs set
  description = 'WAVE is a student-led group that offers a safe space to destress. Bring your friends and enjoy hands-on activities like making slime, lotion, hand-sanitizer, and lip balm. There''s zero commitment, it''s always free, and snacks are included!',
  detailed_description = 'WAVE (Wayzata Actively Valuing Empathy) is a student-led group that offers a safe space to destress. Bring your friends and enjoy hands-on activities like making slime, lotion, hand-sanitizer, lip balm, and other art projects. There''s zero commitment, everyone is always welcome, and it''s always free -- snacks included.'
where id = 'wave-wayzata-actively-valuing-empathy';

-- ---- Enrichment (additive, no conflict) ----
-- Club Unified Students: form gives specific activities the current
-- one-line description didn't mention.
update clubs set detailed_description = 'Club Unified Students works to bridge the gap between students with and without disabilities, building meaningful relationships and making sure everyone feels included at Wayzata. The club runs activities like bowling outings, cornhole tournaments, arts-and-crafts events, the Polar Plunge at Lake Nokomis, SOMN Student Engagement Events, and apple-orchard trips -- planned and led by the student members themselves.'
where id = 'club-unified-students';

-- ---- Brand new groups introduced by this form ----
alter table clubs add column if not exists is_student_led boolean not null default false;

insert into clubs (id, name, category, advisor, email, phone, description, detailed_description, target_audience, meeting_location, meeting_days, meeting_time, instagram, interests, scores, is_student_led)
values (
  'paws-for-a-cause',
  'Paws for a Cause',
  'Service & Leadership',
  'Anne Hooton',
  null, null,
  'Paws for a Cause is a student group that helps animals in need by making collars, tie-blankets, and chew toys for dogs in shelters.',
  'Paws for a Cause is a motivated student group focused on helping animals in need. The club provides meaningful donations, care, and support to rescue dogs in animal shelters -- members create collars, tie-blankets, and chew toys that are donated to partner shelters, including Warrior Dog Rescue in Savage, MN, until the dogs find their forever homes.',
  'Students who want to help animals in shelters through hands-on craft projects.',
  'C420', 'Every other Monday or Wednesday', 'Before school, 7:40-8:10 a.m.',
  'whspawsforcause',
  array['Animal welfare', 'Dog rescue', 'Hands-on crafting', 'Community service', 'Low-commitment volunteering']::text[],
  '{"business_entrepreneurship": 0, "computer_science_tech": 0, "science_stem": 0, "arts_creative": 3, "community_service": 5, "cultural_identity": 0, "academic_competition": 0, "health_medical": 0, "writing_media_journalism": 0, "environmental_sustainability": 0, "leadership_government": 0, "social_special_interest": 2, "world_languages": 0, "sports_recreation": 0, "trades_technical": 0, "competitiveness": 0, "time_commitment": 1, "team_vs_individual": 3, "public_speaking_emphasis": 0, "leadership_opportunity": 1}'::jsonb,
  true
);

insert into clubs (id, name, category, advisor, email, phone, description, detailed_description, target_audience, meeting_location, meeting_days, meeting_time, instagram, interests, scores, is_student_led)
values (
  'aha-american-heart-association',
  'AHA: American Heart Association',
  'CTE',
  'Clarice Jorenby',
  null, null,
  'AHA teaches students life-saving skills like CPR and works to raise awareness for better heart health within the school community.',
  'American Heart Association (AHA) is a student club focused on teaching practical life-saving skills, including CPR, and raising awareness of heart health within the Wayzata community.',
  'Students interested in health, CPR training, and community health education.',
  'A205', 'First Wednesday of the month', null,
  'wayzata_americanheart',
  array['CPR & life-saving skills', 'Heart health awareness', 'Interested in medicine and healthcare careers', 'Community health education']::text[],
  '{"business_entrepreneurship": 0, "computer_science_tech": 0, "science_stem": 1, "arts_creative": 0, "community_service": 3, "cultural_identity": 0, "academic_competition": 0, "health_medical": 5, "writing_media_journalism": 0, "environmental_sustainability": 0, "leadership_government": 1, "social_special_interest": 1, "world_languages": 0, "sports_recreation": 0, "trades_technical": 0, "competitiveness": 0, "time_commitment": 2, "team_vs_individual": 3, "public_speaking_emphasis": 1, "leadership_opportunity": 2}'::jsonb,
  true
);