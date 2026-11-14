-- Line 110 / Q143 and Q144. Run after the production baseline on a disposable
-- zyra_server0_v2_* database. The shared actor fixture and all rows roll back.
\set ON_ERROR_STOP on
begin;
\ir fixtures/server0_v2_full_schema_prestate.sql

do $catalog$
declare
  caller_view regclass := 'public.zyra_my_attempt_participation'::regclass;
  roster_view regclass := 'public.zyra_attempt_participant_rows'::regclass;
  caller_helper regprocedure := 'private.zyra_my_attempt_participation_rows()'::regprocedure;
begin
  if not exists (
    select from pg_class where oid = caller_view
      and reloptions @> array['security_invoker=true']
  ) then raise exception 'Q143: participation view must use caller rights'; end if;

  if (select array_agg(attname::text order by attnum) from pg_attribute
      where attrelid = caller_view and attnum > 0 and not attisdropped)
      is distinct from array['attempt_id', 'role', 'match_id', 'is_main', 'attempt_status']
  then raise exception 'Q143: participation view changed its five-field contract'; end if;

  if not exists (
    select from pg_proc where oid = caller_helper and prosecdef and provolatile = 's'
      and proconfig @> array['search_path=""']
  ) then raise exception 'Q143: caller helper must be stable, owner-rights, with an empty search path'; end if;

  if not has_table_privilege('authenticated', caller_view, 'SELECT')
     or not has_function_privilege('authenticated', caller_helper, 'EXECUTE')
     or has_table_privilege('anon', caller_view, 'SELECT')
     or has_table_privilege('service_role', caller_view, 'SELECT')
     or has_function_privilege('anon', caller_helper, 'EXECUTE')
     or has_function_privilege('service_role', caller_helper, 'EXECUTE')
     or has_schema_privilege('anon', 'private', 'USAGE')
     or has_schema_privilege('authenticated', 'private', 'USAGE')
  then raise exception 'Q143: caller entry points have unexpected access grants'; end if;

  if exists (
    select from pg_roles where rolname in ('anon', 'authenticated', 'service_role')
      and has_table_privilege(oid, roster_view, 'SELECT')
  ) then raise exception 'Q143: unscoped roster must remain private'; end if;
  raise notice 'Q143 PASS: view, result shape, helper and grants';

  if not exists (
    select from pg_trigger where tgname = 'family_message_chats_create_thread'
      and tgrelid = 'public.family_message_threads'::regclass and tgtype = 5
      and tgfoid = 'private.zyra_family_chat_create_for_thread()'::regprocedure
      and tgenabled = 'O'
  ) or not exists (
    select from pg_trigger where tgname = 'family_message_chats_create_attempt'
      and tgrelid = 'public.journey_attempts'::regclass and tgtype = 21
      and tgfoid = 'private.zyra_family_chat_create_for_attempt()'::regprocedure
      and tgenabled = 'O'
      and tgattr::smallint[] @> array(
        select attnum from pg_attribute where attrelid = 'public.journey_attempts'::regclass
          and attname in ('status', 'started_at')
      )
      and cardinality(tgattr::smallint[]) = 2
  ) then raise exception 'Q144: renamed row-level AFTER triggers must be enabled'; end if;
  raise notice 'Q144 PASS: both renamed triggers point to the corresponding renamed functions';
end;
$catalog$;

create function pg_temp.actor(p_label text) returns uuid language sql stable as $$
  select id from server0_v2_fixture_actors where fixture_label = p_label;
$$;
create function pg_temp.as_actor(p_label text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object(
    'sub', pg_temp.actor(p_label), 'role', 'authenticated')::text, true);
$$;
create function pg_temp.expect(p_ok boolean, p_label text) returns void language plpgsql as $$
begin
  if p_ok is distinct from true then raise exception 'Line 110 FAIL: %', p_label; end if;
  raise notice 'Line 110 PASS: %', p_label;
end;
$$;

create temp table line110_matches (label text primary key, match_id uuid not null);
insert into line110_matches values
  ('a', '11000000-0000-0000-0000-000000000001'),
  ('b', '11000000-0000-0000-0000-000000000002');
create function pg_temp.match_id(p_label text) returns uuid language sql stable as $$
  select match_id from line110_matches where label = p_label;
$$;
grant select on server0_v2_fixture_actors, line110_matches to authenticated;
grant execute on function pg_temp.actor(text), pg_temp.as_actor(text),
  pg_temp.expect(boolean, text), pg_temp.match_id(text) to authenticated;

insert into public.wali_links(seeker_id, wali_id, status, is_main, relationship) values
  (pg_temp.actor('male1'), pg_temp.actor('gadd'), 'active', false, 'brother'),
  (pg_temp.actor('fem1'), pg_temp.actor('gb'), 'active', true, 'father'),
  (pg_temp.actor('male2'), pg_temp.actor('gmain2'), 'active', true, 'father'),
  (pg_temp.actor('fem2'), pg_temp.actor('gb2'), 'active', true, 'father');
update public.subscriptions set plan_type = 'seeker_premium' where user_id = pg_temp.actor('male1');
update public.subscriptions set plan_type = 'wali_premium' where user_id = pg_temp.actor('gmain');

