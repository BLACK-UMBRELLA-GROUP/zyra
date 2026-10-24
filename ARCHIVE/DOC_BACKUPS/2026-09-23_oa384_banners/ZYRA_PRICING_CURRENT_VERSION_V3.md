# ZYRA — Membership and Pricing

**Version:** V3
**Status:** CURRENT_VERSION — Founder-directed product model; activation NOT complete
**Date:** 2026-09-13
**Owner / approval authority:** Founder
**Supersedes:** ZYRA_PRICING_2026-09-13_V2.md (byte-preserved archive)
**Governing reference:** Founder direct instruction 2026-09-13; AD-AIOS-109; subscription continuity DR-ZYRA-118; Guardian authority DR-ZYRA-233
**Implementation owner:** Codex
**Actions:** OA-ZYRA-253 (pricing/payment implementation), OA-ZYRA-266 (IDV), OA-ZYRA-175/176 (dual-context exclusion blockers), OA-ZYRA-286 (separate delivery gate)

## 1. Founder-directed model

The permanent free/Basic product is retired. There are two membership subscriptions:

1. **ZYRA One:** one Seeker profile/access allocation and one included Guardian
   access allocation. The approved one-identity/two-context direction stands.
   The Guardian access may be reassigned under the Guardian rules; payment never
   transfers another person's account, identity, profile or history.
2. **Additional Guardian:** additional Guardian access, not Main Guardian
   appointment or permission to see otherwise-private information. The
   membership buys capacity to link with a Seeker; it does not guarantee
   access to any Journey. The Seeker controls which active Journeys an
   Additional Guardian may access and may change that access at any time.

The preceding Founder discussion establishes the intended **14-day trial then
paid One** model. It replaces the old seven-day first-Active-Journey offer.
No device clock, page visit or onboarding button may fabricate a trial.
Verification precedes trial activation; activation requires explicit store
consent and server-confirmed eligibility/entitlement. Real billing is not yet
implemented, so no trial or charge begins in the current client.

**Founder clarification, 2026-09-13: "Separate charge".** Compatibility Unlock
and Unlock Plus remain separate optional purchases, not membership subscription
tiers. This supersedes this version's initial retirement of their sales and
settles the question of unlimited inclusion in One: no unlimited grant.
Existing credits, permanent disclosure rights and Journey-revealed Overall
access are not erased. The prior three-included-Plus-credit rule (DR-ZYRA-119)
is not silently revoked by a decision that permits separate purchases; any
prospective change to that allowance needs explicit supersession when real
billing is scoped. No new grant or recurring allowance is activated here.
The unavailable detailed-category fuse remains in force.

## 2. Prices — unchanged

| Product | Weekly | Monthly |
|---|---:|---:|
| ZYRA One | £19.99 | £39.99 |
| Additional Guardian | £14.99 | £24.99 |

| Optional purchase | One credit | Five credits |
|---|---:|---:|
| Compatibility Unlock | £1.99 | £7.99 |
| Unlock Plus | £2.99 | £9.99 |

These add-on prices carry forward unchanged from the preserved pricing V2.
Purchasing credits is not available in the current build. Existing credits are
still checked server-side; presenting prices does not spend or grant a credit.

These are catalogue figures, not fetched StoreKit products. Actual regional
checkout must show the verified store price, period, renewal and cancellation
terms. No store products were created or changed in this work.

The former derived annual figure £399.90 still needs its separately recorded
Founder confirmation. It is not represented as an available checkout offer.
Previously promised Founder/Early-Adopter discounts remain historical approved
commitments, not silently cancelled: their interaction with the new trial and
weekly billing must be resolved before any offer is activated. No automatic
stacking, trial renewal price or new discount has been invented.

## 3. Identity, allocation and safeguards

- One identity may ultimately use both contexts, but never guard itself.
- The included externally assigned Guardian access remains **Main-only** under
  D14; additional paid access never promotes a Guardian or exposes Main context.
- Using the Guardian allocation oneself means supporting another eligible
  Seeker. Simultaneous allocation to oneself and someone else is not inferred.
- Transfer is about access, not account ownership. Precise transfer frequency,
  cooldowns, in-flight use and whether the Founder intended any Seeker-allocation
  transfer are not specified by the current instruction. They remain held.
- Guardian links, explicit Seeker consent, Main/Additional permissions and all
  romantic-exclusion predicates survive unchanged.
- Main Guardian responsibilities are separate from paid capacity. Main is
  always included in active Journeys; Additional Guardian participation is
  decided per active Journey by the linked Seeker.
- Past Journey summaries are a separate, Guardian-specific Seeker permission,
  OFF by default. Where enabled they are limited to start date, end date,
  final status and furthest stage. They never include the other participant's
  identity, messages, answers, reasons, private notes or safety information.
- This limitation must be prominent before purchase, at linking acceptance and
  in-product. It must not exist only in Terms or Privacy copy.
- OA-ZYRA-175's former-direct-Guardian rule and OA-ZYRA-176's exclusion retention
  on deletion must be resolved before enabling previously blocked dual-role
  matching. Do not adopt the superseded Aug-07 permissive exclusion examples.
- Expiry, cancellation or payer change never deletes relationships, history or
  configuration. Reporting, blocking, privacy and account management remain
  accessible without a subscription. Paid access is not authority.

## 4. Implementation truth / release boundary

The local client removes Basic sales, advert cards, commercial upgrade prompts
and mock purchase success. Its Membership page describes the two subscriptions
and separate compatibility purchases, with prices and truthful unavailable
checkout copy. Payments/trials/transfers remain unavailable. This is **not**
production paid-only enforcement.

Existing server contracts still have legacy plan identifiers/caps and permit
Basic participation. They are retained for compatibility, not offered as a
product. Existing `wali_has_wali_one()` conflates any linked Seeker's premium
with own Guardian payment and cannot prove the required contextual Main-only
allocation. The single-role database, one-active-subscription-row constraint,
missing verified purchase pipeline and missing allocation ledger are real
implementation dependencies, not solved by changing labels.

No migration, receipt adapter, payment SDK, account reassignment, live access
change or Apple upload was performed. A bounded server/payment implementation
contract and the standing exact activation gates are required next. The current
as-built handover and reports 118–119 own measured implementation/test state.

## 5. Historical material and rollback

V2 is preserved at `ZYRA_PRICING_2026-09-13_V2.md`. Removed app material has a
true pre-edit source archive outside SOURCE under
`SYSTEM/RESOURCES/TEMPORARY/ZYRA_PAID_ONLY_ROLLBACK_2026-09-13/`.
Approved visual pixels and historical migrations are not deleted or regenerated.

No new OA is raised: the pricing/billing work is already OA-ZYRA-253; identity,
dual-role safety and delivery have the specific existing owners listed above.
Those OAs are not closed by this partial client implementation.
