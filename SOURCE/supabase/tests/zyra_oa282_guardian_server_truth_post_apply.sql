-- OA-ZYRA-282 / DR-ZYRA-224 F6 / DR-ZYRA-225 — POST-APPLY only.
--
-- Do not run before 20260830200416 has a Founder apply GO and is present in
-- supabase_migrations.schema_migrations. This is the corrected canonical
-- harness: H1 uses the actual stored empty-path literal; H2 isolates links by
-- delete-then-insert with Main first; H3 uses paused_by/paused_at. The original
-- twelve 044 cases remain, with summary scope and role-switch consent updated
-- to the later DR-ZYRA-230/233 rules (OA291, preserved by F02). Main assignment
-- epochs still rotate; a continuous per-person consent survives role changes.
-- The DR-ZYRA-225 and 054 N1 active-period/trigger cases remain. The scenario runs in one
-- transaction and always rolls back. No earlier broken harness is claimed as
-- having passed.

\set ON_ERROR_STOP on

begin;

-- Catalog identity and ACL: these checks fail before the staged migration is
-- applied, which is intentional. They are the post-apply proof, not a staging
-- substitute.
do $catalog$
declare
  v_owner text;
  v_definer boolean;
  v_volatility "char";
  v_config text[];
  v_public_execute boolean;
begin
  select
    pg_get_userbyid(p.proowner),
    p.prosecdef,
    p.provolatile,
    p.proconfig,
    exists (
      select 1
      from aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) acl
      where acl.grantee = 0
        and acl.privilege_type = 'EXECUTE'
    )
  into v_owner, v_definer, v_volatility, v_config, v_public_execute
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'zyra_attempt_summary_for_guardian'
    and pg_get_function_identity_arguments(p.oid) = 'p_seeker uuid';

  if v_owner is distinct from 'postgres' then
    raise exception 'OA282 catalog: owner %, expected postgres', v_owner;
  end if;
  if v_definer is distinct from true then
    raise exception 'OA282 catalog: SECURITY DEFINER is not true';
  end if;
  if v_volatility is distinct from 's' then
    raise exception 'OA282 catalog: volatility %, expected STABLE', v_volatility;
  end if;
  if v_config is distinct from array['search_path=""']::text[] then
    raise exception 'OA282 catalog: stored config %, expected empty search_path', v_config;
  end if;
  if v_public_execute then
    raise exception 'OA282 catalog: PUBLIC still has EXECUTE';
  end if;
  if has_function_privilege(
    'anon',
    'public.zyra_attempt_summary_for_guardian(uuid)',
    'EXECUTE'
  ) then
    raise exception 'OA282 catalog: anon still has EXECUTE';
  end if;
  if not has_function_privilege(
    'authenticated',
    'public.zyra_attempt_summary_for_guardian(uuid)',
    'EXECUTE'
  ) then
    raise exception 'OA282 catalog: authenticated lacks EXECUTE';
  end if;
  if not has_function_privilege(
    'service_role',
    'public.zyra_attempt_summary_for_guardian(uuid)',
    'EXECUTE'
  ) then
    raise exception 'OA282 catalog: service_role lacks EXECUTE';
  end if;
end;
$catalog$;

-- DR-ZYRA-225 catalog, schema, grant and positive-allowlist contract.
do $dr225_catalog$
declare
  v_migration_count integer;
  v_rls boolean;
  v_force_rls boolean;
  v_summary_definition text;
  v_rpc_owner text;
  v_rpc_definer boolean;
  v_rpc_volatility "char";
  v_rpc_config text[];
  v_trigger_config text[];
  v_trigger_definition text;
  v_status_constraint text;
