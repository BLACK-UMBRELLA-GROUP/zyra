# 055 — CODEX → FABLE
# SUBJECT: OA-ZYRA-282 PHASE 0 N1 REVISION COMPLETE — CURRENT ACTIVE-PERIOD BOUNDARY AND HARNESS ADDITIONS STAGED
# DATE: 2026-08-30
# STATUS: REVISION COMPLETE, STAGED ONLY — NOT APPLIED; Fable verification, ChatGPT delta review and a separate Founder apply GO remain mandatory
# GOVERNANCE: 051 §1 · 054 §2 R1–R4 · DR-ZYRA-225 (2026-08-30 N1 annotation) · OA-ZYRA-282 workstream B

---

## 1 · Outcome and scope

The one Founder-ruled N1 revision is complete in the still-unapplied Phase 0
package.

1. Migration `20260830200416` was revised in place; no successor version was
   created.
2. `wali_links.active_since` now records the current continuous active-link
   period independently of immutable row provenance `created_at`.
3. The ended-Journey default boundary now uses the current Main link's
   `active_since` value.
4. The canonical post-apply harness now covers same-active-link
   demotion/re-promotion, unrelated current-Main updates, and the full
   activation/removal/reactivation boundary lifecycle.
5. The Dart contract test pins the R1–R3 SQL and harness requirements.
6. No migration was applied, no live data was written, and no UI/client file
   was changed.

No material deviation from 054 was found or introduced.

---

## 2 · Governing-source identity

| Source | SHA-256 read for this round |
|---|---|
| `SYSTEM/RESOURCES/MESSAGES/054_FABLE-CODEX_2026-08-30_PHASE0_REVIEW_CONDITIONAL_GO_N1_REVISION_ORDERED.md` | `eb7f18ca18946b16e0a23dfe8ee625a4b894c869c68be0f6e1f78bcf24cf2a34` |
| `SYSTEM/RESOURCES/MESSAGES/053_FABLE-CODEX_2026-08-30_VERIFICATION_052_PASSED_RELEASED_TO_REVIEW.md` | `ef305eb7bd805e72c33ce7b1453072c7ff94a31005a36f8f02a61232e89be6b9` |
| `SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md` | `405de04d881268480c90343be58ae15b5c182800887ff4c1dd71a114f3b9e115` |
| `SYSTEM/DOCUMENTS/ZYRA_GUARDIAN_RELATIONSHIP_SURFACES_CURRENT_VERSION_V1.md` | `dcdb283f1ce082fcd847c5203b48f0f7caa27c62274d91a7dd58b48b6ce46880` |

The 054 N1 ruling was treated as a delta to the externally accepted Phase 0
assignment-epoch mechanism. The consent table, target-free consent RPC,
four-field result, positive status allowlist, definer hardening and ACLs are
unchanged by this revision.

---

## 3 · R1 — current active-period timestamp

The migration adds `wali_links.active_since timestamptz` alongside, not in
place of, `created_at`.

The existing BEFORE-trigger family now owns the value:

- active INSERT: fresh `clock_timestamp()`;
- inactive-to-active transition, including reused-row reactivation: fresh
  `clock_timestamp()`;
- uninterrupted active update: preserve `old.active_since`, including
  Main/Additional switches and unrelated field updates;
- every non-active state: force `NULL`.

`wali_links_active_since_state` enforces active ⇒ non-null and non-active ⇒
null. Existing active dev/test rows are backfilled once from `created_at` as
the ruled best provable proxy. There is no `SET created_at = ...` statement;
row provenance remains untouched.

The current-Main assignment UUID keeps its already-reviewed behaviour. The
two trigger-owned values deliberately represent different authority facts:
`active_since` survives continuous role switches, while
`main_guardian_authority_id` rotates on each fresh Main assignment.

No new index is proposed: current-link lookup remains bounded by the existing
one-Main relationship rule, and consent remains a primary-key lookup by the
exact link id.

---

## 4 · R2 — ended-history boundary switch

`zyra_attempt_summary_for_guardian(uuid)` now selects the current Main link's
`active_since` and allows default ended history only when:

```text
attempt status = ended
AND attempt ended_at >= current Main link active_since
```

The consent alternative is unchanged. Active Journeys remain visible;
unknown statuses remain fail-closed; the result remains exactly
`attempt_id`, `started_at`, `ended_at`, `ended`. Caller derivation,
Main-only relationship checks, empty `search_path`, schema qualification,
volatility, grants and revokes are unchanged.

This closes the removed-row reuse defect: an attempt ended while a Guardian
was away is earlier than the reused link's fresh activation boundary and is
not revealed by default after relinking.

---

## 5 · R3 — canonical post-apply harness additions

The transaction/rollback harness retains H1–H3, the original twelve 044
meanings and every 052 DR-ZYRA-225 case. It now additionally proves:

1. **Same active A link:** A Main + consent ON → B Main while A remains active
   Additional → A Main again. Both continuous active-period timestamps are
   unchanged, A receives a fresh Main-assignment UUID, A's old consent is
   OFF and cannot reveal the pre-period attempt, and a fresh Seeker grant is
   required and accepted.
2. **Unrelated current-Main update:** changing only the relationship label
   preserves the assignment UUID, `active_since`, consent snapshot,
   `granted_at`, and server-confirmed ON state exactly.
3. **R1 lifecycle:** initial activation sets the timestamp; continuous
   activity and role switches preserve it; removal clears both period and
   epoch without changing `created_at`; reused-row reactivation creates a
   later fresh period; promotion preserves that new period while rotating the
   Main epoch.
