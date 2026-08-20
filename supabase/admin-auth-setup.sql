-- Advisor / admin editing for TrojanMatch.  RUN THIS ONCE, BY HAND, in the
-- Supabase SQL editor (Dashboard -> SQL Editor -> New query -> paste -> Run).
-- It cannot be applied over the REST API, because that API cannot run DDL.
--
-- What it sets up:
--   admins        - who may edit anything and add clubs
--   club_editors  - which email may edit which single club
--   policies on clubs so an advisor can update THEIR row and nobody else's
--   a trigger so an advisor cannot change the fields that drive matching
--
-- Read before running. This is the file that decides who can change the live
-- site, and a mistake here is not visible from the app.

-- ---------------------------------------------------------------------------
-- 1. Who is who
-- ---------------------------------------------------------------------------

create table if not exists public.admins (
  email      text primary key,
  note       text,
  created_at timestamptz not null default now()
);

create table if not exists public.club_editors (
  club_id    text not null references public.clubs(id) on delete cascade,
  email      text not null,
  created_at timestamptz not null default now(),
  primary key (club_id, email)
);

create index if not exists club_editors_email_idx on public.club_editors (email);

-- Emails are stored and compared lowercased. Sign-in addresses are not case
-- sensitive, so anything else lets the same person be an editor and not an
-- editor depending on how they typed it.
alter table public.admins       add constraint admins_email_lower       check (email = lower(email)) not valid;
alter table public.club_editors add constraint club_editors_email_lower check (email = lower(email)) not valid;

-- ---------------------------------------------------------------------------
-- 2. Helpers
-- ---------------------------------------------------------------------------

-- The signed-in user's email, lowercased, or '' when nobody is signed in.
--
-- THE THREAT THIS ANSWERS. Everything here keys off an email address, so the
-- obvious attack is to sign up AS an advisor: type timothy.masters@... into the
-- create-account form, pick your own password, and inherit his club. What stops
-- that is that Supabase will not issue a session until the address has been
-- confirmed by clicking a link sent TO that address. The attacker can create
-- the account; they cannot open the inbox, so they can never sign in to it.
-- Possession of the mailbox is the proof of identity, which is the same thing
-- every "reset your password" flow on the internet relies on.
--
-- That protection lives in one dashboard toggle (Authentication -> Providers ->
-- Email -> Confirm email). If someone ever turns it off, unconfirmed accounts
-- would start receiving sessions and the attack opens back up. So the check is
-- repeated here, where it cannot be switched off by accident: an identity whose
-- token explicitly says the email is NOT verified resolves to '' and matches no
-- row in admins or club_editors.
--
-- A missing claim is treated as verified rather than not, deliberately. Older
-- tokens do not carry it, and the failure mode of the strict reading is that
-- every advisor silently loses access at once -- worse than leaning on the
-- GoTrue setting that is, in fact, on.
create or replace function public.current_email() returns text
language sql stable
as $$
  select case
    when (auth.jwt() -> 'user_metadata' ->> 'email_verified') = 'false' then ''
    else lower(coalesce(auth.jwt() ->> 'email', ''))
  end
$$;

-- SECURITY DEFINER on purpose: the admins table has RLS of its own, and a
-- policy that reads it would otherwise recurse. Locked to the public schema so
-- it cannot be pointed at a different table by a search_path trick.
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.admins a where a.email = public.current_email()) $$;

create or replace function public.may_edit_club(target text) returns boolean
language sql stable security definer set search_path = public
as $$
  select public.is_admin()
      or exists (select 1 from public.club_editors e
                 where e.club_id = target and e.email = public.current_email())
$$;

-- ---------------------------------------------------------------------------
-- 3. Row level security
-- ---------------------------------------------------------------------------

alter table public.admins       enable row level security;
alter table public.club_editors enable row level security;
alter table public.clubs        enable row level security;

-- Nobody reads the admin list except an admin. It is a list of people worth
-- phishing, and the app never needs to show it to anyone else.
drop policy if exists admins_read on public.admins;
create policy admins_read on public.admins
  for select to authenticated using (public.is_admin());

drop policy if exists admins_write on public.admins;
create policy admins_write on public.admins
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- An advisor may see their own assignment (that is how the app knows which
-- club to open). An admin sees all of them.
drop policy if exists club_editors_read on public.club_editors;
create policy club_editors_read on public.club_editors
  for select to authenticated
  using (email = public.current_email() or public.is_admin());

drop policy if exists club_editors_write on public.club_editors;
create policy club_editors_write on public.club_editors
  for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- The public site keeps reading the table with the publishable key. This
-- policy is what the live site has always run on; it is restated here so this
-- file describes the whole picture rather than half of it.
drop policy if exists clubs_public_read on public.clubs;
create policy clubs_public_read on public.clubs
  for select to anon, authenticated using (true);

