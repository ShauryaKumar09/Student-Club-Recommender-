-- 2026-08-20 -- staff corrections to the club roster.
-- Already applied to the live table via PostgREST; this file is the record.

-- Advisor names.
update clubs set advisor = 'Chris Easton' where id = 'sports-promotional-team';
update clubs set advisor = 'Riley Davis'  where id = 'robotics';

-- Super Mileage finally has an advisor, so the two sentences that said it did
-- not have to go with it, or the page contradicts its own advisor line.
update clubs set
  advisor = 'Ryan Ward',
  description = 'Engineering-focused: students build ultra-fuel-efficient vehicles and compete on miles-per-gallon.',
  detailed_description = 'Super Mileage Team is an engineering-focused club where students design and build ultra-fuel-efficient vehicles, competing against other schools on fuel economy.'
where id = 'super-mileage-team';

-- Both are official clubs, not student-organized groups.
update clubs set is_student_led = false where id in ('club-unified-students', 'trojan-tribune-journalism-club');

-- Dance Club is called Showstoppers, and it is not open sign-up. The old copy
-- said "no prior training expected" and "including complete beginners", which
-- is exactly the impression the correction was about. The row id stays
-- dance-club: photo object names and share links are built from it.
update clubs set
  name = 'Showstoppers',
  description = 'Showstoppers is Wayzata''s dance group: members choreograph together, explore new styles and perform through the year. Membership is by tryout — tryouts for the Showstoppers take place in the Spring for the following school year.',
  target_audience = 'Students with dance experience who want to choreograph and perform, and who can try out in the spring for the following school year.',
  detailed_description = 'Showstoppers is Wayzata''s dance group, for students who want to keep dancing outside of a studio setting. Members work on choreography together, explore different styles, and build routines as a group over the course of the year. A lot of what the group does is shaped by the people in it, so members have real say in what gets worked on from one season to the next. Membership is not open sign-up: tryouts for the Showstoppers take place in the Spring for the following school year.'
where id = 'dance-club';

-- Trap & Skeet is an athletics team listed on the Wayzata Athletics site, not a
-- club. International Club is no longer listed. Their photo objects are left in
-- the club-photos bucket; nothing references them.
delete from clubs where id in ('trap-and-skeet-club', 'international-club');

-- Trap & Skeet was the ONLY row scoring sports_recreation >= 3, so deleting it
-- left the quiz's Sports chip matching nothing at all. Esports is already filed
-- under Sports & Recreation and Sports Promotional Team shoots the games, so
-- both are scored at 3 and the chip has something to return.
update clubs set scores = jsonb_set(scores, '{sports_recreation}', '3')
where id in ('esports', 'sports-promotional-team');
