# CODEX HANDOVER — ZYRA FULL APP AUDIT

**Version:** V1  
**Status:** CURRENT_VERSION — audit complete; repair and production execution NOT approved  
**Date:** 2026-10-03  
**Owner:** Codex under Founder authority / AD-AIOS-111  
**Action:** OA-ZYRA-305; existing finding owners retained below  
**Authority:** Founder-relayed full product/code/backend/privacy/UI/release audit brief. Audit and documentary evidence only. Only the Founder approves repairs, live containment, provider changes and release.

## Result

The client is substantially tested, but ZYRA is **not cleared for public/external TestFlight or untrusted member testing against the inspected backend**. Three critical live permission/retention paths require bounded security repair. A passing local suite does not establish server authorization, real verification, receipts, native accessibility or a correct installed artifact.

| Measure | Result |
|---|---|
| Finding groups | 61: 3 CRITICAL; 23 HIGH; 30 MEDIUM; 2 LOW; 3 INFORMATIONAL. |
| Product/implementation contradictions | 18 topic groups in the contradiction matrix; not additional findings. |
| Duplicates | 0 exact duplicate contents among 271 inspected non-configuration Dart files. 6 overlap/legacy groups; 4 ordinary-route dead-screen candidates within one group. No blanket deletion authority. |
| Security/privacy | 24 tagged finding/evidence-gap groups; not 24 demonstrated exploits. |
| Missing or insufficient proof | 58 proposed regression/acceptance proof groups, one per non-informational finding. This is NOT a count of missing test files or individual cases; existing tests cover parts of these paths. |
| Fresh functional checks | 2,487 passed; 2 conditional skips; 0 failed across 225 explicit non-visual files. Analyzer: 0 issues. |
| Fresh visual checks | Existing full comparison suite: 211 passed / 124 failed / 335 total. Separate real-Poppins modal checks: 3 passed. No baseline promotion. |
| Production-data risk | YES: live catalog evidence confirms paths that can erase safety evidence or authorize unintended historical chat/private file access. No actual exposure, lost report count or exploited member was measured. |
| Immediate Founder action | YES: approve a narrowly scoped Phase 0 security repair/containment brief. No containment was silently applied. |
| Product changes this phase | None. Source, tests, native files, migrations, assets and tool aggregate hashes remained identical across the captured audit window. |
| Phone / distribution | No build, install, launch or TestFlight upload in this audit. The earlier signed build's receipt reported device unavailable; source is not proof of what is currently installed. |

Counts are issue groups, not independent bugs: high-level matrices cross-reference the same F IDs. “Confirmed” can mean confirmed live authorization, confirmed source defect, or confirmed staged mismatch; each finding states which. Candidates and evidence gaps are not represented as reproduced production failures.

### Scope and working-state limits

Reviewed the current Seeker and Guardian role shells, admission/onboarding, profile/settings, Browse/Connections/Journeys, messages/notifications, membership/credits, compatibility, storage, safety, release gates/native configuration, governed contracts and live Supabase catalog authority. Parallel auditors reviewed core actions/UI, compatibility, and release/identity/membership; their focused tests overlap the full suite and are not added to its count.

The checkout is heavily pre-existing work in progress. No Git commands were run. Read-only index/HEAD inspection found main at `ce4fb8128a3018aae4046be50892be37a753d08e`, 968 index entries, 226 SOURCE files different from index, 408 unchanged and 8 missing. Across 966 safe HEAD/index entries, no staged additions/removals/modifications or unmerged entries were found; two sensitive entries were excluded. There were 472 refined non-generated index-absent candidates and 28,850 generated/local candidates; these are NOT effective Git-ignore classifications. Existing differences belong to the Founder and were not cleaned up. Local app/build processes were absent at initial check; a remote/editor-wide exclusivity guarantee is unavailable.

The 8 SOURCE index-missing paths are: old com/example MainActivity, ios/Podfile, ios/Podfile.lock, blocked_users_screen.dart, zyra_trails_meet_rule.dart, two Aug11 timeline/rewind migration paths, and splash_trails_meet_test.dart. This audit did not delete or restore them. Migration provenance is separately reconciled below.

No protected PRIVATE directory, credential config contents, session tokens, member photo pixels, chat contents, member identities or payment records were opened. Initial backend/version/advisor lookups were catalog-only; subsequent targeted SQL used explicit READ ONLY transactions. No member function was invoked, account impersonated, receipt verified, credit spent or data changed. Upon critical minimum proof, affected inspection stopped; each critical risk was reported immediately. The evidence receipt preserves safe catalog definitions and query strings, not exploitable member material.

## Authority reconciliation — before judging the app

The supplied brief's older no-Basic rule is **superseded by DR-ZYRA-252 (2026-10-03)**: Basic is £4.99 one-time, not £0, and is role-specific. One and Family remain according to current pricing. Basic is retained, not deleted. Selection is intent, never payment proof.

DR-ZYRA-253's four purpose-led opening pages are deliberately **protected local preview** until acceptance. Ordinary OAuth does not run them; this is a held approved boundary, not an auth-flow defect. The retired seven-slide sequence is not the current repair target. Required first and last names are public; DOB is private; gender is required. Seeker admission separates essentials/membership/real IDV from four profile parts, permits finishing profile later, and requires explicit publication. Guardian has identity and responsibility orientation, not the Seeker roadmap.

Poppins is the reading face, including “Welcome to ZYRA”; Syne is the standalone wordmark. The current Hulu-inspired Midnight Plum gradient is #30203F → #160E20. Splash/wordmark gold #E5CE8E and Journey semantic gold #E8C98A have approved distinct purposes. Shared centred dialogs use opaque #241A2F; Glass Signals cards/Floating Glass navigation and protected comparison designs are intentionally retained.

AD-AIOS-111 supersedes historical AI seats/routes: Codex implements and files; the Founder alone approves. Internal audit, repair GO, exact production GO, post-verification and Founder acceptance remain separate. Policy-only DR-ZYRA-250 does not authorize activating Stage 2 or Unlock+.

## Executive findings

1. **F01 — Safety evidence can disappear on account deletion.** The caller-pinned deletion RPC reaches cascading report FKs. Preserve investigation evidence without silently removing account-deletion rights.
2. **F02 — A current Main Guardian can inherit ended-Journey messages.** Current active link/Main status is treated as participation across historical attempts without the required temporal/history consent boundary.
3. **F03 — A photo row can point at someone else's known private file path.** Owner-row RLS is not owner-file validation; the read helper trusts that row. No foreign file was requested.
4. **F04/F05 — Legacy APIs remain disclosure oracles.** Raw exact scoring and arbitrary-user progress helpers exceed their caller/purpose boundary; new isolated calculation tests do not protect these live entry points.
5. **F06/F07 — Unlock+ hold and credit safety are incomplete server-side.** Plus is callable despite the client hold; spending lacks account serialization/full operation identity and can charge a covered downgrade.
6. **F19 — Developer Guardian defaults can reach ordinary member logic.** A hidden toggle is insufficient if the feature itself reads a default demo override, including Journey gates.
7. **F14/F15 — Verified and moderated admission is not production-proven.** Real provider and quarantine/moderation pipelines are unfinished; publication does not enforce the full invariant. Do not present an all-verified launch claim as proven.
8. **F16–F18 — Payment intent and live entitlements diverge.** Basic funding is not proven, Family/grace hydration differs, and Guardian paid access is still inferred from linked Seeker premium.
9. **F35 — The large unapplied Sep24 migration weakens message INSERT guards.** Current live Seeker INSERT is safer; do not apply the candidate wholesale as a repair.
10. **F44/F45/F59 — Release evidence is incomplete.** Functional tests pass, but 124 historical pixel comparisons fail and current native/provider/installed-artifact acceptance remains unproven.

## Critical and high findings

Every finding below includes live/staged state, impact, minimum reproduction, repair, tests, approval boundaries and action owner. No finding closes its existing OA by being documented here.

### Smallest containment candidates — proposed, not executed

For explicit Founder production GO only: (1) if retained safety evidence cannot
be protected immediately, temporarily restrict the destructive deletion RPC
while maintaining a clearly available support-assisted deletion route; (2)
narrow the Main-only participation branch to the authorized current attempt
until separately consented history access is proven, retaining valid Seeker and
explicit Guardian assignment access; (3) reject new/changed photo references
whose object owner/path does not match the caller, preserving legitimate owned
photo reads and replacement rights through a validated write path. Each option
needs an exact SQL/grant delta, backup, synthetic rights/refusal proof, rollback
and post-verification. A client toggle, hidden button or TestFlight hold alone
does not contain an authenticated backend path. No option is permission to
erase existing evidence, broaden access or silently remove account rights.

### F01 — Account deletion cascades safety reports

- **Severity:** CRITICAL
- **Area:** Safety retention
- **Evidence:** Live delete_own_account(); profiles.id → auth.users ON DELETE CASCADE; profile_reports reporter_id AND reported_id → profiles ON DELETE CASCADE
- **Governed rule:** Safety Respect V3 and report permanence; approved bounded safety retention, DR248
- **Current client behaviour:** Account deletion invokes the caller-pinned RPC; previous wrong-account race is repaired, not this retention path.
- **Current server behaviour:** Authenticated EXECUTE allowed; deletes auth.users; no independent retained report identity in the confirmed FK path.
- **User impact:** Deleting either party can erase the report and its investigation context.
- **Security/privacy impact:** Release-blocking loss of safety evidence. Actual lost reports were NOT measured.
- **Minimum reproduction / limits:** Minimum proof: inspect function, effective ACL and FK definitions only. Do not delete a member or test live.
- **Files/functions involved:** Live delete_own_account(); profiles.id → auth.users ON DELETE CASCADE; profile_reports reporter_id AND reported_id → profiles ON DELETE CASCADE
- **Whether live data is affected:** Live authorization/deletion path confirmed; no deletion performed.
- **Recommended fix:** Prepare narrow evidence-preserving deletion/retention migration. Any interim RPC restriction must preserve a support-assisted deletion path; no silent removal of rights.
- **Tests required:** Synthetic reporter/reported deletion, open/closed case, legal hold, anonymisation, deletion retries and restored backups.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** YES — exact migration/containment GO after backup, replay and rollback proof.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-305
- **Repair phase:** 0

Source/document locators: [SOURCE/supabase/migrations/20260726170000_delete_own_account.sql](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/supabase/migrations/20260726170000_delete_own_account.sql>).

### F02 — Current Main can inherit old ended-Journey chat access

- **Severity:** CRITICAL
- **Area:** Guardian authorization
- **Evidence:** Live zyra_attempt_participant_rows Main branch w.is_main=true has no temporal/status consent bound; messages_select/conversations_select permit Guardian attempt_status <> potential
- **Governed rule:** DR232 Main active/paused boundary; DR233 past-summary opt-in never includes messages
- **Current client behaviour:** Guardian Journey reader relies on live attempt participation.
- **Current server behaviour:** Active current link grants Main participation across all historic attempts; authenticated SELECT permitted.
- **User impact:** A newly linked/promoted Main can be authorized for conversations predating that link, including ended attempts.
- **Security/privacy impact:** Live cross-user private-message authorization bypass; no observed read claimed.
- **Minimum reproduction / limits:** Catalog/view/policy/grant proof only; no member conversation queried. Affected inspection stopped.
- **Files/functions involved:** Live zyra_attempt_participant_rows Main branch w.is_main=true has no temporal/status consent bound; messages_select/conversations_select permit Guardian attempt_status <> potential
- **Whether live data is affected:** Live reachable path confirmed from catalog.
- **Recommended fix:** Scope Main to approved current attempts/epoch; preserve permitted summary projection separately. Review effective grants without granting new Guardian visibility.
- **Tests required:** Synthetic pre-link ended, post-link active/paused, revoked/relinked Main, consent summary, stranger and no historical messages.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** YES — exact RLS/view migration GO.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-290 / OA-ZYRA-291 / OA-ZYRA-305
- **Repair phase:** 0

### F03 — Photo references can defeat file-owner visibility

- **Severity:** CRITICAL
- **Area:** Storage authorization
- **Evidence:** Live profile_photos INSERT/UPDATE grants, policies user_id=auth.uid only; only PK+user FK constraints; zero photo triggers; zyra_can_read_photo_object(text)
- **Governed rule:** Image Handling privacy; DR169 cache never grants authority; private photos obey owner visibility/block rules
- **Current client behaviour:** Normal upload uses own folder; syncPhotos derives storage_path from URLs.
- **Current server behaviour:** Read helper trusts any profile_photos row referencing the path and zyra_can_view_profile(row.user_id); self visibility is true. No row-to-object-owner binding.
- **User impact:** A known other-owner object path can be referenced in the caller's own photo row and satisfy the signing/read predicate.
- **Security/privacy impact:** Private-file authorization bypass, conditional on knowledge of an object path. No image accessed.
- **Minimum reproduction / limits:** Compose the captured grant/policy/constraint/helper definitions; do NOT insert a reference, sign a target URL or download photos. Inspection stopped after minimum proof.
- **Files/functions involved:** Live profile_photos INSERT/UPDATE grants, policies user_id=auth.uid only; only PK+user FK constraints; zero photo triggers; zyra_can_read_photo_object(text)
- **Whether live data is affected:** Live metadata confirms path; affected rows/actual abuse not inspected.
- **Recommended fix:** Enforce owned object provenance at the photo-row write boundary and signing gate; reconcile historic shared seed references separately, not by weakening member authorization.
- **Tests required:** Synthetic foreign-folder reference, owned upload, blocked/withdrawn target, seed exceptions, row mutation and no stranger read.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** YES — ownership/Storage boundary migration GO.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-305 / OA-ZYRA-302
- **Repair phase:** 0

### F04 — Raw scorer is an exact-score and non-scored-field oracle

- **Severity:** HIGH
- **Area:** Compatibility privacy
- **Evidence:** score_candidates(uuid[]) live SD/auth EXECUTE; 20260811152809…sql:84-102; discovery_service.dart:312-397; profile_unlock_screen.dart:143-145,225-248
- **Governed rule:** OA285; DR250 validated inputs and purpose-scoped disclosure
- **Current client behaviour:** Browse hides returned numbers; Profile Unlock fetches them before entitlement.
- **Current server behaviour:** Visibility guard exists, but no purpose/Unlock gate or canonical scored-qid whitelist. Caller preferences can address q101/q102 and bio_* keys.
- **User impact:** Repeated own-preference changes can infer sensitive target answers from scores/absence, including fields not intended for scoring.
- **Security/privacy impact:** Major sensitive-answer inference risk despite visibility checks.
- **Minimum reproduction / limits:** Catalog/body proof only. Later use two synthetic worlds, own preference changes and canonical/unscored controls; no member calls.
- **Files/functions involved:** score_candidates(uuid[]) live SD/auth EXECUTE; 20260811152809…sql:84-102; discovery_service.dart:312-397; profile_unlock_screen.dart:143-145,225-248
- **Whether live data is affected:** Live RPC access confirmed; no oracle invoked.
- **Recommended fix:** Private canonical scorer with safe Browse projection and authorized saved Standard/Plus/Journey interfaces; preserve legitimate exclusions/order.
- **Tests required:** Effective ACLs, qid whitelist, purpose positives/negatives and complete inference transcripts.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** YES — separate integration/security migration GO.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-285 / OA-ZYRA-193
- **Repair phase:** 0

Source/document locators: [SOURCE/lib/screens/subscription/profile_unlock_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/subscription/profile_unlock_screen.dart>); [SOURCE/supabase/migrations/20260811152809_score_candidates_null_array_guard.sql](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/supabase/migrations/20260811152809_score_candidates_null_array_guard.sql>); [SOURCE/lib/services/zyra_discovery_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_discovery_service.dart>).

### F05 — Arbitrary-user progress helpers bypass own-account scope

- **Severity:** HIGH
- **Area:** Onboarding privacy
- **Evidence:** Live zyra_onboarding_missing(uuid), zyra_onboarding_complete(uuid), zyra_onboarding_data_complete(uuid,text); 20260811173212…sql:161-185
- **Governed rule:** Engineering least privilege; own-account onboarding progress, not unrelated-user disclosure
- **Current client behaviour:** App uses my-progress wrapper, not arbitrary stranger inspection.
- **Current server behaviour:** SD authenticated EXECUTE on all three; no ownership/visibility guard; missing returns qids and conditional presence.
- **User impact:** Private progress and conditional answer information can be derived for an unrelated supplied UUID.
- **Security/privacy impact:** Sensitive progress oracle, not a demonstrated raw-answer payload.
- **Minimum reproduction / limits:** Definitions/ACL only. No UUID enumeration or helper invocation.
- **Files/functions involved:** Live zyra_onboarding_missing(uuid), zyra_onboarding_complete(uuid), zyra_onboarding_data_complete(uuid,text); 20260811173212…sql:161-185
- **Whether live data is affected:** Live grants/body confirmed; no member data accessed.
- **Recommended fix:** Revoke public raw helper execution or add narrow ownership scope, retaining internal trigger/server callers.
- **Tests required:** Own, anonymous, unrelated, linked Guardian, block and null principal denials.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** YES — exact ACL/ownership migration GO.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-305 / OA-ZYRA-193
- **Repair phase:** 0

Source/document locators: [SOURCE/supabase/migrations/20260811173212_oa193c_bank_holds_all_104_chapter3_questions.sql](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/supabase/migrations/20260811173212_oa193c_bank_holds_all_104_chapter3_questions.sql>).

### F06 — Default-off Plus hold is client-only

