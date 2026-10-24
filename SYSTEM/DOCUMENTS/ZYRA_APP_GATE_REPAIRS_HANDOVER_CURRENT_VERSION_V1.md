# ZYRA app gate repair handover

**Version:** V1  
**Date:** 2026-10-05  
**Owner:** Codex under Founder authority and AD-AIOS-111  
**Action:** OA-ZYRA-305 with the existing finding-specific actions  
**Status:** CURRENT_VERSION — local repairs tested and delivered to the Founder iPhone; production database application and Founder acceptance remain open

This handover records the bounded engineering work following the Founder's
“dothem pelase” instruction and explicit permission to run the existing isolated
database VM. It supplements, rather than rewrites, the immutable October 3 full
app audit. No live database migration, member-data change, provider activation,
payment, store submission or external message was performed.

The critical database repairs are prepared and exercised against fake records.
Preparing and testing them does not close the live risks. The application
repair removes ordinary Guardian preview authority and makes previously opened
preview content withdraw when its authority or account changes. The approved
onboarding copy, page structure, fonts, prices and design remain unchanged.

## Authority and evidence

The Founder alone approves. Local implementation, internal verification,
production GO, post-verification and Founder acceptance remain distinct under
the Founder Codex Operating Model V2. Sibling agents supplied bounded work and
internal checks; they are not external independent auditors or approvers.

The dated machine-readable receipt is
`SYSTEM/RESOURCES/REVIEWS/ZYRA_APP_GATE_REPAIRS_2026-10-05_EVIDENCE.json`.
It owns exact file and log hashes, final test measurements, isolation cleanup,
build identity and the earlier undelivered state. The later local installation
is recorded separately in
`SYSTEM/RESOURCES/REVIEWS/ZYRA_APP_GATE_REPAIRS_LOCAL_DELIVERY_2026-10-05_VERIFICATION.json`;
the earlier receipt remains unchanged. The original audit remains
`ZYRA_FULL_APP_AUDIT_HANDOVER_CURRENT_VERSION_V1.md` and its October 3 receipt
SHA256 is `a3f02c512d31bdc1a3ae7b8e860c4f188e1b5d903bae98a6671a5ead3db9c4fb`.
Fresh October 5 catalog receipts for photo, progress and credit authority are
separate metadata-only files in the same reviews directory. They contain no
member contents, credentials or payment proof.

Current product authority includes DR-ZYRA-225/232/233 for current Guardian
Journey access, DR-ZYRA-248 for Circle permissions and its named retention
scope, DR-ZYRA-250 for compatibility, DR-ZYRA-252 for Basic £4.99 once,
DR-ZYRA-253 for the protected opening, and DR-ZYRA-257 for home phone delivery.
Older July messaging summaries are not current runtime authority.

## Database repair state

All paths in this section are under `SOURCE/supabase/`. No candidate was
applied to the live project. Never bulk-apply this folder: the F04 preparation
artifact deliberately refuses non-synthetic databases, and unrelated staged
migrations retain their own holds.

| Finding | Candidate migration | Local behavior | Live state |
|---|---|---|---|
| F01 | `20261005113808_oa305_f01_safety_report_retention.sql` | Safety reports survive deletion of either participant; subject references become null | Not applied |
| F02 | `20261005114141_f02_guardian_current_attempt_read_boundary.sql` | Guardian chat and rich counterpart details are limited to current active attempts and current link grants | Not applied |
| F03 | `20261005113453_f03_photo_row_object_owner_binding.sql` | Photo row owner, canonical object prefix and Storage owner must agree | Not applied |
| F04 | `20261005120711_oa305_f04_private_legacy_score_and_browse_ids.sql` | Preparation-only private canonical legacy scorer and ID-only Browse ordering | Not deployable alone; not applied |
| F05 | `20261005120004_oa305_f05_private_progress_helpers.sql` | Ordinary callers cannot execute four arbitrary-user progress or maintenance helpers | Not applied |
| F06/F07 | `20261005120420_f06_f07_unlock_hold_serialization_receipts.sql` | Default-off Plus hold, serialized new debits and durable successful-operation bookkeeping | Not applied |

### Safety report preservation

