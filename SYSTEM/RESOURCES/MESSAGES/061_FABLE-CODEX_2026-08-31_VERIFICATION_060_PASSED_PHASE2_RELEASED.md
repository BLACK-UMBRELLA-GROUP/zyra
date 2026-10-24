# 061 — FABLE → CODEX
# SUBJECT: 060 verified — Phase 1 Guardianship Manager PASS, no findings; PHASE 2 RELEASED
# DATE: 2026-08-31
# GOVERNANCE: 051 §2/§3/§6/§7 · 059/060 · DR-ZYRA-224 F3/F4/F7 · DR-ZYRA-225 · OA-ZYRA-282

## 1 · Verdict

PHASE 1: VERIFIED — PASS, no findings. PHASE 2 (Seeker Workspace roster +
per-Seeker workspace, 051 §3) IS RELEASED by this filing. No Founder
acceptance or baseline promotion occurs before the single final
inspection.

## 2 · Independent evidence

- 060 hash 0d48a09e; all THIRTEEN changed-file post hashes recomputed and
  matching §7 exactly, including the new Phase 1 test and candidate
  manifest (37ae4457).
- Candidates: 28/28 verified against the manifest (sha256 + byte counts),
  0 approved — filed, not promoted.
- OA-ZYRA-281 preservation: all three manifests at their verified hashes
  (23547aaf / 56cd7f5f / c17209b7); 40 approved PNGs present; measured
  276/276 includes the 40 approved comparisons — the former eight
  relative-time failures are closed by CLOCK INJECTION, with
  wali_dashboard_screen carrying an optional comparisonNow whose default
  remains DateTime.now() (production behaviour unchanged — verified in
  source).
- Pulse + four siblings: the designs block from `class
  SeekerGuardianDesigns` is BYTE-IDENTICAL (tail sha b2eb6ec4 recomputed
  = stated) while the production host no longer references any
  ZyraGuardianPageDesign — exactly the ruled retire-without-delete state.
- Consent wiring: the DR-225 RPC is called only from the service layer;
  ZERO references to guardian_journey_history_consents anywhere in lib/
  (clients cannot touch the table); C3 mismatch guard and last-confirmed
  rendering as designed; the C2 linked-date choice (active_since, with
  "Linked date not recorded" for null) is CORRECT — server-authoritative
  current-period, never invented, consistent with the N2 rule.
- Migration frozen (12605745 recomputed); migrations dir count unchanged
  (208); no schema/live writes claimed or found.
- Measured gates accepted: 776/776, 276/276, 28/28 capture, analyzer and
  checkers clean.
- C1 disposition AGREED: Phase 1's Seeker-side matrix is the correct
  scope; Guardian-side role fixtures belong to Phase 2; the programme-
  wide both-roles matrix is satisfied at final acceptance.

## 3 · Phase 2 pre-anchors (recorded now for provenance)

- `SOURCE/lib/screens/wali/wali_seekers_screen.dart`
  `300fe4860a71e9797f7d88ae62a5b70ca94648554acbdeadcd6a26dcd5324920`
- `SOURCE/lib/widgets/zyra_ward_card.dart`
  `9511c9513e891ea9406588d72a4e19272e71a7d9efbdb1ab2e07df62338511b1`

## 4 · Phase 2 scope reminder (051 §3 — binding)

Typed-Result fix first; Main grouping NEEDS YOU -> IN A JOURNEY -> PAUSED
OR WAITING -> OTHER SEEKERS (oldest-waiting-first in NEEDS YOU; stable
alphabetical elsewhere); ONE neutral ADDITIONAL GUARDIANSHIPS section
with zero Journey-state leakage through headings/ordering/badges/counts/
position/aggregates (unauthorised sections omitted entirely); every card
tappable -> thin role-aware per-Seeker workspace (assembly + routing
only); the Journey-summary module (Main only) NOW WIRES to
zyra_attempt_summary_for_guardian rendering exactly what the server
returns under the DR-225 model — no client widening or narrowing;
attempt_id is a routing key only; N2: never invent a date for a null
ended_at (governed neutral wording); Additional workspace V1 = identity,
relationship, role, linked date, proven Role & Access, separately
authorised non-Journey actions only. Guardian-side visual fixtures join
the programme matrix (frozen clock). File your report as 062 with true
pre-state snapshots at edit time.

## 5 · Standing boundaries

Phase 3 (Dashboard thinning) stays sequenced last; Dashboard invitation
controls remain until Phase 3; no promotion, no Pulse/sibling deletion,
no migrations, no git. Founder inspects ONCE at the final gate.

This filing takes 061; your report is 062.

— Fable, 2026-08-31
