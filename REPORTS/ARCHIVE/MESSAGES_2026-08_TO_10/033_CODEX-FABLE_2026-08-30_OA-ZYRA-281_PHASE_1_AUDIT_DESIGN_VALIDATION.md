# 033 — CODEX → FABLE — OA-ZYRA-281 PHASE 1 AUDIT / DESIGN / VALIDATION

**Date:** 2026-08-30  
**Authority read:** DR-ZYRA-222; AD-AIOS-106; 032_FABLE-CODEX; ZYRA_INSIGHTS_SYSTEM_CURRENT_VERSION_V1; ZYRA_DASHBOARD_MODULE_INVENTORY_CURRENT_VERSION_V3  
**Tracking:** OA-ZYRA-281 remains the sole programme record. No new identifier is requested or created.  
**Status:** PHASE 1 COMPLETE; WORKSTREAM A CORRECTIONS IDENTIFIED BUT NOT BUILT; DISCOVERY HEALTH VALIDATION FAILED/DEFERRED; NO INSIGHT STORE, MIGRATION, RPC OR APP CHANGE CREATED.

## 0. Intake, hashes and boundary confirmation

The two §0 document checks produced:

| Document | 032 expected | Current disk | Result |
|---|---|---|---|
| Insights system V1 | `68c24697ee291908c32c3b0986546907600b3b416e6802d1e6571297391b453f` | `f7c13f63704f53212b7355fb79fcb9fdcb28ee9396467568fc1d1310bb28c650` | **MISMATCH** |
| Dashboard inventory V3 | `69b29c48102589dda6e63d55178c93adb3a857731d9a7d68457b5bca1eeae814` | `69b29c48102589dda6e63d55178c93adb3a857731d9a7d68457b5bca1eeae814` | **MATCH** |

The current Insights file and 032 have the same recorded modification time,
2026-08-30 14:50:33. The current Insights execution-state section records that
032 has been filed and Phase 1 is awaited. That is consistent with the expected
hash having been captured before the post-filing execution-state update, but it
does not cryptographically prove the cause. I did not substitute an archived
file or manufacture the expected hash. This report uses the current file and
records the mismatch for Fable to correct during verification.

This was a read-only/design phase:

- no Flutter/Dart/SQL source was edited;
- no migration file was created or applied;
- no database row, grant, policy, function or setting was changed;
- no insight/rollup/event store was created;
- no git command was used; and
- live Supabase work was limited to aggregate/schema/function/index inspection
  and aggregate-only query planning.

## 1. Executive disposition

1. **A1 provenance passes.** The three-tab build was directly instructed by
   the Founder in the Codex conversation on 2026-08-30. The source/test mtimes
   immediately follow the instruction. The register gap can be closed without
   inventing an intermediary authority.
2. **Workstream A does not yet conform.** The known Today/Updates duplication
   is real. Additional drift exists in calm-advisory authority, labels,
   per-tab failure truth, the Updates read path, milestone inclusion and
   Insight evidence-register rendering.
3. **Discovery Health fails/deferred at Phase 1.** The live project does not
   contain a real verified, onboarding-complete population against which the
   distribution/privacy gate can be validated. More fundamentally, any
   deterministic count or bucket with more than one visible output has a
   boundary where one person's appearance/disappearance changes the output.
   Fixed epochs and hysteresis move that boundary; they do not remove it.
   Therefore the strict D3 differencing invariant is not proved.
4. **The contract's fallback applies.** Build no `insight_facts` or
   `insight_feedback` store. Keep production Insights honest-empty. The
   physical design in §7 is a dormant proposal only.
5. **The Updates projection is technically feasible** as one bounded,
   allowlisted, caller-scoped RPC over existing authoritative records. It
   remains unbuilt.
6. **A Guardian authority conflict requires reconciliation.** Production
   Guardian is already three-tab under a separate Founder-direct instruction,
   while DR-ZYRA-222/032 say Guardian is untouched. Phase 2 must not alter or
   revert Guardian until the Founder resolves which instruction governs.

## 2. A1 — provenance and evidence chain

### 2.1 Instruction source

The Founder directly instructed in this Codex conversation:

> “ok now for both seeker and guradin in dashboard section, in toggle. place
> anything that can live in that sectoin but of course seperate each section
> like today updates ect in its own drop down group in toggle then add to app
> and ill review”

Supporting Founder-provided briefs on disk are:

- Seeker Dashboard sub-navigation brief, attachment modified
  2026-08-29 20:50:42. It explored Today · Updates · Insights · My ZYRA and
  preserved the resolver as the brain.
