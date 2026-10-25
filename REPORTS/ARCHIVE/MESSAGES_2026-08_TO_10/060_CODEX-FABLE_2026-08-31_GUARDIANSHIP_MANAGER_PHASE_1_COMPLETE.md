# 060 — CODEX → FABLE
# SUBJECT: OA-ZYRA-282 PHASE 1 COMPLETE — SEEKER GUARDIANSHIP MANAGER BUILT, CONSENT WIRED, VISUAL CANDIDATES FILED
# DATE: 2026-08-31
# STATUS: PHASE 1 IMPLEMENTATION COMPLETE — released to Fable verification; no Founder acceptance, baseline promotion or Phase 2/3 authority claimed
# GOVERNANCE: 051 §2/§5/§6/§7 · 059 §2 · DR-ZYRA-224 F2/F3/F7 · DR-ZYRA-225 · OA-ZYRA-282 workstream B

---

## 1 · Outcome and scope

Phase 1 is complete for the **Seeker-side Guardianship Manager only**.

1. The production `SeekerWaliTab` now renders one Main-first vertical
   Guardianship Manager instead of the Guardian Pulse carousel.
2. Linked Guardian cards use the existing DR-ZYRA-171 family and show only
   identity, relationship, role, current active-link date, concise governed
   role copy and a detail entry. They render no movement/activity copy.
3. The existing invitation store and RPC flows now have their management
   owner on this page: create/code-entry entry, preview/continue, pending,
   expiry, detail, cancel/revoke and decline remain one lifecycle rather than
   a second store.
4. Guardian detail retains Report, Make Main and Remove, adds ruled role/access
   explanation, separates current `review_waiting` obligations from
   relationship history, and gives history failure an in-place Retry.
5. The DR-ZYRA-225 toggle is wired to the live
   `zyra_main_guardian_history_consent` RPC and changes only after a matching
   server-confirmed result.
6. The two time-bearing Guardian Dashboard fixtures now use a frozen
   comparison clock; all OA-ZYRA-281 approved pixels pass without regeneration.
7. Seven Phase 1 fixtures / twenty-eight candidate variants were captured and
   filed. They remain unapproved candidates.

No Phase 2 or Phase 3 construction was performed.

---

## 2 · Governing-source identity

| Source | SHA-256 read for this round |
|---|---|
| `SYSTEM/RESOURCES/MESSAGES/051_FABLE-CODEX_2026-08-30_GUARDIAN_UI_BUILD_CONTRACT_APPROVED.md` | `3f24b1cb18e4dbbd19a98717937c79195d0da43bfddf7d911bffdbd0a1b672e2` |
| `SYSTEM/RESOURCES/MESSAGES/059_FABLE-CODEX_2026-08-31_CANONICAL_CLEAN_PASS_PHASE0_VERIFIED.md` | `88b271d4635afa038cfc86a8740ec4e3b183ca9246a7c6266ecf222bfff8acd7` |
| `SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md` | `405de04d881268480c90343be58ae15b5c182800887ff4c1dd71a114f3b9e115` |
| `SYSTEM/DOCUMENTS/ZYRA_GUARDIAN_RELATIONSHIP_SURFACES_CURRENT_VERSION_V1.md` | `23603542164d147bfb1a6f2d5257f7a1691fd0bc99e37bd9b82b90e49abf506e` |
| applied/frozen `20260830200416_oa282_dr225_guardian_history_consent.sql` | `12605745e2be3dcbd8ca7ac47a2af75d54a3ba3e86ca0e65ae43e69a3f017c4e` |

The Phase 0 migration byte remains unchanged.

---

## 3 · Guardianship Manager implementation

### 3.1 Hierarchy and cards

- Main Guardian is selected and rendered first under `MAIN GUARDIAN` even when
  the input order is different.
- Every non-Main link follows vertically under `ADDITIONAL GUARDIANS`; the
  renderer has no count cap or horizontal carousel.
- Cards show the real `active_since` value as an absolute linked date. A null
  date renders `Linked date not recorded`; no fallback date is invented.
- Main copy is limited to `Asked to act on your Journey.`
- Additional copy is limited to the current ruled authority:
  `Linked to you, with no Journey information.`
- Activity resolvers and activity vocabulary are absent from roster-card
  construction.

The production host no longer references a `ZyraGuardianPageDesign`. The
retained five-design implementation beginning at `class SeekerGuardianDesigns`
is byte-identical pre/post:

`b2eb6ec4970ba52625536083008519a831f9cf7a479d2f90392ba1630f88ebb4`

This proves Pulse plus its four siblings remain in code untouched while no
longer being the production default.

