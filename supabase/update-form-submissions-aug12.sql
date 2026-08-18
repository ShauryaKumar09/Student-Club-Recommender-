-- Aug 12 2026: apply the second batch of Google Form submissions.
-- 11 new form responses, all of which matched clubs already in the
-- table, so every statement here is an update rather than an insert.
-- Already applied to the live database via PostgREST; kept for the record.

update public.clubs set
  email = 'clubrise2025@gmail.com'
where id = 'r-i-s-e-group';

update public.clubs set
  advisor = 'Darcy Hanley',
  email = 'sheleads.whs@gmail.com',
  instagram = 'whs_sheleads',
  meeting_days = 'Every other Tuesday',
  meeting_time = 'Before school, 7:40-8:10 a.m.',
  meeting_location = 'Room C121 (Ms. Hanley’s classroom)',
  target_audience = 'Girls who want to build confidence and practical life skills, and start thinking about college and career early.',
  description = 'A club for girls building confidence and practical life skills — public speaking, resume writing, personal finance — alongside college and career planning.',
  detailed_description = 'SheLeads is a club at Wayzata High School designed to empower girls by helping them build confidence, develop valuable life skills and prepare for their futures.

Members meet new people and connect with like-minded girls while learning skills such as public speaking, resume building and personal finance. Through college and career quizzes, activities and group discussions, SheLeads provides a supportive environment to explore future opportunities and grow as a leader.',
  interests = ARRAY['Building confidence', 'Public speaking', 'Resume building', 'Personal finance', 'Life skills', 'College preparation', 'Career readiness', 'Leadership for young women', 'Meeting new people', 'Networking']::text[],
  scores = '{"science_stem": 0, "arts_creative": 0, "health_medical": 0, "competitiveness": 0, "performing_arts": 0, "time_commitment": 2, "world_languages": 0, "trades_technical": 0, "community_service": 0, "cultural_identity": 0, "sports_recreation": 0, "team_vs_individual": 3, "academic_competition": 0, "computer_science_tech": 0, "leadership_government": 3, "leadership_opportunity": 4, "social_special_interest": 3, "public_speaking_emphasis": 4, "writing_media_journalism": 0, "business_entrepreneurship": 3, "environmental_sustainability": 0}'::jsonb
where id = 'wayzata-she-leads';

update public.clubs set
  email = 'whsscienceolympiad@wayzataschools.org',
  meeting_days = 'Tuesdays, late September through March',
  meeting_time = 'Immediately after school',
  target_audience = 'Students who like building things and hands-on science, not just quizzing, and who want to compete at a high level.',
  description = 'A 23-event team competition mixing study, lab and build events. More hands-on and project-oriented than Science Bowl; the season runs late September to the March state tournament.',
  detailed_description = 'Wayzata High School Science Olympiad is an academic team for students who love science, technology, engineering or math, or who just enjoy solving complex hands-on challenges.

Science Olympiad works much like an academic track meet. Instead of running or jumping, team members compete across 23 different events spanning nearly every scientific discipline imaginable, including biology, chemistry, physics, earth science, astronomy, coding and engineering.

Members pair up with partners and specialize in specific events. Depending on your interest, you focus on one, or a mix, of three event types. In study events you and a partner become subject-matter experts in a specialized field such as Astronomy, Anatomy & Physiology or Geological Mapping, studying advanced material, creating reference binders and cheat sheets, and tackling rigorous exams at competitions. In lab events such as Chemistry Lab or Forensics you put theory into practice, performing experiments, analyzing unknown chemicals or solving crime scenes under a strict time limit. In build events you spend the season designing, constructing and testing devices from scratch, such as bridges, rubber-band-powered airplanes or autonomous vehicles, to meet strict specs and perform precise tasks at tournaments.

Through the fall and winter, team members meet after school to study, run mock tests, conduct lab experiments and test build devices in the labs and hallways, and the team attends multiple invitational tournaments across the region to sharpen skills, tweak builds and refine strategies. Everything builds toward the Minnesota State Science Olympiad tournament, where the team competes for the state championship and a spot representing Minnesota at the National Science Olympiad tournament.

