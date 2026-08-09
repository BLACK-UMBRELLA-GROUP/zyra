-- ═══════════════════════════════════════════════════════════════════════
-- ZYRA — visibility & Journey regression suite
--
-- Written 2026-08-08. Every assertion here corresponds to a defect that
-- was REAL in this database at some point today, not a hypothetical.
-- Run it after any change to zyra_can_view_profile, the participant
-- views, the Journey RPCs, wali_links, or any policy naming is_main.
--
-- HOW TO RUN
--   Supabase SQL editor, or:  psql "$DATABASE_URL" -f zyra_guard_suite.sql
-- It builds its own scenario from seeded @zyra.test accounts, asserts,
-- and tears everything down. Safe to run repeatedly. It writes nothing
-- permanent and leaves `matches` as it found it.
--
-- WHY THIS FILE EXISTS: on 2026-08-08 a review claimed in writing that
-- Additional Guardians were "genuinely closed" from counterpart
-- visibility. Measurement said otherwise — they could see the other
-- family's Seeker and both of its Guardians. The claim was made from the
-- intended model rather than the running system. A suite is the only
-- thing that stops that happening twice.
-- ═══════════════════════════════════════════════════════════════════════

drop table if exists zyra_guard_results;
create table zyra_guard_results (
  n int, area text, check_name text, got text, expected text
);
-- RLS on, no policy, no grant. `public` is PostgREST-exposed, so a results
-- table left here with RLS off is readable by anon over the REST API — the
-- security advisor flagged exactly that on 2026-08-08. The DO block runs as
-- the table owner and bypasses RLS, so no grant is needed; the old
-- `grant insert ... to authenticated` was left over from a `set role` the
-- suite no longer does. Same change made to zyra_journey_suite.sql.
alter table zyra_guard_results enable row level security;
revoke all on zyra_guard_results from anon, authenticated;

do $$
declare
  -- Seeded @zyra.test actors. Swap these if the seed set changes.
  A    uuid := '9805470a-d9e6-4e7f-aff1-933031e4aaed'; -- male Seeker, has a Main Guardian
  B    uuid := '2e1bcfed-b1f5-4e91-a6a1-c81ab8bf6802'; -- female Seeker
  GA   uuid := '058050b9-f8d4-4449-920e-8abf7a4a0325'; -- MAIN Guardian of A
  GA2  uuid := '6493a6e6-6fc7-4d7a-b1b5-58b637c08647'; -- ADDITIONAL Guardian of A
  GB   uuid := '565a0208-f968-4680-8d68-f1d1165c2679'; -- MAIN Guardian of B
  GB2  uuid := 'cda84c79-cb3e-4c9e-8572-399a1b5ee640'; -- ADDITIONAL Guardian of B
  OUTS uuid := '6c84767c-64df-4d24-b17d-c3239848d68e'; -- unrelated Seeker
  v_a uuid; v_b uuid; v_m uuid; v_conv uuid; v_tl uuid;
  n int; c record; r record;

