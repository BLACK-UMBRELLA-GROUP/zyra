-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806211002, applied name
-- 'notification_preferences_deterministic_order') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- FIX, found by reading the first test's output rather than its summary.
--
-- Three consent events written in one statement came back with the SAME
-- changed_at, because now() is TRANSACTION start time, not wall clock. The
-- "latest per category" read orders by changed_at, so under a tie it picks
-- arbitrarily — and a consent record whose ordering is ambiguous cannot
-- evidence anything. The current state happened to come back correct, which
-- is worse than it coming back wrong, because it would have shipped.
--
-- TWO CHANGES, because either alone leaves a gap:
--   clock_timestamp()  real wall clock, so events within one transaction
--                      differ. Fixes the cause.
--   seq bigserial      a monotonic tiebreaker, so ordering is deterministic
--                      even if two rows somehow share a timestamp. Fixes
--                      the consequence.

alter table public.notification_preferences
  alter column changed_at set default clock_timestamp();

alter table public.notification_preferences
  add column if not exists seq bigserial;

drop index if exists notification_preferences_current;
create index notification_preferences_current
  on public.notification_preferences (user_id, category, seq desc);

comment on column public.notification_preferences.seq is
  'Monotonic insertion order. The authoritative tiebreaker for "which '
  'consent event is current" — changed_at alone is not sufficient, because '
  'two events in one transaction can share it.';

-- Re-read using seq, which cannot tie.
create or replace function public.zyra_notification_preferences()
returns table(category text, enabled boolean, changed_at timestamptz)
language sql
stable
security definer
set search_path to 'public'
as $function$
  with defaults(category, enabled) as (
    values ('matches_journeys',  true),
           ('guardian_activity', true),
           ('introductions',     true),
           -- OFF by default. Under UK GDPR consent is a positive opt-in and
           -- a pre-ticked box is not consent, so "no row" must read as "no".
           ('marketing_emails',  false),
           ('product_updates',   false)
  ),
  latest as (
    select distinct on (p.category)
           p.category, p.enabled, p.changed_at
    from public.notification_preferences p
    where p.user_id = (select auth.uid())
    order by p.category, p.seq desc
  )
  select d.category,
         coalesce(l.enabled, d.enabled),
         l.changed_at
  from defaults d
  left join latest l on l.category = d.category;
$function$;
