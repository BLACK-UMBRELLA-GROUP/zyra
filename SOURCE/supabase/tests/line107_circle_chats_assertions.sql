-- ZYRA line 107, DOC-ZYRA-0510 / Q138 and Q141. Synthetic actors in a disposable replay.
\set ON_ERROR_STOP on
begin;
\ir fixtures/server0_v2_full_schema_prestate.sql

grant select on server0_v2_fixture_actors to authenticated;
create temp table circle_chat_fixture (label text primary key, id uuid not null);
grant select, insert on circle_chat_fixture to authenticated;
grant select on circle_chat_fixture to service_role;
create temp table circle_alert_fixture (id uuid primary key, created_at timestamptz not null);
grant select, insert on circle_alert_fixture to authenticated;
create function pg_temp.chat_actor(p_label text) returns uuid language sql stable as $$
  select id from server0_v2_fixture_actors where fixture_label = p_label;
$$;
create function pg_temp.chat_id(p_label text) returns uuid language sql stable as $$
  select id from circle_chat_fixture where label = p_label;
$$;
create function pg_temp.chat_as(p_label text) returns text language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', pg_temp.chat_actor(p_label), 'role', 'authenticated')::text, true);
$$;
create function pg_temp.chat_assert(p_ok boolean, p_label text)
returns void language plpgsql as $$
begin
  if p_ok is distinct from true then
    raise exception 'line 107 chats FAIL: %', p_label;
  end if;
  raise notice 'line 107 chats PASS: %', p_label;
end;
$$;
create function pg_temp.chat_reject(p_sql text, p_reason text, p_label text)
returns void language plpgsql as $$
begin
  begin
    execute p_sql;
  exception when others then
    if sqlstate <> p_reason and sqlerrm <> p_reason then raise; end if;
    perform pg_temp.chat_assert(true, p_label);
    return;
  end;
  raise exception 'line 107 chats FAIL: %', p_label;
end;
$$;
grant execute on function pg_temp.chat_actor(text), pg_temp.chat_id(text),
  pg_temp.chat_as(text), pg_temp.chat_assert(boolean,text),
  pg_temp.chat_reject(text,text,text) to authenticated;
grant execute on function pg_temp.chat_reject(text,text,text) to anon;

-- Distinct Guardians belong to each side. One additional Guardian lacks an
-- assignment, and a counterpart Guardian has no authority over this Circle.
insert into public.wali_links(seeker_id, wali_id, status, is_main, relationship) values
  (pg_temp.chat_actor('male1'), pg_temp.chat_actor('gadd'), 'active', false, 'brother'),
  (pg_temp.chat_actor('fem1'), pg_temp.chat_actor('gb'), 'active', true, 'father');
update public.subscriptions set plan_type = 'seeker_premium'
where user_id in (pg_temp.chat_actor('male1'), pg_temp.chat_actor('fem1'));
update public.subscriptions set plan_type = 'wali_premium'
where user_id in (pg_temp.chat_actor('gmain'), pg_temp.chat_actor('gadd'), pg_temp.chat_actor('gb'));

set local role authenticated;
select pg_temp.chat_as('male1');
insert into circle_chat_fixture
select 'owner_thread', thread_id from public.zyra_open_family_message_circle(pg_temp.chat_actor('male1'));
insert into circle_chat_fixture
select 'owner_main', chat_id from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
where kind = 'main';
select pg_temp.chat_assert(
  (select count(*) = 1 and bool_and(kind = 'main' and state = 'current' and unread_count = 0)
   from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))),
  'a new Circle initially lists only its Main');
reset role;

insert into circle_chat_fixture values ('match', '10700000-0000-0000-0000-000000000001');
insert into public.matches(id, seeker_a_id, seeker_b_id, status, journey_stage)
values (pg_temp.chat_id('match'),
  least(pg_temp.chat_actor('male1'), pg_temp.chat_actor('fem1')),
  greatest(pg_temp.chat_actor('male1'), pg_temp.chat_actor('fem1')),
  'active', 'compatibility_reveal');
insert into circle_chat_fixture
select 'first_attempt', id from public.journey_attempts
where match_id = pg_temp.chat_id('match') and status = 'active';
insert into circle_chat_fixture
select 'first_chat', id from public.family_message_chats
where thread_id = pg_temp.chat_id('owner_thread') and attempt_id = pg_temp.chat_id('first_attempt');
select pg_temp.chat_assert(pg_temp.chat_id('first_chat') is not null,
  'starting an attempt creates a Journey chat in an already-open Circle');

set local role authenticated;
select pg_temp.chat_as('fem1');
insert into circle_chat_fixture
select 'other_thread', thread_id from public.zyra_open_family_message_circle(pg_temp.chat_actor('fem1'));
insert into circle_chat_fixture
select 'other_main', chat_id from public.zyra_family_message_chats(pg_temp.chat_id('other_thread'))
where kind = 'main';
select pg_temp.chat_assert(
  (select count(*) = 2
   and count(*) filter (where kind = 'journey' and state = 'current'
                         and chat_id <> pg_temp.chat_id('first_chat')) = 1
   from public.zyra_family_message_chats(pg_temp.chat_id('other_thread'))),
  'opening the counterpart Circle later creates its own chat for the existing attempt');
reset role;

