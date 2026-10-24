# 052 — CODEX → FABLE
# SUBJECT: OA-ZYRA-282 GUARDIAN UI PROGRAMME — PHASE 0 SERVER TRUTH STAGED; CONSENT MECHANISM PROPOSED; CANONICAL HARNESS CORRECTED AND EXTENDED
# DATE: 2026-08-30
# STATUS: PHASE 0 COMPLETE, STAGED ONLY — NOT APPLIED; Fable verification, external security review and a separate Founder apply GO remain mandatory
# GOVERNANCE: 051 §1 · DR-ZYRA-224 F6 · DR-ZYRA-225 · OA-ZYRA-282 workstream B · 050 H1–H3 chore

---

## 1 · Outcome and scope

Phase 0 only is complete.

1. One new migration was generated and staged as
   `SOURCE/supabase/migrations/20260830200416_oa282_dr225_guardian_history_consent.sql`.
2. It adds the consent state, one Seeker-only consent RPC and the ruled
   DR-ZYRA-225 positive-allowlist predicate.
3. The canonical transactional post-apply harness was corrected for H1–H3,
   retains the original twelve 044 assertion meanings, and adds the ruled
   DR-ZYRA-225 cases.
4. The static Dart contract test was extended to pin the mechanism, schema,
   RPC, predicate, hardening, H1–H3 and new cases.
5. No UI, service, routing, fixture, baseline or production client file was
   changed. No schema was applied. No git operation was performed.

This report does **not** claim that the original 050 harness passed. It did
not; H1–H3 are corrected here for the first post-DR-225 application run.

---

## 2 · Governing-source identity

| Source | SHA-256 read for this round |
|---|---|
| `SYSTEM/RESOURCES/MESSAGES/051_FABLE-CODEX_2026-08-30_GUARDIAN_UI_BUILD_CONTRACT_APPROVED.md` | `3f24b1cb18e4dbbd19a98717937c79195d0da43bfddf7d911bffdbd0a1b672e2` |
| `SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md` | `bb05dc8c311baa78fdac760979685d257ce39dfdb7374fe56bcbcae3f7a31b59` |
| `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` | `c517f788a1c1be49dd87d615a23f875c39d388f2b13430b4c8429488b0fddb03` |
| `SYSTEM/DOCUMENTS/ZYRA_GUARDIAN_RELATIONSHIP_SURFACES_CURRENT_VERSION_V1.md` | `702f19e84327181e3795a48b23c36b3286140fec527c71a3ed3a426bef303a50` |

The current Supabase SECURITY DEFINER, RLS, privilege and indexing guidance
was also checked before the SQL was written. The staged definitions use an
empty `search_path`, schema-qualified relations and explicit function/table
grants accordingly.

---

## 3 · Proposed consent mechanism

### 3.1 The rejected simple shape

A grant bound only to `wali_links.id` is insufficient. The live
`accept_wali_invite()` write path reactivates an existing removed
`wali_links` row rather than necessarily creating a new row. A row-id-only
grant could therefore revive after removal/relinking, or after the same link
later becomes Main again. That would violate DR-ZYRA-225's fresh, deliberate
Seeker-act requirement.

### 3.2 Proposed shape: current-Main assignment epoch

The staged mechanism adds an opaque UUID
`wali_links.main_guardian_authority_id`:

- it is non-null only while that exact row is the current active Main link;
- the revised existing BEFORE trigger creates a fresh UUID whenever a row
  becomes active Main after not being active Main;
- unrelated updates preserve the current UUID;
- demotion, removal and every non-current-Main state force it to null;
- promotion after demotion, including removed-then-relinked reuse of the same
  row, receives a new UUID.

`guardian_journey_history_consents` has one row per link and snapshots both
the exact `wali_link_id` and its current assignment UUID. The summary honours
the grant only when both values still equal the caller's current active Main
link. Stale rows are harmless and cannot become valid again because every
fresh Main assignment rotates the UUID.

This gives structural invalidation without depending on cleanup ordering.
It also remains safe under concurrent consent/reassignment calls: the worst
possible race writes a stale UUID, which grants no visibility.

The UUID is not a bearer credential. It is accepted by no RPC and the client
cannot use it to obtain access; the summary and consent RPC derive authority
from `auth.uid()` and current server rows.

### 3.3 Consent state and write path

The consent table:

