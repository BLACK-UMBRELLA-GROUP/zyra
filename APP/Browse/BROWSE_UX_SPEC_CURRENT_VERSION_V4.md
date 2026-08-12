# ZYRA — Browse UX Specification

**Version:** V4
**Status:** CURRENT_VERSION
**Date:** 2026-07-26
**Supersedes:** BROWSE_UX_SPEC_2026-07-26_V3.md (archived:
BROWSE_UX_SPEC_2026-07-26_V3.md, same folder — no ARCHIVE subfolder
convention exists under APP/, matching APP/Standards precedent)
**Owner:** ZYRA Product

**Filing note (2026-07-26) — DR-ZYRA-112:** the three-dot Profile
Actions menu (below) now has a companion cross-context standard,
`APP/Standards/PROFILE_ACTIONS_MENU_STANDARD_CURRENT_VERSION_V1.md`,
resolving the three gaps DR-ZYRA-095 left open (Block confirmation,
Block-vs-End-Journey interaction, per-relationship-stage contents).
This file's own Profile Actions section is unchanged in substance —
it remains the correct, complete definition for the Browse-screen
context specifically — a pointer was added directing readers to the
fuller cross-context standard for every other stage (Saved, Matches,
Active Journey, Family Stage, Completed Journey).

**Filing note (2026-07-25) — DR-ZYRA-099:** terminology renamed
(Decline/Like → Pass/Consider; Save unchanged) and interaction
mechanism changed from tap-buttons to swipe gestures, per Founder
decision — direct quote: *"I want it to be Pass/Save/Consider. Pass
being red, Save being yellow, Consider being green. And no, we will
stick with swiping actions for cleaner UI."* This reverses
`APP/Navigation/SEEKER NAVIGATION/Summary.md`'s prior explicit
"tap-only, no swipe gestures" rule — see that document for the full
reversal note and reasoning. Source proposal: ChatGPT UX review,
OA-ZYRA-135.
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
document also specifies separate Save (10/day) and Consider
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
On Save (swipe down) → Added to Saved Profiles (private, no notification)
On Consider (swipe left) → Added to Outgoing Potentials
  ↓ [if the other Seeker has already considered this account]
Match event fires → Potential Journey created
  ↓
Match notification → appears in Matches section
  ↓ [ZYRA One — Incoming Potentials]
Separate Incoming Potentials section shows who has Considered this account
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

## User Actions (mechanism updated V3, 2026-07-25 — DR-ZYRA-099)

Terminology renamed and mechanism changed from tap-buttons to swipe
gestures — see `APP/Matching/PROFILE DECISION SYSTEM/Summary.md` for
the terminology decision and `APP/Navigation/SEEKER NAVIGATION/
Summary.md` §BROWSE for the full gesture-reversal reasoning. This
supersedes V2's implicit "Skip / Scroll past" row — 🔴 Pass is now an
explicit swipe action, not an implicit dismissal, resolving the
terminology drift logged as OA-ZYRA-137.

| Action | Gesture | Meaning | Result |
|--------|---------|---------|--------|
| **🟡 Save** | Swipe Down | "I want to come back to this profile." No romantic interest implied. | Added to Saved Profiles. Private. No notification to the other Seeker. |
| **🟢 Consider** | Swipe Left | "I am genuinely interested in pursuing this person." | Added to Outgoing Potentials. If mutual → Potential Journey created. |
| **🔴 Pass** | Swipe Right | "This profile is not suitable for me." | Profile passes without record. No notification. Explicit action, not implicit scroll-past (was ambiguous in V2). |
| **Tap card** | Tap | View card detail. | Shows same limited information (photo, name, age, city) — no additional reveal. Optional: Unlock Profile (purchasable, see Profile Unlock spec). |
| **Report / Hide / Block** | Tap (three-dot menu) | Safety and disinterest actions, separate from the primary swipe experience. | See **Profile Actions** section below. |

