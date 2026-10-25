---
id: DOC-ZYRA-0021
type: SPEC
status: CURRENT
feature: APP: JOURNEY
purpose: Journey / Journey Suspension — JOURNEY SUSPENSION CURRENT VERSION V4: ZYRA — Journey Suspension Specification
links: []
owner: ZYRA chat
---

# ZYRA — Journey Suspension Specification

**Version:** V4
**Status:** CURRENT_VERSION — Founder-directed 2026-08-25 (Shared Pause Decision brief); documented by Fable same day. Client implementation CODE COMPLETE; **server migration STAGED, NOT APPLIED** — see §15
**Date:** 2026-08-25
**Owner:** ZYRA Product Governance
**Governing Documents:**
  ZYRA Product Specification (canonical relationship lifecycle)
  DR-ZYRA-121 — Journey Lifecycle redesign (journey_attempts, no automatic endings)
  Entitlements matrix, Founder-approved 2026-08-09 (`SOURCE/lib/data/zyra_entitlements.dart`)
  DR-ZYRA-138 — both plans pause, caps 5/10 · DR-ZYRA-142 — time-honesty, nameless Timeline pair
  DR-ZYRA-206 — deliberate confirmation and outcome screens (carried forward)
  **DR-ZYRA-215 — Shared Pause Decision (this version's subject; supersedes DR-ZYRA-170's personal-hold model)**
  OA-ZYRA-261 — implementation/activation tracking
  `SYSTEM/DOCUMENTS/ZYRA_PAUSE_DECISION_HANDOVER_CURRENT_VERSION_V1.md` — as-built truth
  AD-081 — Capability Independence Principle · AD-082 — State Integrity Principle
**Supersedes:** JOURNEY_SUSPENSION_2026-08-25_V3.md (archived; was dated 2026-08-18)

---

## 0. What changed since V3, and why

V3's personal-hold model (DR-ZYRA-170) still distinguished *Paused by you /
by them / by both*, gave the holder a unilateral **Resume Journey**, and left
the other person a one-shot **Request Continue** readiness message. The
Founder's 2026-08-25 brief retired that shape entirely:

> *"It makes one person appear to control the Journey while the other has to
> ask for permission. One person feels superior and the other feels as though
> they are begging to continue. Pause should become a shared decision process,
> even when one person initiates it."*

Pause is now a **negotiation with equal hands**. Asking to pause does not
pause; it opens a decision the other person answers with equal, respectful
choices. Only a settled outcome moves the Journey — to Active, Paused or
Ended. Nobody owns the pause, and nobody begs.

The experience to communicate: *one person asked for space; the other person
chooses how they respond; the final Journey state belongs to both.*

## 1. Architectural Framing

Suspension remains a behavioural condition of the Journey (AD-082), but its
shape is a five-state, server-enforced decision machine rather than flags of
ownership:

```
ACTIVE  (unlocked · Active capacity)
  │  Request Pause (either person = A)
  ▼
PAUSE_REQUESTED  (locked · still Active capacity)
  ├─ Agree to Pause (B) ──────────────────────────────► PAUSED
  ├─ End Journey (B) ─────────────────────────────────► ENDED
  └─ Request to Continue (B)
        ▼
     CONTINUE_REQUESTED  (locked · still Active capacity)
        ├─ Continue Journey (A) ───────────────────────► ACTIVE (unlocked)
        ├─ Confirm Pause (A) ──────────────────────────► PAUSED
        └─ End Journey (A) ────────────────────────────► ENDED

PAUSED  (locked · Paused capacity for both)
  │  Request Resume (either)
  ▼
RESUME_REQUESTED  (locked · still Paused capacity)
  ├─ Agree to Resume (other) ───────────────────────────► ACTIVE
  ├─ Keep Paused (other) ───────────────────────────────► PAUSED
  └─ End Journey (either) ──────────────────────────────► ENDED
```

Storage: `none · pause_requested · continue_requested · paused ·
resume_requested`, with a compare-and-swap `pause_version` on every
transition so stale pages and double taps are refused, never half-applied.
`transition_journey_pause` is the single write door; direct client writes and
the three retired RPCs (`suspend_journey`, `resume_journey`,
`nudge_paused_journey`) are refused server-side.

## 2. Terminology

