-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806113329, applied name
-- 'oa156_stage4b_policies_on_attempt_id') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- OA-ZYRA-156 STAGE 4b — the 19 policies now resolve through attempt_id.
--
-- Behaviour must be identical to 3b. The only change is which column joins
-- the row to the participant projection: attempt_id rather than match_id.
--
-- Safe because stage 4a made attempt_id correct-by-construction — the
-- backfill covered existing rows and a BEFORE INSERT trigger fills it on
-- every new one, so there is no window where a row exists without an
-- attempt and is therefore invisible to its own participants.
--
-- Shape A seekers only · B seekers + any Guardian ·
-- C seekers always, Guardian once started · D seekers + MAIN Guardian.

-- ============================ SHAPE A ==================================
drop policy if exists journey_compatibility_read   on public.journey_compatibility;
drop policy if exists journey_compatibility_insert on public.journey_compatibility;
drop policy if exists journey_compatibility_update on public.journey_compatibility;
create policy journey_compatibility_read on public.journey_compatibility for select
  using (exists (select 1 from public.zyra_my_attempt_participation r
                 where r.attempt_id = journey_compatibility.attempt_id and r.role = 'seeker'));
create policy journey_compatibility_insert on public.journey_compatibility for insert
  with check (exists (select 1 from public.zyra_my_attempt_participation r
                      where r.match_id = journey_compatibility.match_id and r.role = 'seeker'));
create policy journey_compatibility_update on public.journey_compatibility for update
  using (exists (select 1 from public.zyra_my_attempt_participation r
                 where r.attempt_id = journey_compatibility.attempt_id and r.role = 'seeker'));

drop policy if exists journey_phase_answers_read  on public.journey_phase_answers;
drop policy if exists journey_phase_answers_write on public.journey_phase_answers;
create policy journey_phase_answers_read on public.journey_phase_answers for select
  using (exists (select 1 from public.zyra_my_attempt_participation r
                 where r.attempt_id = journey_phase_answers.attempt_id and r.role = 'seeker'));
create policy journey_phase_answers_write on public.journey_phase_answers for insert
  with check (seeker_id = (select auth.uid())
              and exists (select 1 from public.zyra_my_attempt_participation r
                          where r.match_id = journey_phase_answers.match_id and r.role = 'seeker'));

drop policy if exists journey_phase_checkpoints_read  on public.journey_phase_checkpoints;
drop policy if exists journey_phase_checkpoints_write on public.journey_phase_checkpoints;
create policy journey_phase_checkpoints_read on public.journey_phase_checkpoints for select
  using (exists (select 1 from public.zyra_my_attempt_participation r
                 where r.attempt_id = journey_phase_checkpoints.attempt_id and r.role = 'seeker'));
create policy journey_phase_checkpoints_write on public.journey_phase_checkpoints for insert
  with check (seeker_id = (select auth.uid())
              and exists (select 1 from public.zyra_my_attempt_participation r
                          where r.match_id = journey_phase_checkpoints.match_id and r.role = 'seeker'));

drop policy if exists journey_salams_read  on public.journey_salams;
drop policy if exists journey_salams_write on public.journey_salams;
create policy journey_salams_read on public.journey_salams for select
  using (exists (select 1 from public.zyra_my_attempt_participation r
                 where r.attempt_id = journey_salams.attempt_id and r.role = 'seeker'));
create policy journey_salams_write on public.journey_salams for insert
  with check (seeker_id = (select auth.uid())
              and exists (select 1 from public.zyra_my_attempt_participation r
                          where r.match_id = journey_salams.match_id and r.role = 'seeker'));

-- ============================ SHAPE B ==================================
drop policy if exists journey_family_answers_read  on public.journey_family_answers;
drop policy if exists journey_family_answers_write on public.journey_family_answers;
create policy journey_family_answers_read on public.journey_family_answers for select
  using (exists (select 1 from public.zyra_my_attempt_participation r
                 where r.attempt_id = journey_family_answers.attempt_id));
create policy journey_family_answers_write on public.journey_family_answers for insert
  with check (answerer_id = (select auth.uid()));

-- ============================ SHAPE C ==================================
drop policy if exists conversations_select on public.conversations;
create policy conversations_select on public.conversations for select
  using (exists (select 1 from public.zyra_my_attempt_participation r
                 where r.attempt_id = conversations.attempt_id
                   and (r.role = 'seeker' or r.attempt_status <> 'potential')));

drop policy if exists messages_select on public.messages;
drop policy if exists messages_insert on public.messages;
create policy messages_select on public.messages for select
  using (exists (select 1 from public.conversations c
                 join public.zyra_my_attempt_participation r on r.attempt_id = c.attempt_id
                 where c.id = messages.conversation_id
                   and (r.role = 'seeker' or r.attempt_status <> 'potential')));
create policy messages_insert on public.messages for insert
  with check (sender_id = (select auth.uid())
              and exists (select 1 from public.conversations c
                          join public.zyra_my_attempt_participation r on r.attempt_id = c.attempt_id
                          where c.id = messages.conversation_id and r.role = 'seeker'));

drop policy if exists timelines_select on public.timelines;
create policy timelines_select on public.timelines for select
  using (exists (select 1 from public.zyra_my_attempt_participation r
                 where r.attempt_id = timelines.attempt_id
                   and (r.role = 'seeker' or r.attempt_status <> 'potential')));

drop policy if exists timeline_milestones_select on public.timeline_milestones;
create policy timeline_milestones_select on public.timeline_milestones for select
  using (exists (select 1 from public.timelines t
                 join public.zyra_my_attempt_participation r on r.attempt_id = t.attempt_id
                 where t.id = timeline_milestones.timeline_id
                   and (r.role = 'seeker' or r.attempt_status <> 'potential')));

-- ============================ SHAPE D ==================================
drop policy if exists journey_family_reviews_read on public.journey_family_reviews;
create policy journey_family_reviews_read on public.journey_family_reviews for select
  using (exists (select 1 from public.zyra_my_attempt_participation r
                 where r.attempt_id = journey_family_reviews.attempt_id
                   and (r.role = 'seeker' or r.is_main = true)));

drop policy if exists journey_family_review_responses_read on public.journey_family_review_responses;
create policy journey_family_review_responses_read on public.journey_family_review_responses for select
  using (exists (select 1 from public.journey_family_reviews rev
                 join public.zyra_my_attempt_participation r on r.attempt_id = rev.attempt_id
                 where rev.id = journey_family_review_responses.review_id
                   and (r.role = 'seeker' or r.is_main = true)));

-- INSERT policies still resolve via match_id, deliberately. A BEFORE INSERT
-- trigger fills attempt_id, but WITH CHECK is evaluated against the NEW row
-- AFTER triggers have run — and relying on that ordering to authorise a
-- write would be a subtle dependency to leave undocumented. match_id is
-- supplied by the client and present at check time either way. These move
-- in 4d, when the client writes attempt_id directly.
