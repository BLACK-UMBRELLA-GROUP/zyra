-- ZYRA line 94 V4 / Q123, Q130 and Q134. Synthetic account-deletion proof. All rows roll back.
\set ON_ERROR_STOP on
begin;

create function pg_temp.deletion_check(p_ok boolean, p_label text)
returns void language plpgsql as $$
begin
  if p_ok is distinct from true then raise exception 'Line 94 deletion FAIL: %', p_label; end if;
  raise notice 'Line 94 deletion PASS: %', p_label;
end;
$$;

create function pg_temp.deletion_denied(p_statement text, p_expected text, p_label text)
returns void language plpgsql as $$
begin
  begin
    execute p_statement;
  exception when others then
    if sqlstate <> p_expected and sqlerrm <> p_expected then raise; end if;
    raise notice 'Line 94 deletion PASS: %', p_label;
    return;
  end;
  raise exception 'Line 94 deletion FAIL: %', p_label;
end;
$$;

create temporary table deletion_ids (
  label text primary key, id uuid not null
);
insert into deletion_ids values
  ('survivor', '94dd0000-0000-0000-0000-000000000001'),
  ('departing', '94dd0000-0000-0000-0000-000000000002'),
  ('guardian', '94dd0000-0000-0000-0000-000000000003'),
  ('stranger', '94dd0000-0000-0000-0000-000000000004'),
  ('replacement', '94dd0000-0000-0000-0000-000000000005'),
  ('guardian_live', '94dd0000-0000-0000-0000-000000000006'),
  ('other_seeker', '94dd0000-0000-0000-0000-000000000007'),
  ('match', '94dd0000-0000-0000-0000-000000000011'),
  ('conversation', '94dd0000-0000-0000-0000-000000000012'),
  ('circle', '94dd0000-0000-0000-0000-000000000013'),
  ('journey_secret', '94dd0000-0000-0000-0000-000000000014'),
  ('journey_kept', '94dd0000-0000-0000-0000-000000000015'),
  ('circle_secret', '94dd0000-0000-0000-0000-000000000016'),
  ('circle_kept', '94dd0000-0000-0000-0000-000000000017'),
  ('circle_report', '94dd0000-0000-0000-0000-000000000018'),
  ('profile_report', '94dd0000-0000-0000-0000-000000000019'),
  ('verified_person', '94dd0000-0000-0000-0000-000000000020'),
  ('family', '94dd0000-0000-0000-0000-000000000021'),
  ('guardian_person', '94dd0000-0000-0000-0000-000000000022'),
  ('survivor_person', '94dd0000-0000-0000-0000-000000000023'),
  ('transfer_pending', '94dd0000-0000-0000-0000-000000000024'),
  ('transfer_declined', '94dd0000-0000-0000-0000-000000000025'),
  ('review_pending', '94dd0000-0000-0000-0000-000000000026'),
  ('review_paused', '94dd0000-0000-0000-0000-000000000027'),
  ('past_attempt', '94dd0000-0000-0000-0000-000000000028'),
  ('past_conversation', '94dd0000-0000-0000-0000-000000000029'),
  ('past_message', '94dd0000-0000-0000-0000-00000000002a'),
  ('ordinary_match', '94dd0000-0000-0000-0000-00000000002b'),
  ('ordinary_conversation', '94dd0000-0000-0000-0000-00000000002c'),
  ('ordinary_message', '94dd0000-0000-0000-0000-00000000002d'),
  ('departing_circle', '94dd0000-0000-0000-0000-00000000002e'),
  ('departing_circle_message', '94dd0000-0000-0000-0000-00000000002f'),
  ('guardian_circle_reply', '94dd0000-0000-0000-0000-000000000030'),
  ('departing_circle_report', '94dd0000-0000-0000-0000-000000000031'),
  ('accepted_request', '94dd0000-0000-0000-0000-000000000032'),
  ('declined_request', '94dd0000-0000-0000-0000-000000000033'),
  ('pending_request', '94dd0000-0000-0000-0000-000000000034'),
  ('introduction', '94dd0000-0000-0000-0000-000000000035'),
  ('journey_notification', '94dd0000-0000-0000-0000-000000000036'),
  ('plain_circle', '94dd0000-0000-0000-0000-000000000037'),
  ('plain_circle_message', '94dd0000-0000-0000-0000-000000000038'),
  ('closed_hold', '94dd0000-0000-0000-0000-000000000039');
grant select on deletion_ids to authenticated, service_role;
create function pg_temp.deletion_id(p_label text)
returns uuid language sql stable as $$
  select id from deletion_ids where label = p_label;
$$;

insert into auth.users (id, aud, role, email, created_at, updated_at)
select id, 'authenticated', 'authenticated', 'q94-' || label || '@zyra.test', now(), now()
from deletion_ids where label in ('survivor','departing','guardian','guardian_live','stranger','replacement','other_seeker');
insert into public.profiles(id, role, first_name, date_of_birth, gender, bio)
select id, case when label in ('guardian','guardian_live') then 'wali' else 'seeker' end,
  label, date '1990-01-01', case when label = 'departing' then 'female' else 'male' end,
  'synthetic fixture'
from deletion_ids where label in ('survivor','departing','guardian','guardian_live','stranger','replacement','other_seeker');
insert into public.subscriptions(user_id,plan_type,status)
values (pg_temp.deletion_id('survivor'),'seeker_premium','active'),
       (pg_temp.deletion_id('departing'),'seeker_premium','active');

