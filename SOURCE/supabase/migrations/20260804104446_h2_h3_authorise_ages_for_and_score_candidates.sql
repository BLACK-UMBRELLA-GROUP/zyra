-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260804104446, applied name
-- 'h2_h3_authorise_ages_for_and_score_candidates') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- H-2 and H-3 — authorisation inside the database functions.
-- Independent review (Fable), verified: neither function contained any
-- reference to auth.uid() in its filtering. Both accepted arbitrary UUID
-- arrays from any signed-in caller.
--
--   ages_for()          partially undid the DOB fix. You could not read the
--                       date, but you could read the AGE of any UUID —
--                       including hidden profiles, blocked users and
--                       same-gender profiles Browse never shows you.
--   score_candidates()  worse in kind. With crafted preference data it is
--                       an ORACLE: submit a preference matrix that scores
--                       green on exactly one sect, see whose score moves,
--                       and you have inferred a stranger's religious
--                       answers without ever reading them. Article 9
--                       inference rather than disclosure, which is not a
--                       meaningfully better outcome.
--
-- THE FIX IS ONE SHARED PREDICATE, not two copies.
--
-- Both functions are SECURITY DEFINER and therefore bypass RLS by design —
-- that is why they exist. So the visibility rule has to be restated inside
-- them, and a rule restated in two places is a rule that will diverge. It
-- lives in zyra_can_view_profile() and is called from both.
--
-- This helper is also where H-1's gender segregation will land, so that
-- when it does, these two functions inherit it automatically instead of
-- being fixed a third time.

create or replace function public.zyra_can_view_profile(p_target uuid)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    p_target = (select auth.uid())
    or exists (
      -- Guardian <-> Seeker, in either direction. Present from the start
      -- rather than added later: a Guardian must be able to resolve their
      -- own Seeker's age and details, and a Seeker their Guardian's.
      select 1 from public.wali_links w
      where w.status = 'active'
        and (   (w.seeker_id = p_target and w.wali_id  = (select auth.uid()))
             or (w.wali_id   = p_target and w.seeker_id = (select auth.uid())) )
    )
    or exists (
      select 1 from public.profiles p
      where p.id = p_target
        and p.is_active = true
        and p.profile_complete = true
        and not public.zyra_block_exists(p_target)
    );
$$;

comment on function public.zyra_can_view_profile(uuid) is
  'Single source of truth for "may the caller see this profile". Called by ages_for and score_candidates, which are SECURITY DEFINER and so bypass RLS. H-1 gender segregation lands here.';

-- H-2 ------------------------------------------------------------------
create or replace function public.ages_for(p_ids uuid[])
returns table(id uuid, age integer)
language sql
stable security definer
set search_path to 'public'
as $$
  SELECT p.id, EXTRACT(YEAR FROM age(current_date, p.date_of_birth))::int
  FROM public.profiles p
  WHERE p.id = ANY(p_ids)
    AND public.zyra_can_view_profile(p.id);
$$;

revoke all on function public.ages_for(uuid[]) from public;
revoke all on function public.ages_for(uuid[]) from anon;
grant execute on function public.ages_for(uuid[]) to authenticated;

revoke all on function public.zyra_can_view_profile(uuid) from public;
revoke all on function public.zyra_can_view_profile(uuid) from anon;
grant execute on function public.zyra_can_view_profile(uuid) to authenticated;
