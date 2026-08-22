-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260808093327, applied name
-- 'block_ends_journey') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- STEP 1b: a block is a terminal safety boundary.
-- Founder approved 2026-08-08, Option B on notifications.
--
-- ══ THE INVARIANT, recorded here and on profile_blocks ═══════════════════
--
--   A block is a TERMINAL safety boundary. Nothing in the product may
--   automatically recreate or restore any relationship, visibility,
--   conversation or Journey that existed before the block. Any future
--   interaction must begin as an entirely new relationship under the
--   normal rules.
--
-- Sits alongside zyra_can_match() and zyra_can_guardian_link() as a rule
-- future features are checked against, not a behaviour of one function.
--
-- ══ TWO TRAPS THIS AVOIDS ════════════════════════════════════════════════
--
-- 1. ended_by WAS THE TELL. end_journey() never wrote it, so an ordinary
--    ending left it NULL while a block-ending would populate it —
--    "ended_by is not null" would have meant "safety ending", and Step 0's
--    prefer_not_to_say substitution would have been worthless on day one.
--    end_journey() now always records it, which the ownership register
--    always said it should.
--
-- 2. ENDING A JOURNEY DOES NOT REVOKE GUARDIAN VISIBILITY. Clause 3 tests
--    `attempt_status <> 'potential'`, and 'ended' is not 'potential'. Nor
--    does the obvious fix work: zyra_block_exists() compares auth.uid() to
--    the target, so it catches the two Seekers and misses every Guardian —
--    no Guardian is party to the block row. The block is between two
--    people; the visibility belongs to four. Hence the ATTEMPT-level check
--    in clause 3 below.
--
-- ══ ONE ENDING PATH, WHICH IS THE WHOLE POINT ════════════════════════════
-- Both kinds of ending go through zyra_end_match_internal(). Identical
-- artefacts — same status, same timestamps, same conversation closure, same
-- timeline milestone, same notification with the same wording. They differ
-- in exactly one value, end_reason, which the Step 0 accessor conceals.
-- If they were two code paths they would drift, and the drift would be the
-- disclosure.

-- ── 1. The notification type ──────────────────────────────────────────
alter table public.notifications drop constraint if exists notifications_type_check;
alter table public.notifications add constraint notifications_type_check
  check (type = any (array['new_match','new_message','wali_request','journey_ended']));

-- ── 2. The single ending path ─────────────────────────────────────────
-- NOT client-callable: it takes ended_by as an argument, so exposing it
-- would let anyone attribute an ending to someone else.
create or replace function public.zyra_end_match_internal(
  p_match_id uuid, p_ended_by uuid, p_reason text
) returns void
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
DECLARE
  m RECORD;
  v_timeline_id UUID;
  v_other UUID;
  v_ender_name TEXT;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND OR m.status = 'ended' THEN RETURN; END IF;

  UPDATE matches
     SET status = 'ended', ended_at = NOW(), ended_by = p_ended_by,
         end_reason = p_reason, suspended_by = NULL, suspended_at = NULL
   WHERE id = p_match_id;

  UPDATE journey_attempts
     SET status = 'ended', ended_at = NOW(), ended_by = p_ended_by,
         end_reason = p_reason, paused_by = NULL, paused_at = NULL
   WHERE match_id = p_match_id AND status <> 'ended';

  UPDATE conversations SET status = 'closed', closed_at = NOW()
   WHERE match_id = p_match_id AND status <> 'closed';

  SELECT id INTO v_timeline_id FROM timelines WHERE match_id = p_match_id;
  IF v_timeline_id IS NOT NULL THEN
    INSERT INTO timeline_milestones (timeline_id, milestone_type)
    VALUES (v_timeline_id, 'journey_ended');
  END IF;

  -- OPTION B. The person who ended it is not told; they know. Only the
  -- other party, and ONLY that it ended.
  --
  -- SEEKERS ONLY, deliberately. The body carries the counterpart's name,
  -- and after Step 1 a Guardian may not be entitled to it — notifying them
  -- would push a name through a channel the visibility rules do not govern,
  -- which is the exact bypass flagged in the surveillance audit.
  IF p_ended_by IS NOT NULL THEN
    v_other := CASE WHEN m.seeker_a_id = p_ended_by THEN m.seeker_b_id ELSE m.seeker_a_id END;
    SELECT first_name INTO v_ender_name FROM profiles WHERE id = p_ended_by;
    PERFORM create_notification(
      v_other, 'journey_ended', 'Journey ended',
      'Your Journey with ' || COALESCE(v_ender_name, 'someone') || ' has ended.',
      p_match_id);
  END IF;
END;
$function$;

revoke execute on function public.zyra_end_match_internal(uuid,uuid,text) from public, anon, authenticated;

comment on function public.zyra_end_match_internal(uuid,uuid,text) is
  'THE only way a Journey ends. Ordinary endings and block-endings both go '
  'through here so their observable artefacts are byte-identical and differ '
  'only in end_reason, which zyra_match_ending() conceals. Do not add a '
  'second ending path — a difference between two paths is a disclosure '
  'channel. NOT client-callable: p_ended_by would be forgeable.';

-- ── 3. end_journey() now records who ended it, and notifies ───────────
create or replace function public.end_journey(p_match_id uuid)
 returns void
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
DECLARE
  m RECORD;
  caller UUID := auth.uid();
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller IS NULL OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN
    RAISE EXCEPTION 'not a party to this match';
  END IF;
  IF m.status = 'ended' THEN RAISE EXCEPTION 'already ended'; END IF;

  -- ended_by ADDED 2026-08-08. It was never written, which would have made
  -- every block-ending identifiable by this column alone. NULL reason: an
  -- ordinary ending states none until the ending-reason feature is built.
  PERFORM public.zyra_end_match_internal(p_match_id, caller, NULL);
