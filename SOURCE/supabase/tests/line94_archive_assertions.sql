-- ZYRA line 94 / Q120, Q126 and Q130. Synthetic fixtures after the isolated replay.
begin;
\ir fixtures/server0_v2_full_schema_prestate.sql

create function pg_temp.archive_actor(p_label text) returns uuid language sql stable as $$
  select id from server0_v2_fixture_actors where fixture_label = p_label;
$$;
create function pg_temp.archive_as(p_label text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object(
    'sub', pg_temp.archive_actor(p_label), 'role', 'authenticated')::text, true);
$$;
create function pg_temp.archive_assert(p_ok boolean, p_label text) returns void language plpgsql as $$
begin
  if p_ok is distinct from true then raise exception 'line 94 archive FAIL: %', p_label; end if;
  raise notice 'line 94 archive PASS: %', p_label;
end;
$$;
create function pg_temp.archive_refuse_removal(p_attempt uuid, p_label text) returns void language plpgsql as $$
begin
  perform public.zyra_remove_ended_journey(p_attempt);
  raise exception 'line 94 archive FAIL: %', p_label;
exception when insufficient_privilege then
  if sqlerrm <> 'ended_journey_not_available' then raise; end if;
  raise notice 'line 94 archive PASS: %', p_label;
end;
$$;
create function pg_temp.archive_refuse_guardian_gate(p_match uuid) returns void language plpgsql as $$
begin
  perform public.zyra_journey_main_guardian_gate(p_match);
  raise exception 'line 94 archive FAIL: Main Guardian gate revealed hidden Match';
exception when raise_exception then
  if sqlerrm <> 'journey_not_available' then raise; end if;
  raise notice 'line 94 archive PASS: Main Guardian gate refuses hidden Match';
end;
$$;
create function pg_temp.archive_refuse_receipt(p_conversation uuid) returns void language plpgsql as $$
begin
  perform public.zyra_mark_journey_messages_read(p_conversation);
  raise exception 'line 94 archive FAIL: message receipt revealed hidden conversation';
exception when raise_exception then
  if sqlerrm <> 'conversation_not_available' then raise; end if;
  raise notice 'line 94 archive PASS: message receipt refuses hidden conversation';
end;
$$;
grant select on server0_v2_fixture_actors to authenticated;
grant execute on function pg_temp.archive_actor(text), pg_temp.archive_as(text),
  pg_temp.archive_assert(boolean, text), pg_temp.archive_refuse_removal(uuid, text),
  pg_temp.archive_refuse_guardian_gate(uuid), pg_temp.archive_refuse_receipt(uuid) to authenticated;

create temporary table archive_matches (label text primary key, match_id uuid, seeker_one uuid, seeker_two uuid);
insert into archive_matches values
  ('old', '94000000-0000-0000-0000-000000000001', pg_temp.archive_actor('male1'), pg_temp.archive_actor('fem1')),
  ('safety', '94000000-0000-0000-0000-000000000002', pg_temp.archive_actor('male2'), pg_temp.archive_actor('fem2')),
  ('hold', '94000000-0000-0000-0000-000000000003', pg_temp.archive_actor('male1'), pg_temp.archive_actor('fem3')),
  ('report', '94000000-0000-0000-0000-000000000004', pg_temp.archive_actor('male1'), pg_temp.archive_actor('fem4'));

insert into public.wali_links(seeker_id, wali_id, status, is_main, relationship) values
  (pg_temp.archive_actor('fem1'), pg_temp.archive_actor('gb'), 'active', true, 'father'),
  (pg_temp.archive_actor('male2'), pg_temp.archive_actor('gmain2'), 'active', true, 'father'),
  (pg_temp.archive_actor('fem2'), pg_temp.archive_actor('gb2'), 'active', true, 'father');

