-- ZYRA shared Pause decision state machine — focused regression suite
--
-- Run only after 20260825120000_shared_pause_decision_state_machine.sql is
-- applied to the target project. The whole suite is transactional and rolls
-- back its seeded state. A failing assertion raises and names the contract.
--
-- Coverage:
--   A. request / continue / pause / resume / end transitions
--   B. Active and Paused plan capacity
--   C. compare-and-swap stale/duplicate/race protection
--   D. Journey lock bypasses (stage, answer, message and delete)
--   E. retired RPC refusal and neutral Timeline outcomes

begin;

do $suite$
declare
  a uuid := '9805470a-d9e6-4e7f-aff1-933031e4aaed';
  b uuid := '2e1bcfed-b1f5-4e91-a6a1-c81ab8bf6802';
  filler uuid[] := array[
    '12421707-fe06-4604-94bb-771ccd8ae30a'::uuid,
    '6c84767c-64df-4d24-b17d-c3239848d68e'::uuid,
    '01c7caa4-56c1-481b-8557-de901d3e7d99'::uuid,
    '03752c3d-0396-4f38-b234-84d93b724b00'::uuid,
    '6493a6e6-6fc7-4d7a-b1b5-58b637c08647'::uuid
  ];
  mid uuid;
  attempt_id uuid;
  conversation_id uuid;
  filler_id uuid;
  filler_attempt uuid;
  actor uuid;
  v bigint;
  got text;
  pause_events integer;
  continued_events integer;
