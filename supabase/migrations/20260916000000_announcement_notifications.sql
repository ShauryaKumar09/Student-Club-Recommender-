-- Announcements reach the roster
--
-- Posting an announcement wrote one row to public.announcements and stopped
-- there. The composer told the advisor "Members get this in their
-- notifications within a minute", and the frontend comment claimed the insert
-- "is what puts it in every member's notifications", but nothing ever fanned
-- it out -- public.notifications stayed empty for everyone.
--
-- The fan-out belongs in the database, not the client: notifications has no
-- insert policy at all (by design -- see notify_user), so a browser cannot
-- write another person's feed even if it wanted to. A definer trigger is also
-- the only way to cover both composers, the club-page one and the advisor
-- dashboard one, without duplicating the logic in two places.

create or replace function public.fanout_announcement()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  club_name text;
  member    record;
begin
  select c.name into club_name
    from public.clubs c
   where c.id = new.club_id;

  -- Everyone on the roster except whoever wrote it; an author does not need
  -- to be told about their own post.
  for member in
    select m.user_id
      from public.memberships m
     where m.club_id = new.club_id
       and (new.author_id is null or m.user_id <> new.author_id)
  loop
    perform public.notify_user(
      member.user_id,
      new.title,
      new.body,
      'announcement',
      -- link carries the club id so the feed can name the club the
      -- announcement actually came from.
      new.club_id
    );
  end loop;

  return new;
end;
$$;

revoke all on function public.fanout_announcement() from public;
revoke all on function public.fanout_announcement() from anon;
revoke all on function public.fanout_announcement() from authenticated;

drop trigger if exists announcements_fanout on public.announcements;
create trigger announcements_fanout
  after insert on public.announcements
  for each row execute function public.fanout_announcement();
