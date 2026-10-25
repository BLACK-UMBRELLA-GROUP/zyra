---
id: DOC-ZYRA-0089
type: SPEC
status: CURRENT
feature: BUSINESS: APP BREAKDOWN
purpose: App Breakdown — Flow Diagram
links: []
owner: ZYRA chat
---

FEATURE NAME
APP BREAKDOWN

============================================================
FLOW DIAGRAM
============================================================

Note:
This is a living document. Add, remove, and update sections
as the app evolves.

Corrected 2026-07-12 against ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V4
(DR-076). The action terminology is now:
• Decline (was: Pass)
• Save (was: Review — this document previously had Save/Review
  reversed relative to the current spec)
• Like (was: Consider)

⚠️ Potentials section terminology (Sent/Received/Mutual etc.)
maps approximately onto the current model as: Sent ≈ Outgoing
Potentials, Received ≈ Incoming Potentials, Mutual ≈ Match — see
APP/Matching/PROFILE DECISION SYSTEM/Summary.md for the verified
current terms and rules. This section has not been rewritten to
match exactly; treat it as directional only until reviewed.

------------------------------------------------------------

APP START
│
├── Splash
├── Welcome
├── Sign Up
├── Login
├── Registration
├── Verification
├── Profile Setup
├── Guardian Setup
└── Home Dashboard
        │
        ├───────────────────────────────
        │
        ├── DISCOVER
        │      │
        │      ├── Browse
        │      ├── View Profile
        │      ├── View Photos
        │      ├── Filter
        │      ├── Search
        │      ├── Save
        │      ├── Like
        │      ├── Decline
        │      ├── Report
        │      ├── Block
        │      ├── ZYRA One Upsell Lock (was "Premium Lock" —
        │      │     shown when a ZYRA Basic limit is hit,
        │      │     e.g. daily Save/Like cap; prompts upgrade
        │      │     to ZYRA One)
        │      ├── No More Profiles
        │      ├── Daily Limit
        │      └── ...
        │
        ├───────────────────────────────
        │
        ├── POTENTIALS
        │      │
        │      ├── Sent
        │      ├── Received
        │      ├── Mutual
        │      ├── Waiting Bio
        │      ├── Accepted
        │      ├── Rejected
        │      ├── Expired
        │      └── ...
        │      ⚠️ Terminology pending review
        │
        ├───────────────────────────────
        │
        ├── PROFILE
        │      │
        │      ├── Edit
        │      ├── Photos
        │      ├── Verification
        │      ├── Preferences
        │      ├── Privacy
        │      ├── Visibility
        │      ├── Delete Photo
        │      ├── Reorder Photos
        │      ├── Preview Profile
        │      └── ...
        │
        ├───────────────────────────────
        │
        ├── CHAT
        │      │
        │      ├── Chat List
        │      ├── Conversation
        │      ├── Attachments
        │      ├── Voice
        │      ├── Report
        │      ├── Block
        │      ├── Archive
        │      ├── Delete
        │      └── ...
        │
        ├───────────────────────────────
        │
        ├── GUARDIAN
        │      │
        │      ├── Dashboard
        │      ├── Linked Seekers
        │      ├── Pending Requests
        │      ├── Approvals
        │      ├── Reject
        │      ├── Proposal Review
        │      ├── Meetings
        │      ├── Family Notes
        │      └── ...
        │
        ├───────────────────────────────
        │
        ├── PROPOSALS
        │      │
        │      ├── Proposal Created
        │      ├── Awaiting Response
        │      ├── Accepted
        │      ├── Rejected
        │      ├── Family Discussion
        │      ├── Meeting Planned
        │      ├── Engagement
        │      ├── Nikah
        │      └── Completed
        │
        ├───────────────────────────────
        │
        ├── SUBSCRIPTIONS
        │
        ├── PAYMENTS
        │
        ├── DONATIONS
        │
        ├── REWARDS
        │
        ├── SETTINGS
        │
        ├── HELP CENTRE
        │
        ├── REPORT USER
        │
        ├── NOTIFICATIONS
        │
        ├── SEARCH
        │
        ├── FILTERS
        │
        ├── AI FEATURES
        │
        ├── SAFETY CENTRE
        │
        ├── ACCOUNT MANAGEMENT
        │
        ├── DEVELOPER TOOLS
        │
        └── ADMIN TOOLS
