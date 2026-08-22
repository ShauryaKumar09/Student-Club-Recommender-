-- RLS regression tests. Run with: supabase test db --local
--
-- pgTAP was chosen over a node script because it can switch identity inside a
-- single transaction -- `set local role authenticated` plus a forged
-- request.jwt.claims is exactly what PostgREST does per request -- and then
-- roll the whole thing back. No throwaway project, no service-role key on
-- disk, and the assertions run against the same policies production would use.
--
-- Identities come from supabase/seed.sql:
--   11111111-...  student@usc.edu   student, member (not advisor) of key-club
--   22222222-...  advisor@usc.edu   'advisor' membership of key-club only
--   33333333-...  admin@usc.edu     admin app_role
--
-- Everything below runs inside one transaction that ends in ROLLBACK, so the
-- seeded database is unchanged afterwards.

begin;

create extension if not exists pgtap with schema extensions;

-- Snapshot the values the update tests compare against, so they do not depend
-- on literal text from the club directory.
create temp table orig_clubs as
  select id, description from public.clubs where id in ('chess-club', 'key-club');

-- The tests read this while acting as `authenticated`, which has no rights to
-- a temp table created by postgres unless granted.
grant select on orig_clubs to authenticated;

select plan(40);

-- =====================================================================
-- Acting as the student
-- =====================================================================
set local role authenticated;
set local request.jwt.claims to '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}';

-- 1. The headline negative: no self-promotion.
select throws_ok(
  $$ update public.profiles
       set role = 'admin'
     where id = '11111111-1111-1111-1111-111111111111' $$,
  '42501',
  null,
  'a student cannot change their own role'
);

-- 2. Membership is not authorship: the student belongs to key-club but is not
--    its advisor, so writing an announcement for it must be refused.
select throws_ok(
  $$ insert into public.announcements (club_id, author_id, title, body)
     values ('key-club', '11111111-1111-1111-1111-111111111111',
             'Cancelled', 'Posted by someone with no authority') $$,
  '42501',
  null,
  'a student cannot post an announcement for a club they do not advise'
);

-- 3. profiles is not a directory: a student sees exactly one row, their own.
select is(
  (select count(*)::int from public.profiles),
  1,
  'a student reads only their own profile row'
);

-- 4. audit_log has no INSERT policy for anyone.
select throws_ok(
  $$ insert into public.audit_log (actor_id, action)
     values ('11111111-1111-1111-1111-111111111111', 'forged.entry') $$,
  '42501',
  null,
  'a student cannot write to audit_log directly'
);

-- 5. ...but the security-definer entry point works and stamps the caller.
select isnt(
  (select public.log_audit_event('club.viewed', 'clubs', 'key-club',
                                 '{"source": "rls_test"}'::jsonb)),
  null,
  'log_audit_event() accepts a write from an authenticated caller'
);

-- 6. That row now exists, and the student still cannot see it.
select is(
  (select count(*)::int from public.audit_log),
  0,
  'a student reads zero rows from audit_log even after writing one'
);

-- =====================================================================
-- Acting as the advisor (advisor of key-club, nothing else)
-- =====================================================================
reset role;
set local role authenticated;
set local request.jwt.claims to '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}';

-- 7. The USING clause filters the row out, so this is a silent zero-row
--    update rather than an error. Postgres will not allow a data-modifying
--    CTE inside a subquery, so the check is on observable state: run the
--    update bare, then read the row back and show nothing moved.
update public.clubs
   set description = 'edited by someone who does not advise this club'
 where id = 'chess-club';

select is(
  (select description from public.clubs where id = 'chess-club'),
  (select description from orig_clubs where id = 'chess-club'),
  'an advisor cannot edit a club they do not advise'
);

-- 8. Positive control: the same statement against their own club lands.
update public.clubs
   set description = 'Updated by the Key Club advisor.'
 where id = 'key-club';

select is(
  (select description from public.clubs where id = 'key-club'),
  'Updated by the Key Club advisor.',
  'an advisor can edit the club they do advise'
);

-- 9. Roster visibility is scoped: their own key-club membership plus the
--    student's key-club membership, and nothing from chess-club.
select is(
  (select count(*)::int from public.memberships where club_id <> 'key-club'),
  0,
  'an advisor sees no memberships outside the club they advise'
);