Whether you want to dive deep into a niche scientific topic, gain real hands-on engineering experience, build connections with like-minded peers or compete at the national level, Science Olympiad is a place to learn, build and win together.',
  interests = ARRAY['Hands-on builder', 'Likes labs and engineering challenges', 'Broad science interest', 'Astronomy', 'Forensics', 'Chemistry lab', 'Anatomy and physiology', 'Coding', 'Enjoys teamwork', 'Interested in STEM careers', 'National-level competition', 'Likes variety, mixing knowledge events with building events']::text[],
  scores = '{"science_stem": 5, "arts_creative": 0, "health_medical": 0, "competitiveness": 4, "performing_arts": 0, "time_commitment": 4, "world_languages": 0, "trades_technical": 3, "community_service": 0, "cultural_identity": 0, "sports_recreation": 0, "team_vs_individual": 4, "academic_competition": 4, "computer_science_tech": 2, "leadership_government": 0, "leadership_opportunity": 1, "social_special_interest": 2, "public_speaking_emphasis": 0, "writing_media_journalism": 0, "business_entrepreneurship": 0, "environmental_sustainability": 1}'::jsonb
where id = 'science-olympiad';

update public.clubs set
  instagram = 'whs__bible_study',
  meeting_days = 'Friday mornings weekly',
  meeting_location = 'A314',
  target_audience = 'Students who want to learn more about Christianity or find a like-minded community at school.',
  description = 'A weekly Friday-morning Bible study with donuts, guest speakers, games and small-group discussion.',
  detailed_description = 'We Have Spirit (WHS) Bible Study is a student-led group that meets weekly on Friday mornings. Members eat donuts, read the Bible, listen to guest speakers, play games and discuss deep topics in small groups.

If you are interested in learning more about Christianity, or in finding a like-minded community at school, WHS Bible Study is the place for you.',
  interests = ARRAY['Bible study', 'Christian fellowship', 'Faith community', 'Small-group discussion', 'Guest speakers', 'Games', 'Learning about Christianity', 'Meeting before school']::text[],
  scores = '{"science_stem": 0, "arts_creative": 0, "health_medical": 0, "competitiveness": 0, "performing_arts": 0, "time_commitment": 3, "world_languages": 0, "trades_technical": 0, "community_service": 0, "cultural_identity": 5, "sports_recreation": 0, "team_vs_individual": 4, "academic_competition": 0, "computer_science_tech": 0, "leadership_government": 0, "leadership_opportunity": 1, "social_special_interest": 3, "public_speaking_emphasis": 0, "writing_media_journalism": 0, "business_entrepreneurship": 0, "environmental_sustainability": 0}'::jsonb
where id = 'we-have-spirit-bible-study';

update public.clubs set
  advisor = 'Abigail Genise',
  email = 'whs.ofg@gmail.com',
  meeting_time = 'After school, 3:30-4:30 p.m.',
  target_audience = 'Students who enjoy paper craft and want their creations to go somewhere meaningful.',
  description = 'A youth-led nonprofit that folds origami and sends it to soldiers, seniors, hospital patients and others to spread creativity and Japanese art and culture.',
  detailed_description = 'Origami For Good is a youth-led 501(c)(3) nonprofit organization that makes origami and sends it to soldiers, youth, seniors, patients and more, in order to inspire creativity and appreciation for Japanese art and culture.

The Wayzata chapter meets once a month after school to fold together. Check the club’s social media and emails for important updates during the year.',
  interests = ARRAY['Origami', 'Paper craft', 'Japanese art & culture', 'Community service', 'Creativity', 'Giving to soldiers and hospital patients', 'Low time commitment', 'Nonprofit work']::text[],
  scores = '{"science_stem": 0, "arts_creative": 5, "health_medical": 0, "competitiveness": 0, "performing_arts": 0, "time_commitment": 2, "world_languages": 0, "trades_technical": 0, "community_service": 4, "cultural_identity": 4, "sports_recreation": 0, "team_vs_individual": 3, "academic_competition": 0, "computer_science_tech": 0, "leadership_government": 0, "leadership_opportunity": 3, "social_special_interest": 2, "public_speaking_emphasis": 0, "writing_media_journalism": 0, "business_entrepreneurship": 0, "environmental_sustainability": 0}'::jsonb
