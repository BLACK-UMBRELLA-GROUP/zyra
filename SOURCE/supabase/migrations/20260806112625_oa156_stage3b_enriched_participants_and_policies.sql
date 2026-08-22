-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806112625, applied name
-- 'oa156_stage3b_enriched_participants_and_policies') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- OA-ZYRA-156 STAGE 3b — enriched participant view, 19 policies rewritten.
-- Founder approved 2026-08-06 after V3 §4's premise was disproved.
--
-- ================== WHAT V3 §4 GOT WRONG ================================
-- It said fifteen policies "each re-deriving the same authorisation
-- question". There are NINETEEN, and they encode FOUR questions:
--
--   A  seekers ONLY, no Guardian at all
--      journey_compatibility · journey_phase_answers ·
--      journey_phase_checkpoints · journey_salams
--   B  seekers + ANY active Guardian          journey_family_answers
--   C  seekers + Guardian once status <> 'potential'
--      conversations · messages · timelines · timeline_milestones
--   D  seekers + MAIN Guardian only (is_main)
--      journey_family_reviews · journey_family_review_responses
--
-- They share a JOIN, not a QUESTION. Pointing all nineteen at the boolean
-- zyra_can_view_attempt() would have handed Guardians the private phase
-- answers Seekers write (A), shown them Journeys that had not started (C),
-- and let every additional Guardian read Family Review decisions the
-- ownership classification makes private to the Guardian who made them (D).
--
-- THE SHAPE APPROVED: one participant source carrying the attributes
-- policies need; one boolean authorisation function; policies expressing
-- their own rule. The view removes duplicated RELATIONSHIP RESOLUTION —
-- not legitimate business-rule differences.
--
-- New columns are APPENDED, not reordered: `create or replace view` cannot
-- rename or reposition existing columns, and dropping the view would take
-- zyra_can_view_profile with it — which profiles_select depends on, and
-- which governs Browse.

create or replace view public.zyra_attempt_participant_rows as
  select a.id as attempt_id, m.seeker_a_id as user_id, 'seeker'::text as role,
         a.match_id, null::boolean as is_main, a.status as attempt_status
    from public.journey_attempts a join public.matches m on m.id = a.match_id
  union all
  select a.id, m.seeker_b_id, 'seeker', a.match_id, null::boolean, a.status
    from public.journey_attempts a join public.matches m on m.id = a.match_id
  union all
  -- Guardians from wali_links as it is now. V3 §10 wants this per attempt;
  -- that join table does not exist and inventing per-attempt Guardian
  -- history would be fabricating a record (Founder agreed 2026-08-06).
  select a.id, w.wali_id, 'guardian', a.match_id, w.is_main, a.status
    from public.journey_attempts a
    join public.matches   m on m.id = a.match_id
    join public.wali_links w on w.status = 'active'
                            and w.seeker_id in (m.seeker_a_id, m.seeker_b_id);

comment on view public.zyra_attempt_participant_rows is
  'SINGLE SOURCE of Journey participation. Carries role, is_main and attempt_status so each policy expresses its own rule without re-deriving WHO is party to the attempt. Add a new participant role HERE and nowhere else. 19 policies read this and ask four different questions of it, deliberately.';

revoke all on public.zyra_attempt_participant_rows from public, anon, authenticated;

drop function if exists public.zyra_attempt_participants(uuid);
create function public.zyra_attempt_participants(p_attempt uuid)
returns table (user_id uuid, role text, is_main boolean, attempt_status text)
language sql stable security definer set search_path to 'public'
as $$
  select r.user_id, r.role, r.is_main, r.attempt_status
  from public.zyra_attempt_participant_rows r
  where r.attempt_id = p_attempt;
$$;
revoke all on function public.zyra_attempt_participants(uuid) from public, anon;
grant execute on function public.zyra_attempt_participants(uuid) to authenticated;

-- COLUMNS: the nine tables still key off match_id. Re-pointing them to
-- attempt_id is STAGE 4, alongside the Dart changes — splitting a column
-- swap from the code that writes it is how you get a half-migrated state.
-- The view carries match_id so this stage needs no column change and
-- stage 4 becomes mechanical.

-- ============================ SHAPE A: SEEKERS ONLY ====================
drop policy if exists journey_compatibility_read   on public.journey_compatibility;
drop policy if exists journey_compatibility_insert on public.journey_compatibility;
drop policy if exists journey_compatibility_update on public.journey_compatibility;
create policy journey_compatibility_read on public.journey_compatibility for select
  using (exists (select 1 from public.zyra_attempt_participant_rows r
                 where r.match_id = journey_compatibility.match_id
                   and r.user_id = (select auth.uid()) and r.role = 'seeker'));
create policy journey_compatibility_insert on public.journey_compatibility for insert
  with check (exists (select 1 from public.zyra_attempt_participant_rows r
                      where r.match_id = journey_compatibility.match_id
                        and r.user_id = (select auth.uid()) and r.role = 'seeker'));
create policy journey_compatibility_update on public.journey_compatibility for update
  using (exists (select 1 from public.zyra_attempt_participant_rows r
                 where r.match_id = journey_compatibility.match_id
                   and r.user_id = (select auth.uid()) and r.role = 'seeker'));

drop policy if exists journey_phase_answers_read  on public.journey_phase_answers;
drop policy if exists journey_phase_answers_write on public.journey_phase_answers;
create policy journey_phase_answers_read on public.journey_phase_answers for select
  using (exists (select 1 from public.zyra_attempt_participant_rows r
                 where r.match_id = journey_phase_answers.match_id
                   and r.user_id = (select auth.uid()) and r.role = 'seeker'));
