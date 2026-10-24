# TO: Fable / Architecture Reviewer
# FROM: Codex / Lead Architect
# SUBJECT: OA-ZYRA-281 — live Dashboard Updates client wiring complete; verification requested

## 1 · Completion status

The authorised 043 client-wiring scope is **CODE COMPLETE**.

Both production Dashboard Updates tabs now consume
`public.zyra_dashboard_updates` through one shared client reader. The former
Seeker notification/Guardian-activity assembly and Guardian per-Journey
Timeline assembly no longer feed Dashboard Updates. Success with rows,
success with zero rows and failure remain distinct; retained rows are visibly
last-known; `TRUE`/`NULL` unread presentation is preserved; all live template
keys are covered; unknown keys fail closed; and Guardian person context comes
only from the already-authorised Journey roster through `related_match_id`.

This is an implementation completion report, not self-approval. Fable
verification and the Founder's single final visual inspection remain pending.

## 2 · Authority and boundaries observed

Authority executed:

- `043_FABLE-CODEX_2026-08-30_MIGRATION_APPLIED_VERIFIED_WIRING_AUTHORISED.md`
- DR-ZYRA-216, DR-ZYRA-217, DR-ZYRA-222 and DR-ZYRA-223
- the live, Fable-verified migration source
  `20260830145711_oa281_dashboard_updates_projection.sql`

Boundaries held:

- no schema change and no new migration;
- live migration source unchanged;
- no Insight store or production Guardian Insight family;
- `score_candidates` untouched;
- no git operation;
- no candidate auto-promotion or baseline approval; and
- no self-approval.

## 3 · Change surface

### 3.1 Shared reader and contract

New `ZyraDashboardUpdatesService`:

- calls `zyra_dashboard_updates` with `p_limit` plus all three cursor parts;
- clamps requested pages to 1–20;
- represents a keyset cursor as one object, making a partial cursor
  unrepresentable in normal client code;
- parses the whole returned page atomically—one malformed row makes the read
  unavailable instead of rendering a misleading partial page;
- preserves `bool? isUnread` without coercion;
- maps every title/detail/destination key emitted by the applied migration;
- maps any unknown key combination to one generic, non-navigable row; and
- exposes the same typed page to both roles.

### 3.2 Seeker

- `ZyraSeekerDashboardAdapter.load` starts one Updates RPC beside the other
  independent Dashboard reads.
- `DashboardSnapshot` has one `updates` source; the former `notifications` and
  `guardianActivity` Updates contributors are removed.
- the resolver computes Updates health from that one source, so the RPC cannot
  create branch-level `partial`.
- a failed refresh retains prior rows only through
  `DashboardResolution.retainUpdatesFrom`, with explicit last-known UI.
- the former notification and Guardian-activity assemblers are absent from the
  production Dashboard adapter. Unread totals and Guardian links remain only
  for their separate MY ZYRA / Family responsibilities.

### 3.3 Guardian

- `WaliDashboardScreen` makes one Updates RPC, not one Timeline request per
  Journey.
- a successful empty RPC clears old rows; a failed RPC keeps prior rows and
  renders `Couldn't refresh Updates — showing last-known rows.`
- Guardian Today no longer contains the retired recent-movement assembly;
  movement remains exclusive to Updates.
- `related_match_id` is matched against `_journeys`; only the matched
  authorised `linkedSeekerName` prefixes the rendered row.
- notifications route to the existing Notifications tab callback; a matched
  Journey row opens that exact Journey; an unresolved or unknown destination
  has no guessed navigation.

## 4 · Health, unread and fail-closed evidence

| Contract | Implementation evidence | Test evidence |
|---|---|---|
| success + rows → available | typed non-null page maps to `DashboardSource.available` / Guardian rows | adapter, resolver and both role widget tests |
| success + zero → empty | non-null empty page replaces old rows | Seeker and Guardian successful-empty tests/candidates |
| failure → unavailable | null page maps to unavailable; never empty | both role failure tests |
| no branch partial | resolver receives one Updates source | pure resolver test |
| retained rows visibly stale | Seeker `LAST-KNOWN UPDATES`; Guardian last-known banner | role refresh tests + eight role/device candidates |
| TRUE unread | purple unread affordance + unread semantics | Seeker and Guardian widget tests |
| NULL unread | no read-state affordance or read label | parser and both role widget tests |
| all emitted keys covered | migration-key extraction checks the closed renderer | service static contract test |
| unknown key fail-closed | generic copy, target `none`, no person prefix | service unit test |
| malformed page fail-closed | one invalid row makes page null | service unit test |

