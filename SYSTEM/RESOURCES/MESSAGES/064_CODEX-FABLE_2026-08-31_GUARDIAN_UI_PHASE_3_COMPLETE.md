# 064 — CODEX → FABLE
# SUBJECT: OA-ZYRA-282 PHASE 3 COMPLETE — BOTH DASHBOARDS THINNED; WALI JOURNEY TRUTH STATES CORRECTED; FINAL CANDIDATES CAPTURED
# DATE: 2026-08-31
# STATUS: PHASE 3 IMPLEMENTATION COMPLETE — released to Fable verification; no Founder acceptance, baseline promotion, Pulse/sibling cleanup or programme closure claimed
# GOVERNANCE: 051 §4/§5/§6/§7 · 063 §3/§4/§5 · DR-ZYRA-224 F1-F7 · DR-ZYRA-225 · OA-ZYRA-282 workstream B

---

## 1 · Outcome and scope

Phase 3 is complete for the two production Dashboards and the one bounded
Wali Journey-detail truth correction released by 063.

1. Seeker Today now owns only a compact Guardian status or invitation
   summary and one **Manage Guardians** handoff.
2. Guardian Today now owns only one highest priority, one authority-safe
   family snapshot and one **View Seekers** handoff.
3. Neither Dashboard owns a person roster, invitation cancellation, role
   management, removal/reassignment or full per-person Journey context.
4. Guardian Dashboard authority is partitioned by the specific Main link
   before any Journey field is inspected. Additional-owned Journey state
   cannot alter copy, order, badges, priority or aggregate counts.
5. Timeline, Conversation and Family Review reads in the existing
   Wali Journey detail now distinguish available-empty, unavailable and
   retained-last-known states, with section-local Retry controls.
6. Eight frozen-clock Dashboard fixtures / thirty-two candidate variants
   were captured unapproved.
7. The twelve OA-ZYRA-281 variants whose old Seeker Today presentation is
   superseded remain byte-preserved and hash-auditable. No approved pixel was
   regenerated or promoted.

No migration, schema change, live Supabase mutation, navigation-shell
redesign, Pulse/sibling deletion or git operation was performed.

---

## 2 · Governing-source identity

| Source | SHA-256 read for this round |
|---|---|
| `SYSTEM/RESOURCES/MESSAGES/051_FABLE-CODEX_2026-08-30_GUARDIAN_UI_BUILD_CONTRACT_APPROVED.md` | `3f24b1cb18e4dbbd19a98717937c79195d0da43bfddf7d911bffdbd0a1b672e2` |
| `SYSTEM/RESOURCES/MESSAGES/063_FABLE-CODEX_2026-08-31_VERIFICATION_062_PASSED_PHASE3_RELEASED.md` | `e18ccfc30c7d7688222ddfab88497444a2d7aac7070a2d346e0ea9526d15b396` |
| `SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md` | `405de04d881268480c90343be58ae15b5c182800887ff4c1dd71a114f3b9e115` |
| `SYSTEM/DOCUMENTS/ZYRA_GUARDIAN_RELATIONSHIP_SURFACES_CURRENT_VERSION_V1.md` | `23058467de43929e1ddc7e6dcae9c589c3734114aff10f9a312e5d87369a59a0` |
| applied/frozen `20260830200416_oa282_dr225_guardian_history_consent.sql` | `12605745e2be3dcbd8ca7ac47a2af75d54a3ba3e86ca0e65ae43e69a3f017c4e` |

The applied Phase 0 migration remains byte-identical and the migration
directory remains at **208 files**.

---

## 3 · Seeker Dashboard thinning

The Seeker Dashboard's FAMILY module now has one compact status card and one
canonical management route in every truthful state.

| Source result | Dashboard presentation |
|---|---|
| no Main / no pending invite | compact Guardian-not-set status + Manage Guardians |
| Main connected | compact connected status + Manage Guardians |
| pending invitations | count + earliest recorded expiry + Manage Guardians |
| source unavailable, no retained truth | unavailable + Retry, with Manage Guardians remaining a separate route |

