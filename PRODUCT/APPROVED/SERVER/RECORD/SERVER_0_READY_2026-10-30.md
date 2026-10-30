---
id: SERVER0-DISPOSITION-2026-10-30
type: REPORT
status: CURRENT
feature: SERVER
purpose: NOT READY disposition for SERVER 0 with exact unchanged source hashes, read-only findings, isolated failures, blocked test gates and future backup requirements
links: [DOC-ZYRA-0329, OA-ZYRA-317, OA-ZYRA-319, OA-ZYRA-324, OA-ZYRA-198]
owner: Codex
---

# SERVER 0 — NOT READY — 30 OCT 2026

**NOT READY. Queue row 28: FAILED in preflight. This filename is the brief's required record location; it is not permission
to apply anything. There is no production-ready ordered payload. Production remains unchanged.**

Built from `PRODUCT/APPROVED/SERVER/BRIEFS/SERVER_0_BRIEF_2026-10-30.md` and DOC-ZYRA-0329 §§3.2, 3.4, 3.6, 4 and 5 line 0.
Founder approval is recorded in DOC-ZYRA-0329: “Yes, Fable's plan” and “Yes, approved”. That approval permits isolated proof,
not a production apply. The original migrations, approved design and app were not changed.

## Written refusals and the changes needed in a future brief

| Refusal | Exact evidence | Required correction / owner |
|---|---|---|
| R1 — Full active-directory replay has a historical prerequisite outside its approved file set (OA-ZYRA-319; historical OA-ZYRA-198). | Both unchanged chronological runs, with and without the proposed Aug25 exclusion, completed 172 migrations then failed in `20260811153416_oa193c_onboarding_question_bank_and_completeness.sql:64–67`: missing `zyra_onboarding_questions`. The active directory has no creator. `SOURCE/supabase/migrations/README_20260811_OA193.md` records two quarantined reconstruction bridges and says a future repeat requires its own exact Founder one-replay GO. Neither bridge was copied, edited, promoted or executed. | Fable/ZYRA chat must name the historical bridge payload and exact replay authority in a corrected brief. The approved active files alone cannot produce a seedless full replay. This does not reopen or change the accepted historical OA. |
| R2 — Kept Main-Guardian hold depends on dropped shared-Pause schema (OA-ZYRA-317). | `20260918140508_oa294_main_guardian_optional_journey_hold.sql:309–336` references `new.pause_state` on both matches and attempts. Only dropped `20260825120000_shared_pause_decision_state_machine.sql:18,27` introduces those columns. Live has neither. Both exact kept CREATE TRIGGER statements failed locally with `column new.pause_state does not exist`. | A revised brief must explicitly reconcile the hold with retired Pause: a narrowly documented inert-column bridge or a hold rewrite. Codex did not silently edit a KEEP file or restore shared Pause. |
| R3 — Kept f04 cannot be a production-ready file (OA-ZYRA-317 / OA-ZYRA-319). | `20261005120711_oa305_f04_private_legacy_score_and_browse_ids.sql:67–70` refuses every database without its synthetic name/GUC. Unchanged candidate on an isolated non-matching database raised `F04 preparation only: coordinated client/saved-result/privacy cutover not authorised`. Its comments require a separate coordinated cutover, client wiring, saved-result/privacy work and exact production GO. | The design/brief must separate local preparation from a future reviewed production cutover, or approve a specific replacement. Codex did not remove the guard, disguise production with a GUC, change app callers or certify this file for live. |
| R4 — “All suites pass” conflicts with an approved removal, and the suite inventory needs explicit schedules (OA-ZYRA-317 / OA-ZYRA-319). | There are 49 top-level SQL files plus three fixtures. `zyra_pause_decision_state_machine_suite.sql:3–5,40–41` demands the very migration the brief drops; the unchanged suite locally raised its exact shared-Pause-not-applied precondition. Historical Journey D/J/L/M sections explicitly archive older Pause behavior. Other files are fixtures, independent minimal-schema harnesses and two-worker race assertions, not interchangeable suites. | The corrected brief must specify retirement/replacement of obsolete Pause assertions and fixture/concurrency schedules. Existing guards remain intact; blocked suites are not counted as passed. |

