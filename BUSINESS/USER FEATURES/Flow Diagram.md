FEATURE NAME
USER FEATURES

============================================================
FLOW DIAGRAM
============================================================

------------------------------------------------------------
SEEKER TIER PROGRESSION
------------------------------------------------------------

New User Registers
        │
        ▼
  Selects Seeker Plan
        │
   ┌────┴────────────┐
   ▼                 ▼
Basic            Pro / Premium
   │                 │
   ▼                 ▼
Browse only      Browse + Consider
(50 per 4hrs)    (Unlimited)
No Matches       View Matches
No Messaging     │
                 ▼
            Has Wali?
           │         │
          YES        NO
           │         │
           ▼         ▼
    Pro/Premium    Pro/Premium
    (Wali)         (No Wali)
    + Messaging    No Messaging
    + Wali tab     No Wali tab

------------------------------------------------------------
WALI TIER PROGRESSION
------------------------------------------------------------

Wali Registers
        │
        ▼
  Selects Wali Plan
        │
   ┌────┴────────────┐
   ▼                 ▼
Basic            Pro / Premium
   │                 │
   ▼                 ▼
View only        View + Act
Read chats       Approve/Concern
No messaging     Send messages
No browsing      Browse + Suggest
                 │
                 ▼
            Premium only
            Wali Network
            Family Intros
            Wali-Wali Chat

------------------------------------------------------------
FEATURE ACCESS GATE (GENERAL)
------------------------------------------------------------

User attempts a feature
        │
        ▼
Is feature included in their plan?
        │               │
       YES              NO
        │               │
        ▼               ▼
  Feature unlocked   Upgrade prompt shown
