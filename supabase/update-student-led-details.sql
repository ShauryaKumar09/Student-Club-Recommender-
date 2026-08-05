-- Card detail fields for the 43 student-led groups.
-- Run in the Supabase SQL editor (writes are blocked for the anon key by RLS).
--
-- Every value is the student's own application text, reworded for grammar and
-- readability only, plus the meeting location/day/time they entered on the form.
-- No activity, event or claim was added that a group did not write itself.
--
-- Touches only target_audience, detailed_description and interests. The short
-- description, name, advisor, scores, category, email and phone are left alone,
-- and the category guard in each WHERE means the original 38 clubs cannot match.
-- Generated 2026-08-05.

begin;

update clubs set
  target_audience = 'Students interested in aviation and aerospace technologies.',
  detailed_description = 'Aerospace and Aeronautical Group will teach students about aviation and aerospace technologies, explaining how they work, what they do, and why they are important. The group meets every Tuesday after school, from 3:10 to 4:10 p.m., in C403.',
  interests = array['Aviation', 'Aerospace technologies', 'How they work', 'What they do', 'Why they are important']::text[]
where id = 'aerospace-and-aeronautical-group' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students who want to make bracelets for hospitals.',
  detailed_description = 'Beads of Serenity makes bracelets for hospitals. It meets once a month on Tuesdays before school, from 7:40 to 8:10 a.m., in A411.',
  interests = array['Bracelets', 'Hospitals']::text[]
where id = 'beads-of-serenity' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in exploring career pathways.',
  detailed_description = 'R.I.S.E Group helps students explore different career pathways so they can discover interests they want to pursue after high school. It meets every other Wednesday after school, from 3:10 to 4:10 p.m., in C406.',
  interests = array['Career pathways', 'Post-high-school interests']::text[]
where id = 'r-i-s-e-group' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students who want to support peers with and without disabilities.',
  detailed_description = 'Club Unified Students works to bridge the gap between students with and without disabilities. It does this through fun events on the weekends and by working to unite our school community. It meets once a month on either Tuesday or Thursday before school, from 7:40 to 8:10 a.m., in H125, the room right next to the weight room.',
  interests = array['Bridge the gap between students with and without disabilities', 'Fun events on the weekends', 'Unite our school community']::text[]
where id = 'club-unified-students-us' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in Indian culture and community service.',
  detailed_description = 'Club Utsaav is an Indian cultural group that helps students connect with their culture and informs members about ways to help out and make an impact in their community. It meets on the second Tuesday of each month after school, from 3:10 to 4:10 p.m., in the second floor forum room.',
  interests = array['Indian culture', 'Community service', 'Cultural connection', 'Community impact']::text[]
where id = 'club-utsaav' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students who want to make crafts for nursing homes.',
  detailed_description = 'Crafted with Care makes crafts for various nursing homes in our community every month. It meets on the second Thursday of the month before school, from 7:40 to 8:10 a.m., in A313.',
  interests = array['Crafts', 'Nursing homes', 'Community service']::text[]
where id = 'crafted-with-care' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in cricket.',
  detailed_description = 'Cricket Group teaches the fundamentals of cricket and has games. It meets once a week after school, from 3:10 to 4:10 p.m., at Hunter Lions Park.',
  interests = array['Cricket fundamentals', 'Cricket games']::text[]
where id = 'cricket-group' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in crocheting.',
  detailed_description = 'Crochet Group is a place for people who want to crochet or want to learn how to crochet. It meets every Friday after school, from 3:10 to 4:10 p.m., in C406.',
  interests = array['Crochet', 'Learning to crochet']::text[]
where id = 'crochet-group' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in environmental activism.',
  detailed_description = 'Earthrise is a group that advocates for climate change and spreads awareness. It delivers presentations explaining the worldwide impact of climate change and what actions can be taken to effect change. It also offers volunteer opportunities at local parks to help pick up trash. The group meets every second Thursday of the month after school, from 3:10 to 4:10 p.m., in A447 in new A.',
  interests = array['Climate change advocacy', 'Presentations', 'Volunteer opportunities', 'Park cleanups']::text[]
where id = 'earthrise' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in becoming an educator.',
  detailed_description = 'Educators Rising connects students who are interested in becoming an educator, whether that''s a teacher, counselor, principal, etc. It meets once a month on the last Wednesday before school, from 7:40 to 8:10 a.m., in C123.',
  interests = array['Teacher', 'Counselor', 'Principal', 'Educator']::text[]
