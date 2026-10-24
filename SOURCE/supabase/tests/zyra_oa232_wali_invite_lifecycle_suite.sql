-- OA-ZYRA-232 — Guardian invite lifecycle, transactional regression suite.

begin;

do $suite$
declare
  v_inviter uuid;
  v_recipient uuid;
  v_token_expiring text := 'OA232E01';
  v_token_expired text := 'OA232E02';
  v_token_decline text := 'OA232D01';
  v_token_revoke text := 'OA232R01';
  v_count bigint;
begin
  select id into v_inviter
    from public.profiles where role = 'seeker' order by created_at limit 1;
  select id into v_recipient
    from public.profiles where role = 'wali' and id <> v_inviter
    order by created_at limit 1;
  if v_inviter is null or v_recipient is null then
    raise exception 'OA232 suite needs one Seeker and one Guardian profile';
  end if;

  delete from public.wali_invites
   where token in (v_token_expiring, v_token_expired, v_token_decline, v_token_revoke);
  delete from public.notification_preferences
   where user_id in (v_inviter, v_recipient) and category = 'guardian_activity';

  insert into public.wali_invites
    (token, inviter_id, inviter_role, label, created_at, expires_at)
  values
    (v_token_expiring, v_inviter, 'seeker', 'Dad',
      clock_timestamp() - interval '5 days 1 hour',
      clock_timestamp() + interval '1 day 23 hours'),
    (v_token_expired, v_inviter, 'seeker', 'Uncle Ibrahim',
      clock_timestamp() - interval '8 days',
      clock_timestamp() - interval '1 day'),
    (v_token_decline, v_inviter, 'seeker', 'Brother',
      clock_timestamp(), clock_timestamp() + interval '7 days'),
    (v_token_revoke, v_inviter, 'seeker', 'Cousin',
      clock_timestamp(), clock_timestamp() + interval '7 days');

  perform set_config('request.jwt.claims', json_build_object('sub', v_inviter)::text, true);
  perform * from public.zyra_expire_due_wali_invites();

  if (select status from public.wali_invites where token = v_token_expired) <> 'expired' then
    raise exception 'OA232 overdue invite did not transition';
  end if;
  if (select expiring_notified_at is not null from public.wali_invites where token = v_token_expiring) is not true then
    raise exception 'OA232 day-5 marker missing';
  end if;
  select count(*) into v_count from public.notifications
   where user_id = v_inviter and type = 'wali_invite_expiring'
     and body like 'Dad%';
  if v_count <> 1 then raise exception 'OA232 expiring notification count %', v_count; end if;
  select count(*) into v_count from public.notifications
   where user_id = v_inviter and type = 'wali_invite_expired'
     and body like 'Uncle Ibrahim%';
  if v_count <> 1 then raise exception 'OA232 expired notification count %', v_count; end if;

  -- Re-running the lazy sweep is idempotent.
  perform * from public.zyra_expire_due_wali_invites();
  select count(*) into v_count from public.notifications
   where user_id = v_inviter and type in ('wali_invite_expiring', 'wali_invite_expired')
     and (body like 'Dad%' or body like 'Uncle Ibrahim%');
  if v_count <> 2 then raise exception 'OA232 sweep duplicated notifications: %', v_count; end if;

  -- Preview records the first actual viewer and emits received without
  -- exposing the sender-private label.
  perform set_config('request.jwt.claims', json_build_object('sub', v_recipient)::text, true);
  perform * from public.preview_wali_invite(v_token_decline);
  if (select seen_by from public.wali_invites where token = v_token_decline) <> v_recipient then
    raise exception 'OA232 preview did not record viewer';
  end if;
  select count(*) into v_count from public.notifications
   where user_id = v_recipient and type = 'wali_invite_received'
     and body not like '%Brother%';
  if v_count < 1 then raise exception 'OA232 received notification missing or leaked label'; end if;

  perform public.zyra_decline_wali_invite(v_token_decline);
  if (select status from public.wali_invites where token = v_token_decline) <> 'declined' then
    raise exception 'OA232 decline did not transition';
  end if;
  select count(*) into v_count from public.notifications
   where user_id = v_inviter and type = 'wali_invite_declined'
     and body like 'Brother%';
  if v_count <> 1 then raise exception 'OA232 decline notification missing'; end if;

  -- A seen invite notifies that viewer when the inviter revokes it.
  perform * from public.preview_wali_invite(v_token_revoke);
  perform set_config('request.jwt.claims', json_build_object('sub', v_inviter)::text, true);
  if not public.zyra_revoke_wali_invite(v_token_revoke) then
    raise exception 'OA232 revoke returned false';
  end if;
  select count(*) into v_count from public.notifications
   where user_id = v_recipient and type = 'wali_invite_revoked'
     and body not like '%Cousin%';
  if v_count <> 1 then raise exception 'OA232 revoke notification missing or leaked label'; end if;

  raise notice 'OA-ZYRA-232 PASS — day 5, day 7, one-shot sweep, received, decline, revoke, label privacy';
end;
$suite$;

rollback;
