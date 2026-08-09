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
per-Guardian-relationship billing model with family pricing
matrices and multiple subscription tiers (Basic/Pro/Premium
for both Seeker and Guardian). That entire structure was replaced
by the ZYRA One model in ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V5
(2026-07-04) and has been removed here per Founder decision
2026-07-12 (see DECISIONS_REGISTER for the record once filed).
Per-Guardian billing, family/multi-account billing, and the old
tiered discount structure are retired, not merely renamed.

Owns:
• Pricing (ZYRA Basic / ZYRA One)
• Founder Members Programme
• Early Adopters Programme
• Compatibility Unlock Pricing
• Pricing Terminology

------------------------------------------------------------
TERMINOLOGY
------------------------------------------------------------

| Term            | Meaning |
|-----------------|---------|
| Seeker          | Person looking for marriage. |
| Guardian             | Person supervising or representing a Seeker. |
| ZYRA Basic      | Free entitlement, default for every account. |
| ZYRA One        | Paid entitlement (£34.99/month) purchasable by any account holder — Seeker or Guardian. Includes one bundled Guardian+ entitlement when held by a Seeker. |
| Guardian+   | The enhanced Guardian capability set. Received either as the one entitlement bundled with a Seeker's ZYRA One, or purchased independently by a Guardian (£9.99/month). Identical capabilities either way (AD-081). |
| Compatibility Unlock | Optional purchase that reveals additional compatibility information before a Match. Renamed from "Profile Unlock" 2026-08-03. Pricing only is defined here — full behaviour is documented in APP/Premium/Profile Unlocks/Summary.md. |

------------------------------------------------------------
FOUNDER MEMBERS
------------------------------------------------------------

Eligibility
• First 1,000 people to purchase ZYRA One — any account,
  Seeker or Guardian. Not restricted by role or gender; counted
  purely by headcount, first 1,000 to subscribe.

Benefits
• 50% off ZYRA One for the first 6 months
• 25% off ZYRA One for the following 6 months
• Applies to ZYRA One only — no separate Guardian pricing, no
  bundled additional subscriptions.

------------------------------------------------------------
EARLY ADOPTERS
------------------------------------------------------------

Eligibility
• Next 5,000 people to purchase ZYRA One — any account,
  Seeker or Guardian. Same basis as Founder Members: headcount
  only, not role- or gender-restricted.

Benefits
• 25% off ZYRA One for 12 months
• Applies to ZYRA One only — no separate Guardian pricing.

------------------------------------------------------------
STANDARD PRICING
------------------------------------------------------------

| Plan      | Monthly | Yearly   |
|-----------|--------:|---------:|
| ZYRA Basic| Free    | Free     |
| ZYRA One  | £34.99  | £349.90  |

Annual billing uses a 10-months-paid, 12-months-received model
(ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V5, Part 1, Section 5).

Guardian+, purchased independently by a Guardian rather than
received via a Seeker's bundled entitlement:

| Plan            | Monthly |
|-----------------|--------:|
| Guardian+   | £9.99   |

------------------------------------------------------------
PROFILE UNLOCK PRICING
------------------------------------------------------------

| Product              | Quantity   | Price |
|----------------------|------------|------:|
| Compatibility Unlock       | 1 profile  | £1.99 |
| Compatibility Unlock       | 5 profiles | £7.99 |
| Compatibility Unlock Plus  | 1 profile  | £2.99 |
| Compatibility Unlock Plus  | 5 profiles | £9.99 |

REPRICED AND RENAMED 2026-08-03, Founder approved. Was Profile
Unlock at £0.99 / £2.99 and Profile Unlock Plus at £1.99 /
£4.99.

The two five-packs sit £2 apart deliberately — price anchoring
intended to make Plus read as the smarter buy. Plus carries a
BEST VALUE badge; Unlock does not.

Savings shown in-app are exact, not rounded up:
  Unlock  5 x £1.99 = £9.95 -> £7.99 saves 19.7%, shown as 20%
  Plus    5 x £2.99 = £14.95 -> £9.99 saves 33.2%, shown as 33%

A ZYRA One Seeker also receives 3 free Compatibility Unlock
Plus credits (Founder approved 2026-08-03).

An unlock is PERMANENT per profile per tier. Revisiting never
costs another. See APP/Premium/Profile Unlocks/Summary.md.

Matches ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V5, Part 1, Section 8
exactly — confirmed consistent 2026-07-12.

Full functionality is documented in:
APP/Premium/PROFILE UNLOCKS

============================================================
IMPLEMENTATION STATUS
============================================================

Status: Approved behaviour only.

• Defines the ZYRA Basic / ZYRA One entitlement pricing.
• Defines Founder Members and Early Adopters launch pricing.
• Defines Compatibility Unlock pricing.
• Defines pricing terminology.

Explicitly out of scope (retired 2026-07-12, Founder decision):
• Per-Guardian-relationship billing and proration
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