where id = 'origami-for-good';

update public.clubs set
  instagram = 'whs_chinese',
  meeting_days = 'Every other Tuesday, all year',
  meeting_time = 'After school, 3:20-4:20 p.m.',
  meeting_location = 'A111',
  target_audience = 'Anyone curious about Chinese language or culture — no language experience required.',
  description = 'After-school activities exploring Chinese language and culture, from traditional holidays to arts and cultural celebrations. No language skills required.',
  detailed_description = 'Wayzata High School Chinese Club provides after-school activities designed to promote and encourage students to learn about Chinese language and culture. No language skills are required — everyone is welcome to join.

The club has previously organized activities connected to Chinese culture, including traditional holidays, arts and cultural celebrations. The club has student officers, who are elected by the members.',
  interests = ARRAY['Interested in Chinese language and culture', 'No language experience needed', 'Beginner friendly', 'Chinese holidays and festivals', 'Arts and cultural celebrations', 'Likes learning languages', 'Curious about Asia', 'Enjoys cultural exchange', 'Interested in international business or travel']::text[],
  scores = '{"science_stem": 0, "arts_creative": 2, "health_medical": 0, "competitiveness": 0, "performing_arts": 0, "time_commitment": 2, "world_languages": 5, "trades_technical": 0, "community_service": 0, "cultural_identity": 4, "sports_recreation": 0, "team_vs_individual": 3, "academic_competition": 0, "computer_science_tech": 0, "leadership_government": 0, "leadership_opportunity": 1, "social_special_interest": 2, "public_speaking_emphasis": 1, "writing_media_journalism": 0, "business_entrepreneurship": 0, "environmental_sustainability": 0}'::jsonb
where id = 'chinese-club';

update public.clubs set
  advisor = 'Amy Swenson, Sarah Lagerquist',
  email = 'whsstudentcouncil@isd284.com',
  meeting_days = 'Senate: twice a month on Mondays. House: first or second Tuesday of the month',
  meeting_time = 'Senate: during the school day. House: before school, 7:45-8:15 a.m.',
  target_audience = 'Students interested in leadership, event planning and representing their classmates — either by running for election or by joining the House in the fall.',
  description = 'The school’s student government. Two ways in: run for the elected Senate in spring, or work on to the House in the fall. Both plan Homecoming, Prom, service drives and spirit events.',
  detailed_description = 'Looking for a way to make a difference at Wayzata High School, build leadership skills and help create a stronger school community? Student Council is for you, and there are two ways to get involved.

The Student Council Senate is the representative body for students. Elections take place each spring, with election materials sent to all students in April. Senate members work with students and administration to address student concerns, improve school culture and plan some of the school’s most memorable events, including Homecoming, P.E.A.C.E., Sip-N-Study, Staff Appreciation Week, the Spring Drive-In Movie and Prom. Student Council also organizes fundraising and service events supporting organizations such as IOCP, Minnesota Children’s Hospital, NAMI and Fund-A-Need, which directly supports WHS students.

Not interested in running for an elected position? You can still be an important part of the council. Students have the opportunity to work on to the Student Council House at the beginning of each school year, and information is shared during Back-to-Business days in the fall. Members of the House develop their leadership skills serving on various committees, and they also belong to a student council family group, where they create events and activities that engage every member of the school community.