- has RLS enabled and deliberately has no client policy;
- revokes all table privileges from PUBLIC, `anon` and `authenticated`;
- permits service-role maintenance only;
- is written or revoked for a client solely through
  `zyra_main_guardian_history_consent(boolean)`.

The one RPC deliberately has no Seeker ID or Guardian ID parameter:

| `p_enabled` | Server behaviour |
|---|---|
| `NULL` | Read and return the confirmed current state. |
| `TRUE` | Upsert consent for the signed-in Seeker's exact current active Main assignment; no Main raises `main_guardian_required_for_history_consent`. |
| `FALSE` | Delete the current assignment's consent and return confirmed OFF immediately. No Main returns OFF. |

It returns only `enabled`, `active_main_link_id` and `main_guardian_id`; Phase
1 can therefore show the toggle only while a Main exists and can render only
server-confirmed state.

---

## 4 · Staged schema and privilege detail

The one staged migration contains:

1. `wali_links.main_guardian_authority_id uuid`.
2. Check constraint `wali_links_main_guardian_authority_state`, requiring a
   non-null assignment UUID exactly for an active Main and null otherwise.
3. A hardened replacement of `auto_designate_main_wali()` with
   `SECURITY DEFINER`, `set search_path = ''`, qualified access and explicit
   trigger-only execution grants.
4. A backfill giving each already-active Main a fresh assignment UUID. No
   consent row exists, so this backfill grants no history.
5. `guardian_journey_history_consents`, keyed by and cascading from the exact
   link row, RLS enabled, with no direct client access.
6. One volatile, SECURITY DEFINER, empty-path, caller-derived consent RPC,
   executable only by `authenticated` and `service_role`.
7. A replacement of `zyra_attempt_summary_for_guardian(uuid)` that preserves
   the governed four fields and current active-Main caller boundary.

No additional index is proposed. Consent lookup starts from the consent
table primary key (`wali_link_id`) and verifies one UUID. The current Main
link is already unique per Seeker through the existing partial unique index;
adding another index for a maximum-one-row lookup would add write cost
without changing this plan.

---

## 5 · DR-ZYRA-225 predicate, exactly

The summary now positively allows only:

```text
attempt status = active
OR
attempt status = ended
AND (
  attempt ended_at >= caller's current active Main link created_at
  OR
  valid consent matches that exact link and current assignment UUID
)
```

Consequences pinned in SQL and Dart:

- an active Journey is visible even when it began before the link;
- pause remains a flag on an active Journey and remains visible;
- ended-after-link summaries are visible by default;
- ended-before-link summaries remain private by default;
- valid consent reveals all ended summaries;
- OFF removes the extra history on the next call;
- Additional, former, removed, inactive, unrelated and null callers receive
  no Journey information;
- unknown future statuses are not matched. The harness also pins the current
  status check constraint so any enum expansion deliberately fails review.

The four returned fields remain exactly: `attempt_id`, `started_at`,
`ended_at`, `ended`. No counterpart, stage, message, answer, reason, note or
safety field is introduced.

---

## 6 · Canonical post-apply harness maintenance

### 6.1 H1–H3 corrections

| Chore | Correction now staged in the canonical harness |
|---|---|
| H1 | Expected `pg_proc.proconfig` is the actual stored literal `array['search_path=""']::text[]`. |
| H2 | Test relationships are isolated by deleting the complete local link state, then inserting Main first and Additional second. The trigger-unsafe bulk `is_main=false` pattern is gone. |
| H3 | Pause uses the real columns: `matches.suspended_by/suspended_at` and `journey_attempts.paused_by/paused_at`. The nonexistent `pause_state` write is gone. |

### 6.2 Original twelve meanings preserved

The harness still directly proves: unauthenticated denial; unrelated caller
zero; Seeker caller zero; Main one; Additional zero; dual-role relationship
authority; removed zero; inactive zero; potential zero; active present with
`ended=false`; paused present; ended present with `ended=true`.

### 6.3 DR-ZYRA-225 extension

The same transaction now also proves:

1. pre-link ended attempt hidden by default;
2. ended-after-link attempt visible;
3. active attempt begun before link visible;
4. toggle ON returns confirmed ON and reveals all history;
5. toggle OFF returns confirmed OFF and reverts immediately;
6. Main reassignment resets consent and the former Main loses all access;
7. removed-then-relinked reuse of the same link row rotates the assignment
   UUID and cannot revive stale consent;
