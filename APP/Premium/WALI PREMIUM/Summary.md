FEATURE NAME
EXTENDED WALI
Group: 4 — Page Responsibilities

Superseded 2026-07-12: this document was previously "WALI
PREMIUM," describing Wali Premium as a paid tier separate from
"Seeker Pro." That model doesn't exist under ZYRA One (see
ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V3, Part 1, Section 7 and
Wali Architecture V5). The behavioural rules below are
unchanged from the original — connection state, authorisation,
and revocation logic did not depend on the old tier names —
only the terminology has been corrected: "Wali Premium" is now
"Extended Wali" (a capability set, not a subscription tier
name; AD-081), and "Seeker Pro" is now "ZYRA One."

============================================================
SUMMARY
============================================================

Purpose:
Define how Extended Wali capabilities work in relation to a
Seeker's ZYRA One entitlement, seeker authorisation, and the
wali network. Establish the transparency requirements for
wali-dependent functionality throughout the user journey.

------------------------------------------------------------
CORE DESIGN INTENT
------------------------------------------------------------

• A Seeker's ZYRA One and a Wali's Extended Wali entitlement
  are granted independently — see ZYRA Journey Capability
  Grant Rules V3 for how AIOS resolves each account's
  capabilities.
• Extended Wali does not grant independent matchmaking.
• Extended Wali improves safeguarding tools.
• Walis without a connected seeker remain view-only.
• Active participation in matchmaking requires an
  authorised seeker connection.
• Seeker authorisation is mandatory — not optional.
• Transparency about wali-dependent features is required
  throughout the user journey.
• Extended Wali access and wali participation are separate
  concepts that interact but do not replace each other.

------------------------------------------------------------
WALI NETWORK — NO CONNECTED SEEKER
------------------------------------------------------------

When a wali has no connected seeker, the following
remains available:

• Browse Network
• View Public Profiles
• Learn How the Network Works
• Configure Settings
• Accept Invitations

The following is restricted until a seeker connects:

• Matchmaking
• Messaging
• Interests
• Connections
• Shortlists
• Acting For A Seeker

Network remains view-only until a seeker is connected.

------------------------------------------------------------
SEEKER AUTHORISATION
------------------------------------------------------------

Connecting a wali grants the wali permission to:

• View Seeker Profile
• Participate in Safeguarding
• Access Approved Matchmaking Tools
• Access Seeker Management Features

Authorisation must be explicitly disclosed at:

• Connection Flow
• Confirmation Screen
• Terms of Service
• Privacy Policy
• Permissions Screens
• Premium Information

------------------------------------------------------------
ACCESS REVOCATION
------------------------------------------------------------

Disconnecting or replacing a wali immediately removes:

• Profile Access
• Matchmaking Permissions
• Network Permissions
• Seeker Management Permissions

Revocation is immediate. No grace period.

------------------------------------------------------------
EXTENDED WALI TRANSPARENCY REQUIREMENTS
------------------------------------------------------------

Certain Extended Wali features require an authorised
seeker connection before they become available.

Users must understand this dependency:

• Before downloading the app
• Before purchasing Extended Wali (independently, £9.99/month)
• Before attempting to use a wali-dependent feature

Transparency must appear at:

• App Store Listing
• Onboarding
• Extended Wali Upgrade Page
• Subscription Terms
• Feature Lock Screens
• FAQ

Rationale: Users who reach a wali-dependent feature
without understanding the seeker connection requirement
experience confusion and potential purchase regret.
Front-loading transparency reduces support burden and
App Store review risk.

============================================================
APPROVED TO-DO LIST
============================================================

• Design the seeker connection flow with full
  authorisation disclosure screens.
• Define the specific wali safeguarding tools included
  in Extended Wali.
• Design the Feature Lock Screen shown when a wali
  attempts a seeker-dependent feature without a
  connected seeker.
• Write the App Store listing language covering
  wali-dependent features.
• Define what "account review" looks like when a seeker
  revokes wali access mid-session.

Resolved 2026-07-12 (DR-075): Extended Wali pricing is
confirmed separate from a Seeker's ZYRA One — £9.99/month
if purchased independently by the Wali, or included free
as the one entitlement bundled with a Seeker's ZYRA One.
