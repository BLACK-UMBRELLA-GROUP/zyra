# TO: Codex / Lead Architect
# FROM: Fable / Architecture Reviewer
# SUBJECT: OA-ZYRA-281 — 036 Phase 2 completion VERIFIED PASSED; one provenance question; Founder gates restated

## 1 · Verification performed (independent, 2026-08-30)

- **036 hash** matched the relay (`d9d9df80…`).
- **Post-edit hashes:** all 14 change-surface files recomputed on disk —
  14/14 match §8, including the staged migration
  (`b17011aa…`) and the amended Seeker handover (`c12e7fef…`).
- **Evidence pack:** `forward.patch`, `reverse.patch`, `README.md` and the
  candidate manifest hashes all match §9/§10. I reviewed the recorded
  procedure and current-state hashes; I did not re-run the reverse/forward
  cycle on the live tree — your 14/14 both-directions proof plus my
  current-state hash confirmation stands as the record.
- **Code spot-checks:** `dashboard-section-today-movement` exists nowhere in
  `lib/`; the test asserts it `findsNothing` on Today and on Insights; `MY
  ZYRA` and `FAMILY` labels present, `AT A GLANCE` gone; production calm copy
  is "Nothing needs your attention right now" with no preference advisory in
  the production path; S20 empty copy exact; `updatesState`/`insightsState`
  typed on the resolution; `fetchTimelineResult` and
  `currentAttemptIdResult` present as described.
- **Manifest governance:** `automatic_promotion_allowed: false`,
  `device_acceptance_pending: true`, 6 fixtures × 4 = 24 candidates, every
  row `approved: false`, Lab untouched.
- **Migration SQL audit (full read, 352 lines):** contract conforms —
  `stable security definer set search_path=''`; caller only from
  `(select auth.uid())`, null → no rows; limit clamped 1–20; all-or-none
  cursor with SQLSTATE 22023; per-branch ownership predicates; controlled
  template/destination keys only; real `read_at is null` unread on
  notifications only; keyset `(occurred_at, class_key, source_id) desc`
  with tuple cursor; no writes, no count; revoke public/anon, grant
  authenticated + service_role; 20 notification templates + 4 domain
  classes per the ruled allowlist; six indexes.
- **Live probes (mine, read-only):** RPC absent; 0 `%dashboard_updates%`
  indexes; migration history still ends `20260829183507` — staged-only
  holds. `journey_family_review_responses` columns are exactly
  `review_id, wali_id, decision, responded_at` with PK
  `(review_id, wali_id)` — your §12.1 composite-key deviation is verified
  correct against the live schema and ACCEPTED.
- **Security check on the participation join:**
  `public.zyra_my_attempt_participation` is defined with
  `where user_id = (select auth.uid())` — explicitly caller-scoped, not
  RLS-dependent, so it remains correctly scoped inside your SECURITY DEFINER
  function. Confirmed safe.
- **§12.2 tab-state correction:** accepted — smallest-change, regression-
  tested, and required for the acceptance evidence to be true.
- **Measured results** (691/691, analyzer clean, 0 static findings, 232/232
  visual, 24/24 captures, restored-tree 667/667) — accepted as the measured
  record per standing practice.

**VERDICT: 036 VERIFIED PASSED.** Disciplined work — the honest interim
sequencing (§5) and the schema-preserving composite key are exactly right.

One observation for post-apply verification, not a finding: the
milestone-dedup guard checks `meeting`/`nikah` rows only, which is correct
if the proposal/confirmation flow exists solely for those milestone types —
confirm that assumption against real rows at post-apply verification.

## 2 · One provenance question — answer in your next message

`lib/screens/home/seeker_dashboard_screen.dart`: 033 §2.2 recorded
`b40ab5c6…` at 11:33:24, but 036 §8 records pre-edit `a2cd21ab…`. Every
other pre-hash chains exactly to 033. Something changed that one file
between the Phase 1 audit and the Phase 2 pre-edit snapshot. State what
changed, when, and under what instruction, so OA-ZYRA-281 carries an
unbroken chain. This does not block Founder device acceptance (the current
tree is fully hashed, tested and reversible); it must be answered on the
record before or with the migration apply GO.

## 3 · Gates (unchanged)

1. Founder direct device acceptance (24 candidates pending, no
   auto-promotion).
2. Separate Founder GO to apply
   `20260830145711_oa281_dashboard_updates_projection.sql`.
3. Post-apply Fable verification (grants/behaviour probes + the dedup
   assumption above) before any client RPC wiring.

Hold until those return.

— Fable, 2026-08-30
