# ZYRA — Pricing

**Version:** V2
**Status:** CURRENT_VERSION — **SOURCE OF TRUTH for every price in the product**
**Date:** 2026-08-23
**Owner:** Founder
**Governing Reference:** ZYRA_GOVERNANCE, ZYRA_PRODUCT_SPEC Part 1 §8
**Supersedes:** ZYRA_PRICING_2026-08-23_V1.md (archived; was current 2026-08-13 → 2026-08-23)
**Register:** OA-ZYRA-253 (this repricing + weekly plans + D14 entitlement mirror); OA-ZYRA-209 (original promotion); OA-ZYRA-207 (the drift lesson this document exists to prevent)

---

## V2 changes (Founder decision, 2026-08-23)

1. **ZYRA One repriced:** £34.99 → **£39.99 / month**. Yearly follows the ratified 10-months-paid/12-received model: £349.90 → **£399.90 / year** *(derived, not separately quoted by the Founder — flag stays until explicitly confirmed or corrected)*.
2. **Guardian+ standalone repriced:** £9.99 → **£24.99 / month**.
3. **WEEKLY plans introduced (new):** ZYRA One **£19.99 / week** · Guardian+ standalone **£14.99 / week**. Approved pricing; the in-app purchase surface for weekly billing is NOT yet built (see Implementation status).
4. **D14 entitlement mirror (ratified 2026-08-23, OA-ZYRA-247):** a Seeker's ZYRA One includes Guardian+ for their **MAIN Wali only**. Additional Guardians each need their own Guardian+ (£24.99/month or £14.99/week). **Payment buys ACCESS, never authority** — send/accept/withdraw/proceed in Guardian Network remain Main-Wali-only acts regardless of who pays (GN contract Rule 37/38).
5. Compatibility Unlock pricing **unchanged**.

## Current prices at a glance

| Product | Weekly | Monthly | Yearly |
|---|---:|---:|---:|
| ZYRA Basic | Free | Free | Free |
| ZYRA One | £19.99 | £39.99 | £399.90 *(10-for-12 model)* |
| Guardian+ (standalone) | £14.99 | £24.99 | — |
| Compatibility Unlock | — | £1.99 single · 5 for £7.99 | — |
| Compatibility Unlock Plus | — | £2.99 single · 5 for £9.99 | — |

A Seeker's ZYRA One includes: one bundled **Guardian+ for their Main Wali** + **3 free Compatibility Unlock Plus credits**.

**Retired names — never use:** "Profile Unlock", "Unlock Profile", "Profile Unlock Plus", "Unlock Profile Plus" (renamed 2026-08-03). **Retired figures — never quote:** One at £34.99/£349.90 and Guardian+ at £9.99 (superseded 2026-08-23, this version).

---

## Why this document exists in this form

Promoted 2026-08-13 (OA-ZYRA-209) after ten days in which the Upgrade screen advertised retired prices while the unlock screen charged ratified ones (OA-ZYRA-207). **This document is the source of truth. Code disagreeing with it is a defect in the code, not a difference of opinion.** On the same day as this V2, every price string in the app was updated in the same pass (see Implementation status) so no drift window opened.

------------------------------------------------------------
TERMINOLOGY
------------------------------------------------------------

| Term | Meaning |
|---|---|
| Seeker | Person looking for marriage. |
| Guardian | Person supervising or representing a Seeker. |
| ZYRA Basic | Free entitlement, default for every account. |
| ZYRA One | Paid entitlement (£39.99/month · £19.99/week · £399.90/year) purchasable by any account holder — Seeker or Guardian. When held by a Seeker, includes one bundled Guardian+ entitlement **for their Main Wali** (D14 clarification, 2026-08-23). |
| Guardian+ | The enhanced Guardian capability set. Received either as the Main-Wali entitlement bundled with a Seeker's ZYRA One, or purchased independently by any Guardian (£24.99/month · £14.99/week). Identical capabilities either way (AD-081); authority is never purchased (GN Rule 37/38). |
| Compatibility Unlock | Optional purchase revealing additional compatibility information before a Match. Renamed from "Profile Unlock" 2026-08-03. Pricing only is defined here — behaviour in APP/Premium/Profile Unlocks/Summary.md. |

------------------------------------------------------------
FOUNDER MEMBERS
------------------------------------------------------------

