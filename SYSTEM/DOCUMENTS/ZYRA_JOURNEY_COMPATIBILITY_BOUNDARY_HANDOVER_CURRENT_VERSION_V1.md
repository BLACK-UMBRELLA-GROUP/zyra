---
id: DOC-ZYRA-0215
type: HANDOVER
status: CURRENT
feature: JOURNEY
purpose: ZYRA — Journey Compatibility Boundary Handover
links: []
owner: ZYRA chat
---

# ZYRA — Journey Compatibility Boundary Handover

**Version:** V1
**Status:** CURRENT_VERSION — OA-ZYRA-198 FOUNDER ACCEPTED + CLOSED / PRODUCTION CUTOVER EXECUTED + POST-VERIFIED / OA-ZYRA-283 FOUNDER ACCEPTANCE PENDING / REQUEST NEW JOURNEY HOLD LIVE / TESTFLIGHT BUILD 2 READY TO TEST / FOUNDER INTERNAL CONFIGURED / INSTALL + DEVICE ACCEPTANCE PENDING
**Date:** 2026-09-12
**Owner:** Codex, Operating Partner under AD-AIOS-109
**Final Authority:** Founder (Shakeel)
**Outstanding Action:** OA-ZYRA-283
**Product Authority:** ZYRA_PRODUCT_SPEC; APP/Journey/PRE-JOURNEY RITUAL/Summary.md; DR-ZYRA-135; OA-ZYRA-193
**Operating Authority:** AD-AIOS-109; FOUNDER_CODEX_OPERATING_MODEL

---

## 1. Current position

This document records the current source and production state of the Journey
Compatibility Reveal authorisation boundary under OA-ZYRA-283.

- The Flutter service uses caller-scoped RPCs rather than direct
  `journey_compatibility` table reads or writes.
- Under the Founder's exact single-use 2026-09-11 GO, migration
  `SOURCE/supabase/migrations/20260910184252_oa283_journey_compatibility_rpc_boundary.sql`
  (SHA-256 `63381febeb9b1732447adb24a6225c1006f42171bc8b5b5e4f5a61712f54296d`)
  and Request New Journey hold migration `20260910195642` (SHA-256
  `0ac36fd4c4c7ed03b8a4fe80ef75d4cb43c10355426d6a972814961f5e061545`)
  were applied atomically, byte-identically and in that order to production
  project `sxoaxonzjqkgajmlagyk` while ZYRA remained closed.
- Both transactional post-apply harnesses passed. Final catalog, ACL/RLS,
  null-caller, non-party, Seeker-side, zero-state, application-health and
  advisor checks passed. The real two-session concurrency/idempotency probe
  passed and its fixture row was restored exactly.
- Focused source/migration tests, analyzer and repository checks remain green.
  A fresh internal-only ZYRA `1.0.0 (2)` archive and IPA were created only
  after post-verification. The IPA passed archive-integrity, identity,
  distribution-signature, entitlement, provisioning-profile and hash checks;
  SHA-256 is
  `1e17a1c3475db1bcb01e59415768d94480538bb601aedcdc8fdd706ea1a7b673`.
  That exact IPA is uploaded once and `Ready to Test` in App Store Connect.
  `Founder Internal` has automatic distribution OFF, only
  `admin@zyraconnect.app`, and only ZYRA `1.0.0 (2)`; the tester is `Invited`.
- OA-ZYRA-283 remains open pending Founder installation/device acceptance. The
  production Apply GO and Apple upload authorities are consumed; neither
  authorises a retry, replacement build or other change.
- Independent two-attempt review found that Request New Journey remains unsafe
  under the partially completed OA-ZYRA-156 schema.
- The Founder resolved that release choice on 2026-09-10 through DR-ZYRA-227:
  the bounded Founder-only TestFlight will temporarily hold Request New Journey
  at both client and server while the permanent per-attempt conversion remains
  open.
- The client hold and grants-only server-hold migration are live and
  post-verified. PUBLIC, anon and authenticated cannot execute the four held
  Request New Journey RPCs; postgres and service_role remain.
- OA-ZYRA-198's clean-replay prerequisite is now satisfied locally. All eight
  substantive OA-ZYRA-193 record files hold their exact retained production
  statements, with delimited UTF-8 body hashes pinned 10/10. The recovery and
  replay chronology below is retained as historical gate evidence.
- Under the Founder's exact 2026-09-11 chronology ruling, live-history
  duplicates 20260811102840/103056 are now preserved under
  `SYSTEM/RESOURCES/MIGRATION_HISTORY/OA-ZYRA-198_2026-09-11_CHRONOLOGY_
  ARCHIVE/`, outside the active CLI path. Their bytes, filenames, modes and
  original mtimes are preserved; active SQL inventory is 209 -> 207.
- A fresh unlinked zero-state reset using PostgreSQL 17 and seeding disabled
  passed the corrected 104500 -> 110300 -> 111500 sequence and continued
  through 20260811152809. It stopped at the first new result,
  `20260811153416` / SQLSTATE `42P01`, because relation
  `zyra_onboarding_questions` has no earlier repository creator. No repair or
  retry followed.
- The subsequent Founder-authorised provenance recovery exhausted the active
  migrations, four source-relevant archives, OA-198 pre-state/scratch evidence,
  local Claude/Fable evidence and retained production migration rows. No
  original CREATE/INSERT bytes, version, statement boundary or pre-153416
  catalog survives. The predecessor was ad-hoc SQL outside migration history.
  The pinned 2026-08-10 Dart source supports deterministic reconstruction of
  72 rows / 71 qids, but does not turn that reconstruction into historical SQL.
  The Founder approved a replay-only production-excluded treatment and then
  gave the separate exact single-use GO naming bridge SHA-256
  `461c3bd0e4ef4692229027c5659756983ed2048e1e78cf71e2148009d6729055`.
  One fresh, seedless, isolated PostgreSQL 17.6 reset executed exactly once.
  It stopped inside bridge version `20260811153415`, statement 11, with
  SQLSTATE `22023`: `ACL arrays must be one-dimensional`. The failing context
  is the column-ACL postcondition's `aclexplode` call over a coalesced empty
  `aclitem[]`. Successor `20260811153416` did not start and the later static
  `zyra_probe_score` gap was not reached. No repair, retry or post-failure
  database query followed. Message 081 is the measured execution record.
- The Founder then explicitly authorised creation and internal testing of a
  new V2 replay-only bridge while preserving V1, with no full replay and no
  production access. V2 changes only that column-ACL query, using
  PostgreSQL's canonical
  `aclexplode(COALESCE(attacl, acldefault('c', relowner)))` form. The exact
  V2 SQL is 28,501 bytes, mode 0600, SHA-256
  `337b342df347b7e902d8da32bafd0a2b21516550b9234213298079304ca66aa1`.
  A read-only PostgreSQL 17 harness reproduced V1's `22023`, proved the
  corrected NULL/empty/nonempty contract and preserved malformed-array
  rejection. The full V2 bridge also passed one minimal-predecessor
  integration execution without loading application migrations. Message 082
  is that pre-execution evidence.
- The Founder then gave the exact single-use reset GO naming the V2 hash. One
  fresh, seedless, credential-free PostgreSQL 17.6 reset ran once from 208
  unique versions: the unchanged 207 active files plus V2 only. V2 and the
  question-bank successors passed. The reset stopped later in
  `20260811233813`, statement 7, SQLSTATE `42P01`, because
  `public.zyra_probe_score` does not exist. The last fully completed
  predecessor was `20260811233755`; neither staged September migration was
  reached. No repair, retry or post-failure database query followed. Message
  084 is the measured result and consumes the current replay authority.
- Under the Founder's instruction to complete every safe TestFlight
  prerequisite, exhaustive retained-record recovery proved that the original
  `zyra_probe_score` creator SQL/version is absent. Read-only production
  catalog inspection then recovered its exact current structural contract
  without reading row values: postgres-owned ordinary table; nullable
  `viewer text`, `rows_returned integer`, `score numeric`; no defaults, keys,
  indexes, policies, triggers, rules or comments; two live scratch rows; RLS
  on / FORCE off and final ACL postgres + service_role. A schema-only bridge
  is now quarantined outside the active path at artificial version
  `20260811233812`, 7,302 bytes, mode 0600, SHA-256
  `9f9a818f3370b849ba1ff21f1d4ea9c3adb9ab866b22e15f6ba7a03454b46b46`.
  It creates no row and leaves unchanged 11233813 to perform the historical
  hardening. A network-none PostgreSQL 17.6 integration plus read-only
  post-target harness matched the live catalog/security contract; four
  artifact tests pass. Message 085 records that pre-execution evidence.
- The Founder then gave the exact single-use GO naming both bridge hashes.
  One fresh disposable, seedless, isolated PostgreSQL 17.6 reset ran the
  unchanged 207 active migrations plus both bridges: 209 unique versions. The
  reset exited 0, applied all versions exactly once and reached both staged
  September migrations. No repair/retry or post-result database query
  followed. The project and unique network were removed, the named VM was
  stopped, ports are clear and the global Docker context remains unchanged.
  Message 086 records the raw-log identity and teardown. Production was not
  accessed or changed by this replay. The Founder accepted the post-verified
  result on 2026-09-11; message 087 closes OA-ZYRA-198. The production Apply
  GO and TestFlight upload gates remain separate.
- Offline TestFlight preparation is complete without touching those gates:
  build `1.0.0+2` is source-owned, the export contract is internal-only and
  export-without-upload, the standard-encryption exemption is explicit,
  feedback reads the installed bundle version, and seven release-preflight
  guards pass. A fresh unsigned iOS release compile proves ZYRA / canonical
  bundle / build 2. Message 083 records the hashes and tests. No signed
  archive, IPA, portal access, replay, production access or upload had occurred
  at that offline checkpoint.
- At the 2026-09-11 pre-upload checkpoint, authenticated read-only Apple
  verification was complete. Apple Developer
  shows explicit App ID `app.zyraconnect.zyra` on paid Team `9Y7Z8F36SJ` with
  In-App Purchase, Push Notifications and Sign in with Apple enabled. App
  Store Connect shows app record `ZYRA Connect` / Apple ID `6810741513` and
  TestFlight `No Builds`, with no internal-testing group. No Apple setting was
  changed; OA-ZYRA-274 is closed. A direct host-keychain check now finds two
  valid Apple Development identities and no Apple Distribution identity, so
  the later fresh build must still prove Xcode's authenticated automatic/cloud
  distribution-signing path.
- On 2026-09-12 the exact uploaded build reached `Ready to Test` and the sole
  internal group was configured as described above. No external tester/group
  or public App Store release was authorised or changed. Apple's delivery
  email reported non-blocking warning `ITMS-90068: MinimumOSVersion too low`:
  immutable build 2 remains minimum iOS 13.0, while all three Xcode source
  configurations now require iOS 15.0 for the next build. A new binary would
  require a new build number and separate exact Founder authority.

Under AD-AIOS-109 the active route is Founder ↔ Codex. Codex may prepare,
challenge, implement, test and document; only the Founder may issue exact
production or upload authority, accept risk, approve the result or close the
OA. The production migration GO described here was issued and consumed once.
ChatGPT, Fable and Claude are not standing gates unless the Founder explicitly
requests one of them for this named matter.

The security release boundary remains the one recorded by OA-ZYRA-283:
Founder-only internal testing may continue as a controlled test now that the
two migrations are applied and post-verified under exact Founder authority,
but no untrusted real-user or external-tester release may rely on this
boundary. OA-ZYRA-285 remains a separate public-release security blocker.

## 2. Product truth preserved by this boundary

The boundary implements the current Compatibility Reveal truth; it does not
redesign the product.

1. Compatibility belongs to the current Journey attempt between two Seekers.
2. Each Seeker owns a different score: how well the counterpart fits what that
   caller said they wanted. There is no shared compatibility number.
3. Ordinary Compatibility Reveal remains mutual. Before both Seekers have
   revealed, the ordinary state/reveal RPC returns no score.
4. Once both reveal flags are true, a caller receives only their own score.
5. A caller never receives the counterpart's score, either party's raw
   onboarding answers, category JSON, side label, user identifier or attempt
   identifier from these RPCs.
6. No production-safe detailed category contract exists. Legacy synthetic
   category data is neither selected nor returned.
7. Guardians receive the Journey milestone permitted by the product model, not
   either Seeker's score.
8. DR-ZYRA-135's paid Plus exception remains score-only early sight for the
   entitled caller. It does not make the relationship mutually revealed.

The completion milestone and each private score remain different facts. This
handover governs access to the private score and reveal flags, not the public
wording of a Journey milestone.

## 3. Why the boundary is required

`journey_compatibility` is one row containing both Seekers' reveal flags and
both private scores. Its earlier participant-level RLS policies could decide
whether a caller may access the row, but could not make different columns in
that row belong to different callers. A modified Data API client could request
the counterpart's score or attempt to update the counterpart's score or reveal
flag even after the trusted Flutter client stopped doing so.

Selecting fewer columns in Flutter was data minimisation, not server-side
authorisation. OA-ZYRA-283 therefore moves all ordinary client access behind
caller-relative definer functions and removes direct client table authority.
The database derives identity from `auth.uid()` and the match row. It never
trusts a caller-supplied counterpart id, score, reveal flag or side label.

## 4. Prepared files and measured source identity

### 4.1 Applied migration

Path:
`SOURCE/supabase/migrations/20260910184252_oa283_journey_compatibility_rpc_boundary.sql`

SHA-256 measured before this handover was created:
`63381febeb9b1732447adb24a6225c1006f42171bc8b5b5e4f5a61712f54296d`

Responsibility: creates/restates the three caller-scoped Compatibility RPCs,
hardens their execution grants, removes direct client privileges from the
shared table, drops the three permissive participant policies and leaves RLS
enabled.

This hash is the exact identity applied to production and re-verified against
the migration-history statement. The applied file and history record are now
frozen. Any repair must be a new forward migration under new exact authority.

### 4.2 Flutter service wiring

Path: `SOURCE/lib/services/zyra_journey_service.dart`

SHA-256 after analyzer cleanup:
`3caab8cb3a6eb100f0d50eb868d0bb15ef437e19526a6ffe698137c3868cc275`

Prepared entry points:

- `compatibilityResultFromRpcRow()` maps only `mine_revealed`,
  `counterpart_revealed` and `my_score`.
- `revealCompatibility()` calls
  `zyra_reveal_journey_compatibility(p_match_id)`.
- `fetchCompatibility()` calls
  `zyra_journey_compatibility_state(p_match_id)`.
- `fetchCounterpartRevealed()` consumes `fetchCompatibility()` rather than
  selecting the table.
- `fetchCompatibilityForPlus()` continues to call
  `zyra_compatibility_for_plus(p_match_id)`.

`revealCompatibility()` temporarily retains its old positional
`otherUserId` argument to avoid a broad screen edit in this bounded security
patch. The value is deliberately unused and is not sent to the database. The
server derives the counterpart from `auth.uid()` and the protected match.

### 4.3 Prepared static assertions

Paths:

- `SOURCE/test/app_shell_correctness_test.dart`
- `SOURCE/test/zyra_oa283_journey_compatibility_boundary_migration_test.dart`

SHA-256 values:

- `2c955eb02fd76ed64ed0696ad74c1c6330233e06bafd7efae0b72359868eeeb2`
- `35270d058d47c681ec41958c749b86959ff6cd8f37dc7fee413892e89c98e365`

The files contain source-level assertions for the RPC names, caller-relative
mapping, absence of direct Flutter table access, absence of client
`score_candidates` calls, empty definer `search_path`, current-attempt and
pause predicates, lock order, caller-only writes, Plus score-only behaviour,
direct table revocation, policy drops and absence of caller-supplied
identity/score/reveal parameters. Their focused run passed 20/20 tests on
2026-09-10.

### 4.4 Executed post-apply harness

Path:
`SOURCE/supabase/tests/zyra_oa283_journey_compatibility_boundary_post_apply.sql`

SHA-256:
`e75657d67be8b84457e5ad2e63920bb3bff161b80092954f28fd43bf010ace7c`

The transactional harness passed against production and rolled back its own
fixture mutations. It covers catalog/ACL truth, direct-table denial, caller-relative
Seeker A/B behaviour, Guardian/non-party/null denial, lifecycle and
current-attempt gates, Plus isolation across the same null/actor/missing/
stale/lifecycle denial matrix, explicit column-ACL and unexpected function
overload/grantee checks, positive asymmetric A-side and B-side Plus paths,
row restoration and rollback. It also
contains conditional cases for the future shared-pause columns. Concurrency
remains a separate multi-session post-apply probe.

### 4.5 DR-ZYRA-227 temporary Request New Journey hold

The Founder-approved interim route is implemented as a separate, reversible
release gate rather than being hidden inside the Compatibility migration.

Client/source artifacts and SHA-256 values:

- `SOURCE/lib/data/zyra_release_gates.dart` —
  `aa6c66cee36840272e61291fc8ba936cc0f1dd320271a4702efd9da5b25a671e`
- `SOURCE/lib/screens/connections/connections_screen.dart` —
  `8ec7f02b180d63cfc271d6bf93a8f0fa838a4f3e848ee6c32f83f80ac087acc0`
- `SOURCE/lib/screens/journey/journey_flow_screen.dart` —
  `074a8626fa0b0a043871bb9dede8c0ec4c79c7481f6d1cfc9d5054b12b1424f0`
- `SOURCE/lib/services/zyra_journey_service.dart` —
  `17a6e0b2785bed0428ffa0d2188f1b407eb78cbbd63262f15dbab1f5c9a62c62`
- `SOURCE/test/connections_design_defaults_test.dart` —
  `058e275683a7bee97c85ef13258f04e9bb4025627634fa20f2c63ea5eaf7e1e4`
- `SOURCE/test/zyra_oa156_request_new_journey_hold_migration_test.dart` —
  `5f568f430322ad7e2d0ece8f55f2ec277b4db2e2314452fd1571cfa56f929ba9`

Server artifact:

- `SOURCE/supabase/migrations/20260910195642_oa156_request_new_journey_testflight_hold.sql`
  — `0ac36fd4c4c7ed03b8a4fe80ef75d4cb43c10355426d6a972814961f5e061545`

The migration changes grants only. It pins the exact signature, owner,
`SECURITY DEFINER` posture, deployed definition hash and existing ACL for
`request_new_journey(uuid)`, `respond_to_journey_request(uuid,text)`,
`zyra_may_request_new_journey(uuid)` and
`zyra_may_request_new_journey_ids()`. It aborts unless request rows, request
notifications and multi-attempt matches are all zero and direct table writes
remain closed. It then revokes `EXECUTE` from `PUBLIC`, `anon` and
`authenticated`, retaining only `postgres` and `service_role`.

Executed post-apply harness:

- `SOURCE/supabase/tests/zyra_oa156_request_new_journey_hold_post_apply.sql`
  — `be2980edfc388d2dab08fd92e87623f5e110b38563c7a083ddbc0a63d6bb7015`

The transactional harness passed against production. It checks migration history,
catalog identity, exact grants, direct anon/authenticated denial on all four
RPCs, unchanged table RLS/DML posture, retained expiry/restart access, zero
affected state and rollback. The client independently hides the ended-card
request control, removes countdown/60-day promises, skips eligibility fetches
and short-circuits request/response wrappers before Supabase access. Keeping
both layers is deliberate defence in depth.

### 4.6 OA-ZYRA-198 history recovery and chronology archive

All eight substantive OA-ZYRA-193 record files now contain their exact
retained `supabase_migrations.schema_migrations` single-statement bodies
between explicit provenance markers. The focused recovery test extracts only
those bytes, hashes them as UTF-8, rejects the former `SELECT 1` record body
and pins the eight governed identities; its current run remains 10/10.

The Founder-approved chronology correction preserves the two duplicated live-
history files under:

`SYSTEM/RESOURCES/MIGRATION_HISTORY/OA-ZYRA-198_2026-09-11_CHRONOLOGY_ARCHIVE/`

The archive manifest pins both original active paths, SHA-256 values
(`897cd7ce...` and `a101e019...`), byte lengths, mode/mtime evidence, active
inventory 209 -> 207 and the exact reverse map. The active representation is
104500 -> 110300 -> 111500.

That correction removed the earlier 42P13 collision. A fresh isolated reset
then reached `20260811153416` and failed with measured SQLSTATE `42P01`
because `zyra_onboarding_questions` has no earlier repository creator. At that
checkpoint, a full clean replay was not yet claimed. Exhaustive follow-up proved the original
populated question-bank direct-DDL bytes are absent from the retained record.
The Founder then approved an explicitly labelled replay-only reconstruction;
the bridge is quarantined outside the active migration path and internally
verified at SHA-256
`461c3bd0e4ef4692229027c5659756983ed2048e1e78cf71e2148009d6729055`.
The separately authorised one replay has now rejected that exact artifact on
PostgreSQL 17 SQLSTATE `22023` inside its column-ACL postcondition. It did not
reach 153416. No retry followed. The eight exact bodies must not be weakened to
make a future replay green, and this executed bridge hash must not be
overwritten or rerun.

