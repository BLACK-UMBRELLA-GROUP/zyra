---
id: DOC-ZYRA-0121
type: SPEC
status: CURRENT
feature: BUSINESS: ZYRA PRICING
purpose: Zyra Pricing — References
links: []
owner: ZYRA chat
---

FEATURE NAME
ZYRA PRICING

============================================================
REFERENCES
============================================================

------------------------------------------------------------
References (depends on)
------------------------------------------------------------

Compatibility Unlock (APP/Premium/Profile Unlocks)
• Founder direct amendment 2026-10-11: one Compatibility Unlock with former
  Plus depth costs £2.99 each or £9.99 for five. ZYRA_PRICING section 9 owns
  the current catalogue; £1.99 / £7.99 and a separate Plus offer are retired.
• Full feature behaviour is documented in Profile Unlocks.
• This document is the source of truth for pricing only.
• Status: Referenced — feature definition lives in APP/Premium/PROFILE UNLOCKS.
• Existing Standard/Plus records, permanent access and balances retain their
  historical meaning. No conversion, membership allocation change, automatic
  Journey trigger change, payment receipt or live activation is authorised.
• ZYRA_PRODUCT_SPEC Part 1 section 8 and DR-ZYRA-250 retain the twelve-category
  reduced-disclosure target and scoring/privacy/spending gates. Six fictional
  local rows are not the future production contract.

------------------------------------------------------------
Referenced By
------------------------------------------------------------

Subscription System
• All subscription tier pricing defined here.

Billing System
• Proration rules, renewal alignment, and invoice structure
  defined here.

Guardian System
• Guardian Relationship subscription rules defined here.
• Guardian billing structure defined here.

Account System
• Payment ownership and verification rules defined here.

Payments & Monetisation
• This document is the master pricing reference.

------------------------------------------------------------
Overlap Flags
------------------------------------------------------------

⚠️ BUSINESS/USER FEATURES
- Subscription tier names (Basic, Pro, Premium) appear in both.
- USER FEATURES owns: feature entitlements per tier.
- ZYRA PRICING owns: prices per tier.
- These documents are complementary but must stay in sync on
  tier names and structure.

⚠️ APP/Premium/PROFILE UNLOCKS
- Compatibility Unlock pricing appears in both files.
- ZYRA PRICING is the source of truth for pricing.
- Compatibility Unlock file should reference this document for prices.

------------------------------------------------------------
Open Dependencies
------------------------------------------------------------

CURRENT EXECUTION DEPENDENCIES — 2026-10-11:
• Verified store products/local prices, trusted receipts, restore and lifecycle
  handling remain required before optional-purchase activation.
• Real full-depth spending remains held. Existing scoring/privacy and migration
  boundaries remain with OA-ZYRA-193/198; scoped client consolidation is
  recorded under OA-ZYRA-151 and the Navigation Haptics handover.

Historical dependency list below is not the current membership contract.
ZYRA_PRICING now defines monthly-only billing, trial and cancellation policy;
the unresolved work is their trusted implementation and activation, not
authority to reintroduce annual terms or redecide approved policy.

• Regional pricing not yet defined.
• Annual pricing discount rationale not documented.
• Payment provider not yet confirmed.
• Subscription & Billing implementation not yet complete.
• Payments flow not yet documented.
• Free trial rules not defined.
• Upgrade/downgrade mid-cycle pricing rules not defined.
• Cancellation and refund rules not defined.