- **Severity:** HIGH
- **Area:** Unlock Plus
- **Evidence:** zyra_unlock_service.dart:98-101,219-224; profile_unlock_screen.dart:298-300; live zyra_unlock_profile(uuid,text)
- **Governed rule:** DR250 D5/D6; unavailable Plus must not create new debit or entitlement
- **Current client behaviour:** New Plus screen/service refuses spend; labelled local sample remains protected.
- **Current server behaviour:** Authenticated RPC still accepts paid_plus_single; no availability fuse or validated result preflight.
- **User impact:** A direct API call can spend a Plus credit while the feature is unavailable.
- **Security/privacy impact:** Financial/entitlement boundary bypass.
- **Minimum reproduction / limits:** Inspect live function; do not spend real credit.
- **Files/functions involved:** zyra_unlock_service.dart:98-101,219-224; profile_unlock_screen.dart:298-300; live zyra_unlock_profile(uuid,text)
- **Whether live data is affected:** Live pathway confirmed; no spend attempted.
- **Recommended fix:** Server-owned default-off fuse across every new Plus debit path; preserve governed previously entitled access.
- **Tests required:** Off gate → zero debit/entitlement; eligible Standard works; legacy Plus governed separately.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** YES — exact server gate migration GO.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-285 / OA-ZYRA-193
- **Repair phase:** 0

Source/document locators: [SOURCE/lib/services/zyra_unlock_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_unlock_service.dart>); [SOURCE/lib/screens/subscription/profile_unlock_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/subscription/profile_unlock_screen.dart>).

### F07 — Wallet spending lacks serialization and full idempotency

- **Severity:** HIGH
- **Area:** Credits
- **Evidence:** Live zyra_unlock_profile SUM(balance) then inserts; no wallet lock/extra triggers; unique(unlocker,target,type); 20260804104818…sql:161-176
- **Governed rule:** OA192/285; atomic no-negative balance and permanent entitlement
- **Current client behaviour:** Exact-tier cache recognizes paid_single/paid_plus_single only.
- **Current server behaviour:** Different targets can observe the same last credit; same target races unique violation; Plus→Standard can charge again.
- **User impact:** Potential overspend, ambiguous retry, redundant charge; bundle/automatic legacy types may not be recognized.
- **Security/privacy impact:** Payment/credit loss risk; exploit outcome requires isolated concurrency proof.
- **Minimum reproduction / limits:** Catalog protocol proof; actual concurrency/spend not run in production.
- **Files/functions involved:** Live zyra_unlock_profile SUM(balance) then inserts; no wallet lock/extra triggers; unique(unlocker,target,type); 20260804104818…sql:161-176
- **Whether live data is affected:** Live protocol confirmed, no observed negative balances claimed.
- **Recommended fix:** Account-level transaction lock, operation id, superset entitlement normalization and atomic result/debit.
- **Tests required:** Different-target last-credit race, same-target race/lost ACK, Plus→Standard and supported legacy types.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** YES — ledger migration GO.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-285 / OA-ZYRA-192
- **Repair phase:** 0

Source/document locators: [SOURCE/supabase/migrations/20260804104818_c1_unlock_credits_ledger.sql](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/supabase/migrations/20260804104818_c1_unlock_credits_ledger.sql>).

### F08 — Completion checks presence rather than valid complete data

- **Severity:** HIGH
- **Area:** Compatibility validation
- **Evidence:** Live completeness helpers; 20260811173212…sql:138-156; onboarding_answers own writes; light_weight unknown→0
- **Governed rule:** DR250 D2; OA193/226 strict required-bank validation
- **Current client behaviour:** Parent checks some visible answers, but does not establish complete canonical matrices.
- **Current server behaviour:** Keys/nonempty JSON qualify; no full type/vocabulary/light/Hard consistency constraints; scorer skips missing mappings.
- **User impact:** Malformed or partial data can qualify as complete and produce a plausible but misleading score.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Catalog/source only; later synthetic null, unknown light, scalar/multi and partial matrix controls.
- **Files/functions involved:** Live completeness helpers; 20260811173212…sql:138-156; onboarding_answers own writes; light_weight unknown→0
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Integrate strict semantic capture/version validation and affected-only legacy review. Never bulk-clear member answers.
- **Tests required:** Entire required bank, duplicate/unknown options, missing selected-option mappings, Hard consistency, no default-red coercion.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** YES for server enforcement; scoped client integration GO also needed.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-193 / OA-ZYRA-226
- **Repair phase:** 1

Source/document locators: [SOURCE/supabase/migrations/20260811173212_oa193c_bank_holds_all_104_chapter3_questions.sql](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/supabase/migrations/20260811173212_oa193c_bank_holds_all_104_chapter3_questions.sql>).

### F09 — q24 q26 q39 preferences target the owner, not counterpart

- **Severity:** HIGH
- **Area:** Compatibility targeting
- **Evidence:** values_preferences_flow.dart:115-139,271-277; compatibility_editors.dart:155-181; chapter3_categories.dart:278,303-324,481-492
- **Governed rule:** DR250 D2 explicitly settles counterpart targeting
- **Current client behaviour:** q24 hidden by own children answer; q26 uses own-gender options; q39 uses own male applicability.
- **Current server behaviour:** Live completeness matches the old capture model, not approved counterpart semantics.
- **User impact:** Wrong/missing preferences and ineffective exclusions for potential spouses.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Trace both gender directions and q3 branches; current research fixtures prove intended semantics, not integration.
- **Files/functions involved:** values_preferences_flow.dart:115-139,271-277; compatibility_editors.dart:155-181; chapter3_categories.dart:278,303-324,481-492
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Canonical target-specific capture and migration-safe affected-only repair.
- **Tests required:** Both directions, target children conditions, q26 propositions, q39 spouse options and Hard behavior.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** YES for server/legacy repair; no new policy vote needed.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-226 / OA-ZYRA-193
- **Repair phase:** 1

Source/document locators: [SOURCE/lib/screens/onboarding/values_preferences_flow.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/onboarding/values_preferences_flow.dart>); [SOURCE/lib/screens/profile/compatibility_editors.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/profile/compatibility_editors.dart>); [SOURCE/lib/data/chapter3_categories.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/data/chapter3_categories.dart>).

### F10 — q26 alias restoration can overwrite edits or resurrect Hard

- **Severity:** HIGH
- **Area:** Compatibility restore
- **Evidence:** values_preferences_flow.dart:174-190; onboarding_answers_service.dart:193-214; compatibility_editors.dart:95
- **Governed rule:** Confirmed saved answers must survive restore/edit; OA303; DR250 no silent data changes
- **Current client behaviour:** Restores canonical q26 into both gender aliases; save collapses aliases in insertion order.
- **Current server behaviour:** Stores the final canonical q26 supplied; cannot identify which alias is the genuine edit.
- **User impact:** On male re-entry untouched female alias can overwrite a light edit or a removed Hard requirement.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Source data-path proof; later restore male q26, change light/remove Hard, save/reopen without editing About You.
- **Files/functions involved:** values_preferences_flow.dart:174-190; onboarding_answers_service.dart:193-214; compatibility_editors.dart:95
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Restore only applicable canonical variant; reject alias collisions and preserve unrelated fields.
- **Tests required:** Male/female reopen, red→green, empty Hard removal, both-alias rejection and hidden-peer preservation.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-226 / OA-ZYRA-303
- **Repair phase:** 1

Source/document locators: [SOURCE/lib/screens/onboarding/values_preferences_flow.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/onboarding/values_preferences_flow.dart>); [SOURCE/lib/services/zyra_onboarding_answers_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_onboarding_answers_service.dart>); [SOURCE/lib/screens/profile/compatibility_editors.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/profile/compatibility_editors.dart>).

### F12 — Entitlement permanence is not a shared saved calculation

- **Severity:** HIGH
- **Area:** Saved compatibility
- **Evidence:** profile_unlock_screen.dart _loadRealScore/:825-827; live unlock and OA283 reveal functions
- **Governed rule:** DR250 D5/D6 one saved directional result, not ordinary re-computation
- **Current client behaviour:** Manual score recomputes per route opening; copy promises dynamic filling.
- **Current server behaviour:** Unlock records entitlement/debit; Journey freezes first non-null directional score; common snapshot absent.
- **User impact:** The same pair/direction can show different previously purchased and Journey results after edits.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Compare source/body storage paths only; later synthetic edit after unlock/reveal.
- **Files/functions involved:** profile_unlock_screen.dart _loadRealScore/:825-827; live unlock and OA283 reveal functions
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Bind one validated saved directional result to interfaces; normalize legacy types and original-input-only free technical repair.
- **Tests required:** Manual/Plus/Journey identity, no refresh oracle, legacy rows, no duplicate automatic/paid debit.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** YES — snapshot/capture migration GO.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-193 / OA-ZYRA-285
- **Repair phase:** 1

Source/document locators: [SOURCE/lib/screens/subscription/profile_unlock_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/subscription/profile_unlock_screen.dart>).

### F14 — Real verification is unavailable and existing-account enforcement is held

- **Severity:** HIGH
- **Area:** Identity admission
- **Evidence:** identity_verification_service.dart:25-55; initial_signup_draft_service.dart:286-328; live provider result ACL; Edge functions list empty
- **Governed rule:** DR221 verified-person admission; current Stripe selection; OA266; DR253 protected opening is deliberately local
- **Current client behaviour:** Provider adapter unavailable; existing-account fuse false; new signup finalizer does re-fetch verified outcome.
- **Current server behaviour:** Private coarse state exists and provider writes are service-role only. Publication RPC does NOT require verified outcome.
- **User impact:** New ordinary signup cannot complete IDV; old/direct paths do not technically support an all-members-verified release promise.
- **Security/privacy impact:** Unbacked identity trust claim and server admission gap; no raw ID exposure found.
- **Minimum reproduction / limits:** Inspect adapter/gates/publication and provider ACL only; no synthetic/live member verification.
- **Files/functions involved:** identity_verification_service.dart:25-55; initial_signup_draft_service.dart:286-328; live provider result ACL; Edge functions list empty
- **Whether live data is affected:** Live provider/publication boundaries confirmed; member verification status not counted.
- **Recommended fix:** Complete provider callbacks/duplicate review and server admission/publication invariants, then approved rollout; no bypass to finish onboarding.
- **Tests required:** Signed callback replay/tamper/order, pending/review/failed/cancelled/verified, existing-account rollout and gate parity.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** YES — provider, server and rollout GO independently.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-266 / OA-ZYRA-303
- **Repair phase:** 1

Source/document locators: [SOURCE/lib/services/zyra_identity_verification_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_identity_verification_service.dart>); [SOURCE/lib/services/zyra_initial_signup_draft_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_initial_signup_draft_service.dart>).

### F15 — Quarantine moderation and server image validation are absent

- **Severity:** HIGH
- **Area:** Photo safety
- **Evidence:** Live private bucket no MIME/size limits; profile_photos no moderation columns/trigger; photo_service.dart:255-280; no deployed Edge Functions
- **Governed rule:** Image Handling V2; OA266/302 photo moderation before display
- **Current client behaviour:** Client safely strips metadata and bounds JPEG, then uploads directly to display bucket.
- **Current server behaviour:** Owner uploads allowed; display row has no approved moderation outcome; server cannot enforce client processor against crafted uploads.
- **User impact:** Photos can be published without the promised safety review; client processing is not server authority.
- **Security/privacy impact:** Release-blocking safety/privacy integration gap, not evidence of harmful photos observed.
- **Minimum reproduction / limits:** Catalog/source only; no upload or harmful image probe.
- **Files/functions involved:** Live private bucket no MIME/size limits; profile_photos no moderation columns/trigger; photo_service.dart:255-280; no deployed Edge Functions
- **Whether live data is affected:** Current settings/path confirmed; no objects opened.
- **Recommended fix:** Measured validated quarantine→moderation→approved-display pipeline; bounded MIME/size limits and shared seed migration separately scoped.
- **Tests required:** Synthetic safe/rejected/review image, bypass client attempt, EXIF sanitization, stored-object iOS/Android and reviewer ownership.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** YES — bucket/pipeline/provider apply GO.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-266 / OA-ZYRA-302
- **Repair phase:** 1

Source/document locators: [SOURCE/lib/services/zyra_photo_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_photo_service.dart>).

### F16 — Basic choice and fallback do not prove £4.99 funded admission

- **Severity:** HIGH
- **Area:** Membership
- **Evidence:** membership_catalog.dart checkoutAvailable=false; release_gates.dart:16; session_router.dart:419-437
- **Governed rule:** DR252 Basic £4.99 once; saved intent is not payment
- **Current client behaviour:** Signup saves intent; missing/non-One subscription hydrates Basic; paid gate false.
- **Current server behaviour:** Live lacks reconciled Basic receipt authority and paid access RPC; store callback pipeline not deployed.
- **User impact:** Ordinary access/client limits cannot be treated as paid Basic; checkout/trial/restore are incomplete.
- **Security/privacy impact:** Commercial authorization gap; no billing changed or charges tested.
- **Minimum reproduction / limits:** Trace default plan, choice storage and receipt authority; no purchases.
- **Files/functions involved:** membership_catalog.dart checkoutAvailable=false; release_gates.dart:16; session_router.dart:419-437
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Verified store products/receipts, one-time role Basic admission and honest lifecycle/restore; keep essential safety accessible.
- **Tests required:** Funded/unfunded Basic, receipt retry/refund/restore, One trial/person, cancellation/renewal/grace.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** YES — receipt/server/store/provider activation GO.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-253 / OA-ZYRA-293
- **Repair phase:** 1

Source/document locators: [SOURCE/lib/data/zyra_membership_catalog.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/data/zyra_membership_catalog.dart>); [SOURCE/lib/data/zyra_release_gates.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/data/zyra_release_gates.dart>); [SOURCE/lib/services/zyra_session_router.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_session_router.dart>).

### F17 — Paid-only candidate and Family/grace hydration conflict with current rules

- **Severity:** HIGH
- **Area:** Membership migration
- **Evidence:** 20260924100231…sql:22-24,617-716; session_router.dart:419-437; seeker_plan_limits.dart
- **Governed rule:** DR252 supersedes no-Basic candidate; DR248 Family/grace role authority
- **Current client behaviour:** Hydrates only active direct subscriptions; Family or covered cancelled/grace would look Basic.
- **Current server behaviour:** Unapplied candidate recognizes Family/grace but Basic cap0 and no Basic receipt branch.
- **User impact:** Applying candidate unchanged could lock funded Basic or show authorized Family users wrong limits.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Static candidate/client comparison only; candidate is NOT live.
- **Files/functions involved:** 20260924100231…sql:22-24,617-716; session_router.dart:419-437; seeker_plan_limits.dart
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Reconcile candidate with Basic and consume a single server-owned paid/funded role projection.
- **Tests required:** Basic admission; Family seats; covered cancellation/grace; cold start/account switch and cap parity.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** YES — revised exact candidate replay/apply GO.
- **Evidence status:** Confirmed staged contract mismatch
- **Action trace:** OA-ZYRA-253 / OA-ZYRA-293
- **Repair phase:** 1

Source/document locators: [SOURCE/supabase/migrations/20260924100231_founder_paid_only_returns_guardian_circle_contract.sql](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/supabase/migrations/20260924100231_founder_paid_only_returns_guardian_circle_contract.sql>); [SOURCE/lib/services/zyra_session_router.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_session_router.dart>); [SOURCE/lib/data/zyra_seeker_plan_limits.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/data/zyra_seeker_plan_limits.dart>).

### F18 — Linked Seeker premium still grants Guardian paid access

- **Severity:** HIGH
- **Area:** Guardian entitlement
- **Evidence:** entitlement_service.dart:26; WaliHomeShell; live wali_has_wali_one()
- **Governed rule:** DR248/252 each Guardian requires independent entitlement or funded Family place; a link never grants paid authority
- **Current client behaviour:** Guardian destinations consume legacy boolean.
- **Current server behaviour:** Returns true for own active wali_premium OR any active linked Seeker's seeker_premium; candidate does not replace it.
- **User impact:** Wrongly grants paid UI by relationship and can deny future funded Family/grace states.
- **Security/privacy impact:** Incorrect entitlement authority.
- **Minimum reproduction / limits:** Body/ACL inspection only; no subscription changes.
- **Files/functions involved:** entitlement_service.dart:26; WaliHomeShell; live wali_has_wali_one()
- **Whether live data is affected:** Legacy live body confirmed; funded member counts not inspected.
- **Recommended fix:** Resolve independent funded Guardian entitlement from canonical server projection; relationship permissions remain separate.
- **Tests required:** Linked-only, own One, Family place, grace, revoked/expired and Basic/no-paid cases.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** YES — effective entitlement RPC migration GO.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-253
- **Repair phase:** 1

Source/document locators: [SOURCE/lib/services/zyra_entitlement_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_entitlement_service.dart>).

### F19 — Ordinary Guardian page and Journey gate consume default demo override

- **Severity:** HIGH
- **Area:** Release fixtures
- **Evidence:** seeker_wali_tab.dart:94-115,171-173,237-300; journey_flow_screen.dart:329-347; dev_scenario.dart:1455-1465,1368
- **Governed rule:** Settings Identity V3 local Founder capability; no demo data for ordinary members
- **Current client behaviour:** guardianOverride defaults true without Developer Access guard; fake people/actions and preview gate used. Invitation dashboard correctly guards its fixtures.
- **Current server behaviour:** Real services/RPCs exist but overridden before use.
- **User impact:** Real account can see invented Guardian people/activity or be falsely blocked; mixed live invitation and fake roster.
- **Security/privacy impact:** Release authorization/fixture isolation defect; not a confirmed real database mutation.
- **Minimum reproduction / limits:** Source default + reachable Home route proof; existing test sets useLiveGuardianData(true), masking default.
- **Files/functions involved:** seeker_wali_tab.dart:94-115,171-173,237-300; journey_flow_screen.dart:329-347; dev_scenario.dart:1455-1465,1368
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Require fresh protected preview authorization at each override; ordinary default always live/typed unavailable.
- **Tests required:** Default ordinary Seeker/Guardian, dev allowed/denied, relaunch/claim loss, gate actual RPC and zero preview mutation.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-305 / OA-ZYRA-286
- **Repair phase:** 0

