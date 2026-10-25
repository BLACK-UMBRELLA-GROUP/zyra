# ZYRA Subscription Architecture Review — complete

## RUN RESULT
**🟠 COMPLETE BUT CONDITIONS REMAIN**
Safe to rely on: **yes**

- **Cost** $0.09 of $0.50 authorised
- **Completed** sections 1–18, independently verified by Codex
- **Failed** none in repair
- **Decisions for you** section 16, plus Codex's three conditions
- **Recovery** none required

> **Codex verdict: SIGN OFF WITH CONDITIONS.** Three conditions, listed in section 18 and in `06_CODEX_VERIFY.md`.

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

## 12. App Store / Play Store Implications

### Current state of billing infrastructure

No real payment flows exist. The preview build mocks entitlements locally via `AppState` and through developer-only RPC calls (`mockSetWaliPlan`, `mockPurchaseWaliPremium`). The upgrade screen handles monthly and annual billing toggles. Weekly SKUs are ratified pricing (E4) with no corresponding store products, no App Store or Play Store SKU registration, and no entitlement service handling for weekly subscription types.

This is not a minor gap. Until real billing is live, every conversion rate, churn figure, and revenue projection in this review — including this review's own household arithmetic — is modelling without a denominator.

### What must be built before launch

**Weekly billing surfaces.** The ratified weekly prices (£19.99/week ZYRA One, £14.99/week Guardian+) require store product registration on both App Store Connect and Google Play Console, a weekly toggle on the upgrade screen, and extension of `wali_has_wali_one()` to recognise weekly subscription type identifiers. The entitlement resolution logic currently handles monthly and annual variants; weekly variants are not in scope and must be added. This is registered as an open action under OA-ZYRA-253(c) and is a Codex-confirmed condition of sign-off.

**App Store and Play Store in-app purchase flows.** The mock purchase paths must be replaced with real store-mediated flows before any real subscriber can be acquired. This involves product registration, pricing tier selection in both consoles, server-side receipt validation, and handling of edge states: billing failure, grace period, refund, and reinstatement. Each store has its own receipt format, validation endpoint, and grace-period policy, and these must be handled separately rather than assumed to be equivalent.

**Subscription management layer.** A RevenueCat integration (or equivalent) is the appropriate abstraction for receipt validation, entitlement state, cross-platform synchronisation, and webhook-driven subscription event handling. Without this layer, the entitlement service must handle store-specific receipt validation directly, which is technically feasible but substantially increases maintenance burden and the risk of entitlement mismatch during edge states.

### Store-specific constraints relevant to this architecture

