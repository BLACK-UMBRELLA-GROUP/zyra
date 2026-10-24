-- OA-ZYRA-283 — Journey Compatibility caller boundary, POST-APPLY only.
--
-- Do not run before migration 20260910184252 has the Founder's separate
-- apply GO and is present exactly once in migration history. This harness
-- uses the current seeded @zyra.test Compatibility Reveal pair, isolates all
-- scenario changes behind a savepoint, proves the compatibility table returns
-- value-for-value to its pre-test contents, and finally rolls back the outer
-- transaction as well. No test mutation can survive a completed run.

begin;

-- Catalog, RPC shape and privilege boundary. These assertions intentionally
-- fail while 20260910184252 remains staged.
do $catalog$
declare
  v_count integer;
  v_rls boolean;
  v_force_rls boolean;
  v_role text;
  v_privilege text;
  v_expected record;
  v_oid oid;
  v_owner text;
  v_definer boolean;
  v_volatility "char";
  v_config text[];
  v_acl aclitem[];
  v_public_execute boolean;
  v_all_arg_types oid[];
  v_arg_modes "char"[];
  v_arg_names text[];
  v_return_type oid;
begin
  select count(*)
    into v_count
    from supabase_migrations.schema_migrations as migration
   where migration.version = '20260910184252';

  if v_count <> 1 then
    raise exception
      'OA283 catalog: migration history count %, expected 1', v_count;
  end if;

  select relation.relrowsecurity, relation.relforcerowsecurity
    into strict v_rls, v_force_rls
    from pg_class as relation
   where relation.oid = 'public.journey_compatibility'::regclass;

  if v_rls is distinct from true or v_force_rls is distinct from false then
    raise exception
      'OA283 catalog: journey_compatibility RLS/FORCE mismatch: %/%',
      v_rls,
      v_force_rls;
  end if;

  select count(*)
    into v_count
    from pg_policy as policy
   where policy.polrelid = 'public.journey_compatibility'::regclass;

  if v_count <> 0 then
    raise exception
      'OA283 catalog: journey_compatibility retains % policies, expected 0',
      v_count;
  end if;

  foreach v_role in array array['anon', 'authenticated'] loop
    foreach v_privilege in array array[
      'SELECT', 'INSERT', 'UPDATE', 'DELETE',
      'TRUNCATE', 'REFERENCES', 'TRIGGER'
    ] loop
      if has_table_privilege(
        v_role,
        'public.journey_compatibility',
        v_privilege
      ) then
        raise exception
          'OA283 catalog: role % retains table privilege %',
          v_role,
          v_privilege;
      end if;
    end loop;

    foreach v_privilege in array array[
      'SELECT', 'INSERT', 'UPDATE', 'REFERENCES'
    ] loop
      if has_any_column_privilege(
        v_role,
        'public.journey_compatibility',
        v_privilege
      ) then
        raise exception
          'OA283 catalog: role % retains column privilege %',
          v_role,
          v_privilege;
      end if;
    end loop;
  end loop;

  if exists (
    select 1
      from pg_class as relation
      cross join lateral aclexplode(
        coalesce(relation.relacl, acldefault('r', relation.relowner))
      ) as acl
     where relation.oid = 'public.journey_compatibility'::regclass
       and acl.grantee = 0
  ) then
    raise exception 'OA283 catalog: PUBLIC retains a table privilege';
  end if;

  if not has_table_privilege(
       'service_role', 'public.journey_compatibility', 'SELECT'
     )
     or not has_table_privilege(
       'service_role', 'public.journey_compatibility', 'INSERT'
     )
     or not has_table_privilege(
       'service_role', 'public.journey_compatibility', 'UPDATE'
     )
     or not has_table_privilege(
       'service_role', 'public.journey_compatibility', 'DELETE'
     ) then
    raise exception
      'OA283 catalog: service_role lost required direct table access';
  end if;

  if obj_description(
       'public.journey_compatibility'::regclass,
       'pg_class'
     ) not like 'RPC-only Compatibility Reveal state.%' then
    raise exception 'OA283 catalog: RPC-only table comment is absent';
  end if;

  for v_expected in
    select *
      from (values
        ('zyra_journey_compatibility_state', 's'::"char"),
        ('zyra_reveal_journey_compatibility', 'v'::"char"),
        ('zyra_compatibility_for_plus', 'v'::"char")
      ) as expected(function_name, volatility)
  loop
    select count(*)
      into v_count
      from pg_proc as proc
      join pg_namespace as namespace
        on namespace.oid = proc.pronamespace
     where namespace.nspname = 'public'
       and proc.proname = v_expected.function_name;

    if v_count <> 1 then
      raise exception
        'OA283 catalog: % has % public overloads, expected exactly 1',
        v_expected.function_name,
        v_count;
    end if;

    select
      proc.oid,
      pg_get_userbyid(proc.proowner),
      proc.prosecdef,
      proc.provolatile,
      proc.proconfig,
      proc.proacl,
      exists (
        select 1
          from aclexplode(
            coalesce(
              proc.proacl,
              acldefault('f', proc.proowner)
            )
          ) as acl
         where acl.grantee = 0
           and acl.privilege_type = 'EXECUTE'
      )
      into strict
        v_oid,
        v_owner,
        v_definer,
        v_volatility,
        v_config,
        v_acl,
        v_public_execute
      from pg_proc as proc
      join pg_namespace as namespace
        on namespace.oid = proc.pronamespace
     where namespace.nspname = 'public'
       and proc.proname = v_expected.function_name
       and pg_get_function_identity_arguments(proc.oid) =
         'p_match_id uuid';

    if v_owner is distinct from 'postgres'
       or v_definer is distinct from true
       or v_volatility is distinct from v_expected.volatility
       or v_config is distinct from array['search_path=""']::text[]
       or v_acl is null then
      raise exception
        'OA283 catalog: % owner/definer/volatility/config/explicit ACL mismatch: %/%/%/%/%',
        v_expected.function_name,
        v_owner,
        v_definer,
        v_volatility,
        v_config,
        v_acl;
    end if;

    if v_public_execute
       or has_function_privilege('anon', v_oid, 'EXECUTE')
       or has_function_privilege('service_role', v_oid, 'EXECUTE')
       or not has_function_privilege('authenticated', v_oid, 'EXECUTE') then
      raise exception
        'OA283 catalog: % ACL is not authenticated-only',
        v_expected.function_name;
    end if;

    if exists (
      select 1
        from aclexplode(v_acl) as acl
       where acl.privilege_type = 'EXECUTE'
         and acl.grantee not in (
           (select role.oid from pg_roles as role
             where role.rolname = 'postgres'),
           (select role.oid from pg_roles as role
             where role.rolname = 'authenticated')
         )
    ) then
      raise exception
        'OA283 catalog: % has an unexpected EXECUTE grantee',
        v_expected.function_name;
    end if;
  end loop;

  -- Both ordinary RPCs expose one UUID input and exactly three caller-relative
  -- OUT fields. No relationship key, side identifier, category payload,
  -- counterpart score or timestamp crosses the boundary.
  for v_expected in
    select unnest(array[
      'zyra_journey_compatibility_state',
      'zyra_reveal_journey_compatibility'
    ]) as function_name
  loop
    select
      proc.proallargtypes,
      proc.proargmodes,
      proc.proargnames,
      proc.prorettype
      into strict
        v_all_arg_types,
        v_arg_modes,
        v_arg_names,
        v_return_type
      from pg_proc as proc
      join pg_namespace as namespace
        on namespace.oid = proc.pronamespace
     where namespace.nspname = 'public'
       and proc.proname = v_expected.function_name
       and pg_get_function_identity_arguments(proc.oid) =
         'p_match_id uuid';

    if v_all_arg_types is distinct from array[
         'uuid'::regtype::oid,
         'boolean'::regtype::oid,
         'boolean'::regtype::oid,
         'numeric'::regtype::oid
       ]::oid[]
       or v_arg_modes is distinct from array[
         'i'::"char", 't'::"char", 't'::"char", 't'::"char"
       ]::"char"[]
       or v_arg_names is distinct from array[
         'p_match_id',
         'mine_revealed',
         'counterpart_revealed',
         'my_score'
       ]::text[]
       or v_return_type is distinct from 'record'::regtype::oid then
      raise exception
        'OA283 catalog: % return/input shape changed',
        v_expected.function_name;
    end if;
  end loop;

  select proc.prorettype
    into strict v_return_type
    from pg_proc as proc
    join pg_namespace as namespace
      on namespace.oid = proc.pronamespace
   where namespace.nspname = 'public'
     and proc.proname = 'zyra_compatibility_for_plus'
     and pg_get_function_identity_arguments(proc.oid) = 'p_match_id uuid';

  if v_return_type is distinct from 'numeric'::regtype::oid then
    raise exception 'OA283 catalog: Plus return type is not numeric';
  end if;
