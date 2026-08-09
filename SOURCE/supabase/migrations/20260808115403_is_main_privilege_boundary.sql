-- APPLIED LIVE 2026-08-08, version 20260808115403. Item 2. STRICT REDUCTION.
-- Rationale: GUARDIAN & ROMANTIC RULES section 7d.
--
-- is_main was a label, not a tier. Audit of every object reading
-- wali_links: 13 honour it, 8 ignore it — and the split is not random.
-- Family Review, Guardian management and the PAID guardians_for_unlocked()
-- all treat Main as a privilege boundary. The visibility layer, which
-- accreted, did not. This brings the five stragglers into line.
--
-- `is_main IS TRUE` — the column is NULL on seeker rows of the view, and
-- NULL is not false in a policy predicate.

drop policy if exists conversations_select on public.conversations;
create policy conversations_select on public.conversations for select
using (exists (select 1 from public.zyra_my_attempt_participation r
  where r.attempt_id = conversations.attempt_id
    and (r.role = 'seeker' or (r.is_main is true and r.attempt_status <> 'potential'))));

-- Narrows WHO among Guardians may read the conversation. Whether ANY
-- should is a live Founder question ("full-conversation Guardian read:
-- default OFF, consented option") — Main-only is a reduction meanwhile,
-- not an answer to it.
drop policy if exists messages_select on public.messages;
create policy messages_select on public.messages for select
using (exists (select 1 from public.conversations c
  join public.zyra_my_attempt_participation r on r.attempt_id = c.attempt_id
  where c.id = messages.conversation_id
    and (r.role = 'seeker' or (r.is_main is true and r.attempt_status <> 'potential'))));

drop policy if exists timelines_select on public.timelines;
create policy timelines_select on public.timelines for select
using (exists (select 1 from public.zyra_my_attempt_participation r
  where r.attempt_id = timelines.attempt_id
    and (r.role = 'seeker' or (r.is_main is true and r.attempt_status <> 'potential'))));

drop policy if exists timeline_milestones_select on public.timeline_milestones;
create policy timeline_milestones_select on public.timeline_milestones for select
using (exists (select 1 from public.timelines t
  join public.zyra_my_attempt_participation r on r.attempt_id = t.attempt_id
  where t.id = timeline_milestones.timeline_id
    and (r.role = 'seeker' or (r.is_main is true and r.attempt_status <> 'potential'))));

-- This one had NO role filter at all — every Guardian of either family
-- could read the Family Stage answers. No status guard added: family
-- answers only exist at family_stage, which is post-potential by
-- construction, so it would be unreachable code rather than a control.
drop policy if exists journey_family_answers_read on public.journey_family_answers;
create policy journey_family_answers_read on public.journey_family_answers for select
using (exists (select 1 from public.zyra_my_attempt_participation r
  where r.attempt_id = journey_family_answers.attempt_id
    and (r.role = 'seeker' or r.is_main is true)));

-- Left as found, already correct, and the pattern the above copies:
--   journey_family_reviews_read · journey_family_review_responses_read
-- Left as found, seeker-only, no Guardian branch to narrow:
--   messages_insert · journey_salams_* · journey_phase_* ·
--   journey_compatibility_* · journey_stage_checkpoints_read
--
-- VERIFIED 2026-08-08, 14/14: Main keeps conversation, messages,
-- timeline, milestones and family answers; Additional gets none of them;
-- Seeker access unchanged on all five.