Wayzata’s Student Council has been recognized as a National Gold Council of Excellence by the National Association of Student Councils, a distinction that reflects its commitment to leadership, service and the WHS community.',
  interests = ARRAY['Interested in leadership', 'Enjoys planning events', 'Organized', 'Outgoing', 'Full of school spirit', 'Wants a voice in the school', 'Willing to run for election', 'Committee work', 'Fundraising and service', 'Homecoming and Prom planning', 'Interested in management, politics, or organizing']::text[],
  scores = '{"science_stem": 0, "arts_creative": 0, "health_medical": 0, "competitiveness": 1, "performing_arts": 0, "time_commitment": 3, "world_languages": 0, "trades_technical": 0, "community_service": 4, "cultural_identity": 0, "sports_recreation": 0, "team_vs_individual": 5, "academic_competition": 0, "computer_science_tech": 0, "leadership_government": 5, "leadership_opportunity": 5, "social_special_interest": 3, "public_speaking_emphasis": 3, "writing_media_journalism": 0, "business_entrepreneurship": 1, "environmental_sustainability": 0}'::jsonb
where id = 'student-council';

update public.clubs set
  meeting_days = 'Every Monday, starting October 12th',
  meeting_time = 'After school',
  meeting_location = 'C314',
  target_audience = 'Anyone who enjoys math and wants to test it competitively — no prerequisites, any experience level.',
  description = 'Competes in the Minnesota State High School Math League and contests such as the AMC. No prerequisites — every experience level finds a challenge.',
  detailed_description = 'The WHS Math Team is open to any high school student who is passionate about mathematics. There are no prerequisites to joining the team, and everyone will find an enjoyable challenge regardless of experience level.

The team competes in the Minnesota State High School Math League and has access to other competitions such as the AMC. Meets are timed and mix individual problem-solving rounds with team rounds, so members work both on their own and together.',
  interests = ARRAY['Strong in math', 'No prerequisites', 'Beginner friendly', 'Enjoys timed problem-solving', 'Competitive', 'Likes puzzles', 'AMC', 'Interested in engineering, computer science, finance, or actuarial work', 'Thrives on precision']::text[],
  scores = '{"science_stem": 4, "arts_creative": 0, "health_medical": 0, "competitiveness": 4, "performing_arts": 0, "time_commitment": 2, "world_languages": 0, "trades_technical": 0, "community_service": 0, "cultural_identity": 0, "sports_recreation": 0, "team_vs_individual": 2, "academic_competition": 5, "computer_science_tech": 1, "leadership_government": 0, "leadership_opportunity": 1, "social_special_interest": 1, "public_speaking_emphasis": 0, "writing_media_journalism": 0, "business_entrepreneurship": 0, "environmental_sustainability": 0}'::jsonb
where id = 'math-team';

update public.clubs set
  advisor = 'Micah Schaefer',
  email = 'richajan001@isd284.com',
  instagram = 'whsbeadsofserenity',
  meeting_days = 'One Tuesday a month',
  meeting_time = 'Before school, 7:30 a.m.',
  meeting_location = 'Micah Schaefer’s classroom',
  target_audience = 'Students who want a low-commitment way to do something kind — no crafting experience or supplies needed.',
  description = 'Student-led club making beaded bracelets once a month and donating them to memory care residents, hospital patients and other community organizations. All supplies provided.',
  detailed_description = 'Beads of Serenity is a student-led club that focuses on giving back to the community through creating and donating bracelets. The goal of giving these bracelets is to spread kindness and care, give back to the community, raise awareness, and form connections.

Every bracelet is student-made during the club’s once-a-month morning meetings, using string and beads that the club board supplies for members to use, so there is nothing to bring and no crafting experience needed. Finished bracelets are donated to organizations and facilities around the area, including Parks Place Memory Care Facility and the children’s hospital.