where id = 'educators-rising' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students who want to help patients, veterans, the elderly, and others in need.',
  detailed_description = 'Forget Me Not Organization is dedicated to spreading joy and kindness through the gift of flowers. Each month it delivers floral arrangements to patients in hospitals, veterans, the elderly, and others in need of a morale boost. It meets on Friday mornings before school, from 7:40 to 8:10 a.m., in A311, though the specific week each month is random.',
  interests = array['Flowers', 'Floral arrangements', 'Hospital patients', 'Veterans', 'Elderly', 'Morale boost']::text[]
where id = 'forget-me-not-organization' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in women''s equality.',
  detailed_description = 'Girls Learn International helps fight for women''s equality worldwide and brings attention to the inequalities women and girls face. It meets on the second Thursday of each month before school, from 7:40 to 8:10 a.m., in A416.',
  interests = array['Women''s equality', 'Inequalities faced by women and girls']::text[]
where id = 'girls-learn-international' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in LGBTQ community.',
  detailed_description = 'GSA spreads LGBTQ awareness and creates community because LGBTQ people are important. It meets every other Tuesday, alternating with art club, after school from 3:10 to 4:10 p.m., in D210.',
  interests = array['LGBTQ awareness', 'Community', 'LGBTQ people']::text[]
where id = 'gsa' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in supporting girls'' education in India.',
  detailed_description = 'Our Right to Learn is a student chapter of the nonprofit organization CRY America that fundraises and raises awareness for girls'' lack of education in India. It meets biweekly on Mondays after school, from 3:10 to 4:10 p.m., in A145.',
  interests = array['CRY America', 'Fundraising', 'Awareness campaigns', 'Girls'' education in India', 'Nonprofit work']::text[]
where id = 'our-right-to-learn' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students who want a supportive community to celebrate their heritage.',
  detailed_description = 'Hindu Student Association is essentially a home away from home. It is a space where students can celebrate their heritage, share the vibrancy of festivals, the depth of traditions, and the warmth of community, while finding a genuine support system to help navigate the highs and lows of high school life together. It''s about more than just events; it''s about creating a place where you can truly be yourself, learn from one another, and weave the values of kindness and inclusivity into the everyday fabric of the school. It meets on the third Wednesday of the month after school, from 3:10 to 4:10 p.m., in C107.',
  interests = array['celebrate heritage', 'festivals', 'traditions', 'community', 'support system', 'kindness and inclusivity']::text[]
where id = 'hindu-student-association' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in medicine and healthcare careers.',
  detailed_description = 'Human Anatomy is a student group that offers hands-on learning experiences in anatomy through dissections, collaborative activities, and discussions. It seeks to promote scientific curiosity and encourage interest in medicine and healthcare careers. The group meets every other Thursday, later switching to every Thursday, after school from 3:10 to 4:10 p.m. in A442.',
  interests = array['Anatomy dissections', 'Collaborative activities', 'Discussions', 'Scientific curiosity', 'Medicine careers', 'Healthcare careers']::text[]
where id = 'human-anatomy' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in Jewish topics.',
  detailed_description = 'Jewish Student Union meets bi-weekly to discuss Jewish topics, connect with the Jewish community, and enjoy their time together. They meet every other Wednesday after school, from 3:10 to 4:10 p.m., in Ms. Gohman''s room in 2A horseshoe.',
  interests = array['Jewish topics', 'Jewish community']::text[]
where id = 'jewish-student-union' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students who want to help underprivileged kids get scholarships.',
  detailed_description = 'Kids Scholarship Fund gives underprivileged kids a scholarship for education. It meets on the first Wednesday of each month after school, from 3:10 to 4:10 p.m., in A302.',
  interests = array['Scholarships', 'Underprivileged kids', 'Education']::text[]
where id = 'kids-scholarship-fund' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in community service and leadership.',
  detailed_description = 'Knots of Kindness brings people together to give back to the less fortunate by making tie knot blankets and donating them to shelters and hospitals. The group also offers a chance to meet new people, collaborate with important organizations, and develop leadership skills. It meets on the last Thursday of each month before school, from 7:40 to 8:10 a.m., in A211.',
  interests = array['Tie knot blankets', 'Donating to shelters/hospitals', 'Meeting new people', 'Collaborating with organizations', 'Leadership skills', 'Giving back to the less fortunate']::text[]