insert into public.matches(id,seeker_a_id,seeker_b_id,status,journey_stage)
values (pg_temp.deletion_id('match'),pg_temp.deletion_id('survivor'),
  pg_temp.deletion_id('departing'),'active','compatibility_reveal');
insert into deletion_ids select 'attempt', id from public.journey_attempts
where match_id = pg_temp.deletion_id('match');

insert into public.journey_attempts
  (id, match_id, attempt_number, status, journey_stage, started_at, ended_at, end_reason)
values (pg_temp.deletion_id('past_attempt'), pg_temp.deletion_id('match'), 2, 'ended',
        'conversation', now() - interval '8 months', now() - interval '7 months', 'not_compatible');

insert into public.matches
  (id, seeker_a_id, seeker_b_id, status, journey_stage, ended_at, end_reason)
values (pg_temp.deletion_id('ordinary_match'), pg_temp.deletion_id('departing'),
        pg_temp.deletion_id('other_seeker'), 'ended', 'conversation',
        now() - interval '3 months', 'not_compatible');
insert into deletion_ids select 'ordinary_attempt', id from public.journey_attempts
where match_id = pg_temp.deletion_id('ordinary_match');

insert into public.conversations(id, match_id, attempt_id, status, closed_at)
values (pg_temp.deletion_id('past_conversation'), pg_temp.deletion_id('match'),
        pg_temp.deletion_id('past_attempt'), 'closed', now() - interval '7 months'),
       (pg_temp.deletion_id('ordinary_conversation'), pg_temp.deletion_id('ordinary_match'),
        pg_temp.deletion_id('ordinary_attempt'), 'closed', now() - interval '3 months')
on conflict (attempt_id) do update set id = excluded.id;

insert into public.messages(id, conversation_id, sender_id, content) values
  (pg_temp.deletion_id('past_message'), pg_temp.deletion_id('past_conversation'),
   pg_temp.deletion_id('survivor'), 'reported earlier Journey message'),
  (pg_temp.deletion_id('ordinary_message'), pg_temp.deletion_id('ordinary_conversation'),
   pg_temp.deletion_id('other_seeker'), 'unprotected ended Journey message');

insert into public.timelines(match_id, attempt_id)
values (pg_temp.deletion_id('match'), pg_temp.deletion_id('attempt')),
       (pg_temp.deletion_id('match'), pg_temp.deletion_id('past_attempt')),
       (pg_temp.deletion_id('ordinary_match'), pg_temp.deletion_id('ordinary_attempt'))
on conflict (attempt_id) do nothing;
insert into public.timeline_milestones(timeline_id, milestone_type)
select id, 'match_created' from public.timelines
where match_id in (pg_temp.deletion_id('match'), pg_temp.deletion_id('ordinary_match'));

-- Populate all three lists: accepted is Past, declined is Past, pending is
-- visible to the outgoing sender and incoming receiver until deletion.
insert into public.journey_requests
  (id, match_id, requested_by, requested_to, status, created_at, expires_at, responded_at, attempt_id)
values
  (pg_temp.deletion_id('accepted_request'), pg_temp.deletion_id('match'),
   pg_temp.deletion_id('departing'), pg_temp.deletion_id('survivor'), 'accepted',
   now() - interval '1 day', now() + interval '29 days', now(), pg_temp.deletion_id('attempt')),
  (pg_temp.deletion_id('declined_request'), pg_temp.deletion_id('match'),
   pg_temp.deletion_id('survivor'), pg_temp.deletion_id('departing'), 'declined',
   now() - interval '32 days', now() - interval '2 days', now() - interval '20 days', null),
  (pg_temp.deletion_id('pending_request'), pg_temp.deletion_id('ordinary_match'),
   pg_temp.deletion_id('other_seeker'), pg_temp.deletion_id('departing'), 'pending',
   now(), now() + interval '30 days', null, null);

insert into public.conversations(id, match_id, attempt_id, status)
values (pg_temp.deletion_id('conversation'),pg_temp.deletion_id('match'),
  pg_temp.deletion_id('attempt'),'active')
on conflict (attempt_id) do update set id = excluded.id;

insert into public.messages(id,conversation_id,sender_id,content) values
  (pg_temp.deletion_id('journey_secret'),pg_temp.deletion_id('conversation'),
    pg_temp.deletion_id('departing'),'departed Journey message'),
  (pg_temp.deletion_id('journey_kept'),pg_temp.deletion_id('conversation'),
    pg_temp.deletion_id('survivor'),'surviving Journey message');

insert into public.journey_phase_answers(match_id,attempt_id,phase,seeker_id,question_id,answer_text)
values (pg_temp.deletion_id('match'),pg_temp.deletion_id('attempt'),1,
          pg_temp.deletion_id('departing'),'q94','departed Journey answer'),
       (pg_temp.deletion_id('match'),pg_temp.deletion_id('attempt'),1,
          pg_temp.deletion_id('survivor'),'q94','surviving Journey answer');

insert into public.journey_family_reviews(id,match_id,attempt_id,from_stage,to_stage,status,deadline_at)
values (pg_temp.deletion_id('review_pending'),pg_temp.deletion_id('match'),pg_temp.deletion_id('attempt'),
          'family_stage','conversation','pending',now()+interval '48 hours'),
       (pg_temp.deletion_id('review_paused'),pg_temp.deletion_id('match'),pg_temp.deletion_id('attempt'),
          'family_stage','conversation','paused',now()+interval '48 hours');

insert into private.zyra_directional_results
  (viewer,subject,capture_version,inputs_hash,overall,area_bands,state)
