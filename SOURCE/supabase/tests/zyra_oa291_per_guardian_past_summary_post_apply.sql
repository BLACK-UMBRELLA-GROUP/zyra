-- OA-ZYRA-291 / DR-ZYRA-233 — transactional post-apply proof.
--
-- This harness creates only transaction-scoped synthetic actors. It proves
-- per-Guardian isolation, OFF-by-default state, immediate revoke, continuous
-- role-switch survival, removal/reactivation invalidation, caller binding and
-- the unchanged four-field summary boundary. The final ROLLBACK is mandatory.

\set ON_ERROR_STOP on

begin;

do $oa291$
declare
  v_seeker uuid := pg_catalog.gen_random_uuid();
  v_counterpart uuid := pg_catalog.gen_random_uuid();
  v_outsider uuid := pg_catalog.gen_random_uuid();
  v_main uuid := pg_catalog.gen_random_uuid();
  v_additional uuid := pg_catalog.gen_random_uuid();
  v_match uuid;
  v_old_attempt uuid;
  v_recent_attempt uuid := pg_catalog.gen_random_uuid();
  v_active_attempt uuid := pg_catalog.gen_random_uuid();
  v_main_link uuid;
  v_additional_link uuid;
  v_authority_before uuid;
  v_authority_after uuid;
  v_enabled boolean;
  v_link uuid;
  v_guardian uuid;
  v_is_main boolean;
  v_count bigint;
  v_columns text;
