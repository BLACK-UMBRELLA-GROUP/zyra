---
id: DOC-ZYRA-0019
type: SPEC
status: CURRENT
feature: APP: JOURNEY
purpose: Journey / Journey Management — Summary: Defines how Journeys (active relationships) are managed, transitioned, and concluded.
links: []
owner: ZYRA chat
---

FEATURE NAME
JOURNEY MANAGEMENT
Group: 4 — Page Responsibilities

============================================================
SUMMARY
============================================================

Purpose:
Defines how Journeys (active relationships) are managed,
transitioned, and concluded. ZYRA does not use a
traditional "Unmatch" system.

Core Philosophy:
Connections are treated as Journeys rather than disposable
matches. Ending communication does not automatically erase
relationship history. Journey Timelines remain unless the
user explicitly requests permanent account/data deletion.

------------------------------------------------------------
JOURNEY ACTIONS
------------------------------------------------------------

END JOURNEY
  • Ends the current Journey for both Seekers.
  • Conversation closes.
  • Timeline remains available as a historical record.
  • The ended Journey cannot be resumed. Beginning together
    again is a new Journey and requires one Seeker to request
    it and the other to accept.
  • The other Seeker is notified when the Journey ends.
  • The existing 24-hour cooling period remains. After it,
    the direct New Journey request is available until 60 days
    after ended_at. Its acceptance must also happen inside that
    window; a pending request cannot extend it.
  • Connections shows the most recent 1 ended person on ZYRA
    Basic and the most recent 5 on ZYRA One. This is a UI
    display/action cap only; it never deletes older history.
  • After 60 days the direct request is removed. The pair may
    meet again only through ordinary Browser discovery and
    eligibility, beginning a completely new Journey.
  • Client window/caps are built. OA-ZYRA-242 owns matching
    server enforcement and post-window Browser rediscovery.
  Purpose: "This chapter has ended."

PAUSE JOURNEY
  RESOLVED 2026-07-25 (OA-ZYRA-140 item 7, Founder decision:
  "build all three now"). Full mechanics are ratified and now
  built in JOURNEY SUSPENSION/JOURNEY_SUSPENSION_CURRENT_
  VERSION_V1.md — this section previously duplicated that
  document with an unresolved "Concept" status and a
  redundant "STEP BACK / HOLD" alternative naming proposal.
  SUSPENSION V3 is the governing document for Pause/Resume;
  this section now simply points to it rather than
  re-specifying it:
  • Journey Suspension is a behavioural sub-state of an
    Active Journey (matches.status stays 'active';
    suspended_by/suspended_at record who paused it).
  • Both plans (corrected 2026-08-12 stewardship pass, DR-ZYRA-138): caps 5 (Basic) / 10 (ZYRA One)
    over pauses this Seeker initiated. See JOURNEY_SUSPENSION_CURRENT_VERSION_V2.md.
  • Conversation locks; Timeline preserved.
  • A pause is a personal hold. The other Seeker may Pause
    too, Request Continue, End Journey, or simply wait.
  • Each Seeker lifts only their own pause. Nothing
    Auto-Ends because a Seeker starts another Journey.
  • Pause and End each open a dedicated confirmation screen;
    the write occurs only after confirmation. Success receives
    its own outcome screen and Return to Connections action.
  See JOURNEY SUSPENSION/JOURNEY_SUSPENSION_CURRENT_VERSION_
  V3.md for full detail (sections 1-15) and
  ZyraJourneyService.suspendJourney/resumeJourney/endJourney
  for the implementation.

------------------------------------------------------------
TIMELINE
------------------------------------------------------------

• Timeline survives Journey ending.
• Conversation status and Timeline are separate concepts.
• May record "Journey Ended" as the final milestone
  (future discussion).
• Timeline is viewable even when the Journey has ended
  or is paused.

------------------------------------------------------------
ENDED JOURNEYS SECTION — BUILT / GOVERNED 2026-08-18
------------------------------------------------------------

  Users can:
  • View previous Journey Timeline, reflections and milestones.
  • During the 60-day post-End window, request a completely
    new Journey after the 24-hour cooling period.

  Users cannot:
  • Continue chatting in the ended Journey.
  • Resume the ended Journey.
  • Begin again without the other Seeker accepting.

  Basic lists the most recent 1 ended person and ZYRA One the
  most recent 5. Older records remain retained even when they
  are not listed. After day 60, rediscovery is Browser-only.

------------------------------------------------------------
FUTURE DISCUSSION — SAFETY & MODERATION
------------------------------------------------------------

**Update, 2026-07-25:** Block User / Report User for the Browse-
screen, pre-Journey, Seeker-to-Seeker case is now specified — see
`APP/Browse/BROWSE_UX_SPEC_CURRENT_VERSION_V4.md` §Profile Actions
(DR-ZYRA-095).

**Update, 2026-07-26 (DR-ZYRA-112):** how blocking affects an
existing Active Journey/Timeline, and menu contents across every
other relationship stage, are now also specified — see
`APP/Standards/PROFILE_ACTIONS_MENU_STANDARD_CURRENT_VERSION_V1.md`.
Blocking during an Active Journey or Family Stage now also force-ends
that Journey, in one confirmed action. Post-Journey-end privacy is
addressed for Report/Block specifically (both remain available after
a Journey ends); broader post-Journey privacy beyond these two
actions is not otherwise revisited here.

Still requires a dedicated future design discussion covering:
• Block Guardian
• Report Guardian
• How reporting interacts with moderation and evidence.

============================================================
OPEN DISCUSSIONS
============================================================

• How "Journey Ended" milestone appears on Timeline.
• Safety & Moderation for Guardian blocking/reporting specifically
  (Browse-stage Seeker-to-Seeker case resolved 2026-07-25; per-stage
  contents and Active-Journey blocking effects resolved 2026-07-26,
  DR-ZYRA-112 — this item now covers only Guardian block/report, still
  fully open).
