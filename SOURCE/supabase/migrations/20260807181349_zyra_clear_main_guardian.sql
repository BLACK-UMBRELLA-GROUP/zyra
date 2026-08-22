-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260807181349, applied name
-- 'zyra_clear_main_guardian') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Step a Guardian DOWN from Main, leaving nobody Main.
--
-- Founder, 2026-08-07: "with main guardian we need a button to make
-- additional guardian".
--
-- The counterpart to zyra_set_main_guardian, and deliberately a SEPARATE
-- function rather than a nullable argument on that one. Promoting and
-- demoting read identically in code but not in consequence: promoting
-- always leaves a valid state, demoting can leave a Seeker with Guardians
-- and no Main, which Family Review cannot resolve.
--
-- Permitted anyway, because it IS reachable and the page already handles
-- it — the Guardian tab shows "NO MAIN GUARDIAN · Choose one of your
-- Guardians below". Refusing would mean the only route out of a wrong Main
-- is promoting someone else first, which is not always what the Seeker
-- wants to do in the moment.
--
-- The UI warns before calling this. The database does not, because "you
-- currently have no Main Guardian" is a legitimate row state, not a
-- corrupt one.

create or replace function public.zyra_clear_main_guardian(p_wali_id uuid)
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

  update public.wali_links
     set is_main = false
   where seeker_id = v_me
     and wali_id = p_wali_id
     and status = 'active'
     and is_main;

  get diagnostics v_n = row_count;
  return v_n > 0;
end;
$function$;

revoke execute on function public.zyra_clear_main_guardian(uuid) from public;
revoke execute on function public.zyra_clear_main_guardian(uuid) from anon;
grant  execute on function public.zyra_clear_main_guardian(uuid) to authenticated;
grant  execute on function public.zyra_clear_main_guardian(uuid) to service_role;
