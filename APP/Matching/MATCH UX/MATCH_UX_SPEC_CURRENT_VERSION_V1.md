---
id: DOC-ZYRA-0025
type: SPEC
status: CURRENT
feature: APP: MATCHING
purpose: Matching / Match Ux — MATCH UX SPEC CURRENT VERSION V1: ZYRA — Match UX Specification: The Match event fires when two Seekers have mutually Liked each other.
links: []
owner: ZYRA chat
---

# ZYRA — Match UX Specification

**Version:** V1
**Status:** CURRENT_VERSION
**Date:** 2026-07-04
**Owner:** ZYRA Product
**Governing Documents:**
  ZYRA Product Specification V3
  ZYRA Journey Capability Grant Rules V3
  Browse UX Specification V1

---

## Purpose

The Match event fires when two Seekers have mutually Liked each other. Its UX purpose is to:

1. Notify both Seekers of the mutual interest — warmly, not transactionally
2. Surface the Potential Journey that has been created
3. Give the Seeker a clear, low-pressure path to either start the Journey or leave it open

**Match answers a single question: "Someone is interested in you too — what do you want to do?"**

### What Match is not

Per Product Specification V3 (AD-082 — State Integrity Principle):

- Match is an **event**, not a stage or state
- Match does **not** start a conversation
- Match does **not** create obligations
- Match does **not** consume a Journey slot
- The result of a Match event is a **Potential Journey** — passive, no commitment required

The Matches tab houses Journey Queue. It is not a conversation inbox.

---

## Screen Flow

```
Browse Tab
  ↓ [mutual Like detected]
Match event fires
  ↓
In-app Match notification (full-screen moment, dismissible)
  ↓
Matches tab updated — new Potential Journey card appears
  ↓
Seeker options:
  A) Leave as Potential Journey — no action required
  B) Tap card — view profile detail (read-only)
  C) Tap "Start Journey" — enters Pre-Journey Ritual
       ↓
       Pre-Journey Ritual (activation sequence)
       ↓
       Active Journey created (slot consumed, conversation unlocked)
```

Push notification also sent if app is in background or closed.

---

## Profile Card — Visible Information on Match Card

Match unlocks a small additional layer of profile detail beyond Browse.

| Field | Browse card | Match card |
|---|---|---|
| Profile photo | ✓ | ✓ |
| First name | ✓ | ✓ |
| Age | ✓ | ✓ |
| Location (city) | ✓ | ✓ |
| Values / faith notes | ✗ | ✓ — brief, single line |
| Education | ✗ | ✓ — field only, no detail |
| Compatibility % | ✗ | ✗ — only after Active Journey begins |

The Match card is warmer and slightly more revealing than a Browse card, but it is still not a full profile. Full profile access requires starting an Active Journey (Profile Plus, ZYRA One feature).

---

## User Actions

| Action | Meaning | Result |
|---|---|---|
| Dismiss Match notification | "I'll decide later." | Notification dismissed. Potential Journey remains in Matches tab. |
| View card | Tap match card to see expanded detail. | Shows Match card with small additional profile info. No slot consumed. |
| Start Journey | "I want to begin this Journey." | Enters Pre-Journey Ritual. Slot consumed on completion. Active Journey created. |
| Leave as Potential Journey | No action taken. | Potential Journey remains open indefinitely. No obligation. No expiry (V1). |

---

## Match Notification — Moment Design

The Match notification is a full-screen celebratory moment. Warm, calm, human — not a game mechanic.

**Elements:**
- Both profile photos (side by side, circular — blurred/softened)
- First names only: "You and Amina matched."
- Subtext: "A Potential Journey has been created."
- Primary CTA: "View match"
- Secondary: "Later" (dismisses without losing the match)

**Tone:** The notification is joyful but not dramatic. ZYRA is a serious platform. The Match moment should feel meaningful, not like a slot machine win.

**No confetti, no animations beyond a gentle fade-in. No sound by default.**

---

## AI Behaviour

| Tier | Match moment |
|---|---|
| ZYRA Basic | Standard match notification. No AI insight. |
| ZYRA One | Notification includes a quiet compatibility signal: "ZYRA Intelligence noted strong alignment." No percentage shown. One line only. |

AI does not generate messaging suggestions at the Match stage. Conversation belongs to Active Journey only.

---

## ZYRA Basic Behaviour

- Match notification: standard (names, photos, "View match" CTA)
- Match card: photo, name, age, city, one additional detail line
- Matches tab: list of all Journey Queue, newest first
- Can start Journey (Pre-Journey Ritual) — subject to slot availability
- No incoming Potentials visibility (only sees mutual matches)
- No compatibility signal in notification

