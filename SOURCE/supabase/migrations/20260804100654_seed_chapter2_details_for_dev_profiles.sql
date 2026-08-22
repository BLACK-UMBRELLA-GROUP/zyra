-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260804100654, applied name
-- 'seed_chapter2_details_for_dev_profiles') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Backfill Chapter 2 answers for the seeded development profiles.
-- Founder approved 2026-08-04: "populate the existing seeded development
-- profiles with realistic Chapter 2 values so compatibility scoring,
-- matching and testing can be exercised properly".
--
-- DETERMINISTIC. Assignment is by row_number() over an ordered id list, so
-- re-running produces identical data and a screenshot taken today still
-- matches the database next week. No random(), which would make every run
-- a different dataset and every bug report unreproducible.
--
-- REALISTIC, NOT UNIFORM. A uniform spread would hide exactly the bugs
-- this data exists to find: if every profile has a different ethnicity,
-- nothing ever collides, and a matching bug that only appears when two
-- people share an attribute never appears at all. The distribution is
-- weighted the way a British Muslim user base plausibly is — heavily
-- GB-born, Sunni-majority, English plus a heritage language — with enough
-- repetition that overlap actually occurs.
--
-- SEEKERS ONLY. seeker_details is a Seeker concept; a Guardian has no
-- Chapter 2. The FK would happily accept a wali id, which is why the
-- filter is explicit.
--
-- CONSENT RECORDS ARE MARKED AS SEEDED. These profiles never consented to
-- anything — they are synthetic. A consent row is needed for the model to
-- hold together, but a fabricated consent that looked real would be worse
-- than none. policy_version is '2026-08-04-seed': greppable, and it can
-- never be mistaken for agreement to the real wording.
--
-- Language arrays use a CASE rather than an array-of-arrays literal: in
-- Postgres `array[array['en','ur'], ...]` is a single 2-D array, and one
-- subscript into it yields a scalar, not a row.

with ordered as (
  select id, row_number() over (order by id) - 1 as n
  from public.profiles
  where role = 'seeker'
),
assigned as (
  select
    id,
    n,
    (array['sunni','sunni','sunni','sunni','sunni','sunni','sunni','sunni',
           'shia','shia','shia','other'])[(n % 12) + 1] as sect,
    ((n % 6) = 4) as revert,
    (array['GB','GB','GB','GB','PK','BD','IN','SO','TR','MA','EG','IR'])[(n % 12) + 1] as cob,
    (array['GB','GB','GB','GB','GB','GB','PK','BD','IN','SO','TR','FR'])[(n % 12) + 1] as nat,
    (array['pakistani','pakistani','pakistani',
           'bangladeshi','bangladeshi',
           'indian','arab','arab','somali','turkish',
           'white_european','mixed'])[(n % 12) + 1] as eth,
    case (n % 12)
      when 0  then array['en','ur']
      when 1  then array['en','ur','pa']
      when 2  then array['en','ur']
      when 3  then array['en','bn']
      when 4  then array['en','bn']
      when 5  then array['en','gu']
      when 6  then array['en','ar']
      when 7  then array['en','ar']
      when 8  then array['en','so']
      when 9  then array['en','tr']
      when 10 then array['en']
      else         array['en','fa']
    end as langs
  from ordered
)
insert into public.seeker_details
  (user_id, sect, sect_other, revert_status, country_of_birth,
   nationality, ethnicity, languages, preferences)
select
  a.id,
  a.sect,
  case when a.sect = 'other' then 'Non-denominational' else null end,
  a.revert,
  a.cob,
  a.nat,
  a.eth,
  a.langs,
  jsonb_build_object(
    'location', jsonb_build_object(
      'preference',  (array['same_city','same_region','same_country','anywhere'])[(a.n % 4) + 1],
      'flexibility', (array['green','yellow','green','red'])[(a.n % 4) + 1]
    ),
    'sect', jsonb_build_object(
      -- Someone Sunni is usually open to Sunni and cooler on Shia, and
      -- vice versa. Modelled rather than flattened: "everyone green on
      -- everything" makes every match score identically, which defeats
      -- the point of having test data.
      'matrix', case when a.sect = 'shia'
                  then '{"Sunni":"yellow","Shia":"green","Other":"red"}'::jsonb
                  else '{"Sunni":"green","Shia":"yellow","Other":"red"}'::jsonb end,
      'hard_requirement',    (a.n % 3) = 0,
      'outside_flexibility', (array['red','yellow','green'])[(a.n % 3) + 1]
    ),
    'revert', jsonb_build_object('flexibility',
      (array['green','green','yellow'])[(a.n % 3) + 1]),
    'country_of_birth', jsonb_build_object(
      'preferred', case when (a.n % 4) = 0 then '[]'::jsonb
                       else jsonb_build_array(a.cob, 'GB') end,
      'skipped',     (a.n % 4) = 0,
      'flexibility', (array['green','yellow','green','yellow'])[(a.n % 4) + 1]
    ),
    'nationality', jsonb_build_object(
      'preferred',   case when (a.n % 3) = 1 then '[]'::jsonb else jsonb_build_array('GB') end,
      'skipped',     (a.n % 3) = 1,
      'flexibility', (array['green','green','yellow'])[(a.n % 3) + 1]
    ),
    'ethnicity', jsonb_build_object(
      'preferred',   case when (a.n % 5) = 2 then '[]'::jsonb else jsonb_build_array(a.eth) end,
      'skipped',     (a.n % 5) = 2,
      'flexibility', (array['green','yellow','green','yellow','green'])[(a.n % 5) + 1]
    ),
    'languages', jsonb_build_object(
      'preferred',   to_jsonb(a.langs),
      'skipped',     false,
      'flexibility', (array['green','yellow'])[(a.n % 2) + 1]
    )
  )
from assigned a
on conflict (user_id) do update set
  sect             = excluded.sect,
  sect_other       = excluded.sect_other,
  revert_status    = excluded.revert_status,
  country_of_birth = excluded.country_of_birth,
  nationality      = excluded.nationality,
  ethnicity        = excluded.ethnicity,
  languages        = excluded.languages,
  preferences      = excluded.preferences;

insert into public.consents (user_id, consent_type, granted, policy_version)
select id, 'article9_special_category', true, '2026-08-04-seed'
from public.profiles where role = 'seeker';
