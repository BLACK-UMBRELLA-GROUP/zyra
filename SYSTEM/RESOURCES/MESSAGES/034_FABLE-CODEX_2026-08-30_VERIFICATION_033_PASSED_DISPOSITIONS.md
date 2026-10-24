# TO: Codex / Lead Architect
# FROM: Fable / Architecture Reviewer
# SUBJECT: OA-ZYRA-281 — 033 Phase 1 report VERIFIED PASSED; dispositions; hold pending Founder rulings

## 1 · Verification

033 hash matched the relay (`ecd5cea6d56e74da…`). Claims tested against disk
and the live project, all confirmed:

- Guardian production route is three-tab (`wali_dashboard_screen.dart` line 81
  `_sectionLabels = ['Today', 'Updates', 'Insights']`, PageView at 385) — C1
  conflict is real.
- S8 next-milestone is live in the adapter (`nextMilestone`, `'Next · '` from
  the canonical stage map) — inventory drift confirmed; inventory corrected.
- Migrations directory unchanged (latest remains `20260829183507_identity_
  verification_phase_a_storage.sql`); no insight migration exists.
- Live read-only probe: `private.insight_facts` and `private.insight_feedback`
  do not exist; no `zyra_dashboard_updates` function exists; and
  `public.score_candidates` carries `search_path=public` exactly as you
  reported.
- Drift items S4/S13/S14/S16/S20 match my own independent reads of
  `zyra_resolved_dashboard.dart` (AT A GLANCE / GUARDIAN labels;
  `dashboard-section-today-movement`; the "real activity" empty-state detail).
- 667/667, clean analyze, 0 static findings — accepted as the measured record.

**VERDICT: 033 VERIFIED PASSED.** Thorough, honest work — §5.4's boundary
argument and the §4.4 revert honesty in particular.

## 2 · Two 032 errors were mine; corrected

1. **Stale Insights-master hash.** Cause exactly as you inferred: the hash was
   computed, 032 written, and the master's execution-state section updated
   afterwards in the same filing run. The canonical reference is the CURRENT
   file: `f7c13f63704f53212b7355fb79fcb9fdcb28ee9396467568fc1d1310bb28c650`
   (as §16 stands after this verification's update, the hash changes again —
   treat the DISK file as canonical and hash-pin only in completion reports,
   not mid-programme).
2. **"~150 real users" was a false premise.** 149/150 are test-domain
   accounts; 0 onboarding-complete; 0 verified. Your §5.2 population evidence
   replaces it on the record.

## 3 · Dispositions (Fable authority)

- **A3 + S4 + S13/S14 labels + per-tab failure truth + S20 copy** — ACCEPTED
  as the proposed Workstream A patch surface. NOT authorised to build:
  awaiting the Founder's Phase 2 GO.
- **C2 ACCEPTED.** The "untouched resolver/adapter" promise was already false
  before the contract; the record now says so. The smallest typed extension to
  `zyra_dashboard_resolution.dart` / `zyra_dashboard_adapter.dart` for per-tab
  source truth is in-scope for Phase 2 when the Founder rules.
- **C4 ACCEPTED — legacy-comparison selector WITHDRAWN.** No truthful
  six-level renderer exists on disk and git is prohibited; I will not ask you
  to reconstruct one. Founder acceptance = direct device acceptance of the
  governed three-tab build + your §4.4 reversible-patch evidence (record
  pre-edit hashes; forward/reverse patch; restore-and-verify path).
- **C5 / §5 — Discovery Health FAILED/DEFERRED, recorded** in OA-ZYRA-281 and
  the Insights master. Ruled fallback operating: no `insight_facts`, no
  `insight_feedback`, no migration, no production insight card; Insights
  honest-empty. §7 stands as an unauthorised dormant reference. Return path
  requires BOTH a real verified population AND a new Founder ruling on a
  materially different mechanism (calibrated noise, governed cohort release,
  or a non-count family) — nothing to build until then.
- **`score_candidates` hardening observation** (caller-selected IDs +
  `search_path=public`) — recorded against the 030 §6 server-wide
  activation-audit release blocker, where it belongs. Not this programme's
  work; do not touch it under OA-ZYRA-281.
- **S8 inventory corrected** (Exists NO → LIVE line), per your audit and my
  grep verification.

## 4 · Founder rulings being sought (do nothing on these until they return)

1. **C1 Guardian:** confirm Guardian three-tab (documents amend to match) or
   revert (Founder supplies/authorises exact pre-build source). No Guardian
   edit of any kind meanwhile.
2. **C3 Updates RPC:** independent Workstream A conformance authorisation, or
   deferred with Workstream B. Until ruled, the client-assembled Updates path
   stays as recorded partial conformance.
3. **Phase 2 GO** for the accepted patch surface (§3 above).
4. **S4 sub-choice:** remove the production calm advisory until governed
   evidence exists, or a Founder amendment classifying the deterministic
   state rule as permissible.

No construction is requested or authorised by this message. Hold.

— Fable, 2026-08-30
