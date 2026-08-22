-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806113031, applied name
-- 'oa156_stage4a_attempt_id_columns') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- OA-ZYRA-156 STAGE 4a — attempt_id on the nine tables.
--
-- ADDITIVE AND CORRECT-BY-CONSTRUCTION. Each table gains a nullable
-- attempt_id, backfilled from its match (0 rows today), and a trigger that
-- populates it on insert from the match_id the Dart layer still writes.
--
-- The trigger is what makes this safe to ship on its own. Without it,
-- attempt_id would be a column nothing fills — correct on the day it was
-- added and wrong the moment anything inserted. With it, every future row
-- carries the right attempt whether or not the client knows attempts exist,
-- so 4b (policies), 4c (Dart) and 4d (drop match_id) can land separately
-- without a half-migrated state in between.
--
-- NOT NULL is deliberately NOT set yet: it would break every existing Dart
-- insert. It goes on in 4d, once the client writes attempt_id directly.

do $$
declare tbl text;
begin
  foreach tbl in array array[
    'conversations','journey_compatibility','journey_family_answers',
    'journey_family_reviews','journey_phase_answers','journey_phase_checkpoints',
    'journey_phase_ratings','journey_salams','timelines'
  ] loop
    execute format(
      'alter table public.%I add column if not exists attempt_id uuid
         references public.journey_attempts(id) on delete cascade', tbl);

    -- Backfill: the current attempt for that match. 1:1 today via the
    -- stage-2 trigger, so "the attempt" is unambiguous.
    execute format(
      'update public.%I t set attempt_id = a.id
         from public.journey_attempts a
        where a.match_id = t.match_id and t.attempt_id is null', tbl);

    execute format('create index if not exists %I on public.%I (attempt_id)',
                   tbl || '_attempt_idx', tbl);

    execute format(
      'comment on column public.%I.attempt_id is
        ''OWNERSHIP: joint. Replaces match_id from stage 4d — a pair may have several attempts and their data must not collide.''', tbl);
  end loop;
end $$;

-- Populates attempt_id from match_id on insert, so the Dart layer can keep
-- writing match_id until 4c without leaving attempt_id null.
create or replace function public.zyra_set_attempt_from_match()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if new.attempt_id is null and new.match_id is not null then
    -- The live attempt if there is one, else the newest. A pair with an
    -- active attempt is unambiguous; a pair whose only attempt has ended
    -- should still hang its rows on that attempt rather than nothing.
    select a.id into new.attempt_id
    from public.journey_attempts a
    where a.match_id = new.match_id
    order by (a.status = 'active') desc, a.attempt_number desc
    limit 1;
  end if;
  return new;
end $$;

revoke all on function public.zyra_set_attempt_from_match() from public, anon, authenticated;

do $$
declare tbl text;
begin
  foreach tbl in array array[
    'conversations','journey_compatibility','journey_family_answers',
    'journey_family_reviews','journey_phase_answers','journey_phase_checkpoints',
    'journey_phase_ratings','journey_salams','timelines'
  ] loop
    execute format('drop trigger if exists %I on public.%I', tbl||'_set_attempt', tbl);
    execute format(
      'create trigger %I before insert on public.%I
         for each row execute function public.zyra_set_attempt_from_match()',
      tbl||'_set_attempt', tbl);
  end loop;
end $$;
