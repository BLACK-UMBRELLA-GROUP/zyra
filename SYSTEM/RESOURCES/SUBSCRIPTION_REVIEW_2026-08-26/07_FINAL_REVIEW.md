# Fable — final deliverable

*Fable · claude-sonnet-4-6 · 2026-08-26T00:11:07.356245+00:00*

# ZYRA Subscription Architecture Final Review

**Run:** SUBSCRIPTION_REVIEW_2026-08-26
**Produced by:** Fable (Claude), product and commercial reviewer
**Codex verification:** Task 06 failed — HTTP 429, token limit exceeded. Codex did not deliver a final verification verdict. This document proceeds on Fable's analysis only. Where Codex's earlier challenges agreed with Fable, that agreement is noted. Where Codex disagreed, the disagreement is recorded in section 18. The absence of a final Codex verdict is not treated as endorsement.
**Status:** Analysis and recommendation only. No code changed. Awaits Founder ratification before any implementation begins.
**Governing baseline:** Part A / ZYRA_PRICING_CURRENT_VERSION_V2 outranks Part B wherever they disagree.

---

## Five Lines for 7am

Keep £39.99 ZYRA One and the D14 Guardian+ bundle — the case for abolishing them rests on problems that are already solved. £34.99 is retired; do not reinstate it without a deliberate decision. Document why Guardian+ standalone costs £24.99 before any billing is built, because that price sits directly in the path of your biggest adoption risk. Do not launch a Family plan yet — design it now, launch it once real payment flows are stable and you have ninety days of individual-subscription data. Seven decisions only you can make are listed in section 16; none of the rest of this document moves until those are answered.

---

## 1. Executive Recommendation

**Retain the current bundled model, ratified 2026-08-23, and complete its implementation before changing the architecture.**

The Founder's proposed personal non-transferable model at £34.99 is not recommended. The case for it rests on three premises that are incorrect as stated (see preliminary corrections below and in prior documents), uses a retired price, and requires Guardian-to-paid-tier conversion at an unknown rate before it outperforms the current architecture commercially. Its structural advantages — entitlement ownership clarity, dual-role simplicity, multi-Seeker Guardian stability — are real, but they are either already addressed by D14 and Subscription Continuity Principle V1, or they are problems that would exist equally under the personal model (multi-role accounts remain unresolved under either architecture).

The recommended path is:

1. Retain ZYRA One at £39.99/month with the D14 bundled Guardian+ entitlement for the Main Wali.
2. Resolve the Guardian+ standalone price rationale before billing is built — £24.99/month requires documented commercial reasoning, and this review suspects it may be set above the adoption-critical threshold.
3. Build weekly billing surfaces (OA-ZYRA-253(c)) and resolve multi-role account architecture before any subscription launch.
4. Design ZYRA Family now; launch it only after ninety days of real individual-subscription data.
5. The Founder resolves seven specific decisions (section 16) before implementation proceeds.

If the Founder chooses to adopt the personal model after reviewing the risks in this document, section 16 identifies exactly what changes and what further decisions that model requires. This review does not recommend it, but it documents the conditions under which it would be less damaging.

---

**Three corrections to Part B that govern the entire review:**

*£34.99 is a retired figure.* The pricing document lists it under "never quote." It was the price of ZYRA One until 2026-08-23, two days before this review. Part B describes returning to £34.99 as a reduction from £39.99. It is a reversal of a deliberate decision made inside the same fortnight. Every reference to £34.99 in this document is flagged. The Founder must make an explicit decision to reinstate it; this review does not.

*Guardian+ standalone already exists at £24.99/month (£14.99/week).* Part B's central household scenario — father needing "another £34.99" for premium Guardian tools — describes a product that does not exist. The current product has a purpose-built Guardian-only SKU. The real question is whether that SKU is correctly priced, not whether premium Guardian access should be separable.

*The bundle is already bounded to one Guardian.* D14 (OA-ZYRA-247, ratified 2026-08-23) limits the bundled entitlement to the Seeker's Main Wali only. Part B's concerns about "which Seeker funds the Guardian" and "one Guardian representing several Seekers" are substantially answered by D14 in combination with Subscription Continuity Principle V1.

