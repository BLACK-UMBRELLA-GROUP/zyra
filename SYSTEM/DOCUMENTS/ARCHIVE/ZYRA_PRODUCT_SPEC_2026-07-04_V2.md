# ZYRA MASTER PRODUCT SPECIFICATION

**Version:** V2
**Status:** Approved — Active Baseline
**Date:** 2026-06-27
**Supersedes:** ZYRA_PRODUCT_SPEC_2026-06-27_V1
**Scope:** Parts 1–3 — Foundation through Conversation Stage
**Governing Reference:** ZYRA_GOVERNANCE_V1
**Architectural Reviewer:** Claude (Lead Architect)

---

## CONTENTS

- Part 1: Foundation & Subscription System
- Part 2: Browse Stage & Potential Stage
- Part 3: Match Stage & Approved Workflow

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

### 2.2 One Journey At A Time

Seekers are intentionally limited to:
- One Active Match
- One Active Conversation

This encourages users to properly invest time into getting to know one potential spouse before moving on.

If a relationship ends respectfully, another journey can begin.

Premium users are not given unlimited conversations. Instead, Premium improves flexibility by allowing users to pause their current journey rather than ending it permanently.

### 2.3 Family Involvement

Family is a core part of the platform.

Rather than treating Walis as optional observers, ZYRA gradually increases family involvement throughout the marriage journey.

The platform is designed so that family participation naturally grows over time rather than appearing immediately.

### 2.4 Privacy

Private actions remain private.

Examples include:
- Individual Saves
- Declines
- Match Actions

Only specifically approved Premium features reveal additional information.

Privacy should always be respected unless both users have independently shown mutual interest.

### 2.5 Premium Philosophy

Premium should improve:
- Visibility
- Convenience
- Discovery
- Flexibility

Premium should not encourage behaviour that conflicts with the platform philosophy.

Examples of features intentionally NOT included:
- Unlimited simultaneous conversations
- Unlimited active matches
- Random boosts that encourage swiping behaviour

Instead, Premium focuses on helping serious users progress more efficiently.

---

## 3. User Types

ZYRA currently supports two user roles.

### 3.1 Seeker

**Purpose:** To search for a suitable spouse.

Seekers browse profiles, save profiles, express interest, communicate with matches and progress through the marriage journey.

### 3.2 Wali

**Purpose:** To represent and support their linked Seeker.

A Wali's responsibility is to:
- Observe
- Guide
- Recommend
- Network with other Premium Walis
- Assist during Family Stage

The Family Network is centred around Walis rather than Seekers.

---

## 4. Subscription Structure

ZYRA currently operates with four plans.

**Seekers**
- Seeker Basic
- Seeker Premium

**Walis**
- Wali Basic
- Wali Premium

The previous three-tier structure (Basic / Pro / Premium) has been removed in favour of a simpler Basic and Premium model.

---

## 5. Pricing

| Plan | Price |
|------|-------|
| Seeker Basic | Free |
| Seeker Premium | £19.99 / month |
| Wali Basic | Free |
| Wali Premium | £9.99 / month |

**Annual Billing**

Annual subscriptions use a simple pricing model. Users pay for 10 months and receive 12 months.

| Plan | Annual Price |
|------|-------------|
| Seeker Premium (annual) | £199.90 / year |
| Wali Premium (annual) | £99.90 / year |

---

## 6. Seeker Plans

### Seeker Basic

**Purpose:** Provide a complete but intentionally limited marriage experience. The free plan allows users to genuinely pursue marriage without turning the platform into a trial experience.

**Features**
- Create profile
- Upload profile photos
- Browse candidate profiles
- View 50 profiles every 4 hours
- Save up to 10 profiles per day
- Like up to 10 profiles per day
- One active match
- One active conversation
- End current match
- Read conversations
- Send messages
- Read receipts
- Timeline
- Link a Wali
- Receive Wali Suggestions (only if their linked Wali has Premium)
- Accept or Reject Wali Suggestions

**Limitations**
- No Incoming Potentials
- No Mutual Save Detection
- No Pause Match
- No Priority Discovery

