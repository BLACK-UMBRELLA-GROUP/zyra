-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806111219, applied name
-- 'ownership_platform_wide_and_self_maintaining_view') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Founder notes 1 and 2, 2026-08-06. Platform-wide standard, and a view
-- that cannot silently miss a new table.
--
-- THE VIEW AS FIRST BUILT COULD NOT MEET NOTE 2. It carried a hardcoded
-- list of 14 tables, so a new table would not appear until somebody
-- remembered to add it — precisely the drift the requirement exists to
-- prevent. A safety net you have to remember to extend is not a safety net.
--
-- Inverted: it now scans every table in `public`. New tables are
-- UNCLASSIFIED by default and visible the moment they are created.
--
-- All 30 current tables hold personal data, so there is no exclusion list.
-- If a genuinely impersonal table is ever added, classify it explicitly as
-- 'not-personal-data' rather than teaching the view to ignore things.

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
join pg_tables    t  on t.tablename = c.table_name and t.schemaname = c.table_schema
left join pg_description pgd
       on pgd.objoid = cl.oid and pgd.objsubid = c.ordinal_position
where c.table_schema = 'public'
  -- Plumbing. Surrogate keys, FKs and row timestamps follow their row and
  -- carry no ownership of their own; excluded so the view shows real gaps.
  and c.column_name not in (
    'id','created_at','updated_at',
    'match_id','conversation_id','timeline_id','review_id','attempt_id',
    'phase','question_id','direction'
  );

comment on view public.zyra_data_ownership is
  'OA-ZYRA-155, platform-wide. Scans EVERY public table — a new table appears as UNCLASSIFIED automatically. Never export a row showing UNCLASSIFIED or pending-legal.';

revoke all on public.zyra_data_ownership from public, anon, authenticated;

-- ===================== THE REMAINING 16 TABLES =========================

-- DECISIONS. The safety reasoning behind safety_concern applies directly:
-- one person's private choice about another must not become visible to the
-- other through an export.
comment on column public.saves.saver_id  is 'OWNERSHIP: row-scoped(saver_id)';
comment on column public.saves.saved_id  is
  'OWNERSHIP: non-exportable to the SAVED person — being saved is the saver''s private act.';
comment on column public.likes.liker_id  is 'OWNERSHIP: row-scoped(liker_id)';
comment on column public.likes.liked_id  is
  'OWNERSHIP: non-exportable to the liked person unless it has become a mutual match.';
comment on column public.passes.passer_id is 'OWNERSHIP: row-scoped(passer_id)';
comment on column public.passes.passed_id is
  'OWNERSHIP: non-exportable to the passed person. ZYRA promises "no record, no notification" on a Pass; an export disclosing it would break that promise through a route nobody thought to close.';

-- BLOCKS AND REPORTS — the same shape as a safety hold.
comment on table  public.profile_blocks is
  'OWNERSHIP: row-scoped(blocker_id). NON-EXPORTABLE to the blocked person — a visible block is a provocation aimed at the person it protects. Same reasoning as V3 §3.';
comment on column public.profile_blocks.blocker_id is 'OWNERSHIP: row-scoped(blocker_id)';
comment on column public.profile_blocks.blocked_id is 'OWNERSHIP: non-exportable to the blocked person';
comment on table  public.profile_reports is
  'OWNERSHIP: row-scoped(reporter_id). NON-EXPORTABLE to the reported person, including any attached evidence — §15.3. Handing someone the report filed against them defeats the protection entirely.';
comment on column public.profile_reports.reporter_id is 'OWNERSHIP: row-scoped(reporter_id)';
comment on column public.profile_reports.reported_id is 'OWNERSHIP: non-exportable to the reported person';
comment on column public.profile_reports.reason      is 'OWNERSHIP: non-exportable to the reported person';
comment on column public.profile_reports.detail      is
  'OWNERSHIP: non-exportable to the reported person — free text, and the most likely place for evidence-like content today.';
comment on column public.profile_reports.source      is 'OWNERSHIP: row-scoped(reporter_id)';
comment on column public.profile_reports.status      is 'OWNERSHIP: row-scoped(reporter_id)';
comment on column public.profile_reports.reviewed_at is 'OWNERSHIP: row-scoped(reporter_id)';

-- ENTITLEMENTS
comment on column public.subscriptions.user_id        is 'OWNERSHIP: row-scoped(user_id)';
comment on column public.subscriptions.plan_type      is 'OWNERSHIP: row-scoped(user_id)';
comment on column public.subscriptions.status         is 'OWNERSHIP: row-scoped(user_id)';
comment on column public.subscriptions.billing_period is 'OWNERSHIP: row-scoped(user_id)';
comment on column public.subscriptions.started_at     is 'OWNERSHIP: row-scoped(user_id)';
comment on column public.subscriptions.expires_at     is 'OWNERSHIP: row-scoped(user_id)';
comment on table  public.unlock_credits is 'OWNERSHIP: row-scoped(user_id) — the holder''s own ledger.';
comment on column public.unlock_credits.user_id           is 'OWNERSHIP: row-scoped(user_id)';
comment on column public.unlock_credits.tier              is 'OWNERSHIP: row-scoped(user_id)';
comment on column public.unlock_credits.delta             is 'OWNERSHIP: row-scoped(user_id)';
comment on column public.unlock_credits.reason            is 'OWNERSHIP: row-scoped(user_id)';
comment on column public.unlock_credits.note              is 'OWNERSHIP: row-scoped(user_id)';
comment on column public.unlock_credits.related_unlock_id is 'OWNERSHIP: row-scoped(user_id)';
comment on column public.profile_unlocks.unlocker_id is 'OWNERSHIP: row-scoped(unlocker_id)';
comment on column public.profile_unlocks.unlocked_id is
  'OWNERSHIP: non-exportable to the UNLOCKED person. Disclosing it would tell someone who has been paying to look at them.';
