---
id: DOC-ZYRA-9027
type: REPORT
status: CURRENT
feature: REPORTS
purpose: ZYRA retention — commercial and store-feasibility preparation
links: []
owner: ZYRA chat
---

# ZYRA retention — commercial and store-feasibility preparation

Date: 27 September 2026  
Owner: Codex; approval authority: Founder  
Owning action: OA-ZYRA-253 — Paid Membership and Entitlement Activation  
Authority: latest Founder approval of converged Family safeguards; preparation only.  
Status: INITIAL PACKAGE PREPARED. Policy recorded; commercial viability and exact store implementation NOT VERIFIED. No implementation or store/database mutations authorised or performed.

## 1. Decision summary

Fixed one-period discounted subscription pricing is documented on both stores. The approved Family saving is more demanding: preserve a locked monetary ceiling through variable-place purchases, provider price changes and replacement payers. Documentation reviewed does not establish that the full mechanism works as specified.

Recommendation: retain the approved policy. Resolve store catalogue mapping and obtain actual UK price/proceeds evidence before asking for a bounded implementation approval. Do not use cashback, subscription credits, free extensions, extra billing subscriptions or restricted Family management as unapproved substitutes.

UK scope and inclusion of Seeker One, Guardian One (including Additional Guardians) and Family are settled. Exact platform, supported products, price points, contribution floor and data-retention duration remain undecided.

## 2. Current local evidence

Current commercial source: `SUB BUSINESS/ZYRA/BUSINESS/ZYRA PRICING/ZYRA_PRICING_CURRENT_VERSION_V6.md`, DR-ZYRA-248. Seeker One £29.99/month; Guardian One £19.99/month; configurable 0–10 places per role with volume saving capped at 40%.

Source inspection: `SUB BUSINESS/ZYRA/SOURCE/lib/data/zyra_membership_catalog.dart` explicitly has `checkoutAvailable = false`; Family checkout, allocation and activation are described as unavailable. Its Family formula matches the commercial document. Bounded package inspection found no `in_app_purchase`/`purchases_flutter` purchase dependency in pubspec. This is not a claim that every server or account has been audited.

OA-ZYRA-253 remains open for real billing, receipt truth, verified-person callbacks, regional price points, Family operations, production server replay and activation. No authenticated App Store Connect/Play Console inventory, provider proceeds statement or runtime purchase was inspected in this preparation. Exact product IDs, account commission enrolment, signing setup and UK supported promotional prices are therefore UNKNOWN, not absent.

## 3. Proposed monetary specification

Use currency minor units. For GBP preparation:

- P: provider-authoritative standard next-renewal price of the accepted purchased-place configuration, preserving any applicable grandfathered price.
- C: maximum locked saving; proposed conservative rounding is `floor(40 × P / 100)` pence.
- R: provider-authoritative standard final renewal charge after ordinary Family pricing/configuration changes.
- S: maximum permitted final saving, `min(C, floor(40 × R / 100))` pence.
- Q: proposed discounted charge, `R − S`, subject to the available store price grid and verified margin floor.

Rounding is a proposed implementation detail, not a new approved store price. Never round a saving upward above the approved 40% ceiling. If available prices yield a smaller saving, use truthful amount/effective-percentage wording and return any material difference to the Founder. No credit balance, cash refund or new stored-value product is implied by C.

Readiness examples only — formula prices BEFORE store rounding, not promised customer charges:

| Product/configuration | Standard formula price | Maximum whole-penny saving | Illustrative discounted charge |
|---|---:|---:|---:|
| Guardian One | £19.99 | £7.99 | £12.00 |
| Seeker One | £29.99 | £11.99 | £18.00 |
| Family 1 Seeker + 1 Guardian | £49.98 | £19.99 | £29.99 |
| Family 2 Seekers + 1 Guardian | £75.97 | £30.38 | £45.59 |
| Family 2 Seekers + 2 Guardians | £89.96 | £35.98 | £53.98 |
| Family 5 Seekers + 5 Guardians | £149.94 | £59.97 | £89.97 |
| Family 10 Seekers + 10 Guardians | £299.88 | £119.95 | £179.93 |

Example: accept 2+2 at P=£89.96, C=£35.98. If the final standard charge becomes £149.94, the saving remains at most £35.98 (about 24%, NOT 40% of the new bill). If it becomes £49.98, the cap falls to £19.99. These are arithmetic examples, not proof that a provider can charge these amounts.

The normal Family formula can sometimes FALL when adding a place because the volume percentage changes. Offline enumeration found three adjacent additions with a lower formula bill: 7S+2G £162.44 → 7S+3G £161.94; 8S+1G £168.94 → 8S+2G £167.94; 9S+0G £175.44 → 9S+1G £173.94. Store rounding may change these outcomes. Use actual R rather than assuming adding capacity always raises the price. This pricing observation is assigned to OA-ZYRA-253; no pricing change is made or proposed as approved.

