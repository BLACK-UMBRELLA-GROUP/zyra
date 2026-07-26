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
  • Permanently ends the Journey.
  • Conversation closes.
  • Timeline remains available as a historical record.
  • Journey cannot be resumed.
  • Users cannot rematch directly from an ended Journey.
  • If both users wish to reconnect, they must discover
    each other again through Browse/Search and begin a
    completely new Journey.
  Purpose: "This chapter has ended."

PAUSE JOURNEY
  RESOLVED 2026-07-25 (OA-ZYRA-140 item 7, Founder decision:
  "build all three now"). Full mechanics are ratified and now
  built in JOURNEY SUSPENSION/JOURNEY_SUSPENSION_CURRENT_
  VERSION_V1.md — this section previously duplicated that
  document with an unresolved "Concept" status and a
  redundant "STEP BACK / HOLD" alternative naming proposal.
  SUSPENSION is the governing document for Pause/Resume;
  this section now simply points to it rather than
  re-specifying it:
  • Journey Suspension is a behavioural sub-state of an
    Active Journey (matches.status stays 'active';
    suspended_by/suspended_at record who paused it).
  • Requires ZYRA One (seeker_premium plan).
  • Conversation locks; Timeline preserved.
  • Only the suspending Seeker may resume, unless the other
    party started a new Active Journey in the meantime, in
    which case the paused Journey Auto-Ends.
  • The non-suspending party may End Journey instead of
    waiting.
  See JOURNEY SUSPENSION/JOURNEY_SUSPENSION_CURRENT_VERSION_
  V1.md for full detail (sections 1-15) and
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
FUTURE DISCUSSION — ENDED JOURNEYS SECTION
------------------------------------------------------------

Potential future section within Matches or Settings:

  Ended Journeys

  Users can:
  • View previous Journey Timeline.
  • View previous reflections and milestones.
  • View Journey summary.

  Users cannot:
  • Continue chatting.
  • Resume the Journey.
  • Rematch directly.

  A new connection would require both users to find each
  other again through Browse/Search, creating a brand-new
  Journey.

------------------------------------------------------------
FUTURE DISCUSSION — SAFETY & MODERATION
------------------------------------------------------------

**Update, 2026-07-25:** Block User / Report User for the Browse-
screen, pre-Journey, Seeker-to-Seeker case is now specified — see
`APP/Browse/BROWSE_UX_SPEC_CURRENT_VERSION_V3.md` §Profile Actions
(DR-ZYRA-095). The remaining items below are **not** resolved by
that filing — it explicitly scopes itself to Browse only.

Still requires a dedicated future design discussion covering:
• Block Wali
• Report Wali
• How blocking affects existing Journeys and Timelines.
• How reporting interacts with moderation and evidence.
• Privacy implications after a Journey ends.

============================================================
OPEN DISCUSSIONS
============================================================

• Final name for "Step Back / Hold".
• Exact behaviour after stepping back.
• Whether stepping back requires both users to agree.
• Whether users can immediately begin another Journey
  after stepping back.
• Limits on inactive / held Journeys.
• How "Journey Ended" milestone appears on Timeline.
• Safety & Moderation for Wali blocking/reporting, and for
  blocking/reporting effects within an existing Active Journey
  (Browse-stage Seeker-to-Seeker case resolved 2026-07-25, see
  above — this item now covers only the remaining scope).