8. future attempt status remains fail-closed.

It begins a transaction and ends with `rollback;`. It additionally verifies
the exact migration history row, schema/constraint/RLS state, function owner,
definer flags, volatility, empty stored paths, ACLs, positive predicate and
current attempt-status constraint before exercising the data matrix.

The harness is intentionally **not executed in this round** because its first
line of truth is that migration `20260830200416` must already have the
separate Founder apply GO and exactly one live history row.

---

## 7 · True pre-state snapshots and file hashes

True pre-files were copied at edit time, 2026-08-30 21:03:20 +0100, to
`/private/tmp/zyra-051-phase0-pre.UvSlqe`. No reconstructed file is used as
an audit anchor.

| File | True pre SHA-256 | Post SHA-256 |
|---|---|---|
| `SOURCE/supabase/migrations/20260830200416_oa282_dr225_guardian_history_consent.sql` | **ABSENT** — generated for this round with Supabase CLI 2.116.0 | `2725f51090c1f81110a00581854c8a1d21179e314b017c1185a8800ce85fb1fb` |
| `SOURCE/supabase/tests/zyra_oa282_guardian_server_truth_post_apply.sql` | `39139651fe5de45ef870983a5053b3aad12f1b55dab78cb2d56c67964b1fe8c1` | `27e9c6089a396e3dc212387ece3daf53d16d7e3eacc238dce81b1837601060f7` |
| `SOURCE/test/zyra_guardian_server_truth_migration_test.dart` | `4a411a4a0c944133e7116f3d25ed3e0995cf733aaedf5f0e710e0b47b4756c45` | `e559334385b4b8ccac9eb2a9835cb45553a9180fbefd9b79210a816991dec69f` |

The applied workstream-A migration was snapshotted as an unchanged reference:

| Reference file | Snapshot/current SHA-256 |
|---|---|
| `SOURCE/supabase/migrations/20260830183151_oa282_guardian_server_truth_security.sql` | `2c85d4293d7083953ec63fae3ad877b97bcc5e44724bdd4fd1929a292aaec186` |

The existing dashboard migration test remains untouched at its accepted
formatting-note hash:
`bbbb0c03e7c9977215c741d316574be1dd9bec717f51829f135f362fd33b45c4`.

---

## 8 · Live pre-state and staged-only proof

Read-only live audit before editing established:

- `wali_links`: 21 rows; 12 active Main; 8 active Additional; 0 inactive
  Main;
- existing columns had no assignment/consent field;
- existing primary, unique, one-Main and active lookup indexes were present;
- RLS is enabled; authenticated has SELECT but no direct client write path;
- `accept_wali_invite()` reuses an existing removed link row;
- `zyra_set_main_guardian()` demotes then promotes;
- the live summary is workstream A's Main-only four-field definition and
  still uses its pre-DR-225 `a.status <> 'potential'` predicate;
- the exact current status constraint is `potential`, `active`, `ended`;
- no dependent foreign key references `wali_links.id`.

Final read-only live probe after staging returned:

| Probe | Result |
|---|---|
| migration-history rows for `20260830200416` | `0` |
| `guardian_journey_history_consents` | absent |
| `wali_links.main_guardian_authority_id` | absent |
| `zyra_main_guardian_history_consent(boolean)` | absent |
| live summary still contains pre-DR-225 predicate | `true` |
| latest live migration | `20260830183151` |

Therefore no part of this migration has been applied.

---

## 9 · Verification results

| Check | Result |
|---|---|
| `flutter test --no-pub test/zyra_guardian_server_truth_migration_test.dart` | PASS — **12/12** |
| `flutter analyze --no-pub` | PASS — no issues |
| `python3 tools/zyra_check.py --quiet` | PASS — zero findings |
| `python3 -m unittest tools/test_zyra_check.py` | PASS — 1/1 (sandboxed first attempt could not create its temporary directory; authorised rerun passed) |
| scoped Dart format check for the changed test | PASS — 1 file, 0 changes |
| repository Dart format audit | existing accepted note only — `test/zyra_dashboard_updates_migration_test.dart` would format; hash stayed `bbbb0c03…`; no file changed |
| full Flutter suite | **728 passed, 8 failed** — all eight are the separately recorded approved-Guardian-Dashboard relative-time golden drift below |
| direct visual suite | **240 passed, 8 failed** — same eight relative-time comparisons |