F01 changes only the two report-to-profile foreign keys to nullable SET NULL.
It preserves case identity, evidence already in the report, source, status and
dates. It does not preserve the deleted account itself or prevent removal of
that account's owned photos. The deletion function remains byte-identical.
The tests reproduce the old cascade, then exercise authenticated and anonymous
denials, legitimate reporting, deletion of either or both subjects, retries,
review rights and unrelated-object preservation.

No new legal hold, moderator authority, identity archive or universal retention
period was invented. DR248's specific Circle message retention is not silently
extended to every profile report. Lawful report expiry and operational hold
handling remain an OA305 acceptance dependency.

### Current Guardian access

F02 keeps Seeker archives but denies Guardian detail for ended, potential or
foreign attempts. Current Main support includes an already-active attempt that
began before the Main link; no new timestamp cutoff contradicts DR225/233.
Paused Journeys retain their active attempt status. Additional Guardians need
an unrevoked assignment whose grant is within the current link period. Reusing
a link cannot revive an old assignment; a fresh explicit grant is required.

The same boundary covers conversation and message RLS, match identity and
`zyra_counterpart_card`. Past-summary consent never grants rich detail. The
existing four-field summary and Seeker message INSERT rule are unchanged.
The synthetic bootstrap reconstructs the necessary match column SELECT grants;
it is not proof of a fresh gateway JWT session or a complete live migration
replay. Nine changed-catalog cases refuse without changing persistent catalog.

### Photo ownership

F03 binds `profile_photos.user_id`, the canonical UUID prefix in the private
object path and `storage.objects.owner_id`, including privileged row writes.
It adds no seed or null-owner exception. Own uploads, row registration,
reordering, replacement and deletion remain tested, together with discovery,
current Guardian/Journey access and privacy/block/safety withdrawal.

This is ownership enforcement, not trusted image moderation. SQL tests do not
prove real Storage API signing, revoke already-issued URLs, purge remote caches
or repair legacy null-owner/foreign rows. Reconciliation or re-upload requires
its own exact production approval. Existing visibility authority is unchanged.

### Compatibility preparation

F04 clones the exact retained scorer into a private canonical scored-topic
whitelist, preserving old valid arithmetic. Unknown, Bio and information-only
preferences or hard controls cannot become counterpart answer probes. Ordinary
numeric execution is denied in the local candidate; retained postgres-owned
Journey RPCs keep their existing internal delegate and gates.

`zyra_browse_ranked_ids(uuid[])` returns only ordered candidate IDs, preserving
hard exclusion, null-last ordering and input-order ties. SQL's one OUT UUID
argument is a scalar transcript; gateway encoding and the future mapper remain
unmeasured. Ordered IDs still permit observable inference; this is not a privacy
certificate or a complete D1–D6 implementation.

This candidate is intentionally not deployable alone. Existing Flutter Browse
and Unlock still call the numeric endpoint. Required coordinated work is the
Browse ID mapper, removal of the pre-entitlement Unlock fetch, authorised
immutable directional saved-result reads and integration of the same result
with Journey. Strict input validation, semantic provenance, shared immutable
result behavior, retention and residual inference acceptance remain open.

### Private progress and credit authority

F05 revokes ordinary EXECUTE on `zyra_onboarding_missing`,
`zyra_onboarding_complete`, `zyra_onboarding_data_complete` and the companion
mutation helper `zyra_refresh_onboarding_complete`. Their bodies and existing
trusted paths remain intact. The app's caller-pinned
`zyra_my_onboarding_progress()` wrapper and internal save-trigger maintenance
continue to work. Linked Guardian status, profile visibility or payment does
not grant another member's private progress.

F06/F07 creates private release, account-guard and successful-operation tables.
Plus stays OFF and a CHECK prevents a flag flip from being mistaken for an
activation contract. New Plus entitlement INSERTs are zero-row holds rather
than aborting a future enclosing Journey; the known RPC callers report the hold
truthfully. New negative Plus ledger entries are denied. Existing unchanged
Plus rows remain recognised. `automatic_match` is Standard, not Plus.

All entitlement and ledger row writers acquire the same per-account guard.
One successful Standard operation binds actor, target and tier to its
entitlement, debit and private receipt in one transaction. Retry is no-charge;
a receipt with a missing entitlement returns recovery_required rather than
charging again. A deliberately stale REPEATABLE READ session must retry the
whole operation with SQLSTATE40001. The test harness observes real lock waits
for both same-target and different-target simultaneous last-credit requests.

