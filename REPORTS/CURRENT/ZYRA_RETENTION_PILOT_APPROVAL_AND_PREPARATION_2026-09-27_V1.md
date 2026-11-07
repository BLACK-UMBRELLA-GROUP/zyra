---
id: DOC-ZYRA-9028
type: REPORT
status: CURRENT
feature: REPORTS
purpose: ZYRA cancellation-retention offer — approved pilot policy and preparation
links: []
owner: ZYRA chat
---

# ZYRA cancellation-retention offer — approved pilot policy and preparation

Date: 27 September 2026  
Authority: Founder direct reply, “I APPROVE”, to the six decisions and operational limits, including Codex's two clarifications.  
Owner: Codex prepares and internally verifies; Founder approves exact production configuration and accepts outcomes.  
Existing action: OA-ZYRA-253 — Paid Membership and Entitlement Activation.  
Feature ownership: 04_BUSINESS/ — membership commercial policy; implementation uses existing billing/entitlement ownership.  
Status: Policy and converged Family safeguards APPROVED for preparation only; see §9 for the binding latest Founder instruction. Earlier approvals and recommendations preserved as history. Implementation, store creation/configuration, migrations, cancellation-flow changes and production rollout are NOT authorised. Commercial/store-feasibility package prepared; account configuration, margins and runtime evidence remain outstanding.

## 1. Approval scope

The Founder approved the proposed controlled UK pilot and operational limits after the ChatGPT/Codex review converged. This approval is for preparing and testing the policy. It does not establish profitability, configure a billing product, activate a public offer, authorise an undisclosed production migration or enable a billing pause.

Approved:

1. Target 40% off one monthly renewal, conditional on acceptable contribution after actual taxes, store fees and attributable costs. No three-month offer.
2. Two completed monthly periods paid at the member's applicable standard price. The initial paid period counts after completion. Established grandfathered standard prices count. Trials/free periods, introductory/launch/retention promotions, failed, refunded, charged-back and incomplete periods do not count.
3. One successful redemption per linked person AND continuing membership in each rolling 12-calendar-month interval. Known changes of role, payer, account or store do not reset history. Only the selected membership receives the discount.
4. One unresolved retention attempt/accepted offer at a time against both person and membership. Accepted-but-unredeemed offers do not consume the annual allowance. Apply a provisional 90-day presentation cooldown from provider-confirmed terminal-unredeemed status.
5. Keep original redemption history after an ordinary refund/chargeback. An authorised, audited correction for a verified billing error may restore eligibility; original events remain available.
6. Original approval: UK monthly ZYRA One pilot, excluding Family and Additional Guardian. This exclusion was superseded by the Founder's later direct instruction in §8. Start with the first verified production store platform; expansion follows separate verification.

## 2. Cancellation experience

Reason is optional. Continue cancellation remains clearly available. At most one relevant alternative is presented, with no escalating offers or countdown.

| Reason | Approved handling |
|---|---|
| Cost | Discount only if eligible |
| Taking a break / low use | Continue cancellation; no billing-pause claim |
| Found someone | Brief acknowledgement and direct cancellation |
| Safety concern | Direct cancellation; optional report/support, without required disclosure |
| Technical failure | Cancellation plus optional support/remedy |
| Unsuitable introductions | Optional feedback and cancellation |
| Other / skipped | Cancellation |

Use only billing/promotion evidence for eligibility. Do not target on religious information, compatibility, private messages or desirability. Suppress inappropriate retention marketing for safety-related cancellation. Existing safety and membership-expiry behaviour remains owned by its respective systems.

Proposed approved wording, populated with confirmed store values:

> **40% off your next renewal**  
> If you keep **[membership name]**, your next payment will be **[discounted price] on [date]**.  
> After that, your membership renews at **[normal price] per month**, unless you cancel.  
> This discount applies to this membership only.  
> **Apply discount** · **Continue cancellation**

Do not present 40% unless the actual configured saving supports it. Do not hard-code a computed price/date as provider truth or move a grandfathered member to a higher standard price merely to provide a temporary discount. Both actions must be easy to find.

## 3. Eligibility, reservations and billing truth

Maintain distinct person, authorised payer, continuing membership and provider subscription/purchase lineage. Enforce restrictions across existing known links; do not claim perfect detection of duplicate people. Shared cards, devices or addresses are not sufficient grounds to merge identities or deny eligibility. Do not collect extra identity documents for this offer.