Each gesture includes smooth animation and clear visual feedback so
the user immediately understands what action occurred. No floating
action buttons are shown above the bottom navigation bar — actions
are performed directly on the profile card.

**Refined 2026-07-26** (Founder feedback: the swipe interaction "is
not nice," wanted "traffic light colour" feedback tied to swipe
direction): the feedback described above is now live during the drag
itself, not only as a post-commit flash. As the card is dragged past
a small dead zone, a soft coloured edge glow and a small icon+label
pill (top of card) appear and grow in intensity toward the matching
traffic-light colour (🟢 Consider / 🟡 Save / 🔴 Pass) as the drag
approaches the commit threshold, then the existing post-commit flash
still plays on release. Deliberately a light edge glow + pill rather
than a full-photo colour wash, so the photo itself stays fully
visible throughout — approved via an interactive mockup shown to the
Founder before implementation. See `SOURCE/lib/screens/browse/
browse_screen.dart`'s `_dragDecision`/`_dragStrength`.

---

## Profile Actions — Report / Hide / Block (new, V2, 2026-07-25)

Source: ChatGPT UX review, 2026-07-19 (OA-ZYRA-132), filed 2026-07-25
per Founder instruction. Checked against existing documentation first:
no existing Browse-screen reporting/blocking mechanism was found in
V1 of this document; `APP/Journey/JOURNEY MANAGEMENT/Summary.md`
explicitly listed "Full Safety & Moderation design (dedicated
session)" as an Open Discussion, covering Block/Report for both
Seekers and Guardians — this section resolves the Seeker/Browse-screen
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
Both users become invisible to each other; existing Considers/Matches are
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
Discussion also asked: Block/Report **Guardian** (not addressed here — no
Guardian-facing report/block UI is specified anywhere yet); how blocking
affects an **existing Active Journey and its Timeline** (not
addressed — this spec is Browse-stage only, before any Journey
exists); and privacy implications after a Journey has already ended
(not addressed). Those three remain open — `JOURNEY MANAGEMENT/
Summary.md`'s Open Discussions list updated 2026-07-25 to reflect
partial resolution, not full resolution.

**UPDATED 2026-07-26 (DR-ZYRA-112):** the Active-Journey/Timeline and
post-Journey-end questions above are now resolved — see
`APP/Standards/PROFILE_ACTIONS_MENU_STANDARD_CURRENT_VERSION_V1.md`
for the full per-stage table and the design principles behind it.
Guardian-facing report/block remains genuinely open (still not addressed
anywhere). This file's own Browse-stage content above is the correct
baseline for that one context and needed no changes.

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
- Consider up to 10 profiles per day
- Feed counter visible: "14 / 50 profiles · resets in 2h 30m"
- No Incoming Potentials (does not see who has Considered them)
- No Mutual Save Detection
- No Priority Discovery
- Sees a Sponsored card roughly every 10 profile interactions, per
  ADVERTISING_STANDARD_CURRENT_VERSION_V1.md and DR-ZYRA-109 (added
  2026-07-26 — currently a design placeholder, no live ad network yet)

---

## ZYRA One Behaviour

- Unlimited profile browsing
- Unlimited Saves and Considers
- Priority Discovery active — ZYRA Intelligence ranks the feed
- **Incoming Potentials** — separate section showing all Seekers who have already Considered this account
- **Mutual Save Detection** — notification when a Saved profile also Saves this account
- No counter displayed. No limits.
- Completely ad-free — never sees a Sponsored card (DR-ZYRA-109)

---

## Guardian Behaviour

Browse is entirely private to the Seeker.

- Guardian has no access to the Browse tab
- Guardian cannot see which profiles the Seeker has browsed
- Guardian cannot see Saves or Considers sent
- Browse activity is never shared with any linked Guardian at any point

This is consistent with the ZYRA privacy principle: family involvement begins at the Journey stage, not at discovery.

---

## Edge Cases

