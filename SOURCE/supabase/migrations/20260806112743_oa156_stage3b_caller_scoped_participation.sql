-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806112743, applied name
-- 'oa156_stage3b_caller_scoped_participation') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- OA-ZYRA-156 STAGE 3b, correction.
--
-- THE BUG I SHIPPED MINUTES AGO: the 19 rewritten policies read
-- zyra_attempt_participant_rows, but that view is revoked from
-- `authenticated`. An RLS policy is evaluated as the QUERYING role, not as
-- the table owner — unlike a SECURITY DEFINER function. So every rewritten
-- policy failed with "permission denied for view", which is a hard denial
-- rather than an empty result. Caught by the verification run immediately
-- after applying it.
--
-- AND THE OBVIOUS FIX IS WRONG. Granting SELECT on the base view would leak
-- the entire participation table: a Postgres view defaults to
-- security_invoker = false, so it runs with the OWNER's privileges and
-- bypasses RLS on journey_attempts and matches. Any signed-in user could
-- read who is party to every Journey on the platform.
--
-- THE FIX: a caller-scoped projection. One definition of participation
-- still — zyra_attempt_participant_rows — plus a view of it filtered to
-- the current user, which is safe to grant precisely because it can only
-- ever return your own rows.
--
-- This is strictly better than what I first wrote. The policies no longer
-- carry `user_id = auth.uid()` themselves, so a policy CANNOT forget it.
-- The filter is structural rather than repeated nineteen times.

create or replace view public.zyra_my_attempt_participation as
  select attempt_id, role, match_id, is_main, attempt_status
  from public.zyra_attempt_participant_rows
  where user_id = (select auth.uid());

comment on view public.zyra_my_attempt_participation is
  'Caller-scoped projection of zyra_attempt_participant_rows — YOUR participation only. Safe to grant because it cannot return another user''s rows. RLS policies read THIS; the unscoped base view stays revoked because a view bypasses RLS on its base tables.';

grant select on public.zyra_my_attempt_participation to authenticated;
revoke all on public.zyra_attempt_participant_rows from public, anon, authenticated;

-- ============================ SHAPE A: SEEKERS ONLY ====================
drop policy if exists journey_compatibility_read   on public.journey_compatibility;
drop policy if exists journey_compatibility_insert on public.journey_compatibility;
drop policy if exists journey_compatibility_update on public.journey_compatibility;
create policy journey_compatibility_read on public.journey_compatibility for select
  using (exists (select 1 from public.zyra_my_attempt_participation r
                 where r.match_id = journey_compatibility.match_id and r.role = 'seeker'));
create policy journey_compatibility_insert on public.journey_compatibility for insert
  with check (exists (select 1 from public.zyra_my_attempt_participation r
                      where r.match_id = journey_compatibility.match_id and r.role = 'seeker'));
create policy journey_compatibility_update on public.journey_compatibility for update
  using (exists (select 1 from public.zyra_my_attempt_participation r
                 where r.match_id = journey_compatibility.match_id and r.role = 'seeker'));

drop policy if exists journey_phase_answers_read  on public.journey_phase_answers;
drop policy if exists journey_phase_answers_write on public.journey_phase_answers;
create policy journey_phase_answers_read on public.journey_phase_answers for select
  using (exists (select 1 from public.zyra_my_attempt_participation r
                 where r.match_id = journey_phase_answers.match_id and r.role = 'seeker'));
create policy journey_phase_answers_write on public.journey_phase_answers for insert
  with check (seeker_id = (select auth.uid())
              and exists (select 1 from public.zyra_my_attempt_participation r
                          where r.match_id = journey_phase_answers.match_id and r.role = 'seeker'));

drop policy if exists journey_phase_checkpoints_read  on public.journey_phase_checkpoints;
drop policy if exists journey_phase_checkpoints_write on public.journey_phase_checkpoints;
create policy journey_phase_checkpoints_read on public.journey_phase_checkpoints for select
  using (exists (select 1 from public.zyra_my_attempt_participation r
                 where r.match_id = journey_phase_checkpoints.match_id and r.role = 'seeker'));
