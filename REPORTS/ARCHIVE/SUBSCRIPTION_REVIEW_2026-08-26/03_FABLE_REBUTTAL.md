# Fable — rebuttal, commercial model, Family architecture

*Fable · claude-sonnet-4-6 · 2026-08-26T00:04:51.171672+00:00*

# ZYRA Subscription Architecture Review — Fable Response to Codex

**Run:** SUBSCRIPTION_REVIEW_2026-08-26
**Reviewer:** Fable (Claude), product and commercial reviewer
**Document:** Response to Codex challenge + Full Commercial Analysis
**Status:** No code changed. Analysis only.

---

## Part I — Response to Codex's Challenge

### Concessions — What Codex Got Right

**Codex is correct that I did not state the reason for the £39.99 repricing.** My phrasing was "the Founder raised the price to £39.99 for a reason" — and then I used that undisclosed reason as rhetorical weight against the proposed reversal. That is an unfair argument. The brief does not record the rationale for the 2026-08-23 increase. I should not have implied one existed and was sufficient to carry the argument. The correct framing is: a deliberate repricing decision was made two days before this review; the burden is on Part B to justify reverting it, not on this review to assume the increase was wise. I was circular. Conceded.

**Codex is correct that calling the Guardian model ZYRA's sole differentiator is an overstatement.** The Seeker experience — journey structure, compatibility intelligence, browsing limits, the tone and seriousness of the product — is also differentiating. The Guardian model is the most structurally distinctive differentiator relative to competitors, but "ZYRA's differentiation is the Guardian model" stated without qualification was too broad. Conceded.

**Codex is correct that the weekly-plan entitlement service gap is real.** The `hasWaliOne()` function resolves against `wali_premium` and `seeker_premium` subscription types. Weekly SKUs do not yet exist as store products. When weekly billing is built, the subscription type resolution will need to include weekly variants — and the risk is that a Guardian or Seeker on a weekly plan resolves incorrectly to Basic until that is done. This is a genuine technical gap registered under OA-ZYRA-253(c) but not addressed by the entitlement service code yet. Conceded; I should have flagged this explicitly.

### Partial Concession — The £24.99 Guardian+ Increase

Codex challenged me for not thoroughly questioning the £24.99 Guardian+ price, and for describing the £9.99 → £24.99 increase misleadingly.

I will separate the two sub-points.

**On the £9.99 historical claim:** Codex is technically correct that the pricing document lists £9.99 under "never quote" (a retired figure) rather than in the canonical pricing history table. However, the V2 changes section records: "Guardian+ standalone repriced: £9.99 → £24.99/month." The document explicitly states this transition. The £9.99 predecessor is not absent from the documentation; it is the stated before-figure in the V2 change log. My claim was accurate. Codex's challenge on this specific point is wrong.

**On whether the £24.99 increase should have been challenged more forcefully:** Codex is right that I did not adequately challenge it. I named it in the opening position and then continued treating £24.99 as a stable datum for household maths without questioning whether a 150% standalone-Guardian price increase in under two weeks was commercially sound. The full commercial analysis below addresses this directly.

### Rebuttal — What Codex Got Wrong

**The £9.99 claim.** As above: the V2 change log in ZYRA_PRICING_CURRENT_VERSION_V2 reads explicitly "Guardian+ standalone repriced: £9.99 → £24.99/month." The document records the before figure. My statement was accurate.

**Codex claims my position "assumes the Guardian+ price at £24.99/month is justified."** I explicitly wrote, in the opening position, under section 4: "£24.99/month for a Guardian+ standalone is an increase from the previous £9.99/month — a 150% increase in less than two weeks. The commercial reasoning is not stated in the brief. If Guardian adoption is the core risk… then the price of that SKU matters considerably." That is not an assumption of justification; it is an explicit flag that the justification is missing. The critique does not hold.

**On the client-server trust model:** Codex notes that the client must trust server responses. This is correct in principle, but the observation conflates two separate concerns. The entitlement service is a server-side RPC call precisely to prevent client-side spoofing. The mock path in the current preview build is developer-only (gated behind developer access in the code comments). When real payment flows exist, the RevenueCat or App Store receipt verification layer will sit between the store and the entitlement function. The architecture is appropriate for its current preview-build state; the risk Codex identifies is a launch-readiness concern, not a design flaw.