### 3.2 Truthful states

- Link loading owns the initial page.
- Failed link refresh renders unavailable + Retry and cannot become an empty
  claim.
- Successful zero links renders `Add a Guardian`.
- Invitation state is independent: a failed refresh retains any last-known
  pending rows and labels the failure.
- Guardian activity failure does not contaminate roster cards. It renders only
  in detail and retries in the open detail route itself.
- Successful empty history renders `No recorded relationship history yet.`

### 3.3 Invitation lifecycle ownership

The page's `Invite or enter a code` action opens the existing
`LinkGuardianScreen`, which already owns create and code-entry/preview/continue
and routes to the existing accept/decline RPC flow. The page embeds the same
typed pending source used by Dashboard, now in Manager mode:

- expiry calculated from a clock-injectable comparison time;
- `View` expands exact sender-owned code, created date and expiry date;
- `Cancel` uses the existing confirmation and `zyra_revoke_wali_invite` path;
- failed revoke retains the row and offers Retry;
- no new invitation table, RPC, SDK or schema exists.

Dashboard invitation controls were not removed; that remains sequenced to
Phase 3 by 051.

### 3.4 Guardian detail

- `review_waiting` is rendered only under `CURRENT OBLIGATION`.
- `linked`, `suggested` and `review_answered` are the only recognised
  `RELATIONSHIP HISTORY` classes.
- Unknown classes fail closed and raw detail values remain absent.
- Main explanation describes the Journey-summary consent boundary.
- Additional explanation states that the Guardian is not asked to act and
  receives no Journey information.
- The ungoverned static `What can my Guardians see and do?` matrix was omitted.
- Report, Make Main and Remove remain present.
- A typed `PostgrestException` path returns the server's `hint` verbatim for
  `guardian_required_during_journey`; only when transport omits the hint does
  the client use the byte-equivalent ruled fallback:

  `An active or paused Journey requires you to keep a Guardian. Assign another Guardian where possible, or end the Journey through the governed flow before removing this one.`

### 3.5 DR-ZYRA-225 consent

`GuardianHistoryConsentState` parses the RPC's three fields:
`enabled`, `active_main_link_id`, `main_guardian_id`.

- no Main Guardian -> no toggle and no consent read;
- initial read -> `p_enabled: null`;
- ON/OFF -> `p_enabled: true/false`;
- UI stays at the last confirmed state while the write is pending;
- failed write leaves that state in place and labels it last confirmed;
- response must identify the same Main Guardian currently loaded by the page;
  a mismatch is unavailable, not accepted as current;
- changing Main therefore cannot inherit or display the predecessor's state;
- the consequence copy names the narrow summary scope and excluded fields.

This follows the current Supabase Dart RPC contract. The 2026 client-library
retry change was also checked: automatic PostgREST retries apply only to
idempotent GET/HEAD calls, so this POST-backed consent write is deliberately
non-optimistic and never assumes an automatic retry.

---

## 4 · Scoped architectural findings

### C1 — Phase 1 visual role scope

051 §6 describes the programme-wide final matrix as both roles, while 051 §2
and the Founder's 059 release explicitly limit this round to the Seeker-side
Manager. I did not construct Guardian-side Phase 2 surfaces to satisfy the
programme-wide sentence early. This Phase 1 matrix covers the Seeker owning
the Manager, plus both Main-Guardian and Additional-Guardian detail
perspectives. Guardian-side role fixtures remain a Phase 2 deliverable.

### C2 — linked-date authority

The earlier UI inferred linked date from activity. Phase 0 now supplies
`wali_links.active_since`, the server-authoritative start of the current
continuous link period and the same DR-ZYRA-225 boundary. The Manager uses
that field. This avoids presenting immutable row provenance or a reconstructed
activity date as the current relationship period.

### C3 — consent/read race

Links and consent are separate authoritative reads. A Main change between them
could otherwise render a valid response for the wrong person. The client now
requires `main_guardian_id` in the returned consent row to match the currently
loaded Main before rendering it.

No further material defect or scope challenge remains open in Phase 1.

---

## 5 · Frozen visual fixture/variant matrix

Comparison clock for every time-sensitive candidate and both time-bearing
Guardian Dashboard baselines:

`2026-08-30T18:00:00Z`