begin
  select count(*)
  into v_migration_count
  from supabase_migrations.schema_migrations m
  where m.version = '20260830200416';

  if v_migration_count <> 1 then
    raise exception 'DR225 catalog: migration history count %, expected 1',
      v_migration_count;
  end if;

  if not exists (
    select 1
    from pg_attribute a
    where a.attrelid = 'public.wali_links'::regclass
      and a.attname = 'main_guardian_authority_id'
      and a.atttypid = 'uuid'::regtype
      and not a.attisdropped
  ) then
    raise exception 'DR225 catalog: Main authority column missing or wrong type';
  end if;

  if not exists (
    select 1
    from pg_attribute a
    where a.attrelid = 'public.wali_links'::regclass
      and a.attname = 'active_since'
      and a.atttypid = 'timestamptz'::regtype
      and not a.attisdropped
  ) then
    raise exception 'DR225 catalog: active-period column missing or wrong type';
  end if;

  if not exists (
    select 1
    from pg_constraint c
    where c.conrelid = 'public.wali_links'::regclass
      and c.conname = 'wali_links_main_guardian_authority_state'
      and c.contype = 'c'
  ) then
    raise exception 'DR225 catalog: Main authority state constraint missing';
  end if;

  if not exists (
    select 1
    from pg_constraint c
    where c.conrelid = 'public.wali_links'::regclass
      and c.conname = 'wali_links_active_since_state'
      and c.contype = 'c'
  ) then
    raise exception 'DR225 catalog: active-period state constraint missing';
  end if;

  select c.relrowsecurity, c.relforcerowsecurity
  into v_rls, v_force_rls
  from pg_class c
  where c.oid = 'public.guardian_journey_history_consents'::regclass;

  if v_rls is distinct from true then
    raise exception 'DR225 catalog: consent table RLS is not enabled';
  end if;
  if v_force_rls is distinct from false then
    raise exception 'DR225 catalog: unexpected FORCE RLS state %', v_force_rls;
  end if;

  if has_table_privilege(
       'anon', 'public.guardian_journey_history_consents', 'SELECT'
     )
     or has_table_privilege(
       'anon', 'public.guardian_journey_history_consents', 'INSERT'
     )
     or has_table_privilege(
       'anon', 'public.guardian_journey_history_consents', 'UPDATE'
     )
     or has_table_privilege(
       'anon', 'public.guardian_journey_history_consents', 'DELETE'
     )
     or has_table_privilege(
       'authenticated', 'public.guardian_journey_history_consents', 'SELECT'
     )
     or has_table_privilege(
       'authenticated', 'public.guardian_journey_history_consents', 'INSERT'
     )
     or has_table_privilege(
       'authenticated', 'public.guardian_journey_history_consents', 'UPDATE'
     )
     or has_table_privilege(
       'authenticated', 'public.guardian_journey_history_consents', 'DELETE'
     ) then
    raise exception 'DR225 catalog: client role has direct consent-table access';
  end if;

  if not has_table_privilege(
       'service_role', 'public.guardian_journey_history_consents', 'SELECT'
     )
     or not has_table_privilege(
       'service_role', 'public.guardian_journey_history_consents', 'INSERT'
     )
     or not has_table_privilege(
       'service_role', 'public.guardian_journey_history_consents', 'UPDATE'
     )
     or not has_table_privilege(
       'service_role', 'public.guardian_journey_history_consents', 'DELETE'
     ) then
    raise exception 'DR225 catalog: service_role lacks consent-table access';
  end if;

  select
    pg_get_userbyid(p.proowner),
    p.prosecdef,
    p.provolatile,
    p.proconfig
  into v_rpc_owner, v_rpc_definer, v_rpc_volatility, v_rpc_config
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'zyra_main_guardian_history_consent'
    and pg_get_function_identity_arguments(p.oid) = 'p_enabled boolean';

  if v_rpc_owner is distinct from 'postgres'
     or v_rpc_definer is distinct from true
     or v_rpc_volatility is distinct from 'v'
     or v_rpc_config is distinct from array['search_path=""']::text[] then
    raise exception
      'DR225 catalog: RPC owner/definer/volatility/config mismatch: %/%/%/%',
      v_rpc_owner,
      v_rpc_definer,
      v_rpc_volatility,
      v_rpc_config;
  end if;

  if has_function_privilege(
       'anon',
       'public.zyra_main_guardian_history_consent(boolean)',
       'EXECUTE'
     )
     or not has_function_privilege(
       'authenticated',
       'public.zyra_main_guardian_history_consent(boolean)',
       'EXECUTE'
     )
     or not has_function_privilege(
       'service_role',
       'public.zyra_main_guardian_history_consent(boolean)',
       'EXECUTE'
     ) then
    raise exception 'DR225 catalog: consent RPC ACL mismatch';
  end if;

  select p.proconfig, pg_get_functiondef(p.oid)
  into v_trigger_config, v_trigger_definition
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'auto_designate_main_wali'
    and pg_get_function_identity_arguments(p.oid) = '';

  if v_trigger_config is distinct from array['search_path=""']::text[] then
    raise exception 'DR225 catalog: trigger function config %, expected empty',
      v_trigger_config;
  end if;

  if v_trigger_definition not like '%new.active_since := pg_catalog.clock_timestamp()%'
     or v_trigger_definition not like '%new.active_since := old.active_since%'
     or v_trigger_definition not like '%new.active_since := null%'
     or v_trigger_definition not like
       '%new.main_guardian_authority_id := pg_catalog.gen_random_uuid()%' then
    raise exception
      'DR225 catalog: trigger lacks active-period or assignment-epoch rules';
  end if;

  select pg_get_functiondef(p.oid)
  into v_summary_definition
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'zyra_attempt_summary_for_guardian'
    and pg_get_function_identity_arguments(p.oid) = 'p_seeker uuid';

  if v_summary_definition not like '%a.status = ''active''%'
     or v_summary_definition not like '%a.status = ''ended''%'
     or v_summary_definition like '%a.status <> ''potential''%'
     or v_summary_definition not like '%a.ended_at >= w.active_since%'
     or v_summary_definition like '%a.ended_at >= w.created_at%'
     or v_summary_definition not like
       '%c.guardian_link_authority_id =%w.guardian_link_authority_id%'
     or v_summary_definition like
       '%c.main_guardian_authority_id =%w.main_guardian_authority_id%' then
    raise exception 'DR225/233 catalog: summary lacks positive lifecycle/current-link consent predicate';
  end if;

  select pg_get_constraintdef(c.oid)
  into v_status_constraint
  from pg_constraint c
  where c.conrelid = 'public.journey_attempts'::regclass
    and c.conname = 'journey_attempts_status_check';

  if v_status_constraint is distinct from
    'CHECK ((status = ANY (ARRAY[''potential''::text, ''active''::text, ''ended''::text])))'
  then
    raise exception 'DR225 catalog: status constraint changed: %',
      v_status_constraint;
  end if;
