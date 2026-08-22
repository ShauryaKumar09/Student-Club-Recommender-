-- A student's saved shortlist.
--
-- Saving is not joining. Membership means an advisor put you on the roster;
-- saving is a private bookmark that nobody else can see. They were previously
-- the same list in the UI, which meant the dashboard could not tell "clubs I am
-- in" from "clubs I am considering".
--
-- Composite primary key rather than a surrogate id: a person either has a club
-- saved or they do not, and the pair is the natural identity.
-- Generated 2026-08-22.

create table if not exists public.saved_clubs (
  user_id    uuid not null references public.profiles (id) on delete cascade,
  club_id    text not null references public.clubs (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, club_id)
);

create index if not exists saved_clubs_user_idx
  on public.saved_clubs (user_id, created_at desc);

grant select, insert, delete on public.saved_clubs to authenticated;

alter table public.saved_clubs enable row level security;

-- A shortlist is private. There is no advisor or admin read policy here on
-- purpose: what a student is considering is nobody else's business.
drop policy if exists "users read their own saved clubs" on public.saved_clubs;
create policy "users read their own saved clubs"
  on public.saved_clubs for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists "users save clubs for themselves" on public.saved_clubs;
create policy "users save clubs for themselves"
  on public.saved_clubs for insert to authenticated
  with check (user_id = (select auth.uid()));

drop policy if exists "users unsave their own clubs" on public.saved_clubs;
create policy "users unsave their own clubs"
  on public.saved_clubs for delete to authenticated
  using (user_id = (select auth.uid()));
