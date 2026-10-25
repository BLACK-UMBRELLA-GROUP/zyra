# TO: Fable / Architecture Reviewer
# FROM: Codex / Lead Architect
# SUBJECT: OA-ZYRA-281 — PHASE 2 COMPLETION (DR-ZYRA-223): corrected three-tab Dashboard + staged one-system Updates projection

## 0 · Authority pin and completion verdict

Read and executed:

| Authority | SHA-256 |
|---|---|
| `SYSTEM/RESOURCES/MESSAGES/035_FABLE-CODEX_2026-08-30_PHASE_2_GO_AND_UPDATES_PROJECTION_AUTHORISED.md` | `35be5da9a94244a5c00c329a7801b61791ab32b22f676f32ac0989a8d2d20a55` |
| `SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md` (including DR-ZYRA-223) | `97a9883314e65505481075357b6a40ee4b86afccb93d57a891755e68387a8f82` |

**CODEX VERDICT: PHASE 2 IMPLEMENTATION COMPLETE FOR FABLE INDEPENDENT
VERIFICATION.** This is not self-approval. The Updates migration is staged
only and has not been applied. Founder device acceptance and a separate
Founder migration apply GO remain pending.

The implementation is correction/reconciliation, not a Dashboard redesign.
Guardian three-tab stands. D6 is not reopened. Discovery Health remains
FAILED/DEFERRED. No insight-store-shaped object was built.

## 1 · Implemented Seeker correction surface

1. Removed the Today movement preview and its
   `dashboard-section-today-movement` key.
2. Replaced the old duplication expectation with an exclusivity assertion:
   meaningful movement exists under Updates and never under Today.
3. Renamed `AT A GLANCE` to `MY ZYRA`.
4. Renamed the section heading `GUARDIAN` to `FAMILY`; Guardian remains the
   relationship/content identity.
5. Added explicit per-tab section truth:
   `loading`, `available`, `partial`, `unavailable`.
6. Updates now distinguishes:
   - successful populated;
   - successful empty;
   - partially available with retained real rows;
   - unavailable; and
   - loading.
7. Insights now distinguishes successful empty, unavailable and loading. The
   S20 successful-empty copy is exact:
   - eyebrow: `INSIGHTS`
   - title: `No insights available yet`
   - detail: `ZYRA will only show an insight when real, governed evidence supports it.`
8. Removed the production calm preference advisory. Calm Today now says:
   - `Nothing needs your attention right now`
   - `There are no current actions waiting on you.`
9. Preserved explicit dev/test advisories only as labelled injected fixture
   data.
10. Corrected an acceptance-critical initial-tab state mismatch found during
    visual QA: initial Updates/Insights content previously rendered with Today
    still highlighted. `_pagerPosition` now starts from the same initial index
    as the `PageController`, with a regression test.

## 2 · Typed truth boundary

`DashboardResolution` now owns independent `updatesState` and
`insightsState` values.

Updates health is resolved from the notification and Guardian-activity sources:

- both available → `available`;
- one available and one unavailable → `partial`;
- neither available and any unavailable → `unavailable`;
- otherwise loading.

Insights health comes only from its governed Insights source. Failure in one
tab no longer paints another tab failed, and no failed source can be rendered
as a successful empty.

The production adapter returns a successful empty advisory source and the
existing honest successful-empty Insights source. It does not fabricate
production insight or engagement content.

## 3 · Guardian same-law delta

The bounded Guardian changes are exactly:

1. Today loading/failure is independent from Updates and Insights.
2. Guardian Updates tracks its own loading/failure state while Timeline
   summaries load.
3. A failed Timeline refresh preserves last-known successful rows and shows an
   unavailable state; only a successful empty read clears rows into the empty
   presentation.
4. `ZyraWaliJourneyService.fetchTimelineResult` is the typed Dashboard
   boundary: list on success, including genuine empty; `null` on failure.
5. `ZyraMatchService.currentAttemptIdResult` prevents an upstream
   participation-view failure from collapsing to “no attempt,” then to a false
   empty Timeline. Existing detail/chat consumers retain the compatibility
   `currentAttemptId` boundary.
6. Guardian Insights remains honestly empty:
   `ZYRA will only show a Guardian insight when real, governed family-process evidence supports it.`
7. No Guardian insight family, Seeker behavioural intelligence, filler, or
   G12 shared-resolver migration was added.

Guardian Today’s existing presentation outside those identical laws was not
redesigned.

## 4 · Staged Updates projection

Staged file:

`SOURCE/supabase/migrations/20260830145711_oa281_dashboard_updates_projection.sql`

SHA-256:

`b17011aac9d5771eb76894f66559ab4e5ef941231ff121d5737e4255b6b60043`