-- One rollback transaction models messages and membership from earlier API
-- transactions. User RPCs still run under actual JWT roles below.
update public.family_message_memberships
set joined_at = now() - interval '1 day', readable_from = now() - interval '1 day'
where thread_id in (pg_temp.chat_id('owner_thread'), pg_temp.chat_id('other_thread'));

insert into circle_chat_fixture values
  ('main_message', '10700000-0000-0000-0000-000000000002'),
  ('journey_message', '10700000-0000-0000-0000-000000000003'),
  ('journey_own', '10700000-0000-0000-0000-000000000004'),
  ('journey_lifecycle', '10700000-0000-0000-0000-000000000005');
insert into public.notifications(user_id, type, title, body)
values (pg_temp.chat_actor('gadd'), 'wali_request', 'Line 107 synthetic legacy notice', 'Synthetic notice');
-- Privileged fixture rows model history with distinct timestamps.
insert into public.family_messages(id, thread_id, chat_id, sender_id, kind, body, created_at) values
  (pg_temp.chat_id('main_message'), pg_temp.chat_id('owner_thread'), pg_temp.chat_id('owner_main'),
   pg_temp.chat_actor('male1'), 'message', 'Line 107 synthetic Main', now() - interval '5 minutes'),
  (pg_temp.chat_id('journey_message'), pg_temp.chat_id('owner_thread'), pg_temp.chat_id('first_chat'),
   pg_temp.chat_actor('male1'), 'message', 'Line 107 synthetic Journey', now() - interval '4 minutes'),
  (pg_temp.chat_id('journey_own'), pg_temp.chat_id('owner_thread'), pg_temp.chat_id('first_chat'),
   pg_temp.chat_actor('gmain'), 'message', 'Line 107 synthetic reply', now() - interval '3 minutes'),
  (pg_temp.chat_id('journey_lifecycle'), pg_temp.chat_id('owner_thread'), pg_temp.chat_id('first_chat'),
   null, 'lifecycle', 'Line 107 synthetic lifecycle', now() - interval '2 minutes');
update public.family_message_threads set last_message_at = now() - interval '5 minutes'
where id = pg_temp.chat_id('owner_thread');
update public.family_message_participant_state set last_read_at = now() - interval '10 minutes'
where thread_id = pg_temp.chat_id('owner_thread');

set local role authenticated;
select pg_temp.chat_as('gmain');
select pg_temp.chat_assert(
  (select unread_count = 1 and not muted and not circle_muted and counts_toward_total and alerts_on
   from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
   where chat_id = pg_temp.chat_id('first_chat') and state = 'current'),
  'current Main Guardian gets one unread, excluding own and lifecycle rows');
select pg_temp.chat_assert(
  (select count(*) = 3 from public.family_messages where chat_id = pg_temp.chat_id('first_chat')),
  'Main Guardian can read exact Journey rows');
select pg_temp.chat_assert(
  (select unread_count = 1 and last_message = 'Line 107 synthetic Main'
          and last_message_at = now() - interval '5 minutes'
   from public.zyra_family_message_circles() where thread_id = pg_temp.chat_id('owner_thread')),
  'legacy circle latest, timestamp and unread are isolated to Main');
select pg_temp.chat_assert(
  (select array_agg(message_id) = array[pg_temp.chat_id('main_message')]
   from public.zyra_family_messages(pg_temp.chat_id('owner_thread')))
  and (select array_agg(message_id) = array[pg_temp.chat_id('main_message')]
   from public.zyra_family_messages_v2(pg_temp.chat_id('owner_thread')))
  and (select array_agg(message_id) = array[pg_temp.chat_id('main_message')]
   from public.zyra_family_messages_v3(pg_temp.chat_id('owner_thread'))),
  'all three legacy readers remain Main-only even for authorized Journey viewers');
insert into circle_chat_fixture values ('journey_report', public.zyra_report_family_message(
  pg_temp.chat_id('owner_thread'), pg_temp.chat_id('journey_message'), 'harassment'));
select public.zyra_set_family_chat_muted(pg_temp.chat_id('first_chat'), true);
select pg_temp.chat_assert(
  (select unread_count = 1 and muted and not circle_muted and not counts_toward_total and not alerts_on
   from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
   where chat_id = pg_temp.chat_id('first_chat')),
  'chat mute retains the unread bubble and disables attention for that member');
select public.zyra_set_family_message_muted(pg_temp.chat_id('owner_thread'), true);
select pg_temp.chat_assert(
  (select unread_count = 1 and not muted and circle_muted and counts_toward_total and not alerts_on
   from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
   where chat_id = pg_temp.chat_id('owner_main'))
  and (select muted and unread_count = 1 from public.zyra_family_message_circles()
       where thread_id = pg_temp.chat_id('owner_thread')),
  'whole-Circle mute keeps Main and legacy Circle counts and suppresses alerts');
select public.zyra_mark_family_chat_read(pg_temp.chat_id('first_chat'));
select pg_temp.chat_assert(
  (select unread_count = 0 from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
   where chat_id = pg_temp.chat_id('first_chat'))
  and (select unread_count = 1 from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
       where chat_id = pg_temp.chat_id('owner_main')),
  'marking Journey read leaves Main unread');
select public.zyra_set_family_message_muted(pg_temp.chat_id('owner_thread'), false);
select pg_temp.chat_assert(
  (select muted and not circle_muted from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
   where chat_id = pg_temp.chat_id('first_chat')),
  'unmuting the Circle leaves the individual chat mute intact');

