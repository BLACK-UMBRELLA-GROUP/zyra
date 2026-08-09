FEATURE NAME
PROFILE DECISION SYSTEM
Group: 4 — Page Responsibilities

Superseded 2026-07-12: rewritten against
ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V4 (Part 0 Section 0.5, Part
2 Sections 3-4) and DR-076. The previous version described a
Decline/Review/Consider model with a 50-profile Review cap and
a Mutual Consideration match rule — retired. This version
reflects the actual current model: Decline/Save/Like, Match as
an event (not a state), Potential Journey as the resulting
record. Original preserved in
ZYRA_TERMINOLOGY_PRICING_AUDIT_2026-07-12_V1.md for reference.

**Terminology updated 2026-07-25, DR-ZYRA-099 (Founder decision):**
Decline → **Pass**, Like → **Consider**. Save is unchanged. Colours
are unchanged (🔴/🟡/🟢) — this is a label change, not a new
taxonomy or a reintroduction of the retired 2026-07-12
Decline/Review/Consider model above (note "Consider" here replaces
"Like," not "Review" — a different mapping than the retired model
used, coincidence of wording only). The underlying data model
(Outgoing/Incoming Potentials, Match event, Mutual Save Detection)
is entirely unchanged — only the two labels. Interaction mechanism
(swipe vs. tap) is owned by `APP/Navigation/SEEKER NAVIGATION/
Summary.md` and `APP/Browse/BROWSE_UX_SPEC_CURRENT_VERSION_V3.md`,
not this document — see those for the swipe-gesture decision made
the same day.

============================================================
SUMMARY
============================================================

Purpose:
Defines the profile decision system used by Seekers on Browse.

Owns:
- Pass / Save / Consider
- Outgoing Potentials
- Incoming Potentials
- Match event / Potential Journey creation
- Mutual Save Detection
- Journey Timeline (Browse-stage events)

------------------------------------------------------------
TERMINOLOGY
------------------------------------------------------------

Seeker
- The person searching for marriage.
- The primary user making profile decisions.
- Holds ZYRA Basic (free) or ZYRA One (£34.99/month).

Guardian
- The Seeker's supervisor/guardian.
- Provides guidance and oversight throughout the marriage process.
- Does not participate in Browse profile decisions — Browse is
  Seeker-only (ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V4, Part 1,
  Section 3). The Guardian's role is oversight of the Seeker's
  Journey once one exists, not making decisions on Browse.

------------------------------------------------------------
ACTIONS (renamed 2026-07-25 — was "BUTTONS"; see terminology
note above. No longer button-only, see interaction mechanism
note above.)
------------------------------------------------------------

🔴 Pass (was: Decline)
- Profile is passed on.
- Discovery moves to the next profile.
- No notification is sent. No explanation given. The other
  Seeker is never informed.

🟡 Save (unchanged)
- Added to the Seeker's private Saves.
- Does not indicate romantic interest — "I would like to come
  back to this profile later."
- Does not create an Outgoing Potential.
- Does not create a Match on its own.

🟢 Consider (was: Like)
- Added to the Seeker's Outgoing Potentials.
- Indicates genuine interest — "I would like to pursue this
  person."
- Mutual Consider = Match event = Potential Journey created.

------------------------------------------------------------
ACTION ACCESS (renamed 2026-07-25 — was "BUTTON ACCESS")
------------------------------------------------------------

Seeker (ZYRA Basic)
- 🔴 Pass
- 🟡 Save — up to 10/day
- 🟢 Consider — up to 10/day

Seeker (ZYRA One)
- 🔴 Pass
- 🟡 Save — unlimited
- 🟢 Consider — unlimited

------------------------------------------------------------
LISTS
------------------------------------------------------------

Saves
- Private list. Does not indicate romantic interest.
- Users can remove a Save at any time.
- No 50-profile cap — Basic is capped at 10 new Saves/day,
  ZYRA One is unlimited. There is no separate storage limit.

Outgoing Potentials
- Profiles the Seeker has Considered, awaiting reciprocation.
- Separate from Saves.
- Users can remove an Outgoing Potential at any time.

