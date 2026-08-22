-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260804095831, applied name
-- 'article9_consents_log') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Article 9 consent log — Founder approved 2026-08-04.
--
-- Chapter 2 collects religious belief (sect, revert status) and ethnic
-- origin (ethnicity, and by inference country of birth and nationality).
-- Under UK GDPR these are special-category data and need a lawful basis
-- beyond ordinary consent — realistically explicit consent, separately
-- recorded.
--
-- Until now the app collected all of it with no consent step of any kind.
--
-- APPEND-ONLY BY DESIGN. Withdrawal is a NEW ROW with granted = false,
-- not an update to the old one. Consent history is the whole point of the
-- record: "did this person consent at the moment we processed their data,
-- and to which wording" cannot be answered by a table you can overwrite.
-- There is deliberately no UPDATE or DELETE policy, not even for the
-- subject themselves.
--
-- policy_version is not decoration. Consent is to a specific text; if the
-- wording changes, prior consent does not automatically carry over, and
-- without this column there is no way to tell who agreed to what.
--
-- NOT LEGAL ADVICE. The Founder has confirmed a solicitor will review the
-- consent wording, Privacy Policy, Terms and the Compatibility Unlock flow
-- before public launch. This table is built so that review can change the
-- wording without changing the schema.

create table if not exists public.consents (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references public.profiles(id) on delete cascade,
  consent_type    text not null,
  granted         boolean not null,
  policy_version  text not null,
  recorded_at     timestamptz not null default now(),
  constraint consents_type_known check (
    consent_type in ('article9_special_category')
  )
);

comment on table public.consents is
  'Append-only consent log. Withdrawal is a new row with granted=false. Never update or delete a row here.';

-- The only query this table serves in the hot path: "what is this user's
-- current position on this consent type", answered by the newest row.
create index if not exists consents_user_type_recent
  on public.consents (user_id, consent_type, recorded_at desc);

alter table public.consents enable row level security;

-- Read your own consent history. Nobody else's, including a Guardian's:
-- whether someone consented to processing their own religious belief is
-- not information a third party needs.
create policy consents_select on public.consents
  for select using (user_id = (select auth.uid()));

-- Record your own consent or withdrawal.
create policy consents_insert on public.consents
  for insert with check (user_id = (select auth.uid()));

-- Current position, newest row wins. STABLE so the planner can cache it
-- within a statement; SECURITY INVOKER (the default) because RLS above
-- already scopes it correctly and a definer function here would let one
-- user read another's consent state.
create or replace function public.has_article9_consent()
returns boolean
language sql
stable
set search_path to 'public'
as $$
  select coalesce(
    (select c.granted
       from public.consents c
      where c.user_id = (select auth.uid())
        and c.consent_type = 'article9_special_category'
      order by c.recorded_at desc
      limit 1),
    false);
$$;