## 5 · Replace-not-parallel evidence

The structural test reads both production files and proves:

- Seeker contains `ZyraDashboardUpdatesService.fetchPage()`;
- Guardian contains `ZyraDashboardUpdatesService.fetchPage`;
- Seeker contains no `fetchRecent(` and no `fetchActivityResult(`; and
- Guardian contains no `fetchTimelineResult(`.

The Timeline service, Notification service and Guardian-activity service were
not deleted because their owning non-Dashboard surfaces still use them.

## 6 · Guardian context evidence

The focused Guardian test loads an authorised Journey whose linked Seeker is
`Maryam`, then supplies a projection row with that Journey's
`related_match_id`. The rendered row is `Maryam · Journey milestone`; the
counterpart name is not used. Rows without a matching authorised Journey
render without a person prefix.

The live multi-Seeker probe used a Main Guardian with 12 active Main-Guardian
links and 6 caller participation rows. The first page contained 20 rows across
3 related matches (15 milestones, 4 opened reviews, 1 direct notification)
and zero `guardian.suggestion` rows.

## 7 · Live wiring-gate performance evidence

All probes were read-only against the live applied function. Caller identity
was set transaction-locally and every transaction was rolled back.

### 7.1 Full function

| Caller case | Representative cardinality | `EXPLAIN (ANALYZE, BUFFERS)` |
|---|---|---|
| Long-Journey Seeker | 3 authorised participations; 16 authorised milestones; 20 returned domain rows | 19.543 ms; 1,956 shared hits; 0 reads; 0 temp blocks |
| Multi-Seeker Main Guardian | 12 linked Seekers; 6 authorised participations; 20 rows; 3 related matches | 14.986 ms; 1,958 shared hits; 0 reads; 0 temp blocks |

The function-level PL/pgSQL plan is a Function Scan, so branch shapes were
also explained directly with the same caller-scoped predicates.

### 7.2 Branch shapes

Current live source cardinality is 7 notifications, 23 Timeline milestones,
1 Guardian suggestion, 4 Family Reviews and 0 review responses.

| Branch | Actual result |
|---|---|
| unread notification | 0.095 ms; 7-row table |
| Seeker suggestion | 0.089 ms; 1-row table |
| authorised milestone | 0.583 ms; 16 returned from 23 rows |
| authorised review-open | 0.433 ms; 4 returned from 4 rows |
| authorised review-response | 0.108 ms; successful empty from 0 rows |

At these tiny table sizes the normal planner prefers small sequential scans
for several branches. For index-eligibility evidence only, a second read-only
`EXPLAIN` set disabled sequential scans transaction-locally. It selected:

1. `notifications_dashboard_updates_unread_idx`
2. `wali_suggestions_dashboard_updates_seeker_idx`
3. `timeline_milestones_dashboard_updates_idx`
4. `journey_family_reviews_dashboard_updates_idx`
5. `journey_family_review_responses_dashboard_updates_idx`

The same plans selected caller-keyed match/attempt indexes for participation
joins. Notification and suggestion branches have direct caller predicates;
Timeline and review families preserve caller participation through
`attempt_id + match_id` before their rows can be presented. No branch can
authorise an unbounded cross-user result. The tiny normal-planner sequential
scans are recorded rather than misreported as index scans.

### 7.3 Keyset pages and sort bound

Four consecutive live pages at limit 5 returned 5 / 5 / 5 / 5 rows. Across
the 20 rows there were 20 distinct `(class_key, source_id)` pairs; all pages
were disjoint. The client unit test separately proves that the exact last-row
three-part cursor is sent on page 2.

`p_limit` remains server- and client-clamped to 20, bounding the final
Dashboard return and sort output. Both representative full calls used no temp
spill. No numerical Dashboard latency budget is stated in 043 or the
governing Dashboard documents; I therefore record the measured
14.986–19.543 ms server execution without inventing a pass threshold.

## 8 · Fixture manifest

Manifest:

`SYSTEM/RESOURCES/UI_GATE/CANDIDATES/OA-ZYRA-281_PHASE_2_manifest.json`

Post hash:

`e57ce8b5173b97afc4f5fc4dbe06532e4239adc6ccfcd7d3abd42f2082799389`

The production review set is now 10 fixtures × 4 variants = **40**:

- retained/refreshed Seeker Today, resolved-action, lower-level,
  Updates-populated, Updates-empty and Insights-empty fixtures;
- new Seeker Updates last-known fixture; and
- new Guardian Updates populated, empty and last-known fixtures.

All 40 entries are `approved:false`; `automatic_promotion_allowed=false`;
device acceptance remains pending. The 24 previously existing PNGs rerendered
byte-identically to their true pre-snapshot hashes. The 16 new variants were
absent pre-edit and are individually hashed in the manifest. No approved
baseline was changed.

## 9 · Verification results

| Check | Result |
|---|---|
| Focused wiring/resolver/role/migration suite | PASS — **101/101** |
| Full Flutter suite | PASS — **724/724** |
| `flutter analyze --no-pub` | PASS — no issues |
| `python3 tools/zyra_check.py` | PASS — 0 findings across 183 files |
| Direct visual suite | PASS — **248/248** |
| Candidate capture | PASS — **40/40** |
| Visual inspection by Codex | populated and last-known standard renders checked for both roles |

## 10 · True pre/post hashes

True pre-files were copied at edit time to
`/private/tmp/oa281_wiring_pre_20260830`; reconstructed files are not used as
audit anchors.

| File | True pre SHA-256 | Post SHA-256 |
|---|---|---|
| `SOURCE/lib/dev/zyra_dashboard_dev_adapter.dart` | `73c15032fd17645bca7834e06af9f31605effa70c6b3f9b24f6a7940e036e21c` | `ceb2d51d009e411b1cba86b7cac77e1229a16c4358a1bd9006bf87ff11fdd655` |
| `SOURCE/lib/models/zyra_dashboard_resolution.dart` | `48e910f7f8a77c2e20b8595653efe0d6990018300494ede16ebd9852d3348efb` | `de688fa3c81d6f5439950b055d7b0c8aa1c38c346683dbac3be0efc1cb9d83ad` |
| `SOURCE/lib/screens/home/seeker_dashboard_screen.dart` | `a679d42639324111c5bbe9f668b2bf3968c21752c796a8bc37f4cd3b498ca3d8` | `1dc4f38bee1de262671d58250005e5b1cb6ffe7db236adbe69a52b7b553a3f5e` |
| `SOURCE/lib/screens/wali/wali_dashboard_screen.dart` | `19cfa94340f786a8bc6d41b923a0833c8873f82167043a297a9cad4724e4ca61` | `26c687d954be33a9600bb69fae7436a700a35b2408d7567a2a1b2482d1053411` |
| `SOURCE/lib/screens/wali/wali_home_shell.dart` | `be471916d669aaa95d4feb28a5d7d6bb62f7e7808559781cf82b98491a9d34a4` | `cdc44fdea8357673f3a1ffda5622ddc2757e4186ced043f24de135409927f476` |
| `SOURCE/lib/services/zyra_dashboard_adapter.dart` | `1ebf7797f8b958fbdb2767a0c8c669e4fcc7c05daa5e468c593145f27d87b4f0` | `0b0fa4f8077a6498ae604bd490ada9a928f5d0dde7d0d00d812643f2d4a0152c` |
| `SOURCE/lib/services/zyra_dashboard_updates_service.dart` | **ABSENT** | `839aaf931fd4498349eef74a8c03880315c91b3c915f776d6ed74663eed039de` |
| `SOURCE/lib/widgets/zyra_dashboard_experience.dart` | `c5d6e2e8b0bcf1473008c4d5e37eb338692c7b59e4a03bb3beeb90e7124d92e5` | `501acc4951f8f4f4079637ad8ae1ec5e0f7804b8b5d92735435265a30eeb0ec6` |
| `SOURCE/lib/widgets/zyra_resolved_dashboard.dart` | `b23afa1899d2568ef548225766b49237f0b55bb718266ef9a4207b7fbc0bbef2` | `49824e416b35fdb5d00ab22914cd8b313c8de9176f8470b61b4c2b95ea072b0d` |
| `SOURCE/test/dashboard_production_routing_test.dart` | `c53570d288ea8170f84dd3b77bbaec6919be7cb787606e5b035006ed3d5b6d32` | `ebba7a196451de08833894702f6511da5a919d823ad8cc1aa212b1e7b4b28dd1` |
| `SOURCE/test/guardian_dashboard_greeting_test.dart` | `82830a496c9d4c5dbbec9ddbc2dc67cd6873be4527d170a30c2012b3f803aa53` | `a25002d779c79c20a223395d618a16a13dae2d7ecdf5cd4ac25440c0e98b7cd4` |
| `SOURCE/test/seeker_dashboard_screen_test.dart` | `ec3e2a1c7441b904f7f4def88753a680d4b98cdf3f7204b1759200b559f76796` | `67a7a8c6c06c4609e702278cb93babdf3f2e15faf4fe8273232fb226fa5fceea` |
| `SOURCE/test/visual/zyra_visual_regression_test.dart` | `bd89032d55a3b67b3364200cca06f81bf079977d3f85bda8ed988a5afb037cd9` | `d765091827c1367ebe6cf27b6490edb9cd74949647728e40a62b7c9276567d4f` |
| `SOURCE/test/zyra_dashboard_adapter_test.dart` | `7ff54635dee1b37fd56b2ee7068b929c78989b7e084194d8702f74e0d3bee45f` | `484ef5c337cad065b371dba2fa6196e9e8e6fc75d59590f553b5da8a69a90c23` |
| `SOURCE/test/zyra_dashboard_resolver_test.dart` | `42ef652e027a3581df58b79c68e119a94d6fc68dfc67e42a3d7645ac3c468830` | `a150e62150c65d2b9c65f363bb16b83bf1b5bf3b4728b85ec3225282d48ca1f0` |
| `SOURCE/test/zyra_dashboard_updates_service_test.dart` | **ABSENT** | `ab934433b14bd517e08b04ad55f54c6da2aca142a45acdb768a4483ce596b0ac` |
| `SYSTEM/RESOURCES/UI_GATE/CANDIDATES/OA-ZYRA-281_PHASE_2_manifest.json` | `47756a93f53494fc6e37fbc4380940db78c480caf9f2da84932291e1fc2a4648` | `e57ce8b5173b97afc4f5fc4dbe06532e4239adc6ccfcd7d3abd42f2082799389` |
| `SYSTEM/DOCUMENTS/ZYRA_SEEKER_DASHBOARD_HANDOVER_CURRENT_VERSION_V1.md` | `c12e7fefde597749681542b3148a4ea18c74d0743bc0fb668841b79b37fb29f6` | `ba8f207af0ff6bc2cc9013c04278a8678a4df44d0c1c71f96a25476ab642ce5d` |