end;
$catalog$;

-- Preserve the complete live table before any scenario mutation. The table is
-- compared after ROLLBACK TO SAVEPOINT, then the outer transaction is rolled
-- back so this temporary evidence object disappears too.
create temporary table oa283_journey_compatibility_before
on commit drop
as
select * from public.journey_compatibility;

savepoint oa283_scenario;

do $matrix$
declare
  -- Current live seeded pair at authoring time. The match id and actors are
  -- stable fixture identities; the active attempt is resolved and checked at
  -- execution time so a legitimate attempt rebuild fails safely rather than
  -- pointing the harness at a guessed row.
  v_match_id constant uuid := '5fde2346-d96f-45dd-869f-64eac717e27f';
  v_seeker_a constant uuid := 'ac6f5cf7-4695-4332-8cc6-58227ac2f89f';
  v_seeker_b constant uuid := 'fd47fa36-99fb-4f11-b891-034a769e42c4';
  v_main_guardian constant uuid :=
    '058050b9-f8d4-4449-920e-8abf7a4a0325';
  v_additional_guardian constant uuid :=
    '6493a6e6-6fc7-4d7a-b1b5-58b637c08647';
  v_nonparty_seeker constant uuid :=
    '6c84767c-64df-4d24-b17d-c3239848d68e';
  v_missing_match constant uuid :=
    '00000000-0000-0000-0000-000000000001';
  v_attempt_id uuid;
  v_stale_attempt_id uuid;
  v_next_attempt_number integer;
  v_count integer;
  v_actor uuid;
  v_actor_label text;
  v_rpc text;
  v_lifecycle_case text;
  v_rejected boolean;
  v_state record;
  v_row_before jsonb;
  v_row_after jsonb;
  v_a_score numeric;
  v_b_score numeric;
  v_a_revealed boolean;
  v_b_revealed boolean;
  v_a_categories jsonb;
  v_b_categories jsonb;
  v_attempt_seen uuid;
  v_revealed_at timestamptz;
  v_joint_revealed_at timestamptz;
  v_plus_score numeric;
  v_shared_pause_columns boolean;
