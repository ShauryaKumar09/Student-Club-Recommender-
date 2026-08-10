-- Reconciles the second batch of club-info Google Form responses
-- ("TrojanMatch Club information Collection (Responses)", submissions dated
-- 2026-08-08 through 2026-08-10) against what's live.
--
-- Responses through 8/07 were already applied in update-form-submissions.sql;
-- this migration covers the seven newer submissions plus four fields that pass
-- left stale. Generated from uploads/clubs.json, which stays the source of
-- truth. Paste into the Supabase SQL editor and run once.
--
-- Student leader names were collected by the form but are deliberately not
-- stored: there is no column for them and two advisors noted they go stale
-- every year.

-- ---- No phone numbers, site-wide ----
-- Many of the numbers submitted through the form were student leaders'
-- personal cells rather than school lines, and one advisor explicitly declined
-- to share hers. Rather than adjudicate case by case, the site publishes no
-- phone numbers at all; the modal hides the Phone row when it is empty.
update clubs set phone = null where phone is not null;

-- ---- Aerospace and Aeronautical Group ----
-- Form gave the advisor's full name.
update clubs set
  advisor = 'Clark Doten'
where id = 'aerospace-and-aeronautical-group';

-- ---- AHA: American Heart Association ----
-- Two submissions (8/7 and 8/9) merged. Phone dropped -- see
-- the note at the bottom of this file.
update clubs set
  description = 'We are a student-led club focused on cardiology, heart health awareness, and hands-on community action. Our purpose is to teach students life-saving skills like CPR and to raise awareness for better heart health within our school community, along with hosting guest speakers when possible. We are partnered with the American Heart Association.',
  detailed_description = 'We are a student-led club focused on cardiology, heart health awareness, and hands-on community action. Our purpose is to teach students life-saving skills like CPR and to raise awareness for better heart health within our school community, along with hosting guest speakers when possible. We are partnered with the American Heart Association.',
  interests = '["CPR & life-saving skills", "Heart health awareness", "Cardiology", "Interested in medicine and healthcare careers", "Guest speakers", "Community health education", "Partnered with the American Heart Association"]'::jsonb,
  scores = '{"science_stem": 1, "arts_creative": 0, "health_medical": 5, "competitiveness": 0, "time_commitment": 2, "world_languages": 0, "trades_technical": 0, "community_service": 4, "cultural_identity": 0, "sports_recreation": 0, "team_vs_individual": 3, "academic_competition": 0, "computer_science_tech": 0, "leadership_government": 1, "leadership_opportunity": 2, "social_special_interest": 1, "public_speaking_emphasis": 1, "writing_media_journalism": 0, "business_entrepreneurship": 0, "environmental_sustainability": 0}'::jsonb,
  email = 'wayzataamericanheart@gmail.com, clarice.jorenby@wayzataschools.org'
where id = 'aha-american-heart-association';

-- ---- Business Professionals of America (BPA) ----
-- New submission 8/10.
update clubs set
  description = 'Business Professionals of America prepares students for the business workforce by building leadership, professionalism, and competency. BPA is a student organization that promotes leadership and success in business. We prepare students for the global workforce through competition and community.',
  detailed_description = 'Business Professionals of America prepares students for the business workforce by building leadership, professionalism, and competency. BPA is a student organization that promotes leadership and success in business. We prepare students for the global workforce through competition and community. BPA is a Career and Technical Student Organization covering business, information technology, office administration, and finance, with technical and leadership competitive events. An informational meeting is held September 22nd in the 2nd floor forum.',
  email = 'whsbpa@wayzataschools.org, tika.kude@wayzataschools.org, michelle.jacklitch@wayzataschools.org'
where id = 'business-professionals-of-america';

