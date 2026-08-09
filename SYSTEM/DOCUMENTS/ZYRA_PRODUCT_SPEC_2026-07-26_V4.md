# ZYRA MASTER PRODUCT SPECIFICATION

**Version:** V4
**Status:** CURRENT_VERSION
**Date:** 2026-07-26
**Supersedes:** ZYRA_PRODUCT_SPEC_2026-07-26_V3.md
**Scope:** Parts 0–3 — Canonical Lifecycle through Active Journey Stage
**Governing References:** ZYRA Journey Capability Grant Rules V1, AIOS Capability Resolution Rules V1
**Governing Principles:** AD-081 Capability Independence Principle, AD-082 State Integrity Principle
**Architectural Reviewers:** Architecture & Governance (ChatGPT), Implementation Lead (Claude)

---

## CONTENTS

- Part 0: Canonical Relationship Lifecycle
- Part 1: Foundation & Subscription System
- Part 2: Browse Stage & Potential Journey Stage
- Part 3: Active Journey Stage & Progression

---

# PART 0 — CANONICAL RELATIONSHIP LIFECYCLE

## 0.1 Governing Principle — State Integrity (AD-082)

> Before introducing a new lifecycle stage or architectural object, it must be demonstrated to represent a durable state — one that is occupied for a meaningful period, has properties and behaviours distinct from adjacent states, and cannot be reduced to a transition event, a user interaction, a UI flow, or an implementation detail. If it does not meet this standard, it belongs in product or interaction behaviour, not in the architectural model.

This principle governs all additions to the relationship lifecycle. All existing states in this document have been validated against it.

---

## 0.2 Canonical Relationship States

Every relationship between two Seekers exists in exactly one of the following states at any given time:

```
No Relationship
      ↓  [Match event — mutual Consider]
Potential Journey
      ↓  [Both Seekers begin + Pre-Journey Ritual completes]
Active Journey
      ↓  [Deliberate end, auto-pause expiry, or Nikah]
Completed / Ended
```

These are the only architectural relationship states. All other concepts — screens, notifications, prompts, reminders, activation sequences, and invitation flows — describe behaviour around these states. They are not states themselves.

---

## 0.3 State Definitions

### No Relationship

No connection exists between the two Seekers. Either:
- Neither has Considered the other, or one has Considered but the other has not yet reciprocated.
- A previous Potential Journey or Active Journey has ended.

### Potential Journey

A passive record of mutual interest. Created when two Seekers Consider each other (the Match event).

**Properties:**
- No Journey slot consumed for either Seeker
- No conversation exists
- No obligations exist for either party
- Duration is indefinite — no expiry timer
- May coexist with an Active Journey for either or both Seekers
- A Seeker may hold multiple simultaneous Potential Journeys

Either Seeker may silently remove a Potential Journey at any time. This returns the relationship to No Relationship.

### Active Journey

The live marriage journey between two Seekers. Created when both Seekers choose to begin a Potential Journey and the Pre-Journey Ritual completes.

**Properties:**
- One Journey slot consumed per Seeker
- Conversation is open
- Timeline is running
- Guardian capabilities are active per each account's ZYRA One entitlement (AIOS grant)

An Active Journey may be Paused (ZYRA One), Ended, or progress to completion.

### Completed / Ended

The terminal state. The Active Journey has concluded.

- **Completed:** The Journey has reached its natural conclusion (Nikah).
- **Ended:** Either Seeker deliberately ended the Journey, or the Journey was auto-paused and not resumed within the defined period.

Journey slot freed for both Seekers immediately on entry to this state.

---

## 0.4 Transition Rules

| From | To | Trigger |
|------|----|---------|
| No Relationship | Potential Journey | Mutual Consider (Match event) |
| Potential Journey | Active Journey | Both Seekers choose to begin + Pre-Journey Ritual completes |
| Potential Journey | No Relationship | Either Seeker removes the Potential Journey |
| Active Journey | Paused (sub-state) | ZYRA One Seeker pauses (see Part 3, Section 5) |
| Paused | Active Journey | ZYRA One Seeker resumes |
| Active Journey | Completed / Ended | Deliberate End, auto-pause expiry, or Nikah completion |