Source/document locators: [SOURCE/lib/screens/wali/seeker_wali_tab.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/wali/seeker_wali_tab.dart>); [SOURCE/lib/screens/journey/journey_flow_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/journey/journey_flow_screen.dart>); [SOURCE/lib/dev/zyra_dev_scenario.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/dev/zyra_dev_scenario.dart>).

### F20 — Real Journey/Match readers retain stranger portrait fallbacks

- **Severity:** HIGH
- **Area:** Profile truth
- **Evidence:** match_service.dart:147; journey_service.dart:308,1362; Engineering Audit V1:254,296
- **Governed rule:** Engineering audit R8; member identity must not be fabricated
- **Current client behaviour:** Missing/signing-failed real photos are replaced with picsum.photos portraits.
- **Current server behaviour:** Absent/unavailable photo does not establish any substitute identity.
- **User impact:** User may see a stranger as their actual counterpart.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Trace fallback branches only; no portrait download.
- **Files/functions involved:** match_service.dart:147; journey_service.dart:308,1362; Engineering Audit V1:254,296
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Use canonical neutral placeholder and typed photo failure, not stock people.
- **Tests required:** Empty photos, signer failure/partial result and placeholder parity across real routes.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-304 / OA-ZYRA-305
- **Repair phase:** 1

Source/document locators: [SOURCE/lib/services/zyra_match_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_match_service.dart>); [SOURCE/lib/services/zyra_journey_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_journey_service.dart>); [SOURCE/lib/services/zyra_wali_journey_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_wali_journey_service.dart>).

### F21 — Replacement deletes existing rows before confirming new ordering

- **Severity:** HIGH
- **Area:** Photo persistence
- **Evidence:** photo_service.dart:686-699; edit_photos_screen.dart _commit/_editPhoto
- **Governed rule:** Confirmed saves preserve prior valid profile data; OA302/303
- **Current client behaviour:** Delete then insert in two requests; failed commit retains old local UI and removes new uploads best-effort.
- **Current server behaviour:** Row deletion commits independently; insert failure cannot rollback it.
- **User impact:** Previously valid photo references can disappear even though UI says replacement failed.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Source request ordering proof; later synthetic insert failure after confirmed delete.
- **Files/functions involved:** photo_service.dart:686-699; edit_photos_screen.dart _commit/_editPhoto
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Atomic owner-scoped ordered replacement RPC with all validation first; cleanup objects after successful commit.
- **Tests required:** Failure between steps, timeout/ACK loss, reorder, empty list, concurrent save/account switch and old-photo recovery.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** YES — transactional replacement migration GO.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-302 / OA-ZYRA-303
- **Repair phase:** 1

Source/document locators: [SOURCE/lib/screens/profile/edit_photos_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/profile/edit_photos_screen.dart>); [SOURCE/lib/services/zyra_photo_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_photo_service.dart>).

### F27 — Private chat body is duplicated into notifications

- **Severity:** HIGH
- **Area:** Message privacy
- **Evidence:** Live notify_new_message() SD → create_notification(..., left(NEW.content,140), ...)
- **Governed rule:** Notification Specification V1 P3 and §8.1 preview minimization
- **Current client behaviour:** In-app notifications read stored body; OS push remains held.
- **Current server behaviour:** Trigger copies private conversation text into a second table.
- **User impact:** Private text persists outside the conversation's current visibility/retention context.
- **Security/privacy impact:** Major privacy-minimization contradiction.
- **Minimum reproduction / limits:** Captured function body only; no messages/notifications read.
- **Files/functions involved:** Live notify_new_message() SD → create_notification(..., left(NEW.content,140), ...)
- **Whether live data is affected:** Live trigger confirmed; no member content observed.
- **Recommended fix:** Generic event copy or governed minimized projection; coordinated existing-body retention/redaction separately approved.
- **Tests required:** Message trigger projection, blocked/ended visibility, retention/deletion and no body in logs/telemetry.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** YES — trigger/data-retention migration GO.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-231 / OA-ZYRA-305
- **Repair phase:** 0

### F34 — Returning pair archive still reads only current envelope

- **Severity:** HIGH
- **Area:** Journey return readiness
- **Evidence:** 20260924100231…sql:1148-1197; journey_service.dart:230-340; past_journeys_screen.dart:75-109; timeline_screen.dart:68-99,165-185
- **Governed rule:** DR248 fresh Ended attempt must preserve and expose previous history
- **Current client behaviour:** Archive/current lists read matches status; Timeline takes profile, not attempt id.
- **Current server behaviour:** Unapplied return candidate reuses unique matches pair envelope and creates new journey_attempts.
- **User impact:** After future return, old ended attempt can become unreachable independently.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Static future-state comparison; returns are held and migration not applied.
- **Files/functions involved:** 20260924100231…sql:1148-1197; journey_service.dart:230-340; past_journeys_screen.dart:75-109; timeline_screen.dart:68-99,165-185
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Attempt-owned history/read/routes, explicit current versus historical addresses.
- **Tests required:** Ended→new attempt, multiple archived attempts, immutable old Timeline and safety terminal case.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** YES for attempt read projections; do not activate returns with UI-only changes.
- **Evidence status:** Confirmed staged readiness gap
- **Action trace:** OA-ZYRA-156 / OA-ZYRA-299
- **Repair phase:** 1

Source/document locators: [SOURCE/lib/screens/profile/past_journeys_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/profile/past_journeys_screen.dart>); [SOURCE/supabase/migrations/20260924100231_founder_paid_only_returns_guardian_circle_contract.sql](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/supabase/migrations/20260924100231_founder_paid_only_returns_guardian_circle_contract.sql>); [SOURCE/lib/services/zyra_journey_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_journey_service.dart>); [SOURCE/lib/services/zyra_wali_journey_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_wali_journey_service.dart>); [SOURCE/lib/screens/matches/journey_timeline_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/matches/journey_timeline_screen.dart>).

### F35 — Sep24 message insert replacement loses current guards

- **Severity:** HIGH
- **Area:** Staged RLS
- **Evidence:** 20260924100231…sql messages_insert replacement; live 20260809161716 safe active seeker-only policy
- **Governed rule:** Message insert must bind exact active attempt/conversation and blocks
- **Current client behaviour:** Guardian sending is NOT live; Circle gate false.
- **Current server behaviour:** Candidate joins match_id rather than exact attempt; drops current active conversation/block protections; candidate NOT applied.
- **User impact:** Future apply could reopen old/suspended conversation or unsafe send paths.
- **Security/privacy impact:** Staged authorization regression, NOT live exposure.
- **Minimum reproduction / limits:** Compare captured live guard and staged policy only; no send.
- **Files/functions involved:** 20260924100231…sql messages_insert replacement; live 20260809161716 safe active seeker-only policy
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Keep exact attempt/current lifecycle/block authority while implementing separately approved Guardian Chat.
- **Tests required:** Synthetic old/new attempts, paused/ended, blocked pair, revoked Guardian, View/Chat and stranger.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** YES — revised candidate replay/apply GO.
- **Evidence status:** Staged regression
- **Action trace:** OA-ZYRA-298 / OA-ZYRA-296 / OA-ZYRA-305
- **Repair phase:** 0

Source/document locators: [SOURCE/supabase/migrations/20260924100231_founder_paid_only_returns_guardian_circle_contract.sql](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/supabase/migrations/20260924100231_founder_paid_only_returns_guardian_circle_contract.sql>); [SOURCE/supabase/migrations/20260809161716_oa_audit_2_4_messages_insert_honours_blocks_and_lifecycle.sql](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/supabase/migrations/20260809161716_oa_audit_2_4_messages_insert_honours_blocks_and_lifecycle.sql>).

### F36 — Unused mock purchase RPCs remain executable for seeded identities

- **Severity:** HIGH
- **Area:** Legacy developer authority
- **Evidence:** Live mock_purchase_wali_premium() and mock_set_wali_plan(text); 20260923225150 revoke candidate NOT applied
- **Governed rule:** Settings Identity V3 no email-based production authority; OA184/286 retirement
- **Current client behaviour:** Client methods removed; Founder previews do not invoke these.
- **Current server behaviour:** Authenticated EXECUTE remains; server requires @zyra.test and wali role, then mutates active subscriptions.
- **User impact:** Seeded identities retain legacy privilege independently of protected Founder claims.
- **Security/privacy impact:** Restricted seeded-identity authority, not an all-authenticated-user purchase bypass.
- **Minimum reproduction / limits:** Captured definitions/ACL only; no account login or purchase invocation.
- **Files/functions involved:** Live mock_purchase_wali_premium() and mock_set_wali_plan(text); 20260923225150 revoke candidate NOT applied
- **Whether live data is affected:** Live grants/body confirmed; seeded credential status unknown.
- **Recommended fix:** Apply proven-unused narrow revokes after dependency replay; review referenced legacy endpoints separately.
- **Tests required:** Seeded/nonseeded/anonymous ACL, no required caller broken and no subscription changes.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** YES — exact narrow revocation GO.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-184 / OA-ZYRA-286
- **Repair phase:** 0

Source/document locators: [SOURCE/supabase/migrations/20260923225150_retire_unused_legacy_purchase_mutators.sql](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/supabase/migrations/20260923225150_retire_unused_legacy_purchase_mutators.sql>).

### F37 — Live PostgreSQL is behind announced security minor

- **Severity:** HIGH
- **Area:** Database maintenance
- **Evidence:** Live server17.6; Supabase Sep25 changelog 17.11 security release; pgcrypto1.3 installed, no ltree/btree_gist extension
- **Governed rule:** Operational security maintenance; no unapproved upgrade
- **Current client behaviour:** Client does not remediate engine.
- **Current server behaviour:** 17.6 confirmed; upstream announcement closes44 CVEs across bundled cycles.
- **User impact:** Known maintenance exposure requires planned compatibility/backup review; not proof all CVEs exploitable here.
- **Security/privacy impact:** Security maintenance risk, exploitability not established.
- **Minimum reproduction / limits:** Version/extension catalogs + official changelog only; no decrypt/member probe.
- **Files/functions involved:** Live server17.6; Supabase Sep25 changelog 17.11 security release; pgcrypto1.3 installed, no ltree/btree_gist extension
- **Whether live data is affected:** Live engine version confirmed.
- **Recommended fix:** Prepare minor upgrade/compatibility plan including pgcrypto/custom operators, restore rehearsal and rollback thresholds.
- **Tests required:** Isolated upgrade/replay, auth/storage/RPC regression, extension compatibility and backup recovery.
- **Founder decision / execution authority:** Approve separately scoped infrastructure upgrade window; no new product rule.
- **Production apply approval:** YES — project upgrade exact GO.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-305
- **Repair phase:** 0

### F38 — Release configuration signs with debug key

- **Severity:** HIGH
- **Area:** Android release
- **Evidence:** android/app/build.gradle.kts:27-35
- **Governed rule:** Android release distribution requires production signing
- **Current client behaviour:** Release signingConfig uses debug.
- **Current server behaviour:** No server relevance.
- **User impact:** Cannot accept this as a Play release artifact.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Static Gradle read; no AAB/build/signing asset creation.
- **Files/functions involved:** android/app/build.gradle.kts:27-35
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Founder-owned upload signing setup without printing secrets; pin application/version.
- **Tests required:** Signed release AAB identity, debug=false, secret-free packaging and Play internal acceptance.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No DB; YES separately for signing/provider/release changes.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-286 / OA-ZYRA-305
- **Repair phase:** 1

Source/document locators: [SOURCE/android/app/build.gradle.kts](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/android/app/build.gradle.kts>).

### F39 — Default session preferences remain eligible for backup

- **Severity:** HIGH
- **Area:** Android session privacy
- **Evidence:** main.dart:104-110 default Supabase2.16 storage; Android backup XML excludes only zyra_signup_draft
- **Governed rule:** Account-session secrecy and Settings private device state
- **Current client behaviour:** Session persistence uses default SharedPreferences; secure_storage dependency exists but not installed as Auth storage.
- **Current server behaviour:** Android cloud/device transfer can include unexcluded preferences.
- **User impact:** Bearer session material may migrate with backup; no actual backup/token inspected.
- **Security/privacy impact:** Major credential-handling risk; no credential read or exposure observed.
- **Minimum reproduction / limits:** Source + default SDK documented storage + backup rules; no device backup performed.
- **Files/functions involved:** main.dart:104-110 default Supabase2.16 storage; Android backup XML excludes only zyra_signup_draft
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Secure session storage with deliberate migration and comprehensive backup exclusions; avoid silent logout/data loss.
- **Tests required:** Cloud/device restore synthetic account, encryption/key loss/recovery, logout and no bearer export.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No DB; scoped native/session migration and release GO.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-286 / OA-ZYRA-305
- **Repair phase:** 0

Source/document locators: [SOURCE/lib/main.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/main.dart>).

## Feature audit matrix

“Tests” means measured scope, not blanket certification of every state. Confirmed useful protections are retained alongside gaps.

| Feature | Product rule | Client | Server | Tests | Status |
|---|---|---|---|---|---|
| Authentication/startup | OAuth/recovery, caller-owned route, no fabricated success | Provider failure recovery/late callback guards covered; default SDK session store used | Profile caller scope and protected IDV writes present; session backup issue remains | Full local suite; no real OAuth/OTP/restore device E2E | PARTIAL — F39/F44 |
| Protected opening | DR253 four purpose-led preview pages, tap/reveal/section motion | Protected and deliberately absent from ordinary OAuth | Not a server admission grant | Current reader tests pass; pixels require acceptance | HELD BY DESIGN — not restored seven-slide bug |
| Names/gender/DOB | DR251 public required first+last; DOB private; required gender | Current admission questions enforce required fields and draft restoration | Frozen DOB/gender on first publication; surname not a server admission requirement yet | Current local regressions; no live signup | PARTIAL — no new surname privacy change |
| Seeker profile setup | Essentials+IDV first; enter app or finish four parts; explicit publish | Current coherent routing/resume; four-part profile separate | Completeness semantic/IDV/photo invariant incomplete | Regression pass != validated publication | HIGH — F08/F14/F15 |
| Guardian onboarding | Distinct identity and responsibilities orientation | Distinct role flow, no Seeker four-part roadmap | Provider/funding incomplete; linked premium authority old | Synthetic role tests; provider E2E missing | HIGH — F14/F16/F18 |
| Membership choice | Choice is intent; role Basic £4.99 once; One/Family current rules | Intent stored, checkout unavailable; client Basic fallback | Receipt/store activation held; Sep24 Basic cap0 stale | Local catalog/plan tests; no purchase | HIGH — F16/F17 |
| Guardian role funding | Independent Guardian or explicit Family coverage | Entitlement service reads live helper | Linked Seeker premium still grants paid access | Helper body/catalog; no billing invocation | HIGH — F18 |
| Verification/admission | Real verified person; server-only trusted result | Provider adapter unavailable; new finalizer rechecks | Private state/ACL good; publication omits verified state | No callback/duplicate/existing-member live proof | HIGH — F14 |
| Photos/upload | Private owner-bound file, stripped metadata, quarantine/moderation | JPEG processing present; row replacement non-atomic | Foreign path binding flaw; no quarantine/size/MIME authority | Local processing tests; no live object read | CRITICAL/HIGH — F03/F15/F21 |
| Browse/listing | Photo-first, current visible complete eligible target | No page bound; decision failure can erase local state | Raw score helper exceeds governed purpose; IDV not visibility invariant | Local Browse tests; scale/JWT missing | HIGH/MEDIUM — F04/F22/F54 |
| Pass/save/consider | Honest ack, limits, mutual match moment | Unsave failures swallowed; real Consider presentation incomplete | Decision writes exist; acknowledgement behavior not fully proved | Focused core tests overlap full suite | MEDIUM — F25/F32 |
| Incoming Potentials | Approved One-only surface, not fabricated teaser | Not implemented; old tease deliberately removed | No new activation audited | No acceptance path yet | INFORMATIONAL — F33 |
| Connections/Begin | Successful state or explicit reason; exact owner/request | Failed first load looks empty; false Begin silent; guards incomplete | Live Journey boundary exists; client suppresses failure | Synthetic paths; gaps itemized | MEDIUM — F23/F24/F26 |
| Journey return/history | New epoch, exact archive, separation of historical authority | Archive readers use current envelope; returns held | Large candidate unapplied; live current participation flaw | Catalog/static replay evidence; no restart invocation | CRITICAL/HIGH — F02/F34/F35 |
| Shared Pause/milestones | Approved exact attempt state and authorized actions | Unavailable/held paths retained | New pause capability candidates not applied | Current local fuses, not server E2E | HELD — F57 |
| Seeker chat | Active exact attempt, participant, block; durable idempotency | Retry has no operation identity; unbounded history | Live INSERT guards active Seeker/current attempt; staged replacement unsafe | No member messages queried/sent | HIGH — F30/F35 |
| Guardian chat/Circle | Authorized participant, stage, history and scoped lanes | Family messaging/Circle held | Candidates present, not deployed; no silent activation | Scope-specific proofs pending | HELD — F57 |
| Guardian linking/Main | Current link, attempt permissions, no fixtures as truth | Default developer override reaches ordinary Seeker Guardian tab | Main history row broad; optional Main/known-code work held | Current local tests; direct-role JWT needed | CRITICAL/HIGH — F02/F19 |
| Guardian Network | Own role entitlement; unavailable != no access | Failure and upgrade copy conflate held capability | wali_has_wali_one uses linked paid Seeker | Catalog/source evidence | HIGH/MEDIUM — F18/F31 |
| Guardian management | Specific person/action/consequence, accessible | Quiet Confirm lacks subject/action; FittedBox shrink | Permission checks not loosened by audit | Large-text native semantics not proved | MEDIUM — F50/F51 |
| Compatibility validity | Canonical enum/type/full answer, counterpart preference | q24/q26/q39 target mismatch; q26 alias; JSON/None conflict | Presence-only checks; unknown weights0; legacy raw oracle | 266 focused overlapping passes; selected missing cases | HIGH — F04/F08–F11 |
| Standard/manual compatibility | Correct visible fields, permanent saved calculation | Manual scorer recomputes | Legacy helper has no unified saved calculation | Stage1 206 isolated passes, not wired/live proof | HIGH — F12 |
| Journey compatibility reveal | Confirmed role, active unpaused attempt and saved access | OA283 guarded reveal path present; failures misleading | Direct anon/auth base-table reads denied; RPC checks inspected | Existing boundary tests; privacy risk remains elsewhere | GUARDED PARTIAL — F12/F13 |
| Unlock+/credits | Held unless server approved; atomic funded operation | Client default off | Direct Plus callable; ledger race/double-charge; Guardian current-state gap | No unlock/credit invocation | HIGH/MEDIUM — F06/F07/F58 |
| Notifications | Generic private event, read-only semantic actions, subject retained | Late read guards repaired; My ZYRA drops Journey subject | Chat snippet copied; recipient UPDATE fields broad | Current notification tests; push held | HIGH/MEDIUM — F27/F28/F29 |
| Push/promotion | Truthful unavailable, permission+provider before send | Preview wording in ordinary settings; remote pipeline held | No push activation performed | Local preference tests; device/provider missing | HELD/COPY — F53/F57 |
| Profile/settings parity | Shared wordmark/body/color/actions; role-specific truth | Opaque shared dialogs fixed earlier; cold Guardian name fallback | Profile data authority unchanged | Real-font modal3 pass; old pixels124 fail | PARTIAL — F45/F47–F52 |
| Hide/block/report | Always available essential safety, confirmed result/retry | Visible control paths present; lost ACK operation identity absent | Report storage cascades on deletion; safety status RPC restored | No report/block invocation; retry/delete synthetic proof needed | CRITICAL/HIGH — F01/F30 |
| Delete/recovery/privacy | Own caller, retained safety, honest retention/session facts | Caller-pinned delete fixed previously; absolute privacy copy stale | Deletion cascade remains; restore/provider evidence incomplete | No deletion/recovery requested | CRITICAL/MEDIUM — F01/F39/F40 |
| App Lock/notifications/preferences | Accessible descriptive semantics and confirmed ownership | Switch/choice semantics incomplete candidates | No new settings authority introduced | Native screen-reader proof absent | MEDIUM — F47 |
| Feedback/help | Working truthful destination, operable narrow layout | Send service present; fixed category Row enlarged-layout candidate | No feedback submitted | No overflow reproduced; targeted fixture needed | MEDIUM CANDIDATE — F61 |
| Android/iOS release | Correct signing/backup/platform/privacy, immutable artifact | Android debug signing; iPad1,2; plugin manifests present | Live PG patch behind; store/provider held | No fresh build/install/store submission | HIGH/MEDIUM — F37–F44/F59 |
| Documentation/evidence | Newest DR and measured current facts, preserve history | Current code not consistently matched in older current files | Live/source aliases and unapplied candidates separate | Index regenerated only after this report | MEDIUM — F46/F55/F59 |