where id = 'knots-of-kindness' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in Latino/Hispanic culture.',
  detailed_description = 'Latino Student Union is a group where students from Latino or Hispanic origins can come together to celebrate Latino/Hispanic culture, learn and share experiences, and build a sense of community for all in attendance. The club explores Latino tradition, history, food, music, and the impact of Latinos on society and vice versa, while welcoming all students and providing a safe, welcoming, and comfortable environment where every student can feel seen and respected. Its purpose is to allow students to feel more connected, represented, and supported, and for many students whose families come from Latin American countries, it can be a place where they feel closer to their culture and heritage while navigating a new environment. It meets every first Wednesday of the month after school, from 3:10 to 4:10 p.m., in Ms. Brandy Office (for now).',
  interests = array['Latino/Hispanic culture', 'Tradition', 'History', 'Food', 'Music', 'Community building']::text[]
where id = 'latino-student-union' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students who want to make cards for children''s hospitals.',
  detailed_description = 'Letters of Love makes cards for children''s hospitals once a month. The cards are delivered to the hospitals to bring joy to the kids during tough times. It meets on the second Friday of every month before school, from 7:40 to 8:10 a.m., in C114.',
  interests = array['Cards', 'Children''s hospitals', 'Joy', 'Tough times']::text[]
where id = 'letters-of-love' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in Muslim community and interfaith dialogue.',
  detailed_description = 'Muslim Student Association (MSA) fosters a sense of unity among Muslims at Wayzata High School. It offers a safe space for Muslim students to explore and express their faith, promotes interfaith cooperation, and raises awareness of Islamic culture and values. Through discussions, debates, and informational meetings, it aims to contribute positively to society. It meets every Tuesday after school, from 3:10 to 4:10 p.m., mainly in A251, with occasional meetings in the 2nd floor forum.',
  interests = array['Unity among Muslims', 'Safe space for faith exploration', 'Interfaith cooperation', 'Islamic culture awareness', 'Discussions and debates', 'Informational meetings']::text[]
where id = 'muslim-student-association-msa' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in nursing.',
  detailed_description = 'Nurses of Tomorrow educates students on the vast nursing field through interactive activities, volunteering opportunities, recent news, and much more! It meets once a month, usually near the end of the month, after school from 3:10 to 4:10 p.m. in C114 (health wing).',
  interests = array['Nursing field', 'Interactive activities', 'Volunteering opportunities', 'Recent news']::text[]
where id = 'nurses-of-tomorrow' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in origami and community service.',
  detailed_description = 'Origami For Good is a youth-led 501(c)(3) nonprofit organization that makes origami and sends it to soldiers, youth, seniors, patients, and more to inspire creativity and appreciation for Japanese art and culture. It meets on the second Wednesday of the month after school, from 3:10 to 4:10 p.m., in A218.',
  interests = array['Origami', 'Japanese art & culture', 'Community service', 'Creativity', 'Giving to soldiers']::text[]
where id = 'origami-for-good' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students who want to help their community.',
  detailed_description = 'Wayzata Red Cross introduces the American Red Cross to the school and helps people in our vicinity with care packages, for example. It meets on the second Monday of each month after school, from 3:10 to 4:10 p.m., in C113.',
  interests = array['American Red Cross', 'care packages', 'helping people']::text[]
where id = 'wayzata-red-cross' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in civic engagement.',
  detailed_description = 'SPEC: Student Political Engagement Center promotes civic engagement in students through discussion and education. It meets bi-weekly on Wednesdays after school, from 3:10 to 4:10, in A413.',
  interests = array['Civic engagement', 'Discussion', 'Education']::text[]
where id = 'spec-student-political-engagement-center' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in sports media.',
  detailed_description = 'Sports Promotional Team is a group of sports photographers, videographers, graphic designers, and marketers for games and events throughout the school year. It meets most Thursdays before school, from 7:40 to 8:10 a.m., in E105, with frequency depending on how much information is needed.',
  interests = array['Sports photography', 'Sports videography', 'Graphic design', 'Marketing', 'Games', 'Events']::text[]
