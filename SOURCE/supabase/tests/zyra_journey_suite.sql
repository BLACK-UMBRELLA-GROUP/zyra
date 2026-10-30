-- ═══════════════════════════════════════════════════════════════════════
-- ZYRA — Journey lifecycle regression suite
--
-- SERVER 0 V2 (30 Oct 2026): Journey Pause is retired (DR-ZYRA-274).
-- Pause-only sections D/J/L/M, I assertions 60-62, K76 and N98 moved to
-- /Users/shakeelahmad/_to_delete/SERVER0_V2_2026-10-30/.
-- Remaining lifecycle, privacy, capacity and busy-signal checks stay active.
-- Family Review pause/reopen is a separate review state and remains covered.
--
-- Companion to zyra_guard_suite.sql, which covers visibility and privacy.
-- This one covers the LIFECYCLE: match creation, promotion, the Family
-- Review Period and endings — the retained OA-ZYRA-156
-- stage 4e steps 2-6 touched on 2026-08-08.
--
-- HOW TO RUN
--   Supabase SQL editor, or:  psql "$DATABASE_URL" -f zyra_journey_suite.sql
-- Builds its own scenario from seeded @zyra.test accounts, asserts, tears
-- down. Safe to run repeatedly. Leaves `matches` as it found it.
--
-- RUN THIS BEFORE STEP 7. Step 7 drops match_id from thirteen tables. Every
-- assertion below exercises a path that step 7 rewrites, so a green run
-- before and after is the difference between a migration you verified and
-- one you hoped about.
--
-- Assertion numbers are stable; gaps identify retired Pause checks.
-- Read TOTAL rather than the highest assertion number.
-- ═══════════════════════════════════════════════════════════════════════

\set ON_ERROR_STOP on

drop table if exists zyra_journey_results;
create table zyra_journey_results (n int, area text, check_name text, got text, expected text);
-- RLS on, no policy, no grant. `public` is PostgREST-exposed, so a results
-- table left here with RLS off is readable by anon over the REST API — the
-- security advisor flagged exactly that on 2026-08-08 (along with three
-- other scratch tables this session had abandoned; all four dropped).
-- The DO block below runs as the table owner and bypasses RLS, so nothing
-- in the suite needs a grant. The old `grant insert ... to authenticated`
-- was left over from a `set role authenticated` the suite no longer does.
alter table zyra_journey_results enable row level security;
-- RLS alone already returns zero rows to anon, but Supabase's default
-- `grant select on all tables in public` leaves the privilege sitting
-- there. Take it away too.
revoke all on zyra_journey_results from anon, authenticated;

do $$
declare
  -- Seeded @zyra.test actors. Swap if the seed set changes.
  male1  uuid := '9805470a-d9e6-4e7f-aff1-933031e4aaed';
  male2  uuid := '12421707-fe06-4604-94bb-771ccd8ae30a';
  fem1   uuid := '2e1bcfed-b1f5-4e91-a6a1-c81ab8bf6802';
  fem2   uuid := '6c84767c-64df-4d24-b17d-c3239848d68e';
  gmain  uuid := '058050b9-f8d4-4449-920e-8abf7a4a0325';  -- MAIN of male1
  -- MAIN of fem1, created here. MUST NOT already guard male1: since
  -- Tier-1 (DR-ZYRA-123) a shared Guardian makes the pair unmatchable,
  -- which would invalidate the matching premise. Assertion 0 enforces it.
  gmain2 uuid := '257d6ebc-ccd0-4c16-a878-3c416ad7b530';
  gadd   uuid := '6493a6e6-6fc7-4d7a-b1b5-58b637c08647';  -- ADDITIONAL of male1
  -- Section K needs male1 matchable with FOUR women. fem3/fem4 chosen
  -- from the seed the same way as the others (female, @zyra.test,
  -- onboarding complete, no Guardian overlap with male1, no matches).
  fem3   uuid := '01c7caa4-56c1-481b-8557-de901d3e7d99';  -- Rahma
  fem4   uuid := '03752c3d-0396-4f38-b234-84d93b724b00';  -- Khadija
  mid uuid; midb uuid; midc uuid; midd uuid;
  att uuid; conv uuid; tl uuid; rev uuid; card record;
  -- Section K pins Premium (cap 3) and restores the prior subscription.
  -- Earlier Basic checks use the explicitly seeded Basic fixture plan.
  base_plan text; base_sub_status text;
  -- SCOPED 2026-08-10. Checks 57/58 used to assert the WHOLE table was
  -- empty, so the suite reported a failure whenever any unrelated row
  -- existed — including a developer's own test Journey. That measured the
  -- database, not the suite. Baselines make them assert what they mean:
  -- this run left nothing behind.
  base_matches int; base_reviews int;
  base_onboarding jsonb;
  fixture_main_links uuid[];
