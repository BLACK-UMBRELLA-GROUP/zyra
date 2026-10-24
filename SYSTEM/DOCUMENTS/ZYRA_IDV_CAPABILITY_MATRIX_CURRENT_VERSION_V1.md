# ZYRA — Identity-Verification Capability Matrix

**Version:** V1
**Status:** RULED 2026-08-29 (DR-ZYRA-221) — the Founder chose a position STRONGER than every recommendation below: **verification is a mandatory onboarding step; the app does not open unverified.** All nine rows resolve to REQUIRED-by-inheritance (Active Journey additionally needs the duplicate flag resolved; Guardian row carries a held-open exemption flag; purchases inherit; verification free on every plan). The row-by-row recommendations below are retained as the decision history only. Solicitor gate removed by DR-ZYRA-220; compliance carried in-house.
**Date:** 2026-08-29
**Author:** Fable
**Authority:** Founder GO 2026-08-29 (post-027 direction, item 4); DR-ZYRA-219 item 8; Codex 027 (provider evidence)
**Register:** OA-ZYRA-266 (master IDV record)

---

## How to decide (one minute)

Mark each row's **FOUNDER DECISION** as one of:
**REQUIRED** (capability blocked until the person is verified) ·
**DESIRABLE** (prompted, badged, not blocking) ·
**LATER** (revisit post-launch) ·
**NOT GATED** (verification never blocks this).

Two principles carry from existing rulings:

1. **The deeper the gate, the safer the legal ground.** Article 9 explicit
   consent must be freely given, normally with an alternative. Requiring
   biometrics merely to *open the app* is the weakest consent position;
   requiring it before *contacting another human being* is the strongest —
   the user retains a real choice (browse without verifying). Handled
   in-house per DR-ZYRA-220 (internal checklist Q1/Q2).
2. **Verification is a trust gate, never a paywall** (DR-ZYRA-217
   never-paywall list: safety and truthful state). Whatever is marked
   REQUIRED must be free of charge to the member on every plan.

Provider columns state only WRITTEN evidence from 027 (checked 2026-08-29).
Where the written record does not prove a thing, it says **UNKNOWN**.
"Verification event" = document authenticity + selfie liveness +
face-to-document match. Capability *gating* is always ZYRA-side logic on the
stored coarse result — no provider "supports Browse"; what differs per row is
which provider OUTPUT the gate depends on.

---

## The matrix

### 1 · Onboarding (create account, build profile)

