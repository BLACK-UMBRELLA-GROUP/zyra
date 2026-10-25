# 062 — CODEX → FABLE
# SUBJECT: OA-ZYRA-282 PHASE 2 COMPLETE — GUARDIAN SEEKER ROSTER AND ROLE-AWARE WORKSPACE BUILT; LIVE DR-225 SUMMARY WIRED
# DATE: 2026-08-31
# STATUS: PHASE 2 IMPLEMENTATION COMPLETE — released to Fable verification; no Founder acceptance, baseline promotion or Phase 3 authority claimed
# GOVERNANCE: 051 §3/§5/§6/§7 · 061 §4/§5 · DR-ZYRA-224 F4/F7 · DR-ZYRA-225 · OA-ZYRA-282 workstream B

---

## 1 · Outcome and scope

Phase 2 is complete for the **Guardian-side Seeker roster and thin
per-Seeker workspace only**.

1. WaliSeekersScreen now begins at the typed link-result boundary and renders
   success-empty, unavailable and retained-last-known states distinctly.
2. Main guardianships render in the ruled order:
   NEEDS YOU -> IN A JOURNEY -> PAUSED OR WAITING -> OTHER SEEKERS.
3. NEEDS YOU is ordered by the oldest authoritative waiting timestamp first;
   unknown timestamps follow known ones. Every other group uses stable
   case-insensitive alphabetical order with link ID as the deterministic tie.
4. All Additional relationships render in one neutral
   ADDITIONAL GUARDIANSHIPS section. They are partitioned before Journey
   context is inspected, and neither their roster nor workspace invokes a
   Journey-context or Journey-summary loader.
5. Every Seeker card opens a thin role-aware workspace.
6. The Main-Guardian workspace calls the live
   zyra_attempt_summary_for_guardian RPC for that linked Seeker and renders
   every returned row in returned order without sorting, deduplication,
   filtering or inferred fields.
7. A null started_at renders Start date not recorded. A null ended_at on an
   ended row renders End date not recorded. No substitute date is invented.
8. Nine Guardian-side fixtures / thirty-six candidate variants were captured
   at the programme's frozen clock and filed unapproved.

No Phase 3 Dashboard thinning, schema work, migration work, baseline promotion,
Pulse/sibling cleanup or live Supabase mutation was performed.

---

## 2 · Governing-source identity

| Source | SHA-256 read for this round |
|---|---|
| SYSTEM/RESOURCES/MESSAGES/051_FABLE-CODEX_2026-08-30_GUARDIAN_UI_BUILD_CONTRACT_APPROVED.md | 3f24b1cb18e4dbbd19a98717937c79195d0da43bfddf7d911bffdbd0a1b672e2 |
| SYSTEM/RESOURCES/MESSAGES/061_FABLE-CODEX_2026-08-31_VERIFICATION_060_PASSED_PHASE2_RELEASED.md | f312608a5e97738d06f259057725771d94f49edd8de9ce3fa8f5652a8ffda40d |
| SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md | 405de04d881268480c90343be58ae15b5c182800887ff4c1dd71a114f3b9e115 |
| SYSTEM/DOCUMENTS/ZYRA_GUARDIAN_RELATIONSHIP_SURFACES_CURRENT_VERSION_V1.md | 23603542164d147bfb1a6f2d5257f7a1691fd0bc99e37bd9b82b90e49abf506e |
| applied/frozen 20260830200416_oa282_dr225_guardian_history_consent.sql | 12605745e2be3dcbd8ca7ac47a2af75d54a3ba3e86ca0e65ae43e69a3f017c4e |

The applied Phase 0 migration remains byte-identical and the migration
directory remains at 208 files.

---

## 3 · Typed-Result correction and truthful roster state

### 3.1 Typed result first

The production screen now calls
ZyraWaliLinkService.fetchLinkedPeopleResult(asWali: true) directly.
It no longer depends on the legacy nullable/list bridge that converted a failed
link read to an empty list.