| Product term | Meaning |
|---|---|
| Request Pause | Either person asks for a pause; the Journey locks and enters the decision |
| Agree to Pause | The other person settles the pause — only now does the Journey become Paused |
| Request to Continue | The other person asks instead to carry on; the final decision returns to the original requester |
| Continue Journey | The original requester unlocks the Journey exactly where it was |
| Confirm Pause | The original requester settles the pause after a continuation request |
| Request Resume | From Paused, either person asks to resume — symmetric, owned by no one |
| Agree to Resume · Keep Paused | The other person's equal answers to a resume request |
| End Journey | Available to either person from every state; ordinary End rules apply |

Retired product-wide: *Paused by you / by them / by both* · *Pause too* ·
unilateral *Resume Journey* · the one-shot readiness nudge as a decision
substitute.

## 3. Entitlement and capacity

Caps are unchanged (entitlements matrix 2026-08-09; DR-ZYRA-138): Active
Journeys — Basic 1, ZYRA One 3; Paused Journeys — Basic 5, ZYRA One 10.
What V4 changes is **when the slot moves**:

1. **A pause request does not free an Active slot.** `pause_requested` and
   `continue_requested` Journeys remain Active-counted for BOTH people, on
   both plans. A pending request can never be used to gain an extra Active
   Journey.
2. The Active slot is freed — and Paused capacity consumed for both people —
   **only at a settled Pause** (Agree to Pause, or Confirm Pause).
3. `resume_requested` remains Paused-counted until Agree to Resume settles it
   back to Active (subject to the ordinary Active-cap and eligibility checks;
   a refusal keeps the Journey Paused with nothing lost).
4. **Paused-cap conflict:** if either account cannot accept another Paused
   Journey, the settling action is refused before any state moves — the
   Journey stays Active and locked, the person is told plainly why, and
   manage/continue/end paths are offered. No silent cap excess; no failure
   after a hopeful tap.
5. Enforcement is server-side inside one locked transaction (row +
   participant locks, capacity re-read in-transaction). Client checks are
   explanation, never the boundary.

*(This supersedes V3 §5's "slot freed at first hold" rule, and — together
with the V2/V3 lineage — the 2026-08-06 entitlement record's earlier
"Paused still consumes the Active slot" position, which is annotated
accordingly.)*

## 4. Requesting a pause

Either Seeker requests from the Journey or Connections surfaces; DR-ZYRA-206
confirmation discipline carries forward (full-screen confirm, write while the
screen is visible, honest failure, outcome screen). On confirmation:

- the current stage locks for both people — stage actions, answers, Continue,
  Salam/compatibility/family/milestone writes and the conversation are all
  blocked, server-side, until the decision settles;