-- ---- Crochet Group ----
-- New submission 8/8. Replaces the one-line placeholder; club
-- gave an official address, so the student leader's personal gmail and cell come off.
update clubs set
  advisor = 'Clark Doten',
  description = 'Wayzata Crochet Club strives to create a fun, low-stress, and creative environment for aspiring and expert crocheters. We welcome crocheters at all levels, whether you''re just starting or already advanced. We will also learn the basics of how to crochet together, and you''ll create small projects to enjoy or share with friends and family.',
  target_audience = 'Crocheters at every level, from complete beginners to advanced.',
  detailed_description = 'Wayzata Crochet Club strives to create a fun, low-stress, and creative environment for aspiring and expert crocheters. We welcome crocheters at all levels, whether you''re just starting or already advanced. We will also learn the basics of how to crochet together, and you''ll create small projects to enjoy or share with friends and family.',
  meeting_days = 'Every other Friday',
  interests = '["Crochet", "Learning to crochet", "All skill levels welcome", "Low-stress creative environment", "Small projects to keep or gift"]'::jsonb,
  scores = '{"science_stem": 0, "arts_creative": 5, "health_medical": 0, "competitiveness": 0, "time_commitment": 1, "world_languages": 0, "trades_technical": 0, "community_service": 0, "cultural_identity": 0, "sports_recreation": 0, "team_vs_individual": 2, "academic_competition": 0, "computer_science_tech": 0, "leadership_government": 0, "leadership_opportunity": 1, "social_special_interest": 3, "public_speaking_emphasis": 0, "writing_media_journalism": 0, "business_entrepreneurship": 0, "environmental_sustainability": 0}'::jsonb,
  email = 'wayzatacrochetclub@gmail.com, clark.doten@wayzataschools.org'
where id = 'crochet-group';

-- ---- Drama Club and Theatre ----
-- New submission 8/9.
update clubs set
  description = 'The WHS Drama Club offers students a vibrant gateway to explore all aspects of theatre, both onstage and off. Members produce six performances annually, participate in exciting social events and workshops, and connect with peers who share their passion for the performing arts.',
  detailed_description = 'The WHS Drama Club offers students a vibrant gateway to explore all aspects of theatre, both onstage and off. Members produce six performances annually, participate in exciting social events and workshops, and connect with peers who share their passion for the performing arts.',
  interests = '["An actor", "Enjoys performing", "Also fits students who like backstage tech such as lighting, sets, and costumes", "Six productions a year", "Workshops and social events", "Creative", "Collaborative", "Expressive", "A storyteller"]'::jsonb,
  scores = '{"science_stem": 0, "arts_creative": 5, "health_medical": 0, "competitiveness": 2, "time_commitment": 5, "world_languages": 0, "trades_technical": 1, "community_service": 0, "cultural_identity": 0, "sports_recreation": 0, "team_vs_individual": 5, "academic_competition": 0, "computer_science_tech": 1, "leadership_government": 0, "leadership_opportunity": 2, "social_special_interest": 3, "public_speaking_emphasis": 3, "writing_media_journalism": 1, "business_entrepreneurship": 0, "environmental_sustainability": 0}'::jsonb,
  email = 'justin.spooner@wayzataschools.org'
where id = 'drama-club-and-theatre';

-- ---- Hindu Student Association ----
-- New submission 8/8. Official club email plus the advisor's
-- school number replace a student leader's personal gmail and cell.
update clubs set
  description = 'Wayzata Hindu Student Association (HSA) is a student-led organization at Wayzata High School focused on promoting awareness and appreciation of Hindu culture, traditions, and values. The club provides students with opportunities to learn through discussions, activities, cultural celebrations, and community service. Wayzata HSA is open to all students, regardless of their background or prior knowledge of Hinduism. Our goal is to create an inclusive environment where students can learn, connect with others, and celebrate cultural diversity within the Wayzata High School community.',
  target_audience = 'Any student curious about Hindu culture and traditions, no prior knowledge needed.',
  detailed_description = 'Wayzata Hindu Student Association (HSA) is a student-led organization at Wayzata High School focused on promoting awareness and appreciation of Hindu culture, traditions, and values. The club provides students with opportunities to learn through discussions, activities, cultural celebrations, and community service. Wayzata HSA is open to all students, regardless of their background or prior knowledge of Hinduism. Our goal is to create an inclusive environment where students can learn, connect with others, and celebrate cultural diversity within the Wayzata High School community.',
  interests = '["Hindu culture and traditions", "Cultural celebrations", "Discussions and activities", "Community service", "Open to all backgrounds", "Inclusive community"]'::jsonb,
  scores = '{"science_stem": 0, "arts_creative": 2, "health_medical": 0, "competitiveness": 0, "time_commitment": 2, "world_languages": 0, "trades_technical": 0, "community_service": 3, "cultural_identity": 5, "sports_recreation": 0, "team_vs_individual": 4, "academic_competition": 0, "computer_science_tech": 0, "leadership_government": 0, "leadership_opportunity": 2, "social_special_interest": 3, "public_speaking_emphasis": 0, "writing_media_journalism": 0, "business_entrepreneurship": 0, "environmental_sustainability": 0}'::jsonb,
  email = 'wayzatahsa@gmail.com, jahnavi.tripuraneni@wayzataschools.org'
where id = 'hindu-student-association';