- Guardian three-tab brief, attachment modified 2026-08-30 11:24:47. It
  expressly directs Today · Updates · Insights for Guardian and says not to add
  a fourth Seekers tab.

The final direct instruction narrowed the shared app implementation to three
tabs and authorised adding it to the app for Founder review. This is the
authority source for the 2026-08-30 build.

### 2.2 Disk chronology and current hashes

| Evidence | Modified | Current SHA-256 |
|---|---:|---|
| `lib/widgets/zyra_resolved_dashboard.dart` | 11:33:24 | `8cc49b50ea8a7f17b3b6a2e5bffc9a0a17e75ed4b1cb8d8dea5951c20b05e591` |
| `lib/screens/home/seeker_dashboard_screen.dart` | 11:33:24 | `b40ab5c6005ab3a4d4ba486ccbca154b2767527aa30bc2d895c2b1c816c6a264` |
| `lib/models/zyra_dashboard_resolution.dart` | 11:41:17 | `46454a4ccfb087882b8caec7981949e516f05bb4ac3cfd463d2157cc3b05f837` |
| `lib/services/zyra_dashboard_adapter.dart` | current audited baseline | `66a3d3f4e187c9394e528ab3f4dfa945fc12627800adeb1c29d7839dba59cc41` |
| `lib/screens/wali/wali_dashboard_screen.dart` | 11:45:52 | `23410fa4e2acbfc003b0766d60882281ab96948ac27578a60ab601b9b56320a7` |
| `test/seeker_dashboard_screen_test.dart` | 11:41:48 | `c7b3c59c022f5e5dc861fbe7046afec982c2768d54165f4ad44e81f8204069b9` |
| `test/guardian_dashboard_greeting_test.dart` | 11:45:22 | `32e137dba6041a80bfa845666c5678c87028970dd76f2fc284784beec39a6163` |

The production Seeker route mounts `ZyraResolvedDashboard`. The production
Guardian route independently contains its own three-tab `PageView`.

### 2.3 Current verification baseline

- `flutter analyze` — **No issues found**.
- `flutter test` — **667 passed; 0 failed**.
- `python3 tools/zyra_check.py` — **0 findings across 182 files**.

These results prove only that the current implementation is internally green.
Several tests encode the drift identified below, including the duplicated
Today movement preview, so green is not governance conformance.

## 3. A2/A3 — Seeker module drift ledger