Corrected V2 remains outside the active path at SHA-256
`337b342df347b7e902d8da32bafd0a2b21516550b9234213298079304ca66aa1`.
Its separately authorised 208-version reset passed V2 and the complete
question-bank successor chain, then stopped in `20260811233813`, statement 7,
with SQLSTATE `42P01` because `public.zyra_probe_score` does not exist. The
last fully completed predecessor was `20260811233755`; the September staged
migrations were not reached. No repair or retry followed. The creator gap is
now represented by the separate catalog-backed bridge recorded in message
085, not by a modification to V2 or the eight exact bodies.

## 5. RPC contracts

### 5.1 `zyra_journey_compatibility_state(uuid)`

Input:

- `p_match_id uuid` only.

Caller-relative return row:

- `mine_revealed boolean`
- `counterpart_revealed boolean`
- `my_score numeric`

The function is `STABLE SECURITY DEFINER` with `search_path = ''` and fully
schema-qualified protected objects. If no compatibility row exists for the
current attempt it returns `false`, `false`, `NULL`. If a row exists, it maps
the stored A/B flags relative to `auth.uid()`. `my_score` is returned only when
both stored reveal flags are true.

### 5.2 `zyra_reveal_journey_compatibility(uuid)`

Input:

- `p_match_id uuid` only.

Caller-relative return row:

- `mine_revealed boolean`
- `counterpart_revealed boolean`
- `my_score numeric`

The function is `VOLATILE SECURITY DEFINER` with `search_path = ''`. It locks
the match, active attempt and compatibility row in that order, derives the
caller's side and counterpart, creates the current compatibility row if absent,
computes only a missing caller-owned score, sets only the caller's reveal flag
and returns only the caller-relative contract above. A stored caller score is
not overwritten on an idempotent retry.

The ordinary reveal result remains mutually gated: `my_score` stays `NULL`
until both reveal flags are true. `revealed_at` is created when the second
party completes mutual reveal and is retained on later idempotent calls.

### 5.3 `zyra_compatibility_for_plus(uuid)`

Input:

- `p_match_id uuid` only.

Return:

- the caller-owned score as `numeric`, or `NULL` where no score can be
  computed.

The existing DR-ZYRA-135 doorway is restated as `VOLATILE SECURITY DEFINER`
with `search_path = ''` and the same current Journey/attempt predicates as the
ordinary boundary. It derives the counterpart and requires a server-side
`profile_unlocks` row from caller to counterpart with unlock type
`paid_plus_single` or `paid_plus_bundle`.

It may compute and persist only the caller-owned score. It writes no reveal
flag, `revealed_at`, Journey stage, timeline milestone or notification. It
therefore preserves the distinction: the result may be bought early; mutual
relationship consent may not.

## 6. Shared authorisation and state rules

All three RPCs enforce these rules server-side:

1. `auth.uid()` must be non-NULL. A null caller receives SQLSTATE `42501` with
   `not_signed_in`.
2. The caller must be `seeker_a_id` or `seeker_b_id` on `p_match_id`. An absent
   match and a non-party deliberately produce the same `42501 not_a_party`
   outcome so the RPC does not become a match-id enumeration oracle.
3. The match must currently be `active`, at `compatibility_reveal`, and have
   both `suspended_by` and `also_paused_by` NULL.
4. Exactly the current `journey_attempts` row with `status = 'active'` is used.
   It must also be at `compatibility_reveal`, with both `paused_by` and
   `also_paused_by` NULL.
5. A missing or unavailable current Journey state receives SQLSTATE `55000`
   with `journey_not_available`.
6. Today's schema exposes legacy pause columns. A separately staged migration
   will later add shared `pause_state` to both match and attempt. To avoid this
   boundary becoming permissive after that migration lands, all three RPCs
   also read the optional row JSON key and require its value to be `none`.
   Missing keys resolve to `none` today; `pause_requested`,
   `continue_requested` and every other non-`none` future state fail closed.
7. Because OA-ZYRA-156 has not finished the destructive per-attempt key
   conversion, the table remains conflict-keyed by `match_id`. Every RPC
   therefore requires the compatibility row's `attempt_id` to equal the
   current active attempt id. A stale prior-attempt row fails with SQLSTATE
   `55000` and `compatibility_attempt_mismatch`; it is never reinterpreted as
   the current Journey.
8. Caller ownership is derived once from the match: A may read/write only A's
   score/flag and B may read/write only B's score/flag. No public RPC parameter
   can select a side or counterpart.

The match-level and attempt-level checks are intentionally both present during
the OA-ZYRA-156 transitional schema. This boundary does not choose one stale
state source silently; disagreement fails closed.

## 7. Direct-table closure and function ACL design

The applied migration changes `journey_compatibility` into an RPC-only client
table:

- revoke all table privileges from `PUBLIC`, `anon` and `authenticated`;
- drop `journey_compatibility_read`;
- drop `journey_compatibility_insert`;
- drop `journey_compatibility_update`;
- keep row-level security enabled; and
- add a table comment stating the caller-relative RPC contract.

Dropping the permissive policies is deliberate defence in depth. A later
accidental table grant must not silently recreate whole-row participant
authority. The migration does not claim to remove database-owner or privileged
backend maintenance powers; it closes the client-role route governed by
OA-ZYRA-283.

For each of the three RPC signatures, the migration first revokes all function
privileges from `PUBLIC`, `anon`, `authenticated` and `service_role`, then
grants `EXECUTE` to `authenticated` only. Every function uses an empty
`search_path` and schema-qualified protected objects. The intended final ACL is
therefore explicit rather than inherited from default function privileges.

## 8. Prepared client data flow

```text
Journey screen
  -> ZyraJourneyService
  -> one RPC carrying p_match_id only
  -> auth.uid() + protected match derive caller side/counterpart
  -> current active, unpaused Compatibility Reveal attempt is checked
  -> journey_compatibility is read/updated inside the definer boundary
  -> only mine_revealed + counterpart_revealed + my_score return
  -> Flutter maps the caller-relative result
```

No category map, raw answer, counterpart score, user id, side label or attempt
id crosses this boundary. The screen's existing mutual reveal, score-empty and
Continue lifecycle remain consumers of the same three caller-relative values.

The current `fetchCompatibility()` catch still maps a failed RPC read to the
same `(false, false, NULL)` shape as a successful unrevealed/empty result. That
truth-state defect is OA-ZYRA-284 and is not silently solved or claimed solved
here.

## 9. Plus preservation and hardening

The applied migration restates the Plus function rather than leaving an older
definer doorway beside the new boundary. The restated function:

- uses the same authenticated party, current active Journey, exact stage,
  unpaused and current-attempt requirements;
- checks the caller-to-counterpart Plus entitlement in the database;
- computes or retrieves only the caller-owned score;
- rejects a stale attempt-key mismatch;
- exposes no counterpart score or category JSON; and
- does not change reveal consent or lifecycle state.

This closes a bypass where hardening only the two ordinary RPCs would have left
an older function with weaker state or definer rules. It does **not** close the
separately discovered raw `score_candidates` timing/entitlement doorway
described in §12.5.

## 10. Rollout order and old-client incompatibility

This is not a backward-compatible database-only change.

- The prepared Flutter client calls the two new OA-ZYRA-283 RPCs, so its
  Compatibility Reveal path cannot work against a database where this
  migration has not created them.
- An older installed client directly accesses `journey_compatibility`, so its
  Compatibility Reveal path will stop working when this migration revokes the
  table privileges and drops the policies.
- The migration creates the RPCs and closes direct table access in one
  transaction. It deliberately provides no period in which old and new client
  authorities coexist.

Measured cutover sequence:

1. Completed: messages 080–087 preserve the reconstruction, failed one-use
   replay, corrected bridges, clean 209-version replay and Founder acceptance
   that unlocked production. All replay-only authority is consumed.
2. Completed: the Founder named project `sxoaxonzjqkgajmlagyk`, the exact two
   migration hashes, their order and the stop rules in one single-use GO.
3. Completed atomically while ZYRA remained closed: OA-ZYRA-283
   `20260910184252` first, then grants-only hold `20260910195642`. No other
   migration or Apple action occurred inside that cutover.
4. Completed: both transactional harnesses, final catalog/ACL/RLS and denial
   matrix, zero-state and application-health probes, advisor comparison and a
   real two-session concurrency/idempotency test passed; its fixture was
   restored exactly.
5. Completed locally: a fresh RPC-wired, Request-New-Journey-held
   Founder-internal `1.0.0 (2)` IPA passed distribution signing, entitlement,
   profile, identity, archive-integrity and hash checks.
6. Pending: Founder acceptance of OA-ZYRA-283 and a separate exact Apple Upload
   GO. External/untrusted distribution remains blocked; OA-ZYRA-285 and all
   public-release gates remain in force.

Older direct-table clients must remain closed. Regranting the shared-table
client privilege is not an acceptable compatibility measure.

## 11. Failure handling and forward repair

The applied migration files and production history records are frozen. They
must never be edited, retried or repaired in place.

After apply, the security-safe recovery is a new forward-repair migration and,
where necessary, a corrected RPC-wired client. A repair must preserve the
RPC-only shared table and caller-relative field ownership. The release rollback
must **never** regrant `authenticated` direct access to the shared table or
restore the permissive participant policies; doing so would reopen the exact
counterpart-score and counterpart-mutation defect OA-ZYRA-283 exists to close.

Stop distribution and prepare a forward repair if any of these occur:

- a caller can observe the counterpart's score or category data;
- a caller can mutate the counterpart's reveal flag or score;
- a non-party, Guardian, `anon` or null caller receives compatibility state;
- a paused, ended, potential, wrong-stage or stale-attempt Journey passes;
- Plus changes a reveal flag or Journey state;
- the function owner, `prosecdef`, `search_path` or ACL differs from the exact
  approved contract; or
- the RPC-wired client cannot complete the intended controlled Journey flow.

A production forward-repair artifact is itself a production migration and
requires its own exact Founder GO unless the Founder has expressly authorised
that exact repair artifact and consequence.

## 12. Known separate gaps and boundaries

### 12.1 OA-ZYRA-284 — truthful compatibility read failures

`fetchCompatibility()` still represents first-load RPC/auth/network failure as
neither party revealed. OA-ZYRA-284 owns the typed
available/empty/unavailable state, retained confirmed state and Retry UI. It is
not part of this database authorisation patch.

### 12.2 OA-ZYRA-156 — per-attempt key cleanup

The compatibility table still uses `match_id` as its conflict key while also
carrying `attempt_id`. The staged boundary fails closed on an attempt mismatch,
but it does not perform OA-ZYRA-156's destructive conversion to an
attempt-owned primary/unique key or remove transitional match lifecycle state.

Independent review proved this is a present release blocker, not merely future
cleanup. `respond_to_journey_request(..., 'accept')` creates attempt 2 without
removing attempt 1 history, as DR-ZYRA-121 requires. Compatibility, Salams and
stage/phase checkpoints still conflict or gate by `match_id`, so the new
attempt can be stuck behind the old row or inherit old Salams, reveal consent
and Continue checkpoints. The trusted client exposes the request action and
contains the acceptance service, while the authenticated acceptance RPC is
directly callable even though no production Flutter caller was found for that
service method.

The unsafe remedies are deleting or rebinding old rows: either would erase or
mislabel history. DR-ZYRA-227 records the Founder's ruling for the bounded
Founder-only TestFlight: temporarily disable Request New Journey at both
server and UI, prove the direct RPCs fail closed, and restore the feature only
after the governed OA-ZYRA-156 per-attempt conversion and real two-attempt
lifecycle suite are complete.

That interim route is internally verified in source and staged SQL. It is not
live: the grants-only migration remains unapplied. The handover remains on
production apply hold pending its exact Founder GO; OA-ZYRA-198's clean local
replay prerequisite has passed, and no unresolved product choice remains.

### 12.3 OA-ZYRA-184 — developer definer functions

Developer-only functions including `zyra_dev_set_compatibility`,
`zyra_dev_set_counterpart_reveal` and `zyra_dev_set_plus_unlock` deliberately
retain seeded `@zyra.test` powers for controlled development. They are not
ordinary member authority and remain governed by OA-ZYRA-184's
drop-before-public-launch gate. This handover neither promotes them to
production behaviour nor removes them.

### 12.4 Legacy category documents and data

Historical documents, column comments and stored category JSON may still
describe or contain synthetic per-category results copied from an overall
score. The current Flutter/RPC contract does not read or render those values.
A future category feature requires a versioned real-data scoring contract,
legacy-row treatment and reconciliation of the stale category documentation.
Absence from the new boundary is deliberate; deletion or reinterpretation is
not authorised here.

### 12.5 OA-ZYRA-285 — raw `score_candidates` timing and entitlement bypass

The boundary RPCs call `score_candidates(uuid[])` internally to compute the
caller-owned score. Separate inspection found that the raw function remains an
authenticated RPC accepting caller-selected candidate ids and can return a
score when its profile-visibility predicate allows the target. A modified
client may therefore call the raw scoring function directly outside the
Compatibility Reveal stage and without the DR-ZYRA-135 Plus entitlement,
bypassing the timing/entitlement boundary even though it does not expose the
counterpart's reverse-direction score.

This is separate from shared-row field ownership and is not fixed by the
OA-ZYRA-283 staged migration. The finding is now registered as OA-ZYRA-285 and
awaits separate Founder-ruled remediation. No release should treat
Compatibility Reveal timing or Plus exclusivity as server-enforced while this
raw authenticated doorway remains callable.

## 13. Verification status and remaining evidence

Production verification is complete. The source and replay paragraphs below
retain the evidence trail that preceded cutover; §13.3 records the matrix that
now passed live. Apple upload and the private internal-group configuration are
complete; Founder invitation acceptance, installation and device acceptance
are the remaining gates.

### 13.1 Source and build — measured 2026-09-10

- `dart format` completed on the touched Dart/test sources.
- Focused OA-ZYRA-283 and app-shell run: 20 passed, 0 failed.
- Focused app-shell + DR-ZYRA-227 hold run: 41 passed, 0 failed.
- Complete Flutter suite: 808 passed and exactly 60 failed, all the already-
  registered unrelated Dashboard golden mismatches; no new non-golden failure.
- `flutter analyze`: no issues.
- `python3 tools/zyra_check.py`: 0 findings.
- `python3 -m unittest tools/test_zyra_check.py`: 1 passed.
- `flutter build ios --release --no-codesign`: passed and produced the local
  release Runner app. This is compile evidence, not the signed upload artifact.
- A fresh signed internal-only `1.0.0 (2)` IPA now passes local release
  verification. Controlled TestFlight device acceptance remains after upload.

### 13.2 SQL and dependency review — completed

- independent source/schema review found no blocker inside the caller-owned
  field boundary after the forward-compatible pause-state amendment;
- exact-schema parse and transaction validation passed live;
- live `pg_proc`, `pg_policies`, `information_schema` privileges,
  default privileges and dependencies were re-read before GO;
- the current deployed bodies/signatures of `score_candidates`,
  `zyra_compatibility_for_plus` and the three old compatibility policies;
- the migration preserved triggers, service processes and approved
  administrative paths; and
- concurrent A/B reveal calls and idempotent retries passed.

The same review found the OA-ZYRA-156 Request New Journey blocker in §12.2.
DR-ZYRA-227 resolves that release route, and internal client/SQL reviews found
no blocker in the staged hold. The two migration hashes became the exact
production identities. Full zero-state syntax, transaction and dependency
replay is now measured locally: both staged migrations executed to completion
inside the exact 209-version reset. Production-specific catalog, ACL and
direct-call checks later passed. The clean-replay prerequisite was satisfied
locally and the Founder subsequently issued the exact Apply GO that is now
consumed. All eight recovered bodies match their retained live-history SHA-256
values and the duplicate-history chronology is now corrected. The earlier
replay stopped at
20260811153416 / SQLSTATE 42P01 on missing
`public.zyra_onboarding_questions`. The V1 one-replay result stopped earlier,
inside bridge 20260811153415 / SQLSTATE 22023 on its column-ACL postcondition;
the later `public.zyra_probe_score` gap was not reached in that V1 run.
Exhaustive follow-up had proved that the
old table's ad-hoc CREATE/INSERT bytes are absent from the retained record.
Message 079 records the safe reconstruction anchors and historical decision
gate. Message 080 records the approved, internally verified replay-only bridge
at SHA-256
`461c3bd0e4ef4692229027c5659756983ed2048e1e78cf71e2148009d6729055`.
Message 081 records the one exact V1 execution: failure inside bridge statement
11 with SQLSTATE `22023`; successor 153416 was not started. The prior static
reviews did not exercise this PostgreSQL 17 ACL-array runtime behaviour.
Message 082 records the corrected V2 bridge at exact SHA-256
`337b342df347b7e902d8da32bafd0a2b21516550b9234213298079304ca66aa1`,
its PostgreSQL 17 runtime PASS and minimal-predecessor integration PASS. The
Founder later authorised one exact full replay using that hash. V2 and the
question-bank chain passed; the first result was instead
`20260811233813` statement 7 / SQLSTATE `42P01` on the missing
`public.zyra_probe_score` relation. Message 084 is the execution record. The
message-084 single-use authority was consumed; at that checkpoint the
September migrations were not reached and no clean-replay or production-apply
gate was satisfied.

The subsequent retained-record search found no historical probe-score creator.
A read-only live catalog inspection recovered its current three-column schema
and absence of schema objects without reading row values. The reconstructed
schema-only bridge at artificial version 20260811233812 is internally verified
at SHA-256
`9f9a818f3370b849ba1ff21f1d4ea9c3adb9ab866b22e15f6ba7a03454b46b46`.
It and unchanged V2 form the proposed 209-version scratch input. Message 085
pins the evidence and tests. The Founder subsequently issued the exact
single-use GO naming both hashes. One fresh, seedless, isolated PostgreSQL 17.6
reset applied all 209 unique versions exactly once, exited 0 and reached both
September migrations. No repair/retry or post-result database query followed;
teardown was clean. Message 086 is the execution record. The replay authority
is consumed. Production was later changed only by the exact two-migration
cutover recorded in §1 and message 088.

### 13.3 Post-apply direct-call matrix — PASSED 2026-09-11

- Seeker A receives A-relative flags and only A's mutually released score.
- Seeker B receives B-relative flags and only B's mutually released score.
- First reveal writes only the caller's flag/score and returns no ordinary
  score; second reveal completes the mutual state.
- Neither Seeker can pass a counterpart id, score, reveal flag or side selector
  to the public signatures.
- Direct `SELECT`, `INSERT` and `UPDATE` by `authenticated` and `anon` fail.
- Null caller, `anon`, non-party Seeker and Guardian calls fail closed.
- Potential, ended, paused, wrong-stage and stale-attempt cases fail closed.
- Plus without entitlement fails; Plus with an exact caller-to-counterpart
  entitlement returns only the caller's score and changes no consent,
  timestamp, milestone, notification or stage.
- Function owner, `prosecdef`, `provolatile`, `proconfig`, comments and ACLs
  match the approved artifact; among the explicitly governed API roles,
  `PUBLIC`, `anon` and `service_role` have no function execution grant and
  `authenticated` does.
- The shared table remains RLS-enabled with no recreated permissive policies
  and no direct `authenticated`/`anon` privileges.
- Existing rows retain both scores/flags unchanged except for calls made by the
  authorised matrix itself.

The complete results are recorded with non-secret fixture labels, row deltas,
catalog output and exact artifact identities in message 088. The live matrix
passed without rewriting any expected result.

## 14. Authority and document map

- `ZYRA_PRODUCT_SPEC` owns the cross-feature Journey and entitlement model.
- `APP/Journey/PRE-JOURNEY RITUAL/Summary.md` owns the Compatibility Reveal
  screen/ritual truth and current private-score amendment.
- DR-ZYRA-135 owns the Plus early-sight exception.
- DR-ZYRA-227 owns the temporary two-layer Request New Journey hold for the
  bounded Founder-only TestFlight.
- OA-ZYRA-193 owns the plain-count, two-private-score scoring direction and
  category-truth cleanup.
- OA-ZYRA-283 owns this shared-row server authorisation defect.
- `SYSTEM/RESOURCES/MESSAGES/075_CODEX-FOUNDER_2026-09-10_REQUEST_NEW_
  JOURNEY_TEMPORARY_HOLD_INTERNALLY_VERIFIED.md` records the implementation
  evidence, true pre-states, staged hold hash and the then-remaining
  OA-ZYRA-198 gate.
- `SYSTEM/RESOURCES/MESSAGES/078_CODEX-FOUNDER_2026-09-11_OA-ZYRA-198_
  CHRONOLOGY_ARCHIVED_CLEAN_REPLAY_SECOND_FAILURE.md` records the
  Founder-approved chronology archive, exact reverse evidence, isolated replay
  controls and measured `153416` / `42P01` stop.