---

## 0.5 Match Is an Event, Not a State

A **Match** is the event that occurs when two Seekers have both Considered each other. Match creates a Potential Journey. Match is not a lifecycle stage. Match does not open a conversation. Match does not consume a Journey slot.

---

## 0.6 Journey Slot Rules

| Relationship State | Journey Slot |
|-------------------|-------------|
| No Relationship | No slot consumed |
| Potential Journey | No slot consumed |
| Ritual in progress | Slot reserved for both Seekers |
| Active Journey | One slot consumed per Seeker |
| Paused Active Journey | Slot behaviour in mixed-tier Journeys: pending resolution (Finding 1/6) |
| Completed / Ended | Slot freed immediately |

Each Seeker's slot is managed independently. A Seeker's slot is freed when their Active Journey ends, regardless of the other Seeker's Journey state.

---

## 0.7 Conversation Rule

Conversation belongs exclusively to Active Journey. No conversation exists:
- During a Potential Journey
- During the Pre-Journey Ritual
- After an Active Journey ends

---

## 0.8 Pre-Journey Ritual

The Pre-Journey Ritual is the activation sequence that transitions a Potential Journey into an Active Journey. It is part of the transition mechanism — not an independent relationship state.

On Ritual completion: Active Journey begins. Conversation opens. Timeline starts. Guardian capabilities activate.

Full Ritual specification: see PRE-JOURNEY RITUAL/Summary.md.

**Ritual sequence:**
1. Salam Exchange — both Seekers must send before Phase 1 unlocks
2. Phase 1 Questions — AI-chosen, simultaneously revealed to both Seekers
3. Phase 2 Questions — negative-focused, simultaneously revealed to both Seekers
4. Phase 3 Questions — user-chosen, simultaneously revealed to both Seekers

Conversation opens only after Phase 3 is complete.

---

## 0.9 Feature-State Covenant

Every new relationship feature proposed for ZYRA must explicitly address the following three questions before it may be implemented or documented:

| Question | What it prevents |
|----------|-----------------|
| **1. Which canonical relationship state(s) does this feature apply to?** | Implicit creation of unlisted states |
| **2. Does this feature change the relationship state, or does it operate within an existing state?** | Lifecycle drift via UI-layer behaviour being treated as architectural state |
| **3. Does this feature consume or release a Journey slot?** | Slot accounting errors across tier combinations |

A feature that cannot answer these three questions without introducing a new relationship state must be reviewed against the State Integrity Principle (AD-082) before proceeding. If the proposed object does not represent a durable state, it must be reclassified as behaviour, a UI interaction, or a transition mechanism — not a lifecycle stage.

**Examples of objects that are NOT canonical states:**
- Invitation, Pending Invitation, Waiting Acceptance — these are user actions within Potential Journey
- Soft Match, Waiting Conversation — these are representations within Potential Journey
- Any named UI flow or screen sequence — these are transition mechanisms, not states

**Downstream reference rule:** All documents that describe relationship behaviour — Guardian Architecture, Journey Availability, AI Tiering, Profile Unlock, Family Stage, screen specifications — must consume the canonical lifecycle defined in this specification rather than maintaining parallel state definitions. If a downstream document needs to describe a new relationship concept, it must reference the relevant canonical state and describe behaviour within it.

---

# PART 1 — FOUNDATION & SUBSCRIPTION SYSTEM

## 1. Introduction

### Purpose

ZYRA is a marriage platform designed specifically for Muslims seeking a serious path towards marriage.

Unlike traditional dating applications, ZYRA is designed around commitment, transparency, family involvement and Islamic values.

The platform encourages users to focus on one genuine marriage journey at a time rather than maintaining multiple conversations with multiple people.

