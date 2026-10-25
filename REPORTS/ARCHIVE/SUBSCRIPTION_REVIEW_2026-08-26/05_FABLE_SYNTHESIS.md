# Fable — synthesis and single recommended architecture

*Fable · claude-sonnet-4-6 · 2026-08-26T00:07:48.448177+00:00*

# ZYRA Subscription Architecture Final Review

**Run:** SUBSCRIPTION_REVIEW_2026-08-26
**Produced by:** Fable (Claude), product and commercial reviewer
**Status:** Final convergence document. Analysis and recommendation only. No code changed. Awaits Founder ratification before any implementation.
**Governing baseline:** Part A / ZYRA_PRICING_CURRENT_VERSION_V2 outranks Part B wherever they disagree.

---

## Preliminary Bookkeeping

Before the recommendation, three corrections to Part B must remain on record in this final document because every subsequent argument depends on them.

**£34.99 is a retired figure, not a price reduction.** It was the price of ZYRA One until 2026-08-23 — two days before this review was commissioned. The pricing document lists it under "never quote." Every reference to £34.99 in Part B describes a reversal of a deliberate repricing decision, not a discount from a stable price. This review uses £39.99 as the current ratified ZYRA One monthly price throughout. Any recommendation to return to £34.99 requires an explicit Founder decision and is flagged as such wherever it appears.

**Guardian+ standalone already exists at £24.99/month.** Part B's central household scenario — father needing "another £34.99" for premium Guardian tools — is wrong as stated. The current product has a separate Guardian+ standalone SKU. The real question is not whether premium Guardian access should be separable from the Seeker subscription; it already is. The real question is whether the bundled model should be abolished, retained, or restructured, and what Guardian+ should cost.

**The bundle is already bounded to one Guardian.** D14 (OA-ZYRA-247, ratified 2026-08-23) limits the bundled Guardian+ entitlement to the Seeker's Main Wali only. Part B's concerns about "which Seeker funds the Guardian" and "one Guardian representing several Seekers" are substantially answered by D14.

---

## Part I — Arguments For and Against Each Model

### Best Arguments FOR the Current Bundled Model

**The Guardian adoption argument is structural, not cosmetic.** ZYRA's differentiation from every other Muslim matrimonial app is not the matching algorithm — it is the Guardian integration. Guardian Network participation, Wali authority, the formal family oversight structure: these are the product. A model that removes friction from Guardian activation is protecting the asset that makes ZYRA worth using at all. The bundled model removes one friction point (the Guardian does not pay) at precisely the moment when that friction most damages adoption: the moment of invitation. A father who is told "accept your daughter's invitation, it costs you nothing" is more likely to activate than one who must make a payment decision. The Guardian adoption risk under any paying-Guardian model is not theoretical — it is the structural risk to the entire product concept.

**The D14 architecture already solves the stated problems.** The entitlement belongs to the Main Wali slot in the relationship graph. If the Seeker cancels, the relationship and all history persist under Subscription Continuity Principle V1; the Guardian simply loses premium capabilities until they purchase Guardian+ standalone. The worked example in Continuity V1 covers this exactly. The complexity Part B describes — "which Seeker funds the Guardian," entitlement ownership, multi-Seeker Guardians — is substantially resolved. Building a new architectural model to solve problems that are already solved is not simplification; it is replacement.

**The bundled model performs better commercially when Guardians do not convert to paid tiers.** The arithmetic is plain. Current model: 1 Seeker + 1 Main Wali = £39.99/month. Proposed personal model: if the Guardian does not pay, ZYRA earns less per household. The revenue upside of the personal model is entirely conditional on Guardian willingness to pay. No data exists on that conversion rate. An architecture that requires an unknown conversion rate to outperform the status quo is a commercial bet, not an improvement.

**Guardian+ standalone at £24.99 already provides the personal-model's main structural benefit.** A Guardian who wants premium independent of any Seeker can purchase it today. The option exists. The argument that the current model "traps" Guardians into dependency is incorrect — there is an explicit escape path priced and ratified.

---

### Best Arguments AGAINST the Current Bundled Model

**The entitlement sits on the wrong account.** A Guardian's premium capability is currently contingent on a Seeker's billing decision. If the Seeker cancels for any reason — financial, personal, or because they are pausing their search — the Guardian loses premium capability without making any decision of their own. The Subscription Continuity Principle correctly preserves the relationship and history, but capability loss without the Guardian's own action is a legitimate fairness concern, regardless of whether the Guardian can then buy standalone.