- `SYSTEM/RESOURCES/MESSAGES/079_CODEX-FOUNDER_2026-09-11_OA-ZYRA-198_
  PROVENANCE_ABSENT_RECONSTRUCTION_RULING_REQUIRED.md` records the exhaustive
  provenance recovery, byte-pinned reconstruction anchors, governed stop and
  the exact Founder decision that was subsequently approved.
- `SYSTEM/RESOURCES/MESSAGES/080_CODEX-FOUNDER_2026-09-11_OA-ZYRA-198_
  REPLAY_BRIDGE_INTERNALLY_VERIFIED_ONE_REPLAY_GO_REQUIRED.md` records the
  bridge identity, reconstructed catalog/security contract, review evidence
  and pre-execution one-replay gate.
- `SYSTEM/RESOURCES/MESSAGES/081_CODEX-FOUNDER_2026-09-11_OA-ZYRA-198_
  ONE_REPLAY_FIRST_RESULT_BRIDGE_ACL_POSTCONDITION_FAILED.md` records the exact
  one-use Founder authorisation, isolated reset input, measured SQLSTATE
  `22023` first result, raw-log identity and teardown evidence.
- `SYSTEM/RESOURCES/MESSAGES/082_CODEX-FOUNDER_2026-09-11_OA-ZYRA-198_
  V2_BRIDGE_INTERNALLY_VERIFIED_ONE_REPLAY_GO_REQUIRED.md` records the
  immutable V1 lineage, exact V2 identity and one-query correction, PostgreSQL
  17 runtime proof, minimal-predecessor integration result and the exact gate
  later consumed by message 084.
- `SYSTEM/RESOURCES/MESSAGES/083_CODEX-FOUNDER_2026-09-11_TESTFLIGHT_
  INTERNAL_OFFLINE_PREFLIGHT_COMPLETE_GATES_HELD.md` records the source-owned
  build-2 identity, internal-only export contract, export-compliance audit,
  release guards, unsigned compile and unchanged external gates.
- `SYSTEM/RESOURCES/MESSAGES/084_CODEX-FOUNDER_2026-09-11_OA-ZYRA-198_
  V2_ONE_REPLAY_FIRST_RESULT_PROBE_SCORE_CREATOR_GAP.md` records the exact
  single-use Founder authorisation, V2 PASS, measured 11233813 statement 7 /
  SQLSTATE 42P01 first result, raw-log identity and teardown evidence.
- `SYSTEM/RESOURCES/MESSAGES/085_CODEX-FOUNDER_2026-09-11_OA-ZYRA-198_
  PROBE_SCORE_BRIDGE_INTERNALLY_VERIFIED_REPLAY_GO_REQUIRED.md` records the
  absent creator provenance, read-only live catalog contract, quarantined
  schema-only bridge identity, PostgreSQL 17 proof, Apple portal verification
  and the next exact single-use replay gate.
- `SYSTEM/RESOURCES/MESSAGES/086_CODEX-FOUNDER_2026-09-11_OA-ZYRA-198_
  CLEAN_209_VERSION_REPLAY_PASSED.md` records the consumed exact authority,
  209-version input, reset exit 0, both September migrations reached, raw-log
  identity, teardown and unchanged production/upload gates.
- `SYSTEM/RESOURCES/MESSAGES/087_CODEX-FOUNDER_2026-09-11_OA-ZYRA-198_
  FOUNDER_ACCEPTED_CLOSED.md` records the Founder's direct acceptance of that
  post-verified result and closes OA-ZYRA-198 without widening either later
  release gate.
- This handover owns what is actually prepared, what remains staged, the file
  identities, boundary/data flow, cutover risk and pending evidence.
- `ZYRA_JOURNEY_FIELD_CLASSIFICATION` and older compatibility/category text
  contain stale joint-score or synthetic-category descriptions where they
  conflict with the later Founder-ratified two-score truth. Those conflicts are
  named here; they are not silently treated as current implementation truth.

## 15. Ordered next steps

1. Preserve the executed `461c3bd0...9055` bridge and message 081 evidence
   unchanged. Exact history is not recoverable; never label reconstruction as
   retained production history or alter the eight exact recovered bodies to
   conceal the gap.
2. Preserve the now-full-replayed V2 artifact at SHA-256
   `337b342df347b7e902d8da32bafd0a2b21516550b9234213298079304ca66aa1`
   outside the active migration path. Never place V1 and V2 together in a
   scratch replay.
3. Preserve the probe-score schema bridge at SHA-256
   `9f9a818f3370b849ba1ff21f1d4ea9c3adb9ab866b22e15f6ba7a03454b46b46`
   outside the active path together with message 086 and raw-log hash
   `42f948b8d...a813`. The exact 209-version replay passed; its one-use GO is
   consumed and authorises no repeat.
4. Completed once: the Founder named the exact production project, both exact
   hashes, quiesced order and stop conditions; the production Apply GO is
   consumed.
5. Completed atomically: OA-ZYRA-283 first, Request New Journey hold second,
   with ZYRA closed and no other migration or Apple upload.
6. Completed: both post-apply matrices and the complete live verification
   passed; this handover now records measured production truth.
7. Completed locally: the fresh signed, held Founder-internal IPA passed
   identity, distribution-signature, entitlement, profile and hash checks.
8. Completed: the exact IPA was uploaded once, Apple retained it as `Ready to
   Test`, and `Founder Internal` was configured with automatic distribution
   OFF, only the Founder account and only build 2. Pending: the Founder accepts
   the invitation, installs it and returns the device result. Only the Founder
   may close OA-ZYRA-283. OA-ZYRA-156 remains open for the permanent
   multi-attempt repair.

---

**State at filing:** EIGHT HISTORICAL BODIES RECOVERED / DUPLICATE HISTORY
ARCHIVED / QUESTION-BANK AND PROBE-SCORE PROVENANCE ABSENT / RECONSTRUCTION
ARTEFACTS QUARANTINED / V1 FAILED ONCE SQLSTATE 22023 / V2
`337b342d...66aa1` + PROBE BRIDGE `9f9a818f...46b46` / EXACT 209-VERSION
LOCAL REPLAY EXECUTED ONCE / RESET EXIT 0 / ALL 209 APPLIED ONCE / BOTH
SEPTEMBER MIGRATIONS REACHED AND COMPLETED LOCALLY / ONE-USE REPLAY AUTHORITY
CONSUMED / PRODUCTION CUTOVER AT EXACT HASHES APPLIED ATOMICALLY + POST-VERIFIED /
ZYRA REMAINED CLOSED / APPLE APP ID + APP STORE CONNECT RECORD VERIFIED /
FRESH INTERNAL-ONLY `1.0.0 (2)` IPA AT `1e17a1c...7b673` UPLOADED ONCE +
READY TO TEST / FOUNDER INTERNAL MANUAL GROUP / ONE TESTER + ONE BUILD /
NO EXTERNAL OR PUBLIC DISTRIBUTION / FOUNDER INSTALL + DEVICE RESULT PENDING.
DR-ZYRA-227 resolves the OA-ZYRA-156 interim release route. OA-ZYRA-198's
local replay target is Founder-accepted and closed by message 087. Production
GO, execution and post-verification are complete. The upload authority is
consumed; final OA-ZYRA-283/build acceptance remains a future Founder state.

## 16. Local client read and page-lifetime repairs measured 6 October 2026

This section records the current local source after the Founder's bounded
execution instruction in ZYRA FINAL REALEASE. Sections 1–15 and their filing
state remain dated history; none of their consumed migration/upload authorities
was reused. The following changes have local mock verification, not a new
production cutover, phone installation, release approval or Founder acceptance.

### 16.1 Explicit read result and unchanged score authority

`ZyraJourneyService.fetchCompatibility()` now returns an immutable
`ZyraCompatibilityReadResult`, not a tuple that also represented failures as
false reveal flags. Its status is `available`, `empty` or `unavailable`.
Only an available result carries a `ZyraCompatibilitySnapshot`; an unavailable
result carries a safe failure category. The scope captures the actual Auth
actor, observed `ZyraAccountState.generation` and match ID. Entry, post-await
and catch checks reject a result from another account lifetime.

An empty RPC list is confirmed empty, not consent. A successful row must be
exactly one map with explicit boolean reveal flags and an explicit finite
number or null `my_score`; a non-mutual ordinary result cannot expose a score.
Malformed shape/types and safe auth/access/configuration/transient categories
remain distinguishable. Provider payloads are not logged or shown as UI copy.
The snapshot's legacy Dart name `overallScore` still maps the viewer-owned
directional `my_score`; it does not introduce a shared score.

The RPC name/parameters, existing mapper, reveal method and Plus method were
preserved. The counterpart helper propagates the typed result. All current
SOURCE/lib consumers were checked and updated; no fallback getters turn an
unavailable result into invented defaults. DR-ZYRA-250's future-held scoring
change is not implemented or authorised by this client repair.

### 16.2 Current result, Retry and protected actions

The screen waits for the current visit's actual read before painting a cached
result. Only a confirmed same-actor/generation/match result can remain visible
after an actual transient refresh failure, and then it is display-only behind
`IgnorePointer`. Empty, malformed, definitive access/auth/context failures
clear confirmed/cache/celebration state. Retry is explicit and coalesces an
in-flight read; an unavailable or invalid result cannot trigger Reveal or Plus.

A valid live mutual/null-score result retains the existing first-score recovery.
Explicit Retry skips that legacy reveal recovery, but a validated live one-sided
result may still invoke the existing Plus RPC. That RPC can compute/persist a
viewer-owned score; Retry is not universally database-read-only. Read-only
history does not invoke either legacy reveal recovery or Plus.

Reads and the captured Reveal, Continue and Retry actions check account scope,
request generation and parent-surface ownership before dispatch and after
awaits. An observed account reset hides old scores immediately and preserves
the unprotected account-change warning without adding an immediate automatic
read just because its widget callback was replaced. The existing later polling
policy is unchanged; a valid current publication clears that reset latch.

### 16.3 Known parent context and animation lifetime

A strict public-screen test reproduced a real local defect: after a confirmed
stage change, an old compatibility subtree remained mounted during the existing
480 ms page animation and a late mutual/null-score read dispatched recovery.
A separate retained old Retry callback also dispatched a replacement-account
read. Both original failed logs were retained before their bounded repairs.

The parent now supplies private captured ownership with a monotonic observed
context generation. It observes build, non-null authoritative refresh and
callback checks. A known stage, pause, review, Guardian/identity hold, ended
state or relevant account/profile/match change retires the old surface and
invalidates only its previously admitted scope's cache and celebration.
Returning to the same section does not reactivate an old callback. Initial
loading on an ordinary unchanged-context revisit is not itself retirement.

The outgoing retired view cannot publish, recover, ask Plus, advance or render
protected cached content. Intentional initial prefetch is not gated on action
page visibility. Existing motion durations, easing, scenes and layouts remain
unchanged. Separately, the existing Atmosphere and VerticalStageSwap controllers
are now initialised in `initState`, preventing their reproduced lazy-initialiser
disposal exceptions; their 12-second/480 ms settings and disposal policy remain.

### 16.4 Source identity and internal evidence

The current journey service is SHA-256
`f2f395e615bf6dd55e8208c422d2fdd95b8bd52f25419a7933b281b1704a559c`.
The current Journey screen is
`468863f89851fd59089e6176f1f9eb448d6d19a421a4ec718560aa4d39db6449`.
Exact before/after snapshots, diffs and intermediate source stages are retained;
earlier pins remain historical rather than being rewritten.

All evidence below is in
`SYSTEM/RESOURCES/REVIEWS/ZYRA_INDEPENDENT_APP_CHECKS_2026-10-06/`:

- `NEXT_COMPATIBILITY_SERVICE_ACCEPTANCE.json` — 47 final service cases,
  44 strictly scripted read requests and zero unexpected requests; SHA-256
  `abe5eb04080537a6b372022dc1aadefd62a3afc320cd66e58af74cee3f732e68`.
- `NEXT_OA284_CALLER_REPAIR.json` — 33 original plus 11 new public-screen
  lifetime/Retry cases, and 18 logic/3 preview controls; SHA-256
  `063f930a6356308214a33c1d717476d2b4023da2343843c82eb15db292294d89`.
- `NEXT_JOURNEY_LIFECYCLE_REPAIR.json` — exact separate controller stage;
  SHA-256 `6b57029445e2d75fe760528c73f06eafa7a6c70d10dafe7ebd9da3c2b8423006`.
- `NEXT_OA284_SURFACE_REPAIR.json` and `NEXT_OA284_RETRY_REPAIR.json` —
  separate backed-up ownership/Retry stages and first failures.
- `NEXT_COMPATIBILITY_INDEPENDENT_REVIEW_STAGE.json` and
  `NEXT_COMPATIBILITY_INDEPENDENT_REVIEW_FINAL.json` — independent static
  review, with writer runtime results attributed rather than counted as the
  reviewer's own tests.
- `NEXT_COMPATIBILITY_SERVICE_ROOT_RUN.log`,
  `NEXT_OA284_CALLER_ROOT_RUN.log` and `NEXT_OA284_SURFACE_ROOT_RUN.log` —
  Main's successful repeat runs of 47, 33 and 11 cases.
- `NEXT_CONTINUATION_ROOT_ANALYZE_RUN3.log` — full SOURCE analysis, zero issues.
- `NEXT_CONTINUATION_ROOT_BROADER_REGRESSIONS_RUN3.log` — Main's 119 passing
  existing checks across 13 retained files. The prior RUN2 had a Main-supplied
  nonexistent test filename; that loading failure is preserved, not hidden or
  classified as a source defect.

Repeated runs, copied-but-filtered fixture cases, preview controls and earlier
audit counts are not added into a new project total. The two external public-
screen fixtures report 26 unsuppressed testing-member placement warnings and
zero analyzer errors; SOURCE analysis is clean. The original unavailable read
characterization and all initial lifecycle, account-reset, Retry and fixture
failures remain preserved.

`NEXT_JOURNEY_LIFECYCLE_PROVENANCE_CLARIFICATION.json` qualifies the original
controller-stage run: its retained log/events record 33 passes, including the
two lifecycle cases, but no immutable historical fixture-content/run binding
was retained. Its stronger historical claims about no teardown suppression and
the other 31 default-motion disposals are unverified for that original run.
The current pinned fixture and later successful reruns are independent current
evidence, not reconstructed historical proof. The original receipt and exact
two-class source diff remain unchanged; this clarification adds no coverage.

### 16.5 Remaining boundaries and acceptance

The tests use synthetic in-memory sessions, fake preferences and strict
`.invalid` HTTP mocks with developer/preview disabled. The existing public
Guardian loader returns fake ready; identity rollout is off. They do not prove
real Guardian/provider enforcement, paid credit authority, server writes,
RLS/grants, native authentication/accessibility or release-artifact behaviour.
The pending stage leave/return test measures disposal and ownership together;
it does not isolate the generation mechanism alone. Family Review, enforced
identity and Guardian rechecking holds have static source review, not newly
measured runtime acceptance.

Parent `refetchOne()` still collapses absent rows/profiles and transport/auth
failures to null. Its refresh retains previous parent fields on null, so it
cannot authenticate deletion/block-versus-transient state; that broader boundary
remains open. Entirely unobserved remote/offline revocation is not instant local
erasure, and read-only history has no polling. No new readiness/bootstrap seam
was introduced to disguise these limits.

History RPC controls use a roomy 800×1000 logical viewport to isolate lifetime
behaviour. Preserved tests also expose an unfixed 143-pixel Wali content overflow
at 800×600 and a 61-pixel ribbon overflow at 430×1000. These are separate
OA-ZYRA-305 layout follow-ups, not phone/native acceptance or fixes achieved by
changing the test viewport. OA-ZYRA-284/305 remain with ADMIN's single register
writer for reconciliation; this local packet does not self-close either action.

The Founder is away. None of these new client repairs was rebuilt for or
installed on the phone in this continuation. Identity-provider, moderation,
commerce/receipt, native release, poor-network and database-plus-photo restore
acceptance remain separate gates. Internal checks and this dated handover do
not replace Founder GO for those actions or Founder acceptance.

## 17. Guardian focus scrolling measured — 6 October 2026

This dated addition supersedes only §16's statement that the 143-pixel
unrevealed Wali focus overflow is unfixed. It does not replace earlier evidence
or close OA-ZYRA-305. Main completed the bounded P1–P5 repair under the Founder's
direct execution and bidirectional-coordination instructions. ZYRA ADMIN
remains the sole shared-register writer; internal verification is not Founder
acceptance, release GO or a readiness-score uplift.

### 17.1 Exact change and preservation

The only source edit is the 114-byte, unrevealed, reason-null focus wrapper in
`SOURCE/lib/screens/journey/journey_flow_screen.dart`, starting at line 7924.
Its `Expanded → Center → _guardianPortraitFocus(revealed: false)` becomes
`Expanded → LayoutBuilder → SingleChildScrollView →
ConstrainedBox(minHeight: available height) → Center → unchanged focus`.
The replacement is 501 bytes. The revealed focus, focus contents, fixed
96-pixel Reveal area, 218-pixel horizontal Guardian pager, copy, fonts,
consent/role gates, services and gestures are unchanged. Controller timing
(420 ms), parent timing (480 ms), load/accept/lifetime logic, Retry seals,
global gesture handling and the separate ribbon remain unchanged. No new
testing/readiness/bootstrap seam was introduced.

Source PRE is 354188 bytes / 9812 lines,
SHA256 `468863f89851fd59089e6176f1f9eb448d6d19a421a4ec718560aa4d39db6449`.
Source POST is 354575 bytes / 9823 lines,
SHA256 `66b50249939cb818eaf7a931bf3ba596c8205a84ec0c71e1ebb77a18fe34cd3f`.
Main read all PRE source lines before editing and made the new TRUE
`NEXT_WALI_FOCUS_SCROLL_PRE_SOURCE.dart` backup. Its exact POST snapshot is
`NEXT_WALI_FOCUS_SCROLL_POST_SOURCE.dart`. Both are distinct regular,
single-link files on the same device. Outside the replacement, all 354074
bytes are identical, SHA256
`96b355523ca3973d465e9ec6539a62545a23cd3b0eacb56cd660b27b4db55763`;
reverse replacement recovers PRE exactly. The new one-hunk patch and
`NEXT_WALI_FOCUS_SCROLL_SOURCE_DIFF.json` preserve that proof.

Five independently sealed SOURCE trees (lib excluding only this target, test,
supabase, ios and android) have matching pre/post aggregates. Generated
directory names Pods, .symlinks, build, .gradle and ephemeral were excluded;
symlinks were not followed. Dependency/configuration seals also match. No
other app source, service, schema, native configuration or dependency edit
is part of this repair.

The Wali service remains 60971 bytes / SHA256
`41e8d60505d3db7526d73b97574077e284c8b0507475d264ec223513a438c339`;
Journey service remains 76285 bytes / SHA256
`f2f395e615bf6dd55e8208c422d2fdd95b8bd52f25419a7933b281b1704a559c`;
CodeScreen remains 62187 bytes / SHA256
`029839431c16126c978a93fefb65b7d635bdc28880dde45491826bdaf2db226e`.
The Guardian handover, including §9, remains 35848 bytes / SHA256
`68564a6d0793e7afd292d3644e8a067a968619a64c6ef5a6776bc2b220676630`.

### 17.2 Public-route measurements and truthful counts

The new fixture imports the actual public `JourneyFlowScreen`, with DEV,
internal preview, main preview and telemetry false. An existing public
Guardian loader admits a ready fake state; SDK authentication/account state
and exactly intercepted HTTPS.invalid requests are in-memory fake records.
No live endpoint is connected. The fixture explicitly selects the vertical
PageView by `Axis.vertical`, distinct from the horizontal Guardian pager.
It uses actual controls, not private widget/state injection. Initial entry
makes seven intercepted requests. The mocked family-review RPC could mutate
state in production; these tests must not be described as proving a wholly
read-only production call graph. The actual Reveal action adds zero HTTP
requests here; unexpected requests remain zero.

There are **12 distinct new cases**, not 36: original attempts, validated
baseline, POST and Main repeats overlap. The validated unchanged-case baseline
is **2 PASS / 10 FAIL / 0 skipped, exit 1**. POST is **5 PASS / 7 FAIL /
0 skipped, exit 1**. Five POST passes cover:

- 800×600 normal-motion, neither revealed;
- 800×600 normal-motion, mine revealed and waiting, using actual Reveal;
- 800×1000 roomy, neither revealed;
- 800×1000 roomy, mine revealed and waiting;
- 800×600 normal-motion gestures: the inner vertical scroll moves while the
  outer page stays fixed; Reveal remains fixed and hittable without accidental
  reveal; two Guardians page horizontally 0→1→0; returning to the inner top
  permits the existing arrival-boundary action. No extra HTTP is triggered.