values (pg_temp.deletion_id('survivor'),pg_temp.deletion_id('departing'),'v1',
  repeat('2',64),50,to_jsonb(array_fill('strong'::text,array[12])),'ok');

insert into public.protection_holds(match_id, restricted_id, protected_id, hold_type, appealable)
values (pg_temp.deletion_id('match'), pg_temp.deletion_id('departing'),
  pg_temp.deletion_id('survivor'), 'moderation', true);
insert into public.protection_holds(match_id, restricted_id, protected_id, hold_type, appealable,
  released_at, released_by, release_reason)
values (pg_temp.deletion_id('match'), pg_temp.deletion_id('survivor'),
  pg_temp.deletion_id('departing'), 'moderation', true, now(), pg_temp.deletion_id('guardian'),
  'Reviewed');
insert into public.protection_holds(id, match_id, restricted_id, protected_id, hold_type, appealable,
  released_at, released_by, release_reason)
values (pg_temp.deletion_id('closed_hold'), pg_temp.deletion_id('ordinary_match'),
  pg_temp.deletion_id('other_seeker'), pg_temp.deletion_id('departing'), 'moderation',
  true, now(), pg_temp.deletion_id('departing'), 'Reviewed');

insert into public.notifications(user_id, type, title, body)
values (pg_temp.deletion_id('survivor'), 'wali_request', 'Old Guardian notice', 'Name without an ID');
with orphaned as (
  insert into public.notifications(user_id, type, title, body)
  values (pg_temp.deletion_id('survivor'), 'wali_invite_expired', 'Guardian invitation expired', 'Old label')
  returning id
)
insert into private.zyra_guardian_notification_sources(notification_id) select id from orphaned;

insert into public.family_message_threads(id,seeker_id)
values (pg_temp.deletion_id('circle'),pg_temp.deletion_id('survivor'));
insert into public.wali_links(seeker_id,wali_id,status,is_main,relationship)
values (pg_temp.deletion_id('survivor'),pg_temp.deletion_id('guardian'),'active',true,'father');
update public.family_message_memberships
set joined_at=now()-interval '1 minute',readable_from=now()-interval '1 minute'
where thread_id=pg_temp.deletion_id('circle');
insert into public.family_messages(id,thread_id,sender_id,body) values
  (pg_temp.deletion_id('circle_secret'),pg_temp.deletion_id('circle'),
    pg_temp.deletion_id('guardian'),'departed Circle message'),
  (pg_temp.deletion_id('circle_kept'),pg_temp.deletion_id('circle'),
    pg_temp.deletion_id('survivor'),'surviving Circle message');
insert into public.family_message_reports(id,thread_id,message_id,reporter_id,reported_id,reason)
values (pg_temp.deletion_id('circle_report'),pg_temp.deletion_id('circle'),
  pg_temp.deletion_id('circle_secret'),pg_temp.deletion_id('survivor'),
  pg_temp.deletion_id('guardian'),'harassment');

insert into public.family_message_threads(id, seeker_id)
values (pg_temp.deletion_id('departing_circle'), pg_temp.deletion_id('departing')),
       (pg_temp.deletion_id('plain_circle'), pg_temp.deletion_id('other_seeker'));
insert into public.wali_links(seeker_id, wali_id, status, is_main, relationship)
values (pg_temp.deletion_id('departing'), pg_temp.deletion_id('guardian_live'), 'active', true, 'father');
update public.family_message_memberships
set joined_at = now() - interval '1 minute', readable_from = now() - interval '1 minute'
where thread_id = pg_temp.deletion_id('departing_circle');
insert into public.family_messages(id, thread_id, sender_id, body) values
  (pg_temp.deletion_id('departing_circle_message'), pg_temp.deletion_id('departing_circle'),
   pg_temp.deletion_id('departing'), 'departing Seeker Circle message'),
  (pg_temp.deletion_id('guardian_circle_reply'), pg_temp.deletion_id('departing_circle'),
   pg_temp.deletion_id('guardian_live'), 'remaining Guardian Circle reply'),
  (pg_temp.deletion_id('plain_circle_message'), pg_temp.deletion_id('plain_circle'),
   pg_temp.deletion_id('other_seeker'), 'unrelated Circle conversation');
insert into public.family_message_reports(id, thread_id, message_id, reporter_id, reported_id, reason)
values (pg_temp.deletion_id('departing_circle_report'), pg_temp.deletion_id('departing_circle'),
        pg_temp.deletion_id('departing_circle_message'), pg_temp.deletion_id('guardian_live'),
        pg_temp.deletion_id('departing'), 'harassment');

insert into public.wali_suggestions(id, wali_id, seeker_id, suggested_id)
values (pg_temp.deletion_id('introduction'), pg_temp.deletion_id('guardian'),
        pg_temp.deletion_id('survivor'), pg_temp.deletion_id('departing'));
insert into public.notifications(id, user_id, type, title, body, related_match_id, payload)
values (pg_temp.deletion_id('journey_notification'), pg_temp.deletion_id('survivor'),
        'new_message', 'departing', 'departing message preview', pg_temp.deletion_id('match'),
        jsonb_build_object('actor_id', pg_temp.deletion_id('departing')));

insert into public.wali_invites(token, inviter_id, inviter_role)
values ('TIME94CC', pg_temp.deletion_id('departing'), 'seeker');