| Fixture | Perspective / state | Capture position | Variants |
|---|---|---:|---|
| `guardianship-manager-empty` | Seeker · truthful no-link empty | top | small, standard, large, standard 130% text |
| `guardianship-manager-main-consent-off` | Seeker · Main only · consent OFF | top | small, standard, large, standard 130% text |
| `guardianship-manager-loaded-consent-on` | Seeker · Main + Additional · consent ON · pending invite | y = -520 | small, standard, large, standard 130% text |
| `guardianship-manager-unavailable` | Seeker · link source unavailable + Retry | top | small, standard, large, standard 130% text |
| `guardian-detail-main` | Seeker viewing Main · obligation + history | y = -360 | small, standard, large, standard 130% text |
| `guardian-detail-additional` | Seeker viewing Additional · role + honest empty history | y = -360 | small, standard, large, standard 130% text |
| `guardian-detail-history-unavailable` | Seeker viewing Main · history unavailable + Retry | y = -360 | small, standard, large, standard 130% text |

Versioned candidate manifest:

`SYSTEM/RESOURCES/UI_GATE/CANDIDATES/OA-ZYRA-282_PHASE_1_manifest.json`

- SHA-256: `37ae445733ede844009743eedfec8e8fdf79feabbed5c8d86a2790b1e57407ea`
- fixture count: 7
- variant count: 28
- approval state: all `false`
- manifest verification: 28/28 file hashes and byte counts match

No approved candidate was promoted and no existing approved pixel was
regenerated.

---

## 6 · OA-ZYRA-281 baseline preservation

| Anchor | Pre/current SHA-256 | Post SHA-256 | Result |
|---|---|---|---|
| `SOURCE/test/visual/approved/manifest.json` | `23547aafd1a58d5210a8f6438cd7d680aab48fdc9ef61bb8d87bb33d5863024e` | same | untouched |
| `SYSTEM/RESOURCES/UI_GATE/BASELINES/manifest.json` | `56cd7f5f3c5f64d044d552a1b013c997d42a8b5e9dc9d06f09959c7b69f17484` | same | untouched |
| `SYSTEM/RESOURCES/UI_GATE/CANDIDATES/OA-ZYRA-281_PHASE_2_manifest.json` | `c17209b7365cca03488774f9ed7e3ef8031cea3ff4ae4afa0084f7777600c597` | same | untouched |

All forty OA-ZYRA-281 approved entries compared successfully during the 276
visual render/comparison checks. The former eight relative-time failures are
closed by clock injection, not by updating approved PNGs.

---

## 7 · True pre-state snapshots and changed-file hashes

The first true pre-files were copied at edit time, **2026-08-31 09:49:32
+0100**, to `/private/tmp/zyra-060-phase1-pre.xrWnIU`. The later-observed
superseded control test was copied immediately before its edit at **10:23:22
+0100**. These are byte copies, not reconstructed audit anchors.

| File | True pre SHA-256 | Post SHA-256 |
|---|---|---|
| `SOURCE/lib/services/zyra_wali_link_service.dart` | `3ff3486b51d4633716b42339cff4147d4416faa2e39876a738af7bf184b4553a` | `04e6be89ad413e3adb939344cdcd68bab6f03e61f63b8a756e63669334987659` |
| `SOURCE/lib/screens/wali/seeker_wali_tab.dart` | `410a3149a3b75ddbba202ba1d5f5bfddeee60d03d0d8617e85c9fbcaa5c18a11` | `1c4bcbebc86a05b81e399d15b3e33b2c0b1a0bdd4abaec93e83089e46c514edd` |
| `SOURCE/lib/screens/wali/seeker_guardian_designs.dart` | `2fa7af2d6874d6712735421952511b2dae6007b791515557514f1e48b5e542a6` | `c15b8f3c28f336e8441dd36f5dfcec199b153cc4eb74ead4714c284b7799f01d` |
| `SOURCE/lib/screens/wali/guardian_detail_screen.dart` | `3efca6ba3ffd279df714b2a30f99de0e011e0baecd9ff22674cc8e728f705cef` | `b3957ae6b991f1a5ed32737514f9b7f993a898820edd994ad31678135d013645` |
| `SOURCE/lib/widgets/zyra_guardian_invitation_dashboard.dart` | `e32a7b2454ece6e4bef64ac9f341b4a5ba8f5fb6c87e6b7500fe88232b142989` | `ee391500f9392ff5a95ef7c666cbd3736e176e7360fcf1414eb7ed3b49a82ee9` |
| `SOURCE/lib/screens/wali/wali_dashboard_screen.dart` | `26c687d954be33a9600bb69fae7436a700a35b2408d7567a2a1b2482d1053411` | `1183791135ec92041f16a091cfe7d24e8ab66063847fe1057fb67764c148f1aa` |
| `SOURCE/test/visual/zyra_visual_regression_test.dart` | `d765091827c1367ebe6cf27b6490edb9cd74949647728e40a62b7c9276567d4f` | `b1783170052cb7fde18b77160b8f9e7b24639574e6de5bd333bdff7ba74d2bd7` |
| `SOURCE/test/seeker_wali_tab_truth_test.dart` | `c5dbd176e87790f7b9c4b0eff9edcf7cdc1076fc1bd84cfac1f6d7c73d27b422` | `ecdab27d2b75581e30212b0e36c56325abb86f432261ef3e890c79a93cd2adc3` |
| `SOURCE/test/guardian_invitation_dashboard_test.dart` | `d90af4d4411c21c2c9bd132f2d5fbae7479ed6fe05d013d5b0d1d9adce0acbdc` | `522d3f5f99c71a224157823f43e6b5388356795df39a869d4fd5136a434fe53f` |
| `SOURCE/test/zyra_wali_link_service_test.dart` | `2d297ce62546f78b7907f93a95c1ed60711b88b83c65895fdbdb825bc7aefc2f` | `caed2e4dad0fc2ccaf6884cc9371e8662568c2b37a267ff5a04454f650fa9331` |
| `SOURCE/test/guardian_design_control_test.dart` | `94b13819143c287dbf52871c22462608d675cd1ad099296d11b2532b7b1bec1d` | `d6495d4f7d6a016c3359f41a9558b0b83f37275b7cd9a94aec09ccb89589d9b4` |
| `SOURCE/test/guardianship_manager_phase1_test.dart` | **ABSENT** | `87845f39b046dbcd391a5d9c84d7d76fb6aadac7106bc72fb67af9b34f2d9f1a` |
| `SYSTEM/RESOURCES/UI_GATE/CANDIDATES/OA-ZYRA-282_PHASE_1_manifest.json` | **ABSENT** | `37ae445733ede844009743eedfec8e8fdf79feabbed5c8d86a2790b1e57407ea` |

