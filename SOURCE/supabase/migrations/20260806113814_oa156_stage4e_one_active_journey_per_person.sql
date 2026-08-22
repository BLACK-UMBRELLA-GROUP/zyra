-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806113814, applied name
-- 'oa156_stage4e_one_active_journey_per_person') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- OA-ZYRA-156 STAGE 4e, part 1 — one Active Journey per PERSON, enforced.
-- Founder 2026-08-06: "This rule should become impossible to violate, not
-- simply unlikely."
--
-- ===================== WHY THE EXISTING INDEXES DO NOT WORK =============
--
-- matches_seeker_a_active and matches_seeker_b_active are two separate
-- partial unique indexes, one per column. They catch a person appearing
-- twice in the SAME column and are blind to a person who is seeker_a on one
-- active match and seeker_b on another.
--
-- REPRODUCED 2026-08-06 while building an unrelated fixture: ordering three
-- ids a < b < c put B in different columns on two matches and neither index
-- objected. Not theoretical.
--
-- journey_attempts_one_active_per_match has the same shape of gap — it is
-- per PAIR, not per PERSON.
--
-- ===================== WHY NOT ANOTHER UNIQUE INDEX =====================
--
-- A unique index needs the person as a column on the table being indexed.
-- The person is not on journey_attempts; they are on matches. Denormalising
-- seeker_a_id/seeker_b_id onto attempts would reproduce the two-column
-- problem exactly — two partial indexes that still do not compose.
--
-- The only index-based fix is one ROW PER PARTICIPANT, i.e. a second table
-- holding participation. The Founder has just ruled that Journey state has
-- a single source of truth, and a maintained side table is a second one.
--
-- ===================== WHAT THIS DOES INSTEAD ==========================
--
-- A constraint trigger that runs AFTER INSERT OR UPDATE, takes a
-- transaction-scoped advisory lock on each participant, and refuses if that
-- person already holds a different active attempt.
--
-- The advisory lock is the part that makes it a real constraint rather than
-- a check. Without it, two concurrent transactions each promoting a
-- different Journey for the same person both see zero conflicts and both
-- commit — the classic read-then-write race, and the reason "every write
-- path checks it" was never actually enforcement.
--
-- `authenticated` cannot disable a trigger (that needs ALTER TABLE, which
-- it does not hold), so from the application's side this is not bypassable.

create or replace function public.zyra_enforce_one_active_attempt()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_a uuid;
  v_b uuid;
  v_clash uuid;
begin
  if new.status <> 'active' then
    return null;
  end if;

  select m.seeker_a_id, m.seeker_b_id into v_a, v_b
  from public.matches m where m.id = new.match_id;

  -- Serialise on the participants, in a stable order so two transactions
  -- touching the same pair can never deadlock against each other.
  perform pg_advisory_xact_lock(hashtextextended(least(v_a,v_b)::text, 0));
  perform pg_advisory_xact_lock(hashtextextended(greatest(v_a,v_b)::text, 0));

  select a.id into v_clash
  from public.journey_attempts a
  join public.matches m on m.id = a.match_id
  where a.status = 'active'
    and a.id <> new.id
    and (m.seeker_a_id in (v_a, v_b) or m.seeker_b_id in (v_a, v_b))
  limit 1;

  if v_clash is not null then
    raise exception 'one_active_journey_limit'
      using hint = 'One of you already has an Active Journey. End or pause it first.';
  end if;

  return null;
end $$;

revoke all on function public.zyra_enforce_one_active_attempt() from public, anon, authenticated;

-- CONSTRAINT TRIGGER, deferrable-capable and evaluated per row after the
-- write. A plain BEFORE trigger would not see rows written earlier in the
-- same statement.
drop trigger if exists journey_attempts_one_active_per_person on public.journey_attempts;
create constraint trigger journey_attempts_one_active_per_person
  after insert or update of status on public.journey_attempts
  for each row execute function public.zyra_enforce_one_active_attempt();

comment on function public.zyra_enforce_one_active_attempt() is
  'One Active Journey per PERSON. The two partial indexes on matches only catch a repeat within the same column — a person can be seeker_a on one and seeker_b on another, reproduced 2026-08-06. Advisory locks close the read-then-write race that made "every write path checks it" not actually enforcement.';
