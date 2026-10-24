# ZYRA Subscription Architecture Review — Brief

**Run:** SUBSCRIPTION_REVIEW_2026-08-26 · armed for 01:00 BST (00:00 UTC), 26 August 2026
**Requested by:** Founder (Shakeel), 2026-08-25
**Reviewers:** Fable (Claude) + Codex (GPT), alternating, adversarial
**Mode:** analysis and discussion only. **No code is changed by this run.**

---

# PART A — VERIFIED CURRENT STATE

*Compiled by Fable from the repository on 2026-08-25, before the run. The Founder's brief (Part B) was written from memory and three of its premises are out of date. **Part A is the baseline. Where Part B and Part A disagree, Part A is the fact and Part B is the intent.***

The Founder was shown this discrepancy and ruled on 2026-08-25: **everything in Part A is in scope**, including Guardian+ standalone and the weekly plans.

## A1 · Ratified prices — ZYRA_PRICING_CURRENT_VERSION_V2, set by the Founder 2026-08-23

| Product | Weekly | Monthly | Yearly |
|---|---:|---:|---:|
| ZYRA Basic | Free | Free | Free |
| ZYRA One | **£19.99** | **£39.99** | £399.90 *(10-for-12; derived, awaiting explicit confirmation)* |
| Guardian+ (standalone) | **£14.99** | **£24.99** | — |
| Compatibility Unlock | — | £1.99 single · 5 for £7.99 | — |
| Compatibility Unlock Plus | — | £2.99 single · 5 for £9.99 | — |

Full before → after of the 2026-08-23 repricing (OA-ZYRA-253):

| | Before | After |
|---|---:|---:|
| One monthly | 34.99 | **39.99** |
| One yearly | 349.90 | **399.90** |
| One weekly | — | **19.99** |
| Guardian+ monthly | 9.99 | **24.99** |
| Guardian+ weekly | — | **14.99** |

> **£34.99 is currently a RETIRED FIGURE.** The pricing document lists One at £34.99 and Guardian+ at £9.99 under "never quote". The Founder's proposal in Part B returns One to £34.99 — the price the product carried until two days ago. That is a reversal, not a reduction from a long-standing price, and the review should treat it as such.

## A2 · Three things Part B does not mention, and each changes its argument

**1 · Guardian+ standalone already exists at £24.99/month (£14.99/week).**
Part B's central worry is a father needing "another £34.99" to get premium Guardian tools. In the shipped product he does not buy ZYRA One — he buys **Guardian+ at £24.99**. The premium-Guardian household maths in Part B is therefore wrong as stated, and the real question is not "should Guardian premium be personal" (it already can be) but **what Guardian+ should cost and whether it should survive as a separate SKU at all.**

**2 · The bundle is already bounded to ONE Guardian — the D14 entitlement mirror.**
Ratified 2026-08-23 (OA-ZYRA-247): a Seeker's ZYRA One includes Guardian+ **for their Main Wali only**. Additional Guardians each need their own. Part B describes the current model as "ZYRA One effectively bundles premium Guardian capability with the Seeker subscription" — true, but far narrower than Part B assumes. Several of Part B's stated problems ("which Seeker funds the Guardian?", "what if one Guardian represents several Seekers?") are **already answered** by D14.

**3 · Payment is already separated from authority.**
Also ratified 2026-08-23: **"Payment buys ACCESS, never authority."** Send, accept, withdraw and proceed in Guardian Network are Main-Wali-only acts regardless of who paid (GN contract Rules 37/38). Part B's fairness concern about premium status conferring control is, in the current architecture, already handled. The review must not re-solve it, and must not break it.

**4 · Weekly plans are approved but unbuilt.**
£19.99/week One and £14.99/week Guardian+ are ratified pricing. The in-app purchase surface does not exist (OA-ZYRA-253 remainder (c)). Any recommended architecture has to say what happens to them.

## A3 · Governing constraints the review may not override

