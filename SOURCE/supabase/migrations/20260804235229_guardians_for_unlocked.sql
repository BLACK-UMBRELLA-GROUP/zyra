-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260804235229, applied name
-- 'guardians_for_unlocked') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Guardian visibility inside Compatibility Unlock+ (Founder decision,
-- 2026-08-05: "I want the Guardian to be visible… show the Guardian's
-- details, not just the relationship… if no Guardian is linked, I want
-- that shown honestly").
--
-- Same shape and same guards as seeker_details_for_unlocked(): the caller
-- must hold a paid_plus_single unlock for this target, and a block in
-- either direction overrides a past purchase. Deliberately NOT readable
-- with a standard (paid_single) unlock — Guardian information belongs to
-- the Plus tier only.
--
-- Returns first_name, gender, location_text and whether they are the main
-- Guardian. NOT returned: date_of_birth (its client SELECT is revoked
-- system-wide, audit C2), bio, id, or any contact route. A reader learns
-- who is involved in her Journey, not how to reach them independently.
--
-- An empty result set is meaningful and is rendered as "No Guardian
-- linked" — the UI does not infer or hide it (Founder decision above).
create or replace function public.guardians_for_unlocked(p_target uuid)
returns table(first_name text, gender text, location_text text, is_main boolean)
language sql
stable
security definer
set search_path to 'public'
as $$
  select p.first_name, p.gender, p.location_text, coalesce(w.is_main, false)
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
$$;

revoke execute on function public.guardians_for_unlocked(uuid) from public, anon;
grant execute on function public.guardians_for_unlocked(uuid) to authenticated;