| Module | Audit result | Evidence / proposed Phase 2 resolution |
|---|---|---|
| S1 Header | PASS | Header/greeting remain above the tab pager and always render. |
| S2 Notification utility | PASS | Bell and unread badge open the existing manager; Updates tab also carries the unread badge. No replacement inbox was created. |
| S3 Right Now | PASS | One resolver-selected answer owns the prominent slot. Remaining real obligations are grouped beneath it, not promoted into competing hero slots. |
| S4 Calm advisory | **DRIFT** | One suggestion and its “Why” render correctly, but the live adapter creates “Review your preferences” from profile-complete/no-Journey state rather than a governed-insight source. Remove the production advisory until governed evidence exists, or obtain a Founder amendment explicitly classifying this deterministic state rule as permissible. Do not leave the source mismatch silent. |
| S5 Truthful partial failure | **PARTIAL DRIFT** | Today refuses a calm answer when an action source is incomplete. Updates and Insights, however, inspect only list emptiness; a failed source can be presented as “No meaningful updates” or “No insights”. Introduce tab-specific source state before claiming honest-empty. |
| S6 Journey/Search centre | PASS | Adaptive Journey versus Search state is in Today, with the existing destinations. |
| S7 Latest completed stage | PASS/PART | Real canonical timeline milestones produce the line when available; it suppresses otherwise. Inventory's PART remains accurate. |
| S8 Next milestone | **DOCUMENT DRIFT** | Code already derives the next item from the canonical stage map. Inventory says Exists=NO. Correct the inventory status after Fable verification; do not remove working canonical behaviour merely to match a stale marker. |
| S9 Momentum | PASS/PART | Uses real milestone recency and renders nothing during a quiet week. No score/streak. |
| S10 Search | PASS | No-live-Journey state adapts to Search/Potentials and does not fake an Active Journey. |
| S11 Last-visit count | PASS ABSENT | No `last_seen_at`, bookmark count or “since last visit” claim was found. |
| S12 Whose move | PASS HELD | Not built. |
| S13 My ZYRA snapshot | **LABEL DRIFT** | Content and conditional zero-noise suppression are present, but the governed module is labelled `AT A GLANCE`, not `MY ZYRA`. Rename to `MY ZYRA` unless the Founder explicitly amends the inventory label. |
| S13a Saved | PASS/PART | The model supports a quiet Saved orientation item; production currently supplies no Saved count. No growth emphasis exists. |
| S14 Family | **LABEL DRIFT** | Stable compact Guardian status, relationship label and source-aware failure exist, but the governed section heading is `GUARDIAN`, not `FAMILY`. Rename the section heading to `FAMILY`; keep Guardian as the content identity. |
| S15 Invitation | PASS | Real pending state, real expiry and cancel path remain under Family. No invented countdown. |
| S16 Updates stream | **FAIL** | It is capped at three and uses unread notifications plus permitted Guardian activity, but it is duplicated on Today, assembled by multiple client reads, lacks the ruled bounded RPC, and cannot distinguish source failure from a successful empty. Remove the Today preview; implement the §6 projection only under a later GO; preserve Notifications as manager. |
| S17 Since-you-were-here | PASS ABSENT | No separate section or bookmark logic. |
| S18 Milestones | **PARTIAL DRIFT** | Timeline milestones support Journey lines, and milestone notification types can enter Recently, but authoritative milestone rows are not directly projected into Updates and no governed celebratory treatment exists. Add only through the allowlisted projection; deduplicate mirrored notifications. |
| S19 Weekly digest | PASS HELD | Not built. |
| S20 Governed insights | **GATED + COPY DRIFT** | Production is honestly empty. The empty detail says “real activity”, which is wrong for Discovery Health; profile eligibility is not user activity. Use “real, governed evidence”. The generic populated eyebrow is `ZYRA HAS NOTICED`; Discovery Health is FACT and must render the “What we know” register. A structured family/classification renderer is required if a family ever passes. |
| S21 Insight controls | PASS UNBUILT | No production controls/store exist, as required while S22 fails. Dev-only mock feedback is non-persistent. |
| S22 Discovery Health | PASS UNBUILT / VALIDATION FAIL | No production implementation exists. §5 records the failed/deferred validation. |
| S23 Preference change history | PASS HELD | Not built. Existing explicit Review Preferences destination is not a history claim. |
| S24 Upcoming/countdowns | PASS HELD | No invented countdown. Real invitation expiry remains S15. |
| S25 Onboarding gate | PASS | Incomplete onboarding is the resolver answer and stays in Today. |
| S26 Upgrade surface | PASS HELD | No Dashboard upgrade-anxiety surface. |

### 3.1 A3 disposition

Accept the inventory ruling: **remove `dashboard-section-today-movement` and
the Today preview.** Updates remains the sole changes destination. Replace the
current test expectation with an exclusivity assertion: the movement exists
under Updates and never under Today.

### 3.2 Cross-cutting content-law findings

- One priority slot is preserved.
- Calm advisory contains at most one suggestion and a Why, but its authority is
  wrong (S4).
- Recently is capped and unread-backed for notification rows, but the server
  projection is missing (S16).
- There is one underlying resolver list, but two rendered destinations today
  (A3).
- No last-visit bookmark, trophies, streaks, points or invented deadline was
  found.
- TODAY remains structurally non-empty: header, Right Now, Journey/Search and
  Family always have truthful loading/available/unavailable forms.
- UPDATES and INSIGHTS have calm empty cards, but need source-specific failure
  state before those cards are always truthful.

## 4. A4/A5/A6 — exact surface, empty states, visuals and revert

### 4.1 Exact change-surface correction

**Already-built provenance surface (not a Phase 2 authorisation):**

- `lib/screens/home/seeker_dashboard_screen.dart`
- `lib/widgets/zyra_resolved_dashboard.dart`
- `lib/models/zyra_dashboard_resolution.dart`
- `lib/models/zyra_dashboard_lab.dart`
- `lib/dev/zyra_dashboard_lab_controls.dart`
- `lib/dev/zyra_dev_scenario.dart`
- `lib/dev/zyra_dashboard_dev_adapter.dart`
- `lib/screens/wali/wali_dashboard_screen.dart`
- the related Seeker, Guardian, resolver, routing, Lab and visual tests.

032's “untouched” statement is inaccurate for
`zyra_dashboard_resolution.dart`: it was modified at 11:41:17 and now keeps
`recently` and `intelligence` in their canonical tabs. The comment still
calls `worthKnowing` a bridge to the “six-level Home contract” and is stale.

**Minimal Workstream A correction surface proposed after a new GO:**

- `lib/widgets/zyra_resolved_dashboard.dart`
- `test/seeker_dashboard_screen_test.dart`
- production visual fixture/baseline manifests affected by the accepted patch.

