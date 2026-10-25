---
id: DOC-ZYRA-0155
type: HANDOVER
status: CURRENT
feature: GENERAL
purpose: ZYRA — Shared Pause Decision: Implementation Handover
links: []
owner: ZYRA chat
---

# ZYRA — Shared Pause Decision: Implementation Handover

**Document:** `ZYRA_PAUSE_DECISION_HANDOVER_CURRENT_VERSION_V1.md`  
**Version:** V1  
**Status:** CURRENT_VERSION — CODE COMPLETE; DATABASE MIGRATION STAGED BUT NOT APPLIED; Fable reconciliation and Founder device verification pending  
**Date:** 2026-08-25  
**Implementation owner / author:** Codex, Lead Architect  
**Documentation verifier:** PENDING — Fable has not yet reconciled this handover against disk  
**Authority:** Founder direct Shared Pause Decision brief, 2026-08-25  
**Register:** OA-ZYRA-261 (assigned by Fable, 2026-08-25 — see §13)  
**Governance:** `IMPLEMENTATION_HANDOVER_STANDARD_CURRENT_VERSION_V4.md`  
**Migration authority:** repository migration authorised; live application was not authorised and did not occur

---

## 1. What was built and why

The former asymmetric personal-hold Pause experience was replaced in the
Flutter client and staged database design by one shared decision process.
Nobody owns the Journey after asking for space, and nobody has to ask a
counterpart for permission to regain control.

The implemented product shape is:

1. Either Seeker selects **Request Pause**.
2. The Journey remains in Active capacity, but its content and write paths are
   locked while the other Seeker decides.
3. The other Seeker receives equal **Agree to Pause**, **Request to Continue**
   and **End Journey** actions.
4. A continuation request returns the final decision to the original
   requester: **Continue Journey**, **Confirm Pause** or **End Journey**.
5. Only a settled Pause frees Active capacity and consumes Paused capacity for
   both people.
6. A settled Pause is symmetrical. Either person can **Request Resume**; the
   counterpart chooses **Agree to Resume**, **Keep Paused** or **End Journey**.
7. Requests create no shared Timeline milestone. Only final Paused,
   Continued/Resumed and Ended outcomes are recorded.

The change exists because the retired model displayed “Paused by you/them”,
“Pause too”, a unilateral “Resume Journey” and a one-shot “Request Continue”.
That model made one person appear to own the pause. The new state belongs to
the pair and keeps each final decision explicit.

## 2. State model and invariants

```text
ACTIVE / unlocked / Active capacity
  |
  | Request Pause (A)
  v
PAUSE_REQUESTED / locked / still Active capacity
  |-- Agree to Pause (B) ------------------------------.
  |-- Request to Continue (B)                          |
  |       v                                             |
  |   CONTINUE_REQUESTED / locked / still Active       |
  |       |-- Continue Journey (A) -> ACTIVE            |
  |       |-- Confirm Pause (A) ------------------------|
  |       `-- End Journey (A) -> ENDED                  |
  `-- End Journey (B) -> ENDED                         |
                                                        v
PAUSED / locked / Paused capacity for both
  |
  | Request Resume (either)
  v
RESUME_REQUESTED / locked / still Paused capacity
  |-- Agree to Resume (other) -> ACTIVE
  |-- Keep Paused (other) ----> PAUSED
  `-- End Journey (either) ---> ENDED
```

Storage values are `none`, `pause_requested`, `continue_requested`, `paused`
and `resume_requested`. Every transition carries `pause_version` for
compare-and-swap rejection of stale/double actions. Pending requests remain
Active-slot-counted. `paused` and `resume_requested` remain Paused-slot-counted.

The staged server RPC locks the match row, active attempt row and both
participant advisory-lock keys in stable order. The first two serialize two
answers on one Journey; participant locks serialize plan-cap changes across
different Journeys involving either account. Capacity is re-read inside the
same transaction. The client preflight improves the explanation but is never
the enforcement boundary.

The database migration repeats the existing direct-write revokes. Authenticated
clients cannot update `matches` or `journey_attempts`; `transition_journey_pause`
is the only new Pause transition door. Retired pause/resume/nudge RPC names are
retained only as loud `pause_flow_superseded` refusals for stale clients.

## 3. Data flow and failure paths

```text
Connections/Journey action
  -> ZyraJourneyService.transitionPause(action, expectedVersion)
  -> transition_journey_pause RPC
     -> auth + pair + active-match + active-attempt checks
     -> match/attempt/participant locks
     -> eligibility + account-active + plan-cap checks
     -> atomic match + attempt + conversation update
     -> one calm, preference-gated notification
     -> final state + incremented version
  -> client re-fetches party-scoped state
  -> Connections and Journey render the same perspective
