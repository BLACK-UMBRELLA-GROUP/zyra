-- SALAM FIRST — DR-ZYRA-183, 2026-08-16.
--
-- Founder: "Send Salam is the first exchange, before Compatibility
-- Reveal. Begin Journey -> Send Salam -> other user responds ->
-- continue into Compatibility Reveal."
--
-- The successor map moves; every per-stage GATE is unchanged — the
-- Salam stage still needs both Salams, the Reveal still needs both
-- reveals and both Continues. Four functions carry the order:
-- zyra_advance_stage (the map), promote_journey_to_active and
-- respond_to_journey_request (the entry stage), and
-- zyra_record_journey_milestone (the forward/backward ordering array).
-- The dev functions move in the companion migration
-- (20260816082800_salam_first_milestones_and_dev), which also carries
-- the data fix for matches parked at the old first stage.
--
-- APPLIED LIVE 2026-08-16 via apply_migration in two parts
-- (salam_first_stage_order + salam_first_milestones_and_dev); this
-- file and its companion mirror those exactly. Suite: 90/90 green
-- after (zyra_journey_suite.sql, check 9 retargeted).
--
-- The full replaced bodies live in the live database and in the
-- companion file; each create-or-replace below is the complete
-- function as applied. See the migration history for the pre-change
-- bodies (dev_counterpart_complete and dev_set_journey_stage are
-- stage-KEYED, not stage-ORDERED, and did not move).

create or replace function public.zyra_advance_stage(p_match_id uuid, p_from_stage text)
 returns table(advanced boolean, stage text, reason text)
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare
  caller     uuid := (select auth.uid());
  m          record;
  next_stage text;
  a_ok       boolean;
  b_ok       boolean;
begin
  if caller is null then
    raise exception 'not_authenticated';
  end if;

  select * into m from matches where id = p_match_id for update;
  if not found then
    raise exception 'match_not_found';
  end if;
  if caller <> m.seeker_a_id and caller <> m.seeker_b_id then
    raise exception 'not_a_party';
  end if;

  if m.status <> 'active' then
    return query select false, m.journey_stage, 'journey_not_active'; return;
  end if;
  if m.suspended_by is not null then
    return query select false, m.journey_stage, 'journey_paused'; return;
  end if;
  if m.journey_stage is distinct from p_from_stage then
    return query select false, m.journey_stage, 'stage_moved'; return;
  end if;

  -- SALAM FIRST (DR-ZYRA-183): the greeting, then the number. Only
  -- this map moved; the gates below are exactly as they were.
  next_stage := case p_from_stage
                  when 'salam_exchange'       then 'compatibility_reveal'
                  when 'compatibility_reveal' then 'wali_gate'
                  when 'wali_gate'            then 'phase_1'
                end;

  if next_stage is null then
    if p_from_stage in ('phase_1','phase_2','phase_3','family_stage') then
      raise exception 'gated_transition'
        using hint = 'This transition opens a Family Review Period. '
                     'Call open_family_review() instead.';
    end if;
    if p_from_stage = 'conversation' then
      return query select false, m.journey_stage, 'terminal_stage'; return;
    end if;
    raise exception 'unknown_stage: %', p_from_stage;
  end if;

  if p_from_stage = 'compatibility_reveal' then
    insert into journey_stage_checkpoints as jsc (match_id, stage, seeker_id)
    values (p_match_id, p_from_stage, caller)
    on conflict do nothing;
  end if;

  if p_from_stage = 'compatibility_reveal' then

    select coalesce(jc.seeker_a_revealed, false) and coalesce(jc.seeker_b_revealed, false)
      into a_ok
      from journey_compatibility jc where jc.match_id = p_match_id;
    if not coalesce(a_ok, false) then
      return query select false, p_from_stage, 'waiting_for_reveal'; return;
    end if;

    -- ALIAS-QUALIFIED: jsc.stage, not stage. See header.
    select count(distinct jsc.seeker_id) = 2 into b_ok
      from journey_stage_checkpoints jsc
     where jsc.match_id  = p_match_id
       and jsc.stage     = p_from_stage
       and jsc.seeker_id in (m.seeker_a_id, m.seeker_b_id);
    if not coalesce(b_ok, false) then
      return query select false, p_from_stage, 'waiting_for_continue'; return;
    end if;

  elsif p_from_stage = 'salam_exchange' then

    select count(distinct js.seeker_id) = 2 into a_ok
      from journey_salams js
     where js.match_id  = p_match_id
       and js.seeker_id in (m.seeker_a_id, m.seeker_b_id);
    if not coalesce(a_ok, false) then
      return query select false, p_from_stage, 'waiting_for_salam'; return;
    end if;

  elsif p_from_stage = 'wali_gate' then

    select exists (select 1 from wali_links wl
                    where wl.seeker_id = caller and wl.is_main and wl.status = 'active')
      into a_ok;
    if not a_ok then
      return query select false, p_from_stage, 'guardian_required_self'; return;
    end if;

    select exists (select 1 from wali_links wl
                    where wl.seeker_id = case when caller = m.seeker_a_id
                                              then m.seeker_b_id else m.seeker_a_id end
                      and wl.is_main and wl.status = 'active')
      into b_ok;
    if not b_ok then
      return query select false, p_from_stage, 'guardian_required_other'; return;
    end if;

  end if;

  update matches
     set journey_stage = next_stage
   where id = p_match_id and journey_stage = p_from_stage;

  if not found then
    select m2.journey_stage into next_stage from matches m2 where m2.id = p_match_id;
    return query select false, next_stage, 'stage_moved'; return;
  end if;

  update journey_attempts ja
     set journey_stage = next_stage
   where ja.match_id = p_match_id and ja.status <> 'ended';

  return query select true, next_stage, 'advanced';
