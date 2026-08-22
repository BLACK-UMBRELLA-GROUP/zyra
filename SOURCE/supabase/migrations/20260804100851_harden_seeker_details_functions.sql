-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260804100851, applied name
-- 'harden_seeker_details_functions') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Hardening for the three functions added earlier today, flagged by the
-- Supabase security advisor. Found 2026-08-04 by running the advisor after
-- the migration rather than assuming a clean bill.

-- 1. anon could call seeker_details_for_unlocked.
--
-- `revoke ... from public` does NOT remove Supabase's default explicit
-- grants to the `anon` and `authenticated` roles — PUBLIC and a named role
-- are separate grants, so the earlier revoke left anon's intact.
--
-- Not exploitable as it stood: auth.uid() is NULL for anon, so the
-- profile_unlocks check could never match and the function returned zero
-- rows. But an unauthenticated caller should not be able to reach a
-- SECURITY DEFINER function that reads Article 9 data at all — the
-- distance between "returns nothing today" and "returns something after a
-- future edit" is one careless WHERE clause.
revoke execute on function public.seeker_details_for_unlocked(uuid) from anon;

-- 2 and 3. Mutable search_path on the two helpers.
--
-- A SECURITY DEFINER trigger without a pinned search_path can be induced to
-- resolve an unqualified name against a schema the caller controls. Pinned
-- explicitly, matching every other function in this project.
create or replace function public.touch_seeker_details()
returns trigger
language plpgsql
set search_path to 'public'
as $$
begin
  new.updated_at := now();
  return new;
end $$;

create or replace function public.zyra_all_iso639_1(p text[])
returns boolean
language sql
immutable
set search_path to 'public'
as $$
  select p is null
      or not exists (select 1 from unnest(p) x where x !~ '^[a-z]{2}$');
$$;
