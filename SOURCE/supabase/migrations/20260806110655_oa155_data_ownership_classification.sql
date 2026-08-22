-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806110655, applied name
-- 'oa155_data_ownership_classification') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- OA-ZYRA-155 — Mine / Theirs / Joint ownership, stored WITH the schema.
-- Founder approved 2026-08-06 with amendments. DR-ZYRA-121, V3 §5.
--
-- Founder: "store these ownership classifications alongside the schema so
-- they travel with the database rather than existing only in
-- documentation."
--
-- A subject access request has a 30-day statutory clock. An export routine
-- must be able to READ the classification, not have a developer re-derive
-- it from a markdown file that may have drifted.
--
-- ===================== THE VOCABULARY ==================================
--
--   joint                  a fact about the pair; disclose to either
--   mine|theirs            resolved per request against the named column
--   row-scoped(<col>)      the row belongs to whoever <col> points at
--   third-party(<who>)     belongs to someone who is NOT either Seeker
--   non-exportable         withheld regardless of who asks
--   pending-legal          NOT YET CLASSIFIED — solicitor decision open
--
-- `pending-legal` is deliberate. The Founder declined to settle message
-- export and rating disclosure without a solicitor, so those columns must
-- not carry an engineering guess. A missing classification is safe — the
-- export routine below refuses anything not explicitly cleared. A WRONG
-- classification is not.

-- ---------------------------------------------------------------- conversations
comment on column public.conversations.match_id   is 'OWNERSHIP: joint';
comment on column public.conversations.status     is 'OWNERSHIP: joint';
comment on column public.conversations.closed_at  is
  'OWNERSHIP: joint — that the conversation closed is observable to both. WHO closed it lives on matches.ended_by.';
comment on column public.conversations.created_at is 'OWNERSHIP: joint';

-- ---------------------------------------------------------------- messages
comment on column public.messages.sender_id  is 'OWNERSHIP: row-scoped(sender_id)';
comment on column public.messages.content    is
  'OWNERSHIP: pending-legal — Founder 2026-08-06: whether messages the OTHER party sent appear in a subject access export is for the solicitor, not engineering. Withhold until confirmed.';
comment on column public.messages.read_at    is
  'OWNERSHIP: pending-legal — records the recipient''s behaviour, not the sender''s. Same solicitor question.';
comment on column public.messages.deleted_at is 'OWNERSHIP: row-scoped(sender_id)';

-- ---------------------------------------------------------------- journey_compatibility
comment on column public.journey_compatibility.seeker_a_revealed is
  'OWNERSHIP: row-scoped(matches.seeker_a_id) — one person''s choice to reveal';
comment on column public.journey_compatibility.seeker_b_revealed is
  'OWNERSHIP: row-scoped(matches.seeker_b_id)';
comment on column public.journey_compatibility.overall_score    is
  'OWNERSHIP: joint — computed from both; meaningless about one person alone';
comment on column public.journey_compatibility.category_scores  is 'OWNERSHIP: joint';
comment on column public.journey_compatibility.revealed_at      is 'OWNERSHIP: joint';

-- ---------------------------------------------------------------- journey_salams
comment on column public.journey_salams.seeker_id is 'OWNERSHIP: row-scoped(seeker_id)';
comment on column public.journey_salams.sent_at   is 'OWNERSHIP: row-scoped(seeker_id)';

-- ---------------------------------------------------------------- journey_phase_answers
comment on column public.journey_phase_answers.seeker_id   is 'OWNERSHIP: row-scoped(seeker_id)';
comment on column public.journey_phase_answers.answer_text is
  'OWNERSHIP: row-scoped(seeker_id) — highest-sensitivity free text in the Journey set. The other party''s answers must never appear in an export.';

-- ---------------------------------------------------------------- journey_phase_ratings
comment on column public.journey_phase_ratings.rater_id is 'OWNERSHIP: row-scoped(rater_id)';
comment on column public.journey_phase_ratings.rating   is
  'OWNERSHIP: pending-legal — Founder 2026-08-06: whether "they rated you Amber" must be disclosed under Art.15''s source limb is a legal question. A rating I gave is mine; a rating of me is theirs. Withhold until confirmed.';

-- ---------------------------------------------------------------- journey_phase_checkpoints
comment on column public.journey_phase_checkpoints.seeker_id is 'OWNERSHIP: row-scoped(seeker_id)';
comment on column public.journey_phase_checkpoints.decision  is
  'OWNERSHIP: row-scoped(seeker_id) — their decision to continue or end is theirs, even though the outcome affected both.';

-- ---------------------------------------------------------------- journey_family_answers
comment on column public.journey_family_answers.answerer_id is
  'OWNERSHIP: row-scoped(answerer_id) — MAY BE A GUARDIAN, not a Seeker. A Guardian''s answers belong to that Guardian and reach neither Seeker''s export.';
comment on column public.journey_family_answers.answer_text is
  'OWNERSHIP: row-scoped(answerer_id) — see answerer_id.';

-- ---------------------------------------------------------------- journey_family_reviews
comment on column public.journey_family_reviews.status      is
  'OWNERSHIP: joint — the OUTCOME is disclosable. Individual Guardian decisions are not (see journey_family_review_responses).';
comment on column public.journey_family_reviews.from_stage  is 'OWNERSHIP: joint';
comment on column public.journey_family_reviews.to_stage    is 'OWNERSHIP: joint';
comment on column public.journey_family_reviews.opened_at   is 'OWNERSHIP: joint';
comment on column public.journey_family_reviews.deadline_at is 'OWNERSHIP: joint';
comment on column public.journey_family_reviews.resolved_at is 'OWNERSHIP: joint';

