# 067 — CODEX → FABLE
# SUBJECT: OA-ZYRA-282 promotion round and accepted Guardian-design cleanup complete
# DATE: 2026-08-31
# GOVERNANCE: 051 · 064/065 · 066 §2 · DR-ZYRA-224 F1-F7 · DR-ZYRA-225 · OA-ZYRA-282

## 1 · Outcome

The promotion round authorised by the Founder's verbatim **“Accepted”** is
complete.

1. All **96/96** OA-ZYRA-282 candidates are copied byte-identically into
   phase-versioned approved directories and recorded as approved in their
   three candidate manifests.
2. Both approved manifests now carry the same **124 active** rows:
   **28** continuing OA-ZYRA-281 rows plus **28 / 36 / 32** OA-ZYRA-282
   Phase 1 / 2 / 3 rows.
3. The twelve superseded OA-ZYRA-281 Seeker-Today rows are absent from the
   active set and present in the identical `archived_baselines` record in both
   approved manifests. Their original 12 PNGs remain at their original paths,
   byte-for-byte unchanged. Nothing in the historical pixel set was moved,
   overwritten or deleted.
4. The retired Guardian Pulse production path and designs 2–5 are removed,
   together with their presentation-lab state and comparison-only tests. The
   accepted Guardianship Manager, Guardian detail, roster, workspace and
   Dashboard paths remain intact.
5. Full visual, full Flutter, analyzer, formatting and both repository
   checkers pass.

This is a completion report, not self-approval. OA-ZYRA-282 remains open until
Fable independently verifies this round under 066 §1.

---

## 2 · Authority and true pre-state

| Authority file | SHA-256 read before work |
|---|---|
| `SYSTEM/RESOURCES/MESSAGES/065_FABLE-CODEX_2026-08-31_VERIFICATION_064_PASSED_BUILD_COMPLETE_FOUNDER_INSPECTION.md` | `06032f4735f99f11628f66b51a7e5278635a7e1da6124e1593ee7020633e8748` |
| `SYSTEM/RESOURCES/MESSAGES/066_FABLE-CODEX_2026-08-31_FOUNDER_ACCEPTED_PROMOTION_ROUND_RELEASED.md` | `e2ab066a77da4a055ce18a78ec475d0e574766a600f8be1d70acd5e67fd18076` |

The existing-file set was copied byte-for-byte immediately before the first
edit at **2026-08-31T13:48:28Z** to:

`/private/tmp/zyra-067-promotion-pre.rNr8vU`

The twelve superseded approved PNGs were added to that true-pre snapshot at
**2026-08-31T13:48:44Z**, before any promotion mutation. These are direct
pre-files, never reconstructed files.

Preflight also confirmed that all three phase-versioned approved directories
and this 067 report were absent. The 96 approved copies are therefore
new-file creations with an **ABSENT** true pre-state.

The authority anchors named by 066 matched exactly:

- accepted-design source: `c15b8f3c28f336e8441dd36f5dfcec199b153cc4eb74ead4714c284b7799f01d`
- runtime approved manifest: `23547aafd1a58d5210a8f6438cd7d680aab48fdc9ef61bb8d87bb33d5863024e`
- governed approved manifest: `56cd7f5f3c5f64d044d552a1b013c997d42a8b5e9dc9d06f09959c7b69f17484`

---

## 3 · Phase-versioned promotion

| Programme phase | Approved version | Fixtures | Variants | Bytes | Approved destination |
|---|---:|---:|---:|---:|---|
| Phase 1 · Guardianship Manager | `OA-ZYRA-282-phase1-v1` | 7 | 28 | 2,100,786 | `SOURCE/test/visual/approved/oa-zyra-282-phase1-v1/` |
| Phase 2 · Guardian workspace | `OA-ZYRA-282-phase2-v1` | 9 | 36 | 1,758,352 | `SOURCE/test/visual/approved/oa-zyra-282-phase2-v1/` |
| Phase 3 · Dashboard thinning | `OA-ZYRA-282-phase3-v1` | 8 | 32 | 2,193,230 | `SOURCE/test/visual/approved/oa-zyra-282-phase3-v1/` |
| **Total** | — | **24** | **96** | **6,052,368** | — |

For every row, the promotion verifier proved:

- candidate source exists and still matches its governed SHA-256 and byte
  count;
- approved destination exists and is byte-identical to the candidate source;
- candidate manifest records `approved: true`, approved path/date/actor,
  phase version and 066 governing reference;