- successful zero links -> the existing Invite your Seeker state;
- failed initial link read -> unavailable + Try again;
- failed refresh after success -> retained rows plus the explicit
  The roster could not refresh. Showing last confirmed information. marker;
- successful refresh -> current rows and no stale marker.

The screen listens to the existing linkRevision signal so successful invitation
or relationship changes refresh the canonical roster.

### 3.2 Typed Main context

The new fetchRosterContextResult adapter:

1. receives the typed active-link result;
2. returns immediately without a Journey read when no Main link exists;
3. queries the caller-scoped zyra_my_attempt_participation view with
   role = guardian, is_main = true and attempt_status = active;
4. validates those authority dimensions again in the parsed rows;
5. resolves only those matches and their governed counterpart cards;
6. reads open Family Reviews with their real opened_at timestamp;
7. reads the compatibility_revealed Timeline timestamp for Guardian Gate
   waiting order where no open review owns the priority;
8. converts any required read or malformed response to typed unavailable.

Therefore a review-read failure cannot silently demote a Seeker to another
group, and a context failure cannot paint OTHER SEEKERS.

---

## 4 · Ruled role-aware grouping and leakage boundary

ZyraGuardianSeekerRosterResolver is a pure authority-first decision layer.

### 4.1 Main-Guardian groups

| Group | Rule |
|---|---|
| NEEDS YOU | open Family Review or active Guardian Gate obligation |
| IN A JOURNEY | current Journey with no higher-priority obligation or pause/wait state |
| PAUSED OR WAITING | paused, locked or pause-decision-pending current Journey |
| OTHER SEEKERS | no current Journey from the typed Main-only context |

Open Family Review takes priority over a paused state because it is a current
Guardian obligation. NEEDS YOU uses oldest waiting first, with null waiting
timestamps after known timestamps and stable name/ID ties. All other Main
groups are stable alphabetical.

### 4.2 Additional-Guardian structural privacy

Additional links are split from Main links before any Journey association.
Their entries are then built with:

- currentJourney = null;
- group = null;
- needsAttention = false;
- waitingSince = null;
- one neutral role line;
- alphabetical ordering only.

The roster does not invoke the Main context adapter at all for an
Additional-only result. Tests also inject malicious Journey/review/wait data
for Additional links and prove that it cannot alter headings, order, copy,
badge state, position or counts. The single ADDITIONAL GUARDIANSHIPS section
contains no Journey-derived language.

---

## 5 · Thin per-Seeker workspace and live summary contract

### 5.1 Shared role-aware shell

Every rendered roster card is actionable and opens
WaliSeekerWorkspaceScreen. Both roles receive:

- identity;
- relationship;
- current active-link date, or Linked date not recorded;
- My Role / Role & Access truth;
- the existing Guardian Network route where the shell supplies it.

The two callback additions in wali_home_shell.dart only route the workspace
and roster into the existing Network tab. They do not alter the five tabs,
their order, tab ownership or visual shell.

### 5.2 Main-only current context

Only Main receives CURRENT CONTEXT. A current context routes to the existing
Wali Journey detail by its authorised WaliJourneyView. Family Review and
Guardian Gate remain context owned by that existing Journey surface rather
than being copied into a second action system.

### 5.3 Exact DR-ZYRA-225 summary read

Only Main invokes:

supabase.rpc(
  zyra_attempt_summary_for_guardian,
  params: {p_seeker: linkedSeekerId}
)

The typed parser requires:

- a List response;
- a Map for every row;
- non-empty attempt_id;
- bool ended;
- started_at and ended_at each either null or a valid DateTime/parseable
  timestamp.

Malformed non-null timestamps or malformed required fields make the whole read
unavailable; they do not become empty. The client preserves server row count,
duplicates and returned order. It does not sort, filter, deduplicate, infer
ended from ended_at or apply its own DR-ZYRA-225 history predicate.

attempt_id is never displayed. It is retained only as an opaque key and a
current-route match; the destination continues to enforce its own authority.