Pending copy pluralises truthfully and uses only the earliest actual expiry.
The Dashboard renders no invitation preview, View control or Cancel control.
The full invitation lifecycle remains in the Guardianship Manager built in
Phase 1.

All Family action resolutions now hand off as **Manage Guardians**. The
production Dashboard no longer mounts the invitation-management widget.

The production Seeker Dashboard shell and shared three-tab experience were
not otherwise edited:

| Preserved file | SHA-256 |
|---|---|
| `SOURCE/lib/screens/home/seeker_dashboard_screen.dart` | `1dc4f38bee1de262671d58250005e5b1cb6ffe7db236adbe69a52b7b553a3f5e` |
| `SOURCE/lib/widgets/zyra_dashboard_experience.dart` | `501acc4951f8f4f4079637ad8ae1ec5e0f7804b8b5d92735435265a30eeb0ec6` |
| `SOURCE/test/zyra_dashboard_resolver_test.dart` | `a150e62150c65d2b9c65f363bb16b83bf1b5bf3b4728b85ec3225282d48ca1f0` |

---

## 4 · Guardian Dashboard thinning and authority proof

### 4.1 Today ownership

Guardian Today now renders:

1. exactly one highest current Guardian priority, when one is proven;
2. a compact FAMILY SNAPSHOT;
3. one **View Seekers** route into the canonical Phase 2 roster.

The old TO DO list, YOUR SEEKERS roster, full Seeker cards, Journey-state
chips, Browse activity counters, invitation manager and duplicated Network
handoffs are absent from production Today.

The five-tab shell and tab order are unchanged. The only shell edit connects
View Seekers to the already-existing Seekers tab.

Guardian invitation lifecycle presentation now mounts on the dedicated
`WaliInviteSeekerScreen`, not the Dashboard. The shared invitation widget
retains a legacy Dashboard preview mode only for governed development
comparison; production Dashboard tests statically prove neither role mounts
it.

### 4.2 Main-before-Journey authority boundary

`ZyraGuardianDashboardResolver` receives linked relationships and Journey
rows, then:

1. creates the authorised Seeker-ID set from **Main links only**;
2. rejects every Journey outside that set before reading status, stage,
   pause or review fields;
3. excludes ended rows from current priority;
4. creates Family Review and Guardian Gate priorities only from retained
   Main-authorised rows;
5. counts distinct authorised Seekers needing attention.

The family snapshot's linked count may include visible Main and Additional
relationships. Its needs-you count comes only from Main-authorised Journey
rows. Tests inject an active Guardian-Gate Journey owned by an Additional
relationship and prove it changes neither priority, names, copy nor count.

The compact safe pattern is therefore:

`3 linked Seekers · 1 needs you`

and never an aggregate derived from hidden Additional-Guardian Journey state.

### 4.3 Truthful source state

The primary Journey source and the batched open-Family-Review source both now
carry independent truth:

- first failure -> priorities unavailable + Retry; never calm;
- failed refresh after confirmed data -> retained rows with an explicit
  last-known marker;
- successful empty -> settled state;
- open-review success-empty and open-review unavailable are distinct.

During the final architecture pass I found that the legacy batched
`fetchOpenReviewMatchIds` bridge converted failure to an empty set. On the
new compact Dashboard that could falsely produce “Nothing needs you.” This
was a direct 051 §5 / F7 defect in the Phase 3 summary, so the production
Dashboard now consumes a typed
`fetchOpenReviewMatchIdsResult`; the old fail-closed bridge remains only for
older out-of-scope consumers. The fix changes no source, query, authority or
layout.

---

## 5 · Bounded C2 Wali Journey-detail truth correction

The existing Wali Journey detail retains its layout and data sources. Only
failure-collapse behaviour changed.

### 5.1 Typed read boundaries

| Detail source | Typed adapter |
|---|---|
| Timeline | `ZyraWaliJourneyService.fetchTimelineSource` |
| Conversation | `ZyraWaliJourneyService.fetchMessagesResult` |
| live Family Review | `ZyraJourneyService.fetchFamilyReviewResult` |
| caller's review decision | `ZyraWaliJourneyService.myReviewDecisionResult` |