The validated 800×600 baseline measured 479-pixel focus content within
336 pixels, reproducing the 143-pixel overflow. The new scroll wrapper removes
that overflow in the normal-motion compact cases without changing viewport
size or hiding framework exceptions.

Seven POST failures remain OPEN and outside the authorized wrapper:

- Two 390×844 normal-motion cases, neither/mine: protected ribbon overflow
  (19 pixels right) and portrait overflow (96 pixels right and 13/29 pixels
  bottom).
- Two roomy 800×1000 cases with text scale 1.3, generated long names and
  24-pixel top/bottom safe insets: protected portrait overflow (12 pixels
  bottom).
- Three reduced-motion 800×600 cases, neither/mine/gestures: unchanged
  `_JourneyRoundActionState` first accesses lazy `_breath` during dispose,
  constructing a controller using a deactivated context (lines 3381/3389).
  Validated baseline mine already reproduced this disposal error. Baseline
  neither/gesture stopped earlier, so identical completed baseline teardown
  was not established for those two. POST neither and gesture also have
  secondary pending-timer errors; those are not separately isolated defects.

No `FlutterError`, `takeException` or teardown suppression was added.
theirsWaiting, mutual reveal and optional Salam remain **UNMEASURED / HELD**:
ordinary public refresh cannot set the theirs-revealed flag; its assignment
is in disabled DEV completion. No copied/private/DEV state was injected to
turn those states into passes. The existing horizontal-edge overscroll parent
notification-axis risk is also unmeasured and untouched.

### 17.3 Raw failures, regression checks and analysis

The first new fixture/log/events are preserved as FIRST, with **0 PASS /
12 FAIL, exit 1**: a premature 600-ms pump had not reached the asserted
page target, alongside the actual focus overflow. Bounded 16-ms frame pumps
(maximum 120), preserving destinations, viewports, controls and assertions,
produced the validated baseline above. These timing failures are not twelve
distinct source defects. The frozen current fixture is 19089 bytes, SHA256
`99855c8a74f6cd617b4d584a18ec620a85e130ff171cd76d3e54f3fe47122beb`.

The immutable validated-FIRST receipt mistakenly names `ZYRA/SYSTEM/SOURCE`
in its sourceBefore path; the actual source path is `ZYRA/SOURCE`. Its
PRE hash and TRUE backup are correct. The final core receipt explicitly
records this correction; the old JSON is not rewritten or presented as proof
that the erroneous path exists.

The older `NEXT_OA284_SURFACE_EXPANDED_SECOND.log` stays immutable:
6440 bytes / SHA256
`cc6c2b8fc145926b3642c69530f24f502ce434bb7920305b9fad37ff2ba04e1b`.
It contains both the historical 143-pixel overflow and an ambiguous
two-PageView finder. Neither historical failure is erased by the new fixture.
The separately known 61-pixel ribbon overflow remains OPEN; roomy lifetime
fixtures do not prove compact/native acceptance.

**77 retained distinct cases PASS / 0 FAIL / 0 skipped, zero new cases**:
caller 33, outgoing/parent lifetime 11, existing scroll 18 + preview handoff 3
+ Guardian selection 12. Two first runner attempts failed before any test
case/reporting, with missing native test-asset startup errors; their logs stay
preserved and their two event files remain absent. Sequential retries pass
the unchanged fixtures. Concurrency is a possible cause, not a proven cause;
these setup failures are not fabricated widget cases or native-app acceptance.

Main independently repeats three normal-motion core cases: **3 PASS,
exit 0**, overlapping the twelve, not added coverage. Full SOURCE PRE and
POST `flutter analyze --no-pub` each exit 0 with no issues. Targeted Journey
analysis also exits 0. External evidence-fixture analysis retains **13 new
fixture placement warnings** and **26 retained fixture placement warnings**,
zero errors, exit 2. The first core analyzer pipeline lacked pipefail and
reported exit 0 despite warnings; its raw log remains preserved and the final
exit-2 result is authoritative. No warning suppression or dependency update
was used. Main's two metadata-verifier invocation errors (wrong retained JSON
schema assumption, then shell quoting) changed no files; the corrected
verifier freshly checked core 19 and retained 26 physical pins plus two
declared absent reporter files. These tool errors are recorded separately,
not counted as app defects.

### 17.4 Evidence, handover and rollback

All new evidence is under
`SYSTEM/RESOURCES/REVIEWS/ZYRA_INDEPENDENT_APP_CHECKS_2026-10-06/`:

- `NEXT_OA305_WALI_FOCUS_PUBLIC_RECEIPT.json`: 31761 bytes, SHA256
  `9719eb8475b22af7586aa9d69c1cada35dde40bd4ad9437488346500346966c2`;
  baseline/POST/raw-event lineage, limits and physical pins.
- `NEXT_GUARDIAN_FOCUS_RETAINED_RECEIPT.json`: 27714 bytes, SHA256
  `813bba34ac5475ce026936ced3d20378bee5e208521a162081608375c0288925`;
  retained counts, runner retries, warnings and unchanged seals.
- `NEXT_WALI_FOCUS_SCROLL_ROOT_VERIFICATION.json`: 28292 bytes, SHA256
  `2ec415c54656afe1a3cc9356f012cfdac286608204275eb16556719370c2ee07`;
  Main checks, full-read/TRUE-backup facts, five-tree preservation and limits.
- `NEXT_WALI_FOCUS_SCROLL_ROOT_NORMAL_RECHECK.log`: 3133 bytes, SHA256
  `ee0158a40c06c6fca4edb172a72b8aabb467543ac937fdbfe3cf0732a8d838d9`.

Main read all 1071 pre-existing handover lines and made
`NEXT_WALI_FOCUS_SCROLL_PRE_HANDOVER.md`, exactly 59811 bytes / SHA256
`61329fecb5b5b656b82f650287d41c9ef9d013745f56af82cb16f3f7ccaedd9e`,
before this single additive §17. Those original bytes must remain the exact
prefix of the updated document. New document reconciliation, independent
review and final handover receipts will pin the post-append document; no old
receipt, index or history is rewritten.

Surgical rollback, if appropriately authorized, replaces only the exact
501-byte wrapper with the original 114-byte wrapper and verifies the PRE
hash. Do not wholesale restore a stale source snapshot, run Git or change
live database/RLS state.

The Founder remains away. No native app build/install/launch, phone delivery,
live Supabase/database/provider operation, trusted moderation, store payment,
receipt verification, DR-ZYRA-250 change or release action occurred. Native
accessibility/orientation, provider/admission, commerce, poor-network and
database-plus-photo restore acceptance remain separate gates. The residual
layout/reduced-motion/ordinary-route gaps are relayed under existing
OA-ZYRA-305 for bounded next-work reconciliation, not self-closed or assigned
an invented new OA. Build evidence, internal verification, Founder GO,
execution/post-verification and Founder acceptance remain distinct.

## 18. Reduced-motion action lifecycle repaired — 6 October 2026

This is a separate, bounded follow-up to §17 under OA-ZYRA-305, not a rewrite
of its dated 5-PASS/7-FAIL matrix. The Founder's direct away-work execution and
bidirectional coordination instructions cover this reversible local repair;
the release coordinator supplied the exact RoundAction-only scope. Internal
verification does not close the OA, raise release scores or replace Founder
GO/acceptance. ADMIN remains the sole shared-register writer.

### 18.1 As-built lifecycle change

Only the inline lazy controller initializer in
`SOURCE/lib/screens/journey/journey_flow_screen.dart`,
`_JourneyRoundActionState`, changes. The field is now
`late final AnimationController _breath;`; a new `initState` calls
`super.initState()` then creates the same controller with `vsync: this`,
1800-ms duration and value 0.5. No repeat, forward, reverse or other start
call was introduced. Existing dispose, build, reduced-motion action value,
styles, copy, labels, semantics, callbacks, paging and consent remain
unchanged. The Wali focus wrapper and revealed path, service/read/lifetime
logic, global gestures, ribbon, portrait and enlarged-text layout are
untouched.

The original 152-byte initializer becomes 234 bytes. PRE source is
354575 bytes / 9823 lines, SHA256
`66b50249939cb818eaf7a931bf3ba596c8205a84ec0c71e1ebb77a18fe34cd3f`;
POST is 354657 bytes / 9829 lines, SHA256
`631eef3d73d4edf200573bb8b76195082bf69ba7cd4f811cb22b3134cd3b15a2`.
The source class excluding its trailing LF is PRE 3373 bytes / SHA256
`4c8876bde3b2ea9472e4e5f8d63a93a303a8719284dbd78c9bd45efe0cc813b7`,
POST 3455 bytes / SHA256
`f589962ebe2f5d3ef85e70fb29918d959f895fe1661d12cd86530be80429879d`.
The previously reported 3374-byte class slice includes one trailing LF;
that boundary difference is not drift.

Outside the exact initializer replacement, 354423 bytes are identical,
SHA256 `8d922a18aa426a00c2f2df563a3450ee77fa4d99e92a0927eb68f6e7633befc4`.
Reverse replacement recovers the entire PRE, retaining the Wali scroll repair.
Fresh regular, single-link, distinct same-device TRUE PRE/POST snapshots
and the one-hunk diff are saved under `NEXT_OA305_ROUND_LIFECYCLE_`.

Main read all current PRE source bytes and compared the whole file with
the exact just-sealed Wali post snapshot: prior full source reading plus
only the already-reviewed Wali wrapper applies to this unchanged continuation
prestate. Main also read the full PRE/POST class, frozen public fixture and
actual disposal stacks. A fresh five-tree traversal matches §17's preceding
SOURCE/lib-outside-target, test, supabase, ios and android aggregates, using
the same ZYRA-relative paths and per-directory ASCII-sorted traversal.
Companion services, CodeScreen, dependencies/configuration and Guardian §9
remain unchanged. The retained checker also verified all 18 selected
source/config/fixture/old-receipt inputs unchanged throughout its run.

### 18.2 Test-first evidence and exact counts

A fresh run of the same three ordinary-public reduced-motion cases on PRE
produced **0 PASS / 3 FAIL / 0 skipped, exit 1**. All three completed their
body observations and failed during disposal:
lazy `_breath` first constructed an AnimationController after the state
was deactivated, triggering TickerMode ancestor lookup. Neither and gesture
also reported secondary pending 8-second timers; mine did not. Those timers
were recorded, not asserted as an independently isolated timer defect.

After the exact lifecycle patch, the **same three PASS / 0 FAIL / 0 skipped,
exit 0**, with no disposal or pending-timer messages. The unchanged full
12-case fixture then reports **8 PASS / 4 FAIL / 0 skipped, exit 1**.
All measurements are reruns of the existing 12 distinct case identities:
this stage adds **zero new unique cases**, not 18. Main's three normal-motion
repeats also pass, overlapping that matrix rather than adding coverage.

Normal and reduced-motion controls preserve actual inner vertical scrolling,
the outer action page, horizontal two-Guardian paging 0→1→0, top-boundary
return to arrival and reentry, the fixed/hittable 96-pixel Reveal area,
local mine-waiting reveal and no unintended reveal/advance or extra HTTP.
The same frozen 19089-byte fixture,
SHA256 `99855c8a74f6cd617b4d584a18ec620a85e130ff171cd76d3e54f3fe47122beb`,
uses the actual imported public JourneyFlowScreen, existing public Guardian
loader, generated unsigned SDK actors, test fonts and strict HTTPS.invalid
mock interception. DEV/preview/telemetry are false. There is no private
widget injection, new readiness seam, viewport/assertion change or exception/
teardown suppression. Initial entry has seven intercepted requests and
unexpected HTTP remains zero. The existing mocked family-review resolver
can persist state in production; this is not live or wholly database-read-only
acceptance.

The **four remaining full-matrix failures are unchanged and OPEN**:

- Two 390×844 normal-motion cases: ribbon Row at line 2564, 19 pixels right;
  protected portrait Row at line 8194, 96 pixels right; protected Column
  at line 8152, 13/29 pixels bottom.
- Two 800×1000 cases with text scale 1.3, long generated name and 24-pixel
  safe insets: protected Column at line 8152, 12 pixels bottom.

The independently known historical 61-pixel ribbon failure stays separate.
theirsWaiting, mutual reveal and optional Salam remain ordinary-route
UNMEASURED/HELD; no disabled DEV completion/private state was injected.
Horizontal-edge overscroll notification-axis behavior remains unmeasured
outside the finite pager controls.

The retained suite passes **77 / 0 FAIL / 0 skipped**, first attempt,
serially: caller 33 + outgoing/parent lifetime 11 + existing scroll/Guardian
controls 33. These are repeats, not another 77 unique cases or layout/native
acceptance. No startup failure occurred in this stage; the earlier §17
startup failures and absent reporter files remain immutable dated evidence.
Full SOURCE analysis on POST exits 0 with no issues; targeted source analysis
also exits 0. Fresh external analysis preserves 13 frozen-fixture warnings
and 26 retained-fixture warnings, zero errors, exit 2. These are unsuppressed
public testing-hook placement warnings, not clean analyzer passes.

### 18.3 Evidence, documentation and limits

New files in the existing 6 October review directory:

- `NEXT_OA305_ROUND_LIFECYCLE_BASELINE.json`: 5027 bytes / SHA256
  `2c6fd4d0d7d9e1f6723d57db26c6358c376fe7e294e16db0b95e48510f8b619a`.
- `NEXT_OA305_ROUND_LIFECYCLE_RECEIPT.json`: 40107 bytes / SHA256
  `acc86b8df31c87c8d9fb78935e3f6eef06b6c93c76705e0aeef7f54100844e93`.
- `NEXT_OA305_ROUND_LIFECYCLE_RETAINED_RECEIPT.json`: 22780 bytes / SHA256
  `0f8f338ae0a48b9044ffbcf9c36199bcb3a8a0fbba797257f4e1b285059f4485`.
- `NEXT_OA305_ROUND_LIFECYCLE_ANALYZER_RECEIPT.json`: 2981 bytes / SHA256
  `9937fb98b1a1023f1e2fc4be7bee9ae5849360c6f5898f83b6eb7b2691fed23a`;
  additive fresh analyzer evidence after the core receipt was sealed, which
  is not rewritten.
- `NEXT_OA305_ROUND_LIFECYCLE_ROOT_VERIFICATION.json`: 31376 bytes /
  SHA256 `02e1c70d98d0532f392f982f6a3ad36a501179ca879f036eb7016b004162abbd`; fresh full analysis,
  normal repeats, exact boundary/backups, tree algorithm and tool qualifications.

Main freshly read/compared the whole 71074-byte PRE handover, whose 1265 lines
are the previously fully-read 1071 lines plus the unchanged §17 addition.
TRUE `NEXT_OA305_ROUND_LIFECYCLE_PRE_HANDOVER.md` is exactly 71074 bytes,
SHA256 `0989c5b6528d1fc1eccf43dc6919c56f65dd23e9fc454a82bc9966a01360526c`.
This is exactly one additive §18; those old bytes must remain the entire
prefix. New document proof/independent review/final receipts pin POST.
All earlier raw failures, mistaken historical source-path metadata and
source-bound stages remain unaltered.

Two no-write preparatory checks rejected reconstructed document text with
extra newline bytes before the TRUE backup was created; the exact backup
then matched. A first tree comparison used root-relative rather than the
original ZYRA-relative record paths; the same original algorithm freshly
matches all five trees. These are metadata/tool qualifications, not app
defects or hidden source changes; raw tool transcripts are not invented
as historical sealed log files. Diff exit 1 records the expected source
difference, not failed acceptance.