create policy journey_phase_checkpoints_write on public.journey_phase_checkpoints for insert
  with check (seeker_id = (select auth.uid())
              and exists (select 1 from public.zyra_my_attempt_participation r
                          where r.match_id = journey_phase_checkpoints.match_id and r.role = 'seeker'));

drop policy if exists journey_salams_read  on public.journey_salams;
drop policy if exists journey_salams_write on public.journey_salams;
create policy journey_salams_read on public.journey_salams for select
  using (exists (select 1 from public.zyra_my_attempt_participation r
                 where r.match_id = journey_salams.match_id and r.role = 'seeker'));
create policy journey_salams_write on public.journey_salams for insert
  with check (seeker_id = (select auth.uid())
              and exists (select 1 from public.zyra_my_attempt_participation r
                          where r.match_id = journey_salams.match_id and r.role = 'seeker'));

-- ==================== SHAPE B: SEEKERS + ANY GUARDIAN ==================
drop policy if exists journey_family_answers_read  on public.journey_family_answers;
drop policy if exists journey_family_answers_write on public.journey_family_answers;
create policy journey_family_answers_read on public.journey_family_answers for select
  using (exists (select 1 from public.zyra_my_attempt_participation r
                 where r.match_id = journey_family_answers.match_id));
create policy journey_family_answers_write on public.journey_family_answers for insert
  with check (answerer_id = (select auth.uid()));

-- ============ SHAPE C: SEEKERS ALWAYS, GUARDIAN ONCE STARTED ===========
drop policy if exists conversations_select on public.conversations;
create policy conversations_select on public.conversations for select
  using (exists (select 1 from public.zyra_my_attempt_participation r
                 where r.match_id = conversations.match_id
                   and (r.role = 'seeker' or r.attempt_status <> 'potential')));

drop policy if exists messages_select on public.messages;
drop policy if exists messages_insert on public.messages;
create policy messages_select on public.messages for select
  using (exists (select 1 from public.conversations c
                 join public.zyra_my_attempt_participation r on r.match_id = c.match_id
                 where c.id = messages.conversation_id
                   and (r.role = 'seeker' or r.attempt_status <> 'potential')));
create policy messages_insert on public.messages for insert
  with check (sender_id = (select auth.uid())
              and exists (select 1 from public.conversations c
                          join public.zyra_my_attempt_participation r on r.match_id = c.match_id
                          where c.id = messages.conversation_id and r.role = 'seeker'));

drop policy if exists timelines_select on public.timelines;
create policy timelines_select on public.timelines for select
  using (exists (select 1 from public.zyra_my_attempt_participation r
                 where r.match_id = timelines.match_id
                   and (r.role = 'seeker' or r.attempt_status <> 'potential')));

drop policy if exists timeline_milestones_select on public.timeline_milestones;
create policy timeline_milestones_select on public.timeline_milestones for select
  using (exists (select 1 from public.timelines t
                 join public.zyra_my_attempt_participation r on r.match_id = t.match_id
                 where t.id = timeline_milestones.timeline_id
                   and (r.role = 'seeker' or r.attempt_status <> 'potential')));

-- ================= SHAPE D: SEEKERS + MAIN GUARDIAN ONLY ===============
drop policy if exists journey_family_reviews_read on public.journey_family_reviews;
create policy journey_family_reviews_read on public.journey_family_reviews for select
  using (exists (select 1 from public.zyra_my_attempt_participation r
                 where r.match_id = journey_family_reviews.match_id
                   and (r.role = 'seeker' or r.is_main = true)));

drop policy if exists journey_family_review_responses_read on public.journey_family_review_responses;
create policy journey_family_review_responses_read on public.journey_family_review_responses for select
  using (exists (select 1 from public.journey_family_reviews rev
                 join public.zyra_my_attempt_participation r on r.match_id = rev.match_id
                 where rev.id = journey_family_review_responses.review_id
                   and (r.role = 'seeker' or r.is_main = true)));
