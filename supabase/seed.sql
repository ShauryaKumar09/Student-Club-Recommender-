-- Local development seed. Runs after seed_clubs.sql on every `supabase db reset`.
--
-- LOCAL ONLY. It writes directly into auth.users with a known password and is
-- never intended for any hosted project.
--
-- Runs as `postgres`, which bypasses RLS -- that is what lets it wire up an
-- admin and an advisor. The tests then re-enter as the `authenticated` role to
-- prove the policies actually bite.
--
-- Four accounts, all with password `password123`:
--   student@usc.edu         student, member of Key Club and Chess Club
--   advisor@usc.edu         student app_role, but 'advisor' membership of Key Club
--   admin@usc.edu           admin app_role, no memberships (admins pass every check)
--   kumarsha003@isd284.com  Shaurya's own account. Seeded so that a `db reset`
--                           -- needed on every new migration -- stops deleting
--                           it. Comes out as 'admin' because the address is in
--                           bootstrap_admins, the same way it will on the real
--                           site.
--
-- advisor@usc.edu keeps the default 'student' app_role on purpose: club
-- authority comes from the membership row, not the global role, and the tests
-- lean on that to prove an advisor of one club cannot touch another.
--
-- Clubs come from seed_clubs.sql (the real 86-club directory); the ids used
-- below are all real slugs from it.
-- Generated 2026-08-22.

begin;

-- ---------------------------------------------------------- signup rules ---
-- 20260822000300 restricts signups to the school's real domains. The test
-- accounts below are @usc.edu, so the local stack allows that domain too.
-- Production never runs this file, so usc.edu is never accepted there.
insert into public.allowed_signup_domains (domain, note) values
  ('usc.edu', 'LOCAL ONLY - the seeded test accounts')
on conflict (domain) do nothing;

-- ------------------------------------------------------------------ users --
-- The on_auth_user_created trigger fires here and creates the profiles rows,
-- every one of them as 'student'. Roles are promoted further down.

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  (
    '00000000-0000-0000-0000-000000000000',
    '11111111-1111-1111-1111-111111111111',
    'authenticated', 'authenticated', 'student@usc.edu',
    extensions.crypt('password123', extensions.gen_salt('bf')), now(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"full_name": "Sam Student"}'::jsonb, now(), now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '22222222-2222-2222-2222-222222222222',
    'authenticated', 'authenticated', 'advisor@usc.edu',
    extensions.crypt('password123', extensions.gen_salt('bf')), now(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"full_name": "Alex Advisor"}'::jsonb, now(), now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '33333333-3333-3333-3333-333333333333',
    'authenticated', 'authenticated', 'admin@usc.edu',
    extensions.crypt('password123', extensions.gen_salt('bf')), now(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"full_name": "Avery Admin"}'::jsonb, now(), now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '44444444-4444-4444-4444-444444444444',
    'authenticated', 'authenticated', 'kumarsha003@isd284.com',
    extensions.crypt('password123', extensions.gen_salt('bf')), now(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"full_name": "Shaurya Kumar"}'::jsonb, now(), now()
  )
on conflict (id) do nothing;

-- GoTrue scans these columns into Go strings, not pointers, so a NULL here
-- makes every sign-in fail with "Database error querying schema" -- a 500 that
-- names none of these columns. The dashboard writes '' rather than NULL; a
-- hand-written seed has to do the same.
update auth.users set
  confirmation_token         = coalesce(confirmation_token, ''),
  recovery_token             = coalesce(recovery_token, ''),
  email_change               = coalesce(email_change, ''),
  email_change_token_new     = coalesce(email_change_token_new, ''),
  email_change_token_current = coalesce(email_change_token_current, ''),
  phone_change               = coalesce(phone_change, ''),
  phone_change_token         = coalesce(phone_change_token, ''),
  reauthentication_token     = coalesce(reauthentication_token, '')
where email in ('student@usc.edu', 'advisor@usc.edu', 'admin@usc.edu',
                'kumarsha003@isd284.com');

-- Without an identities row, GoTrue will not accept an email/password sign-in.
insert into auth.identities (
  id, user_id, provider_id, identity_data, provider,
  last_sign_in_at, created_at, updated_at
)
select
  gen_random_uuid(), u.id, u.id::text,
  jsonb_build_object('sub', u.id::text, 'email', u.email, 'email_verified', true),
  'email', now(), now(), now()
from auth.users u
where u.email in ('student@usc.edu', 'advisor@usc.edu', 'admin@usc.edu',
                  'kumarsha003@isd284.com')
on conflict do nothing;

-- Only the admin is promoted. Signup never grants a role above 'student'.
update public.profiles set role = 'admin'
where id = '33333333-3333-3333-3333-333333333333';

-- ------------------------------------------------------------ memberships --

insert into public.memberships (user_id, club_id, role) values
  ('11111111-1111-1111-1111-111111111111', 'key-club',   'member'),
  ('11111111-1111-1111-1111-111111111111', 'chess-club', 'member'),
  ('22222222-2222-2222-2222-222222222222', 'key-club',   'advisor')
