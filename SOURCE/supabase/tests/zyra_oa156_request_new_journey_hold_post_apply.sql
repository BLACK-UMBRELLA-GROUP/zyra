-- OA-ZYRA-156 / DR-ZYRA-227 — POST-APPLY ONLY.
--
-- Run only after migration 20260910195642 has a separate exact Founder GO
-- and is present exactly once in production history. The harness proves the
-- temporary Request New Journey hold without creating test people, requests,
-- notifications or attempts. It finishes with an outer rollback.

begin;

do $catalog$
declare
  v_expected record;
  v_oid oid;
  v_count integer;
  v_acl aclitem[];
begin
  select count(*)
    into v_count
    from supabase_migrations.schema_migrations as migration
   where migration.version = '20260910195642';
  if v_count <> 1 then
    raise exception
      'OA156 hold: migration history count %, expected 1', v_count;
  end if;

  for v_expected in
    select *
      from (values
        (
          'request_new_journey',
          'public.request_new_journey(uuid)',
          '897e43500f078122efedf07e74f42d28'
        ),
        (
          'respond_to_journey_request',
          'public.respond_to_journey_request(uuid,text)',
          'f4c650277d3228a79b95d06cc9acfd63'
        ),
        (
          'zyra_may_request_new_journey',
          'public.zyra_may_request_new_journey(uuid)',
          '29995908506ff0f9b8a7343ab21fa3fe'
        ),
        (
          'zyra_may_request_new_journey_ids',
          'public.zyra_may_request_new_journey_ids()',
          'b8d434d35e2195940bbd9fd4221b91d8'
        )
      ) as expected(function_name, signature, definition_md5)
  loop
    select count(*)
      into v_count
      from pg_catalog.pg_proc as procedure
      join pg_catalog.pg_namespace as namespace
        on namespace.oid = procedure.pronamespace
     where namespace.nspname = 'public'
       and procedure.proname = v_expected.function_name;
    if v_count <> 1 then
      raise exception
        'OA156 hold: % overload count %, expected 1',
        v_expected.function_name,
        v_count;
    end if;

    v_oid := pg_catalog.to_regprocedure(v_expected.signature);
    if v_oid is null then
      raise exception 'OA156 hold: missing %', v_expected.signature;
    end if;

    select procedure.proacl
      into strict v_acl
      from pg_catalog.pg_proc as procedure
     where procedure.oid = v_oid
       and pg_catalog.pg_get_userbyid(procedure.proowner) = 'postgres'
       and procedure.prosecdef
       and pg_catalog.md5(
         pg_catalog.pg_get_functiondef(procedure.oid)
       ) = v_expected.definition_md5;

    if pg_catalog.has_function_privilege(
         'authenticated', v_oid, 'EXECUTE'
       )
       or pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       or not pg_catalog.has_function_privilege(
         'service_role', v_oid, 'EXECUTE'
       ) then
      raise exception 'OA156 hold: wrong ACL for %', v_expected.signature;
    end if;

    if v_acl is null
       or exists (
         select 1
           from pg_catalog.aclexplode(v_acl) as acl
          where acl.privilege_type = 'EXECUTE'
            and acl.grantee not in (
              (select role.oid
                 from pg_catalog.pg_roles as role
                where role.rolname = 'postgres'),
              (select role.oid
                 from pg_catalog.pg_roles as role
                where role.rolname = 'service_role')
            )
       ) then
      raise exception
        'OA156 hold: unexpected EXECUTE grantee for %',
        v_expected.signature;
    end if;
  end loop;

  if not pg_catalog.has_function_privilege(
       'authenticated',
       'public.zyra_expire_due_journey_requests(uuid)',
       'EXECUTE'
     )
     or not pg_catalog.has_function_privilege(
       'authenticated',
       'public.restart_journey(uuid)',
       'EXECUTE'
     ) then
    raise exception
      'OA156 hold: expiry or retired restart ACL changed outside scope';
  end if;

  if (
       select relation.relrowsecurity is distinct from true
         from pg_catalog.pg_class as relation
        where relation.oid = 'public.journey_requests'::pg_catalog.regclass
     )
     or pg_catalog.has_table_privilege(
       'authenticated', 'public.journey_requests', 'INSERT'
     )
     or pg_catalog.has_table_privilege(
       'authenticated', 'public.journey_requests', 'UPDATE'
     )
     or pg_catalog.has_table_privilege(
       'authenticated', 'public.journey_requests', 'DELETE'
     )
     or pg_catalog.has_any_column_privilege(
       'authenticated', 'public.journey_requests', 'INSERT'
     )
     or pg_catalog.has_any_column_privilege(
       'authenticated', 'public.journey_requests', 'UPDATE'
     ) then
    raise exception 'OA156 hold: direct journey_requests write path exists';
  end if;
end;
$catalog$;

do $direct_calls$
declare
  v_role text;
  v_call text;
  v_rejected boolean;
begin
  foreach v_role in array array['anon', 'authenticated'] loop
    foreach v_call in array array[
      'select public.request_new_journey(''00000000-0000-0000-0000-000000000000''::uuid)',
      'select public.respond_to_journey_request(''00000000-0000-0000-0000-000000000000''::uuid, ''accept''::text)',
      'select public.zyra_may_request_new_journey(''00000000-0000-0000-0000-000000000000''::uuid)',
      'select public.zyra_may_request_new_journey_ids()'
    ] loop
      perform pg_catalog.set_config('role', v_role, true);
      v_rejected := false;
      begin
        execute v_call;
      exception
        when insufficient_privilege then v_rejected := true;
      end;
      perform pg_catalog.set_config('role', 'postgres', true);

      if not v_rejected then
        raise exception
          'OA156 hold: role % was not denied call %', v_role, v_call;
      end if;
    end loop;
  end loop;
end;
$direct_calls$;

do $state$
declare
  v_count bigint;
  v_expired integer;
begin
  select count(*) into v_count from public.journey_requests;
  if v_count <> 0 then
    raise exception 'OA156 hold: request row count %, expected 0', v_count;
  end if;

  select count(*) into v_count
    from public.notifications as notification
   where notification.type in (
     'journey_request',
     'journey_request_accepted',
     'journey_request_declined'
   );
  if v_count <> 0 then
    raise exception
      'OA156 hold: request notification count %, expected 0', v_count;
  end if;

  select count(*) into v_count
    from (
      select attempt.match_id
        from public.journey_attempts as attempt
       group by attempt.match_id
      having count(*) > 1
    ) as multi_attempt_match;
  if v_count <> 0 then
    raise exception
      'OA156 hold: multi-attempt match count %, expected 0', v_count;
  end if;

  perform pg_catalog.set_config('role', 'authenticated', true);
  select public.zyra_expire_due_journey_requests(null::uuid)
    into v_expired;
  perform pg_catalog.set_config('role', 'postgres', true);
  if v_expired <> 0 then
    raise exception
      'OA156 hold: expiry changed % rows, expected 0', v_expired;
  end if;
end;
$state$;

rollback;
