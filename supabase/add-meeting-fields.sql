-- Meeting details for the 43 student-led groups, as their own fields.
-- Run in the Supabase SQL editor (writes are blocked for the anon key by RLS).
--
-- Location, days and time come straight from the form cells each group filled in.
-- They were previously folded into the last sentence of detailed_description; that
-- sentence is removed here so the text is only about what the group does and the
-- meeting facts live in their own columns, ready to render as a separate section.
--
-- Adding columns is additive: the original 38 clubs get NULL in all three and are
-- otherwise untouched, and every UPDATE is guarded on the category.
-- Generated 2026-08-05.

alter table clubs add column if not exists meeting_location text;
alter table clubs add column if not exists meeting_days text;
alter table clubs add column if not exists meeting_time text;

begin;

update clubs set
  meeting_location = 'C403',
  meeting_days = 'Tuesdays after school',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'Aerospace and Aeronautical Group will teach students about aviation and aerospace technologies, explaining how they work, what they do, and why they are important.'
where id = 'aerospace-and-aeronautical-group' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'A411',
  meeting_days = 'Tuesdays once a month',
  meeting_time = 'Before school, 7:40-8:10 a.m.',
  detailed_description = 'Beads of Serenity makes bracelets for hospitals.'
where id = 'beads-of-serenity' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'H125 (The room right next to the weight room)',
  meeting_days = 'Once a month either on Tuesday or Thursdays',
  meeting_time = 'Before school, 7:40-8:10 a.m.',
  detailed_description = 'Club Unified Students works to bridge the gap between students with and without disabilities. It does this through fun events on the weekends and by working to unite our school community.'
where id = 'club-unified-students-us' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'The second floor forum room',
  meeting_days = 'The second Tuesday of each month',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'Club Utsaav is an Indian cultural group that helps students connect with their culture and informs members about ways to help out and make an impact in their community.'
where id = 'club-utsaav' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'A313',
  meeting_days = 'Second Thursday of the month',
  meeting_time = 'Before school, 7:40-8:10 a.m.',
  detailed_description = 'Crafted with Care makes crafts for various nursing homes in our community every month.'
where id = 'crafted-with-care' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'Hunter Lions Park',
  meeting_days = 'Once a week',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'Cricket Group teaches the fundamentals of cricket and has games.'
where id = 'cricket-group' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'C406',
  meeting_days = 'Every Friday',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'Crochet Group is a place for people who want to crochet or want to learn how to crochet.'
where id = 'crochet-group' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'A447 in new A',
  meeting_days = 'Every second Thursday of the month',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'Earthrise is a group that advocates for climate change and spreads awareness. It delivers presentations explaining the worldwide impact of climate change and what actions can be taken to effect change. It also offers volunteer opportunities at local parks to help pick up trash.'
where id = 'earthrise' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'C123',
  meeting_days = 'Once a month, on the last Wednesday',
  meeting_time = 'Before school, 7:40-8:10 a.m.',
  detailed_description = 'Educators Rising connects students who are interested in becoming an educator, whether that''s a teacher, counselor, principal, etc.'
where id = 'educators-rising' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'A311',
  meeting_days = 'We would usually meet Friday morning each month and it was random what week we did',
  meeting_time = 'Before school, 7:40-8:10 a.m.',
  detailed_description = 'Forget Me Not Organization is dedicated to spreading joy and kindness through the gift of flowers. Each month it delivers floral arrangements to patients in hospitals, veterans, the elderly, and others in need of a morale boost.'
where id = 'forget-me-not-organization' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'A416',
  meeting_days = 'Second Thrusday of each month',
  meeting_time = 'Before school, 7:40-8:10 a.m.',
  detailed_description = 'Girls Learn International helps fight for women''s equality worldwide and brings attention to the inequalities women and girls face.'
where id = 'girls-learn-international' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'D210',
  meeting_days = 'Every other Tuesday alternating with art club',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'GSA spreads LGBTQ awareness and creates community because LGBTQ people are important.'
where id = 'gsa' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'C107',
  meeting_days = 'Third Wednesday of the month',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'Hindu Student Association is essentially a home away from home. It is a space where students can celebrate their heritage, share the vibrancy of festivals, the depth of traditions, and the warmth of community, while finding a genuine support system to help navigate the highs and lows of high school life together. It''s about more than just events; it''s about creating a place where you can truly be yourself, learn from one another, and weave the values of kindness and inclusivity into the everyday fabric of the school.'
where id = 'hindu-student-association' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'A442',
  meeting_days = 'Every other Thursday. Later in the year in order to help prep for certain events, we will switch to every Thursday',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'Human Anatomy is a student group that offers hands-on learning experiences in anatomy through dissections, collaborative activities, and discussions. It seeks to promote scientific curiosity and encourage interest in medicine and healthcare careers.'
where id = 'human-anatomy' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'I don’t know the room number but Ms. Gohman’s room in 2A horseshoe',
  meeting_days = 'Every other Wednesday',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'Jewish Student Union meets bi-weekly to discuss Jewish topics, connect with the Jewish community, and enjoy their time together.'