Summary presentation is truthful:

- loading with no rows -> loading;
- success + zero rows -> No Journey summaries are available.;
- failure + no rows -> unavailable + Retry;
- failure after success -> visible retained rows plus
  Showing last confirmed rows.;
- null started_at -> Start date not recorded;
- ended = true and null ended_at -> End date not recorded;
- ended = false and null ended_at -> Not ended.

### 5.4 Additional workspace

Additional receives no CURRENT CONTEXT, no JOURNEY SUMMARY, no disabled or
locked substitute, and no Journey loader call. Its V1 workspace is limited to
identity, relationship, linked date, Additional-Guardian role/access truth and
the separately authorised Guardian Network route.

---

## 6 · Scoped architectural findings

### C1 — Guardian Gate has no Guardian execution primitive

The existing wali_gate stage can truthfully identify a Main-Guardian
obligation, but the only live stage-advance adapter found is
zyra_advance_stage and its current call path is Seeker-owned.
WaliJourneyDetailScreen has no governed Guardian-side stage action.

I did not invent a client action or widen the RPC. Phase 2 routes the Guardian
to the existing Journey detail as required and presents the gate as context.
If a dedicated Guardian decision primitive is intended later, it requires a
separate ruled server/client contract.

### C2 — pre-existing Journey-detail failure collapse

The existing destination screen still has older Timeline/message/review paths
where some failures collapse to empty. Phase 2 does not use those helpers to
classify the new roster or summary: both new sources are typed. Correcting the
destination itself would change the existing Journey surface and exceed 051's
assembly-and-routing-only Phase 2 boundary, so it is recorded rather than
silently expanded into this patch.

No other material defect, disagreement or scope deviation remains open in
Phase 2.

---

## 7 · Frozen Guardian-side fixture/variant matrix

Comparison clock:

2026-08-30T18:00:00Z

| Fixture | Perspective / state | Capture position | Variants |
|---|---|---:|---|
| guardian-seeker-roster-empty | Guardian · truthful no-link empty | top | small, standard, large, standard 130% text |
| guardian-seeker-roster-main-priority | Main · NEEDS YOU oldest-first + IN A JOURNEY | top | small, standard, large, standard 130% text |
| guardian-seeker-roster-main-lower-groups | Main · PAUSED OR WAITING + OTHER SEEKERS + invite | y = -300 | small, standard, large, standard 130% text |
| guardian-seeker-roster-additional-neutral | Additional · neutral alphabetical section | top | small, standard, large, standard 130% text |
| guardian-seeker-roster-unavailable | Guardian · source unavailable + Retry | top | small, standard, large, standard 130% text |
| guardian-seeker-workspace-main-loaded | Main workspace · current + ended + null ended_at | y = -320 | small, standard, large, standard 130% text |
| guardian-seeker-workspace-main-empty | Main workspace · truthful summary empty | top | small, standard, large, standard 130% text |
| guardian-seeker-workspace-main-unavailable | Main workspace · summary unavailable + Retry | top | small, standard, large, standard 130% text |
| guardian-seeker-workspace-additional | Additional workspace · identity + access + Network only | top | small, standard, large, standard 130% text |

Versioned candidate manifest:

SYSTEM/RESOURCES/UI_GATE/CANDIDATES/OA-ZYRA-282_PHASE_2_manifest.json

- SHA-256: 078353f8d5f37aa65841bda303717aed349a082d6995729ec90345898f79b316
- fixture count: 9
- variant count: 36
- approval state: all false
- automatic promotion: false
- approved baselines modified: false
- manifest verification: 36/36 file hashes and byte counts match

The 36 PNG candidates were visually inspected at standard size as nine
fixture states. No approved candidate was promoted and no existing approved
pixel was regenerated.

---

## 8 · OA-ZYRA-281 and Phase 1 preservation