select pg_temp.chat_as('male1');
select pg_temp.chat_assert(
  (select unread_count = 1 and not muted and not circle_muted and counts_toward_total
   from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
   where chat_id = pg_temp.chat_id('first_chat')),
  'another member does not inherit the Guardian read or mute state');
insert into circle_chat_fixture values ('main_rpc_send',
  public.zyra_send_family_message(pg_temp.chat_id('owner_thread'), 'Line 107 synthetic Main send', null));
select pg_temp.chat_assert(
  (select unread_count = 1 from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
   where chat_id = pg_temp.chat_id('first_chat')),
  'sending to Main does not advance the Journey watermark');
select pg_temp.chat_reject(
  'select public.zyra_send_family_message(pg_temp.chat_id(''owner_thread''), ''Wrong Circle'', pg_temp.chat_id(''other_main''))',
  'family_chat_not_found', 'send cannot target a different Circle chat');
reset role;

select pg_temp.chat_assert(
  (select chat_id = pg_temp.chat_id('owner_main') from public.family_messages
   where id = pg_temp.chat_id('main_rpc_send')),
  'explicit null send routes to the stable Main chat');
select pg_temp.chat_assert(
  (select last_read_at = now() - interval '10 minutes'
   from public.family_message_participant_state
   where thread_id = pg_temp.chat_id('owner_thread') and user_id = pg_temp.chat_actor('male1')),
  'new Main send leaves the legacy thread watermark unchanged');
select pg_temp.chat_assert(
  (select not exists (
     select from jsonb_array_elements(e.immediate_context) context
     where context->>'message_id' = pg_temp.chat_id('main_message')::text
   ) and exists (
     select from jsonb_array_elements(e.immediate_context) context
     where context->>'message_id' = pg_temp.chat_id('journey_message')::text
   ) from public.family_message_report_evidence e where report_id = pg_temp.chat_id('journey_report')),
  'Journey report evidence captures its own chat context, without Main');

-- Arrival alone determines who gets an alert. Include an unassigned Guardian
-- in Main and exclude them from Journey even though they are in the Circle.
select pg_temp.chat_assert(
  (select count(*) = 2 and bool_and(user_id in (pg_temp.chat_actor('gmain'), pg_temp.chat_actor('gadd')))
      and bool_and(title = 'Guardian Circle' and body = 'New message in your Guardian Circle'
                   and payload = '{}'::jsonb and related_match_id is null and read_at is null)
   from public.notifications where type = 'circle_message' and related_chat_id = pg_temp.chat_id('owner_main')),
  'Main arrival alerts both eligible members with only the safe copy and chat id');
select pg_temp.chat_reject(
  'insert into public.notifications(user_id,type,title,body,related_chat_id)
   values (pg_temp.chat_actor(''gmain''), ''circle_message'', ''Guardian Circle'',
           ''New message in your Guardian Circle'', pg_temp.chat_id(''owner_main''))',
  '23505', 'the database rejects duplicate unread alert rows for a recipient and chat');
select pg_temp.chat_reject(
  'insert into public.notifications(user_id,type,title,body,payload,related_chat_id)
   values (pg_temp.chat_actor(''male2''), ''circle_message'', ''Guardian Circle'',
           ''New message in your Guardian Circle'', ''{"preview":"Synthetic message text"}'',
           pg_temp.chat_id(''owner_main''))',
  '23514', 'the database rejects text in a Circle alert payload');

set local role authenticated;
select pg_temp.chat_as('gmain');
insert into circle_alert_fixture
select id, created_at from public.notifications
where type = 'circle_message' and related_chat_id = pg_temp.chat_id('owner_main');
select pg_temp.chat_assert(
  (select count(*) = 1 and bool_and(user_id = pg_temp.chat_actor('gmain'))
   from public.notifications where type = 'circle_message'),
  'notification rows are visible only to their own recipient');
select pg_temp.chat_reject(
  'update public.notifications set created_at = now() where type = ''circle_message''',
  '42501', 'recipient cannot alter alert timestamps');
select pg_temp.chat_reject(
  'update public.notifications set related_chat_id = null where type = ''circle_message''',
  '42501', 'recipient cannot change a notification’s chat');
select pg_temp.chat_as('male1');
insert into circle_chat_fixture values ('first_journey_send',
  public.zyra_send_family_message(pg_temp.chat_id('owner_thread'), 'Line 107 synthetic Current send',
                                  pg_temp.chat_id('first_chat')));
reset role;
select pg_temp.chat_assert(
  exists (select from public.family_messages where id = pg_temp.chat_id('first_journey_send')
          and chat_id = pg_temp.chat_id('first_chat'))
  and not exists (select from public.notifications where type = 'circle_message'
                  and related_chat_id = pg_temp.chat_id('first_chat')),
  'Current send succeeds while chat mute and missing assignment suppress every Journey alert');

set local role authenticated;
select pg_temp.chat_as('gmain');
select public.zyra_set_family_chat_muted(pg_temp.chat_id('first_chat'), false);
select pg_temp.chat_assert(
  (select unread_count = 1 and alerts_on from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
   where chat_id = pg_temp.chat_id('first_chat'))
  and not exists (select from public.notifications where type = 'circle_message'
                  and related_chat_id = pg_temp.chat_id('first_chat')),
  'unmuting Journey restores alerts for future arrivals without creating a catch-up row');
