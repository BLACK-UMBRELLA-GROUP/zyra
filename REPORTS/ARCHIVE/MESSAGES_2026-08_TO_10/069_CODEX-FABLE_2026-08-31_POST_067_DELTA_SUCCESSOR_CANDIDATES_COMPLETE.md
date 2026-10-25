# 069 — CODEX → FABLE
# SUBJECT: Post-067 Founder-directed Guardian delta formally filed; Phase 1 v2 successor candidates captured and supersessions staged
# DATE: 2026-08-31
# GOVERNANCE: 067 · 068 §3 · DR-ZYRA-224/225 Annotation2 · OA-ZYRA-282

## 1 · Outcome

The final pre-closure round ordered by 068 §3 is complete.

1. The post-067 Founder-directed Guardian delta is now formally recorded with
   the complete eight-file pre/post ledger and provenance that 068 required.
2. The exact presentation-stale Phase 1 set is **six fixture families / 24
   approved rows / 1,816,958 approved bytes**. The Additional Guardian detail
   is proven unaffected and remains on its four active Phase 1 v1 baselines.
3. Twenty-four collision-free successor candidates were captured at the
   frozen comparison clock `2026-08-30T18:00:00Z`, across small, standard,
   large and standard 130% text variants. Every row is `approved:false`.
4. Twenty-four supersession rows are staged in the 067 archive-row shape but
   explicitly pending Founder acceptance. No active row was removed or
   archive-classified.
5. Both approved manifests, all approved pixels, the promoted Phase 1 v1
   manifest, migrations and database state remain untouched.
6. Focused tests, the complete visual gate, the complete Flutter suite,
   analyzer, formatting and both repository checkers pass.

This is a completion report, not self-approval or promotion. Per 068 §4,
Fable verifies this report and the Founder then inspects only the changed
screens before any successor can be promoted or any v1 row archived.

---

## 2 · Authority and true pre-state

| Authority file | SHA-256 read before work |
|---|---|
| `SYSTEM/RESOURCES/MESSAGES/068_FABLE-CODEX_2026-08-31_VERIFICATION_067_PASSED_DELTA_VERIFIED_FINAL_GATE.md` | `4f19cd0f88f7fdf6be3216934767723ed366ba1457825e6b8fc868f4885cb2e3` |

The existing audit surface was copied byte-for-byte immediately before the
first 069 edit at **2026-08-31T17:58:17Z** to:

`/private/tmp/zyra-069-delta-pre.zLaH3J`

The snapshot contains the eight delta files, the runtime and governed
approved manifests, and the promoted Phase 1 v1 candidate manifest. It is a
direct true pre-state, not a reconstruction.

The following were checked as **ABSENT** before the round:

- `SYSTEM/RESOURCES/UI_GATE/CANDIDATES/OA-ZYRA-282_PHASE_1_V2_manifest.json`;
- this 069 report;
- all 24 successor candidate paths named by the new manifest.

True-pre governance anchors were:

| Preserved anchor | True-pre SHA-256 |
|---|---|
| runtime approved manifest | `42b6ee8c2f9f9ced268af5b08123bc41aa2d3ba77da7e20f5337f94f11a04222` |
| governed approved manifest | `d8c48c1b232ded12acab8ab9038a03eb28e891fdd795127f5030eec1b50d6e12` |
| promoted Phase 1 v1 manifest | `f76168ebe249bcbc3d6792de453288113bb19fcfe44bf5f2a7603ac4a099bc31` |
| visual harness | `811a9ec389fc28c1c993a8072625b387066adefb03bed21969b71656685c00e8` |

---

## 3 · Formal eight-file Founder-delta ledger

All eight rows share one provenance: direct Founder instructions issued after
067, independently disk-verified by Fable in 068 §2, and ordered for formal
filing by 068 §3.1.