insert into public.matches(id, seeker_a_id, seeker_b_id, status, journey_stage, ended_at, ended_by, end_reason, end_note)
select match_id, least(seeker_one, seeker_two), greatest(seeker_one, seeker_two),
  case label when 'safety' then 'active' else 'ended' end, 'conversation',
  case when label <> 'safety' then now() - interval '5 months' end,
  case when label <> 'safety' then seeker_one end,
  case when label <> 'safety' then 'not_compatible' end,
  case when label <> 'safety' then 'Synthetic end note' end
from archive_matches;
update public.journey_attempts a
set started_at = now() - interval '6 months', ended_at = m.ended_at,
    ended_by = m.ended_by, end_reason = m.end_reason, end_note = m.end_note
from public.matches m join archive_matches f on f.match_id = m.id
where a.match_id = m.id and a.status = 'ended';

create temporary table archive_attempts (label text primary key, attempt_id uuid);
insert into archive_attempts
select f.label, a.id from archive_matches f join public.journey_attempts a on a.match_id = f.match_id;
create function pg_temp.archive_attempt(p_label text) returns uuid language sql stable as $$
  select attempt_id from archive_attempts where label = p_label;
$$;
create function pg_temp.archive_match(p_label text) returns uuid language sql stable as $$
  select match_id from archive_matches where label = p_label;
$$;
grant select on archive_matches, archive_attempts to authenticated;
grant execute on function pg_temp.archive_attempt(text), pg_temp.archive_match(text) to authenticated;

insert into public.conversations(match_id, attempt_id, status)
select match_id, id, case status when 'active' then 'active' else 'closed' end from public.journey_attempts;
create temporary table archive_conversations as
select f.label, c.id from archive_matches f join public.conversations c on c.match_id = f.match_id;
grant select on archive_conversations to authenticated;
insert into public.messages(conversation_id, sender_id, content)
select c.id, m.seeker_a_id, 'Synthetic archive message: ' || f.label
from public.conversations c join public.matches m on m.id = c.match_id
join archive_matches f on f.match_id = m.id;
insert into public.timelines(match_id, attempt_id)
select match_id, id from public.journey_attempts on conflict (attempt_id) do nothing;
insert into public.timeline_milestones(timeline_id, milestone_type)
select id, 'match_created' from public.timelines;

with review as (
  insert into public.journey_family_reviews(match_id, attempt_id, from_stage, to_stage, deadline_at, status)
  values (pg_temp.archive_match('old'), pg_temp.archive_attempt('old'),
          'phase_1', 'phase_2', now() + interval '2 days', 'continued') returning id
)
insert into public.journey_family_review_responses(review_id, wali_id, decision)
select id, pg_temp.archive_actor('gmain'), 'continue' from review;

