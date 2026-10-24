# CODEX HANDOVER — ZYRA FULL HEALTH CHECK AND REPAIR

**Version:** V1  
**Status:** CURRENT_VERSION — local repairs internally verified; production apply and release NOT approved  
**Date:** 2026-09-24 (audit began 2026-09-23)  
**Owner:** Codex — ZYRA product, under Founder authority and AD-AIOS-110  
**Authority:** Founder's attached “ZYRA FULL APP HEALTH CHECK AND REPAIR” execution request. This report does not create new commercial, privacy or Journey rules.

## Result

> **Current client-review overlay — 2026-10-03 / OA-ZYRA-304 / AD-AIOS-111.**
> `ZYRA_APP_FLOW_UI_REVIEW_HANDOVER_CURRENT_VERSION_V1.md` owns the later full
> Seeker/Guardian/onboarding route, failure-state and shared-UI review. The
> September audit below is preserved historical/backend evidence, not the latest
> pricing, source version, device artifact or operating-model authority. Basic
> £4.99 once was reinstated by DR-ZYRA-252; the October membership choice is
> intent-only and does not activate a receipt, entitlement or provider. The
> current +5 signed local delivery and client checks do not close September's
> held live-provider/backend/release actions. Current authority is AD-AIOS-111,
> superseding the historical AD-AIOS-110 header for active work.

The app is materially safer in the working source, but **not ready for a public launch or ordinary-member TestFlight acceptance**. Real identity verification, paid membership lifecycle and several live backend capabilities remain incomplete. An unsigned production-mode iOS build succeeds; that is compilation evidence, not proof of a usable signed release.

- **42 grouped findings:** **29 repair groups implemented locally or staged**, and **13 outstanding groups** listed below. This is an issue-group count, not a claim that every possible defect has been found.
- **Four product-rule gates are now resolved.** Two later activation approvals remain: the exact production migration batch and IDV/provider rollout. Other follow-up work is engineering or verification, not a reason to ask the Founder to approve every small fix.
- **No production migration, account deletion, subscription change, provider change, device install, TestFlight upload or external message was performed.**
- Existing pixel baselines remain unapproved for the newer screens. Layout tests are separate from pixel approval.
- Current presentation is **Seeker One £29.99/month; Guardian One £19.99/month; configurable ZYRA Family with independent 0–10 role places and a maximum 40% formula saving; no consumer Basic/free offer**. This is not yet a completed server/store billing rollout.

### Scope, working state and rollback

Project: `/Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA`; Flutter app: `SOURCE`.

Before edits, the recorded branch pointer was `refs/heads/main`, revision `ce4fb8128a3018aae4046be50892be37a753d08e`. A read-only index comparison found **263 pre-existing differences**, preserved throughout. This comparison is not a complete staged-versus-HEAD report. No git commands were used.

The other identified “ZYRA APP BUILD” task was not loaded/running when checked; four recent turns were complete. Its returned turn bodies were empty, so this does not prove all prior intent was inspected. No active Flutter/Xcode process was found at the initial check. Three bounded audit agents worked on separate areas with shared-file coordination and cross-review; they are not external approval authorities.

Evidence root, abbreviated **E** below:

`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/evidence/zyra_health_20260923_VIAGYP`

`E/source-before.tar.gz` contains **2,615 source files**, with every archived file checked against its pre-edit SHA-256. Build caches, dependencies, logs, `.env`, secret-key extensions and PRIVATE directories were excluded. `E/baseline.json` records the baseline; `E/backup-verification.json` records verification. Pricing, product spec, membership handover, documentation index and index generator have separate pre-edit copies in E. Do not restore the entire tree over later work: compare final hashes and restore only an explicitly selected audit-owned file. Database repairs have not been applied, so no production database rollback is currently necessary.

**Evidence deviation:** the Circle handover was read before its bounded documentation patch, but its pre-edit bytes/SHA were not saved. A reconstructed “original” has not been invented. Its date, staged hash/repair explanation and verification sections changed; the current post-edit hash is recorded in the final manifest. The migration itself is covered by the verified source backup. This documentation gap limits byte-exact rollback of that one handover.

## Critical findings