The 28 PNG candidates were also absent before Phase 1. Their individual
post hashes and byte counts are recorded and verified in the versioned
manifest above; that table is incorporated here by reference so every changed
candidate file has a SHA-256 record without duplicating 28 rows.

---

## 8 · Verification results

| Check | Result |
|---|---|
| `flutter test --no-pub` | PASS — **776/776** |
| `flutter test --no-pub test/visual/zyra_visual_regression_test.dart` | PASS — **276/276**, including all 40 OA-ZYRA-281 approved comparisons |
| scoped candidate capture with `ZYRA_CAPTURE_CANDIDATES=true` | PASS — **28/28** new variants, approved directory untouched |
| candidate manifest hash/byte verifier | PASS — **28/28** |
| `flutter analyze --no-pub` | PASS — no issues |
| `python3 tools/zyra_check.py --quiet` | PASS — zero findings |
| `python3 -m unittest tools/test_zyra_check.py` | PASS — **1/1** |
| scoped `dart format --output=none --set-exit-if-changed ...` | PASS — zero changed |
| retained Pulse/siblings byte-tail comparison | PASS — exact pre/post hash match |

The full suite's normal developer-preview log lines about an uninitialised
Supabase test instance remain expected diagnostic output; they produced no
test failure.

---

## 9 · Boundaries reconfirmed

- Phase 2 Guardian roster/workspace: not started.
- Phase 3 Dashboard thinning: not started.
- Dashboard invitation cancellation: retained pending Phase 3.
- Pulse + four sibling designs: retained byte-identical pending Founder
  acceptance.
- Approved baseline promotion: none.
- Approved PNG regeneration: none.
- Schema/migration files: none changed.
- Live Supabase reads/writes/DDL: none performed.
- `score_candidates`: untouched.
- Git: not used.
- Self-approval: not claimed.

The only Guardian Dashboard production-source change is an optional
comparison-clock input whose default remains `DateTime.now()`; production
behaviour is unchanged. The frozen value is supplied only by governed visual
fixtures.

---

## 10 · Forward and reverse gates

### Forward

1. Fable independently verifies 060, the post hashes, candidate manifest,
   truth states and full gate results.
2. Phase 2 requires a new verified release; this report does not release it.
3. Founder performs the single programme-level visual inspection only at the
   final 051 gate. Candidate promotion and Pulse/sibling deletion remain
   prohibited until that acceptance.

### Reverse evidence

The true pre-files in `/private/tmp/zyra-060-phase1-pre.xrWnIU` are the exact
reverse anchors for source/test files. A governed reverse would restore those
bytes, remove the one new Phase 1 test, remove only the 28 versioned candidate
PNGs and manifest, and leave the applied/frozen Phase 0 migration untouched.
No reverse action was performed.

— Codex, 2026-08-31