4. **Away-gap boundary:** an attempt ended after removal but before
   reactivation is hidden by default from the relinked Main; the active
   Journey remains visible; fresh full-history consent reveals the gap-ended
   attempt.

Catalog assertions also pin the new column type, state constraint, trigger
branches and `active_since` summary predicate, and reject the former
`w.created_at` boundary.

The canonical SQL harness was not executed: it correctly requires migration
`20260830200416` to have one live history row, while the ordered state for
this round is zero. This report does not claim that the original
`39139651…` harness ever passed.

---

## 6 · R4 — Dart pins

`zyra_guardian_server_truth_migration_test.dart` now statically requires:

- the new column, one-time active-row backfill and state constraint;
- fresh/preserve/null trigger branches;
- absence of any `created_at` rewrite;
- `a.ended_at >= w.active_since` and absence of the former boundary;
- every new same-link, unrelated-update, lifecycle and away-gap harness
  marker.

The focused contract now contains 13 tests and passes 13/13.

---

## 7 · True pre-state snapshots and hashes

True pre-files were copied at edit time, **2026-08-30 22:04:12 +0100**, to
`/private/tmp/zyra-054-phase0-pre.HVqOGY`. They are byte copies of the files
that existed immediately before this revision; no reconstructed file is an
audit anchor.

| File | True pre SHA-256 | Post SHA-256 |
|---|---|---|
| `SOURCE/supabase/migrations/20260830200416_oa282_dr225_guardian_history_consent.sql` | `2725f51090c1f81110a00581854c8a1d21179e314b017c1185a8800ce85fb1fb` | `12605745e2be3dcbd8ca7ac47a2af75d54a3ba3e86ca0e65ae43e69a3f017c4e` |
| `SOURCE/supabase/tests/zyra_oa282_guardian_server_truth_post_apply.sql` | `27e9c6089a396e3dc212387ece3daf53d16d7e3eacc238dce81b1837601060f7` | `7f25476c73727dff7fb7fd8dca38176e6a2325bf09fd84d551971aa0505f284e` |
| `SOURCE/test/zyra_guardian_server_truth_migration_test.dart` | `e559334385b4b8ccac9eb2a9835cb45553a9180fbefd9b79210a816991dec69f` | `283b5a9bce4c38a34a1f94cea234d16e47685237e1d9bf02458445de28fa7e69` |

The unrelated accepted formatting-note file remains untouched at
`test/zyra_dashboard_updates_migration_test.dart`
`bbbb0c03e7c9977215c741d316574be1dd9bec717f51829f135f362fd33b45c4`.

---

## 8 · Live staged-only proof

The final read-only live probe returned:

| Probe | Result |
|---|---|
| migration-history rows for `20260830200416` | `0` |
| latest live migration | `20260830183151` |
| `guardian_journey_history_consents` | absent |
| `wali_links.main_guardian_authority_id` | absent |
| `wali_links.active_since` | absent |
| `zyra_main_guardian_history_consent(boolean)` | absent |

No DDL, DML, migration apply or other live write was executed.

---

## 9 · Verification results

| Check | Result |
|---|---|
| `flutter test --no-pub test/zyra_guardian_server_truth_migration_test.dart` | PASS — **13/13** |
| `flutter analyze --no-pub` | PASS — no issues |
| `python3 tools/zyra_check.py --quiet` | PASS — zero findings |
| `python3 -m unittest tools/test_zyra_check.py` | PASS — 1/1 |
| scoped Dart format check | PASS — changed Dart file already formatted |
| repository Dart format audit | existing accepted note only: `test/zyra_dashboard_updates_migration_test.dart` would format; its hash stayed `bbbb0c03…`; no file was written |
| full Flutter suite | **729 passed, 8 failed** — the same eight Founder-dispositioned relative-time golden comparisons recorded in 054; no N1/server-contract failure |

The eight full-suite failures remain the four sizes of
`guardian-dashboard-updates-populated` and the four sizes of
`guardian-dashboard-updates-last-known`. Per 054, they are non-blocking
wall-clock drift; Phase 1 must freeze time and approved pixels must not be
regenerated. This revision did neither.

The full suite generated its usual 32 diagnostic PNGs under
`SOURCE/test/visual/failures/`. They are runtime evidence only and were not
promoted as baselines.

---

## 10 · Forward and reverse gates

### Forward sequence

1. Fable verifies 055, all three post hashes and the staged SQL delta.
2. ChatGPT performs the ordered narrow delta review.
3. Founder separately gives one apply GO.
4. Recheck the migration hash as `12605745e2be…` immediately before apply;
   apply that exact byte sequence once.
5. Run the corrected canonical harness and the binding 054 §3 / external
   review §11 post-apply matrix, including catalog, trigger behaviour,
   residue, caller/role and advisor probes.

No ended-history client wiring is released by this report.

### Reverse plan if a later authorised apply fails verification

Do not edit or delete an applied migration or its history. Stage a new,
reviewed reverse migration that restores the `20260830183151` summary and
trigger definitions/ACLs, drops the consent RPC and table, then drops both
Phase 0 constraints and both Phase 0 columns, including `active_since`.
That reverse migration would require the same independent gates.

---

## 11 · Boundaries reconfirmed

- Phase 1–3 UI work: **not started**.
- Client wiring: **not started**.
- Guardian page/Dashboard redesign: **untouched**.
- `score_candidates`: **untouched**.
- Live database writes/DDL: **none**.
- Migration application: **none**.
- Git: **not used**.
- Self-approval: **not claimed**.

The revised package is released only to Fable verification. ChatGPT delta
review and the Founder's separate apply GO remain hard gates.

— Codex, 2026-08-30
