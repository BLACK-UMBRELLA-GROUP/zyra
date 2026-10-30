---
id: DOC-ZYRA-0126
type: BRAND
status: SUPERSEDED
feature: BUSINESS: ZYRA TERMINOLOGY
purpose: Zyra Terminology — ZYRA TERMINOLOGY CURRENT VERSION V1: Owns official ZYRA terminology, definitions, language standards, terminology relationships, and terminology usage throughout the platform.
links: []
owner: ZYRA chat
---

# ZYRA — Terminology

**Version:** V1
**Status:** ARCHIVED 2026-10-29 — superseded by ZYRA_TERMINOLOGY_CURRENT_VERSION_V2.md (same folder, one level up). Reference only; describes the old member app
**Date:** 2026-08-13
**Owner:** Founder
**Governing Reference:** ZYRA_GOVERNANCE, TERMINOLOGY_STANDARDS
**Promoted under:** OA-ZYRA-209

---

## Why this document was promoted

Naming drift is the same failure as pricing drift, and this project has had
both. "Wali" became "Guardian"; "Profile Unlock" became "Compatibility
Unlock" — and in each case retired names survived in the code for weeks
because the glossary had no governed status to breach.

**This document is now the source of truth for product vocabulary.** A word
in the interface that disagrees with it is a defect.

## The renames that must not reappear

| Retired | Current | Since |
|---|---|---|
| Wali | **Guardian** | ratified; Guardian+ is the paid tier |
| Wali One | **Guardian+** | — |
| Profile Unlock / Unlock Profile | **Compatibility Unlock** | 2026-08-03 |
| Profile Unlock Plus | **Compatibility Unlock Plus** | 2026-08-03 |
| Match (as a verb for liking) | **Consider** / **Save** / **Pass** | Decision system |

ZYRA is a **marriage** platform, not a dating app. Vocabulary follows from
that everywhere: Seeker, Guardian, Journey, Salam, Family Review — never
"date", "swipe", "hook up", or "singles".

---

## Content, as promoted

FEATURE NAME
ZYRA TERMINOLOGY
Group: 1 — Business Rules

Status: Approved

============================================================
SUMMARY
============================================================

Purpose:
Owns official ZYRA terminology, definitions, language
standards, terminology relationships, and terminology usage
throughout the platform.

This document is the source of truth for all terminology
used across ZYRA — in features, scripts, flows, onboarding,
notifications, and all product documentation.

Owns:
• Official terminology
• Definitions
• User explanations
• Internal explanations
• Terminology relationships
• Language standards
• Terminology usage rules

Note:
• Flow Diagram — not applicable. This document defines
  terminology rather than application flows.
• Script — not applicable. Feature implementations belong
  within their respective files.

============================================================
ROLE TERMINOLOGY
============================================================

------------------------------------------------------------
TERM: Seeker
------------------------------------------------------------

Definition:
A person actively looking for marriage through ZYRA.

Purpose:
Identifies the primary marriage candidate using the platform.

User Explanation:
A Seeker is someone looking for a suitable marriage partner.

Internal Explanation:
The core marriage-candidate role throughout ZYRA. The Seeker
is the person progressing through the marriage journey and
is the primary user of marriage-search features.

Found In:
• Sign Up
• Onboarding
• Browse
• Profile Page
• Connections
• Proposal Tracker
• Subscriptions

Related Systems:
• Browse
• Potentials
• Connections
• Profile Unlocks
• Proposal Tracker
• Guardian System
• Subscriptions

Notes:
• Seeker = Marriage Candidate.
• When "Seeker" is used, it always refers to the person
  seeking marriage.
• The Seeker is the person paying to find a marriage partner.

------------------------------------------------------------
TERM: Guardian
------------------------------------------------------------

Definition:
A supervisor or guardian who helps oversee and support the
marriage process.

Purpose:
Provides guidance, oversight, accountability, and involvement
throughout the marriage journey.

User Explanation:
A Guardian is a guardian or supervisor who helps oversee the
marriage process.

Internal Explanation:
The supervisory role within ZYRA. A Guardian assists and oversees
Seekers while supporting the marriage journey.

Found In:
• Sign Up
• Onboarding
• Browse
• Guardian Features
• Connections
• Proposal Tracker
• Notifications

Related Systems:
• Guardian System
• Browse
• Potentials
• Connections
• Proposal Tracker
• Subscriptions

Notes:
• Guardian = Supervisor / Guardian.
• When "Guardian" is used, it always refers to the supervisory role.
• The Guardian is not the marriage candidate.

============================================================
DISCOVERY TERMINOLOGY
============================================================

------------------------------------------------------------
TERM: Browse
------------------------------------------------------------

Definition:
The primary profile discovery area within ZYRA where users
discover potential marriage candidates.

Purpose:
Allows users to discover and assess potential marriage
candidates before viewing more detailed profile information.

User Explanation:
Browse is where you discover potential marriage candidates
and make an initial decision about whether a profile may
be suitable.

Internal Explanation:
The primary discovery system used for first-stage marriage
consideration.

Found In:
• Bottom Navigation
• Browse Page
• Discovery Journey

Related Systems:
• Pass
• Save
• Consider
• Potentials
• Notifications
• Profile Pages

Notes:
• Browse focuses on first impressions.
• Browse is appearance-first.
• Browse does not display profile bios.
• Browse does not display detailed profile information.
• Browse does not allow messaging.
• Browse is intended to support fast profile discovery.

============================================================
PROFILE DECISION TERMINOLOGY
============================================================

------------------------------------------------------------
TERM: Pass
------------------------------------------------------------

