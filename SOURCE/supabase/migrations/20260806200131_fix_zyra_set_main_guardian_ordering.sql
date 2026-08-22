-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806200131, applied name
-- 'fix_zyra_set_main_guardian_ordering') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- FIX. The first version set the new Main before demoting the old one, and
-- explained at length why that order was necessary. It was wrong, because
-- it reasoned about one safeguard while a second one existed:
--
--   auto_designate_main_wali          BEFORE trigger; promotes when it sees
--                                     NO active Main
--   wali_links_one_main_per_seeker    partial UNIQUE index; forbids TWO
--
-- Promote-then-demote satisfies the trigger and violates the index —
-- "duplicate key value violates unique constraint" — which is exactly what
-- happened on the first live test. The index was never checked for.
--
-- CORRECT ORDER IS DEMOTE, THEN PROMOTE, and it satisfies both:
--
--   Demote: a BEFORE UPDATE trigger reads the pre-update snapshot, in which
--           the row being demoted is still Main. EXISTS is true, so the
--           trigger does not re-promote it. It becomes false as intended.
--   Promote: no Main exists now, so the index is free AND the trigger would
--           set is_main itself even if this statement did not.
--
-- The lesson is the standing one, arrived at the hard way again: constraints
-- and triggers on the same column are two safeguards with opposite failure
-- modes, and reasoning about either alone gets the answer wrong.

create or replace function public.zyra_set_main_guardian(p_wali_id uuid)
returns boolean
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_me uuid := auth.uid();
  v_n  int;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;

  if not exists (
    select 1 from public.wali_links
    where seeker_id = v_me and wali_id = p_wali_id and status = 'active'
  ) then
    raise exception 'not_your_guardian';
  end if;

  -- 1. Demote the incumbent, if there is one.
  update public.wali_links
     set is_main = false
   where seeker_id = v_me and status = 'active' and is_main;

  -- 2. Promote the target into the now-vacant slot.
  update public.wali_links
     set is_main = true
   where seeker_id = v_me and wali_id = p_wali_id and status = 'active';

  get diagnostics v_n = row_count;
  return v_n > 0;
end;
$function$;