with notices as (
  insert into public.notifications(user_id, type, title, body, payload)
  select pg_temp.deletion_id('survivor'), 'journey_request', 'Old request',
    'Departing name in legacy preview', jsonb_build_object(
      'context', jsonb_build_array(jsonb_build_object('reference', ref.id)))
  from (
    select pg_temp.deletion_id('departing') as id
    union all select pg_temp.deletion_id('match')
    union all select pg_temp.deletion_id('accepted_request')
    union all (
      select id from public.wali_invites
      where pg_temp.deletion_id('departing') in (inviter_id, seen_by, declined_by)
      order by id limit 1
    )
    union all (
      select id from public.wali_links where seeker_id = pg_temp.deletion_id('departing')
      order by id limit 1
    )
  ) ref
  returning id
)
insert into deletion_ids(label, id) select 'payload_notice_' || id::text, id from notices;

insert into public.profile_reports(id,reporter_id,reported_id,reason,source,detail)
values (pg_temp.deletion_id('profile_report'),pg_temp.deletion_id('survivor'),
  pg_temp.deletion_id('departing'),'harassment','chat','Synthetic report naming the departing account');
insert into private.verified_people(id,provider_code,provider_person_ref_hash)
values(pg_temp.deletion_id('verified_person'),'stripe',repeat('9',64)),
      (pg_temp.deletion_id('guardian_person'),'stripe',repeat('4',64)),
      (pg_temp.deletion_id('survivor_person'),'stripe',repeat('5',64));
insert into private.verified_person_accounts(verified_person_id,user_id,role)
values(pg_temp.deletion_id('verified_person'),pg_temp.deletion_id('departing'),'seeker'),
      (pg_temp.deletion_id('guardian_person'),pg_temp.deletion_id('guardian'),'guardian'),
      (pg_temp.deletion_id('survivor_person'),pg_temp.deletion_id('survivor'),'seeker');
insert into private.seeker_trial_ledger
  (verified_person_id,claimed_by,status,payment_authorisation_ref_hash,started_at,ends_at)
values(pg_temp.deletion_id('verified_person'),pg_temp.deletion_id('departing'),'active',
       repeat('7',64),now(),now()+interval '14 days');

insert into public.family_subscriptions(id,owner_id,owner_role,status,seeker_places,guardian_places)
values (pg_temp.deletion_id('family'),pg_temp.deletion_id('guardian'),'guardian','active',1,1);
insert into public.family_seat_assignments(family_subscription_id,member_id,role)
values (pg_temp.deletion_id('family'),pg_temp.deletion_id('guardian'),'guardian'),
       (pg_temp.deletion_id('family'),pg_temp.deletion_id('survivor'),'seeker');
insert into public.family_ownership_transfers
  (id,family_subscription_id,current_owner_id,replacement_owner_id,replacement_role,status)
values (pg_temp.deletion_id('transfer_pending'),pg_temp.deletion_id('family'),
          pg_temp.deletion_id('guardian'),pg_temp.deletion_id('survivor'),'seeker','pending_acceptance'),
       (pg_temp.deletion_id('transfer_declined'),pg_temp.deletion_id('family'),
          pg_temp.deletion_id('guardian'),pg_temp.deletion_id('survivor'),'seeker','declined');
set constraints family_owner_row_guard,family_owner_seat_guard immediate;
set constraints family_owner_row_guard,family_owner_seat_guard deferred;

insert into public.wali_invites(token,inviter_id,inviter_role)
values ('TIME94AA',pg_temp.deletion_id('survivor'),'seeker'),
       ('TIME94BB',pg_temp.deletion_id('survivor'),'seeker');

set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub',pg_temp.deletion_id('guardian'),'role','authenticated')::text,true);
select invite_status from public.preview_wali_invite('TIME94AA');
select public.zyra_decline_wali_invite('TIME94BB');
select pg_temp.deletion_denied('select public.delete_own_account()','family_owner_must_transfer',
  'active Family owner refused before erasure');
select pg_temp.deletion_denied('select * from private.safety_sealed_messages','42501',
  'app cannot read sealed message rows');
select pg_temp.deletion_denied('select public.zyra_purge_expired_safety_messages()','42501',
  'app cannot run sealed message purge');
reset role;

select pg_temp.deletion_check((
  select count(*) = 2 and bool_and(seen_by = pg_temp.deletion_id('guardian') and seen_at is not null)
    and bool_or(status = 'declined' and declined_by = pg_temp.deletion_id('guardian') and declined_at is not null)
  from public.wali_invites where token in ('TIME94AA', 'TIME94BB')
), 'fixture Guardian previewed one invite and declined the other');
update public.family_subscriptions set status = 'cancelled' where id=pg_temp.deletion_id('family');

select pg_temp.deletion_check(public.zyra_active_journey_count(pg_temp.deletion_id('survivor'), null) = 1,
  'the protected active Journey consumes one place before deletion');
set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub',pg_temp.deletion_id('survivor'),'role','authenticated')::text,true);
select pg_temp.deletion_check(exists (
  select 1 from public.zyra_my_attempt_participation where attempt_id = pg_temp.deletion_id('attempt')
) and exists (
  select 1 from public.zyra_my_ended_journeys() where attempt_id = pg_temp.deletion_id('past_attempt')
), 'survivor can read active and past attempts before deletion');
select pg_temp.deletion_check(exists (
  select 1 from public.journey_requests where id = pg_temp.deletion_id('accepted_request')
) and exists (
  select 1 from public.wali_suggestions where id = pg_temp.deletion_id('introduction')
), 'survivor can read the request and introduction before deletion');
select set_config('request.jwt.claims',
  json_build_object('sub',pg_temp.deletion_id('guardian_live'),'role','authenticated')::text,true);