set local role authenticated;
select pg_temp.archive_as('male1');
select public.zyra_guardian_history_consent(pg_temp.archive_actor('gmain'), true);
select pg_temp.archive_as('fem1');
select public.zyra_guardian_history_consent(pg_temp.archive_actor('gb'), true);
select pg_temp.archive_assert(exists (
  select 1 from public.zyra_my_ended_journeys() where attempt_id = pg_temp.archive_attempt('old')
), 'a Seeker can read an ended archive older than three months');
select pg_temp.archive_assert(exists (
  select 1 from public.zyra_match_ending(pg_temp.archive_match('old')) where end_reason = 'not_compatible'
), 'legacy ended Match reader preserves ordinary end reason');
select public.zyra_block_user(pg_temp.archive_actor('male1'));
select pg_temp.archive_assert(not exists (
  select 1 from public.zyra_my_ended_journeys() where attempt_id = pg_temp.archive_attempt('old')
), 'live block hides an already-ended Journey for the blocker');
select pg_temp.archive_as('male1');
select pg_temp.archive_assert(not exists (
  select 1 from public.zyra_my_attempt_participation where attempt_id = pg_temp.archive_attempt('old')
) and not exists (
  select 1 from public.zyra_match_ending(pg_temp.archive_match('old'))
) and not exists (
  select 1 from public.messages where content = 'Synthetic archive message: old'
), 'live block hides attempt, ending RPC and messages for the other Seeker');
select pg_temp.archive_assert(not exists (
  select 1 from public.zyra_guardian_activity() where activity_type = 'review_answered'
) and not exists (
  select 1 from public.zyra_journey_busy_flags(array[pg_temp.archive_match('old')])
), 'live block hides Family Review activity and counterpart busy flag');
select pg_temp.archive_refuse_guardian_gate(pg_temp.archive_match('old'));
select pg_temp.archive_refuse_receipt((select id from archive_conversations where label = 'old'));
select pg_temp.archive_as('gmain');
select pg_temp.archive_assert(not exists (
  select 1 from public.zyra_attempt_summary_for_guardian(pg_temp.archive_actor('male1'))
  where attempt_id = pg_temp.archive_attempt('old')
), 'live block hides Guardian Past summary');
select pg_temp.archive_as('fem1');
select public.zyra_unblock_user(pg_temp.archive_actor('male1'));
select pg_temp.archive_assert(exists (
  select 1 from public.zyra_my_ended_journeys() where attempt_id = pg_temp.archive_attempt('old')
), 'unblocking restores already-ended Journey');
select pg_temp.archive_as('male1');
select public.zyra_mark_journey_messages_read((select id from archive_conversations where label = 'old'));
select pg_temp.archive_assert(exists (
  select 1 from public.zyra_guardian_activity() where activity_type = 'review_answered' and detail = 'continue'
) and exists (
  select 1 from public.zyra_journey_busy_flags(array[pg_temp.archive_match('old')])
), 'unblock restores existing Family Review activity and counterpart busy flag');
select pg_temp.archive_as('gmain');
select pg_temp.archive_assert(exists (
  select 1 from public.zyra_attempt_summary_for_guardian(pg_temp.archive_actor('male1'))
  where attempt_id = pg_temp.archive_attempt('old')
) and not exists (
  select 1 from public.messages where content = 'Synthetic archive message: old'
), 'unblock restores consented four-field summary without Guardian detail');

select pg_temp.archive_as('male2');
select public.zyra_block_user(pg_temp.archive_actor('fem2'));
select pg_temp.archive_assert(not exists (
  select 1 from public.zyra_my_ended_journeys() where attempt_id = pg_temp.archive_attempt('safety')
), 'a block-ended Journey stays hidden while the block exists');
select public.zyra_unblock_user(pg_temp.archive_actor('fem2'));
select pg_temp.archive_assert(exists (
  select 1 from public.zyra_my_ended_journeys()
  where attempt_id = pg_temp.archive_attempt('safety') and end_reason = 'safety_concern'
), 'the blocker can read their own safety reason after unblock');
select pg_temp.archive_as('fem2');
select pg_temp.archive_assert(exists (
  select 1 from public.zyra_my_ended_journeys()
  where attempt_id = pg_temp.archive_attempt('safety') and end_reason = 'prefer_not_to_say'
    and end_note is null and display_name is null
) and not exists (
  select 1 from public.zyra_compatibility_topics(pg_temp.archive_actor('male2'), pg_temp.archive_match('safety'))
), 'unblock restores the safety-ended card without revealing the protected reason, name or Compatibility');
select pg_temp.archive_refuse_removal(pg_temp.archive_attempt('old'), 'nonparticipant cannot remove');
reset role;

-- A new attempt of the old pair stays untouched by both removals of attempt 1.
with restarted as (
  insert into public.journey_attempts(match_id, attempt_number, status, journey_stage, started_at)
  values (pg_temp.archive_match('old'), 2, 'active', 'conversation', clock_timestamp()) returning id
)
insert into archive_attempts select 'restart', id from restarted;
update public.matches set status = 'active', ended_at = null, ended_by = null, end_reason = null, end_note = null
where id = pg_temp.archive_match('old');
insert into public.timelines(match_id, attempt_id)
values (pg_temp.archive_match('old'), pg_temp.archive_attempt('restart'))
on conflict (attempt_id) do nothing;