The current client treats the new plus_unavailable and recovery_required
responses as failure, never as a granted unlock. Dedicated recovery UX and
status mapping must be included in the eventual deployment check; no successful
client recovery experience is claimed here.

These records are not payment-provider receipts or saved compatibility results.
Positive included grants are unchanged and no live balances were backfilled.
Privileged DELETE, the old seeded-email developer reset/authority (F36), bulk
writer deadlocks/retries, legacy ownership already deleted, bookkeeping
retention and target-erasure reconciliation remain open. The candidate does
not certify arbitrary privileged ledger correction as safe.

## Application authority repair

The F19 repair keeps the visual design but changes who may use sample data and
how long that data can remain displayed. `guardianOverride` now requires fresh
protected developer authority; ordinary launch/reset/sign-out cannot turn a
stored preview preference into account authority.

Live files under `SOURCE/`:

- `lib/dev/zyra_dev_scenario.dart`: protected Guardian preview predicate.
- `lib/screens/wali/seeker_wali_tab.dart`: owner/request-pinned real roster;
  authority changes clear fixtures and stale local action callbacks are denied.
- `lib/screens/journey/journey_flow_screen.dart`: immediate withdrawal before
  live Guardian gate refresh; late, superseded and foreign-account results
  cannot publish. Optional test transport defaults to the existing service.
- `lib/widgets/zyra_guardian_preview_lifetime.dart`: denial-only owner and
  generation lifetime; requested preview never grants authority. Revocation
  cannot silently turn a retained preview route into live mode.
- `lib/screens/wali/family_messaging_screens.dart`: Circle/inbox fixture,
  composer, asynchronous send and context/member/readers destinations use the
  same lifetime. Unavailable live context never falls back to synthetic identity.
- `lib/screens/wali/seeker_guardian_designs.dart`: retained Guardian Journey,
  chat-access and history-consent controls withdraw sample grants and reject
  stale callbacks and load results.
- `lib/widgets/zyra_message_receipt.dart`: optional default-preserving caller
  guards for a previously opened readers sheet.

An already-open sheet clears its child and removes only its exact route after
the frame; it does not broadly pop unrelated navigation. The Circle live
release gate remains held. Test-only transports, fixtures and authorised test
seams do not grant a production account role or server entitlement.

Focused tests cover ordinary launch, authorised preview, revocation, account
change, preview-to-live handoff, delayed READY results, stale callbacks and
already-open sheets. Existing intentional preview fixtures must explicitly
authorise themselves. The exact final inventory and results are in the receipt.

## Isolated verification and cleanup

`SOURCE/tool/run_oa305_isolated_sql.mjs` uses only the cached pinned PostgreSQL
17.6 image and existing explicitly approved `zyra-oa198` VM. Every run creates
its own labelled container with network none, no ports, no host mounts,
read-only root and a synthetic tmpfs database. SQL inputs and includes are
screened and hashed before execution. No cloud connection is available.

The runner resolves only its own exact container identity after an ambiguous
launch, bounds worker execution, settles independent sessions and stops that
container in finally. It verifies absence after stop. The final receipt records
VM return to its original stopped state and unchanged profile configuration.
Synthetic JWT claim GUCs and direct roles are test actors, not real Auth tokens.

F01, F02, F03, F04, F05 and F06/F07 each have dedicated fake prestate and
positive/denial assertions. F02 includes nine exact drift refusals. F06/F07
includes deterministic account-lock contention, a deliberately stale snapshot,
lost-ack retries and injected partial failure. Earlier failures and corrections
are retained in logs; a passing final run does not erase them. Transaction or
savepoint recovery is not a physical database-plus-photo backup restore.

Application checks include focused regressions, the full explicitly nonvisual
test inventory, analyzer and the existing UI gate. Pixel baselines are not
rewritten. Native screen-reader and poor-radio acceptance are not inferred from
unit tests. Final signed main PROFILE build identity and phone availability are
recorded separately from source tests and Apple/TestFlight artifacts.

## Final local measurements — October 5

- Six synthetic SQL packages passed 194 named PASS-notice groups in total:
  F01 10, F02 55, F03 62, F04 8, F05 6 and F06/F07 53. These are groups, not a
  count of nested assertions. F01 includes its exact-repeat refusal; F02 also
  passed nine separate changed-catalog refusal runs. Expected stale/refusal
  errors are distinguished from unexpected failures in the dated receipt.
