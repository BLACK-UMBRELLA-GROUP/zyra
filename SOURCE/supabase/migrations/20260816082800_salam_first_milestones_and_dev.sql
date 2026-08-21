-- SALAM FIRST, part two — DR-ZYRA-183, 2026-08-16. Companion to
-- 20260816082700_salam_first_stage_order.sql: the milestone trigger's
-- ordering array (forward vs backward moves), the two dev functions'
-- rewind/seed targets, and the data fix for matches parked at the old
-- first stage. Applied live the same morning; suite 90/90 green after.

create or replace function public.zyra_record_journey_milestone()
 returns trigger
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
DECLARE
  v_timeline UUID;
  v_attempt  UUID;
  v_type     TEXT;
  v_old_ord  INT;
  v_new_ord  INT;
  -- SALAM FIRST (DR-ZYRA-183): this array decides forward vs backward,
  -- so it must mirror zyra_advance_stage's map exactly.
  v_order    TEXT[] := ARRAY['salam_exchange','compatibility_reveal','wali_gate',
                             'phase_1','phase_2','phase_3','family_stage','conversation'];
BEGIN
  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = NEW.id
   ORDER BY (a.status = 'active') DESC, a.attempt_number DESC LIMIT 1;
  IF v_attempt IS NULL THEN RETURN NEW; END IF;

  INSERT INTO timelines (match_id, attempt_id) VALUES (NEW.id, v_attempt)
  ON CONFLICT (attempt_id) DO NOTHING;
  SELECT id INTO v_timeline FROM timelines WHERE attempt_id = v_attempt;
  IF v_timeline IS NULL THEN RETURN NEW; END IF;

  IF NEW.status = 'active' AND OLD.status IS DISTINCT FROM 'active' THEN
    IF NOT EXISTS (SELECT 1 FROM timeline_milestones
                    WHERE timeline_id = v_timeline AND milestone_type = 'journey_started') THEN
      INSERT INTO timeline_milestones (timeline_id, milestone_type)
      VALUES (v_timeline, 'journey_started');
    END IF;
  END IF;

  -- Pauses and resumes — DR-ZYRA-142 (2026-08-12): the Timeline records
  -- the PAIR, dated, nameless and reasonless. Deliberately NOT deduped:
  -- a couple may pause many times, and each "paused … continued" pair is
  -- part of the story, quiet by styling rather than by omission. Who
  -- paused is never written — the Timeline is the keepsake, not a ledger
  -- of responsibility (Main Guardians can read it, which is exactly why).
  IF NEW.suspended_by IS NOT NULL AND OLD.suspended_by IS NULL THEN
    INSERT INTO timeline_milestones (timeline_id, milestone_type)
    VALUES (v_timeline, 'journey_paused');
  END IF;
  -- An end-while-paused writes no "continued": journey_ended below
  -- already closes the chapter.
  IF NEW.suspended_by IS NULL AND OLD.suspended_by IS NOT NULL
     AND NEW.status = 'active' THEN
    INSERT INTO timeline_milestones (timeline_id, milestone_type)
    VALUES (v_timeline, 'journey_continued');
  END IF;

  IF NEW.journey_stage IS DISTINCT FROM OLD.journey_stage
     AND OLD.journey_stage IS NOT NULL THEN

    v_old_ord := array_position(v_order, OLD.journey_stage);
    v_new_ord := array_position(v_order, NEW.journey_stage);

    IF v_old_ord IS NOT NULL AND v_new_ord IS NOT NULL AND v_new_ord > v_old_ord THEN

      v_type := CASE OLD.journey_stage
                  WHEN 'compatibility_reveal' THEN 'compatibility_revealed'
                  WHEN 'salam_exchange'       THEN 'salam_exchanged'
                  WHEN 'wali_gate'            THEN 'guardian_linked'
                  WHEN 'phase_1'              THEN 'phase_1_complete'
                  WHEN 'phase_2'              THEN 'phase_2_complete'
                  WHEN 'phase_3'              THEN 'phase_3_complete'
                  WHEN 'family_stage'         THEN 'family_stage'
                END;

      IF v_type IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM timeline_milestones
         WHERE timeline_id = v_timeline AND milestone_type = v_type) THEN
        INSERT INTO timeline_milestones (timeline_id, milestone_type) VALUES (v_timeline, v_type);
      END IF;

      IF NEW.journey_stage = 'conversation' AND NOT EXISTS (
        SELECT 1 FROM timeline_milestones
         WHERE timeline_id = v_timeline AND milestone_type = 'conversation_started') THEN
        INSERT INTO timeline_milestones (timeline_id, milestone_type)
        VALUES (v_timeline, 'conversation_started');
      END IF;
    END IF;
  END IF;

  -- Endings — NOW GUARDED (2026-08-12): zyra_end_match_internal writes the
  -- same milestone after this trigger has fired.
  IF NEW.status = 'ended' AND OLD.status IS DISTINCT FROM 'ended' THEN
    IF NOT EXISTS (SELECT 1 FROM timeline_milestones
                    WHERE timeline_id = v_timeline AND milestone_type = 'journey_ended') THEN
      INSERT INTO timeline_milestones (timeline_id, milestone_type)
      VALUES (v_timeline, 'journey_ended');
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;