select pg_temp.chat_as('male1');
select public.zyra_send_family_message(pg_temp.chat_id('owner_thread'), 'Line 107 synthetic legacy Main send');
select public.zyra_send_family_message(pg_temp.chat_id('owner_thread'), 'Line 107 synthetic Journey alert',
                                       pg_temp.chat_id('first_chat'));
select pg_temp.chat_as('gmain');
select pg_temp.chat_assert(
  (select count(*) = 1 and bool_and(n.created_at > first.created_at)
   from public.notifications n join circle_alert_fixture first using (id)
   where n.type = 'circle_message' and n.related_chat_id = pg_temp.chat_id('owner_main') and n.read_at is null)
  and (select count(*) = 1 from public.notifications where type = 'circle_message'
       and related_chat_id = pg_temp.chat_id('owner_main') and read_at is null),
  'another Main arrival refreshes the same unread row and does not duplicate it');
select pg_temp.chat_assert(
  (select count(*) = 1 from public.notifications where type = 'circle_message'
   and related_chat_id = pg_temp.chat_id('first_chat') and read_at is null),
  'eligible Journey arrival creates a separate unread row');
select public.zyra_mark_family_chat_read(pg_temp.chat_id('first_chat'));
select pg_temp.chat_assert(
  (select count(*) = 1 and bool_and(read_at is not null) from public.notifications where type = 'circle_message'
   and related_chat_id = pg_temp.chat_id('first_chat'))
  and exists (select from public.notifications where type = 'circle_message'
              and related_chat_id = pg_temp.chat_id('owner_main') and read_at is null),
  'marking Journey read clears only that chat alert');
select public.zyra_set_family_chat_muted(pg_temp.chat_id('first_chat'), true);
select public.zyra_mark_family_chat_read(pg_temp.chat_id('owner_main'));
select pg_temp.chat_as('gadd');
select pg_temp.chat_assert(
  exists (select from public.notifications where type = 'circle_message'
          and related_chat_id = pg_temp.chat_id('owner_main') and read_at is null)
  and not exists (select from public.notifications where type = 'circle_message'
                  and related_chat_id = pg_temp.chat_id('first_chat')),
  'one member reading Main preserves another member’s alert and gives no unassigned Journey alert');
update public.notifications set read_at = clock_timestamp()
where type = 'circle_message' and related_chat_id = pg_temp.chat_id('owner_main');
select pg_temp.chat_assert(
  (select bool_and(read_at is null) from public.notifications where type = 'circle_message'
   and related_chat_id = pg_temp.chat_id('owner_main')),
  'generic notification update cannot acknowledge Circle chat attention');
update public.notifications set read_at = clock_timestamp()
where title = 'Line 107 synthetic legacy notice';
select pg_temp.chat_assert(
  (select read_at is not null from public.notifications where title = 'Line 107 synthetic legacy notice'),
  'recipient can still use the direct read update on an ordinary notification');

select pg_temp.chat_as('gmain');
select public.zyra_set_family_chat_muted(pg_temp.chat_id('owner_main'), true);
select pg_temp.chat_as('male1');
select public.zyra_send_family_message(pg_temp.chat_id('owner_thread'), 'Line 107 synthetic muted Main arrival');
select pg_temp.chat_as('gmain');
select public.zyra_set_family_chat_muted(pg_temp.chat_id('owner_main'), false);
select public.zyra_set_family_message_muted(pg_temp.chat_id('owner_thread'), true);
select pg_temp.chat_as('male1');
select public.zyra_send_family_message(pg_temp.chat_id('owner_thread'), 'Line 107 synthetic muted Circle arrival');
select pg_temp.chat_as('gmain');
select pg_temp.chat_assert(
  (select unread_count = 2 and counts_toward_total and not alerts_on
   from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
   where chat_id = pg_temp.chat_id('owner_main'))
  and not exists (select from public.notifications where type = 'circle_message'
                  and related_chat_id = pg_temp.chat_id('owner_main') and read_at is null),
  'arrivals during either mute count as unread and create no unread alert');
select public.zyra_set_family_message_muted(pg_temp.chat_id('owner_thread'), false);
select pg_temp.chat_assert(
  not exists (select from public.notifications where type = 'circle_message'
              and related_chat_id = pg_temp.chat_id('owner_main') and read_at is null),
  'unmuting the Circle does not create a catch-up alert');

select public.zyra_set_notification_preference('circle', false);
select pg_temp.chat_assert(
  (select not enabled from public.zyra_notification_preferences() where category = 'circle'),
  'Circle notification preference can be set and read');
select pg_temp.chat_as('male1');
select public.zyra_send_family_message(pg_temp.chat_id('owner_thread'), 'Line 107 synthetic opted-out arrival');
select pg_temp.chat_as('gmain');
select pg_temp.chat_assert(
  (select unread_count = 3 and alerts_on from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
   where chat_id = pg_temp.chat_id('owner_main'))
  and not exists (select from public.notifications where type = 'circle_message'
                  and related_chat_id = pg_temp.chat_id('owner_main') and read_at is null),
  'Circle preference suppresses delivery while the chat exposes its mute flags and count');
select public.zyra_set_notification_preference('circle', true);
select pg_temp.chat_as('male1');
select public.zyra_send_family_message(pg_temp.chat_id('owner_thread'), 'Line 107 synthetic new Main alert');
select pg_temp.chat_as('gmain');
select pg_temp.chat_assert(
  (select count(*) = 2 and count(*) filter (where read_at is null) = 1
   from public.notifications where type = 'circle_message' and related_chat_id = pg_temp.chat_id('owner_main')),
  'first eligible arrival after a read creates one new unread row');