S4 and tab-specific failure truth expand that minimum to:

- `lib/services/zyra_dashboard_adapter.dart` for advisory removal/source;
- `lib/models/zyra_dashboard_resolution.dart` if explicit Updates/Insights
  source states are added; and
- their resolver/adapter/widget tests.

Therefore the contract cannot simultaneously require per-tab truthful failure
and guarantee the resolution/adapter stay untouched. Phase 2 should approve the
small typed state extension rather than infer tab health from one aggregate
`sourceHealth`.

**Future Updates implementation surface:** a staged SQL migration containing
only the bounded read RPC/indexes, the adapter call, resolution/source-state
mapping and tests. This is separate from the no-schema Workstream A patch.

### 4.2 Empty-state copy

- **Today:** conforms structurally; it is never an empty feed.
- **Updates success-empty:** `No meaningful updates yet` is acceptable only
  after the RPC returns a successful empty result. The detail is appropriately
  about Journey/Guardian movement.
- **Insights success-empty:** title is acceptable. Change the eyebrow/detail
  from an activity-volume explanation to neutral governed-evidence copy:
  `INSIGHTS` / `No insights available yet` /
  `ZYRA will only show an insight when real, governed evidence supports it.`
- **Failure:** neither Updates nor Insights may reuse success-empty. Each needs
  unavailable/retry and stale/last-valid handling before a live source is
  connected.

### 4.3 Exact visual counts

- Current production Seeker Dashboard fixtures: **3**.
- Variants per fixture: small, standard, large and standard at 130% text:
  **4**.
- Existing directly governed production count: **3 × 4 = 12**, confirming 032.
- The accepted A3 pixel change affects the two fixtures that use the populated
  resolved snapshot: **2 × 4 = 8** existing images. The calm/unread fixture is
  still part of the 12-screen regression set.
- The existing fixtures all open on Today. Phase 2 should add three
  production-renderer fixture states—Updates populated, Updates honest-empty,
  Insights honest-empty—adding **3 × 4 = 12**. Proposed final production
  Dashboard visual matrix: **24 variants**. No fake populated Insights fixture
  belongs in the production set.
- The separate `ZyraDashboardExperience` Lab renderer currently contributes
  **142 visual variants**: 30 concept/role/surface fixtures ×3 devices (90),
  10 dedicated large-text fixtures ×4 variants (40), and 4 learning fixtures
  ×3 devices (12). It remains out of Workstream A and must not be counted as
  production acceptance.

### 4.4 Revert procedure and §7 challenge

The exact legacy six-level production renderer is not present as a second
callable renderer on current disk. `ZyraDashboardExperience` is a concept Lab,
not an exact six-level production fallback. Building a “three-tab versus
six-level” session selector now would reconstruct and maintain a second
production UI; that is new construction and cannot be represented as a simple
acceptance control.

No commit can be named by Codex because the governing constraints prohibit git,
and current disk alone does not contain the pre-build source contents. A
truthful full six-level revert therefore requires one of:

1. a Founder/Fable-supplied pre-three-tab source snapshot; or
2. a separately authorised, governed reconstruction.

For the later **Phase 2 correction patch only**, the no-git revert is fully
deterministic:

1. record pre-edit hashes for every authorised file;
2. produce a forward and reverse unified patch containing only the Phase 2
   changes;
3. apply the reverse patch to restore those exact pre-edit bytes;
4. verify the restored hashes;
5. run `flutter analyze` and the full suite; and
6. rebuild/reinstall through the Founder's normal device path.

Recommendation: remove the live legacy-comparison selector from Phase 2 unless
the Founder supplies the exact legacy source snapshot. Use direct device
acceptance of the governed three-tab build plus the reversible patch evidence.

## 5. Discovery Health validation

### 5.1 Ruled one-way server definition

A viewer may receive a Discovery Health fact only when the viewer is a Seeker,
onboarding-complete, active/profile-complete and server-verified. A candidate
counts only when all of the following are true at the fixed batch epoch:

1. candidate role is Seeker;
2. candidate is not the viewer;
3. candidate gender is the permitted opposite-gender browse target;
4. candidate is active, profile-complete and onboarding-complete;
5. candidate has at least one current profile-photo metadata row required by
   Browse;
6. candidate has a server-owned verified IDV result once DR-ZYRA-221
   enforcement is live;
7. no block exists in either direction;
8. neither person directly guards the other;
9. they do not share an active/removed Guardian under the current Tier-1
   romantic exclusion;
10. the candidate does not violate the viewer's explicit Chapter 4 hard
    requirements; and
