# ZYRA — Journey Suspension Specification

**Version:** V1
**Status:** CURRENT_VERSION
**Date:** 2026-07-04
**Owner:** ZYRA Product Governance
**Governing Documents:**
  ZYRA Product Specification V3 (canonical relationship lifecycle)
  ZYRA Journey Capability Grant Rules V2
  AD-081 — Capability Independence Principle
  AD-082 — State Integrity Principle
**Resolves:** Finding 1 (Pause in Basic ↔ One matches), Finding 6 (Pause in One ↔ One matches)

---

## 1. Architectural Framing

### 1.1 Canonical Lifecycle Position

Journey Suspension is a **behavioural sub-state of Active Journey**. It is not an independent relationship state. Per AD-082 (State Integrity Principle):

- The relationship remains in the **Active Journey** canonical state while suspended
- Suspension is a constraint on behaviour within Active Journey — it is not a lifecycle transition to a new state
- The suspended Journey may resume into full Active Journey or transition to Ended

```
Active Journey
  ├── Full Activity (conversation open, timeline running)
  └── Suspended (conversation closed, timeline paused)
        ├── Resume → Full Activity
        └── End → Completed / Ended
```

### 1.2 Feature-State Covenant (per Product Spec V3, Section 0.9)

| Question | Answer |
|----------|--------|
| Which canonical state does this feature apply to? | Active Journey |
| Does it change the relationship state? | No — Active Journey remains the state |
| Does it consume or release a Journey slot? | Slot release depends on suspension type — see Section 4 |

---

## 2. Terminology

| Product term | Architectural term |
|-------------|-------------------|
| Pause Journey | Journey Suspension — entry |
| Paused Journey | Suspended Active Journey |
| Resume Journey | Journey Suspension — exit (resume path) |
| Paused Journeys (ZYRA One tab) | Suspended Journey archive |

"Journey Suspension" is the architectural term used in specifications. "Pause" is the product-facing term used in screen and UX design.

---

## 3. Suspension Entitlement

Journey Suspension is available to Seekers whose account holds a **ZYRA One entitlement**.

- A Seeker with ZYRA Basic entitlement **cannot** initiate Journey Suspension.
- A Seeker with ZYRA One entitlement **can** initiate Journey Suspension at any time during an Active Journey.
- Suspension entitlement is assessed at the point of initiation. The other Seeker's entitlement does not affect whether suspension can be initiated.

---

## 4. Suspension Entry

### 4.1 How Suspension Is Initiated

A ZYRA One Seeker may suspend their Active Journey at any time from within the Journey view. Suspension is immediate on confirmation.

### 4.2 Pre-Suspension Notification

Before suspension completes, the initiating Seeker receives a confirmation screen summarising:
- What suspension means for their slot
- What the other Seeker will experience
- How to resume

### 4.3 Suspension Takes Effect

On confirmation:
- The Journey enters Suspended state
- The conversation closes immediately for both Seekers
- The Timeline freezes at the current position
- Both Guardians receive a suspension notification (see Section 9)

---

## 5. Slot Behaviour During Suspension

Slot behaviour differs based on the entitlement combination of the two Seekers in the Journey.

### 5.1 ZYRA One ↔ ZYRA Basic (Finding 1)

One Seeker (A) holds ZYRA One and initiates suspension. The other Seeker (B) holds ZYRA Basic.

| Account | Entitlement | Slot on suspension |
|---------|------------|-------------------|
| Seeker A (initiator) | ZYRA One | Slot freed immediately. Journey moves to Seeker A's Suspended Journeys. |
| Seeker B | ZYRA Basic | Slot freed immediately. |

**Rationale:** ZYRA Basic Seekers hold only one Journey slot. Holding that slot against an indefinitely suspended Journey — initiated by the other party — would effectively block the Basic Seeker's only opportunity. Freeing the slot respects the one-Journey-at-a-time philosophy while not punishing the Basic Seeker for the One Seeker's decision to suspend.

**Consequence for Seeker B:** With their slot freed, Seeker B may begin a new Active Journey with a different Potential Journey.

**Auto-End rule:** If Seeker B begins a new Active Journey while Seeker A's Journey is suspended, the suspended Journey between A and B **auto-Ends** at the moment Seeker A attempts to resume. Seeker B cannot simultaneously hold an Active Journey and have a suspended Journey reinstated. Seeker A is notified that the Journey has ended.

**If Seeker B begins no new Journey:** The suspended Journey may be resumed by Seeker A at any time. On resume, if Seeker B's slot is available, the Active Journey reinstates for both.

