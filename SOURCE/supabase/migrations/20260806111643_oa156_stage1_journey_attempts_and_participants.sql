-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806111643, applied name
-- 'oa156_stage1_journey_attempts_and_participants') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- OA-ZYRA-156 STAGE 1 of 4 — DR-ZYRA-121, V3 §2 and §4.
--
-- PURE ADDITION. Creates journey_attempts and zyra_attempt_participants().
-- Nothing is re-pointed, no policy changes, no columns dropped. Behaviour
-- after this migration must be byte-identical to the baseline captured
-- immediately before it.
--
-- Later stages: 2 backfill (0 rows — trivial), 3 re-point the nine tables
-- and 15 policies, 4 drop the moved columns from matches.
--
-- THE MODEL (V3 §2): matches stays the permanent one-row-per-pair record.
-- Each ATTEMPT gets its own lifecycle. "Every Journey is an attempt from
-- the start" — attempt 1 exists the moment a Journey does, so there is
-- never a migration moment later.

create table if not exists public.journey_attempts (
  id             uuid primary key default gen_random_uuid(),
  match_id       uuid not null references public.matches(id) on delete cascade,

  -- Internal only. V3 §2: "Not 'Attempt 1, 2, 3.' Numbering is technical
  -- and quietly shaming — 'attempt' presupposes failure. Users see TIME:
  -- 'Journey with Ahmed · June – August 2026'." This column must never
  -- reach a screen.
  attempt_number int  not null default 1,

  -- Three states. 'paused' is deliberately absent: pausing is a FLAG on an
  -- Active attempt, not a state of its own (V3 §2, and the same reason the
  -- value was removed from matches.status in OA-ZYRA-164).
  status         text not null default 'potential'
                 check (status in ('potential','active','ended')),
  journey_stage  text,

  started_at     timestamptz,
  ended_at       timestamptz,
  ended_by       uuid references public.profiles(id) on delete set null,
  end_reason     text,
  end_note       text,

  paused_by      uuid references public.profiles(id) on delete set null,
  paused_at      timestamptz,

  created_at     timestamptz not null default now(),

  unique (match_id, attempt_number),

  -- Same ending rules as matches, so the two cannot diverge during the
  -- stages where both exist.
  constraint attempts_end_reason_known check (
    end_reason is null or end_reason in (
      'not_compatible','circumstances_changed','marrying_elsewhere',
      'family_decision','safety_concern','prefer_not_to_say','no_response')),
  constraint attempts_no_response_is_system check (
    end_reason is distinct from 'no_response' or ended_by is null),
  constraint attempts_no_note_on_safety_ending check (
    end_reason is distinct from 'safety_concern' or end_note is null),
  constraint attempts_end_fields_need_ended_status check (
    status = 'ended' or (ended_by is null and end_reason is null and end_note is null)),
  constraint attempts_end_note_length check (
    end_note is null or char_length(end_note) <= 500),
  constraint attempts_pause_needs_active check (
    paused_by is null or status = 'active')
);

create index if not exists journey_attempts_match  on public.journey_attempts (match_id);
create index if not exists journey_attempts_active on public.journey_attempts (status) where status = 'active';

-- ONE ACTIVE ATTEMPT PER PAIR. V3 §14 calls this one of "two fixes that
-- come free". The per-person rule still needs the participant check below —
-- see the note on the matches indexes.
create unique index if not exists journey_attempts_one_active_per_match
  on public.journey_attempts (match_id) where status = 'active';

-- OWNERSHIP CLASSIFICATION, IN THE SAME MIGRATION THAT CREATES THE TABLE.
-- Founder note 3, 2026-08-06: "Any future migration that introduces
-- personal data should include ownership classification as part of the
-- migration itself, not as documentation afterwards." First table built
-- under that rule.
comment on table public.journey_attempts is
  'One attempt at a Journey between the pair in matches. OWNERSHIP: joint, except end_reason — see column comments and ZYRA_JOURNEY_FIELD_CLASSIFICATION_CURRENT_VERSION_V2.';
