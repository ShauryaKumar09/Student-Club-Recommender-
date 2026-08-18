-- Aug 17 2026: photo drop for the clubs that had none.
--
-- 53 images uploaded to the public club-photos bucket as <club-id>-N.png|jpg
-- and pointed at from photos[]. 36 clubs went from no photos to some; GSA
-- already had gsa-1.png (byte-identical to the first file in its folder) and
-- gained two more, appended rather than replacing.
--
-- AHA and Sustainable Swag are listed with their second image first: the
-- alphabetically-first file was a 7.6KB thumbnail in one case and a 692x142
-- banner strip in the other, and photos[0] is what the card shows.
--
-- Already applied to the live database via PostgREST; kept for the record.

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/aha-american-heart-association-2.jpg", "https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/aha-american-heart-association-1.png"]'::jsonb
where id = 'aha-american-heart-association';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/beads-of-serenity-1.png", "https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/beads-of-serenity-2.png"]'::jsonb
where id = 'beads-of-serenity';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/chinese-club-1.png", "https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/chinese-club-2.png", "https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/chinese-club-3.jpg"]'::jsonb
where id = 'chinese-club';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/dance-club-1.jpg"]'::jsonb
where id = 'dance-club';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/data-science-and-ai-1.jpg"]'::jsonb
where id = 'data-science-and-ai';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/environmental-group-1.png"]'::jsonb
where id = 'environmental-group';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/future-problem-solvers-1.png"]'::jsonb
where id = 'future-problem-solvers';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/gsa-1.png", "https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/gsa-2.png", "https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/gsa-3.png"]'::jsonb
where id = 'gsa';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/international-club-1.png"]'::jsonb
where id = 'international-club';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/jewish-student-union-1.png"]'::jsonb
where id = 'jewish-student-union';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/kids-scholarship-fund-1.png"]'::jsonb
where id = 'kids-scholarship-fund';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/knots-of-kindness-1.png"]'::jsonb
where id = 'knots-of-kindness';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/latino-student-union-1.png"]'::jsonb
where id = 'latino-student-union';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/leaders-and-lawmakers-1.png"]'::jsonb
where id = 'leaders-and-lawmakers';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/our-right-to-learn-1.png", "https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/our-right-to-learn-2.png"]'::jsonb
where id = 'our-right-to-learn';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/paws-for-a-cause-1.png"]'::jsonb
where id = 'paws-for-a-cause';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/pediatric-cancer-awareness-1.png"]'::jsonb
where id = 'pediatric-cancer-awareness';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/science-olympiad-1.png", "https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/science-olympiad-2.png"]'::jsonb
where id = 'science-olympiad';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/spanish-club-1.png"]'::jsonb
where id = 'spanish-club';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/sports-promotional-team-1.png"]'::jsonb
where id = 'sports-promotional-team';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/stress-management-1.png"]'::jsonb
where id = 'stress-management';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/super-mileage-team-1.png", "https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/super-mileage-team-2.png"]'::jsonb
where id = 'super-mileage-team';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/sustainable-swag-ss-2.png", "https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/sustainable-swag-ss-1.png"]'::jsonb
where id = 'sustainable-swag-ss';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/the-elite-pressure-line-1.png"]'::jsonb
where id = 'the-elite-pressure-line';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/trojan-tribune-journalism-club-1.png", "https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/trojan-tribune-journalism-club-2.png"]'::jsonb
where id = 'trojan-tribune-journalism-club';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/wave-wayzata-actively-valuing-empathy-1.png"]'::jsonb
where id = 'wave-wayzata-actively-valuing-empathy';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/wayzata-computer-science-group-1.png", "https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/wayzata-computer-science-group-2.png"]'::jsonb
where id = 'wayzata-computer-science-group';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/wayzata-immune-1.png"]'::jsonb
where id = 'wayzata-immune';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/wayzata-k-pop-group-1.png"]'::jsonb
where id = 'wayzata-k-pop-group';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/wayzata-neuroscience-1.png"]'::jsonb
where id = 'wayzata-neuroscience';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/wayzata-philosophy-1.png"]'::jsonb
where id = 'wayzata-philosophy';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/wayzata-real-estate-team-1.png", "https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/wayzata-real-estate-team-2.png"]'::jsonb
where id = 'wayzata-real-estate-team';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/wayzata-red-cross-1.png", "https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/wayzata-red-cross-2.png"]'::jsonb
where id = 'wayzata-red-cross';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/wayzata-she-leads-1.png"]'::jsonb
where id = 'wayzata-she-leads';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/wayzata-unicef-1.png", "https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/wayzata-unicef-2.png"]'::jsonb
where id = 'wayzata-unicef';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/we-have-spirit-bible-study-1.png", "https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/we-have-spirit-bible-study-2.png"]'::jsonb
where id = 'we-have-spirit-bible-study';

update public.clubs set photos = '["https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/women-in-government-1.png", "https://pqfchywvjinosvvphshy.supabase.co/storage/v1/object/public/club-photos/women-in-government-2.png"]'::jsonb
where id = 'women-in-government';

-- Two rows created after performing_arts was split out of arts_creative
-- were missing that key; harmless at runtime but backfilled for a clean audit.
update public.clubs set scores = scores || '{"performing_arts": 0}'::jsonb
where not (scores ? 'performing_arts');