| Constraint | Source |
|---|---|
| ZYRA_PRICING_CURRENT_VERSION_V2 is the source of truth for every price. Code disagreeing with it is a defect in the code, not a difference of opinion. | Pricing V2 |
| Payment buys ACCESS, never authority. | OA-ZYRA-247 / GN Rules 37/38 |
| No subscription event may delete relationships or history. | Subscription Continuity Principle V1 |
| Safety functions are never paywalled. | Founder, Part B |
| Yearly follows the ratified 10-months-paid / 12-received model. | Pricing V2 |
| £399.90 yearly is DERIVED and awaits explicit Founder confirmation. | OA-ZYRA-253 remainder (a) |

## A4 · Open items this review must not contradict

- **OA-ZYRA-253 (a)** Founder confirms £399.90 yearly.
- **OA-ZYRA-253 (b)** Founder decides launch-promo applicability to weekly plans.
- **OA-ZYRA-253 (c)** Weekly billing surfaces are unbuilt.
- **OA-ZYRA-247** D14 entitlement mirror — Main-Wali-only bundle.

## A5 · Context supplied to both reviewers at runtime

- `BUSINESS/ZYRA PRICING/ZYRA_PRICING_CURRENT_VERSION_V2.md`
- `APP/Standards/SUBSCRIPTION_CONTINUITY_PRINCIPLE_CURRENT_VERSION_V1.md`
- `SOURCE/lib/services/zyra_entitlement_service.dart`
- `SOURCE/lib/screens/subscription/upgrade_screen.dart`
- OA-ZYRA-253 and OA-ZYRA-247 register entries

---

# PART B — THE FOUNDER'S BRIEF, VERBATIM

*Reproduced exactly as written. Read Part A first.*

I want you to use the API review workflow for this pricing/subscription decision and have Claude + Codex review it together before we change anything in production.

This is a product, commercial, technical and architecture decision — not simply a pricing edit.

I want both models to keep an open mind. Do not defend the current subscription structure simply because it already exists.

The objective is:

**What subscription architecture is best for ZYRA as a business, best for users, simplest to understand, technically clean, scalable for families, and strong enough commercially to build a sustainable company?**

## MODELS TO REVIEW

### CURRENT / OLD DIRECTION

ZYRA One currently effectively bundles premium Guardian capability with the Seeker subscription. Example: Seeker purchases ZYRA One. Their linked Guardian may receive premium Guardian functionality through that Seeker's entitlement. This lowers the family's cost and makes Guardian adoption easier.

But it creates questions around: Who owns the Guardian entitlement? What happens if the Seeker cancels? What if one Guardian represents several Seekers? Which Seeker funds the Guardian? Dual-role users. Subscription continuity. Entitlement transfer. Family plans.

Review the current implementation/documentation accurately before criticising it.

### NEW MODEL TO CHALLENGE

**ZYRA Basic — Free.** Every human has one identity/account. That identity may have Seeker context and Guardian context. Essential participation remains free. A Guardian should NEVER be required to pay merely to fulfil the basic Guardian role.

**ZYRA One — £34.99/month.** Price reduced from £39.99. The entitlement belongs to the PERSON. It is **non-transferable**. If I buy ZYRA One: my own Seeker context receives ZYRA One features; my own Guardian context receives ZYRA One Guardian features. I cannot give my ZYRA One entitlement to my father, daughter, sibling or another account. Each identity owns their own subscription.

Example — Daughter: ZYRA One = £34.99. Father: Basic = £0, and he can still fulfil the essential Guardian role. If Father wants premium Guardian tools, Father purchases his own ZYRA One = £34.99. Combined premium household spend: **£69.98/month**.

### WHY THIS MAY BE BETTER

One person = one subscription. Much simpler entitlement ownership. No transferable premium Guardian entitlement. Cleaner dual-role architecture. Cleaner multiple-Seeker Guardian architecture. A Guardian can represent several Seekers without asking which Seeker funds them. Seeker cancellation does not remove the Guardian's personal premium subscription. Cleaner subscription continuity. £34.99 is psychologically more competitive than £39.99. Increased revenue when multiple family members independently choose premium. Creates a clearer reason for ZYRA Family to exist.

But do NOT assume these advantages outweigh the disadvantages.

### MAJOR RISK TO REVIEW

Guardian adoption. Daughter pays £34.99. Father can participate as Guardian for free. But if the best Guardian features sit behind ZYRA One, he may need another £34.99. Does this make families think "Why do both of us need to pay?" Could this damage the Guardian-led differentiation that makes ZYRA special? Could we accidentally monetise the very safety/family structure we need users to adopt? This must be assessed seriously.