select pg_temp.deletion_check((
  select count(*) = 2 from public.zyra_family_messages_v3(pg_temp.deletion_id('departing_circle'))
  where kind = 'message'
), 'linked Guardian can read both sides of the departing Seeker Circle before deletion');
reset role;

set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub',pg_temp.deletion_id('departing'),'role','authenticated')::text,true);
select public.delete_own_account();
-- A retry with a stale subject cannot generate another notice.
select public.delete_own_account();
select set_config('request.jwt.claims',
  json_build_object('sub',pg_temp.deletion_id('survivor'),'role','authenticated')::text,true);
select pg_temp.deletion_check(not exists (
  select 1 from public.matches where id = pg_temp.deletion_id('match')
) and not exists (
  select 1 from public.zyra_my_attempt_participation
  where attempt_id in (pg_temp.deletion_id('attempt'), pg_temp.deletion_id('past_attempt'))
) and not exists (
  select 1 from public.zyra_my_ended_journeys()
  where attempt_id in (pg_temp.deletion_id('attempt'), pg_temp.deletion_id('past_attempt'))
), 'survivor sees neither the protected active nor the protected past Journey');
select pg_temp.deletion_check(not exists (
  select 1 from public.timelines where match_id = pg_temp.deletion_id('match')
) and not exists (
  select 1 from public.timeline_milestones milestone join public.timelines timeline
    on timeline.id = milestone.timeline_id where timeline.match_id = pg_temp.deletion_id('match')
), 'survivor sees no Timeline or milestone from either removed attempt');
select pg_temp.deletion_check(not exists (
  select 1 from public.conversations where match_id = pg_temp.deletion_id('match')
) and not exists (
  select 1 from public.messages
  where conversation_id in (pg_temp.deletion_id('conversation'), pg_temp.deletion_id('past_conversation'))
), 'survivor sees neither side of the protected Journey conversation');
select pg_temp.deletion_check(not exists (
  select 1 from public.zyra_counterpart_card(pg_temp.deletion_id('match'))
) and not exists (
  select 1 from public.zyra_match_ending(pg_temp.deletion_id('match'))
) and not exists (
  select 1 from public.zyra_journey_busy_flags(array[pg_temp.deletion_id('match')])
), 'survivor cannot retrieve counterpart details, ending or busy flag by known ID');
select pg_temp.deletion_denied(format(
  'select public.zyra_mark_journey_messages_read(%L)', pg_temp.deletion_id('conversation')
), 'conversation_not_available', 'survivor cannot mark a hidden Journey conversation read');
select pg_temp.deletion_check(not exists (
  select 1 from public.journey_requests
  where id in (pg_temp.deletion_id('accepted_request'), pg_temp.deletion_id('declined_request'))
) and not exists (
  select 1 from public.wali_suggestions where id = pg_temp.deletion_id('introduction')
), 'survivor loses Past requests and the introduction involving the deleted Seeker');
select pg_temp.deletion_check((
  select count(*) = 1 and bool_and(payload = '{}'::jsonb and related_match_id is null
    and title = 'One of your Journeys has ended'
    and body = 'This profile is no longer active. Your place is free for a new Journey.')
  from public.notifications where type = 'journey_ended_profile_inactive'
), 'survivor receives one anonymous notice for two attempts with the same person');
select pg_temp.deletion_check(not exists (
  select 1 from public.notifications
  where related_match_id = pg_temp.deletion_id('match') or title = 'departing'
    or payload::text like '%' || pg_temp.deletion_id('departing')::text || '%'
), 'old previews expose neither the departed person nor their protected match ID');
select pg_temp.deletion_check((
  select count(*) = 5 and bool_and(n.payload = '{}'::jsonb
    and n.title = 'This profile is no longer active' and n.body is null)
  from public.notifications n join deletion_ids ref on ref.id = n.id
  where ref.label like 'payload_notice_%'
), 'nested previews with a deleted user, match, request, invite or link reference are scrubbed');
select pg_temp.deletion_check(not exists (
  select 1 from public.zyra_dashboard_updates(20) update_row
  where update_row.related_match_id = pg_temp.deletion_id('match')
    or update_row.source_id in (pg_temp.deletion_id('introduction'), pg_temp.deletion_id('journey_notification'))
), 'Dashboard removes old Journey activity, suggestions and matching notification previews');
select pg_temp.deletion_check(not exists (
  select detail from public.profile_reports where id = pg_temp.deletion_id('profile_report')
) and exists (
  select 1 from public.zyra_my_safety_cases() where case_id = pg_temp.deletion_id('profile_report')
), 'Journey reporter retains case status without access to protected report text');
select set_config('request.jwt.claims',
  json_build_object('sub',pg_temp.deletion_id('guardian'),'role','authenticated')::text,true);
select public.delete_own_account();
select set_config('request.jwt.claims',
  json_build_object('sub',pg_temp.deletion_id('survivor'),'role','authenticated')::text,true);