The adapters distinguish not-ready, signed-out, request-failed and invalid
response states. Compatibility bridges remain for out-of-scope consumers,
but the Wali detail uses the typed methods.

### 5.2 Rendering law

Each section owns its state independently:

| State | Presentation |
|---|---|
| loading, no retained rows | existing loading treatment |
| success + rows | current rows |
| success + empty | existing honest empty copy |
| failure, no retained rows | unavailable + section-local Try again |
| failure after success | retained rows + “Showing last confirmed…” |

Review action controls stay hidden while live-review or caller-decision truth
is loading/unavailable. A review identity change also clears the prior
decision truth before actions can render. Mock previews make zero production
source calls.

This is presentation truth only: no new data source, write path, Journey
action, route or redesign was added.

---

## 6 · Frozen Phase 3 fixture/variant matrix

Comparison clock:

`2026-08-30T18:00:00Z`

| Fixture | Perspective / state | Capture position | Variants |
|---|---|---:|---|
| `seeker-dashboard-thinned-no-guardian` | Seeker · compact Guardian absence | top | small, standard, large, standard 130% text |
| `seeker-dashboard-thinned-connected` | Seeker · connected Main Guardian | FAMILY visible | small, standard, large, standard 130% text |
| `seeker-dashboard-thinned-pending-invitation` | Seeker · two pending invitations | FAMILY visible | small, standard, large, standard 130% text |
| `seeker-dashboard-thinned-unavailable` | Seeker · Guardian source unavailable | top | small, standard, large, standard 130% text |
| `guardian-dashboard-thinned-main-priority` | Main · mixed-role links + one safe priority | top | small, standard, large, standard 130% text |
| `guardian-dashboard-thinned-additional-neutral` | Additional-owned Journey injected · zero leakage | top | small, standard, large, standard 130% text |
| `guardian-dashboard-thinned-empty` | Guardian · no linked Seeker | top | small, standard, large, standard 130% text |
| `guardian-dashboard-thinned-unavailable` | Guardian · Journey source unavailable | top | small, standard, large, standard 130% text |

Versioned candidate manifest:

`SYSTEM/RESOURCES/UI_GATE/CANDIDATES/OA-ZYRA-282_PHASE_3_manifest.json`

- SHA-256: `761a3839255be4a788d370a6093f0950882dac2465155ce9364f5392e2d99999`
- fixture count: **8**
- variant count: **32**
- approval state: all **false**
- automatic promotion: **false**
- approved baselines modified: **false**
- manifest verification: **32/32** file hashes and byte counts match

All eight standard-size states were visually inspected. The final capture
after the truth-state correction reproduced the same 32 candidate hashes.

---

## 7 · OA-ZYRA-281 supersession delta and preservation

Thinning changes only three approved Seeker Today fixture families:

| Approved OA-ZYRA-281 fixture | Phase 3 candidate | Variants |
|---|---|---:|
| `seeker-dashboard-unread` | `seeker-dashboard-thinned-no-guardian` | 4 |
| `seeker-dashboard-resolved-actions` | `seeker-dashboard-thinned-connected` | 4 |
| `seeker-dashboard-home-lower-levels` | `seeker-dashboard-thinned-pending-invitation` | 4 |

Delta: **3 fixtures / 12 variants** await the Founder's supersession ruling.
Those twelve old approved PNGs remain in place and are hash-checked explicitly.
The other **28/40** approved variants continue their normal rendered
comparisons.