comment on column public.profile_unlocks.unlock_type is 'OWNERSHIP: row-scoped(unlocker_id)';

-- ARTICLE 9 AND ONBOARDING — the subject's own, in full.
comment on column public.consents.user_id        is 'OWNERSHIP: row-scoped(user_id)';
comment on column public.consents.consent_type   is 'OWNERSHIP: row-scoped(user_id)';
comment on column public.consents.granted        is 'OWNERSHIP: row-scoped(user_id)';
comment on column public.consents.policy_version is 'OWNERSHIP: row-scoped(user_id)';
comment on column public.consents.recorded_at    is 'OWNERSHIP: row-scoped(user_id)';
comment on table  public.seeker_details is
  'OWNERSHIP: row-scoped(user_id). Article 9 special-category data — always disclosable to its subject, never to anyone else except through a paid unlock (seeker_details_for_unlocked).';
comment on column public.seeker_details.user_id          is 'OWNERSHIP: row-scoped(user_id)';
comment on column public.seeker_details.sect             is 'OWNERSHIP: row-scoped(user_id) — Article 9';
comment on column public.seeker_details.sect_other       is 'OWNERSHIP: row-scoped(user_id) — Article 9';
comment on column public.seeker_details.revert_status    is 'OWNERSHIP: row-scoped(user_id) — Article 9';
comment on column public.seeker_details.country_of_birth is 'OWNERSHIP: row-scoped(user_id) — Article 9 by inference';
comment on column public.seeker_details.nationality      is 'OWNERSHIP: row-scoped(user_id) — Article 9 by inference';
comment on column public.seeker_details.ethnicity        is 'OWNERSHIP: row-scoped(user_id) — Article 9';
comment on column public.seeker_details.languages        is 'OWNERSHIP: row-scoped(user_id)';
comment on column public.seeker_details.preferences      is 'OWNERSHIP: row-scoped(user_id)';
comment on column public.onboarding_answers.user_id               is 'OWNERSHIP: row-scoped(user_id)';
comment on column public.onboarding_answers.ch3_answers           is 'OWNERSHIP: row-scoped(user_id)';
comment on column public.onboarding_answers.ch4_preferences       is 'OWNERSHIP: row-scoped(user_id)';
comment on column public.onboarding_answers.ch4_hard_requirements is 'OWNERSHIP: row-scoped(user_id)';

-- NOTIFICATIONS
comment on column public.notifications.user_id          is 'OWNERSHIP: row-scoped(user_id)';
comment on column public.notifications.type             is 'OWNERSHIP: row-scoped(user_id)';
comment on column public.notifications.title            is 'OWNERSHIP: row-scoped(user_id)';
comment on column public.notifications.body             is 'OWNERSHIP: row-scoped(user_id)';
comment on column public.notifications.read_at          is 'OWNERSHIP: row-scoped(user_id)';
comment on column public.notifications.related_match_id is 'OWNERSHIP: row-scoped(user_id)';

-- GUARDIAN LINKS — genuinely joint between a Seeker and that Guardian.
comment on table  public.wali_links is
  'OWNERSHIP: joint between the Seeker and that Guardian — both know the link exists. Never disclosable to a third Seeker.';
comment on column public.wali_links.seeker_id is 'OWNERSHIP: joint(seeker_id, wali_id)';
comment on column public.wali_links.wali_id   is 'OWNERSHIP: joint(seeker_id, wali_id)';
comment on column public.wali_links.status    is 'OWNERSHIP: joint(seeker_id, wali_id)';
comment on column public.wali_links.is_main   is 'OWNERSHIP: joint(seeker_id, wali_id)';
comment on column public.wali_invites.inviter_id   is 'OWNERSHIP: row-scoped(inviter_id)';
comment on column public.wali_invites.inviter_role is 'OWNERSHIP: row-scoped(inviter_id)';
comment on column public.wali_invites.token        is
  'OWNERSHIP: row-scoped(inviter_id) — a live credential while unredeemed. Never export a usable token.';
comment on column public.wali_invites.status       is 'OWNERSHIP: row-scoped(inviter_id)';
comment on column public.wali_invites.expires_at   is 'OWNERSHIP: row-scoped(inviter_id)';
comment on column public.wali_invites.accepted_at  is 'OWNERSHIP: joint(inviter_id, accepted_by)';
comment on column public.wali_invites.accepted_by  is 'OWNERSHIP: joint(inviter_id, accepted_by)';

-- PROFILES — the one genuinely mixed table.
comment on column public.profiles.first_name       is 'OWNERSHIP: row-scoped(id) — shown publicly in Browse';
comment on column public.profiles.surname_line     is 'OWNERSHIP: row-scoped(id)';
comment on column public.profiles.date_of_birth    is
  'OWNERSHIP: row-scoped(id) — not client-readable; others see a derived age via ages_for().';
comment on column public.profiles.gender           is 'OWNERSHIP: row-scoped(id)';
comment on column public.profiles.location_text    is 'OWNERSHIP: row-scoped(id)';
comment on column public.profiles.bio              is 'OWNERSHIP: row-scoped(id)';
comment on column public.profiles.role             is 'OWNERSHIP: row-scoped(id)';
comment on column public.profiles.is_active        is 'OWNERSHIP: row-scoped(id)';
comment on column public.profiles.profile_complete is 'OWNERSHIP: row-scoped(id)';