Every feature within ZYRA should support this philosophy.

---

## 2. Core Philosophy

Every future feature should follow these principles.

### 2.1 Marriage First

ZYRA is not designed for casual dating.

The objective is always:

```
Discover → Communicate → Involve Family → Meet → Marriage
```

### 2.2 One Journey at a Time

Seekers are intentionally limited to one Active Journey at a time.

This encourages users to properly invest time into getting to know one potential spouse before moving on. If a relationship ends respectfully, another journey can begin.

ZYRA One users are not given multiple simultaneous Active Journeys. Instead, ZYRA One improves flexibility by allowing users to Pause their current journey rather than ending it permanently.

### 2.3 Family Involvement

Family is a core part of the platform.

Rather than treating Guardians as optional observers, ZYRA gradually increases family involvement throughout the marriage journey. The platform is designed so that family participation naturally grows over time.

### 2.4 Privacy

Private actions remain private.

Examples include individual Saves, Passes, and Match Actions. Only specifically approved features reveal additional information, and only when mutual interest has been independently established by both parties.

### 2.5 Premium Philosophy

ZYRA One should improve:
- Visibility
- Convenience
- Discovery
- Flexibility

ZYRA One should not encourage behaviour that conflicts with the platform philosophy.

Examples of features intentionally NOT included:
- Unlimited simultaneous conversations
- Multiple simultaneous Active Journeys
- Random boosts that encourage swiping behaviour

---

## 3. User Types

ZYRA currently supports two user roles.

### 3.1 Seeker

**Purpose:** To search for a suitable spouse.

Seekers browse profiles, save profiles, express interest, communicate with matches and progress through the marriage journey.

### 3.2 Guardian

**Purpose:** To represent and support their linked Seeker.

A Guardian is a male guardian who supports a Seeker through their marriage journey in accordance with Islamic guidance.

**Guardian capability model:** Guardian accounts carry identity only. Guardian capabilities are not stored on the Guardian account. They are granted by AIOS per Journey relationship, based on the entitlement held by the Guardian's own account. A Guardian with multiple linked Seekers may simultaneously hold different capability grants for different Journey relationships if their entitlement or the relationship context differs.

Governing document: ZYRA Journey Capability Grant Rules V3. See also: AD-081 — Capability Independence Principle.

---

## 4. Entitlement Structure

ZYRA operates with two account entitlement tiers, available to any ZYRA account holder:
- **ZYRA Basic** — Free (default entitlement for all accounts)
- **ZYRA One** — £34.99 / month (purchasable by any account holder — Seeker or Guardian)

After onboarding, an account operates in its chosen role (Seeker or Guardian). AIOS resolves the capabilities granted to that account based on: its entitlement, its current role, its relationship, and the operational context. The same entitlement grants different capabilities to a Seeker account than to a Guardian account.

See: ZYRA Journey Capability Grant Rules V2, AD-081 — Capability Independence Principle.

---

## 5. Pricing

| Plan | Price |
|------|-------|
| ZYRA Basic | Free |
| ZYRA One | £34.99 / month |

### Annual Billing

Annual subscriptions use a 10-months-paid, 12-months-received model.

| Plan | Annual Price |
|------|-------------|
| ZYRA One (annual) | £349.90 / year |

---

## 6. ZYRA Basic

**Purpose:** The default account entitlement for all ZYRA accounts. Provides a complete, genuine marriage experience. ZYRA Basic is not a trial — it is a full product that supports a complete marriage journey.

This section describes the capabilities granted by ZYRA Basic when the account is operating as a Seeker. Guardian capabilities under ZYRA Basic are defined in Guardian Architecture V4.

### Features

- Create profile, upload profile photos
- Browse up to 50 profiles every 4 hours
- Save up to 10 profiles per day
- Consider up to 10 profiles per day
- Unlimited Potential Journeys (passive — no slot consumed)
- One Active Journey slot
- Pre-Journey Ritual
- Active Journey: conversation, messaging, read receipts
- Standard Profile Unlock on Active Journey creation (see Section 8)
- System intelligence: compatibility calculations, Journey progression, question library, Timeline milestones
- Timeline
- Link a Guardian
- 7-day ZYRA One trial — activates automatically when a Seeker's first Active Journey begins (not on Match)