end;
$dr225_catalog$;

-- Twelve direct-call cases from 044 §4. The actors are the same stable seed
-- identities used by zyra_guard_suite.sql and zyra_journey_suite.sql.
do $matrix$
declare
  seeker_a uuid := '9805470a-d9e6-4e7f-aff1-933031e4aaed';
  seeker_b uuid := '2e1bcfed-b1f5-4e91-a6a1-c81ab8bf6802';
  main_guardian uuid := '058050b9-f8d4-4449-920e-8abf7a4a0325';
  additional_guardian uuid := '6493a6e6-6fc7-4d7a-b1b5-58b637c08647';
  unrelated_user uuid := '6c84767c-64df-4d24-b17d-c3239848d68e';
  dual_counterpart uuid := '01c7caa4-56c1-481b-8557-de901d3e7d99';
  v_match uuid;
  v_attempt uuid;
  v_dual_match uuid;
  v_dual_attempt uuid;
  v_recent_match uuid;
  v_recent_attempt uuid;
  v_active_match uuid;
  v_active_attempt uuid;
  v_link_started_at timestamptz;
  v_main_active_since timestamptz;
  v_additional_active_since timestamptz;
  v_period_before timestamptz;
  v_period_after timestamptz;
  v_reactivated_since timestamptz;
  v_gap_ended_at timestamptz;
  v_additional_created_at timestamptz;
  v_created_at_after timestamptz;
  v_consent_granted_at timestamptz;
  v_consent_granted_at_after timestamptz;
  v_consent_authority uuid;
  v_consent_authority_after uuid;
  v_old_authority uuid;
  v_new_authority uuid;
  v_count integer;
  v_anon_denied boolean := false;
  v_ended boolean;
  v_consent_enabled boolean;
  v_future_rejected boolean := false;
