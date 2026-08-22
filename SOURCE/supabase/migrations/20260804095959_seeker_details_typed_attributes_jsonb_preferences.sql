-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260804095959, applied name
-- 'seeker_details_typed_attributes_jsonb_preferences') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Chapter 2 persistence — Founder approved 2026-08-04 (Option C).
--
-- Onboarding collected 31 values and persisted one. Everything below the
-- city died with the app object.
--
-- SHAPE: typed columns for the eight OWN ATTRIBUTES, JSONB for the
-- preference block. The split is principled, not a compromise —
--
--   attributes    queried ACROSS users, by the scorer and by matching.
--                 `where ethnicity = any($1)` uses an index; the same
--                 question asked of a JSONB blob on 200,000 rows does not.
--   preferences   only ever read WHOLE, for ONE user, to compute that
--                 user's own score. Nothing gains from columns, and every
--                 future question would otherwise be a migration.
--
-- CODES, NEVER LABELS. Ratified rule, until now unexercised — zyraCodeFor()
-- had zero callers. Store 'TR'; render "Türkiye" at read time. Relabel and
-- no row changes. This was already load-bearing: ISO 639-1 calls two of
-- this audience's most-spoken languages "Panjabi" and "Pushto"; the labels
-- are corrected in the reference data while the codes stay canonical.
--
-- The CHECK constraints are what make that rule enforceable rather than
-- merely intended. A label cannot be stored by accident.

-- Element-wise array validation. A CHECK constraint may not contain a
-- subquery, but it may call an IMMUTABLE function that does — which is
-- also the only way to say "every element matches" without writing out
-- all 676 two-letter combinations as a literal array.
create or replace function public.zyra_all_iso639_1(p text[])
returns boolean
language sql
immutable
as $$
  select p is null
      or not exists (select 1 from unnest(p) x where x !~ '^[a-z]{2}$');
$$;

create table if not exists public.seeker_details (
  user_id           uuid primary key references public.profiles(id) on delete cascade,

  -- Article 9: religious belief
  sect              text,
  sect_other        text,
  revert_status     boolean,

  -- Article 9: ethnic origin (directly, and by inference from the two
  -- country codes)
  country_of_birth  text,
  nationality       text,
  ethnicity         text,
  languages         text[]  not null default '{}',

  -- Traffic lights and preference lists. Same green/yellow/red vocabulary
  -- as onboarding_answers.ch4_preferences, so a future Chapter-2-aware
  -- scorer can reuse score_candidates()' logic unchanged.
  preferences       jsonb   not null default '{}'::jsonb,

  updated_at        timestamptz not null default now(),

  constraint seeker_details_sect_known
    check (sect is null or sect in ('sunni','shia','other')),

  -- Free text from a user, reaching _sectOptions and rendering on screen.
  constraint seeker_details_sect_other_len
    check (sect_other is null or char_length(sect_other) <= 60),

  -- ISO 3166-1 alpha-2. Rejects "Pakistan" outright.
  constraint seeker_details_cob_is_code
    check (country_of_birth is null or country_of_birth ~ '^[A-Z]{2}$'),
  constraint seeker_details_nat_is_code
    check (nationality is null or nationality ~ '^[A-Z]{2}$'),

  -- Reference codes are lowercase snake_case ('south_asian_other').
  constraint seeker_details_ethnicity_is_code
    check (ethnicity is null or ethnicity ~ '^[a-z][a-z_]*$'),

  constraint seeker_details_languages_are_codes
    check (public.zyra_all_iso639_1(languages))
);

comment on table public.seeker_details is
  'Chapter 2 answers. Special-category data under UK GDPR Article 9 — see public.consents. Codes are stored, never display labels.';

create index if not exists seeker_details_ethnicity on public.seeker_details (ethnicity);
create index if not exists seeker_details_sect      on public.seeker_details (sect);
create index if not exists seeker_details_languages on public.seeker_details using gin (languages);

create or replace function public.touch_seeker_details()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists seeker_details_touch on public.seeker_details;
create trigger seeker_details_touch
  before update on public.seeker_details
  for each row execute function public.touch_seeker_details();

alter table public.seeker_details enable row level security;

-- =====================================================================
-- RLS — DELIBERATELY STRICTER THAN profiles
--
-- profiles is readable by anyone when (is_active AND profile_complete).
-- seeker_details must NOT inherit that. Chapter 2 marks every one of these
-- fields PrivacyLevel.unlock, which means another Seeker sees them only
-- after paying. A blanket select policy here would hand away the entire
-- premium feature and publish Article 9 data to every signed-in account.
--
-- There is therefore NO policy granting another Seeker access. That path
-- goes through seeker_details_for_unlocked() below, which checks
-- profile_unlocks first — the same reasoning that put the once-per-profile
-- rule in a unique index rather than in client code.
-- =====================================================================

create policy seeker_details_select_own on public.seeker_details
  for select using (user_id = (select auth.uid()));

-- A linked Guardian reads their own Seeker's row.
--
-- SCOPE NOTE (2026-08-04): the Founder's approval reads "a linked Guardian
-- should be able to view the same Compatibility Unlock information that the
-- Seeker is permitted to view". That supports two readings —
--   (a) the Guardian sees THEIR SEEKER'S own details, and
--   (b) the Guardian also inherits the Seeker's unlocks, seeing the details
--       of THIRD PARTIES the Seeker has paid to unlock.
-- Only (a) is implemented. (b) grants a Guardian access to a fourth party's
-- Article 9 data — a materially larger privacy surface, not something to
-- infer from an ambiguous sentence. It is a one-line addition to
-- seeker_details_for_unlocked() once the Founder confirms.
create policy seeker_details_select_guardian on public.seeker_details
  for select using (
    exists (
      select 1 from public.wali_links w
      where w.seeker_id = seeker_details.user_id
        and w.wali_id  = (select auth.uid())
        and w.status   = 'active'
    )
  );

create policy seeker_details_insert_own on public.seeker_details
  for insert with check (user_id = (select auth.uid()));

create policy seeker_details_update_own on public.seeker_details
  for update using (user_id = (select auth.uid()))
          with check (user_id = (select auth.uid()));

-- =====================================================================
-- The only route by which one Seeker reads another's Chapter 2 data.
-- Returns nothing unless profile_unlocks holds a row for this pair.
-- Either tier qualifies: both lead to the same screen, and holding Unlock
-- but not Plus still means there is compatibility to view.
-- =====================================================================
create or replace function public.seeker_details_for_unlocked(p_target uuid)
returns table (
  user_id          uuid,
  sect             text,
  sect_other       text,
  revert_status    boolean,
  country_of_birth text,
  nationality      text,
  ethnicity        text,
  languages        text[]
)
language sql
stable
security definer
set search_path to 'public'
as $$
  select d.user_id, d.sect, d.sect_other, d.revert_status,
         d.country_of_birth, d.nationality, d.ethnicity, d.languages
  from public.seeker_details d
  where d.user_id = p_target
    and exists (
      select 1 from public.profile_unlocks u
      where u.unlocker_id = (select auth.uid())
        and u.unlocked_id = p_target
    )
    -- A block overrides a past purchase, in either direction.
    and not public.zyra_block_exists(p_target);
$$;

revoke all on function public.seeker_details_for_unlocked(uuid) from public;
grant execute on function public.seeker_details_for_unlocked(uuid) to authenticated;