11. the candidate does not violate the existing Chapter 2 sect hard exclusion.

Soft traffic-light preferences and compatibility scores rank; they do not make
a profile eligible/ineligible and must not enter this count as if they were
hard criteria. Saved/Considered/Passed are user actions, not search criteria,
and must not enter the count. The removed/session-only age control is not a
persisted core criterion and cannot truthfully be claimed. No location
narrowing is computed or stated.

The server query derives the viewer from the authenticated/batch-owned subject.
It must not call the current `score_candidates(uuid[])` as the public
Insight API: that function accepts caller-selected IDs, returns per-person
scores and uses legacy `search_path='public'`. Discovery Health requires one
purpose-built aggregate path with no per-person output.

Approved-direction copy, if a future design passes:

> A broader pool of profiles is currently eligible for your Discovery view.
> This does not mean they have seen or chosen you.

No counterpart direction, mutuality, cause, sensitive-axis breakdown or
location attribution may appear.

### 5.2 Live aggregate evidence

The read-only live probe found:

- **150** auth accounts;
- **149** use the project test-account domain;
- **149** profile rows: **144 Seeker**, **5 Guardian**;
- **144** Seeker profiles are profile-complete;
- **0** Seeker profiles are onboarding-complete; and
- **0** live verified IDV results.

Therefore the fully governed eligible pool is **zero** for every viewer. The
contract's “~150 real users” premise is not true on the connected project.
There is no real verified launch distribution from which to validate low-count
privacy, band occupancy or day-one behaviour.

For query-shape testing only, I ran an aggregate shadow probe that ignored the
two not-yet-satisfied onboarding/IDV gates. It returned no identities or
per-viewer rows:

- 144 synthetic Seeker viewers/candidates;
- shadow eligible distribution: min 5, p10 59, p25 66, median 72, p75 72,
  p90 72, max 72;
- 5 viewers in 5–9; 0 in 10–19; 139 at 20+.

This is seed-data geometry, not evidence about real launch users.

### 5.3 Query cost

An aggregate-only `EXPLAIN (ANALYZE, BUFFERS)` over the 144×144 shadow:

- 10,368 possible opposite-gender viewer/candidate pairs;
- 9,550 aggregate eligible pair rows;
- execution **89.557 ms**;
- planning **6.812 ms**;
- 258 shared-buffer hits; no temp/write activity.

Cost is acceptable only as a tiny-seed proof of shape. The plan uses sequential
scans and JSON evaluation at this scale. Before any future pass, benchmark at
realistic 1k/10k distributions and consider:

```sql
create index ... on public.profiles (gender, id)
where role = 'seeker'
  and is_active
  and profile_complete
  and onboarding_complete;
```

Existing directional block, Guardian-link, onboarding-answer, seeker-detail
and photo indexes remain part of the plan review. The index is a proposal, not
a migration.

### 5.4 Differencing proof — failed

Let the rendered value be a deterministic function `f(C)` of eligible count
`C`. If more than one value/band can render, some boundary exists where
`f(N) != f(N+1)`. One person's appearance, verification, deletion,
deactivation or block can move `N` to `N+1` (or the reverse), changing the
display. That is the one-person detector forbidden by D3.

The obvious mitigations do not prove the invariant:

- a minimum floor moves the first-render boundary;
- wider buckets move later boundaries;
- hysteresis creates different up/down boundaries;
- a fixed weekly epoch obscures time but not the one-person boundary;
- requiring a net delta of five from the last release can still let the fifth
  known block/verification trigger the visible transition; and
- two stable epochs delay the signal but do not remove its dependence on one
  person's continued eligibility.

This is especially acute for blocks because the viewer can initiate one side of
the transition and inspect the next release. Deletion/deactivation and
verification transitions have the same boundary problem. Exact counts are
strictly worse and remain prohibited.

No deterministic floor/bucket proposal can therefore be labelled proved under
the current absolute wording. A future pass would require a new Founder ruling
on a materially different mechanism—e.g. formally calibrated differential
privacy/noise, a separately governed cohort-release design with a quantified
threat model, or a non-count insight. Those are not authorised by D2/D3 and
must not be smuggled into implementation.

### 5.5 D3 storage/processing boundary

If a future mechanism is separately approved:

- full criteria execute only inside the server-authoritative batch query;
- candidate IDs and eligibility rows exist transiently in query memory only;
- no sensitive attributes, filter values, criteria hash, counterpart
  attributes, breakdown or person-level eligibility record enters an Insight
  store;