### Not Available on ZYRA Basic

- Incoming Potentials
- Mutual Save Detection
- Pause Journey / Resume Journey
- Priority Discovery
- Unlimited browsing / saves / likes
- ZYRA Intelligence: Recommendations, Insights, Summaries, adaptive questions, Guardian AI Summary
- Profile Unlock Plus on Active Journey creation

---

## 7. ZYRA One

**Purpose:** The paid account entitlement tier. Purchasable by any ZYRA account holder — Seeker or Guardian. The account role (chosen during onboarding or at purchase) determines how the entitlement is applied by AIOS.

**Price:** £34.99 / month

This section describes the capabilities granted by ZYRA One when the account is operating as a Seeker. Guardian capabilities under ZYRA One are defined in Guardian Architecture V5.

### Included Extended Guardian Entitlement

When a Seeker account holds ZYRA One, the subscription includes **one Extended Guardian entitlement** at no additional cost. The Seeker may assign this included entitlement to any one of their linked Guardians.

- The included entitlement grants the receiving Guardian Extended Guardian capabilities for all their Journey relationships with that Seeker.
- The included entitlement belongs to the Seeker's ZYRA One subscription — it is not permanently attached to one individual Guardian. If the Seeker reassigns it, the previous holder's entitlement reverts to ZYRA Basic.
- A Guardian who does not receive the included entitlement may independently purchase Extended Guardian capabilities (£9.99/month) — see Guardian Architecture V5.

Once AIOS grants the Extended Guardian capability set, behaviour is identical regardless of whether it was received via an included entitlement or an independent purchase. This is an application of AD-081 — Capability Independence Principle.

### Includes Everything in ZYRA Basic, Plus

- Unlimited profile browsing
- Unlimited Saves
- Unlimited Considers
- Incoming Potentials
- Mutual Save Detection
- Pause Journey / Resume Journey
- Unlimited Paused Journeys
- Priority Discovery
- Profile Unlock Plus on Active Journey creation (see Section 8)
- ZYRA Intelligence: Recommendations, Insights, Summaries, adaptive questions, conversation topic suggestions, Guardian AI Summary delivery

### Journey Slot Rules (unchanged from ZYRA Basic)

ZYRA One does not grant multiple simultaneous Active Journeys. One Active Journey per Seeker is the invariant of the ZYRA platform. ZYRA One improves the journey experience through Pause rather than concurrency.

### Guardian Capabilities Under ZYRA One

When a Guardian account holds a ZYRA One entitlement, AIOS grants that Guardian extended Journey-level capabilities for their Journey relationships. A Seeker holding ZYRA One does not determine the Guardian's capability set — each account's capabilities are determined by its own entitlement. See: ZYRA Journey Capability Grant Rules V2, Guardian Architecture V4.

---

## 8. Profile Unlock System

### Manual Unlocks (purchasable — all tiers)

The Profile Unlock system allows Seekers to reveal additional compatibility information before a Match. Manual unlocks operate independently of subscription tier.

| Product | Quantity | Price |
|---------|----------|-------|
| Unlock Profile | 1 profile | £0.99 |
| Unlock Profile | 5 profiles | £2.99 |
| Unlock Profile Plus | 1 profile | £1.99 |
| Unlock Profile Plus | 5 profiles | £4.99 |

*(Unlock Profile Plus additional functionality will be fully specified in a dedicated document.)*

### Automatic Unlock on Active Journey Creation

When an Active Journey begins (Pre-Journey Ritual completes), profiles unlock automatically at the level corresponding to each Seeker's entitlement:

| Seeker's Subscription | Automatic Unlock Received |
|-----------------------|--------------------------|
| ZYRA Basic | Standard Profile Unlock — overall compatibility % and alignment category counts |
| ZYRA One | Profile Unlock Plus — overall compatibility % and full category-level breakdown |

Each Seeker receives their own tier's unlock, independently of the other Seeker's subscription. A ZYRA One Seeker receives Profile Unlock Plus regardless of whether the other Seeker is on ZYRA Basic. A ZYRA Basic Seeker receives the standard unlock regardless of whether the other Seeker is on ZYRA One.

**Duplicate unlock rule:** If a Seeker paid to manually unlock a profile and later begins an Active Journey with that person, the automatic unlock produces no additional effect. The profile was already unlocked. No separate unlock state is tracked — both paid and automatic unlocks produce the same outcome. Users pay for earlier access, not for the communication right.

---

# PART 2 — BROWSE STAGE & POTENTIAL JOURNEY STAGE

## 1. Marriage Workflow

```
Browse
  ↓
Potential Journey
  ↓  [Both Seekers begin + Ritual]
Active Journey
  ↓
Family Stage
  ↓
Meeting
  ↓
Nikah
```

A Match event (mutual Consider) creates a Potential Journey. The Pre-Journey Ritual transitions a Potential Journey into an Active Journey.

---

## 2. Browse Stage

### Purpose

The Browse Stage allows Seekers to discover potential spouses in a simple, clean and distraction-free environment.

### Browse Philosophy

Browse should answer only one question: *"Am I interested enough to learn more?"*

Users first express interest. Additional information becomes available after mutual interest is established.

### Visible Information

The Browse page displays limited profile information only:
- Profile photo
- First name
- Age
- Location

Additional profile information remains hidden until:
- The profile is manually unlocked (see Part 1, Section 8)
- An Active Journey begins with that person

### Profile Unlock Philosophy

The Browse page intentionally does not display an Unlock button. Users should never feel pressured into purchasing unlocks while simply browsing. Users browse naturally first.

### Browse Workflow

```
Browse
  ↓
Save  OR  Consider
  ↓
(Optional) Unlock Profile
```

OR

```
Browse → Consider → Mutual Consider → Match event → Potential Journey created
  → [Both begin + Ritual] → Active Journey → Profiles auto-unlock
```

---

## 3. Save

**Purpose:** Saving a profile does not indicate romantic interest. Save means: *"I would like to come back to this profile later."*

Saving must remain private wherever possible.

### Save Rules

| Group | Combination | Behaviour |
|-------|-------------|-----------|
| 1 | ZYRA Basic ↔ ZYRA Basic | Save is completely private. Neither user is notified. |
| 2 | ZYRA Basic ↔ ZYRA One | If mutual save: ZYRA One user receives Mutual Save Detected. ZYRA Basic user receives nothing. |
| 3 | ZYRA One ↔ ZYRA Basic | Same as Group 2. Only the ZYRA One user receives notification. |
| 4 | ZYRA One ↔ ZYRA One | If mutual save: both users receive Mutual Save Detected. |

A single Save is never revealed. Only mutual Saves may generate a notification, and only for ZYRA One users.

---

## 4. Consider

**Purpose:** A Consider represents genuine interest. A Consider tells the system: *"I would like to pursue this person."*

### Consider Rules

| Group | Combination | Behaviour |
|-------|-------------|-----------|
| 1 | ZYRA Basic → ZYRA Basic | Added to sender's Outgoing Potentials. Receiving user gets nothing. If they later Consider back, Match event occurs and Potential Journey is created. |
| 2 | ZYRA Basic → ZYRA One | ZYRA One user immediately receives Incoming Potential. May Consider Back, Save, or Pass. |
| 3 | ZYRA One → ZYRA Basic | ZYRA Basic user receives nothing. Continues browsing. If they later Consider back, Match event occurs and Potential Journey is created. |
| 4 | ZYRA One → ZYRA One | Both receive Incoming Potentials immediately. May Consider Back, Save, or Pass. |

