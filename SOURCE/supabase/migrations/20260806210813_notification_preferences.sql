-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806210813, applied name
-- 'notification_preferences') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Notification preferences, persisted at last.
--
-- The three toggles that exist today write to AppState and nowhere else —
-- in memory, gone on restart. That was survivable while they were product
-- notifications. It stops being survivable the moment Marketing Emails and
-- Product Updates join them, because those are consent categories under UK
-- GDPR and PECR: a switch that forgets means the consent record does not
-- exist, a withdrawal is not honoured, and neither is evidenced.
--
-- APPEND-ONLY, deliberately. A single mutable row with an updated_at can
-- only ever evidence the LATEST change — opt in, opt out, opt in again and
-- the middle event is gone. Consent and its WITHDRAWAL both need to be
-- provable. Same shape as unlock_credits and article9_consents_log, both
-- already in this schema for the same reason.
--
-- Current state is therefore "the newest row per (user, category)", never
-- an UPDATE.

create table if not exists public.notification_preferences (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  category   text not null check (category in (
               'matches_journeys',
               'guardian_activity',
               'introductions',
               'marketing_emails',
               'product_updates')),
  enabled    boolean not null,
  changed_at timestamptz not null default now()
);

create index if not exists notification_preferences_current
  on public.notification_preferences (user_id, category, changed_at desc);

comment on table public.notification_preferences is
  'OWNERSHIP: row-scoped(user_id). Append-only consent and preference log. '
  'Never UPDATE or DELETE a row — the history IS the evidence. Current '
  'state is the newest row per (user_id, category).';

comment on column public.notification_preferences.enabled is
  'OWNERSHIP: row-scoped(user_id). For marketing_emails and product_updates '
  'this is a record of CONSENT given or withdrawn, and is disclosable to the '
  'user under Article 15.';

alter table public.notification_preferences enable row level security;

drop policy if exists notification_preferences_select on public.notification_preferences;
create policy notification_preferences_select
  on public.notification_preferences for select
  using (user_id = (select auth.uid()));

-- No INSERT policy and no INSERT grant: writes go through the RPC below,
-- which is the only thing that may append. Nothing may UPDATE or DELETE,
-- which is what makes "append-only" true rather than merely intended.
revoke all on public.notification_preferences from anon;
revoke all on public.notification_preferences from authenticated;
grant select on public.notification_preferences to authenticated;