begin
  select count(*) into base_matches from matches;
  select count(*) into base_reviews from journey_family_reviews;
  select jsonb_object_agg(id::text, onboarding_complete)
    into base_onboarding
    from profiles
   where id = any(array[male1,male2,fem1,fem2,fem3,fem4]);
  -- These are synthetic @zyra.test actors. Keep the suite independent from
  -- whether a developer has reset their onboarding flag between test runs.
  update profiles
     set onboarding_complete = true
   where id = any(array[male1,male2,fem1,fem2,fem3,fem4]);
  -- The Main-Guardian hold now guards activation itself. Give every test
  -- Seeker a real, independent Main before any promotion. Capture only links
  -- created here so teardown preserves male1's pre-existing fixture Main.
  with inserted as (
    insert into wali_links (seeker_id, wali_id, status, is_main) values
      (male2, '565a0208-f968-4680-8d68-f1d1165c2679', 'active', true),
      (fem1, gmain2, 'active', true),
      (fem2, 'cda84c79-cb3e-4c9e-8572-399a1b5ee640', 'active', true),
      (fem3, gmain2, 'active', true),
      (fem4, gmain2, 'active', true)
    returning id
  )
  select array_agg(id) into fixture_main_links from inserted;
  delete from likes where (liker_id in (male1,fem1) and liked_id in (male1,fem1));

  -- ══ 0 · the scenario itself must be legal ═══════════════════════════
  -- Twice now a test has picked a "different" Guardian who already
  -- guarded the other party, and the resulting Tier-1 refusal read as a
  -- product defect. Assert the premise before asserting anything else.
  insert into zyra_journey_results values (0,'premise','the two Seekers share no Guardian before section C',
    zyra_can_match(male1,fem1)::text,'true');

  -- ══ A · match creation through the REAL path (step 3) ═══════════════
  -- Two mutual Likes, not a hand-built row. The trigger chain is the
  -- thing under test: it used to rely on matches_create_first_attempt
  -- being AFTER INSERT so the downstream BEFORE triggers would find the
  -- attempt. Now explicit.
  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  insert into likes (liker_id, liked_id) values (male1, fem1);
  insert into zyra_journey_results values (1,'create','one-sided Like creates no match',
    (select count(*) from matches where seeker_a_id=least(male1,fem1) and seeker_b_id=greatest(male1,fem1))::text,'0');
  perform set_config('request.jwt.claims', json_build_object('sub', fem1)::text, true);
  insert into likes (liker_id, liked_id) values (fem1, male1);
  select id into mid from matches where seeker_a_id=least(male1,fem1) and seeker_b_id=greatest(male1,fem1);
  select id into att from journey_attempts where match_id=mid;
  select id into conv from conversations where match_id=mid;
  select id into tl   from timelines     where match_id=mid;
  insert into zyra_journey_results values (2,'create','mutual Like creates match + attempt',(att is not null)::text,'true');
  insert into zyra_journey_results values (3,'create','conversation carries attempt_id',(select (attempt_id=att)::text from conversations where id=conv),'true');
  insert into zyra_journey_results values (4,'create','timeline carries attempt_id',(select (attempt_id=att)::text from timelines where id=tl),'true');
  insert into zyra_journey_results values (5,'create','both parties notified',
    (select count(*) from notifications where related_match_id=mid and type='new_match')::text,'2');
  insert into zyra_journey_results values (6,'create','attempt starts potential',(select status from journey_attempts where id=att),'potential');

  -- ══ B · promote (step 5) and one-per-person (step 6) ════════════════
  -- promote not maintaining journey_attempts is what made the per-person
  -- trigger inert and blocked half of step 4. Assertions 8-10 are that fix.
  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  perform promote_journey_to_active(mid);
  insert into zyra_journey_results values (7,'promote','match active',(select status from matches where id=mid),'active');
  insert into zyra_journey_results values (8,'promote','ATTEMPT active too',(select status from journey_attempts where id=att),'active');
  insert into zyra_journey_results values (9,'promote','attempt stage mirrored (Salam first, DR-183)',(select journey_stage from journey_attempts where id=att),'salam_exchange');
  insert into zyra_journey_results values (10,'promote','attempt started_at set',(select (started_at is not null)::text from journey_attempts where id=att),'true');

  -- audit R7: with ids ordered a < b < c one person could be seeker_a on
  -- one active Journey and seeker_b on another. Both routes must refuse.
  insert into matches (seeker_a_id, seeker_b_id, status)
    values (least(male2,fem1), greatest(male2,fem1),'potential') returning id into midb;
  perform set_config('request.jwt.claims', json_build_object('sub', male2)::text, true);
  begin
    perform promote_journey_to_active(midb);
    insert into zyra_journey_results values (11,'one-per-person','second Active Journey refused','ALLOWED — DEFECT','one_active_journey_limit');
  exception when others then
    insert into zyra_journey_results values (11,'one-per-person','second Active Journey refused', sqlerrm,'one_active_journey_limit');
  end;
  begin
    update matches set status='active' where id=midb;
    insert into zyra_journey_results values (12,'one-per-person','direct UPDATE also refused','ALLOWED — DEFECT','one_active_journey_limit');
  exception when others then
    insert into zyra_journey_results values (12,'one-per-person','direct UPDATE also refused', sqlerrm,'one_active_journey_limit');
  end;
  delete from matches where id=midb;

  -- ══ C · Family Review, keyed on the attempt (step 2) ════════════════
  insert into wali_links (seeker_id, wali_id, status, is_main) values (male1, gadd,'active',false);
  update matches          set journey_stage='phase_1' where id=mid;
  update journey_attempts set journey_stage='phase_1' where id=att;
  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  select open_family_review(mid,'phase_1','phase_2') into rev;
  insert into zyra_journey_results values (13,'review','review keyed on the attempt',
    (select (attempt_id=att)::text from journey_family_reviews where id=rev),'true');
  insert into zyra_journey_results values (14,'review','second open is idempotent',
    (open_family_review(mid,'phase_1','phase_2') = rev)::text,'true');
  perform set_config('request.jwt.claims', json_build_object('sub', gadd)::text, true);
  begin
    perform wali_review_decision(rev,'continue');
    insert into zyra_journey_results values (15,'review','ADDITIONAL Guardian refused','ALLOWED','not an authorised Wali for this Journey');
  exception when others then
    insert into zyra_journey_results values (15,'review','ADDITIONAL Guardian refused', sqlerrm,'not an authorised Wali for this Journey');
  end;
  perform set_config('request.jwt.claims', json_build_object('sub', gmain)::text, true);
  perform wali_review_decision(rev,'continue');
  insert into zyra_journey_results values (16,'review','one of two Mains leaves it pending',
    (select status from journey_family_reviews where id=rev),'pending');
  perform set_config('request.jwt.claims', json_build_object('sub', gmain2)::text, true);
  perform wali_review_decision(rev,'continue');
  insert into zyra_journey_results values (17,'review','both Mains continue it',(select status from journey_family_reviews where id=rev),'continued');
  insert into zyra_journey_results values (18,'review','matches advanced',(select journey_stage from matches where id=mid),'phase_2');
  insert into zyra_journey_results values (19,'review','ATTEMPT advanced too',(select journey_stage from journey_attempts where id=att),'phase_2');

  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  select open_family_review(mid,'phase_2','phase_3') into rev;
  perform set_config('request.jwt.claims', json_build_object('sub', gmain)::text, true);
  perform wali_review_decision(rev,'pause');
  insert into zyra_journey_results values (20,'review','pause holds it',(select status from journey_family_reviews where id=rev),'paused');
  perform reopen_family_review(rev);
  insert into zyra_journey_results values (21,'review','reopen restores pending',(select status from journey_family_reviews where id=rev),'pending');
  insert into zyra_journey_results values (22,'review','reopen clears responses',
    (select count(*) from journey_family_review_responses where review_id=rev)::text,'0');
  update journey_family_reviews set deadline_at = now() - interval '1 hour' where id=rev;
  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  perform resolve_family_review_if_due(mid);
  insert into zyra_journey_results values (23,'review','due review auto-continues',(select status from journey_family_reviews where id=rev),'continued');
  insert into zyra_journey_results values (24,'review','auto-continue moved both copies',
    (select journey_stage from matches where id=mid)||'/'||(select journey_stage from journey_attempts where id=att),'phase_3/phase_3');

  -- ══ E · endings (step 5) ════════════════════════════════════════════
  perform end_journey(mid);
  insert into zyra_journey_results values (30,'end','match and attempt both ended',
    (select status from matches where id=mid)||'/'||(select status from journey_attempts where id=att),'ended/ended');
  insert into zyra_journey_results values (31,'end','ended_by recorded',(select (ended_by=male1)::text from matches where id=mid),'true');
  insert into zyra_journey_results values (32,'end','no reason when none given',(select coalesce(end_reason,'NULL') from matches where id=mid),'NULL');
  insert into zyra_journey_results values (33,'end','conversation closed via attempt_id',(select status from conversations where id=conv),'closed');
  insert into zyra_journey_results values (34,'end','journey_ended milestone via attempt_id',
    (select count(*) from timeline_milestones where timeline_id=tl and milestone_type='journey_ended')::text,'1');
  -- Option B: both ending kinds notify identically, and only the other party.
  insert into zyra_journey_results values (35,'end','other party notified, ender not',
    (select count(*) from notifications where related_match_id=mid and type='journey_ended' and user_id=fem1)::text||'/'||
    (select count(*) from notifications where related_match_id=mid and type='journey_ended' and user_id=male1)::text,'1/0');
  delete from notifications where related_match_id=mid;
  delete from wali_links where seeker_id=male1 and wali_id=gadd;
  delete from matches where id=mid;
  delete from likes where liker_id in (male1,fem1) and liked_id in (male1,fem1);

  insert into matches (seeker_a_id, seeker_b_id, status)
    values (least(male2,fem2), greatest(male2,fem2),'potential') returning id into mid;
  select id into att from journey_attempts where match_id=mid;
  perform set_config('request.jwt.claims', json_build_object('sub', male2)::text, true);
  perform promote_journey_to_active(mid);
  begin
    perform end_journey(mid,'no_response');
    insert into zyra_journey_results values (36,'end','no_response refused (system only)','ALLOWED','reason_is_system_only');
  exception when others then
    insert into zyra_journey_results values (36,'end','no_response refused (system only)', sqlerrm,'reason_is_system_only');
  end;
  begin
    perform end_journey(mid,'nonsense');
    insert into zyra_journey_results values (37,'end','unknown reason refused','ALLOWED','unknown_end_reason: nonsense');
  exception when others then
    insert into zyra_journey_results values (37,'end','unknown reason refused', sqlerrm,'unknown_end_reason: nonsense');
  end;
  perform end_journey(mid,'safety_concern');
  insert into zyra_journey_results values (38,'end','safety_concern recorded on both rows',
    (select end_reason from matches where id=mid)||'/'||(select end_reason from journey_attempts where id=att),'safety_concern/safety_concern');
  -- Step 0's concealment must survive everything above it.
  perform set_config('request.jwt.claims', json_build_object('sub', fem2)::text, true);
  insert into zyra_journey_results values (39,'end','other party reads prefer_not_to_say',
    (select end_reason from zyra_match_ending(mid)),'prefer_not_to_say');
  perform set_config('request.jwt.claims', json_build_object('sub', male2)::text, true);
  insert into zyra_journey_results values (40,'end','the ender reads the truth',
    (select end_reason from zyra_match_ending(mid)),'safety_concern');
  delete from notifications where related_match_id=mid;
  delete from matches where id=mid;

  -- ══ F · Tier-1 · shared-Guardian matching exclusion ═════════════════
  -- DR-ZYRA-123. Before this rule, zyra_can_match(brother, sister) with
  -- their father guarding both returned TRUE — a mutual Like would have
  -- created a real Journey between siblings.
  insert into wali_links (seeker_id, wali_id, status, is_main) values (fem1, gmain,'active',false);
  insert into zyra_journey_results values (46,'tier-1','siblings sharing a Guardian cannot match',
    zyra_can_match(male1,fem1)::text,'false');
  insert into zyra_journey_results values (47,'tier-1','...and symmetrically',
    zyra_can_match(fem1,male1)::text,'false');
  -- I1: the rule must not be clearable by retiring the Guardian
  update wali_links set status='removed', is_main=false where seeker_id=fem1 and wali_id=gmain;
  insert into zyra_journey_results values (48,'tier-1','retiring the shared Guardian does NOT unlock it (I1)',
    zyra_can_match(male1,fem1)::text,'false');
  update wali_links set status='pending' where seeker_id=fem1 and wali_id=gmain;
  insert into zyra_journey_results values (49,'tier-1','a never-accepted invite is not a bond',
    zyra_can_match(male1,fem1)::text,'true');
  delete from wali_links where seeker_id=fem1 and wali_id=gmain;
  insert into zyra_journey_results values (50,'tier-1','a pair with no shared Guardian still matches',
    zyra_can_match(male1,fem2)::text,'true');
  insert into zyra_journey_results values (51,'tier-1','Guardian and own ward still refused (Tier-0)',
    zyra_can_match(gmain,male1)::text,'false');

  -- ══ G · Guardian ward count disclosed on the invite preview ═════════
  -- DR-ZYRA-123 decision 2 — chosen over a hard cap, because every cap
  -- refuses somebody legitimate.
  insert into wali_invites (token, inviter_id, inviter_role, status)
    values ('SUITEWARDCOUNT01', gmain, 'wali', 'pending');
  perform set_config('request.jwt.claims', json_build_object('sub', fem1)::text, true);
  select * into card from preview_wali_invite('SUITEWARDCOUNT01');
  insert into zyra_journey_results values (52,'ward count','invite preview reports the ward count',
    (card.inviter_ward_count is not null)::text,'true');
  insert into zyra_journey_results values (53,'ward count','and it matches the live link count',
    card.inviter_ward_count::text,
    (select count(distinct seeker_id)::text from wali_links where wali_id=gmain and status='active'));
  delete from wali_invites where token='SUITEWARDCOUNT01';

  -- ══ H · shape and grants ════════════════════════════════════════════
  insert into zyra_journey_results values (54,'grants','restart_journey refuses unconditionally',
    (select (prosrc ~* 'restart_requires_mutual_consent')::text from pg_proc where proname='restart_journey'),'true');
  insert into zyra_journey_results values (55,'grants','end_journey keeps BOTH forms (the Dart calls the 1-arg)',
    (select count(*)::text from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and proname='end_journey'),'2');
  insert into zyra_journey_results values (56,'grants','promote denied to anon',
    has_function_privilege('anon','public.promote_journey_to_active(uuid)','EXECUTE')::text,'false');
  -- ══ I · OA-ZYRA-174 · Tier-1 is grandfathered for a live Journey ════
  -- Tier-1 governs new matching; a new shared Guardian does not end an
  -- existing Journey. Preserve the non-Pause predicate and link checks.
  delete from likes where liker_id in (male1,fem1) and liked_id in (male1,fem1);
  delete from wali_links where seeker_id=fem1 and wali_id=gmain;
  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  insert into likes (liker_id, liked_id) values (male1, fem1);
  perform set_config('request.jwt.claims', json_build_object('sub', fem1)::text, true);
  insert into likes (liker_id, liked_id) values (fem1, male1);
  select id into mid from matches where seeker_a_id=least(male1,fem1) and seeker_b_id=greatest(male1,fem1);
  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  perform promote_journey_to_active(mid);
  -- the third party arrives AFTER the Journey exists
  insert into wali_links (seeker_id, wali_id, status, is_main) values (fem1, gmain,'active',false);
  insert into zyra_journey_results values (59,'oa-174','Tier-1 still blocks a NEW match',
    zyra_can_match(male1,fem1)::text,'false');
  -- Tier-0 cannot even ARISE mid-Journey — the link guard refuses first.
  begin
    insert into wali_links (seeker_id, wali_id, status, is_main) values (fem1, male1,'active',true);
    insert into zyra_journey_results values (63,'oa-174','Tier-0 link over a live Journey refused','ALLOWED — DEFECT','romantic_edge_exists');
  exception when others then
    insert into zyra_journey_results values (63,'oa-174','Tier-0 link over a live Journey refused', sqlerrm,'romantic_edge_exists');
  end;
  -- ...and the predicate refuses it directly anyway (defence in depth)
  insert into zyra_journey_results values (64,'oa-174','can_continue_journey refuses Tier-0',
    zyra_can_continue_journey(gmain, male1)::text,'false');
  insert into zyra_journey_results values (65,'oa-174','can_continue_journey ALLOWS a shared Guardian',
    zyra_can_continue_journey(male1, fem1)::text,'true');
  -- the predicate is internal; no client role may call it
  insert into zyra_journey_results values (66,'oa-174','can_continue_journey not client-callable',
    has_function_privilege('authenticated','public.zyra_can_continue_journey(uuid,uuid)','EXECUTE')::text,'false');
  delete from wali_links where seeker_id=fem1 and wali_id=gmain;
  delete from notifications where related_match_id=mid;
  delete from matches where id=mid;
  delete from likes where liker_id in (male1,fem1) and liked_id in (male1,fem1);

  -- ══ K · the Active cap is the PLAN's, not the number one (2026-08-12) ═
  -- plan_aware_active_journey_limit made the entitlements matrix real:
  -- Basic 1 / ZYRA One 3, per party, via zyra_active_journey_cap(). The
  -- unique indexes became plain indexes that day — the constraint
  -- triggers (advisory-lock serialised) are the sole race-proof guard —
  -- so 75 is the assertion that the raw route STILL cannot pass the cap.
  -- Basic's own cap of 1 is already held above by checks 11/12.
  --
  -- Pinned to PREMIUM and restored immediately after this section.
  select plan_type, status into base_plan, base_sub_status
    from subscriptions where user_id = male1;
  if base_plan is not null then
    update subscriptions set plan_type='seeker_premium', status='active'
     where user_id = male1;
  else
    insert into subscriptions (user_id, plan_type, status)
    values (male1, 'seeker_premium', 'active');
  end if;

  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  insert into likes (liker_id, liked_id) values (male1, fem1);
  perform set_config('request.jwt.claims', json_build_object('sub', fem1)::text, true);
  insert into likes (liker_id, liked_id) values (fem1, male1);
  select id into mid from matches where seeker_a_id=least(male1,fem1) and seeker_b_id=greatest(male1,fem1);
  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  perform promote_journey_to_active(mid);

  insert into likes (liker_id, liked_id) values (male1, fem2);
  perform set_config('request.jwt.claims', json_build_object('sub', fem2)::text, true);
  insert into likes (liker_id, liked_id) values (fem2, male1);
  select id into midb from matches where seeker_a_id=least(male1,fem2) and seeker_b_id=greatest(male1,fem2);
  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  begin
    perform promote_journey_to_active(midb);
    insert into zyra_journey_results values (72,'plan cap','One holds a SECOND Active Journey',(select status from matches where id=midb),'active');
  exception when others then
    insert into zyra_journey_results values (72,'plan cap','One holds a SECOND Active Journey','REFUSED: '||sqlerrm,'active');
  end;

  insert into likes (liker_id, liked_id) values (male1, fem3);
  perform set_config('request.jwt.claims', json_build_object('sub', fem3)::text, true);
  insert into likes (liker_id, liked_id) values (fem3, male1);
  select id into midc from matches where seeker_a_id=least(male1,fem3) and seeker_b_id=greatest(male1,fem3);
  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  begin
    perform promote_journey_to_active(midc);
    insert into zyra_journey_results values (73,'plan cap','and a THIRD',(select status from matches where id=midc),'active');
  exception when others then
    insert into zyra_journey_results values (73,'plan cap','and a THIRD','REFUSED: '||sqlerrm,'active');
  end;

  insert into likes (liker_id, liked_id) values (male1, fem4);
  perform set_config('request.jwt.claims', json_build_object('sub', fem4)::text, true);
  insert into likes (liker_id, liked_id) values (fem4, male1);
  select id into midd from matches where seeker_a_id=least(male1,fem4) and seeker_b_id=greatest(male1,fem4);
  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  begin
    perform promote_journey_to_active(midd);
    insert into zyra_journey_results values (74,'plan cap','a FOURTH is refused','ALLOWED — DEFECT','one_active_journey_limit');
  exception when others then
    insert into zyra_journey_results values (74,'plan cap','a FOURTH is refused', sqlerrm,'one_active_journey_limit');
  end;
  begin
    update matches set status='active' where id=midd;
    insert into zyra_journey_results values (75,'plan cap','direct UPDATE past the cap also refused','ALLOWED — DEFECT','one_active_journey_limit');
  exception when others then
    insert into zyra_journey_results values (75,'plan cap','direct UPDATE past the cap also refused', sqlerrm,'one_active_journey_limit');
  end;

  delete from notifications where related_match_id in (mid, midb, midc, midd);
  delete from matches where id in (mid, midb, midc, midd);
  delete from likes where (liker_id=male1 and liked_id in (fem1,fem2,fem3,fem4))
                       or (liker_id in (fem1,fem2,fem3,fem4) and liked_id=male1);
  if base_plan is not null then
    update subscriptions set plan_type = base_plan, status = base_sub_status
     where user_id = male1;
  else
    delete from subscriptions where user_id = male1;
  end if;

  -- ══ N · counterpart busy signal (OA-ZYRA-204, 2026-08-21) ═══════════
  -- male1↔fem1 stays potential; fem1↔male2 is live. From male1's card
  -- fem1 is busy; from fem1's card male1 is not. A non-party learns nothing.
  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  insert into likes (liker_id, liked_id) values (male1, fem1);
  perform set_config('request.jwt.claims', json_build_object('sub', fem1)::text, true);
  insert into likes (liker_id, liked_id) values (fem1, male1);
  select id into mid from matches
   where seeker_a_id=least(male1,fem1) and seeker_b_id=greatest(male1,fem1);
  -- A potential match supplies the resting card without a retired Pause RPC.

  perform set_config('request.jwt.claims', json_build_object('sub', male2)::text, true);
  insert into likes (liker_id, liked_id) values (male2, fem1);
  perform set_config('request.jwt.claims', json_build_object('sub', fem1)::text, true);
  insert into likes (liker_id, liked_id) values (fem1, male2);
  select id into midb from matches
   where seeker_a_id=least(male2,fem1) and seeker_b_id=greatest(male2,fem1);
  perform set_config('request.jwt.claims', json_build_object('sub', male2)::text, true);
  perform promote_journey_to_active(midb);

  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  insert into zyra_journey_results values (95,'busy-signal','counterpart active with a third person is true',
    (select in_another_journey::text from zyra_journey_busy_flags(array[mid])),'true');

  perform set_config('request.jwt.claims', json_build_object('sub', fem1)::text, true);
  insert into zyra_journey_results values (96,'busy-signal','signal is caller-relative, not a match flag',
    (select in_another_journey::text from zyra_journey_busy_flags(array[mid])),'false');

  perform set_config('request.jwt.claims', json_build_object('sub', male2)::text, true);
  insert into zyra_journey_results values (97,'busy-signal','a non-party receives no requested row',
    (select count(*)::text from zyra_journey_busy_flags(array[mid])),'0');
  delete from notifications where related_match_id in (mid, midb);
  delete from matches where id in (mid, midb);
  delete from likes where (liker_id in (male1,male2) and liked_id=fem1)
                       or (liker_id=fem1 and liked_id in (male1,male2));

  update profiles p
     set onboarding_complete = saved.value::boolean
    from jsonb_each_text(base_onboarding) as saved(key, value)
   where p.id = saved.key::uuid;

  delete from wali_links where id = any(fixture_main_links);

  insert into zyra_journey_results values (57,'teardown','no matches left behind by THIS suite',
    (select count(*) from matches)::text, base_matches::text);
  insert into zyra_journey_results values (58,'teardown','no reviews left behind by THIS suite',
    (select count(*) from journey_family_reviews)::text, base_reviews::text);
  insert into zyra_journey_results values (67,'teardown','no stray Guardian link on fem1',
    (select count(*) from wali_links where seeker_id=fem1)::text,'0');
end $$;

-- Wrapped in a subquery 2026-08-12: an ORDER BY attached directly to a
-- UNION may only name output columns, so `order by area='TOTAL'` is an
-- error (0A000) and the tail refused to run. Same fix in the guard suite.
select * from (
  select area, count(*) as checks, count(*) filter (where got=expected) as passed,
         count(*) filter (where got is distinct from expected) as failed
  from zyra_journey_results group by area
  union all select 'TOTAL', count(*), count(*) filter (where got=expected),
         count(*) filter (where got is distinct from expected) from zyra_journey_results
) t
order by (t.area='TOTAL'), t.area;

-- Failures in detail. Empty = suite green.
select n, area, check_name, got, expected
from zyra_journey_results where got is distinct from expected order by n;

do $assert_results$
declare
  mismatch_count integer;
begin
  select count(*) into mismatch_count from zyra_journey_results
  where got is distinct from expected;
  if mismatch_count <> 0 then
    raise exception 'ZYRA Journey suite: % assertion mismatches', mismatch_count;
  end if;
end;
$assert_results$;

-- drop table zyra_journey_results;   -- uncomment to clean up