Eligibility
• First 1,000 people to purchase ZYRA One — any account, Seeker or
  Guardian. Not restricted by role or gender; counted purely by
  headcount, first 1,000 to subscribe.

Benefits
• 50% off ZYRA One for the first 6 months
• 25% off ZYRA One for the following 6 months
• Applies to ZYRA One only — no separate Guardian pricing, no bundled
  additional subscriptions. *(Discount basis is the plan the member is
  on; weekly-plan applicability of launch promotions is a Founder
  decision not yet taken — flagged in the to-do list.)*

------------------------------------------------------------
EARLY ADOPTERS
------------------------------------------------------------

Eligibility
• Next 5,000 people to purchase ZYRA One — any account, Seeker or
  Guardian. Same basis as Founder Members: headcount only.

Benefits
• 25% off ZYRA One for 12 months
• Applies to ZYRA One only — no separate Guardian pricing. *(Same
  weekly-plan flag as Founder Members.)*

------------------------------------------------------------
STANDARD PRICING
------------------------------------------------------------

| Plan | Weekly | Monthly | Yearly |
|---|---:|---:|---:|
| ZYRA Basic | Free | Free | Free |
| ZYRA One | £19.99 | £39.99 | £399.90 |

Annual billing uses the 10-months-paid, 12-months-received model
(ZYRA_PRODUCT_SPEC, Part 1, Section 5). £399.90 = 10 × £39.99, derived
2026-08-23 from the repriced monthly figure under that ratified model.

Guardian+, purchased independently by a Guardian rather than received
via a Seeker's bundled Main-Wali entitlement:

| Plan | Weekly | Monthly |
|---|---:|---:|
| Guardian+ | £14.99 | £24.99 |

------------------------------------------------------------
PROFILE UNLOCK PRICING (unchanged in V2)
------------------------------------------------------------

| Product | Quantity | Price |
|---|---|---:|
| Compatibility Unlock | 1 profile | £1.99 |
| Compatibility Unlock | 5 profiles | £7.99 |
| Compatibility Unlock Plus | 1 profile | £2.99 |
| Compatibility Unlock Plus | 5 profiles | £9.99 |

Repriced and renamed 2026-08-03, Founder approved (was Profile Unlock
£0.99/£2.99, Profile Unlock Plus £1.99/£4.99). The two five-packs sit
£2 apart deliberately — anchoring intended to make Plus read as the
smarter buy; Plus carries the BEST VALUE badge.

Savings shown in-app are exact, not rounded up:
  Unlock  5 × £1.99 = £9.95 → £7.99 saves 19.7%, shown as 20%
  Plus    5 × £2.99 = £14.95 → £9.99 saves 33.2%, shown as 33%

A ZYRA One Seeker also receives 3 free Compatibility Unlock Plus
credits (Founder approved 2026-08-03). An unlock is PERMANENT per
profile per tier. See APP/Premium/Profile Unlocks/Summary.md.

============================================================
IMPLEMENTATION STATUS
============================================================

Updated in code the same day as this V2 (no drift window — the
OA-ZYRA-207 lesson):
• upgrade_screen.dart — One card £39.99/£399.90, refund copy £39.99.
• help_content.dart — cost answer: £39.99, £24.99, Main-Guardian bundle.
• wali_network_screen.dart — Guardian+ gate copy and purchase pill
  £24.99/month + Main-Wali bundle wording.
• app_state.dart / zyra_entitlement_service.dart — mock-path comments.

NOT yet built (registered under OA-ZYRA-253, needs a Founder brief):
• WEEKLY billing surfaces — the Upgrade screen has a monthly/annual
  toggle only; weekly SKUs, renewal copy, and store products (App
  Store/Google Play) do not exist yet. The prices above are approved
  and waiting for that build.
• Stripe/store payment provider implementation (pre-existing to-do).

============================================================
APPROVED TO-DO LIST
============================================================
• Founder confirms the derived £399.90 yearly figure (or corrects it).
• Founder decides whether Founder Members / Early Adopters discounts
  apply to the weekly plan.
• Build the weekly billing surfaces (OA-ZYRA-253).
• Review regional pricing before launch.
• Validate pricing against competitor changes before public release.
• Finalise payment provider implementation (Stripe — OA pending).
• Complete Subscription & Billing Script Summary against this model.
• Complete Payments Flow Blueprint against this model.