create temp table line110_circle (thread_id uuid primary key);
grant insert on line110_circle to authenticated;
set local role authenticated;
select pg_temp.as_actor('male1');
insert into line110_circle
select thread_id from public.zyra_open_family_message_circle(pg_temp.actor('male1'));
reset role;

select pg_temp.expect(
  (select count(*) = 1 and bool_and(kind = 'main' and attempt_id is null)
   from public.family_message_chats join line110_circle using (thread_id)),
  'Q144: opening a Circle creates exactly one Main chat');

insert into public.matches(id, seeker_a_id, seeker_b_id, status, journey_stage)
select pg_temp.match_id(pair.label), least(pg_temp.actor(pair.first), pg_temp.actor(pair.second)),
       greatest(pg_temp.actor(pair.first), pg_temp.actor(pair.second)), 'active', 'compatibility_reveal'
from (values ('a', 'male1', 'fem1'), ('b', 'male2', 'fem2')) pair(label, first, second);

select pg_temp.expect(
  (select count(*) = 2
     and count(*) filter (where c.kind = 'journey' and a.match_id = pg_temp.match_id('a')) = 1
   from public.family_message_chats c join line110_circle using (thread_id)
   left join public.journey_attempts a on a.id = c.attempt_id),
  'Q144: a new Journey creates exactly one attempt-linked chat in its own Circle');

insert into public.conversations(match_id, attempt_id, status)
select match_id, id, 'active' from public.journey_attempts;
insert into public.messages(conversation_id, sender_id, content)
select c.id, m.seeker_a_id, 'Synthetic line 110 message'
from public.conversations c join public.matches m on m.id = c.match_id;

set local role authenticated;
select pg_temp.as_actor('male1');
select pg_temp.expect(
  (select count(*) = 1 and bool_and(match_id = pg_temp.match_id('a') and role = 'seeker'
      and is_main is null and attempt_status = 'active')
   from public.zyra_my_attempt_participation),
  'Q143: member A sees only their own participation');
select pg_temp.as_actor('male2');
select pg_temp.expect(
  (select count(*) = 1 and bool_and(match_id = pg_temp.match_id('b') and role = 'seeker'
      and is_main is null and attempt_status = 'active')
   from public.zyra_my_attempt_participation)
  and (select count(*) = 1 and bool_and(match_id = pg_temp.match_id('b')) from public.conversations),
  'Q143: member B sees their own participation and never member A''s Journey or conversation');
select pg_temp.as_actor('gadd');
select pg_temp.expect(
  not exists (select from public.zyra_my_attempt_participation)
  and not exists (select from public.conversations)
  and not exists (select from public.messages),
  'Q143: unassigned Additional Guardian sees no Journey participation or protected rows');

select pg_temp.as_actor('male1');
select access.attempt_id
from public.zyra_my_attempt_participation own
cross join lateral public.zyra_guardian_journey_access(pg_temp.actor('gadd'), own.attempt_id, true) access;
select pg_temp.as_actor('gadd');
select pg_temp.expect(
  (select count(*) = 1 and bool_and(match_id = pg_temp.match_id('a') and role = 'guardian'
      and is_main is false and attempt_status = 'active')
   from public.zyra_my_attempt_participation)
  and (select count(*) = 1 and bool_and(match_id = pg_temp.match_id('a')) from public.conversations)
  and (select count(*) = 1 from public.messages),
  'Q143: Additional Guardian gains only the assigned active Journey via the same policies');

select pg_temp.as_actor('male1');
select access.attempt_id
from public.zyra_my_attempt_participation own
cross join lateral public.zyra_guardian_journey_access(pg_temp.actor('gadd'), own.attempt_id, false) access;
select pg_temp.as_actor('gadd');
select pg_temp.expect(
  not exists (select from public.zyra_my_attempt_participation)
  and not exists (select from public.conversations)
  and not exists (select from public.messages),
  'Q143: revoking the assignment removes participation and protected rows');

select pg_temp.as_actor('male1');
select access.attempt_id
from public.zyra_my_attempt_participation own
cross join lateral public.zyra_guardian_journey_access(pg_temp.actor('gadd'), own.attempt_id, true) access;
reset role;

update public.journey_attempts set status = 'ended', ended_at = now(),
  ended_by = pg_temp.actor('male1'), end_reason = 'not_compatible'
where match_id = pg_temp.match_id('a');
update public.matches set status = 'ended', ended_at = now(),
  ended_by = pg_temp.actor('male1'), end_reason = 'not_compatible'
where id = pg_temp.match_id('a');
select pg_temp.expect(
  exists (select from public.journey_guardian_assignments
          where seeker_id = pg_temp.actor('male1') and revoked_at is null),
  'Q143: ended Journey fixture still has an unrevoked assignment');

set local role authenticated;
select pg_temp.as_actor('gadd');
select pg_temp.expect(
  not exists (select from public.zyra_my_attempt_participation)
  and not exists (select from public.conversations)
  and not exists (select from public.messages),
  'Q143: ending a Journey removes Additional Guardian access even with an unrevoked assignment');
reset role;

set local role anon;
select set_config('request.jwt.claims', '{"role":"anon"}', true);
do $anon_read$
begin
  perform from public.zyra_my_attempt_participation;
  raise exception 'Q143: anonymous role can query the participation view';
exception when insufficient_privilege then
  raise notice 'Q143 PASS: anonymous role cannot query the participation view';
end;
$anon_read$;
reset role;
rollback;
