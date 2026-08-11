-- Two corrections, 2026-08-11.
--
-- 1. Girls Learn International: "Thrusday" -> "Thursday".
--
-- 2. Band, Choirs and Orchestras carry the statement the music department
--    asked for, verbatim. Their point: these are curricular entities, not
--    clubs, and the co-curricular groups attached to them are drawn almost
--    entirely from students already enrolled in the classes -- so a club-style
--    listing promises a sign-up that does not exist and creates confusion
--    rather than clarity. The frontend gives the three of them a separate
--    "Curricular Program" tag with an explanation behind it.
--
-- Already applied to production via the REST API.


update clubs set
  meeting_days = 'Second Thursday of each month'
where id = 'girls-learn-international';

update clubs set
  description = 'A curricular program and one of the largest high school band programs in the state, with about 400 students taking part every year. Students join by enrolling in a band class or auditioning for an ensemble.',
  detailed_description = 'Band is a curricular program at Wayzata and one of the largest high school band programs in the state, with about 400 students taking part every year. There are two ways in: enroll in a band class, or audition for an ensemble. Season length, rehearsal schedules and meeting times all vary by group. Most ensembles perform about four concerts a year, and some also play at athletic events.

Students interested in joining band, choir, or orchestra should contact the appropriate teacher for more information. If you are unsure who to contact, you can ask any music teacher or your counselor for the appropriate contact information. For students not enrolled in band, choir, or orchestra, limited opportunities to participate in our co-curricular music groups will be communicated through the student newsletter.',
  target_audience = 'Instrumentalists of any experience level. Participation runs through enrolling in a music class rather than signing up for a club.'
where id = 'band';

update clubs set
  description = 'A curricular program offering multiple vocal ensembles that range in style and skill level. Students join by enrolling in a choir class.',
  detailed_description = 'Choirs is a curricular program at Wayzata offering multiple vocal ensembles for students who want to sing, ranging in style and skill level. Students join by enrolling in a choir class.

Students interested in joining band, choir, or orchestra should contact the appropriate teacher for more information. If you are unsure who to contact, you can ask any music teacher or your counselor for the appropriate contact information. For students not enrolled in band, choir, or orchestra, limited opportunities to participate in our co-curricular music groups will be communicated through the student newsletter.',
  target_audience = 'Students who want to sing, at a range of experience levels. Participation runs through enrolling in a music class rather than signing up for a club.'
where id = 'choirs';

update clubs set
  description = 'A curricular program offering string and full-orchestra ensembles. Students join by enrolling in an orchestra class.',
  detailed_description = 'Orchestras is a curricular program at Wayzata offering string and full-orchestra ensembles for instrumentalists who want to perform classical and contemporary repertoire together. Students join by enrolling in an orchestra class.

Students interested in joining band, choir, or orchestra should contact the appropriate teacher for more information. If you are unsure who to contact, you can ask any music teacher or your counselor for the appropriate contact information. For students not enrolled in band, choir, or orchestra, limited opportunities to participate in our co-curricular music groups will be communicated through the student newsletter.',
  target_audience = 'String and orchestral players who want to perform in an ensemble. Participation runs through enrolling in a music class rather than signing up for a club.'
where id = 'orchestras';
