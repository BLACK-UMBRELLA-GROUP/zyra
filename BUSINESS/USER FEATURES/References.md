FEATURE NAME
USER FEATURES

============================================================
REFERENCES
============================================================

------------------------------------------------------------
References (depends on)
------------------------------------------------------------

Matching System
- Save/Like daily limits and Match event access are gated by
  entitlement (ZYRA Basic vs ZYRA One).
- Status: Referenced — definition lives in APP/Matching.

Saved System
- Save is available on all entitlements, with a daily cap on
  ZYRA Basic (10/day) and unlimited on ZYRA One.
- Status: Referenced — definition lives elsewhere.

Potentials System
- Like, Outgoing/Incoming Potentials are available on both
  entitlements; immediate Incoming Potentials is ZYRA One only.
- Status: Referenced — definition lives elsewhere.

Timeline System
- Timeline is available on both ZYRA Basic and ZYRA One.
- Status: Referenced — definition lives elsewhere.

Family Introduction System
- Family Introductions require Extended Wali (bundled with a
  Seeker's ZYRA One, or purchased independently by the Wali).
- Status: Referenced — definition lives elsewhere.

------------------------------------------------------------
Referenced By
------------------------------------------------------------

Browse
- Profile viewability limits and browsing access controlled
  by this document.

Profile
- Profile creation and photo upload access defined here.

Chats
- Messaging is available on both ZYRA Basic and ZYRA One once
  an Active Journey begins.
- Wali visibility into messages applies to both Standard and
  Extended Wali (see WALI_ARCHITECTURE_CURRENT_VERSION_V5).

Matches
- Match viewing and creation access defined here.

Notifications
- Notification access defined per tier.

Timeline
- Timeline access defined per tier.

Subscription & Billing
- This document is the source of truth for all plan features
  and entitlements.

------------------------------------------------------------
Overlap Flags
------------------------------------------------------------

⚠️ PROFILE DECISION SYSTEM (APP/Matching)
- Contains entitlement feature breakdowns.
- Rewritten 2026-07-12 to match this document and Product Spec V3.

⚠️ PROFILE UNLOCKS (APP/Premium)
- References ZYRA Basic / ZYRA One subscription benefits.
- Must remain in sync with this document.
- This document (USER FEATURES) is the source of truth for
  feature entitlements; ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V3
  is the source of truth for the underlying product model.

------------------------------------------------------------
Open Dependencies
------------------------------------------------------------

- Mutual Save Detection — resolved 2026-07-12, ZYRA One only.
- Pricing for each plan — see BUSINESS/ZYRA PRICING (updated
  2026-07-12).
- Free trial rules — 7-day ZYRA One trial confirmed in Product
  Spec V3, Section 6 (activates on first Active Journey).
- Upgrade/downgrade rules not defined.
- Plan cancellation rules not defined.
- Extended Wali may be purchased by either the Seeker (bundled
  with ZYRA One) or the Wali independently — see DR-075.