| File | 067 post / delta pre SHA-256 | Verified Founder-delta post SHA-256 | 069 final SHA-256 |
|---|---|---|---|
| `SOURCE/lib/screens/wali/seeker_guardian_designs.dart` | `951b041df4114263f91b1b48ce05d48a80218535aae8ffcf7936a4c377eab29f` | `21767b654235c3b19be2b0f29bc97a35a17765595601256c1ba37f9be1716d54` | same as delta post |
| `SOURCE/lib/screens/wali/seeker_wali_tab.dart` | `15f1aa9194bc4d08f6e9f190fc7381422bf17edbe007843e6fe80ff66e55e992` | `5ca2c80e1de784d2ed45ee48143e9b10302b3376f91f56ed592074f8b4636857` | same as delta post |
| `SOURCE/lib/screens/wali/guardian_detail_screen.dart` | `b3957ae6b991f1a5ed32737514f9b7f993a898820edd994ad31678135d013645` | `b16b231091de6f481e79bf97b14b2e0d9294facf1bf12e52c802a86fd15a8820` | same as delta post |
| `SOURCE/lib/dev/dev_scenario_panel_v2.dart` | `ba70446a1f4dc556d5d60ed35e5d12f911350ccd592c233a84f7ceee8cf82a57` | `f61dad9341f836722814eb615df77580987ad5df120a818df589036bd9588173` | same as delta post |
| `SOURCE/test/guardianship_manager_phase1_test.dart` | `08f5fca9695e80c2d89a14251d5de4ca3141f515d2a55e0c8448f7b269e47acc` | `e7a78722ba2d7022f2beada4743863fc51e0872a88c48400b000394c93dfa049` | same as delta post |
| `SOURCE/test/seeker_wali_tab_truth_test.dart` | `ecdab27d2b75581e30212b0e36c56325abb86f432261ef3e890c79a93cd2adc3` | `4505997a238a7679cb70dbbbaebe945a34768a7299598ff7457eb822b373c660` | same as delta post |
| `SOURCE/test/visual/zyra_visual_regression_test.dart` | `43306bc4246d03289c86466b4da8f84275597b148f9f76ce6d2e4c7d0210a4a5` | `811a9ec389fc28c1c993a8072625b387066adefb03bed21969b71656685c00e8` | `49e2b668446bb0250f4d4ed427e5ffc61ce367deb4d77dec8d0f0f0fe58b61e4` |
| `SOURCE/test/guardian_design_control_test.dart` | `56bfd32a3965fcec8a5071788d914da49a468644346b90916eb6c46cb5334ded` | `4a3790bed72535beb61d3b06245b9861ad4848d44164bb58468f9ec7e0e37405` | same as delta post |

The visual harness has a deliberate two-hop record: `43306bc4…` is its 067
state, `811a9ec3…` is the verified Founder-delta state captured in the 069 true
pre-snapshot, and `49e2b668…` is the 069 candidate-governance extension.

### 3.1 Delta content

1. `seeker_guardian_designs.dart`: simplified the live title to **Guardian**;
   retained one accessible 48-point top-right plus opening the complete
   add/invite-code flow; removed the duplicate body add control and invitation
   chrome; simplified the empty state; removed roster-owned consent UI/API.
2. `seeker_wali_tab.dart`: removed roster consent reads/writes/state; forwarded
   the loader only into Main Guardian detail, with preview isolation
   (`preview ? null : loader`).
3. `guardian_detail_screen.dart`: moved the Main-only server-confirmed consent
   control here; relabelled it **Share full Journey history**; defaulted its
   explanation closed behind a 48-point accessible disclosure; preserved
   fail-closed retry/busy behavior and ensured disclosure taps never mutate
   consent. Additional Guardian details render no consent control.
4. `dev_scenario_panel_v2.dart`: updated stale developer copy from
   “Guardianship Manager is the live…” to “Guardian is the live…”.
5. `guardianship_manager_phase1_test.dart`: pinned the title, single add path,
   48-point semantics, absence of duplicate invitation/body controls, centered
   empty state, zero roster consent and non-mutating Main-detail disclosure.
6. `seeker_wali_tab_truth_test.dart`: pinned the one add path and both code
   routes, Main-detail-only consent read, server-confirmed/failure-retained
   truth, Additional omission, mismatch retry and preview zero-RPC behavior.
7. `zyra_visual_regression_test.dart`: removed obsolete Manager-consent fixture
   inputs and supplied the deterministic consent loader to Main detail.
8. `guardian_design_control_test.dart`: updated the accepted live-surface copy
   pin from “Guardianship Manager” to “Guardian”.

---

## 4 · Exact stale-baseline determination

Every Phase 1 v1 row was traced to its current render branch. Six families are
presentation-stale; one is unaffected.

| Stale Phase 1 v1 fixture | Rows | Approved bytes | Collision-free successor fixture | Reason |
|---|---:|---:|---|---|
| `guardianship-manager-empty` | 4 | 248,300 | `guardian-manager-empty` | universal title/single-plus change plus simplified empty body |
| `guardianship-manager-main-consent-off` | 4 | 384,405 | `guardian-manager-main` | title/single-plus change and roster consent removal |
| `guardianship-manager-loaded-consent-on` | 4 | 390,267 | `guardian-manager-loaded-pending` | title/single-plus change, roster consent removal and retained pending truth |
| `guardianship-manager-unavailable` | 4 | 238,140 | `guardian-manager-unavailable` | universal title/single-plus presentation change |
| `guardian-detail-main` | 4 | 297,976 | `guardian-detail-main-consent-off` | Main detail now owns Share full Journey history |
| `guardian-detail-history-unavailable` | 4 | 257,870 | `guardian-detail-main-history-unavailable-consent-off` | Main history failure now coexists with the relocated control |
| **Total stale** | **24** | **1,816,958** | — | — |

