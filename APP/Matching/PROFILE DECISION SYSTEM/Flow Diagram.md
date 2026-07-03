FEATURE NAME
PROFILE DECISION SYSTEM

============================================================
FLOW DIAGRAM
============================================================

------------------------------------------------------------
CORE DECISION FLOW
------------------------------------------------------------

Seeker views profile in Browser
            │
            ▼
    ┌───────────────┐
    │  Make Decision │
    └───────────────┘
       │        │        │
       ▼        ▼        ▼
   Decline   Review   Consider
       │        │        │
       ▼        ▼        ▼
   Next      Added     Added to
  Profile   to Review  Considerations

------------------------------------------------------------
MATCH CREATION FLOW
------------------------------------------------------------

Seeker A considers Seeker B
            │
            ▼
  Does Seeker B consider Seeker A?
       │               │
      YES              NO
       │               │
       ▼               ▼
  Mutual              No Match
  Consideration       Created
  Created
       │
       ▼
  Match Created
       │
       ▼
  Both Seekers Notified
       │
       ▼
  Communication System
  controls next steps

------------------------------------------------------------
MUTUAL REVIEW DETECTION FLOW (PREMIUM ONLY)
------------------------------------------------------------

Seeker A (Premium) reviews Seeker B
            │
            ▼
  Is Seeker B also Premium?
       │               │
      YES              NO
       │               │
       ▼               ▼
  Has Seeker B       No Detection
  reviewed           No Notification
  Seeker A?
       │
      YES
       │
       ▼
  Mutual Review Detected
       │
       ▼
  Both Seekers Notified:
  "A profile you reviewed has also reviewed
   your profile. Would you like to move this
   profile to Consideration?"
       │
       ▼
    ┌─────────────────────────┐
    │     Both choose         │
    │   Move to Consideration │
    └─────────────────────────┘
       │               │
    BOTH YES        ONE/BOTH NO
       │               │
       ▼               ▼
  Mutual             No Match
  Consideration      Profile stays
  + Match Created    in Review

------------------------------------------------------------
CONSIDERATION REMOVAL FLOW
------------------------------------------------------------

Seeker removes a Consideration
            │
            ▼
  Consideration removed
            │
            ▼
  Other Seeker notified
            │
            ▼
  Event recorded in Relationship Timeline
            │
            ▼
  Other Seeker's Consideration remains active
            │
            ▼
  Future reconsideration allowed
  (unless blocked)

------------------------------------------------------------
REVIEW LIST CAPACITY FLOW
------------------------------------------------------------

Seeker tries to add profile to Review
            │
            ▼
  Review list below 50?
       │               │
      YES              NO
       │               │
       ▼               ▼
  Profile added     Must remove a profile
  to Review         before adding new one