end;
$function$;

-- Entry stage: a promoted or freshly re-accepted Journey now stands at
-- Salam Exchange. Only the two literals change in each.
create or replace function public.promote_journey_to_active(p_match_id uuid)
 returns void
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
DECLARE m RECORD; caller UUID := auth.uid(); v_attempt UUID; v_party UUID;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller IS NULL OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN
    RAISE EXCEPTION 'not a party to this match';
  END IF;
  IF m.status <> 'potential' THEN
    RAISE EXCEPTION 'match is not in potential state (status=%)', m.status;
  END IF;

  -- UNCHANGED (2026-08-07): re-checked at promotion, not merely at
  -- creation — a Guardian link or a block may have appeared in between.
  IF NOT public.zyra_can_match(m.seeker_a_id, m.seeker_b_id) THEN
    RAISE EXCEPTION 'not_eligible_to_match'
      USING HINT = 'Something has changed since this match was made — a '
                   'Guardian relationship or a block now exists between you.';
  END IF;

  -- UNCHANGED in role, and kept deliberately even though the constraint
  -- trigger backstops it: this produces a clear, actionable error before
  -- the trigger fires. The trigger is the race-proof guarantee (audit R7:
  -- SELECT INTO takes no row lock); this is the good message.
  -- 2026-08-12 (later the same day as pause-frees-slot): per-party,
  -- per-plan — Basic 1 / One 3, and paused rows never count.
  FOREACH v_party IN ARRAY ARRAY[m.seeker_a_id, m.seeker_b_id] LOOP
    IF zyra_active_journey_count(v_party, p_match_id) >= zyra_active_journey_cap(v_party) THEN
      RAISE EXCEPTION 'one_active_journey_limit'
        USING HINT = CASE WHEN v_party = caller
          THEN 'You are at your plan''s Active Journey limit. End or pause one before starting another.'
          ELSE 'The other person is at their Active Journey limit right now.'
        END;
    END IF;
  END LOOP;

  -- SALAM FIRST (DR-ZYRA-183): a Journey begins with the greeting.
  UPDATE matches SET status = 'active', journey_stage = 'salam_exchange'
   WHERE id = p_match_id;

  -- NEW. The omission that gated steps 4, 6 and 7.
  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id
   ORDER BY (a.status <> 'ended') DESC, a.attempt_number DESC LIMIT 1;
  IF v_attempt IS NULL THEN RAISE EXCEPTION 'no_attempt_for_match'; END IF;

  UPDATE journey_attempts
     SET status        = 'active',
         journey_stage = 'salam_exchange',
         started_at    = COALESCE(started_at, NOW())
   WHERE id = v_attempt;
END; $function$;