-- ---- HOSA Future Health Professionals ----
-- New submission 8/8. First meeting details and contact email.
-- Advisor declined to share a phone number, so phone stays null.
update clubs set
  description = 'Welcome to Wayzata HOSA! HOSA is a global student organization that helps students explore careers in healthcare and develop leadership skills. Members can compete in events covering topics such as medical science, public health, emergency medicine, and biomedical innovation. HOSA also provides opportunities to attend conferences, meet other students interested in healthcare, and learn from professionals in the field. Through competitions, community service, and chapter activities, HOSA encourages students to build the knowledge, confidence, and skills needed for future careers in healthcare.',
  detailed_description = 'Welcome to Wayzata HOSA! HOSA is a global student organization that helps students explore careers in healthcare and develop leadership skills. Members can compete in events covering topics such as medical science, public health, emergency medicine, and biomedical innovation. HOSA also provides opportunities to attend conferences, meet other students interested in healthcare, and learn from professionals in the field. Through competitions, community service, and chapter activities, HOSA encourages students to build the knowledge, confidence, and skills needed for future careers in healthcare.',
  meeting_location = '2nd floor forum',
  meeting_days = 'First Tuesday of the month',
  meeting_time = 'Morning and afternoon',
  interests = '["Future doctors, nurses, EMTs, dentists, or therapists", "Interested in medicine and healthcare careers", "Competes in medical science, public health, and emergency medicine events", "Biomedical innovation", "Conferences and networking", "Service-minded", "Wants exposure to the healthcare field"]'::jsonb,
  scores = '{"science_stem": 2, "arts_creative": 0, "health_medical": 5, "competitiveness": 3, "time_commitment": 3, "world_languages": 0, "trades_technical": 0, "community_service": 2, "cultural_identity": 0, "sports_recreation": 0, "team_vs_individual": 2, "academic_competition": 3, "computer_science_tech": 0, "leadership_government": 1, "leadership_opportunity": 3, "social_special_interest": 0, "public_speaking_emphasis": 1, "writing_media_journalism": 0, "business_entrepreneurship": 0, "environmental_sustainability": 0}'::jsonb,
  email = 'hosa@wayzataschools.org, clarice.jorenby@wayzataschools.org'
where id = 'hosa-future-health-professionals';

-- ---- Our Right to Learn ----
-- Gap from the 8/7 pass: the description was updated to cover all
-- children, but target_audience and interests still said "girls' education in India".
update clubs set
  target_audience = 'Students who want to advocate for children''s access to education.',
  interests = '["CRY America", "Fundraising", "Awareness campaigns", "Children''s right to education", "Advocacy and outreach", "Nonprofit work"]'::jsonb
where id = 'our-right-to-learn';

-- ---- Quiz Bowl ----
-- Gap from the 8/7 pass: form listed two advisors, only one was stored.
update clubs set
  advisor = 'Abigail Genise, Alexander Jazyk'
where id = 'quiz-bowl';

-- ---- Wayzata Real Estate Team ----
-- New submission 8/10. meeting_days had the time baked into it and
-- contradicted meeting_time; split correctly. Instagram handle is new.
update clubs set
  advisor = 'Timothy Masters',
  description = 'Wayzata Real Estate Team is a student-led organization created with three peers, where we host weekly sessions after school for students to learn about real estate. Through interactive activities, projects, simulations, and discussions, we aim to make real estate informative and engaging for our classmates who may be interested in pursuing real estate in the future.',
  detailed_description = 'Wayzata Real Estate Team is a student-led organization created with three peers, where we host weekly sessions after school for students to learn about real estate. Through interactive activities, projects, simulations, and discussions, we aim to make real estate informative and engaging for our classmates who may be interested in pursuing real estate in the future.',
  meeting_location = 'C409 (Mr. Masters'' room)',
  meeting_days = 'Mondays',
  meeting_time = '3:30-4:30 p.m.',
  instagram = 'wayzata.real.estate.team',
  email = 'wayzatarealestate.7@gmail.com, timothy.masters@wayzataschools.org'
where id = 'wayzata-real-estate-team';

-- ---- Needs a human decision ----
-- Mock Trial's response put "C414" in the advisor-phone field and left the
-- meeting question blank, so it reads as the advisor's room rather than a
-- confirmed meeting location. meeting_location is left null.
--
-- Women In Government submitted a member sign-up form link and BPA submitted a
-- one-time informational meeting date (Sept 22, 2nd floor forum). There is no
-- column for a sign-up link; the BPA meeting is noted in detailed_description.