---

## 5. Incoming Potentials

ZYRA One feature. ZYRA One Seekers immediately see who has already Considered them.

ZYRA Basic Seekers do not receive Incoming Potentials. They discover potential matches through their own browsing.

---

## 6. Outgoing Potentials

Whenever a Consider is sent, the sender sees that profile in their Outgoing Potentials. Allows Seekers to track profiles they have already expressed interest in. Available to all tiers.

---

## 7. Pass

Pass behaves identically for every subscription combination.

When Pass is selected:
- No notification is sent
- No explanation is provided
- The sender is never informed
- The Potential is removed silently
- The profile disappears from the active view

---

## 8. Match Event

A **Match** occurs when two Seekers have both Considered each other.

**A Match is an event. A Match creates a Potential Journey. A Match does not create a conversation. A Match does not consume a Journey slot.**

Immediately on Match:
- A Potential Journey record is created for both Seekers
- The Match appears in each Seeker's Matches section
- No conversation is created
- No Journey slot is consumed
- No Guardian involvement begins

---

## 9. Potential Journey

### State Definition

A Potential Journey is a passive record of mutual interest between two Seekers. It records that both Seekers have Considered each other. Nothing else is implied or activated.

### Properties

- No Journey slot consumed
- No conversation
- No obligations for either party
- No expiry timer
- May coexist with an Active Journey for either or both Seekers
- A Seeker may hold multiple simultaneous Potential Journeys

### ZYRA Surfacing Behaviour

ZYRA surfaces Potential Journeys as candidates when a Seeker's Journey slot is available.

- **ZYRA One:** ZYRA Intelligence ranks and recommends Potential Journeys based on compatibility and activity signals.
- **ZYRA Basic:** Potential Journeys are surfaced without intelligent ranking.

In both cases, the Seeker makes the final decision.

### Activating a Potential Journey

Both Seekers must independently choose to begin. When the second Seeker confirms, the Pre-Journey Ritual begins for both simultaneously.

### Removing a Potential Journey

Either Seeker may remove a Potential Journey at any time. No notification is sent to the other Seeker. The relationship returns to No Relationship state.

---

# PART 3 — ACTIVE JOURNEY STAGE & PROGRESSION

## 1. Active Journey

### Creating an Active Journey

An Active Journey is created when the Pre-Journey Ritual completes. This is the only mechanism that creates an Active Journey.

### Immediate Behaviours on Active Journey Creation

| Element | Behaviour |
|---------|-----------|
| Profiles | Both profiles unlock automatically — standard or enhanced per each Seeker's subscription (see Part 1, Section 8) |
| Conversation | Created and opened |
| Timeline | Created and begins recording |
| Journey slot | One slot consumed per Seeker |
| Guardian capabilities | Activated per each Seeker's entitlement (AIOS grant per Journey Capability Grant Rules V1) |
| ZYRA Intelligence | Active for ZYRA One Seekers |

---

## 2. Active Journey Slot Rules

| Tier | Active Journey slots | Notes |
|------|---------------------|-------|
| ZYRA Basic | 1 | Hard limit — enforced at database layer |
| ZYRA One | 1 (active) + unlimited paused | Only one may be Active at any time |

Neither tier permits multiple simultaneous Active Journeys. The one-Active-Journey limit is the invariant of the ZYRA platform and is not removed by any subscription.

**Architecture note:** The one Active Journey limit must be enforced at the database layer, not only within the application. A database constraint must prevent two simultaneous active Journey records for the same Seeker, regardless of how the request originates.

---

## 3. Conversation Stage

The conversation opens on Active Journey creation and remains open throughout the Active Journey.

**All tiers:**
- Send and receive messages
- Read receipts
- View Timeline

**ZYRA One additions:**
- ZYRA topic suggestions
- Mid-conversation ZYRA Insights
- Compatibility context surfaced within conversation

---

## 4. Timeline

Every Active Journey has a shared Timeline that begins on Active Journey creation.