create or replace function public.respond_to_journey_request(p_request_id uuid, p_decision text)
 returns text
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
DECLARE
  k_cooldown CONSTANT INTERVAL := INTERVAL '6 months';  -- DR-121 item 16, a guess
  caller  UUID := (SELECT auth.uid());
  r       RECORD;
  m       RECORD;
  v_att   UUID;
  v_n     INT;
  v_name  TEXT;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;
  IF p_decision NOT IN ('accept','decline','decline_never') THEN
    RAISE EXCEPTION 'unknown_decision';
  END IF;

  SELECT * INTO r FROM journey_requests WHERE id = p_request_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'request_not_found'; END IF;
  IF r.requested_to <> caller THEN RAISE EXCEPTION 'not_yours_to_answer'; END IF;
  IF r.status <> 'pending' THEN RAISE EXCEPTION 'already_answered'; END IF;
  IF r.expires_at <= NOW() THEN RAISE EXCEPTION 'request_expired'; END IF;

  SELECT * INTO m FROM matches WHERE id = r.match_id FOR UPDATE;

  -- ── DECLINE ────────────────────────────────────────────────────────────
  -- Both kinds write the SAME request row. The difference lives only in
  -- protection_holds, which the requester cannot read, so no future SELECT on
  -- this table can leak which one happened.
  IF p_decision IN ('decline','decline_never') THEN
    UPDATE journey_requests
       SET status = 'declined', responded_at = NOW()
     WHERE id = p_request_id;

    INSERT INTO protection_holds
      (match_id, restricted_id, protected_id, hold_type, appealable, expires_at)
    VALUES (
      r.match_id, r.requested_by, caller,
      CASE WHEN p_decision = 'decline_never' THEN 'decline_permanent' ELSE 'decline_cooldown' END,
      TRUE,
      CASE WHEN p_decision = 'decline_never' THEN NULL ELSE NOW() + k_cooldown END);

    -- OA-ZYRA-159: a decline DOES notify — "hiding it behind the expiry would
    -- mean fourteen days of hope for something already answered." Identical
    -- wording for both kinds, and for an expiry sweep, by design.
    PERFORM create_notification(
      r.requested_by, 'journey_request_declined', 'Journey request',
      'Your request to begin a new Journey was not taken up.', r.match_id);

    RETURN 'declined';
  END IF;

  -- ── ACCEPT ─────────────────────────────────────────────────────────────
  -- Re-checked at accept time, not trusted from request time. Days may have
  -- passed; a block, a Guardian change or another Journey can have happened
  -- in between.
  IF zyra_block_exists(r.requested_by) THEN RAISE EXCEPTION 'not_available'; END IF;
  IF NOT zyra_can_match(caller, r.requested_by) THEN RAISE EXCEPTION 'not_available'; END IF;

  IF EXISTS (SELECT 1 FROM matches x WHERE x.status = 'active'
               AND (x.seeker_a_id IN (m.seeker_a_id, m.seeker_b_id)
                 OR x.seeker_b_id IN (m.seeker_a_id, m.seeker_b_id))) THEN
    RAISE EXCEPTION 'one_active_journey_limit'
      USING HINT = 'One of you already has an Active Journey.';
  END IF;

  -- A FRESH ATTEMPT. Nothing is deleted and ended_at is NOT cleared — the
  -- prior ending stays on the record (DR-121 item 3). The old attempt row
  -- keeps its own ended_by / ended_at / end_reason, which is where the
  -- history actually lives now.
  SELECT COALESCE(MAX(attempt_number), 0) + 1 INTO v_n
    FROM journey_attempts WHERE match_id = r.match_id;

  -- SALAM FIRST (DR-ZYRA-183): a fresh attempt begins with the greeting.
  INSERT INTO journey_attempts
    (match_id, attempt_number, status, journey_stage, started_at)
  VALUES (r.match_id, v_n, 'active', 'salam_exchange', NOW())
  RETURNING id INTO v_att;

  -- matches_end_fields_need_ended_status FORCES ended_by/end_reason/end_note
  -- to null once status leaves 'ended'. ended_at is not in that constraint,
  -- which is exactly why the preserved comment in restart_journey said to
  -- keep it: it is the one part of the ending the pair row can still carry.
  UPDATE matches
     SET status = 'active',
         journey_stage = 'salam_exchange',
         ended_by = NULL, end_reason = NULL, end_note = NULL,
         suspended_by = NULL, suspended_at = NULL
   WHERE id = r.match_id;

  -- Its own conversation and its own timeline — possible only since stage 4a
  -- moved both tables from UNIQUE(match_id) to UNIQUE(attempt_id). The old
  -- attempt's messages stay with the old conversation, so a fresh start is
  -- genuinely fresh without erasing anything.
  INSERT INTO conversations (match_id, attempt_id, status)
  VALUES (r.match_id, v_att, 'active');

  INSERT INTO timelines (match_id, attempt_id) VALUES (r.match_id, v_att);

  UPDATE journey_requests
     SET status = 'accepted', responded_at = NOW(), attempt_id = v_att
   WHERE id = p_request_id;

  SELECT first_name INTO v_name FROM profiles WHERE id = caller;
  PERFORM create_notification(
    r.requested_by, 'journey_request_accepted', 'A new Journey',
    COALESCE(v_name,'They') || ' accepted. Your new Journey has begun.',
    r.match_id);

  RETURN 'accepted';
END;
$function$;