select pg_temp.deletion_check((
  select count(*) = 1 and min(body) = 'surviving Circle message'
  from public.zyra_family_messages_v3(pg_temp.deletion_id('circle')) where kind = 'message'
), 'survivor retains unrelated Circle content without the deleted Guardian message');
select pg_temp.deletion_check((
  select count(*) = 1 and bool_and(title = 'This profile is no longer active' and body is null)
  from public.notifications where type = 'wali_invite_declined'
), 'Guardian notification tracks the invite and rewrites its preview on departure');
select pg_temp.deletion_check((
  select count(*) = 1 and bool_and(title = '' and body is null)
  from public.notifications where type = 'wali_request'
), 'unidentifiable legacy Guardian notification retains type and date only');
select pg_temp.deletion_check((
  select count(*) = 1 and bool_and(title = '' and body is null)
  from public.notifications where type = 'wali_invite_expired'
), 'legacy preview is erased when its source IDs have all detached');
select pg_temp.deletion_denied('select * from private.zyra_guardian_notification_sources',
  '42501', 'Guardian notification source IDs stay private');
select pg_temp.deletion_denied('select * from private.zyra_report_sealed_messages',
  '42501', 'Journey report links to sealed messages stay private');
select pg_temp.deletion_check(exists (
  select 1 from public.zyra_my_safety_cases() where case_id=pg_temp.deletion_id('circle_report')
), 'Circle reporter can still see case status after sender deletion');
select set_config('request.jwt.claims',
  json_build_object('sub',pg_temp.deletion_id('other_seeker'),'role','authenticated')::text,true);
select pg_temp.deletion_check(not exists (
  select 1 from public.journey_requests where id = pg_temp.deletion_id('pending_request')
) and not exists (
  select 1 from public.zyra_my_ended_journeys() where attempt_id = pg_temp.deletion_id('ordinary_attempt')
), 'the other affected Seeker loses their pending request and ended Journey');
select pg_temp.deletion_check((
  select count(*) = 1 and bool_and(payload = '{}'::jsonb and related_match_id is null)
  from public.notifications where type = 'journey_ended_profile_inactive'
), 'the second affected Seeker receives their own single anonymous notice');
select set_config('request.jwt.claims',
  json_build_object('sub',pg_temp.deletion_id('stranger'),'role','authenticated')::text,true);
select pg_temp.deletion_check(not exists (
  select 1 from public.notifications where type = 'journey_ended_profile_inactive'
), 'an unrelated account receives no Journey deletion notice');
select pg_temp.deletion_denied(format(
  'select * from public.zyra_advance_stage(%L,%L)',
  pg_temp.deletion_id('match'),'compatibility_reveal'
),'match_not_found','removed Journey stage is indistinguishable from a missing match');
select set_config('request.jwt.claims',
  json_build_object('sub',pg_temp.deletion_id('guardian_live'),'role','authenticated')::text,true);
select pg_temp.deletion_check(not exists (
  select 1 from public.family_message_threads where id = pg_temp.deletion_id('departing_circle')
) and not exists (
  select 1 from public.zyra_family_message_circles() where thread_id = pg_temp.deletion_id('departing_circle')
) and not exists (
  select 1 from public.zyra_family_message_participants(pg_temp.deletion_id('departing_circle'))
), 'former Circle Guardian sees no thread, list row or participants');
select pg_temp.deletion_check(not exists (
  select 1 from public.family_messages where thread_id = pg_temp.deletion_id('departing_circle')
) and not exists (
  select 1 from public.zyra_family_messages(pg_temp.deletion_id('departing_circle'))
) and not exists (
  select 1 from public.zyra_family_messages_v2(pg_temp.deletion_id('departing_circle'))
) and not exists (
  select 1 from public.zyra_family_messages_v3(pg_temp.deletion_id('departing_circle'))
), 'former Circle Guardian sees no Circle messages in any app read');
select pg_temp.deletion_check(exists (
  select 1 from public.zyra_my_safety_cases() where case_id = pg_temp.deletion_id('departing_circle_report')
), 'remaining Guardian retains Circle safety case status after the Circle disappears');
reset role;
set constraints family_owner_row_guard,family_owner_seat_guard immediate;

insert into public.wali_links(seeker_id,wali_id,status,is_main,relationship)
values (pg_temp.deletion_id('survivor'),pg_temp.deletion_id('guardian_live'),'active',true,'father');
set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub',pg_temp.deletion_id('guardian_live'),'role','authenticated')::text,true);
select pg_temp.deletion_check(not exists (
  select 1 from public.zyra_attempt_summary_for_guardian(pg_temp.deletion_id('survivor'))
  where attempt_id in (pg_temp.deletion_id('attempt'), pg_temp.deletion_id('past_attempt'))
) and not exists (
  select 1 from public.zyra_my_attempt_participation where match_id = pg_temp.deletion_id('match')
), 'linked Guardian cannot recover removed Journey detail or Past summaries');
select pg_temp.deletion_denied(format(
  'select public.wali_review_decision(%L,%L)', pg_temp.deletion_id('review_pending'), 'continue'
), 'review not found', 'a known protected review is indistinguishable from an absent review');
select pg_temp.deletion_denied(format(
  'select public.reopen_family_review(%L)', pg_temp.deletion_id('review_paused')
), 'review not found', 'a known protected review cannot be reopened or distinguished from absence');
reset role;

select pg_temp.deletion_check(public.zyra_active_journey_count(pg_temp.deletion_id('survivor'), null) = 0,
  'protected active Journey immediately releases the survivor place');
