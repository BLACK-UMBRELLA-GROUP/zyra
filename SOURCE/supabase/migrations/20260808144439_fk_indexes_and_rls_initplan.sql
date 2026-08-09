-- APPLIED LIVE 2026-08-08, version 20260808144439.
-- Performance debt: audit R17/R25 (unindexed foreign keys) and R24
-- (auth_rls_initplan). Behaviour-neutral — no policy's meaning changes
-- and no row's visibility changes. Verified 11/11.
--
-- MEASURED FIRST:
--   • 21 foreign keys had no index on the referencing side. The audit
--     recorded 15; it had grown, including journey_stage_checkpoints
--     added earlier the same day.
--   • Only 4 policies still re-evaluated auth.uid() per row. The audit
--     recorded 21, so most were fixed in the intervening weeks — the
--     number went DOWN without anyone recording that it had.
--
-- WHY ALL 21 rather than a chosen few: every one of those columns appears
-- in at least one RLS policy or function body, and every one is walked by
-- the cascade from delete_own_account(), which deletes from auth.users
-- and lets it fan out. Unindexed, each child table is a sequential scan
-- per deleted account.
--
-- HONESTY ABOUT THE EVIDENCE: the usage counts behind that claim came
-- from substring-matching column names against policy and function
-- source, which over-counts. It establishes that none of the 21 is
-- integrity-only; it is NOT a measurement of hot paths. There is no
-- production traffic to measure. Cheap insurance taken while the tables
-- are small, not a tuned response to a profile.
--
-- Plain CREATE INDEX, not CONCURRENTLY: a migration runs in a transaction
-- and at current row counts (largest table 149 profiles) these are
-- instant. Revisit if ever re-run against real volume.

create index if not exists journey_attempts_ended_by_idx            on public.journey_attempts (ended_by);
create index if not exists journey_attempts_paused_by_idx           on public.journey_attempts (paused_by);
create index if not exists journey_family_answers_answerer_idx      on public.journey_family_answers (answerer_id);
create index if not exists journey_family_review_responses_wali_idx on public.journey_family_review_responses (wali_id);
create index if not exists journey_phase_answers_seeker_idx         on public.journey_phase_answers (seeker_id);
create index if not exists journey_phase_checkpoints_seeker_idx     on public.journey_phase_checkpoints (seeker_id);
create index if not exists journey_phase_ratings_rater_idx          on public.journey_phase_ratings (rater_id);
create index if not exists journey_salams_seeker_idx                on public.journey_salams (seeker_id);
create index if not exists journey_stage_checkpoints_seeker_idx     on public.journey_stage_checkpoints (seeker_id);
create index if not exists matches_ended_by_idx                     on public.matches (ended_by);
create index if not exists matches_suspended_by_idx                 on public.matches (suspended_by);
create index if not exists messages_sender_idx                      on public.messages (sender_id);
create index if not exists notifications_related_match_idx          on public.notifications (related_match_id);
create index if not exists passes_passed_idx                        on public.passes (passed_id);
create index if not exists profile_reports_reporter_idx             on public.profile_reports (reporter_id);
create index if not exists profile_unlocks_unlocked_idx             on public.profile_unlocks (unlocked_id);
create index if not exists timeline_milestones_timeline_idx         on public.timeline_milestones (timeline_id);
create index if not exists unlock_credits_related_unlock_idx        on public.unlock_credits (related_unlock_id);
create index if not exists wali_invites_accepted_by_idx             on public.wali_invites (accepted_by);
create index if not exists wali_invites_inviter_idx                 on public.wali_invites (inviter_id);
create index if not exists wali_suggestions_suggested_idx           on public.wali_suggestions (suggested_id);

-- ── auth_rls_initplan · the remaining four ────────────────────────────
-- Unwrapped, auth.uid() is treated as volatile and re-evaluated for every
-- row scanned. Wrapped as (select auth.uid()) the planner hoists it into
-- an InitPlan and calls it once. Identical semantics; the difference is
-- one call versus one per row, which on a table scan is the whole cost.
--
-- matches_select matters most: it runs on every Journey list load and
-- called auth.uid() three times per row.

drop policy if exists journey_phase_ratings_own on public.journey_phase_ratings;
create policy journey_phase_ratings_own on public.journey_phase_ratings
  for all using (rater_id = (select auth.uid()))
  with check (rater_id = (select auth.uid()));

drop policy if exists matches_select on public.matches;
create policy matches_select on public.matches for select
using (
      seeker_a_id = (select auth.uid())
   or seeker_b_id = (select auth.uid())
   or ( status <> 'potential'
        and exists (
          select 1 from public.wali_links wl
          where wl.wali_id = (select auth.uid())
            and wl.status = 'active'
            and wl.seeker_id = any (array[matches.seeker_a_id, matches.seeker_b_id])
        ) )
);

drop policy if exists notifications_select on public.notifications;
create policy notifications_select on public.notifications for select
  using (user_id = (select auth.uid()));

drop policy if exists notifications_update on public.notifications;
create policy notifications_update on public.notifications for update
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- VERIFIED 2026-08-08, 11/11 — structural AND behavioural:
--   foreign keys still unindexed ................. 0
--   policies re-evaluating auth.uid() per row .... 0
--   party sees own match ......................... yes
--   rater sees own rating, other party does NOT .. yes / no  (ratings stay private)
--   owner sees own notification, other does NOT .. yes / no
--   Main Guardian sees an ACTIVE match ........... yes
--   Main Guardian sees NOTHING at 'potential' .... correct
--   stranger sees nothing ........................ correct
