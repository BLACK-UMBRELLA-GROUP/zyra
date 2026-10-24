# 073 — CODEX → FOUNDER
# SUBJECT: OA-ZYRA-282 Phase 1 v2 promotion complete; supersessions final; programme closed by Founder direction
# DATE: 2026-09-10
# GOVERNANCE: 068 §3/§4 · 069 · 070 §4 · 072 · AD-AIOS-109 · DR-ZYRA-224/225 · OA-ZYRA-257/282
# STATUS: COMPLETE — INTERNALLY VERIFIED WITH ONE SEPARATE, EXPLICITLY RECORDED DASHBOARD-GATE DEBT

## 1 · Outcome

The final OA-ZYRA-282 promotion round is complete.

1. The exact **24/24** Founder-accepted Phase 1 v2 candidate PNGs were
   byte-copied, never regenerated, into
   `SOURCE/test/visual/approved/oa-zyra-282-phase1-v2/`.
2. The paired **24** Phase 1 v1 active rows were replaced in place.
3. All **24** original Phase 1 v1 rows and pixels remain byte-preserved at
   their original paths and are now final archive entries.
4. Active arithmetic is unchanged at **124**; archive arithmetic is **12 →
   36**.
5. Runtime and governed manifests expose byte-semantic identical active and
   archive arrays. The governed manifest alone retains its intentional root
   `decision: "DR-ZYRA-214"` field.
6. The historical `staged_by: "Codex / Lead Architect"` value remains
   untouched, exactly as 072 §5 required.
7. The Founder directed this work item to proceed on 2026-09-10 and expressly
   said this section may close, with later Guardian findings opened
   separately. OA-ZYRA-282 is therefore closed by Founder direction, not by
   Codex self-approval.

No product UI behaviour changed in this round.

---

## 2 · Authority, drift reconciliation and true pre-state

### 2.1 Authority

| Authority | SHA-256 read before work |
|---|---|
| `072_FABLE-CODEX_2026-09-01_FOUNDER_ACCEPTED_PROMOTION_ROUND_RELEASED.md` | `5cf627aa29286c899a69cbd8129f4dd7607b44bdf002c914b11c873e1e2361e0` |
| Founder direct instruction, 2026-09-10 | Proceed with work item 1; close this section; later Guardian issues may be separate |

AD-AIOS-109 removes the later Fable/ChatGPT relay dependency. The Founder's
current instruction is the fresh execution and closure authority.

### 2.2 Later harness change reconciled before promotion

072 recorded the visual harness at `49e2b668…`; the true 2026-09-10 pre-edit
hash was `096b879b…`. This was not silently accepted. A scratch reverse proved
that the difference consists only of the later 2026-09-09 Dashboard work:

- five callback renames from `onOpenNotifications` to
  `onNotificationsChanged`;
- the Guardian Dashboard's merged-Now scrolling interaction replacing the
  former Updates-tab tap.

Reversing only those changes reproduced `49e2b668…` exactly. None overlaps
the OA-ZYRA-282 Phase 1 v2 mapping, candidate, archive or governance-test
block. The later Dashboard work was preserved byte-for-byte.

### 2.3 True pre-state captured at edit time

Snapshot root:
`/private/tmp/zyra-073-true-pre.53K8BE/`

| Existing file / path | True pre SHA-256 or state |
|---|---|
| `SOURCE/test/visual/approved/manifest.json` | `42b6ee8c2f9f9ced268af5b08123bc41aa2d3ba77da7e20f5337f94f11a04222` |
| `SYSTEM/RESOURCES/UI_GATE/BASELINES/manifest.json` | `d8c48c1b232ded12acab8ab9038a03eb28e891fdd795127f5030eec1b50d6e12` |
| `SYSTEM/RESOURCES/UI_GATE/CANDIDATES/OA-ZYRA-282_PHASE_1_V2_manifest.json` | `c354d8fa4c6d39f164a389b99af4257ad1bc8cf1c1bd81ebbc575dbb86d50dc7` |
| `SOURCE/test/visual/zyra_visual_regression_test.dart` | `096b879b305709f7171efa761a9cdd3e486ed9dbe390161c8d663b7e0151db45` |
| `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` | `f3a0e4241ab4dbe5325443233b3b8664908a69089cb6ef69318b09d0df58e3a2` |
| `SOURCE/test/visual/approved/oa-zyra-282-phase1-v2/` | **ABSENT** |
| 28 Phase 1 v1 approved files | copied to true-pre snapshot before promotion; 24 superseded + 4 continuing |

Preflight also proved: 124 active / 12 archived; 24 candidates all
`approved:false`; 24 pending staged rows with null acceptance actor/date;
candidate bytes 1,144,685; superseded bytes 1,816,958; frozen clock
`2026-08-30T18:00:00Z`.

