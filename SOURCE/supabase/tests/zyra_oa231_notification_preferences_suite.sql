-- OA-ZYRA-231 — notification creation honours the latest preference event.
-- Run in the Supabase SQL editor. Transactional: leaves no rows behind.

begin;

do $suite$
declare
  v_user uuid;
  v_before bigint;
  v_after bigint;
  v_unknown_refused boolean := false;
begin
  select id into v_user from public.profiles order by created_at limit 1;
  if v_user is null then
    raise exception 'OA231 suite needs one profile row';
  end if;

  delete from public.notification_preferences
   where user_id = v_user and category in ('matches_journeys', 'guardian_activity');

  -- Product defaults are ON: no row still creates.
  select count(*) into v_before from public.notifications where user_id = v_user;
  perform public.create_notification(v_user, 'new_match', 'OA231 default', null, null);
  select count(*) into v_after from public.notifications where user_id = v_user;
  if v_after <> v_before + 1 then
    raise exception 'OA231 default-on failed: before %, after %', v_before, v_after;
  end if;

  -- Latest false suppresses creation.
  insert into public.notification_preferences(user_id, category, enabled)
  values (v_user, 'matches_journeys', false);
  select count(*) into v_before from public.notifications where user_id = v_user;
  perform public.create_notification(v_user, 'new_message', 'OA231 off', null, null);
  select count(*) into v_after from public.notifications where user_id = v_user;
  if v_after <> v_before then
    raise exception 'OA231 disabled category inserted: before %, after %', v_before, v_after;
  end if;

  -- A later true event wins by seq and creation resumes.
  insert into public.notification_preferences(user_id, category, enabled)
  values (v_user, 'matches_journeys', true);
  select count(*) into v_before from public.notifications where user_id = v_user;
  perform public.create_notification(v_user, 'journey_paused', 'OA231 on again', null, null);
  select count(*) into v_after from public.notifications where user_id = v_user;
  if v_after <> v_before + 1 then
    raise exception 'OA231 latest true did not win: before %, after %', v_before, v_after;
  end if;

  -- Guardian Activity is independently gated.
  insert into public.notification_preferences(user_id, category, enabled)
  values (v_user, 'guardian_activity', false);
  select count(*) into v_before from public.notifications where user_id = v_user;
  perform public.create_notification(v_user, 'wali_request', 'OA231 guardian off', null, null);
  select count(*) into v_after from public.notifications where user_id = v_user;
  if v_after <> v_before then
    raise exception 'OA231 guardian category inserted while disabled';
  end if;

  -- Unknown types fail closed at the mapper instead of bypassing consent.
  begin
    perform public.zyra_notification_category('future_type_without_mapping');
  exception when sqlstate '22023' then
    v_unknown_refused := true;
  end;
  if not v_unknown_refused then
    raise exception 'OA231 unknown type was not refused';
  end if;

  -- Security/Account are deliberately categoryless (and therefore cannot be
  -- disabled). The current notifications CHECK does not permit these proposed
  -- feed types yet, so this assertion pins the mapping without inventing one.
  if public.zyra_notification_category('new_device_signin') is not null then
    raise exception 'OA231 Security/Account unexpectedly has a toggle';
  end if;

  raise notice 'OA-ZYRA-231 PASS — default on, latest seq, suppression, independent category, unknown refusal, Security/Account bypass';
end;
$suite$;

rollback;