Before issuing purchase authorisation, atomically check eligibility and reserve against both the person and membership. Repeated requests return the existing attempt. Provider-confirmed acceptance converts it to a pending-payment reservation. A successful discounted payment records redemption once against both histories and starts the annual limit.

Distinct events: presented, attempt reserved, provider accepted, pending discounted payment, redeemed, terminal unredeemed, refunded, charged back, administratively reversed. Refund/dispute events preserve the earlier redemption; do not overwrite it with a destructive replacement state.

Do not release pending accepted offers merely on a local tap, reinstall, changed device/store, disabled auto-renewal or delayed webhook. Release only on evidence the purchase cannot complete or the promotional state definitively ended without redemption. Short attempt timeouts must not allow duplicate completion after a late provider event.

Retry/grace follows the existing authorised billing lifecycle. No second offer and no extra entitlement beyond those rules. Reservations/cooldowns never obstruct cancellation, ordinary purchases, account controls or support.

## 4. Operational limits and measurement

- Reconciliation begins immediately on an unclear/delayed event; 24 hours is the maximum initial resolution target, not a deliberate delay.
- Escalate unresolved cases to support after 48 hours.
- Manual resolution target: seven days. A missed target triggers escalation, not an invented provider state or automatic reservation release.
- Define retry scheduling, ownership, alerts and pending-case recovery before activation; do not create an unapproved recurring automation from this policy.
- Review the pilot after at least 90 days AND sufficient successful redemptions/later full-price renewals to assess results. A numeric minimum sample is not yet established; small samples remain inconclusive.
- Measure eligible attempts, presentation, provider acceptance, discounted payment, later full-price renewal, 60/90-day paid retention, contribution, repeat attempts, duplicate prevention, cancellation duration and complaints.
- Use an eligible comparison group if feasible; otherwise label staged results observational.
- Stop/revise for negative contribution, obstructed cancellation, repeated complaints or frequent duplicate-offer defects. Successful marriage-related departures are not retention failures.
- Retain only necessary cancellation/promotion evidence under an agreed retention/access policy; exact retention duration remains an activation dependency.

## 5. Existing implementation facts checked

The current commercial source is `SUB BUSINESS/ZYRA/BUSINESS/ZYRA PRICING/ZYRA_PRICING_CURRENT_VERSION_V6.md`, controlled by DR-ZYRA-248. It names **Seeker One £29.99/month**, **Guardian One £19.99/month** and configurable ZYRA Family, with staged commerce activation. Its Seeker trial is not an eligible standard-price period.

The current Paid Membership Client Handover V5 and OA-ZYRA-253 explicitly leave live billing, receipts, store products, verified-person callbacks and production activation outstanding. A bounded source search found no StoreKit, Google Play or RevenueCat purchase integration establishing live retention functionality. This is source/document inspection, not a signed-in store inventory or a runtime purchase test.

The approval's older **ZYRA One / Additional Guardian** wording needs reconciliation with those current product names and role permissions. It does not authorise an invented new SKU or eligibility based solely on whether a Guardian happens to be Main for one Seeker. The subsequent scope amendment in §8 includes Seeker One, Guardian One regardless of Main/Additional link role, and ZYRA Family. Before store configuration, confirm the exact corresponding product IDs. Source prices above are not verified storefront charges or discount-price promises.

## 6. Implementation and verification sequence

1. Resolve included current product IDs/roles under §8, store and UK storefront; preserve current approved pricing and decide the Family-specific recommendations before implementation.
2. Establish actual unit contribution and available offer price points. Present any material percentage/pricing drift before activation.
3. Inspect and implement the approved billing foundation under OA-ZYRA-253; record chosen integration, provider receipt authority and continuing subscription linkage.
4. Stage server eligibility, atomic reservations, idempotent event processing, correction permissions, retention and reconciliation. Prepare an exact migration only once its dependencies are concrete.
5. Prepare the cancellation UI with truthful billing management and offer confirmation; do not claim a discount is active before provider acceptance.
6. Prove isolated eligibility/concurrency cases and store sandbox scenarios below. Record observed timing/prices/events; do not report simulated results as store acceptance.
7. Present the verified configuration, margins, tests, rollout/rollback, monitoring and unresolved limitations for the separate exact production activation/release approval.