---

## 3 · Deterministic convention bound for 072's unspecified literals

072 fixes the state transition but does not prescribe every root literal or
array-order convention. The following minimal conventions are now explicit:

1. retain the historical key `staged_supersession_rows`; its rows now carry
   the final archive state rather than deleting staging provenance;
2. set root `supersession_status` to `finalized_founder_accepted`;
3. append `OA-ZYRA-282-phase1-v2` to `active_versions` in approval-event
   order and set singular `active_version` to that latest approved version;
4. set latest approval date/reference to the real 2026-09-01 second
   acceptance and 072 §1/§3;
5. keep each replacement in its paired old row's array position, avoiding any
   unrelated reorder;
6. use current surface names `Guardian` and `Guardian Detail` in the new
   approved-row `screen` metadata;
7. use archive status `superseded_byte_preserved`, real Founder actor/date,
   the 072 reference, and one uniform accepted-presentation reason.

These choices affect ledger description only. They do not alter pixels or UI.

---

## 4 · Exact promotion and archive ledger

The six accepted fixture mappings, each across small, standard, large and
standard-at-130%-text variants, are:

| Superseded Phase 1 v1 family | Active Phase 1 v2 family | Rows |
|---|---|---:|
| `guardianship-manager-empty` | `guardian-manager-empty` | 4 |
| `guardianship-manager-main-consent-off` | `guardian-manager-main` | 4 |
| `guardianship-manager-loaded-consent-on` | `guardian-manager-loaded-pending` | 4 |
| `guardianship-manager-unavailable` | `guardian-manager-unavailable` | 4 |
| `guardian-detail-main` | `guardian-detail-main-consent-off` | 4 |
| `guardian-detail-history-unavailable` | `guardian-detail-main-history-unavailable-consent-off` | 4 |

`guardian-detail-additional` remains exactly **4** active Phase 1 v1 rows, as
ordered.

| Ledger | Rows | Bytes | Compact-array SHA-256 |
|---|---:|---:|---|
| active `baselines` | 124 | 6,678,148 | `948049091ed1759b5a7aa545f1c598fc17fc3e66d31c45be4ab39fc404a58aab` |
| `archived_baselines` | 36 | 2,847,230 | `eb21dfe20e7183cbf695a2a832df7db711e352af2cc9fc69238be1af568bc55b` |
| v2 manifest `screenshots` | 24 | 1,144,685 | `f39d61f10c7781baaade817930898750df00b6ab97b9e8a4dc87b95f599eb8f1` |
| v2 manifest finalized supersessions | 24 | 1,816,958 | `ab65e9c48246c4f8b0ff08ee77c0647626c713e69c7082d4c988571985d69301` |

Active version distribution:

| Version | Rows | Bytes |
|---|---:|---:|
| `OA-ZYRA-281-v1` | 28 | 1,298,053 |
| `OA-ZYRA-282-phase1-v1` | 4 | 283,828 |
| `OA-ZYRA-282-phase1-v2` | 24 | 1,144,685 |
| `OA-ZYRA-282-phase2-v1` | 36 | 1,758,352 |
| `OA-ZYRA-282-phase3-v1` | 32 | 2,193,230 |

Archive distribution is 12 OA-ZYRA-281-v1 rows / 1,030,272 bytes plus 24
Phase 1 v1 rows / 1,816,958 bytes. Active IDs and archive IDs are disjoint;
every archived row points to an active successor. Every old PNG still exists
and matches its original hash and byte count.

The candidate manifest is now 24/24 `approved:true`, records
`device_acceptance_pending:false`, preserves
`approved_baselines_modified:false`, retains the frozen clock, and finalizes
all 24 reserved archive rows. Its row-by-row hashes, byte counts, source paths
and approved paths are the canonical 24-file evidence ledger.

---

## 5 · Changed-file SHA-256 ledger

| File | True pre SHA-256 | Post SHA-256 |
|---|---|---|
| `SOURCE/test/visual/approved/manifest.json` | `42b6ee8c2f9f9ced268af5b08123bc41aa2d3ba77da7e20f5337f94f11a04222` | `4667f42228d76dcb0893c247ea5c95c2f9556f485fc3fb8af3ece76974b5e03e` |
| `SYSTEM/RESOURCES/UI_GATE/BASELINES/manifest.json` | `d8c48c1b232ded12acab8ab9038a03eb28e891fdd795127f5030eec1b50d6e12` | `b8070c0be1c9a62e00704229c849794e39ce87db5f5ab6ab2ea49346e0dd3f26` |
| `SYSTEM/RESOURCES/UI_GATE/CANDIDATES/OA-ZYRA-282_PHASE_1_V2_manifest.json` | `c354d8fa4c6d39f164a389b99af4257ad1bc8cf1c1bd81ebbc575dbb86d50dc7` | `5379b51b6108fa010160f74a4dc48a6ecf1ef892d4f5245c3d3566f8e2a14f1e` |
| `SOURCE/test/visual/zyra_visual_regression_test.dart` | `096b879b305709f7171efa761a9cdd3e486ed9dbe390161c8d663b7e0151db45` | `f1195d01f385b8195fb454f174cd6bce1a17aa0238b14aa200f2905fb0341815` |
| `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` | `f3a0e4241ab4dbe5325443233b3b8664908a69089cb6ef69318b09d0df58e3a2` | `9d36eb088ca69cdf0eac774b9b338b4c69e15b7f9e9a7fddce9947907d6130ac` |

