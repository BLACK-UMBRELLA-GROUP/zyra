-- OA-ZYRA-156 / DR-ZYRA-227 — temporary Founder-only TestFlight hold.
--
-- Request New Journey's permanent mutual-consent design is preserved, but
-- its ritual rows are not yet attempt-owned. Until OA-ZYRA-156 completes,
-- an accepted second Journey can collide with the first Journey's Salams,
-- compatibility and checkpoint rows. The Founder therefore ruled that the
-- feature must be unavailable at BOTH client and server layers for the
-- bounded internal TestFlight.
--
-- This migration changes grants only. It does not rewrite function bodies,
-- delete requests, alter history or create an application feature flag.
-- postgres/service_role retain the trusted administration plane; every
-- public app role loses all four request/read entry points. A later forward
-- migration may restore authenticated EXECUTE only after the per-attempt
-- conversion is completed, tested and separately approved.

do $preflight$
declare
  v_expected record;
  v_oid oid;
  v_overloads integer;
  v_request_rows bigint;
  v_second_attempts bigint;
  v_request_notifications bigint;
begin
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
      into v_overloads
      from pg_catalog.pg_proc as procedure
      join pg_catalog.pg_namespace as namespace
        on namespace.oid = procedure.pronamespace
     where namespace.nspname = 'public'
       and procedure.proname = v_expected.function_name;

    if v_overloads <> 1 then
      raise sqlstate '55000' using
        message = format(
          'oa156_request_new_journey_hold_function_overload_drift:%s:%s',
          v_expected.function_name,
          v_overloads
        );
    end if;

    v_oid := pg_catalog.to_regprocedure(v_expected.signature);
    if v_oid is null then
      raise sqlstate '55000' using
        message = format(
          'oa156_request_new_journey_hold_signature_missing:%s',
          v_expected.signature
        );
    end if;

    if (
      select pg_catalog.pg_get_userbyid(procedure.proowner) <> 'postgres'
          or procedure.prosecdef is distinct from true
          or pg_catalog.md5(pg_catalog.pg_get_functiondef(procedure.oid)) <>
             v_expected.definition_md5
        from pg_catalog.pg_proc as procedure
       where procedure.oid = v_oid
    ) then
      raise sqlstate '55000' using
        message = format(
          'oa156_request_new_journey_hold_definition_drift:%s',
          v_expected.signature
        );
    end if;

    if not pg_catalog.has_function_privilege(
         'authenticated', v_oid, 'EXECUTE'
       )
       or pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       or not pg_catalog.has_function_privilege(
         'service_role', v_oid, 'EXECUTE'
       ) then
      raise sqlstate '55000' using
        message = format(
          'oa156_request_new_journey_hold_acl_prestate_drift:%s',
          v_expected.signature
        );
    end if;
  end loop;

  select count(*) into v_request_rows
    from public.journey_requests;
  if v_request_rows <> 0 then
    raise sqlstate '55000' using
      message = format(
        'oa156_request_new_journey_hold_request_rows_drift:%s',
        v_request_rows
      );
  end if;

  select count(*) into v_second_attempts
    from (
      select attempt.match_id
        from public.journey_attempts as attempt
       group by attempt.match_id
      having count(*) > 1
    ) as multi_attempt_match;
  if v_second_attempts <> 0 then
    raise sqlstate '55000' using
      message = format(
        'oa156_request_new_journey_hold_second_attempt_drift:%s',
        v_second_attempts
      );
  end if;

  select count(*) into v_request_notifications
    from public.notifications as notification
   where notification.type in (
     'journey_request',
     'journey_request_accepted',
     'journey_request_declined'
   );
  if v_request_notifications <> 0 then
    raise sqlstate '55000' using
      message = format(
        'oa156_request_new_journey_hold_notification_drift:%s',
        v_request_notifications
      );
  end if;

  if not (
       select relation.relrowsecurity
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
    raise sqlstate '55000' using
      message = 'oa156_request_new_journey_hold_direct_table_write_drift';
  end if;
end;
$preflight$;

revoke execute on function public.request_new_journey(uuid)
  from public, anon, authenticated;
revoke execute on function public.respond_to_journey_request(uuid, text)
  from public, anon, authenticated;
revoke execute on function public.zyra_may_request_new_journey(uuid)
  from public, anon, authenticated;
revoke execute on function public.zyra_may_request_new_journey_ids()
  from public, anon, authenticated;

do $postflight$
declare
  v_expected record;
  v_oid oid;
begin
  for v_expected in
    select *
      from (values
        ('public.request_new_journey(uuid)'),
        ('public.respond_to_journey_request(uuid,text)'),
        ('public.zyra_may_request_new_journey(uuid)'),
        ('public.zyra_may_request_new_journey_ids()')
      ) as expected(signature)
  loop
    v_oid := pg_catalog.to_regprocedure(v_expected.signature);

    if pg_catalog.has_function_privilege(
         'authenticated', v_oid, 'EXECUTE'
       )
       or pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       or not pg_catalog.has_function_privilege(
         'service_role', v_oid, 'EXECUTE'
       )
       or exists (
         select 1
           from pg_catalog.aclexplode(
             coalesce(
               (select procedure.proacl
                  from pg_catalog.pg_proc as procedure
                 where procedure.oid = v_oid),
               pg_catalog.acldefault(
                 'f',
                 (select procedure.proowner
                    from pg_catalog.pg_proc as procedure
                   where procedure.oid = v_oid)
               )
             )
           ) as acl
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
      raise sqlstate '55000' using
        message = format(
          'oa156_request_new_journey_hold_postflight_failed:%s',
          v_expected.signature
        );
    end if;
  end loop;
end;
$postflight$;