---

## 2. Recommended Basic Model

**ZYRA Basic remains free, permanently, for every account holder regardless of role.**

### Seeker context — permanently free

- Create and maintain a profile with photos.
- Browse up to 50 profiles per 4-hour window.
- Save up to 10 profiles per day.
- Like up to 10 profiles per day.
- One Active Journey.
- Unlimited Potential Journeys.
- Standard Compatibility Unlock on Active Journey creation.
- No sponsored cards whilst browsing.
- Link a Guardian.
- Seven-day ZYRA One trial on the first Active Journey.

### Guardian context — permanently free

- Accept an invitation and establish a Guardian relationship.
- View the Seeker's profile and Active Journey.
- Receive notifications for Journey milestones requiring Guardian input.
- Exercise all Guardian Network authority: send, accept, withdraw, and proceed (GN Rules 37/38). **Authority is never paywalled.**
- Communicate within the Guardian Network on the Seeker's journey.
- View match outcomes and provide substantive input on compatibility decisions.
- Withdraw Guardian status at any time.

### Safety functions — permanently free, unconditionally

- Block any user.
- Report any content or user.
- All privacy controls.
- Ability to withdraw Guardian authority immediately.

### The test this tier must pass

A father who accepts his daughter's invitation and uses only ZYRA Basic must be able to genuinely exercise his role as Wali — reviewing matches, expressing his view, formally participating in Guardian Network decisions. If he cannot do those things without paying, Basic is not credibly useful and the adoption argument for the entire commercial architecture collapses. The exact Basic/premium feature split must be audited against the full Guardian journey specification before any subscription is launched. This review cannot complete that audit from the information available; it is a Founder and product decision flagged in section 16.

---

## 3. Recommended ZYRA One Model

**Retain ZYRA One at £39.99/month with the D14 bundled Guardian+ entitlement. No structural changes to this product.**

### Price

£39.99/month. £19.99/week (ratified; billing surface unbuilt). £399.90/year (10 months paid, 12 received; derived, awaiting explicit Founder confirmation — flagged as open item OA-ZYRA-253(a)).

£34.99 is not recommended. The commercial reasoning for the 2026-08-23 increase is not recorded in the brief, so this review cannot assess whether £39.99 was correct — but reinstating a retired figure without a deliberate pricing decision is not the answer. If the Founder believes £39.99 is wrong, the correct process is a documented repricing against market comparables, not a reversion to the prior figure.

### Who buys it

Any account holder, regardless of role. A Guardian who wants premium capability in their own right purchases ZYRA One (or Guardian+ standalone — see section 3b below).

### What it includes — Seeker context

- Everything in ZYRA Basic.
- Unlimited browsing, Saves, and Likes.
- Incoming Potentials (see who Liked you first).
- Mutual Save Detection.
- Higher Active and Paused Journey limits.
- Priority Discovery.
- Compatibility Unlock Plus on Active Journey creation.
- Three free Compatibility Unlock Plus credits.
- ZYRA Intelligence: Recommendations, Insights, Summaries.
- **One bundled Guardian+ entitlement for the Seeker's Main Wali** (D14, OA-ZYRA-247).

### What it includes — Guardian context (when purchased by a Guardian, or when the Main Wali receives the D14 bundle)

- Advanced Guardian Dashboard with Journey analytics.
- Multi-Seeker intelligence (where the Guardian is Main Wali to more than one Seeker).
- Deeper family and compatibility insights.
- Advanced recommendation and workflow tools.
- ZYRA Intelligence applied to the Guardian view.
- Additional premium Guardian Network tools.

### The D14 bundle — retained, bounded, unchanged

The bundled entitlement covers the Seeker's Main Wali only. Additional Guardians beyond the Main Wali must purchase Guardian+ standalone. This is implemented in `wali_has_wali_one()` and ratified in OA-ZYRA-247. It is not modified by this review.

### Payment buys access, never authority

GN Rules 37 and 38 are unchanged. Authority is determined by the relationship structure, not the payment tier.

