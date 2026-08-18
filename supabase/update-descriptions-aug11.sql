-- Club descriptions rewritten from two sources, 2026-08-11.
--
-- 1. The school's own activities pages, for six clubs whose listings were
--    written from guesswork: Band, Robotics, Wayako Yearbook, Trap & Skeet,
--    Dance Club and Student Council. Robotics was the important one -- the
--    site said VEX, the school says FIRST.
-- 2. Google Form responses 28-37 (submitted 8/10 - 8/11), where clubs sent in
--    their own write-ups. Text is theirs; edits were grammar and punctuation
--    only. Rows 1-27 of that export were already live and are untouched.
--
-- Dance Club and Student Council did not submit and have no source page of
-- their own; their text is a draft pending confirmation from Ms. Conn and
-- Ms. Swenson.
--
-- Already applied to production via the REST API. Kept here so the change is
-- reproducible and reviewable alongside the other migrations.


update clubs set
  description = 'One of the largest high school band programs in the state, with about 400 students taking part every year. Join by enrolling in a band class or by auditioning for an ensemble.',
  detailed_description = 'Band is one of the largest high school programs in the state, with about 400 students taking part every year. There are two ways in: enroll in a band class, or audition for an ensemble. Season length, rehearsal schedules and meeting times all vary by group. Most ensembles perform about four concerts a year, and some also play at athletic events.',
  target_audience = 'Instrumentalists of any experience level, whether you want a class or a competitive ensemble.'
where id = 'band';

update clubs set
  description = 'Students research, design, fabricate and test a robot built to the criteria set by the FIRST Robotics competition. About 25 members each year, by application and interview.',
  detailed_description = 'Robotics members research, design, fabricate and test a robot that has to meet the criteria set by the FIRST Robotics competition. About 25 students take part each year. Membership is open to grades 10-12 through an application and interview before the school year starts, and participating in SkillsUSA first is recommended. Pre-season runs September through December with meetings twice a week after school. Build season starts in January, when the team meets at least four days a week, with more days added closer to competition. Competitions run from locals in the fall through regionals in March, nationals in April and state in May. All members help with outreach events during the school year.',
  target_audience = 'Students in grades 10-12 interested in engineering, fabrication and coding, who can commit to a heavy build season.'
where id = 'robotics';

update clubs set
  description = 'The staff that plans, coordinates and publishes Wayako, the WHS yearbook. Typically eight editors and around 50 staffers.',
  detailed_description = 'Yearbook staff plan, coordinate and publish Wayako, the WHS yearbook, usually with eight editors and around 50 staffers. The team sets the theme and design, then creates and edits the content: interviews, articles, photos, captions and the style guide. They also run the logistics behind it, including student portrait days, senior photo submissions and distribution. Members build skills in interviewing, research and writing, digital design, planning and hitting deadlines.',
  target_audience = 'Students in grades 10-12 who have completed the yearbook course and are interested in writing, photography or design.',
  meeting_days = 'Third block (semester-long class), plus some after-school commitments'
where id = 'wayako-yearbook';

update clubs set
  description = 'A competitive team shooting American trap, American skeet and sporting clays. Requires a valid Minnesota DNR firearm safety certification.',
  detailed_description = 'Trap & Skeet is a competitive shooting team that shoots American trap, American skeet and sporting clays. A valid firearm safety certification issued by the Minnesota DNR is required to join. The season runs 12 weeks in the spring, from mid-March through late June, with after-school practices and weekend competitions.',
  target_audience = 'Students with a Minnesota DNR firearm safety certification who are interested in competitive shooting sports.'
where id = 'trap-and-skeet-club';

update clubs set
  description = 'Dance Club is a space to choreograph, explore new styles and perform alongside other students. Open to any experience level, with no prior training expected, and members help shape what the group works on.',
  detailed_description = 'Dance Club is a space for students who want to keep dancing outside of a studio setting, and for students who want to try it for the first time. Members work on choreography together, explore different styles, and build routines as a group over the course of the year. A lot of what the club does is shaped by the people in it, so members have real say in what gets worked on from one season to the next. No prior training or experience is expected, and the focus is on creativity, movement and having a group of people to dance with rather than on technical background.',
  target_audience = 'Students interested in dance, choreography and performance at any experience level, including complete beginners and dancers who train outside of school.'