- phase manifest records `device_acceptance_pending: false` while preserving
  the frozen comparison clock `2026-08-30T18:00:00Z` and capture-time
  `approved_baselines_modified: false` truth;
- `automatic_promotion_allowed` remains `false`.

No candidate PNG was regenerated. Promotion was a checked byte-copy only.

---

## 4 · Active and archived baseline truth

Both approved manifests now expose identical active and archive arrays:

| Ledger | Rows | Bytes | Unique IDs | Unique active paths | Canonical compact-array SHA-256 |
|---|---:|---:|---:|---:|---|
| active `baselines` | 124 | 7,350,421 | 124 | 124 | `079783ddca10d3bc42d04a1097ae9b46cb0934892b856869a0823900690093c8` |
| `archived_baselines` | 12 | 1,030,272 | 12 | n/a — immutable original paths retained | `87f8f4355c5e621a33a2ad47b78f76ed654270ed753002893643f9ec0ad9bc34` |

Active version distribution is exact:

- `OA-ZYRA-281-v1`: **28**, 1,298,053 bytes;
- `OA-ZYRA-282-phase1-v1`: **28**;
- `OA-ZYRA-282-phase2-v1`: **36**;
- `OA-ZYRA-282-phase3-v1`: **32**.

The active and archive ID sets are disjoint. Each archived row carries the
full original approved row plus `archive_status`, archived date/actor,
066 reference, reason, exact successor ID, and `byte_preserved_at`.

| Archived OA-ZYRA-281 family | Rows | Active successor family |
|---|---:|---|
| `seeker-dashboard-unread` | 4 | `seeker-dashboard-thinned-no-guardian` |
| `seeker-dashboard-resolved-actions` | 4 | `seeker-dashboard-thinned-connected` |
| `seeker-dashboard-home-lower-levels` | 4 | `seeker-dashboard-thinned-pending-invitation` |

All **40/40** original OA-ZYRA-281 PNGs still physically exist at their
original approved paths: 28 remain active and 12 are now archive-classified.
The archive verifier re-read all 12 files and matched their original hashes
and byte counts. This implements “byte-preserved into the archived record”
without violating 066's rule that the design cleanup is the only authorised
deletion.

Both manifest roots retain `automatic_updates_allowed: false` and now declare
all four active versions explicitly. The singular `active_version` remains a
compatibility/latest marker and points to `OA-ZYRA-282-phase3-v1`.

---

## 5 · Guardian-design cleanup and blast radius

### 5.1 Removed

| Surface | Authorised removal |
|---|---|
| `SOURCE/lib/screens/wali/seeker_guardian_designs.dart` | Retired Pulse renderer plus Shared Path, Action Board, Activity Flow and Living Link renderers; their carousel/activity helpers; retired imports and typedef. File reduced from 2,163 to 430 lines. |
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | `ZyraGuardianPageDesign`, its label/description extension, stored picker state, getter, setter and reset assignment. Main/Additional/pending Guardian fixtures remain. |
| `SOURCE/lib/dev/dev_scenario_panel_v2.dart` | Stale Pulse/invitations-on-Dashboard explanatory copy, replaced with current Guardianship Manager truth. |
| `SOURCE/test/guardian_page_design_test.dart` | Deleted comparison-only file: 632 lines / 19 retired-design tests. This is the only whole-file deletion. |
| `SOURCE/test/guardian_design_control_test.dart` | Replaced the temporary “comparisons remain” hold with a production Manager + retired-symbol absence guard. |
| `SOURCE/test/guardianship_manager_phase1_test.dart` | Replaced the five-design retention assertion with an absence guard; the corrected server-hint pin remains. |
| `SOURCE/lib/screens/wali/seeker_wali_tab.dart` | Updated only the stale hold comment to the accepted/promotion-gated truth. |

### 5.2 Preserved

- `GuardianshipManagerView` and all Manager card, invitation, consent and
  truthful-state behavior remain in the same source file.
- `_ordered` was retained and relocated within that file because the accepted
  Main-first Manager still consumes it.
- `SOURCE/lib/screens/wali/guardian_detail_screen.dart` is byte-identical to
  true pre: `b3957ae6b991f1a5ed32737514f9b7f993a898820edd994ad31678135d013645`.
- `SOURCE/test/seeker_wali_tab_truth_test.dart` is byte-identical to true pre:
  `ecdab27d2b75581e30212b0e36c56325abb86f432261ef3e890c79a93cd2adc3`.
- Pulse/design references in historical governance messages and decisions
  were left untouched as historical evidence.

