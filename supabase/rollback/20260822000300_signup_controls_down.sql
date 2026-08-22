-- Reverses supabase/migrations/20260822000300_signup_controls.sql.
-- Restores the unrestricted signup trigger from 20260821000100.
-- Generated 2026-08-22.

begin;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, email, full_name)
  values (
    new.id,
    new.email,
    nullif(trim(coalesce(new.raw_user_meta_data ->> 'full_name', '')), '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop table if exists public.bootstrap_admins;
drop table if exists public.allowed_signup_domains;

commit;
