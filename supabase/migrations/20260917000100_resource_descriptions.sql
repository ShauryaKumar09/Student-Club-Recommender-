-- A description on each resource
--
-- 20260916000300 gave a section a blurb, which says what the section is for.
-- The individual files and links still had nothing but a title, so "Regionals
-- packet" could not say what it is, who needs it, or by when.
--
-- Same shape as the section blurb: optional, and a resource without one simply
-- shows its title as before.

alter table public.resources
  add column if not exists description text;