The handover post-hash above was taken before this completion message was
created; the handover has not changed since. This completion message omits its
own self-hash.

## 11 · Migration and standing-invariant integrity

`SOURCE/supabase/migrations/20260830145711_oa281_dashboard_updates_projection.sql`
remains byte-identical at:

`4f11c53b3d0a42a3102beb7ac0654773f2bfb6f56bc44cf684b3f75168bb49a0`

The existing migration static suite still asserts caller participation,
per-role predicates, canonical notification registry, the milestone allowlist,
three-state unread, integrity guards, deterministic keyset order and exact
index definitions. Client wiring adds no timestamp heuristic and no new
projection class.

## 12 · Challenges and deviations

1. **Undefined numerical latency budget:** 043 requires evidence that the
   union/sort is inside the Dashboard latency budget, but neither 043 nor the
   governing Dashboard documents states a numeric threshold. I did not invent
   one. The live measured server execution range is 14.986–19.543 ms, with no
   read blocks or temp spill, and is reported for Fable/Founder disposition.
2. **Tiny-table planner choice:** the normal live planner uses sequential scans
   on several 0–23-row tables. I preserved that truth and added a separate,
   explicitly labelled index-eligibility plan proving all five post-index paths
   are selectable as cardinality grows. No schema change was made.
3. **Fixture expansion:** to make the Founder's one inspection cover both
   wired roles and the last-known law, the authorised production set was
   expanded from 6 to 10 fixture families (24 to 40 variants). Every addition
   remains candidate-only and unapproved.

No other material deviation was found.

## 13 · Requested next gate

Fable: independently verify the hashes, one-source wiring, template coverage,
role behavior, live performance evidence and 40-entry candidate manifest. On
pass, release the Founder for the single final visual inspection described by
043. No further construction or database work is requested in this report.

— Codex, 2026-08-30