---

## ZYRA One Behaviour

- Match notification: includes one-line ZYRA Intelligence signal (no %)
- Match card: same as Basic plus compatibility note
- **Incoming Potentials tab** visible separately — shows all Seekers who have Liked this account, including non-mutual Likes
- Matches tab: mutual matches only (Journey Queue)
- Profile Plus available at Journey start (more profile detail unlocked when Active Journey begins)
- Unlimited Journey Queue visible (no cap)

**Incoming Potentials is a separate tab, not mixed into Matches.** Matches = mutual. Incoming Potentials = one-way Likes received.

---

## Guardian Behaviour

Guardian has no access to the Matches tab or Match notifications.

- Guardian cannot see who the Seeker has matched with
- Guardian cannot see Journey Queue
- Guardian cannot see Incoming Potentials
- Guardian involvement begins only when the Seeker starts an Active Journey (via Pre-Journey Ritual)

This is consistent with the ZYRA privacy model: family involvement begins at the Journey stage, not at discovery or matching.

---

## Edge Cases

| Scenario | Behaviour |
|---|---|
| Match notification arrives while app is closed | Push notification sent. Tapping opens app directly to Match notification screen. |
| Seeker has no available Journey slot | CHANGED 2026-08-12 stewardship pass (Founder 2026-08-11): tapping shows the end-then-start dialog — starting with the new person permanently ENDS the current Journey on confirm (Timeline kept); ZYRA One is offered pause instead. Starting is no longer blocked; it is destructive and says so. |
| Both Seekers tap "Start Journey" simultaneously | First request creates Active Journey. Second Seeker sees confirmation that Journey has already started. No duplicate Journey created. |
| Match with a Seeker the user later blocks | Potential Journey removed. Match card disappears. |
| Multiple new matches arrive simultaneously | Each creates its own Potential Journey. Notification shows "You have [n] new matches." Individual match cards in Matches tab. |
| Seeker dismisses notification, then forgets | Potential Journey remains in Matches tab with "New" indicator for 48 hours. |
| ZYRA One downgrade with Journey Queue open | Journey Queue remain. Incoming Potentials tab hidden. Compatibility signal removed from match cards. |

---

## Upgrade Moments

### 1. Profile Plus Tease (at Start Journey)

**When:** ZYRA Basic Seeker taps "Start Journey."

**Placement:** As part of the Pre-Journey Ritual entry screen (not on the Match card itself).

**Copy:** "Starting a Journey unlocks the full profile. ZYRA One members also unlock Profile Plus — deeper detail from the first day."

**CTA:** "Continue with Basic" / "Explore ZYRA One"

**Tone:** Informational. Not a barrier. Basic Seekers can continue without upgrading.

### 2. Incoming Potentials Upgrade (on Matches tab)

**When:** ZYRA Basic Seeker is on the Matches tab.

**Placement:** Subtle persistent tab: "Incoming" — greyed out, with a small badge showing a non-specific signal (not a count, not a face).

**Copy (on tap):** "See who's already interested in you. Available with ZYRA One."

**Tone:** Curious, not pressuring.

---

## Final UI Decisions

| Element | Decision |
|---|---|
| Match notification style | Full-screen moment — both photos, names, warm copy, two CTAs |
| Photo treatment in notification | Circular, slightly softened — not harsh passport-photo crop |
| Compatibility % at Match | Not shown. Not shown anywhere until Active Journey begins. |
| AI signal (ZYRA One) | One line, qualitative only. No number. |
| Matches tab layout | Card list, newest first. Potential Journey cards only (mutual matches). |
| Incoming Potentials | Separate tab — not mixed into Matches |
| "New" indicator | 48-hour badge on unseen match cards |
| Start Journey CTA position | On expanded match card only — not on collapsed card |
| Conversation | Not visible at Match stage. Belongs to Active Journey. |
| Guardian | Not present at Match stage. |

---

## Screen Summary

| Screen | Trigger | Key elements |
|---|---|---|
| Match notification | Mutual Like detected | Both photos, names, "View match" / "Later" |
| Matches tab | Navigate to Matches | List of Potential Journey cards |
| Match card (collapsed) | Default state | Photo, name, age, city |
| Match card (expanded) | Tap card | Above + one extra detail line, "Start Journey" CTA |
| Slot unavailable state | Tap "Start Journey" with no slot | Explanation, no slot consumed |
| Incoming Potentials tab | ZYRA One only | One-way Likes received |