---

## Part II — Full Commercial Analysis

### II.1 — The Three Models Under Comparison

For this analysis I compare three models consistently:

- **Model Current:** Ratified 2026-08-23. ZYRA One £39.99/month; Guardian+ standalone £24.99/month; D14 Main-Wali bundle.
- **Model Personal:** Founder's Part B proposal. ZYRA One £34.99/month, non-transferable, no bundle. Guardian+ standalone status unresolved (see section II.2).
- **Model Current+:** A variant I introduce — retain the current structure but reconsider the £24.99 Guardian+ price and add a Family plan. This is Model E from the family analysis.

I will compare revenue, adoption, and commercial psychology across all three, with worked household examples in section II.3.

---

### II.2 — What Happens to Guardian+ Standalone Under the Personal Model

Part B does not mention Guardian+ standalone. This creates an architectural ambiguity that must be resolved before the personal model can be costed or evaluated.

**Option Personal-A:** Guardian+ standalone survives at £24.99/month. A Guardian who wants premium tools buys Guardian+ rather than ZYRA One. This preserves a lower-cost Guardian premium path.

**Option Personal-B:** Guardian+ standalone is retired. Premium Guardian access requires ZYRA One at £34.99/month. A Guardian who wants premium pays the same as a Seeker.

**Option Personal-C:** Guardian+ standalone is repriced to align with the personal model. Under a strictly personal model, Guardian+ becomes the Guardian-context equivalent of ZYRA One. Its current price (£24.99/month) may or may not remain appropriate.

The analysis below runs Personal-A and Personal-B as the two realistic variants. Personal-C is addressed in the pricing challenge section. Throughout, any figure using £34.99 is flagged as a retired price that requires a Founder decision to reactivate.

---

### II.3 — Worked Household Examples

All calculations use ratified prices (Part A) for the current model. Part B's £34.99 is flagged as a retired figure in every instance. For Guardian+ annual, no yearly SKU is ratified; I use 12 × monthly as a conservative estimate throughout.

---

#### Household A: 1 Seeker + 1 Main Wali Guardian

| | Current Model | Personal-A | Personal-B |
|---|---:|---:|---:|
| Seeker (ZYRA One) | £39.99 | £34.99 *(retired)* | £34.99 *(retired)* |
| Guardian basic | £0 | £0 | £0 |
| Guardian premium | £0 (bundled) | £24.99 (Guardian+) | £34.99 *(retired)* (ZYRA One) |
| Household — Seeker only premium | **£39.99/mo** | **£34.99/mo** | **£34.99/mo** |
| Household — both premium | **£39.99/mo** | **£59.98/mo** | **£69.98/mo** |
| Annual — Seeker only | £399.90 | £349.90 *(derived)* | £349.90 *(derived)* |
| Annual — both premium | £399.90 | £649.78 *(est.)* | £699.80 *(derived)* |

**ZYRA revenue impact vs current, Seeker-only-premium household:** Personal model earns **£5/month less** per core household. At 10,000 such households that is **£600,000/year less** in revenue (estimate — actual subscriber count unknown; real data required).

**ZYRA revenue impact vs current, both-premium household:** Personal-A earns £19.99/month more; Personal-B earns £29.99/month more — *but only if the Guardian converts to a paid tier.* The upside is conditional. It requires converting a cohort of Guardians who currently receive premium for free into paying customers. Guardian conversion rate to a paid tier is unknown; no data exists from which to estimate it with confidence. I will flag two scenarios: 50% Guardian conversion (optimistic) and 15% Guardian conversion (conservative). Real data — activation logs, cohort analysis by Guardian tier — is what would be needed.

**Revenue model for 10,000 households (estimate, flagged):**

| Scenario | Current monthly | Personal-A monthly | Personal-B monthly |
|---|---:|---:|---:|
| Guardian never pays (0%) | £399,900 | £349,900 | £349,900 |
| Guardian converts at 15% | £399,900 | £349,900 + £37,485 = £387,385 | £349,900 + £52,485 = £402,385 |
| Guardian converts at 50% | £399,900 | £349,900 + £124,950 = £474,850 | £349,900 + £174,950 = £524,850 |

