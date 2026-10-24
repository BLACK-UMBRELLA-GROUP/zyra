# Fable — opening position

*Fable · claude-sonnet-4-6 · 2026-08-26T00:02:12.920104+00:00*

# ZYRA Subscription Architecture Review — Fable Opening Position

**Run:** SUBSCRIPTION_REVIEW_2026-08-26
**Reviewer:** Fable (Claude), acting as product and commercial reviewer
**Status:** Opening position — adversarial review, no code changed

---

## Preliminary: Three Corrections to Part B Before the Argument Begins

Part B was written from memory and three of its premises are out of date. The review cannot proceed honestly without naming them first.

**Correction 1: £34.99 is a retired figure, not a reduction.** The Founder's proposal describes "reducing" ZYRA One from £39.99 to £34.99. In the current pricing document, £34.99 is listed under "never quote" — it is what the product cost until two days ago. The proposed model is a reversal of a deliberate repricing decision, not a discount from a stable price. Every commercial argument in Part B that rests on "£34.99 is psychologically more competitive" must be read with that context.

**Correction 2: Guardian+ standalone already exists.** Part B's central scenario — "Father needs another £34.99 to get premium Guardian tools" — does not describe the current architecture. The current product has Guardian+ standalone at £24.99/month or £14.99/week. The real question is not whether Guardian premium should be separable from the Seeker subscription; it already is. The real question is what Guardian+ should cost, whether it should survive as a standalone SKU, and how it sits relative to whatever replaces it.

**Correction 3: The bundle is already bounded to one Guardian.** Part B worries about "which Seeker funds the Guardian" and "what if one Guardian represents several Seekers." These are answered by D14 (OA-ZYRA-247), ratified 2026-08-23. The Seeker's ZYRA One includes Guardian+ for their Main Wali only. Additional Guardians each purchase their own. D14 did not merely solve these problems in principle — it is ratified and in the register.

With those corrections on record, the review proceeds.

---

## 1. What the Current Architecture Actually Is

The live, ratified architecture as of 2026-08-23 consists of the following components.

**Entitlement structure.** There are two subscription products. ZYRA One (£39.99/month, £19.99/week, £399.90/year awaiting explicit Founder confirmation) is purchasable by any account holder regardless of role. When held by a Seeker, it includes one bundled Guardian+ entitlement for that Seeker's Main Wali — and for that Guardian only. Guardian+ standalone (£24.99/month, £14.99/week) is purchasable independently by any Guardian, giving identical capabilities to the bundled entitlement. The upgrade screen confirms the feature list: "One Guardian+ entitlement included" under ZYRA One. The capabilities in both paths are identical (AD-081); the source of the entitlement does not change what the Guardian can do.