select public.zyra_mark_family_messages_read(pg_temp.chat_id('owner_thread'));
select pg_temp.chat_assert(
  not exists (select from public.notifications where type = 'circle_message' and read_at is null)
  and (select bool_and(unread_count = 0) from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))),
  'legacy thread read clears that member’s unread alerts and chat counts');
reset role;

set local role authenticated;
select pg_temp.chat_as('gadd');
select pg_temp.chat_assert(
  (select count(*) = 1 and bool_and(kind = 'main')
   from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread')))
  and not exists (select from public.family_messages where chat_id = pg_temp.chat_id('first_chat')),
  'unassigned Additional Guardian sees Main but no Journey metadata or messages');
select pg_temp.chat_reject(
  'select public.zyra_mark_family_chat_read(pg_temp.chat_id(''first_chat''))',
  'family_chat_not_found', 'unassigned Additional Guardian cannot mark read');
select pg_temp.chat_reject(
  'select public.zyra_set_family_chat_muted(pg_temp.chat_id(''first_chat''), true)',
  'family_chat_not_found', 'unassigned Additional Guardian cannot mute');
select pg_temp.chat_reject(
  'select public.zyra_send_family_message(pg_temp.chat_id(''owner_thread''), ''Wrong Journey'', pg_temp.chat_id(''first_chat''))',
  'family_chat_not_found', 'unassigned Additional Guardian cannot send into a Journey chat');
select pg_temp.chat_reject(
  'select public.zyra_report_family_message(pg_temp.chat_id(''owner_thread''), pg_temp.chat_id(''journey_message''), ''privacy'')',
  'message_not_reportable', 'unassigned Additional Guardian cannot report an inaccessible Journey row');
select pg_temp.chat_as('gb');
select pg_temp.chat_assert(
  not exists (select from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread')))
  and not exists (select from public.family_messages where chat_id = pg_temp.chat_id('first_chat')),
  'counterpart Main Guardian gets no access to the owning Seeker Circle');
select pg_temp.chat_as('male2');
select pg_temp.chat_assert(
  not exists (select from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))),
  'unrelated Seeker cannot enumerate Circle chats');
select pg_temp.chat_as('male1');
select * from public.zyra_guardian_journey_access(pg_temp.chat_actor('gadd'), pg_temp.chat_id('first_attempt'), true);
select pg_temp.chat_as('gadd');
select pg_temp.chat_assert(
  exists (select from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
          where chat_id = pg_temp.chat_id('first_chat')),
  'same-Seeker per-attempt assignment grants current Journey admission');
select pg_temp.chat_as('male1');
select * from public.zyra_guardian_journey_access(pg_temp.chat_actor('gadd'), pg_temp.chat_id('first_attempt'), false);
select pg_temp.chat_as('gadd');
select pg_temp.chat_assert(
  not exists (select from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
              where chat_id = pg_temp.chat_id('first_chat')),
  'revoking assignment removes current Journey admission');
reset role;

-- Stage an ordinary end older than 30 days, with the original attempt id.
update public.journey_attempts
set status = 'ended', started_at = now() - interval '60 days', ended_at = now() - interval '40 days',
    ended_by = pg_temp.chat_actor('male1'), end_reason = 'not_compatible'
where id = pg_temp.chat_id('first_attempt');
update public.matches
set status = 'ended', ended_at = now() - interval '40 days',
    ended_by = pg_temp.chat_actor('male1'), end_reason = 'not_compatible'
where id = pg_temp.chat_id('match');

set local role authenticated;
select pg_temp.chat_as('male1');
select pg_temp.chat_assert(
  (select state = 'past' and ended_at = now() - interval '40 days'
   from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
   where chat_id = pg_temp.chat_id('first_chat')),
  'ordinary Journey becomes Past under the same chat id after day 30');
select pg_temp.chat_as('gmain');
select pg_temp.chat_assert(
  not exists (select from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
              where chat_id = pg_temp.chat_id('first_chat'))
  and not exists (select from public.family_messages where chat_id = pg_temp.chat_id('first_chat')),
  'former current access is not Past sharing');
select pg_temp.chat_as('male1');
select * from public.zyra_guardian_history_consent(pg_temp.chat_actor('gmain'), true);
select pg_temp.chat_as('gmain');
select pg_temp.chat_assert(
  (select state = 'past' and muted and unread_count = 0
   from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
   where chat_id = pg_temp.chat_id('first_chat')),
  'independent history consent restores access to the same chat and member state');
select pg_temp.chat_as('male1');
insert into circle_chat_fixture values ('past_send',
  public.zyra_send_family_message(pg_temp.chat_id('owner_thread'), 'Line 107 synthetic Past send',
                                  pg_temp.chat_id('first_chat')));
select pg_temp.chat_assert(
  exists (select from public.family_messages where id = pg_temp.chat_id('past_send')
          and chat_id = pg_temp.chat_id('first_chat')),
  'eligible member can still send to the original Past chat after day 30');
select pg_temp.chat_as('fem1');
select public.zyra_block_user(pg_temp.chat_actor('male1'));
select pg_temp.chat_as('male1');
select pg_temp.chat_assert(
  not exists (select from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
              where chat_id = pg_temp.chat_id('first_chat'))
  and not exists (select from public.family_messages where chat_id = pg_temp.chat_id('first_chat')),
  'pair block hides an ended Journey chat for the owning Seeker');