| Preservation anchor | SHA-256 | Result |
|---|---|---|
| `SOURCE/test/visual/approved/manifest.json` | `23547aafd1a58d5210a8f6438cd7d680aab48fdc9ef61bb8d87bb33d5863024e` | untouched |
| `SYSTEM/RESOURCES/UI_GATE/BASELINES/manifest.json` | `56cd7f5f3c5f64d044d552a1b013c997d42a8b5e9dc9d06f09959c7b69f17484` | untouched |
| `SYSTEM/RESOURCES/UI_GATE/CANDIDATES/OA-ZYRA-281_PHASE_2_manifest.json` | `c17209b7365cca03488774f9ed7e3ef8031cea3ff4ae4afa0084f7777600c597` | untouched |
| `SYSTEM/RESOURCES/UI_GATE/CANDIDATES/OA-ZYRA-282_PHASE_1_manifest.json` | `37ae445733ede844009743eedfec8e8fdf79feabbed5c8d86a2790b1e57407ea` | untouched |
| `SYSTEM/RESOURCES/UI_GATE/CANDIDATES/OA-ZYRA-282_PHASE_2_manifest.json` | `078353f8d5f37aa65841bda303717aed349a082d6995729ec90345898f79b316` | untouched |
| `SOURCE/lib/widgets/zyra_ward_card.dart` | `9511c9513e891ea9406588d72a4e19272e71a7d9efbdb1ab2e07df62338511b1` | unchanged |
| `SOURCE/lib/screens/wali/seeker_guardian_designs.dart` | `c15b8f3c28f336e8441dd36f5dfcec199b153cc4eb74ead4714c284b7799f01d` | Pulse + four siblings retained |

All **40/40** approved OA-ZYRA-281 PNG hashes and byte counts match their
approved manifest. No baseline promotion occurred.

The visual harness also makes each Guardian Updates fixture establish its own
authorised Seeker context. This removed fixture-order dependence introduced
when the new Today fixtures joined the matrix; it did not alter an approved
pixel.

---

## 8 · True pre-state snapshots and changed-file hashes

The initial existing-file set was copied byte-for-byte immediately before the
first edit at **2026-08-31T11:30:54Z** to:

`/private/tmp/zyra-064-phase3-pre.RbtEms`

The same directory was augmented with the two later-discovered service/page
dependencies immediately before their first edit at **2026-08-31T11:46:18Z**.
These are true pre-files, not reconstructions. The new focused C2 test, the
Phase 3 candidate manifest and all 32 candidate paths were confirmed absent
during the preflight before creation.

