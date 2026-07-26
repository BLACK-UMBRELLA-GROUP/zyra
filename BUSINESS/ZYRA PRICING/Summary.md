FEATURE NAME
ZYRA PRICING
Group: 1 — Business Rules

============================================================
SUMMARY
============================================================

Purpose:
Defines ZYRA's complete pricing strategy: the ZYRA Basic /
ZYRA One entitlement model, launch promotions, and Profile
Unlock pricing.

Superseded 2026-07-12: this document previously described a
per-Wali-relationship billing model with family pricing
matrices and multiple subscription tiers (Basic/Pro/Premium
for both Seeker and Wali). That entire structure was replaced
by the ZYRA One model in ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V3
(2026-07-04) and has been removed here per Founder decision
2026-07-12 (see DECISIONS_REGISTER for the record once filed).
Per-Wali billing, family/multi-account billing, and the old
tiered discount structure are retired, not merely renamed.

Owns:
• Pricing (ZYRA Basic / ZYRA One)
• Founder Members Programme
• Early Adopters Programme
• Profile Unlock Pricing
• Pricing Terminology

------------------------------------------------------------
TERMINOLOGY
------------------------------------------------------------

| Term            | Meaning |
|-----------------|---------|
| Seeker          | Person looking for marriage. |
| Wali             | Person supervising or representing a Seeker. |
| ZYRA Basic      | Free entitlement, default for every account. |
| ZYRA One        | Paid entitlement (£34.99/month) purchasable by any account holder — Seeker or Wali. Includes one bundled Extended Wali entitlement when held by a Seeker. |
| Extended Wali   | The enhanced Wali capability set. Received either as the one entitlement bundled with a Seeker's ZYRA One, or purchased independently by a Wali (£9.99/month). Identical capabilities either way (AD-081). |
| Profile Unlock  | Optional purchase that reveals additional compatibility information before a Match. Pricing only is defined here — full behaviour is documented in APP/Premium/PROFILE UNLOCKS and ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V3, Part 1, Section 8. |

------------------------------------------------------------
FOUNDER MEMBERS
------------------------------------------------------------

Eligibility
• First 1,000 people to purchase ZYRA One — any account,
  Seeker or Wali. Not restricted by role or gender; counted
  purely by headcount, first 1,000 to subscribe.

Benefits
• 50% off ZYRA One for the first 6 months
• 25% off ZYRA One for the following 6 months
• Applies to ZYRA One only — no separate Wali pricing, no
  bundled additional subscriptions.

------------------------------------------------------------
EARLY ADOPTERS
------------------------------------------------------------

Eligibility
• Next 5,000 people to purchase ZYRA One — any account,
  Seeker or Wali. Same basis as Founder Members: headcount
  only, not role- or gender-restricted.

Benefits
• 25% off ZYRA One for 12 months
• Applies to ZYRA One only — no separate Wali pricing.

------------------------------------------------------------
STANDARD PRICING
------------------------------------------------------------

| Plan      | Monthly | Yearly   |
|-----------|--------:|---------:|
| ZYRA Basic| Free    | Free     |
| ZYRA One  | £34.99  | £349.90  |

Annual billing uses a 10-months-paid, 12-months-received model
(ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V3, Part 1, Section 5).

Extended Wali, purchased independently by a Wali rather than
received via a Seeker's bundled entitlement:

| Plan            | Monthly |
|-----------------|--------:|
| Extended Wali   | £9.99   |

------------------------------------------------------------
PROFILE UNLOCK PRICING
------------------------------------------------------------

| Product              | Quantity   | Price |
|----------------------|------------|------:|
| Profile Unlock       | 1 profile  | £0.99 |
| Profile Unlock       | 5 profiles | £2.99 |
| Profile Unlock Plus  | 1 profile  | £1.99 |
| Profile Unlock Plus  | 5 profiles | £4.99 |

Matches ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V3, Part 1, Section 8
exactly — confirmed consistent 2026-07-12.

Full functionality is documented in:
APP/Premium/PROFILE UNLOCKS

============================================================
IMPLEMENTATION STATUS
============================================================

Status: Approved behaviour only.

• Defines the ZYRA Basic / ZYRA One entitlement pricing.
• Defines Founder Members and Early Adopters launch pricing.
• Defines Profile Unlock pricing.
• Defines pricing terminology.

Explicitly out of scope (retired 2026-07-12, Founder decision):
• Per-Wali-relationship billing and proration
• Family / multi-account billing and payment ownership rules
• Any Basic/Pro/Premium tiered subscription structure
These may be reconsidered in a future version if genuine
demand exists, but are not part of the current product.

============================================================
APPROVED TO-DO LIST
============================================================
• Review regional pricing before launch.
• Validate pricing against competitor changes before public release.
• Finalise payment provider implementation (Stripe — OA pending).
• Complete Subscription & Billing Script Summary against this model.
• Complete Payments Flow Blueprint against this model.
