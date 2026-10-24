# ZYRA Learning Loop — P1 Historic-Data Audit

**Version:** V1  
**Status:** CURRENT_VERSION — P1 TECHNICAL AUDIT COMPLETE; PRODUCTION LEARNING INACTIVE  
**Date:** 2026-08-25  
**Author:** Codex, Lead Architect  
**Authority:** OA-ZYRA-259 and `ZYRA_LEARNING_LOOP_CURRENT_VERSION_V1.md`  
**Scope:** Read-only repository/schema audit plus aggregate live-volume probes. No names, messages, answer values or profile values were read.

## 1 · Executive result

The app already holds useful **current state** and Journey lifecycle signals,
but it does not yet hold every historical sequence needed by the draft
learning model. A production learning engine cannot be switched on honestly
from the present client or schema.

- Journey attempts and timeline milestones can support cautious, server-side
  stage-pattern aggregation once enough real, distinct counterparts exist.
- Save / Consider / Set Aside tables describe the latest state only. They are
  not a complete behavioural event history.
- Onboarding and Seeker preference rows describe the latest answer set only.
  They do not show how a priority changed over time.
- The current compatibility RPC returns one overall score. Existing category
  JSON in Journey rows is sparse/mock-era data and is not an approved category
  scoring foundation.
- Location is free text, is deliberately excluded from scoring, and has no
  honest search-pool-impact aggregator.
- All current onboarding and Seeker-detail rows are marked synthetic. They are
  unsuitable for tuning evidence thresholds or production claims.

The safe P1 output is therefore the developer-only mock surface and this
audit. No production inference, persisted feedback, preference mutation or
ranking influence was activated.

## 2 · Aggregate live-volume measurement

Measured read-only against Supabase project `sxoaxonzjqkgajmlagyk` on
2026-08-25. Counts are project-wide aggregates, not user-visible conclusions.

| Source | Rows | Distinct owners / pairs | Distinct counterpart-side IDs | Observed date span |
|---|---:|---:|---:|---|
| `saves` | 18 | 3 owners | 18 | 2026-07-26 to 2026-08-20 |
| `likes` (Consider) | 5 | 3 owners | 5 | 2026-07-26 to 2026-08-20 |
| `passes` (Set Aside) | 2 | 1 owner | 2 | 2026-08-20 only |
| `matches` | 5 | 5 A-side IDs | 3 B-side IDs | 2026-08-10 to 2026-08-18 |
| `journey_attempts` | 5 | 5 matches | 1 ended-by ID | 2026-08-10 to 2026-08-18 |
| `timeline_milestones` | 22 | 5 timelines | — | 2026-08-07 to 2026-08-18 |
| `onboarding_answers` | 144 | 144 users | — | 2026-08-10 only |
| `seeker_details` | 144 | 144 users | — | one 2026-08-21 seed timestamp |

Additional probes:

- Journey attempts: 4 active, 1 ended; one active row records a pause.
- Milestones include 3 `journey_started`, 1 `journey_paused`, 1
  `journey_ended`, 1 each of `phase_1_complete`, `phase_2_complete` and
  `phase_3_complete`, plus other lifecycle events.
- `journey_compatibility`: 3 rows; 2 contain category JSON. The present keys
  are Communication, Deen, Family Expectations, Lifestyle and Marriage
  Goals, each occurring twice across the two Seeker-side JSON objects.
- `journey_phase_answers`: 60 rows across 2 attempts.
- `journey_phase_ratings`: 23 rows across 2 attempts.
- `onboarding_answers`: 144 synthetic, 0 non-synthetic.
- `seeker_details`: 144 synthetic, 0 non-synthetic.

These volumes do not meet the draft's per-user evidence rules for a truthful
production launch. Project-wide row counts must never be mistaken for one
Seeker having three or five independent counterpart experiences.

## 3 · Source-by-source capability audit

| Draft source | Reality now | Classification | Production requirement |
|---|---|---|---|
| Save / Consider / Set Aside | Three RLS-protected current-state tables with timestamps. Applied migration `20260803112115_one_state_per_profile_saves_likes_passes_exclusive.sql` deletes the other two states when a new choice wins. `zyra_reset_search()` also deletes the caller's pass rows. | **Partial** | If longitudinal choice patterns are approved, add an append-only, row-scoped event design. Do not repurpose current-state rows as history. Migration needs separate Founder authority. |
| Matches | Pair and lifecycle state exist. | **Partial** | Aggregate through an authorised server projection; never expose the other participant or infer why a Journey changed. |
| Journey attempts | Attempt history, stage, start/end/pause fields and declared end reason exist; direct client access is deliberately revoked. | **Possible with server aggregation** | New SECURITY DEFINER read model/RPC with strict participant scope, anonymity floor and safety-reason exclusion. Migration authority required. |
| Timeline milestones | Canonical lifecycle events exist and cover start, pause, end and several stage completions. | **Possible with server aggregation** | Count distinct counterpart pairs and canonical stages in a bounded rolling window; never return pinpointing dates/details. |
| Current preferences / hard requirements | Current JSON exists in `onboarding_answers` and `seeker_details`; own-row RLS applies. | **Current state only** | A defined version/event history is required for priority drift. Article 9 fields remain legally gated. |
| Compatibility overall score | `score_candidates()` returns candidate ID + one overall score. | **Limited** | Overall trend is technically aggregable only after real data, rules and an authorised server projection exist. |
| Compatibility categories | Sparse category JSON exists in 2 Journey rows, while the app currently mirrors the overall score into each displayed category because no approved category output exists. OA-ZYRA-193(d) still carries category-model drift. | **Blocked as an evidence source** | Ratify canonical category names/count, calculate real per-category scores, backfill policy if any, and verify synthetic-vs-real separation. |
| Search-pool impact | Browse filters role, opposite gender, active, complete and photo availability. `location_text` is free text; the scoring migration explicitly excludes it because region/country/distance cannot be computed honestly. | **Blocked** | Structured geography and a privacy-safe before/after eligible-pool count projection. Do not show the location mock as measured truth. |
| Preference changes over time | Only the latest `updated_at` row is retained. | **Blocked** | Append-only preference-change evidence or snapshots with retention/deletion rules. |
| Messages | Stored but explicitly prohibited by the rules draft. | **Never source** | No implementation. |
| Guardian-originated information | Exists in separate Guardian/Journey structures but is prohibited for Seeker learning v1. | **Never source** | No implementation. |

