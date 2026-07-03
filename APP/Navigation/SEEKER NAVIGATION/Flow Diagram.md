FEATURE NAME
SEEKER NAVIGATION

============================================================
FLOW DIAGRAM
============================================================

------------------------------------------------------------
SEEKER NAVIGATION STRUCTURE
------------------------------------------------------------

SEEKER BASIC / PRO
┌─────────────────────────────────────┐
│  Browse • Connections • Wali • Profile │
└─────────────────────────────────────┘

SEEKER PREMIUM
┌──────────────────────────────────────────────────┐
│  Browse • Connections • Wali • Network • Profile  │
└──────────────────────────────────────────────────┘

------------------------------------------------------------
WALI NAVIGATION STRUCTURE (TEMPORARY)
------------------------------------------------------------

WALI BASIC
┌──────────────────────────────┐
│  Dashboard • Seekers • Profile │
└──────────────────────────────┘

WALI PRO
┌─────────────────────────────────────────┐
│  Dashboard • Seekers • Browse • Profile  │
└─────────────────────────────────────────┘

WALI PREMIUM
┌────────────────────────────────────────────────────┐
│  Dashboard • Seekers • Browse • Network • Profile   │
└────────────────────────────────────────────────────┘

------------------------------------------------------------
NAVIGATION STATE FLOW
------------------------------------------------------------

User opens app
        │
        ▼
MAIN NAVIGATION displayed
(Browse • Connections • Wali • Profile)
        │
        ▼
User taps Connections
        │
        ▼
CONNECTIONS NAVIGATION displayed
Left: Floating Back Button
Right: Last 5 Declined • Review • Considerations
       • Incoming Considerations • Matches
        │
        ▼
User taps Back Button
        │
        ▼
Returns to MAIN NAVIGATION

------------------------------------------------------------
CONNECTIONS RELATIONSHIP JOURNEY
------------------------------------------------------------

Review
  │
  ▼
Consider
  │
  ▼
Match
  │
  ▼
Communication
  │
  ▼
Family Introduction

------------------------------------------------------------
BROWSE END OF SEARCH FLOW
------------------------------------------------------------

No more profiles
        │
        ▼
"No more profiles right now."
"Check back soon, in shaa Allah."
        │
        ├── Restart Search
        │   (Declined + Reviewed profiles may reappear)
        │
        └── Edit Search Filters (Future)
