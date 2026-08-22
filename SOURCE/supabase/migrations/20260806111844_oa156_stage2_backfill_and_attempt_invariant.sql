-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806111844, applied name
-- 'oa156_stage2_backfill_and_attempt_invariant') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- OA-ZYRA-156 STAGE 2 of 4 — backfill, and the invariant that keeps it true.
--
-- V3 §2: "Every Journey is an attempt from the start. Attempt 1 exists the
-- moment a Journey does. If there is never a second attempt nothing is
-- wasted; if there is, no data has to be migrated at that moment."
--
-- THE BACKFILL IS A NO-OP TODAY — matches holds 0 rows. Written anyway, and
-- idempotent, because it is the statement of the invariant and must run
-- correctly against a restored backup or a dev database that gains matches
-- before stage 3.
--
-- THE TRIGGER IS THE ACTUAL DELIVERABLE. A backfill without it would be
-- true for exactly as long as nobody created a match: stage 3 re-points
-- nine tables at attempt_id, and a match with no attempt row would have
-- nowhere for its Journey data to hang.

insert into public.journey_attempts
  (match_id, attempt_number, status, journey_stage, started_at, ended_at, created_at)
select m.id, 1, m.status, m.journey_stage,
       case when m.status in ('active','ended') then m.created_at end,
       m.ended_at, m.created_at
from public.matches m
where not exists (select 1 from public.journey_attempts a where a.match_id = m.id);

create or replace function public.zyra_create_first_attempt()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  insert into public.journey_attempts
    (match_id, attempt_number, status, journey_stage, started_at, created_at)
  values (new.id, 1, new.status, new.journey_stage,
          case when new.status = 'active' then now() end, now())
  on conflict (match_id, attempt_number) do nothing;
  return new;
end $$;

drop trigger if exists matches_create_first_attempt on public.matches;
create trigger matches_create_first_attempt
  after insert on public.matches
  for each row execute function public.zyra_create_first_attempt();

revoke all on function public.zyra_create_first_attempt() from public, anon, authenticated;

comment on function public.zyra_create_first_attempt() is
  'Maintains V3 §2''s invariant: a match always has attempt 1. Without this, stage 3 would re-point nine tables at attempts that do not exist.';

-- ===================== THE TRANSITION WINDOW, NAMED ====================
--
-- Between stage 2 and stage 4, matches.status and journey_attempts.status
-- BOTH exist. That is two places holding one fact, which is the exact thing
-- this architecture removes — so it is worth being explicit rather than
-- letting it look intentional.
--
-- NO SYNC TRIGGER, deliberately. A bidirectional mirror is real machinery
-- with real failure modes (loops, divergence, ordering), built to protect a
-- window that should last hours. The cheaper and safer answer is to close
-- the window quickly: stage 3 switches every reader to the attempt, stage 4
-- drops the columns from matches.
--
-- Until stage 3, MATCHES IS AUTHORITATIVE — every existing service and
-- policy still reads it. The attempt row mirrors matches at creation and is
-- not maintained afterwards. Any dev data created and then mutated inside
-- the window can drift; with 0 matches, 0 real users and hours between
-- stages, that is a bounded and acceptable cost. Recorded so nobody later
-- mistakes the drift for a bug in the model.
comment on column public.journey_attempts.status is
  'OWNERSHIP: joint. TRANSITIONAL until stage 4: matches.status is authoritative and this mirrors it at creation only. After stage 4 this becomes the sole source of truth.';