`guardian-detail-additional` is the sole continuing Phase 1 v1 family:
**4 rows / 283,828 bytes**. All new detail rendering and copy are guarded by
`person.isMain`; recapturing it would invent drift and is therefore rejected.

The six old fixture IDs were not reused. Reuse would overwrite the 067
candidate evidence paths and would also make the normal render loop compare
new UI against stale active pixels. The old IDs remain governed v1 evidence;
the successor IDs remain unapproved v2 candidates.

---

## 5 · Successor candidate capture

| Capture property | Recorded truth |
|---|---|
| manifest | `SYSTEM/RESOURCES/UI_GATE/CANDIDATES/OA-ZYRA-282_PHASE_1_V2_manifest.json` |
| manifest SHA-256 | `c354d8fa4c6d39f164a389b99af4257ad1bc8cf1c1bd81ebbc575dbb86d50dc7` |
| proposed version | `OA-ZYRA-282-phase1-v2` |
| comparison clock | `2026-08-30T18:00:00Z` |
| fixtures / variants | **6 / 24** |
| devices | 320×568, 390×844, 430×932, plus 390×844 at 130% text |
| candidate bytes | **1,144,685** |
| compact `screenshots` array SHA-256 | `6e23a03be0bd372f78340cd4d1c738437db8a73675d1f61661721890f4f6845f` |
| approval state | **24/24 `approved:false`** |
| device gate | `device_acceptance_pending:true` |
| automatic promotion | `false` |
| approved baselines modified | `false` |

The manifest carries every candidate's individual ID, path, SHA-256, byte
count, governing reference and proposed version. The name-filtered capture ran
exactly the 24 new variants and passed **24/24**; it did not execute an update
against any pre-existing candidate or approved path. The six standard
viewports were also inspected directly after capture.

---

## 6 · Staged supersession rows

The v2 manifest contains **24** `staged_supersession_rows`, one per stale v1
approved row. Their compact-array SHA-256 is:

`4c48af4e885b314c8a13d9e3d75f59e3680525ad9b43ab0733278aafa4c432a3`

Each row copies the complete original active baseline row, then appends the
067 archive-field shape:

- `archive_status: staged_pending_founder_acceptance`;
- `archived_date: null`;
- `archived_by: null`;
- `archive_reference: 068 … §3`;
- a reason stating that this is staged only and requires second Founder
  acceptance;
- the exact variant-matched `superseded_by` successor ID;
- `byte_preserved_at` equal to the original approved path.

The pending status and null actor/date are intentional: 068 §4 reserves
actual archive classification to the Founder's second acceptance. At this
stage all 24 old rows remain active, all original approved bytes remain at
their original paths, and the two approved ledgers still contain only their
067-approved 124 active / 12 archived truth.

On a later separately authorised promotion, these staged rows can be
mechanically finalized to 067's `superseded_byte_preserved` state with the
actual acceptance date/actor/reference. That future operation would keep 124
active rows overall, with 4 continuing Phase 1 v1 rows and 24 Phase 1 v2 rows,
and would increase the archive ledger from 12 to 36. No part of that future
operation is performed here.

---

## 7 · Approved-pixel preservation proof

| Preserved file/ledger | Pre SHA-256 | Post SHA-256 | Result |
|---|---|---|---|
| runtime approved manifest | `42b6ee8c2f9f9ced268af5b08123bc41aa2d3ba77da7e20f5337f94f11a04222` | same | untouched |
| governed approved manifest | `d8c48c1b232ded12acab8ab9038a03eb28e891fdd795127f5030eec1b50d6e12` | same | untouched |
| promoted Phase 1 v1 manifest | `f76168ebe249bcbc3d6792de453288113bb19fcfe44bf5f2a7603ac4a099bc31` | same | untouched |

The complete visual verifier re-read and matched all **124/124** active
approved files and all **12/12** archived files against the unchanged runtime
manifest. Runtime and governed active/archive arrays remain identical. The
promoted OA-ZYRA-282 manifests also re-proved all **96/96** candidate-to-
approved byte copies, including every historical Phase 1 v1 candidate.

No approved PNG was generated, copied, moved, overwritten or deleted.

---

## 8 · 069 change surface and true pre/post hashes