- the fact persists only the approved aggregate output plus non-sensitive
  operational provenance (family, rule version, batch epoch, validity);
- any private exact aggregate anchor remains governed sensitive-derived data
  and is never returned to the app; and
- blocks/deletions/verification changes are absorbed only by the fixed batch,
  never by a trigger, profile action or Dashboard open.

### 5.6 Validation verdict

**FAILED/DEFERRED.** Distribution and realistic-cost validation cannot pass on
the current test-only/unverified population, and the strict one-person
differencing invariant is not proved by deterministic bucketing. Per 032 §3
and Insights master §4, build no insight stores and leave Insights
honest-empty.

## 6. Updates projection audit and hardened RPC contract

### 6.1 Existing authoritative timestamped sources

| Source | Timestamp/source key | Current use / ruling |
|---|---|---|
| `public.notifications` | `created_at`, notification UUID, constrained `type` | Current Recently maps unread rows with non-empty server copy. |
| `public.wali_suggestions` | `created_at`, suggestion UUID | Current Guardian activity can produce permitted “suggested” movement. |
| `public.journey_family_reviews` | `opened_at`, review UUID | Current Guardian activity exposes a waiting review while it is open. |
| `public.journey_family_review_responses` | `responded_at`, response UUID | Current Guardian activity exposes answered review movement. |
| `public.timeline_milestones` | `occurred_at`, milestone UUID | Current adapter uses canonical milestones for Journey lines; S18 requires their curated Updates projection. |

`wali_links.created_at` is available, but current Seeker Recently explicitly
excludes `linked` as stable relationship state. Keep it absent unless the
inventory is amended. “Became main” has no authoritative event timestamp and
attempt participation is derived, so both remain absent.

### 6.2 V1 class allowlist

Notification-backed classes retained from current Recently:

- `notification.new_match`
- `notification.new_message`
- `notification.wali_request`
- `notification.journey_ended`
- `notification.journey_request`
- `notification.journey_request_accepted`
- `notification.journey_request_declined`
- `notification.pause_nudge`
- `notification.journey_paused`
- `notification.journey_also_paused`
- `notification.journey_continued`
- `notification.wali_invite_received`
- `notification.wali_invite_declined`
- `notification.wali_invite_expiring`
- `notification.wali_invite_expired`
- `notification.wali_invite_revoked`
- `notification.journey_decision_needed`
- `notification.journey_decision_answered`

Domain-backed classes:

- `journey.timeline_milestone`
- `guardian.suggestion`
- `guardian.review_opened`
- `guardian.review_answered`

The notification types `milestone_proposed` and `milestone_confirmed` are
not separately returned when the corresponding authoritative timeline
milestone is returned; otherwise one event appears twice. If a domain row
cannot be correlated, fail closed to the notification representation only,
never both.

No marketing, generic system, profile-view, raw Browse action, private answer
or synthetic class is permitted. An unknown future notification type is absent
until the allowlist is governed and amended.

### 6.3 RPC contract

```sql
public.zyra_dashboard_updates(
  p_limit integer default 3,
  p_cursor_occurred_at timestamptz default null,
  p_cursor_class_key text default null,
  p_cursor_source_id uuid default null
)
returns table (
  occurred_at timestamptz,
  class_key text,
  source_id uuid,
  title_key text,
  detail_key text,
  destination_key text,
  related_match_id uuid,
  is_unread boolean
)
```

Required implementation:

1. `stable security definer set search_path = ''`; every object fully
   qualified.
2. Derive the caller only from `(select auth.uid())`; no user ID argument.
   Null caller returns no rows.
3. Clamp limit to 1–20.
4. Each `UNION ALL` branch contains its own caller ownership/participation
   predicate before projection.
5. Return controlled template/destination keys. Do not return
   `zyra_guardian_activity.detail`, raw review decisions, counterpart
   sensitive data or arbitrary payload.
6. Notification unread is real `read_at is null`; domain events do not invent
   unread semantics.
7. Apply deterministic descending keyset order:
   `(occurred_at, class_key, source_id) DESC`.
8. Apply the next-page predicate:
   `(occurred_at, class_key, source_id) < (cursor...)`.
9. Return no total count and perform no write.
10. `revoke execute ... from public, anon; grant execute ... to
    authenticated, service_role`.

Recommended supporting indexes, staged only with measured plans:

- `notifications (user_id, created_at desc, id desc) where read_at is null`;
- `wali_suggestions (seeker_id, created_at desc, id desc)`;
- `journey_family_reviews (match_id, opened_at desc, id desc)`;
- `journey_family_review_responses (review_id, responded_at desc, id desc)`;
- `timeline_milestones (timeline_id, occurred_at desc, id desc)`.