where id = 'dance-club';

update clubs set
  description = 'The school''s elected student government. Members represent the student body to administration, plan school-wide events and organize spirit activities throughout the year.',
  detailed_description = 'Student Council is the school''s elected student government and the main way students have a formal voice in how the school runs. Members represent the student body to administration, bring forward ideas and concerns from their classmates, and plan events across the school year, including spirit weeks and other all-school activities. Much of the work happens in planning and coordination behind the scenes rather than in front of a crowd, and members build experience in organizing, budgeting time and working with staff. Because positions are filled by election, joining means running for a seat and campaigning to your class.',
  target_audience = 'Students interested in leadership, event planning and representing their classmates, who are willing to run in a school election.'
where id = 'student-council';

update clubs set
  description = 'A student-led business and leadership organization with about 300 members, exploring careers in business, entrepreneurship, marketing, finance, hospitality and management through competition.',
  detailed_description = 'Wayzata DECA is a student-led business and leadership organization at Wayzata High School that gives students hands-on opportunities to explore careers in business, entrepreneurship, marketing, finance, hospitality and management. With approximately 300 members, Wayzata DECA provides students with opportunities to develop professional skills that extend beyond the classroom through competitions, workshops, leadership experiences and collaborative projects.

The only requirement is taking one business course during the school year, in any semester. Members participate in DECA competitive events, where students apply business concepts to real-world scenarios. Depending on their first event, students may complete written business projects, develop marketing or entrepreneurship plans, or create presentations. Members'' second event includes a role-play scenario where they solve a business problem in front of a judge. Members prepare through practice sessions, workshops, mock competitions and individualized feedback before competing at the district, state and international levels. Successful members have the opportunity to advance to DECA''s International Career Development Conference (ICDC), where they compete against students from across the country and around the world. This year ICDC will take place in Anaheim, California.

Beyond competition, Wayzata DECA focuses heavily on professional development and leadership. Members learn skills such as public speaking, teamwork, problem-solving, communication, networking, research, presentation design and time management. The chapter also offers DECAchieve, an after-school program where members can get additional support with event preparation and meet business professionals who help them succeed in competition.

Wayzata DECA also provides opportunities for students to take on leadership roles and contribute to the broader community. Members can help organize chapter events, lead workshops, mentor other students, take part in fundraising and service initiatives, and develop programs that introduce younger students to business and entrepreneurship. They also host the best socials.',
  target_audience = 'Students interested in business, marketing, entrepreneurship or finance. Leans more toward marketing and entrepreneurship than BPA does, which is stronger on office and IT skills.',
  meeting_days = 'Monthly, with a morning and an evening session each month',
  meeting_location = 'Forum rooms'
where id = 'deca';

update clubs set
  description = 'Community service, leadership and volunteering in support of the American Red Cross mission.',
  detailed_description = 'The Wayzata Red Cross Club is a way to get involved in your community through service, leadership and volunteer opportunities. Throughout the year we host projects and events that support the mission of the American Red Cross, from care packages for people in our area to larger service initiatives, while giving members meaningful ways to make an impact.',
  target_audience = 'Students who want to serve their community and take on leadership in service projects.',
  instagram = 'wayzata.rcc'
where id = 'wayzata-red-cross';

update clubs set
  description = 'A creative community for writers of every kind. Workshops, monthly themes, contests, readings with local authors, and the school''s literary magazine.',
  detailed_description = 'Creative Writing Club calls all writers, poets, world builders, screenwriters, playwrights and lyricists. As a creative community, we publish the school''s literary magazine, host events with monthly themes, and take part in contests and publication opportunities. We give constructive feedback and host workshops and readings with local authors. We are open to all kinds of work and all kinds of goals. Come visit the glass case of published works by CWC authors on the 2nd floor of C Wing.

The club publishes The Voice, the school''s online literary magazine, twice a year, featuring student art, poetry, short stories and novel chapters. Entries are accepted throughout the year, and any student may submit work whether or not they attend meetings.',
  target_audience = 'Students who write anything at all, from poetry to screenplays to novels, at any level of experience, and any student who wants to publish work in the literary magazine.'
where id = 'creative-writing-club';