---

### 3b. Guardian+ Standalone — Pricing Decision Required Before Build

**Current ratified price:** £24.99/month · £14.99/week · no yearly SKU ratified.

**This review's assessment of the price:** The £24.99/month price lacks documented commercial rationale and represents a 150% increase from the predecessor figure (£9.99/month, recorded explicitly in the V2 change log as the "before" figure). For a SKU whose purpose is to allow Guardians to participate in premium capability independent of a Seeker's subscription, £24.99/month may be priced above the threshold at which adoption-critical Guardians will convert.

Codex also flagged this in its challenge, independently of Fable. Both reviewers reached the same concern via different routes. This is the one point of strong convergence in the adversarial review.

**This review cannot recommend a specific replacement figure** because the rationale for £24.99 is not recorded. The Founder must resolve this before billing is built. Two defensible positions exist:

- *If £24.99 reflects the value of Guardian+ capability (roughly 60% of the ZYRA One price for a Guardian-only entitlement):* £24.99 is internally coherent and should stand with documented reasoning.
- *If £24.99 should be the adoption-supporting price for Guardians who are not primary product customers:* £14.99–£19.99/month is more appropriate for that goal. The lower end of that range is the ratified weekly price, which provides a useful internal anchor.

**Flagged as Founder decision required. Recorded in section 16.**

---

## 4. Recommended Family Model

**Design ZYRA Family now. Do not launch it yet.**

### Why not yet

The individual subscription layer has no real payment flows. Weekly billing surfaces are unbuilt. The multi-role account architecture is explicitly unresolved. Launching a Family plan — which is architecturally more complex than individual billing — before individual billing is proven would compound known risks with new ones. A Family plan launched prematurely and then restructured damages user trust more than a Family plan that launches later and cleanly.

### Trigger conditions for Family launch

1. Real payment flows (App Store and Play Store) are live and stable.
2. At least 90 days of individual-subscription data showing conversion rates, churn, and Guardian-adoption behaviour.
3. Multi-role account architecture is resolved and documented.
4. The Guardian+ standalone price rationale is documented and the price is confirmed or corrected.

### Recommended model: Modified Family-D

*Structure:* A Family plan provides a defined number of full ZYRA One identities at a bundle price. Each member holds their own account with their own full entitlements. The plan creates a billing group, not a shared-entitlement pool. No member is a second-class participant. The D14 Guardian+ bundle applies within the Family plan identically to individual subscriptions: each Seeker member's entitlement includes Guardian+ for their Main Wali, whether that Main Wali is inside or outside the Family plan.

*Why not Model A (limited Seeker seats):* Creates a two-class family structure. Directly recreates the adoption friction the bundled model avoids.

*Why not Model B (5 full ZYRA One at £99 with a very large discount):* At £99 for five accounts against an individual price of £39.99 × 5 = £199.95, the discount is 51%. That is likely unsustainable and invites abuse. It is appropriate as a launch promotion, not as a permanent price.

*Why not Model C (shared Guardian infrastructure):* Architecturally vague. Risks recreating bundled-entitlement complexity in a new form.

### Indicative Family parameters (for design, not ratification)

| Parameter | Indicative value | Rationale |
|---|---|---|
| Members | Up to 5 | Realistic nuclear family. Extendable with paid additional seats. |
| Entitlement per member | Full ZYRA One | No second-class members. |
| Monthly price | £99 | Cheaper than 3 individual ZYRA One subscriptions (3 × £39.99 = £119.97). Natural conversion point at 3+ members. |
| Yearly price | ~£990 | 10-for-12 model, consistent with individual pricing. Founder decision required. |
| Organiser role | Billing only | Pays the subscription; does not control other members' account permissions, Seeker autonomy, or Guardian authority. Organiser billing authority does not create organiser authority over any Journey. |
| Additional seats | £24.99/month each (indicative) | Below individual ZYRA One cost; above zero. Prevents unlimited group growth. |
| Yearly additional seats | No ratified figure yet | Requires Founder decision when Family is designed for launch. |