| File | True pre SHA-256 | Post SHA-256 |
|---|---|---|
| `SOURCE/lib/models/zyra_dashboard_resolution.dart` | `de688fa3c81d6f5439950b055d7b0c8aa1c38c346683dbac3be0efc1cb9d83ad` | `0d2621779b952992321cf32093fcbfdd77711e659383489a810bc00168c0e900` |
| `SOURCE/lib/screens/wali/wali_dashboard_screen.dart` | `1183791135ec92041f16a091cfe7d24e8ab66063847fe1057fb67764c148f1aa` | `32e6627aba569db4846a063bc1e8e1b5a9de717d072519c545dd73961e30575a` |
| `SOURCE/lib/screens/wali/wali_home_shell.dart` | `c4636662b76be236fbae8fbacdaa97e83bfdcdcd06599e6e27396e6805d22954` | `9671dbac2d9905e9c0206b1ab79d2c24a3ea94d87df80cc71c5a57e820c8bd43` |
| `SOURCE/lib/screens/wali/wali_invite_seeker_screen.dart` | `d6bf15901ed10c87d9b7727101453a32e1692ce4edcc90dfc1132d8d9befc249` | `fd08495a37d1c4d14c5ab89263e9f1ec4ab0c7b109834c7c22cb6c0661d9352f` |
| `SOURCE/lib/screens/wali/wali_journey_detail_screen.dart` | `ce254476106bea83dcbe970320fe07615cbb30bd9d6794f0e69caa36ea770370` | `3ca91dc258a8c4a64da60c97bdfa215f481ab88ee4ee02323cbe3862fc323952` |
| `SOURCE/lib/services/zyra_dashboard_adapter.dart` | `0b0fa4f8077a6498ae604bd490ada9a928f5d0dde7d0d00d812643f2d4a0152c` | `dfa175f2b147fcd498593b87d5073fe36f326c3b9ff354b3c047dd0f92f420eb` |
| `SOURCE/lib/services/zyra_guardian_dashboard_resolver.dart` | `fad8c8ee404731a930d513cf1b1bf68d61333582c1610119a867d91cb7692c85` | `e03fc170a4287d30ac733c928bbf60b16b16bab244d9264299eaa8c4e42b6bce` |
| `SOURCE/lib/services/zyra_journey_service.dart` | `720e80b7c2afedb5e3a52b33312b456175d8d8801540c9f9ff5b654a0534d5e9` | `2107b217d865e3c7e4deb01d9c440091fd1dc75e35429234c6646d573e601e9c` |
| `SOURCE/lib/services/zyra_wali_journey_service.dart` | `63a2260be3c6be5a3087009ad2172597bd759d8185bcfb24b934d34d49af4ba5` | `32e0d6c5f51c5d09bab7d78b132e0f3a10c29b9da4e0aaf398f3cc3e5d3a2bdf` |
| `SOURCE/lib/widgets/zyra_guardian_invitation_dashboard.dart` | `ee391500f9392ff5a95ef7c666cbd3736e176e7360fcf1414eb7ed3b49a82ee9` | `5c8ce47e89e84e945e45d546d6e6a4ed157c4ced5b050d243d0190ec8744ef9f` |
| `SOURCE/lib/widgets/zyra_resolved_dashboard.dart` | `49824e416b35fdb5d00ab22914cd8b313c8de9176f8470b61b4c2b95ea072b0d` | `6f9af00b36ee7760af827a248c0457a617c72c8a7f4c8f0362b67ab65bae200a` |
| `SOURCE/test/dashboard_production_routing_test.dart` | `ebba7a196451de08833894702f6511da5a919d823ad8cc1aa212b1e7b4b28dd1` | `9f8565499a8893e1043a3707668659c00895e592ddbb06478e0afc8f1ccae061` |
| `SOURCE/test/guardian_dashboard_greeting_test.dart` | `a25002d779c79c20a223395d618a16a13dae2d7ecdf5cd4ac25440c0e98b7cd4` | `e3d7d88794f6718536308be673c7090ea28fc4e2d9e77d630b74a354652d8161` |
| `SOURCE/test/guardian_dashboard_resolver_test.dart` | `fdf797cf6b113cae17112bd5e31dedc5936a5a5ea7cf350561033f41d68698f7` | `0df0a399042c627cba3b127c3d6a1008ff3d63f40d2a617f7fc731da36cf0f55` |
| `SOURCE/test/guardian_invitation_dashboard_test.dart` | `522d3f5f99c71a224157823f43e6b5388356795df39a869d4fd5136a434fe53f` | `4d5bab3de8e43a8c2cc2c658b61be53d6f41dc8f96b083ce178bf207a3183b83` |
| `SOURCE/test/seeker_dashboard_screen_test.dart` | `67a7a8c6c06c4609e702278cb93babdf3f2e15faf4fe8273232fb226fa5fceea` | `decefea0b3b827ee105bb7f4a607f911100fda679a5f5ff6f27660eae7e81f57` |
| `SOURCE/test/visual/zyra_visual_regression_test.dart` | `22b6c2269d28a363a92f46a102dd444bf2ba7b770de3648b6704f662a81d6c9d` | `8bcbeefd1c5e10d1856788ef06af1f1ab2588a225629d61b5b358f055b3cfa87` |
| `SOURCE/test/zyra_dashboard_adapter_test.dart` | `484ef5c337cad065b371dba2fa6196e9e8e6fc75d59590f553b5da8a69a90c23` | `a027e38013dcf40b2891a7b5a6e5524a94fc2618ecc81fe82230b982a30a35e3` |
| `SOURCE/test/wali_journey_detail_truth_test.dart` | **ABSENT** | `91780f4ce1173ad08cb3dc4c0bd1e0329c5d79daca2a7278629a34bb16691e37` |
| `SYSTEM/RESOURCES/UI_GATE/CANDIDATES/OA-ZYRA-282_PHASE_3_manifest.json` | **ABSENT** | `761a3839255be4a788d370a6093f0950882dac2465155ce9364f5392e2d99999` |

The 32 PNG candidate files were absent before Phase 3. Their individual
post-edit SHA-256 values and byte counts are recorded in the versioned
manifest above. That ledger is incorporated here by reference so every
changed candidate file has an exact hash record without duplicating 32 rows.

The 064 report path was confirmed absent at
**2026-08-31T13:03:22Z** before this filing.