The 24 new approved files were all absent at true pre. Their exact post hashes
and sizes equal the unchanged candidate source rows in the v2 manifest. No
existing approved or candidate PNG was overwritten.

---

## 6 · Verification results

| Check | Result |
|---|---|
| staged preflight governance test | PASS — 1/1 before mutation |
| four promotion/archive governance checks | PASS — 4/4 |
| focused Guardian Manager / Seeker truth / retired-design suite | PASS — 14/14 |
| promoted source → approved byte comparison | PASS — 24/24 |
| active approved hash/byte verifier | PASS — 124/124 |
| archive hash/byte verifier | PASS — 36/36 |
| runtime ↔ governed active/archive equality | PASS |
| full `flutter analyze --no-pub` | PASS — no issues found |
| `python3 tools/zyra_check.py` | PASS — 185 files, 0 findings; 5 baselined references, 0 new |
| `python3 -m unittest tools/test_zyra_check.py` | PASS — 1/1 |
| changed-file Dart format audit | PASS — 0 changes |
| complete visual suite | **275 pass / 60 fail — all 60 are pre-existing later Dashboard comparisons; zero Phase 1 v2 Guardian target failures** |
| complete Flutter suite | **790 pass / 60 fail — the same 60 visual comparisons; all 515 non-visual tests pass** |
| whole `lib test` format audit | **one pre-existing would-format file: `test/zyra_dashboard_updates_migration_test.dart`; not modified here** |

The complete gate is reported honestly rather than relabelled as green.
Before this promotion it already had the same 60 Dashboard failures. After
the promotion, all four governance checks and every targeted Guardian visual
variant pass; the full gate still has exactly those same 60 unrelated
comparisons.

The 15 affected Dashboard families (four variants each) are:

- Seeker: `thinned-no-guardian`, `thinned-connected`,
  `thinned-pending-invitation`, `thinned-unavailable`,
  `updates-populated`, `updates-empty`, `updates-last-known`,
  `insights-empty`;
- Guardian: `thinned-empty`, `thinned-main-priority`,
  `thinned-additional-neutral`, `thinned-unavailable`,
  `updates-populated`, `updates-empty`, `updates-last-known`.

They result from later 2026-09-09 Dashboard work, are outside 072's scope,
and are recorded under the already-open permanent anti-drift owner
OA-ZYRA-257. No duplicate OA was created and no approved Dashboard pixel was
regenerated or promoted.

---

## 7 · Forward/reverse evidence

### Forward — executed

- checked all true pre hashes and the target-directory absence;
- validated each staged row against its complete active source row;
- re-read all 24 candidate and 24 old approved hashes/byte counts;
- copied only the 24 candidates to the new versioned approved directory;
- re-read each copy and proved exact candidate equality;
- replaced the paired active rows without unrelated array reordering;
- appended the 24 final byte-preserved archive rows;
- wrote identical active/archive arrays to both manifests;
- updated the candidate ledger and governance test to the accepted state.

### Reverse — not executed

A mechanical reverse is available from the true-pre snapshot: restore the
four existing promotion files and the register, then remove only the 24 newly
created approved copies and their now-empty v2 directory. The old Phase 1 v1
pixels require no reconstruction because they were never moved or deleted.

---

## 8 · Frozen boundaries and closure

- Migration count remains **208**.
- Applied Phase 0 migration remains byte-identical:
  `12605745e2be3dcbd8ca7ac47a2af75d54a3ba3e86ca0e65ae43e69a3f017c4e`.
- No migration, database, RPC or network write occurred.
- No UI source or behaviour changed.
- No fixture, candidate or approved screenshot was recaptured.
- No approved Dashboard pixel was altered to conceal later drift.
- No git command was used.
- No ChatGPT or Fable response is a closure dependency under AD-AIOS-109.

OA-ZYRA-282 is **CLOSED** by the Founder's direct 2026-09-10 instruction.
Any Guardian issue noticed after this accepted programme is new scope and
must be opened and ruled separately; this closure does not waive or hide it.

— Codex / Product Designer & Implementation Engineer, 2026-09-10