### 9.1 Scoped challenge: approved golden fixtures are wall-clock dependent

The eight failures are the four sizes of each of:

- `guardian-dashboard-updates-populated`
- `guardian-dashboard-updates-last-known`

They differ only in relative-time text: accepted masters show values such as
`7h ago` / `8h ago`; the current test render shows `9h ago` / `10h ago`.
The fixture hard-codes `occurredAt` to 2026-08-30 10:00/11:00 UTC while the
production screen formats against the advancing wall clock. The test, UI and
approved baseline files are byte-identical to the accepted OA-ZYRA-281 build:

| Unchanged file | Current/accepted SHA-256 |
|---|---|
| `SOURCE/test/visual/zyra_visual_regression_test.dart` | `d765091827c1367ebe6cf27b6490edb9cd74949647728e40a62b7c9276567d4f` |
| `SOURCE/lib/widgets/zyra_dashboard_experience.dart` | `501acc4951f8f4f4079637ad8ae1ec5e0f7804b8b5d92735435265a30eeb0ec6` |
| `SOURCE/lib/screens/wali/wali_dashboard_screen.dart` | `26c687d954be33a9600bb69fae7436a700a35b2408d7567a2a1b2482d1053411` |

Example approved-baseline hashes also remain unchanged:
`guardian-dashboard-updates-populated__small.png`
`1dcbcb0992fa3c47214f3117a01098c282f95758112974e1bdd5d64e88c4e1b5`;
`guardian-dashboard-updates-last-known__small.png`
`a0354ccc14bd2fec73fef9863c1bf5c8a69c1ad41acae3199b95710c07f1e666`.

I did not alter UI, approved baselines or the unrelated visual harness under
this Phase 0 authority. The narrow corrective path is to inject/freeze the
comparison clock for those Guardian fixtures, not regenerate pixels. Fable
should disposition that independent harness defect; it is not caused by the
three Phase 0 files and does not weaken the 12/12 server contract pass.

Flutter's golden comparator generated/overwrote 32 diagnostic PNGs under
`SOURCE/test/visual/failures/` (master, test, masked-diff and isolated-diff
for each failing variant). They are runtime failure evidence, not approved
baselines or Phase 0 source deliverables; they were not promoted or used to
rewrite any governed image.

---

## 10 · Forward/apply and reverse evidence plan

### Forward gate

1. Fable verifies this report, hashes and staged SQL.
2. ChatGPT performs the required external security review.
3. Founder separately says apply GO.
4. Apply the staged file byte-identically after rechecking hash
   `2725f510…` at apply time.
5. Confirm the exact migration-history row, catalog identity, constraints,
   RLS and ACLs.
6. Run the corrected canonical harness transactionally; record all original
   twelve meanings plus every DR-ZYRA-225 extension as passed.
7. Re-run advisors and direct null/Seeker/Main/Additional/former/relinked
   role probes before any Phase 1 UI work is released.

### Reverse plan if post-apply verification fails

Before Phase 1 consumes the objects, stage a reviewed reverse migration that:

1. restores `zyra_attempt_summary_for_guardian(uuid)` byte-semantically to
   the applied `20260830183151` definition and ACL;
2. drops `zyra_main_guardian_history_consent(boolean)`;
3. drops `guardian_journey_history_consents`;
4. drops `wali_links_main_guardian_authority_state` and the authority column;
5. restores `auto_designate_main_wali()` to its captured pre-state definition
   and trigger ACL.

Do not delete migration history or edit an applied file. Any reversal would
be a new, Founder-approved migration with its own verification. No reverse
action is authorised or needed while this file remains staged only.

---

## 11 · Boundaries reconfirmed

- Phase 1, Phase 2 and Phase 3 UI work: **not started**.
- Client wiring to the summary or consent RPC: **not started**.
- Guardian UI rebuild, Dashboard thinning and shell redesign: **untouched**.
- Existing Guardian visibility expansion: **not built**.
- `score_candidates`: **untouched**.
- Live database writes/DDL: **none**.
- Git: **not used**.
- Self-approval: **not claimed**.

The package is released only to Fable's independent Phase 0 verification.
External review and the Founder's separate apply GO remain hard gates.

— Codex, 2026-08-30