### ESSENTIAL GUARDIAN PRINCIPLE

My current thinking: **Guardian Basic must remain genuinely useful.** Never: "Pay £34.99 or you cannot properly act as your daughter's Guardian."

**Basic Guardian** receives everything required to perform the legitimate core Guardian role. **ZYRA One Guardian** receives advanced/premium capabilities — possibly Guardian Network, Advanced Guardian Dashboard, Multi-Seeker intelligence, Deeper family insights, Advanced recommendation tools, ZYRA learning/intelligence, Additional premium workflow tools.

But review which features genuinely belong in premium. Do not put safety, essential oversight or required Guardian participation behind a paywall merely to create value.

### ZYRA FAMILY

We also need to properly define **ZYRA Family — approximately £99/month.** Do NOT assume £99 or 5 members is automatically correct merely because I suggested them. Review the maths.

Under £34.99 ZYRA One: 1 = £34.99 · 2 = £69.98 · 3 = £104.97 · 4 = £139.96 · 5 = £174.95. Therefore ZYRA Family at £99 becomes cheaper than individual ZYRA One once roughly 3 people want premium. That may be very compelling. But we need to decide WHAT £99 actually includes.

- **Family Model A** — Up to 5 verified family members. Maximum 3 premium Seeker entitlements. Remaining members may be Guardians.
- **Family Model B** — 5 full ZYRA One identities. At £99 this represents a very large discount versus £174.95.
- **Family Model C** — Family membership + shared premium Guardian infrastructure, but individual Seeker premium limits.
- **Family Model D** — Base family subscription includes a number of members, with paid additional premium Seeker seats.
- **Family Model E** — Another model you believe is commercially/technically superior.

Please propose alternatives rather than limiting the analysis to my examples.

### IMPORTANT FAMILY QUESTIONS

What counts as a family member? How is family membership verified? Who is the Family organiser? Does organiser control billing only, or permissions too? Can organiser remove someone? What happens to someone's account if removed? Can family seats be transferred? Can strangers abuse Family by forming cheap subscription groups? Can one father include several children? Mother + father + daughters + sons? Extended family? Cousins? Nieces/nephews? One Guardian representing several Seekers? A person who is both Seeker and Guardian? How many active Seekers? How many Guardians? Does every Family member receive full ZYRA One? Does Family include features unavailable in individual ZYRA One? What happens if Family subscription lapses? What happens to ongoing Journeys? What happens to Guardian relationships? What happens to historical data? Upgrade/downgrade paths?

No subscription event should delete relationships/history.

### COMMERCIAL REVIEW

Compare the old bundled model vs £34.99 personal/non-transferable ZYRA One vs Family variants. Analyse: Revenue per user. Revenue per household. Guardian adoption. Seeker conversion. Family conversion. Cannibalisation. Customer acquisition. Churn risk. Pricing psychology. Perceived fairness. Simplicity. Upgrade pressure. Lifetime value. Family-plan abuse. Potential market positioning. Competitor comparability. Whether £34.99 is actually the right price. Whether £99 is actually the right Family price.

Use worked examples: 1 Seeker + 1 Guardian · 2 Seekers + parents · 3 adult siblings + parents · 1 Guardian representing multiple Seekers · Dual-role user · 5-person premium household. Show actual monthly and annual maths.

### PRODUCT REVIEW

Which system is easiest for a normal family to understand? I want to avoid users needing to understand "Guardian entitlement funded by Seeker A but inherited through Relationship B unless Seeker C also subscribes..." The subscription architecture should be explainable in a sentence. But simplicity alone is not enough if it damages adoption.

### TECHNICAL REVIEW — CODEX

Codex should inspect the current ZYRA implementation. Determine: Current entitlement architecture. Subscription tables. Current Guardian+ inheritance. ZYRA One resolution logic. RevenueCat/App Store/Play assumptions. Journey capability grants. Guardian relationships. Account/context architecture. Subscription continuity rules. Existing plan-aware limits. Developer toggles. Current documentation.

Compare technical complexity between models. Identify: What would need changing. What becomes simpler. What becomes harder. Migration risks. Existing users/data implications. Server enforcement. Client enforcement. Testing requirements.

