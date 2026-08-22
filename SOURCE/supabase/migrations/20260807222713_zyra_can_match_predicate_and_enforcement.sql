-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260807222713, applied name
-- 'zyra_can_match_predicate_and_enforcement') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- STEP 2: one canonical predicate for romantic eligibility, enforced where
-- it cannot be skipped. Founder authorised 2026-08-07.
--
-- ── THE PROBLEM IT CLOSES, demonstrated before this migration:
-- likes_insert, saves_insert and passes_insert each checked exactly one
-- thing — `liker_id = auth.uid()`. Who is acting. Nothing about who is
-- being acted upon. Two SAME-GENDER Seekers could each Like the other and
-- a match plus a conversation were created, even though neither could SEE
-- the other. The segregation rule existed only as a filter on the Browse
-- query, never as a property of the system.
--
-- ── VIEWING AND MATCHING ARE NOW TWO CONCEPTS.
--   zyra_can_view_profile(target)  who may SEE whom     — already existed
--   zyra_can_match(a, b)           who may PURSUE whom  — this
--
-- Guardian visibility is deliberately broader than Browse visibility, and
-- must never become a route into a romantic action. That is why they are
-- separate functions rather than one with a flag.
--
-- ── DELIBERATELY STATELESS. Durable facts only:
--     not the same person · both Seekers · genders differ ·
--     no block either way · no active Guardian edge either way
--
-- Transient state — already matched, already passed, already ended,
-- suspended, subscription tier — stays in the queries that need it.
-- Mixing the two would turn a predicate into a state machine: expensive
-- inside an RLS check on every insert, hostile to caching, and wrong under
-- concurrency. It also keeps the useful distinction intact — "may these
-- two EVER be linked" is a different question from "may they act now".
--
-- ── SYMMETRIC. zyra_can_match(a,b) = zyra_can_match(b,a), always. Blocks
-- are checked in both directions on purpose: if A blocks B, neither may
-- pursue the other. A directional rule here would let the blocked party
-- keep acting.
--
-- ── SECURITY DEFINER IS REQUIRED, not convenience. This runs inside RLS
-- policies, where the caller's own RLS applies. Without DEFINER it could
-- not read the other person's profile row to compare gender, would return
-- false, and would block every legitimate action.
--
-- ── THE GUARDIAN CLAUSE IS IN FROM DAY ONE. It was going to wait for the
-- Guardian gender governance review, but the Founder restated the rule as
-- absolute on 2026-08-07 — "they can never match anyone they are a
-- Guardian for" — and that is independent of who may BECOME a Guardian.
-- Governance gates opening dual-context, not this.
--
-- VERIFIED BEFORE APPLYING: of 4 likes and 16 saves in the database, zero
-- violate any clause. Nothing existing is invalidated.

create or replace function public.zyra_can_match(p_a uuid, p_b uuid)
 returns boolean
 language sql
 stable
 security definer
 set search_path to 'public'
as $function$
  select exists (
    select 1
    from public.profiles a, public.profiles b
    where a.id = p_a
      and b.id = p_b
      and a.id <> b.id
      -- A Guardian is not a romantic candidate. Neither is an admin.
      and a.role = 'seeker'
      and b.role = 'seeker'
      -- The segregation rule. NOT NULL on the column, checked anyway
      -- because a future nullable column would otherwise open it silently.
      and a.gender is not null
      and b.gender is not null
      and a.gender <> b.gender
      and not exists (
        select 1 from public.profile_blocks x
        where (x.blocker_id = p_a and x.blocked_id = p_b)
           or (x.blocker_id = p_b and x.blocked_id = p_a)
      )
      and not exists (
        select 1 from public.wali_links w
        where w.status = 'active'
          and (   (w.seeker_id = p_a and w.wali_id = p_b)
               or (w.seeker_id = p_b and w.wali_id = p_a) )
      )
  );
$function$;

