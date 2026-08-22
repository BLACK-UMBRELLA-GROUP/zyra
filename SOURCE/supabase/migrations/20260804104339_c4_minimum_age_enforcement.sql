-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260804104339, applied name
-- 'c4_minimum_age_enforcement') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- C-4 — minimum age. Founder approved 2026-08-04, independent review
-- (Fable) finding C-4, verified: pg_constraint held ZERO checks referencing
-- date_of_birth.
--
-- A marriage platform had no server-side guarantee that any account
-- belonged to an adult. Combined with C-3 — users could UPDATE their own
-- date_of_birth — an under-18 could set any DOB they liked and nothing
-- anywhere would object. Both Terms and the app stores assume 18+.
--
-- A CHECK rather than a trigger, deliberately:
--   • a trigger can be disabled (ALTER TABLE ... DISABLE TRIGGER); a CHECK
--     cannot be bypassed by anything short of dropping it
--   • CHECK also covers COPY and bulk insert paths a row-trigger would
--     still catch but which are easier to get wrong
--   • the error surfaces identically to the client either way
--
-- On CURRENT_DATE inside a CHECK: Postgres accepts it (verified before
-- writing this). It is normally discouraged because a constraint that
-- changes meaning over time can fail on restore — but here the drift only
-- ever runs in the safe direction. People get older, never younger, so a
-- row valid when written stays valid forever. Re-validation on a pg_dump
-- restore cannot fail for that reason.
--
-- Data verified clean before applying: 0 of 26 profiles under 18, 0 null
-- DOBs. No data migration needed.
--
-- NOT sufficient on its own. This is the last line, not the only one —
-- client-side validation still belongs in onboarding so the user gets a
-- helpful message rather than a constraint violation, and C-3 must still
-- remove the ability to rewrite the field after the fact.

alter table public.profiles
  add constraint profiles_adult_only
  check (date_of_birth <= (current_date - interval '18 years'));

-- Sanity bound. Catches a typo'd century or an epoch-zero default landing
-- in the column, which the age check alone would happily accept.
alter table public.profiles
  add constraint profiles_dob_plausible
  check (date_of_birth >= date '1900-01-01');

comment on constraint profiles_adult_only on public.profiles is
  'ZYRA is 18+. Final authority — client validation is a courtesy, this is the guarantee.';