insert into public.journey_compatibility (
  match_id, attempt_id, seeker_a_revealed, seeker_b_revealed, revealed_at,
  seeker_a_score, seeker_b_score, seeker_a_categories, seeker_b_categories
) values (
  pg_temp.archive_match('old'), pg_temp.archive_attempt('old'), true, true,
  now() - interval '6 months', 60, 75, '{"synthetic":60}', '{"synthetic":75}'
);
insert into public.journey_requests (
  match_id, requested_by, requested_to, status, created_at, expires_at,
  responded_at, attempt_id, closed_reason
) values (
  pg_temp.archive_match('old'), pg_temp.archive_actor('male1'), pg_temp.archive_actor('fem1'),
  'accepted', now(), now() + interval '30 days', now(),
  pg_temp.archive_attempt('restart'), 'accepted'
);

set local role authenticated;
select pg_temp.archive_as('fem1');
insert into public.profile_reports (id, reporter_id, reported_id, reason, source)
values ('94000000-0000-0000-0000-000000000104', pg_temp.archive_actor('fem1'), pg_temp.archive_actor('male1'),
        'other', 'journey');
reset role;
select pg_temp.archive_assert(exists (
  select 1 from public.profile_reports
  where id = '94000000-0000-0000-0000-000000000104' and attempt_id is null
) and (
  select count(*) = 2 from private.report_protected_attempts
  where report_id = '94000000-0000-0000-0000-000000000104'
    and attempt_id in (pg_temp.archive_attempt('old'), pg_temp.archive_attempt('restart'))
), 'a legacy Journey report on a restarted pair protects both the old and active attempt');
update public.profile_reports set status = 'dismissed', reviewed_at = now()
where id = '94000000-0000-0000-0000-000000000104';

set local role authenticated;
select pg_temp.archive_as('male1');
select pg_temp.archive_refuse_removal(pg_temp.archive_attempt('restart'), 'participant cannot remove an active restarted attempt');
select public.zyra_remove_ended_journey(pg_temp.archive_attempt('old'));
select public.zyra_remove_ended_journey(pg_temp.archive_attempt('old'));
select pg_temp.archive_assert(not exists (
  select 1 from public.zyra_my_ended_journeys() where attempt_id = pg_temp.archive_attempt('old')
) and not exists (
  select 1 from public.timelines where attempt_id = pg_temp.archive_attempt('old')
), 'first removal hides only the caller archive, including Timeline; retry stays removed');
select pg_temp.archive_assert(not exists (
  select 1 from public.zyra_guardian_activity() where activity_type = 'review_answered'
), 'first removal also hides Family Review activity for its exact attempt');
select pg_temp.archive_as('gmain');
select pg_temp.archive_assert(not exists (
  select 1 from public.zyra_attempt_summary_for_guardian(pg_temp.archive_actor('male1'))
  where attempt_id = pg_temp.archive_attempt('old')
), 'first removal hides that side Guardian Past summary');
select pg_temp.archive_as('gb');
select pg_temp.archive_assert(exists (
  select 1 from public.zyra_attempt_summary_for_guardian(pg_temp.archive_actor('fem1'))
  where attempt_id = pg_temp.archive_attempt('old')
), 'first removal leaves the other side Guardian Past summary');
select pg_temp.archive_as('fem1');
select pg_temp.archive_assert(exists (
  select 1 from public.zyra_my_ended_journeys() where attempt_id = pg_temp.archive_attempt('old')
) and exists (
  select 1 from public.messages where content = 'Synthetic archive message: old'
), 'first removal leaves other Seeker archive and messages');
select public.zyra_remove_ended_journey(pg_temp.archive_attempt('old'));
select pg_temp.archive_assert((select count(*) = 12
  from public.zyra_compatibility_topics(pg_temp.archive_actor('male1'), pg_temp.archive_match('old'))
), 'accepted active restart still has access based on its earlier mutual consent');
reset role;
select pg_temp.archive_assert(not exists (
  select 1 from public.timelines where attempt_id = pg_temp.archive_attempt('old')
) and not exists (
  select 1 from public.messages where content = 'Synthetic archive message: old'
) and exists (
  select 1 from public.journey_attempts a join public.timelines t on t.attempt_id = a.id
  where a.id = pg_temp.archive_attempt('restart') and a.status = 'active'
), 'second removal purges exact-attempt Timeline and messages, preserving active attempt and Timeline');
select pg_temp.archive_assert(not exists (
  select 1 from public.journey_attempts where id = pg_temp.archive_attempt('old')
) and not exists (
  select 1 from public.journey_compatibility where attempt_id = pg_temp.archive_attempt('old')
) and exists (
  select 1 from private.zyra_journey_reveal_tombstones t
  where t.attempt_id = pg_temp.archive_attempt('old')
    and t.match_id = pg_temp.archive_match('old')
    and t.consent_for_attempt_id = pg_temp.archive_attempt('restart')
    and t.started_at is not null and t.ended_at is not null and t.revealed_at is not null
    and (select count(*) from jsonb_object_keys(to_jsonb(t))) = 7
), 'the consent tombstone stores only IDs and dates while all original reveal content is gone');