- no progress, answers or Timeline history are lost;
- the requester sees the dedicated waiting page ("Pause requested — waiting
  for ‹name› to decide");
- the other person receives a **dedicated decision page** — not a pill — with
  three equal choices: Agree to Pause · Request to Continue · End Journey.

## 5. The continuation round

Request to Continue keeps the Journey Active-counted and locked, shows the
responder their own waiting page, and returns the final decision to the
original requester on a dedicated page: Continue Journey · Confirm Pause ·
End Journey. Continue Journey unlocks both people at the exact stage and
state they left; the Active slot was never freed, so nothing recalculates.

## 6. Settled Pause and mutual resume

A settled Pause moves the Journey to Paused Journeys for both people, frees
the Active slot, consumes Paused capacity for both, and gives **both people
the identical Request Resume action**. Resuming is mutual: one requests, the
other agrees, keeps it paused, or ends. Until both agree, it stays Paused.
Either person may End at any time. The UI must never imply the original
requester owns the pause.

## 7. Ending from the flow

End Journey is available in every pending, paused and resume state, for
either person — including the responder to a mere pause request. The ordinary
End rules, privacy protections and history preservation apply; the other
person's reason or private decision is never exposed.

## 8. Timeline behaviour

A request is not a relationship event. The shared Timeline records **final
outcomes only** — Journey Paused, Journey Continued/Resumed, Journey Ended —
dated, neutral, reasonless, and without identifying who initiated anything
(the nameless-pair principle of DR-ZYRA-142 continues). Internal audit
history may record actors; the shared Timeline is not a blame ledger.

## 9. Guardian behaviour

Unchanged in spirit (AD-081): a pause negotiation is a whisper between the
two. Guardian surfaces read only the neutral state ("Journey awaiting a
decision" / "Journey paused") with no actor identity, no requester/initiator
fields, and no Guardian action while the Journey is locked.

## 10. Notifications

Calm, decision-focused, one per decision point, routed through the existing
preference gate: "A Journey needs your decision" · "Your continuation request
has been answered" — with no sensitive Journey detail on the lock screen and
no nagging. The in-app badge/state carries the rest.

## 11. Deadline — OPEN FOUNDER DECISIONS

The decision pages carry a response deadline **architecturally**: a single
configurable window source (`zyra_pause_decision_window()`, currently NULL)
with *approaching* and *expired* states testable in the developer matrix. No
ratified duration exists, so, deliberately:

- **no duration is set**;
- **nothing auto-pauses, auto-continues, auto-resumes or auto-ends** on
  expiry;
- the countdown appears on the decision pages only once a duration is
  ratified.

Open for the Founder (tracked in OA-ZYRA-261): the exact duration; the
outcome when the pause responder never answers; the outcome when the original
requester never answers a continuation request.

## 12. Navigation and lock integrity

During any pending state the Journey stays in **Active** with an "awaiting a
decision" label; opening it routes directly to the waiting/decision page; the
normal stage is not interactable beneath, and deep links, stale screens or
old clients cannot bypass the lock (server refusal + CAS version). Timeline
and View Profile remain accessible per existing approved read rules.

## 13. Developer controls

One global test-state owner (`ZyraDevScenario.pauseScenario`) drives the real
Connections/Journey readers through 13 independent states — Active; pause
requester waiting; pause responder decision; continuation requester waiting;
continuation responder decision; mutually paused; resume requester waiting;
resume responder decision; resumed; ended from the flow; deadline
approaching; deadline expired (no auto-outcome); paused-cap conflict — with
Basic / ZYRA One as the existing separate plan axis (covering the Founder's
fourteenth variant requirement without duplicated fake states). Actions
mutate the real underlying test state; Reset returns everything to Active,
version zero, no episode.

## 14. Interaction summary

| Situation | Result |
|---|---|
| A requests pause | Journey locks, stays Active-counted; B gets the decision page |
| B agrees to pause | Paused for both; slot freed now; both hold Request Resume |
| B ends | Ended for both, ordinary End rules — even though A asked only to pause |
| B requests to continue | Still Active-counted and locked; decision returns to A |
| A continues | Unlocked at the exact prior stage; nothing lost, nothing recalculated |
| A confirms pause | Paused for both; slot freed now |
| Either at Paused requests resume | Other person: Agree to Resume · Keep Paused · End |
| Paused-cap full on settling | Refused before movement; Journey stays Active + locked; clear explanation and manage paths |
| Deadline reached | Nothing automatic — Founder rule pending (§11) |
| Stale page / double tap | CAS refusal; re-fetch the winning state |

## 15. Implementation status (2026-08-25)

Client, developer matrix and staged server machine are code-complete and
verified (32/32 focused + 392/392 full Flutter tests, analyzer clean,
`zyra_check` clean, iOS simulator build PASS) — see the as-built handover for
files, SHA-256 evidence and probes (22/22 hashes independently re-verified by
Fable on disk, 2026-08-25). The database migration
(`20260825120000_shared_pause_decision_state_machine.sql`) is **staged and
deliberately NOT applied**: live production pause requests fail truthfully
until the Founder authorises application, after which Codex runs the focused
SQL suite and live probes and updates the handover, and the Architecture
Reviewer examines the transition, lock ordering, privacy projection and
rollback policy independently. One legacy live pause row converts to neutral
mutual Paused on application.

## 16. Version History

| Version | Date | Changes |
|---------|------|---------|
| V1 | 2026-07-04 | Initial specification. One-only entitlement; per-combination slot behaviour; Auto-End on blocked resume; 30-day timer. |
| V2 | 2026-08-12 | Both plans pause, caps 5/10 (DR-ZYRA-138). All automatic endings removed. Slot model unified. |
| V3 | 2026-08-15 (amended 08-18) | Shared Pause Holds (DR-ZYRA-170): personal holds, mirrors, lift-your-own-only. DR-ZYRA-206 confirmations. |
| **V4** | **2026-08-25** | **Shared Pause Decision (DR-ZYRA-215).** Personal holds retired. Request Pause opens a locked, Active-counted decision; equal three-way responses; continuation round; slot moves only at settled Pause; symmetric mutual Request Resume returns; final-outcome-only Timeline; neutral Guardian state; configurable deadline with all expiry outcomes reserved for the Founder; 13-state developer matrix. Server machine staged, unapplied. |

---

*ZYRA Journey Suspension Specification — CURRENT_VERSION_V4 — 2026-08-25*