### 5.2 ZYRA One ↔ ZYRA One (Finding 6)

Both Seekers hold ZYRA One. Either may initiate suspension independently.

**When Seeker A (One) suspends:**

| Account | Slot on suspension |
|---------|-------------------|
| Seeker A (initiator) | Slot freed immediately. Journey moves to Seeker A's Suspended Journeys. |
| Seeker B | Journey enters Peer-Suspended state. Slot **remains occupied**. |

**Rationale:** Both Seekers have ZYRA One. Seeker B has the ability to independently Pause or End the Journey if they wish to free their slot. Automatically freeing Seeker B's slot on Seeker A's suspension would be inconsistent — Seeker B may wish to hold the Journey in place. Seeker B retains full agency to resolve this on their own terms.

**Seeker B's options while the Journey is Peer-Suspended:**
1. **Wait** — hold the slot and wait for Seeker A to resume.
2. **End Journey** — permanently end the Journey and free their slot.
3. **Suspend independently** — Seeker B may also Pause the Journey. Both slots are then freed (Full Suspension — see Section 5.3).

**If Seeker A resumes:**
- If Seeker B has not Ended the Journey → Active Journey reinstates for both.
- If Seeker B has Ended the Journey → reinstatement is not possible. Seeker A is notified.

### 5.3 Full Suspension (One ↔ One — both suspend)

When both Seekers in a One ↔ One Journey have independently suspended:

| Account | Slot |
|---------|------|
| Both Seekers | Slots freed |
| Journey | Held in Full Suspension |

Either Seeker may resume at any time. On resume, if the other Seeker's slot is available, the Active Journey reinstates. If the other Seeker has started a new Active Journey, the resuming Seeker is notified and the Journey auto-Ends.

**Full Suspension Auto-End Timer:** A Journey in Full Suspension (both slots freed) that receives no resume action within **30 days** automatically transitions to Ended. Both Seekers and their Guardians are notified 7 days before the auto-End.

---

## 6. Suspension State

### 6.1 Active Suspension (Initiator's Slot Freed)

The suspended Journey is visible to the initiating Seeker in their **Suspended Journeys** tab.

