-- DECA and BPA moved from CTE to Academic Competition, 2026-08-11, per the
-- site owner. Both are competition-first organisations, and the browse
-- grouping now says so.
--
-- Note their academic_competition score is still 2, below the >= 3 relevance
-- gate in scoreClubs. The browse category and the quiz therefore disagree
-- until that score is raised -- see the discussion attached to this change.
-- Already applied to production via the REST API.

update clubs set category = 'Academic Competition' where id = 'deca';
update clubs set category = 'Academic Competition' where id = 'business-professionals-of-america';