Incoming Potentials
- Shows Seekers who have Considered your profile.
- ZYRA One receives Incoming Potentials immediately. ZYRA
  Basic does not see who Considered them until they Consider back
  (at which point the Match event fires) — see Consider Rules,
  ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V4, Part 2, Section 4 (updated
  2026-07-26, #25/OA-ZYRA-138, to this same terminology).
- Removed Considers no longer appear.

Journey Queue
- Created by the Match event (mutual Consider).
- A passive record of mutual interest — no conversation, no
  Journey slot consumed. Progresses to an Active Journey via
  the Pre-Journey Ritual.

------------------------------------------------------------
MATCH CREATION
------------------------------------------------------------

A Match event occurs when:
- Seeker A Considers Seeker B.
- Seeker B Considers Seeker A.

Result:
- Match event fires (an event, not a lifecycle stage).
- Potential Journey created.
- Both Seekers notified.
- Guardian approval is not required for the Match event.
- No conversation opens and no Journey slot is consumed at
  this point — see ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V4, Part
  0, Sections 0.5-0.6.

------------------------------------------------------------
MUTUAL SAVE DETECTION
------------------------------------------------------------

A Mutual Save occurs when:
- Seeker A saves Seeker B.
- Seeker B saves Seeker A.

Detection and notification depend on both Seekers' entitlement
(ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V4, Part 2, Section 3):

| Combination            | Result |
|-------------------------|--------|
| Basic ↔ Basic           | Completely private. Neither notified. |
| Basic ↔ One             | ZYRA One user receives Mutual Save Detected. Basic user receives nothing. |
| One ↔ Basic              | Same as above. |
| One ↔ One                | Both receive Mutual Save Detected. |

A single Save is never revealed. Only a mutual Save can
generate a notification, and only to the ZYRA One side of the
pair.

A Mutual Save Detected notification does not itself create a
Match — the Match event only fires on a mutual Consider.

------------------------------------------------------------
OUTGOING POTENTIAL REMOVAL
------------------------------------------------------------

When a Seeker removes an Outgoing Potential (un-Considers before
reciprocation):
- Their Consider is removed.
- The other Seeker receives a notification, if they had already
  received an Incoming Potential (ZYRA One recipients only).
- The event is recorded in the Journey Timeline.
- Future re-Considering is allowed unless the Seeker has been
  blocked.
- Communication permissions are handled by the Communication System.

------------------------------------------------------------
JOURNEY TIMELINE (BROWSE-STAGE EVENTS)
------------------------------------------------------------

Every profile interaction is recorded in a timeline.

Purpose:
- Relationship history.
- Transparency.
- Guardian supervision (once a Journey exists).
- Support and moderation.
- Future family introduction tracking.

Example Timeline:
01 Jun  Seeker A saved Seeker B
03 Jun  Seeker B considered Seeker A
05 Jun  Seeker A considered Seeker B
05 Jun  Match event — Potential Journey created
12 Jun  Seeker B removed their Consider
15 Jun  Seeker B considered Seeker A again
18 Jun  Pre-Journey Ritual completed — Active Journey began
22 Jun  Messaging paused

------------------------------------------------------------
TIMELINE EVENTS
------------------------------------------------------------

- Save Added
- Save Removed
- Consider Added
- Consider Removed
- Match Event
- Potential Journey Created
- Active Journey Started
- Journey Ended
- Messages Started
- Messages Paused
- Guardian Added
- Guardian Removed
- Family Introduction Requested
- Family Introduction Accepted

------------------------------------------------------------
TIMELINE ACCESS
------------------------------------------------------------

Seeker  — Can view their own Journey timelines.
Guardian    — Can view timelines for Journeys they supervise (once
          an Active Journey exists — Guardian is not involved at
          the Browse/Potential Journey stage).
Admin   — Can view timelines for support, moderation and dispute resolution.

------------------------------------------------------------
PHILOSOPHY
------------------------------------------------------------

🔴 Pass     = This profile is not suitable for me.
🟡 Save     = I would like to come back to this profile later.
🟢 Consider = I would like to pursue this person.

A Match event occurs only when both Seekers Consider each other.
Saving a profile is a private action that does not signal
interest.

**Updated 2026-07-25:** the system is designed around genuine
interest and progression toward marriage. The interaction
mechanism is now swipe-based (see SEEKER NAVIGATION/Summary.md and
BROWSE_UX_SPEC_CURRENT_VERSION_V3.md, DR-ZYRA-099) — the Founder's
explicit 2026-07-25 decision was that swipe gestures give a
cleaner UI without reintroducing dating-app-style casualness, since
the underlying philosophy (genuine, deliberate, one-decision-at-a-
time progression toward marriage) is unchanged; only "no swipe
gestures, ever" as a blanket rule is superseded. The previous
"rather than dating-style swiping" framing here described the
button-based mechanism that predated this decision — the
progression-toward-marriage philosophy itself has not changed.

------------------------------------------------------------
ENTITLEMENT ALIGNMENT
------------------------------------------------------------

ZYRA Basic
- Pass
- Save — up to 10/day
- Consider — up to 10/day
- Incoming Potentials not shown until reciprocated

ZYRA One
- Pass
- Save — unlimited
- Consider — unlimited
- Incoming Potentials shown immediately
- Mutual Save Detection
- Profile Unlock Plus on Active Journey creation

============================================================
APPROVED TO-DO LIST
============================================================
(None listed in source — add as decisions are made.)