## 4 · Insight-family feasibility

| Draft family | Feasibility now | Reason |
|---|---|---|
| Strongest recurring alignment | **Blocked** | No approved category-scoring output; current category rows are too sparse and mock-era. Faith/religious-practice output is also Article 9 gated. |
| Common recurring difference | **Blocked** | Needs real per-dimension difference tallies across distinct counterparts; current overall score is insufficient. |
| Preference pool-impact | **Blocked for location; design needed for other fields** | No structured location or before/after eligible-pool RPC. Other fields still need an approved eligible-pool definition and privacy-safe aggregation. |
| Journey-stage pattern | **Schema-capable, data/rules pending** | Attempts and milestones exist, but the live set is too small and a participant-scoped aggregator is absent. Correlation only; no cause. |
| Positive progression correlate | **Needs aggregation and more real data** | Stage depth can be related to approved non-sensitive dimensions only after category/attribute truth and anonymity rules are implemented. |
| Priority drift | **Blocked** | Current choices and current preferences exist, but complete action history and preference-version history do not. |

An honest insufficient-data state is possible immediately. It does not need a
learning engine and is represented in the P1 mock.

## 5 · Required production foundations

No item below was built in P1.

1. Founder ratification of the learning rules and final copy.
2. Reconciliation of the entitlement contradiction in §6 below.
3. Canonical compatibility categories and real per-category scoring
   (dependency: OA-ZYRA-193(d)); no tuning on synthetic data (OA-ZYRA-190).
4. A server-side, participant-scoped aggregation contract that returns only
   thresholded, anonymous facts—not raw other-person events.
5. An explicit data model for eligible insights, confirmation, dismissal,
   family suppression, expiry and revocation.
6. If priority drift is retained, an approved append-only history design for
   decisions/preferences with retention and erasure behaviour.
7. A structured geography/pool-impact foundation before any location-impact
   claim.
8. Article 9 lawful-basis confirmation and privacy-policy disclosure before
   religious/ethnicity-derived families activate.
9. Separate migration authority for every schema/RPC/RLS change, with a repo
   migration file in the same change.

## 6 · Contradictions and corrections for Fable verification

1. **Basic entitlement:** `ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V5.md` §6 says
   ZYRA Intelligence—Recommendations, Insights and Summaries—is unavailable
   on Basic; the OA-ZYRA-259 draft gives Basic one insight. This is a real
   source-of-truth conflict. The P1 Basic/One switch is mock-only. Production
   tiering waits for Founder ratification and Product Spec reconciliation.
2. **Existing sources are not all historical evidence:** Learning Loop §4
   says no new collection is introduced, but Save/Consider/Set Aside and
   preference tables retain latest state, not the full sequence needed for
   drift. The rules source should distinguish current-state sources from an
   approved future event/aggregation requirement.
3. **Timeline coverage is usable but not sufficient by itself:** stage events
   exist, but current live volume includes only one pause and one ending. No
   personal conclusion should be generated from that project-wide fact.
4. **Location pool impact is not currently measurable:** the mock is useful
   for design review only and is labelled accordingly.

## 7 · Security and privacy boundary

- Every audited user-data table has RLS enabled.
- `journey_attempts` intentionally exposes no direct client grants/policies;
  future reads must use an approved participant-filtered RPC.
- `seeker_details` contains Article 9 data and remains own-row scoped.
- Aggregate probes read counts, timestamps and category keys only. They did
  not read names, messages, answer text, preference values, end notes or
  profile values.
- Insights remain Seeker-only. No Guardian mock was added.

## 8 · Migrations and activation

No migration was created or applied. No RLS policy, RPC, trigger, table,
stored preference, entitlement or production ranking changed.

Production learning remains inactive under OA-ZYRA-259 P1. The only visible
output is the authorised developer mock documented in the implementation
handover.

---

## Version history

| Version | Date | Change |
|---|---|---|
| V1 | 2026-08-25 | First aggregate live-data and repository feasibility audit for OA-ZYRA-259 P1. |
