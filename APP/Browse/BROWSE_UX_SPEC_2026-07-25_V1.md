# ZYRA — Browse UX Specification

**Version:** V1
**Status:** SUPERSEDED 2026-07-25 by BROWSE_UX_SPEC_CURRENT_VERSION_V2.md
**Date:** 2026-07-04
**Owner:** ZYRA Product
**Governing Documents:**
  ZYRA Product Specification V3
  ZYRA Journey Capability Grant Rules V3

**Implementation note (2026-07-19, DR-ZYRA-089, PROPOSED/not
ratified):** a ChatGPT-authored UX review (OA-ZYRA-125) asked
to hide the profile counter entirely during normal browsing
and only surface it via a modal once a limit is hit. That was
built today — but it conflicts with this document's own
**ZYRA Basic Behaviour** section below, which specifies the
counter should be **visible** during normal Basic browsing
("Feed counter visible: '14 / 50 profiles...'"), and this
document also specifies separate Save (10/day) and Like
(10/day) caps that were not implemented — only a single
50-profile view cap exists in code so far. The live Browse
screen (`browse_screen.dart`) also doesn't yet distinguish
ZYRA Basic from ZYRA One at all, so none of this tier-specific
behaviour is wired to a real entitlement check. Flagging per
Conflict Flag Before Edit rather than picking a side — needs a
Founder decision on which document is correct (this spec, or
today's OA-ZYRA-125 change) before Browse's limit UI is
finalised.

---

## Purpose

Allow Seekers to discover potential spouses in a focused, clean, distraction-free environment.

Browse answers a single question: **"Am I interested enough to learn more?"**

It does not overwhelm. It does not reveal everything upfront. It creates deliberate, intentional discovery. The experience is built around the idea that first impression should be human and simple — a face, a name, an age, a city. That is enough to know whether you want to know more.

---

## Screen Flow

```
Browse Tab
  ↓
Profile Feed (scrollable cards)
  ↓
On Save → Added to Saved Profiles (private, no notification)
On Like → Added to Outgoing Potentials
  ↓ [if the other Seeker has already liked this account]
Match event fires → Potential Journey created
  ↓
Match notification → appears in Matches section
  ↓ [ZYRA One — Incoming Potentials]
Separate Incoming Potentials section shows who has Liked this account
```

---

## Profile Card — Visible Information

| Field | Visible on Browse card |
|-------|----------------------|
| Profile photo | ✓ — primary, dominant |
| First name | ✓ |
| Age | ✓ |
| Location (city) | ✓ |
| Compatibility % | ✗ — only after Active Journey |
| Values / preferences | ✗ — private until further into Journey |
| Education / career | ✗ — hidden until unlocked or matched |
| Any profile detail beyond the above | ✗ |

The card is intentionally limited. Additional information becomes available only after mutual interest is established.

---

## User Actions

| Action | Meaning | Result |
|--------|---------|--------|
| **Save** | "I want to come back to this profile." No romantic interest implied. | Added to Saved Profiles. Private. No notification to the other Seeker. |
| **Like** | "I am genuinely interested in pursuing this person." | Added to Outgoing Potentials. If mutual → Potential Journey created. |
| **Skip / Scroll past** | No interest — implicit dismissal. | Profile passes without record. No notification. |
| **Tap card** | View card detail. | Shows same limited information (photo, name, age, city) — no additional reveal. Optional: Unlock Profile (purchasable, see Profile Unlock spec). |

---

## AI Behaviour

| Tier | Browse feed ordering |
|------|---------------------|
| ZYRA Basic | Standard system ordering — recency, basic activity signals |
| ZYRA One | **Priority Discovery** — ZYRA Intelligence ranks the feed. Profiles with strong compatibility signals, active users, and mutual interest indicators surface first. Ranking is invisible to the user. The feed simply feels more relevant. |

Priority Discovery does not show scores, labels, or indicators on cards. The ranking is silent.

---

## ZYRA Basic Behaviour

- Browse up to 50 profiles per 4-hour window
- Save up to 10 profiles per day
- Like up to 10 profiles per day
- Feed counter visible: "14 / 50 profiles · resets in 2h 30m"
- No Incoming Potentials (does not see who has Liked them)
- No Mutual Save Detection
- No Priority Discovery

---

## ZYRA One Behaviour

- Unlimited profile browsing
- Unlimited Saves and Likes
- Priority Discovery active — ZYRA Intelligence ranks the feed
- **Incoming Potentials** — separate section showing all Seekers who have already Liked this account
- **Mutual Save Detection** — notification when a Saved profile also Saves this account
- No counter displayed. No limits.

---

## Wali Behaviour

Browse is entirely private to the Seeker.

- Wali has no access to the Browse tab
- Wali cannot see which profiles the Seeker has browsed
- Wali cannot see Saves or Likes sent
- Browse activity is never shared with any linked Wali at any point

This is consistent with the ZYRA privacy principle: family involvement begins at the Journey stage, not at discovery.

---

## Edge Cases

| Scenario | Behaviour |
|----------|-----------|
| Basic Seeker hits 50 profile limit | Feed stops. Full-screen overlay: limit reached, reset timer, upgrade CTA. Gentle — not punitive. |
| Basic Seeker hits 10 Like limit | Like button visually locked. Inline message: "You've used your likes for today." Resets at midnight. Upgrade prompt. |
| Basic Seeker hits 10 Save limit | Save button locked. Same pattern as Like limit. |
| Feed exhausted — all eligible profiles seen | Empty state: "You've seen everyone available right now. Check back later or revisit your Saved Profiles." |
| Profile already Liked — seen again in feed | Card shows "Liked" indicator. Like button inactive. Save still available. |
| Profile already Saved — seen again in feed | Card shows "Saved" indicator. Like still available. |
| Mutual Like occurs while browsing (instant match) | System notification appears immediately. New Potential Journey visible in Matches. Normal browsing continues. |
| ZYRA One downgrade mid-session | Limits apply from the next app session. Current session preserved. |
| No profile photo present | Placeholder shown. Profile still browsable. |

---

## Upgrade Moments

Upgrade moments are contextual, human, and non-intrusive. They appear at natural friction points — never as random popups.

### 1. Profile Limit (Basic at 50)

**When:** Seeker has viewed all 50 profiles in their window.

**Screen:** Full-screen overlay. Reset timer shown prominently. CTA for ZYRA One.

**Tone:** Not "You've hit your limit." Rather: "Take this time to revisit the profiles you've saved. Or explore unlimited with ZYRA One."

**CTA:** "Explore unlimited with ZYRA One" / "View my Saved Profiles"

---

### 2. Like Limit (Basic at 10)

**When:** Seeker taps Like and is at limit.

**Placement:** Inline — just below the Like button. Small, contextual.

**Copy:** "You've sent all your likes for today. They reset at midnight."

**Secondary:** Small link — "Unlimited likes with ZYRA One."

---

### 3. Incoming Potentials Tease

**When:** A ZYRA Basic Seeker has received one or more Likes.

**Placement:** Subtle banner or pill at top of Browse screen.

**Copy:** "Someone has already liked your profile."

**No number. No face.** Tapping leads to the ZYRA One upgrade screen.

**Tone:** Curious and warm — not transactional. The user should feel intrigued, not sold to.

---

### 4. Mutual Save Tease (Never surfaced — intentional)

ZYRA Basic Seekers who save a profile that has also saved them receive nothing. This is by design. ZYRA does not create half-upgrades.

The Mutual Save Detection feature is visible in the ZYRA One upgrade screen as a listed benefit — not teased mid-Browse.

---

## Final UI Decisions

| Element | Decision |
|---------|---------|
| Card layout | Single card per view — deliberate, not a grid of thumbnails |
| Photo proportion | Photo is the dominant element — large, full-width card |
| Info position | Name / Age / City in small type at bottom of card — understated |
| Compatibility % | Not shown on Browse cards. Not visible anywhere until Active Journey begins. |
| Action buttons | Save (bookmark icon) + Like (heart icon) — both labelled on first use only |
| Like animation | Subtle heart animation on Like — warm, not dramatic |
| Save animation | Subtle bookmark animation — quiet, confirmatory |
| Counter (Basic only) | Small, discrete — bottom of screen, not on the card |
| Priority Discovery label | Not visible — ranking is silent |
| Incoming Potentials | Separate tab section — not mixed into Browse feed |
| Profile Unlock | Not shown in Browse by default. Available on card detail tap. No pressure placement. |

---

## Screen Summary

| Screen | Trigger |
|--------|---------|
| Browse Feed | Default Browse tab state |
| Card Detail | Tap on profile card |
| Save Limit Screen | Basic Seeker: 10th save used |
| Like Limit Screen | Basic Seeker: 10th like used |
| Profile Limit Screen | Basic Seeker: 50th profile viewed |
| Incoming Potentials (One) | Separate section — ZYRA One only |
| ZYRA One Upgrade | From any upgrade moment CTA |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| V1 | 2026-07-04 | Initial Browse UX specification |

---

*ZYRA Browse UX Specification — superseded 2026-07-25 by BROWSE_UX_SPEC_CURRENT_VERSION_V2.md — archived, reference-only.*