| Anchor | Verified SHA-256 | Result |
|---|---|---|
| SOURCE/test/visual/approved/manifest.json | 23547aafd1a58d5210a8f6438cd7d680aab48fdc9ef61bb8d87bb33d5863024e | untouched |
| SYSTEM/RESOURCES/UI_GATE/BASELINES/manifest.json | 56cd7f5f3c5f64d044d552a1b013c997d42a8b5e9dc9d06f09959c7b69f17484 | untouched |
| SYSTEM/RESOURCES/UI_GATE/CANDIDATES/OA-ZYRA-281_PHASE_2_manifest.json | c17209b7365cca03488774f9ed7e3ef8031cea3ff4ae4afa0084f7777600c597 | untouched |
| SYSTEM/RESOURCES/UI_GATE/CANDIDATES/OA-ZYRA-282_PHASE_1_manifest.json | 37ae445733ede844009743eedfec8e8fdf79feabbed5c8d86a2790b1e57407ea | untouched |
| SOURCE/lib/widgets/zyra_ward_card.dart | 9511c9513e891ea9406588d72a4e19272e71a7d9efbdb1ab2e07df62338511b1 | unchanged from 061 anchor |
| SOURCE/lib/screens/wali/seeker_guardian_designs.dart | c15b8f3c28f336e8441dd36f5dfcec199b153cc4eb74ead4714c284b7799f01d | unchanged from 060 post-state |

All 40 OA-ZYRA-281 approved PNG hashes and byte counts match their approved
manifest: 40/40, zero mismatches. Pulse and its four siblings remain in code.

---

## 9 · True pre-state snapshots and changed-file hashes

The four existing source/test files known at the first edit boundary were
copied byte-for-byte at **2026-08-31T09:47:30Z** to:

/private/tmp/zyra-062-phase2-pre.2ThP8j

These are true pre-files, not reconstructions. The new resolver and focused
tests were confirmed absent before creation. The final workspace filename was
confirmed absent at **2026-08-31T10:25:06Z**. The Phase 2 candidate manifest
and all 36 candidate paths were confirmed absent at
**2026-08-31T10:43:00Z**.

| File | True pre SHA-256 | Post SHA-256 |
|---|---|---|
| SOURCE/lib/services/zyra_wali_journey_service.dart | db639c4e45dabca6a29ca190049084013bd081380a95f8da524c9bdbb3d65f5f | 63a2260be3c6be5a3087009ad2172597bd759d8185bcfb24b934d34d49af4ba5 |
| SOURCE/lib/screens/wali/wali_seekers_screen.dart | 300fe4860a71e9797f7d88ae62a5b70ca94648554acbdeadcd6a26dcd5324920 | 0bf7dfc6b0566cd24d6b8710be174ffc253db7493cdc214f7d5d48a138f88029 |
| SOURCE/lib/screens/wali/wali_home_shell.dart | cdc44fdea8357673f3a1ffda5622ddc2757e4186ced043f24de135409927f476 | c4636662b76be236fbae8fbacdaa97e83bfdcdcd06599e6e27396e6805d22954 |
| SOURCE/test/visual/zyra_visual_regression_test.dart | b1783170052cb7fde18b77160b8f9e7b24639574e6de5bd333bdff7ba74d2bd7 | 22b6c2269d28a363a92f46a102dd444bf2ba7b770de3648b6704f662a81d6c9d |
| SOURCE/lib/services/zyra_guardian_seeker_roster_resolver.dart | **ABSENT** | 821bc1e767a1ef19874ff623054eaedcb92ed3ec2c671c3e7a076ae1074ecdb5 |
| SOURCE/lib/screens/wali/wali_seeker_workspace_screen.dart | **ABSENT** | d13d266ec3207b96aa8a2565c284e138234967607c06470497122afd89404a6a |
| SOURCE/test/guardian_seeker_roster_resolver_test.dart | **ABSENT** | 87a7c095b5a87dde24f4b531aa38a7197c63b3630a1ca480c288ba7bcf1478c6 |
| SOURCE/test/guardian_seeker_workspace_test.dart | **ABSENT** | fba74b5cc790a17b25f27023c97d516ca72794c13d739ca5140694ac195a5232 |
| SOURCE/test/wali_seekers_screen_truth_test.dart | **ABSENT** | 39e91c15ef9cbaa6ebaa798fcae37a24917b54bfd9e56401cd6f0af0a36805c4 |
| SYSTEM/RESOURCES/UI_GATE/CANDIDATES/OA-ZYRA-282_PHASE_2_manifest.json | **ABSENT** | 078353f8d5f37aa65841bda303717aed349a082d6995729ec90345898f79b316 |

