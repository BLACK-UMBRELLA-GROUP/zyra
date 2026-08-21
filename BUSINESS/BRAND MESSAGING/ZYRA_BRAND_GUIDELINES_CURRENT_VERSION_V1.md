# ZYRA — Brand Guidelines

**Version:** V1
**Status:** CURRENT_VERSION — **SOURCE OF TRUTH for brand identity**
**Date:** 2026-08-13
**Owner:** Founder
**Governing Reference:** ZYRA_GOVERNANCE, ZYRA_TERMINOLOGY
**Consolidates:** `BUSINESS/COLOUR THEME/`, `BUSINESS/BRAND MESSAGING/`, `BUSINESS/APP LOGO/`
**Promoted under:** OA-ZYRA-209

---

## Why this document exists

Brand lived in three unversioned `Summary.md` files in three folders —
colour in one, messaging in another, logo in a third. Anyone asking "what is
the brand" had to find and reconcile all three, and none carried a version,
owner or supersession trail.

This document consolidates them. **The three source folders remain** as
working material and detail; where they disagree with this document, this
document wins.

---

## 1. What ZYRA is

A **Muslim marriage platform**. Not a dating app, and the distinction governs
every branding decision that follows.

| Attribute | Consequence for brand |
|---|---|
| Marriage-first | No dating vocabulary, no swipe language, no "singles" framing |
| Family-involved | The Guardian is part of the product, so the brand is not Seeker-only |
| Deliberate, not fast | Visual calm over urgency; nothing gamified |
| Premium | Reads as a modern technology company, not a traditional marriage service |

### Tagline — approved

> **Connecting Through Trust**

Chosen because it covers the whole ecosystem — Seekers, Guardians, families —
rather than a single user type.

### Brand goals

Premium · Modern · Memorable · Trust-focused · Marriage-first · Neutral
between Seeker and Guardian.

---

## 2. Colour

Ratified **DR-ZYRA-094** (2026-07-25), implemented in
`SOURCE/lib/theme/zyra_colors.dart`.

| Role | Colour |
|---|---|
| Signature brand colour | **Pastel Grey Lavender `#CEA2D1`** |
| Gradient terminus — every theme fades to it | **Luxury Dark Purple `#3D2A4A`** |
| Male context | Blue gradient → `#3D2A4A` |
| Female context | Pink gradient → `#3D2A4A` |
| Pre-authentication / neutral | Purple |

### Rules

1. **Every gradient fades into `#3D2A4A`.** This is the single most
   recognisable property of the interface and is not varied.
2. **Gender themes apply in profile context only** — Profile, Matches, Match
   Notification, Journey Timeline, Chat, Upgrade, Guardian screens
   (DR-ZYRA-101). Onboarding stays flat and neutral throughout
   (OA-ZYRA-123).
3. **Frosted translucent surfaces over the gradient** are the app's visual
   language — pills, segments, cards. Solid black menus and buttons are
   not used; they read as a different product.
4. Button colours follow one consistent system across the app. A new button
   style is a brand decision, not a screen decision.

The colour should feel: royal, calm, premium, trustworthy.

---

## 3. Logo and icon

### Approved direction

- **A standalone icon with no text.** The mark must work without the word
  "ZYRA" beside it.
- Purple is the primary colour; blue and pink are supporting.
- Soft, rounded, premium.
- Simple enough to function at app-icon size.

### Design goals

Instantly recognisable · works without the name · functions as an app icon ·
reads as a modern technology company rather than a traditional marriage
service.

---

## 4. Voice

Follows `ZYRA_TERMINOLOGY` for vocabulary, and the app's own
`ERROR_AND_EMPTY_STATE_STANDARD` for interface copy. The principles:

| Do | Do not |
|---|---|
| Say what happens next | Explain the system to the user |
| Name the person | Use generic "user" language |
| State facts plainly | Reassure with adjectives |
| Let the verb carry the meaning | Add a subtitle explaining the verb |

The last row is a real decision, not a slogan: the Potential Journey card's
explanatory subtitle was removed on 2026-08-13 for exactly this reason.

**Never use the word "AI" in user-facing copy.** The capability is called
**ZYRA Intelligence**.

---

## 5. What is still open

| Item | Status |
|---|---|
| Final logo artwork | Direction approved; artwork not produced |
| Typography specification | Not documented — the app uses Jost; this has never been ratified as a brand decision |
| Social handle set | Scanned 2026-08-01 (Company Formation report §8.1); not claimed |
| Trademark | Clearance searched; not filed — needs a registered applicant |

Each of these is a gap, not an oversight. Under **DR-ZYRA-151** they are
recorded here rather than left unstated, and no action is raised for the
first two until the Founder decides to commission artwork.
