# Codex — independent verification (recovered)

*Codex · gpt-4o · 2026-08-26T16:16:20.812525+00:00 · run subrev-recovery-20260826*
*Contract: CHALLENGE COMPLETE*

## 1. CONSTRAINT CHECK — does it contradict any governing constraint?

The recommendation does not contradict any governing constraint. It adheres to existing constraints, such as maintaining the structure under D14, which bounds the Guardian+ entitlement to the Seeker's Main Wali (E6). It retains the "payment buys access, never authority" constraint (E7).

## 2. SAFETY / PAYWALL — does it paywall anything safety-related or essential to the core Guardian role?

The recommendation ensures that safety functions are permanently free and unconditionally accessible, including blocking and reporting features (E8). It also maintains the core Guardian functionalities, such as exercising Guardian Network authority, as part of the free ZYRA Basic tier, thus not paywalling essential Guardian roles.

## 3. AUTHORITY — does it break 'payment buys access, never authority'?

The recommendation does not break the 'payment buys access, never authority' principle (E7). Authority within the Guardian Network continues to be governed by relationship structures rather than by payment tiers, as outlined in the recommendation and supported by GN Rules 37 and 38.

## 4. CONTINUITY / HISTORY — does any subscription event delete or orphan relationships or history?

The recommendation aligns with the Subscription Continuity Principle (E8). It states that no subscription event — including expiry, cancellation, or a change of payer — will delete or orphan relationships, history, or configuration data. This principle is maintained as a key part of the recommendation.

## 5. STORE BILLING — is it implementable under Apple and Play as described?

The recommendation will require the development of billing surfaces for weekly plans, as these have not been built yet (E4). The entitlements must be expanded to handle weekly subscription types under both Apple's App Store and Google's Play Store billing systems. This is a technical requirement that is feasible but necessitates completion before launch.

## 6. ARITHMETIC — recompute the household maths yourself and say whether it holds.

The arithmetic provided in the recommendation appears correct. For instance, a single Seeker and Guardian household generates revenue of £39.99/month (E1), while a dual Wali situation for Guardian Standalone results in £64.98/month (£39.99 Seeker + £24.99 standalone Guardian+; E3). The provided calculations align accurately with the pricing details listed in E1 and E3.

## 7. WHAT WAS MISSED — by both reviewers.

Both reviewers do not extensively elaborate on the ramifications for multi-role accounts, which are architecturally unresolved and acknowledged as such. Further clarification is needed on how these accounts will be structured and billed. Additionally, neither review delves into detailed market data or user feedback that would indicate Guardian willingness to convert based on proposed pricing changes.

## 8. VERDICT — exactly one of: SIGN OFF / SIGN OFF WITH CONDITIONS (list them) / REJECT (say what must change).

SIGN OFF WITH CONDITIONS

**Conditions:**
1. Complete the development of weekly billing surfaces and ensure compliance with app store requirements.
2. Document and finalize the rationale for the £24.99 Guardian+ pricing.
3. Provide a more detailed plan for resolving multi-role account architecture ambiguities before launch.