At 15% Guardian conversion, Personal-A earns less than current. At 15% Guardian conversion, Personal-B barely exceeds current. The personal model only outperforms the current model on revenue if Guardian conversion to premium exceeds roughly 10% (Personal-A) or 3% (Personal-B). Above 50%, the personal model is substantially better. The critical unknown is: what percentage of Guardians will pay for premium? That number does not exist. This review cannot assume it is high.

---

#### Household B: 2 Seekers (Siblings) + 1 Shared Parent Guardian

Both siblings use the same parent as Main Wali. Parent is Main Wali to both.

**Under D14 (current):** Each Seeker's ZYRA One includes Guardian+ for their Main Wali. The parent has two Seeker-funded Guardian+ entitlements — one from each child's subscription. Under `wali_has_wali_one()`, the function returns true if any linked Seeker with active ZYRA One exists. Parent's entitlement is covered.

| | Current Model | Personal-A | Personal-B |
|---|---:|---:|---:|
| Seeker 1 (ZYRA One) | £39.99 | £34.99 *(retired)* | £34.99 *(retired)* |
| Seeker 2 (ZYRA One) | £39.99 | £34.99 *(retired)* | £34.99 *(retired)* |
| Parent basic | £0 | £0 | £0 |
| Parent premium | £0 (bundled × 2) | £24.99 or £0 | £34.99 *(retired)* or £0 |
| Household — Seekers only | **£79.98/mo** | **£69.98/mo** | **£69.98/mo** |
| Household — all premium | **£79.98/mo** | **£94.97/mo** | **£104.97/mo** |
| Annual — Seekers only | £799.80 | £699.80 *(derived)* | £699.80 *(derived)* |
| Annual — all premium | £799.80 | £1,099.64 *(est.)* | £1,199.60 *(derived)* |

**Revenue impact:** Again, personal model earns less if Guardian does not pay. Earns more if Guardian pays. The sibling household is one of ZYRA's natural use cases — two sisters seeking marriage, father as Main Wali to both. Under the current model, that family pays £79.98 and the father has full Guardian+ access to both Journeys. Under the personal model, the father faces a binary: pay nothing and participate at Basic level for both daughters; pay £24.99 or £34.99 and participate at premium for both. That is not an unreasonable ask if premium Guardian tools are genuinely valuable. But it must be evaluated against adoption risk.

---

#### Household C: 3 Adult Siblings + 2 Parents (Both Parents are Guardians)

Three Seekers, each with a different Main Wali designation. Seeker 1: Father as Main Wali. Seeker 2: Father as Main Wali. Seeker 3: Mother as Main Wali.

**Current model:**
- 3 × £39.99 = £119.97/month. Father's Guardian+ covered by Seekers 1 and 2. Mother's covered by Seeker 3. Both parents have full Guardian+ at no additional cost.
- Annual: £1,199.70.

**Personal-A (if parents want premium):**
- 3 × £34.99 *(retired)* = £104.97 + Father £24.99 + Mother £24.99 = **£154.95/month** *(estimate)*.
- Annual: approximately £1,799.40 *(estimate)*.

**Personal-B:**
- 3 × £34.99 *(retired)* + Father £34.99 *(retired)* + Mother £34.99 *(retired)* = **£174.95/month** *(estimate)*.
- Annual: approximately £2,099.40 *(estimate)*.

**Revenue impact vs current, all-premium household:** +£35/month (Personal-A) or +£54.98/month (Personal-B). This is the strongest commercial case for the personal model: in multi-child, multi-Guardian households where all adults want premium access, the personal model generates substantially more revenue. The question is whether those households convert all adults to premium, or whether parents decline and participate at Basic.

**Note on this scenario's importance:** The 3-siblings + 2-parents household is where ZYRA Family becomes genuinely relevant. If the Family plan is set at £99/month for up to 5 members, this household pays £99 vs £154.95 or £174.95 under the personal model. That is a genuine conversion incentive. I analyse Family pricing in section III.

---

#### Household D: 1 Guardian Representing Multiple Seekers (Non-Family)