**Apple App Store.** Apple's in-app purchase rules require that all digital subscription sales through iOS be processed through App Store billing, with Apple taking a 15–30% revenue share (15% for subscriptions after the first year under the Small Business Programme, 30% in the first year). The Guardian+ standalone SKU and the ZYRA One SKU must both be registered as auto-renewable subscriptions. The Family plan, when built, cannot use a custom family-billing model on iOS — it must either use Apple's Family Sharing infrastructure (which has its own constraints and does not map cleanly to ZYRA's relationship-linked architecture) or be structured as a single auto-renewable subscription on the organiser's account with server-side entitlement distribution to linked accounts. The latter requires the server-side entitlement broker to maintain family membership accurately and in real time, including handling organiser lapse, member removal, and mid-cycle seat additions.

**Google Play.** Google Play's billing policies are substantively similar in their requirements (all digital subscriptions must use Play Billing) with a comparable revenue-share structure (15% after year one for most developers). Play Store subscriptions support base plans and offers, which map reasonably to the monthly, weekly, and annual structure recommended in this review. Play's family billing (Google Play Pass family sharing) is similarly constrained and similarly unlikely to map cleanly to ZYRA's architecture. Server-side entitlement management is the correct approach on Play as it is on iOS.

**Weekly subscription policies.** Both stores support weekly auto-renewable subscriptions. However, weekly subscriptions have higher administrative overhead per subscriber (more renewal events, higher absolute refund risk per unit time), and some store policies treat weekly subscriptions differently in promotional offer eligibility. This does not prevent the weekly plans from launching but is a consideration in billing system design.

**The Family plan's store billing problem.** Codex correctly identified that neither Apple nor Google provides native infrastructure for a flexible family billing model of the kind described in section 4 of this review. A £99/month Family plan for up to five members, with server-controlled member management, seat additions, and individual-member continuity on removal, cannot be implemented as a standard store subscription — it requires a server-side entitlement broker that maintains family group state and distributes entitlements to individual accounts. This is architecturally achievable but is not trivial. It is a further reason to delay the Family plan until the individual billing layer is proven: the individual layer uses straightforward store-native flows; the Family layer does not, and the latter should not be built before the former is stable.

**Promotional pricing constraints.** If the Founder decides to launch ZYRA One at an introductory price or offer a time-limited discount — for instance, if the decision is made to move Guardian+ standalone below £24.99 — store-side promotional pricing has lead times and approval processes. Price changes to existing subscriptions trigger subscriber notifications on both platforms, and existing subscribers must be given notice before their price changes. This is relevant to the Guardian+ pricing decision: once Guardian+ at £24.99 has real subscribers, lowering the price is straightforward operationally but must be communicated properly; raising it requires even more care. Setting the price correctly before billing is built is substantially easier than adjusting it after.

---

## 13. Risks

Risks are listed by severity. Each entry names the risk, its likelihood assessment (qualitative, as no real data exists), and the recommended mitigation.

---

**Risk 1 — Guardian activation failure (Severity: Critical)**

*What it is:* Guardians who are invited do not activate, do not engage meaningfully, or activate and then disengage before the journey reaches a meaningful milestone. The product's core differentiation collapses if the Guardian layer is populated by inactive accounts.

*Why it is critical:* This is not a revenue risk — it is a product risk. Without genuine Guardian participation, ZYRA is a standard matrimonial app with a Guardian-shaped notification system. The commercial model, the ethical positioning, and the competitive differentiation all depend on Guardians being present, engaged, and exercising real oversight.

*Likelihood:* Unknown. No activation data exists. The cultural context (Wali as religious obligation) provides some natural motivation, but the friction of account creation, interface learning, and sustained engagement over a multi-month process may be higher than expected.

*Mitigation:* Ensure Guardian Basic is genuinely useful (section 14). Audit the Guardian onboarding flow against the invitation-to-first-meaningful-action path. Design the launch to capture Guardian activation rates as a primary metric. Do not interpret any other metric as a proxy for product health until Guardian activation is measured.

---

**Risk 2 — Guardian+ standalone price too high (Severity: High)**

*What it is:* Guardian+ standalone at £24.99/month is set above the threshold at which Guardians who are not receiving the D14 bundle will purchase. Guardians who lose their bundle when a Seeker cancels simply do not buy standalone. The fallback path exists in theory but fails in practice.

*Why it is high:* Both reviewers flagged this independently. A 150% price increase with no documented rationale, for a user cohort who are participating in a family religious obligation rather than selecting a consumer product, is a combination that warrants caution. The commercial impact is felt most acutely in the households where Guardian adoption matters most.

*Likelihood:* Moderate to high. Guardian willingness to pay for a standalone subscription at £24.99 is uncertain. The £9.99 predecessor may have been close to the correct adoption-supporting price. The risk increases if Guardian+ standalone is the only path for a Guardian whose Seeker cancels or downgrades.

*Mitigation:* Document the £24.99 rationale before building billing surfaces. Consider A/B price testing once real billing exists. Treat this as the highest-priority commercial validation question in the first 90 days after launch.

---

**Risk 3 — Weekly billing surfaces not built at launch (Severity: High)**

*What it is:* Weekly plans are ratified pricing (E4) with no billing infrastructure. If the product launches with monthly and annual plans only, weekly-plan Seekers and Guardians are unable to purchase. If the product launches without clarifying that weekly plans are unavailable, there is a trust and expectation problem.

*Why it is high:* Weekly pricing is ratified and presumably expected by Guardians and Seekers who have seen it communicated. Launching without it — or without a clear explanation that it is coming — creates a gap between what has been communicated and what is available.

*Mitigation:* Complete weekly billing surfaces before launch, or explicitly scope them out of the launch and do not communicate weekly pricing externally until the surface is built. OA-ZYRA-253(c) records this as an open action.

---

**Risk 4 — Multi-role account architecture unresolved (Severity: High)**

*What it is:* An account holder who is simultaneously a Seeker and a Guardian to another Seeker sits in an explicitly unresolved architectural space. The Subscription Continuity Principle flags this as a separate discussion. Under the current entitlement model, the resolution is handled in practice by D14 providing Guardian+ from the correct direction (the other Seeker's bundle), but the formal architecture is silent on how one ZYRA One subscription should behave when the holder is both a Seeker and a Guardian.

*Why it is high:* This is not a theoretical edge case. A man seeking marriage who is also his sister's Wali is a plausible and probably common user profile in this market.

*Mitigation:* Resolve the multi-role account architecture before any subscription launch. This is a Founder and product decision flagged in section 16. It is also a Codex condition of sign-off.

---

**Risk 5 — Organiser authority leakage in Family plan (Severity: Moderate, deferred)**

*What it is:* A Family plan organiser — a father, for instance — who pays for the household subscription might expect, or attempt to use, that billing role to control other family members' account settings, Journey privacy, or Guardian Network decisions. The current architecture explicitly prohibits this (authority is relationship-determined, not payment-determined, per E7), but the user interface must make this boundary clear.

*Why it is moderate:* It is deferred because the Family plan is not being built now. The risk is real and must be designed against from the start of Family plan development; it is not an immediate operational concern.

*Mitigation:* When Family is designed, the organiser role must be explicitly labelled as billing-only in every interface surface that exposes it. Organiser controls must be scoped strictly to membership management (invite, remove, cancel plan). No organiser control may touch another member's Journey, Guardian relationships, profile, or communication history.

---

**Risk 6 — Store billing failure states not handled (Severity: Moderate)**

*What it is:* When real billing is live, subscription renewals will fail for some users (expired card, insufficient funds, payment method removed). The entitlement service must handle the transition from active to grace period to lapsed state correctly, including ensuring that lapsed-state behaviour matches the Subscription Continuity Principle (history and relationships preserved; capabilities reduced to Basic).

*Why it is moderate:* This is a known, solvable problem. It is on the implementation list rather than the architectural risk list. It becomes high severity if it is not handled before launch, because billing failures affect real users and real relationships.

*Mitigation:* Design the entitlement service grace-period logic as part of the RevenueCat integration. Test with simulated billing failures before launch. Document the expected user experience during a grace period.

---

**Risk 7 — £399.90 yearly price not formally confirmed (Severity: Low, currently)**

*What it is:* The yearly ZYRA One price of £399.90 is derived from the 10-for-12 model and registered under OA-ZYRA-253(a) as awaiting Founder confirmation (E5). It appears in the upgrade screen toggle. If the Founder ratifies a different yearly price, the toggle copy, the annual-saving calculation, and any external communications referencing the annual price must all be updated.

*Why it is low currently:* The price is internally consistent, arithmetically sound, and already in the interface. The risk is low unless the Founder decides it should be different.

*Mitigation:* Founder decision on OA-ZYRA-253(a) before launch. Recorded in section 16.

---

## 14. What Stays Free Permanently

The following capabilities are free for every account holder, in every role, under every subscription state, permanently. They may not be moved to a premium tier, restricted during a subscription lapse, or removed as part of any future pricing change without a Founder decision that explicitly records the product and ethical implications of doing so.

### Identity and presence

Every person who creates a ZYRA account holds that account permanently. Profile data, photos, relationship links, Guardian Network connections, Journey history, match history, conversation history, and all configuration belong to the account holder and are never deleted, restricted, or altered by a subscription state change (E8). This is the Subscription Continuity Principle and it is not a pricing feature — it is a foundational data commitment.

### Seeker capabilities (permanently free)

Browse up to 50 profiles per 4-hour window. Save up to 10 profiles per day. Like up to 10 profiles per day. Maintain one Active Journey and unlimited Potential Journeys. Receive a Standard Compatibility Unlock on Active Journey creation. Browse without sponsored cards. Link a Guardian. Access the seven-day ZYRA One trial on the first Active Journey.

### Guardian capabilities (permanently free)

Accept an invitation and establish a Guardian relationship. View the Seeker's profile and Active Journey. Receive milestone notifications. Exercise all Guardian Network authority — sending, accepting, withdrawing, and proceeding on Guardian Network decisions — as governed by GN Rules 37 and 38. Communicate within the Guardian Network on the Seeker's journey. View match outcomes and provide compatibility input. Withdraw Guardian status at any time.

The Guardian Network authority functions listed above are the most important items on this list. They are the core of the Wali role. No pricing decision, upgrade prompt, or commercial consideration may place them behind a paywall, gate them with a free trial that expires, or restrict them to premium Guardians only. A Guardian on ZYRA Basic, in perpetuity, must be able to send, accept, withdraw, and proceed on Guardian Network decisions for the Seeker whose journey they are part of.

### Safety functions (permanently free, unconditionally)

Block any user. Report any content or user. All privacy controls. Emergency contact features. The ability to withdraw Guardian authority immediately. These functions have no premium equivalent and no tiered version. They are available to every account holder in every state.

### What this means for product decisions

If a feature review ever proposes moving any of the above to a premium tier — for commercial reasons, as part of a feature rationalisation, or as a consequence of a restructure — the decision requires a named Founder decision with recorded reasoning. This is not to make such decisions impossible; it is to ensure they are deliberate rather than accidental. The commercial pressure to deepen the premium/free divide as the product matures is real and predictable. The list above is the floor that must not be breached without explicit acknowledgement.

---

## 15. What Becomes Premium

The following capabilities require an active ZYRA One subscription (or Guardian+ standalone, where the Guardian+ entitlement is the relevant source) to access. They revert to Basic capability on subscription lapse, cancellation, or expiry. History and relationships are never affected by capability changes.

### Seeker premium (ZYRA One)

Unlimited browsing, Saves, and Likes — removing the Basic-tier browse limit, Save limit, and Like limit. Incoming Potentials — the ability to see who has Liked the Seeker's profile before a mutual Like is established. Mutual Save Detection — notification when a saved profile has also saved the Seeker. Higher Active Journey and Paused Journey limits — the exact limits are a product decision not ratified in the documents available to this review; they must be specified before launch. Priority Discovery — the Seeker's profile is shown more prominently in the browse experience of compatible Seekers. Compatibility Unlock Plus on Active Journey creation — the enhanced compatibility report, in contrast to the Standard report available on Basic. Three free Compatibility Unlock Plus credits — usable throughout the subscription period. ZYRA Intelligence — Recommendations, Insights, and Summaries applied to the Seeker's journey. The bundled Guardian+ entitlement for the Main Wali (D14) — not a separate premium feature, but a consequence of ZYRA One that benefits the Main Wali without the Main Wali paying.

### Guardian premium (ZYRA One or Guardian+)

Advanced Guardian Dashboard with Journey analytics — structured data on how a Journey is progressing, milestone history, and timeline visibility beyond the Basic view. Multi-Seeker intelligence — consolidated views and insights for a Guardian who is Main Wali to more than one Seeker. Deeper family and compatibility insights — analytics applied to compatibility matching, family background signals, and recommendation explanations. Advanced recommendation and workflow tools — ZYRA Intelligence applied to the Guardian's view of potential matches. Premium Guardian Network workflow tools — the specific tools in this category are a product decision that must be specified before launch. The exact scope of premium Guardian tooling must be audited against the Basic feature list to confirm that nothing required for genuine Guardian participation appears here.

### Compatibility Unlocks (purchasable separately, not subscription-gated)

Standard Compatibility Unlock: £1.99 single, five for £7.99. Compatibility Unlock Plus: £2.99 single, five for £9.99. These are available to Basic-tier Seekers as one-time purchases and are not gated by subscription status. A Seeker on Basic can purchase individual Compatibility Unlocks without upgrading to ZYRA One.

### The premium/Basic boundary — what must be audited before launch

The entitlement lists above describe the premium features as understood from the available documents. They do not constitute a complete product specification. Before any subscription surface is shown to a real user, the exact feature list at each tier must be audited by the product team against three tests: (a) does every function required for genuine Guardian participation sit in the free tier; (b) does the premium tier add genuine capability rather than removing Basic limitations on already-available features; and (c) does the Basic/premium line as drawn match what a reasonable Guardian or Seeker would understand from the ZYRA communications about the product. This audit is a Founder decision (section 16).

---

## 16. What Requires Founder Decision

This is the action list. Every item below is a decision only the Founder can make. Each item records what this review recommends, what the alternatives are, and what turns on the decision. Implementation must not proceed past the point noted in each item without the Founder's recorded decision.

---

**Decision 1 — Guardian+ standalone price**

*What must be decided:* Whether £24.99/month is the correct price for Guardian+ standalone, and if so, why. This decision must be documented.

*This review's recommendation:* Do not build billing surfaces for Guardian+ standalone until the price rationale is recorded. If the rationale is that Guardian+ delivers premium value equivalent to approximately 60% of ZYRA One, £24.99 is internally coherent. If the rationale is that Guardian+ should be an accessible on-ramp for Guardians not covered by a D14 bundle, a price in the £14.99–£19.99 range is more appropriate for that goal. Both positions are defensible; neither is currently documented.

*What turns on it:* The commercial success of every household scenario where a Guardian's premium capability is not covered by a D14 bundle. This includes: Guardians whose Seekers cancel; additional Guardians beyond the Main Wali; and Guardians who are Main Wali to multiple Seekers and want a personal subscription rather than entitlement dependency. It is also the largest single input to Guardian conversion rate projections.

*Cannot be implemented without this decision:* Guardian+ standalone billing surface.

---

**Decision 2 — ZYRA One yearly price confirmation**

*What must be decided:* Whether £399.90/year is confirmed as the ratified yearly ZYRA One price (OA-ZYRA-253(a)).

*This review's recommendation:* Confirm £399.90. It is arithmetically consistent with the 10-for-12 model, produces a 16.7% saving displayed as 17% on the toggle, and is internally consistent with the weekly and monthly prices. No change is recommended.

*What turns on it:* The upgrade screen annual toggle copy, the annual-saving calculation shown to Seekers, and all external communications referencing annual pricing. If the Founder confirms a different figure, all of the above must change before launch.

*Cannot be implemented without this decision:* Annual ZYRA One SKU registration on App Store and Play Store.

---

**Decision 3 — Multi-role account architecture**

*What must be decided:* How an account holder who is simultaneously a Seeker and a Guardian to another Seeker is handled by the entitlement system, the billing system, and the product interface. Specifically: does one ZYRA One subscription cover both Seeker and Guardian contexts for that person, or must they be resolved separately?

*This review's recommendation:* A single ZYRA One subscription should cover both contexts. This is consistent with the "one subscription, all your contexts" logic and removes the architectural ambiguity that currently exists. However, the implementation details — how the entitlement service determines which context is active, how the upgrade screen presents options to a dual-role user, and how the Guardian context is triggered — require explicit product specification.

*What turns on it:* The completeness of the subscription architecture at launch. A product that launches with a billing surface but no resolution for dual-role users will encounter the ambiguity in practice very quickly, given that dual-role users (a man seeking marriage who is also a Wali) are not an edge case in the target market.

*Cannot be implemented without this decision:* Any subscription launch serving the target market.

---

**Decision 4 — Basic/premium Guardian feature split**

*What must be decided:* The exact list of features available to a Guardian on ZYRA Basic, and the exact list of features that require Guardian+ premium. This must be mapped against the Guardian journey specification function by function.

*This review's recommendation:* Every function required for genuine Guardian participation — reviewing matches, formal Guardian Network authority (send, accept, withdraw, proceed), viewing the Seeker's Active Journey, communicating within the Guardian Network — must sit in the free tier. Premium adds intelligence, analytics, multi-Seeker views, and depth. It does not add participation. The product team must confirm that the current implementation matches this boundary before any upgrade prompt is shown to a Guardian.

*What turns on it:* The entire Guardian adoption argument. If the Basic/premium line is drawn at participation rather than enhancement, the product's central claim — that family involvement is built into the product — is not credible to the Guardians the product needs. This is the most consequential product decision on this list.

*Cannot be implemented without this decision:* Any Guardian-facing upgrade prompt or paywall.

---

**Decision 5 — Weekly billing surfaces scope at launch**

*What must be decided:* Whether weekly billing surfaces (£19.99/week ZYRA One, £14.99/week Guardian+) will be built and live at launch, or scoped to a post-launch release.

*This review's recommendation:* If weekly pricing has been communicated to any external audience — including any beta users, community communications, or social media — build the surfaces before launch. If weekly pricing has not been externally communicated, it is acceptable to scope it to a post-launch release, provided the upgrade screen does not display weekly pricing until the billing surface exists.

*What turns on it:* The entitlement service extension required for weekly SKUs, store product registration, and whether the upgrade screen shows a weekly toggle at launch. If scoped to post-launch, the open action OA-ZYRA-253(c) must record the scoping decision and a target date.

*Cannot be implemented without this decision:* Weekly billing surfaces and the upgrade screen weekly toggle.

---

**Decision 6 — Family plan design commencement**

*What must be decided:* When to begin the Family plan design and build process, and which team resource is assigned to it.

*This review's recommendation:* Begin design now; do not begin build until individual billing is live and 90 days of conversion data exist. The design work — entitlement model, abuse prevention, organiser role scope, billing structure, and store billing approach — can proceed in parallel with individual billing infrastructure without committing engineering resource to the build.

*What turns on it:* The lead time to Family plan launch after individual billing is validated. If design begins now, Family can launch approximately 90–120 days after individual billing is live. If design begins at the 90-day data point, the lead time extends by the full design cycle.

*Cannot be implemented without this decision:* Family plan design sprint.

---

**Decision 7 — Whether to reinstate £34.99**

*What must be decided:* Whether the Founder wishes to reinstate £34.99 as the ZYRA One monthly price, despite it being a retired figure listed under "never quote" in the current pricing document (E1, E2).

*This review's recommendation:* Do not reinstate £34.99. The 2026-08-23 repricing to £39.99 was a deliberate decision. Reversing it within the same fortnight, without documented rationale, undermines pricing consistency and communicates to the market that ZYRA's prices are unstable. If £39.99 is believed to be wrong, the correct process is a documented repricing against market comparables, not reversion to a retired figure.

*What turns on it:* Every pricing surface, all external communications, the upgrade screen, and the revenue projections in this review. If £34.99 is reinstated, all household arithmetic in section 7, all revenue modelling in section 8, and the pricing table in section 5 must be recalculated and reissued. The Codex review must also be re-run against the new price, since its arithmetic verification was conducted against £39.99.

*This decision requires an explicit written ratification.* £34.99 must not appear on any pricing-facing surface unless this decision is recorded. It is a retired figure until the Founder formally reinstates it.

---

## 17. Recommended Rollout and Migration Path

This section describes the sequence of implementation steps in priority order. Steps are grouped into three phases. No phase begins until the Founder decisions in section 16 that gate it are resolved.

### Phase 0 — Founder decisions (before any build begins)

The following decisions from section 16 must be resolved before engineering work proceeds. They have no dependency between them and can be made simultaneously.

Decision 1 (Guardian+ standalone price) gates the Guardian+ billing surface build.
Decision 2 (yearly price confirmation) gates the annual SKU registration.
Decision 3 (multi-role account architecture) gates any subscription launch.
Decision 4 (Basic/premium Guardian feature split) gates any Guardian-facing upgrade prompt.
Decision 5 (weekly billing surfaces scope) determines whether weekly billing is in Phase 1 or Phase 2.
Decision 7 (£34.99 reinstatement) must be resolved before any external pricing communication.

Decision 6 (Family plan design) can begin in Phase 0 in parallel with all of the above, as it requires Founder input but does not block Phase 1.

### Phase 1 — Core billing infrastructure (target: before first subscriber)

**Entitlement service extension.** Extend `wali_has_wali_one()` to handle weekly subscription type identifiers if Decision 5 confirms weekly billing is in scope for launch. Test the entitlement resolution logic against all subscription states: active monthly, active annual, active weekly (if in scope), grace period, lapsed, and cancelled. Confirm that lapsed state reduces capability to Basic without affecting any relationship, history, or configuration data (Continuity V1).

**RevenueCat integration.** Replace mock purchase flows (`mockSetWaliPlan`, `mockPurchaseWaliPremium`) with a RevenueCat integration handling App Store and Play Store receipt validation, entitlement state, grace-period logic, and webhook-driven subscription event processing. RevenueCat is the recommended abstraction layer rather than direct store SDK integration, for cross-platform consistency and billing failure handling.

**Store SKU registration.** Register App Store Connect and Google Play Console products for all in-scope SKUs: ZYRA One monthly (£39.99), ZYRA One annual (£399.90, pending Decision 2), Guardian+ standalone monthly (£24.99 or revised price per Decision 1), and weekly variants if in scope per Decision 5. Pricing tier selection must account for both stores' available pricing tiers; confirm that target prices map to available tiers before committing to them in the pricing document.

**Multi-role account architecture implementation.** Implement the resolution determined by Decision 3. This must be complete before any subscription is offered to a user whose account could be both a Seeker and a Guardian.

**Upgrade screen audit.** Confirm that the upgrade screen shows only SKUs with live billing surfaces. If weekly SKUs are scoped to Phase 2, the weekly toggle must not appear in Phase 1. The upgrade screen must not display £34.99 unless Decision 7 reinstates it.

**Guardian Basic feature audit.** Conduct the audit specified in Decision 4. Confirm that no Guardian Network authority function is gated. Any function that fails the audit must be moved to Basic before the upgrade screen is live.

### Phase 2 — Post-launch, within 90 days

**Weekly billing surfaces** (if scoped to Phase 2 per Decision 5). Register weekly SKUs, extend upgrade screen to include the weekly toggle, confirm entitlement service handles weekly identifiers. Close OA-ZYRA-253(c).

**Annual ZYRA One** (if Decision 2 confirmation arrives after Phase 1 launch, which this review does not anticipate but records as a possibility). Register annual SKU, add annual toggle to upgrade screen, confirm the 17% saving label is accurate.

**Metrics instrumentation.** Ensure the following are being measured as primary metrics from day one: Guardian activation rate (percentage of invited Guardians who create an account and accept the invitation), Guardian engagement depth (percentage who reach a meaningful Guardian Network participation milestone), Guardian conversion rate to paid tier, and Guardian churn on paid tiers. These are the four numbers that determine whether the commercial architecture is performing as modelled.

**Guardian+ standalone price validation.** At 60 days post-launch, review Guardian+ standalone conversion rates against the Guardian activation base. If conversion rates are materially below the thresholds implied by the household revenue models in section 8, bring the price decision back to the Founder with real data. This is not a scheduled price change — it is a scheduled data review.

### Phase 3 — Family plan (90+ days post individual-subscription launch)

**Trigger conditions.** Phase 3 does not begin until: real App Store and Play Store billing is live and stable (Phase 1 complete); at least 90 days of conversion rate, churn, and Guardian adoption data are available; multi-role account architecture is resolved and live (Phase 1 complete); and Guardian+ standalone price rationale is documented and confirmed (Decision 1 complete and validated by Phase 2 data review).

**Design.** Family plan entitlement model, organiser role definition, abuse prevention mechanisms, and store billing approach are designed in Phase 0 in parallel with Phase 1 work. The design output is a Family plan specification ready for engineering when Phase 3 is triggered.

**Build sequence.** Server-side family group management (creation, membership, seat addition, removal, lapse handling). Entitlement distribution to member accounts. Organiser billing surface (the organiser is the only account with a direct store subscription; member accounts receive entitlements from the server-side broker). Member onboarding flow (invitation link, relationship declaration, joining confirmation). Continuity on removal (confirm that a removed member reverts to Basic without data loss). Launch with a defined membership cap of 5, with per-seat pricing for additional members as specified in section 4.

### Migration note — no existing subscribers to migrate

This review is written before any real subscriber exists. There is no legacy subscriber population to migrate, no entitlement data to reconcile, and no billing history to handle. The migration path described above is therefore a rollout path, not a migration. When real subscribers exist and a future architecture change is contemplated — for instance, a move to a personal model or a Family plan restructure — a migration plan will be required at that point. The Subscription Continuity Principle governs what must be preserved (all relationships, history, and configuration); the implementation of that preservation in a migration is a future engineering decision.

---

## 18. Where Fable and Codex Did Not Agree

### The Codex verdict

Codex's verification verdict is SIGN OFF WITH CONDITIONS. The recommendation as written in sections 1–11 is conditionally endorsed, not unconditionally endorsed. The conditions are binding. This review does not contest them. Each is addressed in turn.

**Condition 1 — Complete the development of weekly billing surfaces and ensure compliance with app store requirements.**

This review accepts this condition without reservation. It is architecturally correct and consistent with the open action OA-ZYRA-253(c). Section 12 specifies what building weekly billing surfaces requires: SKU registration on both stores, an upgrade screen weekly toggle, an extension of `wali_has_wali_one()` to handle weekly subscription type identifiers, and compliance with each store's auto-renewable subscription policies. Section 17 places weekly billing in Phase 1 if Decision 5 confirms it is in scope at launch, or Phase 2 if scoped post-launch. The condition is not in tension with the recommendation; it requires completion of work the recommendation already identifies as incomplete.

**Condition 2 — Document and finalise the rationale for the £24.99 Guardian+ pricing.**

This review accepts this condition. The £24.99 Guardian+ standalone price is the most commercially sensitive figure in the architecture. Both Fable and Codex flagged this concern independently and via different analytical routes — that convergence is itself a signal. The condition is recorded as Decision 1 in section 16, and section 17 places it in Phase 0, meaning no billing surfaces are built until the rationale is recorded. The original recommendation did not defend £24.99; it identified the absence of a documented rationale as a problem. Codex's condition formalises that identification as a requirement. The recommendation is unchanged; the condition confirms the urgency.

**Condition 3 — Provide a more detailed plan for resolving multi-role account architecture ambiguities before launch.**

This review accepts this condition. Sections 1–11 flag multi-role accounts as unresolved but do not specify a path to resolution. Sections 16 and 17 of this document address that gap. Decision 3 in section 16 names the question, states the recommended resolution (one ZYRA One subscription covers both Seeker and Guardian contexts for the same account holder), and identifies what the product team must specify before any subscription is offered to users. Section 17 places multi-role architecture resolution in Phase 1. The Codex condition is satisfied by that specificity; sections 1–11 alone did not satisfy it, and Codex was correct to say so.

---

### Disagreements Codex raised that this review contested

**Codex's claim that "ZYRA's differentiation is the Guardian model" overstates the case.**

Codex argued that this framing oversimplifies the product and that the matchmaking experience is equally central to ZYRA's differentiation. This review maintains its position: the Guardian Network structure, as designed, is the primary differentiator from competing Muslim matrimonial platforms, most of which have some form of compatibility matching. Matching algorithms are necessary but not distinctive in this market. The formal Wali integration — with real Guardian Network authority, relationship-linked entitlements, and structured family oversight — is what makes ZYRA architecturally different. That said, Codex's point is acknowledged in this sense: a poor Seeker experience would be disqualifying regardless of how well the Guardian layer is built. The Guardian model differentiates; the Seeker experience must be good enough not to undermine the differentiation. Both things are true. The disagreement is one of emphasis, not of product strategy.

**Codex's challenge on the £9.99 predecessor price for Guardian+.**

Codex argued that characterising the Guardian+ standalone price as an increase from £9.99 to £24.99 was unsupported, because £9.99 appears in the pricing document as a "never quote" figure rather than as a prior active price. This is a fair technical reading of how the document presents the figure. The position of this review is that E3 records the before/after table explicitly — £9.99 was the prior price, £24.99 is the current price, and the repricing occurred on 2026-08-23. E2 records £9.99 as retired and not to be quoted going forward. These two facts are consistent: £9.99 was the predecessor price, it is now retired, and it should not be quoted to users or in external communications. The claim in this review is about the historical magnitude of the change, not a recommendation to quote the old figure. Where the original drafting was ambiguous on that point, this section corrects it. The historical increase of 150% is accurate. The figure must not be quoted externally.

**Codex's conversion rate challenge.**

Codex correctly identified that the conversion rate figures used in section 8 — 10%, 25%, and 50% Guardian conversion — are speculative and lack empirical basis. This review acknowledged this explicitly in section 8, labelling all revenue figures as illustrative modelling only. The challenge is valid as a methodological caution. It does not alter the qualitative finding: the personal model outperforms the current model commercially only above a Guardian conversion threshold that is presently unknown, and the current model outperforms the personal model when Guardian conversion is low. That qualitative finding holds regardless of where exactly the threshold sits numerically. The precise figures in the table are there to make the logic legible, not to represent forecasts. Codex is right that they should not be treated as forecasts.

---

### What Codex said was missed by both reviewers

Codex identified two gaps that neither Fable's analysis nor the earlier Codex challenge addressed with sufficient depth.

**Multi-role account architecture.** Codex noted that neither review elaborated extensively on the ramifications for multi-role accounts. This is accurate. Sections 1–11 flag the issue and Household 6 in section 7 illustrates it, but the path to resolution is not specified until sections 16 and 17. The earlier Codex challenge raised multi-role accounts as a complexity but did not itself resolve the question. This is an honest gap in both analyses.

**Guardian willingness to pay.** Codex noted that neither review presents market data or user feedback indicating at what price, if any, Guardians in this cohort would purchase standalone premium access. This gap is real and cannot be papered over. The honest position is that no such data exists from the preview build, and that this review's conversion rate assumptions are therefore entirely without empirical foundation. The Codex condition requiring documented rationale for £24.99 is in part a response to this absence.

---

### Where Codex was itself wrong

**The arithmetic verification.** Codex confirmed the household arithmetic as accurate. It is accurate for the scenarios verified. However, Codex did not independently identify that the dual-role household scenario (Household 6 in section 7) carries an embedded architectural ambiguity in the entitlement resolution logic — the correct figure for that household depends on whether one ZYRA One subscription covers both contexts, which is precisely the question that is unresolved. Codex's arithmetic sign-off is accurate as far as it goes but does not cover the architecturally ambiguous household. The verification should carry that caveat.

---

### Disagreements that remain unresolved after the verdict

**The right price for Guardian+ standalone.** Codex flagged £24.99 as unvalidated and required documentation of the rationale. Fable flagged it as potentially set above the adoption-critical threshold and proposed £14.99–£19.99 as a range more appropriate if the goal is Guardian adoption rather than revenue maximisation on a small cohort. Codex did not specify an alternative price. This disagreement cannot be resolved by either reviewer. It requires the Founder to record a rationale and, once real billing is live, real conversion data to validate or refute it. It remains open at the close of this review.

**The personal model's long-term merits.** Codex's verdict endorsed the bundled model conditionally but did not take a position on whether the personal model should eventually be adopted once Guardian conversion data exists. Fable's position is that the personal model's structural advantages — entitlement ownership clarity, dual-role simplicity, stability for Guardians with multiple Seekers — are real and may justify adoption at a future point, provided Guardian conversion rates support the commercial case. Codex neither confirmed nor contested this. The question is deferred, as it should be, to a point when real data exists.

---

— END OF REVIEW — Sections 1–18 complete —