Required test scenarios: two completed periods including initial purchase; trials/promotions/refunds excluded; grandfathered standard-price preservation; annual boundary; known cross-role/store links; simultaneous requests on two memberships; repeated and late events; failed/abandoned authorisation; acceptance then cancellation; discounted renewal then normal-price renewal; retry/grace/expiry; refund/dispute and authorised correction; Family and Additional Guardian inclusion; skipped reason; all cancellation reasons; accessible cancellation; no retained entitlement invented by reservations. Family-specific scenarios are in §8.

Testing status: **NOT EXECUTED for the pilot.** Live billing dependency remains outstanding; this preparation establishes the test contract rather than asserting it has passed. No public offer should be advertised until exact store mechanics and contribution pass.

## 7. Traceability and handover

This durable approval/preparation record is assigned to existing OA-ZYRA-253, which already owns billing/receipt/entitlement activation. No duplicate OA identifier was consumed. The central OA register and pricing document were not modified in this turn; they remain the existing product foundation rather than a purported complete retention implementation.

Evidence: Founder approval in this conversation dated 27 September 2026; Founder-relayed ChatGPT reviews; Codex final convergence; full current pricing and membership-handover reads; owning OA-ZYRA-253 inspection; bounded source search. Prepared and internally checked by Codex under AD-AIOS-111. Production activation and Founder acceptance are pending.

## 8. Founder scope amendment and Family abuse review — 27 September 2026

Founder instruction: include Additional Guardian and Family and check abuse from changing the main payer. This is approval of the scope extension, not automatic acceptance of every safeguard recommended below. Existing one-renewal, two-completed-period, 12-month, refund-history, cancellation-access and activation controls continue.

Included product mapping: Seeker One; Guardian One including people acting as Additional Guardians; ZYRA Family. Main/Additional is link authority, not a separate current subscription SKU. An individual guardian's offer discounts their own membership; a guardian covered through Family uses the Family billing flow, not a second personal offer against that same coverage.

Checked current contract: Pricing V6 §4 requires a verified existing Family member to accept ownership and establish a replacement purchase; ownership changes at renewal. Local pricing/catalogue preparations are not proof that provider purchase transfer or discount enforcement exists. Do not equate this ZYRA Family product with Apple's separate Family Sharing feature.

### Historical recommendations before final convergence — superseded where inconsistent with §9

1. **Continuing Family identity:** retain a stable internal Family membership lineage and its paid-period, pending-offer, redemption and cooldown history through payer/owner, card, email, role, store and provider-subscription changes. A new provider purchase identifier is not a fresh Family allowance. Check the existing Family history AND the incoming verified payer's person history atomically. Only the current authorised payer can accept the offer.
2. **Re-created groups:** known migration/re-creation of the same Family carries its history. Record the verified people whose coverage benefited from a discounted renewal so moving those people into another group cannot simply manufacture another discount. A member/payer move is not itself evidence of fraud. Exact beneficiary eligibility/partial-Family handling remains a policy decision; route mixed or ambiguous histories to review rather than silently rejecting the whole Family or inventing identity matches. Shared cards, homes, devices, surnames or Guardian links alone do not establish a duplicate Family.
3. **Earned history:** require two completed renewals at that Family's normal applicable price, including its ordinary contractual Family volume saving. That built-in saving is the standard Family price, not a disqualifying promotional period. New unrelated Families do not borrow another member's individual paid history to qualify immediately. Confirm how genuinely continuing individual-to-Family coverage counts before implementation; payer transfer within an existing Family must not reset earned history.
4. **Composition changes:** bind an offer to a recorded qualifying composition and provider-confirmed price. Recommended monetary ceiling: the retention saving cannot exceed 40% of the qualifying Family's actual standard renewal charge, and cannot exceed 40% of the actual smaller renewal charge if places decrease. Adding places after qualification must not increase the retention saving. Verify whether store products can implement this; if not, do not advertise the ceiling as enforced. Before acceptance, changed composition requires a fresh verified quote/reservation, not a second allowance. After acceptance, handle changes through tested provider mechanics or support; never block ordinary cancellation or necessary membership changes.
5. **Ownership transfer while pending:** reconcile the old and replacement provider purchases together. Do not duplicate, assume portability of, or silently promise an accepted promotion on the replacement payer's purchase. Show the verified effect of transfer before confirmation. A pending offer/reservation remains linked to the continuing Family until its authoritative outcome is established; cancelling the old purchase alone is not proof that it cannot redeem.
6. **Financial floor:** Family already saves up to 40% against summed individual base prices. Another 40% off the normal Family price yields up to 64% total saving against that base (0.6 × 0.6 = 0.36), before store rounding. Evaluate each supported composition/price point after actual tax, store fees and costs, including unused places and permitted additions. The Founder has included Family in scope; that does not waive the previously approved positive-contribution condition. Any lower Family percentage, amount cap beyond the recommended ceiling, or different offer requires an explicit Founder decision.