```

Named failures remain truthful:

- stale version -> re-fetch the winning state;
- invalid action -> re-fetch rather than pretending success;
- Paused-cap conflict -> keep Active+locked and explain manage/continue/end;
- either Active-cap conflict on resume -> keep Paused and explain that nothing
  was lost;
- changed eligibility -> keep the Journey locked; End remains available;
- unknown/network failure -> show a retry message and preserve the current
  state.

The client fetches actor/timing/version fields only through
`zyra_my_pause_states`, which returns rows only when `auth.uid()` is one of the
two Seekers. Guardians select only neutral `pause_state`; they never receive
initiator/requester ids. A Guardian sees “Journey awaiting a decision” or
“Journey paused”, with stage/review actions hidden while locked.

## 4. Navigation and user-visible surfaces

- **Connections / Active:** pending requests stay here and show “Pause decision
  pending” / “Open decision”. Opening the card routes directly to the dedicated
  waiting/decision page.
- **Journey:** every non-`none` state replaces the normal stage with the
  dedicated Pause surface. The ordinary stage is not interactable beneath it.
- **Connections / Paused:** only mutually settled Pause and pending Resume
  appear here. Both people receive the same Request Resume capability.
- **End:** remains available from every waiting/decision/paused state and uses
  the existing End Journey privacy/history rules.
- **Guardian Dashboard and Journey detail:** neutral status only; no actor
  disclosure and no Guardian action while the Journey is locked.
- **Profile and Timeline:** existing read-only access is preserved; the shared
  Timeline records only final outcomes.

## 5. Developer and testing controls

`ZyraDevScenario.pauseScenario` is one global test-state owner consumed by the
real Connections and Journey readers. It is not a cosmetic page switch.
Changing the Pause scenario recomposes the Journey row and its dedicated
decision surface; actions advance the same state model. Reset restores Active,
version zero and no Pause episode.

The 13 independent states are:

1. Active
2. Pause requester waiting
3. Pause responder decision
4. Continuation requester waiting
5. Continuation responder decision
6. Mutually paused
7. Resume requester waiting
8. Resume responder decision
9. Resumed / active
10. Ended from Pause
11. Deadline approaching
12. Deadline expired
13. Paused-cap conflict

Basic and ZYRA One remain a separate developer account-plan axis, so every
state can be reviewed against Basic 1 Active / 5 Paused and ZYRA One 3 Active /
10 Paused without duplicating fake Pause states.

## 6. Mock versus production behaviour

| Area | Developer/profile build | Production/live truth |
|---|---|---|
| State previews | All 13 states are local deterministic test state and use the real client model/surfaces | No fake state is rendered in release |
| Actions inside a preview | Advance the shared in-memory test state and its real consumers | Call the atomic RPC and re-fetch persisted state |
| Legacy bridge | Old fully paused rows render neutrally as mutual Pause | Temporary only until the staged migration is applied |
| New Pause writes | Preview works without Supabase | **NOT LIVE:** the RPC does not exist until the Founder authorises migration application |
| Guardian view | Neutral staged labels | Neutral `pause_state` only; actor ids remain Seeker-party-scoped |
| Deadline | Approaching/expired preview states are testable | Field exists in staged schema, but the duration and expiry outcome remain unset |

## 7. Database and migration

### Repository file

`SOURCE/supabase/migrations/20260825120000_shared_pause_decision_state_machine.sql`

The migration:

- adds the five-state Pause shape, actor/timing fields, attempt identity and
  CAS version to `matches` and `journey_attempts`;
- refuses a legacy conversion if an active old Pause lacks an active attempt;
- converts valid old personal holds into neutral mutually Paused rows;
- adds one nullable deadline source, `zyra_pause_decision_window()`;
- enforces Basic 5 / ZYRA One 10 Paused capacity for both Seekers;
- provides party-scoped state and capacity readers;
- adds calm decision notification types to the existing preference gate;
- implements the atomic transition RPC with row and participant locks;
- blocks stage, answer, rating, checkpoint, Salam, compatibility, family,
  milestone and message INSERT/UPDATE/DELETE paths while locked;
- clears Pause state on every match/attempt ending path;
- refuses the three retired RPCs; and
- grants clients neutral match state only, never Pause actor columns.

### Live status and probes

**NOT APPLIED.** No DDL, migration, Edge Function, auth setting or live data
mutation was performed.

Read-only live probes against project `sxoaxonzjqkgajmlagyk` measured:

- `transition_journey_pause(uuid,text,bigint)` present: **false**;
- active legacy Pauses: **1**;
- active legacy Pauses missing any non-ended attempt: **0**;
- active legacy Pauses missing an active attempt: **0**;
- lock-target table columns checked: **13**; missing: **0**;
- prerequisite eligibility, Active-count, Active-cap and notification
  functions: **4/4 present**;
- currently stored notification types all fit the migration constraint:
  `journey_ended`, `journey_paused`, `new_message`, `wali_request`.

Rollback is not yet authored because the migration has not been applied and a
rollback policy for already-entered shared decision states requires a product
decision. Do not improvise a downgrade to personal ownership. Before live
application: back up/probe the one legacy row, apply the repository file only
with Founder authority, then run the focused SQL suite in the same release
window.

## 8. Live files and SHA-256 evidence

Hashes were measured from the live working tree after the final Dart format,
analyzer, focused/full Flutter suites, repository checker and iOS simulator
build on 2026-08-25.

| File | SHA-256 | Responsibility |
|---|---|---|
| `SOURCE/lib/data/zyra_journey_pause_state.dart` | `b292b5042b8d393c5a6f1de0a6d62b4c92a15ac22895e124038cf3c46c79d205` | Authoritative client phases, perspectives, actions, pure transition policy and 13-state developer matrix |
| `SOURCE/lib/models/journey_match.dart` | `663e3a5c29920d67bccbc1a03755fab0e7ca15b35f65d3ff2f5b9688e094823f` | One Pause state on each Journey; Active/Paused/locked derivation |
| `SOURCE/lib/services/zyra_journey_service.dart` | `ee9d0681d76f6ab7b22d7271c0f8cf57d27668a04b6418c27940fe7e6eb30f05` | Party-scoped reads, transition/capacity RPCs, named failures and temporary legacy bridge |
| `SOURCE/lib/services/zyra_wali_journey_service.dart` | `924a3a57b3c5031b06f547c8c709f1071a7f2af347001b54c758e5af9300120e` | Guardian-neutral Pause read with missing-migration-only fallback |
| `SOURCE/lib/screens/journey/journey_flow_screen.dart` | `775bbfc07abb8df09eaf2ca0e4f9055fd8cc260c997ed67d38373e18b1970847` | Request confirmation, all dedicated waiting/decision states, capacity/deadline copy and locked-stage routing |
| `SOURCE/lib/screens/connections/connections_screen.dart` | `b03753d4d8b672c4dd390d8ecea9365a3796fb60faf15281398057b521fb979c` | Active pending rows, mutual Paused rows, resume flow and takeover correction |
| `SOURCE/lib/screens/wali/wali_dashboard_screen.dart` | `9210a7198dbd9c23a3c39232456c8b424dd00becdb14dbd43bf692e8654a13f3` | Neutral status/capacity counts and no locked Guardian attention action |
| `SOURCE/lib/screens/wali/wali_journey_detail_screen.dart` | `ce254476106bea83dcbe970320fe07615cbb30bd9d6794f0e69caa36ea770370` | Neutral detail state and family/review controls hidden while locked |
| `SOURCE/lib/widgets/zyra_ward_card.dart` | `8fa876601f0089a33fa34c10bf9459e48e07f152fb53b1167baf94cdcb2f495a` | Guardian card terminology alignment |
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | `baf5634befe68d53d0a79f4889cb3786434a0e3109c656c7b562cc16134b2c43` | Singular global Pause scenario, composition and reset |
| `SOURCE/lib/dev/dev_scenario_panel_v2.dart` | `eff6fe2a7a7597115181388c7c2e227409a432db98b3f55e118242110fa195fa` | Seeker 13-state selector |
| `SOURCE/lib/dev/zyra_page_preview_screen.dart` | `4bfe73769ad36a3690c7552441b988f1dfc67e7ea59f5f7da91f79ef23f2db8f` | Current page inventory language |
| `SOURCE/lib/dev/wali_dev_scenario_panel.dart` | `fd36ac38e6a26487e1a07ad90c0ee290a307f6620fb421579720c6d5f7375a6d` | Guardian-neutral developer labels |
| `SOURCE/lib/data/zyra_entitlements.dart` | `1b13436b730224595d0079d8ae26bb02321251bb616d8880707b1ffadfb0e54b` | Canonical Active/Paused capacity meaning updated for shared Pause |
| `SOURCE/lib/screens/subscription/upgrade_screen.dart` | `0bbbd5c3715ab26a4d4d9e40d03b7f765588b35e22209ad62584a112b7684ba2` | Accurate plan-limit wording |
| `SOURCE/lib/screens/profile/seeker_profile_screen.dart` | `da21ccd29be8b87aafc4b7f8dc48172a6f8e0c8f9d204cdc50308e0d59860ff7` | Retired Pause terminology removed from implementation commentary |
| `SOURCE/test/journey_pause_state_test.dart` | `de3d697ad7228ff7a5781f4bd3c5890d94a106d502b52c27e1be4559b1adab32` | Pure transitions, matrix edges, decision UI, deadline, capacity and male/female parity |
| `SOURCE/test/zyra_truthful_failure_test.dart` | `8e2f88f5224006619e228b911ec579ab3b342fb9a029351e119a6dee616bc03d` | Named/unknown Pause write failure truthfulness |
| `SOURCE/test/dev_scenario_panel_policy_test.dart` | `ac4f978d4f1b3a9b1f51472821fd5ce728d44c898378f73db62a4e18b2158760` | Full state selector and reset policy |
| `SOURCE/supabase/migrations/20260825120000_shared_pause_decision_state_machine.sql` | `8b25b2ba20e42f6d1236c009e47b391ebd3fd67e565f028944707b8a765ac89e` | Staged server state machine, privacy, capacity, lock and migration logic |
| `SOURCE/supabase/tests/zyra_pause_decision_state_machine_suite.sql` | `01ea98c6a0dcbc55013ae238aacffe900e511d9cf35e96a1ffe353399057a4a5` | Transactional SQL contract suite to run after migration application |
| `SOURCE/supabase/tests/zyra_journey_suite.sql` | `4ed112129ef49aa6288602be0d32c93059acdd0f718ef1d4dfbd9e8499d5efa4` | Legacy-suite retirement notice pointing Pause verification to the current suite |

## 9. Verification evidence

- `dart format` over all 19 changed Dart/test files, followed by the two final
  helper files — **PASS; final source already formatted**.
- `flutter analyze --no-pub` — **PASS, no issues**.
- `flutter test --no-pub --reporter compact test/journey_pause_state_test.dart
  test/zyra_truthful_failure_test.dart test/dev_scenario_panel_policy_test.dart`
  — **32/32 PASS** on the exact final Dart source.
- Focused coverage includes both requester/responder perspectives, settled
  Pause, continuation, resume, stale/invalid actions, deadline approaching and
  expired-with-no-auto-outcome, Paused-cap conflict, truthful failures, all 13
  developer states, reset and identical male/female Seeker decision contracts.
- `flutter test --no-pub --reporter compact` — **392/392 PASS** on the exact
  final Dart source.
- `python3 tools/zyra_check.py --quiet` — **PASS, zero findings**.
- `python3 -m unittest tools/test_zyra_check.py` — **1/1 PASS**.
- `flutter build ios --simulator --no-codesign --no-pub` — **PASS**; Xcode
  build completed in **54.9s** and produced
  `build/ios/iphonesimulator/Runner.app`.
- Old-copy/reference sweep across `SOURCE/lib` and `SOURCE/test` — **zero**
  `Paused by you/them/both`, `Pause too`, `Resume Journey`, retired Dart RPC
  wrappers or retired ownership-field model references.
- Live read-only SQL probes — results recorded in §7.
- `SOURCE/supabase/tests/zyra_pause_decision_state_machine_suite.sql` —
  **PENDING — not run**, because the migration is deliberately not applied and
  no local PostgreSQL/Supabase CLI exists. The suite is transactional and
  covers transitions, Basic/One caps, CAS/duplicate rejection, participant
  locking presence, direct-write privilege closure, lock bypasses, actor-field
  privacy, notification preference routing, final Timeline outcomes, retired
  RPC refusal and End cleanup.
- Physical iPhone two-account interaction and visual observation — **PENDING —
  not yet measured**. Simulator compilation is not presented as device proof.

## 10. Old behaviour retired and documentation drift

Retired from the Dart runtime and developer controls:

- Paused by you / them / both;
- Pause too;
- unilateral Resume Journey;
- the old readiness nudge as a final decision;
- `suspendedBy`, `alsoPausedBy`, `pauseNudgedAt`, `heldBy` and
  `pausedByBoth` client ownership fields; and
- client calls to `suspend_journey`, `resume_journey` and
  `nudge_paused_journey`.

The governed `APP/Journey/JOURNEY SUSPENSION/JOURNEY_SUSPENSION_CURRENT_VERSION_V3.md`
still specifies the superseded personal-hold model. It is therefore not
current implementation truth for Pause after this build. Codex did not
self-ratify or overwrite this Fable-owned product authority. Fable must issue a
new governed version, archive V3, retarget references, update the developer
control documentation and regenerate the documentation index.

The broad `zyra_journey_suite.sql` still contains historical personal-hold
sections because it also verifies many unrelated Journey contracts. A banner
marks those Pause sections as legacy and routes current Pause verification to
the focused suite. Fable should decide whether to split/archive those sections
during reconciliation; silently deleting unrelated coverage was rejected.

## 11. Open decisions, limitations and next owners

1. **Founder — response duration:** no ratified Pause-decision window was found.
   Decide the exact duration.
2. **Founder — Person B silence:** decide the outcome when the Pause responder
   never answers. No auto-pause, auto-continue or auto-end exists.
3. **Founder — Person A silence:** decide the outcome when the original
   requester never answers a continuation request. No automatic outcome exists.
4. **Founder — migration authority:** explicitly authorise live application
   before the RPC can power real accounts. Until then, only developer previews
   work and new production Pause requests truthfully fail.
5. **Codex after authority:** apply the exact repository migration, run the
   focused SQL suite, re-run live probes/advisors, update this handover with
   measured SQL results and perform the two-account device flow.
6. **Fable:** assign/link the OA, update and reconcile the product/build/dev
   documents, archive superseded V3 assumptions, regenerate the index and
   verify every hash/evidence claim against disk.
7. **Architecture Reviewer:** review the server transition, participant-lock
   ordering, privacy projection and migration rollback policy independently.

No OA identifier was invented for these gaps because the live register was not
delegated to Codex in this work. No git command, commit or self-approval was
performed.

## 12. Authority map

| Truth layer | Current authority/status |
|---|---|
| Founder intent | Direct Shared Pause Decision brief, 2026-08-25 |
| Shared implementation governance | `BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_STANDARDS/IMPLEMENTATION_HANDOVER_STANDARD_CURRENT_VERSION_V4.md` |
| Product Pause specification | **PENDING Fable supersession**; V3 is now documented as implementation-stale |
| As-built implementation | This handover plus the live hashes in §8 |
| Database production state | Old live schema; staged migration explicitly unapplied |
| Superseded runtime model | Personal holds / pause ownership / unilateral resume |

## 13. Fable reconciliation record (2026-08-25)

Verified by Fable against disk and the live database, per §11.6 and the
Codex handover message:

1. **Hashes:** all 22 §8 hashes matched disk at completion verification.
   Three shared developer files later moved under a separately
   Founder-authorised change (Active Journey count in the Connections
   developer toggle), which did not touch the Pause state machine. Their §8
   values are therefore historical completion hashes; current disk values,
   re-measured and confirmed 2026-08-25:
   `zyra_dev_scenario.dart` `4e04227280b3c166db57b4c89512b7a6f8c0ee518e62e9f024076e71cc49e8fa`;
   `dev_scenario_panel_v2.dart` `e083e6235a5346bd54d499854fe1950cdeac311c2c3b3bf05808a2980c82168f`;
   `dev_scenario_panel_policy_test.dart` `b3d3aa8aeeb89d3d4d4ba01457552f50af776ede98d57dc673590ac5a4919123`.
   All other §8 hashes remain current.
2. **Retired wording:** independent sweep of `lib` + `test` found zero
   Paused-by-you/them/both, Pause too, unilateral Resume Journey, retired
   ownership fields or old RPC client calls.
3. **Migration boundary:** independent read-only live probe (2026-08-25):
   `transition_journey_pause` present = 0; legacy
   suspend/resume/nudge RPCs present = 3; `matches.pause_version` column
   present = 0 — the staged migration is confirmed unapplied.
4. **Capacity provenance:** Active 1/3 and Paused 5/10 trace to the
   Founder-approved 2026-08-09 entitlements matrix and DR-ZYRA-138.
5. **Governed documentation:** JOURNEY_SUSPENSION_CURRENT_VERSION_V4 issued;
   V3 archived with lineage; DR-ZYRA-215 filed; **OA-ZYRA-261 assigned to
   this work**; 2026-08-06 entitlement record annotated (superseded-in-part);
   documentation index regenerated with this handover and V4 mapped.

— Fable, Documentation Owner

---

— END OF AS-BUILT HANDOVER — code completion is not migration approval, documentation approval or Founder acceptance. —