-- =====================================================================
-- Acting as the admin
-- =====================================================================
reset role;
set local role authenticated;
set local request.jwt.claims to '{"sub": "33333333-3333-3333-3333-333333333333", "role": "authenticated"}';

-- 10. Role changes are an admin power -- this must not be refused.
select lives_ok(
  $$ update public.profiles
        set role = 'advisor'
      where id = '11111111-1111-1111-1111-111111111111' $$,
  'an admin can change another user''s role'
);

-- 11. And it stuck.
select is(
  (select role::text from public.profiles
    where id = '11111111-1111-1111-1111-111111111111'),
  'advisor',
  'the role the admin set is the role that persisted'
);

-- =====================================================================
-- Acting as an anonymous visitor
-- =====================================================================
reset role;
set local role anon;
set local request.jwt.claims to '{"role": "anon"}';

-- 12. First gate: anon was never granted SELECT on profiles.
select throws_ok(
  $$ select id from public.profiles $$,
  '42501',
  null,
  'anon has no SELECT privilege on profiles'
);

-- 13. Second gate, and the one that matters: even with the grant handed to
--     anon, RLS alone returns zero rows. This is what proves the policies --
--     not the grant table -- are doing the enforcing.
reset role;
grant select on public.profiles to anon;
set local role anon;
set local request.jwt.claims to '{"role": "anon"}';

select is(
  (select count(*)::int from public.profiles),
  0,
  'anon reads zero rows from profiles even when granted SELECT'
);

reset role;

-- =====================================================================
-- Provisioning (20260821000200)
-- =====================================================================
reset role;
set local role authenticated;
set local request.jwt.claims to '{"sub": "33333333-3333-3333-3333-333333333333", "role": "authenticated"}';

-- 14. Put the student back where they started, this time through the
--     function rather than a bare UPDATE.
select is(
  (select public.set_user_role('11111111-1111-1111-1111-111111111111'::uuid,
                               'student'::public.app_role)::text),
  'student',
  'an admin can set a role through set_user_role()'
);

-- 15. The write landed.
select is(
  (select role::text from public.profiles
    where id = '11111111-1111-1111-1111-111111111111'),
  'student',
  'set_user_role() actually changed the stored role'
);

-- 16. Three role changes have happened: the seed promoting the admin, the bare
--     UPDATE in test 10, and set_user_role() in test 14. All three are logged,
--     which is the point of the trigger -- a dashboard that PATCHes profiles
--     directly is recorded just as well as one that calls the function.
select is(
  (select count(*)::int from public.audit_log where action = 'profile.role_changed'),
  3,
  'every role change is audited, whichever path it took'
);

-- 17. The lockout guard. The seed now creates two admins -- admin@usc.edu and
--     the owner's address, which bootstrap_admins promotes on signup -- so the
--     test has to demote one first, otherwise there is no "last admin" to
--     protect and the guard is never exercised.
do $$
begin
  perform public.set_user_role('44444444-4444-4444-4444-444444444444'::uuid,
                               'student'::public.app_role);
end $$;

select throws_ok(
  $$ select public.set_user_role('33333333-3333-3333-3333-333333333333'::uuid,
                                 'student'::public.app_role) $$,
  'P0001',
  'cannot demote the last remaining admin',
  'set_user_role() refuses to demote the last admin'
);

-- Acting as the student again -------------------------------------------
reset role;
set local role authenticated;
set local request.jwt.claims to '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}';

-- 18. The admin-only gate holds when called by a non-admin.
select throws_ok(
  $$ select public.set_user_role('22222222-2222-2222-2222-222222222222'::uuid,
                                 'admin'::public.app_role) $$,
  '42501',
  'only an admin may change a role',
  'a student cannot call set_user_role()'
);

-- 19. Self-service joining -- impossible before this migration, because
--     memberships has no INSERT policy for ordinary members.
select isnt(
  (select public.join_club('science-olympiad')),
  null,
  'a student can join a club themselves'
);

-- 20. And it is a member row, never an advisor row.
select is(
  (select role::text from public.memberships
    where user_id = '11111111-1111-1111-1111-111111111111'
      and club_id = 'science-olympiad'),
  'member',
  'join_club() can only ever create a member, not an advisor'
);