These figures are indicative for design purposes only. The Founder must ratify all Family pricing before build begins.

---

## 5. Exact Pricing Recommendation

All prices use ZYRA_PRICING_CURRENT_VERSION_V2 as the source of truth. No price change is recommended in this document. Prices flagged with † are open items requiring Founder decision.

| Product | Weekly | Monthly | Yearly |
|---|---:|---:|---:|
| ZYRA Basic | Free | Free | Free |
| ZYRA One | £19.99 *(unbuilt)* | £39.99 | £399.90 † *(derived; awaiting Founder confirmation)* |
| Guardian+ standalone | £14.99 *(unbuilt)* | £24.99 † *(rationale required before build)* | — |
| Compatibility Unlock | — | £1.99 single · 5 for £7.99 | — |
| Compatibility Unlock Plus | — | £2.99 single · 5 for £9.99 | — |
| ZYRA Family | — | £99 *(indicative; not ratified)* † | £990 *(indicative; not ratified)* † |

**£34.99 is not recommended.** It is a retired figure. It must not appear in any pricing-facing surface. Any decision to reinstate it requires an explicit Founder ratification with documented rationale.

**Annual saving shown in-app (ZYRA One):** £399.90 vs 12 × £39.99 = £479.88. Saving: £79.98, which is 16.7% — shown as 17% per the existing toggle label. This is accurate and consistent with the V2 pricing model once £399.90 is confirmed.

---

## 6. Exact Entitlements

### ZYRA Basic — Seeker context

Browse (50 per 4 hours) · Save (10 per day) · Like (10 per day) · One Active Journey · Unlimited Potential Journeys · Standard Compatibility Unlock on Active Journey creation · No sponsored browsing cards · Link a Guardian · 7-day ZYRA One trial on first Active Journey.

### ZYRA Basic — Guardian context

Accept invitation · View Seeker's profile and Active Journey · Receive milestone notifications · Full Guardian Network authority (GN Rules 37/38) · Communicate within Guardian Network · View match outcomes and provide compatibility input · Withdraw Guardian status.

### ZYRA One — Seeker context (adds to Basic)

Unlimited browsing, Saves, Likes · Incoming Potentials · Mutual Save Detection · Higher Active and Paused Journey limits · Priority Discovery · Compatibility Unlock Plus on Active Journey creation · 3 free Compatibility Unlock Plus credits · ZYRA Intelligence (Recommendations, Insights, Summaries) · **Bundled Guardian+ for Main Wali only (D14).**

### ZYRA One / Guardian+ — Guardian context (adds to Basic)

Advanced Guardian Dashboard · Journey analytics · Multi-Seeker intelligence · Deeper compatibility and family insights · Advanced recommendation tools · ZYRA Intelligence applied to Guardian view · Premium Guardian Network workflow tools.

### Guardian+ standalone

Identical capability to ZYRA One Guardian context. Source of entitlement does not affect what the Guardian can do (AD-081). Authority is not affected by either source (GN Rules 37/38).

### Subscription Continuity

On any subscription state change — expiry, cancellation, payer change, upgrade, downgrade, or temporary lapse — the following are never deleted, reset, or altered: all Guardian relationships and wali links; all Journey history and Timeline; all match history and conversation history; all configuration including notification preferences, Primary Guardian designation, and saved settings. Capabilities change. Data does not.

---

## 7. Worked Household Examples

All examples use ratified prices from Part A. £34.99 is not used. Guardian+ annual is not ratified; 12 × monthly is used as a conservative estimate where annual figures are shown. Figures marked *(est.)* are estimates; figures marked *(derived)* follow from the 10-for-12 model.

---

### Household 1 — Daughter (Seeker, ZYRA One) + Father (Guardian, Basic)

The most common ZYRA household. Father fulfils his Wali role using Guardian Basic. Daughter wants premium Seeker features.

| | Monthly | Annual |
|---|---:|---:|
| Daughter: ZYRA One | £39.99 | £399.90 |
| Father: ZYRA Basic | £0 | £0 |
| Father: Guardian+ bundled via D14 | £0 (included) | £0 (included) |
| **Household total** | **£39.99** | **£399.90** |