select pg_temp.chat_as('gmain');
select pg_temp.chat_assert(
  not exists (select from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
              where chat_id = pg_temp.chat_id('first_chat')),
  'pair block also hides the ended Journey chat from a consented Guardian');
select pg_temp.chat_as('fem1');
select public.zyra_unblock_user(pg_temp.chat_actor('male1'));
select public.zyra_remove_ended_journey(pg_temp.chat_id('first_attempt'));
select pg_temp.chat_assert(
  (select count(*) = 1 and bool_and(kind = 'main')
   from public.zyra_family_message_chats(pg_temp.chat_id('other_thread'))),
  'one Seeker removal hides only that side’s Past Circle chat');
select pg_temp.chat_as('male1');
select pg_temp.chat_assert(
  exists (select from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
          where chat_id = pg_temp.chat_id('first_chat') and state = 'past'),
  'the other Seeker still has the original Past chat after unblock');
reset role;

-- Preserve the old attempt while the same pair begins a new one.
insert into circle_chat_fixture values ('restart_attempt', '10700000-0000-0000-0000-000000000006');
insert into public.journey_attempts (id, match_id, attempt_number, status)
values (pg_temp.chat_id('restart_attempt'), pg_temp.chat_id('match'), 2, 'potential');
select pg_temp.chat_assert(
  not exists (select from public.family_message_chats where attempt_id = pg_temp.chat_id('restart_attempt')),
  'an unstarted potential attempt creates no Circle chat');
update public.matches
set status = 'active', ended_at = null, ended_by = null, end_reason = null
where id = pg_temp.chat_id('match');
update public.journey_attempts
set status = 'active', journey_stage = 'compatibility_reveal', started_at = now()
where id = pg_temp.chat_id('restart_attempt');
insert into circle_chat_fixture
select 'restart_chat', id from public.family_message_chats
where thread_id = pg_temp.chat_id('owner_thread') and attempt_id = pg_temp.chat_id('restart_attempt');

set local role authenticated;
select pg_temp.chat_as('gmain');
select pg_temp.chat_assert(
  pg_temp.chat_id('restart_chat') <> pg_temp.chat_id('first_chat')
  and (select state = 'current' and not muted and unread_count = 0
       from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
       where chat_id = pg_temp.chat_id('restart_chat'))
  and (select state = 'past' and muted from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
       where chat_id = pg_temp.chat_id('first_chat')),
  'restart gets a distinct stable chat and does not inherit Past read or mute state');
reset role;