| Problem | Impact | Fix | Verification |
|---|---|---|---|
| Account deletion could dispatch against a later signed-in account after awaited work or SDK token refresh. | Wrong-account deletion/sign-out risk. | Capture account/generation, recheck after awaits, pin the destructive RPC to the original valid session, and only sign out the original owner. | Six synthetic deletion-isolation tests, including explicit request Authorization and account replacement; no real account touched. |
| Chat displayed a fabricated incoming greeting and could pretend a real member's send succeeded locally. | False communication and loss of trust. | Ordinary routes require a real conversation and successfully loaded history; no invented greeting or local-success fallback. Local sends remain isolated to authorised preview. | New Chat truth tests; failure, genuine empty, retry, preview and account replacement. |
| Failed send removed the last message, even if it was a newly received message. | Visible data loss and draft races. | Append only acknowledged sends, one send in flight, preserve failed/newer drafts and incoming messages. | Concurrent incoming/failure and draft tests. |
| Browse failure looked empty; scoring failure returned unfiltered candidates. | Misleading all-clear and possible Hard Requirement bypass. | Typed unavailable result and Retry; failed scoring never returns an unfiltered deck. | Mocked HTTP exclusion/failure cases and widget tests. |
| Startup/Founder-authorisation reads could wait indefinitely. | Purple/splash stall and late stale authorisation. | Bounded ten-second read waits with generation checks; no late routing hydration or Founder grant. | Hang/late-completion tests. These deadlines do not cancel underlying SDK operations. |
| Two unused legacy purchase RPCs still have ordinary authenticated execution in production. | Legacy test principals can grant themselves Guardian plan access despite removal of UI entry points. | Remove unreferenced client methods; stage narrow EXECUTE revocation for the two proven-unused endpoints. | Exact live definitions tested on synthetic PostgreSQL fixtures: allowed before, denied after. **Production remains unchanged.** |
| Staged Circle open/deletion/concurrency defects. | First open fails; sender deletion fails; concurrent Circles can exceed rate cap. | Named conflict constraint and qualified return; preserve declared SET NULL behavior; sender-scoped lock. | 29/29 isolated PostgreSQL component checks, including old-code counterfactual failures. |
| New ordinary members cannot complete IDV; billing and live Pause are incomplete. | Primary live flows remain blocked regardless of successful app compilation. | Truthful unavailable/denial retained; no bypass, free-access grant or fabricated successful purchase. | Read-only live catalog, provider/gate inspection and entitlement/IDV denial tests. Requires release work, not a cosmetic fix. |

## What I fixed

The following 28 groups are the repair count above. Overlapping file edits belong to one coherent working tree, not 28 independent deployments.

### Security/privacy

- **F01:** Account-deletion principal isolation, pinned request identity, same-owner cleanup and truthful post-delete result.
- **F02:** Startup and privileged refresh timeouts; timed-out responses cannot subsequently grant Founder proof.
- **F03:** Suppressed raw Flutter/framework/platform exception console output in release, installed before initialization. Fixed-category reliability counters remain. This is not a guarantee about every native third-party logger.

### Bugs

- **F04:** `SeekerProfile.photoUrl` no longer crashes on an empty photo list; it follows the shared placeholder contract.
- **F05:** Chat pending-send, concurrent-message and draft handling repaired.
- **F06:** Guardian Circle preserves a newer draft entered while a send is pending. Production Circle gate stays off.
- **F07:** Chat/Browse truth and account-lifetime boundaries: no fabricated Chat content, no member mock send; touched Chat, Browse, Timeline and introductions discard stale account responses and clear owner-scoped visible data.

### Navigation

- **F08:** Five unimplemented Edit Profile rows no longer masquerade as working buttons. They truthfully say unavailable, with no false chevron or no-op tap; saved answers remain unchanged.

### Journeys

- **F09:** Timeline load failure now shows unavailable/Retry instead of “No story yet”. Genuine empty remains distinct.
- **F10:** Failed Guardian-introduction refresh preserves last-confirmed rows and attribution with a stale label; initial failure offers Retry. Failed reads do not mark introductions seen.

### Guardians

- **F11:** Confirmed Guardian entitlement now reaches shared membership state, but only for the unchanged account/generation. Late responses cannot grant the next account access.
- **F12:** Help no longer falsely excludes male Seekers from Guardian surfaces or claims that profile/photo completion alone means a profile is live. No Guardian visibility rule was invented.

### My ZYRA

- **F13:** Visual regression locators now target the actual quiet dashboard and horizontal Guardian roster. New health-capture output is isolated from sealed candidate evidence. Current layout checks pass; historical visual differences still require review. Existing resolver/owner-page/read-versus-resolved boundaries were tested, not redesigned.

### Memberships

- **F14 (superseded 2026-09-24):** Rebuilt the Founder-approved variable Family calculator from one shared formula: 0–10 places per role, 0/0 disabled, 0–40% saving, integer-pence rounding, and explicit store-price-point disclosure.
- **F15:** A Guardian access boolean is no longer represented as proof of a separately billed £19.99 subscription. Current access and who owns cancellation are distinguished.
- **F16:** False or throwing store-management launcher results now show recovery rather than escaping or claiming a cancellation.
- **F17 (superseded 2026-09-24):** Removed Basic/free from the current public catalogue. Legacy enum values remain parseable only for safe migration and developer fixtures; their entitlement limits are zero and the staged public boundary is a full product lock with essential account/safety controls retained.
- **F18:** Removed two client mock-purchase/set-plan methods only after proving no current callers. Server retirement is separately staged below.