begin
  if (
    select count(*)
    from public.profiles p
    where p.id = any(array[
      seeker_a,
      seeker_b,
      main_guardian,
      additional_guardian,
      unrelated_user,
      dual_counterpart
    ])
  ) <> 6 then
    raise exception 'OA282 premise: required seeded actors are missing';
  end if;

  -- Transaction-local isolation from any developer scenario using the same
  -- test actors. ROLLBACK restores every pre-existing row at the end.
  delete from public.matches m
  where seeker_a = any(array[m.seeker_a_id, m.seeker_b_id])
     or seeker_b = any(array[m.seeker_a_id, m.seeker_b_id])
     or unrelated_user = any(array[m.seeker_a_id, m.seeker_b_id])
     or dual_counterpart = any(array[m.seeker_a_id, m.seeker_b_id]);

  -- H2: remove the complete local relationship state first. Updating every
  -- row to is_main=false is trigger-blind: the BEFORE trigger can re-promote
  -- a row mid-statement and collide with the one-Main unique index.
  delete from public.wali_links w
  where w.seeker_id in (seeker_a, unrelated_user);

  insert into public.wali_links (seeker_id, wali_id, status, is_main)
  values (seeker_a, main_guardian, 'active', true);

  insert into public.wali_links (seeker_id, wali_id, status, is_main)
  values (seeker_a, additional_guardian, 'active', false);

  select w.active_since
  into strict v_main_active_since
  from public.wali_links w
  where w.seeker_id = seeker_a
    and w.wali_id = main_guardian;

  select w.active_since, w.created_at
  into strict v_additional_active_since, v_additional_created_at
  from public.wali_links w
  where w.seeker_id = seeker_a
    and w.wali_id = additional_guardian;

  if v_main_active_since is null or v_additional_active_since is null then
    raise exception 'DR225 active_since: activation did not set both periods';
  end if;

  insert into public.matches (
    seeker_a_id,
    seeker_b_id,
    status,
    journey_stage
  )
  values (
    least(seeker_a, seeker_b),
    greatest(seeker_a, seeker_b),
    'potential',
    null
  )
  returning id into v_match;

  select a.id
  into strict v_attempt
  from public.journey_attempts a
  where a.match_id = v_match;

  -- 1. Unauthenticated caller: direct execution must fail at the ACL.
  perform set_config('request.jwt.claims', '{}'::text, true);
  perform set_config('role', 'anon', true);
  begin
    perform *
    from public.zyra_attempt_summary_for_guardian(seeker_a);
  exception
    when insufficient_privilege then
      v_anon_denied := true;
  end;
  perform set_config('role', 'postgres', true);
  if not v_anon_denied then
    raise exception 'OA282 case 1 unauthenticated: call was not denied';
  end if;

  -- 9. Potential attempt: even the active Main receives no row.
  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', main_guardian)::text,
    true
  );
  select count(*) into v_count
  from public.zyra_attempt_summary_for_guardian(seeker_a);
  perform set_config('role', 'postgres', true);
  if v_count <> 0 then
    raise exception 'OA282 case 9 potential attempt: got %, expected 0', v_count;
  end if;

  update public.matches
  set status = 'active', journey_stage = 'phase_1'
  where id = v_match;
  update public.journey_attempts
  set status = 'active',
      journey_stage = 'phase_1',
      started_at = coalesce(started_at, clock_timestamp())
  where id = v_attempt;

  -- 2. Unrelated authenticated user.
  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', unrelated_user)::text,
    true
  );
  select count(*) into v_count
  from public.zyra_attempt_summary_for_guardian(seeker_a);
  perform set_config('role', 'postgres', true);
  if v_count <> 0 then
    raise exception 'OA282 case 2 unrelated caller: got %, expected 0', v_count;
  end if;

  -- 3. The Seeker cannot substitute themselves for a Guardian caller.
  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', seeker_a)::text,
    true
  );
  select count(*) into v_count
  from public.zyra_attempt_summary_for_guardian(seeker_a);
  perform set_config('role', 'postgres', true);
  if v_count <> 0 then
    raise exception 'OA282 case 3 Seeker caller: got %, expected 0', v_count;
  end if;

  -- 4. Active Main Guardian sees the ward's non-potential attempt.
  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', main_guardian)::text,
    true
  );
  select count(*) into v_count
  from public.zyra_attempt_summary_for_guardian(seeker_a);
  perform set_config('role', 'postgres', true);
  if v_count <> 1 then
    raise exception 'OA282 case 4 Main Guardian: got %, expected 1', v_count;
  end if;

  -- 10. Active-attempt lifecycle case, called independently from case 4;
  -- the row is present and its explicit ended fact is false.
  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', main_guardian)::text,
    true
  );
  select count(*), bool_and(not s.ended)
  into v_count, v_ended
  from public.zyra_attempt_summary_for_guardian(seeker_a) s;
  perform set_config('role', 'postgres', true);
  if v_count <> 1 or v_ended is distinct from true then
    raise exception 'OA282 case 10 active attempt: count %, not-ended %, expected 1/true',
      v_count,
      v_ended;
  end if;

  -- 5. DR230/233: an active Additional Guardian receives the minimal summary.
  -- Rich Journey detail remains a separate per-attempt View boundary (F02).
  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', additional_guardian)::text,
    true
  );
  select count(*) into v_count
  from public.zyra_attempt_summary_for_guardian(seeker_a);
  perform set_config('role', 'postgres', true);
  if v_count <> 1 then
    raise exception 'OA282 case 5 Additional Guardian summary: got %, expected 1', v_count;
  end if;

  -- 7. Removed Guardian: no relationship row remains.
  delete from public.wali_links
  where seeker_id = seeker_a and wali_id = main_guardian;
  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', main_guardian)::text,
    true
  );
  select count(*) into v_count
  from public.zyra_attempt_summary_for_guardian(seeker_a);
  perform set_config('role', 'postgres', true);
  if v_count <> 0 then
    raise exception 'OA282 case 7 removed Guardian: got %, expected 0', v_count;
  end if;

  insert into public.wali_links (seeker_id, wali_id, status, is_main)
  values (seeker_a, main_guardian, 'active', true)
  on conflict (seeker_id, wali_id) do update
    set status = 'active', is_main = true;

  -- 8. Inactive relationship: row retained as removed, still no authority.
  update public.wali_links
  set status = 'removed', is_main = false
  where seeker_id = seeker_a and wali_id = main_guardian;
  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', main_guardian)::text,
    true
  );
  select count(*) into v_count
  from public.zyra_attempt_summary_for_guardian(seeker_a);
  perform set_config('role', 'postgres', true);
  if v_count <> 0 then
    raise exception 'OA282 case 8 inactive relationship: got %, expected 0', v_count;
  end if;
  update public.wali_links
  set status = 'active', is_main = true
  where seeker_id = seeker_a and wali_id = main_guardian;

  -- 11. Paused is still a non-potential attempt and remains visible to Main.
  update public.matches
  set suspended_by = seeker_a,
      suspended_at = clock_timestamp()
  where id = v_match;
  update public.journey_attempts
  set paused_by = seeker_a,
      paused_at = clock_timestamp()
  where id = v_attempt;
  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', main_guardian)::text,
    true
  );
  select count(*) into v_count
  from public.zyra_attempt_summary_for_guardian(seeker_a);
  perform set_config('role', 'postgres', true);
  if v_count <> 1 then
    raise exception 'OA282 case 11 paused attempt: got %, expected 1', v_count;
  end if;

  -- 12. Ended remains summary-visible and returns the explicit ended fact.
  update public.matches
  set status = 'ended',
      ended_at = clock_timestamp(),
      suspended_by = null,
      suspended_at = null
  where id = v_match;
  update public.journey_attempts
  set status = 'ended',
      ended_at = clock_timestamp(),
      paused_by = null,
      paused_at = null
  where id = v_attempt;
  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', main_guardian)::text,
    true
  );
  select count(*), bool_and(s.ended)
  into v_count, v_ended
  from public.zyra_attempt_summary_for_guardian(seeker_a) s;
  perform set_config('role', 'postgres', true);
  if v_count <> 1 or v_ended is distinct from true then
    raise exception 'OA282 case 12 ended attempt: count %, ended %, expected 1/true',
      v_count,
      v_ended;
  end if;

  -- -----------------------------------------------------------------
  -- DR-ZYRA-225 extension.
  -- -----------------------------------------------------------------
  -- Use the trigger-maintained current period as the only boundary. The old
  -- ended attempt is moved before it; a second ended attempt falls after it;
  -- a new active attempt began before it. created_at is never rewritten.
  select w.active_since
  into strict v_link_started_at
  from public.wali_links w
  where w.seeker_id = seeker_a
    and w.wali_id = main_guardian
    and w.status = 'active'
    and w.is_main is true;

  if v_link_started_at is null then
    raise exception 'DR225 active_since: current Main period is null';
  end if;

  update public.matches
  set ended_at = v_link_started_at - interval '1 day'
  where id = v_match;
  update public.journey_attempts
  set started_at = v_link_started_at - interval '3 days',
      ended_at = v_link_started_at - interval '1 day'
  where id = v_attempt;

  insert into public.matches (
    seeker_a_id,
    seeker_b_id,
    status,
    journey_stage
  ) values (
    least(seeker_a, unrelated_user),
    greatest(seeker_a, unrelated_user),
    'potential',
    null
  )
  returning id into v_recent_match;
  select a.id
  into strict v_recent_attempt
  from public.journey_attempts a
  where a.match_id = v_recent_match;
  update public.matches
  set status = 'ended',
      ended_at = v_link_started_at + interval '1 day'
  where id = v_recent_match;
  update public.journey_attempts
  set status = 'ended',
      started_at = v_link_started_at,
      ended_at = v_link_started_at + interval '1 day'
  where id = v_recent_attempt;

  insert into public.matches (
    seeker_a_id,
    seeker_b_id,
    status,
    journey_stage
  ) values (
    least(seeker_a, dual_counterpart),
    greatest(seeker_a, dual_counterpart),
    'potential',
    null
  )
  returning id into v_active_match;
  select a.id
  into strict v_active_attempt
  from public.journey_attempts a
  where a.match_id = v_active_match;
  update public.matches
  set status = 'active', journey_stage = 'phase_1'
  where id = v_active_match;
  update public.journey_attempts
  set status = 'active',
      journey_stage = 'phase_1',
      started_at = v_link_started_at - interval '5 days'
  where id = v_active_attempt;

  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', main_guardian)::text,
    true
  );
  select count(*) into v_count
  from public.zyra_attempt_summary_for_guardian(seeker_a) s
  where s.attempt_id = v_attempt;
  perform set_config('role', 'postgres', true);
  if v_count <> 0 then
    raise exception 'DR225 pre-link ended hidden by default: got %, expected 0',
      v_count;
  end if;

  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', main_guardian)::text,
    true
  );
  select count(*) into v_count
  from public.zyra_attempt_summary_for_guardian(seeker_a) s
  where s.attempt_id = v_recent_attempt;
  perform set_config('role', 'postgres', true);
  if v_count <> 1 then
    raise exception 'DR225 ended-after-link visible by default: got %, expected 1',
      v_count;
  end if;

  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', main_guardian)::text,
    true
  );
  select count(*) into v_count
  from public.zyra_attempt_summary_for_guardian(seeker_a) s
  where s.attempt_id = v_active_attempt;
  perform set_config('role', 'postgres', true);
  if v_count <> 1 then
    raise exception
      'DR225 active-started-before-link visible: got %, expected 1',
      v_count;
  end if;

  -- ON grants all ended history to this exact Main assignment.
  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', seeker_a)::text,
    true
  );
  select c.enabled into v_consent_enabled
  from public.zyra_main_guardian_history_consent(true) c;
  perform set_config('role', 'postgres', true);
  if v_consent_enabled is distinct from true then
    raise exception 'DR225 toggle ON did not return confirmed ON';
  end if;

  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', main_guardian)::text,
    true
  );
  select count(*) into v_count
  from public.zyra_attempt_summary_for_guardian(seeker_a);
  perform set_config('role', 'postgres', true);
  if v_count <> 3 then
    raise exception 'DR225 toggle ON all history: got %, expected 3', v_count;
  end if;

  -- OFF deletes the current grant and the pre-link ended row vanishes in the
  -- very next call.
  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', seeker_a)::text,
    true
  );
  select c.enabled into v_consent_enabled
  from public.zyra_main_guardian_history_consent(false) c;
  perform set_config('role', 'postgres', true);
  if v_consent_enabled is distinct from false then
    raise exception 'DR225 toggle OFF did not return confirmed OFF';
  end if;

  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', main_guardian)::text,
    true
  );
  select count(*) into v_count
  from public.zyra_attempt_summary_for_guardian(seeker_a);
  perform set_config('role', 'postgres', true);
  if v_count <> 2 then
    raise exception 'DR225 toggle OFF immediate revert: got %, expected 2',
      v_count;
  end if;

  -- Capture the current uninterrupted periods after the earlier explicit
  -- inactive/reactivation case. All role changes below must preserve them.
  select w.active_since
  into strict v_main_active_since
  from public.wali_links w
  where w.seeker_id = seeker_a
    and w.wali_id = main_guardian;
  select w.active_since, w.created_at
  into strict v_additional_active_since, v_additional_created_at
  from public.wali_links w
  where w.seeker_id = seeker_a
    and w.wali_id = additional_guardian;

  -- Grant A, then make B Main. A remains continuously active as Additional:
  -- A keeps their own consent; B does not inherit it. Both active periods stay.
  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', seeker_a)::text,
    true
  );
  perform * from public.zyra_main_guardian_history_consent(true);
  perform set_config('role', 'postgres', true);
  select w.main_guardian_authority_id into v_old_authority
  from public.wali_links w
  where w.seeker_id = seeker_a
    and w.wali_id = main_guardian;

  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', seeker_a)::text,
    true
  );
  perform public.zyra_set_main_guardian(additional_guardian);
  select c.enabled into v_consent_enabled
  from public.zyra_main_guardian_history_consent(null) c;
  perform set_config('role', 'postgres', true);

  select w.main_guardian_authority_id, w.active_since
  into v_new_authority, v_period_after
  from public.wali_links w
  where w.seeker_id = seeker_a
    and w.wali_id = additional_guardian;
  if v_old_authority is null
     or v_new_authority is null
     or v_new_authority = v_old_authority
     or v_period_after is distinct from v_additional_active_since
     or (
       select w.active_since is distinct from v_main_active_since
       from public.wali_links w
       where w.seeker_id = seeker_a
         and w.wali_id = main_guardian
    )
     or v_consent_enabled is distinct from false then
    raise exception
      'DR225 Main reassignment consent auto-reset/period preservation failed';
  end if;

  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', additional_guardian)::text,
    true
  );
  select count(*) into v_count
  from public.zyra_attempt_summary_for_guardian(seeker_a);
  perform set_config('role', 'postgres', true);
  if v_count <> 2 then
    raise exception 'DR225 reassigned Main default scope: got %, expected 2',
      v_count;
  end if;

  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', main_guardian)::text,
    true
  );
  select count(*) into v_count
  from public.zyra_attempt_summary_for_guardian(seeker_a);
  perform set_config('role', 'postgres', true);
  if v_count <> 3 then
    raise exception 'DR233 former Main retains own granted summary scope: got %, expected 3',
      v_count;
  end if;

  -- R3(a): re-promote the SAME continuously active A link. The Main assignment
  -- epoch rotates, while the role-neutral link epoch and A's consent survive.
  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', seeker_a)::text,
    true
  );
  perform public.zyra_set_main_guardian(main_guardian);
  select c.enabled into v_consent_enabled
  from public.zyra_main_guardian_history_consent(null) c;
  perform set_config('role', 'postgres', true);

  select w.main_guardian_authority_id, w.active_since
  into v_new_authority, v_period_after
  from public.wali_links w
  where w.seeker_id = seeker_a
    and w.wali_id = main_guardian;
  if v_new_authority is null
     or v_new_authority = v_old_authority
     or v_period_after is distinct from v_main_active_since
     or (
       select w.active_since is distinct from v_additional_active_since
       from public.wali_links w
       where w.seeker_id = seeker_a
         and w.wali_id = additional_guardian
     )
     or v_consent_enabled is distinct from true then
    raise exception
      'DR225/233 same-active-link repromotion epoch/period/consent failed';
  end if;

  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', main_guardian)::text,
    true
  );
  select count(*) into v_count
  from public.zyra_attempt_summary_for_guardian(seeker_a) s
  where s.attempt_id = v_attempt;
  perform set_config('role', 'postgres', true);
  if v_count <> 1 then
    raise exception
      'DR233 same-active-link repromotion lost the per-person history grant';
  end if;

  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', seeker_a)::text,
    true
  );
  select c.enabled into v_consent_enabled
  from public.zyra_main_guardian_history_consent(true) c;
  perform set_config('role', 'postgres', true);
  if v_consent_enabled is distinct from true then
    raise exception
      'DR225 same-active-link repromotion fresh grant was not accepted';
  end if;

  -- R3(b): an unrelated current-Main update must preserve the epoch, period,
  -- consent snapshot and grant timestamp exactly.
  select w.main_guardian_authority_id, w.active_since
  into strict v_old_authority, v_period_before
  from public.wali_links w
  where w.seeker_id = seeker_a
    and w.wali_id = main_guardian;
  select c.main_guardian_authority_id, c.granted_at
  into strict v_consent_authority, v_consent_granted_at
  from public.guardian_journey_history_consents c
  join public.wali_links w on w.id = c.wali_link_id
  where w.seeker_id = seeker_a
    and w.wali_id = main_guardian;

  update public.wali_links
  set relationship = 'father'
  where seeker_id = seeker_a
    and wali_id = main_guardian;

  select w.main_guardian_authority_id, w.active_since
  into strict v_new_authority, v_period_after
  from public.wali_links w
  where w.seeker_id = seeker_a
    and w.wali_id = main_guardian;
  select c.main_guardian_authority_id, c.granted_at
  into strict v_consent_authority_after, v_consent_granted_at_after
  from public.guardian_journey_history_consents c
  join public.wali_links w on w.id = c.wali_link_id
  where w.seeker_id = seeker_a
    and w.wali_id = main_guardian;

  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', seeker_a)::text,
    true
  );
  select c.enabled into v_consent_enabled
  from public.zyra_main_guardian_history_consent(null) c;
  perform set_config('role', 'postgres', true);
  if v_new_authority is distinct from v_old_authority
     or v_period_after is distinct from v_period_before
     or v_consent_authority_after is distinct from v_consent_authority
     or v_consent_granted_at_after is distinct from v_consent_granted_at
     or v_consent_enabled is distinct from true then
    raise exception
      'DR225 unrelated current-Main update changed epoch/period/consent';
  end if;

  -- Prepare B's stale grant, then remove and reactivate that same row. Removal
  -- must clear active_since; reactivation must create a fresh period while
  -- created_at remains unchanged.
  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', seeker_a)::text,
    true
  );
  perform public.zyra_set_main_guardian(additional_guardian);
  perform * from public.zyra_main_guardian_history_consent(true);
  perform set_config('role', 'postgres', true);
  select w.main_guardian_authority_id, w.active_since, w.created_at
  into strict v_old_authority, v_period_before, v_additional_created_at
  from public.wali_links w
  where w.seeker_id = seeker_a
    and w.wali_id = additional_guardian;

  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', seeker_a)::text,
    true
  );
  perform public.zyra_set_main_guardian(main_guardian);
  perform public.zyra_remove_guardian(additional_guardian);
  perform set_config('role', 'postgres', true);

  select w.active_since, w.main_guardian_authority_id, w.created_at
  into v_period_after, v_new_authority, v_created_at_after
  from public.wali_links w
  where w.seeker_id = seeker_a
    and w.wali_id = additional_guardian;
  if v_period_after is not null
     or v_new_authority is not null
     or v_created_at_after is distinct from v_additional_created_at then
    raise exception
      'DR225 removal did not clear period/epoch or rewrote created_at';
  end if;

  -- Make one ended attempt land inside B's away gap, before reactivation.
  v_gap_ended_at := clock_timestamp();
  update public.matches
  set ended_at = v_gap_ended_at
  where id = v_recent_match;
  update public.journey_attempts
  set ended_at = v_gap_ended_at
  where id = v_recent_attempt;

  update public.wali_links
  set status = 'active', is_main = false
  where seeker_id = seeker_a
    and wali_id = additional_guardian;

  select w.active_since, w.created_at
  into strict v_reactivated_since, v_created_at_after
  from public.wali_links w
  where w.seeker_id = seeker_a
    and w.wali_id = additional_guardian;
  if v_reactivated_since is null
     or v_reactivated_since <= v_gap_ended_at
     or v_reactivated_since <= v_period_before
     or v_created_at_after is distinct from v_additional_created_at then
    raise exception
      'DR225 reactivation did not refresh active_since while preserving created_at';
  end if;

  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', seeker_a)::text,
    true
  );
  perform public.zyra_set_main_guardian(additional_guardian);
  select c.enabled into v_consent_enabled
  from public.zyra_main_guardian_history_consent(null) c;
  perform set_config('role', 'postgres', true);

  select w.main_guardian_authority_id, w.active_since
  into v_new_authority, v_period_after
  from public.wali_links w
  where w.seeker_id = seeker_a
    and w.wali_id = additional_guardian;
  if v_new_authority is null
     or v_new_authority = v_old_authority
     or v_period_after is distinct from v_reactivated_since
     or v_consent_enabled is distinct from false then
    raise exception
      'DR225 removed-relinked Main stale consent: old % new % state %',
      v_old_authority,
      v_new_authority,
      v_consent_enabled;
  end if;

  -- The away-gap ended attempt is now before B's fresh active_since boundary,
  -- so it stays hidden by default. The still-active Journey remains visible.
  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', additional_guardian)::text,
    true
  );
  select count(*) into v_count
  from public.zyra_attempt_summary_for_guardian(seeker_a) s
  where s.attempt_id = v_recent_attempt;
  perform set_config('role', 'postgres', true);
  if v_count <> 0 then
    raise exception
      'DR225 relink away-gap ended hidden by active_since: got %, expected 0',
      v_count;
  end if;

  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', additional_guardian)::text,
    true
  );
  select count(*) into v_count
  from public.zyra_attempt_summary_for_guardian(seeker_a) s
  where s.attempt_id = v_active_attempt;
  perform set_config('role', 'postgres', true);
  if v_count <> 1 then
    raise exception
      'DR225 relink active Journey remains visible: got %, expected 1',
      v_count;
  end if;

  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', seeker_a)::text,
    true
  );
  perform * from public.zyra_main_guardian_history_consent(true);
  perform set_config('role', 'postgres', true);
  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', additional_guardian)::text,
    true
  );
  select count(*) into v_count
  from public.zyra_attempt_summary_for_guardian(seeker_a) s
  where s.attempt_id = v_recent_attempt;
  perform set_config('role', 'postgres', true);
  if v_count <> 1 then
    raise exception
      'DR225 relink fresh consent reveals away-gap history: got %, expected 1',
      v_count;
  end if;

  -- Today the check constraint rejects unknown states. This is deliberately
  -- pinned: any future expansion must fail this harness and receive its own
  -- visibility ruling. The summary itself is also catalog-pinned above to a
  -- positive active/ended allowlist.
  begin
    update public.journey_attempts
    set status = 'future_status_probe'
    where id = v_active_attempt;
  exception
    when check_violation then
      v_future_rejected := true;
  end;
  if not v_future_rejected then
    raise exception
      'DR225 future-status fail-closed pin: constraint accepted expansion';
  end if;

  -- H4: the DR-225 assertions for this actor pair are complete. Remove that
  -- Journey scene child-first so case 6 retains its original no-romantic-edge
  -- premise; the production exclusion guard and case-6 assertions stay intact.
  delete from public.journey_attempts
  where id = v_recent_attempt;
  delete from public.matches
  where id = v_recent_match;

  -- 6. Dual-role caller: seeker_a is already a Seeker above and is now the
  -- active Main Guardian of a different ward. The ward relationship—not a
  -- caller-supplied identity or global role label—authorises this one row.
  insert into public.wali_links (seeker_id, wali_id, status, is_main)
  values (unrelated_user, seeker_a, 'active', true)
  on conflict (seeker_id, wali_id) do update
    set status = 'active', is_main = true;

  insert into public.matches (
    seeker_a_id,
    seeker_b_id,
    status,
    journey_stage
  )
  values (
    least(unrelated_user, dual_counterpart),
    greatest(unrelated_user, dual_counterpart),
    'potential',
    null
  )
  returning id into v_dual_match;
  select a.id
  into strict v_dual_attempt
  from public.journey_attempts a
  where a.match_id = v_dual_match;
  update public.matches
  set status = 'ended', ended_at = clock_timestamp()
  where id = v_dual_match;
  update public.journey_attempts
  set status = 'ended',
      started_at = coalesce(started_at, clock_timestamp()),
      ended_at = clock_timestamp()
  where id = v_dual_attempt;

  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', seeker_a)::text,
    true
  );
  select count(*) into v_count
  from public.zyra_attempt_summary_for_guardian(unrelated_user);
  perform set_config('role', 'postgres', true);
  if v_count <> 1 then
    raise exception 'OA282 case 6 dual-role caller: got %, expected 1', v_count;
  end if;

  raise notice
    'OA-ZYRA-282: 12 cases + DR225 active-period/epoch coverage, updated to DR230/233 summary scope, passed';
end;
$matrix$;

rollback;