-- Relinking the same Guardian does not preserve history consent from the
-- prior active-link epoch. The old message also predates the new membership.
set local role authenticated;
select pg_temp.chat_as('gadd');
select public.zyra_send_family_message(pg_temp.chat_id('owner_thread'), 'Line 107 synthetic previous epoch arrival');
select pg_temp.chat_as('gmain');
insert into circle_chat_fixture
select 'old_main_alert', id from public.notifications where type = 'circle_message'
and related_chat_id = pg_temp.chat_id('owner_main') and read_at is null;
reset role;
update public.wali_links set status = 'removed'
where seeker_id = pg_temp.chat_actor('male1') and wali_id = pg_temp.chat_actor('gmain');
set local role authenticated;
select pg_temp.chat_as('gmain');
select pg_temp.chat_assert(
  not exists (select from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread')))
  and not exists (select from public.notifications where related_chat_id = pg_temp.chat_id('owner_main')),
  'Guardian departure revokes the whole Circle, including its alert rows');
reset role;
update public.wali_links set status = 'active'
where seeker_id = pg_temp.chat_actor('male1') and wali_id = pg_temp.chat_actor('gmain');
set local role authenticated;
select pg_temp.chat_as('gmain');
select pg_temp.chat_assert(
  not exists (select from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
              where chat_id = pg_temp.chat_id('first_chat'))
  and not exists (select from public.family_messages where id = pg_temp.chat_id('journey_message'))
  and not exists (select from public.notifications where related_chat_id = pg_temp.chat_id('owner_main')),
  'relink cannot inherit old Past consent, history, or Main alerts');
select pg_temp.chat_as('gadd');
select public.zyra_send_family_message(pg_temp.chat_id('owner_thread'), 'Line 107 synthetic new epoch arrival');
select pg_temp.chat_as('gmain');
select pg_temp.chat_assert(
  (select count(*) = 1 and bool_and(id <> pg_temp.chat_id('old_main_alert'))
   from public.notifications where related_chat_id = pg_temp.chat_id('owner_main') and read_at is null),
  'the first eligible arrival after relinking gets a fresh alert ID');
reset role;
insert into public.protection_holds(match_id, restricted_id, protected_id, hold_type, appealable)
values (pg_temp.chat_id('match'), pg_temp.chat_actor('male1'), pg_temp.chat_actor('fem1'), 'moderation', true);
set local role authenticated;
select pg_temp.chat_as('male1');
select public.zyra_remove_ended_journey(pg_temp.chat_id('first_attempt'));
select pg_temp.chat_assert(
  not exists (select from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
              where chat_id = pg_temp.chat_id('first_chat'))
  and not exists (select from public.family_messages where chat_id = pg_temp.chat_id('first_chat')),
  'owner removal hides the exact Past chat and its rows after both sides remove it');
reset role;
select pg_temp.chat_assert(
  exists (select from public.journey_attempts where id = pg_temp.chat_id('first_attempt'))
  and exists (select from public.family_messages where id = pg_temp.chat_id('journey_message')
              and chat_id = pg_temp.chat_id('first_chat')),
  'mutual removal retains the hidden chat and its rows while a protection hold and report are open');
set local role service_role;
select set_config('request.jwt.claims', '{"role":"service_role"}', true);
select public.zyra_close_family_message_report(pg_temp.chat_id('journey_report'));
reset role;
select private.zyra_purge_closed_ended_journeys();
select pg_temp.chat_assert(
  exists (select from public.family_messages where id = pg_temp.chat_id('journey_message')),
  'after the report closes, the protection hold alone retains hidden chat history');
update public.family_message_reports set status = 'reviewing', reviewed_at = null
where id = pg_temp.chat_id('journey_report');
update public.protection_holds set released_at = now(), released_by = pg_temp.chat_actor('gmain'),
  release_reason = 'Reviewed'
where match_id = pg_temp.chat_id('match');
select private.zyra_purge_closed_ended_journeys();
select pg_temp.chat_assert(
  exists (select from public.family_messages where id = pg_temp.chat_id('journey_message')),
  'after the hold is released, the open Circle report alone retains hidden chat history');
set local role service_role;
select public.zyra_close_family_message_report(pg_temp.chat_id('journey_report'));
reset role;
select private.zyra_purge_closed_ended_journeys();
select pg_temp.chat_assert(
  not exists (select from public.journey_attempts where id = pg_temp.chat_id('first_attempt'))
  and not exists (select from public.family_message_chats where attempt_id = pg_temp.chat_id('first_attempt'))
  and not exists (select from public.family_messages where id = pg_temp.chat_id('journey_message'))
  and not exists (select from public.notifications where related_chat_id = pg_temp.chat_id('first_chat'))
  and exists (select from public.family_message_report_evidence where report_id = pg_temp.chat_id('journey_report'))
  and exists (select from public.family_messages where id = pg_temp.chat_id('main_message')),
  'the daily purge deletes only the mutually removed Journey, with the existing moderation evidence retained');

-- An end for safety redacts the name even on the ending Seeker's own
-- visible Past chat. Neither the other Seeker nor either consented Guardian
-- can use their own Circle access to discover that private Past chat.
insert into circle_chat_fixture
select 'other_restart_chat', id from public.family_message_chats
where thread_id = pg_temp.chat_id('other_thread') and attempt_id = pg_temp.chat_id('restart_attempt');
set local role authenticated;
select pg_temp.chat_as('gmain');
insert into circle_chat_fixture values ('survivor_circle_message',
  public.zyra_send_family_message(pg_temp.chat_id('owner_thread'), 'Line 107 synthetic survivor Circle chat',
                                  pg_temp.chat_id('restart_chat')));
select pg_temp.chat_as('gb');
insert into circle_chat_fixture values ('departing_circle_message',
  public.zyra_send_family_message(pg_temp.chat_id('other_thread'), 'Line 107 synthetic departing Circle chat',
                                  pg_temp.chat_id('other_restart_chat')));
insert into circle_chat_fixture values ('departing_main_message',
  public.zyra_send_family_message(pg_temp.chat_id('other_thread'), 'Line 107 synthetic departing Main chat'));
select pg_temp.chat_as('fem1');
insert into circle_chat_fixture values ('departing_journey_report', public.zyra_report_family_message(
  pg_temp.chat_id('other_thread'), pg_temp.chat_id('departing_circle_message'), 'harassment'));
reset role;
update public.journey_attempts
set status = 'ended', ended_at = now(), ended_by = pg_temp.chat_actor('male1'),
    end_reason = 'safety_concern'
where id = pg_temp.chat_id('restart_attempt');
update public.matches
set status = 'ended', ended_at = now(), ended_by = pg_temp.chat_actor('male1'),
    end_reason = 'safety_concern'
where id = pg_temp.chat_id('match');

set local role authenticated;
select pg_temp.chat_as('male1');
select * from public.zyra_guardian_history_consent(pg_temp.chat_actor('gmain'), true);
select pg_temp.chat_assert(
  (select state = 'past' and other_first_name is null
   from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
   where chat_id = pg_temp.chat_id('restart_chat')),
  'ending Seeker can list their own safety Past chat without a counterpart name');
select pg_temp.chat_as('gmain');
select pg_temp.chat_assert(
  not exists (select from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
              where chat_id = pg_temp.chat_id('restart_chat')),
  'history consent does not reveal the safety Past chat to the ending side Guardian');
select pg_temp.chat_as('fem1');
select * from public.zyra_guardian_history_consent(pg_temp.chat_actor('gb'), true);
select pg_temp.chat_assert(
  not exists (select from public.zyra_family_message_chats(pg_temp.chat_id('other_thread'))
              where chat_id = pg_temp.chat_id('other_restart_chat'))
  and not exists (select from public.family_messages where chat_id = pg_temp.chat_id('other_restart_chat')),
  'non-ending Seeker cannot infer the safety Past chat from list or transcript');
select pg_temp.chat_reject(
  'select public.zyra_set_family_chat_muted(pg_temp.chat_id(''other_restart_chat''), true)',
  'family_chat_not_found', 'non-ending Seeker cannot mutate the safety Past chat');
select pg_temp.chat_as('gb');
select pg_temp.chat_assert(
  not exists (select from public.zyra_family_message_chats(pg_temp.chat_id('other_thread'))
              where chat_id = pg_temp.chat_id('other_restart_chat'))
  and not exists (select from public.family_messages where chat_id = pg_temp.chat_id('other_restart_chat')),
  'history consent does not reveal the safety Past chat to the other side Guardian');
reset role;

-- Erasure must remove both Journey Circle copies, including a chat whose
-- messages were authored entirely by people staying on ZYRA.
insert into public.protection_holds(match_id, restricted_id, protected_id, hold_type, appealable)
values (pg_temp.chat_id('match'), pg_temp.chat_actor('fem1'), pg_temp.chat_actor('male1'), 'moderation', true);
set local role authenticated;
select pg_temp.chat_as('male1');
select pg_temp.chat_assert(
  exists (select from public.notifications where type = 'circle_message'
          and related_chat_id = pg_temp.chat_id('restart_chat') and read_at is null),
  'surviving Seeker has an eligible Journey alert before counterpart deletion');
select pg_temp.chat_as('fem1');
select public.delete_own_account();
select pg_temp.chat_as('male1');
select pg_temp.chat_assert(
  (select count(*) = 1 and bool_and(kind = 'main')
   from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread')))
  and not exists (select from public.family_messages where chat_id = pg_temp.chat_id('restart_chat'))
  and not exists (select from public.notifications where related_chat_id = pg_temp.chat_id('restart_chat')),
  'counterpart deletion immediately removes the surviving Circle’s Journey, transcript and alert');
select pg_temp.chat_reject(
  'select * from private.safety_sealed_messages', '42501', 'members cannot read sealed Circle history');
reset role;
select pg_temp.chat_assert(
  (select count(*) = 2 and bool_and(source = 'guardian_circle'
     and purge_at = sealed_at + interval '8760 hours')
   from private.safety_sealed_messages where source_message_id in
   (pg_temp.chat_id('survivor_circle_message'), pg_temp.chat_id('departing_circle_message')))
  and not exists (select from public.family_message_chats where attempt_id = pg_temp.chat_id('restart_attempt'))
  and exists (select from public.family_messages where id = pg_temp.chat_id('main_message')),
  'counterpart deletion seals both Circle copies for 365 days and keeps unrelated Main history');
select pg_temp.chat_assert(
  exists (select from public.family_message_reports r
          join private.safety_sealed_messages s on s.id = r.sealed_message_id
          where r.id = pg_temp.chat_id('departing_journey_report') and r.message_id is null
            and s.source_message_id = pg_temp.chat_id('departing_circle_message'))
  and not exists (select from private.zyra_circle_seal_protections p
                  join private.safety_sealed_messages s on s.id = p.sealed_message_id
                  where p.report_id = pg_temp.chat_id('departing_journey_report')
                    and s.source_message_id = pg_temp.chat_id('departing_main_message')),
  'the Journey report points to its exact sealed message and does not protect an unrelated Main message');
update private.safety_sealed_messages set sealed_at = now() - interval '8760 hours', purge_at = now()
where source_message_id in (pg_temp.chat_id('survivor_circle_message'), pg_temp.chat_id('departing_circle_message'),
                            pg_temp.chat_id('departing_main_message'));
select public.zyra_purge_expired_safety_messages();
select pg_temp.chat_assert(
  (select count(*) = 2 from private.safety_sealed_messages where source_message_id in
   (pg_temp.chat_id('survivor_circle_message'), pg_temp.chat_id('departing_circle_message')))
  and not exists (select from private.safety_sealed_messages
                  where source_message_id = pg_temp.chat_id('departing_main_message')),
  'an active protection hold keeps both expired Journey copies while the unrelated Main message purges');
update public.protection_holds set released_at = now(), released_by = pg_temp.chat_actor('gmain'),
  release_reason = 'Reviewed'
where match_id = pg_temp.chat_id('match') and released_at is null;
select public.zyra_purge_expired_safety_messages();
select pg_temp.chat_assert(
  exists (select from private.safety_sealed_messages
          where source_message_id = pg_temp.chat_id('departing_circle_message')),
  'the open Journey report retains sealed content after the protection hold closes');
set local role service_role;
select set_config('request.jwt.claims', '{"role":"service_role"}', true);
select public.zyra_close_family_message_report(pg_temp.chat_id('departing_journey_report'));
reset role;
select public.zyra_purge_expired_safety_messages();
select pg_temp.chat_assert(
  not exists (select from private.safety_sealed_messages where source_message_id in
              (pg_temp.chat_id('survivor_circle_message'), pg_temp.chat_id('departing_circle_message'))),
  'expired sealed Circle copies purge after their protection hold and report both close');

set local role anon;
select set_config('request.jwt.claims', '{"role":"anon"}', true);
select pg_temp.chat_reject(
  'select * from public.zyra_family_message_chats(null::uuid)',
  '42501', 'anonymous chat list has no execute grant');
select pg_temp.chat_reject(
  'select public.zyra_mark_family_chat_read(null::uuid)',
  '42501', 'anonymous chat read mutation has no execute grant');
select pg_temp.chat_reject(
  'select public.zyra_set_family_chat_muted(null::uuid, true)',
  '42501', 'anonymous chat mute has no execute grant');
select pg_temp.chat_reject(
  'select public.zyra_send_family_message(null::uuid, ''Anonymous'', null::uuid)',
  '42501', 'anonymous chat send has no execute grant');
reset role;
rollback;