create policy journey_phase_answers_write on public.journey_phase_answers for insert
  with check (seeker_id = (select auth.uid())
              and exists (select 1 from public.zyra_attempt_participant_rows r
                          where r.match_id = journey_phase_answers.match_id
                            and r.user_id = (select auth.uid()) and r.role = 'seeker'));

drop policy if exists journey_phase_checkpoints_read  on public.journey_phase_checkpoints;
drop policy if exists journey_phase_checkpoints_write on public.journey_phase_checkpoints;
create policy journey_phase_checkpoints_read on public.journey_phase_checkpoints for select
  using (exists (select 1 from public.zyra_attempt_participant_rows r
                 where r.match_id = journey_phase_checkpoints.match_id
                   and r.user_id = (select auth.uid()) and r.role = 'seeker'));
create policy journey_phase_checkpoints_write on public.journey_phase_checkpoints for insert
  with check (seeker_id = (select auth.uid())
              and exists (select 1 from public.zyra_attempt_participant_rows r
                          where r.match_id = journey_phase_checkpoints.match_id
                            and r.user_id = (select auth.uid()) and r.role = 'seeker'));

drop policy if exists journey_salams_read  on public.journey_salams;
drop policy if exists journey_salams_write on public.journey_salams;
create policy journey_salams_read on public.journey_salams for select
  using (exists (select 1 from public.zyra_attempt_participant_rows r
                 where r.match_id = journey_salams.match_id
                   and r.user_id = (select auth.uid()) and r.role = 'seeker'));
create policy journey_salams_write on public.journey_salams for insert
  with check (seeker_id = (select auth.uid())
              and exists (select 1 from public.zyra_attempt_participant_rows r
                          where r.match_id = journey_salams.match_id
                            and r.user_id = (select auth.uid()) and r.role = 'seeker'));

-- ==================== SHAPE B: SEEKERS + ANY GUARDIAN ==================
drop policy if exists journey_family_answers_read  on public.journey_family_answers;
drop policy if exists journey_family_answers_write on public.journey_family_answers;
create policy journey_family_answers_read on public.journey_family_answers for select
  using (exists (select 1 from public.zyra_attempt_participant_rows r
                 where r.match_id = journey_family_answers.match_id
                   and r.user_id = (select auth.uid())));
create policy journey_family_answers_write on public.journey_family_answers for insert
  with check (answerer_id = (select auth.uid()));

-- ============ SHAPE C: SEEKERS ALWAYS, GUARDIAN ONCE STARTED ===========
drop policy if exists conversations_select on public.conversations;
create policy conversations_select on public.conversations for select
  using (exists (select 1 from public.zyra_attempt_participant_rows r
                 where r.match_id = conversations.match_id
                   and r.user_id = (select auth.uid())
                   and (r.role = 'seeker' or r.attempt_status <> 'potential')));

drop policy if exists messages_select on public.messages;
drop policy if exists messages_insert on public.messages;
create policy messages_select on public.messages for select
  using (exists (select 1 from public.conversations c
                 join public.zyra_attempt_participant_rows r on r.match_id = c.match_id
                 where c.id = messages.conversation_id
                   and r.user_id = (select auth.uid())
                   and (r.role = 'seeker' or r.attempt_status <> 'potential')));
create policy messages_insert on public.messages for insert
  with check (sender_id = (select auth.uid())
              and exists (select 1 from public.conversations c
                          join public.zyra_attempt_participant_rows r on r.match_id = c.match_id
                          where c.id = messages.conversation_id
                            and r.user_id = (select auth.uid()) and r.role = 'seeker'));

drop policy if exists timelines_select on public.timelines;
create policy timelines_select on public.timelines for select
  using (exists (select 1 from public.zyra_attempt_participant_rows r
                 where r.match_id = timelines.match_id
                   and r.user_id = (select auth.uid())
                   and (r.role = 'seeker' or r.attempt_status <> 'potential')));

drop policy if exists timeline_milestones_select on public.timeline_milestones;
create policy timeline_milestones_select on public.timeline_milestones for select
  using (exists (select 1 from public.timelines t
                 join public.zyra_attempt_participant_rows r on r.match_id = t.match_id
                 where t.id = timeline_milestones.timeline_id
                   and r.user_id = (select auth.uid())
                   and (r.role = 'seeker' or r.attempt_status <> 'potential')));

-- ================= SHAPE D: SEEKERS + MAIN GUARDIAN ONLY ===============
drop policy if exists journey_family_reviews_read on public.journey_family_reviews;
create policy journey_family_reviews_read on public.journey_family_reviews for select
  using (exists (select 1 from public.zyra_attempt_participant_rows r
                 where r.match_id = journey_family_reviews.match_id
                   and r.user_id = (select auth.uid())
                   and (r.role = 'seeker' or r.is_main = true)));

drop policy if exists journey_family_review_responses_read on public.journey_family_review_responses;
create policy journey_family_review_responses_read on public.journey_family_review_responses for select
  using (exists (select 1 from public.journey_family_reviews rev
                 join public.zyra_attempt_participant_rows r on r.match_id = rev.match_id
                 where rev.id = journey_family_review_responses.review_id
                   and r.user_id = (select auth.uid())
                   and (r.role = 'seeker' or r.is_main = true)));

-- journey_phase_ratings_own untouched: rater_id = auth.uid() involves no
-- relationship resolution, so it has nothing to share with the view.