-- ---------------------------------------------------------------- journey_family_review_responses
-- Founder approved 2026-08-06: "Guardian decisions must remain private to
-- the Guardian. Seekers should only receive the Family Review outcome,
-- never individual Guardian decisions or comments."
comment on table public.journey_family_review_responses is
  'OWNERSHIP: third-party(guardian). NEVER exported to either Seeker. A Guardian is a data subject in their own right; my own Guardian''s decision is not my personal data. A Guardian pausing a Journey, and that being exportable to the Seeker they paused, is a family-safety problem as well as a privacy one.';
comment on column public.journey_family_review_responses.wali_id      is
  'OWNERSHIP: third-party(guardian) — non-exportable to Seekers';
comment on column public.journey_family_review_responses.decision     is
  'OWNERSHIP: third-party(guardian) — non-exportable to Seekers. Only the aggregate review outcome is disclosable.';
comment on column public.journey_family_review_responses.responded_at is
  'OWNERSHIP: third-party(guardian) — non-exportable to Seekers';

-- ---------------------------------------------------------------- timelines
comment on column public.timelines.match_id                  is 'OWNERSHIP: joint';
comment on column public.timeline_milestones.milestone_type  is 'OWNERSHIP: joint';
comment on column public.timeline_milestones.occurred_at     is 'OWNERSHIP: joint';
comment on column public.timeline_milestones.metadata        is
  'OWNERSHIP: non-exportable — Founder approved 2026-08-06. Unconstrained jsonb; until it has a defined schema it cannot inherit a class its future contents may not deserve. Loosen later if appropriate, never the other way round.';

-- ---------------------------------------------------------------- matches
comment on column public.matches.status       is 'OWNERSHIP: joint';
comment on column public.matches.journey_stage is 'OWNERSHIP: joint';
comment on column public.matches.ended_at     is 'OWNERSHIP: joint';
comment on column public.matches.ended_by     is 'OWNERSHIP: joint — who ended it is knowable to both';
comment on column public.matches.end_note     is 'OWNERSHIP: joint — written TO the other person. Constraint forbids one on a safety ending.';
comment on column public.matches.suspended_by is 'OWNERSHIP: joint — the other party is told a pause happened';
comment on column public.matches.suspended_at is 'OWNERSHIP: joint';
comment on column public.matches.end_reason   is
  'OWNERSHIP: per-value. joint for the five stated reasons (V3 §8: a stated reason is kinder than silence). safety_concern is row-scoped(ended_by) and MUST NEVER reach the other party by export or any indirect route — otherwise the export becomes the disclosure channel V3 §3 and §11 exist to close.';

-- ---------------------------------------------------------------- attachments, in advance
-- Founder additional requirement, 2026-08-06: "I want this ownership
-- framework to explicitly cover future attachment-based data from the
-- beginning — uploaded documents, evidence, voice notes, photos, future
-- file attachments. These should adopt the same Mine / Theirs / Joint
-- model rather than introducing a separate system later."
--
-- profile_photos is the only attachment table that exists today. Classified
-- now so the rule is established before there are five more.
comment on table public.profile_photos is
  'OWNERSHIP: row-scoped(user_id). Attachment data follows the same Mine/Theirs/Joint model as Journey data — Founder requirement 2026-08-06. Any future attachment table (documents, evidence, voice notes, media) MUST carry an OWNERSHIP comment on its author column before it is used, and the binary in Storage inherits its row''s class.';
comment on column public.profile_photos.user_id      is 'OWNERSHIP: row-scoped(user_id)';
comment on column public.profile_photos.storage_path is
  'OWNERSHIP: row-scoped(user_id) — the Storage object inherits the row''s class. An export must include the FILE, not just the path.';

-- ===================== THE AUDIT VIEW ==================================
-- Self-enforcing: a new column on a classified table shows up here as
-- UNCLASSIFIED the moment it is added, rather than being discovered during
-- a subject access request.

create or replace view public.zyra_data_ownership as
select
  c.table_name,
  c.column_name,
  coalesce(
    substring(pgd.description from 'OWNERSHIP:\s*([a-z\-]+(\([^)]*\))?)'),
    '*** UNCLASSIFIED ***'
  ) as ownership,
  pgd.description as note
from information_schema.columns c
join pg_class     cl on cl.relname = c.table_name
join pg_namespace ns on ns.oid = cl.relnamespace and ns.nspname = c.table_schema
left join pg_description pgd
       on pgd.objoid = cl.oid and pgd.objsubid = c.ordinal_position
where c.table_schema = 'public'
  and c.table_name in (
    'conversations','messages','journey_compatibility','journey_salams',
    'journey_phase_answers','journey_phase_ratings','journey_phase_checkpoints',
    'journey_family_answers','journey_family_reviews',
    'journey_family_review_responses','timelines','timeline_milestones',
    'matches','profile_photos')
  -- Surrogate keys and FKs carry no ownership of their own; they follow
  -- their row. Excluded so the view shows real gaps rather than noise.
  and c.column_name not in ('id','match_id','conversation_id','timeline_id',
                            'review_id','created_at','phase','question_id',
                            'direction');

comment on view public.zyra_data_ownership is
  'OA-ZYRA-155. Every classified column and its Mine/Theirs/Joint class, read from column comments. Rows showing UNCLASSIFIED or pending-legal must not be exported. Query this before writing any subject-access export.';

revoke all on public.zyra_data_ownership from public, anon, authenticated;