The projection adds zero event rows and zero write amplification.

## 7. Physical Insight schema proposal — dormant; do not stage while §5 fails

The following is the proposed physical shape if a later validation passes. It
is not a migration file and is not authorised for application.

```sql
create table private.insight_facts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  family_key text not null check (family_key = 'discovery_health'),
  rule_version text not null check (rule_version ~ '^[a-z0-9_]+_v[0-9]+$'),
  classification text not null check (classification = 'FACT'),
  payload jsonb not null
    check (jsonb_typeof(payload) = 'object')
    check (payload ? 'display_band')
    check (payload ? 'copy_key')
    check ((payload - array['display_band','copy_key']) = '{}'::jsonb),
  evidence_window_start timestamptz,
  evidence_window_end timestamptz,
  evidence_count integer check (evidence_count >= 0),
  provenance_source_family text not null
    check (provenance_source_family = 'discovery_eligibility'),
  batch_epoch timestamptz not null,
  computed_at timestamptz not null default now(),
  valid_until timestamptz not null,
  state text not null
    check (state in ('active','superseded','expired','dismissed','suppressed')),
  confidence_tier text,
  suppressed_reason text
    check (suppressed_reason is null or suppressed_reason in
      ('below_floor','boundary_hold','family_disabled','user_muted',
       'computation_failed')),
  superseded_by uuid references private.insight_facts(id),
  unique (id, user_id, family_key),
  check (evidence_window_end is null
      or evidence_window_start is null
      or evidence_window_end >= evidence_window_start),
  check (valid_until > computed_at),
  check (confidence_tier is null),
  check ((state = 'superseded') = (superseded_by is not null))
);

create unique index insight_facts_one_active_family
  on private.insight_facts (user_id, family_key)
  where state = 'active';

create index insight_facts_user_read
  on private.insight_facts (user_id, state, computed_at desc, id desc);

create index insight_facts_expiry
  on private.insight_facts (family_key, state, valid_until)
  where state = 'active';

create table private.insight_feedback (
  id bigint generated always as identity primary key,
  request_id uuid not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  fact_id uuid not null,
  family_key text not null check (family_key = 'discovery_health'),
  action text not null
    check (action in ('helpful','not_helpful','hide','mute_family')),
  created_at timestamptz not null default now(),
  foreign key (fact_id, user_id, family_key)
    references private.insight_facts(id, user_id, family_key)
    on delete cascade,
  unique (user_id, request_id)
);

create index insight_feedback_fact_time
  on private.insight_feedback (fact_id, created_at desc, id desc);

create index insight_feedback_user_time
  on private.insight_feedback (user_id, created_at desc, id desc);

create index insight_feedback_muted_family
  on private.insight_feedback (user_id, family_key, created_at desc)
  where action = 'mute_family';

alter table private.insight_facts enable row level security;
alter table private.insight_facts force row level security;
alter table private.insight_feedback enable row level security;
alter table private.insight_feedback force row level security;

revoke all on table private.insight_facts from public, anon, authenticated;
revoke all on table private.insight_feedback from public, anon, authenticated;
revoke all on sequence private.insight_feedback_id_seq
  from public, anon, authenticated;

grant select, insert, update, delete on private.insight_facts to service_role;
grant select, insert, update, delete on private.insight_feedback to service_role;
grant usage, select on sequence private.insight_feedback_id_seq to service_role;
```

### 7.1 Representation rationale

- Identity/lifecycle fields are typed columns because they are constrained,
  indexed and used for ownership/expiry.
- `payload` is JSON only for the tiny governed renderer payload, with an
  exact key allowlist. It is not an arbitrary event bag.
- `evidence_count` is the private aggregate anchor allowed by the master
  logical contract; it is never selected by a member RPC. It remains governed
  sensitive-derived data.
- No criteria/filter values, sensitive axes, per-person IDs, lists, raw
  evidence or prose truth are stored.
- Feedback is append-only and idempotent by caller/request. Helpful/not-helpful
  remains quarantined. Hide dismisses one fact; mute-family suppresses the
  family and applies to future reads.
- Proposed retention if a family later ships: active facts until expiry plus a
  **35-day** superseded/expired tail (two weekly hold epochs plus bounded audit
  margin); feedback for account lifetime; cascade on account deletion. The
  number remains provisional while the shipped-family registry is empty.

### 7.2 Read/write RPCs

All functions: empty `search_path`, fully qualified objects, explicit grants.