END;
$function$;

-- ── 4. Blocking, atomic ───────────────────────────────────────────────
create or replace function public.zyra_block_user(p_other uuid)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
DECLARE
  v_me uuid := auth.uid();
  v_match RECORD;
  v_ended int := 0;
BEGIN
  IF v_me IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;
  IF p_other IS NULL OR p_other = v_me THEN RAISE EXCEPTION 'cannot_block_self'; END IF;
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = p_other) THEN
    RAISE EXCEPTION 'no_such_user';
  END IF;

  INSERT INTO profile_blocks (blocker_id, blocked_id)
  VALUES (v_me, p_other) ON CONFLICT DO NOTHING;

  -- Every live Journey between the pair. Plural on purpose: nothing
  -- guarantees there is only one, and a loop that assumes one is the kind
  -- of assumption that survives until it does not.
  FOR v_match IN
    SELECT id FROM matches
    WHERE status <> 'ended'
      AND (   (seeker_a_id = v_me AND seeker_b_id = p_other)
           OR (seeker_a_id = p_other AND seeker_b_id = v_me) )
  LOOP
    PERFORM public.zyra_end_match_internal(v_match.id, v_me, 'safety_concern');
    v_ended := v_ended + 1;
  END LOOP;

  RETURN jsonb_build_object('status','blocked','journeys_ended',v_ended);
END;
$function$;

revoke execute on function public.zyra_block_user(uuid) from public, anon;
grant  execute on function public.zyra_block_user(uuid) to authenticated;

-- ── 5. Unblocking restores NOTHING ────────────────────────────────────
create or replace function public.zyra_unblock_user(p_other uuid)
 returns void
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
DECLARE v_me uuid := auth.uid();
BEGIN
  IF v_me IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;
  -- Deliberately the ONLY statement. The invariant at the top of this
  -- migration: nothing is recreated or restored. The Journey stays ended,
  -- the conversation stays closed, visibility stays revoked. Reconnecting
  -- means a new Journey under the normal rules.
  DELETE FROM profile_blocks WHERE blocker_id = v_me AND blocked_id = p_other;
END;
$function$;

revoke execute on function public.zyra_unblock_user(uuid) from public, anon;
grant  execute on function public.zyra_unblock_user(uuid) to authenticated;

-- ── 6. The direct write path closes ───────────────────────────────────
revoke insert, update, delete on public.profile_blocks from anon, authenticated;

comment on table public.profile_blocks is
  'A block is a TERMINAL safety boundary. Nothing may automatically '
  'recreate or restore any relationship, visibility, conversation or '
  'Journey that existed before it; reconnecting starts a new Journey under '
  'the normal rules. WRITE PATH IS zyra_block_user() / zyra_unblock_user() '
  'ONLY — direct grants revoked 2026-08-08 so the atomicity cannot be '
  'bypassed. Do not re-grant.';

-- ── 7. Clause 3 gains the ATTEMPT-level block check ───────────────────
create or replace function public.zyra_can_view_profile(p_target uuid)
 returns boolean
 language sql
 stable
 security definer
 set search_path to 'public'
as $function$
  select
    p_target = (select auth.uid())

    or exists (
      select 1 from public.wali_links w
      where w.status = 'active'
        and (   (w.seeker_id = p_target and w.wali_id   = (select auth.uid()))
             or (w.wali_id   = p_target and w.seeker_id = (select auth.uid())) )
    )

    -- PARTICIPANTS OF A SHARED ATTEMPT.
    --   status guard  2026-08-08 (Step 1)  — families do not meet at 'potential'
    --   block  guard  2026-08-08 (Step 1b) — see below
    --
    -- The block check is at the ATTEMPT level, not between viewer and
    -- target. zyra_block_exists() compares auth.uid() to the target, which
    -- catches the two Seekers and misses all four Guardians. If the two
    -- Seekers of an attempt have blocked each other, that attempt confers
    -- nothing on anyone.
    or exists (
      select 1
      from public.zyra_attempt_participant_rows me
      join public.zyra_attempt_participant_rows them
        on them.attempt_id = me.attempt_id
      where me.user_id = (select auth.uid())
        and them.user_id = p_target
        and (
              (me.role = 'seeker' and them.role = 'seeker')
           or me.attempt_status <> 'potential'
        )
        and not exists (
          select 1
          from public.matches mm
          join public.profile_blocks b
            on (b.blocker_id = mm.seeker_a_id and b.blocked_id = mm.seeker_b_id)
            or (b.blocker_id = mm.seeker_b_id and b.blocked_id = mm.seeker_a_id)
          where mm.id = me.match_id
        )
    )

    -- BROWSING. Active, published, not blocked, opposite gender.
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
        and viewer.role = 'seeker'
        and viewer.gender is not null
        and p.gender is not null
        and p.gender <> viewer.gender
    );
$function$;

-- ── 8. Backfill: existing blocks end existing Journeys ────────────────
-- Measured as 0 rows before applying. Written anyway, because it will not
-- be 0 the day it matters.
do $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT m.id, b.blocker_id
    FROM matches m
    JOIN profile_blocks b
      ON (b.blocker_id = m.seeker_a_id AND b.blocked_id = m.seeker_b_id)
      OR (b.blocker_id = m.seeker_b_id AND b.blocked_id = m.seeker_a_id)
    WHERE m.status <> 'ended'
  LOOP
    PERFORM public.zyra_end_match_internal(r.id, r.blocker_id, 'safety_concern');
  END LOOP;
END $$;