Flutter's primary [controller lifecycle documentation](https://api.flutter.dev/flutter/animation/AnimationController-class.html)
and [ticker implementation](https://api.flutter.dev/flutter/widgets/SingleTickerProviderStateMixin/createTicker.html)
were checked today. They support creating the controller during initState
and disposing it later; the fresh runtime measurements above, not the
documentation alone, support this bounded repair.

Rollback, if appropriately authorized, replaces only the exact 234-byte
initializer/initState with the 152-byte old initializer, then verifies
354575 bytes / PRE66b502…; it keeps the Wali wrapper intact. No rollback or
Git operation occurred.

The Founder remains away: no native app build/install/launch or phone
delivery, live database/provider/RLS operation, dependency/store/commerce/
receipt-authority change, DR-ZYRA-250 change, release action, new OA,
register edit or status/score/closure uplift. Native/accessibility/recovery/
poor-network/remote revocation/payment/provider/database-photo restore
acceptance remain separate gates. Residual layout and ordinary-route
criteria are handed back under existing OA-ZYRA-305, not self-approved.

## 19. 2026-10-06 — bounded Guardian portrait and selected-ribbon responsiveness (OA-ZYRA-305)

This is one additive as-built handover under the Founder's verified
routine-local execution and bidirectional chat authority, coordinated with
ZYRA FINAL REALEASE. It records internal implementation and checks, not
Founder acceptance or release approval. Sections 1–18 remain byte-for-byte
unchanged: the true pre-document is 80662 bytes, SHA256
098b66c6ff3388105426cf6a27a4623dc219ec9f2bd54c0d7ab520f8cf54ceec.
The source and document were backed up as regular, single-link files on
the same filesystem before editing.

### Exact implementation and preservation

Only three spans in two existing widgets changed in
SOURCE/lib/screens/journey/journey_flow_screen.dart:

- _ProtectedGuardianPortrait: its unchanged 82px decorative avatar is now
  inside Flexible(loose) and FittedBox(scaleDown); its unchanged footer
  Text is directly Flexible and centered so it can wrap.
- _JourneyRibbon: only the selected pill becomes
  Flexible(loose) → IntrinsicWidth → existing Container with minimum
  height 24 rather than fixed height 24 → centered existing Text.

No font size, copy, gold treatment, padding, border, ordering, navigation
callback or consent changed. The parent Row, 3px separators, 20×24
nonselected markers and their 9px dots remain unchanged. The fixed 96px
Reveal target, 218px horizontal Guardian pager, earlier Wali scroll fix
and 420/480ms gesture timing remain intact. The earlier _RoundAction
class is still 3455 bytes / f589962ebe2f5d3ef85e70fb29918d959f895fe1661d12cd86530be80429879d.

Source stages (full-byte SHA256):

- True PRE: 354657 bytes / 631eef3d73d4edf200573bb8b76195082bf69ba7cd4f811cb22b3134cd3b15a2.
- Portrait-only: 355002 bytes / e3b119c80e60da8a8f238487b5753436e5d9e6301ae0c52c5ba38103b4eb5ed7.
- Final: 355277 bytes, 9844 lines / 10b679778c9bcd7c1b8a1fe51b4194d3c31d4cfcf0798b78808623b46de77266.

Avatar span: 563→793 bytes. Footer span: 233→348 bytes. Selected pill:
723→998 bytes. Omitting only these three exact spans gives identical
353138-byte outside content / 8430b785c50a658353c12a39e5f2d71bfa7392c2d1c3bac43459ccfd9ff9cc7d.
Reversing all three edits reproduces the true PRE exactly. Individual
portrait and ribbon phase outside/reversal checks also pass.

The Main fresh five-tree inventories (SOURCE/lib excluding the target,
test, supabase, ios and android; explicitly excluding generated
directories and not following links) match the pre-edit inventories.
The Supabase tree count is 386, including the two already-known earlier
backup additions; no claim is made that an older 384-file inventory is
unchanged. Services, dependencies, configs, existing tests and the
Guardian handover remain pinned unchanged. The latter is 35848 bytes /
68564a6d0793e7afd292d3644e8a067a968619a64c6ef5a6776bc2b220676630.

### Runtime results, including failed attempts

The old 19089-byte public fixture remains unchanged / SHA256
99855c8a74f6cd617b4d584a18ec620a85e130ff171cd76d3e54f3fe47122beb.
Its same four focused cases were PRE 0 pass / 4 fail; portrait-only
2 pass / 2 fail; final 4 pass / 0 fail. The complete frozen 12-case final
run is 12 pass / 0 fail / 0 skip. It includes normal and reduced motion,
vertical content reading, two-Guardian horizontal paging, top-boundary
return and fixed-Reveal hit testing. Repeated focused cases add no
unique coverage.

Exactly 18 new cases were authored: eight real canonical stages at
800×1000/default and 390×844/enlarged text 1.3 with long generated name
and 24px safe insets; one wide 82px-avatar/full-copy/fixed-Reveal case;
one completed-stage navigation/current-future-disabled case. Eight
canonical server stages produce nine displayed marks because Life
Snapshot is an inserted preview. No selected-Life-Snapshot case was
authored. Canonical family_stage is not the FamilyReview override.

The new first attempt was 1 pass / 17 fail, exit 1. It had an
over-strict selection rounding check (0.125px) and missing legitimate
mock GET routes; it is retained as fixture-invalid, not seventeen
product defects. Only the new fixture received exact, strictly asserted
synthetic read mocks and rounding allowance, first 1px, then tightened
to 0.25px before freezing. Original tests and framework-error/teardown
assertions were not weakened. The intermediate and frozen PRE runs
were both 10 pass / 8 fail: the eight narrow cases exposed genuine
93–184px old RibbonRow overflow.

The final frozen new fixture is 23741 bytes / SHA256
615640cf58a0ac9ce127558c7ff828c61d82d028d76571560dd1d4c6b2294932.
Its POST is 14 pass / 4 fail, exit 1, not an all-green 18-case result.
The original RibbonRow overflow is gone. The four remaining
phase1/phase2/phase3/family narrow full-selection-bound assertions
remain recorded as failed.

An authorized diagnostic-only copy added a TextBox import and
per-character prints immediately before the same assertions, with
identical mocks, viewports, tolerances and cleanup. Its four executions
are overlapping cases and remain 0 pass / 4 fail, exit 1. At paragraph
width 181, all out-of-bounds character rectangles are trailing spaces
(offsets 11/14/14/10); non-whitespace selection boxes fit, the full
copy remains present, maxLines is null and didExceedMaxLines is false.
This supports no observed letter-box clipping in these synthetic-font
cases, not native painted-glyph acceptance or a retroactive PASS.
No post-diagnostic expectation repair or further green rerun occurred.

The three phase cases also expose a genuine, unsuppressed 68px
horizontal overflow in the unchanged _JourneyQuestionChapterBriefing
bottom lock/count Row at final source line 4384 (width 326). It is an
additional OA-ZYRA-305 finding outside this two-widget packet. It was
not repaired here and has been handed back for a separate bounded
repair; no isolated pre-patch briefing measurement is claimed.

All eight wide canonical PRE/POST geometry records match exactly,
including item rectangles, 24px selected height, original fonts,
nine markers and natural-width-plus-25px pill widths. A ninth geometry
record repeats the completed-navigation case, not another case.

The separate retained suite is 77 first-attempt pass / 0 fail / 0 skip,
with no retries or additional unique cases: 33 caller, 11 filtered
outgoing/parent-history and 33 existing (18 scroll, 3 preview, 12
Guardian selection). Its 553-Dart source/test aggregate is unchanged
14525fc81bff7f5d7db44cfc0b9e546b0c278716a1260526d733853f00e4d13b.

### Analysis, evidence and limits

Main SOURCE flutter analyze --no-pub exits 0 with no issues. The old
external fixture analyze exits 2 with 13 placement warnings; new
external fixture exits 2 with 14 warnings (13 placement plus unused
copied helper); diagnostic exits 2 with those 14 warnings plus one
unnecessary-import information item. Retained external two-fixture
analysis has 26 placement warnings, exit 2. These unsuppressed,
overlapping issue sets are not summed or called clean; all have zero
analyzer errors.

New pipelines put set -o pipefail before test/analyzer | tee. The
additive CORE_PIPEFAIL_CLARIFICATION records earlier RoundAction
command ordering as the command owner's retained-input attestation.
Main/reviewer independently check physical pins and raw event results,
not independently retrieved historical shell sessions. Old receipts,
raw failures, seals and handover sections are not rewritten.

The complete bounded packet is in
SYSTEM/RESOURCES/REVIEWS/ZYRA_INDEPENDENT_APP_CHECKS_2026-10-06,
under NEXT_OA305_RESPONSIVE_*: true backups, individual/composite source
proofs, immutable first/intermediate/frozen fixtures, raw events/logs,
Core, retained, Main and independent receipts, document-prefix proof
and final handover. Raw events back the counts above; internal review
remains distinct from Founder GO and acceptance.

Supabase SDK setup is synthetic, with deny-by-default intercepted
transport, generated fake actors, disabled refresh, cleared account
scope/preferences, unsuppressed teardown and no main-bootstrap
readiness override. Mock RPCs can be stateful on a real server; these
checks do not prove production database read-only policy, RLS,
provider verification or member consent. The FamilyReview override
is held because the ordinary service readiness guard exits before its
query; no private bypass was used. Selected Life Snapshot,
other-party-only/mutual reveal, optional Salam, native fonts,
accessibility/performance and broader extreme-name/edge gestures
remain unmeasured in this packet.

The Founder remains away. No phone delivery, native build/install/
foreground, live database/provider action, dependency/store/commerce
change, register edit, new OA, Git/PRIVATE access, spending/destruction,
release action, DR-ZYRA-250 change, OA closure, score uplift or Founder
acceptance occurred. The separate briefing overflow and held ordinary/
native/security/admission/payment/recovery/restore acceptance remain
open. Rollback would require appropriate authority and exact reversal
of only these three spans; none occurred.

## 20. OA-ZYRA-305 question-footer baseline and P3 source HOLD — 2026-10-06

### Scope and implementation state

The coordinator's eighth away-work P1–P5 packet permitted only wrapping
the existing question-count Text in Flexible(loose), centering that same
copy, plus new evidence and this additive handover section. P3 explicitly
requires a hold if that text-only hunk cannot satisfy arrival-cue clearance.
Founder local execution and bidirectional internal messaging authority
remain separate from internal review and Founder acceptance.

No chapter-footer SOURCE change was made. Current Journey SOURCE is
355277 bytes / SHA256
10b679778c9bcd7c1b8a1fe51b4194d3c31d4cfcf0798b78808623b46de77266,
exactly equal to this stage's true PRE backup. The earlier portrait,
Wali footer, selected ribbon and RoundAction fixes remain intact. The
question-footer class is 1977 bytes / SHA256
27bc18f67b3210191303a04ddf46a55cb36ff9cb3209689a2c9411c557292575,
excluding its trailing LF. The prospective Flexible hunk exists only
as a plan and was not applied.

This section appends to the unchanged 89761-byte document PRE prefix,
SHA256 0a08f86ed9858e7809d5a89c44488fcac594f25667719df147e1e3522cca2c45.
Earlier raw failures, receipts, seals and sections 1–19 were not rewritten.
No Guardian document or shared OA register edit is made by Main.

### Frozen baseline and counting

The new frozen follow-on fixture is 30504 bytes / SHA256
30f4016c02fef67740c136e77611276cc53720d51cb6018b2b9799859be583e2.
It retains the same eighteen overlapping product-case identities,
mocks, setup, viewports and unsuppressed cleanup. It adds exactly three
pure per-character rectangle-predicate controls, not new product flows.
The predicate ignores whitespace but rejects missing, non-finite or
out-of-bounds non-whitespace boxes with the unchanged 0.25px tolerance.

FIRST helper run: 3 pass / 0 fail / 0 skip, exit 0.
FIRST full PRE21: 18 pass / 3 fail / 0 skip, exit 1: fifteen of the
copied eighteen product cases pass; three narrow phase cases fail; the
three repeated helper cases pass. Thus there are 24 executions across
21 distinct case identities, only three new predicate identities and
zero new product cases. No setup/authoring failures or suppressed
framework, timer or teardown errors occurred.

The three narrow phase1/phase2/phase3 cases reproduce a genuine 68px
right RenderFlex overflow at unchanged SOURCE line 4384. The unflexed
Text width is 375.299835px against a 326px Row also containing a 13px
lock and 6px gap. Text-right containment fails at fixture line 669;
the earlier raw framework failures remain unsuppressed. The old four
trailing-space selection-box failures remain preserved as historical
failures, not retroactively reclassified as PASS.

### Same-page clearance finding and why source is held

Raw geometry printed before the narrow containment assertions shows
footer-to-cue clearance (cue top minus footer Row bottom) of
-82.281484px / -78.361484px / -80.601484px for phase1/2/3.
All three use cue rectangle [32,694.038516,326,98] and arrival pages
4/5/6. These are measured rectangle overlaps, not separately reached
cue-clearance assertion failures. Narrow cue hitTestable/clearance
assertions occur later and were NOT reached; narrow hittability is
not accepted.

The single vertical pager's arrival branch contains both the unique
question briefing and the unique count-labelled Begin Question cue
within the same Stack. Reached finder uniqueness, observed arrival
pages, current source ownership and retained framework creator context
support the same-page binding. No separate runtime Element common-
ancestor trace was captured; this is source/raw-context binding, not
that additional measurement.

All three corresponding wide cases fully pass the footer, semantic,
diagram, cue-hittability and clearance assertions. Each wide footer
Row is [245.375,622.12,309.25,15], Text is
[264.375,622.12,290.25,15], and clearance is 263.918516px.
These are PRE-only geometry results, not POST equivalence.

Actual fixture surfaces are 800×1000, scale 1, no insets (wide), and
390×844, scale 1.3, 24px top/bottom insets with a generated long
counterpart name (narrow). The logged viewport Size(800,600) describes
the test view's physical-size/DPR field, not setSurfaceSize used for
layout. No viewport, name or tolerance was refitted after freezing.

The allowed footer-only wrapping hunk cannot resolve the measured
vertical body/cue overlap; increased wrapped height may worsen it
(inference, not a POST observation). Arrival body/cue reservation is
outside that hunk. P3 therefore holds SOURCE continuation pending a
separately bounded arrival-layout packet under existing Founder GO.
No wider body, diagram, font/copy, cue, pager or gesture redesign
was implemented, and no partial text-only fix was applied.

### Evidence, preservation and limits

Evidence is additive under NEXT_OA305_CHAPTER_FOOTER_* in the existing
2026-10-06 independent-review directory: true SOURCE/document backups,
MAIN_SCOPE, frozen fixture, FIRST helper/PRE logs and events,
BASELINE and the sealed 24178-byte BASELINE_RECEIPT (SHA256
24700de0789d00f60421d4e4acf81186b9f3720b10d99bd2e90e8d964f3b5253),
Main raw/pin verification, independent receipt and final hold handover.
Main freshly checked all sixteen baseline receipt/input pins and
the five outside-source tree aggregates unchanged.

Supabase skill informed the unchanged isolated fake-session, .invalid
deny-by-default intercepted transport and unsuppressed cleanup.
All six measured footer records show nine expected HTTP calls and
zero unexpected calls. No live provider/database/member, readiness
bypass or private injection was used. Synthetic-font selection boxes
are not native painted-glyph, accessibility or performance acceptance.

SOURCE is unchanged and runtime released. POST21, the original12
rerun, retained77 rerun and analyzer are NOT RUN in this baseline-only
stage. No phone/native build/install/launch, live security/admission/
payment/recovery/restore acceptance, dependencies, Git/PRIVATE access,
spend/destruction, release action, new OA, OA closure, score uplift
or Founder acceptance occurred. This finding remains within existing
OA-ZYRA-305; Main hands the P3 hold back for the next exact scoped
repair, rather than claiming completion.

## 21. OA-ZYRA-305 whole-arrival fit measurement and source hold — 2026-10-06

### What the new measurement establishes

The ninth local packet permitted question-only placement/reservation
and the existing footer Flexible correction only if the unchanged
body could fit between unchanged cues. No SOURCE hunk was applied:
the enlarged-text bodies already exceed that space before wrapping.

At the settled 390×844 surface, scale1.3 and controlled24px top/bottom
insets, phase1/2/3 actual body heights are501/473/477px. Available
space between the mounted upper and lower cues is383/362/362px.
The current height deficits are118/111/115px. Moving the body cannot
remove these deficits while preserving fonts, copy, gaps and cues.

The unchanged footer paragraph needs40px intrinsic height at its
prospective307px available width, versus its current20px height.
Adding that20px predicts total bodies521/493/497px and deficits
138/131/135px. This is an intrinsic estimate, not an implemented
POST result. The actual existing-body deficits independently establish
the hold, so the decision does not depend on the wrapping estimate.

All wide phase controls have258px bodies,742px available space and
484px spare height. Ordinary and disableAnimations=true cases share
the same settled geometry. The preferred optical alignment remains
unmodified; no hardcoded viewport cutoff or partial footer fix landed.

### Independent fit checks and evidence counts

The new frozen public fixture is40445 bytes / SHA256
fa7016be8fe7ed4b1222feb8b5cea59f478873cfc46971ac602985e767e9aabb.
It adds only9941 bytes of geometry helper/cases to the unchanged
30504-byte earlier fixture: removing that insertion exactly recovers
the old fixture, including all21 identities, mocks and assertions.

FIRST PRE43 exits1:34 pass /9 fail /0 skip. The copied21 remain
18 pass /3 fail. New22 geometry controls are16 pass /6 fail:
eight canonical arrivals across two layouts plus six overlapping
question reduced-motion cases. There are no new product flows or
pure predicate identities. Nine68px horizontal framework reports
are repeated executions of three routes, not nine unique defects.

The44 geometry records contain two animation samples per case.
Each full body and both cues reach the identical mounted arrival
Stack ancestor before logging. Intrinsic body height equals actual
height and the sum of direct-child extents; no vertical body clamping
was observed. The six narrow geometry cases reach and fail the
whole-body fit assertion independently of the copied horizontal
assertions. Later clearance assertions in these six are not reached.
No new narrow cue hittability, semantic action, tap or swipe acceptance
is claimed.

Exact actual paragraph copies, per-character non-whitespace selection
rectangles, diagram and gaps are recorded; these are measurements,
not native painted-text or global clipping acceptance. Current
unflexed footer text still extends beyond its Row. Five non-question
routes are saved reference controls, not permission to change them
or universal cue clearance acceptance. In particular, narrow Family
Compatibility and Open Conversation record lower clearances
-2.64px/-1.52px without fit expectations; these residuals remain
outside the current question-only repair scope under OA-ZYRA-305.

At mount500ms the down cue retains opacity0.996148 and Y shift0.038516px;
after another60ms these are1/0, giving the settled boundaries above.
The unchanged560ms cue tween also runs with disableAnimations=true.
This records a further existing reduced-motion limitation under
OA-ZYRA-305, not acceptance that cue motion is disabled or authority
to alter its widget in this packet.

The body MediaQuery padding reads0 because SafeArea has consumed the
controlled24px insets; the measured arrival page already excludes
those insets, header and ribbon. The actual padded arrival Stack is
326px wide on the narrow surface,736px on wide. No misleading raw
physical-view800×600 value is used as the layout surface.

### Source, documentation and limits

Current SOURCE remains355277 bytes / SHA256
10b679778c9bcd7c1b8a1fe51b4194d3c31d4cfcf0798b78808623b46de77266,
byte-equal to the new TRUE_PRE source backup. Existing arrival4410-byte
and footer273-byte spans, earlier fixes, all old frozen evidence,
Guardian handover and five outside-source tree aggregates remain
unchanged. This section preserves the entire prior96084-byte document
prefix, SHA256
d835fc69f7c2af3661fbfcf6addd517398ae35acba49bf7efcc39f4db2d64525.

The initial newly authored PRE source/document snapshots accidentally
contained one additional LF. They are preserved as invalid authoring
snapshots, not true audit anchors. Separate collision-safe TRUE_PRE
files were created and byte-compared with live files before tests or
any source edit. No existing file was restored or rewritten.

For precise source citations, current immutable PRE _history is at
3848–3849 and PageController initialPage at3856–3858. Older baseline
receipt line references were offset although the logic was correct;
those sealed receipts are not edited.

New evidence under NEXT_OA305_ARRIVAL_RESERVATION_* includes scope,
true backups, frozen fixture, complete FIRST log638578 bytes
(SHA256 2b30bb3ae5c9f14d7aaf201acbe3be9affa7aba44369be73e2887fd4ab2f58eb)
and events704327 bytes
(SHA256 2c16137f5a03fe4a1419e7cb05b65b777801d864b20d3e877dacffdcd721bec8),
baseline/Main verification, independent review and final handover.
The large live output was display-truncated; complete files and all
counts/records were retained and parsed. No setup/compile failure,
framework-error suppression or teardown/transport fallback occurred.

Supabase guidance keeps the copied synthetic actor/.invalid mocked
transport separate from production claims; unexpected requests remain
denied and every44 record hasunexpectedHTTP0. No live DB/provider,
member experiment, readiness override or real commercial proof is used.

P2 holds SOURCE; runtime is released. POST, source reversal, analyzer,
old12/21/77 standalone reruns and native delivery are NOT RUN.
Earlier14/4, diagnostic0/4 and eighth18/3 failures remain dated truth.
No shared register/index/dashboard/schedule edit, new OA, closure,
score uplift, Founder acceptance, production/security/account/public/
spend/destructive/Git/PRIVATE action occurred.

### Recommended Founder choice

Allow only the three question-arrival content bodies to scroll within
the area between fixed unchanged cues when enlarged content cannot
fit, retaining fonts, copy, gaps and ordinary wide/non-question layouts.
This is outside the current packet and is not implemented. The exact
choice returns to the Founder through the coordinator; OA-ZYRA-305
remains open. No partial layout patch or success claim substitutes
for that decision.

## 22. OA-ZYRA-305 down-arrow reduced-motion trial — reverted after live-setting failure

### Authority and exact scope

The tenth local away packet used the already verified direct Founder
execution and bidirectional internal-message authority. It allowed only
the flag read and duration choice in `_JourneyDownCue.build`; the
question-arrival scrolling/layout choice and Family/Conversation placement
remained held. This is internal implementation evidence, not Founder
acceptance, native delivery, live-provider acceptance or OA closure.

The immutable method at lines4521–4569 was1507 bytes,
`3b70a34194ac8be5c94dfb9e954f4d2d1c7d4f0ee38c93c47a2bae3418cb476c`.
The trial read `MediaQuery.maybeOf(context)?.disableAnimations ?? false`
and selected zero duration when true, retaining560ms otherwise. The
Tween0→1, easeOutCubic, opacity/Y mapping, complete child/semantics/callback
tree, normal timing, all earlier hunks and every outside source byte
were unchanged.

### Frozen public-path checks and actual trial result

Core authored the separately named
`NEXT_OA305_DOWN_CUE_REDUCED_MOTION_PUBLIC_test.dart` before Main runtime:
20566 bytes,
`4ada0c5e1a8e4f18aa2df54c6a34ecc90865334c6b41488f17f7376ec2094c0c`.
Main and the independent reviewer read it completely. It has seven named
motion/control identities on the ordinary public Salam Journey route,
not seven new app flows or a private widget export.

One FIRST PRE run returned3PASS/4FAIL; the same frozen FIRST POST returned
6PASS/1FAIL. Each exited1, with no compiler/setup/teardown failure.
These are fourteen executions of the same seven identities. Twenty PRE
cue samples and twenty-three POST samples were saved, plus two actual
public arrow-action records per run. Samples inspect the public cue's
actual ancestor Opacity/Transform/Tween configuration at the first
available rendered frame after bounded zero-time pumps, early frames
and560ms; they do not mutate tween values. This is framework/widget
evidence, not native first-painted-frame or assistive-technology proof.

The candidate passed first-entry reduced flag checks: opacity1/Y0 at
0/16/140/560ms, full finite bounds and unchanged label/button/callback
properties. Normal0/140/280/420/559/560ms samples were exactly equal to
PRE, including the ease curve, translation and absolute bounds. Both
settled preference directions passed; the two actual arrow taps still
moved the public pager0→1 with no send/reveal/advance action RPC.

The stricter reachable mid-flight false→true check, DC07, FAILED. At140ms
the configured duration became0, but opacity remained
0.5991595584154129 and Y4.008404415845871. At156ms it still advanced to
opacity0.6464062470197678/Y3.535937529802322, settling only at560ms.
The unchanged framework updates controller duration but does not
restart an already active unchanged-target simulation. No immediate
motion cancellation or comprehensive reduced-motion repair is claimed.
The expectation and raw failure were not weakened or relabelled.

### Fresh exact reversal and final source state

The temporary source was355418 bytes,
`ebd39fe3cc6131e066ec41899eee9390d3892daed6a3a44841951129a0e5f881`,
with a1648-byte method
`229183b54a77aa75bc4f5de0c84209cd0d8a821af6d97a2791df4f8fec8cac72`.
The method starts at byte164757. All353770 outside bytes retained hash
`416d468acaf91e17f22d06fabe868f6c0fd8786d5bd6c79b5e24a9b81c312afb`.

Following the packet's failed-criterion stop rule, Main compared the
complete candidate and frozen evidence, then reverted ONLY its new
141-byte delta. Live source is again355277 bytes,
`10b679778c9bcd7c1b8a1fe51b4194d3c31d4cfcf0798b78808623b46de77266`,
exactly equal to TRUE_PRE. Reconstructing PRE from the retained
immutable POST source by replacing only the new method also yields
that identical full file. No blind full-file restoration occurred.
Candidate cold/settled successes are historical trial observations,
not a current installed fix.

### Serial retention and analyzer results on the reverted source

All following commands ran once and serially after focus runtime release.

| Retained invocation | Passed | Failed | Exit |
|---|---:|---:|---:|
| Previous footer21 |18|3|1|
| Previous arrival43 |34|9|1|
| Original targeted Wali12 |12|0|0|
| Existing caller33 |33|0|0|
| Filtered surface/lifetime11 |11|0|0|
| Existing source tests33 |33|0|0|

The last three retain77PASS, and original12 retain12PASS.
These153 executions give141PASS/12FAIL/0skip, not153 new coverage cases.
Old21 is embedded in43; the three footer failures are repeated within
the nine arrival failures, not twelve distinct product defects.
All44 raw arrival geometry records exactly equal the earlier sealed
baseline. Enlarged-text fit deficits and Family/Conversation residuals
remain unresolved; passing geometry controls are not arrow-clearance
acceptance.

Targeted reverted SOURCE analyzer: exit0/no issues. Candidate SOURCE
analyzer was not run because the failed motion criterion required
reversion first. Six external fixture analyzers exited2, with no ERROR
or INFO and eighty warning occurrences: thirteen test-hook placement
warnings in each fixture, plus one unused frozen `focusScroll` helper
in each of footer21/arrival43. Counts are13/14/14/13/13/13 for focus,
footer21, arrival43, Wali12, caller33 and surface11. Warnings remain
unsuppressed; none is a clean analyzerPASS or retroactive earlier result.
Frozen evidence fixtures were not changed to remove warnings.

### Isolation, provenance and qualification

Generated in-memory actors and exact HTTPS `.invalid` transport checked
host/default port, method, path/query/body and decoded actor authority.
All focus samples report HTTP7/unexpected0; arrow actions7→8,
pager0→1/unexpected0/direct product-action RPC0. Existing public
guardian loader only, DEV/preview/telemetryoff, default false readiness
and identity-rollout assertions, test-font stubs and awaited unmount/
account/service cleanup were retained. Some production-named mocked
RPCs could persist state in production; this is not a production
read-only graph, real verification, live database or provider proof.
No exception/timer/teardown suppression was added.

The source backup is byte-exact. Initial document reconstruction from
saved text inserted one extra separator LF at zero-based byte96085:
102893 bytes/`70e820544d092e20cf509556b522683c21497b6017b061bdaf8f2afe8bd3d201`.
That newly authored snapshot remains INVALID and immutable, not an
audit/rollback anchor. Before tests or source edits Main reread the
complete live document in bounded chunks and saved the separately named
`TRUE_PRE_HANDOVER_VERIFIED.md`:102892 bytes/`df2dd4fdc1933411604eeacfb8219e64b0fc9a3353563f796fe1a8ed06749ba7`,
exactly equal to live PRE. This whole prefix is preserved by this section.

The first source-method diagnostic omitted its final LF and printed
1506 bytes; corrected extraction INCLUDING the LF matched the required
1507-byte pin before any runtime/source write. The first retained
reporter projection counted one successful `(setUpAll)` and one
successful `(tearDownAll)` as cases in EXISTING33, producing35 events
and an internal count guard error after runtime exit0. Correctly excluding
those two harness identities yields33 authored PASS; no runtime retry,
raw rewrite or source change followed.

Current official
[disableAnimations documentation](https://api.flutter.dev/flutter/widgets/MediaQueryData/disableAnimations.html)
distinguishes the iOS reduceMotion flag. Installed Flutter3.44.2 SDK
`media_query.dart`318–320 reads accessibilityFeatures.disableAnimations;
no iOS/engine mapping change or native accessibility acceptance is made.
The scoped trial tests the explicit custom MediaQuery flag only.

All five outside source/test/backend/iOS/Android tree inventories remain
exactly equal to the prior packet; Guardian handover and old evidence
seals are unchanged. No dependency/font/style/provider/production/
phone/native/signing/store/public/legal/payment/account/security/spend/
destructive/Git/PRIVATE action, OA closure, score change or Founder
acceptance occurred. Main runtime is released; source is reverted and
released. Main is the sole writer of this additive document section;
ADMIN remains the sole shared OA-register writer.

### Evidence and useful next step

Evidence is separately named `NEXT_OA305_DOWN_CUE_REDUCED_MOTION_*` in
the existing2026-10-06 review directory: MAIN_SCOPE, TRUE_PRE source and
VERIFIED handover, immutable POST_SOURCE, PRE/POST logs and reporters,
PRE_BASELINE_RECEIPT, POST_FAILURE_RECEIPT, RETAINED_ANALYZER_RECEIPT
and the later Main/independent seals. Older records and the invalid
authoring snapshot are preserved.

OA-ZYRA-305 remains OPEN. A useful next routine local repair, subject to
a separately bounded execution packet, is to make the reduced flag map
the cue's visible opacity/translation directly to their terminal values
during a live rebuild while retaining the normal mapping exactly.
This is not implemented here and does not authorise a new controller,
key or broader animation redesign. The separate enlarged-content
inner-scrolling choice still belongs to the Founder; no layout hunk
was applied.

## 23. Private down-cue latch trial: preserved authoring holds, clean focused successor, failed retained gate and exact reversal — 2026-10-06

### Authority and final state

This is an additive as-built record under OPEN OA-ZYRA-305, not closure,
a readiness-score uplift or Founder acceptance. ZYRA FINAL REALEASE
bounded the eleventh class-only local trial, the twelfth public
semantics-selector API copy, and the later owned-handle lifecycle copy
under the verified Founder AWAY/local-execution and bidirectional-chat
authority. Main was the sole fixture, runtime, Source and document
writer. Root coordinates evidence; ADMIN alone owns shared registers.
No AI acceptance substitutes for Founder acceptance.

**Final production Source is reverted/HOLD.** The focused successor
passed12/12, but the retained77 gate passed76 and failed1 with an
unsuppressed app-links test-environment error. That failure was not
absorbed, suppressed, labelled harmless or attributed to the cue
implementation without evidence. No exploratory rerun occurred.
Only the authorised private class hunk was reversed, with a fresh
exact Source readback at18:50:48.217 UTC. Existing enlarged-body,
chapter-footer, Family Conversation and native/release decisions
remain held and unchanged.

### Exact Source boundary and reversibility

The true original Source is355277B /
`10b679778c9bcd7c1b8a1fe51b4194d3c31d4cfcf0798b78808623b46de77266`.
The separately copied lifecycle true PRE is
[NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_CORRECTED_TRUE_PRE_SOURCE.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/RESOURCES/REVIEWS/ZYRA_INDEPENDENT_APP_CHECKS_2026-10-06/NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_CORRECTED_TRUE_PRE_SOURCE.dart>), exact to that
original. At zero-based byte164588, the only owned old class was1678B /
`9b463fff906e10c1611c5086176b51317b0ae792674fa4f015f274c199348bdd`.

The attempted replacement was the same frozen2335B private
`_JourneyDownCue` StatefulWidget plus its private State /
`72813f68cfb60c60d718d5d754bfb3a60ed2504db96befde295be06f52ff8bdd`.
It preserved the public const label/onTap constructor, every original
child and callback-registration shape, normal0→1/easeOutCubic560ms
entrance, and the current reduced flag's duration0 mapping. A private
per-State latch set once in didChangeDependencies on an explicit
MediaQuery disableAnimations=true observation forced visible opacity1
and translationY0 for that State's remaining lifetime. The latch was
not reset on a later false flag; a genuinely disposed/remounted normal
cue retained a new normal entrance.

There were no new keys, timers, controllers, remount sentinels,
public/private-export test seams, direct callback invocations or
side effects. The trial concerned visible pose/no revival only; it
did **not** establish that an active internal implicit-animation ticker
stopped or that native iOS Reduce Motion was accepted.

Both attempted applications produced identical355934B /
`9c648ede7589aa97e3ef391c035c8746a7caa69021c6341ab37fd625732fbf98`.
The immutable first [NEXT_OA305_DOWN_CUE_LATCH_POST_SOURCE.dart](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/RESOURCES/REVIEWS/ZYRA_INDEPENDENT_APP_CHECKS_2026-10-06/NEXT_OA305_DOWN_CUE_LATCH_POST_SOURCE.dart>) remains evidence, not
live Source. The353599B outside-class bytes stayed exactly
`b39ed752ea8bfb1fcf12c5a48bbb888d3e2a4d75bfafd9b8f2408f12c0ec9bab`.
Both fresh guarded hunk reversals reconstructed355277B/10b679…7266
exactly; no whole-file restore or unrelated edit was used.

### Preserved authoring stages and actual runtime outcomes

| Stage | Actual result | Qualification |
|---|---|---|
| Original new public fixture36780B/15662e…450c FIRST12 | 3PASS/9FAIL, exit1 | DL03 exact whole-label finder returned0 before dispatch. The initial receipt incorrectly called all five new failures duration failures; the separate PRE_SEMANTICS_HOLD erratum supersedes only that classification. All raw failures remain. |
| Frozen DL03 selector-corrected copy40477B/8f1c37…6b5f9 | Runtime0 | Main/reviewer static check found unsupported childrenInTraversalOrder getter; no production patch or runtime was taken from that copy. |
| API-only copy40625B/1b0dca…db4f FIRST12 | 3PASS/9FAIL, exit1 | Nine actual560-vs0 duration-oracle failures; authentic mapped-node SemanticsOwner action reached its expected destination. Failed PRE did not prove handle cleanup because normal end invariants were skipped. |
| Same API-only copy FIRST POST12 | 11PASS/1FAIL, exit1 | DL03 left its extra test-owned SemanticsHandle active at end verification. All motion/action assertions completed, but this was not a clean run. First candidate was exactly reverted before the separately bounded successor. |
| Lifecycle-only copy40862B/bab20c…9331 FIRST12 | 3PASS/9FAIL, exit1 | Original motion bug reproduced with all12 names unchanged; nine actual duration expectations. This failed PRE still is not cleanup acceptance. |
| Same lifecycle-only copy FIRST POST12 | 12PASS/0FAIL/0skip, exit0 | Clean local focused run, including end verification. Not sufficient to override wider regressions or approve release. |
| Frozen retained21/43/12/77, serial once on candidate | 140PASS/13FAIL across153 repeated executions |21=18/3known;43=34/9known;12=12/0;77=76/1. One extra unsuppressed plugin error caused mandatory Source reversal and HOLD. |

The original36780B fixture, erroneous initial classification and
separate semantic hold, invalid40477B copy and its static API hold,
40625B PRE/POST logs,11/1 failure receipt and first reversal, and
40862B PRE/POST/retained data remain separately named and immutable.
No test result was upgraded by fixing a later copy.

The public selector resolves the actual node via tester.semantics.find,
not a supposed exclusive exact-label leaf. In measured runs its full
label combines four non-action text lines including exactly one
Scroll to begin component; the actual tree has one matching node
identity, attached owner, button/tap action, one mapped actual cue
control, and no descendant action nodes. Dispatch is through that
actual SemanticsOwner. The measured node's large local rectangle is
**not** cue-exclusive ownership/bounds or native accessibility proof.

The lifecycle successor copied40625B exactly outside the allowed
semantic branch at byte28074: old4276B /
`4809a461cdc6934793f9b23e685a8601e19d15e1bff8d77dfda0b2eb331c7154`
to4513B /
`31769da6121b445c7e749529adc62ef417f9e28b672963f3cd98a6f311316fef`.
It retained the acquisition and pump/dispatch timing, removed only
deferred addTearDown disposal and wrapped the existing body in
try/finally with exactly one disposal of that owned handle. The4176B
body /`d8d88274d410fd46d455dab2ad7651f97ad909d11df9bfe2f50a4e9a60bea1fa`
is exact modulo two-space mechanical indentation. Outside36349B /
`720aa54f8723d760a0d717cc13dfab32e034fe0a935d33f3a3f27270c3946e5b`
and reverse-to-frozen40625B proofs are exact. Original DC01–07,
nonsemantic branch, shared settle/effects/motion assertions, imports,
strict fake HTTP, focus/held-pointer/remount oracles and unsuppressed
framework cleanup all remained intact.

Installed Flutter SDK source was read directly:
widget_tester.dart151–197/1050–1085 and binding.dart1949–1985.
The framework-owned default semantics handle remains. Its managed
lifecycle does not make an extra addTearDown-owned handle timely for
end verification. Current primary
[testWidgets](https://api.flutter.dev/flutter/flutter_test/testWidgets.html)
and [ensureSemantics](https://api.flutter.dev/flutter/flutter_test/WidgetController/ensureSemantics.html)
docs corroborate the API contract; they are not installed-version or
native-device acceptance.

### Focused observations and limits

The lifecycle POST measured46 pose samples,16 Element observations,
four actual focus records, three independent public input scenarios,
one held-pointer record and one fresh-remount record. All six DC02
ordinary timing/translation samples exactly equal PRE. Reduced cold
entry is resting from first sample; mid-flight/rapid true→false
remains visible1/Y0 through700ms; genuinely new normal State enters
at0/Y10 and settles normally after560ms.

Within each required mounted scenario the Tween/semantic/InkWell/
label/gesture/focus Elements remain the same. All four focus records
retain the actual primary FocusNode. Semantics and InkWell each keep
one original registration and the same current callback. The held
pointer does not change page while held; one release reaches page1.
Separately reset semantic-owner and physical-tap scenarios each reach
one expected settled destination, use the same strict eight-request
sequence7→8, issue no direct product action RPC and have unexpected
HTTP0. The supported claim is **callback wiring preserved; no duplicate
observable side effects in tested scenarios**. Literal private
callback invocation multiplicity remains UNMEASURED.

Authoring evidence:
[NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_CORRECTED_PRE_BASELINE_RECEIPT.json](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/RESOURCES/REVIEWS/ZYRA_INDEPENDENT_APP_CHECKS_2026-10-06/NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_CORRECTED_PRE_BASELINE_RECEIPT.json>) —60934B /
`ab7a2658029db793fda20d95c9ab6f3f4bbe1aceff71aca2ff65d0c928c3f8aa`;
[NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_CORRECTED_POST_RECEIPT.json](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/RESOURCES/REVIEWS/ZYRA_INDEPENDENT_APP_CHECKS_2026-10-06/NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_CORRECTED_POST_RECEIPT.json>) —58593B /
`0071b5dcd5b51af73135bf62ceda54d6f2ec7214313cf2251d8133d75d1469e4`.
The preserved earlier11/1 plus reversal receipt is63602B /
`7c0958f8f851c2416a0fa87fa7215b031051694c26a6fb9bf3619932905ce451`.

### Retained gate, exact44-record comparison and analysis

| Retained suite | PASS/FAIL/skip | Exit | Raw reporter |
|---|---|---|---|
| FOOTER21 | 18/3/0 | 1 | [NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_RETAINED_FOOTER21.events.json](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/RESOURCES/REVIEWS/ZYRA_INDEPENDENT_APP_CHECKS_2026-10-06/NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_RETAINED_FOOTER21.events.json>) — 44196B / `b722ca1db22e1e8cf73b46fd298ab2c52d566a58dafb7d1c1bc0ab7b982c4a0e` |
| ARRIVAL43 | 34/9/0 | 1 | [NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_RETAINED_ARRIVAL43.events.json](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/RESOURCES/REVIEWS/ZYRA_INDEPENDENT_APP_CHECKS_2026-10-06/NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_RETAINED_ARRIVAL43.events.json>) — 704069B / `525d129a93f0d6539883dc19eed6283cc07fc66aae7b6e6856bd11338ab09d03` |
| WALI12 | 12/0/0 | 0 | [NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_RETAINED_WALI12.events.json](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/RESOURCES/REVIEWS/ZYRA_INDEPENDENT_APP_CHECKS_2026-10-06/NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_RETAINED_WALI12.events.json>) — 21488B / `d99ec1b45746c559b5de683e8b741da835a9179d59a5ac6ddf73bd9f9ef61ad9` |
| CALLER33 | 33/0/0 | 0 | [NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_RETAINED_CALLER33.events.json](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/RESOURCES/REVIEWS/ZYRA_INDEPENDENT_APP_CHECKS_2026-10-06/NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_RETAINED_CALLER33.events.json>) — 19625B / `c0f496e57f0fa318dcf5b66432184a3f38a53f8baa36d22d63cd5de8bec24682` |
| SURFACE11 | 11/0/0 | 0 | [NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_RETAINED_SURFACE11.events.json](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/RESOURCES/REVIEWS/ZYRA_INDEPENDENT_APP_CHECKS_2026-10-06/NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_RETAINED_SURFACE11.events.json>) — 7419B / `a0237658179b44fb1fc8dbf752877e2fd397ca59173023409e371977df34409b` |
| EXISTING33 | 32/1/0 | 1 | [NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_RETAINED_EXISTING33.events.json](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/RESOURCES/REVIEWS/ZYRA_INDEPENDENT_APP_CHECKS_2026-10-06/NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_RETAINED_EXISTING33.events.json>) — 21381B / `6fff39952c7a7f0a1ae1c0b525be78bc648b4592ec33005f7794fe3d74fef48d` |

The extra failure is **revocation and refreshed gate reject the earlier
late result** in the existing Guardian-preview handoff test:
MissingPluginException, no implementation for listen on
com.llfbandit.app_links/events. The complete log/reporter is preserved
without catch, filtering or changed assertions. Test-owned plugin
isolation/lifetime may be a useful next diagnosis, but no causation,
harmlessness or app/native fix was established here. The original
33PASS baseline is not overwritten.153 executions overlap21/43 and
reuse prior evidence; they are not153 unique new cases.

P4 was frozen before patching and compared every raw identity, key,
shape and leaf exactly. Candidate ARRIVAL43 has44 unique records:
**38 entire records are exact; six reduced mount500ms records differ
only in the18 specified leaves**. For each phase_1/2/3 at800×1000 and
390×844: opacity0.996148420451209→1, translation
0.038515795487910065→0, and downRect[1] equals PRE.top−PRE.translation
(901.0385157954879→901 or694.0385157954879→694). All remaining geometry,
paragraph boxes, resting footer/body dimensions and clearance are
exact. There were no rounding tolerances, whole-rectangle exclusions,
dropped records, layout/oracle changes or expanded whitelists.
[NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_GEOMETRY_COMPARISON.json](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/RESOURCES/REVIEWS/ZYRA_INDEPENDENT_APP_CHECKS_2026-10-06/NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_GEOMETRY_COMPARISON.json>) —5947B /
`17e243cd54a10efe3582c7e32606361982e1d7a63cf581a345f1c8fb4b52fbf1`
contains the actual18-leaf list. Independent read-only comparison
corroborated it. Geometry success does not override the failed77 gate.

Scoped production-source analyzer ran **after reversal only**:
exit0, zero errors/warnings/info. Failed candidate analysis was not
run after mandatory STOP. Copied external fixtures analyzer exit2:
zero errors,80 warnings (78 INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER,
two UNUSED_ELEMENT). They remain warnings, not a clean analyzer result;
no fixture production-seam cleanup was added.
[NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_ANALYSIS_RECEIPT.json](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/RESOURCES/REVIEWS/ZYRA_INDEPENDENT_APP_CHECKS_2026-10-06/NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_ANALYSIS_RECEIPT.json>) —45640B /
`09595e78aeb9aeaa15eeed42bbdeb07283cfbf919d93e08ba24c80442e3c2268`.
[NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_RETAINED_FAILURE_AND_REVERSAL_RECEIPT.json](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/RESOURCES/REVIEWS/ZYRA_INDEPENDENT_APP_CHECKS_2026-10-06/NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_RETAINED_FAILURE_AND_REVERSAL_RECEIPT.json>) —114783B /
`7807b0c47517217e3a2c56cc6c73c8eccba63dab05ae2c33907b94befd5ebfb5`
holds commands, named cases, all six first runs, actual failure,
strict reversal and qualifications.

### Documentation, diagnostics and release boundary

Fresh full no-follow handover read before this append:
112084B /`2f1f168dda6fd6fe234cb09369bedac32b969301c2e2954de0566c015eb08e49`.
[NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_TRUE_PRE_HANDOVER.md](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/RESOURCES/REVIEWS/ZYRA_INDEPENDENT_APP_CHECKS_2026-10-06/NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_TRUE_PRE_HANDOVER.md>) is a separately
created exact112084B backup. All existing112084 prefix bytes are
preserved; this is the only additive §23. Prefix/post hashes, final
pins and Main/independent writer releases belong to the final seals.

Read-only metadata diagnostics are not app-test reruns. Main preserved
the initial incorrect original-PRE classification plus its semantic
erratum, unsupported static selector API hold, a first lifecycle proof
that used the wrong helper boundary then stopped, and a prepatch
metadata serialization that referenced an undeclared pins variable
and stopped before Source mutation. Main's first retained identity
comparison read old skip as skipped and stopped; exact schema-aware
case/boolean comparison then passed without modifying raw data,
fixtures, runtime or Source. These did not weaken any oracle. The
independent reviewer also reports stopped metadata projections
(wrong held-record prefix, semantic-branch boundary assumption, stray
brace, truncated oversized guard display and leaf-list order
comparison), corrected only by bounded read-only projection; its
actual tests/Source/document writes remain0.

Fresh five outside Source/lib, test, supabase, iOS and Android
inventories at18:54:38.513 UTC are exactly equal to prior controlled
inventories, with the same owned-file/build exclusions. The private
Source file is separately exact TRUE_PRE after reversal. Guardian
handover, dependencies and older seals remain unchanged.
[NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_FINAL_OUTSIDE_TREES.json](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/RESOURCES/REVIEWS/ZYRA_INDEPENDENT_APP_CHECKS_2026-10-06/NEXT_OA305_DOWN_CUE_LATCH_LIFECYCLE_FINAL_OUTSIDE_TREES.json>) records the inventories.

Main runtime/fixture/Source writers are released; document writer
releases after the additive-prefix readback. The later independent
seal and Root relay complete handover, not product acceptance.
No dependency/font/colour/ordinary-scroll/layout/membership/provider/
account/security/payment/legal/public/production/live-database/
native/signing/store/phone/spend/destructive/Git/PRIVATE action,
shared OA-register mutation, score change, OA closure or Founder
acceptance occurred.

A separately bounded **read-only diagnostic** of the existing33
test-owned app-links channel/isolation/lifetime is the useful next
proposal. It must preserve this first failure and distinguish harness
availability from production behaviour. No suppressed exception,
live/native plugin change, hidden test seam, rewritten oracle or
candidate reapplication is authorised by this section. Larger
inner-scroll, native accessibility and release-artifact gates still
need their own Founder decisions/evidence.

## 24. Source-context visible-pose latch live and sealed — 6 October 2026

This is the finite append-only filing of the later successful
NEXT_OA305_LATCH_SOURCE_CONTEXT_ stage under OPEN OA-ZYRA-305.
It supersedes only section23's dated final-current-source reversal/HOLD:
the later stage reapplied the exact proven private latch, passed its
separately frozen source-context regression contract and left it live.
Section23's failed earlier gate, reversals, raw logs and all earlier
sections remain unchanged. Nothing here is Founder acceptance, OA
closure, a readiness-score uplift or phone/release acceptance.

The latest local Journey Source is355934B /
9c648ede7589aa97e3ef391c035c8746a7caa69021c6341ab37fd625732fbf98.
The as-built delta below is preserved verbatim as its point-in-time
prepared record; its statement that the CURRENT handover was not then
edited is historical. This section is the subsequent filing.

Sealed RESULT is194533B /
bcc0307d0641c161feb46c990d70d58cce05cfad886f70f143c2f060f32e36a0.
Its before-seal writer flags are not a final release observation.
FINAL_SEAL is1905B /
9067e529dcda568974ae86b3e83e9c19a8aec249905f53ddf434339c84543a36.
The actual final readback/release was21:39:15.415UTC, tool65825c/exit0,
after full guardabbf72/exit0 at21:39:15.345UTC: Source exact,80 old
protected paths unchanged,16 execution artifacts exact, all four owned
process groups absent and independent readers released. Source/evidence
writers released then; this new document writer releases separately
after its own whole-prefix readback. These are distinct dated facts.

The prepared6949B delta is SHA256
d927add67246af6ff4af9a836367531c5cdead460eedf4e86f07b35eb2cb8411,
under the existing6October review directory. Verbatim prepared text:

```text
# OA-ZYRA-305 — Source-context arrow latch as-built delta (PREPARED)

Dated 2026-10-06T21:37:08.385Z. This is a point-in-time implementation delta for later finite filing, not a second CURRENT_VERSION, OA closure, general release GO or Founder acceptance.

## Authority and scope

Original direct Founder away/bidirectional execution authority in ZYRA FINAL REALEASE: turn 01a110fb-bd68-7980-a294-64d45848a5cd; actual human message IDs 01a110fb-c6a2-71e0-aa6f-6ab681e81be3 and 01a1110e-070c-7d60-9fbb-b167ca5cc41f were independently verified earlier in this logical turn. Latest direct human request in APP BUILD again asks to update that chat and do further app-building work. Release Root routed this exact class-only continuation after sealed preparation. AI review/routing is not approval. Latest independently verified Founder availability is AWAY; no phone/native delivery.

An optional later historical read_thread lookup did not expose user items. The unsupported turnLimit20/non-JSON response, unsuccessful supported pagination and optional lookup HOLD are retained as tooling errata; no fresh historical readback is claimed. They did not change the already verified original authority, scoped task, app code or test oracles.

## Live implementation

Only /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/screens/journey/journey_flow_screen.dart changed. Whole PRE355277B/10b679778c9bcd7c1b8a1fe51b4194d3c31d4cfcf0798b78808623b46de77266; whole POST355934B/9c648ede7589aa97e3ef391c035c8746a7caa69021c6341ab37fd625732fbf98.
Actual whole PRE backup: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/RESOURCES/REVIEWS/ZYRA_INDEPENDENT_APP_CHECKS_2026-10-06/NEXT_OA305_LATCH_SOURCE_CONTEXT_TRUE_PRE_SOURCE.dart; captured and verified before editing.
Exact UTF-8 byte offset164588: _JourneyDownCue PRE1678B -> POST2335B; outside353599B SHA b39ed752ea8bfb1fcf12c5a48bbb888d3e2a4d75bfafd9b8f2408f12c0ec9bab stays unchanged. Whole inverse reconstruction equals the actual backup.

The cue now has per-mounted-State reduced-motion visible-pose latching. didChangeDependencies observes MediaQuery.disableAnimations. Once true on that mounted State, visible opacity stays1 and Y translation0 even when that flag later becomes false. Normal560ms easeOutCubic tween is unchanged; a new remount starts a fresh latch. Child semantics, InkWell, labels, callbacks, focus and held-pointer structure remain as tested. No user-facing wording, font, colour, page layout, other widget, key, timer, controller, API, session or entitlement changed.

This proves final VISIBLE pose only. It does not prove that the underlying animation ticker ceases, native iOS Reduce Motion, native accessibility or an installed release artifact.

## Measured FIRST checks

One FIRST cached /opt/homebrew/bin/flutter analyze --no-pub in SOURCE: child66281, exit0; no errors/warnings/info. Complete raw log and source-class proof are filed under this prefix. No static retry or policy/config/dependency change.

Exactly three sequential FIRST candidate-state test invocations, with unchanged fixtures/oracles/timing, cached Flutter, expanded + JSON reporters and owned soft597000/hard600000ms process bounds:
- POST_FIRST12: child66415, exit0. 12PASS/0FAIL/0SKIP;108rows/77prints/46 DOWN_CUE_SAMPLE prints/135 typed identity observations; complete normalized rows and full expanded body exactly equal the frozen POST projection. NodeId17 exact.
- POST_FIRST43: child66520, exit1 EXPECTED.34PASS/9KNOWN layoutFAIL/0SKIP;195rows/93prints/9errors; complete rows and body exactly equal the frozen signature. All27 ordered diagnostics,9x68px RIGHT/SOURCE4384:13 and SDK frames remain exact. All44 geometry match array8c36ffede9d30d92b3e72548e0457b616dd07f6e47e52a06ab1b8ee83c651a93;38 wholly unchanged/six records/exactly18 approved numeric leaves. No tolerance or Source-frame shift.
- POST_FIRST33: child66610, exit0.33ordinaryPASS/5hiddenSuccess/0FAIL/0SKIP/errors;91rawrows/50-node graph. Whole semantic graph611527fac0c72f441275dd57919f426bf844eb06acdd2ef31102bdfd462baace. Mandatory final frozen expanded helper used, not older inMemoryCheck. All actual37 reporter lines, complete wrappers, global interleaving and partial count associations preserved. Printed labels may latch; no invented starts, exact timestamp-causality or printed-label/completed-test equality.

88 ordinary test executions total:79PASS/9knownFAIL. Cases overlap prior inventories; not88 unique coverage. The known failures remain unresolved under OA-ZYRA-305 and were not repaired in this packet. No general acceptance/pass claim.

## Evidence and errata

Immutable earlier FIRST failures, reversals, P1 hold, corrected preparation and all historical pins remain. New actual Source/static/runtime raw artifacts and full mapping/comparison results are under /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/RESOURCES/REVIEWS/ZYRA_INDEPENDENT_APP_CHECKS_2026-10-06/NEXT_OA305_LATCH_SOURCE_CONTEXT_. SourceProof, prospective execution/capture plans and separate wrapper audits document the transport.

The ancillary FIRST12 receipt counter incorrectly searched nonexistent DOWN_CUE_LATCH_SAMPLE and recorded0; the separate COUNTER_ERRATUM preserves that error and proves actual DOWN_CUE_SAMPLE count46. Full frozen rows/body already matched; no oracle edit or runtime retry.

An unexecuted factory rehydration omitted its B lexical binding before POST43 runner creation. Restoring the original B/protectedPins binding left the exact runner/test flags unchanged and launched one FIRST43, not a retry.
FIRST33 read-only comparison succeeded but its huge UI export was truncated. Exact immutable comparison/result export was transferred in bounded slices; no app execution, oracle broadening or discarded raw rows. Original truncation and all transfer pins remain.

Routine generated child-output logs are captured verbatim collision-safely (O_EXCL/O_NOFOLLOW), not hand-edited or truncated. Same launcher, owned timeout and process outcome wrapper; test file-reporter JSON is complete. Full body comparisons separate only the exact first owner/last end wrapper, independently audited. All other characters remain.

## Boundaries and next step

No migration, database/provider/security/account/payment/commerce/store/public/SDK/dependency/pubspec/lock/config change. No build/install/launch/device acceptance. No Git or PRIVATE access. Current governed handover and shared OA registers were not edited. Source remains the exact candidate at final postcheck; all owned process groups are absent.

Independent evidence checks remain separate from Main verification and Founder acceptance. Release Root owns ledger and next routing; ADMIN alone owns shared register reconciliation. Next useful action: finite filing of this delta and separately scoped investigation/repair of the9 retained layout failures; no automatic native/live/provider gate expansion.
```

## 25. Status-row packet stopped before Source/runtime — 6 October 2026

### Exact retained evidence and corrected gate

The subsequent NEXT_OA305_BRIEFING_STATUS_WRAP_ packet proposed only
loose Flexible wrapping/centering of the unchanged lock/count Text in
_JourneyQuestionChapterBriefing. No such Source hunk was applied.
No new PRE, POST, analyzer or app/widget runtime invocation occurred.
The current proven arrow latch and every other Source byte remain exact.

Fresh full applicable product/build/summary/current-handover checks
and the actual saved704663B POST_FIRST43.events.json /
ada1c7ad6105a1b8627ae93dbe09dc8970844489426640c7ba77737c3ef411e2
show the nine failures have more than one cause:

- Six arrival reservation phase_1/2/3 narrow ordinary/reduced cases
  independently reach immutable fixture line924 and fail whole-body
  fit: required521/493/497 versus383.25/362.25/362.25 allowed.
- Three canonical phase_1/2/3 narrow-enlarged cases reach line665 and
  fail text-right containment:426.2998352050781 versus358.25 allowed.
- All nine also report the existing68px right overflow at
  Source4384:13. That common framework report does not make it their
  only reached assertion failure.

Sections20/21 retain the actual existing body heights501/473/477
against383/362/362 available pixels and the separate20px intrinsic
footer-wrapping estimate. Three saved canonical lower clearances are
already negative, approximately-82.281/-78.361/-80.601px; after the
horizontal assertion passes, their later unchanged line683 clearance
expectation would still need acceptance. That latter future failure is
an inference from saved geometry/source, not a new measured POST.

Root retracted the proposed43PASS/0FAIL target and its common-Row-only
cause classification in its substantive correction. This is an
explicit correction, not a relaxed oracle or retroactive PASS.
Status-row-only wrapping cannot resolve the already measured vertical
body/cue deficit and can increase body height. P2–P4 remain HELD.
No partial source patch, hidden-text/clipping/font reduction, changed
frame/tolerance/viewport, fixture or expectation rewrite, extra mock,
retry or inverse of the successful latch was used.

The historical PRE-JOURNEY RITUAL Summary has no Status header or
References.md and retains open product discussions. The current
bounded local defect/record filing follows verified direct Founder
authority and settled current handover facts; it does not finalize that
Summary or decide any open Guardian/question/lifecycle/commercial policy.
No new action is raised for this previously recorded governance lag
because this stage changes neither product text nor a specification;
the existing OA-ZYRA-305 remains the owner of the held layout findings.

### True backups, scope and decision-ready next step

At21:54:25.005UTC, fresh no-follow checks prove the new true Source
backup355934B/9c648…bf98 and true CURRENT-document backup130277B /
cae00ee27ea4b51e9c0aeec12a25f8e871b35d1e6496c3f868ebe33bb9af64c3
byte-identical to live PRE, regular/single-link/distinct same-device
files.99 old protected whole-file pins were unchanged. All130277 old
document bytes remain the exact prefix of this additive24/25 filing.
No second CURRENT_VERSION, shared register/index/policy/price change or
new product authority was created; ADMIN alone owns register filing.
The filenames are NEXT_OA305_BRIEFING_STATUS_WRAP_TRUE_PRE_SOURCE.dart
and TRUE_PRE_HANDOVER.md in the existing review directory. Its MAIN_SCOPE,
saved-failure classifier, document proof and final seal preserve the
finite stage and metadata/UI-transport qualifications.

The existing decision-ready proposal returns to the Founder through
ZYRA FINAL REALEASE: allow only phase1/2/3 question-arrival bodies to
scroll inside the space between fixed unchanged upper/lower cues when
enlarged content cannot fit. Preserve fonts, copy, gaps, normal fitting
wide/non-question layouts and the proven visible-pose latch. Before a
separately authorized implementation, freeze sizing/reservation, nested
vertical-pager edge behavior, tap/swipe/focus/semantic action contracts
and full-text/cue-containment oracles. Do not substitute another policy
or silently waive the current fit assertion. No AI has chosen or built
that broader layout here.

Known narrow Family/Conversation lower-clearance residuals and native
fonts/accessibility/poor-network/provider/database-photo restore,
security/admission/commerce/payment/release gates remain separate and
OPEN. Founder availability remains AWAY. No phone/native build,
install, launch, SDK/dependency/config, live Supabase/provider/backend,
public/store/payment/security/account, Git/PRIVATE, spend/destructive
action, OA closure, readiness uplift or Founder acceptance occurred.
Source reservation is released unchanged; document/evidence release
belongs to the final whole-prefix readback and durable stage seal.

## 26. Fresh public account-lifetime checks and two bounded repairs — 6 October 2026

This is a finite local execution/as-built filing under OA-ZYRA-305, not
release GO, OA closure, readiness uplift or Founder acceptance. The latest
direct APP BUILD instruction requests coordination with ZYRA FINAL REALEASE
and further app work. Renewed human authority in that chat was independently
verified: turn01a1135c-2694-7ae2-9a4e-f531d8069029, exact user text
“SO WRITE TO EACH CHAT RUNNIGN AGAIN ANYTHING THEY CAN DO WITHOUT ME”,
recorded22:36:08.883UTC. The actual local human record ID is
msg_01a1135c-272b-7160-91be-e99b48167e86; the supplied relay ID had a
different suffix. That attribution limitation is retained, not silently
equated. The Root return packet records Founder BACK, superseding earlier
AWAY availability; neither is blanket production/provider/store authority.

Main was the sole Source/document writer; independent helpers were read-only.
Only journey_flow_screen.dart changed, in Compatibility initState's auth
listener and Phase _submitAll. True PRE was355934B /
9c648ede7589aa97e3ef391c035c8746a7caa69021c6341ab37fd625732fbf98;
POST is357006B /
f641a9a7bbaa2fa8909535bb2d019cc1e1ca5888fbab82bbcd85e46e801049cd.
The fresh physical true-PRE Source and143922B/ad965…d57f CURRENT-document
backups were byte-identical before the edit. Whole-method outside354476B /
862c7f47e28a85673a2886cd8f888fa6dcd904176343ec4599f561b6db10f7c5
is unchanged; whole inverse equals actual PRE. The existing arrow latch,
every layout/pager/copy/font/colour byte and all other methods are preserved.

Phase submission now captures its starting actor and AccountState generation.
It checks that lifetime and mounted State before each draft read/dispatch,
after each awaited write and before feedback/reload. A→B and A→B→A while the
first insert is pending cannot dispatch the seven remaining old-lifetime
drafts or publish/reload after its acknowledgement. The first dispatched
write cannot be revoked locally; this is not server rollback or new
idempotency policy. Same-owner submission still writes all eight in order.
This patch does not claim a complete audit of other Phase reads/polling.

Compatibility now handles the actual public auth stream's error channel.
For the same current principal it retires the local read generation/flight
and publishes existing typed transient unavailability. Previously confirmed
data stays display-only behind IgnorePointer; Retry uses the existing read
path. An old initial read cannot restore a late score after the error.
A real principal/generation change still follows the existing account-reset
path. No invented logout, account generation change or silent Reveal/Plus
mutation was added. Existing successful-read, polling and score-recovery
policy remains unchanged. Supabase documents that this stream requires
onError: https://supabase.com/docs/reference/dart/auth-onauthstatechange.

Eight new unique cases were authored, not eight new release gates:
three public Phase owner/ABA controls, valid and malformed public auth-refresh
controls, one auth-error/late-initial-read control, and two public Guardian
decline/cancel lost-ACK/explicit-retry controls. Strict generated .invalid
HTTP, ordinary authorization and the real JourneyFlowScreen/public services
were used. No private widget/state injection, app bootstrap/readiness bypass,
live provider or real member data. Guardian cases use a synthetic committed
ledger; they prove client no-auto-retry/revision behavior, not real database
commit/rollback or native rendered Guardian caller behavior.

Retained runtime history:
- Initial fixture failed compilation before any case ran: inferred nullable
  async return mismatch. The initial file is preserved; V2 uses an explicit
  Object? generic. This is a harness error, not an app finding.
- PRE V2:2PASS/4FAIL, exit1 (actual raw toolb1fb4e). Both Phase negative
  cases dispatched8 instead of1; malformed auth refresh escaped the stream
  as FormatException and neither unavailable banner appeared.
- POST V2:6PASS/2FAIL, exit1, tool7a32f8. These two later failures were after
  explicit Retry: the unchanged2600ms score animation had not settled.
  This count is Main-attributed to actual tool output; no full raw log was
  reconstructed. V3 adds exactly two normal2600ms pump/flush waits, retaining
  all assertions/mocks and the existing animation, not changing Source.
- POST V3:8PASS/0FAIL, exit0, final tool2e4a36. The saved verbatim final
  output chunk is deliberately named OUTPUT_TAIL; initial loading remains
  transcript evidence. Analyzer --no-pub:exit0/no issues, final toold88384.
  Six PRE + eight POST V2 + eight POST V3 are22 executions of eight unique
  cases, not22 new cases or a full app/native acceptance run.

Independent read-only source/outside/inverse, V2→V3 exact timing delta,
PRE raw, final V3 tail and analyzer-tail checks finished22:58:39.393UTC,
tool1dcde2/exit0. They agree with the bounded repair and harness distinction;
they are internal verification, not approval. Cached Flutter only, no
dependency refresh or historical large-suite rerun.

The SDK/privacy investigation remains open under OA-ZYRA-305 and the native
artifact gate OA-ZYRA-286. The locked foundation2.5.6/cache/archive/local-app
manifest uses only UserDefaults reason1C8F.1, while the project-owned prefs
path uses the default domain rather than an AppGroup. An official2.5.7 tagged
manifest is the same598B /056428…80b1a and sole reason, so a blind2.5.7 upgrade
is not a demonstrated remedy:
https://raw.githubusercontent.com/flutter/packages/shared_preferences_foundation-v2.5.7/packages/shared_preferences/shared_preferences_foundation/darwin/shared_preferences_foundation/Sources/shared_preferences_foundation/Resources/PrivacyInfo.xcprivacy.
Nineteen whole SDK/config/archive/prior-evidence pins matched at22:59:36.574UTC,
toola8883d/exit0. No vendor/cache/binary/AppGroup/reason substitution,
dependency/config/signing/archive mutation or fresh native acceptance.
SDK ownership/justification and exact remedy/artifact verification need a
separate bounded packet; app-level declarations are not claimed to fix it.

All nine enlarged-text findings remain OPEN and HELD: six body-fit and three
text-containment cases. No scroll/wrap/layout/font/copy/pager decision was
implemented or oracle relaxed. Existing critical production/restore,
identity/photo moderation, paid receipt lifecycle, ordinary native login/
recovery/accessibility/network, legal/public/release acceptance gates remain
separate and unproved by these mocks. Guardian retry evidence belongs to
OA-ZYRA-289 with the wider audit linked to OA-ZYRA-305; ADMIN alone files shared
registers, and Root owns release ledger/scoring/dashboard.

DR-ZYRA-257 home delivery was checked against the current One-App runbook.
The paired iPhone was connected but passcodeRequired=true in the actual
lockState read, tool0a85be/exit0. Delivery stopped at that gate: no build,
install or launch was attempted. A new unlocked check and unchanged approved
identity/signature/version routine are required before delivery. No Git,
PRIVATE, live database/provider/payment/store/account/public/security/spend,
destructive action, schedule change or worker-chat notification occurred.

Evidence is under the existing6October review directory, prefix
NEXT_OA305_FRESH_LIFETIME_2026_10_06_. TRUE_PRE backups, fixture versions,
PRE_V2.log, POST_V3_OUTPUT_TAIL.log, ANALYZE_OUTPUT_TAIL.log, SOURCE_PROOF.json,
SDK_PINS.json, RESULT.json and FINAL_SEAL.json retain their distinct roles.
This additive section preserves all143922 old document bytes. Final
document/evidence readback and writer release are recorded by FINAL_SEAL;
this paragraph does not pre-assert that later verification.

## 27. Family answer submission lifetime repair measured 7 October 2026

OA-ZYRA-305 owns this bounded local repair. The Founder directly asked APP BUILD
to update ZYRA FINAL REALEASE and do further applicable work. The 7 October
human restart instruction in that chat was independently read: turn
01a115fa-d7cb-70c0-817e-cddf4563af9a, message
01a115fa-d868-7000-8887-7438092859c9. Routine reversible local work within
settled ownership semantics is authorised; production and release approval
remain separate. Founder availability is AWAY. The coordinator confirmed
there was no additional assignment beyond the existing finite packet.

### Implemented boundary

Only _FamilyStageViewState._submit in journey_flow_screen.dart changed.
Each Family answer service call captures the current SDK user independently.
Previously, a first pending acknowledgement could resume the loop after A→B
and submit the remaining three old-A drafts as B. Returning A→B→A also resumed
an obsolete generation, and normal page disposal did not stop later writes.

Submission now captures its starting actor and account generation, matching
the already-established Phase boundary. It checks mounted/current ownership
before each controller read and dispatch, after each awaited write and before
failure feedback or reload. An already-dispatched first write may settle;
the client does not revoke or roll back that write. Same-owner sequential
submission and the existing failed-write/duplicate/retry semantics remain.
No service contract, API/RPC, schema, provider, membership, lifecycle, layout,
copy, font, colour, arrow or animation policy changed.

True PRE Source357006B/f641a9a7bbaa2fa8909535bb2d019cc1e1ca5888fbab82bbcd85e46e801049cd
became357417B/ef2effd3e0364eb9274c8c77ea3a167440df66d4f122a1a8fb16e7b155b40146.
The method changed989→1400B. All356017 outside-method bytes remain exact,
SHA-25691be8f933d0f45cecfa9a9638003155dce1b02ffa0330abbf545c98c5d197f37;
replacing only the new method with its true PRE yields the original whole file.
Distinct regular/single-link no-follow Source and CURRENT-document backups
were proved byte-identical to live PRE before the edit. Main alone wrote
Source/document; the helper owned only the new fixture and original PRE capture.

### Public reproduction and verification

The new SOURCE/test/journey_family_submission_lifetime_test.dart contains four
distinct public-widget controls: same owner, held first ACK across A→B,
A→B→A and normal disposal. It uses ordinary synthetic SDK sessions, real public
JourneyFlowScreen, four visible answer fields and Share my answers. The
inherited public Guardian-ready loader is an explicitly synthetic prerequisite,
not real admission proof. Strict generated .invalid HTTP checks permit the
wrong-owner writes so the oracle, rather than a mock refusal, detects the bug.
Real telemetry and developer previews are disabled; no private widget/state
injection, new readiness seam or teardown-exception suppression was used.

PRE ran once:1PASS/3FAIL, exit1, four executions, no compilation failure.
The three retired-lifetime cases sent4 rather than1 answers. A→B write actors
were[A,B,B,B]; ABA and disposal sent all4 as A. Their printed observations
showed17→25 requests and4→6 Family reads after the held ACK. Those cases reached
the first length assertion and failed; later assertions did not all execute.

POST on that unchanged frozen fixture ran once:4PASS/0FAIL, exit0. All three
retired cases preserved only the first synthetic commit,17→17 requests and4→4
Family reads. Same-owner still sent all4 in order and reloaded the server state.
Each observation lasted500ms and ended1752ms after mount, before8-second
polling. This is bounded pending-write behavior, not permanent no-polling proof.

The two-file analyzer then reported one avoid_print info in the new test,
exit1; it reported no Source diagnostic. The test-only diagnostic became
debugPrint, and apply_patch normalized one extra terminal LF. Exact proof
retains all assertions, mocks and timing. Fixture21760B/a3ca68986ce2b20bbec5a519c437dd24c368a0dc3ee0a139c70c76c156c99a3c
became21764B/072d0ef364a28d9549b1be04acf52ec0d4f930cc9bd041320e151e70b70a00bb.
Final POST4PASS/0FAIL, exit0, and final two-file analyzer exit0/no issues.
Totals are four unique new cases, three Flutter invocations and12 case
executions:9PASS/3FAIL across PRE and both POSTs. The last POST is not four
additional unique cases. The previous12 controls and platform/grants review
were not rerun. Analysis covers only the changed Source and new test file,
not the full app or native artifact.

### Remaining criteria and evidence

Submission guards do not make already-pending _FamilyStageViewState._loadOnce
reads account-scoped. That separate read-lifetime verification remains a next
bounded OA-ZYRA-305 check; this repair is not whole-screen or server clearance.

The enlarged-text review confirms all nine previous cases remain held.
They are six ordinary/reduced question-arrival fit identities across phase1/2/3
and three canonical count-text containment identities, not three Welcome pages
or nine independent defects. Existing bodies exceed the fixed cue space;
status-row wrapping alone increases the deficit. The status-wrap RESULT
contains sourceEditCount0 and did not repair these cases. A body-scroll/fixed-cue
choice still awaits Founder. Family/Conversation saved cue rectangles have
separate small overlap observations, without a painted-glyph or failed-action
oracle; no arbitrary placement correction was implemented.

Original/raw PRE, both actual POST captures, failed/final analyzer captures,
true PRE backups, method inverse/outside proof, fixture diagnostic-only proof,
dated scope, result and final seal use prefix
NEXT_OA305_FAMILY_LIFETIME_2026_10_07_ in the existing6October review directory.
The original PRE is helper-attributed and stored from its actual tool objects;
POST and analyzer are Main executions. Preparation-only capture/path/Node-format
errors are retained separately from product and test-compilation results.
This additive section preserves all151722 previous document bytes; its final
readback and internal review belong to the subsequent result/seal, not a
pre-assertion in this section.

The existing IPA25581029B/da89aff38201eee83bb0f3685b09a6c1350b9853e34bee831c99e9a44940fca0
was only pinned, not rebuilt, re-signed, installed or launched; it does not
contain this new Source repair by virtue of this local pass. Ordinary native
Apple/Google/recovery/accessibility/network acceptance, SDK privacy,
database-plus-photo restore, identity/moderation, paid receipt authority and
all production/security/legal/release gates remain separate and open.
No shared OA/register/dashboard/schedule, Git/PRIVATE, dependency, live
backend/provider/account, public/store, spend or destructive action occurred.
Internal checks are not Founder acceptance or readiness-score uplift.

## 28. Family answer read lifetime repair measured 7 October 2026

OA-ZYRA-305 owns this separate pending-read repair. ZYRA FINAL REALEASE sent a
finite follow-through after verifying section27's submission repair. Main
independently re-read the direct 7October human away-work authority identified
in section27. Routine reversible local execution is authorised; the Founder
remains AWAY and production, phone delivery and release acceptance are separate.

### Implemented boundary

Only _FamilyStageViewState._loadOnce in journey_flow_screen.dart changed.
The first pending Family answer fetch previously continued after A→B,
A→B→A or normal disposal. It dispatched the opposite-direction Family fetch
and three rating reads. In the synthetic A→B control these four later requests
used B, and the old first result contributed to visible completion; ABA also
published under the returned actor's new generation. Disposal prevented
publication through the existing mounted check but did not stop those reads.

The load now captures its starting SDK actor and account generation. A local
predicate checks mounted state, SDK actor and current account generation
before the initial load, after each Family await and after the aggregate rating
await, before visible publication. Already-dispatched work may settle; the
client does not revoke the first request. Same-owner loading and completion
remain. The coalescing _load method, polling/lifecycle/parent/constructors,
verified _submit, services, API/RPC/schema and role contracts are unchanged.
No layout, copy, font, colour, navigation, arrow or motion design changed.

True PRE Source357417B/ef2effd3e0364eb9274c8c77ea3a167440df66d4f122a1a8fb16e7b155b40146
became357806B/9edc0341a1bd70d10c11704b82788ee48d82a86f72846818f2e681ca6bdd6c5d.
The exact load method changed1263→1652B, a389B addition; method POST is
de86961cf5c45fa51d46af4b6d8d870676bfc98bc570dbfdfbf3ae4257de3242.
All356154 outside-method bytes remain exact,
SHA-25630d1bfcb0210c7cd2d006e2190db3082cccc54a9e40ed1ab560388c8417e94a2;
replacing only the new method with true PRE reproduces the whole original.
Family _submit remains1400B/e0c8fbabafdcd7ac619a9319c45222b06e5a070fec884fc49e3cb056cb12d299.
Fresh independent regular/single-link Source and document before-state backups
were proved exact. Main wrote only Source, this handover and its evidence;
the helper owned the new fixture and original PRE capture, then released.

### Public controls and measured results

The new SOURCE/test/journey_family_read_lifetime_test.dart holds the FIRST
Family answer GET while the same owner remains, A→B, A→B→A or normal disposal
occurs. It uses the public JourneyFlowScreen, ordinary synthetic SDK sessions
and account synchronization. The inherited public Guardian-ready loader is a
disclosed synthetic prerequisite, not real admission. Developer preview and
production telemetry are disabled; font stubs do not prove native typography.

The first actor and four generated answer rows are frozen at dispatch. The
strict generated .invalid transport permits later B/returned-A reads so a
mock refusal cannot hide the defect. Baseline requests are counted after
ordinary account transitions or disposal and before releasing the successful
held response. All observations precede the first late-read assertion.
Teardown is normal, without exception suppression or private state injection.
The oracle and final21941B/e9a16c461b6c2c4c895cc068d1da3d3275b800a54d737e5e8ca93090bfcad1da
fixture were frozen before PRE and remain unchanged after it. Mechanical
formatting occurred only on that new fixture before the first run.

PRE ran once:1PASS/3FAIL, exit1, four executions, no compilation failure.
Same-owner and all three retired cases recorded7→11 total requests,
1→2 Family reads and0→3 rating reads after release. A→B issued all four
later requests as B; ABA/disposal used A. Completion was observed for same
owner, A→B and ABA, but not disposal. Failed cases stopped at the first
extra-Family-read assertion; printed later observations are not passed
assertions. No framework or teardown error was concealed.

POST ran the unchanged four new cases plus four existing Family submission
cases as directly affected load/reload regression:8PASS/0FAIL, exit0.
Same-owner still recorded7→11 requests, one later Family fetch and three
ratings, with completion visible. A→B, ABA and disposal recorded7→7 requests,
1→1 Family reads and0→0 ratings, with no stale completion or feedback.
All four existing submission controls passed: same-owner writes/reload worked;
retired submissions kept only their already-dispatched first synthetic write.

Each new observation window lasts500ms and ends1752ms after mount, before
the initial8-second poll. This proves the measured pending-first-read boundary,
not permanent absence of polling. Totals in this packet are two Flutter
invocations and12 executions:9PASS/3FAIL. Four new distinct controls add to
the prior16, giving20 accumulated targeted identities; four old submission
cases were rerun, not counted as new. The other previous12 were not rerun.
One targeted analyzer covered Source plus both Family fixtures, exit0/no
issues. It is not whole-app or native-artifact analysis.

### Remaining criteria and preserved evidence

This resolves section27's unmeasured FIRST-Family-fetch criterion only.
Account changes during later reads, already-visible account snapshots and
native auth-driven remount behavior remain unmeasured. In particular,
fetchAllMyRatings performs its own three sequential reads inside one await;
the caller now rejects obsolete publication afterward, but this packet does
not establish stopping its internal chain if ownership changes mid-aggregate.
Further service-owned coverage or repair requires a separate bounded packet;
no service or contract change was made here. Server RLS/privacy, identity and
Guardian admission are not proved by these synthetic client controls.

All nine enlarged-text Journey question-arrival case identities remain held
as described in sections25–27, pending the Founder body-scroll/fixed-cue
choice. These are six fit and three count-text containment identities across
phase1/2/3, not Welcome pages or nine independent defects. No layout repair,
native/provider acceptance, SDK privacy remedy, paid receipt authority or
database-plus-photo restore acceptance is implied.

Dated scope/oracle, independent true PRE backups, original helper PRE tool
objects, Main POST objects and exact raw log, analyzer, method inverse/outside
proof and the subsequent result/seal use prefix
NEXT_OA305_FAMILY_READ_LIFETIME_2026_10_07_ in the existing6October review
directory. Preparation-only path/capture/schema/boundary errors are recorded
separately from product and compilation results. The additive document proof
preserves all158667 prior bytes; final readback belongs to its result/seal.

The old IPA remains only pinned and unchanged, not rebuilt, re-signed,
installed or launched. No shared registers/dashboard/scores/schedules,
Git/PRIVATE/aliases, dependencies/native/signing, live backend/provider/SQL,
security apply, account/public/store/spend or destructive action occurred.
Internal verification is not Founder acceptance, whole-OA closure or readiness
uplift. The finite packet ends with one substantive coordinator handoff.

## 29. Family ratings aggregate account-lifetime repair measured 7 October 2026

OA-ZYRA-305 owns this finite follow-through from ZYRA FINAL REALEASE.
The direct 7 October away-work human authority was independently read again,
including message 01a11636-37dd-7f73-86c5-c162e2a60211. Routine reversible
local execution is authorised; the Founder remains AWAY. This is not
production execution, delivery to the phone, release approval or acceptance.

### Implemented boundary

Only fetchAllMyRatings in SOURCE/lib/services/zyra_journey_service.dart
changed. Each existing fetchMyRatings call formerly recaptured the SDK actor.
After a held phase1 response, an account-retired aggregate continued phase2
and phase3 under B, or under the returned A's new account generation.
Section 28's widget guard already prevented stale UI publication; that did
not stop these service-internal requests.

The aggregate now captures the starting SDK actor and account generation.
A local predicate checks both the current SDK actor ID and the existing
ZyraAccountState.isCurrent result before each phase and immediately after
its await. On retirement the implementation returns an empty aggregate before
merging that response or dispatching another phase. Already-dispatched work
may settle; this does not cancel or revoke it. Same-owner phase order and
merging remain. No new widget-lifetime parameter or service API was introduced.

Whole service PRE was 76285 bytes,
SHA-256 f2f395e615bf6dd55e8208c422d2fdd95b8bd52f25419a7933b281b1704a559c.
POST is 76687 bytes,
SHA-256 a2ebb51830cccaceb87d9000bb8af0a94401e9e67df165de7b8da72a3596a39d.
The exact method changed 240 to 642 bytes (+402); POST method SHA-256 is
f81d79bc7b503ada072c715a6ed00207e00251ad9ad9eb193fb49554422b4765.
All 76045 outside-method bytes remain exact,
SHA-256 aec18d69d1daab6f321ab3bf640fb971e129c67c60a983f71606ef20ad7ffc9c.
Replacing only the method with true PRE reproduces the whole original.
fetchMyRatings remains 743 bytes,
SHA-256 b263e76cfda419b00c8bf232a01e7322c00e0ec2cd83de848526b52133497c57.
Imports, signatures, queries, error handling, RPC/schema, account state,
dependencies and the previous Journey screen/fixtures are unchanged.
No layout, copy, fonts, colours, navigation, arrows or motion changed.

### Public controls and measured results

The new SOURCE/test/journey_family_ratings_read_lifetime_test.dart has
exactly three new controls: same owner, A→B and A→B→A. It uses the public
Family widget and ordinary synthetic SDK sessions/account synchronization,
with strict generated .invalid transport. Both Family answer GETs complete
before the first phase1 rating GET is held. Its A actor, rater ID and row
(p1_q1=reassured) are frozen at dispatch; later phases return p2_q1=concerns
and p3_q1=discuss_further. Potential wrong-actor requests are permitted and
observed, not blocked by the mock.

The inherited public Guardian-ready loader and font stubs are synthetic
prerequisites, not identity/admission or native typography evidence.
Only same-owner uses the existing public mock-only One plan setter to make
the exact ratings-dependent Guardian summary visible. Its three distinct
topics require all three returned rows. Retired cases start Basic and use the
ordinary account reset; there is no paid entitlement or receipt proof.
No private state injection, duplicate service call, exception suppression or
new aggregate-disposal case was added.

The oracle and final fixture were frozen before PRE. Fixture size is
23018 bytes, SHA-256
8026239cb740e6891b776a48ce12469c3938895bcca0be9ac7550d7acd0de9ee,
unchanged through POST. Mechanical formatting and the draft correction
moving mock One from common setup to same-owner occurred before freezing.

Original PRE ran once: 1 PASS / 2 FAIL, exit 1, three executions and no
compilation failure. All three recorded 9→11 total requests, 2→2 Family
reads and 1→3 rating reads after release. A→B's phase2/3 actor and rater IDs
were B; ABA used returned A at generation 13 rather than starting generation
11. Same-owner's exact returned-value-dependent summary and completion were
visible. Both retired UIs were already hidden. Retired controls failed the
first late-rating-count assertion at fixture line 549 (1 expected, 3 actual);
later printed observations are not claims that unreached assertions passed.

POST used the same unchanged three controls plus the existing first Family
read fixture's four controls: 7 PASS / 0 FAIL, exit 0. Same-owner retained
all three A phases, 9→11 requests, 1→3 rating reads, completion and the exact
summary. A→B and ABA recorded 9→9 requests and 1→1 rating reads, with no
later requests or stale publication. The four directly affected first-read
regressions also passed: normal Family loading/completion remained, and
account-retired/disposed first Family reads stopped their later chain.
That old disposed control is not evidence of cancellation after an aggregate
rating request has already started; no such widget-lifetime API exists here.

All observations precede the first behavior assertion and use a separate
ordinary-account-transition baseline. Each 500 ms window ends 1752 ms from
mount, before the initial eight-second Family poll. Null framework-error
diagnostics and normal unsuppressed teardown were retained. These bounded
synthetic observations are not production latency or permanent polling claims.
The service's empty-return implementation is source-verified; stale widget
publication is measured separately, not used to infer internal cancellation.

This packet has two Flutter invocations and ten executions: 8 PASS / 2
intentional original PRE FAIL. Three new distinct controls bring the
accumulated local targeted identities from 20 to 23. Four old first-read
controls were rerun, not counted as new; the other previous 16 were not
rerun for activity. One targeted analyzer covered only the changed service,
new fixture and affected first-read fixture: exit 0, no issues. This is not
whole-app or native-artifact analysis, and 23 is not a release-gate count.

### Evidence, remaining criteria and delivery limits

Main owns the method repair, additive handover and supporting evidence.
The helper owned only the new fixture and original PRE capture, then
released its writer. A separate internal read-only reviewer checked the
fixture/value oracle, actual PRE and method inverse/outside proof; final
evidence verification is recorded separately, not treated as Founder approval.

The dated prefix NEXT_OA305_FAMILY_RATINGS_READ_LIFETIME_2026_10_07_ in the
existing 6 October review directory contains scope/oracle, independent true
PRE service/document backups, original helper PRE tool objects, Main POST
objects and exact log, analyzer, method-only inverse/outside proof and
subsequent document/result/seal proofs. Fresh named-input guards include
106 explicitly acquired protected files, including previous screen/fixtures,
sealed evidence, mock entitlement/generator dependencies and the old IPA.
This is not a whole-tree unchanged claim; ordinary Flutter caches may change.
This section is additive to the exact 166034-byte prior handover; the
subsequent document proof checks that complete prefix byte for byte.

The section 28 first-held-rating aggregate ownership concern is now measured
and repaired at that boundary. Changes during later phases, already-visible
snapshots, native auth-driven remount, other callers/polls and widget disposal
after rating dispatch are not newly measured. The before/after guards cover
each phase in source, but the tests here hold only phase1. Server RLS/privacy,
Guardian admission, identity/moderation and commerce remain separate gates.

All nine coupled enlarged-text Journey question-arrival layout identities
remain HELD pending the Founder body-scroll/fixed-cue decision: six fit and
three count-text containment identities across phase1/2/3, not Welcome pages.
No native/provider login/recovery/accessibility/network acceptance, SDK
privacy remedy, paid lifecycle/receipt authority, database-plus-photo restore
acceptance, readiness-score uplift or whole-OA closure is implied.

The old IPA remains only pinned and unchanged, not rebuilt, signed,
installed or launched. No phone work while away, Git/PRIVATE/aliases,
shared registers/dashboard/scores/schedules, dependency changes, live
backend/provider/SQL/migrations/security/account/public/store/spend/legal
or destructive action occurred. This finite packet ends with one substantive
coordinator handoff and released writers, not acknowledgement-only loops.