-- Start Over now lands on the NEW first stage. Full body as applied;
-- identical to the 2026-08-11 original except the two stage literals,
-- the return sentence, and one comment line.
create or replace function public.zyra_dev_rewind_journey(p_match_id uuid default null::uuid)
 returns text
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
DECLARE
  caller    UUID := (SELECT auth.uid());
  v_email   TEXT;
  v_ids     UUID[];
  v_id      UUID;
  v_conv    UUID;
  n         INT;
  total     INT := 0;
  journeys  INT := 0;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;

  SELECT email INTO v_email FROM auth.users WHERE id = caller;
  IF v_email IS NULL OR v_email NOT LIKE '%@zyra.test' THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Rewinding a Journey is limited to seeded @zyra.test accounts.';
  END IF;

  IF p_match_id IS NULL THEN
    SELECT array_agg(id) INTO v_ids FROM matches
     WHERE seeker_a_id = caller OR seeker_b_id = caller;
  ELSE
    SELECT array_agg(id) INTO v_ids FROM matches
     WHERE id = p_match_id AND (seeker_a_id = caller OR seeker_b_id = caller);
    IF v_ids IS NULL THEN RAISE EXCEPTION 'not_a_party'; END IF;
  END IF;

  IF v_ids IS NULL THEN RETURN 'No Journeys on this account — nothing to rewind.'; END IF;

  -- GUARD BOTH PARTIES (2026-08-12): the loop below deletes the other
  -- party's rows, so every party of every affected match must be seeded.
  IF EXISTS (SELECT 1 FROM matches mm
              JOIN auth.users ua ON ua.id = mm.seeker_a_id
              JOIN auth.users ub ON ub.id = mm.seeker_b_id
             WHERE mm.id = ANY(v_ids)
               AND (ua.email IS NULL OR ua.email NOT LIKE '%@zyra.test'
                 OR ub.email IS NULL OR ub.email NOT LIKE '%@zyra.test')) THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Every party of every affected match must be a seeded @zyra.test account.';
  END IF;

  FOREACH v_id IN ARRAY v_ids LOOP
    journeys := journeys + 1;

    DELETE FROM journey_phase_ratings     WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_phase_answers     WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_phase_checkpoints WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_family_answers    WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_stage_checkpoints WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_salams            WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_compatibility     WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_requests          WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;

    DELETE FROM journey_family_review_responses
     WHERE review_id IN (SELECT id FROM journey_family_reviews WHERE match_id = v_id);
    GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_family_reviews WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;

    SELECT id INTO v_conv FROM conversations WHERE match_id = v_id LIMIT 1;
    IF v_conv IS NOT NULL THEN
      DELETE FROM messages WHERE conversation_id = v_conv; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
      UPDATE conversations SET status = 'closed', closed_at = NULL WHERE id = v_conv;
    END IF;

    -- How you met, and that this Journey began, both survive. Everything
    -- the Journey itself recorded from its first stage onwards goes.
    DELETE FROM timeline_milestones
     WHERE timeline_id IN (SELECT id FROM timelines WHERE match_id = v_id)
       AND milestone_type NOT IN ('liked', 'match_created', 'journey_started');
    GET DIAGNOSTICS n = ROW_COUNT; total := total + n;

    DELETE FROM notifications WHERE related_match_id = v_id;
    GET DIAGNOSTICS n = ROW_COUNT; total := total + n;

    -- SALAM FIRST (DR-ZYRA-183): a rewound Journey starts at the greeting.
    UPDATE matches
       SET journey_stage = 'salam_exchange',
           status        = 'active',
           suspended_by  = NULL, suspended_at = NULL,
           ended_at      = NULL, ended_by     = NULL,
           end_reason    = NULL, end_note     = NULL
     WHERE id = v_id;

    UPDATE journey_attempts
       SET journey_stage = 'salam_exchange', status = 'active'
     WHERE match_id = v_id;
  END LOOP;

  RETURN format('%s Journey(s) back at Salam Exchange. %s row(s) cleared.',
                journeys, total);