begin
  if (
    select count(*)
      from public.profiles as profile
     where profile.id = any(array[
       v_seeker_a,
       v_seeker_b,
       v_main_guardian,
       v_additional_guardian,
       v_nonparty_seeker
     ])
  ) <> 5 then
    raise exception 'OA283 premise: one or more seeded actors are missing';
  end if;

  if (select profile.role from public.profiles as profile
       where profile.id = v_seeker_a) is distinct from 'seeker'
     or (select profile.role from public.profiles as profile
       where profile.id = v_seeker_b) is distinct from 'seeker'
     or (select profile.role from public.profiles as profile
       where profile.id = v_nonparty_seeker) is distinct from 'seeker'
     or (select profile.role from public.profiles as profile
       where profile.id = v_main_guardian) is distinct from 'wali'
     or (select profile.role from public.profiles as profile
       where profile.id = v_additional_guardian) is distinct from 'wali' then
    raise exception 'OA283 premise: seeded actor roles changed';
  end if;

  select attempt.id
    into strict v_attempt_id
    from public.matches as m
    join public.journey_attempts as attempt
      on attempt.match_id = m.id
     and attempt.status = 'active'
     and attempt.journey_stage = 'compatibility_reveal'
     and attempt.paused_by is null
     and attempt.also_paused_by is null
   where m.id = v_match_id
     and m.seeker_a_id = v_seeker_a
     and m.seeker_b_id = v_seeker_b
     and m.status = 'active'
     and m.journey_stage = 'compatibility_reveal'
     and m.suspended_by is null
     and m.also_paused_by is null;

  if not exists (
    select 1
      from public.journey_compatibility as compatibility
     where compatibility.match_id = v_match_id
       and compatibility.attempt_id = v_attempt_id
  ) then
    raise exception
      'OA283 premise: current seeded compatibility row/attempt binding changed';
  end if;

  -- Make the two Guardian denial actors authoritative examples rather than
  -- merely profiles whose role column happens to say wali. The current fixture
  -- has no active Guardian for Seeker A; drift stops the harness before it can
  -- temporarily replace relationship state.
  if exists (
    select 1
      from public.wali_links as link
     where link.seeker_id = v_seeker_a
       and link.status = 'active'
  ) then
    raise exception
      'OA283 premise: seeded Seeker A unexpectedly has an active Guardian';
  end if;

  delete from public.wali_links as link
   where link.seeker_id = v_seeker_a
     and link.wali_id in (v_main_guardian, v_additional_guardian);

  insert into public.wali_links (seeker_id, wali_id, status, is_main)
  values (v_seeker_a, v_main_guardian, 'active', true);

  insert into public.wali_links (seeker_id, wali_id, status, is_main)
  values (v_seeker_a, v_additional_guardian, 'active', false);

  if not exists (
       select 1 from public.wali_links as link
        where link.seeker_id = v_seeker_a
          and link.wali_id = v_main_guardian
          and link.status = 'active'
          and link.is_main is true
     )
     or not exists (
       select 1 from public.wali_links as link
        where link.seeker_id = v_seeker_a
          and link.wali_id = v_additional_guardian
          and link.status = 'active'
          and link.is_main is false
     ) then
    raise exception 'OA283 premise: temporary Guardian roles are not exact';
  end if;

  -- Deterministic one-question scorer input. A scores B at 100; B scores A at
  -- 50. Every change is transaction-local and is undone at the savepoint.
  update public.onboarding_answers as answers
     set ch3_answers = case answers.user_id
           when v_seeker_a then
             pg_catalog.jsonb_build_object('oa283_for_b', 'yes')
           else pg_catalog.jsonb_build_object('oa283_for_a', 'yes')
         end,
         ch4_preferences = case answers.user_id
           when v_seeker_a then pg_catalog.jsonb_build_object(
             'oa283_for_a',
             pg_catalog.jsonb_build_object('yes', 'green')
           )
           else pg_catalog.jsonb_build_object(
             'oa283_for_b',
             pg_catalog.jsonb_build_object('yes', 'yellow')
           )
         end,
         ch4_hard_requirements = '{}'::jsonb
   where answers.user_id in (v_seeker_a, v_seeker_b);
  get diagnostics v_count = row_count;
  if v_count <> 2 then
    raise exception
      'OA283 premise: deterministic onboarding rows updated %, expected 2',
      v_count;
  end if;

  update public.seeker_details as details
     set preferences = '{}'::jsonb
   where details.user_id in (v_seeker_a, v_seeker_b);
  get diagnostics v_count = row_count;
  if v_count <> 2 then
    raise exception
      'OA283 premise: deterministic seeker_details rows updated %, expected 2',
      v_count;
  end if;

  -- Null authenticated caller: all three entrypoints reject before reading
  -- state or checking Plus entitlement.
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims', '{}'::text, true);
  foreach v_rpc in array array[
    'zyra_journey_compatibility_state',
    'zyra_reveal_journey_compatibility',
    'zyra_compatibility_for_plus'
  ] loop
    v_rejected := false;
    begin
      execute pg_catalog.format('select * from public.%I($1)', v_rpc)
        using v_match_id;
    exception
      when sqlstate '42501' then
        if sqlerrm is distinct from 'not_signed_in' then
          raise exception
            'OA283 null caller: % returned unexpected message %',
            v_rpc,
            sqlerrm;
        end if;
        v_rejected := true;
    end;
    if not v_rejected then
      raise exception 'OA283 null caller: % was not denied', v_rpc;
    end if;
  end loop;
  perform set_config('role', 'postgres', true);

  -- A nonparty Seeker and both real Guardian relationship roles receive the
  -- same non-enumerating denial from all three RPCs.
  foreach v_actor in array array[
    v_nonparty_seeker,
    v_main_guardian,
    v_additional_guardian
  ] loop
    v_actor_label := case v_actor
      when v_nonparty_seeker then 'nonparty Seeker'
      when v_main_guardian then 'Main Guardian'
      else 'Additional Guardian'
    end;

    perform set_config('role', 'authenticated', true);
    perform set_config(
      'request.jwt.claims',
      pg_catalog.json_build_object('sub', v_actor)::text,
      true
    );

    foreach v_rpc in array array[
      'zyra_journey_compatibility_state',
      'zyra_reveal_journey_compatibility',
      'zyra_compatibility_for_plus'
    ] loop
      v_rejected := false;
      begin
        execute pg_catalog.format('select * from public.%I($1)', v_rpc)
          using v_match_id;
      exception
        when sqlstate '42501' then
          if sqlerrm is distinct from 'not_a_party' then
            raise exception
              'OA283 %: % returned unexpected message %',
              v_actor_label,
              v_rpc,
              sqlerrm;
          end if;
          v_rejected := true;
      end;
      if not v_rejected then
        raise exception 'OA283 %: % was not denied', v_actor_label, v_rpc;
      end if;
    end loop;
    perform set_config('role', 'postgres', true);
  end loop;

  -- Match absence is deliberately indistinguishable from non-participation.
  -- This fixed UUID must remain absent; otherwise the premise fails rather
  -- than testing an accidental real relationship.
  if exists (
    select 1 from public.matches as m where m.id = v_missing_match
  ) then
    raise exception 'OA283 premise: fixed missing-match UUID now exists';
  end if;

  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    pg_catalog.json_build_object('sub', v_seeker_a)::text,
    true
  );
  foreach v_rpc in array array[
    'zyra_journey_compatibility_state',
    'zyra_reveal_journey_compatibility',
    'zyra_compatibility_for_plus'
  ] loop
    v_rejected := false;
    begin
      execute pg_catalog.format('select * from public.%I($1)', v_rpc)
        using v_missing_match;
    exception
      when sqlstate '42501' then
        if sqlerrm is distinct from 'not_a_party' then
          raise exception
            'OA283 missing match: % returned unexpected message %',
            v_rpc,
            sqlerrm;
        end if;
        v_rejected := true;
    end;
    if not v_rejected then
      raise exception 'OA283 missing match: % was not denied', v_rpc;
    end if;
  end loop;
  perform set_config('role', 'postgres', true);

  -- Successful absence is not failure: a valid party gets exactly one
  -- false/false/NULL caller-relative state row.
  delete from public.journey_compatibility as compatibility
   where compatibility.match_id = v_match_id;

  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    pg_catalog.json_build_object('sub', v_seeker_a)::text,
    true
  );
  select *
    into strict v_state
    from public.zyra_journey_compatibility_state(v_match_id);
  perform set_config('role', 'postgres', true);

  if v_state.mine_revealed is distinct from false
     or v_state.counterpart_revealed is distinct from false
     or v_state.my_score is not null then
    raise exception
      'OA283 absent row: expected false/false/NULL, got %/%/%',
      v_state.mine_revealed,
      v_state.counterpart_revealed,
      v_state.my_score;
  end if;

  -- Direct authenticated access is a hard ACL denial, not an RLS-filtered
  -- empty result. INSERT is tested while the row is absent.
  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    pg_catalog.json_build_object('sub', v_seeker_a)::text,
    true
  );

  v_rejected := false;
  begin
    execute
      'select seeker_b_score from public.journey_compatibility '
      'where match_id = $1'
      using v_match_id;
  exception
    when insufficient_privilege then v_rejected := true;
  end;
  if not v_rejected then
    raise exception 'OA283 direct SELECT was not denied';
  end if;

  v_rejected := false;
  begin
    execute
      'insert into public.journey_compatibility (match_id, attempt_id) '
      'values ($1, $2)'
      using v_match_id, v_attempt_id;
  exception
    when insufficient_privilege then v_rejected := true;
  end;
  if not v_rejected then
    raise exception 'OA283 direct INSERT was not denied';
  end if;
  perform set_config('role', 'postgres', true);

  -- First reveal by A: the RPC creates/binds the current-attempt row and may
  -- touch only A's flag/score. The ordinary return still hides the score.
  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    pg_catalog.json_build_object('sub', v_seeker_a)::text,
    true
  );
  select *
    into strict v_state
    from public.zyra_reveal_journey_compatibility(v_match_id);
  perform set_config('role', 'postgres', true);

  select
    compatibility.seeker_a_revealed,
    compatibility.seeker_b_revealed,
    compatibility.seeker_a_score,
    compatibility.seeker_b_score,
    compatibility.seeker_a_categories,
    compatibility.seeker_b_categories,
    compatibility.attempt_id,
    compatibility.revealed_at
    into strict
      v_a_revealed,
      v_b_revealed,
      v_a_score,
      v_b_score,
      v_a_categories,
      v_b_categories,
      v_attempt_seen,
      v_revealed_at
    from public.journey_compatibility as compatibility
   where compatibility.match_id = v_match_id;

  if v_state.mine_revealed is distinct from true
     or v_state.counterpart_revealed is distinct from false
     or v_state.my_score is not null
     or v_a_revealed is distinct from true
     or v_b_revealed is distinct from false
     or v_a_score is distinct from 100::numeric
     or v_b_score is not null
     or v_a_categories is not null
     or v_b_categories is not null
     or v_attempt_seen is distinct from v_attempt_id
     or v_revealed_at is not null then
    raise exception
      'OA283 A reveal: caller/column/binding result is not exact';
  end if;

  -- B sees the mirrored flags, and neither caller can see a score before the
  -- second consent even though A's caller-owned score is already stored.
  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    pg_catalog.json_build_object('sub', v_seeker_b)::text,
    true
  );
  select *
    into strict v_state
    from public.zyra_journey_compatibility_state(v_match_id);
  perform set_config('role', 'postgres', true);
  if v_state.mine_revealed is distinct from false
     or v_state.counterpart_revealed is distinct from true
     or v_state.my_score is not null then
    raise exception
      'OA283 B pre-mutual mapping: expected false/true/NULL, got %/%/%',
      v_state.mine_revealed,
      v_state.counterpart_revealed,
      v_state.my_score;
  end if;

  -- Direct UPDATE is denied even for the participant and even when aimed at
  -- the counterpart-owned columns on an otherwise visible historical row.
  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    pg_catalog.json_build_object('sub', v_seeker_a)::text,
    true
  );
  v_rejected := false;
  begin
    execute
      'update public.journey_compatibility '
      'set seeker_b_revealed = true, seeker_b_score = 99 '
      'where match_id = $1'
      using v_match_id;
  exception
    when insufficient_privilege then v_rejected := true;
  end;
  if not v_rejected then
    raise exception 'OA283 direct UPDATE was not denied';
  end if;
  perform set_config('role', 'postgres', true);

  -- A retry is exactly idempotent before mutual reveal.
  select to_jsonb(compatibility)
    into strict v_row_before
    from public.journey_compatibility as compatibility
   where compatibility.match_id = v_match_id;

  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    pg_catalog.json_build_object('sub', v_seeker_a)::text,
    true
  );
  perform * from public.zyra_reveal_journey_compatibility(v_match_id);
  perform set_config('role', 'postgres', true);

  select to_jsonb(compatibility)
    into strict v_row_after
    from public.journey_compatibility as compatibility
   where compatibility.match_id = v_match_id;

  if v_row_after is distinct from v_row_before then
    raise exception 'OA283 idempotence: A retry changed the stored row';
  end if;

  -- B is the second caller. A's fields and binding are snapshotted first and
  -- must remain unchanged; only B's flag/score plus the joint timestamp land.
  select
    compatibility.seeker_a_revealed,
    compatibility.seeker_a_score,
    compatibility.seeker_a_categories,
    compatibility.attempt_id
    into strict
      v_a_revealed,
      v_a_score,
      v_a_categories,
      v_attempt_seen
    from public.journey_compatibility as compatibility
   where compatibility.match_id = v_match_id;

  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    pg_catalog.json_build_object('sub', v_seeker_b)::text,
    true
  );
  select *
    into strict v_state
    from public.zyra_reveal_journey_compatibility(v_match_id);
  perform set_config('role', 'postgres', true);

  select
    compatibility.seeker_a_revealed,
    compatibility.seeker_b_revealed,
    compatibility.seeker_a_score,
    compatibility.seeker_b_score,
    compatibility.seeker_a_categories,
    compatibility.seeker_b_categories,
    compatibility.attempt_id,
    compatibility.revealed_at
    into strict
      v_a_revealed,
      v_b_revealed,
      v_a_score,
      v_b_score,
      v_a_categories,
      v_b_categories,
      v_attempt_seen,
      v_joint_revealed_at
    from public.journey_compatibility as compatibility
   where compatibility.match_id = v_match_id;

  if v_state.mine_revealed is distinct from true
     or v_state.counterpart_revealed is distinct from true
     or v_state.my_score is distinct from 50::numeric
     or v_a_revealed is distinct from true
     or v_b_revealed is distinct from true
     or v_a_score is distinct from 100::numeric
     or v_b_score is distinct from 50::numeric
     or v_a_categories is not null
     or v_b_categories is not null
     or v_attempt_seen is distinct from v_attempt_id
     or v_joint_revealed_at is null then
    raise exception
      'OA283 B reveal: counterpart isolation/joint timestamp is not exact';
  end if;

  -- Caller-relative mapping after mutual reveal is deliberately asymmetric.
  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    pg_catalog.json_build_object('sub', v_seeker_a)::text,
    true
  );
  select *
    into strict v_state
    from public.zyra_journey_compatibility_state(v_match_id);
  perform set_config('role', 'postgres', true);
  if v_state.mine_revealed is distinct from true
     or v_state.counterpart_revealed is distinct from true
     or v_state.my_score is distinct from 100::numeric then
    raise exception
      'OA283 A post-mutual mapping: expected true/true/100, got %/%/%',
      v_state.mine_revealed,
      v_state.counterpart_revealed,
      v_state.my_score;
  end if;

  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    pg_catalog.json_build_object('sub', v_seeker_b)::text,
    true
  );
  select *
    into strict v_state
    from public.zyra_journey_compatibility_state(v_match_id);
  perform set_config('role', 'postgres', true);
  if v_state.mine_revealed is distinct from true
     or v_state.counterpart_revealed is distinct from true
     or v_state.my_score is distinct from 50::numeric then
    raise exception
      'OA283 B post-mutual mapping: expected true/true/50, got %/%/%',
      v_state.mine_revealed,
      v_state.counterpart_revealed,
      v_state.my_score;
  end if;

  -- A repeated second reveal cannot move the established joint timestamp or
  -- recompute either score.
  select to_jsonb(compatibility)
    into strict v_row_before
    from public.journey_compatibility as compatibility
   where compatibility.match_id = v_match_id;

  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    pg_catalog.json_build_object('sub', v_seeker_b)::text,
    true
  );
  perform * from public.zyra_reveal_journey_compatibility(v_match_id);
  perform set_config('role', 'postgres', true);

  select to_jsonb(compatibility)
    into strict v_row_after
    from public.journey_compatibility as compatibility
   where compatibility.match_id = v_match_id;

  if v_row_after is distinct from v_row_before then
    raise exception 'OA283 idempotence: B retry changed the mutual row';
  end if;

  -- Give Seeker A a transaction-local entitlement before the attempt and
  -- lifecycle matrix. This ensures Plus denials below prove the same
  -- actor/state/attempt boundary rather than stopping earlier at
  -- plus_required. The later no-entitlement case removes it explicitly.
  insert into public.profile_unlocks (
    unlocker_id,
    unlocked_id,
    unlock_type
  ) values (
    v_seeker_a,
    v_seeker_b,
    'paid_plus_single'
  ) on conflict do nothing;

  -- A stale row from another attempt, and a legacy NULL attempt, both fail
  -- closed in every path. Neither rejected call mutates the row.
  select coalesce(max(attempt.attempt_number), 0) + 1
    into v_next_attempt_number
    from public.journey_attempts as attempt
   where attempt.match_id = v_match_id;

  insert into public.journey_attempts (
    match_id,
    attempt_number,
    status,
    journey_stage,
    started_at,
    ended_at
  ) values (
    v_match_id,
    v_next_attempt_number,
    'ended',
    'compatibility_reveal',
    pg_catalog.clock_timestamp() - interval '2 days',
    pg_catalog.clock_timestamp() - interval '1 day'
  ) returning id into v_stale_attempt_id;

  update public.journey_compatibility as compatibility
     set attempt_id = v_stale_attempt_id
   where compatibility.match_id = v_match_id;

  foreach v_rpc in array array[
    'zyra_journey_compatibility_state',
    'zyra_reveal_journey_compatibility',
    'zyra_compatibility_for_plus'
  ] loop
    select to_jsonb(compatibility)
      into strict v_row_before
      from public.journey_compatibility as compatibility
     where compatibility.match_id = v_match_id;
    perform set_config('role', 'authenticated', true);
    perform set_config(
      'request.jwt.claims',
      pg_catalog.json_build_object('sub', v_seeker_a)::text,
      true
    );
    v_rejected := false;
    begin
      execute pg_catalog.format('select * from public.%I($1)', v_rpc)
        using v_match_id;
    exception
      when sqlstate '55000' then
        if sqlerrm is distinct from 'compatibility_attempt_mismatch' then
          raise exception
            'OA283 stale attempt: % returned unexpected message %',
            v_rpc,
            sqlerrm;
        end if;
        v_rejected := true;
    end;
    perform set_config('role', 'postgres', true);
    if not v_rejected then
      raise exception 'OA283 stale attempt: % was not refused', v_rpc;
    end if;
    select to_jsonb(compatibility)
      into strict v_row_after
      from public.journey_compatibility as compatibility
     where compatibility.match_id = v_match_id;
    if v_row_after is distinct from v_row_before then
      raise exception 'OA283 stale attempt: % mutated the row', v_rpc;
    end if;
  end loop;

  update public.journey_compatibility as compatibility
     set attempt_id = null
   where compatibility.match_id = v_match_id;

  foreach v_rpc in array array[
    'zyra_journey_compatibility_state',
    'zyra_reveal_journey_compatibility',
    'zyra_compatibility_for_plus'
  ] loop
    perform set_config('role', 'authenticated', true);
    perform set_config(
      'request.jwt.claims',
      pg_catalog.json_build_object('sub', v_seeker_a)::text,
      true
    );
    v_rejected := false;
    begin
      execute pg_catalog.format('select * from public.%I($1)', v_rpc)
        using v_match_id;
    exception
      when sqlstate '55000' then
        if sqlerrm is distinct from 'compatibility_attempt_mismatch' then
          raise exception
            'OA283 NULL attempt: % returned unexpected message %',
            v_rpc,
            sqlerrm;
        end if;
        v_rejected := true;
    end;
    perform set_config('role', 'postgres', true);
    if not v_rejected then
      raise exception 'OA283 NULL attempt: % was not refused', v_rpc;
    end if;
  end loop;

  update public.journey_compatibility as compatibility
     set attempt_id = v_attempt_id
   where compatibility.match_id = v_match_id;

  -- Every lifecycle condition is rejected by all three entrypoints.
  -- Restore the exact active/unpaused Compatibility Reveal state after each
  -- case so one failure cannot make the next case pass for the wrong reason.
  foreach v_lifecycle_case in array array[
    'potential', 'wrong_stage', 'paused', 'ended'
  ] loop
    if v_lifecycle_case = 'potential' then
      update public.matches as m
         set status = 'potential'
       where m.id = v_match_id;
      update public.journey_attempts as attempt
         set status = 'potential'
       where attempt.id = v_attempt_id;
    elsif v_lifecycle_case = 'wrong_stage' then
      update public.matches as m
         set journey_stage = 'salam_exchange'
       where m.id = v_match_id;
      update public.journey_attempts as attempt
         set journey_stage = 'salam_exchange'
       where attempt.id = v_attempt_id;
    elsif v_lifecycle_case = 'paused' then
      update public.matches as m
         set suspended_by = v_seeker_a,
             suspended_at = pg_catalog.clock_timestamp()
       where m.id = v_match_id;
      update public.journey_attempts as attempt
         set paused_by = v_seeker_a,
             paused_at = pg_catalog.clock_timestamp()
       where attempt.id = v_attempt_id;
    else
      update public.matches as m
         set status = 'ended',
             ended_at = pg_catalog.clock_timestamp()
       where m.id = v_match_id;
      update public.journey_attempts as attempt
         set status = 'ended',
             ended_at = pg_catalog.clock_timestamp()
       where attempt.id = v_attempt_id;
    end if;

    foreach v_rpc in array array[
      'zyra_journey_compatibility_state',
      'zyra_reveal_journey_compatibility',
      'zyra_compatibility_for_plus'
    ] loop
      perform set_config('role', 'authenticated', true);
      perform set_config(
        'request.jwt.claims',
        pg_catalog.json_build_object('sub', v_seeker_a)::text,
        true
      );
      v_rejected := false;
      begin
        execute pg_catalog.format('select * from public.%I($1)', v_rpc)
          using v_match_id;
      exception
        when sqlstate '55000' then
          if sqlerrm is distinct from 'journey_not_available' then
            raise exception
              'OA283 lifecycle %: % returned unexpected message %',
              v_lifecycle_case,
              v_rpc,
              sqlerrm;
          end if;
          v_rejected := true;
      end;
      perform set_config('role', 'postgres', true);
      if not v_rejected then
        raise exception
          'OA283 lifecycle %: % was not refused',
          v_lifecycle_case,
          v_rpc;
      end if;
    end loop;

    update public.matches as m
       set status = 'active',
           journey_stage = 'compatibility_reveal',
           ended_at = null,
           ended_by = null,
           end_reason = null,
           end_note = null,
           suspended_by = null,
           suspended_at = null,
           also_paused_by = null,
           also_paused_at = null
     where m.id = v_match_id;
    update public.journey_attempts as attempt
       set status = 'active',
           journey_stage = 'compatibility_reveal',
           ended_at = null,
           ended_by = null,
           end_reason = null,
           end_note = null,
           paused_by = null,
           paused_at = null,
           also_paused_by = null,
           also_paused_at = null
     where attempt.id = v_attempt_id;
  end loop;

  -- Forward-compatible shared-Pause lock proof. Production did not yet have
  -- the 20260825120000 pause_state columns when OA283 was staged, so the
  -- functions read the optional composite-row key through to_jsonb(). Once
  -- that separately governed migration lands, this same harness exercises
  -- pause_requested and continue_requested independently at both authority
  -- layers. Until then the static Dart contract pins the bridge and this
  -- branch reports an honest skip rather than inventing a live result.
  select
    exists (
      select 1 from pg_attribute as attribute
       where attribute.attrelid = 'public.matches'::regclass
         and attribute.attname = 'pause_state'
         and not attribute.attisdropped
    )
    and exists (
      select 1 from pg_attribute as attribute
       where attribute.attrelid = 'public.journey_attempts'::regclass
         and attribute.attname = 'pause_state'
         and not attribute.attisdropped
    )
    into v_shared_pause_columns;

  if v_shared_pause_columns then
    foreach v_lifecycle_case in array array[
      'match_pause_requested',
      'attempt_pause_requested',
      'match_continue_requested',
      'attempt_continue_requested'
    ] loop
      if v_lifecycle_case like 'match_%' then
        execute
          'update public.matches set '
          'pause_state = $1, pause_initiated_by = $2, '
          'pause_requested_by = $2, pause_requested_at = $3, '
          'pause_deadline_at = null, pause_attempt_id = $4, '
          'pause_version = pause_version + 1 where id = $5'
          using
            case when v_lifecycle_case like '%pause_requested'
              then 'pause_requested' else 'continue_requested' end,
            v_seeker_a,
            pg_catalog.clock_timestamp(),
            v_attempt_id,
            v_match_id;
      else
        execute
          'update public.journey_attempts set '
          'pause_state = $1, pause_initiated_by = $2, '
          'pause_requested_by = $2, pause_requested_at = $3, '
          'pause_deadline_at = null, pause_version = pause_version + 1 '
          'where id = $4'
          using
            case when v_lifecycle_case like '%pause_requested'
              then 'pause_requested' else 'continue_requested' end,
            v_seeker_a,
            pg_catalog.clock_timestamp(),
            v_attempt_id;
      end if;

      foreach v_rpc in array array[
        'zyra_journey_compatibility_state',
        'zyra_reveal_journey_compatibility',
        'zyra_compatibility_for_plus'
      ] loop
        perform set_config('role', 'authenticated', true);
        perform set_config(
          'request.jwt.claims',
          pg_catalog.json_build_object('sub', v_seeker_a)::text,
          true
        );
        v_rejected := false;
        begin
          execute pg_catalog.format('select * from public.%I($1)', v_rpc)
            using v_match_id;
        exception
          when sqlstate '55000' then
            if sqlerrm is distinct from 'journey_not_available' then
              raise exception
                'OA283 shared Pause %: % returned unexpected message %',
                v_lifecycle_case,
                v_rpc,
                sqlerrm;
            end if;
            v_rejected := true;
        end;
        perform set_config('role', 'postgres', true);
        if not v_rejected then
          raise exception
            'OA283 shared Pause %: % was not refused',
            v_lifecycle_case,
            v_rpc;
        end if;
      end loop;

      if v_lifecycle_case like 'match_%' then
        execute
          'update public.matches set '
          'pause_state = ''none'', pause_initiated_by = null, '
          'pause_requested_by = null, pause_requested_at = null, '
          'pause_deadline_at = null, pause_attempt_id = null, '
          'pause_version = pause_version + 1 where id = $1'
          using v_match_id;
      else
        execute
          'update public.journey_attempts set '
          'pause_state = ''none'', pause_initiated_by = null, '
          'pause_requested_by = null, pause_requested_at = null, '
          'pause_deadline_at = null, pause_version = pause_version + 1 '
          'where id = $1'
          using v_attempt_id;
      end if;
    end loop;
  else
    raise notice
      'OA283 shared Pause cases DEFERRED — 20260825120000 is not applied';
  end if;

  -- Plus is a separate entitled early-sight path. With deterministic scoring
  -- it must populate only A's score; both flags and the joint timestamp remain
  -- untouched, and the ordinary state RPC continues to hide that score.
  update public.journey_compatibility as compatibility
     set seeker_a_revealed = false,
         seeker_b_revealed = false,
         seeker_a_score = null,
         seeker_b_score = null,
         seeker_a_categories = null,
         seeker_b_categories = null,
         revealed_at = null,
         attempt_id = v_attempt_id
   where compatibility.match_id = v_match_id;

  -- Remove either Plus entitlement class inside the rollback-only scenario,
  -- prove the denied path is side-effect free, then add one temporary
  -- entitlement for the positive case.
  delete from public.profile_unlocks as unlocks
   where unlocks.unlocker_id = v_seeker_a
     and unlocks.unlocked_id = v_seeker_b
     and unlocks.unlock_type in ('paid_plus_single', 'paid_plus_bundle');

  select to_jsonb(compatibility)
    into strict v_row_before
    from public.journey_compatibility as compatibility
   where compatibility.match_id = v_match_id;

  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    pg_catalog.json_build_object('sub', v_seeker_a)::text,
    true
  );
  v_rejected := false;
  begin
    perform public.zyra_compatibility_for_plus(v_match_id);
  exception
    when sqlstate '42501' then
      if sqlerrm is distinct from 'plus_required' then
        raise exception
          'OA283 Plus denial returned unexpected message %', sqlerrm;
      end if;
      v_rejected := true;
  end;
  perform set_config('role', 'postgres', true);
  if not v_rejected then
    raise exception 'OA283 Plus without entitlement was not denied';
  end if;

  select to_jsonb(compatibility)
    into strict v_row_after
    from public.journey_compatibility as compatibility
   where compatibility.match_id = v_match_id;
  if v_row_after is distinct from v_row_before then
    raise exception 'OA283 denied Plus call mutated compatibility state';
  end if;

  insert into public.profile_unlocks (
    unlocker_id,
    unlocked_id,
    unlock_type
  ) values (
    v_seeker_a,
    v_seeker_b,
    'paid_plus_single'
  ) on conflict do nothing;

  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    pg_catalog.json_build_object('sub', v_seeker_a)::text,
    true
  );
  select public.zyra_compatibility_for_plus(v_match_id)
    into v_plus_score;
  perform set_config('role', 'postgres', true);

  select
    compatibility.seeker_a_revealed,
    compatibility.seeker_b_revealed,
    compatibility.seeker_a_score,
    compatibility.seeker_b_score,
    compatibility.seeker_a_categories,
    compatibility.seeker_b_categories,
    compatibility.attempt_id,
    compatibility.revealed_at
    into strict
      v_a_revealed,
      v_b_revealed,
      v_a_score,
      v_b_score,
      v_a_categories,
      v_b_categories,
      v_attempt_seen,
      v_revealed_at
    from public.journey_compatibility as compatibility
   where compatibility.match_id = v_match_id;

  if v_plus_score is distinct from 100::numeric
     or v_a_revealed is distinct from false
     or v_b_revealed is distinct from false
     or v_a_score is distinct from 100::numeric
     or v_b_score is not null
     or v_a_categories is not null
     or v_b_categories is not null
     or v_attempt_seen is distinct from v_attempt_id
     or v_revealed_at is not null then
    raise exception
      'OA283 Plus: expected score-only A mutation and no consent/timestamp';
  end if;

  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    pg_catalog.json_build_object('sub', v_seeker_a)::text,
    true
  );
  select *
    into strict v_state
    from public.zyra_journey_compatibility_state(v_match_id);
  perform set_config('role', 'postgres', true);

  if v_state.mine_revealed is distinct from false
     or v_state.counterpart_revealed is distinct from false
     or v_state.my_score is not null then
    raise exception
      'OA283 Plus: ordinary state leaked the pre-mutual score';
  end if;

  -- Exercise the B-side branch independently. A's score remains caller-owned;
  -- B receives its own asymmetric score and still changes no consent or joint
  -- timestamp.
  delete from public.profile_unlocks as unlocks
   where unlocks.unlocker_id = v_seeker_b
     and unlocks.unlocked_id = v_seeker_a
     and unlocks.unlock_type in ('paid_plus_single', 'paid_plus_bundle');

  insert into public.profile_unlocks (
    unlocker_id,
    unlocked_id,
    unlock_type
  ) values (
    v_seeker_b,
    v_seeker_a,
    'paid_plus_single'
  ) on conflict do nothing;

  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    pg_catalog.json_build_object('sub', v_seeker_b)::text,
    true
  );
  select public.zyra_compatibility_for_plus(v_match_id)
    into v_plus_score;
  perform set_config('role', 'postgres', true);

  select
    compatibility.seeker_a_revealed,
    compatibility.seeker_b_revealed,
    compatibility.seeker_a_score,
    compatibility.seeker_b_score,
    compatibility.seeker_a_categories,
    compatibility.seeker_b_categories,
    compatibility.attempt_id,
    compatibility.revealed_at
    into strict
      v_a_revealed,
      v_b_revealed,
      v_a_score,
      v_b_score,
      v_a_categories,
      v_b_categories,
      v_attempt_seen,
      v_revealed_at
    from public.journey_compatibility as compatibility
   where compatibility.match_id = v_match_id;

  if v_plus_score is distinct from 50::numeric
     or v_a_revealed is distinct from false
     or v_b_revealed is distinct from false
     or v_a_score is distinct from 100::numeric
     or v_b_score is distinct from 50::numeric
     or v_a_categories is not null
     or v_b_categories is not null
     or v_attempt_seen is distinct from v_attempt_id
     or v_revealed_at is not null then
    raise exception
      'OA283 Plus B: expected caller-owned score-only B mutation';
  end if;
end;
$matrix$;

-- Undo every fixture, relationship, scoring, lifecycle, compatibility and
-- entitlement mutation before inspecting the original compatibility rows.
rollback to savepoint oa283_scenario;

do $rollback_proof$
begin
  if exists (
    (
      select to_jsonb(current_row)
        from public.journey_compatibility as current_row
      except all
      select to_jsonb(before_row)
        from pg_temp.oa283_journey_compatibility_before as before_row
    )
    union all
    (
      select to_jsonb(before_row)
        from pg_temp.oa283_journey_compatibility_before as before_row
      except all
      select to_jsonb(current_row)
        from public.journey_compatibility as current_row
    )
  ) then
    raise exception
      'OA283 rollback proof: current compatibility rows differ from snapshot';
  end if;
end;
$rollback_proof$;

-- Removes the temporary snapshot as well. The database is unchanged.
rollback;
