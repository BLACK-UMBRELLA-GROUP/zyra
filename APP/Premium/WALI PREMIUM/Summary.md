FEATURE NAME
GUARDIAN ONE
Group: 4 — Page Responsibilities

Superseded 2026-07-12: this document was previously "GUARDIAN
PREMIUM," describing Guardian Premium as a paid tier separate from
"Seeker Pro." That model doesn't exist under ZYRA One (see
ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V5, Part 1, Section 7 and
Guardian Architecture V6). The behavioural rules below are
unchanged from the original — connection state, authorisation,
and revocation logic did not depend on the old tier names —
only the terminology has been corrected: "Guardian Premium" is now
"Guardian+" (a capability set, not a subscription tier
name; AD-081), and "Seeker Pro" is now "ZYRA One."

============================================================
SUMMARY
============================================================

Purpose:
Define how Guardian+ capabilities work in relation to a
Seeker's ZYRA One entitlement, seeker authorisation, and the
guardian network. Establish the transparency requirements for
guardian-dependent functionality throughout the user journey.

------------------------------------------------------------
CORE DESIGN INTENT
------------------------------------------------------------

• A Seeker's ZYRA One and a Guardian's Guardian+ entitlement
  are granted independently — see ZYRA Journey Capability
  Grant Rules V3 for how AIOS resolves each account's
  capabilities.
• Guardian+ does not grant independent matchmaking.
• Guardian+ improves safeguarding tools.
• Guardians without a connected seeker remain view-only.
• Active participation in matchmaking requires an
  authorised seeker connection.
• Seeker authorisation is mandatory — not optional.
• Transparency about guardian-dependent features is required
  throughout the user journey.
• Guardian+ access and guardian participation are separate
  concepts that interact but do not replace each other.

------------------------------------------------------------
GUARDIAN NETWORK — NO CONNECTED SEEKER
------------------------------------------------------------

When a guardian has no connected seeker, the following
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

Connecting a guardian grants the guardian permission to:

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

Disconnecting or replacing a guardian immediately removes:

• Profile Access
• Matchmaking Permissions
• Network Permissions
• Seeker Management Permissions

Revocation is immediate. No grace period.

------------------------------------------------------------
GUARDIAN ONE TRANSPARENCY REQUIREMENTS
------------------------------------------------------------

Certain Guardian+ features require an authorised
seeker connection before they become available.

Users must understand this dependency:

• Before downloading the app
• Before purchasing Guardian+ (independently, £9.99/month)
• Before attempting to use a guardian-dependent feature

Transparency must appear at:

• App Store Listing
• Onboarding
• Guardian+ Upgrade Page
• Subscription Terms
• Feature Lock Screens
• FAQ

Rationale: Users who reach a guardian-dependent feature
without understanding the seeker connection requirement
experience confusion and potential purchase regret.
Front-loading transparency reduces support burden and
App Store review risk.

============================================================
APPROVED TO-DO LIST
============================================================

• Design the seeker connection flow with full
  authorisation disclosure screens.
• Define the specific guardian safeguarding tools included
  in Guardian+.
• Design the Feature Lock Screen shown when a guardian
  attempts a seeker-dependent feature without a
  connected seeker.
• Write the App Store listing language covering
  guardian-dependent features.
• Define what "account review" looks like when a seeker
  revokes guardian access mid-session.

Resolved 2026-07-12 (DR-075): Guardian+ pricing is
confirmed separate from a Seeker's ZYRA One — £9.99/month
if purchased independently by the Guardian, or included free
as the one entitlement bundled with a Seeker's ZYRA One.

------------------------------------------------------------
GATING — BUILT 2026-07-26 (#19)
------------------------------------------------------------

The rule above is now real, not a local mock toggle:
`wali_has_wali_one()` (SECURITY DEFINER, originally created as
`wali_has_extended_wali()` by 20260726160000_wali_extended_wali_real_
gating.sql, renamed by 20260726180000_rename_wali_has_extended_wali_
to_wali_one.sql when "Extended Guardian" was renamed "Guardian+" — DR-ZYRA-
106) resolves true if EITHER the Guardian's own `subscriptions` row is
`wali_premium`/active, OR any Seeker they're actively linked to has an
active `seeker_premium` (ZYRA One) subscription.
`wali_network_screen.dart` and `wali_profile_screen.dart` read this via
`ZyraEntitlementService.hasWaliOne()` instead of
`AppState.waliHasWaliOne`.

**Known limitation:** the free-bundling branch depends on the linked
Seeker having a REAL `seeker_premium` row — a Seeker's ZYRA One
purchase in `upgrade_screen.dart` is still a local AppState mock (see
#20, Real payment processing). Until #20 ships, bundling only resolves
for accounts with a real seeded row (verified against
`supabase/seed_dev_accounts.sql`'s Khadija↔Yusuf, 2026-07-26). The
independent-purchase branch (a) works fully today via
`mock_purchase_wali_premium()` — no real payment, but a real row.

Still not built: the four Guardian+ capabilities themselves
(Browse Guardian Network, Family Introduction Requests, Suggest profiles,
Guardian AI Summary — WALI_ARCHITECTURE_CURRENT_VERSION_V6.md). Gating now
correctly opens/closes the door; there's still an empty room behind
it for Browse/Requests (Guardian AI Summary additionally needs an LLM
integration that doesn't exist anywhere in this codebase).