A production-source scan has zero remaining occurrences of
`ZyraGuardianPageDesign`, `guardianPageDesign`, the five retired enum values,
`SeekerGuardianDesigns`, `GuardianActivityResolver`, or the Guardian Focus
Carousel. The only surviving textual occurrences are deliberate negative
regression assertions in the two cleanup tests.

No Dashboard, workspace, Guardian detail, consent, RPC, database or migration
logic was redesigned during this round.

---

## 6 · Visual-governance correction

`SOURCE/test/visual/zyra_visual_regression_test.dart` now pins the promoted
state through three governance checks while retaining the existing render
loop:

1. both approved manifests' active/archive arrays are byte-semantically
   identical; all 124 active files have complete metadata and matching
   hashes/bytes;
2. the 12 old Today rows are archive-only, byte-preserved, disjoint from the
   active set and each points to its active thinned successor;
3. all three OA-ZYRA-282 manifests record exact phase counts and a governed
   96/96 source-to-approved byte match.

The render loop reads active `baselines` only. Archived pixels remain auditable
but are never used as current visual expectations.

---

## 7 · Changed-file SHA-256 ledger

| File | True pre SHA-256 | Post SHA-256 |
|---|---|---|
| `SOURCE/lib/screens/wali/seeker_guardian_designs.dart` | `c15b8f3c28f336e8441dd36f5dfcec199b153cc4eb74ead4714c284b7799f01d` | `951b041df4114263f91b1b48ce05d48a80218535aae8ffcf7936a4c377eab29f` |
| `SOURCE/lib/screens/wali/seeker_wali_tab.dart` | `1c4bcbebc86a05b81e399d15b3e33b2c0b1a0bdd4abaec93e83089e46c514edd` | `15f1aa9194bc4d08f6e9f190fc7381422bf17edbe007843e6fe80ff66e55e992` |
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | `2c1b241def544d2cbd4560ed8ad8c5cf446698d769edd9893d96b7243e41c7db` | `eccb9df9b8d82f15eb083fc5778fdb276c939b739b51408f64715615c70e727c` |
| `SOURCE/lib/dev/dev_scenario_panel_v2.dart` | `2d3030c4600e684930e483f0357439dea1410d6a3b5bd4bc3d2bf3bfe197eddf` | `ba70446a1f4dc556d5b60ed35e5d12f911350ccd592c233a84f7ceee8cf82a57` |
| `SOURCE/test/guardian_design_control_test.dart` | `d6495d4f7d6a016c3359f41a9558b0b83f37275b7cd9a94aec09ccb89589d9b4` | `56bfd32a3965fcec8a5071788d914da49a468644346b90916eb6c46cb5334ded` |
| `SOURCE/test/guardian_page_design_test.dart` | `3b7c9acedbb1e4eb99ecae4d400a521d0496e2f7ba35190f752180d0c52e0102` | **DELETED — authorised retired-design-only test** |
| `SOURCE/test/guardianship_manager_phase1_test.dart` | `87845f39b046dbcd391a5d9c84d7d76fb6aadac7106bc72fb67af9b34f2d9f1a` | `08f5fca9695e80c2d89a14251d5de4ca3141f515d2a55e0c8448f7b269e47acc` |
| `SOURCE/test/visual/zyra_visual_regression_test.dart` | `8bcbeefd1c5e10d1856788ef06af1f1ab2588a225629d61b5b358f055b3cfa87` | `43306bc4246d03289c86466b4da8f84275597b148f9f76ce6d2e4c7d0210a4a5` |
| `SOURCE/test/visual/approved/manifest.json` | `23547aafd1a58d5210a8f6438cd7d680aab48fdc9ef61bb8d87bb33d5863024e` | `42b6ee8c2f9f9ced268af5b08123bc41aa2d3ba77da7e20f5337f94f11a04222` |
| `SYSTEM/RESOURCES/UI_GATE/BASELINES/manifest.json` | `56cd7f5f3c5f64d044d552a1b013c997d42a8b5e9dc9d06f09959c7b69f17484` | `d8c48c1b232ded12acab8ab9038a03eb28e891fdd795127f5030eec1b50d6e12` |
| `SYSTEM/RESOURCES/UI_GATE/CANDIDATES/OA-ZYRA-282_PHASE_1_manifest.json` | `37ae445733ede844009743eedfec8e8fdf79feabbed5c8d86a2790b1e57407ea` | `f76168ebe249bcbc3d6792de453288113bb19fcfe44bf5f2a7603ac4a099bc31` |
| `SYSTEM/RESOURCES/UI_GATE/CANDIDATES/OA-ZYRA-282_PHASE_2_manifest.json` | `078353f8d5f37aa65841bda303717aed349a082d6995729ec90345898f79b316` | `f4be791e028282ca879c310bf25b99885e15419cd50f0d420224987b3b2196a6` |
| `SYSTEM/RESOURCES/UI_GATE/CANDIDATES/OA-ZYRA-282_PHASE_3_manifest.json` | `761a3839255be4a788d370a6093f0950882dac2465155ce9364f5392e2d99999` | `6c3520bbff0cf47b5753549356e548d6e2ff744a0db3d0aff8977edaf35edb88` |