### Seeker Premium

**Purpose:** Improve discovery and flexibility without encouraging multiple simultaneous relationships.

**Includes Everything In Basic, Plus:**
- Unlimited profile browsing
- Unlimited Saves
- Unlimited Likes
- Incoming Potentials
- Mutual Save Detection
- Pause Match
- Resume Match
- Unlimited paused matches
- Priority Discovery

**Important Rules**

Premium users remain limited to:
- One Active Match
- One Active Conversation

This is intentional. Premium improves the journey but does not encourage multiple concurrent relationships.

---

## 7. Wali Plans

### Wali Basic

**Purpose:** Allow family members to supervise and support their Seeker.

**Features**
- View Seeker activity
- View matches
- Receive notifications
- Included in Match
- Read conversations
- Receive conversation notifications
- Read receipts
- View Timeline

Basic Walis primarily observe the marriage journey.

### Wali Premium

**Purpose:** Allow Walis to actively represent and assist their Seeker.

**Includes Everything In Basic, Plus:**
- Browse candidate profiles
- Suggest profiles to their Seeker
- Add profiles to Wali Suggestions
- Access the Family Network
- Request Family Introductions
- Receive Family Introduction Requests
- Submit Match Actions
- Participate in conversations during Family Stage (subject to Family Stage rules)
- Private Wali ↔ Wali communication (subject to Family Stage rules)

The Family Network exists exclusively for Premium Walis. This keeps introductions centred around trusted family representatives rather than individual Seekers.

---

## 8. Profile Unlock System

The Profile Unlock system is separate from Premium subscriptions. Premium does not include profile unlocks.

### Unlock Profile

Allows a Seeker to reveal a locked profile before a mutual match.

| Quantity | Price |
|----------|-------|
| One Profile | £0.99 |
| Five Profiles | £2.99 |

### Unlock Profile Plus

An enhanced version of Profile Unlock.

| Quantity | Price |
|----------|-------|
| One Profile | £1.99 |
| Five Profiles | £4.99 |

*(The exact additional functionality of Unlock Profile Plus will be defined in a future specification.)*

### Automatic Unlock

Whenever two Seekers successfully match, both profiles unlock automatically. No purchase is required once a match exists.

If a Seeker has already paid to unlock a profile and later matches with that person, the automatic unlock has no additional effect. The profile was already unlocked. No separate unlock state is tracked for this case — the paid unlock and the automatic unlock produce the same outcome.

This ensures users are paying for earlier information, not for access to conversations or relationships.

---

# PART 2 — BROWSE STAGE & POTENTIAL STAGE

## 1. Marriage Workflow

```
Browse
↓
Potential
↓
Match
↓
Conversation
↓
Family Stage
↓
Meeting
↓
Nikah
```

Each stage has a different purpose and unlocks different functionality.

---

## 2. Browse Stage

### Purpose

The Browse Stage allows Seekers to discover potential spouses in a simple, clean and distraction-free environment.

Browse is intentionally limited. The goal is not to overwhelm users with information but to encourage genuine interest before revealing deeper profile details.

### Browse Philosophy

Browse should answer only one question: *"Am I interested enough to learn more?"*

Users first express interest. Additional information becomes available later.

### Visible Information

The Browse page displays only limited profile information:
- Profile photo
- First name
- Age
- Location

Additional profile information remains hidden until:
- The profile is manually unlocked
- A mutual Match occurs

### Profile Unlock Philosophy

The Browse page intentionally does not display an Unlock button. Users should never feel pressured into purchasing unlocks while simply browsing profiles. Users browse naturally first.

### Browse Workflow

```
Browse
↓
Save OR Like
↓
(Optional) Unlock Profile
```

OR

```
Browse
↓
Like
↓
Mutual Match
↓
Both Profiles Automatically Unlock
```

---

## 3. Save

**Purpose:** Saving a profile does not indicate romantic interest. Save simply means: *"I would like to come back to this profile later."*

Saving should remain private wherever possible.

### Save Rules