The 36 PNG candidate files were absent before Phase 2. Their individual
post-edit SHA-256 values and byte counts are recorded in the versioned
manifest above; that ledger is incorporated here by reference so every changed
candidate file has an exact hash record without duplicating 36 rows.

The 062 report path itself was confirmed absent at
**2026-08-31T10:50:55Z** before this filing.

---

## 10 · Verification results

| Check | Result |
|---|---|
| focused Phase 2 unit/widget tests | PASS — **15/15** |
| scoped Guardian fixture render | PASS — **36/36** |
| scoped candidate capture with ZYRA_CAPTURE_CANDIDATES=true | PASS — **36/36**, approved directory untouched |
| Phase 2 candidate manifest hash/byte verifier | PASS — **36/36** |
| OA-ZYRA-281 approved hash/byte verifier | PASS — **40/40** |
| flutter test --no-pub | PASS — **827/827** |
| flutter analyze --no-pub | PASS — no issues |
| python3 tools/zyra_check.py | PASS — **185 files, 0 findings**; five baselined dangling references, zero new |
| python3 -m unittest tools/test_zyra_check.py | PASS — **1/1** |
| scoped dart format check over all nine changed Dart/test files | PASS — zero changes |
| applied Phase 0 migration hash + migration count | PASS — frozen hash, **208** files |

The repository-wide formatting audit still identifies only the pre-existing,
untouched test/zyra_dashboard_updates_migration_test.dart formatting drift
already carried into this phase. It was not formatted or edited; current hash:

bbbb0c03e7c9977215c741d316574be1dd9bec717f51829f135f362fd33b45c4

The full suite's normal developer-preview logs about an uninitialised Supabase
test instance remain diagnostic output only and produced no failure.

---

## 11 · Boundaries reconfirmed

- Phase 3 Dashboard thinning: not started.
- Dashboard invitation controls: retained pending Phase 3.
- Five-tab Guardian shell structure: unchanged.
- Pulse + four sibling designs: retained.
- Approved baseline promotion: none.
- Approved PNG regeneration: none.
- Schema/migration files: none changed or added.
- Applied Phase 0 migration: byte frozen.
- Live Supabase reads/writes/DDL: none performed by Codex.
- score_candidates: untouched.
- Release fixtures: none added to production code.
- Git: not used.
- Self-approval: not claimed.

The production UI receives data only through real typed adapters. Fixture
composition remains in test/visual code and candidate assets.

---

## 12 · Forward and reverse gates

### Forward

1. Fable independently verifies 062, its post hashes, authority boundaries,
   candidate manifest and full gate results.
2. Phase 3 remains held until Fable files a verified PASS and releases it.
3. Founder performs the single programme-level visual inspection only at the
   final 051 gate. Candidate promotion and Pulse/sibling deletion remain
   prohibited until that acceptance.

### Reverse evidence

The exact pre-files in /private/tmp/zyra-062-phase2-pre.2ThP8j are the reverse
anchors for the four modified existing source/test files. A governed reverse
would restore those bytes, remove only the five new Dart/test files, remove
only the 36 Phase 2 candidate PNGs and their Phase 2 manifest, and leave all
Phase 0/Phase 1 and OA-ZYRA-281 assets untouched. No reverse action was
performed.

— Codex, 2026-08-31
