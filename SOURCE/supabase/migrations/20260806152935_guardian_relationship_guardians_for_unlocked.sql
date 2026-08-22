-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806152935, applied name
-- 'guardian_relationship_guardians_for_unlocked') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Guardian Relationship, step 2b: guardians_for_unlocked returns it.
--
-- DROP then CREATE: a RETURNS TABLE signature cannot gain a column via
-- CREATE OR REPLACE. relationship is APPENDED, so existing callers reading
-- by key are unaffected.
--
-- No policy change. Disclosure stays gated exactly as before: an active link,
-- a paid_plus_single unlock held by the caller, and no block between the
-- parties. Adding a column to a function that was already correctly gated
-- does not widen who can call it.

drop function if exists public.guardians_for_unlocked(uuid);

create function public.guardians_for_unlocked(p_target uuid)
returns table(
  first_name text,
  gender text,
  location_text text,
  is_main boolean,
  relationship text
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select p.first_name, p.gender, p.location_text,
         coalesce(w.is_main, false), w.relationship
  from public.wali_links w
  join public.profiles p on p.id = w.wali_id
  where w.seeker_id = p_target
    and w.status = 'active'
    and exists (
      select 1 from public.profile_unlocks u
      where u.unlocker_id = (select auth.uid())
        and u.unlocked_id = p_target
        and u.unlock_type = 'paid_plus_single'
    )
    and not public.zyra_block_exists(p_target)
  order by coalesce(w.is_main, false) desc, w.created_at;
$function$;

revoke execute on function public.guardians_for_unlocked(uuid) from public;
revoke execute on function public.guardians_for_unlocked(uuid) from anon;
grant  execute on function public.guardians_for_unlocked(uuid) to authenticated;
grant  execute on function public.guardians_for_unlocked(uuid) to service_role;