**All tiers:** Full milestone Timeline.
**ZYRA One additions:** ZYRA Insights within the Timeline narrative.

Timeline milestone behaviour will be specified in a dedicated document.

---

## 5. Pause Journey (ZYRA One)

ZYRA One Seekers may Pause their Active Journey.

**When Paused:**
- Journey moves to the Seeker's Paused Journeys
- Conversation closes temporarily
- Timeline and all progress are preserved
- Journey slot behaviour in mixed-tier Journeys: **pending resolution — Outstanding Finding 1/6**

### Resume Journey

ZYRA One Seekers may Resume any Paused Journey at any time. Timeline continues from exactly where it stopped. Conversation reopens.

### Unlimited Paused Journeys

ZYRA One Seekers may hold unlimited Paused Journeys simultaneously. Only one Journey may be Active at any time.

---

## 6. End Journey

Either Seeker may end an Active Journey at any time.

On ending:
- Journey transitions to Ended state
- Conversation closes permanently
- Journey slot freed for both Seekers immediately
- Timeline preserved as read-only archive
- Ended Journeys are soft-deleted — hard deletion is not permitted

**Architecture note:** Ended Journeys and their conversations must be soft-deleted from day one. The archive display behaviour will be specified separately, but the database must treat all ended Journeys as archived records rather than deleted rows.

Restarting after End: requires both Seekers to discover each other again and complete the full lifecycle — Potential Journey → Ritual → Active Journey.

---

## 7. Auto-Pause (Inactivity)

If an Active Journey receives no activity from either party for 7 days, it automatically moves to Paused state. Journey slot is freed for both Seekers. Timeline is preserved. Journey may be resumed if both parties agree.

The 7-day inactivity threshold is subject to review.

---

## 8. Family Review Period

After both Seekers complete a Journey stage, a 48-hour Family Review Period begins before the next stage unlocks.

**During the Review Period:**
- Both linked Guardians receive notification
- Each Guardian may Continue (explicit) or raise a concern (explicit)
- Silence for 48 hours = auto-continue

This is a deliberate pause for family awareness, not a veto mechanism.

---

## 9. Approved Journey Sequence

```
Both Seekers choose to begin a Potential Journey
          ↓
    Pre-Journey Ritual
    (Salam Exchange → Phase 1 → Phase 2 → Phase 3)
          ↓
    Active Journey Created
    ├── Profiles unlock (per tier)
    ├── Conversation opened
    ├── Timeline started
    └── Guardian capabilities activated (AIOS grant)
          ↓
    Conversation Stage
          ↓
    Question Journey (chapters + Family Review Periods)
          ↓
    Family Stage  [specification deferred]
          ↓
    Meeting  [specification deferred]
          ↓
    Nikah
```

---

## 10. Approved Feature Summary

| Area | Status |
|------|--------|
| Canonical Relationship Lifecycle | Approved |
| State Integrity Principle (AD-082) | Approved |
| Capability Independence Principle (AD-081) | Approved |
| Core Philosophy | Approved |
| User Roles (Seeker, Guardian) | Approved |
| Subscription Structure (ZYRA Basic, ZYRA One) | Approved |
| Pricing | Approved |
| Guardian Capability Model | Approved — governed by Journey Capability Grant Rules V1 |
| Profile Unlock (manual) | Approved (Plus details deferred) |
| Profile Unlock on Active Journey creation (tiered) | Approved |
| Browse Stage | Approved |
| Save System | Approved |
| Consider System | Approved |
| Match (event) | Approved |
| Potential Journey (state) | Approved |
| Pre-Journey Ritual | Approved — see PRE-JOURNEY RITUAL/Summary.md |
| Active Journey Stage | Approved |
| Conversation Stage | Approved |
| Pause / Resume (ZYRA One) | Approved — mixed-tier Pause behaviour pending (Finding 1/6) |
| Timeline | Approved (milestones deferred) |
| Active Journey slot rules | Approved |
| Family Stage | Future Specification |
| Meeting Stage | Future Specification |
| Nikah Stage | Future Specification |