---

## 9 · Verification results

| Check | Result |
|---|---|
| focused Guardian Dashboard widget suite | PASS — **13/13** |
| focused Wali Journey-detail truth suite | PASS — **5/5** |
| scoped Phase 3 candidate capture | PASS — **32/32**, approved directory untouched |
| Phase 3 candidate manifest hash/byte verifier | PASS — **32/32** |
| complete visual regression suite | PASS — **334/334** |
| OA-ZYRA-281 approved hash/byte verifier | PASS — **40/40** |
| `flutter test --no-pub` | PASS — **861/861** |
| `flutter analyze --no-pub` | PASS — no issues |
| `python3 tools/zyra_check.py` | PASS — **185 files, 0 findings**; five baselined dangling references, zero new |
| `python3 -m unittest tools/test_zyra_check.py` | PASS — **1/1** |
| scoped Dart format check over all 19 changed Dart/test files | PASS — zero changes |
| applied Phase 0 migration hash + migration count | PASS — frozen hash, **208** files |

The repository-wide formatting audit still identifies only the pre-existing,
untouched `test/zyra_dashboard_updates_migration_test.dart` formatting drift
already carried into prior phases. It was not formatted or edited; current
hash:

`bbbb0c03e7c9977215c741d316574be1dd9bec717f51829f135f362fd33b45c4`

The full suite's normal developer-preview diagnostics about an uninitialised
Supabase test instance remain non-failing test output.

The only test-only routing adjustment replaces one fixed Dashboard drag with
`ensureVisible`: thinning shortened the page, so the old geometry-dependent
gesture could move the target outside the cache. The route assertion and
production behaviour are unchanged.

---

## 10 · Scoped challenges and dispositions

### C1 — open-review failure could manufacture a calm Dashboard

The Phase 3 compact priority and needs-you aggregate cannot be truthful when
the batched Family Review query silently returns an empty set after failure.
Leaving the bridge in production would violate EMPTY ≠ FAILED and could
misstate a current Guardian obligation.

Disposition: corrected inside the Dashboard thinning boundary with a typed
result, unavailable + Retry, and retained-last-known behaviour. Query shape,
RLS, Main-only authority and visual design are unchanged. A focused regression
proves the failure cannot render “Nothing needs you.”

No other material defect, disagreement or scope deviation remains open in
Phase 3.

---

## 11 · Boundaries reconfirmed

- Five-tab Guardian shell structure/order: unchanged.
- Pulse + four sibling designs: retained.
- Phase 1 Manager and Phase 2 roster/workspace ownership: retained.
- Dashboard roster/invitation-cancel/role-management ownership: removed.
- Approved baseline promotion: none.
- Approved PNG regeneration: none.
- Schema/migration files: none changed or added.
- Applied Phase 0 migration: byte frozen.
- Live Supabase reads/writes/DDL: none performed by Codex.
- New server surface or data source: none.
- `score_candidates`: untouched.
- Release fixtures: none added to production code.
- Git: not used.
- Self-approval: not claimed.

The production UI continues to use real typed service adapters. All fixture
composition and candidate capture remain in test/visual code and candidate
assets.

---

## 12 · Forward and reverse gates

### Forward

1. Fable independently verifies 064, post hashes, source ownership,
   authority-first aggregation, truth-state behaviour, candidate manifest and
   full gate results.
2. Fable assembles the programme-complete package after a verified PASS.
3. The Founder performs the single final visual inspection across Manager,
   detail, roster, workspaces and thinned Dashboards.
4. Only Founder acceptance may promote candidates, rule the twelve-variant
   supersession, authorize Pulse/sibling cleanup and close OA-ZYRA-282.

### Reverse evidence

The exact pre-files in `/private/tmp/zyra-064-phase3-pre.RbtEms` are the
reverse anchors for every modified existing source/test file. A governed
reverse would restore those bytes, remove only the new focused C2 test,
remove only the 32 Phase 3 candidate PNGs and their Phase 3 manifest, and
leave all Phase 0/1/2 and OA-ZYRA-281 assets untouched. No reverse action was
performed.

— Codex, 2026-08-31
