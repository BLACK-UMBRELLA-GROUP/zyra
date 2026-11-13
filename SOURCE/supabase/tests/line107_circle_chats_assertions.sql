-- ZYRA line 107, DOC-ZYRA-0476 / Q138. Synthetic actors in a disposable replay.
\set ON_ERROR_STOP on
begin;
\ir fixtures/server0_v2_full_schema_prestate.sql

grant select on server0_v2_fixture_actors to authenticated;
create temp table circle_chat_fixture (label text primary key, id uuid not null);
grant select, insert on circle_chat_fixture to authenticated;
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
-- Privileged fixture rows exercise all Journey reads while the unapproved
-- user send path remains fenced.
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
  (select unread_count = 1 and not muted and not circle_muted and counts_toward_total
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
  (select unread_count = 1 and muted and not circle_muted and not counts_toward_total
   from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
   where chat_id = pg_temp.chat_id('first_chat')),
  'chat mute retains the unread bubble and disables attention for that member');
select public.zyra_set_family_message_muted(pg_temp.chat_id('owner_thread'), true);
select pg_temp.chat_assert(
  (select unread_count = 1 and not muted and circle_muted and not counts_toward_total
   from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
   where chat_id = pg_temp.chat_id('owner_main'))
  and (select muted and unread_count = 1 from public.zyra_family_message_circles()
       where thread_id = pg_temp.chat_id('owner_thread')),
  'whole-Circle mute retains the Main bubble and legacy Circle count');
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
select pg_temp.chat_reject(
  'select public.zyra_send_family_message(pg_temp.chat_id(''owner_thread''), ''Await delivery contract'', pg_temp.chat_id(''first_chat''))',
  'family_journey_send_unavailable', 'authorized current Journey send stays fenced');
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
select pg_temp.chat_reject(
  'select public.zyra_send_family_message(pg_temp.chat_id(''owner_thread''), ''Await delivery contract'', pg_temp.chat_id(''first_chat''))',
  'family_journey_send_unavailable', 'older Past shares the Journey fence rather than a 30-day close');
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
update public.wali_links set status = 'removed'
where seeker_id = pg_temp.chat_actor('male1') and wali_id = pg_temp.chat_actor('gmain');
set local role authenticated;
select pg_temp.chat_as('gmain');
select pg_temp.chat_assert(
  not exists (select from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))),
  'Guardian departure revokes the whole Circle');
reset role;
update public.wali_links set status = 'active'
where seeker_id = pg_temp.chat_actor('male1') and wali_id = pg_temp.chat_actor('gmain');
set local role authenticated;
select pg_temp.chat_as('gmain');
select pg_temp.chat_assert(
  not exists (select from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
              where chat_id = pg_temp.chat_id('first_chat'))
  and not exists (select from public.family_messages where id = pg_temp.chat_id('journey_message')),
  'relink cannot inherit old Past consent or history');
select pg_temp.chat_as('male1');
select public.zyra_remove_ended_journey(pg_temp.chat_id('first_attempt'));
select pg_temp.chat_assert(
  not exists (select from public.zyra_family_message_chats(pg_temp.chat_id('owner_thread'))
              where chat_id = pg_temp.chat_id('first_chat'))
  and not exists (select from public.family_messages where chat_id = pg_temp.chat_id('first_chat')),
  'owner removal hides the exact Past chat and its rows after both sides remove it');
reset role;
select pg_temp.chat_assert(
  not exists (select from public.journey_attempts where id = pg_temp.chat_id('first_attempt'))
  and exists (select from public.family_messages where id = pg_temp.chat_id('journey_message')
              and chat_id = pg_temp.chat_id('first_chat')),
  'purging a Journey attempt cannot silently cascade unsealed Circle discussion');

-- An end for safety redacts the name even on the ending Seeker's own
-- visible Past chat. Neither the other Seeker nor either consented Guardian
-- can use their own Circle access to discover that private Past chat.
insert into circle_chat_fixture
select 'other_restart_chat', id from public.family_message_chats
where thread_id = pg_temp.chat_id('other_thread') and attempt_id = pg_temp.chat_id('restart_attempt');
insert into public.family_messages(thread_id, chat_id, sender_id, body, created_at)
values (pg_temp.chat_id('other_thread'), pg_temp.chat_id('other_restart_chat'),
        pg_temp.chat_actor('gb'), 'Line 107 synthetic safety chat', now() - interval '1 minute');
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