The approved Sep24 rewrite also needs to preserve f02's captured prestate. The original changes the six-column participant
view to seven columns at `20260924100231…sql:1513`, and changes the three-argument Guardian RPC's six-column return shape at
`:1485`. Kept f02 pins the old view at `20261005114141…sql:105–110` and helper source at `:204–220`. The existing F02 view-drift
fixture reproduced the expected `F02 preflight: canonical/caller view drift` refusal. A DROP/CREATE view repair alone is not
sufficient; a compatible rewritten message helper must preserve f02's intended boundary. This is an implementation requirement
for the authorised rewrite, not permission to weaken the preflight.

## Exact original identities — audit list only

This is the brief's intended dependency order, with the dropped input shown separately. It is **not** an apply manifest.
The two rewrite slots have no final artifact and therefore no final production SHA. The f01→f07 order differs from timestamp
order (f03 sorts first, f04 last); a future explicit execution manifest must resolve this rather than claim chronological
order implies the approved order. All original files below are still at their existing paths and hashes.

| Audit order | Original file in SOURCE/supabase/migrations | Brief disposition | SHA-256 of unchanged original |
|---|---|---|---|
| excluded | `20260825120000_shared_pause_decision_state_machine.sql` | DROP (not performed; preflight held) | `8b25b2ba20e42f6d1236c009e47b391ebd3fd67e565f028944707b8a765ac89e` |
| 1 | `20260918140508_oa294_main_guardian_optional_journey_hold.sql` | KEEP (not apply-ready) | `67683db6045e42e2ae691321b8a35676913c69433392276a07551138dbc8004b` |
| 2 | `20260918145126_oa295_known_person_code_matching.sql` | KEEP (not apply-ready) | `30c12a15b83b9e07e4183140162e09086322d623a40960758a83bea712e80c5b` |
| 3 | `20260918171910_oa256_product_telemetry_foundation.sql` | KEEP (not apply-ready) | `dd20f85ed308c85efca18b9e33564405fce760fc1238190dc50a6ed673614dca` |
| 4 | `20260919185927_oa298_family_messaging_foundation.sql` | KEEP (not apply-ready) | `27bda6deefd981ad84c900c1db52d578e7a1383656f871f85284214ad1c7c986` |
| 5 | `20260919191016_oa299_journey_return_initiation_gate.sql` | REWRITE (not performed) | `0ff28ae7c6d98da43b1b6d608c93c9dfb2039b4bde0c28ad5a78e63d58111460` |
| 6 | `20260923225150_retire_unused_legacy_purchase_mutators.sql` | KEEP (not apply-ready) | `f3521467d45c10aeea0cf346e08c50309d112499fa6f8e4251e7e58d2010f7c6` |
| 7 | `20260924100231_founder_paid_only_returns_guardian_circle_contract.sql` | REWRITE (not performed) | `f6af8a28e1b0ce319a8daaa39ff22fc30574bd6c9d47f70a5de8cfec49374006` |
| 8 | `20260925215350_family_circle_participant_list.sql` | KEEP (not apply-ready) | `46ede6b9416f17b8435c1e3360610321cebd0fb501fab10d1521e8e44b3b350e` |
| 9 | `20260926144532_family_message_sender_identity.sql` | KEEP (not apply-ready) | `97828cad31855b174be0dd6f7831d49729e48d20860f47449c47e33f018025d2` |
| 10 | `20260926233533_message_read_receipts.sql` | KEEP (not apply-ready) | `deb1fae89d547bd10d98cac016116f96013f163d549e01e103af8eaa0b0d9a15` |
| 11 | `20261005113808_oa305_f01_safety_report_retention.sql` | KEEP (not apply-ready) | `e770b758cdbe4d1b79a331540fcca8d28f736c9fa6d011b4580b05269a1ac9cb` |
| 12 | `20261005114141_f02_guardian_current_attempt_read_boundary.sql` | KEEP (not apply-ready) | `79f13c3e92df71b2e16f1169cff1f2b393a7682e800039b8823fc992e4c1668e` |
| 13 | `20261005113453_f03_photo_row_object_owner_binding.sql` | KEEP (not apply-ready) | `dcc99410572915a3aaa8104904d86ab545ea7c332e90e417b1c112d1a8b99b9e` |
| 14 | `20261005120711_oa305_f04_private_legacy_score_and_browse_ids.sql` | KEEP (not apply-ready) | `b82ecb384b50a26b87fd289938ca971b22c25544267c5cae9a159eccf872fe12` |
| 15 | `20261005120004_oa305_f05_private_progress_helpers.sql` | KEEP (not apply-ready) | `4d624cb2ba19cd008845494a3c98809ffe4d0919d08fecc05f99760f746b69f7` |
| 16 | `20261005120420_f06_f07_unlock_hold_serialization_receipts.sql` | KEEP (not apply-ready) | `3901e36eb14f2ecce4a9b8fdc5f6632c5ed67cb45cb7a979d20f4764049d564e` |