### Backend

- **F19:** Fixed ambiguous Circle `ON CONFLICT`/return binding in the existing **unapplied** OA298 migration.
- **F20:** Corrected the Circle sender CHECK/FK conflict, preserving the existing declared anonymising SET NULL behavior. Broader retention policy remains a separate gate.
- **F21:** Serialised sender rate-limit evaluation across Circles; simultaneous sends cannot bypass the ten-per-minute cap.
- **F22:** Staged removal of ordinary client EXECUTE from two unused legacy mock-purchase RPCs. No drops or production mutation.

### Accessibility

- **F23:** Edit Profile row wrapping, contrast and unavailable-state presentation repaired and tested at 320×568 / 430×932 with 2× text. Chat uses clear loading/failure states and an accessible Send tooltip. This is not a full physical-device VoiceOver certification.

### Performance and evidence integrity

- **F24:** Failed Browse queries, photo signing and scoring no longer masquerade as an empty successful load; overlapping loads cannot replace newer results. Unbounded-population optimisation is still outstanding, not claimed fixed.
- **F25:** Historical OA198 tests now validate their preserved original test artifacts and historical 207-migration frontier. Current migration uniqueness and reconstruction-bridge quarantine remain separately enforced. Original digest manifests were not rewritten.

### Release cleanup and documentation

- **F26:** Preflight now matches source version 1.0.0+3 and rejects, rather than requires, the forbidden older IPA hash. This is a negative safety check, not upload approval.
- **F27:** Current pricing/spec/handover overlays reconciled with the explicit Founder brief. Index currency classification respects supersession banners and rollback/archive locations instead of treating every retained CURRENT_VERSION filename as current. Historical documents remain preserved.
- **F28 (superseded 2026-09-24):** Static and browser pricing checks now reject consumer Basic/free, yearly billing and the temporary £49.99/£99.99 offer while pinning Seeker One £29.99/month, Guardian One £19.99/month and the current Family formula.
- **F29:** Staged the consolidated paid-only server contract: verified-person-bound Seeker trial, monthly-only and 16-day grace constraints, independent bounded Family places, verified owner/member roles, seven-day consent invitations, renewal-bound ownership transfer, non-reusable funded removals, single paid-role authority, five-recent Journey returns, separate Guardian View/Chat, Circle paid-participant and history-epoch controls, bounded deleted-message/report retention, and caller-scoped safety-case status after membership expiry. Ordinary execution and all release gates remain held.

## Duplicates found

| Duplicate/overlap | Decision | Action taken |
|---|---|---|
| 235 Dart units; exact-content duplicates | No exact duplicate units found | No speculative file deletion. |
| Temporary fixed Family offer vs the later Founder-approved role-count formula | Fixed £99.99 was superseded | Restored one canonical independent 0–10-per-role formula shared by app, website and staged server authority. |
| Two unreferenced client mock-plan methods and corresponding server mutators | Old implementation to retire | Client methods removed; narrow server ACL retirement staged, not applied. |
| Typed Chat/Timeline/discovery/introduction results and older list-returning methods | Legitimate compatibility adapters, not parallel source owners | Touched user surfaces use typed results; adapters retained for remaining callers. |
| Multiple My ZYRA design/lab components and fixtures | Development-only variants where gated | Retained; public-boundary tests run. Binary string stripping remains a distinct open item. |
| 19 units not reachable in the simple import graph | Uncertain; not proof of dead code | Full list in `E/source_inventory.json`. Dynamic routes, tests and historical contracts preclude blind deletion. |
| Notifications, Now summaries and owner pages | Legitimate different views only while actions stay owner-owned | Existing canonical/read-resolution tests retained; no second inbox or new workflow ownership introduced. |
| Known-code matching, link invitations and ordinary Journey requests | Distinct permissions/intents | Retained; known-code production migration remains staged. |
| Live/local migration timestamps: 27 same-name differences and two naming differences | Historical reconciliation, not duplicate replay permission | Inventory retained; no rename, db push or blanket replay. |
| Documents with old CURRENT_VERSION filenames plus explicit supersession banners | Historical/reference-only | Currency generator repaired; filenames/old evidence not deleted or renamed. |
| Shared profile loading, placeholders, sliders and route guards | Legitimate shared behavior | Existing components reused; no unnecessary replacement design system. |