where id = 'sports-promotional-team' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in sports.',
  detailed_description = 'Sports Talk Group is a student-led interest group where students discuss professional sports, participate in sports-related discussions and activities, and connect with peers who share similar interests. The group strives to create a fun, respectful, and engaging environment for students interested in sports. It meets once or twice a month before school, from 7:40 to 8:10 a.m., in Room A444 (Mr. Larsen''s classroom).',
  interests = array['Professional sports', 'Sports discussions', 'Sports activities', 'Peer connection', 'Fun environment', 'Respectful environment']::text[]
where id = 'sports-talk-group' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students dealing with stress and anxiety.',
  detailed_description = 'Stress Management provides support and strategies for students dealing with stress and anxiety. It meets every other Wednesday before school, from 7:40 to 8:10 a.m., in C420.',
  interests = array['Support', 'Strategies', 'Stress', 'Anxiety']::text[]
where id = 'stress-management' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in fashion and design.',
  detailed_description = 'Sustainable Swag (SS) is a get-together for people who share a love for fashion and designing. They do fun crafts such as embroidery on old shirts, bleaching patterns onto cloth, and teach simple sewing techniques. Some items may be donated to shelters or other organizations. The goal is to repurpose old clothes into something you can wear again or to make them aesthetically appealing for others in need. It meets every Thursday after school, from 3:10 to 4:10 p.m., in A215, with some weeks free depending on the testing schedule and club member vote.',
  interests = array['Embroidery on old shirts', 'Bleaching patterns onto cloth', 'Simple sewing techniques', 'Repurposing old clothes', 'Fashion design']::text[]
where id = 'sustainable-swag-ss' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students new to business, entrepreneurship, and marketing.',
  detailed_description = 'The BizMark Exchange aims to inspire and educate students about business, entrepreneurship, and marketing through hands-on experiences, great speakers, and real-world case studies. It strives to make business accessible and exciting for everyone, especially those new to the field. The club meets on the first Monday of every month after school, from 3:10 to 4:10 p.m., in C409.',
  interests = array['Business', 'Entrepreneurship', 'Marketing', 'Hands-on experiences', 'Guest speakers', 'Real-world case studies']::text[]
where id = 'the-bizmark-exchange' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in step dancing.',
  detailed_description = 'The Elite Pressure Line is a step team. It meets after school, from 3:10 to 4:10 p.m., on Mondays and Thursdays, in C123 or B302.',
  interests = array['Step team']::text[]
where id = 'the-elite-pressure-line' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students who want to seek purpose or hope and develop a relationship with Jesus.',
  detailed_description = 'Trojan of God is a group where members speak about Jesus and for those who want to seek a purpose or hope, it is a club to develop a relationship with Jesus. It meets every Thursday after school, from 3:10 to 4:10 p.m., in C417.',
  interests = array['Jesus', 'Purpose', 'Hope', 'Relationship with Jesus']::text[]
where id = 'trojan-of-god' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students who want to stay informed about school news.',
  detailed_description = 'Trojan Tribune provides a digital newspaper for the students of Wayzata, shines a bright light on achievements that go unnoticed, and keeps everyone informed. It meets biweekly on Thursday mornings before school, from 7:40 to 8:10 a.m., in C218.',
  interests = array['Digital newspaper', 'Student achievements', 'Information sharing']::text[]
where id = 'trojan-tribune' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in mental health support.',
  detailed_description = 'WAVE is a mental health initiative that actively combats poor mental health among high schoolers. Instead of creating a campaign advocating for mental health awareness, it performs activities that are detoxing in response to stressful schoolwork, homework, and current events. It meets on the last Friday of every month after school, from 3:10 to 4:10 p.m., in C415.',
  interests = array['Mental health', 'Detox activities', 'Stress relief', 'Schoolwork', 'Homework', 'Current events']::text[]
where id = 'wave-wayzata-actively-valuing-empathy' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in engineering projects and science fair competitions.',
  detailed_description = 'Wayzata Inventors Group offers students the chance to design, build, and test innovative engineering projects in a collaborative, hands-on environment. Members tackle challenges ranging from structural design projects such as bridges and towers to more advanced experimental systems, developing strong problem-solving, creativity, and technical thinking skills. A central focus is guiding students through the development of official science-fair projects, supporting team formation based on shared interests, idea generation, research, prototyping, and testing, with structured mentorship to prepare for regional, state, and international competitions, including the International Science and Engineering Fair. The group aims to create a space where students pursue ambitious ideas, gain real project experience, and work toward producing high-quality, competition-ready research, meeting every Tuesday of the month after school from 3:10 to 4:10 p.m. in A315.',
  interests = array['Engineering projects', 'Structural design', 'Bridges and towers', 'Experimental systems', 'Science fair projects', 'Competition preparation']::text[]