The club is open to all students throughout the year, and information and updates are posted on the club Instagram.',
  interests = ARRAY['Making bracelets', 'Crafting', 'Community service', 'Spreading kindness', 'Donating to hospitals', 'Memory care residents', 'Small hands-on projects', 'Low time commitment', 'Beginner friendly', 'Supplies provided']::text[],
  scores = '{"science_stem": 0, "arts_creative": 5, "health_medical": 1, "competitiveness": 0, "performing_arts": 0, "time_commitment": 1, "world_languages": 0, "trades_technical": 0, "community_service": 5, "cultural_identity": 0, "sports_recreation": 0, "team_vs_individual": 3, "academic_competition": 0, "computer_science_tech": 0, "leadership_government": 0, "leadership_opportunity": 1, "social_special_interest": 2, "public_speaking_emphasis": 0, "writing_media_journalism": 0, "business_entrepreneurship": 0, "environmental_sustainability": 0}'::jsonb
where id = 'beads-of-serenity';

update public.clubs set
  email = 'wayzata.compsciclub@gmail.com',
  instagram = 'wayzata.csc',
  target_audience = 'Students who want to actually build things with code, from first-time programmers to anyone eyeing a tech career.',
  description = 'Weekly hands-on computer science: Python and small projects early in the year, then machine learning, cybersecurity, web development and AI.',
  detailed_description = 'Wayzata Computer Science Group meets weekly to teach members computer science topics, focusing on Python early in the year with fun projects that apply what members learn.

The group is built around teamwork, with group projects and team hackathons rather than solo work. Later in the year it introduces other computer science fields such as machine learning, cybersecurity, web development, and agentic uses of artificial intelligence, so members can dive deeper into whichever topics interest them as a possible career.',
  interests = ARRAY['Python programming', 'Beginner friendly', 'Group projects', 'Team hackathons', 'Machine learning', 'Cybersecurity', 'Web development', 'Artificial intelligence', 'Tech careers']::text[],
  scores = '{"science_stem": 3, "arts_creative": 0, "health_medical": 0, "competitiveness": 1, "performing_arts": 0, "time_commitment": 3, "world_languages": 0, "trades_technical": 0, "community_service": 0, "cultural_identity": 0, "sports_recreation": 0, "team_vs_individual": 4, "academic_competition": 1, "computer_science_tech": 5, "leadership_government": 0, "leadership_opportunity": 2, "social_special_interest": 2, "public_speaking_emphasis": 1, "writing_media_journalism": 0, "business_entrepreneurship": 0, "environmental_sustainability": 0}'::jsonb
where id = 'wayzata-computer-science-group';

update public.clubs set
  email = 'whsaidatascience@gmail.com',
  target_audience = 'Students who want to work with data and AI hands-on rather than just read about them.',
  description = 'Explores machine learning, data analysis and real-world AI applications through hands-on projects, competitions and guest speakers.',
  detailed_description = 'Data Science & AI is a student-led group for students who want to work with data and artificial intelligence directly rather than just read about them.

Members explore machine learning, data analysis and real-world applications of AI through hands-on projects. The group also enters competitions and brings in guest speakers, so members can see how data science is used outside of school. Sessions are project-based, which means members pick up the tools by building something with them.',
  interests = ARRAY['Machine learning', 'Data analysis', 'Real-world AI applications', 'Hands-on projects', 'Building models', 'Competitions', 'Guest speakers', 'Tech careers']::text[],
  scores = '{"science_stem": 3, "arts_creative": 0, "health_medical": 0, "competitiveness": 2, "performing_arts": 0, "time_commitment": 2, "world_languages": 0, "trades_technical": 0, "community_service": 0, "cultural_identity": 0, "sports_recreation": 0, "team_vs_individual": 4, "academic_competition": 2, "computer_science_tech": 5, "leadership_government": 0, "leadership_opportunity": 1, "social_special_interest": 1, "public_speaking_emphasis": 0, "writing_media_journalism": 0, "business_entrepreneurship": 0, "environmental_sustainability": 0}'::jsonb
where id = 'data-science-and-ai';

-- The performing_arts dimension was added after these five rows were
-- created, so their score objects were missing the key. A missing key
-- reads as 0 in the matcher, but a complete object keeps the audit clean.
update public.clubs set scores = scores || '{"performing_arts": 0}'::jsonb
where not (scores ? 'performing_arts');