## Contradictions found

| Conflict | Actual live/current behavior | Resolution |
|---|---|---|
| Fixed £49.99/£99.99 override vs later Founder decisions | The override was temporary and contradicted the recovered role-specific model | DR-ZYRA-248 and Pricing V6 now control: £29.99 Seeker, £19.99 Guardian, configurable Family up to 40%. |
| Paid-only model vs Basic/premium enums and limits | Server retains legacy restricted/premium enforcement; active limit defaults one, three for active seeker premium | Remove misleading marketing, not enforcement. Billing cutover remains blocked. |
| Guardian access vs separate Additional Guardian billing claim | Boolean access does not prove payment owner/product | Neutral current-access card and correct cancellation ownership. |
| Current Pause UI vs live backend | Shared Pause fields/RPCs absent | Document explicit blocker; no unilateral fallback or production apply. |
| Main/Additional View/Chat preview controls vs server | Split permissions not fully implemented in production | Existing OA296 remains open; no privacy expansion. |
| Circle/new-Journey return source vs “live” assumption | Both feature flags false; staged migrations and deliberate return-RPC hold | Truthfully staged/held, not completed live. |
| “All caught up” / “No story yet” vs failed reads | Previous implementations returned empty collections on failure | Typed unavailable and last-confirmed states on touched screens. |
| “Message sent” vs missing real conversation | Old member route could fall back locally | Removed fake success. |
| “Profile live” help vs unimplemented IDV provider | Provider is unavailable; new ordinary verification cannot complete | Correct help; keep fail-closed verification. |
| Public UI has no mock buttons vs legacy server authority | Old email-suffix developer RPCs remain live | Stage two unused RPC revocations; thirteen referenced endpoints require coordinated retirement. |
| Historical 207-file digest vs growing migration tree | Current source now has 217 migrations | Freeze historical frontier, preserve original test bytes, validate current tree separately. |
| Old pixel baseline vs newer approved-in-chat design work | 124 pixel comparisons fail against historical goldens | Keep baselines unchanged; independent layout pass does not approve appearance. |
| AD109 bootstrap text vs AD110 domain split | Current Founder instruction restores Fable for company administration | Apply AD110 to this task; do not silently rewrite group governance or close registers. |
| Universal deletion-copy promise vs retained/anonymised Circle history | Staged Circle FK preserves messages with null sender; client removes photos before account RPC | Requires approved end-to-end deletion/retention wording and workflow. |
| Release access gates pass vs no internal strings in package | Binary retains internal path and demo markers | Report separately; not equivalent to user-visible leakage or an accepted clean package. |

## Founder decisions resolved; activation approvals still held

1. **Resolved — pricing, Family and paid lifecycle.** DR-ZYRA-248 and Pricing V6 control. The app/site calculator and a staged server authority now match the decision. Store products, receipts, webhooks and regional price-point evidence remain engineering work.
2. **Resolved — Journey returns.** Paid initiation from each member's five most recent Paused/Ended rows; 30-day request expiry; 30-day decline cooldown; withdrawal has no cooldown; incoming requests resurface; both people must be below the three-Active cap before send/accept; Ended creates a fresh attempt and preserves history.
3. **Resolved — Additional Guardian View/Chat.** Separate per-active-Journey controls, both default ON; Main permanently ON; Chat requires View. Server/client changes are staged, not live.
4. **Resolved — Circle deletion/report retention.** Removed Guardians lose access immediately; relinking creates a new epoch; deleted-sender messages retain a neutral label for 12 months; protected reported-message evidence retains for 24 months after case closure unless legal/safety hold requires longer.
5. **Still required later — exact production migration approval.** Hold until dependency replay, local PostgreSQL/impersonation/concurrency proof, backup/restore and rollback thresholds are complete. No blanket db push is authorised.
6. **Still required later — IDV activation and rollout.** Stripe remains the selected provider. Complete verified callbacks/security evidence before enabling existing-account enforcement or ordinary-user launch.

## Files changed

All project-relative paths below are rooted at `/Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/`. `E/final_changes.json` is the machine-readable source delta; `E/final_file_manifest.json` records hashes/provenance for intentional edits, generated changes and evidence. Existing unrelated changes are not attributed to this audit.

### Implementation