A father with three children seeking marriage through ZYRA, each from a different Guardian Network. He is Main Wali for all three.

**Current model:**
- 3 children × £39.99 = £119.97/month. Father's Guardian+ is covered by all three Seeker subscriptions. Father's entitlement is unambiguous.
- Annual: £1,199.70.

**Personal model (any variant):**
- Father's entitlement is now his own subscription, independent of any child. If he holds ZYRA One or Guardian+, he has premium across all three Guardian contexts with one personal subscription.
- Children: 3 × £34.99 *(retired)* = £104.97/month.
- Father: £34.99 *(retired)* or £24.99 (Personal-A) or £0 (basic).
- Household total (all premium, Personal-A): **£129.96/month**.
- Household total (all premium, Personal-B): **£139.96/month**.

**This is the scenario where the personal model is cleanest architecturally and commercially.** Under the current model, Father's entitlement technically depends on three separate Seeker subscriptions, each of which could individually lapse. Under the personal model, Father's one personal subscription covers all three Guardian contexts stably. The entitlement service `wali_has_wali_one()` with OR logic across multiple Seeker relationships is technically correct today, but it is more complex than a single personal subscription. This is the personal model's strongest genuine structural argument.

---

#### Household E: Dual-Role User (Seeker and Guardian Simultaneously)

A man who is seeking marriage himself and also acting as Wali to his sister.

**Current model:** He purchases ZYRA One as a Seeker (£39.99/month). His own Seeker subscription includes Guardian+ for his sister's Main Wali (himself, in the Guardian Network). In principle, D14 covers this — he is both the Seeker and his own Wali context holds entitlement. But the multi-role account architecture is explicitly unresolved (Subscription Continuity Principle V1, referenced discussion). Whether `wali_has_wali_one()` correctly resolves for an account that is simultaneously a Seeker with ZYRA One and a Guardian, and whether the resolution applies to his own Guardian context (as Wali to his sister) via his own Seeker subscription, is architecturally ambiguous. The entitlement service RPC is designed around the relationship graph, not role-based queries, so this is likely to resolve correctly — but it is untested.

**Personal model:** He purchases ZYRA One once. His Seeker context receives ZYRA One features. His Guardian context receives ZYRA One Guardian features. Single subscription, both roles covered. Monthly: **£34.99 *(retired)***. This is architecturally unambiguous and is the personal model's second genuine structural advantage.

**Revenue impact:** Current £39.99 vs proposed £34.99. ZYRA earns less from the dual-role user. The dual-role user was arguably paying for a Seeker subscription that happened to also cover his Guardian role; under the current model that is already clean. Under the personal model he saves £5/month.

---

#### Household F: 5-Person All-Premium Household (Family Plan Candidate)

Two parents + three adult children, all wanting premium.

**Current model (no Family plan):**
- 3 Seekers × £39.99 = £119.97. Parents covered by D14 bundles (assuming each child designates a different parent as Main Wali). If all three designate the same parent, only one Guardian+ is needed.
- Worst case (both parents want premium independently): £119.97 + £24.99 = **£144.96/month**.
- Annual: approximately £1,739.52 *(estimate, Guardian+ annual not ratified)*.

**Personal-B model (no Family plan):**
- 5 × £34.99 *(retired)* = **£174.95/month**.
- Annual: **£1,749.50** *(derived)*.