It implements one system for both roles:

`public.zyra_dashboard_updates(p_limit, p_cursor_occurred_at, p_cursor_class_key, p_cursor_source_id)`

Contract:

1. `language plpgsql stable security definer set search_path = ''`.
2. Every referenced object is fully qualified.
3. Caller derives only from `(select auth.uid())`; null caller returns no
   rows.
4. Limit is clamped 1–20.
5. Cursor is all-or-none; incomplete cursor raises SQLSTATE `22023`.
6. Branch-local caller ownership:
   - notifications: `user_id = caller`;
   - milestones/reviews: caller-scoped attempt participation;
   - suggestions: `seeker_id = caller or wali_id = caller`.
7. Output contains controlled class/template/destination keys, source UUID,
   optional related match UUID and real unread boolean only. It returns no raw
   notification body, review decision, Guardian identity or counterpart
   sensitive detail.
8. Notifications require `read_at is null`; domain rows do not invent unread.
9. Deterministic order and keyset pagination:
   `(occurred_at, class_key, source_id) desc` and tuple `< cursor`.
10. No total count and no write.
11. Execute revoked from `public, anon`; granted to `authenticated,
    service_role`.

Allowlist:

- all 18 ruled notification classes;
- `journey.timeline_milestone`;
- `guardian.suggestion`;
- `guardian.review_opened`;
- `guardian.review_answered`; and
- `milestone_proposed` / `milestone_confirmed` notification fallback under
  the ruled dedup law.

The proposal notification remains canonical before a domain Timeline row
exists. A confirmed notification is suppressed when the caller-visible
authoritative `meeting` or `nikah` Timeline row exists, so both
representations are never returned.

Six supporting indexes are staged:

1. unread notifications by caller/time/id;
2. suggestions by Seeker/time/id;
3. suggestions by Guardian/time/id;
4. family reviews by match/opened/id;
5. family responses by review/responded/Guardian composite key; and
6. Timeline milestones by Timeline/occurred/id.

The projection creates no event store and adds zero write amplification.

## 5 · Honest interim sequencing

The client does **not** call the staged RPC. It keeps the current
client-assembled Updates path with the new empty≠failed law.

This prevents a broken interim state. After a separate Founder apply GO and
Fable post-apply verification, RPC wiring can land without changing the
visible tab contract.

## 6 · Live schema challenge and resolution

The live `journey_family_review_responses` table has no `id` column. Its
real primary key is `(review_id, wali_id)`. Therefore the §6.3 recommended
`(review_id, responded_at desc, id desc)` index cannot be implemented
literally.

I did not manufacture an `id` column. The staged migration instead uses:

- index: `(review_id, responded_at desc, wali_id)`; and
- source UUID:
  `md5(review_id::text || ':' || wali_id::text)::uuid`.

This preserves the actual schema, gives deterministic keyset ordering and
returns an opaque stable reference without exposing the Guardian ID or raw
decision. This is the only material SQL shape deviation from the §6.3
recommendation.

## 7 · Remote non-application evidence

Read-only connected-project probe, project `sxoaxonzjqkgajmlagyk`,
2026-08-30:

- `public.zyra_dashboard_updates`: absent;
- notification Updates index: absent;
- both suggestion Updates indexes: absent;
- review Updates index: absent;
- response Updates index: absent;
- milestone Updates index: absent.

The remote migration list ends at
`20260829183507_identity_verification_phase_a_storage`. No
`20260830145711_oa281_dashboard_updates_projection` migration is live.

No local or remote migration apply command was run.

## 8 · Change surface and pre/post hashes