comment on column public.journey_attempts.attempt_number is
  'OWNERSHIP: joint — INTERNAL ONLY. Never render this. V3 §2: users see dates, not attempt numbers.';
comment on column public.journey_attempts.status        is 'OWNERSHIP: joint';
comment on column public.journey_attempts.journey_stage is 'OWNERSHIP: joint';
comment on column public.journey_attempts.started_at    is 'OWNERSHIP: joint';
comment on column public.journey_attempts.ended_at      is 'OWNERSHIP: joint';
comment on column public.journey_attempts.ended_by      is 'OWNERSHIP: joint — who ended it is knowable to both';
comment on column public.journey_attempts.end_note      is 'OWNERSHIP: joint — written TO the other person';
comment on column public.journey_attempts.paused_by     is 'OWNERSHIP: joint — the other party is told a pause happened';
comment on column public.journey_attempts.paused_at     is 'OWNERSHIP: joint';
comment on column public.journey_attempts.end_reason    is
  'OWNERSHIP: per-value. joint for the five stated reasons; safety_concern is row-scoped(ended_by) and MUST NEVER reach the other party by export or any indirect route.';

alter table public.journey_attempts enable row level security;

-- No policies yet. Stage 1 adds the table; stage 3 adds visibility once
-- zyra_can_view_attempt() exists. RLS on with no policy means no client can
-- read it — the safe default while it is empty and unused.

-- =====================================================================
-- THE SINGLE SOURCE OF TRUTH FOR PARTICIPATION
--
-- Founder, 2026-08-06: "I want zyra_attempt_participants() to become the
-- single source of truth for participation. Any future role (Mediator,
-- Family Account, Mosque Representative, Moderator visibility etc.) should
-- be added there rather than duplicated across multiple visibility
-- functions."
--
-- BOOLEAN BY DESIGN. It answers exactly one question — who has FULL access
-- to this attempt. The successor-Guardian case (V3 §10: a new Guardian sees
-- THAT a previous Journey existed and how it ended, never its contents) is
-- deliberately NOT expressed here. Founder: "I would rather have one
-- obvious exception than quietly increase the complexity of the core
-- authorisation layer." That exception becomes its own narrow function in
-- stage 3.
--
-- Guardians are resolved from wali_links AS IT IS NOW. V3 §10 requires
-- Guardian involvement to be recorded PER ATTEMPT, which needs a join table
-- that does not exist yet — noted as a stage-3 item rather than faked here.
-- Today, with zero attempts, current-Guardian and Guardian-at-the-time are
-- the same set.
-- =====================================================================
create or replace function public.zyra_attempt_participants(p_attempt uuid)
returns table (user_id uuid, role text)
language sql
stable
security definer
set search_path to 'public'
as $$
  select m.seeker_a_id, 'seeker'::text
    from public.journey_attempts a join public.matches m on m.id = a.match_id
   where a.id = p_attempt
  union
  select m.seeker_b_id, 'seeker'::text
    from public.journey_attempts a join public.matches m on m.id = a.match_id
   where a.id = p_attempt
  union
  select w.wali_id, 'guardian'::text
    from public.journey_attempts a
    join public.matches m   on m.id = a.match_id
    join public.wali_links w on w.status = 'active'
                            and w.seeker_id in (m.seeker_a_id, m.seeker_b_id)
   where a.id = p_attempt;
$$;

comment on function public.zyra_attempt_participants(uuid) is
  'SINGLE SOURCE OF TRUTH for Journey attempt participation (Founder, 2026-08-06). Returns everyone with FULL access. Add new roles HERE — never in a visibility function. Boolean by design: the successor-Guardian summary case is a separate narrow function, not a role in this set.';

revoke all on function public.zyra_attempt_participants(uuid) from public, anon;
grant execute on function public.zyra_attempt_participants(uuid) to authenticated;