update clubs set
  name = 'Crafted With Care',
  description = 'Handmade crafts and projects for nursing home residents, made once a month by students.',
  detailed_description = 'Crafted With Care is a student group at Wayzata High School that brings creativity and kindness together. Once a month, members meet to make handmade crafts and thoughtful projects for residents of nursing homes. Our goal is to create meaningful items that can brighten someone''s day and help residents feel remembered and cared for.',
  target_audience = 'Students who like making things and want their crafting to go somewhere meaningful.'
where id = 'crafted-with-care';

update clubs set
  description = 'Build hands-on technical and career skills through team projects and state competitions, across engineering, digital media, skilled trades and leadership.',
  detailed_description = 'SkillsUSA at Wayzata High School is a student-led club where you can build real-world career skills, hands-on technical expertise and confidence through team projects and state competitions. Whether you''re interested in engineering, digital media, skilled trades or leadership, we offer practical experience and networking opportunities for every passion.',
  target_audience = 'Students interested in trades, technical careers, engineering or digital media, at any experience level.',
  meeting_days = 'Thursdays',
  meeting_time = '3:30 p.m.',
  meeting_location = 'D216',
  email = 'kyle.swenson@wayzataschools.org'
where id = 'skills-usa';

update clubs set
  description = 'An open space to make art with other students. Meetings are planned by a student leadership board around what members want to do.',
  detailed_description = 'The WHS Art Club is a space where students with an interest in art can come together and create with like-minded people. Activities and meetings are planned by a student-led leadership board with the group''s interests in mind. We create, we laugh, we learn, we make art together.',
  target_audience = 'Students interested in visual art of any medium or skill level.',
  meeting_days = 'Every other Tuesday',
  meeting_location = 'D210',
  email = 'ericka.bachmeier@wayzataschools.org'
where id = 'art-club';

update clubs set
  description = 'A community service and leadership organization with a portal of local volunteer opportunities. $55 to join, fall registration closes September 27.',
  detailed_description = 'Volunteer Club is a community service and youth leadership organization. Members sign up for a variety of volunteer opportunities in the local community and get access to the club''s volunteer opportunities portal, Canvas course and more. Meetings are held once a month, with a Wednesday after-school option and a Thursday before-school option, in Auditorium 1 or 2 depending on the month.

Membership for the 2026-27 school year costs $55 and you register through EPay. Fall registration is open August 10 through September 27. Club capacity is limited to 1,000 members, and a second registration window may open January 8-18, 2027 if space allows. Members must be current 9-12 students at WHS.',
  target_audience = 'Students who want a steady, organized way to find volunteer work and log service hours.',
  meeting_days = 'Once a month, Wednesday after school or Thursday before school',
  meeting_location = 'Auditorium 1 or 2',
  email = 'volunteerclub@wayzataschools.org'
where id = 'volunteer-club';

update clubs set
  description = 'Trained juniors and seniors mentor incoming freshmen and new students through the transition to high school, helping them find their footing socially and academically.',
  detailed_description = 'Wayzata Link Crew is a transition and leadership program that pairs trained juniors and seniors, called Link Leaders, with incoming freshmen and new students to help them adjust to a large school environment. Link Crew is a national program used by high schools across the country, built on the idea that the students best equipped to help a freshman find their footing are the ones who did it themselves a few years earlier.

Link Leaders are trained before the school year starts and then work with a small group of freshmen, helping them navigate the move to high school both socially and academically: learning the building, understanding how classes and expectations differ from middle school, and having an older student they can go to with questions that feel too small to ask a teacher.

For upperclassmen, Link Crew is a leadership role rather than a club you drop into. It builds skills in mentoring, public speaking and working with a group, and it puts you in front of students who will remember the person who made their first weeks easier.',
  target_audience = 'Juniors and seniors who want a real mentoring and leadership role, and every incoming freshman on the receiving end.',
  email = 'jennifer.landy@wayzataschools.org, emily.haugh@wayzataschools.org'
where id = 'link-crew';

update clubs set
  description = 'Explore different career fields through group activities, internships and volunteering, so you can figure out what to pursue after high school.',
  detailed_description = 'RISE Group is a student-led group at Wayzata High School that helps students explore different career fields so they can decide what they want to pursue after high school. We help students find clarity through group activities, internships and volunteering.',
  target_audience = 'Students who aren''t sure what they want to do after high school and want to try things out.'
where id = 'r-i-s-e-group';
