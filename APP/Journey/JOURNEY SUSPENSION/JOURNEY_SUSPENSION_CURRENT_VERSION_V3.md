# ZYRA — Journey Suspension Specification

**Version:** V3
**Status:** CURRENT_VERSION — Founder-ratified 2026-08-15; confirmation and response language amended 2026-08-18 (DR-ZYRA-206)
**Date:** 2026-08-18
**Owner:** ZYRA Product Governance
**Governing Documents:**
  ZYRA Product Specification (canonical relationship lifecycle)
  DR-ZYRA-121 — Journey Lifecycle redesign (journey_attempts, no automatic endings)
  Entitlements matrix, Founder-approved 2026-08-09 (`SOURCE/lib/data/zyra_entitlements.dart`)
  DR-ZYRA-142 — the pause package (time-honesty, one-shot ready note, nameless Timeline pair)
  DR-ZYRA-170 — Shared Pause Holds (this version's subject)
  DR-ZYRA-206 — Deliberate Pause/End confirmation and response experience
  AD-081 — Capability Independence Principle · AD-082 — State Integrity Principle
**Supersedes:** JOURNEY_SUSPENSION_2026-08-15_V2.md (archived; was dated 2026-08-12)

---

## 0. What changed since V2, and why

One Founder decision reshaped the model (2026-08-15, the shared-pause design
round): *"I want the pause to feel like a shared Journey state, not one person
having power over the other."* V2's model had one pauser holding the only key —
and the key-holder's resume re-activated the Journey for both people without
the other's say. Two structural imbalances, both removed:

**A pause is now a PERSONAL HOLD (DR-ZYRA-170):**

1. Either party may place a hold — the same "Pause Journey" verb, whoever
   presses it. If the other side already holds, yours is a **mirror**
   (`also_paused_by`).
2. The Journey rests while **any** hold exists.
3. Each person lifts **only their own** hold. Nobody resumes anybody else.
   The unilateral "Request Resume" concept remains retired; the non-holder's
   one-shot **Request Continue** is a calm readiness message, not permission
   to lift the holder's pause.
4. Lifting yours while theirs stands is also a standing readiness signal
   (`pause_nudged_at` is set; the existing `pause_nudge` notification carries
   it). The same one-shot field carries Request Continue for a person who has
   not placed their own hold.
5. The pause lifecycle now **speaks**: `journey_paused` (you've been paused
   on — previously discovered by opening the app), `journey_also_paused` (they
   rest too), `journey_continued` (the last hold lifted — the silent
   re-activation is gone).

V2's stale implementation warning in §5 is also corrected: the
pause-frees-the-slot rule and plan-aware Active caps were **built** on
2026-08-12 (migrations `pause_frees_active_slot` + 
`plan_aware_active_journey_limit`; journey suite sections J and K hold them).

---

## 1. Architectural Framing

Journey Suspension remains a **behavioural sub-state of Active Journey**
(AD-082). What changed is its internal shape: not one flag but up to two hands.

```
Active Journey
  ├── Full Activity (conversation open, stages advance)
  └── Paused (conversation paused, stages frozen)
        ├── one hold  — suspended_by set
        │     ├── holder lifts        → Full Activity (journey_continued)
        │     ├── other pauses too    → two holds (journey_also_paused)
        │     ├── other requests Continue once (pause_nudge)
        │     └── either Ends         → Ended (always free)
        └── two holds — suspended_by + also_paused_by set
              ├── second hand lifts   → one hold (their ready signal stands)
              ├── primary hand lifts  → one hold, PROMOTED (their hold,
              │                          their original hold time)
              └── either Ends         → Ended
```

## 2. Terminology

| Product term | Architectural / storage term |
|-------------|------------------------------|
| Pause Journey | first hold — `suspend_journey` sets `suspended_by` |
| Pause too | mirror hold — `suspend_journey` sets `also_paused_by` |
| Paused by you / by them / **by both of you** | which hands hold |
| Resume Journey | `resume_journey` lifts the **caller's own** hold |
| Request Continue | the never-held person's one-shot readiness message (`nudge_paused_journey`) |

Storage still says `suspended_*` on `matches` and `paused_*` on
`journey_attempts`; both tables now also carry `also_paused_by/_at`. The
constraint `matches_also_pause_requires_primary` guarantees a second hold never
exists without a first, and `matches_holds_distinct` that they are never the
same hand.

## 3. Suspension Entitlement

**Both plans may pause.** The differentiator is the cap — now counted over
**holds you currently hold, either column** (a mirror is your hold and counts
toward your plan):

| Plan | Paused holds held at once |
|------|---------------------------|
| ZYRA Basic | 5 |
| ZYRA One | 10 |

Enforced server-side in `suspend_journey`; at the cap it raises
`paused_limit_reached` (Basic sees the upgrade offer, One the honest ceiling).
A mirror at the cap receives the same refusal — ratified with the shared-holds
design. Journeys paused *at* you by the other party still never consume your
cap unless you choose to also hold them.

## 4. Suspension Entry

Either Seeker may pause from the Journey view or the Connections card; the
non-holder on an already-paused Journey may **Pause too** from the card's
response pair. Pause and Pause too open a dedicated full-screen confirmation;
the hold is written only after confirmation. First hold: rows and conversation pause exactly as V2, a new
episode resets the ready flag, and the **other party is notified**
(`journey_paused` — "A pause, not an ending"). Mirror: `also_paused_by` set on
both rows, no Journey-level state change, no second Timeline event, and the
first pauser is notified (`journey_also_paused` — "Resting together").
Repeat taps from a hand already holding are idempotent no-ops.

## 5. Slot Behaviour

One rule, both plans: **a paused Journey does not consume an Active slot for
either party** — built and suite-held since 2026-08-12 (sections J/K: pause
with one person, begin with another; the final lift back is refused by name
while a party is busy elsewhere). Mirroring changes nothing here — the slot
was already free. There is no Auto-End in any branch.

## 6. Suspension State

- Connections → Paused Journeys reads **"Paused by you" / "Paused by
  ‹name› " / "Paused by both of you"**, with DR-ZYRA-142's time-honesty line
  after 30 days.
- The HOLDER's card: **Resume Journey** (lifts their own hold only).
- The NON-HOLDER's response rail: **Pause too | Request Continue | End
  Journey**, with waiting (no button) an equally legitimate answer. Request
  Continue becomes the quiet fact "Continue requested" after its confirmed
  one-shot write.
- Pause and End never write from the first action tap. Each opens a separate
  confirmation screen, keeps that screen open on failure, and follows success
  with an outcome screen and **Return to Connections**.
- Conversation paused; history preserved; stages frozen; no Family Review
  windows open while paused. Caps per §3.

## 7. Timeline Behaviour

Unchanged mechanism, one clarification: the trigger writes `journey_paused`
only when `suspended_by` goes null→set and `journey_continued` only set→null
while active — so **mirrors and promotions write nothing**, and the Timeline
keeps exactly one nameless paused/continued pair per episode regardless of how
many hands held (verified against the live trigger; suite checks 87/91).

## 8. Conversation Behaviour

As V2: paused with the first hold, reopened by the final lift, history intact
throughout, closed on End.

## 9. Guardian Behaviour During Suspension

Unchanged (AD-081), and deliberately: **no Guardian notification exists for any
pause event** — first hold, mirror, ready signal, or continuation. A pause is a
whisper between the two, not a family event. Main Guardians can still read the
Timeline, which is precisely why the pair stays nameless.

## 10. ZYRA Intelligence During Suspension

Unchanged: nothing generated for a paused Journey.

## 11. Notification Summary

| Event | Who is told | Type |
|-------|-------------|------|
| First hold placed | the other party | `journey_paused` |
| Mirror placed | the first pauser | `journey_also_paused` |
| Request Continue (never-held person, one per episode) | the holder | `pause_nudge` |
| A hand lifts while the other holds | the remaining holder | `pause_nudge` (the lift IS the signal) |
| Final hold lifts | the other party | `journey_continued` |
| Refused resume (busy elsewhere / terminal) | resuming Seeker, in-screen | copy states the Journey is intact |

All three new types route to Connections like every other Journey event
(`sectionFor`, DR-ZYRA-154 dots included).

## 12. Resume Behaviour — SUPERSEDES V2 §12

**12.1 Who may lift what:** each Seeker lifts **only their own hold**.
`resume_journey` raises `no_hold_to_lift` for a caller holding nothing. The
never-held person's affordances are Pause too, the one Request Continue
message, End Journey, or simply waiting.

**12.2 Lift outcomes:**
1. **Second hand lifts** (their `also_paused_by`): Journey stays paused on the
   primary; the lifter's ready signal stands (`pause_nudged_at`), the holder is
   told. No eligibility checks — nothing activates.
2. **Primary lifts while the second stands:** **promotion** — the second hold
   becomes the (only) hold, keeping its original hold time. Journey stays
   paused; the new sole holder is told the lifter is ready. No checks, no
   Timeline event.
3. **Final hold lifts:** eligibility unchanged from V2 — blocks/Tier-0 refuse
   terminally (`not_eligible_to_continue`); either party busy elsewhere refuses
   by name (`self_in_active_journey` / `other_party_in_active_journey`), the
   Journey **stays paused, nothing lost**. Otherwise: pause cleared on both
   rows, conversation reopened, `journey_continued` milestone and notification.

## 13. End While Paused

Either Seeker may End at any time, regardless of who holds what. End first
opens a dedicated full-screen confirmation. The write occurs while that screen
remains visible; a failure leaves the choice available with an honest message.
A confirmed end clears the pause shape, notifies the other Seeker, and opens a
solid outcome screen before Return to Connections. The closure moment plays
only for an end that actually happened (DR-ZYRA-167/206).

## 14. Interaction Summary — REPLACES V2 §14

| Situation | Result |
|-----------|--------|
| Any Seeker confirms Pause, under their cap | Journey rests; the other is told and answers freely: Pause too · Request Continue · wait · End |
| Non-holder confirms Pause too | Paused by both; each Resume lifts its own hand only |
| Non-holder chooses Request Continue | Confirmed one-shot message; Journey waits for the holder to lift their own pause |
| At the cap (5/10) — first hold or mirror | `paused_limit_reached`; the honest refusal |
| Second hand lifts | Still paused; their ready signal stands with the holder |
| Primary lifts while second stands | Still paused — promoted; they now simply hold, as anyone might |
| Final hold lifts, other party free | Journey continues; the other party is told |
| Final lift, other party busy elsewhere | Refused by name; stays paused; nothing lost |
| Block/Tier-0 arisen | Refused, terminal; End is the only exit |
| Nobody acts, indefinitely | Stays paused indefinitely — no timer, no auto-end |

## 15. Version History

| Version | Date | Changes |
|---------|------|---------|
| V1 | 2026-07-04 | Initial specification. One-only entitlement; per-combination slot behaviour; Auto-End on blocked resume; 30-day timer. |
| V2 | 2026-08-12 | Both plans pause, caps 5/10 (DR-ZYRA-138). All automatic endings removed. Slot model unified. |
| V3 | 2026-08-15 | **Shared Pause Holds (DR-ZYRA-170).** Pause becomes a personal hold: either party may hold, mirrors via `also_paused_by`, lift-your-own-only resume with promotion, three notification types end the silent pause and silent re-activation, "Request Resume" retired product-wide. Cap counts holds held. §5's stale implementation warning corrected — slot freeing was built 2026-08-12. |
| V3 amendment | 2026-08-18 | **DR-ZYRA-206.** Pause/Pause too and End gain truthful full-screen confirmation and outcome screens. The non-holder response language becomes Pause too / Request Continue / End Journey; Request Continue is explicitly a readiness message and never lifts another person's hold. |

---

*ZYRA Journey Suspension Specification — CURRENT_VERSION_V3 — amended 2026-08-18*