- Eight focused Guardian regression files: 101 passed, no failures or skips.
- Full explicit inventory of 236 nonvisual test files: 2,703 passed, two
  conditional skips, no failures. The opt-in real-photo fixture acceptance and
  the existing-account IDV-fuse case were not measured by this default run.
- Analyzer: zero issues. Deterministic UI gate: PASS-WITH-FINDINGS, 311
  findings (zero critical/high, 23 medium and 288 low). The single newly
  recorded LOW import-string repetition is triaged under OA257/305, not a
  user-facing duplicate or reason to change approved UI. No suppression added.
- Real Poppins Guardian fixed-slot layout matrix: 18 passed across compact,
  standard and large viewports. Capture was OFF: no approved-pixel comparison
  or baseline update occurred. The October 3 broader visual result of
  211 passed / 124 failed remains unresolved, not replaced by this layout test.
- Final main iPhone PROFILE build succeeded in 52.3 seconds, 56.1 MB;
  app.zyraconnect.zyra, version 1.0.0 (5), Apple Development signed. Deep strict
  signature verification passed. Source/test/SQL/tool aggregate hashes were
  unchanged across the final build; protected onboarding hashes also match.
- At 14:00 BST the intended iPhone was unavailable; that earlier pending state
  remains in the immutable repair receipt. After the Founder returned home,
  fresh paired/unlocked and unchanged source/artifact checks passed. The same
  main PROFILE build was installed at 23:40 BST (installation sequence 6420)
  and natively launched. PID 73931 was independently observed running from
  new container DD9177B0-8DDD-4FAD-982D-53CFFBD7722D. Identity, signature and
  source/binary post-checks passed. No rebuild, app-data deletion, backend
  activation or Apple upload occurred. This proves local delivery and launch,
  not full-screen functional, release-artifact or physical Founder acceptance.

Earlier test failures, the narrowly corrected intentional preview fixture,
analyzer repairs and the cancelled superseded build are retained as evidence.
The final green run does not retrospectively certify those earlier snapshots.

## Production and release work still required

| Gate | Current evidence | Required next proof |
|---|---|---|
| Database deployment | Local candidates and fake-record tests | Exact final payload GO, fresh drift catalog, rights-preserving backup/restore and controlled live post-checks |
| Identity admission | Unavailable adapter; production fuse remains OFF | Approved provider configuration, trusted webhook/session authority and real positive/negative recovery tests |
| Photo moderation | Preview queue, not operational moderation | Trusted server review/decision authority, upload and retry tests, no client self-approval |
| Basic/One/Family commerce | Membership choice and introductory preview only | Store/provider products, verified receipts, first payment/renewal/cancel/refund/grace lifecycle and reconciliation |
| Apple/Google and email OTP | Not measured on intended release artifact | Ordinary non-Founder sign-in, cancellation, recovery, correct-account OTP and expiry/reuse denial |
| Accessibility and network | Unit regressions only | Native focus/text-scale/reduced-motion checks and interrupted radio/session/upload recovery |
| Physical restore | No database-plus-photo acceptance run | Isolated restore of schema/data/private blobs with ownership, counts, access and object retrieval checks |

The current unavailable verification adapter must not be replaced by a guessed
success or enabled admission fuse that locks existing users out. SDK completion
is not trusted verification. Membership intent, preview pricing and synthetic
receipts are not payment proof. No charges or provider agreements were accepted.
The approved verified-community introduction describes the intended launch
standard; it is not evidence that the current unavailable provider fulfils it.
Do not release that promise as an established fact before admission enforcement
and existing-account reconciliation are actually verified.
The local PROFILE build is not the submitted Apple release artifact merely
because its version/build number matches.

## Deployment conditions and next steps

Do not run blanket `db push`, a wholesale September 24 migration, or any live
candidate on this handover's authority. Before production GO, each exact
candidate needs current hashes and complete affected catalog/ACL/column grants,
relevant existing-row reconciliation, a verified backup and restore plan,
stated downtime/lock thresholds and positive as well as denial post-checks.
F04 additionally requires its complete coordinated client/saved-result/privacy
cutover; the current preparation artifact is not that payload.