Acceptance-based locking prevents enlargement AFTER acceptance. It does not prove that enlarging capacity BEFORE acceptance is unprofitable or impossible. Test short-lived additions, proration and unused places in the margin model; do not introduce a new qualifying-plan holding period without Founder approval.

## 4. Commercial model and missing inputs

For illustration only, assume VAT-inclusive UK price Q, 20% VAT and commission f applied to the tax-exclusive amount:

`illustrative store proceeds = Q / 1.20 × (1 − f)`

Actual provider proceeds reports override this simplified model. Do not deduct VAT or fees twice. Tax status, fee bases, nonrecoverable taxes and account terms must be verified.

| Illustrative discounted charge | Proceeds at 15% fee / 20% VAT | Proceeds at 30% fee / 20% VAT |
|---|---:|---:|
| Guardian £12.00 | £8.50 | £7.00 |
| Seeker £18.00 | £12.75 | £10.50 |
| Family 2+2 £53.98 | £38.24 | £31.49 |
| Family 5+5 £89.97 | £63.73 | £52.48 |
| Family 10+10 £179.93 | £127.45 | £104.96 |

These figures are before hosting, storage/egress, support, moderation, IDV cost allocation, provider/platform charges not included above, refunds/disputes and any agreed overhead allocation. They establish NO profit or contribution pass.

Define before approval:

- Contribution basis: discounted-renewal incremental costs AND a separate cohort/lifetime view including acquisition/onboarding costs; do not treat sunk IDV spending as a fresh cash charge on every renewal, but do not omit it from cohort economics.
- Exact cost inputs for supported Family compositions/usage, including vacant and fully used places and capacity changes.
- Actual tax/store/provider treatment from UK customer price and net-proceeds evidence.
- Founder-selected minimum £ contribution and/or percentage floor, cost uncertainty buffer and stop thresholds.
- Comparison baseline: expected contribution with and without the offer, including later full-price renewal; redemptions are not automatically incremental retention.