on conflict (user_id, club_id) do nothing;

-- --------------------------------------------------------------- content ---

insert into public.announcements (club_id, author_id, title, body, pinned) values
  (
    'key-club', '22222222-2222-2222-2222-222222222222',
    'Fall service fair sign-ups are open',
    'Bring a permission slip to the next meeting to claim a Saturday slot.',
    true
  ),
  (
    'key-club', '22222222-2222-2222-2222-222222222222',
    'Officer elections move to October',
    'Nominations stay open until the first Tuesday of October.',
    false
  ),
  (
    'chess-club', null,
    'Ladder resets this week',
    'Everyone starts the season unrated; first four games set your placement.',
    false
  );

insert into public.events (club_id, title, description, location, starts_at, ends_at) values
  (
    'key-club', 'Service fair volunteer shift',
    'Two-hour shift staffing the community table.',
    'Commons', '2026-09-12 15:30:00-05', '2026-09-12 17:30:00-05'
  ),
  (
    'key-club', 'Monthly chapter meeting',
    'Officer reports, then service project sign-ups.',
    'A211', '2026-09-22 07:40:00-05', '2026-09-22 08:10:00-05'
  ),
  (
    'chess-club', 'Season opener ladder night',
    'Four rated games, clocks provided.',
    'Media Center', '2026-09-10 15:10:00-05', '2026-09-10 16:30:00-05'
  ),
  (
    'science-olympiad', 'Event assignment meeting',
    'Pick your two competition events for the season.',
    'C210', '2026-09-09 15:15:00-05', '2026-09-09 16:15:00-05'
  );

insert into public.resources (club_id, title, url, kind) values
  ('key-club',        'Volunteer hours log',    'https://example.org/key-club/hours',      'form'),
  ('key-club',        'Club constitution',      'https://example.org/key-club/bylaws.pdf', 'document'),
  ('key-club',        'Service project ideas',  'https://example.org/key-club/ideas',      'link'),
  ('chess-club',      'Opening study playlist', 'https://example.org/chess/openings',      'link'),
  ('science-olympiad','Event rules manual',     'https://example.org/scioly/rules.pdf',    'document');

-- --------------------------------------------------- dashboard queue data ---

-- One pending request from the student, so the advisor's Requests panel and
-- the student's own Requests panel both have something real to show.
insert into public.join_requests (user_id, club_id, status, message) values
  (
    '11111111-1111-1111-1111-111111111111', 'science-olympiad', 'pending',
    'I did Science Olympiad in middle school and would like to compete in Anatomy.'
  )
on conflict do nothing;

insert into public.notifications (user_id, title, body, kind, read) values
  (
    '11111111-1111-1111-1111-111111111111',
    'Welcome to TrojanMatch',
    'Take the quiz to get club matches picked for your interests.',
    'info', true
  ),
  (
    '11111111-1111-1111-1111-111111111111',
    'Fall service fair sign-ups are open',
    'Key Club posted a new announcement.',
    'info', false
  ),
  (
    '22222222-2222-2222-2222-222222222222',
    'New request to join Key Club',
    'A student asked to join. Review it in Requests.',
    'info', false
  );

insert into public.club_submissions (
  submitted_by, name, category, club_type, advisor_name, advisor_email,
  meeting_days, meeting_time, meeting_location, description, target_audience, interests
) values
  (
    '11111111-1111-1111-1111-111111111111',
    'Rocketry Club', 'CTE', 'Student Organized Group',
    'Clark Doten', 'clark.doten@wayzataschools.org',
    'Fridays', 'After school, 3:10-4:30 p.m.', 'C403',
    'Design, build, and launch model rockets, then compete at the state meet.',
    'Students interested in aerospace engineering and hands-on building.',
    array['Rocketry', 'Engineering', 'Competition']::text[]
  ),
  (
    '11111111-1111-1111-1111-111111111111',
    'Film Photography Club', 'Visual & Written Arts', 'Student Organized Group',
    'Kari Rohrich', 'kari.rohrich@wayzataschools.org',
    'Wednesdays', 'Before school, 7:40-8:10 a.m.', 'B120',
    'Shoot 35mm, develop in the darkroom, and put on a print show each spring.',
    'Anyone curious about analog photography. No camera required to start.',
    array['Photography', 'Darkroom', 'Visual arts']::text[]
  );

insert into public.bug_reports (reporter_id, email, body, page, severity, status) values
  (
    '11111111-1111-1111-1111-111111111111', 'student@usc.edu',
    'The quiz results page scrolls back to the top every time I open a club.',
    'quiz', 'medium', 'new'
  ),
  (
    null, 'anonymous@wayzataschools.org',
    'Chess Club photo is sideways on the browse card.',
    'browse', 'low', 'triaged'
  ),
  (
    null, null,
    'Sign in button does nothing on iPhone Safari.',
    'login', 'high', 'new'
  );

commit;