Properties while suspended:
- Journey slot freed for initiating Seeker
- Conversation closed
- Timeline frozen (no new milestones, no time elapsed)
- Journey progress preserved exactly
- Guardian Network activities unaffected (Guardian's capabilities do not change)

### 6.2 Peer-Suspended State (One ↔ One — only one suspend)

The non-initiating Seeker's Active Journey slot remains occupied. From their view:
- An active suspension banner appears on the Journey
- Conversation is closed
- Timeline frozen
- Seeker B may End the Journey or wait

### 6.3 Unlimited Suspended Journeys

A ZYRA One Seeker may hold unlimited Journeys in Suspended state simultaneously. Only one Journey may be in Full Activity at any time.

---

## 7. Timeline Behaviour

| Phase | Timeline |
|-------|----------|
| Active Journey (Full Activity) | Running — milestones advance |
| Suspended (either type) | Frozen — no milestones advance, no elapsed time added |
| Resumed | Continues from exact freeze point |
| Ended | Preserved as read-only archive |

Time spent in suspension does not count towards Journey duration. When a Journey resumes, the Timeline continues from the exact position at which it froze.

ZYRA does not penalise a Journey's stage progression for time spent suspended.

---

## 8. Conversation Behaviour

| Phase | Conversation |
|-------|-------------|
| Full Activity | Open — both Seekers may send and receive messages |
| Suspended | Closed — no messages may be sent or received by either Seeker |
| Resumed | Reopened — conversation history intact |
| Ended | Permanently closed — archive preserved (soft-delete) |

On suspension: the conversation view is replaced by a suspension notice for both Seekers.

On resume: the full conversation history is visible. A system message appears marking the suspension and resume timestamps.

---

## 9. Guardian Behaviour During Suspension

### 9.1 Notification on Suspension

Both Guardians receive a notification when their linked Seeker's Journey suspends:
- Guardian of the initiating Seeker: "Journey paused by [Seeker name]."
- Guardian of the non-initiating Seeker: "Journey paused. Waiting for the other party to resume."

### 9.2 Guardian Access While Suspended

| Capability | During Suspension |
|-----------|-----------------|
| View Journey progress | ✓ — suspended state visible |
| View conversation | ✓ — read-only archive visible; no new messages |
| Family Review Period actions | N/A — timeline frozen; no new stages to review |
| Guardian Network | Unchanged — Guardian's entitlement-based capabilities unaffected by Journey suspension |
| Raise concern | ✓ |

Guardian capabilities are not revoked by Journey suspension. The Guardian's entitlement-based capabilities (per Journey Capability Grant Rules V2) remain active throughout.

### 9.3 Notification on Resume

Both Guardians receive a notification when the Journey resumes.

### 9.4 Notification on Auto-End

Both Guardians receive the 7-day warning and the auto-End notification alongside the Seekers.

---

## 10. ZYRA Intelligence Behaviour During Suspension

| Feature | During Suspension |
|---------|-----------------|
| Recommendations | Suspended — no active recommendation generation for this Journey |
| Insights | Suspended — no new Insights generated |
| Summaries | Not generated during suspension |
| Guardian AI Summary | Not generated or delivered during suspension |
| Adaptive questions | Not generated during suspension |
| Topic suggestions | Not available during suspension |

ZYRA Intelligence resumes full operation when the Journey enters Full Activity.

---

## 11. Notification Behaviour

| Event | Notified parties |
|-------|-----------------|
| Suspension initiated | Both Seekers, both Guardians |
| Peer-Suspended (Seeker B's slot occupied) | Seeker B, Seeker B's Guardian |
| Seeker B Ends a Peer-Suspended Journey | Seeker A, Seeker A's Guardian |
| Full Suspension (both paused) | Confirmation to both Seekers, both Guardians |
| Auto-End warning (7 days before) | Both Seekers, both Guardians |
| Auto-End | Both Seekers, both Guardians |
| Resume | Both Seekers, both Guardians |
| Resume blocked (other Seeker in new Journey) | Resuming Seeker, resuming Seeker's Guardian |

Notification content, delivery channel, and timing are defined in the ZYRA Notification Specification (separate document — to be specified).

---

## 12. Resume Behaviour

### 12.1 Who May Resume

Only the Seeker who initiated suspension may resume. The non-initiating Seeker cannot force a resume.

In Full Suspension (One ↔ One, both paused), either Seeker may resume independently. The first to resume reinstates the Journey for both, provided the other's slot is available.

### 12.2 Resume Flow

On tapping Resume:
1. ZYRA checks whether the other Seeker's Journey slot is available.
2. If available: Journey reinstates immediately into Full Activity.
3. If not available (other Seeker has a new Active Journey): Journey auto-Ends. Resuming Seeker is notified.

### 12.3 Post-Resume State

On successful resume:
- Conversation reopens with full history
- Timeline continues from freeze point
- Both Guardians notified
- ZYRA Intelligence resumes

---

## 13. End Journey While Suspended

### 13.1 Initiating Seeker Ends (from Suspended Journeys)

The suspending Seeker may End the Journey at any time from their Suspended Journeys tab.

- Journey transitions to Ended
- Both Seekers notified
- Both Guardians notified
- Slots freed (initiating Seeker's slot was already freed on suspension; other Seeker's slot is freed on End)

### 13.2 Non-Initiating Seeker Ends (Peer-Suspended, One ↔ One)

In Peer-Suspended state (One ↔ One), Seeker B may End the Journey to free their occupied slot.

- Journey transitions to Ended
- Seeker A notified (their suspended Journey has ended; resume is no longer possible)
- Both Guardians notified

### 13.3 Auto-End (Full Suspension Timer)

After 30 days of Full Suspension with no resume:
- Journey auto-transitions to Ended
- Both Seekers and Guardians receive the End notification
- Slots confirmed freed (both were already freed in Full Suspension)

---

## 14. Suspension Interaction Summary

| Entitlement combination | A initiates suspension | A's slot | B's slot | B's options |
|------------------------|----------------------|----------|----------|-------------|
| A: ZYRA One / B: ZYRA Basic | A suspends | Freed | Freed | Start new Journey; Auto-End if A resumes while B is in new Journey |
| A: ZYRA One / B: ZYRA One | A suspends | Freed | Occupied (Peer-Suspended) | Wait, End, or independently suspend |
| A: ZYRA One / B: ZYRA One (both suspended) | Full Suspension | Freed | Freed | Either may resume; Auto-End at 30 days |

---

## 15. Version History

| Version | Date | Changes |
|---------|------|---------|
| V1 | 2026-07-04 | Initial specification. Resolves Finding 1 (Basic ↔ One suspension slot behaviour) and Finding 6 (One ↔ One suspension slot behaviour). Full suspension model defined. |

---

*ZYRA Journey Suspension Specification — CURRENT_VERSION_V1 — 2026-07-04*