END;
$function$;

-- A freshly seeded Journey starts at the greeting too. Full body as
-- applied; identical to 20260815232347 except the stage literal and
-- the return sentence.
create or replace function public.zyra_dev_seed_journey()
 returns text
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare
  caller    uuid := (select auth.uid());
  v_email   text;
  v_gender  text;
  v_partner uuid;
  v_name    text;
  v_current text;
  v_match   uuid;
  v_attempt uuid;
begin
  if caller is null then raise exception 'not_signed_in'; end if;

  select email into v_email from auth.users where id = caller;
  if v_email is null or v_email not like '%@zyra.test' then
    raise exception 'dev_only'
      using hint = 'Seeding a Journey is limited to seeded @zyra.test accounts.';
  end if;

  select gender into v_gender from profiles where id = caller;
  if v_gender is null then raise exception 'no_profile_gender'; end if;

  select u.id, p.first_name into v_partner, v_name
    from auth.users u
    join profiles p on p.id = u.id
   where u.email like 'dev.browse.%@zyra.test'
     and p.gender is distinct from v_gender
     and not exists (select 1 from matches m
                      where m.status = 'active'
                        and (m.seeker_a_id = u.id or m.seeker_b_id = u.id))
     and not exists (select 1 from matches m
                      where (m.seeker_a_id = u.id and m.seeker_b_id = caller)
                         or (m.seeker_b_id = u.id and m.seeker_a_id = caller))
   order by u.email
   limit 1;
  if v_partner is null then
    raise exception 'no_free_partner'
      using hint = 'Every seeded browse account of the opposite gender is taken or already matched with you.';
  end if;

  begin
    insert into matches (seeker_a_id, seeker_b_id, status, journey_stage)
    values (v_partner, caller, 'active', 'salam_exchange')
    returning id into v_match;
  exception when others then
    if sqlerrm = 'one_active_journey_limit' then
      select p.first_name into v_current
        from matches m
        join profiles p on p.id = case when m.seeker_a_id = caller then m.seeker_b_id else m.seeker_a_id end
       where m.status = 'active' and m.suspended_by is null
         and (m.seeker_a_id = caller or m.seeker_b_id = caller)
       order by m.created_at desc limit 1;
      return format('Your plan''s live-Journey slots are full%s — End or pause one, then seed again.',
                    case when v_current is null then '' else format(' (you''re with %s)', v_current) end);
    end if;
    raise;
  end;

  select id into v_attempt from journey_attempts
   where match_id = v_match and attempt_number = 1;
  if v_attempt is null then raise exception 'attempt_not_created'; end if;

  insert into conversations (match_id, attempt_id, status)
  values (v_match, v_attempt, 'closed')
  on conflict (attempt_id) do nothing;

  insert into timelines (match_id, attempt_id)
  values (v_match, v_attempt)
  on conflict (attempt_id) do nothing;

  return format('Seeded a real Journey with %s — it starts at Salam Exchange.', v_name);
end;
$function$;

-- DATA FIX: dev matches parked at the OLD first stage with no reveal
-- progress move back to the NEW first stage, so their walk starts at
-- the start. Any reveal progress means genuinely mid-stage-two — stays.
update matches m
   set journey_stage = 'salam_exchange'
 where m.status = 'active' and m.journey_stage = 'compatibility_reveal'
   and not exists (select 1 from journey_compatibility jc
                    where jc.match_id = m.id
                      and (jc.seeker_a_revealed or jc.seeker_b_revealed));

update journey_attempts a
   set journey_stage = 'salam_exchange'
  from matches m
 where m.id = a.match_id and a.status <> 'ended'
   and m.journey_stage = 'salam_exchange'
   and a.journey_stage = 'compatibility_reveal';