begin
  if to_regprocedure('public.transition_journey_pause(uuid,text,bigint)') is null then
    raise exception 'PRECONDITION: shared Pause migration is not applied';
  end if;
  if position(
    'pg_advisory_xact_lock' in pg_get_functiondef(
      'public.transition_journey_pause(uuid,text,bigint)'::regprocedure
    )
  ) = 0 then
    raise exception 'C0 transition RPC lacks cross-Journey participant locks';
  end if;
  if public.zyra_notification_category('journey_decision_needed')
       <> 'matches_journeys'
     or public.zyra_notification_category('journey_decision_answered')
       <> 'matches_journeys' then
    raise exception 'E0 Pause decision notifications bypass preference category';
  end if;

  -- Isolate the seeded actors inside this transaction. ROLLBACK restores all.
  update public.profiles
  set onboarding_complete=true, is_active=true
  where id = any(array[a,b] || filler);
  update public.matches
  set status='ended'
  where status='active'
    and (seeker_a_id = any(array[a,b] || filler)
      or seeker_b_id = any(array[a,b] || filler));
  delete from public.matches
  where seeker_a_id=least(a,b) and seeker_b_id=greatest(a,b);

  insert into public.matches(seeker_a_id,seeker_b_id,status)
  values(least(a,b),greatest(a,b),'potential')
  returning id into mid;
  select id into attempt_id
  from public.journey_attempts where match_id=mid order by attempt_number desc limit 1;
  select id into conversation_id
  from public.conversations where match_id=mid order by created_at desc limit 1;

  perform set_config('request.jwt.claims',json_build_object('sub',a)::text,true);
  perform public.promote_journey_to_active(mid);

  -- A1: request is locked but still consumes Active capacity.
  perform public.transition_journey_pause(mid,'request_pause',0);
  select pause_version into v from public.matches where id=mid;
  if (select pause_state from public.matches where id=mid) <> 'pause_requested' then
    raise exception 'A1 request did not enter pause_requested';
  end if;
  if public.zyra_active_journey_count(a,null) <> 1
     or public.zyra_active_journey_count(b,null) <> 1 then
    raise exception 'A2 pending request released an Active slot';
  end if;
  if (select status from public.conversations where id=conversation_id) <> 'paused' then
    raise exception 'A3 pending request did not lock conversation';
  end if;

  -- C1: duplicate/stale action cannot overwrite the current request.
  begin
    perform public.transition_journey_pause(mid,'request_pause',0);
    raise exception 'C1 duplicate action was accepted';
  exception when others then
    if sqlerrm not like '%stale_pause_decision%' then raise; end if;
  end;

  -- C2: requester cannot answer their own request.
  begin
    perform public.transition_journey_pause(mid,'agree_pause',v);
    raise exception 'C2 requester answered own request';
  exception when others then
    if sqlerrm not like '%pause_transition_not_allowed%' then raise; end if;
  end;

  -- B1: pending state counts Active and no Paused capacity yet.
  if public.zyra_paused_journey_count(a,null) <> 0 then
    raise exception 'B1 request consumed Paused capacity prematurely';
  end if;

  -- D: every normal write route stays locked, including DELETE.
  begin
    update public.matches set journey_stage='phase_1' where id=mid;
    raise exception 'D1 stage update bypassed Pause lock';
  exception when others then
    if sqlerrm not like '%journey_pause_locked%' then raise; end if;
  end;
  begin
    insert into public.journey_phase_answers(
      match_id,phase,seeker_id,question_id,answer_text
    ) values(mid,1,a,'pause-lock-probe','blocked');
    raise exception 'D2 answer insert bypassed Pause lock';
  exception when others then
    if sqlerrm not like '%journey_pause_locked%' then raise; end if;
  end;
  begin
    insert into public.messages(conversation_id,sender_id,content)
    values(conversation_id,a,'blocked');
    raise exception 'D3 message insert bypassed Pause lock';
  exception when others then
    if sqlerrm not like '%journey_pause_locked%' then raise; end if;
  end;
  -- Seed a row as owner with the lock temporarily cleared, then prove a stale
  -- screen cannot delete it after the lock returns.
  update public.matches set
    pause_state='none',pause_initiated_by=null,pause_requested_by=null,
    pause_requested_at=null,pause_deadline_at=null,pause_attempt_id=null
  where id=mid;
  update public.journey_attempts set
    pause_state='none',pause_initiated_by=null,pause_requested_by=null,
    pause_requested_at=null,pause_deadline_at=null
  where id=attempt_id;
  insert into public.journey_salams(match_id,seeker_id) values(mid,a);
  update public.matches set
    pause_state='pause_requested',pause_initiated_by=a,pause_requested_by=a,
    pause_requested_at=now(),pause_attempt_id=attempt_id
  where id=mid;
  update public.journey_attempts set
    pause_state='pause_requested',pause_initiated_by=a,pause_requested_by=a,
    pause_requested_at=now()
  where id=attempt_id;
  begin
    delete from public.journey_salams where match_id=mid and seeker_id=a;
    raise exception 'D4 delete bypassed Pause lock';
  exception when others then
    if sqlerrm not like '%journey_pause_locked%' then raise; end if;
  end;

  -- Restore through state-machine-compatible state for the continuation path.
  select pause_version into v from public.matches where id=mid;
  perform set_config('request.jwt.claims',json_build_object('sub',b)::text,true);
  perform public.transition_journey_pause(mid,'request_continue',v);
  select pause_version into v from public.matches where id=mid;
  perform set_config('request.jwt.claims',json_build_object('sub',a)::text,true);
  perform public.transition_journey_pause(mid,'continue_journey',v);
  if (select pause_state from public.matches where id=mid) <> 'none'
     or (select status from public.conversations where id=conversation_id) <> 'active' then
    raise exception 'A4 Continue did not restore the exact active Journey';
  end if;

  -- A5/B2: mutual Pause frees Active and consumes Paused for BOTH accounts.
  select pause_version into v from public.matches where id=mid;
  perform public.transition_journey_pause(mid,'request_pause',v);
  select pause_version into v from public.matches where id=mid;
  perform set_config('request.jwt.claims',json_build_object('sub',b)::text,true);
  perform public.transition_journey_pause(mid,'agree_pause',v);
  if public.zyra_active_journey_count(a,null) <> 0
     or public.zyra_paused_journey_count(a,null) <> 1
     or public.zyra_paused_journey_count(b,null) <> 1 then
    raise exception 'B2 mutual Pause did not move both capacity counters';
  end if;

  -- E1: requests add no Timeline event; the final Pause adds exactly one.
  select count(*) into pause_events
  from public.timeline_milestones tm
  join public.timelines t on t.id=tm.timeline_id
  where t.match_id=mid and tm.milestone_type='journey_paused';
  if pause_events <> 1 then
    raise exception 'E1 Timeline must contain one final Pause, got %',pause_events;
  end if;

  -- A6: resume is mutual and remains in Paused capacity while pending.
  select pause_version into v from public.matches where id=mid;
  perform public.transition_journey_pause(mid,'request_resume',v);
  if public.zyra_paused_journey_count(a,null) <> 1 then
    raise exception 'B3 resume request released Paused capacity early';
  end if;
  select pause_version into v from public.matches where id=mid;
  perform set_config('request.jwt.claims',json_build_object('sub',a)::text,true);
  perform public.transition_journey_pause(mid,'agree_resume',v);
  if (select pause_state from public.matches where id=mid) <> 'none' then
    raise exception 'A6 mutual resume did not reactivate Journey';
  end if;
  select count(*) into continued_events
  from public.timeline_milestones tm
  join public.timelines t on t.id=tm.timeline_id
  where t.match_id=mid and tm.milestone_type='journey_continued';
  if continued_events <> 1 then
    raise exception 'E2 Timeline must contain one final Continue, got %',continued_events;
  end if;

  -- B4: server cap source is plan-aware.
  delete from public.subscriptions where user_id=a;
  insert into public.subscriptions(user_id,plan_type,status)
  values(a,'seeker_basic','active');
  if public.zyra_paused_journey_cap(a) <> 5 then
    raise exception 'B4 Basic Paused cap is not 5';
  end if;
  update public.subscriptions set plan_type='seeker_premium' where user_id=a;
  if public.zyra_paused_journey_cap(a) <> 10 then
    raise exception 'B5 ZYRA One Paused cap is not 10';
  end if;
  update public.subscriptions set plan_type='seeker_basic' where user_id=a;

  -- B6: fill Basic's five Paused slots, then confirm Pause must refuse
  -- atomically and leave the primary Journey active+locked.
  foreach actor in array filler loop
    delete from public.matches
    where seeker_a_id=least(a,actor) and seeker_b_id=greatest(a,actor);
    insert into public.matches(seeker_a_id,seeker_b_id,status)
    values(least(a,actor),greatest(a,actor),'potential')
    returning id into filler_id;
    select id into filler_attempt from public.journey_attempts
    where match_id=filler_id order by attempt_number desc limit 1;
    update public.matches set
      status='active',journey_stage='salam_exchange',
      pause_state='paused',pause_initiated_by=a,pause_attempt_id=filler_attempt,
      pause_version=2,suspended_by=a,suspended_at=now()
    where id=filler_id;
    update public.journey_attempts set
      status='active',journey_stage='salam_exchange',started_at=now(),
      pause_state='paused',pause_initiated_by=a,pause_version=2,
      paused_by=a,paused_at=now()
    where id=filler_attempt;
  end loop;

  select pause_version into v from public.matches where id=mid;
  perform set_config('request.jwt.claims',json_build_object('sub',a)::text,true);
  perform public.transition_journey_pause(mid,'request_pause',v);
  select pause_version into v from public.matches where id=mid;
  perform set_config('request.jwt.claims',json_build_object('sub',b)::text,true);
  begin
    perform public.transition_journey_pause(mid,'agree_pause',v);
    raise exception 'B6 Paused-cap conflict was accepted';
  exception when others then
    if sqlerrm not like '%paused_capacity_conflict%' then raise; end if;
  end;
  if (select pause_state from public.matches where id=mid) <> 'pause_requested'
     or public.zyra_active_journey_count(a,null) <> 1 then
    raise exception 'B7 capacity refusal mutated state or freed Active slot';
  end if;

  -- C3/E3: old unilateral RPCs refuse; end remains available and clears all.
  begin
    perform public.suspend_journey(mid);
    raise exception 'C3 retired suspend RPC was accepted';
  exception when others then
    if sqlerrm not like '%pause_flow_superseded%' then raise; end if;
  end;
  perform public.end_journey(mid);
  select pause_state into got from public.matches where id=mid;
  if got <> 'none' or (select status from public.matches where id=mid) <> 'ended' then
    raise exception 'E3 End did not clear pending Pause state';
  end if;

  -- Direct clients have read access to neutral state, never write access.
  if has_column_privilege('authenticated','public.matches','pause_state','UPDATE') then
    raise exception 'D5 authenticated has direct pause_state UPDATE privilege';
  end if;
  if has_table_privilege('authenticated','public.journey_attempts','UPDATE') then
    raise exception 'D6 authenticated has direct journey_attempts UPDATE privilege';
  end if;
  if has_column_privilege(
    'authenticated','public.matches','pause_initiated_by','SELECT'
  ) or has_column_privilege(
    'authenticated','public.matches','pause_requested_by','SELECT'
  ) then
    raise exception 'D7 Pause actor ids are directly readable from matches';
  end if;

  raise notice 'ZYRA shared Pause suite: PASS (transitions, caps, CAS, locks, Timeline, retired RPCs)';
end;
$suite$;

rollback;