| File | Purpose |
|---|---|
| `SOURCE/lib/main.dart` | Install release logging policy early; do not emit raw caught errors. |
| `SOURCE/lib/services/zyra_release_diagnostics.dart` | New release-only raw debugPrint suppression. |
| `SOURCE/lib/services/zyra_auth.dart` | Deletion principal safety; remove unused mock-plan methods. |
| `SOURCE/lib/services/zyra_session_router.dart` | Bounded startup reads and staged paid-only routing boundary. |
| `SOURCE/lib/screens/subscription/membership_required_screen.dart` | Restricted post-expiry surface retaining billing, support, privacy/data deletion and sign out. |
| `SOURCE/lib/services/zyra_developer_access.dart` | Bounded privileged refresh and stale completion rejection. |
| `SOURCE/lib/services/zyra_entitlement_service.dart` | Publish same-owner confirmed Guardian entitlement. |
| `SOURCE/lib/data/zyra_membership_catalog.dart` | £29.99/£19.99 paid-only catalogue and canonical Family formula. |
| `SOURCE/lib/widgets/zyra_family_pricing_card.dart` | Independent Seeker/Guardian plus-minus calculator with store-price disclosure. |
| `SOURCE/lib/screens/subscription/upgrade_screen.dart` | Truthful current Guardian access, store recovery and cancellation ownership. |
| `SOURCE/lib/data/zyra_guardian_capacity.dart` | Neutral current-access limit wording. |
| `SOURCE/lib/data/help_content.dart` | Guardian and profile/IDV help truth. |
| `SOURCE/lib/models/seeker_profile.dart` | Safe photo-less profile getter. |
| `SOURCE/lib/screens/chat/chat_screen.dart` | Real-source truth, send/draft repair, account lifetime. |
| `SOURCE/lib/services/zyra_match_service.dart` | Typed Chat/Timeline load results. |
| `SOURCE/lib/screens/matches/journey_timeline_screen.dart` | Retry/empty distinction and account isolation. |
| `SOURCE/lib/services/zyra_discovery_service.dart` | Typed fail-closed discovery/scoring. |
| `SOURCE/lib/screens/browse/browse_screen.dart` | Retry/empty truth, response ordering/isolation, preview-only adverts. |
| `SOURCE/lib/services/zyra_guardian_suggestion_service.dart` | Typed introduction load result. |
| `SOURCE/lib/screens/connections/connections_screen.dart` | Retain labelled known introductions; neutral access copy. |
| `SOURCE/lib/screens/wali/family_messaging_screens.dart` | Preserve newer Circle draft. |
| `SOURCE/lib/screens/profile/edit_profile_screen.dart` | Remove fake edit actions; accessible row layout. |

### Tests, tooling and staged SQL

| File | Purpose |
|---|---|
| `SOURCE/test/chat_screen_truth_test.dart` | New real/preview/failed/send/account Chat regression coverage. |
| `SOURCE/test/browse_truth_test.dart` | New exclusion/failure/empty/retry/account Browse coverage. |
| `SOURCE/test/timeline_introductions_truth_test.dart` | New Timeline/introduction stale and Circle draft tests. |
| `SOURCE/test/zyra_account_deletion_isolation_test.dart` | New destructive principal-isolation tests. |
| `SOURCE/test/zyra_guardian_entitlement_isolation_test.dart` | New owner/generation entitlement tests. |
| `SOURCE/test/edit_profile_truth_test.dart` | New truthful unavailable rows and 2× text layouts. |
| `SOURCE/test/help_truth_test.dart` | New help-copy contract checks. |
| `SOURCE/test/zyra_release_diagnostics_test.dart` | New release log-policy tests. |
| `SOURCE/test/family_membership_pricing_test.dart` | Canonical variable Family formula, all 121 valid role-count combinations and responsive plus/minus presentation. |
| `SOURCE/test/founder_paid_only_contract_migration_test.dart` | Static guards for the paid-only/Family/trial/Journey/Guardian/Circle forward contract and held activation boundaries. |
| `SOURCE/test/safety_case_status_screen_test.dart` | Safety-case status stays visible after paid feature lock without exposing other members. |
| `SOURCE/test/membership_management_screen_test.dart` | Billing ownership and store-launch failure coverage. |
| `SOURCE/test/zyra_guardian_capacity_test.dart` | Current neutral wording. |
| `SOURCE/test/zyra_startup_routing_test.dart` | Startup read timeout/late response coverage. |
| `SOURCE/test/zyra_developer_access_concurrency_test.dart` | Timeout cannot later grant privileged access. |
| `SOURCE/test/zyra_ios_testflight_release_preflight_test.dart` | Current build number and banned-artifact rejection. |
| `SOURCE/test/zyra_oa198_replay_bridge_artifact_test.dart` | Historical frontier plus full active bridge quarantine. |
| `SOURCE/test/zyra_oa198_replay_bridge_v2_artifact_test.dart` | Preserve historical V2 integrity contract. |
| `SOURCE/test/zyra_oa198_probe_score_replay_bridge_artifact_test.dart` | Preserve probe-score historical integrity contract. |
| `SOURCE/test/support/oa198_historical_inventory.dart` | Shared historical migration inventory helper. |
| `SOURCE/test/migration_inventory_test.dart` | Current migration version uniqueness. |
| `SOURCE/test/fixtures/oa198/zyra_oa198_replay_bridge_artifact_test.dart.txt` | Exact pre-edit historical test bytes. |
| `SOURCE/test/fixtures/oa198/zyra_oa198_replay_bridge_v2_artifact_test.dart.txt` | Exact pre-edit historical test bytes. |
| `SOURCE/test/fixtures/oa198/zyra_oa198_probe_score_replay_bridge_artifact_test.dart.txt` | Exact pre-edit historical test bytes. |
| `SOURCE/test/visual/zyra_visual_regression_test.dart` | Actual dashboard/roster locators; isolated health candidates. |
| `SOURCE/test/family_messaging_foundation_test.dart` | Circle SQL regression contracts. |
| `SOURCE/test/zyra_retired_legacy_mutators_test.dart` | New narrow ACL retirement and absence-of-callers guard. |
| `SOURCE/tools/zyra_ui_gate.py` | Current commercial price warnings. |
| `SOURCE/tools/test_doc_index.py` | New supersession/archive currency tests. |
| `SOURCE/supabase/migrations/20260919185927_oa298_family_messaging_foundation.sql` | Three repairs to existing unapplied Circle migration. |
| `SOURCE/supabase/migrations/20260923225150_retire_unused_legacy_purchase_mutators.sql` | New staged client EXECUTE revocation for two unused legacy RPCs. |
| `SOURCE/supabase/migrations/20260924100231_founder_paid_only_returns_guardian_circle_contract.sql` | New staged DR-ZYRA-248 paid-role, trial, Family, Journey-return, Guardian permission, Circle retention and safety-status contract. |