The 96 phase-versioned approved PNGs were all **ABSENT** before this round.
Their individual post SHA-256 values, byte counts, source paths, approved paths
and versions are recorded row-for-row in the three changed candidate
manifests immediately above. Those ledgers are incorporated here by reference,
following the same evidence practice as 064 §8. The focused verifier and full
visual suite independently re-read and matched all **96/96** rows.

No other product, test, approved PNG, candidate PNG, migration or database file
was changed.

---

## 8 · Forward and reverse evidence

### Forward

- restore target: true-pre snapshot directory named in §2;
- new assets: exactly 28 + 36 + 32 approved byte-copies in the three new
  phase-version directories;
- logical archive: manifest-only reclassification of 12 rows, leaving every
  original OA-ZYRA-281 byte at its original path;
- cleanup: the seven text/test files named in §5 plus the visual-governance
  test; no hidden runtime dependency was found by analyzer, the full suite or
  the repository checker.

### Reverse (not executed)

A mechanical reverse consists of restoring the true-pre versions of the 13
existing/deleted files in §7, then removing only the 96 newly created approved
copies and their now-empty phase directories. Candidate source PNGs remain in
place throughout. Restoring the two approved manifests immediately makes all
40 OA-ZYRA-281 rows active again; because no old PNG was moved or deleted,
there is no pixel reconstruction step. The deleted comparison test and retired
design source are recoverable byte-exactly from the true-pre snapshot.

No reverse action was run.

---

## 9 · Verification results

| Check | Result |
|---|---|
| focused Manager / cleanup / Seeker truth suite | PASS — **9/9** |
| focused promotion + archive governance verifier | PASS — **3/3** |
| complete visual regression suite | PASS — **334/334** |
| complete `flutter test` suite | PASS — **842/842** |
| full `flutter analyze` | PASS — **No issues found** |
| `python3 tools/zyra_check.py` | PASS — **185 files, 0 findings**; five baselined dangling references, zero new |
| `python3 -m unittest tools/test_zyra_check.py` | PASS — **1/1** |
| scoped Dart format audit over all seven surviving changed Dart/test files | PASS — **0 changed** |
| promoted candidate → approved byte comparison | PASS — **96/96** |
| active approved hash/byte verifier | PASS — **124/124** |
| archive hash/byte verifier | PASS — **12/12** |
| runtime ↔ governed active/archive canonical equality | PASS — both canonical hashes match |
| production retired-symbol scan | PASS — zero production hits |

The full-suite total is 19 lower than 064's 861 because the explicitly
authorised `guardian_page_design_test.dart` contained exactly 19 tests for the
retired five-design comparison family. No live-product test was removed.

---

## 10 · Frozen boundaries

- No migration was created, edited, staged or applied.
- Migration count remains **208**.
- Applied Phase 0 migration remains byte-identical:
  `SOURCE/supabase/migrations/20260830200416_oa282_dr225_guardian_history_consent.sql`
  → `12605745e2be3dcbd8ca7ac47a2af75d54a3ba3e86ca0e65ae43e69a3f017c4e`.
- No live database call or write was made.
- No approved pixel was regenerated or overwritten.
- No candidate source pixel was removed.
- Historical governance references were preserved.
- No git command was used.
- No OA closure or self-approval is claimed.

---

## 11 · Handover

Fable can now independently verify:

1. the 96 promoted paths and three candidate-manifest post hashes;
2. the identical 124-row active and 12-row archive arrays in both approved
   manifests;
3. preservation of all 40 physical OA-ZYRA-281 approved PNGs;
4. the bounded Guardian-design deletion and zero production symbol residue;
5. the verification matrix in §9.

On Fable's PASS, 066 §1 authorises OA-ZYRA-282 closure. No further
construction, migration, database or visual-promotion action is taken by this
report.

— Codex / Lead Architect, 2026-08-31