-- 21. Leaving works too, and only touches the caller's own row.
--     The call has to be its own statement: a function that writes cannot be
--     read back inside the same SELECT, which still sees the statement-start
--     snapshot. DO ... PERFORM keeps it silent so pg_prove reads clean TAP.
do $$ begin perform public.leave_club('science-olympiad'); end $$;

select is(
  (select count(*)::int from public.memberships
    where user_id = '11111111-1111-1111-1111-111111111111'
      and club_id = 'science-olympiad'),
  0,
  'leave_club() removes the caller''s own membership'
);

-- Acting as the advisor --------------------------------------------------
reset role;
set local role authenticated;
set local request.jwt.claims to '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}';

-- 22. Appointment authority is per-club, same as every other advisor power.
select throws_ok(
  $$ select public.grant_club_advisor('11111111-1111-1111-1111-111111111111'::uuid,
                                      'chess-club') $$,
  '42501',
  'not authorised to appoint advisors for chess-club',
  'an advisor cannot appoint advisors for a club they do not advise'
);

-- Acting as the admin ----------------------------------------------------
reset role;
set local role authenticated;
set local request.jwt.claims to '{"sub": "33333333-3333-3333-3333-333333333333", "role": "authenticated"}';

-- 23. The bootstrap path: the student already holds a member row for
--     chess-club, so this upgrades it in place rather than duplicating.
do $$
begin
  perform public.grant_club_advisor('11111111-1111-1111-1111-111111111111'::uuid,
                                    'chess-club');
end $$;

select is(
  (select m.role::text
     from public.memberships m
    where m.user_id = '11111111-1111-1111-1111-111111111111'
      and m.club_id = 'chess-club'),
  'advisor',
  'an admin can appoint a club advisor'
);

-- 24. Revoking demotes rather than deletes -- losing advisor rights should not
--     quietly drop someone off the roster.
do $$
begin
  perform public.revoke_club_advisor('11111111-1111-1111-1111-111111111111'::uuid,
                                     'chess-club');
end $$;

select is(
  (select m.role::text
     from public.memberships m
    where m.user_id = '11111111-1111-1111-1111-111111111111'
      and m.club_id = 'chess-club'),
  'member',
  'revoke_club_advisor() demotes to member and keeps the roster row'
);

reset role;

-- =====================================================================
-- Dashboard tables (20260822000000)
-- =====================================================================
reset role;
set local role authenticated;
set local request.jwt.claims to '{"sub": "33333333-3333-3333-3333-333333333333", "role": "authenticated"}';

-- Setup: give the advisor authority over Science Olympiad, which is the club
-- the seeded join request points at.
do $$
begin
  perform public.grant_club_advisor('22222222-2222-2222-2222-222222222222'::uuid,
                                    'science-olympiad');
end $$;

reset role;
set local role authenticated;
set local request.jwt.claims to '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}';

-- 25. A student can ask to join a club they are not in.
select isnt(
  (select public.request_to_join_club('art-club', 'Interested in the spring show.')),
  null,
  'a student can raise a join request'
);

-- 26. But only ever on their own behalf.
select throws_ok(
  $$ insert into public.join_requests (user_id, club_id)
     values ('22222222-2222-2222-2222-222222222222', 'art-club') $$,
  '42501',
  null,
  'a student cannot raise a join request in someone else''s name'
);

-- 27. And cannot rule on their own request.
select throws_ok(
  $$ select public.decide_join_request(
       (select id from public.join_requests
         where user_id = '11111111-1111-1111-1111-111111111111'
           and club_id = 'science-olympiad'), true) $$,
  '42501',
  null,
  'a student cannot approve their own join request'
);

-- 28. The advisor of that club can.
reset role;
set local role authenticated;
set local request.jwt.claims to '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}';

do $$
declare
  req uuid;
begin
  select id into req from public.join_requests
   where user_id = '11111111-1111-1111-1111-111111111111'
     and club_id = 'science-olympiad'
     and status = 'pending';
  perform public.decide_join_request(req, true);
end $$;

select is(
  (select status::text from public.join_requests
    where user_id = '11111111-1111-1111-1111-111111111111'
      and club_id = 'science-olympiad'),
  'approved',
  'an advisor can approve a join request for their club'
);

