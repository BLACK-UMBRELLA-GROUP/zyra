# ZYRA — Browse UX Specification

**Version:** V2
**Status:** SUPERSEDED 2026-07-25 (same day) by
  BROWSE_UX_SPEC_CURRENT_VERSION_V3.md — Pass/Save/Consider
  terminology and swipe-gesture mechanism, DR-ZYRA-099
**Date:** 2026-07-25
**Supersedes:** BROWSE_UX_SPEC_CURRENT_VERSION_V1.md (archived:
BROWSE_UX_SPEC_2026-07-25_V1.md, same folder — no ARCHIVE subfolder
convention exists under APP/, matching APP/Standards precedent)
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
finalised. **Unchanged in V2 — carried forward from V1, still open.**

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
| **Report / Hide / Block** (new, V2) | Safety and disinterest actions, separate from the primary swipe experience. | See **Profile Actions** section below. |

---

## Profile Actions — Report / Hide / Block (new, V2, 2026-07-25)

Source: ChatGPT UX review, 2026-07-19 (OA-ZYRA-132), filed 2026-07-25
per Founder instruction. Checked against existing documentation first:
no existing Browse-screen reporting/blocking mechanism was found in
V1 of this document; `APP/Journey/JOURNEY MANAGEMENT/Summary.md`
explicitly listed "Full Safety & Moderation design (dedicated
session)" as an Open Discussion, covering Block/Report for both
Seekers and Walis — this section resolves the Seeker/Browse-screen
portion of that gap only (see Scope Note at the end of this section).
See DR-ZYRA-095.

### UI

A permanently visible three-dot (•••) menu sits in the top-right
corner of every Browse profile — preferred over a long-press gesture
(poor discoverability, conflicts with swipe gestures, discouraged for
safety-critical actions) or a flag icon (implies reporting is the only
action, no room for future options, unnecessarily aggressive on every
profile).

Tapping it opens a bottom sheet / action menu: **Report Profile /
Hide Profile / Block User / Cancel**.

### Actions

**Report Profile** — used when a profile violates ZYRA's Community
Guidelines (fake profile, impersonation, nudity, violence, underage
user, harassment, other policy violations). Enters the moderation
pipeline for automated and/or manual review — see
`APP/Profiles/Summary.md` for the photo-specific instance of this
pipeline (currently 🔴, unresolved — see that document's Conflict
Flag).

**Hide Profile** — "I don't want to see this profile again." No
penalty to the other user. Removes the profile from future
recommendations. Does not notify the other user. Reversible via
account settings (optional). This is the encouraged option when a
user simply isn't interested, to reduce false/unnecessary reports.

**Block User** — prevents any future interaction between two users.
Both users become invisible to each other; existing Likes/Matches are
removed if applicable; messaging is disabled; no notification is
sent. Intended for unwanted contact rather than policy violations.

### Report flow

Tap three-dot menu → Report Profile → choose a reason → optionally add
detail → submit → enters ZYRA's moderation system → user receives
confirmation.

### Design principles

Never interferes with swiping. Always discoverable. As few taps as
possible. Clearly distinguishes Hide / Block / Report from one
another. Scales to future additions without redesigning the Browse
screen — potential future items in the same menu: Share Profile, Copy
Profile Link, Save for Later, Report Specific Photo, Report Specific
Prompt, Mute Profile, Export Conversation (where applicable). None of
these future items are approved for build; listed for scope awareness
only.

### Scope note — what this does NOT resolve

This section covers **Browse-screen, pre-Journey, Seeker-to-Seeker**
report/hide/block only. `JOURNEY MANAGEMENT/Summary.md`'s Open
Discussion also asked: Block/Report **Wali** (not addressed here — no
Wali-facing report/block UI is specified anywhere yet); how blocking
affects an **existing Active Journey and its Timeline** (not
addressed — this spec is Browse-stage only, before any Journey
exists); and privacy implications after a Journey has already ended
(not addressed). Those three remain open — `JOURNEY MANAGEMENT/
Summary.md`'s Open Discussions list updated 2026-07-25 to reflect
partial resolution, not full resolution.

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
| Report/Hide/Block menu (V2) | Permanent three-dot (•••) top-right on every card — not a long-press, not a flag icon. |

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
| Profile Actions Sheet (V2) | Tap three-dot menu on any Browse card |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| V1 | 2026-07-04 | Initial Browse UX specification |
| V2 | 2026-07-25 | Added Profile Actions — Report / Hide / Block (OA-ZYRA-132, DR-ZYRA-095). Checked against JOURNEY MANAGEMENT/Summary.md's Open Discussions first — this section resolves the Browse-screen/Seeker-to-Seeker portion of that item only; Wali blocking, Active-Journey-stage blocking effects, and post-Journey privacy remain open, see Scope Note. |

---

*ZYRA Browse UX Specification — CURRENT_VERSION_V2 — 2026-07-25*