Additional test cases under OA-ZYRA-253: payer A redeems then transfers to B; transfer during pending acceptance; B has recent individual redemption; cancellation/re-creation; same known members moved into another Family; genuinely unrelated new Family; Family-to-individual and individual-to-Family migration; simultaneous offers on old/new provider purchases; additions/decreases before and after acceptance; member leaves with funded access; delayed renewal/refund events; normal volume-discount periods counting; high-discount Family margin; ordinary cancellation and coverage changes remain available.

Platform evidence checked: Apple allows developer eligibility criteria for promotional offers, with server authorisation (https://developer.apple.com/documentation/storekit/implementing-promotional-offers-in-your-app). Google documents linked purchase tokens for replacement subscriptions (https://developer.android.com/google/play/billing/subscriptions). Neither establishes a universal cross-payer/cross-store Family fraud limit; that needs ZYRA's own server history and verified provider integration. No claim of perfect fraud prevention, store compatibility or real purchase testing is made.

Trace: scope amendment filed in this owning brief for OA-ZYRA-253. Central register, pricing contract, app code and live store configuration unchanged. Pre-amendment file SHA-256: b9fe342c1c374dfd4f8343f580e678a8fe1f5b89121b97f1335692e6e515bfc7. Internal document checks only; runtime/store tests remain unexecuted.

## 9. Binding Founder approval of converged Family safeguards — 27 September 2026

Authority: Founder direct message headed “FROM FOUNDER — TO CODEX”, approving the converged Family safeguards and explicitly requesting a concrete commercial/store-feasibility package before a separate implementation approval.

Approved policy:

- Target 40% off one Family renewal, conditional on verified contribution and supported store pricing.
- Lock the maximum saving at acceptance. Added paid places cannot increase it. If the actual final renewal price decreases, cap the saving so it does not exceed 40% of that price.
- Successful redemption consumes the continuing Family membership's rolling 12-month allowance and the accepting payer's personal rolling 12-month allowance. Beneficiaries who did not accept/pay do not lose their personal allowance.
- Payer changes do not reset Family history. Preserve explicit lineage through transfers, restoration, replacement purchases, reactivation, supported store migrations, plan changes and known recreation. A new purchase identifier is not automatically a new allowance.
- Do not merge or accuse Families solely from surname, address, device, card, Guardian relationships or shared members. Ambiguous continuity receives proportionate support review.
- Explicit continuing individual-to-Family conversion requires two completed standard-price monthly periods in total, at least one completed standard-price Family period, and only qualifying history of the same verified payer/continuing conversion. Unrelated memberships cannot donate history.
- Additional Guardian is a link role within Guardian One, not a retention SKU. No per-link offer, allowance or discount logic. Family-funded places use Family billing.
- Material platform/commercial departures return to the Founder; no silent substitute.

Explicitly not approved: production implementation, store-product creation, database migrations, cancellation-flow changes, final contribution threshold, record-retention duration, final Apple/Google configuration and production rollout. Do not treat earlier testing approval as permission to create products or change the app now. Sandbox/runtime evidence requiring those changes remains a future separately approved step.

Prepared artifact: `ZYRA_RETENTION_COMMERCIAL_AND_STORE_FEASIBILITY_2026-09-27_V1.md` — moved to the private group folder (7 Nov 2026) in this reports directory. It is an initial documented assessment, not a completed account audit or verified commercial GO. Findings belong to existing OA-ZYRA-253; central register not edited in this turn. No duplicated OA created.

Pre-edit SHA-256 of this brief: 97aefa452550dddead00c640595189d9c36cf70022f5a895b74f1da268d79965. Earlier §8 proposals to track beneficiaries for discount eligibility or lock at qualification rather than acceptance do not override this final payer-only/acceptance-based approval.
