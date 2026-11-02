-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806105438, applied name
-- 'oa158_oa164_ending_reasons_and_no_automatic_end') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- OA-ZYRA-158 and OA-ZYRA-164 — DR-ZYRA-121, V3 §8 and approved item 12.
-- Founder authorised 2026-08-06 as independent of the journey_attempts
-- migration. Behaviour-preserving elsewhere; `matches` holds 0 rows.
--
-- =========================== 1. WHY AN ENDING NEEDS A REASON ============
--
-- Today an ending records only `ended_at`. V3 §1: "A mutual, respectful
-- ending and someone fleeing a frightening situation are indistinguishable
-- in the data." That is the whole argument.
--
-- Six reasons, deliberately. V3 §8: "Long lists at painful moments produce
-- whichever option is least awkward, not the true one."
--
-- Rejected and recorded so they are not re-proposed: "mutual decision"
-- (unverifiable from one person's tap, and invites the ender to soften
-- their own account), "personal readiness" and "life priorities" (both are
-- circumstances_changed wearing different coats), and "religious
-- incompatibility" — analytically the most valuable and still refused,
-- because it invites one member to formally record a judgement about
-- another's deen. It stays inside not_compatible.
--
-- `no_response` is the seventh value and is NOT selectable. Ghosting is
-- system-detected: the person who ghosts never opens the dropdown. The
-- constraint below enforces that — a no_response ending must have no human
-- author, and a human-authored ending may not claim it.

alter table public.matches
  add column if not exists ended_by  uuid references public.profiles(id) on delete set null,
  add column if not exists end_reason text,
  add column if not exists end_note   text;

comment on column public.matches.ended_by is
  'Who ended it. NULL with end_reason=no_response means the system detected it. Never NULL for a chosen ending.';
comment on column public.matches.end_reason is
  'V3 §8. Only safety_concern is withheld from the other party.';
comment on column public.matches.end_note is
  'Optional free text — "Anything you''d like them to know?". Never shown for a safety_concern ending.';

alter table public.matches
  add constraint matches_end_reason_known check (
    end_reason is null or end_reason in (
      'not_compatible',
      'circumstances_changed',
      'marrying_elsewhere',
      'family_decision',
      'safety_concern',
      'prefer_not_to_say',
      'no_response'          -- system only, never offered in the UI
    )
  );

-- Ghosting has no author; a chosen ending always has one.
alter table public.matches
  add constraint matches_no_response_is_system check (
    end_reason is distinct from 'no_response' or ended_by is null
  );

-- A note attached to a safety ending would be delivered to the person the
-- ending is being hidden from. Refused at the schema, not in the client.
alter table public.matches
  add constraint matches_no_note_on_safety_ending check (
    end_reason is distinct from 'safety_concern' or end_note is null
  );

alter table public.matches
  add constraint matches_end_fields_need_ended_status check (
    status = 'ended' or (ended_by is null and end_reason is null and end_note is null)
  );

-- Cap the free text. It reaches another person's screen.
alter table public.matches
  add constraint matches_end_note_length check (
    end_note is null or char_length(end_note) <= 500
  );

-- =========================== 2. THE DEAD 'paused' VALUE =================
--
-- V3 §1: suspend_journey() never sets status='paused'. It writes
-- suspended_by / suspended_at and leaves the status 'active'. The value has
-- been unreachable since the feature was built; pausing is a FLAG on an
-- Active Journey, not a lifecycle state. The implementation decided this
-- long ago and the documents had not caught up.
--
-- Verified 0 rows hold it before dropping.

alter table public.matches drop constraint if exists matches_status_check;
alter table public.matches
  add constraint matches_status_check
  check (status in ('potential','active','ended'));

-- =========================== 3. NO AUTOMATIC ENDING, EVER ===============
--
-- Approved item 12. V3 §13 names ONE offender: the 30-day Full Suspension
-- auto-End timer in JOURNEY_SUSPENSION_CURRENT_VERSION_V1 §5.3.
--
-- THAT ONE WAS NEVER BUILT. Verified: no pg_cron, no pg_net, no scheduled
-- job, and zyra_journey_service.dart:20 says it "needs a server-side" job
-- that does not exist. Removing it is a documentation edit.
--
-- BUT resume_journey() CONTAINS A DIFFERENT AUTOMATIC END, not listed in
-- V3, and this one is live:
--
--     IF EXISTS (other seeker has another active journey) THEN
--       UPDATE matches SET status = 'ended', ended_at = NOW() ...
--       RAISE EXCEPTION 'auto_ended'
--
-- A person who paused their Journey, came back, and pressed Resume had it
-- ENDED underneath them — by the platform, because of something the other
-- person did while they were away. It is the exact behaviour item 12
-- forbids, and it is worse than the timer V3 named because it is reachable
-- today.
--
-- Raised rather than silently fixed: this is an addition to OA-ZYRA-164's
-- stated scope, made because the Founder's instruction was to "remove the
-- 30-day automatic end behaviour so it aligns with the approved Journey
-- architecture", and this is automatic end behaviour.
--
-- CORRECT BEHAVIOUR under V3: refuse, change nothing, explain. The other
-- person holding an Active Journey is a reason this one cannot resume YET —
-- not a reason to destroy it. The Journey stays paused. Ending remains
-- available and free (§7A guardrail 1), so the person is not trapped; they
-- simply are not overruled. The platform reminds; the people decide.

create or replace function public.resume_journey(p_match_id uuid)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
DECLARE
  m RECORD;
  caller UUID := auth.uid();
  other_id UUID;
BEGIN
  IF caller IS NULL THEN
    RAISE EXCEPTION 'not_signed_in';
  END IF;

  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;

  -- V3 §7: "Only the person who placed a pause may lift it."
  IF caller <> m.suspended_by THEN
    RAISE EXCEPTION 'only the suspending Seeker may resume';
  END IF;

  other_id := CASE WHEN m.seeker_a_id = caller THEN m.seeker_b_id ELSE m.seeker_a_id END;

  IF EXISTS (
    SELECT 1 FROM matches
    WHERE status = 'active' AND id <> p_match_id
      AND (seeker_a_id = other_id OR seeker_b_id = other_id)
  ) THEN
    -- Refuses. Does NOT end anything. The row is untouched.
    RAISE EXCEPTION 'other_party_in_active_journey'
      USING HINT = 'This Journey stays paused for now. You can wait, or end it '
                   'yourself if you would rather.';
  END IF;

  UPDATE matches SET suspended_by = NULL, suspended_at = NULL WHERE id = p_match_id;
  UPDATE conversations SET status = 'active' WHERE match_id = p_match_id AND status = 'paused';
END;
$function$;

comment on function public.resume_journey(uuid) is
  'OA-ZYRA-164: no longer auto-ends. Previously ended the Journey if the other party had started another one. Refuses and leaves state untouched.';

revoke all on function public.resume_journey(uuid) from public, anon;
grant execute on function public.resume_journey(uuid) to authenticated;