comment on function public.zyra_can_match(uuid, uuid) is
  'THE canonical romantic-eligibility predicate. Every romantic surface — '
  'Browse, Search, Consider, Save, Like, match creation, and any future '
  'matchmaking or recommendation feature — must consult this and nothing '
  'else. Symmetric and stateless: durable facts only. Enforced in the RLS '
  'WITH CHECK on likes/saves/passes and inside '
  'create_match_on_mutual_like(). Guardian visibility must NEVER be a '
  'route into a romantic action — that is why this is separate from '
  'zyra_can_view_profile().';

revoke execute on function public.zyra_can_match(uuid, uuid) from public, anon;
grant  execute on function public.zyra_can_match(uuid, uuid) to authenticated;

-- ── Enforcement 1: the write policies ─────────────────────────────────
-- IN THE POLICY, not only in the trigger. A trigger can be disabled for a
-- transaction — this project disabled one twice today to run backfills —
-- and a disabled trigger enforces nothing. An RLS WITH CHECK cannot be
-- switched off per transaction.

drop policy if exists likes_insert on public.likes;
create policy likes_insert on public.likes
  for insert with check (
    liker_id = (select auth.uid()) and public.zyra_can_match(liker_id, liked_id)
  );

drop policy if exists saves_insert on public.saves;
create policy saves_insert on public.saves
  for insert with check (
    saver_id = (select auth.uid()) and public.zyra_can_match(saver_id, saved_id)
  );

-- Passes are guarded too. Declining someone is harmless in itself, but an
-- unguarded write path is exactly what this migration exists to remove,
-- and a Pass recorded against someone who could never be a candidate is
-- meaningless data that later features would have to reason about.
drop policy if exists passes_insert on public.passes;
create policy passes_insert on public.passes
  for insert with check (
    passer_id = (select auth.uid()) and public.zyra_can_match(passer_id, passed_id)
  );

-- ── Enforcement 2: match creation ─────────────────────────────────────
-- Belt and braces. The policies above stop the likes being written at all,
-- so this should be unreachable — which is the point. If a like ever
-- arrives by another route (a backfill, a future admin tool, a restored
-- dump), the match still does not get created.

create or replace function public.create_match_on_mutual_like()
 returns trigger
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
DECLARE
  reciprocal_exists BOOLEAN;
  a_id UUID;
  b_id UUID;
  new_match_id UUID;
  new_timeline_id UUID;
  a_name TEXT;
  b_name TEXT;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM likes WHERE liker_id = NEW.liked_id AND liked_id = NEW.liker_id
  ) INTO reciprocal_exists;

  IF NOT reciprocal_exists THEN
    RETURN NEW;
  END IF;

  -- ADDED 2026-08-07. Mutual interest is necessary and NOT sufficient.
  -- Before this, reciprocity was the only test, so two people who were
  -- never eligible for each other still got a match and a conversation.
  IF NOT public.zyra_can_match(NEW.liker_id, NEW.liked_id) THEN
    RETURN NEW;
  END IF;

  IF NEW.liker_id < NEW.liked_id THEN
    a_id := NEW.liker_id; b_id := NEW.liked_id;
  ELSE
    a_id := NEW.liked_id; b_id := NEW.liker_id;
  END IF;

  IF EXISTS (SELECT 1 FROM matches WHERE seeker_a_id = a_id AND seeker_b_id = b_id) THEN
    RETURN NEW;
  END IF;

  INSERT INTO matches (seeker_a_id, seeker_b_id, status) VALUES (a_id, b_id, 'potential') RETURNING id INTO new_match_id;
  INSERT INTO conversations (match_id) VALUES (new_match_id);
  INSERT INTO timelines (match_id) VALUES (new_match_id) RETURNING id INTO new_timeline_id;
  INSERT INTO timeline_milestones (timeline_id, milestone_type) VALUES (new_timeline_id, 'match_created');

  SELECT first_name INTO a_name FROM profiles WHERE id = a_id;
  SELECT first_name INTO b_name FROM profiles WHERE id = b_id;
  PERFORM create_notification(a_id, 'new_match', 'New Match', COALESCE(b_name, 'Someone') || ' matched with you.', new_match_id);
  PERFORM create_notification(b_id, 'new_match', 'New Match', COALESCE(a_name, 'Someone') || ' matched with you.', new_match_id);

  RETURN NEW;
END;
$function$;