select pg_temp.deletion_check(not exists (
  select 1 from public.matches where id = pg_temp.deletion_id('ordinary_match')
) and not exists (
  select 1 from public.journey_attempts where id = pg_temp.deletion_id('ordinary_attempt')
) and not exists (
  select 1 from public.messages where id = pg_temp.deletion_id('ordinary_message')
), 'ordinary ended Journey rows and ordinary transcript are physically removed');
select pg_temp.deletion_check((
  select match_id is null and protected_id is null and released_at = now()
    and release_reason = 'Reviewed' and released_by is null and released_by_departed
  from public.protection_holds where id = pg_temp.deletion_id('closed_hold')
), 'already closed hold retains its release audit when the ordinary Journey is removed');
select pg_temp.deletion_check((
  select count(*) = 2 from private.report_protected_attempts
  where report_id = pg_temp.deletion_id('profile_report')
    and attempt_id in (pg_temp.deletion_id('attempt'), pg_temp.deletion_id('past_attempt'))
), 'both restarted attempts retain the legacy report link after identity detaches');
select pg_temp.deletion_check((
  select count(*) = 2 and bool_and(status = 'ended') from public.journey_attempts
  where match_id = pg_temp.deletion_id('match')
), 'both protected attempts are retained in safety custody and consume no place');
select pg_temp.deletion_check(exists (
  select 1 from private.zyra_deleted_attempt_evidence
  where attempt_id = pg_temp.deletion_id('attempt')
    and records->'phase_answers' @> '[{"answer_text":"departed Journey answer"}]'::jsonb
), 'the protected attempt keeps the departed answer in private safety custody');
select pg_temp.deletion_check((
  select count(*) = 1 and bool_and(seeker_a_id is null and seeker_b_id is null)
  from public.matches where id = pg_temp.deletion_id('match')
), 'retained safety match carries neither member identity in the participant fields');
select pg_temp.deletion_check(exists (
  select 1 from public.family_messages where id = pg_temp.deletion_id('plain_circle_message')
), 'ordinary unrelated Circle is untouched');
select pg_temp.deletion_check(not exists (
  select 1 from private.zyra_directional_results where subject=pg_temp.deletion_id('departing')
), 'saved Compatibility involving departed person is removed');
select pg_temp.deletion_check(not exists (
  select 1 from public.profiles where id in (pg_temp.deletion_id('departing'),pg_temp.deletion_id('guardian'))
), 'departed profiles are erased');
select pg_temp.deletion_check(not exists (
  select 1 from public.wali_links where wali_id=pg_temp.deletion_id('guardian')
), 'departed Guardian link is removed');
select pg_temp.deletion_check((
  select status = 'pending' and seen_by is null and seen_at is null
  from public.wali_invites where token = 'TIME94AA'
), 'previewed invitation remains pending without the departed preview marker');
select pg_temp.deletion_check((
  select status = 'declined' and seen_by is null and seen_at is null
    and declined_by is null and declined_at is null
  from public.wali_invites where token = 'TIME94BB'
), 'declined invitation stays declined without the departed actor markers');
select pg_temp.deletion_check((
  select reported_id is null and reporter_id=pg_temp.deletion_id('survivor')
  from public.profile_reports where id=pg_temp.deletion_id('profile_report')
), 'profile report survives with null departed identity');
select pg_temp.deletion_check(exists (
  select 1 from public.protection_holds where match_id = pg_temp.deletion_id('match')
    and restricted_id is null and protected_id = pg_temp.deletion_id('survivor')
    and released_at is null and not released_by_departed
), 'active hold survives with the departing party detached');
select pg_temp.deletion_check(exists (
  select 1 from public.protection_holds where match_id = pg_temp.deletion_id('match')
    and protected_id is null and restricted_id = pg_temp.deletion_id('survivor')
    and released_at = now() and release_reason = 'Reviewed'
    and released_by is null and released_by_departed
), 'closed hold retains date and reason with an anonymous departed releaser');
select pg_temp.deletion_check((
  select message_id is null and reported_id is null and sealed_message_id is not null
  from public.family_message_reports where id=pg_temp.deletion_id('circle_report')
), 'Circle report retains exact sealed copy reference');
select pg_temp.deletion_check((
  select owner_id is null and status='cancelled'
  from public.family_subscriptions where id=pg_temp.deletion_id('family')
), 'cancelled Family plan history no longer refers to the deleted owner');
select pg_temp.deletion_check((
  select current_owner_id is null and status='cancelled'
  from public.family_ownership_transfers where id=pg_temp.deletion_id('transfer_pending')
), 'pending Family transfer is cancelled and detached');
select pg_temp.deletion_check((
  select current_owner_id is null and status='declined'
  from public.family_ownership_transfers where id=pg_temp.deletion_id('transfer_declined')
), 'finished Family transfer keeps its status and loses the departed owner ID');
select pg_temp.deletion_check(not exists (
  select 1 from public.family_seat_assignments where member_id=pg_temp.deletion_id('guardian')
), 'deleted Family owner no longer holds a seat');
select pg_temp.deletion_check((
  select claimed_by is null and payment_authorisation_ref_hash is null
    and started_at is null and ends_at is null and updated_at is null
  from private.seeker_trial_ledger where verified_person_id=pg_temp.deletion_id('verified_person')
), 'Seeker trial keeps only the consumed verified-person claim');

insert into private.verified_person_accounts(verified_person_id,user_id,role)
values (pg_temp.deletion_id('verified_person'),pg_temp.deletion_id('replacement'),'seeker');

