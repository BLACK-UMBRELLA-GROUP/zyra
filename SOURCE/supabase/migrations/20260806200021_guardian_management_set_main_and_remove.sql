-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806200021, applied name
-- 'guardian_management_set_main_and_remove') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Guardian management: promote a Main, and remove a Guardian.
--
-- Founder decision 2026-08-06: removing the Main Guardian is BLOCKED until
-- another is promoted. The alternative — auto-promoting the longest-linked
-- — would have the app decide who represents a family, and that is not the
-- app's decision to make even when it announces it.
--
-- WHY THIS IS NEEDED AT ALL: auto_designate_main_wali is a BEFORE trigger
-- on the row being written. It sets NEW.is_main when no active Main exists,
-- which covers the first link and nothing else. It does NOT promote a
-- survivor when a Main is removed. Without the guard below, removing a Main
-- leaves a Seeker with Guardians and no Main — and wali_review_decision,
-- reopen_family_review, resolve_family_review_if_due and the review_waiting
-- branch of zyra_guardian_activity all read is_main. A Family Review would
-- become unresolvable.

-- ── Promote ──────────────────────────────────────────────────────────
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

  -- ORDER MATTERS, and not for style.
  --
  -- auto_designate_main_wali fires per row and re-asserts is_main whenever
  -- it sees no active Main in the table. Clearing everyone FIRST and then
  -- setting one would, in the case where no Main currently exists, make the
  -- trigger promote every row it touched. Setting the new Main first means
  -- the demotion statement always runs with a Main visible in its snapshot,
  -- so the trigger correctly leaves it alone.
  update public.wali_links
     set is_main = true
   where seeker_id = v_me and wali_id = p_wali_id and status = 'active';

  get diagnostics v_n = row_count;

  update public.wali_links
     set is_main = false
   where seeker_id = v_me and wali_id <> p_wali_id and status = 'active';

  return v_n > 0;
end;
$function$;

-- ── Remove ───────────────────────────────────────────────────────────
create or replace function public.zyra_remove_guardian(p_wali_id uuid)
returns boolean
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_me     uuid := auth.uid();
  v_main   boolean;
  v_others int;
  v_n      int;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;

  select is_main into v_main
  from public.wali_links
  where seeker_id = v_me and wali_id = p_wali_id and status = 'active';

  if not found then
    raise exception 'not_your_guardian';
  end if;

  select count(*) into v_others
  from public.wali_links
  where seeker_id = v_me and wali_id <> p_wali_id and status = 'active';

  -- The guard. Removing your last Guardian is allowed — that leaves an
  -- empty page, which is a real and recoverable state. Removing your MAIN
  -- while others remain is not, because nothing would promote a
  -- replacement and Family Review reads is_main.
  if coalesce(v_main, false) and v_others > 0 then
    raise exception 'main_guardian_must_be_reassigned';
  end if;

  update public.wali_links
     set status = 'removed', is_main = false
   where seeker_id = v_me and wali_id = p_wali_id;

  get diagnostics v_n = row_count;
  return v_n > 0;
end;
$function$;

revoke execute on function public.zyra_set_main_guardian(uuid) from public;
revoke execute on function public.zyra_set_main_guardian(uuid) from anon;
grant  execute on function public.zyra_set_main_guardian(uuid) to authenticated;
grant  execute on function public.zyra_set_main_guardian(uuid) to service_role;

revoke execute on function public.zyra_remove_guardian(uuid) from public;
revoke execute on function public.zyra_remove_guardian(uuid) from anon;
grant  execute on function public.zyra_remove_guardian(uuid) to authenticated;
grant  execute on function public.zyra_remove_guardian(uuid) to service_role;