| Group | Combination | Behaviour |
|-------|-------------|-----------|
| 1 | Basic ↔ Basic | Save is completely private. Neither user is notified. |
| 2 | Basic ↔ Premium | If mutual save: Premium user receives Mutual Save Detected. Basic user receives nothing. |
| 3 | Premium ↔ Basic | Same as Group 2. Only the Premium user receives notification. |
| 4 | Premium ↔ Premium | If mutual save: Both users receive Mutual Save Detected. |

**Important:** A single Save is never revealed. Only mutual Saves may generate a notification.

---

## 4. Like

**Purpose:** Unlike Save, a Like represents genuine interest. A Like tells the system: *"I would like to pursue this person."*

### Like Rules

| Group | Combination | Behaviour |
|-------|-------------|-----------|
| 1 | Basic ↔ Basic | Added to Outgoing Potentials. Receiving user gets nothing. If they later Like back, Match occurs. |
| 2 | Basic → Premium | Premium user immediately receives Incoming Potential. May Like Back, Save, or Decline. |
| 3 | Premium → Basic | Basic user receives nothing. Continues browsing. If they later Like back, Match occurs. |
| 4 | Premium ↔ Premium | Both receive Incoming Potentials immediately. May Like Back, Save, or Decline. |

---

## 5. Incoming Potentials

Premium-only feature. Allows Premium users to immediately see who has already expressed interest in them.

Basic users do not receive Incoming Potentials. They continue discovering profiles naturally through Browse.

---

## 6. Outgoing Potentials

Whenever a Like is sent, the sender sees that profile inside Outgoing Potentials. Allows users to track profiles they have already expressed interest in.

---

## 7. Decline

Decline behaves identically for every subscription combination.

When Decline is selected:
- No notification is sent
- No explanation is provided
- The sender is never informed
- The Potential is removed
- The profile disappears from the active journey

---

# PART 3 — MATCH STAGE & APPROVED WORKFLOW

## 1. Match Stage

### Purpose

A Match occurs when two Seekers have both expressed mutual interest by pressing Like on each other's profiles.

A Match is the beginning of the marriage journey — not the end goal.

### Creating A Match

A Match is only created when:
- Seeker A Likes Seeker B
- Seeker B Likes Seeker A

Saving, viewing, and unlocking profiles do not create a Match. Only mutual Likes create a Match.

---

## 2. Automatic Match Behaviour

Immediately after a successful Match:

| Element | Behaviour |
|---------|-----------|
| Profiles | Both profiles automatically unlock |
| Matches | Match appears in each user's Matches section |
| Conversation | Private conversation automatically created |
| Timeline | Timeline automatically created and begins recording |
| Walis | Linked Walis automatically become associated with the Match |

---

## 3. Active Match Rules

| Plan | Active Matches | Active Conversations |
|------|---------------|---------------------|
| Seeker Basic | 1 | 1 |
| Seeker Premium | 1 | 1 |

Premium does not unlock multiple simultaneous conversations. Premium focuses on flexibility through the Pause system.

**Architecture note:** The one active conversation limit must be enforced at the database layer, not only within the application. A database constraint or row-level rule must prevent two simultaneous active conversations from existing for the same Seeker, regardless of how the request originates.

---

## 4. End Match

Every Seeker has the ability to end their current Match.

Current approved behaviour:
- Match ends
- Conversation closes
- Active Match slot becomes available again

**Architecture note:** Ended Matches and their conversations must be soft-deleted from day one. Hard deletes are not permitted. The archive display behaviour will be specified separately, but the database must treat all ended Matches as archived records rather than deleted rows. This avoids future schema migrations when archive behaviour is formally defined.

---

## 5. Pause Match (Premium Only)

Allows Premium users to temporarily stop progressing without permanently ending the relationship.

**When paused:**
- Match leaves Active Matches
- Conversation closes temporarily
- Progress is preserved
- Relationship moves into Paused Matches

### Resume Match

Premium users may resume any paused Match.

When resumed:
- Conversation returns
- Timeline continues
- Progress continues from exactly where it stopped

### Unlimited Paused Matches