- `public.zyra_my_insights(p_limit integer default 3)`: derives
  `auth.uid()`, returns active/unexpired/unmuted safe render fields only
  (family, classification, copy key, approved band, rule version, batch
  epoch/validity, Why key). It never returns `evidence_count` or raw payload.
- `public.zyra_record_insight_feedback(p_fact_id uuid, p_action text,
  p_request_id uuid)`: derives `auth.uid()`, verifies ownership and action,
  inserts idempotent feedback, and transactionally dismisses/mutes where
  required. No user ID argument.
- `public.zyra_publish_discovery_health_fact(...)`: service-role only,
  validates the fixed family/rule/payload, suppresses no-change writes,
  supersedes the prior row atomically and enforces the write ceiling. A
  background service may supply the subject ID only because the entrypoint is
  not granted to members.
- `public.zyra_suppress_insight_family(p_family_key text, p_reason text)`:
  service-role only, changes active facts to suppressed; no deletion.

The two-store D5 limit leaves no durable third config table. Preserve it with a
server deployment allowlist that defaults to no enabled families plus the
service-only bulk suppression RPC. The operational kill procedure must disable
future batch publication and suppress current facts in the same release. Do
not claim this is an installed-build presentation fallback.

### 7.3 Staged migration plan (future only)

1. Revalidate §5 on a real verified population and obtain a new Founder
   decision for any revised privacy mechanism.
2. Create one staged migration containing private tables, constraints,
   indexes, RLS/revokes and hardened functions; do not apply.
3. Run local disposable-database SQL, RLS, allowlist, idempotency, retention,
   write-ceiling and keyset tests.
4. Fable verifies source/hash/evidence; Founder separately authorises apply.
5. Apply, then live-probe grants/RLS/functions with anon/authenticated/service
   roles. Do not create/backfill facts.
6. Enable computation only after privacy policy/DPIA Insights sections and an
   explicit Founder enablement GO.

## 8. Challenges requiring Fable/Founder disposition

### C1 — Guardian contradiction

Founder-direct source says build Guardian Today · Updates · Insights; current
production and tests do so. DR-ZYRA-222, the Insights master, inventory V3 and
032 say Guardian is untouched and sequenced after a separate presentation
decision. The later documentation may supersede the earlier direct instruction,
but the current record does not state that explicitly. Do not silently remove
or bless the Guardian tabs. Required disposition: Founder confirms either
“Guardian three-tab remains approved” and the documents are amended, or
“Guardian returns to the pre-build presentation” and supplies/authorises the
exact revert source.

### C2 — “Untouched resolver/adapter” is not sustainable

The resolution model was already changed in the pre-contract build. Per-tab
truthful failure cannot be proved from one aggregate health field, and the
future bounded Updates RPC necessarily changes the adapter or introduces a new
typed adapter boundary. Approve the smallest typed extension rather than
preserving an inaccurate change-surface promise.

### C3 — Workstream sequencing ambiguity

032 §5 says build Workstream B only if Discovery Health passes. Discovery
Health failed, but the governed S16 Updates RPC is also missing and does not
depend on Insight stores. Fable/Founder should state whether the Updates RPC:

1. is authorised as an independent Workstream A conformance correction after
   verification; or
2. remains deferred with all of Workstream B.

Until resolved, leave the current client-assembled Updates path in place and
record it as known partial conformance.

### C4 — Live six-level comparison cannot be truthfully supplied

No exact callable legacy renderer exists on current disk, and Codex may not use
git to retrieve one. Remove the selector requirement or supply the governed
legacy source snapshot. Do not relabel the concept Lab as the old production
renderer.

### C5 — Discovery Health cannot proceed under the present invariant

Deterministic count/bucket output cannot prove absolute one-person stability at
every boundary. Current live data also has no real verified population.
Therefore no Phase 2 Insight construction is eligible for GO. The safe
contractual fallback is already defined: honest-empty, no stores.

## 9. Requested disposition

1. Verify this Phase 1 report under OA-ZYRA-281 and correct the stale Insights
   master hash recorded in 032.
2. Reconcile C1 Guardian authority before any Guardian edit.
3. Accept A3 removal plus the S4/label/per-tab-failure corrections as the
   proposed Workstream A patch surface, then seek a separate Founder Phase 2
   GO.
4. Decide C3 so the Updates RPC is either independently authorised or
   explicitly deferred.
5. Record Discovery Health **FAILED/DEFERRED**. Do not create
   `insight_facts`, `insight_feedback`, a migration or a production Insight
   card.
6. Remove or resolve the impossible legacy-selector requirement before Phase 2.

No Phase 2 construction is requested by this message.