## Security and privacy

### Authentication and authorization

OAuth is the ordinary signup/login route; configured recovery email OTP is a recovery route, not an invented password/signup path. No member token was examined. SharedPreferencesLocalStorage in the installed Supabase Flutter 2.16 source persists the session string; app initialization does not replace it, while Android backup excludes only the signup draft (F39). This is a backup/session boundary gap, not proof a token was stolen. Android backup defaults must be assessed against [Android Auto Backup documentation](https://developer.android.com/identity/data/autobackup).

Caller-pinned deletion, caller-safe safety status and coarse provider-state service-role ACLs are useful existing protections. They do not cure destructive FK chains, publication invariants or arbitrary-UUID helper access. Role/account/request guards repaired earlier are not universal; F26 records the remaining source paths without claiming observed cross-account exposure.

### RLS, RPCs and views

All inspected public/private base tables have RLS enabled; inspected private tables do not grant anon/authenticated direct reads/writes. That does not guarantee function bodies or definer views enforce policy. There are 136 public functions, 123 SECURITY DEFINER; 98 are executable by authenticated and 0 by anon in this catalog inventory. All inspected definer functions set an explicit search_path. These counts are not 98 vulnerabilities: many are the intended caller-checked interface.

The single advisor SECURITY DEFINER view warning was investigated: `zyra_my_attempt_participation` does filter self identity. The confirmed problem is the underlying Main/history branch and messages/conversations SELECT envelope (F02), not the label alone. `zyra_attempt_participant_rows` and `zyra_data_ownership` have no anon/authenticated SELECT grant. An absent WITH CHECK on storage UPDATE defaults to USING under PostgreSQL policy rules; it was **not** falsely reported as a standalone vulnerability.

Unsafe legacy scoring/progress helpers, seeded-account mock purchase authority, notification update columns, and staged message policy replacement are separately itemized. Each proposed change needs direct-role/JWT and gateway proof, not a superuser-only test.

### Storage and photos

The profile-photos bucket is private. “Private bucket” alone is insufficient: own profile row permissions allow a known foreign storage path, and the read helper trusts that reference (F03). No foreign path was enumerated or requested. Capture owner-bound authoritative constraints/triggers or a narrowly scoped write API, and prove storage/RLS behavior for stranger, block, withdrawn visibility, expired/replaced file and account deletion.

The current client JPEG/metadata/size handling is real and worth retaining. No bucket MIME/size cap, moderation/quarantine state, trusted server validation or deployed image-processing Edge Function was established (F15). Client metadata removal is not moderation. Replacement currently deletes old database rows before confirming new insertion/order (F21); preserving photo state across partial failures needs an atomic design.

### Messaging and Guardian history

Current live Seeker INSERT enforces active conversation/attempt, participant sender and no block. Guardian send/new Circle functions are not silently counted as live. The large Sep24 candidate regresses those INSERT protections (F35). Its apply remains held.

Current Main membership is expanded across old attempts; message SELECT permits Guardians on non-potential attempts (F02). Require history-specific temporal authorization and prove new/replaced/revoked Main, additional Guardian, unlink, block, ended/return epochs and signed-in nonparticipant refusal. Do not remove approved current Guardian support while fixing history. Private chat bodies are duplicated into notification body snippets (F27), and message/report retry has no operation identity (F30).

### Compatibility and disclosure

Current Journey reveal's caller/current active-unpaused gate and base-table denial were confirmed. Legacy raw scorer, presence-only validation, non-scored q101/q102/Journey Bio oracle, counterpart targeting, restored aliases and separate manual result authority remain gaps. Stage1 is isolated/unwired; Stage2 is research/staged. Historical OBS01 99 versus 100 in two synthetic worlds demonstrates residual inference, not a newly replayed live attack (F60). Standard exact result remains intended; full transcript and incremental Plus risk require measured acceptance. Permanent entitlement does not automatically authorize disclosing a withdrawn target's connected Guardian basics (F58).

### IDV, logging and safety

Provider result/session writes are service-role-only; raw provider evidence is not exposed to clients in the inspected coarse state boundary. Current selected provider is Stripe; no deployed callbacks/duplicate-person pipeline/E2E was proven. Existing-account IDV fuse is off and publication lacks verified enforcement (F14). Approval of the principle does not mean the all-verified claim is established today.

Remote product telemetry is default off in the inspected current flow; a bounded 200-event local diagnostic log exists. “No tracking/analytics” as an absolute is therefore not evidence-backed, nor is an absolute on-device/archive statement given backup and retained data paths (F40). No new AI/analytics processing was introduced. Safety reporting remains independent of upgrade/paywall, but report persistence must survive identity removal under approved bounded retention (F01). No safety cases were read or deletion exercised.

### Public claim check

| Claim/topic | Current evidence | Release disposition |
|---|---|---|
| All members verified | Provider unavailable and admission/publication invariant incomplete. | Keep as intended product direction; do not publish as proven operational fact (F14). |
| Photos private/secure | Private bucket and visibility helper exist; owner-binding flaw confirmed. | No absolute claim until F03 and validated delivery tests pass. |
| Photos stripped/moderated | Client processing exists; trusted quarantine/moderation absent. | Separate stripping from moderation; never say moderation complete (F15). |
| No tracking / only on device | Local diagnostics/session backup and recovery/server records exist. | Use measured scoped facts after technical/legal reconciliation (F39/F40). |
| Basic/One/Family/verification fee | Prices approved; intent is not a receipt, active provider or entitlement. | Retain approved prices; explicitly distinguish held purchase capability (F16–F18). |
| Guardian together journey | Intended linked support; historical visibility boundaries incomplete. | Do not use invasive/infinite-history claim; repair exact permissions (F02/F58). |
| AI / intelligence | No new member-data AI processing authorized or introduced. | No unsupported inferred/AI promise; keep held work and research labelled. |

## Product contradictions

| Topic | Approved rule | Current behaviour | Required resolution |
|---|---|---|---|
| Safety deletion | Bounded retained safety evidence survives account deletion. | Live report FKs cascade on deletion. | F01: separate retained safety record from removable identity. |
| Guardian history | Main/history access respects attempt, temporal access and separate history consent. | Current Main participation reaches ended attempts without that bound. | F02: preserve lawful current access; isolate history authorization. |
| Photo object ownership | A member may reference only their own validated private file. | Own profile row can point to another owner's known object path. | F03: authoritative owner/object validation. |
| Photos before deeper disclosure | Current visibility rules, not arbitrary raw scoring, control disclosure. | Authenticated raw scorer returns exact scores and uses non-scored preference/bio fields. | F04/F05: caller/target/purpose-bound APIs; revoke unsafe legacy entry points after proof. |
| Held Unlock+ | Default-off hold must also hold at server authority. | Direct Plus RPC remains callable. | F06: server hold; no new Plus activation. |
| Credits | One funded atomic operation; approved upgrade/permanence rules. | Balance checked without account serialization; Plus→Standard can charge again. | F07: serialized ledger and operation identity. |
| Compatibility answer meaning | Owner answers and desired-counterpart preferences are distinct. | q24/q26/q39 target owner; aliases and JSON restoration disagree. | F08–F11: canonical validation, counterpart targeting and alias migration proof. |
| Saved calculation | First entitlement and Journey reveal reuse the governed immutable result. | Manual views recompute; Journey has a separate saved boundary. | F12: shared authority without losing approved privacy. |
| Verified admission | All admitted/published people satisfy real verified-person admission. | Provider unavailable; existing-account fuse off; publication omits IDV check. | F14: provider, server and existing-account rollout before claim. |
| Photo safety | Validation, quarantine, moderation and delivery happen before publication. | Client processing exists; server/quarantine/provider pipeline not established. | F15/F21: validated atomic pipeline, not client metadata as moderation. |
| Funded Basic | DR252: role Basic costs £4.99 once; choice is not entitlement. | Client falls back to Basic; no confirmed receipt activation. | F16: funded admission/restore authority. |
| Current commercial contract | Basic + role One + Family/coverage according to DR248/252. | Sep24 candidate gives Basic cap 0; client ignores Family/grace coverage. | F17: revise candidate and use server-owned entitlement projection. |
| Guardian membership | Guardian role access is independently funded; Family coverage is explicit. | Linked Seeker premium still grants wali_has_wali_one(). | F18: reconcile effective entitlement, not inferred sponsorship. |
| Live versus preview truth | Member data and capabilities are never replaced with developer defaults. | Guardian demo override reaches ordinary flow; stranger portrait fallback remains. | F19/F20: protected fixture boundary and truthful unavailable states. |
| Private messages | Private content is not duplicated into unrelated notification stores. | Live trigger copies the first 140 message characters. | F27: generic event payload and bounded approved cleanup. |
| Returning Journey / message authority | Exact attempt, active state, block and actor permissions survive returns. | Unapplied Sep24 policy weakens guards; archive readers use current envelope. | F34/F35: hold candidate; exact-attempt archive and policy proof. |
| Privacy statements | Claims match measured retention, access, local diagnostics and recovery. | Absolute no-tracking/on-device/no-archive wording exceeds implementation. | F39/F40/F42: measured technical facts and separately approved privacy submission. |
| Supported platforms | Accepted phone scope and physical delivered artifact are explicit. | iPad remains targeted; source/build/phone equivalence unverified. | F41/F44/F59: Founder scope decision and exact native acceptance. |

These 18 topics cross-reference findings and are not 18 extra defects. DR252 resolves the supplied brief's no-Basic contradiction; no Founder pricing re-vote is needed.

## Duplicate and dead code

| Item | Classification | Evidence | Recommended action |
|---|---|---|---|
| Separate compatibility readers | Logic overlap, not byte-identical files | Manual profile scorer and saved Journey reveal have different authority (F12). | Consolidate authority after semantic/privacy replay; retain distinct presentations. |
| Multiple entitlement projections | Contract duplication | Client Basic/One hydration, linked-Seeker Guardian premium and unapplied paid-access projection disagree (F16–F18). | One role-specific authoritative projection; do not remove Basic. |
| Four old screens | Ordinary-route dead-code candidates | notifications_screen.dart; wali_notification_settings_screen.dart; guardian_detail_screen.dart; journey_map_screen.dart have no ordinary imports (F56). | Verify fixture/deep-link/tests first; cleanup only under an approved brief. |
| Historical/current style recipes | Historical/preview overlap | Midnight Plum text has old and new meanings; approved glass cards/nav and a protected settings comparator remain (F55). | Clarify current recipe; no blanket glass removal. |
| Migration identities | Reconstruction/history overlap | 28 same-name/different-version migrations plus safety alias; not 41 unapplied features. | Build exact semantic provenance bridge, preserve ledger; no renumber/reapply sweep. |
| Repeated copy/reachability inventory | Candidates, not proven duplicates | Prior UI inventory: 416 copy and 17 reachability candidates; search hits are not behavior proof. | Written refusal to delete or count all as defects; inspect scoped ordinary paths. |

Fresh safe content hashing found zero exact duplicate Dart file groups across 271 files. Prior inventory found no duplicate widget names; that prior result was not freshly re-run. Similar card copy, filename “glass”, preview controls, protected fixtures and historical migration aliases are not deletion permission. The broad structural documentation walker was refused because it does not prune PRIVATE; the bounded documentation-index generator does.

## Truth-state defects

| Dimension | Affected paths | Required truthful distinction |
|---|---|---|
| Empty / failed | Decisions F22; first Connections load F23; Guardian Network F31. | Confirmed zero != unavailable. Retain current-owner last-known data or explicit Retry, never fabricate empty. |
| Stale / current | Connections/Guardian requests F26; cold-start name F52; delivered build F59. | Account, request revision, route lifetime, exact attempt and artifact identity matter. |
| Unread / unresolved | My ZYRA subject loss F29; generic payload F27/F28; unread scale F54. | Read status is not resolution; retain event subject and authoritative count, not notification-body identity. |
| Available / unavailable | False Begin F24; IDV/provider F14; Guardian Network upgrade F31; held features F57. | Explain refusal/retry where appropriate; no pay promise for an unavailable service. |
| Paid / unpaid | Basic fallback F16; Family/grace F17; linked premium F18; credits F07. | Stored intent/client plan enum != funded role entitlement/confirmed ledger operation. |
| Dev / live | Guardian fixture override F19; stranger portraits F20; ordinary preview copy F53. | Protected synthetic data remains synthetic; never silently fill a real member read with mock identity. |
| Success / unknown commit | Unsave F25; photo replacement F21; message/report lost ACK F30. | Use operation identity/reconciliation and confirm server state instead of optimistic success or duplicate retry. |

## Release leakage

The current gates disable public developer entry and hold Plus, returns, family messaging, receipts/paid access and provider activation where recorded; their existence is not a complete release guarantee. F19 shows ordinary consumers of the developer Guardian override, so hiding controls is insufficient. F20 records picsum stranger portraits in real Journey/Match readers. F36 is authenticated execution of legacy mock purchase RPCs restricted to seeded @zyra.test Guardian identities, **not all-user free purchase**. Client callers are absent, but server authority remains until scoped retirement.

No secret leakage was found in the safely inspected ordinary artifacts; protected credential contents were intentionally not opened, so this is not a global secret scan certificate. Test identities/fixtures were not deleted. Native PROFILE signing or a production flavour alone does not prove all release gates. Android release configuration still uses the debug signing key (F38); [Android's official app-signing guidance](https://developer.android.com/studio/publish/app-signing) distinguishes that from proper release signing.

iPad remains in device-family 1,2 despite phone-only accepted scope (F41). No App Store Connect/TestFlight state was freshly mutated or certified. Current source, earlier build number +5 and current phone installation must not be conflated.

## Accessibility

| Priority | Finding | Screens/measurement | Boundary |
|---|---|---|---|
| P1 before member release | F47 descriptive labels and selected semantics | Privacy/App Lock/Notification switches; feedback/personalisation choices. | Source evidence; native VoiceOver/TalkBack behavior still requires proof. |
| P1 | F48 accessible photo navigation/dismiss and action targets | Seeker/Guardian profile actions, 36–40px areas versus 48px common controls. | Preserve visual layout while providing operable hit/semantic controls. |
| P1 | F49 small-text contrast | Feedback 11.5px ink .30 and settings 13px ink .38 over current plum gradient; estimated ratios2.65–3.57. | Measure composited actual surface, not flat token only. |
| P1 | F50 large-text shrink | Guardian FittedBox scaleDown can shrink copy and targets; current no-overflow tests allow it. | A passing no-overflow test is not accessible readable text. |
| P2 | F51 named confirmations | Quiet Guardian Confirm lacks action/person context. | Speak consequence and specific action; do not change permission policy. |
| P2 candidate | F61 narrow enlarged feedback Row | Fixed chip Row at320px/1.4x/2x with keyboard. | Overflow not reproduced; measure before changing layout. |
| Acceptance | F44 native and assistive E2E | Real Poppins, 320/390 layouts, keyboard, reduced motion, focus, dynamic text, assistive navigation. | Automated modal3 pass does not certify whole-app accessibility. |

No unnecessary tap/swipe instructional copy is proposed. Brand/Syne wordmark exceptions remain explicit; body text remains Poppins.

## Performance

Measured fresh checks: whole analyzer8s; nonvisual suite~120s; full historical visual comparison34s. These are developer-check times, **not device frame/network measurements**. No production member latency or UI frame profile was taken.

F54 records unbounded Browse/history loads and fetching all unread IDs. Profile with representative synthetic population/history, cold/warm resume, concurrent role/session replacement and failing networks. Capture bounded query/cursor payload, time-to-first-card, memory, rebuild/raster/jank, gold-dust/motion reduced-mode behavior and cache invalidation. Do not add a cache that bypasses privacy/current-attempt checks.

Fresh database performance advisors report 14 unindexed FKs, 22 unused indexes, 6 permissive-policy entries and 4 no-PK tables. The four no-PK tables are probe/seed/guard tables, not four established member-table defects. Unused does not mean safe to drop; history of use and deployment age matter. Scope representative EXPLAIN/catalog checks and replay before index work. See official linter guidance for [FK indexes](https://supabase.com/docs/guides/database/database-linter?lint=0001_unindexed_foreign_keys), [unused indexes](https://supabase.com/docs/guides/database/database-linter?lint=0005_unused_index) and [multiple policies](https://supabase.com/docs/guides/database/database-linter?lint=0006_multiple_permissive_policies).

## Test audit

| Check | Fresh result | Interpretation |
|---|---|---|
| flutter analyze --no-pub | Exit0; no issues;8s. | Static analysis only. |
| Explicit225 nonvisual *_test.dart files | 2,487 passed /2 skipped /0 failed; exit0;~120s. | Full functional local suite for this inventory; no provider or backend membership invocation. |
| Existing full visual regression suite | 211 passed /124 failed /335 total; exit1;34s. | Not green. No --update-goldens or approved-baseline overwrite. |
| Focused failing golden | guardian-dashboard-thinned-additional-neutral__small:99.99% pixels mismatch;181,733 different pixels. | One failure class independently confirmed; full124 error classes were not retained/classified. |
| Real-Poppins modal suite | 3 passed; exit0; capture disabled. | 320/390 layouts and1.0/1.6/2.0 scales; scoped shared dialog proof. |
| Parallel compatibility/core suites | 266 compatibility passes including206 Stage1;21 core-action passes. | Overlapping subsets of full suite, not additional total. |
| Stage2 database-free baseline runner | Exit1;4 of45 anchor hashes drift before runtime. | No --evidence, VM, database or fresh112-test integration result. |
| Historical Stage2 research | 112 passes;1 privacy counterexample;11 deferred in old evidence. | Historical only. OBS01/REV05 residual risk is not closed. |
| Flakiness | No repeated-run flake campaign. | Do not call failed goldens flaky; no flake-free claim. |
| Missing/insufficient acceptance groups | 58 non-informational finding groups each specify required tests. | Not58 absent files/cases; synthesis, device/JWT, fault/retry, privacy and visual acceptance proof remain. |

The initial unsupported `--exclude-path` invocation exited64 before tests; it was replaced with the explicit safe file inventory and is not a product defect. Nonvisual full output was truncated by the terminal; the final counts/exit were preserved, not a complete raw stdout archive. Detailed receipts list commands and boundaries. Default golden comparison wrote/replaced diagnostics under test/visual/failures; there are496 PNGs now. No exact pre-run count was captured, so not all496 are attributed as newly created today.

Prior OA304 candidate-only335 layout checks and3 modal checks passed; they are not the fresh approved-pixel result. Do not replace baselines simply to make green. Fresh acceptance must separately identify real layout defects versus approved design drift.

### Required regression programme

Every F record supplies targeted tests. Minimum shared matrix: anonymous/other user/current user/Seeker/Guardian/service role; live current/ended/returned/revoked/blocked/hidden/safety-held; pending/error/unknown commit/retry/duplicate/reordered ACK; funded/unfunded/refunded/cancelled/grace/Family seat; account switch/late load/dispose/route cover; real-font compact/large-text/keyboard/reduced-motion/assistive controls. Direct SQL-superuser success is not a client JWT authorization proof. Cross-user tests must use synthetic authorized local/staging data, never Founder or live member accounts by default.

## Backend audit

Catalog-only inspection of project sxoaxonzjqkgajmlagyk confirmed ACTIVE_HEALTHY metadata and PostgreSQL17.6 (server170006). The project name containing “LAB” does not make it disposable: it is the authoritative configured endpoint.

| Area | Observed authority | Required disposition |
|---|---|---|
| Relations | 60 inspected public/private/storage relations; base-table RLS enabled; private direct anon/auth grants absent. | Preserve denial; fix helper/policy-level gaps F01–F05. |
| Functions/grants | 136 public;123 SD;98 authenticated SD;0 anon SD; explicit SD search paths. | Review caller, target, role, temporal/purpose checks. Counts alone are not exploits. |
| Views | Self-scoped my_attempt view accessible; underlying participant/data-ownership views not client SELECT. | Fix Main history envelope, not blanket rename all definer views (F02). |
| Storage | 1 private profile bucket; no MIME/size limit; owner-path write policies; read helper trusts profile reference. | Owner-bind reference and trusted validation/quarantine F03/F15. |
| Message authority | Live active Seeker INSERT guarded; SELECT inherits participant history; trigger copies content snippet. | F02/F27/F35; current policy != unapplied candidate. |
| Realtime | 8 publication tables inspected. | Publication presence != proven per-role Realtime leakage or safe delivery; JWT subscription tests required. |
| Extensions | 5 installed: plpgsql, pg_stat_statements1.11, uuid-ossp1.1, pgcrypto1.3, supabase_vault0.3.1; no ltree indexes. | Review PG patch compatibility without decryption/member probes. |
| Schema ownership | anon/authenticated CREATE false for inspected public/private schema authority. | Useful negative evidence; no temporary-function exploit probes. |
| Provider ACL | Coarse private status and provider result writers restricted to service authority. | Useful boundary; no deployed Edge Functions listed, real pipeline unproven. |
| Safety status | Caller-pinned my-safety-cases and restored status RPC present. | Do not confuse restored status with retained reports after deletion. |
| Migrations | 211 applied;222 local SQL files; latest live safety RPC20260925202103. | Semantic provenance, not blind apply of missing timestamps. |

### Live/source migration drift

41 local versions are not present live; 30 live versions are absent at the same local timestamp; 28 of those are same-name timestamp aliases. The restored safety RPC also has a local/live timestamp alias, and two absent Aug11 timeline/rewind files need provenance reconciliation. No same-version name drift was found. These counts are **not** “41 approved unapplied changes”.

The large `20260924100231_founder_paid_only_returns_guardian_circle_contract.sql` is unapplied and contains stale Basic treatment plus the INSERT regression. Later Guardian Circle participant identity/receipts, optional Main/known-code, telemetry, developer RPC retirement and returns/shared-pause capabilities also remain staged as recorded. OA283/290/291 are applied protections; do not blindly replay older candidates over them. Preserve the actual migration ledger and reconstruct an exact dependency/definition bridge.

### Advisors and platform maintenance

Security advisor counts: 16 RLS-enabled/no-policy objects;1 definer view;98 authenticated definer functions;1 leaked-password protection warning. Server-only tables intentionally lacking client policies are not automatically defects. ZYRA ordinary OAuth/recovery OTP does not use an app password signup path; assess warning applicability rather than treating it as proven password compromise.

Live17.6 is behind the [Supabase Sep25 announcement of17.11/15.19 security minors](https://supabase.com/changelog/postgres-15-19-17-11-breaking-changes). The announcement aggregates44 CVEs over patch cycles; this audit does not claim all44 apply to ZYRA. Installed pgcrypto requires upgrade compatibility review; no ltree/btree_gist installation was found. Prepare a separately approved maintenance window, backup/replay/rollback and monitoring; no upgrade was executed.

Pinned package version drift is not proof of a vulnerable package. A complete current advisory sweep was not performed and no CVE-free claim is made. Reconcile official advisories and actual platform usage before any controlled upgrade; follow [Dart advisory guidance](https://dart.dev/tools/pub/security-advisories).

## Documents requiring correction

No product/legal contract was rewritten in this audit. Proposed corrections below preserve history and current authority, and are separate from approval of repairs.

| File (ZYRA-relative) | Problem | Correct authority | Proposed update |
|---|---|---|---|
| SYSTEM/DOCUMENTS/ZYRA_SETTINGS_AND_IDENTITY_CURRENT_VERSION_V3.md | Old build2/3 and flow paragraphs remain amid later overlays. | DR251/252/253; current source; exact delivery receipt. | Add concise current as-built banner and dated flow/delivery limits; retain historical entries. |
| SYSTEM/DOCUMENTS/ZYRA_PRIVACY_POLICY_IDV_SECTIONS_CURRENT_VERSION_V1.md | Draft names Sumsub despite current Stripe selection. | DR248 / current IDV capability and legal review gate. | Correct proposed provider scope after capability confirmation; remains draft, not published privacy approval. |
| APP/Standards/IMAGE_HANDLING_CURRENT_VERSION_V2.md | Original-retention language does not match current client JPEG no-original pipeline. | Current photo handling handoverV2; approved privacy/server safety. | Separate current client facts from unbuilt trusted/quarantine/retention authority. |
| SYSTEM/DOCUMENTS/ZYRA_PAID_MEMBERSHIP_HANDOVER_CURRENT_VERSION_V5.md and prior preserved current filenames | Paid-only historical text can be mistaken for active no-Basic policy. | DR252; BUSINESS/ZYRA PRICING/ZYRA_PRICING_CURRENT_VERSION_V6.md. | Explicit Basic overlay and receipt/role funding holds; preserve superseded record. |
| SYSTEM/DOCUMENTS/ZYRA_STYLE_DEFAULT_HANDOVER_CURRENT_VERSION_V1.md | Early Midnight Plum recipe means a different background from current token. | OA257 current Hulu gradient, Poppins/Syne/gold and opaque modal overlay. | One current recipe banner; do not erase deliberate glass/nav/comparison history. |
| SYSTEM/DOCUMENTS/ZYRA_FULL_HEALTH_CHECK_HANDOVER_CURRENT_VERSION_V1.md | Earlier snapshots are not current app release proof. | This audit, live catalog and measured current checks. | Cross-link current risks/holds; do not self-close older findings. |
| SYSTEM/DOCUMENTS/ZYRA_COMPATIBILITY_SERVER_STAGE2_HANDOVER_CURRENT_VERSION_V1.md | Sealed older baseline differs at4/45 current anchors. | DR250; current baseline bridge and historical OBS01. | Append dated drift/refusal/current replay limit, preserve original evidence. |
| SYSTEM/DOCUMENTS/ZYRA_APP_STORE_RUNBOOK_CURRENT_VERSION_V2.md | Earlier build3 passages differ from +5 artifact and failed latest install. | Exact signed artifact hash, receipt, native scope and Founder acceptance. | Update only after actual authorized delivery; no inferred phone/TestFlight success. |
| SYSTEM/DOCUMENTS/ZYRA_IDV_DPIA_CURRENT_VERSION_V1.md | Provider-specific legal/privacy assumptions need current selected capability validation. | Founder-approved provider direction + legal/privacy sign-off. | Review precise processing/retention/duplicate workflow; never operationalize draft. |
| SYSTEM/DOCUMENTS/ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V4.md | New governed audit must be discoverable. | Current disk metadata and safe generator. | Regenerated after this report; no authority/status invention. |

## Founder decisions required

Only genuine unsettled product choices are listed here; fixing established authorization, validation, crashes, truth states and release guards is ordinary engineering, still requiring scoped execution approval.

1. **Supported iPad scope (F41):** retain the accepted phone-only scope and align native targeting, or explicitly fund/approve tablet UX/native acceptance. Do not accidentally ship iPad1,2 as a new promise.
2. **Future Plus Guardian disclosure scope (F58):** reconcile precise fields, current eligibility and consent/history purpose where existing contracts do not settle it. Do not invent a new opt-in requirement or treat a permanent entitlement as permanent permission.
3. **Measured compatibility residual-risk acceptance (F60):** decide unresolved bands/suppression/minimum useful disclosure/retention after the full observable transcript is measured. DR250 policy alone and a99/100 synthetic counterexample cannot be labelled privacy approval.

Separate operational gates—not new product decisions—are Phase0 repair GO, exact live containment/migration GO, provider/store contracts and activation, infrastructure window, legal/store declaration sign-off, visual candidate acceptance, physical delivery and TestFlight approval. Feature priority (e.g. Incoming Potentials/Circle/returns) is backlog ordering, not a reason to re-vote already approved pricing or Basic.

## Proposed repair programme

Do not apply a broad candidate migration or use a generic “fix all” authorization. Each package states exact source/SQL artifacts, prestate, dependencies, synthetic proof, backup and rollback, expected catalog delta, post-checks and Founder acceptance.

### Phase 0 — Emergency/security

**Scope:** F01–F07, F19, F27/F28, F35–F37, F39 and current-state F58; F60 is a research/activation hold, not an emergency live policy rewrite. Start with safety deletion retention, historical Guardian SELECT and owner-bound photo references. Then close raw/progress APIs and server Plus hold, serialized operation ledger, developer authority, private notification snippets/update columns and reject unsafe staged INSERT. Prepare platform/session-boundary review separately.

**Dependencies:** current Safety Respect/retention, OA290/291 temporal history, OA283 reveal, DR252 membership, OA285 Plus hold. Do not implement unsettled Guardian disclosure fields or Stage2 activation. Existing rights to report, block, support and deletion must remain accessible.

**Database impact:** narrow FKs/retained evidence structure, caller/target helpers, owner-path validation, SELECT/EXECUTE/UPDATE policy/grant deltas, server hold and ledger function. Not the full Sep24 bundle. Avoid live report/photo/user cleanup until exact scope is approved. Any temporary deletion restriction needs a support-assisted route.

**Risk:** CRITICAL; permissions may deny rightful current access or delete evidence if incorrectly sequenced. Never repair by broad grants, fixture data or client-only checks.

**Tests:** synthetic multi-party deletion/history/foreign reference; direct anonymous/auth/service role and gateway/JWT; revocation/block/epoch/history replay; concurrent spend and lost ACK; safe backup/rollback; UI rights/retry. No live-member exploitation.

**Founder gates:** approve local repair preparation/implementation and isolated synthetic replay first. Return exact live plan for separate Founder GO; only then execute, post-verify and request acceptance. Infrastructure upgrade and irreversible retention/data cleanup remain independent gates. No interim mutation authorized by this audit.

### Phase 1 — Core correctness

**Scope:** F08–F12, F14–F18, F20/F21, F30/F34; unfinished F33/F57 only if prioritized. Canonical answer type/target/alias rules; one saved-calculation boundary; real IDV/provider/duplicate admission; trusted photo moderation/atomic persistence; funded role Basic/One/Family/restore; exact returning-attempt archive; operation identities.

**Dependencies:** Phase0 authorization first; settled current commercial/IDV/privacy contracts. Provider/legal/store activation, known-code/Main/Circle/history components each have their own dependency ledger.

**Database impact:** revised—not blindly applied—membership/receipt and archive candidates, provider/quarantine authority, canonical validation, durable calculation/operation IDs. Any data backfill needs proposed affected scope and recoverability.

**Risk:** HIGH across admission, commerce and irreversible data. Do not bypass verification/payment to finish the client flow.

**Tests:** pending/failed/verified/refused/callback replay; same person/roles; funded/unfunded/refund/restore/grace/Family; Hard/alias/None/JSON/gender counterpart; existing answer preservation; immutable first calculation; restart epochs/history; atomic photo faults.

**Founder gates:** exact local repair brief; separately provider/store/legal/server activation and data backfill GO; measured post-verification. No public trust claim until invariant proven.

### Phase 2 — Truth states and UX

**Scope:** F13, F22–F26, F29, F31/F32, F40, F51/F52/F53. Typed unavailable/failed/empty states, honest Begin/Unsave and acknowledgements, request/account ownership, event subject navigation, current confirmed names, named confirmations and truthful privacy/feature copy. No unrequested page or instructional filler.

**Dependencies:** server result types and current authority from Phases0/1; not new entitlement/consent rules.

**Database impact:** ordinarily none; a specific RPC/error projection or notification payload contract may require a separately reviewed small migration.

**Risk:** MEDIUM; stale cross-account presentation and silent success need privacy-aware tests. Avoid optimistically removing confirmed data.

**Tests:** cold/error/empty/slow/out-of-order/unknown commit, rapid repeated taps, account replacement, dispose/route covering, stale widget retention and real navigation destination.

**Founder gates:** scoped engineering GO and visual/physical acceptance; any published privacy statement remains legal/Founder sign-off, not a copy tweak certificate.

### Phase 3 — Accessibility and performance

**Scope:** F41/F44/F47–F50/F54/F61. Descriptive operable controls; enlarged/narrow layout; contrast and target geometry; platform scope; real native assistive/motion tests; bounded queries and pagination/count with validated current-authority cache.

**Dependencies:** current body/wordmark/palette tokens and Phase2 truth states; Founder iPad choice before new tablet work.

**Database impact:** justified FK/query indexes and bounded result/count APIs only after synthetic plans/scale review; no blind unused-index deletion.

**Risk:** MEDIUM; shrinking text to pass overflow or caching stale disclosure is unacceptable.

**Tests:**320/390 and supported device sizes,1.0/1.4/1.6/2.0 text/keyboard, real bundled fonts, VoiceOver/TalkBack/focus/reduced motion, worst-case histories/network/memory/frame traces and safe pagination invalidation.

**Founder gates:** scope GO; platform decision; actual visual/native acceptance. Performance changes are not a waiver of permission checks.

### Phase 4 — Cleanup and documentation

**Scope:** F42/F43/F45/F46/F55/F56/F59. Privacy manifest aggregate proof, controlled advisory review, reviewed baseline promotion, sealed Stage2 bridge, verified dead-route cleanup, current banners and immutable device/release receipt.

**Dependencies:** repaired as-built facts, current real-font candidates, earlier approvals; no new policy hidden in cleanup.

**Database impact:** none by default. Migration provenance bridge is documentation/replay first, never a renumber/reapply sweep; old developer cleanup follows Phase0 approved scope.

**Risk:** LOW/MEDIUM; loss of historical evidence, false green baseline or false installed-build claims can mislead later work.

**Tests:** link/currency inventory, sealed historical hashes, candidate-versus-approved diff, narrow native privacy archive, dependency regressions and signed artifact/source/gate pins.

**Founder gates:** candidate visual promotion, cleanup scope, truthful store/privacy sign-off, exact physical install/launch acceptance, then independent TestFlight GO. Do not self-close the audit after local tests.

## Additional findings — medium, low and informational

The same full finding format follows; research limitations, source candidates and held capabilities are deliberately distinguished from active defects.

### F11 — JSON multiselect restoration and None combinations disagree

- **Severity:** MEDIUM
- **Area:** Answer restore
- **Evidence:** generic_select_question_screen.dart:37-39,59-64; answers_service.dart:127-129; values_preferences_flow.dart:424-432
- **Governed rule:** Valid saved state must render accurately; DR250 strict selection semantics
- **Current client behaviour:** Renderer accepts List<String>, while decoded JSON can be List<dynamic>; parent still considers it complete. None can coexist with concrete choices.
- **Current server behaviour:** Own JSON is retained; strict option semantics absent.
- **User impact:** Saved choices can appear unselected, and contradictory options can be submitted.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Source type path; later feed jsonDecode array and q37/q97 None+concrete selections.
- **Files/functions involved:** generic_select_question_screen.dart:37-39,59-64; answers_service.dart:127-129; values_preferences_flow.dart:424-432
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Normalize valid string lists; enforce exclusive None and reject invalid/duplicate choices.
- **Tests required:** JSON restore/toggle/save, list types, None exclusivity and checkpoint round trip.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-303 / OA-ZYRA-226
- **Repair phase:** 1

Source/document locators: [SOURCE/lib/screens/onboarding/generic_select_question_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/onboarding/generic_select_question_screen.dart>); [SOURCE/lib/services/zyra_onboarding_answers_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_onboarding_answers_service.dart>); [SOURCE/lib/screens/onboarding/values_preferences_flow.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/onboarding/values_preferences_flow.dart>).

### F13 — Compatibility failures imply no consent, no credits or missing answers

- **Severity:** MEDIUM
- **Area:** Truth states
- **Evidence:** journey_service.dart:550-577; journey_flow_screen.dart:5867-5872; unlock_service.dart:286-309; discovery_service.dart:377-397
- **Governed rule:** OA284 EMPTY != FAILED; DR250 typed unavailable
- **Current client behaviour:** Failed reads become false/false/null, zero balances or not enough answers.
- **Current server behaviour:** OA283 correctly guards caller/current active unpaused attempt; failure does not prove missing/revoked consent.
- **User impact:** Paid members receive misleading state and may repeat Reveal.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Mock first-load and refresh failures; no live request required.
- **Files/functions involved:** journey_service.dart:550-577; journey_flow_screen.dart:5867-5872; unlock_service.dart:286-309; discovery_service.dart:377-397
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Typed results, retained confirmed state with stale notice and Retry.
- **Tests required:** Initial/refresh failure, genuine empty/no-score, forbidden/configuration and account changes.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-284
- **Repair phase:** 2

Source/document locators: [SOURCE/lib/screens/journey/journey_flow_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/journey/journey_flow_screen.dart>); [SOURCE/lib/services/zyra_journey_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_journey_service.dart>); [SOURCE/lib/services/zyra_wali_journey_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_wali_journey_service.dart>); [SOURCE/lib/services/zyra_unlock_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_unlock_service.dart>); [SOURCE/lib/services/zyra_discovery_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_discovery_service.dart>).

### F22 — Decision read failure clears Saved Considered and Passed

- **Severity:** MEDIUM
- **Area:** Discovery state
- **Evidence:** discovery_service.dart:595-666; session_router.dart:482-500; app_state.dart:424-438
- **Governed rule:** EMPTY != FAILED; confirmed state retained on refresh failure
- **Current client behaviour:** Failure becomes empty lists; hydration clears all local decisions.
- **Current server behaviour:** Read failure is not confirmation of zero decisions.
- **User impact:** Previously passed/saved cards can resurface and lists falsely appear empty.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Mock fetchDecisions failure before/after confirmed state.
- **Files/functions involved:** discovery_service.dart:595-666; session_router.dart:482-500; app_state.dart:424-438
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Typed decision snapshot and account-scoped last-confirmed data.
- **Tests required:** Initial/refresh partial failure, account replacement and no decided-card resurfacing.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-305 / OA-ZYRA-304
- **Repair phase:** 2

Source/document locators: [SOURCE/lib/state/app_state.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/state/app_state.dart>); [SOURCE/lib/services/zyra_discovery_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_discovery_service.dart>); [SOURCE/lib/services/zyra_session_router.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_session_router.dart>).

### F23 — Initial Journey load failure looks like no Journeys

- **Severity:** MEDIUM
- **Area:** Connections truth
- **Evidence:** connections_screen.dart:869-886,2160-2178,2334-2375; PastJourneysScreen has separate correct retry
- **Governed rule:** DR179 EMPTY != FAILED
- **Current client behaviour:** Null fetch returns without initial unavailable state; empty lists render definitive Start/Paused/Ended copy.
- **Current server behaviour:** RPC/query failure does not mean empty.
- **User impact:** Missing active relationships are misrepresented as none.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Mock initial null then successful refresh; retain existing rows on later error.
- **Files/functions involved:** connections_screen.dart:869-886,2160-2178,2334-2375; PastJourneysScreen has separate correct retry
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Initial unavailable/Retry and explicit stale state; preserve successful PastJourneys handling.
- **Tests required:** Initial versus refresh failure in all three statuses.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-304 / OA-ZYRA-305
- **Repair phase:** 2

Source/document locators: [SOURCE/lib/screens/connections/connections_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/connections/connections_screen.dart>).

### F24 — Begin refusal can silently do nothing

- **Severity:** MEDIUM
- **Area:** Journey action
- **Evidence:** journey_service.dart:401-420; connections_screen.dart:1305-1380
- **Governed rule:** Action must report confirmed result or refusal
- **Current client behaviour:** promote false exits _promote without feedback for most refusals/errors.
- **Current server behaviour:** IDV/lifecycle/server refusal cannot be reduced to successful no-op.
- **User impact:** Begin appears broken and user cannot recover.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Mock false IDV/RPC refusal and timeout.
- **Files/functions involved:** journey_service.dart:401-420; connections_screen.dart:1305-1380
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Typed action refusal/error with concise relevant recovery, no invented success.
- **Tests required:** Blocked IDV, cap, unavailable, denied, stale account and duplicate tap.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-304 / OA-ZYRA-305
- **Repair phase:** 2

Source/document locators: [SOURCE/lib/screens/connections/connections_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/connections/connections_screen.dart>); [SOURCE/lib/services/zyra_journey_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_journey_service.dart>); [SOURCE/lib/services/zyra_wali_journey_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_wali_journey_service.dart>).

### F25 — Unsave can appear successful after delete failure

- **Severity:** MEDIUM
- **Area:** Saved action
- **Evidence:** discovery_service.dart:701-710; connections_screen.dart:3002-3021
- **Governed rule:** Truthful write confirmation
- **Current client behaviour:** Delete error swallowed; caller updates without confirmed result.
- **Current server behaviour:** Failed delete preserves row.
- **User impact:** Profile reappears after seeming to be removed.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Mock save deletion error and reopen.
- **Files/functions involved:** discovery_service.dart:701-710; connections_screen.dart:3002-3021
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Return acknowledged outcome, preserve row and Retry.
- **Tests required:** Failure, success, double tap and owner replacement.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-304 / OA-ZYRA-305
- **Repair phase:** 2

Source/document locators: [SOURCE/lib/screens/connections/connections_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/connections/connections_screen.dart>); [SOURCE/lib/services/zyra_discovery_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_discovery_service.dart>).

### F26 — Remaining Connections and Guardian loads lack request-owner guards

- **Severity:** MEDIUM
- **Area:** Concurrency
- **Evidence:** connections_screen.dart:869-980; seeker_wali_tab.dart:181-222
- **Governed rule:** Engineering invariants stale responses never replace new account/request
- **Current client behaviour:** Awaited loaders lack generation/current-principal checks before state hydration.
- **Current server behaviour:** Supabase response belongs to request's old context.
- **User impact:** Late responses can overwrite newer view; cross-account visible stale data risk needs synthetic reproduction.
- **Security/privacy impact:** Potential cross-account stale presentation; not demonstrated live.
- **Minimum reproduction / limits:** Deferred old fetch, change account/start new request, then release old fetch in test.
- **Files/functions involved:** connections_screen.dart:869-980; seeker_wali_tab.dart:181-222
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Capture owner+epoch+request id and discard superseded responses.
- **Tests required:** Reverse completion, logout/login, unmount, long hang and no stale rows.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Confirmed missing guard; impact requires synthetic reproduction
- **Action trace:** OA-ZYRA-304 / OA-ZYRA-305
- **Repair phase:** 2

Source/document locators: [SOURCE/lib/screens/connections/connections_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/connections/connections_screen.dart>); [SOURCE/lib/screens/wali/seeker_wali_tab.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/wali/seeker_wali_tab.dart>).

### F28 — Recipients can alter server-authored notification fields

- **Severity:** MEDIUM
- **Area:** Notification integrity
- **Evidence:** Live notifications_update owner-only RLS; authenticated UPDATE body/title/type/related_match_id/created_at/id/user_id/read_at
- **Governed rule:** Server event identity/content authority; client marks read only
- **Current client behaviour:** Legitimate app updates read_at.
- **Current server behaviour:** Effective privileges permit all listed event fields while keeping owner UID.
- **User impact:** Own event chronology/type/subject can be forged; no other-user write established.
- **Security/privacy impact:** Server-event integrity gap limited to own rows.
- **Minimum reproduction / limits:** Column grants and policy proof only; no update.
- **Files/functions involved:** Live notifications_update owner-only RLS; authenticated UPDATE body/title/type/related_match_id/created_at/id/user_id/read_at
- **Whether live data is affected:** Live ACL/policy confirmed.
- **Recommended fix:** Column-level read_at grant or caller-scoped mark-read RPC; revoke broad UPDATE.
- **Tests required:** Allowed read marking; denied content/type/id/time mutation, foreign owner and old cases.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** YES — exact grants/RPC migration GO.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-231 / OA-ZYRA-305
- **Repair phase:** 0

### F29 — My ZYRA drops the related Journey subject

- **Severity:** MEDIUM
- **Area:** Notification navigation
- **Evidence:** dashboard_updates_service.dart notification projection; seeker_dashboard_screen.dart update navigation; related_match_id discarded
- **Governed rule:** Notification Spec destination rules; Now routes to owner, not duplicate workflow
- **Current client behaviour:** Tap routes to generic Connections rather than exact Journey.
- **Current server behaviour:** Notification event contains related_match_id.
- **User impact:** User must hunt for the update's actual relationship.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Synthetic notification with related match → resolve/tap.
- **Files/functions involved:** dashboard_updates_service.dart notification projection; seeker_dashboard_screen.dart update navigation; related_match_id discarded
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Retain stable subject id and authorize owner destination; safe fallback for deleted/inaccessible subject.
- **Tests required:** Exact Journey, missing/deleted/blocked subject and role parity.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-281 / OA-ZYRA-304
- **Repair phase:** 2

Source/document locators: [SOURCE/lib/screens/home/seeker_dashboard_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/home/seeker_dashboard_screen.dart>); [SOURCE/lib/services/zyra_dashboard_updates_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_dashboard_updates_service.dart>).

### F30 — Lost-response retries have no operation identity

- **Severity:** MEDIUM
- **Area:** Messaging safety
- **Evidence:** journey_service.dart send; report_service.dart report/reportAndBlock; family_messaging_service.dart held send
- **Governed rule:** Confirmed send/report once; durable safety records
- **Current client behaviour:** Retries issue new insert/report requests without idempotent operation id.
- **Current server behaviour:** No shared acknowledged-operation protocol demonstrated.
- **User impact:** Lost ACK can duplicate messages or reports; block and report may partially succeed.
- **Security/privacy impact:** Safety evidence integrity/duplicate reports; no real report filed.
- **Minimum reproduction / limits:** Synthetic committed-but-lost response, retry same intent; do not send/report live.
- **Files/functions involved:** journey_service.dart send; report_service.dart report/reportAndBlock; family_messaging_service.dart held send
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Client operation id + server uniqueness/atomic report-and-block contract, truthful recovery.
- **Tests required:** ACK loss, timeout, duplicates, incoming concurrency and report/block partial failure.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** YES for idempotency constraints/RPCs.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-305 / OA-ZYRA-298
- **Repair phase:** 1

Source/document locators: [SOURCE/lib/services/zyra_journey_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_journey_service.dart>); [SOURCE/lib/services/zyra_wali_journey_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_wali_journey_service.dart>); [SOURCE/lib/services/zyra_report_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_report_service.dart>); [SOURCE/lib/services/zyra_family_messaging_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_family_messaging_service.dart>).

### F31 — Access failures and upgrade copy misstate a held feature

- **Severity:** MEDIUM
- **Area:** Guardian Network
- **Evidence:** wali_network_screen.dart:119-129,904-1004; entitlement_service.dart:18-42; wali_link_service.dart:1604-1607
- **Governed rule:** Network V2 C7/OA142; unavailable distinct from not entitled
- **Current client behaviour:** Errors become no paid access/no linked people; Basic says upgrade unlocks recommendations.
- **Current server behaviour:** Actual recommendations remain unavailable; production does not run D14 preview.
- **User impact:** Outage appears as a paywall; upgrade promises a feature still held.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Mock entitlement/link read failures and compare Basic/One gate.
- **Files/functions involved:** wali_network_screen.dart:119-129,904-1004; entitlement_service.dart:18-42; wali_link_service.dart:1604-1607
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Typed unavailable/Retry and honest coming-soon copy without premature activation.
- **Tests required:** Paid/unpaid/linked/unlinked/error matrix and no preview fallback.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-142 / OA-ZYRA-304
- **Repair phase:** 2

Source/document locators: [SOURCE/lib/screens/wali/wali_network_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/wali/wali_network_screen.dart>); [SOURCE/lib/services/zyra_entitlement_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_entitlement_service.dart>); [SOURCE/lib/services/zyra_wali_link_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_wali_link_service.dart>).

### F32 — Real mutual Consider does not trigger promised instant match presentation

- **Severity:** MEDIUM
- **Area:** Browse match moment
- **Evidence:** app_state.dart:454; discovery_service.dart:260-283; browse_screen.dart:1219-1252
- **Governed rule:** Browse UX V4:78-83,292
- **Current client behaviour:** Local match moment depends on alreadyLikedYou; real mapper never sets it; trigger presentation not awaited.
- **Current server behaviour:** Mutual-like trigger can create server event later.
- **User impact:** Real mutual match lacks the approved immediate confirmation or robust acknowledged routing.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Synthetic mutual server acknowledgement after Consider.
- **Files/functions involved:** app_state.dart:454; discovery_service.dart:260-283; browse_screen.dart:1219-1252
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Return/read authoritative match outcome and present only confirmed moment.
- **Tests required:** Mutual versus single Consider, failure/lost response, delayed event and no fake match.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-304 / OA-ZYRA-305
- **Repair phase:** 2

Source/document locators: [SOURCE/lib/state/app_state.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/state/app_state.dart>); [SOURCE/lib/screens/browse/browse_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/browse/browse_screen.dart>); [SOURCE/lib/services/zyra_discovery_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_discovery_service.dart>).

### F33 — Incoming Potentials surface remains unimplemented

- **Severity:** INFORMATIONAL
- **Area:** Discovery roadmap
- **Evidence:** Connections tabs Journey/Activity/Introductions; former tease deliberately removed at connections_screen.dart:1912
- **Governed rule:** Browse UX V4:74-83,257-271 and current One feature model
- **Current client behaviour:** No approved One-only incoming list/Consider Back surface found.
- **Current server behaviour:** No current completed incoming capability claimed.
- **User impact:** Promised roadmap feature is missing; no reason to invent a no-op page.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Source route review, not a live account proof.
- **Files/functions involved:** Connections tabs Journey/Activity/Introductions; former tease deliberately removed at connections_screen.dart:1912
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Scope One incoming action/server projection separately; retain truthful availability.
- **Tests required:** Future incoming permission/action/quota/navigation suite.
- **Founder decision / execution authority:** Founder prioritization of unfinished feature, not a privacy waiver.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Approved feature not implemented
- **Action trace:** OA-ZYRA-305
- **Repair phase:** 1

Source/document locators: [SOURCE/lib/screens/connections/connections_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/connections/connections_screen.dart>).

### F40 — Absolute privacy claims exceed measured architecture

- **Severity:** MEDIUM
- **Area:** Privacy copy
- **Evidence:** privacy_and_data_screen.dart:73-89,133-139; product_telemetry.dart:129-174; local_prefs.dart:16-27,68
- **Governed rule:** Public claims reflect actual data use and authentication
- **Current client behaviour:** No analytics wording despite bounded local events/default-off RPC path; never uploaded prefs despite backup; only Apple/Google omits verified recovery email.
- **Current server behaviour:** Remote telemetry is default off; no enabled remote analytics found.
- **User impact:** Overbroad claims confuse actual local diagnostics, OS backup and passwordless recovery.
- **Security/privacy impact:** Disclosure accuracy gap, not evidence enabled remote analytics.
- **Minimum reproduction / limits:** Source/copy comparison only.
- **Files/functions involved:** privacy_and_data_screen.dart:73-89,133-139; product_telemetry.dart:129-174; local_prefs.dart:16-27,68
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Accurate bounded copy with data inventory; preserve no advertising tracking claim only where proved.
- **Tests required:** Copy/data-use assertions, default-off telemetry, recovery method and backup parity.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-266 / OA-ZYRA-305
- **Repair phase:** 2

Source/document locators: [SOURCE/lib/screens/settings/privacy_and_data_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/settings/privacy_and_data_screen.dart>); [SOURCE/lib/services/zyra_product_telemetry.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_product_telemetry.dart>); [SOURCE/lib/services/zyra_local_prefs.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_local_prefs.dart>).

### F41 — iPad targeting conflicts with phone-only accepted scope

- **Severity:** MEDIUM
- **Area:** Native scope
- **Evidence:** project.pbxproj:385 TARGETED_DEVICE_FAMILY=1,2; Info.plist:87 iPad orientations; main.dart:52-64 portrait
- **Governed rule:** DR188 deferred iPad/tablet scope
- **Current client behaviour:** Native target accepts iPad while app locks portrait.
- **Current server behaviour:** No server relevance.
- **User impact:** Store/device support suggests unverified layouts and orientations.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Static native targeting review.
- **Files/functions involved:** project.pbxproj:385 TARGETED_DEVICE_FAMILY=1,2; Info.plist:87 iPad orientations; main.dart:52-64 portrait
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Choose explicit iPhone-only release or approved iPad/resizing acceptance; no silent scope change.
- **Tests required:** Native supported devices, orientation/resizing/keyboard and large text.
- **Founder decision / execution authority:** YES — Founder chooses iPhone-only or funded/approved iPad scope.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-286 / OA-ZYRA-257
- **Repair phase:** 3

Source/document locators: [SOURCE/lib/main.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/main.dart>); [SOURCE/ios/Runner.xcodeproj/project.pbxproj](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/ios/Runner.xcodeproj/project.pbxproj>); [SOURCE/ios/Runner/Info.plist](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/ios/Runner/Info.plist>).

### F42 — App-level privacy manifest and aggregate declarations not verified

- **Severity:** MEDIUM
- **Area:** iOS privacy evidence
- **Evidence:** No Runner PrivacyInfo.xcprivacy in source/current PROFILE; plugin manifests do exist
- **Governed rule:** Apple privacy manifest/App Store data declarations
- **Current client behaviour:** App's aggregate required-reason/data disclosures not evidenced.
- **Current server behaviour:** No server relevance.
- **User impact:** Privacy submission correctness remains unproven; absence alone is not proof of rejection.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Read native bundle/source inventory only.
- **Files/functions involved:** No Runner PrivacyInfo.xcprivacy in source/current PROFILE; plugin manifests do exist
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Review Xcode aggregate privacy report and actual app data use; prepare accurate App Privacy answers.
- **Tests required:** Release bundle privacy manifest/report, APIs, SDK declarations and App Store labels.
- **Founder decision / execution authority:** Founder approves truthful store/privacy submission; no legal sign-off invented.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Evidence gap
- **Action trace:** OA-ZYRA-266 / OA-ZYRA-286
- **Repair phase:** 4

Source/document locators: [SOURCE/ios/Runner](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/ios/Runner>); [SOURCE/ios/Runner.xcodeproj/project.pbxproj](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/ios/Runner.xcodeproj/project.pbxproj>).

### F43 — Pinned packages need controlled advisory and update review

- **Severity:** MEDIUM
- **Area:** Dependencies
- **Evidence:** pubspec.lock: SupabaseFlutter2.16 vs2.18; secure_storage11.1.1 vs11.2; image4.9.1 vs4.10.1; share_plus13.3 vs13.3.1
- **Governed rule:** Current supported/security-reviewed dependency chain; audit cannot upgrade
- **Current client behaviour:** Lockfile pins current build; latest alone does not prove vulnerability.
- **Current server behaviour:** Engine review separate F37; complete transitive advisory/SBOM not performed.
- **User impact:** Potential fixes/security issues need controlled evaluation, not blanket upgrades.
- **Security/privacy impact:** Advisory-free status NOT established; no affected package CVE asserted.
- **Minimum reproduction / limits:** Official version/changelog checks as of Oct3; no pub upgrade.
- **Files/functions involved:** pubspec.lock: SupabaseFlutter2.16 vs2.18; secure_storage11.1.1 vs11.2; image4.9.1 vs4.10.1; share_plus13.3 vs13.3.1
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** SBOM/advisory scan and individually justified patch plan; preserve pins until approval.
- **Tests required:** pub advisory/outdated evidence without lock edits, native regressions and patched package tests.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Evidence gap
- **Action trace:** OA-ZYRA-305
- **Repair phase:** 4

Source/document locators: [SOURCE/pubspec.lock](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/pubspec.lock>); [SOURCE/pubspec.yaml](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/pubspec.yaml>).

### F44 — Automated tests do not establish provider or physical-device E2E

- **Severity:** MEDIUM
- **Area:** Native acceptance
- **Evidence:** 251 Dart test files; one iOS test; no integration_test/Android instrumentation inventory
- **Governed rule:** Measured source check ≠ native/member acceptance
- **Current client behaviour:** Extensive mocks/source contracts; physical/current ordinary account not exercised this audit.
- **Current server behaviour:** Live writes/provider callbacks were deliberately not tested.
- **User impact:** OAuth, deep links, backup, role switch, IDV, payments, photo upload and native accessibility remain uncertified.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Test inventory and prior receipt review, not install/run.
- **Files/functions involved:** 251 Dart test files; one iOS test; no integration_test/Android instrumentation inventory
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Prepare synthetic native acceptance plan, then exact device/provider scope GO.
- **Tests required:** iOS/Android fresh/resume/logout, auth/deeplink, keyboard, permissions, receipts, backup and VoiceOver/TalkBack.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Evidence gap
- **Action trace:** OA-ZYRA-286 / OA-ZYRA-305
- **Repair phase:** 3

### F45 — 124 approved screenshot comparisons are failing

- **Severity:** MEDIUM
- **Area:** Visual evidence
- **Evidence:** Fresh visual suite211 passed/124 failed/335 total; representative99.99% mismatch; no approved PNG updated
- **Governed rule:** OA257 approved visual baselines never overwritten to manufacture pass
- **Current client behaviour:** Current theme/fonts/design differs from old approved pixels.
- **Current server behaviour:** No server relevance.
- **User impact:** Whole visual suite is NOT green; baseline promotion still needs review.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Run existing suite without update-goldens. Full error-class enumeration not retained; one mismatch proven.
- **Files/functions involved:** Fresh visual suite211 passed/124 failed/335 total; representative99.99% mismatch; no approved PNG updated
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Review current candidates versus historical baseline with Founder; fix real layout issues separately from promotion.
- **Tests required:** Current real-font render/overflow matrix and explicit approved pixel acceptance.
- **Founder decision / execution authority:** Founder visual acceptance/promotion required, not blanket approve all pixels.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-257
- **Repair phase:** 4

Source/document locators: [SOURCE/test/visual/zyra_visual_regression_test.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart>); [SOURCE/test/visual/approved/oa-zyra-282-phase3-v1/guardian-dashboard-thinned-additional-neutral__small.png](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/approved/oa-zyra-282-phase3-v1/guardian-dashboard-thinned-additional-neutral__small.png>).

### F46 — Stage2 current replay stops at baseline drift

- **Severity:** MEDIUM
- **Area:** Compatibility evidence
- **Evidence:** Current run_stage2 exits1 before runtime;4/45 anchors drift: Values, answers service, seeker-details service, pubspec
- **Governed rule:** DR250 Stage2 research not production/privacy proof
- **Current client behaviour:** Stage1 remains unwired and206 focused tests pass.
- **Current server behaviour:** Stage2 not deployed; historical112 passes/1counterexample/11deferred do not revalidate current anchors.
- **User impact:** Cannot reuse historical green result as current integration approval.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Database-free runner invocation only, no --evidence/no VM/no DB.
- **Files/functions involved:** Current run_stage2 exits1 before runtime;4/45 anchors drift: Values, answers service, seeker-details service, pubspec
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Reconcile approved source changes without rewriting sealed old evidence; fresh synthetic evidence under separate scope.
- **Tests required:** Current baseline bridge, Stage2 replay, real JWT/gateway/transport and retention proof.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-193 / OA-ZYRA-285
- **Repair phase:** 4

Source/document locators: [SYSTEM/DOCUMENTS/ZYRA_COMPATIBILITY_SERVER_STAGE2_HANDOVER_CURRENT_VERSION_V1.md](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/DOCUMENTS/ZYRA_COMPATIBILITY_SERVER_STAGE2_HANDOVER_CURRENT_VERSION_V1.md>).

### F47 — Switch and selection controls lack explicit descriptive semantics

- **Severity:** MEDIUM
- **Area:** Accessibility
- **Evidence:** privacy_settings.dart:168-214; app_lock_screen.dart:95-130; notification_settings.dart:411-447; feedback.dart:154-190; personalisation.dart:403-471
- **Governed rule:** Accessible named controls/selected state
- **Current client behaviour:** Text siblings do not label focused Switch; gesture choices lack radio/selected semantics; Feedback Send bare gesture.
- **Current server behaviour:** No server relevance; save guards should remain unchanged.
- **User impact:** Assistive users may hear only on/off or unlabeled actions.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Source semantics review; verify actual spoken behavior with semantic tester/device.
- **Files/functions involved:** privacy_settings.dart:168-214; app_lock_screen.dart:95-130; notification_settings.dart:411-447; feedback.dart:154-190; personalisation.dart:403-471
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Merge/descriptive semantics, selected state and semantic buttons.
- **Tests required:** Semantic tree, VoiceOver/TalkBack labels/state/action and role parity.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-257
- **Repair phase:** 3

Source/document locators: [SOURCE/lib/screens/settings/privacy_settings_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/settings/privacy_settings_screen.dart>); [SOURCE/lib/screens/settings/app_lock_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/settings/app_lock_screen.dart>); [SOURCE/lib/screens/settings/feedback_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/settings/feedback_screen.dart>); [SOURCE/lib/screens/settings/personalisation_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/settings/personalisation_screen.dart>); [SOURCE/lib/widgets/zyra_write_feedback.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/widgets/zyra_write_feedback.dart>).

### F48 — Photo navigation and compact profile actions need operable targets

- **Severity:** MEDIUM
- **Area:** Accessibility
- **Evidence:** seeker_profile_screen.dart:170-213,354-390; profile_screen.dart:636-649,680-705; wali_profile_screen.dart:382-407
- **Governed rule:** Accessible alternatives to gesture-only actions;48px common target
- **Current client behaviour:** Photo changes use tap halves; swipe-down-only close lacks action; profile rows/Buy more ~36–40px.
- **Current server behaviour:** No server relevance.
- **User impact:** Assistive navigation/dismissal and motor access can fail.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Source geometry/semantics; physical speech/actions not tested.
- **Files/functions involved:** seeker_profile_screen.dart:170-213,354-390; profile_screen.dart:636-649,680-705; wali_profile_screen.dart:382-407
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Named next/previous/dismiss semantic actions and minimum hit areas preserving approved visual layout.
- **Tests required:** Semantic tap actions,48px geometry, compact viewport and native back.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-257
- **Repair phase:** 3

Source/document locators: [SOURCE/lib/screens/profile/seeker_profile_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/profile/seeker_profile_screen.dart>); [SOURCE/lib/screens/profile/profile_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/profile/profile_screen.dart>); [SOURCE/lib/screens/wali/wali_profile_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/wali/wali_profile_screen.dart>); [SOURCE/lib/screens/profile/edit_profile_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/profile/edit_profile_screen.dart>).

### F49 — Small copy falls below readable contrast target

- **Severity:** MEDIUM
- **Area:** Accessibility contrast
- **Evidence:** feedback_screen.dart:251-259 ink(.30)11.5; settings_screen.dart:738-745 ink(.38)13; current gradient #30203F→#160E20
- **Governed rule:** Accessible normal text contrast4.5:1; current Hulu theme
- **Current client behaviour:** Composited ratios approx2.65:1 and3.42–3.57:1 at endpoints.
- **Current server behaviour:** No server relevance.
- **User impact:** Low-vision users may not read disclosure/value text.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Mathematical source-color composition, not a device-pixel certification.
- **Files/functions involved:** feedback_screen.dart:251-259 ink(.30)11.5; settings_screen.dart:738-745 ink(.38)13; current gradient #30203F→#160E20
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Measure all actual surfaces and adjust canonical small-text tokens, preserving brand.
- **Tests required:** Contrast per opaque/composited background, enlarged text and screenshot review.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-257
- **Repair phase:** 3

Source/document locators: [SOURCE/lib/screens/settings/feedback_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/settings/feedback_screen.dart>); [SOURCE/lib/screens/settings/settings_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/settings/settings_screen.dart>); [SOURCE/lib/screens/wali/wali_notification_settings_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/wali/wali_notification_settings_screen.dart>); [SOURCE/lib/screens/settings/privacy_settings_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/settings/privacy_settings_screen.dart>); [SOURCE/lib/screens/settings/notification_settings_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/settings/notification_settings_screen.dart>).

### F50 — Guardian FittedBox shrinks text and tap targets

- **Severity:** MEDIUM
- **Area:** Accessibility scaling
- **Evidence:** seeker_guardian_designs.dart:640-667,1030-1070; guardian_one_page_designs_test.dart:237-333
- **Governed rule:** Large text remains readable/operable; approved one-page design not a license to negate OS text size
- **Current client behaviour:** Entire interactive page scaleDown; Manage starts42px before shrinking; tests assert no overflow only.
- **Current server behaviour:** No server relevance.
- **User impact:** 2x text can shrink whole UI rather than improve readability; effective target size unmeasured.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Source scaling path; later measure320px/1.4x/2x actual transforms.
- **Files/functions involved:** seeker_guardian_designs.dart:640-667,1030-1070; guardian_one_page_designs_test.dart:237-333
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Accessible adaptation preserving visual intent; large-text layout decision before redesign.
- **Tests required:** Effective glyph/target geometry, scroll/focus reachability and reduced-motion dismissal.
- **Founder decision / execution authority:** Founder visual acceptance for adapted one-screen design; engineering semantics not a product vote.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-257
- **Repair phase:** 3

Source/document locators: [SOURCE/lib/screens/wali/seeker_guardian_designs.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/wali/seeker_guardian_designs.dart>); [SOURCE/test/guardian_one_page_designs_test.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_one_page_designs_test.dart>).

### F51 — Confirm loses the person and action context

- **Severity:** MEDIUM
- **Area:** Guardian action safety
- **Evidence:** seeker_guardian_designs.dart:963-1022, current Quiet management route
- **Governed rule:** Destructive/authority actions visibly identify target and consequences
- **Current client behaviour:** Remove/Remove as Main becomes generic Cancel/Confirm without visible/spoken target/action.
- **Current server behaviour:** RPC action remains separate.
- **User impact:** Accidental confirmation or uncertainty over which Guardian is changing.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Inspect current confirm state; do not remove a real Guardian.
- **Files/functions involved:** seeker_guardian_designs.dart:963-1022, current Quiet management route
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Compact named action/person/consequence, accessible confirmation; preserve existing permission checks.
- **Tests required:** Each manage action, target identity, main constraints and cancel/no mutation.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-257 / OA-ZYRA-304
- **Repair phase:** 2

Source/document locators: [SOURCE/lib/screens/wali/seeker_guardian_designs.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/wali/seeker_guardian_designs.dart>).

### F52 — Cold start can lose the displayed Guardian name

- **Severity:** MEDIUM
- **Area:** Guardian Profile
- **Evidence:** wali_profile_screen.dart:251; session_router.dart:447-455; app_state.dart:118-142; wali_dashboard.dart:496
- **Governed rule:** Shared identity hydration and role profile parity
- **Current client behaviour:** Profile uses waliName ?? Your Profile; router hydrates name; Dashboard already uses waliName ?? name.
- **Current server behaviour:** Profile first_name still present.
- **User impact:** Confirmed name becomes generic after relaunch.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Synthetic cold session with name set and waliName null.
- **Files/functions involved:** wali_profile_screen.dart:251; session_router.dart:447-455; app_state.dart:118-142; wali_dashboard.dart:496
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Shared confirmed name resolver across role surfaces.
- **Tests required:** Cold/relaunch/account switch and preview/live names.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-304
- **Repair phase:** 2

Source/document locators: [SOURCE/lib/screens/wali/wali_profile_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/wali/wali_profile_screen.dart>); [SOURCE/lib/state/app_state.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/state/app_state.dart>); [SOURCE/lib/screens/wali/wali_dashboard_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/wali/wali_dashboard_screen.dart>); [SOURCE/lib/services/zyra_session_router.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_session_router.dart>).

### F53 — Ordinary Settings says this preview

- **Severity:** LOW
- **Area:** Held push copy
- **Evidence:** notification_settings_screen.dart:333-344; promotion_engine.dart:525-533
- **Governed rule:** Normal user copy must not imply Developer Preview
- **Current client behaviour:** Unavailable device-alert status says not connected in this preview.
- **Current server behaviour:** APNs/FCM/token registration remains held; in-app events work.
- **User impact:** Minor credibility/confusion on ordinary route.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Open unified Settings with unavailable permission state in test.
- **Files/functions involved:** notification_settings_screen.dart:333-344; promotion_engine.dart:525-533
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Truthful not available yet copy; no permission/push activation.
- **Tests required:** Ordinary versus protected preview copy and unavailable state.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-254 / OA-ZYRA-304
- **Repair phase:** 2

Source/document locators: [SOURCE/lib/screens/settings/notification_settings_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/settings/notification_settings_screen.dart>); [SOURCE/lib/screens/wali/wali_notification_settings_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/wali/wali_notification_settings_screen.dart>); [SOURCE/lib/services/zyra_promotion_engine.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_promotion_engine.dart>).

### F54 — Browse chat and unread loads need bounded scale measurements

- **Severity:** MEDIUM
- **Area:** Performance
- **Evidence:** discovery_service.dart:161-181 no limit/range; journey_service.dart full history loads; notification_service.dart:281 reads all unread IDs
- **Governed rule:** Responsive bounded queries and no speculative lifecycle redesign
- **Current client behaviour:** Full candidate deck scored/photo-signed; Journey mapping includes sequential awaits. Browse photo signing already batched.
- **Current server behaviour:** 154indexes; advisors14unindexedFK,4probe-tables withoutPK,22unusedindexes,6multiple-policy role findings.
- **User impact:** Large real populations can exhaust bandwidth/frame/memory; no production latency measured.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Source/catalog only; no live EXPLAIN ANALYZE or load test.
- **Files/functions involved:** discovery_service.dart:161-181 no limit/range; journey_service.dart full history loads; notification_service.dart:281 reads all unread IDs
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Representative synthetic query/cursor benchmarks; server count unread; bounded fetch and revalidated cache.
- **Tests required:** 1k/10k candidate synthetic scale, low-memory photo decoding, reconnect/message gap and explain plans.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** Separate GO for index/query migrations; do not drop unused indexes on lint alone.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-305
- **Repair phase:** 3

Source/document locators: [SOURCE/lib/services/zyra_discovery_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_discovery_service.dart>); [SOURCE/lib/services/zyra_journey_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_journey_service.dart>); [SOURCE/lib/services/zyra_wali_journey_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_wali_journey_service.dart>); [SOURCE/lib/services/zyra_notification_service.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_notification_service.dart>).

### F55 — Current filenames contain superseded or unbuilt claims

- **Severity:** MEDIUM
- **Area:** Documentation currency
- **Evidence:** Settings Identity V3 oldbuild2/3 paragraphs; IDV draft Sumsub; ImageHandling original retention; older handovers paid-only; StyleDefault early Midnight Plum
- **Governed rule:** AD111 current roles; newest specific DRs trump historical text
- **Current client behaviour:** Current source Poppins/Syne/Hulu, Basic restored, selected Stripe, client JPEG no-original pipeline.
- **Current server behaviour:** Live/source capabilities differ; publication/moderation/receipt not activated.
- **User impact:** Future implementer can follow old contract or publish unsupported privacy/provider claims.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Compare current overlays with preserved historical sections.
- **Files/functions involved:** Settings Identity V3 oldbuild2/3 paragraphs; IDV draft Sumsub; ImageHandling original retention; older handovers paid-only; StyleDefault early Midnight Plum
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** After repair, surgical current banners/as-built facts with original history intact; legal drafts stay draft.
- **Tests required:** Doc-link/currency gate and source/live rule reconciliation.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Confirmed
- **Action trace:** OA-ZYRA-305 / OA-ZYRA-266
- **Repair phase:** 4

Source/document locators: [SYSTEM/DOCUMENTS/ZYRA_SETTINGS_AND_IDENTITY_CURRENT_VERSION_V3.md](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/DOCUMENTS/ZYRA_SETTINGS_AND_IDENTITY_CURRENT_VERSION_V3.md>); [SYSTEM/DOCUMENTS/ZYRA_PRIVACY_POLICY_IDV_SECTIONS_CURRENT_VERSION_V1.md](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/DOCUMENTS/ZYRA_PRIVACY_POLICY_IDV_SECTIONS_CURRENT_VERSION_V1.md>); [APP/Standards/IMAGE_HANDLING_CURRENT_VERSION_V2.md](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/APP/Standards/IMAGE_HANDLING_CURRENT_VERSION_V2.md>); [SYSTEM/DOCUMENTS/ZYRA_STYLE_DEFAULT_HANDOVER_CURRENT_VERSION_V1.md](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/DOCUMENTS/ZYRA_STYLE_DEFAULT_HANDOVER_CURRENT_VERSION_V1.md>).

### F56 — Four old screens have no ordinary imports

- **Severity:** LOW
- **Area:** Dead code
- **Evidence:** notifications_screen.dart; wali_notification_settings_screen.dart; guardian_detail_screen.dart; journey_map_screen.dart; UI gate UIG10
- **Governed rule:** Single owner pages, no speculative deletion
- **Current client behaviour:** Current routes use shared NotificationSettings/Quiet manager; old variants retained.
- **Current server behaviour:** No server impact.
- **User impact:** Maintenance duplication, not evidence users see obsolete screens.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Import/reachability review; simple graph cannot prove no dynamic/test reference.
- **Files/functions involved:** notifications_screen.dart; wali_notification_settings_screen.dart; guardian_detail_screen.dart; journey_map_screen.dart; UI gate UIG10
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Archive/remove only after route/fixture/reference verification and approved cleanup.
- **Tests required:** Route/fixture inventory and no lost shared contracts.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Cleanup candidate; not live broken route
- **Action trace:** OA-ZYRA-257
- **Repair phase:** 4

Source/document locators: [SOURCE/lib/screens/notifications/notifications_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/notifications/notifications_screen.dart>); [SOURCE/lib/screens/wali/wali_notification_settings_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/wali/wali_notification_settings_screen.dart>); [SOURCE/lib/screens/wali/guardian_detail_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/wali/guardian_detail_screen.dart>); [SOURCE/lib/screens/journey/journey_map_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/journey/journey_map_screen.dart>).

### F57 — Several approved services remain deliberately held

- **Severity:** INFORMATIONAL
- **Area:** Held capability matrix
- **Evidence:** requestNewJourneyEnabled=false; familyMessagingEnabled=false; absent live pause RPCs; staged Main optional/known-code/telemetry/receipts
- **Governed rule:** Existing OA156/261/294/295/298/299/254/296 scopes
- **Current client behaviour:** Local controls/previews or unavailable copy, not completed member capability.
- **Current server behaviour:** 211 applied migrations; latest safety RPC only, large Sep24 package absent.
- **User impact:** App remains incomplete but honest holds must not be mistaken for regression or silently bypassed.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Catalog existence/source gates only.
- **Files/functions involved:** requestNewJourneyEnabled=false; familyMessagingEnabled=false; absent live pause RPCs; staged Main optional/known-code/telemetry/receipts
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Dependency-ordered exact capability work after repairs; retain fail-closed paths.
- **Tests required:** Per-feature replay, ACLs, epochs/history, permission and end-to-end acceptance.
- **Founder decision / execution authority:** Founder prioritizes activation work; settled rules need no repeat vote.
- **Production apply approval:** YES for each separate backend activation.
- **Evidence status:** Documented limitation
- **Action trace:** OA-ZYRA-305
- **Repair phase:** 1

Source/document locators: [SOURCE/lib/data/zyra_release_gates.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/data/zyra_release_gates.dart>).

### F58 — Permanent Plus disclosure lacks current target-state revalidation

- **Severity:** MEDIUM
- **Area:** Plus Guardian disclosure
- **Evidence:** Live guardians_for_unlocked(uuid); 20260806152935…sql:20-46
- **Governed rule:** DR250 D4/D5 current privacy purpose; future Guardian disclosure scope requires reconciliation
- **Current client behaviour:** Previously entitled Plus can request Guardian basics.
- **Current server behaviour:** Checks existing Plus, active link and block, returns first name/gender/location/main/relationship; no target active/visible/current-attempt predicate.
- **User impact:** Withdrawn/inactive target's connected Guardian basics can remain disclosed; exact consent policy not settled by this audit.
- **Security/privacy impact:** Current-state privacy gap; broader consent/field policy needs Founder decision.
- **Minimum reproduction / limits:** Body only; no Guardian data fetched.
- **Files/functions involved:** Live guardians_for_unlocked(uuid); 20260806152935…sql:20-46
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Reconcile current disclosure authorization separately from entitlement permanence; do not invent a new opt-in requirement.
- **Tests required:** Inactive/withdrawn/revoked/blocked/safety/historical Plus and policy refusal.
- **Founder decision / execution authority:** YES where Guardian disclosure fields/consent differ from already approved policy.
- **Production apply approval:** YES — future scoped disclosure migration GO.
- **Evidence status:** Confirmed guard gap; policy resolution required
- **Action trace:** OA-ZYRA-285 / OA-ZYRA-292
- **Repair phase:** 0

Source/document locators: [SOURCE/supabase/migrations/20260806152935_guardian_relationship_guardians_for_unlocked.sql](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/supabase/migrations/20260806152935_guardian_relationship_guardians_for_unlocked.sql>).

### F59 — Latest source is not proof the phone or TestFlight was updated

- **Severity:** MEDIUM
- **Area:** Delivery evidence
- **Evidence:** Prior OA304 receipt signed PROFILE1.0.0+5; device unavailable CoreDevice4016; runbook describes olderbuild3
- **Governed rule:** Runbook immutable artifact/delivery/Founder acceptance separation
- **Current client behaviour:** This audit performs no install/build/upload; existing phone/source equivalence not verified.
- **Current server behaviour:** App Store/current distribution state not freshly inspected in this phase.
- **User impact:** Founder may test a different immutable build and think repair regressed.
- **Security/privacy impact:** No separate cross-user exposure established; see impact.
- **Minimum reproduction / limits:** Compare recorded receipt and current source, not assumed installed version.
- **Files/functions involved:** Prior OA304 receipt signed PROFILE1.0.0+5; device unavailable CoreDevice4016; runbook describes olderbuild3
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** After repair approval, exact signed artifact verify/install/launch and Founder acceptance; separate TestFlight GO.
- **Tests required:** Bundle/version/hash/current account/source pins and physical installed build receipt.
- **Founder decision / execution authority:** No new product decision; approve bounded repair scope before implementation.
- **Production apply approval:** No for client-only repair; separate release/delivery GO remains.
- **Evidence status:** Evidence gap
- **Action trace:** OA-ZYRA-286 / OA-ZYRA-304
- **Repair phase:** 4

Source/document locators: [SYSTEM/RESOURCES/REVIEWS/ZYRA_APP_FLOW_UI_REVIEW_2026-10-03_VERIFICATION.json](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/RESOURCES/REVIEWS/ZYRA_APP_FLOW_UI_REVIEW_2026-10-03_VERIFICATION.json>); [SYSTEM/DOCUMENTS/ZYRA_APP_STORE_RUNBOOK_CURRENT_VERSION_V2.md](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/DOCUMENTS/ZYRA_APP_STORE_RUNBOOK_CURRENT_VERSION_V2.md>).

### F60 — Stage2 counterexample prevents an absolute inference-free claim

- **Severity:** INFORMATIONAL
- **Area:** Compatibility privacy acceptance
- **Evidence:** Historical OBS01 two synthetic worlds differ q33 and yield99vs100; OBS02–11/REV05 deferred
- **Governed rule:** DR250 measured residual-risk acceptance; exact Standard result remains intended
- **Current client behaviour:** Protected Plus categories are labelled synthetic; ordinary categories unavailable.
- **Current server behaviour:** Stage2 not deployed; public legacy oracle tracked F04.
- **User impact:** Removing category percentages alone cannot establish zero inference from exact Standard or order/transcripts.
- **Security/privacy impact:** Research privacy counterexample, not newly observed production disclosure.
- **Minimum reproduction / limits:** Historical measured result, NOT replayed as current live exploit.
- **Files/functions involved:** Historical OBS01 two synthetic worlds differ q33 and yield99vs100; OBS02–11/REV05 deferred
- **Whether live data is affected:** No member data changed or queried; source-level defect or evidence gap.
- **Recommended fix:** Measure full observable transcript and document residual risk before activation.
- **Tests required:** Standard baseline + incremental Plus, ordering/errors/timing/history/multi-account and Guardian combinations.
- **Founder decision / execution authority:** YES — category bands/suppression/minimum useful disclosure/retention and measured risk acceptance remain undecided.
- **Production apply approval:** YES for any later implementation/activation; no policy-only GO inference.
- **Evidence status:** Research limitation
- **Action trace:** OA-ZYRA-193 / OA-ZYRA-285
- **Repair phase:** 0

Source/document locators: [SYSTEM/DOCUMENTS/ZYRA_COMPATIBILITY_SERVER_STAGE2_HANDOVER_CURRENT_VERSION_V1.md](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/DOCUMENTS/ZYRA_COMPATIBILITY_SERVER_STAGE2_HANDOVER_CURRENT_VERSION_V1.md>).

### F61 — Feedback category chips may overflow enlarged narrow layouts

- **Severity:** MEDIUM
- **Area:** Accessible layout
- **Evidence:** feedback_screen.dart:154-190 fixed Row;17px horizontal padding and9px margins
- **Governed rule:** Readable responsive controls at320px and large text
- **Current client behaviour:** Idea/Problem/Other gesture chips share fixed Row without Wrap/Flexible.
- **Current server behaviour:** No server relevance.
- **User impact:** Enlarged labels can exceed usable width or shrink touch usability.
- **Security/privacy impact:** No separate privacy impact.
- **Minimum reproduction / limits:** Source width estimate only; actual overflow NOT reproduced. Run320×568 at1.4x/2x real Poppins with keyboard.
- **Files/functions involved:** feedback_screen.dart:154-190
- **Whether live data is affected:** No member data or writes. Geometry candidate requiring fixture/device proof.
- **Recommended fix:** Measure then use responsive layout preserving selected/save semantics.
- **Tests required:** Narrow large-text chip/Send/keyboard semantic and geometry fixture.
- **Founder decision / execution authority:** No new product rule; visual acceptance after bounded repair.
- **Production apply approval:** No database apply; release/delivery GO separate.
- **Evidence status:** Evidence-backed candidate; not reproduced
- **Action trace:** OA-ZYRA-257
- **Repair phase:** 3

Source/document locators: [SOURCE/lib/screens/settings/feedback_screen.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/settings/feedback_screen.dart>).

## Exact changed-artifact inventory

**No product files changed.**

Documentary artifacts created:

- [ZYRA_FULL_APP_AUDIT_HANDOVER_CURRENT_VERSION_V1.md](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/DOCUMENTS/ZYRA_FULL_APP_AUDIT_HANDOVER_CURRENT_VERSION_V1.md>) — this governed report; observations, all61 findings, rule/client/server/test matrix, repair programme and approval boundaries.
- [ZYRA_FULL_APP_AUDIT_2026-10-03_EVIDENCE.json](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/RESOURCES/REVIEWS/ZYRA_FULL_APP_AUDIT_2026-10-03_EVIDENCE.json>) — safe catalog/definitions, queries, measured test summaries, migration drift, hashes, scope exclusions and structured finding ledger. No credentials or member contents.

Documentary artifacts updated:

- [OUTSTANDING_ACTIONS_V2.md](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md>) — append OA-ZYRA-305 above metadata; NEXT305→306 and total304→305. Existing OAs are linked, not silently reopened or closed.
- [ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V4.md](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/DOCUMENTS/ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V4.md>) — safe established generator refresh to discover this report. No contract rewrite.

Generated diagnostics, separate from product edits:

- SOURCE/test/visual/failures/ — Flutter golden comparator diagnostic PNGs;496 present at observation, pre-run count unknown. Approved images unchanged.
- Flutter/Dart test tool caches are incidental diagnostics, excluded from product hashes and not promoted as deliverable/approved artifacts. No build/install archive was created.

Six safe aggregate categories—lib, tests (excluding generated failures), native, migrations, assets and root tools—match exactly before/after the captured audit window. The snapshot was captured mid-audit, not pretended to be a complete turn-entry archive; safe index/HEAD inspection and each auditor's no-edit confirmation supply additional ownership context. Configuration/credential files and caches were excluded; this is not a hash/secret scan of protected material. No Git command, source patch, approved-golden update, migration apply, provider setting, production row, charge, entitlement, app installation or TestFlight upload occurred.

## Recommended next step

**Hold public/external release and approve the narrowly scoped Phase0 security repair brief first.** Start with F01 retained safety evidence, F02 temporal Guardian history and F03 photo-owner binding; then close the remaining exposed legacy/held authorization paths. Local repair plus isolated synthetic proof and exact production execution are separate Founder gates. Do not approve the whole Sep24 package or use client test success as live authorization proof.

Audit complete is not repair complete, release approval or Founder acceptance. OA-ZYRA-305 remains OPEN. No further live containment or member-data inspection will occur without exact authority.
