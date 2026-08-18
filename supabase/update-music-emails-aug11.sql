-- Contact emails for the three curricular music programs, 2026-08-11.
-- The music department's statement tells students to "contact the appropriate
-- teacher", which only works if the listing names one. One address per
-- program, supplied by the department.
-- Already applied to production via the REST API.

update clubs set email = 'daniel.tewalt@wayzataschools.org'      where id = 'band';
update clubs set email = 'eliza.lewisoconnor@wayzataschools.org' where id = 'choirs';
update clubs set email = 'mark.gitch@wayzataschools.org'         where id = 'orchestras';
