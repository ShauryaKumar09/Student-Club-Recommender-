-- Who may create an account, and who may administer.
--
-- Two small tables rather than hard-coded lists, so both can be changed from
-- the admin panel or a single SQL line without shipping a migration.
--
--   allowed_signup_domains  an account can only be created with an email in
--                           one of these domains. Empty table = no restriction
--                           (that is what the local stack relies on).
--   bootstrap_admins        emails that become 'admin' the moment they sign
--                           up, so the very first administrator does not have
--                           to be promoted by hand.
--
-- IMPORTANT about bootstrap_admins: it trusts the email address on the signup.
-- That is only safe while email confirmation is ON in the Supabase dashboard.
-- With confirmation off, anyone could sign up claiming one of these addresses
-- and be handed an admin account. Do not deploy this to production with
-- confirmations disabled.
-- Generated 2026-08-22.

create table if not exists public.allowed_signup_domains (
  domain     text primary key,
  note       text,
  created_at timestamptz not null default now()
);

create table if not exists public.bootstrap_admins (
  email      text primary key,
  note       text,
  created_at timestamptz not null default now()
);

-- The school's two real domains. Anything else is refused at signup.
insert into public.allowed_signup_domains (domain, note) values
  ('wayzataschools.org', 'Staff addresses'),
  ('isd284.com',         'Student addresses')
on conflict (domain) do nothing;

-- The two people building this. No advisor has been given any power yet, by
-- design: every other account starts, and stays, a student until an admin
-- changes it.
insert into public.bootstrap_admins (email, note) values
  ('kumarsha003@isd284.com', 'Project owner'),
  ('menonnay000@isd284.com', 'Co-developer')
on conflict (email) do nothing;

-- Signup now enforces the domain list and applies the admin bootstrap. The
-- role is still never read from the client -- it is decided here, from tables
-- only an admin can edit.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  addr        text := lower(coalesce(new.email, ''));
  addr_domain text := split_part(addr, '@', 2);
  assigned    public.app_role := 'student';
begin
  -- An empty allow-list means "no restriction", which is how the local stack
  -- and its usc.edu test accounts keep working.
  if exists (select 1 from public.allowed_signup_domains)
     and not exists (
       select 1 from public.allowed_signup_domains d
       where d.domain = addr_domain
     )
  then
    raise exception 'Accounts are limited to school email addresses.'
      using errcode = '22023';
  end if;

  if exists (select 1 from public.bootstrap_admins b where b.email = addr) then
    assigned := 'admin';
  end if;

  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    nullif(trim(coalesce(new.raw_user_meta_data ->> 'full_name', '')), ''),
    assigned
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

-- Both tables are admin-only in every direction. A student cannot read who the
-- administrators are, and certainly cannot add themselves.
grant select, insert, update, delete on public.allowed_signup_domains to authenticated;
grant select, insert, update, delete on public.bootstrap_admins       to authenticated;

alter table public.allowed_signup_domains enable row level security;
alter table public.bootstrap_admins       enable row level security;

drop policy if exists "admins manage signup domains" on public.allowed_signup_domains;
create policy "admins manage signup domains"
  on public.allowed_signup_domains for all to authenticated
  using (public.auth_role() = 'admin')
  with check (public.auth_role() = 'admin');

drop policy if exists "admins manage bootstrap admins" on public.bootstrap_admins;
create policy "admins manage bootstrap admins"
  on public.bootstrap_admins for all to authenticated
  using (public.auth_role() = 'admin')
  with check (public.auth_role() = 'admin');