-- An advisor updates exactly one row: theirs. USING decides which rows they may
-- touch; WITH CHECK decides what the row is allowed to look like afterwards.
-- Both are needed -- without WITH CHECK an advisor could change their club's id
-- to another club's id and edit that one instead.
drop policy if exists clubs_editor_update on public.clubs;
create policy clubs_editor_update on public.clubs
  for update to authenticated
  using (public.may_edit_club(id))
  with check (public.may_edit_club(id));

-- Adding and removing clubs is an admin job.
drop policy if exists clubs_admin_insert on public.clubs;
create policy clubs_admin_insert on public.clubs
  for insert to authenticated with check (public.is_admin());

drop policy if exists clubs_admin_delete on public.clubs;
create policy clubs_admin_delete on public.clubs
  for delete to authenticated using (public.is_admin());

-- RLS decides which rows. These grants decide whether the role may attempt the
-- verb at all; without them every write fails with a permission error before a
-- policy is ever consulted.
grant select on public.clubs to anon, authenticated;
grant insert, update, delete on public.clubs to authenticated;
grant select, insert, update, delete on public.admins, public.club_editors to authenticated;

-- ---------------------------------------------------------------------------
-- 4. What an advisor may NOT change
-- ---------------------------------------------------------------------------
-- Column privileges are granted per role, and every signed-in person is the
-- same role, so they cannot separate an advisor from an admin. A trigger can.
--
-- scores is the matching vector: it decides where the club ranks in the quiz.
-- An advisor editing their own scores is an advisor ranking their own club.
-- id, category, is_student_led and photos change how the club is filed and are
-- admin decisions for the same reason.

create or replace function public.clubs_guard_protected_columns()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if public.is_admin() then
    return new;
  end if;
  if new.id is distinct from old.id then
    raise exception 'Only an admin can change a club id';
  end if;
  if new.scores is distinct from old.scores then
    raise exception 'Only an admin can change the matching scores';
  end if;
  if new.category is distinct from old.category then
    raise exception 'Only an admin can change the category';
  end if;
  if new.is_student_led is distinct from old.is_student_led then
    raise exception 'Only an admin can change whether this is a student-organized group';
  end if;
  if new.photos is distinct from old.photos then
    raise exception 'Only an admin can change the photos';
  end if;
  return new;
end $$;

drop trigger if exists clubs_guard_protected_columns on public.clubs;
create trigger clubs_guard_protected_columns
  before update on public.clubs
  for each row execute function public.clubs_guard_protected_columns();

-- ---------------------------------------------------------------------------
-- 5. Seed
-- ---------------------------------------------------------------------------

-- Admins. Add Shaurya by pasting his address in the same shape -- it was not
-- known when this file was written, so it is deliberately absent rather than
-- guessed.
insert into public.admins (email, note) values
  ('menonnay000@isd284.com', 'Nayan Menon, school account')
on conflict (email) do nothing;

-- Shaurya goes here. Left out rather than guessed -- his address was not known
-- when this was written, and an admin row is not something to approximate.
-- insert into public.admins (email, note) values
--   ('...', 'Shaurya Kumar') on conflict (email) do nothing;

-- nayanmenon.2009@gmail.com is deliberately NOT an admin. It is set up below as
-- an ordinary advisor on two clubs, so the advisor side can be checked from the
-- outside: an admin sees all 86 clubs and would never notice a scoping bug.
-- Move it into the block above whenever that test is done with.

-- Advisors, taken from the club rows themselves rather than a hand-written
-- list, so this stays true as the data changes. Staff addresses ONLY: the
-- email column also holds student leaders' @isd284.com addresses, and edit
-- rights over live club data are not a student's to have by default. An admin
-- can add any of them by hand afterwards.
insert into public.club_editors (club_id, email)
select c.id, lower(trim(e))
from public.clubs c,
     lateral unnest(string_to_array(coalesce(c.email, ''), ',')) as e
where lower(trim(e)) like '%@wayzataschools.org'
on conflict do nothing;

-- A worked example, and the advisor-side test: this address can edit exactly two
-- clubs and nothing else. Signing in with it should show BPA and DECA and no
-- third club, and a save against any other club should be refused by the policy
-- even if the request is made by hand.
insert into public.club_editors (club_id, email) values
  ('business-professionals-of-america', 'nayanmenon.2009@gmail.com'),
  ('deca',                              'nayanmenon.2009@gmail.com')
on conflict do nothing;

-- ---------------------------------------------------------------------------
-- 6. Check it did what you think
-- ---------------------------------------------------------------------------
-- select count(*) from public.club_editors;                  -- clubs now claimable
-- select * from public.admins;
-- select c.id from public.clubs c
--   where not exists (select 1 from public.club_editors e where e.club_id = c.id);
--                                                            -- clubs with no editor yet