---

## 11. Intentional Design Decisions

The following are confirmed design decisions. They are intentional and must not be changed without a formal Architecture Decision record.

| Decision | Principle |
|----------|-----------|
| One Active Journey per Seeker (ZYRA Basic and ZYRA One) | Core philosophy — one genuine marriage journey at a time |
| ZYRA One uses Pause for flexibility, not multiple concurrent Journeys | Consistent with Marriage First philosophy |
| Match creates a Potential Journey — not an Active Journey or conversation | Canonical lifecycle: Match is an event, not a stage |
| Conversation belongs exclusively to Active Journey | Separation of lifecycle states |
| Pre-Journey Ritual gates the Active Journey — it is not optional | Commitment to intentional progression |
| Profiles unlock on Active Journey creation — not on Match | Users pay for earlier access, not for communication rights |
| Guardian accounts carry identity only — capabilities are AIOS-granted per Journey | AD-081 Capability Independence Principle |
| Family Network exclusive to Guardians with AIOS-granted Journey capabilities | Introductions centred on trusted family representatives |

---

## 12. Deferred Specifications

The following are intentionally not yet specified. They must not be implemented until dedicated specifications are approved.

| Item | Reason |
|------|--------|
| Pause behaviour in mixed-tier Journeys (Finding 1/6) | Pending formal resolution |
| Family Stage | Full specification required |
| Guardian communication rules | Depends on Family Stage specification |
| Guardian ↔ Guardian chat | Depends on Family Stage specification |
| Match Action definitions | Depends on Family Stage specification |
| Family Network workflow | Depends on Family Stage specification |
| Unlock Profile Plus — full functionality | Dedicated specification required |
| Priority Discovery — full definition | Dedicated specification required |
| Timeline milestone behaviour | Depends on stage transition specifications |
| Notification system | Dedicated specification required |
| Journey activation UX | Screen flow and interaction design required |
| Reminder and expiry behaviour | Dedicated specification required |
| Meeting Stage | Future specification |
| Nikah Stage | Future specification |
| Archive display (ended Journeys) | Soft-delete confirmed; display rules deferred |
| Account deletion and data handling | Required before production launch |
| Safety and blocking system | Dedicated specification required |
| Subscription transition rules | Finding E — pending resolution |
| ZYRA One trial — full rules | Trigger confirmed (first Active Journey begin); full terms deferred |

---

## 13. Version History

| Version | Date | Changes |
|---------|------|---------|
| V1 | 2026-06-27 | Initial baseline — Parts 1–3 |
| V2 | 2026-06-27 | Clarifications from architectural review: annual pricing confirmed, Guardian Basic wording corrected, Profile Unlock duplicate state clarified, soft-delete confirmed, one Active Conversation database enforcement noted, Intentional Design Decisions and Deferred Specifications sections added |
| V3 | 2026-07-04 | **Major revision.** Part 0 added; Section 0.9 Feature-State Covenant added (every new relationship feature must state which canonical state it applies to, whether it changes state, and whether it consumes/releases a slot); downstream reference rule established |
| V4 | 2026-07-26 | **Terminology only** (resolves OA-ZYRA-138). Applies DR-ZYRA-099 (2026-07-25) to this document: Decline → **Pass**, Like → **Consider**, throughout Parts 0–3 (Section headers "4. Like"/"7. Decline" renamed "4. Consider"/"7. Pass"; "Like Rules" → "Consider Rules"; "Like System" → "Consider System" in Section 10). Save is unchanged. No architectural, lifecycle, rule, or numeric content changed — this document was the last owning/citing document still using the pre-2026-07-25 terminology, per OA-ZYRA-138. Previous version archived as ZYRA_PRODUCT_SPEC_2026-07-26_V3.md |

---

*End of ZYRA Master Product Specification V3 — Parts 0–3*