### Documentation

| File | Purpose |
|---|---|
| `BUSINESS/ZYRA PRICING/ZYRA_PRICING_CURRENT_VERSION_V6.md` | Current DR-ZYRA-248 paid-only prices, Family formula, lifecycle and launch-market contract; V5 is superseded. |
| `SYSTEM/DOCUMENTS/ZYRA_PAID_MEMBERSHIP_HANDOVER_CURRENT_VERSION_V5.md` | Current commercial presentation and unresolved activation/allocation truth. |
| `SYSTEM/DOCUMENTS/ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V5.md` | Explicit controlling commercial overlay, preserve historic body. |
| `SYSTEM/DOCUMENTS/ZYRA_FAMILY_MESSAGING_HANDOVER_CURRENT_VERSION_V1.md` | Repaired staged hash and component verification, production still held. |
| `SYSTEM/tools/generate_doc_index.py` | Correct currency classification; skip PRIVATE directories. |
| `SYSTEM/DOCUMENTS/ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V4.md` | Regenerated index including this handover and corrected historical status. |
| `SYSTEM/DOCUMENTS/ZYRA_FULL_HEALTH_CHECK_HANDOVER_CURRENT_VERSION_V1.md` | This combined result, decisions, verification and rollback record. |

Generated files are **not** source repairs: `SOURCE/ios/Flutter/Generated.xcconfig` and `flutter_export_environment.sh` reflect local build commands. The observed `SOURCE/ios/Runner.xcworkspace/xcuserdata/shakeelahmad.xcuserdatad/UserInterfaceState.xcuserstate` change is user/Xcode state of unproven ownership and was not overwritten. Visual failure images and fresh layout candidates are test evidence, not approved baselines. The exact generated-output disposition is retained in the final manifest.

All 36 changed failure images were moved to `E/final-golden-failures` and the pre-existing files restored byte-for-byte. All 799 sealed candidate/baseline files and the git index were verified unchanged. Final manifest classifies **57 intentional source/document edits** and **three generated/unowned file changes**.

## Database changes

**Staged only. No production apply.**

1. Existing unapplied `20260919185927_oa298_family_messaging_foundation.sql`: SHA-256 `27bda6deefd981ad84c900c1db52d578e7a1383656f871f85284214ad1c7c986`.
2. New `20260923225150_retire_unused_legacy_purchase_mutators.sql`: SHA-256 `f3521467d45c10aeea0cf346e08c50309d112499fa6f8e4251e7e58d2010f7c6`.
3. New `20260924100231_founder_paid_only_returns_guardian_circle_contract.sql`: SHA-256 `f6af8a28e1b0ce319a8daaa39ff22fc30574bd6c9d47f70a5de8cfec49374006`.