RESOLVED 2026-07-25 (OA-ZYRA-140 item 15, Founder decision:
"Yes, rewrite it now"). This is the canonical glossary — the
last place still using the pre-DR-ZYRA-099 term "Decline",
renamed "Pass" everywhere else in the app on 2026-07-25.

Definition:
A decision indicating that a profile is not suitable for
marriage consideration.

Purpose:
Allows users to remove unsuitable profiles from their
discovery process.

User Explanation:
Pass means "this profile is not suitable for me."

Internal Explanation:
A negative profile decision that removes the profile from
active consideration.

Found In:
• Browse
• Profile Page

Related Systems:
• Browse
• Discovery

Notes:
• Available to Seekers.
• Not available to Guardians.
• Pass is a final rejection decision.

------------------------------------------------------------
TERM: Save
------------------------------------------------------------

Definition:
A private decision indicating the Seeker wants to come back
to a profile later. Does not indicate romantic interest.

Purpose:
Allows Seekers to revisit profiles later without signalling
interest to the other profile.

User Explanation:
Save means "I would like to come back to this profile later."

Internal Explanation:
A private holding decision. Saving is completely private
between ZYRA Basic users; only a mutual Save between two
ZYRA One users (or a ZYRA One user matched with a ZYRA Basic
user) generates a Mutual Save Detected notification, and only
for the ZYRA One side. See ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V4,
Part 2, Section 3.

Found In:
• Browse
• Profile Page

Related Systems:
• Browse
• Mutual Save Detection (ZYRA One)

Notes:
• Available to Seekers.
• Does not indicate romantic interest.
• Save does not create a Match on its own — only a mutual
  Save can be surfaced as a signal, and only to ZYRA One users.

------------------------------------------------------------
TERM: Consider
------------------------------------------------------------

RESOLVED 2026-07-25 (OA-ZYRA-140 item 15, Founder decision:
"Yes, rewrite it now"). This is the canonical glossary — the
last place still using the pre-DR-ZYRA-099 term "Like",
renamed "Consider" everywhere else in the app on 2026-07-25.

Definition:
A decision indicating genuine interest in pursuing this
person for marriage.

Purpose:
Allows Seekers to signal interest and initiate the path
toward a Match.

User Explanation:
Consider means "I would like to pursue this person."

Internal Explanation:
An interest signal. A mutual Consider between two Seekers is
the Match event — it creates a Potential Journey. Consider is
not the same as Match: Match is the event, Potential Journey is
the resulting state. See ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V4,
Part 0, Section 0.5 and Part 2, Section 4.

Found In:
• Browse
• Profile Page
• Incoming Potentials

Related Systems:
• Browse
• Potentials
• Match event
• Potential Journey

Notes:
• Available to Seekers.
• A single Consider is not revealed to the other profile until
  reciprocated.
• Mutual Consider = Match event = Potential Journey created.
• Considering a profile does not open a conversation and does
  not consume a Journey slot on its own — see Journey Slot
  Rules.

============================================================
ROLE RELATIONSHIPS
============================================================

| Role   | Meaning                                          |
|--------|--------------------------------------------------|
| Seeker | Person actively looking for marriage             |
| Guardian   | Supervisor / Guardian helping oversee the process|

| ZYRA Term | Equivalent Meaning       |
|-----------|--------------------------|
| Seeker    | Marriage Candidate       |
| Guardian      | Supervisor / Guardian    |

Usage Rules:
• "Seeker" always refers to the person seeking marriage.
• "Guardian" always refers to the supervisor or guardian.
• Seeker and Guardian are separate roles with different
  responsibilities.

Decision Permissions:

Seeker:
• Pass
• Save
• Consider

Guardian:
• Does not participate in Browse profile decisions. The Guardian's
  role is to represent and support their linked Seeker (see
  Guardian Architecture V5), not to browse or decide on profiles
  for themselves.

============================================================
DISCOVERY RELATIONSHIPS
============================================================

Browse Available To:
• Seeker (ZYRA Basic)
• Seeker (ZYRA One)

Guardian accounts do not use Browse — Browse is a Seeker-only
discovery surface. See ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V4,
Part 1, Section 3.

Primary Decisions:
• Pass
• Save
• Consider

Browse Purpose:
Browse    → Discovery
Save      → Come Back Later (private)
Consider  → Interested (may lead to Match)
Pass      → Not Suitable

Browse Philosophy:
• First impressions first.
• Decision before deeper profile information.
• Fast profile discovery.
• Appearance-first experience.

============================================================
DECISION RELATIONSHIPS
============================================================

Decision Flow:
Pass     → Not Suitable
Save     → Come Back Later (private, no interest signal)
Consider → Interested — mutual Consider triggers the Match event

Important:
• Consider = "I would like to pursue this person"
• Mutual Consider = Match event = Potential Journey created
• Match is an event, not a state — it does not open a
  conversation and does not consume a Journey slot by itself

Role Access:
• Seeker → Pass, Save, Consider
• Guardian   → Does not participate in Browse decisions

(UPDATED 2026-07-25, OA-ZYRA-140 item 15: Decline/Like renamed
Pass/Consider throughout this document, per DR-ZYRA-099.)

============================================================
APPROVED TO-DO LIST
============================================================

Terms still to be defined:
• Potential
• Consideration
• Connection
• Match
• Timeline
• Proposal Tracker
• Profile Unlock
• Network
• Incoming Potential
• Mutual Potential
• Notifications
• Discovery
• Subscription Terminology
• AI Terminology
• Trust Score
• Verification
• Compatibility Preview
• Compatibility Preview+
• Match Confidence