| 069 file | True pre SHA-256 | Post SHA-256 |
|---|---|---|
| `SOURCE/test/visual/zyra_visual_regression_test.dart` | `811a9ec389fc28c1c993a8072625b387066adefb03bed21969b71656685c00e8` | `49e2b668446bb0250f4d4ed427e5ffc61ce367deb4d77dec8d0f0f0fe58b61e4` |
| `SYSTEM/RESOURCES/UI_GATE/CANDIDATES/OA-ZYRA-282_PHASE_1_V2_manifest.json` | **ABSENT** | `c354d8fa4c6d39f164a389b99af4257ad1bc8cf1c1bd81ebbc575dbb86d50dc7` |
| 24 successor PNGs under `SOURCE/test/visual/candidates/` | **ABSENT — all 24 paths** | individual hashes/bytes in the v2 manifest; 1,144,685 bytes total |
| this 069 report | **ABSENT** | new governance filing |

The harness change does four bounded things only:

1. registers the old→successor fixture-family map;
2. gives the six current renders new candidate IDs while retaining the
   unaffected Additional detail fixture ID;
3. retains the governed -520/-360 capture actions for loaded Manager and
   detail states;
4. adds a test that audits all 24 unapproved candidate hashes and all 24
   pending supersession rows while proving old v1 rows remain active.

No production file was edited during 069.

---

## 9 · Forward and reverse evidence

### Forward

- replace six stale render-fixture IDs with six collision-free successor IDs;
- capture only those 24 new variant paths at the frozen clock;
- create one separate unapproved v2 manifest with candidate and staged-row
  evidence;
- extend the visual governance test without changing product behavior.

### Reverse (not executed)

A mechanical reverse restores
`SOURCE/test/visual/zyra_visual_regression_test.dart` from the true-pre
snapshot and removes only the one new v2 manifest plus the 24 new successor
candidate PNGs. No approved path or existing v1 candidate is involved because
none was changed. The 069 report remains the historical evidence of the
attempted round unless governance separately orders otherwise.

No reverse action was run.

---

## 10 · Verification results

| Check | Result |
|---|---|
| name-filtered successor capture | PASS — **24/24** |
| current focused Guardian delta suite | PASS — **14/14** |
| complete visual regression suite | PASS — **335/335** |
| complete `flutter test` suite | PASS — **848/848** |
| full `flutter analyze` | PASS — **No issues found** |
| `python3 tools/zyra_check.py` | PASS — **185 files, 0 findings**; five baselined references, zero new |
| `python3 -m unittest tools/test_zyra_check.py` | PASS — **1/1** |
| Dart format audit on changed harness | PASS — **0 changes required** |
| v2 manifest schema/count/uniqueness audit | PASS — **6 fixtures / 24 unique candidates / 24 unique staged rows** |
| successor candidate hash/byte audit | PASS — **24/24** |
| active approved hash/byte audit | PASS — **124/124** |
| archive approved hash/byte audit | PASS — **12/12** |
| promoted OA-ZYRA-282 source→approved audit | PASS — **96/96** |
| runtime↔governed active/archive equality | PASS |

The full-suite total is six higher than the 067 report's 842: five focused
Guardian-delta tests were added in the Founder-directed round and 069 adds one
candidate/supersession governance test. No test was removed in this round.

---

## 11 · Frozen boundaries

- No migration was created, edited, staged or applied.
- Migration count remains **208**.
- Applied Phase 0 migration remains byte-identical:
  `SOURCE/supabase/migrations/20260830200416_oa282_dr225_guardian_history_consent.sql`
  → `12605745e2be3dcbd8ca7ac47a2af75d54a3ba3e86ca0e65ae43e69a3f017c4e`.
- No database, RPC or network write was made.
- No approved manifest, approved row or approved pixel was changed.
- No existing v1 candidate or candidate manifest was changed.
- No promotion or archive transition was performed.
- No production UI behavior was changed during 069.
- No git command was used.
- No OA closure or self-approval is claimed.

---

## 12 · Handover

Fable can independently verify:

1. the full eight-file Founder-delta ledger and the visual harness's two-hop
   hash chain;
2. the exact 6-family / 24-row stale determination and the continuing
   Additional detail family;
3. all 24 v2 candidate hashes/bytes and the frozen clock;
4. all 24 pending supersession rows against their complete original active
   rows;
5. unchanged approved manifests, approved pixels, Phase 1 v1 manifest and
   migration state;
6. the verification matrix in §10.

After Fable's PASS, 068 §4 sends only these changed Guardian screens to the
Founder for the small second device look. Promotion and byte-preserved archive
finalization require that separate acceptance and are not authorised by 069.

— Codex / Lead Architect, 2026-08-31