Premium users may maintain an unlimited number of paused Matches. However, only one Match may ever be active at a time.

---

## 6. Conversation Stage

Immediately after matching, the relationship enters the Conversation Stage.

**Current approved behaviour:**
- Both users may send messages
- Both users may read messages
- Read receipts are enabled
- Timeline remains visible
- Both profiles remain fully unlocked

---

## 7. Timeline

Every Match automatically creates a shared Timeline.

**Current approved journey:**

```
Browse → Potential → Match → Conversation → Family Stage → Meeting → Nikah
```

---

## 8. Current Approved Workflow

```
Browse
│
├── Save
├── Like
└── Unlock Profile (Optional)
        │
        ▼
Potential
        │
        ▼
Mutual Like
        │
        ▼
Match Created
        │
        ├── Profiles Unlock Automatically
        ├── Match Added
        ├── Conversation Created
        ├── Timeline Started
        └── Linked Walis Attached
        │
        ▼
Conversation Stage
        │
        ├── Continue Conversation
        ├── Pause Match (Premium)
        └── End Match
```

---

## 9. Approved Feature Summary

| Area | Status |
|------|--------|
| Core Philosophy | Approved |
| User Roles (Seeker, Wali) | Approved |
| Subscription Structure (4 plans) | Approved |
| Pricing | Approved |
| Profile Unlock System | Approved (Plus details deferred) |
| Browse Stage | Approved |
| Save System | Approved |
| Like System | Approved |
| Potential Stage | Approved |
| Match Stage | Approved |
| Conversation Stage | Approved |
| Pause / Resume System | Approved |
| Timeline | Approved (milestones deferred) |
| Active Match Rules | Approved |
| Family Stage | Future Specification |
| Wali eligibility rules | Future Specification |
| Meeting Stage | Future Specification |
| Nikah Stage | Future Specification |

---

## 10. Intentional Design Decisions

The following are confirmed design decisions. They are intentional and must not be changed without a formal decision record.

| Decision | Principle |
|----------|-----------|
| One active Match per Seeker (Basic and Premium) | Core philosophy — one genuine marriage journey |
| One active conversation limit | Enforces commitment; Premium uses Pause, not multiples |
| Premium does not allow multiple simultaneous relationships | Premium improves journey quality, not quantity |
| Family Network exclusive to Premium Walis | Introductions centred on trusted family representatives |
| Profiles unlock automatically on Match at no charge | Users pay for earlier access, not for communication rights |
| No unlimited conversations even on Premium | Consistent with Marriage First philosophy |

---

## 11. Deferred Specifications

The following are intentionally not yet specified. They must not be implemented until dedicated specifications are approved.

| Item | Reason |
|------|--------|
| Family Stage | Full specification required before any family features are built |
| Wali communication rules | Depends on Family Stage specification |
| Wali ↔ Wali chat | Depends on Family Stage specification |
| Wali eligibility | Dedicated specification required |
| Match Action definitions | Depends on Family Stage specification |
| Family Network workflow | Depends on Family Stage specification |
| Unlock Profile Plus | Functionality not yet defined |
| Priority Discovery | Definition required before implementation |
| Timeline milestone behaviour | Depends on stage transition specifications |
| Notification system | Dedicated specification required |
| Meeting Stage | Future specification |
| Nikah Stage | Future specification |
| Archive behaviour (ended Matches) | Soft-delete architecture confirmed; display rules deferred |
| Account deletion and data handling | Required before production launch |
| Safety and blocking system | Dedicated specification required |

---

## 12. Version History

| Version | Date | Changes |
|---------|------|---------|
| V1 | 2026-06-27 | Initial baseline — Parts 1–3 filed from approved content |
| V2 | 2026-06-27 | Clarifications from architectural review: annual pricing confirmed, Wali Basic wording corrected (Included in Match + Receive conversation notifications), Profile Unlock duplicate state clarified, End Match soft-delete architecture confirmed, One Active Conversation database-level enforcement noted, Intentional Design Decisions section added, Deferred Specifications section added |

---

*End of ZYRA Master Product Specification V2 — Parts 1–3*
