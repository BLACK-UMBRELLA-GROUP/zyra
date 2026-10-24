-- OA-ZYRA-289 — post-apply transactional regression suite.
-- Self-contained: temporary Seeker/Guardian actors are created inside this
-- transaction and disappear with the final rollback.

begin;

do $suite$
declare
  v_seeker uuid := gen_random_uuid();
  v_guardian uuid := gen_random_uuid();
  v_seeker_email text;
  v_guardian_email text;
  v_code text;
  v_guardian_code text;
  v_request uuid;
  v_reciprocal_request uuid;
  v_count bigint;
  v_expiring integer;
  v_expired integer;
  v_result boolean;
  v_preview_outputs jsonb;
begin
  v_seeker_email := format(
    'oa289-seeker-%s@zyra.test', replace(v_seeker::text, '-', '')
  );
  v_guardian_email := format(
    'oa289-guardian-%s@zyra.test', replace(v_guardian::text, '-', '')
  );

  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at, confirmation_token, recovery_token,
    email_change, email_change_token_new, email_change_token_current
  )
  values
    (
      '00000000-0000-0000-0000-000000000000', v_seeker,
      'authenticated', 'authenticated', v_seeker_email,
      extensions.crypt(
        encode(extensions.gen_random_bytes(32), 'hex'),
        extensions.gen_salt('bf')
      ),
      clock_timestamp(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{}'::jsonb, clock_timestamp(), clock_timestamp(), '', '', '', '', ''
    ),
    (
      '00000000-0000-0000-0000-000000000000', v_guardian,
      'authenticated', 'authenticated', v_guardian_email,
      extensions.crypt(
        encode(extensions.gen_random_bytes(32), 'hex'),
        extensions.gen_salt('bf')
      ),
      clock_timestamp(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{}'::jsonb, clock_timestamp(), clock_timestamp(), '', '', '', '', ''
    );

  insert into public.profiles (
    id, role, first_name, date_of_birth, gender,
    location_text, bio, is_active, profile_complete
  )
  values
    (
      v_seeker, 'seeker', 'OA289 Seeker', date '1990-01-01', 'male',
      'Test', 'Transaction-scoped OA-ZYRA-289 actor.', true, false
    ),
    (
      v_guardian, 'wali', 'OA289 Guardian', date '1960-01-01', 'female',
      'Test', 'Transaction-scoped OA-ZYRA-289 actor.', true, false
    );

  perform set_config(
    'request.jwt.claims', json_build_object('sub', v_seeker)::text, true
  );

  begin
    perform public.zyra_my_personal_code('seeker');
    raise exception 'OA289 unverified caller minted a personal code';
  exception
    when others then
      if sqlerrm <> 'identity_verification_required' then
        raise;
      end if;
  end;

  insert into private.identity_verification_attempts (
    user_id, provider_code, provider_session_ref, result,
    duplicate_review_required, provider_event_ref_hash,
    consent_granted, consent_version, decided_at
  ) values
    (
      v_seeker, 'stripe', 'oa289-seeker-' || v_seeker::text, 'verified',
      false, repeat('a', 64), true, 'oa289_test_v1', clock_timestamp()
    ),
    (
      v_guardian, 'stripe', 'oa289-guardian-' || v_guardian::text, 'verified',
      false, repeat('b', 64), true, 'oa289_test_v1', clock_timestamp()
    );

  select c.code into v_code from public.zyra_my_personal_code('seeker') c;
  if v_code !~ '^ZYRA-[0-9A-F]{4}(-[0-9A-F]{4}){4}$' then
    raise exception 'OA289 code format mismatch: %', v_code;
  end if;

  perform set_config(
    'request.jwt.claims', json_build_object('sub', v_guardian)::text, true
  );
  select count(*) into v_count
  from public.zyra_preview_personal_code(v_code);
  if v_count <> 1 then raise exception 'OA289 safe preview unavailable'; end if;

  v_request := public.zyra_request_guardian_link(v_code, 'father');

  select c.code into v_guardian_code
  from public.zyra_my_personal_code('wali') c;
  perform set_config(
    'request.jwt.claims', json_build_object('sub', v_seeker)::text, true
  );
  v_reciprocal_request := public.zyra_request_guardian_link(
    v_guardian_code,
    null
  );

  if exists (
    select 1 from public.wali_links wl
    where wl.seeker_id = v_seeker and wl.wali_id = v_guardian
  ) then
    raise exception 'OA289 request created a link before owner approval';
  end if;

  perform set_config(
    'request.jwt.claims', json_build_object('sub', v_seeker)::text, true
  );
  perform public.zyra_accept_guardian_request(v_request, null);
  if not exists (
    select 1 from public.wali_links wl
    where wl.seeker_id = v_seeker and wl.wali_id = v_guardian
      and wl.status = 'active' and wl.relationship = 'father'
  ) then
    raise exception 'OA289 owner approval did not create the governed link';
  end if;

  -- The reciprocal request was valid when created, but it became stale once
  -- the first request created the active relationship. Acceptance must recheck
  -- current link state at the mutation boundary instead of updating it.
  perform set_config(
    'request.jwt.claims', json_build_object('sub', v_guardian)::text, true
  );
  begin
    perform public.zyra_accept_guardian_request(
      v_reciprocal_request,
      'father'
    );
    raise exception 'OA289 stale reciprocal request bypassed active-link recheck';
  exception
    when others then
      if sqlerrm <> 'already_linked' then
        raise;
      end if;
  end;

  update public.wali_invites
     set created_at = clock_timestamp() - interval '5 days',
         expires_at = clock_timestamp() + interval '25 days',
         request_expires_at = clock_timestamp() + interval '25 days',
         expiring_notified_at = null
   where id = v_reciprocal_request;
  select expiry.expiring_count, expiry.expired_count
    into v_expiring, v_expired
  from public.zyra_expire_due_wali_invites() expiry;
  if v_expiring <> 0 or v_expired <> 0 or exists (
    select 1 from public.wali_invites wi
    where wi.id = v_reciprocal_request
      and wi.expiring_notified_at is not null
  ) then
    raise exception 'OA289 thirty-day request received a false day-five warning';
  end if;

  update public.wali_invites
     set expires_at = clock_timestamp() - interval '1 second',
         request_expires_at = clock_timestamp() - interval '1 second'
   where id = v_reciprocal_request;
  v_result := public.zyra_decline_guardian_request(v_reciprocal_request);
  if v_result then
    raise exception 'OA289 owner declined a logically expired request';
  end if;
  perform set_config(
    'request.jwt.claims', json_build_object('sub', v_seeker)::text, true
  );
  v_result := public.zyra_cancel_guardian_request(v_reciprocal_request);
  if v_result then
    raise exception 'OA289 requester cancelled a logically expired request';
  end if;
  if not exists (
    select 1 from public.wali_invites wi
    where wi.id = v_reciprocal_request and wi.status = 'pending'
  ) then
    raise exception 'OA289 expired decline/cancel mutated request state';
  end if;

  -- A code is not a credential: self-preview is neutral and never returns a
  -- row. The server also exposes no photo or verification result column.
  select count(*) into v_count
  from public.zyra_preview_personal_code(v_code);
  if v_count <> 0 then raise exception 'OA289 self-preview did not fail closed'; end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'name', proc.proargnames[output_arg.ordinal_position],
        'type', pg_catalog.format_type(
          proc.proallargtypes[output_arg.ordinal_position],
          null
        )
      )
      order by output_arg.ordinal_position
    ),
    '[]'::jsonb
  )
  into v_preview_outputs
  from pg_catalog.pg_proc proc
  cross join lateral pg_catalog.generate_subscripts(
    proc.proallargtypes,
    1
  ) as output_arg(ordinal_position)
  where proc.oid =
    'public.zyra_preview_personal_code(text)'::pg_catalog.regprocedure
    and proc.proargmodes[output_arg.ordinal_position] in ('o', 'b', 't');

  if v_preview_outputs is distinct from
      '[{"name":"owner_first_name","type":"text"},'
      '{"name":"owner_role","type":"text"}]'::jsonb then
    raise exception 'OA289 preview output contract mismatch: %',
      v_preview_outputs;
  end if;

  raise notice 'OA-ZYRA-289 PASS — permanent code, safe preview, request-only, owner approval';
end;
$suite$;

rollback;