Apple documents 70% of subscription price minus applicable taxes in the first paid-service year, 85% thereafter, and 85% for Small Business Program participants. Enrolment is not established here. [Apple subscription proceeds](https://developer.apple.com/app-store/subscriptions/).

Google lists 15% for auto-renewing subscriptions. No claim of this account's final settlement calculation is made. [Google service fees](https://support.google.com/googleplay/android-developer/answer/112622?hl=en).

20% is the UK standard VAT rate used for sensitivity calculations, not a tax determination for the company. [GOV.UK VAT rates](https://www.gov.uk/vat-rates).

## 5. Store-feasibility matrix

| Requirement | Apple documented baseline | Google documented baseline | ZYRA evidence still required |
|---|---|---|---|
| One discounted monthly period | One-month pay-as-you-go promotional duration exists | Offers support specified discounted billing-period phases | Exact product, supported price, offer type and return to normal renewal |
| Eligibility | Developer eligibility and signed promotional purchase flow | Developer-determined offer criteria | Server Family/person reservation, failure and replay enforcement |
| Next renewal, not immediate extra charge | Timing varies for upgrade/crossgrade/downgrade | Replacement modes/base-plan changes affect timing | Same-product save offer and each transition timing in sandbox |
| Locked saving through capacity changes | Product-specific configured prices; no proven arbitrary dynamic credit | Configured offer phases/price overrides; no proven arbitrary dynamic credit | P→R mapping preserves S, actual charge and margin without repeated subsidy |
| Payer change | No verified transfer of accepted offer between purchasers | Replacement linkage does not prove cross-purchaser offer portability | Separate payer's purchase, original outcome, exactly one funded coverage period |
| UK pilot | Promotional offers apply in all available subscription storefronts | Regional availability is configurable | Verified storefront eligibility; replay/storefront-change denial and normal purchase retained |
| Variable Family catalogue | Subscription groups/levels determine switching | Base plans/products and replacement rules determine switching | Full capacity catalogue, coexistence of two individual role memberships, Family replacement and no double billing |

Sources and interpretation:

- Apple allows configured promotional prices/durations and up to ten active promotional offers per subscription. Offers are not limited to selected countries; UK-only presentation/server authorisation must be designed and tested. A client location toggle alone is insufficient. [Apple promotional setup](https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-promotional-offers-for-auto-renewable-subscriptions/).
- One-month subscriptions allow one-month pay-as-you-go offers. This establishes duration, not next-charge timing for every transition. [Apple pricing/duration reference](https://developer.apple.com/help/app-store-connect/reference/pricing-and-availability/in-app-purchase-and-subscriptions-pricing-and-availability).
- Apple's implementation documentation describes different offer timing for plan changes. Existing same-product renewal behaviour still needs observation. [Apple promotional implementation](https://developer.apple.com/documentation/storekit/implementing-promotional-offers-in-your-app).
- Google documents developer-determined eligibility, regional price phases and a limit of 50 active base plans/offers per subscription (250 total). [Google subscription structure](https://support.google.com/googleplay/android-developer/answer/12154973?hl=en).
- Google replacement modes change entitlement and charge timing; linked purchase tokens help identify replacements, not all cross-payer continuity. [Google replacements](https://developer.android.com/google/play/billing/subscriptions).

Inference: neither reviewed baseline establishes the entire approved adaptive locked-saving mechanism. Treat it as UNPROVEN, not categorically impossible. It must map to actual store configurations or return to the Founder as a material feasibility departure.

There are 120 nonzero Family capacity combinations (11×11−1). This is not necessarily 120 SKUs: the product mapping is not chosen. Enumerate valid capacity configurations and transitions before deciding the catalogue. A single Google subscription with one active base plan per configuration would exceed its documented 50-active limit; a target-specific Apple price ladder may need more than ten active offers. Neither observation authorises splitting products/groups or narrowing the approved Family range.

## 6. Concrete account-readiness evidence checklist

Read-only account inspection or an authorised non-secret export must establish:

1. App/bundle/package identity; store agreements and subscription capabilities.
2. Existing product IDs, groups/levels or base plans, normal local prices, preserved price cohorts and subscription availability. Report observed IDs; do not invent/create them.
3. UK monthly promotional price points for each supported composition, one-period duration and actual ordinary price afterward.
4. Offer ceilings and capacity-transition mapping, including descending prices, ordinary member allocation and store-initiated changes outside the app.
5. Actual proceeds/fee programme evidence and cost schedule; no login secrets or signing keys in this report.
6. Verified person/payer and provider purchase linkage exposed by the selected billing integration; distinction between Family lineage and store subscription lineage.
7. Offer authorisation, UK storefront eligibility, expiry/replay handling, incoming-payer purchase and old/new event reconciliation design.

No account inventory was obtained this turn. Sandbox product creation or implementation would exceed the current preparation authority. The package deliberately identifies those future prerequisites rather than claiming feasibility verified by paperwork.

## 7. Proposed sandbox acceptance contract — NOT RUN

Record product/offer IDs, local currency/standard/promotional amount, timestamps, renewal boundaries and provider event outcomes without secrets. Require:

- One ordinary renewal becomes discounted exactly once; next renewal returns to the correct standard/grandfathered price; no early surprise charge.
- Exact UK eligibility succeeds; non-UK and changed-storefront attempts fail without blocking standard purchasing/cancellation.
- Two completed periods and one Family period on approved continuing conversion; unrelated history rejected; standard Family volume saving counts normally.
- Family A redeems then brother takes over: no new Family offer; brother's unused personal allowance remains unused. If he personally redeems elsewhere, his payer limit applies.
- Simultaneous acceptance requests across devices/memberships and old/new payer purchases produce at most one permitted accepted attempt/redemption.
- Allocation to funded vacancy does not change charge. Paid addition, reduction, descending-price addition, mixed-role substitution and reverse transition preserve the saving ceiling and ordinary Family terms.
- Pending offer + ownership transfer, cancellation/reactivation, restoration, deferred change and late renewal/refund notifications preserve history without double funding or false redemption.
- Cancellation, billing failure/grace, retry, expiry and refund correction never invent access or erase immutable history; no beneficiaries' personal allowance consumed.
- Final charge below store margin floor, stale quote, unavailable price and unsupported transition do not silently issue a substitute. Any accepted offer requires a concrete fulfilment/reconciliation path; no simple “suppress after acceptance” solution.
- Cancellation remains visible and direct for every reason, including safety and successful marriage; no retention analytics deployed without its own approved data controls.

No runtime, sandbox or real-device test passed is claimed. Offline arithmetic alone was checked for all 120 valid configurations and the specified cap inequality.

## 8. Founder review / next preparation boundary

Settled: Family policy, 40% target conditional on contribution, locked saving, dual limits, payer-only personal consumption, approved continuing conversion and current Guardian SKU semantics. Do not ask for those approvals again.

Still needed for an implementation-ready package: account read-only price/configuration evidence, fee/cost inputs, selected integration/product mapping, numeric contribution floor, record-retention duration, platform-specific transition/quote design, exact commercial deviations if any, and a bounded test/implementation plan. This V1 is not ready for production or blanket implementation GO.

After those inputs are established, present the specific proposed implementation scope separately. Any store creation, code/cancellation change or database work remains held until the Founder approves that concrete scope. Production deployment and activation remain further exact gates.

## 9. Trace and internal verification

Linked approval: `ZYRA_RETENTION_PILOT_APPROVAL_AND_PREPARATION_2026-09-27_V1.md` §9. Reviewed current pricing, local catalogue and owning OA-ZYRA-253; official documentation checked 27 September 2026. Arithmetic used integer-pence Family rounding and conservative promotional caps; sensitivity proceeds rounded for presentation only. All 120 valid Family configurations enumerated; three price-decreasing adjacent additions identified.

Files changed: this new report and the existing approval brief only. No app code, price contract, central OA register, store, database, billing, account setting or cancellation flow changed. Findings assigned to existing OA-ZYRA-253 in this package; no new OA consumed. Founder implementation/production approval remains absent by explicit instruction.