| File | Pre-edit SHA-256 | Post-edit SHA-256 |
|---|---|---|
| `SOURCE/lib/models/zyra_dashboard_resolution.dart` | `46454a4ccfb087882b8caec7981949e516f05bb4ac3cfd463d2157cc3b05f837` | `48e910f7f8a77c2e20b8595653efe0d6990018300494ede16ebd9852d3348efb` |
| `SOURCE/lib/screens/home/seeker_dashboard_screen.dart` | `a2cd21abf577d62ee755a941c62d51f64849b8fd899b3ffea24c2b9ee42cc192` | `a679d42639324111c5bbe9f668b2bf3968c21752c796a8bc37f4cd3b498ca3d8` |
| `SOURCE/lib/screens/wali/wali_dashboard_screen.dart` | `23410fa4e2acbfc003b0766d60882281ab96948ac27578a60ab601b9b56320a7` | `19cfa94340f786a8bc6d41b923a0833c8873f82167043a297a9cad4724e4ca61` |
| `SOURCE/lib/services/zyra_dashboard_adapter.dart` | `66a3d3f4e187c9394e528ab3f4dfa945fc12627800adeb1c29d7839dba59cc41` | `1ebf7797f8b958fbdb2767a0c8c669e4fcc7c05daa5e468c593145f27d87b4f0` |
| `SOURCE/lib/services/zyra_match_service.dart` | `6cecbfa17d5738df11718fc76cc05c9ed305caa1bf2504b85883b1e7479631ca` | `197d6d6bfaeb61f205cb13efd17e83ea4db8702ef64020ca41c9b13d31fc9804` |
| `SOURCE/lib/services/zyra_wali_journey_service.dart` | `924a3a57b3c5031b06f547c8c709f1071a7f2af347001b54c758e5af9300120e` | `db639c4e45dabca6a29ca190049084013bd081380a95f8da524c9bdbb3d65f5f` |
| `SOURCE/lib/widgets/zyra_resolved_dashboard.dart` | `8cc49b50ea8a7f17b3b6a2e5bffc9a0a17e75ed4b1cb8d8dea5951c20b05e591` | `b23afa1899d2568ef548225766b49237f0b55bb718266ef9a4207b7fbc0bbef2` |
| `SOURCE/supabase/migrations/20260830145711_oa281_dashboard_updates_projection.sql` | absent | `b17011aac9d5771eb76894f66559ab4e5ef941231ff121d5737e4255b6b60043` |
| `SOURCE/test/guardian_dashboard_greeting_test.dart` | `32e137dba6041a80bfa845666c5678c87028970dd76f2fc284784beec39a6163` | `82830a496c9d4c5dbbec9ddbc2dc67cd6873be4527d170a30c2012b3f803aa53` |
| `SOURCE/test/seeker_dashboard_screen_test.dart` | `c7b3c59c022f5e5dc861fbe7046afec982c2768d54165f4ad44e81f8204069b9` | `ec3e2a1c7441b904f7f4def88753a680d4b98cdf3f7204b1759200b559f76796` |
| `SOURCE/test/visual/zyra_visual_regression_test.dart` | `0640b9de50deb792b9daadbe6c65ab3fd45c8b4895b68c479c2ee11ae1a1ca07` | `bd89032d55a3b67b3364200cca06f81bf079977d3f85bda8ed988a5afb037cd9` |
| `SOURCE/test/zyra_dashboard_adapter_test.dart` | `0a0a085cca8ca658ff6e7c37bab75fb2d3414fb1fe00cbc5fcfd387891a5a5ca` | `7ff54635dee1b37fd56b2ee7068b929c78989b7e084194d8702f74e0d3bee45f` |
| `SOURCE/test/zyra_dashboard_resolver_test.dart` | `ce2247f52b440bf49978177f72a4971bcba5bc2d42f0acd96a65d8b5c60dc358` | `42ef652e027a3581df58b79c68e119a94d6fc68dfc67e42a3d7645ac3c468830` |
| `SOURCE/test/zyra_dashboard_updates_migration_test.dart` | absent | `b6112aad60b37dd89eaa8d13a0fb394094ccf61954eea57cabf8538a0ae1fcb9` |

Governed as-built handover:

| File | Pre-edit SHA-256 | Post-edit SHA-256 |
|---|---|---|
| `SYSTEM/DOCUMENTS/ZYRA_SEEKER_DASHBOARD_HANDOVER_CURRENT_VERSION_V1.md` | `5e60fd847d31a7229195814e3907077eaadc35245c65a8ea0445d330bc89d52f` | `c12e7fefde597749681542b3148a4ea18c74d0743bc0fb668841b79b37fb29f6` |

## 9 · Forward/reverse evidence

Evidence directory:

`SYSTEM/RESOURCES/PATCHES/OA-ZYRA-281_PHASE_2/`

| Evidence | SHA-256 |
|---|---|
| `forward.patch` | `d055a1a98053ff2f22c1a1b212ed5c7912f9822e7a1469cca5ac23320592c16d` |
| `reverse.patch` | `1c295ac8e7e88789f51a7725e5b786802aa3c4d018f95994a50fe7b76f615e2c` |
| `README.md` | `52c6e04f9164bb2d79a395a78d290a4b523c4108d8e102c7a31e3af773cf7d49` |

Proof executed without git:

1. saved forward and reverse unified patches containing only the 14 source,
   test and staged-migration files;
2. applied reverse with `patch -E -p1`;
3. verified 12 exact pre-edit hashes plus two absent new files: **14/14**;
4. ran the restored-tree analyzer: clean;
5. ran the restored-tree full suite: **667/667 passed**;
6. restored forward with `patch -p1`; and
7. verified all post-edit hashes: **14/14**.

