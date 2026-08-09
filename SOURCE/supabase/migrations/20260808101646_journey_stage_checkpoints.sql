-- APPLIED LIVE 2026-08-08 via the management API, then written here.
-- Version 20260808101646. Founder-approved 2026-08-08.
--
-- Stage A of the advanceStage release-blocker fix. Additive only:
-- nothing read this table at the time it was created.
--
-- WHY IT EXISTS
-- PRE-JOURNEY RITUAL (current version): "Every checkpoint is a shared
-- decision" and, for the Compatibility Reveal, "Neither of you sees the
-- result until you both choose to reveal", followed by a "Continue
-- Journey" checkpoint action. Founder-decided 2026-08-08: leaving
-- compatibility_reveal requires BOTH parties revealed AND BOTH parties
-- pressing Continue.
--
-- Revealing was already recorded (journey_compatibility.seeker_a_revealed
-- / seeker_b_revealed). Pressing Continue was recorded nowhere — the
-- client simply called an UPDATE that RLS silently discarded.
--
-- WHY A ROW PER PERSON RATHER THAN TWO BOOLEANS ON matches
-- CLAUDE.md 3d: the fact is per-person and permanent for the attempt. A
-- pair of columns on matches would need renaming for every future stage
-- that gains a checkpoint; a row is object state and scales with the
-- objects.
--
-- WHY NOT journey_phase_checkpoints
-- That table is keyed by an INTEGER phase (1/2/3) and carries a
-- Continue/Ask More/End decision WITHIN a phase. It cannot express a
-- named stage. Different question, different table.
--
-- OA-ZYRA-156 NOTE: this is a TENTH journey_* table carrying match_id
-- that will need re-pointing to attempt_id. It deliberately follows the
-- identical attempt_id + zyra_set_attempt_from_match pattern as the
-- other nine so it migrates with them rather than needing its own case.

create table if not exists public.journey_stage_checkpoints (
  match_id   uuid        not null references public.matches(id)          on delete cascade,
  attempt_id uuid                 references public.journey_attempts(id) on delete cascade,
  stage      text        not null,
  seeker_id  uuid        not null references public.profiles(id)         on delete cascade,
  created_at timestamptz not null default now(),
  primary key (match_id, stage, seeker_id),
  constraint journey_stage_checkpoints_stage_known check (
    stage = any (array['compatibility_reveal','salam_exchange','wali_gate',
                       'phase_1','phase_2','phase_3','family_stage','conversation'])
  )
);

comment on table public.journey_stage_checkpoints is
  'OWNERSHIP: row-scoped(seeker_id), readable by both Seekers of the '
  'attempt. One row = "this Seeker has chosen to continue past this '
  'stage". Written ONLY by zyra_advance_stage(); no client INSERT grant '
  'exists, so a checkpoint cannot be forged or written on another '
  'person''s behalf. See PRE-JOURNEY RITUAL (current version).';

create index if not exists journey_stage_checkpoints_attempt_idx
  on public.journey_stage_checkpoints (attempt_id);

-- Same BEFORE INSERT trigger every other journey_* table uses to resolve
-- attempt_id from match_id. Consistency is the point: OA-156 re-points
-- all of them with one pass.
drop trigger if exists journey_stage_checkpoints_set_attempt on public.journey_stage_checkpoints;
create trigger journey_stage_checkpoints_set_attempt
  before insert on public.journey_stage_checkpoints
  for each row execute function public.zyra_set_attempt_from_match();

alter table public.journey_stage_checkpoints enable row level security;

-- Read: the two Seekers of the attempt. Mirrors journey_phase_checkpoints_read.
-- Guardians are deliberately excluded — who pressed Continue and when is
-- not something the Guardian role needs, and the Family Review Period is
-- the Guardian's own instrument for the transitions they do govern.
create policy journey_stage_checkpoints_read
  on public.journey_stage_checkpoints for select
  using (exists (
    select 1 from public.zyra_my_attempt_participation r
    where r.attempt_id = journey_stage_checkpoints.attempt_id
      and r.role = 'seeker'
  ));

-- No INSERT/UPDATE/DELETE policy and no write grant. I4 — enforce at the
-- layer that cannot be skipped. Deliberately TIGHTER than the sibling
-- tables, whose blanket anon+authenticated write grants are the known
-- open item (Guardian & Romantic Rules, section 8 item 4); this table
-- does not add to that debt.
revoke all on public.journey_stage_checkpoints from public, anon, authenticated;
grant select on public.journey_stage_checkpoints to authenticated;

-- While here: journey_attempts.journey_stage had no CHECK.
-- matches.journey_stage has carried matches_journey_stage_check since
-- 2026-07-25. Its copy on journey_attempts — the column OA-156 makes
-- authoritative — was unconstrained, so the table about to become the
-- source of truth was the looser of the two.
-- NULL is permitted: a 'potential' attempt has no stage until
-- promote_journey_to_active() sets one.
alter table public.journey_attempts
  drop constraint if exists journey_attempts_journey_stage_check;
alter table public.journey_attempts
  add constraint journey_attempts_journey_stage_check check (
    journey_stage is null or journey_stage = any (
      array['compatibility_reveal','salam_exchange','wali_gate',
            'phase_1','phase_2','phase_3','family_stage','conversation'])
  );

-- VERIFIED EMPIRICALLY 2026-08-08, 8/8:
--   rls_enabled                    true
--   grants to authenticated        SELECT only
--   grants to anon                 (none)
--   has_table_privilege INSERT     false
--   attempt_id trigger present     journey_stage_checkpoints_set_attempt
--   policies                       1
--   journey_attempts CHECK present 1