begin
  v_a := least(A,B); v_b := greatest(A,B);

  -- ── scenario ────────────────────────────────────────────────────────
  insert into wali_links (seeker_id, wali_id, status, is_main) values (B, GB, 'active', true);
  insert into wali_links (seeker_id, wali_id, status, is_main) values (B, GB2,'active', false);
  insert into wali_links (seeker_id, wali_id, status, is_main) values (A, GA2,'active', false);
  insert into matches (seeker_a_id, seeker_b_id, status, journey_stage)
    values (v_a, v_b, 'active', 'phase_1') returning id into v_m;
  update journey_attempts set status='active', journey_stage='phase_1' where match_id=v_m;
  insert into conversations (match_id, status) values (v_m,'active') returning id into v_conv;
  insert into messages (conversation_id, sender_id, content) values (v_conv, A, 'suite');
  insert into timelines (match_id) values (v_m) returning id into v_tl;
  insert into timeline_milestones (timeline_id, milestone_type) values (v_tl,'match_created');
  insert into journey_family_answers (match_id, direction, question_id, answerer_id, answer_text)
    values (v_m, 'seeker_to_wali', 'q1', A, 'suite');

  -- ══ AREA 1 · clause 3 must never grant a Guardian sight of the other
  --    family. All seven were TRUE before 2026-08-08.
  perform set_config('request.jwt.claims', json_build_object('sub', GA)::text, true);
  insert into zyra_guard_results values (1,'clause 3','MAIN G(A) -> counterpart Seeker (opposite gender)', zyra_can_view_profile(B)::text,  'false');
  insert into zyra_guard_results values (2,'clause 3','MAIN G(A) -> counterpart MAIN Guardian',            zyra_can_view_profile(GB)::text, 'false');
  insert into zyra_guard_results values (3,'clause 3','MAIN G(A) -> counterpart ADDITIONAL Guardian',      zyra_can_view_profile(GB2)::text,'false');
  insert into zyra_guard_results values (4,'clause 3','MAIN G(A) -> own co-Guardian',                      zyra_can_view_profile(GA2)::text,'false');
  perform set_config('request.jwt.claims', json_build_object('sub', GA2)::text, true);
  insert into zyra_guard_results values (5,'clause 3','ADDL G(A) -> counterpart Seeker',                   zyra_can_view_profile(B)::text,  'false');
  insert into zyra_guard_results values (6,'clause 3','ADDL G(A) -> counterpart MAIN Guardian',            zyra_can_view_profile(GB)::text, 'false');
  insert into zyra_guard_results values (7,'clause 3','ADDL G(A) -> counterpart ADDITIONAL Guardian',      zyra_can_view_profile(GB2)::text,'false');

  -- knock-ons: both delegate to can_view and must tighten with it
  perform set_config('request.jwt.claims', json_build_object('sub', GA)::text, true);
  insert into zyra_guard_results values (8,'clause 3','ages_for() on counterpart as Guardian', (select count(*) from ages_for(array[B]))::text, '0');
  insert into zyra_guard_results values (9,'clause 3','photo object of counterpart as Guardian', zyra_can_read_photo_object(B::text||'/x.jpg')::text, 'false');

  -- ══ AREA 2 · legitimate access that must SURVIVE. A suite that only
  --    checks denials passes trivially on a broken product.
  insert into zyra_guard_results values (10,'clause 2','MAIN G(A) -> own ward',   zyra_can_view_profile(A)::text, 'true');
  perform set_config('request.jwt.claims', json_build_object('sub', GA2)::text, true);
  insert into zyra_guard_results values (11,'clause 2','ADDL G(A) -> own ward',   zyra_can_view_profile(A)::text, 'true');
  perform set_config('request.jwt.claims', json_build_object('sub', A)::text, true);
  insert into zyra_guard_results values (12,'clause 2','Seeker -> own Guardian',  zyra_can_view_profile(GA)::text,'true');
  insert into zyra_guard_results values (13,'clause 3','Seeker -> counterpart Seeker', zyra_can_view_profile(B)::text, 'true');

  -- the regression that a naive status guard would cause: clause 4 needs
  -- is_active, so clause 3 is the ONLY thing keeping a paused counterpart
  -- visible in Potential Journeys.
  update profiles set is_active=false where id=B;
  insert into zyra_guard_results values (14,'clause 3','Seeker -> PAUSED counterpart still visible', zyra_can_view_profile(B)::text, 'true');
  update profiles set is_active=true where id=B;

  -- ══ AREA 3 · block guards. Attempt-level, not viewer-level:
  --    zyra_block_exists() compares auth.uid() to the target, which
  --    catches the two Seekers and misses all four Guardians.
  insert into profile_blocks (blocker_id, blocked_id) values (A,B);
  insert into zyra_guard_results values (15,'block','blocker -> blocked',  zyra_can_view_profile(B)::text, 'false');
  perform set_config('request.jwt.claims', json_build_object('sub', B)::text, true);
  insert into zyra_guard_results values (16,'block','blocked -> blocker',  zyra_can_view_profile(A)::text, 'false');
  delete from profile_blocks where blocker_id=A and blocked_id=B;

  -- ══ AREA 4 · is_main is a privilege boundary, not a label.
  perform set_config('role','authenticated',true);
  perform set_config('request.jwt.claims', json_build_object('sub', GA)::text, true);
  select count(*) into n from conversations         where id=v_conv;              insert into zyra_guard_results values (17,'is_main','MAIN G -> conversation row', n::text,'1');
  select count(*) into n from messages              where conversation_id=v_conv; insert into zyra_guard_results values (18,'is_main','MAIN G -> messages',         n::text,'1');
  select count(*) into n from timelines             where id=v_tl;                insert into zyra_guard_results values (19,'is_main','MAIN G -> timeline',         n::text,'1');
  select count(*) into n from timeline_milestones   where timeline_id=v_tl;       insert into zyra_guard_results values (20,'is_main','MAIN G -> milestones',       n::text,'1');
  select count(*) into n from journey_family_answers where match_id=v_m;          insert into zyra_guard_results values (21,'is_main','MAIN G -> family answers',   n::text,'1');

  perform set_config('request.jwt.claims', json_build_object('sub', GA2)::text, true);
  select count(*) into n from conversations         where id=v_conv;              insert into zyra_guard_results values (22,'is_main','ADDL G -> conversation row', n::text,'0');
  select count(*) into n from messages              where conversation_id=v_conv; insert into zyra_guard_results values (23,'is_main','ADDL G -> messages',         n::text,'0');
  select count(*) into n from timelines             where id=v_tl;                insert into zyra_guard_results values (24,'is_main','ADDL G -> timeline',         n::text,'0');
  select count(*) into n from timeline_milestones   where timeline_id=v_tl;       insert into zyra_guard_results values (25,'is_main','ADDL G -> milestones',       n::text,'0');
  select count(*) into n from journey_family_answers where match_id=v_m;          insert into zyra_guard_results values (26,'is_main','ADDL G -> family answers',   n::text,'0');

  perform set_config('request.jwt.claims', json_build_object('sub', A)::text, true);
  select count(*) into n from messages              where conversation_id=v_conv; insert into zyra_guard_results values (27,'is_main','SEEKER -> own messages unaffected', n::text,'1');
  select count(*) into n from journey_family_answers where match_id=v_m;          insert into zyra_guard_results values (28,'is_main','SEEKER -> family answers unaffected', n::text,'1');
  perform set_config('role','postgres',true);

  -- ══ AREA 5 · the counterpart card is the ONLY Guardian route to the
  --    other family, and it is Main-only.
  perform set_config('request.jwt.claims', json_build_object('sub', GA)::text, true);
  select * into c from zyra_counterpart_card(v_m);
  insert into zyra_guard_results values (29,'card','MAIN G gets counterpart first name', (c.counterpart_first_name is not null)::text, 'true');
  insert into zyra_guard_results values (30,'card','MAIN G gets other MAIN Guardian name', (c.guardian_first_name is not null)::text, 'true');
  insert into zyra_guard_results values (31,'card','contact stays withheld', coalesce(c.guardian_contact,'NULL'), 'NULL');

  perform set_config('request.jwt.claims', json_build_object('sub', GA2)::text, true);
  select count(*) into n from zyra_counterpart_card(v_m);
  insert into zyra_guard_results values (32,'card','ADDITIONAL Guardian gets no card', n::text, '0');
  perform set_config('request.jwt.claims', json_build_object('sub', A)::text, true);
  select count(*) into n from zyra_counterpart_card(v_m);
  insert into zyra_guard_results values (33,'card','Seeker gets no card (Unlock+ is the paid route)', n::text, '0');
  perform set_config('request.jwt.claims', json_build_object('sub', OUTS)::text, true);
  select count(*) into n from zyra_counterpart_card(v_m);
  insert into zyra_guard_results values (34,'card','unrelated user gets no card', n::text, '0');

  perform set_config('request.jwt.claims', json_build_object('sub', GA)::text, true);
  update matches set status='potential' where id=v_m;
  select count(*) into n from zyra_counterpart_card(v_m);
  insert into zyra_guard_results values (35,'card','no card before the Journey starts', n::text, '0');
  update matches set status='active' where id=v_m;

  insert into profile_blocks (blocker_id, blocked_id) values (A,B);
  select count(*) into n from zyra_counterpart_card(v_m);
  insert into zyra_guard_results values (36,'card','no card once a block stands', n::text, '0');
  delete from profile_blocks where blocker_id=A and blocked_id=B;

  -- ══ AREA 6 · Journey stage machine. The three ungated transitions were
  --    a silent no-op until 2026-08-08 — RLS discarded the client write,
  --    so no Journey could ever leave compatibility_reveal.
  update matches set journey_stage='compatibility_reveal' where id=v_m;
  insert into journey_compatibility (match_id, seeker_a_revealed, seeker_b_revealed) values (v_m,false,false);
  perform set_config('request.jwt.claims', json_build_object('sub', A)::text, true);
  select * into r from zyra_advance_stage(v_m,'compatibility_reveal');
  insert into zyra_guard_results values (37,'stage','blocked until both reveal', r.reason, 'waiting_for_reveal');
  update journey_compatibility set seeker_a_revealed=true, seeker_b_revealed=true where match_id=v_m;
  select * into r from zyra_advance_stage(v_m,'compatibility_reveal');
  insert into zyra_guard_results values (38,'stage','blocked until both continue', r.reason, 'waiting_for_continue');
  perform set_config('request.jwt.claims', json_build_object('sub', B)::text, true);
  select * into r from zyra_advance_stage(v_m,'compatibility_reveal');
  insert into zyra_guard_results values (39,'stage','both continued -> advances', r.advanced||'/'||r.stage, 'true/salam_exchange');
  insert into zyra_guard_results values (40,'stage','attempt row kept in step',
    (select ja.journey_stage from journey_attempts ja where ja.match_id=v_m), 'salam_exchange');
  -- The stage must ACTUALLY be phase_1 for this assertion to reach the
  -- gated-transition branch. First draft of this suite asserted it right
  -- after check 39 had already advanced to salam_exchange, so it hit the
  -- stale-stage guard instead and reported a false failure — the suite
  -- catching its own bug on first run, which is the argument for running
  -- one before trusting it.
  update matches set journey_stage='phase_1' where id=v_m;
  begin
    select * into r from zyra_advance_stage(v_m,'phase_1');
    insert into zyra_guard_results values (41,'stage','Family-Review transition refused','NOT REFUSED: '||r.reason,'gated_transition');
  exception when others then
    insert into zyra_guard_results values (42,'stage','Family-Review transition refused', sqlerrm, 'gated_transition');
  end;

  -- and the stale-client path as its own assertion, since it is real
  update matches set journey_stage='salam_exchange' where id=v_m;
  select * into r from zyra_advance_stage(v_m,'phase_1');
  insert into zyra_guard_results values (43,'stage','stale from_stage reports stage_moved', r.reason, 'stage_moved');
  perform set_config('request.jwt.claims', json_build_object('sub', OUTS)::text, true);
  begin
    select * into r from zyra_advance_stage(v_m,'salam_exchange');
    insert into zyra_guard_results values (44,'stage','non-party refused','NOT REFUSED','not_a_party');
  exception when others then
    insert into zyra_guard_results values (45,'stage','non-party refused', sqlerrm, 'not_a_party');
  end;

  -- ══ AREA 7 · enumeration surfaces and grants.
  begin
    perform ages_for(array(select id from profiles limit 51));
    insert into zyra_guard_results values (46,'grants','51-id batch refused','NOT REFUSED','ages_for_batch_too_large');
  exception when others then
    insert into zyra_guard_results values (47,'grants','51-id batch refused', sqlerrm, 'ages_for_batch_too_large');
  end;
  insert into zyra_guard_results values (48,'grants','zyra_attempt_participants NOT client-callable (no caller check inside)',
    has_function_privilege('authenticated','public.zyra_attempt_participants(uuid)','EXECUTE')::text, 'false');
  insert into zyra_guard_results values (49,'grants','counterpart card denied to anon',
    has_function_privilege('anon','public.zyra_counterpart_card(uuid)','EXECUTE')::text, 'false');
  insert into zyra_guard_results values (50,'grants','advance_stage denied to anon',
    has_function_privilege('anon','public.zyra_advance_stage(uuid,text)','EXECUTE')::text, 'false');
  insert into zyra_guard_results values (51,'grants','journey_stage_checkpoints has no client INSERT',
    has_table_privilege('authenticated','public.journey_stage_checkpoints','INSERT')::text, 'false');
  insert into zyra_guard_results values (52,'grants','profile_blocks has no client INSERT (blocking is an RPC)',
    has_table_privilege('authenticated','public.profile_blocks','INSERT')::text, 'false');
  insert into zyra_guard_results values (53,'grants','matches.end_reason not client-readable',
    has_column_privilege('authenticated','public.matches','end_reason','SELECT')::text, 'false');

  -- ── teardown ────────────────────────────────────────────────────────
  delete from matches where id=v_m;
  delete from wali_links where (seeker_id=B and wali_id in (GB,GB2)) or (seeker_id=A and wali_id=GA2);
  insert into zyra_guard_results values (54,'teardown','no matches left behind', (select count(*) from matches)::text, '0');
  insert into zyra_guard_results values (55,'teardown','no stage checkpoints left behind', (select count(*) from journey_stage_checkpoints)::text, '0');
end $$;

-- ── report ─────────────────────────────────────────────────────────────
select area,
       count(*)                                              as checks,
       count(*) filter (where got = expected)                as passed,
       count(*) filter (where got is distinct from expected) as failed
from zyra_guard_results
group by area
union all
select 'TOTAL', count(*), count(*) filter (where got = expected),
       count(*) filter (where got is distinct from expected)
from zyra_guard_results
order by area = 'TOTAL', area;

-- Failures in detail. Empty result = suite green.
select n, area, check_name, got, expected
from zyra_guard_results
where got is distinct from expected
order by n;

-- drop table zyra_guard_results;   -- uncomment to clean up