-- 29. Approving is what actually creates the membership.
select is(
  (select count(*)::int from public.memberships
    where user_id = '11111111-1111-1111-1111-111111111111'
      and club_id = 'science-olympiad'),
  1,
  'approving a request grants the membership'
);

-- 30. The student is told, rather than finding out by chance.
reset role;
set local role authenticated;
set local request.jwt.claims to '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}';

select is(
  (select count(*)::int from public.notifications
    where user_id = '11111111-1111-1111-1111-111111111111'
      and title like '%Science Olympiad%'),
  1,
  'approving a request notifies the student'
);

-- 31. Notifications are readable, never writable -- no INSERT policy exists,
--     so only notify_user() can create them.
select throws_ok(
  $$ insert into public.notifications (user_id, title)
     values ('11111111-1111-1111-1111-111111111111', 'Fake notification') $$,
  '42501',
  null,
  'a student cannot write their own notifications'
);

-- 32. Club submissions are an admin decision.
select throws_ok(
  $$ select public.decide_club_submission(
       (select id from public.club_submissions where name = 'Rocketry Club'), true, null) $$,
  '42501',
  'only an admin may decide club submissions',
  'a student cannot approve a club submission'
);

-- 33. An admin approving one creates the real directory row.
reset role;
set local role authenticated;
set local request.jwt.claims to '{"sub": "33333333-3333-3333-3333-333333333333", "role": "authenticated"}';

do $$
begin
  perform public.decide_club_submission(
    (select id from public.club_submissions where name = 'Rocketry Club'), true, null);
end $$;

select is(
  (select name from public.clubs where id = 'rocketry-club'),
  'Rocketry Club',
  'approving a submission creates the club in the directory'
);

-- 34/35. The bug form works signed out, but the queue is not readable that way.
reset role;
set local role anon;
set local request.jwt.claims to '{"role": "anon"}';

select lives_ok(
  $$ insert into public.bug_reports (body, page, severity)
     values ('Filed while signed out.', 'browse', 'low') $$,
  'an anonymous visitor can file a bug report'
);

select throws_ok(
  $$ select id from public.bug_reports $$,
  '42501',
  null,
  'an anonymous visitor cannot read the bug queue'
);

-- 36. The admin sees every report, including the anonymous one.
reset role;
set local role authenticated;
set local request.jwt.claims to '{"sub": "33333333-3333-3333-3333-333333333333", "role": "authenticated"}';

select is(
  (select count(*)::int from public.bug_reports),
  4,
  'an admin reads the whole bug queue'
);

reset role;

-- =====================================================================
-- Advisor visibility of the people in their club (20260822000200)
-- =====================================================================
reset role;
set local role authenticated;
set local request.jwt.claims to '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}';

-- 37. An advisor can read the profile of someone on their roster. Without
--     this the Members panel and request queue show every student as
--     "Unknown", because profiles was self-and-admin only.
select is(
  (select count(*)::int from public.profiles where email = 'student@usc.edu'),
  1,
  'an advisor can read the profile of a student in their club'
);

-- 38. ...and only those people. The admin holds no membership in any club this
--     advisor runs, so their profile stays invisible -- the policy grants a
--     roster, not the directory.
select is(
  (select count(*)::int from public.profiles where email = 'admin@usc.edu'),
  0,
  'an advisor cannot read the profile of someone outside their clubs'
);

reset role;

-- =====================================================================
-- Signup controls (20260822000300)
-- =====================================================================
reset role;

-- 39. Only an admin may see or change who is allowed to sign up, and who is
--     handed an admin account on first login. A student reading these tables
--     gets nothing rather than a list of the administrators.
set local role authenticated;
set local request.jwt.claims to '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}';

select is(
  (select count(*)::int from public.bootstrap_admins)
  + (select count(*)::int from public.allowed_signup_domains),
  0,
  'a student cannot read the signup allow-list or the admin bootstrap list'
);

-- 40. The admin can.
reset role;
set local role authenticated;
set local request.jwt.claims to '{"sub": "33333333-3333-3333-3333-333333333333", "role": "authenticated"}';

select isnt(
  (select count(*)::int from public.allowed_signup_domains),
  0,
  'an admin can read the signup allow-list'
);

reset role;

select * from finish();

rollback;