**The dual-role architecture is genuinely ambiguous.** A user who is simultaneously a Seeker and a Guardian to another Seeker sits in an unresolved architectural space. The Subscription Continuity Principle explicitly flags multi-role accounts as a "separate, unresolved discussion." The bundled model adds an entitlement layer on top of this ambiguity. The personal model resolves it cleanly: one account, one subscription, all contexts covered.

**The one-Guardian-per-Seeker limit creates a cost cliff for additional Guardians.** Under D14, only the Main Wali receives bundled Guardian+. If a Seeker has a Guardian Network with multiple participants — father, uncle, older brother — each additional Guardian beyond the Main Wali needs standalone Guardian+ at £24.99/month. In a traditional family context where multiple male relatives might participate in the wali structure, this creates a stepwise cost increase that the current pricing does not communicate clearly.

**No family plan exists.** The bundled model partially substitutes for a family plan by making Guardian participation free under the Seeker's subscription. But it does so asymmetrically (Seeker pays, Guardian benefits), incompletely (only Main Wali), and without explicit family structure. A real family plan requires deliberate design. The bundled model is not a family plan; it is a side effect that looks like one.

**The £24.99 Guardian+ repricing has no documented rationale.** The price increased 150% in under two weeks (£9.99 → £24.99). If this price is correct, the reasoning should be documented. If it is wrong, it is the single largest adoption risk in the current architecture. A Guardian who would accept £9.99/month as a modest participation cost may refuse £24.99 as a substantive subscription commitment. This review cannot assess whether £24.99 is right without knowing why it was set there. This is flagged as a Founder decision required.

---

### Best Arguments FOR the Personal Non-Transferable Model

**One person, one subscription, all their contexts covered.** The personal model is genuinely simpler to explain and genuinely simpler to build. A single subscription covers both Seeker and Guardian contexts for that person. There are no cross-account dependencies, no entitlement sources to resolve, no scenario where one person's billing decision affects another person's capabilities. This is architecturally clean in a way the bundled model is not.

**Guardian entitlement stability.** A Guardian who purchases their own subscription retains premium capability regardless of what any Seeker does. This is fairer and more resilient.

**Multi-Seeker Guardian clarity.** A father who is Main Wali to three children holds one personal subscription covering all three Guardian contexts. Under the current bundled model, his entitlement technically has three sources; if all three children cancel, he loses premium from all three paths simultaneously. Under the personal model, he holds one stable subscription covering all three.

**Creates genuine family-plan conversion motivation.** When every premium participant pays individually, a family discount has clear demonstrable value. "Three of you want premium; the family plan saves £X" is a legible pitch. Under the bundled model, the family saving is harder to articulate because premium Guardian access is partially absorbed.

**Revenue ceiling is higher if Guardian conversion is achieved.** If 30% or more of Guardians convert to a paid tier — a number this review cannot validate but treats as plausible in a highly engaged, mission-driven user cohort — the personal model generates substantially more revenue per household than the current model.

---

### Best Arguments AGAINST the Personal Non-Transferable Model

**The proposal rests on a retired price.** The entire commercial case in Part B is built around £34.99. That price is retired. At £39.99, the personal model with no Guardian bundle means: the Seeker pays the same as before, receives fewer benefits (no Guardian+ included), and the Guardian must now pay independently for premium access. From the Seeker's perspective, this is a price increase for a reduced product. This is the most serious single objection to Part B's proposal.

**Guardian adoption damage is the product risk, not a pricing sensitivity.** In the Muslim matrimonial context, the Wali is not an optional feature. He is a structural requirement. A father who is invited to act as Wali to his daughter is not shopping for a subscription service — he is participating in a family religious and social obligation. Asking him to make a payment decision to do so meaningfully introduces a category mismatch. This is not a price sensitivity problem that can be solved by setting Guardian+ at the right number. It is a psychological and cultural barrier that the bundled model deliberately bypasses. Removing the bundle re-introduces that barrier.