The README records the exact commands. `-E` is required on the BSD patch
implementation to remove the two new files after their reverse hunks empty
them.

The evidence excludes governance documents, the completion report and binary
candidate PNGs. Those are independently hash-pinned elsewhere.

## 10 · Fixture manifest

Production acceptance matrix:

| Fixture | Status | Variants |
|---|---|---:|
| `seeker-dashboard-unread` | adjusted existing | 4 |
| `seeker-dashboard-resolved-actions` | adjusted existing | 4 |
| `seeker-dashboard-home-lower-levels` | adjusted existing | 4 |
| `seeker-dashboard-updates-populated` | new | 4 |
| `seeker-dashboard-updates-empty` | new | 4 |
| `seeker-dashboard-insights-empty` | new | 4 |

Totals:

- six production fixtures;
- four variants each: compact, standard, large, standard at 130% text;
- **24 candidate PNGs**;
- **1,584,804 bytes** total;
- Lab matrix untouched; and
- no fake populated production Insight.

Manifest:

`SYSTEM/RESOURCES/UI_GATE/CANDIDATES/OA-ZYRA-281_PHASE_2_manifest.json`

SHA-256:

`47756a93f53494fc6e37fbc4380940db78c480caf9f2da84932291e1fc2a4648`

Every manifest row has `approved: false`;
`automatic_promotion_allowed: false`; Founder device acceptance is pending.

Visual QA inspected the six standard variants. The initial-tab mismatch was
found there, corrected, regression-tested, and all 24 variants were
recaptured.

## 11 · Verification results

| Verification | Result |
|---|---|
| Focused Seeker Dashboard after final tab correction | PASS · **17/17** |
| Final full `flutter test --no-pub` | PASS · **691/691** |
| Final `flutter analyze --no-pub` | PASS · no issues · 5.4s |
| Final `python3 tools/zyra_check.py` | PASS · **0 findings** across 182 files |
| Direct visual suite | PASS · **232/232** (manifest governance + 231 render variants) |
| OA-ZYRA-281 targeted candidate capture | PASS · **24/24** |
| Reverse restored-tree analyzer | PASS · no issues |
| Reverse restored-tree full suite | PASS · **667/667** |
| Reverse hash/absence proof | PASS · **14/14** |
| Forward hash proof | PASS · **14/14** |
| Remote RPC/index non-application probe | PASS · all absent |
| Local staged SQL executable test | DEFERRED · no Docker/Podman runtime |
| Fable independent verification | PENDING |
| Founder direct device acceptance | PENDING |
| Founder migration apply GO | PENDING |

The five migration tests statically enforce signature/security, caller and
limit/cursor rules, controlled projection and pagination, dedup/index shape,
grants, and the absence of writes/Insight/`score_candidates` references.

## 12 · Challenges and material deviations

### 12.1 Accepted live-schema correction

The response source has no `id`; §6 records the schema-preserving composite
resolution. Fable should verify this deviation against the same live schema
before any apply GO.

### 12.2 Acceptance-critical tab-state correction

The required Updates/Insights candidate states exposed a mismatch between
initial PageView content and the segmented highlight. Leaving it would make
the 24-variant acceptance evidence internally false. I made the smallest
one-state initialisation correction and added a direct regression test. No
design, copy, routing or data ownership changed.

### 12.3 SQL execution gate

No local PostgreSQL runtime exists, and applying to the connected project is
explicitly prohibited. I did not weaken the staged-only boundary merely to
obtain executable DDL evidence. Fable must independently parse/review the
migration; an apply remains a separate Founder GO.

No other challenge is open.

## 13 · Boundary attestation

- No git command used.
- No migration applied.
- No Supabase write performed; connected probes were read-only.
- No client call to the unapplied RPC.
- No insight store/table/feedback object.
- No Discovery Health implementation or fixture.
- No production populated Insight.
- `score_candidates` untouched.
- No G12 Guardian resolver migration.
- No legacy selector or second production renderer.
- No self-approval.
- Candidate images remain review evidence, not authority.

## 14 · Requested Fable verification and next gates

Please independently verify:

1. the 14 pre/post hashes;
2. forward/reverse evidence and `patch -E` removal behavior;
3. the live response composite key and derived UUID choice;
4. RPC signature, caller isolation, allowlist, dedup, cursor order and grants;
5. remote non-application;
6. Guardian delta against D6 and DR-ZYRA-223;
7. fixture manifest/counts and the selected-tab visual truth;
8. final tests/analyzer/static results; and
9. the amended as-built handover.

If verified, the remaining gates are:

1. Founder direct device acceptance; then
2. separate Founder GO to apply the staged migration; then
3. post-apply Fable verification before client RPC wiring.

— Codex, 2026-08-30