Live read-only inspection found **210 recorded migrations; 217 local now**, including the new staged revoke. Counts alone do not identify missing semantics: 27 same-name timestamp differences and two name discrepancies require historical reconciliation. Shared Pause really is absent (`matches.pause_state`, `transition_journey_pause`, `zyra_my_pause_states`). OA294, OA295, OA256, OA298 and OA299 capabilities are also staged/not live. No Edge Functions were deployed.

Security evidence: 49 public/private ordinary tables have RLS; all inspected SECURITY DEFINER functions have explicit search paths, none grants anon EXECUTE, and no function bodies use editable user-metadata claims for authority. Sensitive raw tables are not ordinary-client granted. Synthetic-principal read-only live probes demonstrated raw Journey/compatibility denial and zero stranger participation/messages/subscriptions; provider-result EXECUTE is denied to anon/authenticated.

Advisor findings are not automatically vulnerabilities: one caller-filtered definer view intentionally exposes only `auth.uid()`-owned participation; 97 authenticated definer warnings require function-level review, not automatic revocation. Password-leak protection warning and 16 no-policy RLS infos remain. Performance advisories: 14 unindexed FK, four no-PK, 22 unused indexes and six multiple-permissive-policy warnings. No speculative index, table or policy deletion occurred.

The earlier 29 PostgreSQL tests used the then-current staged SQL/legacy definitions with minimal synthetic external fixtures on PostgreSQL 17.6, in a networkless container with no host mounts, ports, production secrets or persistent volume. The later DR-ZYRA-248 migration has static contract coverage but has **not** received PostgreSQL replay: Docker was unavailable on the final pass (`/var/run/docker.sock` absent). This is not full-chain replay, full account-deletion cascade proof or production acceptance.

## Tests

| Check | Result / limitation |
|---|---|
| Baseline analyzer | Pass. |
| Final `flutter analyze --no-pub` | **No issues found.** |
| Final focused paid-contract/UI run | **49 passed, zero failed.** |
| Final all non-visual Flutter run | **1,313 passed, one intentionally skipped, zero failed** across 154 test files. |
| Baseline full suite | 1,699 passed, 129 failed, one skipped; retained as comparison. |
| Full post-repair suite | 1,749 passed, 126 failed, one skipped. 124 are historical pixel mismatches; two missing test shader assets are explained in the isolated rerun below. Original failing log retained. |
| Dashboard shader-failure rerun | Both failing tests passed individually unchanged, then both complete files passed together **147/147**. Missing Flutter shader assets are consistent with overlapping independent Flutter commands sharing the same test bundle; this was not an app assertion failure. Subsequent independent Flutter commands are serialised. |
| Final sequential non-visual-directory run | **1,289 passed, one conditionally skipped, zero failed.** No other Flutter command ran concurrently. Additional visual-directory layout suites are verified separately below. |
| Additional visual-directory suites | **251 passed** across the My ZYRA designs, supportive dashboard, Developer Access and quiet dashboard layout suites; no capture/update flag and no baseline changes. |
| Focused UI regression | 100/100 across 11 suites, including 20 new truth tests. |
| Focused auth/membership | 27-, 57-, 26- and 22-test runs passed; overlapping, not summed. Final deletion 6/6 and management 5/5 passed. |
| Root repair tests | 25 passed. |
| Isolated layout capture | **335 passed:** 331 render cases plus four integrity checks. Small/standard/large sizes, selected enlarged text; not pixel approval. |
| Explicit public production boundaries | **20 passed** without internal opt-in. |
| Conditional IDV fail-closed branch | **One passed** with enforcement fuse enabled only in the test command; app default unchanged. |
| PostgreSQL security/component checks | **29/29 passed**, including direct-write/anonymous/stranger denials, removal/block/re-link, deletion and concurrency. |
| Circle/legacy SQL Dart guards | 7/7 + 2/2 passed. |
| Python tooling tests | Four passed (including three new index-currency cases). |
| Public website paid/pricing/motion/browser suite | **PASS:** 121/121 Family combinations; 24 scroll-unit checks; 99 core browser checks; 247 audience/pricing checks; 77 cinematic-scroll checks; automated accessibility reported zero violations in every tested scope. Production-style static build also passed. |
| Final unsigned iOS profile build | `flutter build ios --profile --no-codesign` **passed**; Runner.app 35.5 MB as reported by Flutter (34 MB on disk), 144 files. Unsigned, not installed/exported/uploaded. |
| Production iOS build | `flutter build ios --no-pub --release --no-codesign --flavor production` **passed**; Runner.app 26.0 MB, arm64, bundle `app.zyraconnect.zyra`, 1.0.0 (3). Unsigned, not installed/exported/uploaded. |
| Release artifact inspection | 144 files scanned; no high-signal private-key/service-role/privileged-key matches. The sole decoded JWT role was public `anon`. Retained strings: 395 native symbol/debug paths, one resident Dart registrant URI and one demo-code literal. No claim that package bytes are clean or all possible secrets ruled out. |
| Physical iPhone/VoiceOver/OAuth/store/two-device chat | Not performed. |

