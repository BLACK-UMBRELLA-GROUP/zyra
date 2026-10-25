---
id: DOC-ZYRA-0106
type: SPEC
status: CURRENT
feature: BUSINESS: USER FEATURES
purpose: User Features — Flow Diagram
links: []
owner: ZYRA chat
---

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
            Has Guardian?
           │         │
          YES        NO
           │         │
           ▼         ▼
    Pro/Premium    Pro/Premium
    (Guardian)         (No Guardian)
    + Messaging    No Messaging
    + Guardian tab     No Guardian tab

------------------------------------------------------------
GUARDIAN TIER PROGRESSION
------------------------------------------------------------

Guardian Registers
        │
        ▼
  Selects Guardian Plan
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
            Guardian Network
            Family Intros
            Guardian-Guardian Chat

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