begin
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at, confirmation_token, recovery_token,
    email_change, email_change_token_new, email_change_token_current
  )
  select
    '00000000-0000-0000-0000-000000000000'::uuid,
    actor.id,
    'authenticated',
    'authenticated',
    actor.email,
    extensions.crypt(
      pg_catalog.encode(extensions.gen_random_bytes(32), 'hex'),
      extensions.gen_salt('bf')
    ),
    pg_catalog.clock_timestamp(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    pg_catalog.clock_timestamp(),
    pg_catalog.clock_timestamp(),
    '', '', '', '', ''
  from (
    values
      (v_seeker, 'oa291-seeker@zyra.test'),
      (v_counterpart, 'oa291-counterpart@zyra.test'),
      (v_outsider, 'oa291-outsider@zyra.test'),
      (v_main, 'oa291-main@zyra.test'),
      (v_additional, 'oa291-additional@zyra.test')
  ) actor(id, email);

  insert into public.profiles (
    id, role, first_name, date_of_birth, gender,
    location_text, bio, is_active, profile_complete
  ) values
    (v_seeker, 'seeker', 'OA291 Seeker', date '1990-01-01', 'male',
      'Test', 'OA291 transaction actor.', true, false),
    (v_counterpart, 'seeker', 'OA291 Counterpart', date '1991-01-01', 'female',
      'Test', 'OA291 transaction actor.', true, false),
    (v_outsider, 'seeker', 'OA291 Outsider', date '1992-01-01', 'male',
      'Test', 'OA291 transaction actor.', true, false),
    (v_main, 'wali', 'OA291 Main', date '1960-01-01', 'male',
      'Test', 'OA291 transaction actor.', true, false),
    (v_additional, 'wali', 'OA291 Additional', date '1961-01-01', 'male',
      'Test', 'OA291 transaction actor.', true, false);

  -- The current approved contract grants no places to an unentitled actor.
  -- Supply real Basic subscriptions for this synthetic Journey's Seekers.
  insert into public.subscriptions (user_id, plan_type, status) values
    (v_seeker, 'seeker_basic', 'active'),
    (v_counterpart, 'seeker_basic', 'active');

  insert into public.matches (
    seeker_a_id, seeker_b_id, status, journey_stage, created_at
  ) values (
    least(v_seeker, v_counterpart),
    greatest(v_seeker, v_counterpart),
    'active',
    'compatibility_reveal',
    pg_catalog.clock_timestamp() - interval '120 days'
  ) returning id into v_match;

  select a.id into strict v_old_attempt
  from public.journey_attempts a
  where a.match_id = v_match and a.attempt_number = 1;

  update public.journey_attempts
  set status = 'ended',
      started_at = pg_catalog.clock_timestamp() - interval '120 days',
      ended_at = pg_catalog.clock_timestamp() - interval '90 days',
      ended_by = v_seeker,
      end_reason = 'prefer_not_to_say'
  where id = v_old_attempt;

  insert into public.wali_links (
    seeker_id, wali_id, status, is_main, relationship
  ) values (
    v_seeker, v_main, 'active', false, 'father'
  ) returning id into v_main_link;

  insert into public.wali_links (
    seeker_id, wali_id, status, is_main, relationship
  ) values (
    v_seeker, v_additional, 'active', false, 'brother'
  ) returning id into v_additional_link;

  if not exists (
    select 1 from public.wali_links
    where id = v_main_link and is_main is true
      and active_since is not null
      and guardian_link_authority_id is not null
      and main_guardian_authority_id is not null
  ) then
    raise exception 'OA291 first Guardian was not made Main with both epochs';
  end if;

  if not exists (
    select 1 from public.wali_links
    where id = v_additional_link and is_main is false
      and active_since is not null
      and guardian_link_authority_id is not null
      and main_guardian_authority_id is null
  ) then
    raise exception 'OA291 Additional Guardian epoch contract failed';
  end if;

  insert into public.journey_attempts (
    id, match_id, attempt_number, status, journey_stage,
    started_at, ended_at, ended_by, end_reason
  ) values (
    v_recent_attempt, v_match, 2, 'ended', 'compatibility_reveal',
    pg_catalog.clock_timestamp() - interval '1 minute',
    pg_catalog.clock_timestamp(), v_seeker, 'prefer_not_to_say'
  );

  insert into public.journey_attempts (
    id, match_id, attempt_number, status, journey_stage, started_at
  ) values (
    v_active_attempt, v_match, 3, 'active', 'compatibility_reveal',
    pg_catalog.clock_timestamp()
  );

  -- Both Guardians start OFF for pre-link history and see only current-period
  -- ended summaries plus the active Journey.
  foreach v_guardian in array array[v_main, v_additional]
  loop
    perform pg_catalog.set_config(
      'request.jwt.claims',
      pg_catalog.json_build_object('sub', v_guardian)::text,
      true
    );
    select count(*) into v_count
    from public.zyra_attempt_summary_for_guardian(v_seeker);
    if v_count <> 2 then
      raise exception 'OA291 Guardian default summary count %, expected 2',
        v_count;
    end if;
    if exists (
      select 1 from public.zyra_attempt_summary_for_guardian(v_seeker) s
      where s.attempt_id = v_old_attempt
    ) then
      raise exception 'OA291 pre-link ended attempt leaked while permission OFF';
    end if;
  end loop;

  -- The linked Seeker grants Main only. The response is server-confirmed and
  -- the Additional Guardian remains isolated.
  perform pg_catalog.set_config(
    'request.jwt.claims',
    pg_catalog.json_build_object('sub', v_seeker)::text,
    true
  );
  select c.enabled, c.active_guardian_link_id, c.guardian_id,
         c.guardian_is_main
    into v_enabled, v_link, v_guardian, v_is_main
  from public.zyra_guardian_history_consent(v_main, true) c;
  if not v_enabled or v_link <> v_main_link or v_guardian <> v_main
     or v_is_main is not true then
    raise exception 'OA291 Main grant response was not server-confirmed';
  end if;

  perform pg_catalog.set_config(
    'request.jwt.claims',
    pg_catalog.json_build_object('sub', v_main)::text,
    true
  );
  select count(*) into v_count
  from public.zyra_attempt_summary_for_guardian(v_seeker);
  if v_count <> 3 then
    raise exception 'OA291 Main grant did not expose exactly 3 summaries';
  end if;

  perform pg_catalog.set_config(
    'request.jwt.claims',
    pg_catalog.json_build_object('sub', v_additional)::text,
    true
  );
  select count(*) into v_count
  from public.zyra_attempt_summary_for_guardian(v_seeker);
  if v_count <> 2 then
    raise exception 'OA291 Main grant leaked to Additional Guardian';
  end if;

  -- Grant Additional, then promote them. The role-neutral link epoch and
  -- permission must survive this continuous role switch for the same person.
  perform pg_catalog.set_config(
    'request.jwt.claims',
    pg_catalog.json_build_object('sub', v_seeker)::text,
    true
  );
  perform public.zyra_guardian_history_consent(v_additional, true);
  select guardian_link_authority_id into strict v_authority_before
  from public.wali_links where id = v_additional_link;
  perform public.zyra_set_main_guardian(v_additional);
  select guardian_link_authority_id into strict v_authority_after
  from public.wali_links where id = v_additional_link;
  if v_authority_after <> v_authority_before then
    raise exception 'OA291 role switch rotated the role-neutral link epoch';
  end if;
  select c.enabled into strict v_enabled
  from public.zyra_guardian_history_consent(v_additional, null) c;
  if not v_enabled then
    raise exception 'OA291 role switch revoked the same person silently';
  end if;

  -- The legacy Main wrapper must now resolve the newly promoted person.
  select c.enabled, c.active_main_link_id, c.main_guardian_id
    into v_enabled, v_link, v_guardian
  from public.zyra_main_guardian_history_consent(null) c;
  if not v_enabled or v_link <> v_additional_link
     or v_guardian <> v_additional then
    raise exception 'OA291 legacy Main wrapper did not follow current Main';
  end if;

  -- Immediate revoke is person-specific.
  perform public.zyra_guardian_history_consent(v_additional, false);
  perform pg_catalog.set_config(
    'request.jwt.claims',
    pg_catalog.json_build_object('sub', v_additional)::text,
    true
  );
  select count(*) into v_count
  from public.zyra_attempt_summary_for_guardian(v_seeker);
  if v_count <> 2 then
    raise exception 'OA291 revoke did not immediately remove pre-link summary';
  end if;

  -- Regrant, restore the original Main, remove and reactivate Additional.
  -- The new active epoch must invalidate the old grant and start OFF.
  perform pg_catalog.set_config(
    'request.jwt.claims',
    pg_catalog.json_build_object('sub', v_seeker)::text,
    true
  );
  perform public.zyra_guardian_history_consent(v_additional, true);
  select guardian_link_authority_id into strict v_authority_before
  from public.wali_links where id = v_additional_link;
  perform public.zyra_set_main_guardian(v_main);
  perform public.zyra_remove_guardian(v_additional);

  perform pg_catalog.set_config(
    'request.jwt.claims',
    pg_catalog.json_build_object('sub', v_additional)::text,
    true
  );
  select count(*) into v_count
  from public.zyra_attempt_summary_for_guardian(v_seeker);
  if v_count <> 0 then
    raise exception 'OA291 removed Guardian retained summary access';
  end if;

  update public.wali_links
  set status = 'active', is_main = false
  where id = v_additional_link;
  select guardian_link_authority_id into strict v_authority_after
  from public.wali_links where id = v_additional_link;
  if v_authority_after = v_authority_before then
    raise exception 'OA291 reactivation reused the retired link epoch';
  end if;

  perform pg_catalog.set_config(
    'request.jwt.claims',
    pg_catalog.json_build_object('sub', v_seeker)::text,
    true
  );
  select c.enabled into strict v_enabled
  from public.zyra_guardian_history_consent(v_additional, null) c;
  if v_enabled then
    raise exception 'OA291 re-linked Guardian did not restart OFF';
  end if;

  -- Unrelated users and Guardians cannot read or change somebody else's
  -- permission. A TRUE write must reject; neutral reads return OFF.
  perform pg_catalog.set_config(
    'request.jwt.claims',
    pg_catalog.json_build_object('sub', v_outsider)::text,
    true
  );
  begin
    perform public.zyra_guardian_history_consent(v_main, true);
    raise exception 'OA291 unrelated Seeker granted another family access';
  exception
    when others then
      if sqlerrm <> 'active_guardian_required_for_history_consent' then
        raise;
      end if;
  end;

  perform pg_catalog.set_config(
    'request.jwt.claims',
    pg_catalog.json_build_object('sub', v_main)::text,
    true
  );
  begin
    perform public.zyra_guardian_history_consent(v_additional, true);
    raise exception 'OA291 Guardian mutated the Seeker-owned permission';
  exception
    when others then
      if sqlerrm <> 'active_guardian_required_for_history_consent' then
        raise;
      end if;
  end;

  -- Null caller cannot call the mutator, and summary reads fail closed.
  perform pg_catalog.set_config('request.jwt.claims', '{}', true);
  begin
    perform public.zyra_guardian_history_consent(v_main, null);
    raise exception 'OA291 null caller read consent';
  exception
    when others then
      if sqlerrm <> 'not_signed_in' then raise; end if;
  end;
  select count(*) into v_count
  from public.zyra_attempt_summary_for_guardian(v_seeker);
  if v_count <> 0 then
    raise exception 'OA291 null caller received Journey summaries';
  end if;

  -- Exact four-field output contract, never expanded data.
  select pg_catalog.string_agg(
           output_name || ':' || output_type,
           ',' order by output_position
         )
    into v_columns
  from (
    select
      argument.ordinality as output_position,
      proc.proargnames[argument.ordinality] as output_name,
      pg_catalog.format_type(argument.type_oid, null) as output_type
    from pg_catalog.pg_proc proc
    cross join lateral pg_catalog.unnest(proc.proallargtypes)
      with ordinality as argument(type_oid, ordinality)
    where proc.oid =
      'public.zyra_attempt_summary_for_guardian(uuid)'::pg_catalog.regprocedure
      and proc.proargmodes[argument.ordinality] in ('o', 'b', 't')
  ) outputs;
  if v_columns <> 'attempt_id:uuid,started_at:timestamp with time zone,'
      || 'ended_at:timestamp with time zone,ended:boolean' then
    raise exception 'OA291 output contract changed: %', v_columns;
  end if;

  if pg_catalog.has_function_privilege(
       'anon',
       'public.zyra_guardian_history_consent(uuid,boolean)',
       'EXECUTE'
     )
     or pg_catalog.has_function_privilege(
       'anon',
       'public.zyra_attempt_summary_for_guardian(uuid)',
       'EXECUTE'
     ) then
    raise exception 'OA291 anon retained RPC execution';
  end if;

  if not pg_catalog.has_function_privilege(
       'authenticated',
       'public.zyra_guardian_history_consent(uuid,boolean)',
       'EXECUTE'
     )
     or not pg_catalog.has_function_privilege(
       'authenticated',
       'public.zyra_attempt_summary_for_guardian(uuid)',
       'EXECUTE'
     ) then
    raise exception 'OA291 authenticated RPC execution missing';
  end if;

  if pg_catalog.has_table_privilege(
       'authenticated',
       'public.guardian_journey_history_consents',
       'SELECT'
     )
     or pg_catalog.has_table_privilege(
       'authenticated',
       'public.guardian_journey_history_consents',
       'INSERT'
     )
     or pg_catalog.has_table_privilege(
       'authenticated',
       'public.guardian_journey_history_consents',
       'UPDATE'
     )
     or pg_catalog.has_table_privilege(
       'authenticated',
       'public.guardian_journey_history_consents',
       'DELETE'
     ) then
    raise exception 'OA291 authenticated retained direct consent-table access';
  end if;

  raise notice 'OA-ZYRA-291 PASS — per-Guardian summaries, revoke, role switch, re-link, caller binding';
end;
$oa291$;

rollback;