Father has full Guardian+ capability at no additional cost. This is the bundled model's strongest practical argument: the most common household pays £39.99 and both participants are fully served.

---

### Household 2 — Daughter (Seeker, ZYRA One) + Father (Guardian) who also wants premium

Father wants premium Guardian tools independent of Daughter's subscription.

| | Monthly | Annual |
|---|---:|---:|
| Daughter: ZYRA One (includes D14 bundle for Father) | £39.99 | £399.90 |
| Father: Guardian+ standalone (own subscription) | £24.99 | £299.88 *(est.)* |
| **Household total** | **£64.98** | **£699.78 *(est.)*** |

Father's Guardian+ standalone entitlement is identical in capability to the D14 bundled entitlement. In practice, Father already receives Guardian+ via D14; purchasing standalone would be redundant unless he is Main Wali to other Seekers, or he wants his entitlement to persist independently of Daughter's subscription.

**Practical note:** Under the current architecture, Father's need to purchase standalone Guardian+ arises primarily if Daughter cancels ZYRA One. At that point, his bundled entitlement revokes (per Continuity V1), and he may choose to purchase standalone to continue. The relationship and all history persist regardless.

---

### Household 3 — Two Sisters (Seekers, both ZYRA One) + Father (Guardian, Main Wali to both)

| | Monthly | Annual |
|---|---:|---:|
| Sister 1: ZYRA One (D14 bundle covers Father as her Main Wali) | £39.99 | £399.90 |
| Sister 2: ZYRA One (D14 bundle covers Father as her Main Wali) | £39.99 | £399.90 |
| Father: covered by D14 from both | £0 | £0 |
| **Household total** | **£79.98** | **£799.80** |

Father's `wali_has_wali_one()` returns true via either Seeker's active ZYRA One subscription. He has stable Guardian+ capability: even if one sister cancels, his entitlement continues via the other sister's subscription until that also lapses. When both lapse, the relationships and history persist; his capabilities reduce to Basic.

---

### Household 4 — Two Sisters + Parents (Both Parents are Guardians to Both Sisters)

Father is Main Wali to Sister 1. Mother is Main Wali to Sister 2. Both parents want Guardian+ on both daughters' journeys.

