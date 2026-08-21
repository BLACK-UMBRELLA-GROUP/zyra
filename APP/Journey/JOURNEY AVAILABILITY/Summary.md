FEATURE NAME
JOURNEY AVAILABILITY
Group: 4 — Page Responsibilities

============================================================
SUMMARY
============================================================

Purpose:
Defines how Journey slots work, how ZYRA determines which
Journey Queue are eligible to begin, and how the AI
recommends the next Journey.

------------------------------------------------------------
CORE PRINCIPLE
------------------------------------------------------------

Users may have:
• Many Likes
• Many Matches
• Many Journey Queue

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
• Continue building a list of Journey Queue

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

Journey Queue remain available until they either:
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

Once available, ZYRA evaluates which Journey Queue
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
  Journey Queue:
  • Yusuf   (currently in a Journey)    — not eligible
  • Ibrahim (available)                 — eligible
  • Omar    (inactive)                  — not eligible
  • Adam    (available)                 — eligible

------------------------------------------------------------
AVAILABILITY STATUS (USER-FACING) — added 2026-07-25, DR-ZYRA-097
------------------------------------------------------------

Source: OA-ZYRA-133 (ChatGPT UX proposal, 2026-07-19). Resolution:
Founder and ChatGPT both confirmed this is a UX presentation layer
over the Journey Eligibility concept above — not a new architectural
state. No new relationship state introduced; Product Spec V3 Part 0
(Feature-State Covenant) unaffected. Filed here rather than as a
separate document, per the same reuse-not-duplicate discipline as
DR-ZYRA-092/093/095.

**Terminology split** (deliberate, ChatGPT's recommendation):
  Backend / business logic → "Journey Eligibility" (unchanged, as
    defined above: eligible / not eligible, with a reason).
  Frontend / user interface → "Availability Status" (new — the
    coloured, plain-language presentation of that same eligibility
    value).

The backend continues to determine eligibility and, if not eligible,
the reason why. The frontend presents that using ZYRA's existing
traffic-light colours only — no new colours (white, black, blue, grey)
are introduced; users already read 🟢 = yes, 🟡 = maybe/depends, 🔴 =
no from elsewhere in the product.

| Internal Journey Eligibility | User-Facing Availability Status |
|-------------------------------|----------------------------------|
| Eligible | 🟢 Available |
| Not Eligible — Active Journey | 🟡 Currently in an Active Journey |
| Not Eligible — Account Paused | 🔴 Unavailable |
| Not Eligible — Account Hidden/Inactive | 🔴 Unavailable |

Example, in the Journey Queue list:
  Journey Queue (9)
  🟢 Aisha — Available
  🟡 Maryam — Currently in an Active Journey

**Privacy (carried over from OA-ZYRA-133's source content):** never
show private information about another user's Journey — no duration,
stage, compatibility progress, family discussions, proposal status,
or estimated completion. Availability Status is the only Journey-
related information ever shown about another user.

**Note on the original 4-status proposal:** OA-ZYRA-133's source
content proposed four visually distinct statuses (🟢🟡⚪⚫ — Available /
In Active Journey / Paused / Hidden-Inactive). Resolved to three
colours: Paused and Hidden/Inactive both collapse to 🔴 Unavailable,
since introducing new colours (⚪/⚫) beyond ZYRA's existing traffic-
light system was explicitly rejected in favour of visual consistency.
The underlying eligibility reasons (Paused vs. Hidden/Inactive) are
still distinguishable on the backend — only the user-facing colour is
unified.

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
• Pause Journey
• End Journey

============================================================
OPEN DISCUSSIONS
============================================================

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

**Current Founder ruling, 2026-08-18 (DR-ZYRA-206):** End closes the
current Journey. It is never resumed or reopened. A future relationship
between the same two Seekers is a **New Journey**, initiated by request
and begun only if the other Seeker accepts.

When a Journey ends (no block / no report):
• 24-hour cooling period begins (no actions possible).
• Journey slot freed for both parties.
• The other Seeker is notified.
• Old timeline is preserved as read-only history.
• After cooling, either party may Request New Journey until 60 days
  after ended_at, subject to the existing request/accept rules. Request
  and acceptance must both complete inside the window; pending does not
  extend it.
• Basic Connections lists the 1 most recent ended person; ZYRA One
  lists the 5 most recent. This is display/action scope, never deletion.
• After 60 days, the direct request is no longer available. The two
  Seekers must encounter one another again through Browser under the
  ordinary visibility and eligibility rules.

NEW JOURNEY AFTER END:
• A request is not a restart and never reopens the old attempt.
• The other Seeker may accept or decline.
• If accepted, the new attempt begins from the start of the Journey.
• Old timeline remains visible as historical record.
• Client display/window rules are built. OA-ZYRA-242 owns the server
  60-day refusal and Browser rediscovery behaviour; those are not
  production-complete until the database-enabled session verifies them.

When a Journey ends WITH a block:
• Both parties disappear from each other's view entirely.
• No direct New Journey request is possible.
• Match is removed.
• No trace remains in Matched list.

------------------------------------------------------------
PAUSE vs END — KEY DISTINCTION
------------------------------------------------------------

PAUSE:
• Temporary personal hold — journey resumes exactly
  where it left off.
• Use when: not ready right now but still interested.

END:
• Deliberate, final choice.
• The ended attempt never resumes. A later accepted request creates
  a completely new Journey during the 60-day direct-request window;
  after that, the pair must meet through Browser again.
• Use when: this journey is no longer right for you.