Failures are retained, not hidden: approved golden images were not replaced. The first existing candidate-capture command overwrote copies of sealed candidates; all original candidate bytes were restored from verified backup and new images preserved separately. The repaired harness now captures only to a dedicated health destination. Original digest evidence remained intact. One early analyzer run had two unnecessary-escape infos in a new test; these were fixed before the final clean run. A reserved Flutter flavor-define invocation was rejected and corrected to `--flavor production`. The older regex static checker reports parser false positives on valid Dart syntax; the Dart analyzer is the authoritative syntax result.

## Still outstanding

These are the **13 open groups** counted in Result; a release limitation is not being called a completed repair.

| ID | Work/risk | Existing trace / next owner action |
|---|---|---|
| O01 | IDV provider integration, verified callbacks and controlled existing-account rollout; new ordinary onboarding currently blocked | OA266; Codex preparation, Founder activation gate. |
| O02 | Real checkout/receipt validation, regional Store products, webhook lifecycle and operational Family invitation/ownership/trial service | DR-ZYRA-248 server shape is staged, including verified-person trial and Family guards; it is not replayed, deployed or connected to store/provider callbacks. Finish engineering and evidence, then activation GO. |
| O03 | Missing live shared Pause; held Ended-return execution; dependency replay and fresh-attempt ritual proof | OA156/OA198/OA299; rules settled, exact apply gate remains. |
| O04 | Additional Guardian View/Chat split staged in client/server but not production-applied | OA296; run PostgreSQL/RLS/denial/concurrency proof, then exact apply gate. |
| O05 | Circle live incoming delivery and full migration replay; retention contract staged but not production-applied | OA298; live gate remains false pending privacy/security/replay evidence. |
| O06 | Staged Main-Guardian hold, known-code and telemetry capabilities not deployed; no remote crash/health production pipeline proven | OA294/OA295/OA256; exact scoped verification/apply. |
| O07 | Thirteen still-referenced email-suffix dev/debug RPCs plus function-by-function security/advisor review | Coordinated retirement after caller migration; do not falsely treat client gate as server revocation. |
| O08 | 124 historical golden mismatches and native/device QA | Founder visual review plus signed/device test plan; no baseline auto-approval. |
| O09 | Unbounded discovery/photo signing and chat-history loads; reconnect/history-to-Realtime gap and ambiguous-send idempotency | Bounded-query/cursor and delivery design with measured scale tests; no fabricated latency claim. |
| O10 | 72 outdated packages | None marked advisory-affected/retracted in fetched metadata; not proof vulnerability-free. Separate constrained upgrade batch, no indiscriminate major upgrades. |
| O11 | Photo cleanup precedes transactional account deletion; failed final RPC may leave an account missing photos; deletion-copy/retention inconsistency | Server cleanup workflow and decision 4; no real erasure in this audit. |
| O12 | Wider historical document/AD109→AD110 ownership drift; OA298 register still quotes pre-repair Circle hash | Domain-appropriate register/governance reconciliation must copy this report's current staged hash/proof, preserve OPEN/held status and link the new narrow ACL retirement. No register item closed and no new identifier invented here. |
| O13 | Release binaries retain developer absolute paths/demo markers despite passing public access gates | Artifact stripping/symbol policy and final binary acceptance; do not distribute this diagnostic build as a clean release. |

Other coverage limitations: optional Timeline enrichment still best-effort; no exhaustive fuzzing of all authenticated RPCs; no full memory/large-population benchmark, assistive-technology or reduced-motion device audit. The approximately 1.58 MB source asset set showed no oversized unused asset requiring a safe deletion. No AI/model calls or new data processing were added.

The operations skill informed authority, backup/evidence discipline and the separation of internally verified code from Founder production approval. Existing OA references above are follow-up linkage, **not** a claim their living registers were edited or completed. Fable's company-administration role under AD110 and the Founder's sole approval authority are preserved.

## Recommended next step

**Complete isolated PostgreSQL replay and adversarial authority tests for the staged 2026-09-24 contract migration.** Then present the exact immutable migration batch and evidence for the separate production GO. In parallel, finish verified StoreKit/Play receipt and Stripe IDV callback work. Keep ordinary-member TestFlight/public launch on hold until those two activation gates are satisfied.