**With Family plan at £99/month (Founder's suggestion):**
- All five covered: **£99/month**. Annual: **£1,188**.
- Saving vs Personal-B (all premium, no Family): **£75.95/month**. Annual saving: **£911.40**.
- Saving vs Current (all premium, no Family): **£45.96/month**. Annual saving: **£551.52**.

**This arithmetic is the strongest argument for ZYRA Family.** It provides genuine, demonstrable value. The question is whether £99 is financially sustainable for ZYRA. I address this in section III.

---

### II.4 — Challenge to the Three Headline Numbers

#### FREE

The Founder's principle — essential Guardian participation never paywalled, safety functions never paywalled — is correct and must not be weakened. The review endorses this without reservation.

**However:** "Free" must be credibly useful, not performatively useful. If the free Guardian experience communicates "you are a participant in your daughter's marriage but only at a reduced level," the adoption risk materialises regardless of price. The review cannot, from this brief, fully specify the Basic/One split — that requires a complete feature audit against the Guardian journey specification. What this review can say is: the distinction between Basic and premium must be drawn at the level of *enhancement*, not *participation*. Every function required to genuinely exercise Guardian oversight (review profiles, express views, formally participate in Guardian Network decisions, communicate with the Seeker's Guardian Network) must be in Basic. Premium should be intelligence, depth, dashboard analytics, multi-Seeker coordination tools, and workflow convenience.

**What data would confirm this:** Guardian activation cohort analysis showing what percentage of invited Guardians reach the Guardian Network decision stage. If activation is high under the current Basic feature set, Basic is credibly useful. If activation is low, the feature audit matters urgently.

#### £34.99 (Proposed ZYRA One Price)

**Three serious challenges to this number:**

**Challenge 1: It is a retired figure.** The pricing document explicitly lists £34.99 under "never quote." The Founder raised the price to £39.99 six days before commissioning this review. Returning to £34.99 is a reversal, not a design choice. This review cannot recommend reinstating a retired price without understanding why it was retired. If the reason for the £39.99 increase was evidence-based (e.g., willingness-to-pay research, comparator pricing, conversion testing), then reverting within a week is commercially damaging — it signals pricing instability that undermines user confidence. If the reason was arbitrary, then £39.99 may itself be wrong, in which case the right question is not "should we return to £34.99" but "what is the right price, derived from market analysis."

**Challenge 2: The personal model's revenue case depends on Guardian conversion.** As shown in the household maths, if Guardians do not convert to paid tiers, the personal model at £34.99 generates less revenue than the current model at £39.99 from every 1+1 household. The break-even Guardian conversion rate (where personal-model revenue equals current-model revenue) is approximately 10% in the Personal-A scenario. That seems achievable, but it is not guaranteed, and there is no current data on Guardian willingness to pay.

**Challenge 3: £39.99 may be correct for reasons unrelated to the bundle.** The Compatibility Unlock pricing (£1.99, £7.99, £2.99, £9.99) was repriced deliberately in August 2026. The ZYRA One price was repriced at the same time. If the overall product value proposition increased with the subscription-continuity guarantees, the D14 entitlement, and the Guardian+ bundle, then £39.99 may be correctly matched to the new product. Reverting to £34.99 without reverting those additions would be incoherent.

**My position on £34.99 vs £39.99:**

I cannot recommend either price with confidence because the rationale for the 2026-08-23 increase is not in the brief. What I can say:

- If the personal model is adopted (no Guardian bundle), the case for £39.99 is weaker — the price increase partly reflected the addition of a bundled Guardian+ entitlement. Remove the bundle, and the price justification needs reexamining.
- If the bundled model is retained, £39.99 should stay unless there is a specific willingnesss-to-pay reason to drop it. Cutting price without a conversion-rate or competitive reason is a permanent revenue loss with no guaranteed upside.
- The pricing psychology argument in Part B ("£34.99 is more competitive than £39.99") is weak. The £5 difference is sub-threshold for most purchase decisions in this category; Muslim matrimonial app users are not price-sensitive in the way a mass-market dating app is. Muzz (the closest comparator) charges comparable or higher prices. The claim that £34.99 wins psychological ground that £39.99 loses requires evidence that does not exist in this brief.

**If I must state a position:** Do not revert to £34.99 unless the personal model is adopted and even then only with a deliberate repricing rationale, not because Part B proposed it. If the bundled model is retained, £39.99 should stand.

#### £99 (Proposed Family Price)

This is analysed fully in section III. Summary preview: £99 is commercially viable if Family is capped at a defined member count and premium Guardian capability is clearly bounded. It is not commercially viable if it provides unlimited premium access to an unlimited family group without controls. The number itself is in the right range; the definition of what it includes determines whether it is a sustainable price or a discounting exercise that cannibalises individual subscriptions.

---

### II.5 — Pricing Psychology and Perceived Fairness

**Current model perception:** The bundled model is perceived as generous by Seekers — "I subscribe and my father gets access too." It creates a slight obligation dynamic where the Seeker feels responsible for their Guardian's access. For a product where Guardian adoption is critical, this is