where id = 'wayzata-inventors-group' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in investing.',
  detailed_description = 'Wayzata Investment Competition (WIC) was created to teach high schoolers basic investing skills, equipping them to become financially responsible adults. Students learn and test their skills in competition through the Wharton Investing Competition and the MN Stock Market Game. The group meets every other Friday after school, from 3:10 to 4:10 p.m., on the second floor forum.',
  interests = array['Investing', 'Financial responsibility', 'Wharton Investing Competition', 'MN Stock Market Game']::text[]
where id = 'wayzata-investment-competition-wic' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students who may be interested in pursuing real estate.',
  detailed_description = 'Wayzata Real Estate Team is a student-led organization founded with three peers, hosting weekly after-school sessions for students to learn about real estate. Through interactive activities, projects, simulations, and discussions, the team aims to make real estate informative and engaging for classmates who may be interested in pursuing a career in real estate. The group meets every Monday after school, from 3:10 to 4:10 p.m., in room C409.',
  interests = array['Real estate', 'Interactive activities', 'Projects', 'Simulations', 'Discussions']::text[]
where id = 'wayzata-real-estate-team' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in public speaking and career preparation.',
  detailed_description = 'Wayzata She Leads empowers young women to connect, build practical life-skills-from public speaking to self-market-and actively prepare for college and career success through engaging activities. It meets twice a month on Thursdays before school, from 7:40 to 8:10 a.m., in Room C121 (Ms. Hanley''s classroom).',
  interests = array['Public speaking', 'Self-market', 'Life skills', 'College preparation', 'Career success', 'Engaging activities']::text[]
where id = 'wayzata-she-leads' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in Christian Bible study.',
  detailed_description = 'We Have Spirit Bible Study reaches Christian students at Wayzata in a community and studies the Bible weekly. It meets every Tuesday morning before school, from 7:40 to 8:10 a.m., in A314.',
  interests = array['Christian students', 'Bible study', 'Community']::text[]
where id = 'we-have-spirit-bible-study' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in K-pop and Korean culture.',
  detailed_description = 'Wayzata K-Pop Group was started during Term 4 of the 2025-2026 school year by three dedicated students. It offers an inclusive, high-energy space at Wayzata High School for students to connect through K-pop, Korean culture, language practice, interactive team games, and choreography covers. The group plans to remain highly organized throughout the 2026-2027 school year to demonstrate consistency and passion to the WHS Activities Office for official sponsorship. It meets every Wednesday after school, from 3:10 to 4:10 p.m., in A119.',
  interests = array['K-pop', 'Korean culture', 'Korean language', 'Interactive team games', 'Choreography covers']::text[]
where id = 'wayzata-k-pop-group' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in government and civic leadership.',
  detailed_description = 'Women In Government empowers students to learn about government, public policy, and civic leadership while encouraging more young women and students to get involved in government. It meets once a week on Thursday after school, from 3:10 to 4:10 p.m., in A414.',
  interests = array['Government', 'Public policy', 'Civic leadership', 'Women in government', 'Student involvement']::text[]
where id = 'women-in-government' and category = 'Student-Led Group';

update clubs set
  target_audience = 'Students interested in medical careers.',
  detailed_description = 'Youth in Medicine sparks thought-provoking conversations about the medical field and its careers. It offers hands-on labs and demonstrations to engage students. The group meets on the first Wednesday of each month after school, from 3:10 to 4:10 p.m., in A219.',
  interests = array['Medical field', 'Healthcare careers', 'Hands-on labs', 'Demonstrations', 'Thought-provoking conversations']::text[]
where id = 'youth-in-medicine' and category = 'Student-Led Group';

commit;

-- Verify: expect 43 rows, all three fields populated, and the original 38 untouched.
select count(*) filter (where detailed_description is not null) as with_detail,
       count(*) filter (where target_audience is not null)      as with_audience,
       count(*) filter (where cardinality(interests) > 0)       as with_interests,
       count(*)                                                 as total
from clubs where category = 'Student-Led Group';

select count(*) as original_clubs_still_untouched from clubs
where category <> 'Student-Led Group';