| | |
|---|---|
| Needed for launch? | Recommended: NOT GATED (offer, don't require) |
| Product reason | Requiring ID before a person even sees ZYRA kills the top of the funnel and creates the weakest freely-given-consent position. Offering verification during onboarding ("get verified now or later") starts trust early without coercion. |
| Sumsub | Verification event: documented (Flutter SDK). Nothing onboarding-specific. |
| Stripe | Verification event: documented (hosted URL). Nothing onboarding-specific. |
| Veriff | Excluded (Founder direction 3) — auto-decline conflict. |
| Evidence quality | Strong for the event itself (all providers, written docs). |
| Privacy/legal sensitivity | HIGHEST if made mandatory here (consent freely-given problem; no alternative path). Low if offered optionally. |
| Recommended position | **NOT GATED at launch; verification offered and badged.** |
| FOUNDER DECISION | ☐ REQUIRED ☐ DESIRABLE ☐ LATER ☐ **NOT GATED** |

### 2 · Browse (view profiles)

| | |
|---|---|
| Needed for launch? | Recommended: NOT GATED |
| Product reason | Viewing is read-only and anonymous-safe (photo rules already governed elsewhere). Gating Browse = an empty app for every new joiner. |
| Sumsub / Stripe | No capability-specific dependency; verification event only. |
| Veriff | Excluded. |
| Evidence quality | n/a (ZYRA-side gate). |
| Privacy/legal sensitivity | Low ungated. High if gated (same freely-given problem as onboarding). |
| Recommended position | **NOT GATED.** |
| FOUNDER DECISION | ☐ REQUIRED ☐ DESIRABLE ☐ LATER ☐ **NOT GATED** |

### 3 · Consider / Save / Pass (act on a profile)

| | |
|---|---|
| Needed for launch? | Recommended: DESIRABLE (the main dial if you want a harder posture) |
| Product reason | The first act *toward* a person. Gating here means no unverified account can signal interest at all — the strongest safety posture short of gating Browse. Cost: friction arrives before the member has felt any value. |
| Sumsub / Stripe | Verification event only; duplicate flag not yet decision-relevant at this stage. |
| Veriff | Excluded. |
| Evidence quality | Strong (event). |
| Privacy/legal sensitivity | Moderate — an alternative (browse-only use) exists, so consent stands on firmer ground than rows 1-2. |
| Recommended position | **DESIRABLE at launch** (prompt + badge on action), stepping to REQUIRED only if abuse data demands it. |
| FOUNDER DECISION | ☐ REQUIRED ☐ **DESIRABLE** ☐ LATER ☐ NOT GATED |

### 4 · Matching (mutual match forms)

| | |
|---|---|
| Needed for launch? | Recommended: REQUIRED |
| Product reason | The moment two real people are connected is ZYRA's core promise. "Every match is between verified people" is the sentence the brand stands on — and the natural, defensible gate. |
| Sumsub | Verification event documented; duplicate flag SHOULD be clear (not pending review) before first match — programmatic path documented, API inclusion in tier = **UNKNOWN until quote**. |
| Stripe | Verification event documented; duplicate handling Dashboard-human-only (fallback acceptable if Founder accepts operational limitation). |
| Veriff | Excluded. |
| Evidence quality | Strong (event); duplicate-path evidence per 027 §5. |
| Privacy/legal sensitivity | Strongest consent position: verification is required only to *connect with another person*, and browse-only use remains available. |
| Recommended position | **REQUIRED — both sides verified before a match completes.** |
| FOUNDER DECISION | ☐ **REQUIRED** ☐ DESIRABLE ☐ LATER ☐ NOT GATED |

### 5 · Potential Journey

| | |
|---|---|
| Needed for launch? | Recommended: REQUIRED (inherits from Matching) |
| Product reason | Follows directly from row 4 — a Potential Journey only exists between matched (therefore verified) people. No separate gate needed if row 4 is REQUIRED. |
| Providers | As row 4. |
| Evidence quality | As row 4. |
| Privacy/legal sensitivity | As row 4. |
| Recommended position | **REQUIRED by inheritance.** |
| FOUNDER DECISION | ☐ **REQUIRED** ☐ DESIRABLE ☐ LATER ☐ NOT GATED |

### 6 · Active Journey

| | |
|---|---|
| Needed for launch? | Recommended: REQUIRED, plus duplicate-review must be RESOLVED |
| Product reason | The deepest engagement stage (single active slot, guardian oversight, real intent). Recommend the strictest condition here: not just verified, but any open duplicate_review_required flag resolved by human review before an Active Journey starts. |
| Sumsub | Duplicate review workflow documented (console review + final webhook) — the reason it is conditional lead. API inclusion in tier = **UNKNOWN until quote**. |
| Stripe | Duplicate resolution = human Dashboard override only (documented) — workable but manual. |
| Veriff | Excluded. |
| Evidence quality | Good written evidence for both remaining providers per 027 §5. |
| Privacy/legal sensitivity | Same strong ground as row 4; duplicate-review consequence rules (027 §8) apply — neutral copy, no disclosure of the other account. |
| Recommended position | **REQUIRED + duplicate flag resolved.** |
| FOUNDER DECISION | ☐ **REQUIRED** ☐ DESIRABLE ☐ LATER ☐ NOT GATED |

### 7 · Guardian linking

| | |
|---|---|
| Needed for launch? | Recommended: LATER (Seeker side covers launch risk) |
| Product reason | Two distinct questions hide here: (a) can an unverified SEEKER link a Guardian — recommend yes (guardian oversight arriving early is good, not risky); (b) must GUARDIANS verify their own identity — real value (impersonated guardians are a genuine abuse vector) but it doubles the biometric-processing population and DPIA scope. Recommend deciding Guardian-identity verification as its own later round. |
| Sumsub / Stripe | Same verification event technically; nothing guardian-specific documented. Guardian-flow product design = **UNKNOWN / not evaluated**. |
| Veriff | Excluded. |
| Evidence quality | Event strong; guardian-specific flow unproved. |
| Privacy/legal sensitivity | High if extended to Guardians (new data-subject class; family relationships inferable). |
| Recommended position | **LATER for Guardian identity; Seeker linking NOT GATED.** |
| FOUNDER DECISION | ☐ REQUIRED ☐ DESIRABLE ☐ **LATER** ☐ NOT GATED |

### 8 · Messaging

| | |
|---|---|
| Needed for launch? | Recommended: REQUIRED by inheritance |
| Product reason | ZYRA messaging exists inside Journeys (matched context) — so if rows 4-6 are REQUIRED, every conversation is already verified-to-verified with no separate gate. If messaging ever exists outside a Journey, this row must be re-ruled first. |
| Providers | As row 4. |
| Evidence quality | As row 4. |
| Privacy/legal sensitivity | As row 4. |
| Recommended position | **REQUIRED by inheritance (no separate gate to build).** |
| FOUNDER DECISION | ☐ **REQUIRED (inherit)** ☐ DESIRABLE ☐ LATER ☐ NOT GATED |

### 9 · Purchases (ZYRA One, Guardian+, unlock packs)

| | |
|---|---|
| Needed for launch? | Recommended: NOT GATED — and verification itself always free |
| Product reason | Paying needs no identity proof (Apple/Google handle payment identity), and blocking purchases would gate revenue on biometrics for no safety gain — the benefits bought are already gated by rows 4-6 where it matters. Inverse rule matters more: verification must never sit behind a purchase (DR-ZYRA-217 never-paywall principle). |
| Providers | n/a. |
| Evidence quality | n/a. |
| Privacy/legal sensitivity | Gating purchases on biometrics would be the worst consent position of all (financial detriment for refusal). |
| Recommended position | **NOT GATED; verification free on every plan.** |
| FOUNDER DECISION | ☐ REQUIRED ☐ DESIRABLE ☐ LATER ☐ **NOT GATED** |

---

## Summary of recommendations (for fast marking)

| # | Capability | Recommended |
|---|---|---|
| 1 | Onboarding | NOT GATED (offer + badge) |
| 2 | Browse | NOT GATED |
| 3 | Consider/Save/Pass | DESIRABLE (the posture dial) |
| 4 | Matching | **REQUIRED** |
| 5 | Potential Journey | **REQUIRED** (inherit) |
| 6 | Active Journey | **REQUIRED + duplicate review resolved** |
| 7 | Guardian linking | LATER (Guardian identity as own round) |
| 8 | Messaging | **REQUIRED** (inherit — in-Journey only) |
| 9 | Purchases | NOT GATED; verification always free |

Net effect if adopted as-is: an unverified member can join, browse and feel
the product; nobody reaches another human being unverified; nothing about
safety costs money. One sentence for the store listing and the solicitor
alike: **"Every ZYRA match is between identity-verified members."**

## Open provider facts still UNKNOWN (do not decide against them)

1. Sumsub: whether Similar Search + API + manual-review routing are included
   in the Basic tier price — written quote required (027 §11 condition 1).
2. Stripe: whether the duplicate-selfie insight can be exposed
   programmatically (written answer outstanding — Founder direction item 2).
3. All providers: arbitrary profile-photo-vs-selfie matching — NOT PROVED
   anywhere; stays OFF (027 §11 condition 8).
