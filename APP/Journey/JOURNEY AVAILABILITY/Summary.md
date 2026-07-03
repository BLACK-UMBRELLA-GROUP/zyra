FEATURE NAME
JOURNEY AVAILABILITY
Group: 4 — Page Responsibilities

============================================================
SUMMARY
============================================================

Purpose:
Defines how Journey slots work, how ZYRA determines which
Potential Journeys are eligible to begin, and how the AI
recommends the next Journey.

------------------------------------------------------------
CORE PRINCIPLE
------------------------------------------------------------

Users may have:
• Many Likes
• Many Matches
• Many Potential Journeys

Users may only have:
• One Active Journey at a time

A Match does NOT create a conversation.
A Journey creates a conversation.

------------------------------------------------------------
ACTIVE JOURNEY
------------------------------------------------------------

While in an Active Journey, users can still:
• Browse profiles
• Like profiles
• Save profiles
• Receive Likes
• Receive Matches
• Continue building a list of Potential Journeys

However, users cannot:
• Start a second Active Journey
• Open multiple Journey conversations simultaneously

The restriction is on active conversations, not on matching.

------------------------------------------------------------
POTENTIAL JOURNEYS
------------------------------------------------------------

When two users match, they become a Potential Journey.

A Potential Journey is a mutual match that has not yet
become an Active Journey.

Potential Journeys remain available until they either:
• Become an Active Journey
• Are removed by either user
• Become temporarily unavailable

------------------------------------------------------------
JOURNEY SLOT
------------------------------------------------------------

Each user has one Active Journey Slot.

When occupied:
• No new Journey conversations can begin.

When available:
• ZYRA prepares the next Journey opportunity.

------------------------------------------------------------
RETURNING TO THE JOURNEY POOL
------------------------------------------------------------

A Journey Slot may become available when:
• A Journey ends
• A Journey is stepped back from / placed on hold
• Other future Journey states free the slot

Once available, ZYRA evaluates which Potential Journeys
are currently eligible.

------------------------------------------------------------
JOURNEY ELIGIBILITY
------------------------------------------------------------

Not every Potential Journey will always be eligible.

Eligibility may consider:
• User is not already in an Active Journey
• User is active on ZYRA
• Compatibility score
• Shared preferences
• Future compatibility factors

Example:
  Potential Journeys:
  • Yusuf   (currently in a Journey)    — not eligible
  • Ibrahim (available)                 — eligible
  • Omar    (inactive)                  — not eligible
  • Adam    (available)                 — eligible

------------------------------------------------------------
AI-CURATED JOURNEY RECOMMENDATIONS
------------------------------------------------------------

Current preferred direction.

Rather than showing every available match, ZYRA
intelligently recommends the next Journey.

Recommendation may consider:
• Compatibility
• Availability
• Activity
• Shared goals and preferences
• Future recommendation factors

Example:
  "Your next recommended Journey is Sarah."
  Options:
  • Begin Journey
  • Show Another Recommendation

The AI curates the recommendation.
The user always makes the final decision.

This keeps the experience moving while preserving
user choice.

------------------------------------------------------------
USER AVAILABILITY
------------------------------------------------------------

Users inactive for an extended period (e.g. 5 days —
subject to review) are temporarily marked as:
  "Not Ready To Begin A Journey"

Effects:
• They remain matched.
• They are not removed.
• They are temporarily excluded from Journey
  recommendations.
• Active users are not left waiting for inactive users.
• Once the inactive user returns, they automatically
  become eligible again.

This keeps Journey recommendations current and progressive.

------------------------------------------------------------
JOURNEY STATUS OPTIONS
------------------------------------------------------------

Current direction — a Journey should support more than
two outcomes:
• Continue Journey
• Step Back / Hold (working name — see Journey Management)
• End Journey

============================================================
OPEN DISCUSSIONS
============================================================

• Final name for "Step Back / Hold".
• Exact behaviour after stepping back.
• Whether stepping back requires both users to agree.
• Whether users can immediately begin another Journey
  after stepping back.
• Limits on inactive / held Journeys.
• How AI recommendations should be prioritised
  (compatibility, activity, family preferences, etc.).
• How long a user should be inactive before being marked
  "Not Ready To Begin A Journey" (5 days is working figure,
  subject to review).

------------------------------------------------------------
PRE-JOURNEY RITUAL
------------------------------------------------------------

A conversation does NOT open immediately when a Journey
begins. The Pre-Journey Ritual must be completed by
both parties first.

The ritual is the gate between a Potential Journey and
the Conversation Stage.

Ritual Stages:
1. Salam Exchange (both must act)
2. Phase 1 Questions — AI-chosen, simultaneous reveal
3. Phase 2 Questions — negative-focused, simultaneous reveal
4. Phase 3 Questions — user-chosen, simultaneous reveal

Only after Phase 3 is complete does the Conversation
Stage open.

See: PRE-JOURNEY RITUAL/Summary.md

------------------------------------------------------------
AUTO-PAUSE (INACTIVE JOURNEY)
------------------------------------------------------------

Approved direction:
If a Journey goes quiet for 7 days with no activity from
either party, it automatically moves to a paused state.

Effects:
• Journey slot is freed for both users.
• Timeline is preserved.
• Journey can be resumed if both parties agree.
• Neither party is required to formally end the journey.

Purpose:
Prevents dead journeys from permanently blocking users'
Journey slots. Keeps the pool moving naturally.

7-day threshold is subject to review.

------------------------------------------------------------
ENDED JOURNEY — RULES
------------------------------------------------------------

When a Journey ends (no block / no report):
• 24-hour cooling period begins (no actions possible).
• After 24 hours, journey officially disconnects.
• Journey slot freed for both parties.
• Match remains visible in Matched list (greyed, at bottom).
• Old timeline is preserved as read-only history.
• Either party may choose to Restart.

RESTART:
• Restart = full fresh start from the beginning.
• Process begins again from Compatibility Reveal.
• This is intentional — End is a deliberate choice.
• Pause exists for users who want to hold without ending.
• Restarting earns the journey again from scratch.
• Old timeline remains visible as historical record.

Reason:
"If you ended it and want a free pass back in,
 why didn't you pause?"

When a Journey ends WITH a block:
• Both parties disappear from each other's view entirely.
• No restart possible.
• Match is removed.
• No trace remains in Matched list.

------------------------------------------------------------
PAUSE vs END — KEY DISTINCTION
------------------------------------------------------------

PAUSE:
• Temporary hold — slot held, journey resumes exactly
  where it left off.
• Use when: not ready right now but still interested.

END:
• Deliberate, final choice.
• Restart requires going through the full process again.
• Use when: this journey is no longer right for you.

