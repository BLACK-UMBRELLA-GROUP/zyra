FEATURE NAME
MATCHES PAGE
Group: 4 — Page Responsibilities

============================================================
SUMMARY
============================================================

Purpose:
Houses all of the user's matches and provides entry into
each Relationship Space (Journey).

Core Principle:
Keep the Matches page simple. Avoid introducing additional
UI or unnecessary complexity until the Relationship Space
can be built and tested visually.

------------------------------------------------------------
COLLAPSED MATCH CARD
------------------------------------------------------------

The collapsed card remains simple.

Two actions only:
1. Tap the card to expand it.
2. Tap the arrow to enter the Relationship Space.

No additional actions are introduced on the collapsed card.

------------------------------------------------------------
EXPANDED MATCH CARD
------------------------------------------------------------

Expanding the card provides additional profile information
as it does today.

The expanded card also contains the entry point into the
Relationship Space.

No separate expandable relationship summary will be added
at this stage. The existing expansion is reused rather
than creating another layer of UI.

------------------------------------------------------------
RELATIONSHIP SPACE ENTRY
------------------------------------------------------------

Selecting the entry from the expanded card opens the
shared Relationship Space.

This is the permanent home of the relationship.

The Relationship Space contains:
• Timeline
• Active Journey stage
• Wali
• Profile
• Chat (when unlocked)

See: RELATIONSHIP SPACE/Summary.md

------------------------------------------------------------
CURRENT ACTIVE CONVERSATION RULE
------------------------------------------------------------

Only one active conversation is permitted.

Users may still enter the Relationship Space for other
matches.

If another relationship currently has the active
conversation:
• Timeline remains viewable.
• Relationship progress remains viewable.
• Further communication cannot continue until the
  current active conversation ends or is changed
  according to ZYRA's conversation rules.

This allows users to revisit previous progress without
creating multiple active conversations.

------------------------------------------------------------
FUTURE DISCUSSION — MATCHES ORGANISATION
------------------------------------------------------------

Potential future organisation of the Matches page:

  📌 Pinned Journeys     (currently active conversations)
  💬 Active Journeys     (ongoing conversations)
  🤝 Matched             (matched but Journey not yet started)
  ⏸ Paused Journeys     (temporarily paused)
  🏁 Ended Journeys      (historical Journeys)

Not approved. Requires dedicated future design session.

------------------------------------------------------------
DESIGN PHILOSOPHY
------------------------------------------------------------

• Keep navigation minimal.
• Avoid adding more buttons.
• Build the simplest version first.
• Only expand functionality after seeing and testing
  the interface visually.
• Future improvements based on real user experience,
  not assumptions.

============================================================
APPROVED TO-DO LIST
============================================================

• Design the collapsed match card.
• Design the expanded match card.
• Design the arrow / entry point into Relationship Space.
• Confirm the exact UI for the active conversation
  restriction state (Timeline visible but chat locked).
• Decide final Matches page organisation (future session).