| | Monthly | Annual |
|---|---:|---:|
| Sister 1: ZYRA One (Father's Guardian+ bundled via D14) | £39.99 | £399.90 |
| Sister 2: ZYRA One (Mother's Guardian+ bundled via D14) | £39.99 | £399.90 |
| Father: Guardian+ standalone (for Sister 2's journey) | £24.99 | £299.88 *(est.)* |
| Mother: Guardian+ standalone (for Sister 1's journey) | £24.99 | £299.88 *(est.)* |
| **Household total** | **£149.96** | **£1,399.56 *(est.)*** |

This is the most expensive natural household case. Four active subscriptions for two seeking-marriage journeys with full bilateral Guardian coverage. ZYRA Family at £99/month for up to 5 members would reduce this household's bill by £50.96/month — a compelling conversion argument. This is the household that justifies the Family plan's existence.

---

### Household 5 — Father (Guardian) who is Main Wali to Three Separate Seekers

Three adult children, three separate ZYRA accounts, Father is Main Wali to all three.

| | Monthly | Annual |
|---|---:|---:|
| Child 1: ZYRA One (Father's Guardian+ bundled) | £39.99 | £399.90 |
| Child 2: ZYRA One (Father's Guardian+ bundled) | £39.99 | £399.90 |
| Child 3: ZYRA One (Father's Guardian+ bundled) | £39.99 | £399.90 |
| Father: covered by D14 from all three | £0 | £0 |
| **Total (children only)** | **£119.97** | **£1,199.70** |

Father has stable Guardian+ entitlement via three independent sources. Under the current architecture, `wali_has_wali_one()` returns true if any linked Seeker's active ZYRA One exists. If all three children cancel, his capabilities reduce to Basic; relationships and history persist.

**This is the cleanest case for the personal model's structural argument:** Father's entitlement is currently dependent on three separate billing chains. Under a personal model, his one personal ZYRA One or Guardian+ subscription covers all three simultaneously. That is a genuine architectural simplification. It is also the case where Guardian+ standalone at an affordable price (£14.99–£19.99) would most obviously pay for itself.

---

### Household 6 — Dual-Role User (Seeker and Guardian simultaneously)

A man seeking marriage himself, and also acting as Wali to his sister.

| | Monthly | Annual |
|---|---:|---:|
| His own Seeker context: ZYRA One | £39.99 | £399.90 |
| His Guardian context (Wali to his sister): covered by his own ZYRA One entitlement? | Architecturally ambiguous | Architecturally ambiguous |
| Sister: ZYRA One | £39.99 | £399.90 |
| Sister's D14 bundle covers him as her Main Wali | £0 additional | £0 additional |
| **Household total** | **£79.98** | **£799.80** |

The dual-role resolution is architecturally ambiguous under the current model (multi-role accounts explicitly unresolved per Continuity V1). In practice, his Guardian+ capability for his sister's journey is covered by her ZYRA One D14 bundle, which is unambiguous. His own Seeker subscription does not need to "cover" his Guardian context because D14 provides the entitlement from the correct direction. But whether one ZYRA One subscription should cover both contexts simultaneously — as the personal model would allow explicitly — is not formally resolved.

**This is the personal model's second cleanest argument:** one subscription, both contexts, no ambiguity. The current model resolves this correctly in practice but not by explicit architectural intention.

---

### Household 7 — 5-Person Premium Household (Family Plan Candidate)

Two parents, three adult children, all wanting premium.

**Without Family plan (current model, each purchases individually):**

| | Monthly |
|---|---:|
| 3 Seekers × £39.99 | £119.97 |
| Father Guardian+ via D14 (assume Main Wali to at least one Seeker) | £0 |
| Mother Guardian+ standalone | £24.99 |
| **Total** | **£144.96** |

**With Family plan at £99/month:**

| | Monthly |
|---|---:|
| All 5 members: ZYRA Family | £99.00 |
| **Saving vs individual** | **£45.96/month (£551.52/year *(est.)**)** |

The Family plan saves this household £45.96/month. The conversion argument is genuine and legible. This is the household ZYRA Family is designed for.

---

## 8. Revenue Implications

All revenue figures are estimates. Real data required: subscriber counts by tier, Guardian activation rates, Guardian willingness-to-pay, churn rates by tier. None of these exist from this preview build. All figures below are illustrative modelling only, flagged accordingly.

---

### 8a — Revenue per household type (monthly, current model)

| Household type | Monthly revenue |
|---|---:|
| 1 Seeker + 1 Guardian (Guardian Basic) | £39.99 |
| 1 Seeker + 1 Guardian (Guardian pays standalone) | £64.98 |
| 2 Seekers + 1 shared Guardian (Basic) | £79.98 |
| 2 Seekers + 2 Guardians (both Basic) | £79.98 |
| 2 Seekers + 2 Guardians (both want independent premium) | £149.96 |
| 3 Seekers + 1 Guardian (Basic) | £119.97 |
| 5-person via Family plan (indicative) | £99.00 |

---

### 8b — The Guardian conversion question (estimate; real data required)

The personal model generates more revenue per household only when Guardians convert to a paid tier. The current model generates more revenue per household when Guardians do not. The break-even point is approximately 10% Guardian conversion rate under Personal-A (Guardian+ standalone survives at £24.99) and approximately 3% under Personal-B (Guardian+ standalone retired; Guardians must purchase ZYRA One at £34.99 *(retired)* to get premium).

These conversion thresholds are estimates derived from the household arithmetic. The actual break-even depends on the precise ratio of Seeker-only households (where the personal model is cheaper for ZYRA) to households where a Guardian would pay (where the personal model is more expensive for the household but more revenue for ZYRA).

**At 10,000 active Seeker households (illustrative — actual numbers unknown):**

| Guardian conversion rate | Current model monthly (est.) | Personal-A monthly (est.) | Difference |
|---|---:|---:|---:|
| 0% (no Guardian ever pays) | £399,900 | £349,900 | −£50,000 |
| 10% | £399,900 | £374,900 | −£25,000 |
| 25% | £399,900 | £412,275 | +£12,375 |
| 50% | £399,900 | £474,650 | +£74,750 |

At 25% Guardian conversion, the personal model begins to outperform the current model by a meaningful margin. Whether 25% is achievable is unknown. Whether the Muslim matrimonial Guardian cohort — many of whom are parents participating in a family religious and social obligation rather than customers choosing a subscription service — will convert at 25% is the central commercial uncertainty of this review.

**This review does not assume that 25% is achievable.** It flags it as the threshold. If the Founder has evidence suggesting Guardian willingness to pay is high in this cohort, the personal model becomes commercially compelling. Without that evidence, the current model is safer.

---

### 8c — The £24.99 Guardian+ pricing risk (estimate)

If Guardian+ standalone is priced above the threshold at which Guardians will pay, the current model's backup path — Guardians who lose their D14 bundle can purchase standalone and continue — is not actually available in practice. The adoption risk of the entire architecture is therefore sensitive to the Guardian+ standalone price more than to almost any other single number in the system. A Guardian who would pay £9.99/month may refuse £24.99/month. If refusal rates are high, the household maths above are optimistic even for the current model.

**Estimate, flagged:** Guardian+ standalone conversion rates at £24.99 are likely lower than they would be at £14.99 or £9.99. By how much is unknown. This is the number the Founder most needs real data on.

---

## 9. Guardian-Adoption Implications

This is the most important section in the document. Everything else is second-order.

### Why Guardian adoption is the architectural constraint

ZYRA's differentiation from every other Muslim matrimonial app is the Guardian integration. This is not a feature; it is the product structure. A model where a Guardian activates, engages, and provides genuine oversight over a period of months is a fundamentally different product to a standard matrimonial app where family involvement is a notification layer. That differentiation requires Guardians to activate when invited, engage meaningfully with the interface, and remain engaged over the duration of a journey.

At every step, friction kills activation. The question this review cannot fully answer from the brief — and which must be answered before launch — is where friction sits in the current design.

### The cultural dimension

In the Muslim matrimonial context, the Wali is not an optional feature. A father who is invited to act as Wali to his daughter is participating in a family religious and social obligation. He is not, in his own understanding, shopping for a subscription service. The app is a tool; the process is a family matter. Asking him to make a payment decision to participate meaningfully introduces a category mismatch that no pricing level entirely resolves. This is not a reason to make Guardian premium free permanently — it is a reason to ensure that Guardian Basic is so genuinely useful that he never needs to make that decision to fulfil his role.

### What Guardian Basic must credibly include

The test is simple: a father who accepts his daughter's invitation and uses only ZYRA Basic must be able to genuinely exercise his role as Wali. The feature list in section 2 is this review's recommended minimum. If the actual product draws the Basic/premium line at a point where a Guardian on Basic cannot meaningfully review matches, participate in Guardian Network decisions, or communicate with the family about the journey — then the label "Guardian Basic is genuinely useful" is not credible, and no pricing decision will fix the adoption problem it creates.

**Critical action required before any subscription launch:** Conduct a full Basic/premium feature audit against the Guardian journey specification. Map every Guardian-facing function against the Basic/premium line. Any function required for genuine Guardian participation that sits behind a paywall is a product defect, not a pricing strategy.

### The £24.99 Guardian+ adoption risk

Guardian+ standalone at £24.99/month is the mechanism by which a Guardian who wants premium independent of a Seeker's subscription can obtain it. It is also the mechanism by which a Guardian whose Seeker cancels can continue with premium capability. If that price is set above the threshold at which adoption-critical Guardians will pay, the mechanism fails in practice even if it exists in the pricing document.

Both reviewers flagged this independently. It is the single most commercially sensitive price in the architecture. It must be documented and validated before billing is built.

### What would confirm or refute the adoption risk

Real data required: Guardian activation rates (what percentage of invited Guardians accept and create an account), Guardian engagement depth (what percentage reach meaningful Guardian Network participation), Guardian willingness to pay (what percentage of Guardians who would not receive a free bundle would purchase standalone Guardian+), and Guardian churn on paid tiers (whether Guardians who pay cancel quickly or stay). None of this data exists from the preview build. The launch should be designed to generate it.

---

## 10. Family-Abuse Prevention

Family plans create an obvious abuse vector: unrelated individuals pooling subscriptions to access a group discount. The following controls are recommended for the Family plan design.

**Relationship declaration at enrolment.** Each joining member declares their relationship to the organiser (daughter, son, father, mother, spouse, sibling). This is self-declaration, not cryptographic proof. It creates accountability and establishes a record, but it does not prevent deliberate abuse by determined individuals. Its primary function is to make abuse a conscious act of misrepresentation rather than an incidental side effect of a permissive system.

**Islamic family structure alignment.** ZYRA's user base is predominantly Muslim. The Wali structure inherently links Guardian and Seeker relationships. A "family" group where no Guardian-Seeker relationship exists between any members is structurally unusual and would not naturally pass Guardian Network validation. The product's own relational architecture acts as a partial abuse filter without requiring separate verification.

**Joining via invitation link with expiry.** Members join via an invitation link issued by the organiser. The link expires within 48 hours. Cold invitations to strangers require deliberate effort. This does not prevent a coordinated group from abusing the system but raises the friction threshold above casual exploitation.

**Membership cap at 5.** Beyond 5 members, additional seats are available at a per-seat price (indicative: £24.99/seat/month). This limits the discount available to any single abusing group and ensures that large groups pay more than the bundle price.

**Removal and continuity.** If the organiser removes a member, or the Family plan lapses, the removed member's account reverts to ZYRA Basic. All their relationships, history, and configuration persist (Continuity V1). They can purchase an individual subscription independently. The organiser's removal decision does not delete any data and does not affect any Guardian relationship or Journey history. **The organiser's billing authority does not create organiser authority over any other member's account, Journey, or Guardian relationships.** This is essential: a father who organises a Family plan cannot use that role to gain additional oversight or control over his daughter's Journey beyond what his Guardian relationship already provides.

**What this does not prevent.** A group of five motivated individuals who know each other and agree to declare false family relationships can abuse the plan. No self-declaration system prevents this entirely. The countermeasure is that the discount (£99 vs approximately £144.96 in a 5-person premium scenario) is meaningful but not so extreme that it creates a mass-market incentive for organised abuse. This is a pricing-design consideration as well as a governance one.

---

## 11. Technical Migration Impact

### Current state

The entitlement service (`ZyraEntitlementService.hasWaliOne()`) resolves Guardian+ capability via a server-side RPC (`wali_has_wali_one()`). That function returns true if the account holds its own `wali_premium` subscription OR is the linked Main Wali of a Seeker with an active `seeker_premium` subscription. This correctly implements D14.

The upgrade screen handles monthly and annual billing toggles. Weekly SKUs are approved pricing but have no billing surface, no store products (App Store/Play Store), and no entitlement service handling.

No real payment flows exist. The preview build mocks entitlements locally (AppState) and via developer-only RPC calls (`mockSetWaliPlan`, `mockPurchaseWaliPremium`).

### If the recommended architecture (retain bundled model) is adopted

**What does not need to change:** The entitlement resolution logic. The D14 boundary. The Subscription Continuity Principle implementation. The authority separation (GN Rules 37/38). The pricing document.

**What needs to be built before launch:**
- Weekly billing surfaces (upgrade screen weekly toggle, store SKU registration for £19.99/week ZYRA One and £14.99/week Guardian+).
- Entitlement service extension to handle weekly subscription types — `wali_has_wali_one()` must recognise weekly `wali_premium` and weekly `seeker_premium` identifiers once those SKUs exist.
- Real App Store and Play Store in-app purchase flows replacing the current mock paths.
- RevenueCat or equivalent subscription management layer for receipt validation, grace