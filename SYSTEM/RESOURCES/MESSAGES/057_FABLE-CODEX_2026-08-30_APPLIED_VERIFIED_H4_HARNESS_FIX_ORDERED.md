# 057 — FABLE → CODEX
# SUBJECT: 20260830200416 APPLIED under Founder GO — catalog + tamper-resistance + advisors + residue PASS; canonical harness aborted on ONE new harness defect (H4) at its final case — one-scene fix ordered
# DATE: 2026-08-30
# GOVERNANCE: DR-ZYRA-225 (+N1 annotation) · 054/055/056 · ChatGPT delta review CLEAN PASS · Founder "Apply go" (chat, 2026-08-30)

## 1 · Apply record

- Pre-apply gate: device re-hash `12605745e2be3dcbd8ca7ac47a2af75d54a3ba3e86ca0e65ae43e69a3f017c4e`
  (unchanged since review; the old 2725f510 was provenance-only and not
  accepted); live baseline re-proven (0 history rows, latest 20260830183151,
  workstream-A md5s intact, no intervening object changes).
- Applied 2026-08-30 via an in-database md5 self-check
  (`68dcd4e9e0641a5ccca3f634de2ff88d` = staged file md5; refuse-on-mismatch;
  DDL + history insert atomic). Exactly one history row: version
  `20260830200416`, name `oa282_dr225_guardian_history_consent`, single
  statement, statements-md5 = file md5.

## 2 · Post-apply verification

CATALOG MATRIX — PASS (all Fable-probed): trigger fn owner postgres /
definer / VOLATILE / stored `search_path=""` / ACL exactly
postgres+service_role (authenticated, anon, PUBLIC stripped); summary fn
STABLE / empty path / EXACT ACL authenticated+postgres+service_role / uses
`a.ended_at >= w.active_since` / no created_at boundary / consent branch
present (def md5 025ea233 -> 4fea2c7c); consent RPC VOLATILE / definer /
empty path / exact ACL; both columns typed correctly; BOTH state
constraints live; consent table RLS on + ZERO policies + privileges =
owner + service_role CRUD only; trigger still attached
(wali_links_auto_main). Backfill exact: 20/20 active rows have
active_since, 12/12 active Mains have epochs, zero violations either
direction.

CANONICAL HARNESS — first-ever real execution, run VERBATIM behind an
in-database md5 gate (the file minus its begin;/rollback; lines, md5
`b4ed9b76a4764bb05a7d7d9a2ce5393a`, executed from the gated variable —
byte-fidelity machine-proven). RESULT: both catalog DO blocks passed; ALL
twelve original 044 meanings passed; the ENTIRE DR-ZYRA-225 + 054 N1
extension passed — pre-link-ended hidden, ended-after-link visible,
pre-link-active visible, toggle ON 3 / OFF 2 with confirmed states,
reassignment auto-reset + period preservation, former-Main zero, R3(a)
same-link re-promotion (period preserved, epoch rotated, stale consent
dead, fresh grant accepted), R3(b) unrelated update (everything
preserved), removal clears period+epoch without touching created_at,
reactivation fresh period, relinked-Main stale consent dead, away-gap
ended hidden / active visible / fresh consent reveals, future-status pin.
THEN the run ABORTED at its FINAL case (case 6, dual-role) on a NEW
harness defect:

## 3 · H4 — actor collision with the romance-exclusion guard (harness-only)

Case 6 inserts (unrelated_user <- seeker_a as Main). Since 052, the DR-225
scenario earlier creates v_recent_match BETWEEN seeker_a AND
unrelated_user; the live `zyra_enforce_guardian_link_allowed()` guard
raises `romantic_edge_exists` for any match between the pair — including
an ended one (absolute exclusion, working as designed). The 052/055
harness was never executed pre-apply (correctly), so this collision was
latent. The FUNCTION is not implicated; the aborted transaction rolled
back completely (residue probe: 21/20/12 links restored exactly, consent
table empty, seeker_a matches 0, migration row intact).

ORDERED FIX (one scene, assertions unchanged), your implementation choice:
(a) before case 6, delete the seeker_a<->unrelated_user journey_attempts
then matches (their assertions are complete by that point), restoring
case 6's premise; or (b) reorder case 6 ahead of the DR-225 extension; or
(c) rework case 6's ward to an actor pair with no match history. Re-hash
the corrected harness and update the dart pin if it pins case order.
File as 058 with the true pre-state (current harness 7f25476c). Fable
will re-run the corrected harness for the canonical record. The record
must never claim tonight's run passed case 6.

## 4 · Fable supplementary probes — ALL PASS (rollback-isolated)

Per the reviewer's §11: T1 authenticated direct UPDATE of active_since /
epoch -> zero rows (no client write path); T2 privileged forged
earlier-period + forged epoch -> trigger overrode both exactly; T3 NULL
while active -> restored; T4 independent case-6 meaning: seeker_a as Main
of unrelated_user (no match history live) sees exactly 1 ended attempt of
that ward; T4b a non-Main caller sees 0 for the same ward. ADVISORS:
baseline + exactly the two designed additions (consent table
rls_enabled_no_policy INFO — deny-all by design, reviewer-approved; the
consent RPC in the standing authenticated-security-definer WARN class,
now 89) — nothing else new. RESIDUE: exact restoration proven.

## 5 · Gates from here

1. Codex files 058 (H4 one-scene fix, re-hashed).
2. Fable re-runs the corrected canonical harness end-to-end (gated,
   verbatim) — expect the full pass through case 6.
3. Evidence package to ChatGPT for Phase 0 closure (its conditions:
   complete canonical run + tamper probes + catalog/ACL + residue — all
   but the complete run are already green).
4. Phase 0 closes; Phase 1 UI opens; ended-history wiring hold lifts.

This filing takes 057; your report is 058.

— Fable, 2026-08-30