-- A legacy report with no recorded attempt protects every attempt of its
-- pair. Reports raised from a Journey with an exact ID protect only that attempt.
insert into public.journey_attempts(match_id, attempt_number, status, journey_stage, started_at, ended_at, end_reason)
values (pg_temp.archive_match('report'), 2, 'ended', 'conversation', now() - interval '4 months',
  now() - interval '3 months', 'not_compatible');
insert into archive_attempts
select 'report_newer', id from public.journey_attempts
where match_id = pg_temp.archive_match('report') and attempt_number = 2;
insert into public.timelines(match_id, attempt_id)
values (pg_temp.archive_match('report'), pg_temp.archive_attempt('report_newer'));
update public.matches set ended_at = now() - interval '3 months' where id = pg_temp.archive_match('report');

set local role authenticated;
select pg_temp.archive_as('fem4');
insert into public.profile_reports(id, reporter_id, reported_id, reason, source)
values ('94000000-0000-0000-0000-000000000101', pg_temp.archive_actor('fem4'), pg_temp.archive_actor('male1'),
        'other', 'profile');
select pg_temp.archive_as('male1');
insert into public.profile_reports(id, reporter_id, reported_id, reason, source, attempt_id)
values ('94000000-0000-0000-0000-000000000102', pg_temp.archive_actor('male1'), pg_temp.archive_actor('fem4'),
        'other', 'journey', pg_temp.archive_attempt('report_newer'));
do $$
begin
  begin
    insert into public.profile_reports(reporter_id, reported_id, reason, source, attempt_id)
    values (pg_temp.archive_actor('male1'), pg_temp.archive_actor('fem4'), 'other', 'journey',
      pg_temp.archive_attempt('old'));
    raise exception 'line 94 archive FAIL: reporter could name an unrelated attempt';
  exception when insufficient_privilege then
    if sqlerrm <> 'report_attempt_not_available' then raise; end if;
    raise notice 'line 94 archive PASS: a Journey report cannot name an unrelated attempt';
  end;
end;
$$;
reset role;

select pg_temp.archive_assert(
  (select count(*) = 2 from private.report_protected_attempts
   where report_id = '94000000-0000-0000-0000-000000000101'
     and attempt_id in (pg_temp.archive_attempt('report'), pg_temp.archive_attempt('report_newer')))
  and (select count(*) = 1 and bool_and(attempt_id = pg_temp.archive_attempt('report_newer'))
       from private.report_protected_attempts where report_id = '94000000-0000-0000-0000-000000000102'),
  'reverse-direction legacy report protects both attempts and an exact report protects only its attempt');

