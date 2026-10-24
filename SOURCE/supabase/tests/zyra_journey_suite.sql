-- ═══════════════════════════════════════════════════════════════════════
-- ZYRA — Journey lifecycle regression suite
--
-- LEGACY ARCHIVE AFTER THE SHARED PAUSE MIGRATION (2026-08-25).
-- Sections D/J/L/M preserve the retired personal-hold RPC evidence and must
-- not be used to verify the current Pause model. Run
-- zyra_pause_decision_state_machine_suite.sql for the authoritative shared
-- decision, capacity, CAS/race and lock-bypass checks. The non-Pause sections
-- remain useful historical lifecycle evidence until Fable splits/renames this
-- archive under the governed test index.
--
-- Companion to zyra_guard_suite.sql, which covers visibility and privacy.
-- This one covers the LIFECYCLE: match creation, promotion, the Family
-- Review Period, pause/resume, and endings — everything OA-ZYRA-156
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
-- First run: 45/45. Extended with Tier-1 and the ward count (DR-ZYRA-123),
-- then with section I for OA-ZYRA-174, all 2026-08-08. Assertion numbers
-- run 0-40 and 46-67 (the 41-45 gap is the old section F, renumbered to
-- H) — 62 checks. READ THE `TOTAL` ROW, not the highest number.
--
-- END-TO-END RUN 2026-08-08: 53/53 green, no residue. The first attempt
-- failed at assertion 29 and the failure was real: section C's Main for
-- fem1 was 565a0208, who ALREADY actively guards male1, so Tier-1 made
-- the pair unmatchable and resume_journey's re-check threw. Assertion 0
-- now guards against that choice being made again. See OA-ZYRA-174 for
-- the product question this exposed.
--
-- EXTENDED 2026-08-12 with section J (checks 68-71): pause frees the
-- Active slot. The 2026-08-09 matrix and SUSPENSION V2 §5 ratified it; the
-- pause_frees_active_slot migration built it; these four checks are the
-- behaviour. Extended again the same day with section K (checks 72-76):
-- the Active cap is plan-aware — Basic 1, ZYRA One 3
-- (plan_aware_active_journey_limit). J and K pin male1's subscription
-- (Basic and Premium respectively) and restore what they found, because
-- the developer's Membership panel writes that same row. Extended a third
-- time the same evening with section L (checks 77-82): the pause package —
-- one-shot nudge per pause episode + the nameless journey_paused /
-- journey_continued Timeline pair (DR-ZYRA-142,
-- pause_nudge_and_timeline_pair). Extended 2026-08-15 with section M
-- (checks 83-94): SHARED PAUSE HOLDS — DR-ZYRA-170. A pause became a
-- personal hold (either party may hold; you lift only your own; the
-- primary lifting first PROMOTES the second hold; three notification
-- types tell people what used to happen silently). Extended 2026-08-21
-- with section N (checks 95-98): OA-ZYRA-204's caller-scoped, server-owned
-- counterpart-busy signal. 94 checks total.
--
-- END-TO-END RUN 2026-08-12: 63/63 green. That day's first attempt failed
-- at the FIRST promote ("match not found") — the same premise class
-- assertion 0 exists for, in a new costume: OA-ZYRA-193(c) had added an
-- onboarding_complete gate to zyra_can_match on 2026-08-11, and the seed
-- predated it, so every @zyra.test seeker still carried the flag false and
-- the mutual Likes silently created no match. Fixed in the DATA (flag set
-- true for all 144 synthetic seekers, each of which holds a full synthetic
-- answer sheet), never by weakening the gate. If assertion 0 reports false
-- again, audit the seed against every gate zyra_can_match has grown since.
--
-- END-TO-END RUN 2026-08-16: 90/90 green under SALAM FIRST (DR-ZYRA-183
-- — salam_exchange is stage one; check 9 asserts the new entry stage).
-- ═══════════════════════════════════════════════════════════════════════

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
  -- and resume_journey re-checks zyra_can_match. Assertion 0 enforces it.
  gmain2 uuid := '257d6ebc-ccd0-4c16-a878-3c416ad7b530';
  gadd   uuid := '6493a6e6-6fc7-4d7a-b1b5-58b637c08647';  -- ADDITIONAL of male1
  -- Sections J/K need male1 matchable with FOUR women. fem3/fem4 chosen
  -- from the seed the same way as the others (female, @zyra.test,
  -- onboarding complete, no Guardian overlap with male1, no matches).
  fem3   uuid := '01c7caa4-56c1-481b-8557-de901d3e7d99';  -- Rahma
  fem4   uuid := '03752c3d-0396-4f38-b234-84d93b724b00';  -- Khadija
  mid uuid; midb uuid; midc uuid; midd uuid;
  att uuid; conv uuid; tl uuid; rev uuid; card record;
  -- Sections J and K are CAP-SENSITIVE and the developer's Membership
  -- panel writes male1's real subscriptions row, so neither may assume a
  -- plan: J pins Basic (its resume-refusals need cap 1), K pins Premium
  -- (its whole point is cap 3), and whatever was found is restored after.
  base_plan text; base_sub_status text;
  -- SCOPED 2026-08-10. Checks 57/58 used to assert the WHOLE table was
  -- empty, so the suite reported a failure whenever any unrelated row
  -- existed — including a developer's own test Journey. That measured the
  -- database, not the suite. Baselines make them assert what they mean:
  -- this run left nothing behind.
  base_matches int; base_reviews int;
  base_onboarding jsonb;
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
  insert into wali_links (seeker_id, wali_id, status, is_main) values (fem1, gmain2,'active',true);
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

  -- ══ D · pause / resume (step 4) ═════════════════════════════════════
  insert into subscriptions (user_id, plan_type, status) values (male1,'seeker_premium','active') on conflict do nothing;
  update conversations set status='active' where id=conv;
  perform suspend_journey(mid);
  insert into zyra_journey_results values (25,'pause','pause on matches',(select (suspended_by=male1)::text from matches where id=mid),'true');
  insert into zyra_journey_results values (26,'pause','pause MIRRORED on the attempt',(select (paused_by=male1)::text from journey_attempts where id=att),'true');
  insert into zyra_journey_results values (27,'pause','conversation paused via attempt_id',(select status from conversations where id=conv),'paused');
  perform set_config('request.jwt.claims', json_build_object('sub', fem1)::text, true);
  begin
    perform resume_journey(mid);
    -- REWORDED 2026-08-15 (DR-ZYRA-170): under shared holds nobody
    -- "resumes" anybody — you lift your own hold or you have nothing to
    -- lift. fem1 holds nothing here, so the refusal is by that name.
    insert into zyra_journey_results values (28,'pause','only your own hold is yours to lift','ALLOWED','no_hold_to_lift');
  exception when others then
    insert into zyra_journey_results values (28,'pause','only your own hold is yours to lift', sqlerrm,'no_hold_to_lift');
  end;
  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  perform resume_journey(mid);
  insert into zyra_journey_results values (29,'pause','resume clears both rows',
    (select (suspended_by is null)::text from matches where id=mid)||'/'||
    (select (paused_by is null)::text from journey_attempts where id=att),'true/true');

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
  delete from subscriptions where user_id=male1 and plan_type='seeker_premium';
  delete from wali_links where (seeker_id=fem1 and wali_id=gmain2) or (seeker_id=male1 and wali_id=gadd);
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
  insert into wali_links (seeker_id, wali_id, status, is_main) values (fem1, gmain,'active',true);
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
  -- Founder decision 2026-08-08: Tier-1 governs who may be MATCHED, not
  -- who stays matched. Before this, resume_journey() called
  -- zyra_can_match(), so a THIRD party linking themselves to both Seekers
  -- made a paused Journey permanently un-resumable — and left it
  -- untouched if the pair simply never paused. This section is the whole
  -- decision, expressed as behaviour.
  delete from likes where liker_id in (male1,fem1) and liked_id in (male1,fem1);
  delete from wali_links where seeker_id=fem1 and wali_id=gmain;
  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  insert into likes (liker_id, liked_id) values (male1, fem1);
  perform set_config('request.jwt.claims', json_build_object('sub', fem1)::text, true);
  insert into likes (liker_id, liked_id) values (fem1, male1);
  select id into mid from matches where seeker_a_id=least(male1,fem1) and seeker_b_id=greatest(male1,fem1);
  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  perform promote_journey_to_active(mid);
  insert into subscriptions (user_id, plan_type, status) values (male1,'seeker_premium','active') on conflict do nothing;
  perform suspend_journey(mid);
  -- the third party arrives AFTER the Journey exists
  insert into wali_links (seeker_id, wali_id, status, is_main) values (fem1, gmain,'active',true);
  insert into zyra_journey_results values (59,'oa-174','Tier-1 still blocks a NEW match',
    zyra_can_match(male1,fem1)::text,'false');
  begin
    perform resume_journey(mid);
    insert into zyra_journey_results values (60,'oa-174','but the EXISTING Journey resumes','resumed','resumed');
  exception when others then
    insert into zyra_journey_results values (60,'oa-174','but the EXISTING Journey resumes','REFUSED: '||sqlerrm,'resumed');
  end;
  insert into zyra_journey_results values (61,'oa-174','and the pause is actually cleared',
    (select (suspended_by is null)::text from matches where id=mid),'true');
  -- a block is an act by one of THEM, and stays terminal (I2)
  perform suspend_journey(mid);
  insert into profile_blocks (blocker_id, blocked_id) values (fem1, male1);
  begin
    perform resume_journey(mid);
    insert into zyra_journey_results values (62,'oa-174','a block still refuses a resume','ALLOWED — DEFECT','not_eligible_to_continue');
  exception when others then
    insert into zyra_journey_results values (62,'oa-174','a block still refuses a resume', sqlerrm,'not_eligible_to_continue');
  end;
  delete from profile_blocks where blocker_id=fem1 and blocked_id=male1;
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
  delete from subscriptions where user_id=male1 and plan_type='seeker_premium';
  delete from matches where id=mid;
  delete from likes where liker_id in (male1,fem1) and liked_id in (male1,fem1);

  -- ══ J · pause frees the Active slot (2026-08-12) ════════════════════
  -- The matrix promise, expressed as behaviour: pause with one person,
  -- BEGIN with another. Before the pause_frees_active_slot migration,
  -- check 68 raised one_active_journey_limit — a paused row still counted.
  --
  -- Pinned to BASIC: 69 and 70 assert a resume/un-pause is refused while
  -- ONE other Journey runs, which is only true at cap 1. On ZYRA One
  -- (cap 3, section K) that resume would legitimately succeed.
  select plan_type, status into base_plan, base_sub_status
    from subscriptions where user_id = male1;
  if base_plan is not null then
    update subscriptions set plan_type='seeker_basic', status='active'
     where user_id = male1;
  end if;  -- no row at all already means Basic (the cap helper's ELSE arm)

  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  insert into likes (liker_id, liked_id) values (male1, fem1);
  perform set_config('request.jwt.claims', json_build_object('sub', fem1)::text, true);
  insert into likes (liker_id, liked_id) values (fem1, male1);
  select id into mid from matches where seeker_a_id=least(male1,fem1) and seeker_b_id=greatest(male1,fem1);
  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  perform promote_journey_to_active(mid);
  perform suspend_journey(mid);
  insert into likes (liker_id, liked_id) values (male1, fem2);
  perform set_config('request.jwt.claims', json_build_object('sub', fem2)::text, true);
  insert into likes (liker_id, liked_id) values (fem2, male1);
  select id into midb from matches where seeker_a_id=least(male1,fem2) and seeker_b_id=greatest(male1,fem2);
  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  begin
    perform promote_journey_to_active(midb);
    insert into zyra_journey_results values (68,'pause-frees','begin while paused elsewhere ALLOWED',
      (select status from matches where id=midb),'active');
  exception when others then
    insert into zyra_journey_results values (68,'pause-frees','begin while paused elsewhere ALLOWED','REFUSED: '||sqlerrm,'active');
  end;
  -- resuming the paused one while the second is live: refused, by name
  begin
    perform resume_journey(mid);
    insert into zyra_journey_results values (69,'pause-frees','resume while active elsewhere refused','ALLOWED — DEFECT','self_in_active_journey');
  exception when others then
    insert into zyra_journey_results values (69,'pause-frees','resume while active elsewhere refused', sqlerrm,'self_in_active_journey');
  end;
  -- and the raw route is refused with no function in the way. TWO guards
  -- can fire and which one wins is an implementation detail: the partial
  -- unique index catches it when the person sits in the SAME column of
  -- both rows (with these seeded uuids male1 is seeker_b in both — the
  -- index answered on the first live run), and the re-armed constraint
  -- trigger covers the cross-column case the single-column indexes cannot
  -- see. Either is a pass; anything else surfaces verbatim as a failure.
  begin
    update matches set suspended_by=null, suspended_at=null where id=mid;
    insert into zyra_journey_results values (70,'pause-frees','direct un-pause also refused (index or trigger)','ALLOWED — DEFECT','refused');
  exception when others then
    insert into zyra_journey_results values (70,'pause-frees','direct un-pause also refused (index or trigger)',
      case when sqlerrm = 'one_active_journey_limit'
             or sqlerrm like '%matches_seeker_%_active%'
           then 'refused' else sqlerrm end,'refused');
  end;
  -- end the second and the paused one resumes cleanly
  perform end_journey(midb);
  perform resume_journey(mid);
  insert into zyra_journey_results values (71,'pause-frees','slot freed, the paused Journey resumes',
    (select (suspended_by is null)::text from matches where id=mid),'true');
  delete from notifications where related_match_id in (mid, midb);
  delete from matches where id in (mid, midb);
  delete from likes where (liker_id=male1 and liked_id in (fem1,fem2))
                       or (liker_id in (fem1,fem2) and liked_id=male1);

  -- ══ K · the Active cap is the PLAN's, not the number one (2026-08-12) ═
  -- plan_aware_active_journey_limit made the entitlements matrix real:
  -- Basic 1 / ZYRA One 3, per party, via zyra_active_journey_cap(). The
  -- unique indexes became plain indexes that day — the constraint
  -- triggers (advisory-lock serialised) are the sole race-proof guard —
  -- so 75 is the assertion that the raw route STILL cannot pass the cap.
  -- Basic's own cap of 1 is already held above by checks 11/12.
  --
  -- Pinned to PREMIUM, restored (with J's capture) right after.
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

  -- both of today's decisions, composed: pausing one of THREE frees the
  -- third slot exactly as pausing one of one freed the only slot in J
  perform suspend_journey(midb);
  begin
    perform promote_journey_to_active(midd);
    insert into zyra_journey_results values (76,'plan cap','pause frees a slot at ANY cap',(select status from matches where id=midd),'active');
  exception when others then
    insert into zyra_journey_results values (76,'plan cap','pause frees a slot at ANY cap','REFUSED: '||sqlerrm,'active');
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

  -- ══ L · the pause package — nudge + Timeline pair (DR-ZYRA-142) ═════
  -- One voice for the waiting person, once per pause episode; the
  -- Timeline records the pair, nameless. Probed green before being
  -- written here, 2026-08-12 evening.
  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  insert into likes (liker_id, liked_id) values (male1, fem1);
  perform set_config('request.jwt.claims', json_build_object('sub', fem1)::text, true);
  insert into likes (liker_id, liked_id) values (fem1, male1);
  select id into mid from matches where seeker_a_id=least(male1,fem1) and seeker_b_id=greatest(male1,fem1);
  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  perform promote_journey_to_active(mid);
  perform suspend_journey(mid);
  begin
    perform nudge_paused_journey(mid);
    insert into zyra_journey_results values (77,'nudge','the pauser cannot nudge (their button is Resume)','ALLOWED — DEFECT','pauser_cannot_nudge');
  exception when others then
    insert into zyra_journey_results values (77,'nudge','the pauser cannot nudge (their button is Resume)', sqlerrm,'pauser_cannot_nudge');
  end;
  perform set_config('request.jwt.claims', json_build_object('sub', fem1)::text, true);
  begin
    perform nudge_paused_journey(mid);
    insert into zyra_journey_results values (78,'nudge','the waiting person nudges once','ok','ok');
  exception when others then
    insert into zyra_journey_results values (78,'nudge','the waiting person nudges once', sqlerrm,'ok');
  end;
  insert into zyra_journey_results values (79,'nudge','one notification, to the pauser ALONE',
    (select count(*) from notifications where related_match_id=mid and type='pause_nudge' and user_id=male1)::text
     || '/' || (select count(*) from notifications where related_match_id=mid and type='pause_nudge' and user_id<>male1)::text,'1/0');
  begin
    perform nudge_paused_journey(mid);
    insert into zyra_journey_results values (80,'nudge','a second nudge is refused','ALLOWED — DEFECT','already_nudged');
  exception when others then
    insert into zyra_journey_results values (80,'nudge','a second nudge is refused', sqlerrm,'already_nudged');
  end;
  -- a NEW pause is a NEW episode: the one nudge comes back
  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  perform resume_journey(mid);
  perform suspend_journey(mid);
  perform set_config('request.jwt.claims', json_build_object('sub', fem1)::text, true);
  begin
    perform nudge_paused_journey(mid);
    insert into zyra_journey_results values (81,'nudge','a new pause episode restores the nudge','ok','ok');
  exception when others then
    insert into zyra_journey_results values (81,'nudge','a new pause episode restores the nudge', sqlerrm,'ok');
  end;
  -- the Timeline pair: paused twice, continued once at this point —
  -- dated, nameless (the milestone row carries type and time only)
  insert into zyra_journey_results values (82,'nudge','Timeline holds the nameless pair (paused/continued)',
    (select count(*) filter (where milestone_type='journey_paused')::text || '/' ||
            count(*) filter (where milestone_type='journey_continued')::text
       from timeline_milestones tm join timelines t on t.id = tm.timeline_id
      where t.match_id = mid),'2/1');
  delete from notifications where related_match_id=mid;
  delete from matches where id=mid;
  delete from likes where liker_id in (male1,fem1) and liked_id in (male1,fem1);

  -- ══ M · shared pause holds (DR-ZYRA-170, 2026-08-15) ════════════════
  -- A pause is a personal hold: either party may hold, the Journey rests
  -- while any hold exists, you lift only your own, and the primary hand
  -- lifting first PROMOTES the second hold. The milestone trigger writes
  -- nothing for mirrors and promotions (suspended_by never touches NULL)
  -- — checks 87 and 91 pin exactly that.
  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  insert into likes (liker_id, liked_id) values (male1, fem1);
  perform set_config('request.jwt.claims', json_build_object('sub', fem1)::text, true);
  insert into likes (liker_id, liked_id) values (fem1, male1);
  select id into mid from matches where seeker_a_id=least(male1,fem1) and seeker_b_id=greatest(male1,fem1);
  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  perform promote_journey_to_active(mid);
  perform suspend_journey(mid);
  insert into zyra_journey_results values (83,'shared-pause','the other person is TOLD about a pause now',
    (select count(*) from notifications where related_match_id=mid and type='journey_paused' and user_id=fem1)::text || '/' ||
    (select count(*) from notifications where related_match_id=mid and type='journey_paused' and user_id=male1)::text,'1/0');
  perform set_config('request.jwt.claims', json_build_object('sub', fem1)::text, true);
  perform suspend_journey(mid);
  insert into zyra_journey_results values (84,'shared-pause','mirror lands in also_paused_by',
    (select (also_paused_by=fem1)::text from matches where id=mid),'true');
  insert into zyra_journey_results values (85,'shared-pause','...and on the attempt',
    (select (also_paused_by=fem1)::text from journey_attempts where match_id=mid),'true');
  insert into zyra_journey_results values (86,'shared-pause','first pauser told "also paused", alone',
    (select count(*) from notifications where related_match_id=mid and type='journey_also_paused' and user_id=male1)::text || '/' ||
    (select count(*) from notifications where related_match_id=mid and type='journey_also_paused' and user_id=fem1)::text,'1/0');
  insert into zyra_journey_results values (87,'shared-pause','mirror writes NO second Timeline pause',
    (select count(*) from timeline_milestones tm join timelines t on t.id=tm.timeline_id
      where t.match_id=mid and tm.milestone_type='journey_paused')::text,'1');
  begin
    perform nudge_paused_journey(mid);
    insert into zyra_journey_results values (88,'shared-pause','a second holder cannot nudge','ALLOWED — DEFECT','pauser_cannot_nudge');
  exception when others then
    insert into zyra_journey_results values (88,'shared-pause','a second holder cannot nudge', sqlerrm,'pauser_cannot_nudge');
  end;
  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  perform resume_journey(mid);
  insert into zyra_journey_results values (89,'shared-pause','primary lift PROMOTES the second hold',
    (select (suspended_by=fem1)::text || '/' || (also_paused_by is null)::text from matches where id=mid),'true/true');
  insert into zyra_journey_results values (90,'shared-pause','the lift IS the ready signal',
    (select (pause_nudged_at is not null)::text from matches where id=mid) || '/' ||
    (select count(*) from notifications where related_match_id=mid and type='pause_nudge' and user_id=fem1)::text,'true/1');
  insert into zyra_journey_results values (91,'shared-pause','promotion writes NO Timeline continued',
    (select count(*) from timeline_milestones tm join timelines t on t.id=tm.timeline_id
      where t.match_id=mid and tm.milestone_type='journey_continued')::text,'0');
  begin
    perform resume_journey(mid);
    insert into zyra_journey_results values (92,'shared-pause','no hold, nothing to lift','ALLOWED — DEFECT','no_hold_to_lift');
  exception when others then
    insert into zyra_journey_results values (92,'shared-pause','no hold, nothing to lift', sqlerrm,'no_hold_to_lift');
  end;
  perform set_config('request.jwt.claims', json_build_object('sub', fem1)::text, true);
  perform resume_journey(mid);
  insert into zyra_journey_results values (93,'shared-pause','last lift activates + tells the other, alone',
    (select status from matches where id=mid) || '/' ||
    (select (suspended_by is null and also_paused_by is null)::text from matches where id=mid) || '/' ||
    (select count(*) from notifications where related_match_id=mid and type='journey_continued' and user_id=male1)::text,'active/true/1');
  begin
    update matches set also_paused_by=fem1 where id=mid;
    insert into zyra_journey_results values (94,'shared-pause','a second hold cannot exist without a first','ALLOWED — DEFECT','refused');
  exception when others then
    insert into zyra_journey_results values (94,'shared-pause','a second hold cannot exist without a first',
      case when sqlerrm like '%also_pause_requires_primary%' then 'refused' else sqlerrm end,'refused');
  end;
  delete from notifications where related_match_id=mid;
  delete from matches where id=mid;
  delete from likes where liker_id in (male1,fem1) and liked_id in (male1,fem1);

  -- ══ N · counterpart busy signal (OA-ZYRA-204, 2026-08-21) ═══════════
  -- male1↔fem1 rests; fem1↔male2 is live. From male1's card fem1 is busy;
  -- from fem1's card male1 is not. A non-party learns nothing, and pausing
  -- the third-party Journey removes the signal immediately.
  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  insert into likes (liker_id, liked_id) values (male1, fem1);
  perform set_config('request.jwt.claims', json_build_object('sub', fem1)::text, true);
  insert into likes (liker_id, liked_id) values (fem1, male1);
  select id into mid from matches
   where seeker_a_id=least(male1,fem1) and seeker_b_id=greatest(male1,fem1);
  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  perform promote_journey_to_active(mid);
  perform suspend_journey(mid);

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
  perform suspend_journey(midb);

  perform set_config('request.jwt.claims', json_build_object('sub', male1)::text, true);
  insert into zyra_journey_results values (98,'busy-signal','a paused third-party Journey is not busy',
    (select in_another_journey::text from zyra_journey_busy_flags(array[mid])),'false');

  delete from notifications where related_match_id in (mid, midb);
  delete from matches where id in (mid, midb);
  delete from likes where (liker_id in (male1,male2) and liked_id=fem1)
                       or (liker_id=fem1 and liked_id in (male1,male2));

  update profiles p
     set onboarding_complete = saved.value::boolean
    from jsonb_each_text(base_onboarding) as saved(key, value)
   where p.id = saved.key::uuid;

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

-- drop table zyra_journey_results;   -- uncomment to clean up
