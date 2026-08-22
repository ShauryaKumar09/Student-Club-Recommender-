repo: ShauryaKumar09/Student-Club-Recommender-
branch: main

## Last sync
date: 2026-08-21T03:05:00Z

### Updated in this project
- Imported `index.html` (the TrojanMatch site), `assets/`, and `uploads/clubs.json`.
- Built the student and advisor dashboards, then merged them into `index.html` itself: a "My dashboard" button in the site header opens a sign-in with role picker, and the dashboard renders as a fourth view alongside landing / browse / quiz.
- Dashboard state lives under one `dash` key; all dashboard template values are namespaced `dash.*`, so nothing collides with the existing app.
- Added the admin panel to `index.html`: club approvals, all-clubs table (real directory data, archive/restore), users and roles, bug-report queue, categories and tag counts, audit log.
- `TrojanMatch Dashboards.dc.html` holds the standalone student + advisor design file; the admin panel exists only in `index.html`.

## Screen map
| Screen | Built from |
| --- | --- |
| Site header, landing, browse, quiz, FAQ, modals | index.html (unchanged) |
| Dashboard sign-in (role picker) | index.html header lockup + assets/whs-fog.jpg |
| Student — My clubs, This week, Matches, Requests, Notifications | index.html browse cards + tag system; uploads/clubs.json |
| Student club page (Home / Resources / Calendar / Members / Announcements) | index.html club modal fields |
| Advisor — Overview, Club information, Club page builder, Members, Requests | index.html form patterns (club submission modal) + clubs.json fields |
| Admin — Overview, Club approvals, All clubs, Users and roles, Bug reports, Categories and tags, Audit log | live `state.clubs` (Supabase / uploads/clubs.json) for the club table, categories, and tag counts; index.html bug-report and club-submission modals for the queues |