| Scenario | Behaviour |
|----------|-----------|
| Basic Seeker hits 50 profile limit | Feed stops. Full-screen overlay: limit reached, reset timer, upgrade CTA. Gentle — not punitive. |
| Basic Seeker hits 10 Consider limit | Swipe-left (Consider) gesture is disabled with a gentle resistance/bounce-back animation. Inline message: "You've used your considers for today." Resets at midnight. Upgrade prompt. (Mechanism updated V3 — was button lock.) |
| Basic Seeker hits 10 Save limit | Swipe-down (Save) gesture disabled, same bounce-back pattern as Consider limit. (Mechanism updated V3 — was button lock.) |
| Feed exhausted — all eligible profiles seen | Empty state: "You've seen everyone available right now. Check back later or revisit your Saved Profiles." |
| Profile already Considered — seen again in feed | Card shows "Considered" indicator. Swipe-left (Consider) disabled. Swipe-down (Save) still available. |
| Profile already Saved — seen again in feed | Card shows "Saved" indicator. Swipe-left (Consider) still available. |
| Mutual Consider occurs while browsing (instant match) | System notification appears immediately. New Potential Journey visible in Matches. Normal browsing continues. |
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

### 2. Consider Limit (Basic at 10)

**When:** Seeker swipes left (Consider) and is at limit.

**Placement:** Inline banner at the point of the gesture, since there
is no longer a fixed button location to anchor to (V3, swipe-based).

**Copy:** "You've sent all your considers for today. They reset at midnight."

**Secondary:** Small link — "Unlimited considers with ZYRA One."

---

### 3. Incoming Potentials Tease

**When:** A ZYRA Basic Seeker has received one or more Considers.

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
| Action buttons | **Removed, V3 (2026-07-25, DR-ZYRA-099)** — no floating buttons above the bottom nav bar. Replaced by swipe gestures directly on the card. |
| Consider gesture | Swipe Left — smooth animation, clear visual feedback (was: heart-icon tap) |
| Save gesture | Swipe Down — smooth animation, clear visual feedback (was: bookmark-icon tap) |
| Pass gesture | Swipe Right — smooth animation, clear visual feedback (new, explicit — was implicit "skip/scroll past") |
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
| Consider Limit Screen | Basic Seeker: 10th consider used |
| Profile Limit Screen | Basic Seeker: 50th profile viewed |
| Incoming Potentials (One) | Separate section — ZYRA One only |
| ZYRA One Upgrade | From any upgrade moment CTA |
| Profile Actions Sheet (V2) | Tap three-dot menu on any Browse card |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| V1 | 2026-07-04 | Initial Browse UX specification |
| V2 | 2026-07-25 | Added Profile Actions — Report / Hide / Block (OA-ZYRA-132, DR-ZYRA-095). Checked against JOURNEY MANAGEMENT/Summary.md's Open Discussions first — this section resolves the Browse-screen/Seeker-to-Seeker portion of that item only; Guardian blocking, Active-Journey-stage blocking effects, and post-Journey privacy remain open, see Scope Note. |
| V3 | 2026-07-25 | Terminology renamed Decline/Like → Pass/Consider (Save unchanged); mechanism changed from tap-buttons to swipe gestures (Swipe Left=Consider, Right=Pass, Down=Save), reversing V1's implicit tap-only assumption. Also resolves OA-ZYRA-137 (Pass/Decline was previously only an implicit "Skip/Scroll past," now an explicit named action). Founder decision, OA-ZYRA-135, DR-ZYRA-099. |
| V4 | 2026-07-26 | Added a pointer from §Profile Actions to the new cross-context `PROFILE_ACTIONS_MENU_STANDARD_CURRENT_VERSION_V1.md`, which resolves the Block-confirmation, Block-vs-End-Journey, and per-stage-contents gaps DR-ZYRA-095 left open. No change to this file's own Browse-stage content. DR-ZYRA-112. |

---

*ZYRA Browse UX Specification — CURRENT_VERSION_V3 — 2026-07-25*
