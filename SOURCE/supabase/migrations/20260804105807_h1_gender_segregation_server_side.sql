-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260804105807, applied name
-- 'h1_gender_segregation_server_side') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- H-1 — gender segregation moves into the database.
--
-- Until now `profiles_select` was:
--   id = auth.uid() OR (is_active AND profile_complete AND NOT blocked)
-- and the opposite-gender rule existed ONLY as `.eq('gender', ...)` in a
-- Dart query. Any signed-in user could read every active profile of either
-- gender with one HTTP request.
--
-- For this product that is not an ordinary access-control gap. It is the
-- religious-integrity guarantee the whole platform is built on, and the
-- server did not keep it.
--
-- ============ TWO TRAPS, BOTH INVISIBLE IN THE CURRENT DATA ============
--
-- A naive "opposite gender only" policy passes every test against this
-- database and breaks in production, twice:
--
--   1. GUARDIAN AND SEEKER OF THE SAME GENDER.
--      A wali is typically male — father, brother, paternal uncle (the
--      app's own fakeGuardians are exactly those three). A MALE Seeker
--      with a MALE Guardian is completely ordinary, and an opposite-gender
--      rule would stop that Guardian reading his own Seeker.
--      There are ZERO same-gender pairs in the seed data, so this would
--      not have shown up in any test run here.
--
--   2. GUARDIAN READING THEIR SEEKER'S MATCH PARTNER.
--      zyra_wali_journey_service._fetchPartnerProfile reads the other
--      party in a Journey. A MALE Guardian of a FEMALE Seeker must read
--      that Seeker's MALE partner — same gender as himself. An
--      opposite-gender rule blocks the Guardian journey view outright.
--
-- Both are handled by explicit clauses below. The rule is not "opposite
-- gender"; it is "opposite gender WHEN BROWSING", and every other
-- relationship is named.
--
-- Implemented inside zyra_can_view_profile() and called from the policy so
-- there is ONE definition. Safe from recursion: the function is SECURITY
-- DEFINER, owned by postgres, and profiles does not have FORCE ROW LEVEL
-- SECURITY — so the owner bypasses RLS inside the function. Verified
-- before writing, and it is the same pattern zyra_block_exists already
-- uses in this very policy.

create or replace function public.zyra_can_view_profile(p_target uuid)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select
    -- yourself
    p_target = (select auth.uid())

    -- your Guardian, or your Seeker. Either direction, any gender.
    or exists (
      select 1 from public.wali_links w
      where w.status = 'active'
        and (   (w.seeker_id = p_target and w.wali_id   = (select auth.uid()))
             or (w.wali_id   = p_target and w.seeker_id = (select auth.uid())) )
    )

    -- a Guardian seeing whoever their Seeker is on a Journey with.
    -- Same-gender by definition roughly half the time.
    or exists (
      select 1
      from public.wali_links w
      join public.matches m
        on (m.seeker_a_id = w.seeker_id or m.seeker_b_id = w.seeker_id)
      where w.wali_id = (select auth.uid())
        and w.status  = 'active'
        and p_target in (m.seeker_a_id, m.seeker_b_id)
        and p_target <> w.seeker_id
    )

    -- someone you are already on a Journey with, regardless of anything
    -- else — a match must not become unreadable because the other person
    -- paused their profile.
    or exists (
      select 1 from public.matches m
      where (   (m.seeker_a_id = (select auth.uid()) and m.seeker_b_id = p_target)
             or (m.seeker_b_id = (select auth.uid()) and m.seeker_a_id = p_target) )
    )

    -- BROWSING. Active, published, not blocked either way, and — new —
    -- of the opposite gender to the viewer.
    or exists (
      select 1
      from public.profiles p
      cross join lateral (
        select pv.role, pv.gender from public.profiles pv where pv.id = (select auth.uid())
      ) viewer
      where p.id = p_target
        and p.is_active = true
        and p.profile_complete = true
        and not public.zyra_block_exists(p_target)
        and (
          -- Guardians do not browse; they reach profiles through the
          -- clauses above. Anyone whose own row is missing gets nothing.
          viewer.role = 'seeker'
          and viewer.gender is not null
          and p.gender is not null
          and p.gender <> viewer.gender
        )
    );
$$;

drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles
  for select using (public.zyra_can_view_profile(id));

comment on function public.zyra_can_view_profile(uuid) is
  'Single definition of profile visibility: self, Guardian<->Seeker, Guardian->Seeker''s match partner, own match partner, or opposite-gender browsing. Used by profiles_select RLS AND by the SECURITY DEFINER functions ages_for and score_candidates, which bypass RLS by design.';