**The revenue upside is entirely conditional.** As shown in the household maths in the prior exchange, the personal model generates less revenue than the current model whenever Guardians do not convert to paid tiers. The break-even Guardian conversion rate (Personal-A, standalone Guardian+) is approximately 10% of Guardians purchasing independently. That may be achievable — but it must be achieved before the model is commercially superior, not assumed. No data exists to validate the assumption.

**The problem it solves is already largely solved.** The entitlement-ownership concern that motivates Part B is addressed by D14 and Continuity V1. The transferability concern is addressed by the fact that the current model does not create transferable tokens — it creates a relationship-bound entitlement that reverts to the Guardian the moment the Seeker cancels (capabilities change; relationships and history persist). Building a new architecture to solve problems that existing documents have already addressed risks creating new problems while fixing old ones.

**£34.99 cannot be recommended without a decision from the Founder.** This review cannot recommend reinstating a retired price. If the personal model is adopted and a price reduction is warranted (because the bundle is removed), the correct process is a deliberate repricing decision, not the reinstatement of a "never quote" figure.

---

## Part II — Where Fable and Codex Agree

These positions are shared and stated plainly.

**Guardian Basic must be genuinely useful, not performatively useful.** Every function required to exercise meaningful Guardian oversight — reviewing matches, formal participation in Guardian Network decisions, communicating with the Guardian Network, viewing the Seeker's journey — must be free. Premium adds intelligence, depth, analytics, multi-Seeker coordination tools, and convenience. It does not add participation.

**Safety functions are permanently free.** Blocking, reporting, privacy controls, and the ability to withdraw Guardian authority are never behind a paywall. This is a hard constraint that this review endorses without qualification.

**The £24.99 Guardian+ repricing requires documented rationale.** Both reviewers flagged this. A 150% increase in under two weeks with no recorded commercial reasoning is a governance gap. The Founder should document why £24.99 is the right price before it is the first price any new Guardian sees.

**No subscription event may delete relationships, history, or configuration.** This is ratified in Continuity V1 and governs all models. It is not negotiable.

**Weekly plans must be addressed in any recommended architecture.** The prices are ratified (£19.99/week ZYRA One, £14.99/week Guardian+). The surfaces are unbuilt. Any recommendation must specify what happens to weekly plans.

**The £399.90 yearly ZYRA One price requires explicit Founder confirmation.** It is derived, not separately quoted. It is in the architecture as a constraint but cannot be locked until the Founder confirms it.

**A Family plan should not be built before individual subscriptions are commercially validated.** Both reviewers agree on this. Family is the right long-term direction. It is not the right immediate priority when the individual-subscription layer is not yet in production with real payment flows.

---

## Part III — Where Fable and Codex Still Disagree

These disagreements are stated plainly rather than papered over.

### Disagreement 1: Whether the personal model should be adopted at all

**Fable's position:** The personal model's structural advantages are real but are mostly already available through the existing architecture (D14 + Continuity V1 + Guardian+ standalone). The case for abolishing the bundle requires demonstrating that the bundle causes ongoing commercial or product harm — and the evidence for that harm is not in the brief. The correct response to the problems Part B identifies is to complete the implementation of the existing architecture (real payment flows, weekly billing surfaces, multi-role account resolution) before considering whether to replace it. The bundled model at £39.99 should be retained, with Guardian+ standalone reviewed on pricing.

**Codex's position:** Codex recommends retaining the current bundled model and re-evaluating the £24.99 Guardian+ pricing. This is broadly aligned with Fable on the top-level recommendation. Where Codex would add emphasis: the transition to any personal model requires concrete Guardian conversion data before it can be justified, and that data does not yet exist.

**Both positions land in the same place on the top-level recommendation** — retain the bundled model — but via different emphases. Fable emphasises architectural completeness; Codex emphasises data sufficiency. The Founder should note that neither reviewer endorses the Part B proposal as stated.

### Disagreement 2: The right price for Guardian+ standalone

**Fable's position:** £24.99/month is possibly too high for a Guardian-context-only subscription in the Muslim matrimonial market. The £9.99 predecessor may have been correctly priced for adoption. The 150% increase lacks documented rationale. This review recommends the Founder document the pricing reasoning and consider whether £14.99–£19.99/month is a better adoption-supporting price.

**Codex's position:** Codex similarly flags the £24.99 price as unvalidated but does not specify an alternative range. Both reviewers agree the Founder needs to document the reasoning; they differ on the urgency of a price correction.