-- The null-ID report is still open when another attempt arrives.
insert into public.journey_attempts(match_id, attempt_number, status)
values (pg_temp.archive_match('report'), 3, 'potential');
select pg_temp.archive_assert(exists (
  select 1 from private.report_protected_attempts p
  join public.journey_attempts a on a.id = p.attempt_id
  where p.report_id = '94000000-0000-0000-0000-000000000101' and a.attempt_number = 3
), 'a subsequent attempt of the legacy reported pair gets its own protection link');
delete from public.journey_attempts
where match_id = pg_temp.archive_match('report') and attempt_number = 3;

set local role authenticated;
select pg_temp.archive_as('male1');
select public.zyra_remove_ended_journey(pg_temp.archive_attempt('report_newer'));
select pg_temp.archive_as('fem4');
select public.zyra_remove_ended_journey(pg_temp.archive_attempt('report_newer'));
reset role;
select pg_temp.archive_assert(exists (
  select 1 from public.timelines where attempt_id = pg_temp.archive_attempt('report_newer')
), 'the exact open report retains removed archive data');
update public.profile_reports set status = 'dismissed', reviewed_at = now()
where id = '94000000-0000-0000-0000-000000000102';
select private.zyra_purge_closed_ended_journeys();
select pg_temp.archive_assert(exists (
  select 1 from public.journey_attempts where id = pg_temp.archive_attempt('report_newer')
), 'the legacy report alone still protects the newer attempt after the exact report closes');
update public.profile_reports set status = 'dismissed', reviewed_at = now()
where id = '94000000-0000-0000-0000-000000000101';
select private.zyra_purge_closed_ended_journeys();
update public.matches set end_note = 'Synthetic later update' where id = pg_temp.archive_match('report');
select pg_temp.archive_assert(not exists (
  select 1 from public.journey_attempts where id = pg_temp.archive_attempt('report_newer')
) and not exists (
  select 1 from private.zyra_journey_reveal_tombstones where attempt_id = pg_temp.archive_attempt('report_newer')
) and exists (
  select 1 from public.profile_reports
  where id = '94000000-0000-0000-0000-000000000102'
    and attempt_id = pg_temp.archive_attempt('report_newer')
), 'after both reports close purge deletes the entire attempt and its content but keeps the report audit ID');
set local role authenticated;
select pg_temp.archive_as('fem4');
select pg_temp.archive_assert(exists (
  select 1 from public.zyra_my_ended_journeys() where attempt_id = pg_temp.archive_attempt('report')
) and not exists (
  select 1 from public.zyra_match_ending(pg_temp.archive_match('report'))
) and not exists (
  select 1 from public.matches where id = pg_temp.archive_match('report')
), 'purging a newer attempt leaves the older card but never exposes the stale match projection');
reset role;


insert into public.protection_holds(match_id, restricted_id, protected_id, hold_type, appealable)
values (pg_temp.archive_match('hold'), pg_temp.archive_actor('male1'), pg_temp.archive_actor('fem3'), 'moderation', false);
set local role authenticated;
select pg_temp.archive_as('fem4');
insert into public.profile_reports(id, reporter_id, reported_id, reason, source)
values ('94000000-0000-0000-0000-000000000103', pg_temp.archive_actor('fem4'), pg_temp.archive_actor('male1'),
        'other', 'journey');
