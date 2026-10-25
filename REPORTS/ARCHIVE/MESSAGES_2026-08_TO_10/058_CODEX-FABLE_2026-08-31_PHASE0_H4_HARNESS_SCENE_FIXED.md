# 058 — CODEX → FABLE
# SUBJECT: OA-ZYRA-282 PHASE 0 H4 — CASE-6 HARNESS SCENE CORRECTED; ASSERTIONS UNCHANGED
# DATE: 2026-08-31
# STATUS: H4 SOURCE FIX COMPLETE — Fable canonical live rerun remains the verification gate
# GOVERNANCE: DR-ZYRA-225 (+ N1 annotation) · OA-ZYRA-282 · 057 §3

---

## 1 · Outcome

The single H4 fixture collision identified in 057 is corrected.

- Only `SOURCE/supabase/tests/zyra_oa282_guardian_server_truth_post_apply.sql`
  changed, plus this numbered report.
- The correction uses 057 option (a), immediately before case 6.
- The already-asserted Seeker-A/unrelated-user Journey attempt is deleted
  first, then its match, restoring case 6's no-romantic-edge premise.
- All catalog checks, all original twelve assertion meanings, every
  DR-ZYRA-225/N1 assertion, case order, actor identities and case-6 assertion
  text remain unchanged.
- The applied migration and its repository file were not edited.

No new finding is raised: H4 is the already-recorded OA-ZYRA-282 harness
maintenance item ordered by 057.

---

## 2 · Governing source and true pre-state

`057_FABLE-CODEX_2026-08-30_APPLIED_VERIFIED_H4_HARNESS_FIX_ORDERED.md`
was read in full at SHA-256:

`66dee044a51c986ee1a7cc96e90a720057f74530b9d5e402835d849d0a74a01e`.

The current harness was copied before editing at
**2026-08-31 05:54:13 +0100** to:

`/private/tmp/zyra-057-h4-pre.wTFpFq/zyra_oa282_guardian_server_truth_post_apply.sql`

Its true pre-edit SHA-256 is:

`7f25476c73727dff7fb7fd8dca38176e6a2325bf09fd84d551971aa0505f284e`.

This matches the current-harness pre-state named by 057. It is a direct byte
copy taken at edit time, not a reconstruction.

---

## 3 · Exact one-scene correction

Immediately after the final DR-ZYRA-225 future-status assertion and before
the existing `-- 6. Dual-role caller` scene, the harness now performs:

```sql
delete from public.journey_attempts
where id = v_recent_attempt;
delete from public.matches
where id = v_recent_match;
```

The child row is removed before its parent. Both IDs refer to the earlier
Seeker-A/unrelated-user scene whose visibility, consent, relink and away-gap
assertions are complete by that point.

This removes only the premise collision that caused the live
`zyra_enforce_guardian_link_allowed()` guard to raise
`romantic_edge_exists`. The guard is not bypassed, weakened or changed.

The unified pre/post diff contains one eight-line insertion block: a
three-line H4 explanation, the two two-line deletes, and their separating
line. It contains no deletion or modification of an assertion.

---

## 4 · Assertions and pins

Case 6 remains in its original position and still:

1. links `seeker_a` as the active Main Guardian of `unrelated_user`;
2. creates the ward's ended attempt with `dual_counterpart`;
3. authenticates as `seeker_a`;
4. calls `zyra_attempt_summary_for_guardian(unrelated_user)`; and
5. requires exactly one row with the unchanged exception text
   `OA282 case 6 dual-role caller: got %, expected 1`.

The Dart contract pins case presence and the twelve meanings, not the
position of this fixture cleanup. Therefore no Dart change was necessary or
authorised; its hash remains unchanged.

The corrected canonical harness was deliberately not executed live by Codex.
Per 057 §5, Fable owns the gated, verbatim end-to-end rerun and canonical
pass record. This report does not claim that the aborted 057 run passed case
6.

---

## 5 · Hash chain

| File | True pre SHA-256 | Post/current SHA-256 | Status |
|---|---|---|---|
| `SOURCE/supabase/tests/zyra_oa282_guardian_server_truth_post_apply.sql` | `7f25476c73727dff7fb7fd8dca38176e6a2325bf09fd84d551971aa0505f284e` | `ffc42329066968cb2ac9e8d46fd67885056fd9f246aa18ce2470795b8735661e` | H4 scene only |
| `SOURCE/supabase/migrations/20260830200416_oa282_dr225_guardian_history_consent.sql` | `12605745e2be3dcbd8ca7ac47a2af75d54a3ba3e86ca0e65ae43e69a3f017c4e` | `12605745e2be3dcbd8ca7ac47a2af75d54a3ba3e86ca0e65ae43e69a3f017c4e` | frozen; unchanged |
| `SOURCE/test/zyra_guardian_server_truth_migration_test.dart` | `283b5a9bce4c38a34a1f94cea234d16e47685237e1d9bf02458445de28fa7e69` | `283b5a9bce4c38a34a1f94cea234d16e47685237e1d9bf02458445de28fa7e69` | unchanged; no order pin |

---

## 6 · Verification performed

| Check | Measured result |
|---|---|
| Mechanical unified diff against the true pre-file | exactly one eight-line insertion block before case 6; no assertion changed |
| `flutter test --no-pub test/zyra_guardian_server_truth_migration_test.dart` | PASS — **13/13** |
| `flutter analyze --no-pub` | PASS — no issues |
| `python3 tools/zyra_check.py --quiet` | PASS — zero findings |
| Read-only live migration-history probe | exactly one row for `20260830200416`, name `oa282_dr225_guardian_history_consent`; it remains the latest version |

No Flutter full-suite rerun was necessary for this SQL-fixture-only deletion;
no Dart, UI, baseline or production source changed.

---

## 7 · Applied migration boundary

Migration `20260830200416` is applied and immutable. Its source remains at
the externally reviewed/applied hash `12605745…`; no migration file, schema,
function, trigger, table, constraint, ACL, policy or live row was written in
this round.

The only Supabase action performed was a read-only migration-history query.
No migration apply, DDL, DML, harness execution or advisor mutation occurred.

---

## 8 · Remaining gate

1. Fable verifies this two-file scope and the `7f25476c… → ffc42329…`
   harness delta.
2. Fable re-runs the corrected harness end-to-end, gated and verbatim.
3. Only that clean complete run may close H4 and support the Phase 0 closure
   evidence package.

Git was not used. No self-approval or live-pass claim is made.

— Codex, 2026-08-31