## What actually ran

| Check | Result and limit |
|---|---|
| Live read-only pass | PASS as a read-only check: 211 opening and closing migration rows are byte-equivalent after canonical JSON serialization; metadata/hash/count queries only. Basic 1 / One 3 and every design “not verified” item answered in the new live report. |
| Unchanged active-directory replay from empty | FAILED: 172 of 228 completed before the missing question-bank creator. No successor claimed applied. |
| Proposed no-Aug25 replay from empty | FAILED: 172 of 227 completed at the same historical prerequisite; it did not reach the Main-Guardian hold. |
| Kept hold dependency proof | PASS as an expected-refusal proof: exact matches and attempts CREATE TRIGGER fragments both reject missing pause_state. Minimal isolated tables/stub trigger function only; not a full migration replay. |
| Unchanged f04 non-synthetic guard | PASS as an expected-refusal proof. No production was contacted. |
| Unchanged f04 synthetic fixture/regression | PASS, exit 0: pre-fix numeric/probe baseline reproduced; eight F04PASS groups cover permissions, rank IDs, canonical arithmetic, unknown-field denials, existing Journey mutual/Plus gates and trusted adapter. Minimal guarded database; not app/gateway/retention or combined catch-up certification. |
| Unchanged f02 clean synthetic bootstrap → candidate → impersonation suite | PASS, all exit 0: actual authenticated/anon roles, Main/Additional/outsider, link epochs, assignment revocation, ended/new attempts, Seeker archive and denied Guardian sends. Final matrix PASS. Minimal guarded database; not live/PostgREST proof. |
| F02 view drift → unchanged candidate | PASS as an expected-refusal proof at the exact canonical/caller-view preflight. Other drift cases were not rerun. |
| Shared-Pause suite on the no-Pause prestate | EXPECTED REFUSAL; the product suite did not pass. |
| Combined before/after suites, all kept/rewrite impersonation cases, two-worker races | BLOCKED / NOT RUN. There is no valid combined before/after schema or final rewritten candidate. JSON inventory classifies every test file and names precisely what ran. No blanket test pass. |
| Final migration integrity | All 228 source hashes unchanged. No rewrite/drop move, dependency, app code change, production write or blueprint edit. |

The local runtime used the already installed `public.ecr.aws/supabase/postgres:17.6.1.147` image in one uniquely named container,
with `--network none`, no port mappings and empty new databases. Auth/extension schema came from that stock image; minimal
synthetic Storage tables and a Realtime publication were supplied only to the replay databases. Initial setup attempts
revealed template-owner, publication and extension prerequisites and were separated from the final 172-file results.
No existing database was reset, overwritten or dropped. The older OA-ZYRA-198 bridges were never used to bypass the failure.

## Backup and production plan — future gate only

1. A corrected brief and new queue line must first resolve R1–R4 and all rewrite dependencies, finish full replay, all applicable
   before/after suites and impersonation/concurrency checks, and pin the exact final ordered SQL SHA-256 values.
2. Before any production apply, confirm the actual point-in-time backup capability, latest successful backup, recoverable
   timestamp/window and a tested restore path. These are **not confirmed** by this task; no backup, restore or paid branch was created.
3. Re-run the live read-only comparison against the exact approved manifest. Stop for any catalog/history drift, missing
   prerequisite, unverified backup, unexpected row-count change, lock/timeout or failed acceptance assertion.
4. Only Shakeel's exact “apply SERVER 0 to live”, tied to that final payload and confirmed backup, can authorise a separate
   production task. Show the target, expected consequence, rollback/restore plan and post-apply acceptance checks first.
5. Stop-writes and physical drops remain separate stages. No production drop belongs in the change that first stops writes.
   Destructive removal needs its own staged verification and authority. A failed transaction rolls back; recovery beyond that
   uses the confirmed backup plan rather than ad-hoc data rewrites.

Evidence: `REPORTS/EVIDENCE/SERVER0_2026-10-30/` JSON only. Runtime cleanup and commit identities are recorded in the daily task
note. No migration is ready for live, no feature has been activated, and no production apply is claimed.