reset role;
select pg_temp.archive_assert(exists (
  select 1 from public.profile_reports where id = '94000000-0000-0000-0000-000000000103'
    and attempt_id = pg_temp.archive_attempt('report')
), 'the existing Journey filing path fills an unambiguous attempt ID');
-- Keep the target active and profile-complete for the existing Q95 photo
-- rule, but exclude them from Browse so the remaining access must be archive-only.
update public.profiles set onboarding_complete = false
where id = pg_temp.archive_actor('male1');
set local role authenticated;
select pg_temp.archive_as('male1');
select set_config('storage.operation', 'storage.object.upload', true);
insert into storage.objects(bucket_id, name, owner_id)
values ('profile-photos', auth.uid()::text || '/archive-fixture.jpg', auth.uid()::text);
insert into public.profile_photos(user_id, storage_path)
values (auth.uid(), auth.uid()::text || '/archive-fixture.jpg');
select public.zyra_remove_ended_journey(pg_temp.archive_attempt('hold'));
select public.zyra_remove_ended_journey(pg_temp.archive_attempt('report'));
select pg_temp.archive_as('fem3');
select pg_temp.archive_assert(
  public.zyra_can_view_profile(pg_temp.archive_actor('male1'))
  and exists (select 1 from public.profile_photos
    where storage_path = pg_temp.archive_actor('male1')::text || '/archive-fixture.jpg')
  and public.zyra_can_read_photo_object(pg_temp.archive_actor('male1')::text || '/archive-fixture.jpg'),
  'first removal preserves the other Seeker’s archive Bio and owned photo outside Browse'
);
select public.zyra_remove_ended_journey(pg_temp.archive_attempt('hold'));
select pg_temp.archive_assert(
  not public.zyra_can_view_profile(pg_temp.archive_actor('male1'))
  and not public.zyra_can_read_photo_object(pg_temp.archive_actor('male1')::text || '/archive-fixture.jpg'),
  'second removal closes the remaining archive Bio and photo read'
);
select pg_temp.archive_assert(not exists (
  select 1 from public.zyra_my_ended_journeys() where attempt_id = pg_temp.archive_attempt('hold')
), 'protected material remains hidden from both after both removals');
select pg_temp.archive_as('fem4');
select public.zyra_remove_ended_journey(pg_temp.archive_attempt('report'));
reset role;
select pg_temp.archive_assert((select count(*) = 2 from public.timelines
  where attempt_id in (pg_temp.archive_attempt('hold'), pg_temp.archive_attempt('report'))),
  'active hold and open report each preserve the hidden Timeline');
update public.protection_holds set released_at = now(), released_by = pg_temp.archive_actor('gmain'), release_reason = 'synthetic release'
where match_id = pg_temp.archive_match('hold');
update public.profile_reports set status = 'dismissed', reviewed_at = now() where source = 'journey';
select private.zyra_purge_closed_ended_journeys();
select pg_temp.archive_assert(not exists (
  select 1 from public.timelines where attempt_id in (pg_temp.archive_attempt('hold'), pg_temp.archive_attempt('report'))
) and exists (
  select 1 from public.protection_holds where match_id = pg_temp.archive_match('hold') and released_at is not null
) and exists (
  select 1 from public.profile_reports where source = 'journey' and status = 'dismissed'
), 'cleanup purges after release and close while keeping hold and report records');
update public.matches set end_note = null where id = pg_temp.archive_match('hold');
select pg_temp.archive_assert(not exists (
  select 1 from public.timelines where attempt_id = pg_temp.archive_attempt('hold')
), 'later Match updates cannot recreate a purged Timeline');

select pg_temp.archive_assert(not has_function_privilege('anon', 'public.zyra_my_ended_journeys()', 'execute')
  and not has_function_privilege('authenticated', 'private.zyra_remove_ended_journey_for(uuid,uuid)', 'execute')
  and not has_table_privilege('authenticated', 'private.zyra_ended_journey_removals', 'select')
  and not has_table_privilege('authenticated', 'private.report_protected_attempts', 'select')
  and not has_table_privilege('authenticated', 'private.zyra_journey_reveal_tombstones', 'select'),
  'anonymous archive and direct removal state access are refused');
rollback;