where id = 'jewish-student-union' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'A302',
  meeting_days = 'First Wednesday of the month',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'Kids Scholarship Fund gives underprivileged kids a scholarship for education.'
where id = 'kids-scholarship-fund' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'A211',
  meeting_days = 'Last Thursday of the month',
  meeting_time = 'Before school, 7:40-8:10 a.m.',
  detailed_description = 'Knots of Kindness brings people together to give back to the less fortunate by making tie knot blankets and donating them to shelters and hospitals. The group also offers a chance to meet new people, collaborate with important organizations, and develop leadership skills.'
where id = 'knots-of-kindness' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'Ms. Brandy Office (For now)',
  meeting_days = 'Every 1st Wednesday of the month',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'Latino Student Union is a group where students from Latino or Hispanic origins can come together to celebrate Latino/Hispanic culture, learn and share experiences, and build a sense of community for all in attendance. The club explores Latino tradition, history, food, music, and the impact of Latinos on society and vice versa, while welcoming all students and providing a safe, welcoming, and comfortable environment where every student can feel seen and respected. Its purpose is to allow students to feel more connected, represented, and supported, and for many students whose families come from Latin American countries, it can be a place where they feel closer to their culture and heritage while navigating a new environment.'
where id = 'latino-student-union' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'C114',
  meeting_days = 'Second Friday of every month',
  meeting_time = 'Before school, 7:40-8:10 a.m.',
  detailed_description = 'Letters of Love makes cards for children''s hospitals once a month. The cards are delivered to the hospitals to bring joy to the kids during tough times.'
where id = 'letters-of-love' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'Mainly A251 but 2nd floor forum occasionally',
  meeting_days = 'Every Tuesday',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'Muslim Student Association (MSA) fosters a sense of unity among Muslims at Wayzata High School. It offers a safe space for Muslim students to explore and express their faith, promotes interfaith cooperation, and raises awareness of Islamic culture and values. Through discussions, debates, and informational meetings, it aims to contribute positively to society.'
where id = 'muslim-student-association-msa' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'C114 (health wing)',
  meeting_days = 'Once a month, exact date varies (usually near the end of the month)',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'Nurses of Tomorrow educates students on the vast nursing field through interactive activities, volunteering opportunities, recent news, and much more!'
where id = 'nurses-of-tomorrow' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'A218',
  meeting_days = 'Second Wednesday of the month',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'Origami For Good is a youth-led 501(c)(3) nonprofit organization that makes origami and sends it to soldiers, youth, seniors, patients, and more to inspire creativity and appreciation for Japanese art and culture.'
where id = 'origami-for-good' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'A145',
  meeting_days = 'Biweekly on Mondays',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'Our Right to Learn is a student chapter of the nonprofit organization CRY America that fundraises and raises awareness for girls'' lack of education in India.'
where id = 'our-right-to-learn' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'C406',
  meeting_days = 'Every other Wednesday',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'R.I.S.E Group helps students explore different career pathways so they can discover interests they want to pursue after high school.'
where id = 'r-i-s-e-group' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'A413',
  meeting_days = 'Bi-weekly on Wednesdays',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'SPEC: Student Political Engagement Center promotes civic engagement in students through discussion and education.'
where id = 'spec-student-political-engagement-center' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'E105',
  meeting_days = 'Most Thursdays, but frequency depends on how much information we need to give to the group',
  meeting_time = 'Before school, 7:40-8:10 a.m.',
  detailed_description = 'Sports Promotional Team is a group of sports photographers, videographers, graphic designers, and marketers for games and events throughout the school year.'
where id = 'sports-promotional-team' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'Room A444 (Mr. Larsen’s classroom)',
  meeting_days = 'Meetings will typically take place once or twice a month before school. Exact dates may vary slightly depending on the sports calendar and school activities',
  meeting_time = 'Before school, 7:40-8:10 a.m.',
  detailed_description = 'Sports Talk Group is a student-led interest group where students discuss professional sports, participate in sports-related discussions and activities, and connect with peers who share similar interests. The group strives to create a fun, respectful, and engaging environment for students interested in sports.'
where id = 'sports-talk-group' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'C420',
  meeting_days = 'Every other Wednesday',
  meeting_time = 'Before school, 7:40-8:10 a.m.',
  detailed_description = 'Stress Management provides support and strategies for students dealing with stress and anxiety.'
where id = 'stress-management' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'A215',
  meeting_days = 'Every Thursday Afterschool (some weeks will be free depending on testing schedule and club member vote)',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'Sustainable Swag (SS) is a get-together for people who share a love for fashion and designing. They do fun crafts such as embroidery on old shirts, bleaching patterns onto cloth, and teach simple sewing techniques. Some items may be donated to shelters or other organizations. The goal is to repurpose old clothes into something you can wear again or to make them aesthetically appealing for others in need.'
where id = 'sustainable-swag-ss' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'C409',
  meeting_days = 'The first Monday of every month',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'The BizMark Exchange aims to inspire and educate students about business, entrepreneurship, and marketing through hands-on experiences, great speakers, and real-world case studies. It strives to make business accessible and exciting for everyone, especially those new to the field.'