Candidates use transactions and short lock/statement timeouts. Stop on hash or
catalog drift, unexpected privilege, timeout, lost legitimate access, ownership
violation, duplicate/negative credit result or unresolved restore prerequisite.
Pre-commit failure rolls back. Post-commit prefer reviewed forward repair;
restoring old oracle, cascade, ownership or Plus-spend behavior would reopen the
known defects and is not a safe routine rollback.

The checked local app has been delivered. Next order: prepare exact critical
deployment packets and their restore proof; obtain
separate Founder production GO; apply only those reviewed deltas and measure
live denial plus legitimate access; complete coordinated compatibility and real
provider/commerce integration; measure the intended release artifact; seek
Founder acceptance. OA305 and companion actions remain open until their own
actual acceptance conditions are met. No new product policy or duplicate OA
is created by this handover.

## October 7 — critical deployment prerequisite reconciliation

This dated addition supplements the October 5 facts above; it does not rewrite
historical receipts or imply production application. Main independently verified
the Founder’s direct local preparation/execution approval in ZYRA FINAL REALEASE.
No exact final production GO, accepted restore proof or Founder release acceptance
is established. Founder remains AWAY; no phone/native work was performed.

F01 now has an additional INSERT-only non-NULL-target predicate, preserving the
old submission requirement while retaining historical nullable SET NULL deletion.
The complete correction is comments plus one ALTER POLICY; no other authority,
SELECT, RPC, grant, lock or timeout changed. Current candidate: 9466B, SHA-256
`e770b758cdbe4d1b79a331540fcca8d28f736c9fa6d011b4580b05269a1ac9cb`.
The previous 9019B/1775aae... version and old assertions are true-PRE backups in
the dated packet. New regression reproduced the original NULL-target admission,
then passed three groups for populated-row preservation, valid/invalid new
submission and historical target detachment/surviving reporter access. Adjusted
retained F01 regression passed nine functional groups plus exact-repeat refusal.
This is 13 corrected-payload groups over two invocations, not 13 new app gates.
All exact-owned fake containers and the initially stopped VM were stopped again.
F02/F03 and their completed October 5 proof were reconciled, not rerun for activity.

Fresh authenticated read-only catalog/ACL/column/dependency and aggregate checks
on exact project `sxoaxonzjqkgajmlagyk` reconcile the captured candidate prestates.
They are static metadata checks, not live execution of the candidates’ DDL/temp
view preflights or real JWT/Storage API acceptance. Live column grants, private
ledgers, transitive Journey readers and Storage protect/delete/update triggers
are recorded. F02 has no observed metadata mismatch; Additional positive access
has no naturally assigned live scenario and remains unmeasured.

F03 MUST NOT be applied yet: 498 of 597 registered photo references fail binding,
affecting 124 profile owners, all with zero bound registered photo and invalid
primary references. All failures are noncanonical foreign-owner references; no
NULL-owner/missing-object metadata is counted. These aggregates neither identify
real members nor prove seed provenance. Do not infer or backfill ownership, add
exceptions, rewrite/re-upload data or apply a blanket migration. The current
DELETE-then-INSERT photo client remains F21/atomic-recovery work. Physical blob
presence, actual Storage API and signed-URL/cache withdrawal are not proven.

No accepted current database-plus-private-blob backup/restore evidence, exact
protected recovery target or measured RPO/RTO exists in this packet. Lawful
profile-report expiry/operational holds remain an acceptance dependency. Candidate
5s lock/30s statement timeouts are not whole-transaction bounds; the report names
a proposed envelope that must be frozen and tested before exact production GO.
Post-commit prefer reviewed forward repair retaining all three restrictions;
old cascade/ended-chat/foreign-photo behavior is not a safe rollback.

Full as-built/diff, authority, raw live receipts, count-only compatibility,
positive/denial matrix, recovery scope, stop rules and visual handoff:
`SYSTEM/RESOURCES/REVIEWS/OA305_CRITICAL_DEPLOYMENT_PREREQUISITES_2026_10_07_REPORT.md`.
The dated RESULT and SEAL own final pins. The supplemental wrong-name collision
scalar is qualified by the correct full-catalog constraint inventory, not silently
rewritten. Approved UI/design/scrolling and all other held provider/payment/release
work are unchanged by this stage. ADMIN alone files the shared OA record; no OA,
score, release acceptance or recurring-loop status is changed here.