**Do NOT implement the new model during this review.**

### APP STORE / GOOGLE PLAY REVIEW

Review whether each subscription design works cleanly with: Apple subscriptions. Google Play subscriptions. Family billing models. Multiple identities. Subscription ownership. Account switching. Restore purchases. User changes devices. Refunds. Cancellation. Grace periods.

Do not design something commercially attractive but incompatible with store billing realities.

### FAIRNESS / SAFETY REVIEW

Essential Guardian capability remaining free. Safety functions never being paywalled. Whether ZYRA One accidentally creates pressure between family members. Whether Family organiser receives inappropriate visibility/control. Whether premium status leaks between users. Whether subscription status affects Journey continuity.

Subscription should determine capabilities. It should NOT determine ownership of relationships/history.

### ZYRA ONE DIFFERENTIATION

We need a stronger answer to: **Why would someone pay £34.99?** Review all current Basic vs ZYRA One functionality. Separate CORE / MUST REMAIN FREE from PREMIUM / GENUINELY VALUABLE. Look at both Seeker premium value and Guardian premium value.

Do not manufacture artificial limitations just to make ZYRA One look better. Premium should provide meaningful Intelligence, Convenience, Depth, Control, Advanced tools — rather than withholding essential usability.

### ZYRA FAMILY DIFFERENTIATION

Why would a household pay £99 instead of buying individual ZYRA One subscriptions? Possible value beyond price: One bill. Family management. Multi-Seeker Guardian Dashboard. Family-wide premium Guardian tools. Family To-Do. Journey oversight across multiple Seekers. Family introductions. Family-level organisation. Priority support. Future family calendar. Review which are genuinely valuable and appropriate.

### PRICING ARCHITECTURE

Challenge all three numbers: FREE · £34.99 · £99. Could the better model be £29.99? £34.99? £39.99? £89? £99? £109? £119? Do not change prices because something "feels nicer". Show the financial implications.

### FINAL OUTPUT

Claude + Codex should discuss this through the API review workflow. I want genuine challenge rather than agreement.

Each should identify: Best arguments FOR the old model. Best arguments AGAINST the old model. Best arguments FOR the personal £34.99 model. Best arguments AGAINST it. Best Family architecture. Biggest commercial risk. Biggest product risk. Biggest technical risk. Biggest opportunity.

Then agree, if possible, on ONE recommended architecture.

Final deliverable: **# ZYRA Subscription Architecture Final Review**, including:

1. Executive recommendation. 2. Recommended Basic model. 3. Recommended ZYRA One model. 4. Recommended Family model. 5. Exact pricing recommendation. 6. Exact entitlements. 7. Worked household examples. 8. Revenue implications. 9. Guardian-adoption implications. 10. Family-abuse prevention. 11. Technical migration impact. 12. App Store/Play implications. 13. Risks. 14. What stays free permanently. 15. What becomes premium. 16. What requires Founder decision. 17. Recommended rollout/migration path.

Keep an open mind. If the existing model is better, say so. If £34.99 is wrong, say so. If £99 Family is wrong, say so. If ZYRA Family should not exist yet, say so. If there is a better subscription architecture neither the Founder nor ChatGPT has proposed, propose it.

The objective is not to validate my idea. The objective is: **Find the strongest long-term commercial model for ZYRA without damaging the Guardian-led product that makes ZYRA different.**

Do not implement until the review is complete and Founder ratification follows.

---

# PART C — RUN RULES

1. **No code is written or changed.** This run produces documents only. Any implementation waits for Founder ratification.
2. **Part A is the baseline.** A reviewer that argues from Part B's out-of-date premises without acknowledging Part A has failed the task.
3. **Genuine challenge is the point.** Agreement reached without a real attempt to break the other's position is worthless here. Each side states its strongest opposing case before converging.
4. **Numbers must be shown.** Every commercial claim carries its arithmetic. "More revenue" without a worked example is not an argument.
5. **Say when you don't know.** Market comparables, conversion rates and churn for a Muslim matrimonial app are not things either reviewer can measure from this repository. Label estimates as estimates and name what would need real data.
6. **Nothing here overrides §A3.**
7. **Every artifact is written to disk as it is produced,** so a run that fails partway still leaves usable work.