set local role service_role;
select set_config('request.jwt.claims','{"role":"service_role"}',true);
select pg_temp.deletion_denied(format(
  'select public.zyra_start_verified_seeker_trial(%L,%L,repeat(''8'',64))',
  pg_temp.deletion_id('replacement'),pg_temp.deletion_id('verified_person')
),'seeker_trial_already_used','rejoined verified person cannot start another Seeker trial');
with expected(message, source, sender, body) as (
  values
    ('journey_secret', 'journey', 'departing', 'departed Journey message'),
    ('journey_kept', 'journey', 'survivor', 'surviving Journey message'),
    ('past_message', 'journey', 'survivor', 'reported earlier Journey message'),
    ('ordinary_message', 'journey', 'other_seeker', 'unprotected ended Journey message'),
    ('departing_circle_message', 'guardian_circle', 'departing', 'departing Seeker Circle message'),
    ('guardian_circle_reply', 'guardian_circle', 'guardian_live', 'remaining Guardian Circle reply'),
    ('circle_secret', 'guardian_circle', 'guardian', 'departed Circle message')
)
select pg_temp.deletion_check((
  select count(*) = 7 and bool_and(seal.purge_at - seal.sealed_at = interval '8760 hours'
    and seal.sender_id = pg_temp.deletion_id(e.sender) and seal.body = e.body)
  from private.safety_sealed_messages seal join expected e
    on seal.source_message_id = pg_temp.deletion_id(e.message) and seal.source = e.source
), 'service sees both sides of Journey and deleted Circle conversations with the 365-day deadline');
select pg_temp.deletion_check(not exists (
  select 1 from private.safety_sealed_messages where source_message_id in
    (pg_temp.deletion_id('circle_kept'), pg_temp.deletion_id('plain_circle_message'))
), 'unrelated Circle messages do not enter safety custody');
select pg_temp.deletion_check((
  select count(*) = 3 from private.zyra_report_sealed_messages evidence
  join private.safety_sealed_messages sealed on sealed.id = evidence.sealed_message_id
  where evidence.report_id = pg_temp.deletion_id('profile_report')
    and sealed.source_message_id in (
      pg_temp.deletion_id('journey_secret'), pg_temp.deletion_id('journey_kept'), pg_temp.deletion_id('past_message')
    )
), 'Journey report can locate sealed messages from both sides and both protected attempts');
select pg_temp.deletion_check(public.zyra_purge_expired_safety_messages() = 0,
  'sealed copies are retained before 365 days');
reset role;

select pg_temp.deletion_check((
  select reporter_id = pg_temp.deletion_id('guardian_live') and reported_id is null
    and message_id is null and sealed_message_id is not null
  from public.family_message_reports where id = pg_temp.deletion_id('departing_circle_report')
), 'departing Circle report survives with detached identities and an exact sealed message');
update private.safety_sealed_messages
set sealed_at = now() - interval '8760 hours', purge_at = now()
where source_message_id in (
  pg_temp.deletion_id('ordinary_message'),
  pg_temp.deletion_id('departing_circle_message'),
  pg_temp.deletion_id('guardian_circle_reply')
);
set local role service_role;
select pg_temp.deletion_check(public.zyra_purge_expired_safety_messages() = 1,
  'unprotected sealed copy is purged at 365 days');
select pg_temp.deletion_check(not exists (
  select 1 from private.safety_sealed_messages where source_message_id = pg_temp.deletion_id('ordinary_message')
) and (
  select count(*) = 2 from private.safety_sealed_messages
  where source_message_id in (pg_temp.deletion_id('departing_circle_message'), pg_temp.deletion_id('guardian_circle_reply'))
), 'the expired Circle copy stays intact while its report is open');
select public.zyra_close_family_message_report(pg_temp.deletion_id('departing_circle_report'));
select pg_temp.deletion_check(public.zyra_purge_expired_safety_messages() = 2,
  'closing the Circle report lets both expired sides of its sealed copy purge');
reset role;
select pg_temp.deletion_check((
  select sealed_message_id is null and status = 'actioned'
  from public.family_message_reports where id = pg_temp.deletion_id('departing_circle_report')
), 'expired Circle evidence detaches without erasing the safety case');

update public.profile_reports set status = 'dismissed', reviewed_at = now()
where id = pg_temp.deletion_id('profile_report');
select private.zyra_purge_closed_ended_journeys();
select pg_temp.deletion_check((
  select count(*) = 2 from public.journey_attempts where match_id = pg_temp.deletion_id('match')
), 'an active hold alone keeps both protected attempts after the report closes');
update public.profile_reports set status = 'reviewing', reviewed_at = null
where id = pg_temp.deletion_id('profile_report');
update public.protection_holds
set released_at = now(), released_by = pg_temp.deletion_id('guardian_live'), release_reason = 'Reviewed'
where match_id = pg_temp.deletion_id('match') and released_at is null;
select private.zyra_purge_closed_ended_journeys();
select pg_temp.deletion_check((
  select count(*) = 2 from public.journey_attempts where match_id = pg_temp.deletion_id('match')
), 'an open report alone keeps both protected attempts after the hold closes');
update public.profile_reports set status = 'dismissed', reviewed_at = now()
where id = pg_temp.deletion_id('profile_report');
select private.zyra_purge_closed_ended_journeys();
select pg_temp.deletion_check(not exists (
  select 1 from public.matches where id = pg_temp.deletion_id('match')
) and not exists (
  select 1 from private.zyra_deleted_attempt_evidence
  where attempt_id in (pg_temp.deletion_id('attempt'), pg_temp.deletion_id('past_attempt'))
) and exists (
  select 1 from public.profile_reports where id = pg_temp.deletion_id('profile_report')
) and exists (
  select 1 from public.protection_holds
  where match_id is null and released_by = pg_temp.deletion_id('guardian_live') and release_reason = 'Reviewed'
), 'cleanup purges Journey evidence after protection ends and retains the separate safety audits');

rollback;