**The D14 Main-Wali-only boundary.** A Seeker's ZYRA One includes Guardian+ for their Main Wali only. If a Seeker has multiple Guardians in their Guardian Network, additional Guardians beyond the Main Wali must purchase Guardian+ independently. This directly answers "which Seeker funds the Guardian" (the Seeker funds their own Main Wali, nobody else), "what if one Guardian represents several Seekers" (each Seeker-Main-Wali pair is independent; the Guardian's entitlement on behalf of Seeker A is separate from their entitlement for Seeker B), and "what happens if the Seeker cancels" (the Seeker's bundled entitlement revokes, but the Guardian relationship and all history persist under the Subscription Continuity Principle; the Guardian can then purchase standalone Guardian+ and continue without relinking).

**Payment buys access, never authority.** This is ratified in OA-ZYRA-247 and enforced in Guardian Network Rules 37 and 38. The right to send, accept, withdraw or proceed in Guardian Network is a Main-Wali function regardless of who paid. A Guardian who receives bundled Guardian+ via a Seeker's ZYRA One does not receive elevated authority — they receive enhanced capability. A Seeker cannot purchase authority for someone. Authority is structurally separate from the subscription layer.

**Weekly plans.** £19.99/week for ZYRA One and £14.99/week for Guardian+ standalone are ratified pricing but unbuilt. The upgrade screen has a monthly/annual toggle; no weekly billing surface exists in the app. This is registered under OA-ZYRA-253 (c) and is a genuine outstanding item that any recommended architecture must address.

**Subscription Continuity Principle (V1).** No subscription event — expiry, cancellation, payer change, upgrade, downgrade, or temporary lapse — deletes relationships, journey history, or configuration. The entitlement changes; the underlying data does not. The principle is explicit that it applies identically across Seeker and Guardian experiences.

**What the entitlement service actually does.** The `ZyraEntitlementService.hasWaliOne()` function resolves Guardian+ entitlement by calling `wali_has_wali_one()`, which returns true either if the Guardian holds their own `wali_premium` subscription or if they are the linked Main Wali of a Seeker with an active ZYRA One. This is the correct implementation of D14: one function, two sources, identical result. The developer `mockSetWaliPlan()` note in the code explicitly flags that if an account is also the Main Wali of a Seeker with ZYRA One, it will resolve as Guardian+ regardless of the mock setting — and comments that this is correct, not a bug.

**What is not yet built.** Weekly billing surfaces. Real App Store/Play Store in-app purchase flows. Stripe integration. The upgrade screen currently mocks entitlement by flipping AppState locally. No real payment flows exist in this preview build.

---

## 2. Which of the Founder's Stated Problems Are Real and Which Are Already Solved

I will go through Part B's list of concerns precisely.

**"Who owns the Guardian entitlement?"** — Solved by D14. The entitlement belongs to the Main Wali slot in the Seeker's relationship structure. If the Guardian purchased standalone Guardian+, it belongs to that Guardian's own subscription. Ownership is unambiguous in both cases.

**"What happens if the Seeker cancels?"** — Solved by the combination of D14 and the Subscription Continuity Principle. The bundled entitlement revokes; the Guardian relationship and all history persist. The Guardian can then purchase standalone Guardian+ and continue. The worked example in Subscription Continuity Principle V1 covers exactly this scenario. This problem is not merely theoretically solved — the document specifying it was ratified before this review.

**"What if one Guardian represents several Seekers?"** — Solved by D14. Each Seeker-Main-Wali entitlement is independent. A Guardian who is the Main Wali of Seeker A and also the Main Wali of Seeker B has two independent entitlement sources. If one Seeker cancels, it affects only the entitlement from that Seeker's ZYRA One. The Guardian's relationship to the other Seeker is unaffected. The Guardian could also hold standalone Guardian+ covering all their Guardian roles simultaneously with a single subscription.

**"Which Seeker funds the Guardian?"** — Solved by D14. Each Seeker funds only their own Main Wali. Nobody else.

**"Dual-role users."** — This is a partially real problem. The current architecture does not clearly specify what happens when a person is simultaneously a Seeker with ZYRA One and a Guardian to another Seeker. The entitlement service resolves Guardian+ capability by role rather than by unified account, but the multi-role account architecture is explicitly parked (Subscription Continuity Principle V1 reference: "Multi-role or multi-account architecture — separate, unresolved discussion"). Part B's concern about dual-role users is legitimate and is not resolved by the current architecture. However, it is not specific to the bundled model — it would be an equally real problem under the personal non-transferable model if someone is both a Seeker and a Guardian.

**"Subscription continuity."** — Substantially solved by Subscription Continuity Principle V1. The worked example in that document is precisely the scenario Part B describes. The concern about entitlement transfer during a payer change is addressed by the principle's explicit provision for that transition.

**"Entitlement transfer."** — The principle covers payer change as a named transition. What is not yet fully specified is the exact timing and grace periods during revocation (the document defers this to when real payment processing begins — Task 20). That is a real gap, but it is a gap in the implementation specification for all models, not a defect specific to the bundled architecture.

**"Family plans."** — A genuine open problem. The current architecture has no family plan. This is real and unaddressed.

**The father scenario in Part B.** Part B's central narrative is: "Daughter pays £34.99 [now £39.99]. Father can participate as Guardian for free. But if the best Guardian features sit behind ZYRA One, he may need another £34.99." The factual correction: Father does not need ZYRA One. Father needs Guardian+ standalone at £24.99/month. The scenario as written is incorrect. The real question is whether £24.99/month for a Guardian is appropriate, fair, and adoption-compatible — which is a genuine commercial question, but it is a different question to the one Part B poses.

**Summary of real versus solved problems:**

| Problem | Status |
|---|---|
| Who owns the Guardian entitlement? | Solved — D14 |
| What happens if Seeker cancels? | Solved — D14 + Continuity V1 |
| Which Seeker funds the Guardian? | Solved — D14 |
| One Guardian, multiple Seekers | Solved — D14 (each pair independent) |
| Subscription continuity | Substantially solved — Continuity V1 (grace-period mechanics remain pending) |
| Dual-role users | Genuinely open — unresolved in all models |
| Family plans | Genuinely open — unaddressed in current architecture |
| Guardian adoption risk | Genuinely open — real commercial question |
| £24.99 Guardian+ pricing appropriateness | Genuinely open — requires commercial analysis |

---

## 3. My Position on the Personal Non-Transferable Model

The Founder's proposed model: ZYRA One at £34.99/month (a reversal of the 2026-08-23 repricing), non-transferable, owned by the identity rather than the relationship. No bundled Guardian entitlement. Guardian+ effectively becomes something a person purchases to use their own Guardian context, rather than something a Seeker purchases to activate a named Guardian.

### The Strongest Case For the Personal Model

**Architectural cleanliness is the real argument.** The bundled model creates an entitlement that exists on one account but is activated by another account's subscription. This is genuinely more complex to implement, to explain, and to reason about at scale. The personal model has one subscription owner, one beneficiary, one entitlement. That is a meaningful reduction in system complexity.

**Seeker-cancellation independence.** Under the personal model, a Guardian's premium capability cannot be disrupted by a Seeker's billing decision. That is a genuine improvement in stability and fairness. Under the current model, a Guardian who has been providing Guardian+ service to a Seeker may lose those capabilities through no action of their own.

**Multiple-Seeker Guardian clarity.** If a Guardian is Main Wali to several Seekers, a single personal ZYRA One subscription covers all their Guardian contexts simultaneously without needing to reason about which Seeker's entitlement is funding which capability. This is cleaner.

**Revenue ceiling expansion.** If every family member who wants premium buys individually, household revenue is additive rather than capped by the Seeker's single ZYRA One purchase. This is the Founder's family-revenue argument. It is real.

**Creates genuine family-plan motivation.** A product with individual subscriptions at £34.99 or £39.99 and no family option has an obvious ceiling. A product where families can see "three of us want premium, £99 is cheaper than three individual subscriptions" has a natural family-plan conversion story. The current bundled model partially obscures this because the Guardian premium appears to be covered.

### The Strongest Case Against the Personal Model

**The proposal uses a retired price.** £34.99 was the price of ZYRA One until 2026-08-23, two days before this review. The case for reverting to it needs to be stronger than "it sounds nicer." The Founder raised the price to £39.99 for a reason. That reason is not stated in Part B. If the case for the personal model requires £34.99, then the review needs to justify not just the structural change but also the price reversal against whatever reasoning drove the 2026-08-23 increase. This review cannot do that without knowing why the price was raised.

**Guardian+ standalone at £24.99 already exists.** The personal model's main structural advantage — that Guardians own their own premium status — is already partially available. A Guardian who does not want to depend on their Seeker's subscription can purchase Guardian+ standalone today. The question is whether the bundled model should be abolished in favour of an exclusively personal model, or whether both should coexist. The case for abolition requires demonstrating that the bundle causes real problems, and most of those problems are already solved by D14.

**The father scenario gets more expensive, not less.** Under the current model: Daughter pays £39.99/month, Father gets Guardian+ for free (as Main Wali bundle). Under the proposed personal model: Daughter pays £34.99 (proposed reversal), Father pays £34.99 for his own ZYRA One if he wants premium Guardian capability. Household spend increases from £39.99 to £69.98. The saving on Daughter's subscription is £5/month; the cost of Father's premium status is £34.99/month. Net household change: +£29.99/month if Father wants premium Guardian tools. This is not a fairness improvement for the household — it is a revenue improvement for ZYRA. That may be the right outcome commercially, but it should be stated plainly.

**Guardian adoption damage is the structural risk.** ZYRA's differentiation is the Guardian model. The Guardian is not an optional feature — the Guardian is what makes ZYRA different from every other matrimonial app. A model that asks Guardians to pay £34.99 for meaningful participation creates friction at the point of ZYRA's greatest differentiation. The question is not whether it's fair in the abstract; the question is whether it reduces Guardian activation rates enough to damage the core product value proposition. I assess this seriously in section 4 below.

**The "non-transferable" framing solves a problem that mostly doesn't exist.** Part B emphasises that under the personal model, "I cannot give my ZYRA One entitlement to my father." But the current architecture also does not allow transfer — a Seeker's ZYRA One includes Guardian+ for the named Main Wali, not a transferable token. The Founder is solving a transferability concern that the current D14 architecture already prevents.

---

## 4. The Guardian-Adoption Risk, Assessed Seriously

This is the most important section in this opening position.

### What the Risk Actually Is

ZYRA's Guardian model is the product. Not a feature — the product. A matrimonial app where a Wali is structurally integrated into the journey, where the Guardian receives their own dashboard, their own intelligence, their own view of the process, is a fundamentally different product to a standard matrimonial app with a tag-along family-notification layer. That differentiation requires Guardians to activate, engage, and find genuine value in the app.

Guardian activation requires:

1. The Guardian is invited by the Seeker.
2. The Guardian accepts and creates an account.
3. The Guardian engages with the interface enough to provide meaningful oversight.
4. The Guardian remains engaged over the duration of the journey.

At each of these steps, friction kills conversion. The question is: does asking a Guardian to pay £34.99/month for meaningful engagement add critical friction?

### What Guardian Basic Must Credibly Include

Part B proposes that Guardian Basic remains "genuinely useful" and that ZYRA One Guardian tools are "advanced/premium" rather than essential. The review must assess whether that distinction is credible to a real Guardian.

The premium Guardian features listed in Part B include: Guardian Network, Advanced Guardian Dashboard, Multi-Seeker intelligence, Deeper family insights, Advanced recommendation tools, ZYRA learning/intelligence, Additional premium workflow tools.

If Guardian Network — the mechanism by which a Guardian formally participates in the journey and exercises their legitimate role — is a premium feature, then Guardian Basic is not credibly useful for the Guardian role that ZYRA is built around. A Guardian who cannot access Guardian Network in any meaningful way is not a Guardian in the ZYRA sense — they are a contact who received an invitation notification.

The review cannot assess from this brief which specific features are behind which gate, because the precise Basic/One feature split is not fully documented here. But the principle is clear: if the Guardian role as designed requires Guardian Network participation, and if Guardian Network in any substantive form is behind a paywall, then "Guardian Basic is genuinely useful" is a claim that will not survive contact with a real user who tries to participate as their daughter's Guardian without paying.

### Does Guardian+ Standalone at £24.99 Already Answer the Adoption Risk?

Partially, but not fully.

**What it answers:** The concern about households where a Guardian wants premium capability is already addressed. Father can buy Guardian+ at £24.99/month rather than £34.99 for ZYRA One. That is a meaningful reduction from the proposed model's household maths. The option exists today in the ratified pricing.

**What it does not answer:** The adoption risk is not primarily about Guardians who want premium capability. The adoption risk is about Guardians who will not pay anything beyond their time. If Guardian Basic does not provide a meaningfully useful Guardian experience — if it provides a stripped-down, limited experience that communicates "you are a second-class participant in your daughter's marriage process" — then the issue is not the price of premium Guardian features. The issue is that the product has created a two-tier Guardian experience where the tier that's free feels inadequate.

**The key question the Founder must answer, and which this review cannot answer from the brief:** What is the specific feature set of Guardian Basic? If the answer is "everything required to exercise genuine Guardian oversight, review matches, communicate with the Guardian Network, and proceed through the journey alongside the Seeker" — then Guardian Basic is credibly useful, and premium is an enhancement. If the answer includes "Guardian Network participation" or "ability to formally approve or decline" as premium features, then Basic is not credibly useful, and the adoption risk is real regardless of the price of Guardian+.

**My estimate (flagged as estimate — real data would be cohort activation rates and engagement metrics by Guardian tier, which do not exist yet):** In the Muslim matrimonial context, the Wali/Guardian relationship is not optional. A father who is invited to be his daughter's Wali expects to be able to fulfil that role without being told it costs £24.99/month or £34.99/month. The more traditional the family, the more likely the Guardian is someone who does not consider themselves a product customer at all — they are participating in their child's marriage process, and the app is a tool, not a service they are subscribing to. Asking that Guardian to pay creates a category mismatch that will produce refusals that no pricing decision can fix.

### Whether £24.99 Guardian+ Is Too Expensive

This is a question the current review should flag even though it arises from Part A, not Part B. £24.99/month for a Guardian+ standalone is an increase from the previous £9.99/month — a 150% increase in less than two weeks. The commercial reasoning is not stated in the brief. If Guardian adoption is the core risk, and if standalone Guardian+ is the mechanism by which Guardians can participate independently, then the price of that SKU matters considerably. A Guardian who would pay £9.99/month might not pay £24.99/month. That is a pricing decision that was made before this review and is now ratified, but it is relevant to the commercial analysis of all models under consideration.

---

## 5. Worked Household Maths

**Notation:** All prices use Part A ratified prices as primary. The proposed model uses Part B's £34.99 (a retired figure — flagged wherever it appears). Annual figures use the 10-months-paid/12-received model: One £399.90/year (derived, awaiting confirmation); Guardian+ has no ratified annual price, so annual Guardian+ figures use 12 × monthly as a conservative estimate for the current model, and 10 × monthly for the proposed model if a family plan is assumed — I will use 12 × monthly for standalone Guardian+ in both models to avoid manufacturing a number that doesn't exist.

---

### Scenario A: 1 Seeker + 1 Guardian (Main Wali)

**Current model (ratified):**
- Seeker: ZYRA One £39.99/month. Includes Guardian+ for Main Wali.
- Guardian (Main Wali): £0 additional.
- Household monthly: **£39.99**
- Household annual: **£399.90**

**Proposed model (£34.99, non-transferable):**
- Seeker: ZYRA One £34.99/month.
- Guardian wants basic Guardian participation: £0.
- Guardian wants premium Guardian tools: £34.99/month (own ZYRA One).
- Household monthly (Seeker only premium): **£34.99**
- Household monthly (both premium): **£69.98**
- Household annual (Seeker only): **£349.90** *(derived, retired model)*
- Household annual (both premium): **£699.80** *(derived)*

**Revenue comparison (Seeker only premium):** Current £39.99 vs proposed £34.99. ZYRA earns **£5/month less** if Guardian does not pay. Revenue declines on the core 1+1 household.

**Revenue comparison (both premium):** Current £39.99 vs proposed £69.98. ZYRA earns **£29.99/month more** if Guardian also pays. This is the revenue upside — but it requires Guardian conversion to a paid tier.

**Current model with Guardian wanting independent premium:**
- Seeker: £39.99. Guardian: Guardian+ £24.99. Household monthly: **£64.98**.
- Still less than proposed both-premium £69.98, and Guardian has purpose-built SKU rather than over-purchasing ZYRA One.

---

### Scenario B: 2 Seekers + 2 Parents (Each Parent is a Guardian)

Assumption: Each Seeker has one parent as Main Wali. Both Seekers are siblings living in the same household.

**Current model:**
- Seeker 1: ZYRA One £39.99. Includes Guardian+ for Parent 1 (Main Wali).
- Seeker 2: ZYRA One £39.99. Includes Guardian+ for Parent 2 (Main Wali — may be the same parent or different).
- If Parent 1 is Main Wali for Seeker 1 only, and Parent 2 for Seeker 2 only:
- Household monthly: **£79.98** (two Seeker subscriptions; both Guardian+ covered by D14 bundle)
- Household annual: **£799.80**

- If both parents want Guardian+ for both children (e.g., Father is Main Wali for Seeker 1, Mother also wants Guardian+ access to Seeker 2's journey):
- Mother needs Guardian+ standalone: £24.99.
- Household monthly: **£104.97**

**Proposed model:**
- Seeker 1: £34.99. Seeker 2: £34.99.
- Parents basic only: Household monthly **£69.98**.
- Parents both want premium Guardian tools: +£34.99 × 2 = +£69.98.
- Household monthly (all premium): **£139.96**
- Household annual (Seekers only): **£699.80** *(derived)*
- Household annual (all premium): **£1,399.60** *(derived)*

**Revenue comparison (Seekers only pay):** Current £79.98 vs proposed £69.98. ZYRA earns **£10/month less.**

**Revenue comparison (all premium):** Current £104.97 (with one extra Guardian+ purchase) vs proposed £139.96. ZYRA earns **£35/month more** if both parents buy ZYRA One — but requires converting two parents who would currently get included Guardian+ for free into paying customers.

---

### Scenario C: 3 Adult Siblings + 2 Parents

Assumption: Three adult children are each seeking marriage (three active Seeker accounts). Parents are Guardians.

**Current model:**
- 3 Seekers × £39.99 =