**Unresolved:** What the right Guardian+ standalone price is. This requires the Founder to articulate the commercial rationale for £24.99. Real data needed: Guardian willingness-to-pay surveys or A/B price testing once real billing exists.

### Disagreement 3: Whether the personal model might be correct at launch

**Fable's position:** The personal model should not be adopted at launch because it removes a structural adoption advantage (Guardian+ bundled) at the moment when activation is most fragile. If the product launches, acquires users, and Guardian adoption data shows that Guardians are willing to pay independently, the architecture can migrate to personal entitlements at that point. The sequencing matters.

**Codex's position:** Codex does not explicitly argue for personal-model adoption at launch but raises the technical migration risks of starting bundled and moving to personal later. Both reviewers agree the migration path matters; Fable accepts that migration from bundled to personal is harder than launching personal from the start.

**This is a genuine unresolved tension.** The Founder must decide: accept a slightly messier future migration in exchange for better adoption dynamics at launch (Fable's recommendation), or accept slightly higher adoption friction in exchange for architectural cleanliness from day one (the logic of the personal model). This review cannot resolve it without Guardian adoption data that does not yet exist.

---

## Part IV — Biggest Risks and Biggest Opportunity

### Biggest Commercial Risk

**Guardian conversion failure under any model that asks Guardians to pay.** If Guardians who receive premium capability today for free (via the D14 bundle) are asked to purchase it independently — whether under the personal model or because the bundle is removed — and if the conversion rate is under 10%, every revenue model that depends on Guardian subscriptions underperforms. The product's core differentiation is the Guardian structure. Monetising the Guardian at the cost of Guardian activation is the worst outcome available. This risk applies to the personal model, and it also applies to the current model if the £24.99 Guardian+ standalone price is set too high for the households it needs to reach.

### Biggest Product Risk

**Guardian Basic is not credibly useful.** If the feature split between Basic and premium Guardian experience is drawn at participation rather than enhancement — if a Guardian on Basic cannot meaningfully exercise oversight, engage with Guardian Network decisions, or view the journey — then "Guardian Basic is genuinely useful" is a claim that fails the moment a real Guardian tries to use it. No pricing architecture fixes this. The product risk is that every premium-tier commercial goal collapses if the free tier creates the impression that the product works only for paying Guardians. The Founder must specify the exact Basic/premium Guardian feature split as a matter of urgency, before any subscription architecture is implemented.

### Biggest Technical Risk

**Weekly billing surfaces and multi-role account architecture are both unbuilt.** The weekly plans (£19.99/week, £14.99/week) are ratified pricing awaiting a build. The entitlement service handles monthly and annual billing; weekly SKUs are not yet in the resolution logic. The multi-role account architecture — a person who is simultaneously a Seeker and a Guardian — is explicitly flagged as unresolved. Any subscription launch without both of these being specified and built will have holes in it. This is not a future concern; it is a current constraint on what can safely be launched.

A secondary technical risk: the current entitlement service uses RPC calls against a Supabase backend with mock purchase flows. No real RevenueCat, App Store, or Play Store billing exists. When real billing is built, the subscription type identifiers used in `wali_has_wali_one()` must include weekly variants, and the resolution logic must handle grace periods, billing-failure states, and store-side receipt validation. This is not architecturally complex, but it is a known gap registered under OA-ZYRA-253(c) and must be completed before launch.

### Biggest Opportunity

**A Muslim matrimonial Family plan with a clear value proposition.** No major Muslim matrimonial app has a well-designed family subscription. The market has individual subscriptions and nothing more. A product that says "one subscription for the whole household — daughters, sons, parents, all covered" addresses the actual way Muslim families approach marriage. It is not a feature addition; it is a market positioning statement. The commercial arithmetic is favourable (shown in Household F above), the product motivation is genuine, and the competitive differentiation is real. The opportunity is not to launch Family immediately — it is to design it correctly now so that when the individual subscription layer is stable, Family launches as a coherent product rather than a retroactive pricing bundle. The risk is building it too early and having it absorb development resource that should go to the core billing infrastructure.

---

## Part V — The Recommended Architecture

### The Single Sentence

Every member of the family has one account that is theirs; the Seeker's subscription includes their Guardian's premium access so the family does not have to pay twice to work together.

---

### Tier 1: ZYRA Basic — Free, Permanently

**Who gets it:** Every account holder, regardless of role, by default.

**Seeker context — what is permanently free:**
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

**Guardian context — what is permanently free:**
- Accept invitation and establish a Guardian relationship.
- View the Seeker's profile and Active Journey.
- Receive notifications for Journey milestones requiring Guardian input.
- Exercise all Guardian Network authority: send, accept, withdraw, and proceed (GN Rules 37/38). Authority is never behind a paywall.
- Communicate with the Guardian Network on the Seeker's journey.
- View match outcomes and provide input on compatibility.
- Withdraw Guardian status at any time.

**Safety functions — permanently free, unconditionally:**
- Block any user.
- Report any content or user.
- Privacy controls.
- Emergency contact features.
- The ability to withdraw Guardian authority immediately.

**The test this free tier must pass:** A father who accepts his daughter's invitation and uses only ZYRA Basic must be able to genuinely exercise his role as Wali — reviewing matches, expressing his view, formally participating in Guardian Network decisions. If he cannot, Basic is not credibly useful and the commercial architecture collapses with it.

---

### Tier 2: ZYRA One — £39.99/month · £19.99/week · £399.90/year

**Price rationale:** £39.99/month is the ratified current price. £34.99 is retired and must not be used. £399.90/year is derived (10 months paid, 12 received) and awaits explicit Founder confirmation — this review endorses it as commercially sound once confirmed. £19.99/week is ratified pricing; the billing surface is unbuilt (OA-ZYRA-253(c)).

**Who should buy it:** Any account holder — Seeker or Guardian — who wants premium capability in their role.

**Seeker context — ZYRA One adds:**
- Unlimited browsing, Saves, and Likes.
- Incoming Potentials (see who Liked you first).
- Mutual Save Detection.
- Higher Active and Paused Journey limits.
- Priority Discovery.
- Compatibility Unlock Plus on Active Journey creation.
- Three free Compatibility Unlock Plus credits.
- ZYRA Intelligence: Recommendations, Insights, Summaries.
- **One bundled Guardian+ entitlement for the Seeker's Main Wali** (D14, OA-ZYRA-247). This is not transferable; it belongs to the Main Wali relationship, not to a named individual independent of that relationship.

**Guardian context — ZYRA One or Guardian+ adds:**
- Advanced Guardian Dashboard with Journey analytics.
- Multi-Seeker intelligence (where the Guardian is Main Wali to more than one Seeker).
- Deeper family and compatibility insights.
- Advanced recommendation and workflow tools.
- ZYRA intelligence applied to the Guardian view.
- Additional premium Guardian Network tools.

**The D14 bundle — ratified, retained, and bounded:**
A Seeker's ZYRA One includes Guardian+ for their Main Wali only. Additional Guardians in the Guardian Network beyond the Main Wali must purchase Guardian+ standalone. This boundary is already implemented in `wali_has_wali_one()` and ratified in OA-ZYRA-247. It is not changed by this review.

**The "payment buys access, never authority" constraint:**
Retained without modification. GN Rules 37 and 38 govern authority regardless of entitlement source. A Guardian whose premium capability comes from the Seeker's bundle has the same authority as a Guardian who purchased standalone Guardian+. A Guardian on Basic has the same authority as either. The payment tier does not change what a Guardian is permitted to decide.

---

### Tier 2b: Guardian+ Standalone — Pricing Decision Required

**Current ratified price:** £24.99/month · £14.99/week · no yearly SKU ratified.

**This review's assessment:** The £24.99/month price lacks documented commercial rationale. It is a 150% increase from the predecessor price (£9.99) made within the same fortnight as this review. The pricing document records the transition but does not record the reasoning. For a SKU whose purpose is to allow Guardians to participate in premium independent of a Seeker's subscription, £24.99/month may be priced above the level at which adoption-critical Guardians will convert.

**This review's recommendation (not a price change — a Founder decision required):** The Founder should document the reasoning for £24.99 before any Guardian-facing build begins. If the reason is "Guardian+ is premium capability equivalent to ZYRA One Guardian context, and should be priced accordingly," then £24.99 is approximately right relative to £39.99 for ZYRA One. If the reason is "Guardian+ should be accessible enough that any Guardian who wants premium can afford it," then a price in the £14.99–£19.99/month range is more appropriate for that goal.

**This review cannot recommend a specific number** because the pricing rationale is undocumented. The Founder must resolve this. What this review can say: the price of Guardian+ standalone is the most commercially sensitive number in the entire architecture. It sits directly in the path of the adoption risk identified throughout this document.

**Flagged as Founder decision required: OA-ZYRA-253 should record the £24.99 rationale before billing is built.**

---

### Tier 3: ZYRA Family — Not Ready to Launch; Design Now

**The recommendation:** Do not launch ZYRA Family until real individual-subscription billing (App Store, Play Store, Stripe) is stable and individual plan conversion rates are known. Design the architecture now so that when the trigger condition is met, Family launches cleanly rather than being retrofitted.

**Why not yet:** The individual subscription layer has no real payment flows. The weekly billing surfaces are unbuilt. The multi-role account architecture is unresolved. Launching a Family plan — which is architecturally more complex than individual billing — before individual billing is proven would compound known risks with new ones.

**Why design now:** The commercial opportunity is real. The arithmetic (shown in Household F) is compelling. The competitive positioning is strong. Designing the entitlement model, abuse-prevention mechanisms, and account structure now means Family can launch quickly once the trigger conditions are met, rather than requiring a full design cycle at that point.

**Trigger conditions for Family launch (recommended):**
1. Real payment flows (App Store + Play Store) are live and stable.
2. At least 90 days of individual-subscription data showing conversion rates, churn, and Guardian adoption behaviour.
3. Multi-role account architecture is resolved.

---

**Family architecture design (for future build, not immediate launch):**

**Recommended model: Family Model D (Modified)**

*Structure:* A Family plan includes a defined number of full ZYRA One identities at a discounted bundle price. Each member holds their own account with their own entitlements. The Family plan does not create a shared pool — it creates a group of individual accounts linked for billing purposes, each with full ZYRA One capability.

*Why not Model A (limited Seeker seats):* Creates a two-class family structure where some members are "full" and others are "Guardian only." This directly recreates the adoption friction the bundled model was designed to avoid.

*Why not Model B (5 full ZYRA One at £99):* At five accounts, £99 represents a £75.95/month saving against the personal model at £34.99 per person — a 43% discount on the headline price. That is a very large discount if maintained long-term. It may be correct at launch as an acquisition offer; it is not clearly sustainable at scale.

*Why not Model C (shared Guardian infrastructure):* The "shared premium Guardian infrastructure" concept is architecturally vague. What makes a Guardian premium under this model is not specified. It risks recreating the bundled-entitlement complexity this review is trying to clarify.

**Recommended Family parameters (indicative — for design, not ratification):**

| Parameter | Recommended | Rationale |
|---|---|---|
| Members | Up to 5 | Reflects a realistic nuclear family unit. Extendable with additional seats. |
| Entitlement per member | Full ZYRA One | No second-class members. |
| Price | £99/month | Cheaper than 3 individual ZYRA One subscriptions (3 × £39.99 = £119.97). Natural conversion point. |
| Yearly | ~£990 (10-for-12 model) | Consistent with individual pricing model. Founder decision required. |
| Organiser role | Billing only | The organiser pays. They do not control other members' account permissions, Seeker autonomy, or Guardian authority. Authority is never purchased; organiser billing does not create organiser authority over family members' journeys. |
| Additional seats | £24.99/month per extra member (indicative) | Below individual ZYRA One cost, above zero. Prevents unlimited growth. |

**Family verification and abuse prevention:**

The principal abuse risk is unrelated individuals forming a "family" group to access the bundle price. The following controls are recommended:

*Relationship declaration at enrolment:* Each member declares their relationship to the organiser (daughter, son, father, mother, spouse, sibling). This is self-declaration, not verification — it creates accountability rather than proof.

*Islamic family structure alignment:* ZYRA's user base is predominantly Muslim. The Wali structure inherently links Guardian and Seeker relationships. A "family" group where no Guardian-Seeker relationship exists between members is structurally unusual and would not pass Guardian Network validation naturally.

*Joining link with expiry:* Members join via an invitation link issued by the organiser. The link expires within 48 hours. Cold invitations to strangers are possible but require deliberate effort.

*Removal and continuity:* If a member is removed from the Family plan, their account reverts to ZYRA Basic. Their relationships, history, and configuration persist (Continuity V1). They can purchase an individual subscription at any time.