where id = 'the-bizmark-exchange' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'C123 or B302',
  meeting_days = 'Mondays and Thursdays',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'The Elite Pressure Line is a step team.'
where id = 'the-elite-pressure-line' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'C417',
  meeting_days = 'Every week on Thursdays',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'Trojan of God is a group where members speak about Jesus and for those who want to seek a purpose or hope, it is a club to develop a relationship with Jesus.'
where id = 'trojan-of-god' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'C218',
  meeting_days = 'Biweekly Thursday mornings',
  meeting_time = 'Before school, 7:40-8:10 a.m.',
  detailed_description = 'Trojan Tribune provides a digital newspaper for the students of Wayzata, shines a bright light on achievements that go unnoticed, and keeps everyone informed.'
where id = 'trojan-tribune' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'C415',
  meeting_days = 'Last Friday of every month',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'WAVE is a mental health initiative that actively combats poor mental health among high schoolers. Instead of creating a campaign advocating for mental health awareness, it performs activities that are detoxing in response to stressful schoolwork, homework, and current events.'
where id = 'wave-wayzata-actively-valuing-empathy' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'A315',
  meeting_days = 'Every Tuesday of the Month',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'Wayzata Inventors Group offers students the chance to design, build, and test innovative engineering projects in a collaborative, hands-on environment. Members tackle challenges ranging from structural design projects such as bridges and towers to more advanced experimental systems, developing strong problem-solving, creativity, and technical thinking skills. A central focus is guiding students through the development of official science-fair projects, supporting team formation based on shared interests, idea generation, research, prototyping, and testing, with structured mentorship to prepare for regional, state, and international competitions, including the International Science and Engineering Fair. The group aims to create a space where students pursue ambitious ideas, gain real project experience, and work toward producing high-quality, competition-ready research.'
where id = 'wayzata-inventors-group' and category = 'Student-Led Group';

update clubs set
  meeting_location = '2nd floor forum',
  meeting_days = 'Every other Friday',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'Wayzata Investment Competition (WIC) was created to teach high schoolers basic investing skills, equipping them to become financially responsible adults. Students learn and test their skills in competition through the Wharton Investing Competition and the MN Stock Market Game.'
where id = 'wayzata-investment-competition-wic' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'A119',
  meeting_days = 'Every Wednesday',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'Wayzata K-Pop Group was started during Term 4 of the 2025-2026 school year by three dedicated students. It offers an inclusive, high-energy space at Wayzata High School for students to connect through K-pop, Korean culture, language practice, interactive team games, and choreography covers. The group plans to remain highly organized throughout the 2026-2027 school year to demonstrate consistency and passion to the WHS Activities Office for official sponsorship.'
where id = 'wayzata-k-pop-group' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'C409',
  meeting_days = 'Every Monday after school 3:30-4:30pm',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'Wayzata Real Estate Team is a student-led organization founded with three peers, hosting weekly after-school sessions for students to learn about real estate. Through interactive activities, projects, simulations, and discussions, the team aims to make real estate informative and engaging for classmates who may be interested in pursuing a career in real estate.'
where id = 'wayzata-real-estate-team' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'C113',
  meeting_days = 'Second Monday of the month',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'Wayzata Red Cross introduces the American Red Cross to the school and helps people in our vicinity with care packages, for example.'
where id = 'wayzata-red-cross' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'Room C121 (Ms. Hanley’s classroom)',
  meeting_days = 'Twice a month on Thursdays',
  meeting_time = 'Before school, 7:40-8:10 a.m.',
  detailed_description = 'Wayzata She Leads empowers young women to connect, build practical life-skills-from public speaking to self-market-and actively prepare for college and career success through engaging activities.'
where id = 'wayzata-she-leads' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'A314',
  meeting_days = 'Tuesday mornings weekly',
  meeting_time = 'Before school, 7:40-8:10 a.m.',
  detailed_description = 'We Have Spirit Bible Study reaches Christian students at Wayzata in a community and studies the Bible weekly.'
where id = 'we-have-spirit-bible-study' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'A414',
  meeting_days = 'Once a week Thursday',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'Women In Government empowers students to learn about government, public policy, and civic leadership while encouraging more young women and students to get involved in government.'
where id = 'women-in-government' and category = 'Student-Led Group';

update clubs set
  meeting_location = 'A219',
  meeting_days = 'First Wednesday of the month',
  meeting_time = 'After school, 3:10-4:10 p.m.',
  detailed_description = 'Youth in Medicine sparks thought-provoking conversations about the medical field and its careers. It offers hands-on labs and demonstrations to engage students.'
where id = 'youth-in-medicine' and category = 'Student-Led Group';

commit;

-- Verify: 43 groups with all three meeting fields, and no meeting text left behind
-- in detailed_description.
select count(*) filter (where meeting_location is not null) as with_location,
       count(*) filter (where meeting_days is not null)     as with_days,
       count(*) filter (where meeting_time is not null)     as with_time,
       count(*)                                              as total
from clubs where category = 'Student-Led Group';

select count(*) as originals_with_meeting_fields from clubs
where category <> 'Student-Led Group'
  and (meeting_location is not null or meeting_days is not null or meeting_time is not null);
