---
id: DOC-ZYRA-0291
type: SPEC
status: DRAFT
feature: PRODUCT BLUEPRINT
purpose: Blueprint part 2 (Membership and payments) - plans and prices, the joining fee, the trial, Family places, Compatibility Unlocks, what each plan includes, cancelling and billing grace, and what App Store purchases need - each marked built, different or missing, with its decision
links: [OA-ZYRA-309, OA-ZYRA-317, DOC-ZYRA-0287, DOC-ZYRA-0289, DR-ZYRA-252, DR-ZYRA-275]
owner: Fable
---

# ZYRA BLUEPRINT — PART 2 — MEMBERSHIP AND PAYMENTS — V1 (DRAFT)

Status: **DRAFT for Shakeel.** Written 26 Oct 2026 from `SOURCE/lib/data/zyra_membership_catalog.dart`,
`zyra_seeker_plan_limits.dart`, `zyra_entitlements.dart`, `zyra_release_gates.dart`, the planned app's membership pages and the
server (`subscriptions`, `family_*`, `unlock_*` tables and functions). Last column: **Built** · **Different** · **Missing**.


> **How to read the server column (added 26 Oct, after the live check DOC-ZYRA-0294):** "Built" here means **in the repository
> files**. Production is about two months behind. Not live today: per-Guardian View/Chat switches and agreed access
> (`zyra_set_guardian_journey_permission`), Family places, the Main-Guardian Journey hold, the Guardian Circle, read receipts,
> the verified trial, Browse ranking (`zyra_browse_ranked_ids`) and the 5 Oct security fixes. Everything else marked Built is live.

## In one paragraph

ZYRA has two plans for each role. **Basic** costs **£4.99 once** (free if you have paid for a membership before) and has no
monthly fee. **One** is monthly — **Seeker One £29.99**, **Guardian One £19.99** — and Seeker One starts with **one 14-day trial
per verified person, for life**. Families can buy **up to 10 Seeker One and 10 Guardian One places** with a growing discount.
**Compatibility Unlocks** are separate: £2.99 for one, £6.99 for three, £9.99 for five; Seeker One includes 3. The server already
knows who has paid, handles trials, billing grace and cancellation — but **nothing can be bought yet**: there is no App Store
purchase code, so plans are set by developer functions. What each plan *includes* is still described in the old app's terms
(Potential, Paused, Saved, Considers) and needs redefining for the planned app (§6).

## 1. Plans and prices

| Plan | Price | Decision | Server |
|---|---|---|---|
| Seeker Basic | £4.99 once; no monthly fee; no trial | DR-ZYRA-252, DR-ZYRA-235 | **Different** — Basic counts as unpaid (0 Journey places) until reconciled (DR-ZYRA-275) |
| Guardian Basic | £4.99 once; view permitted linked Journeys and Timeline, Main Guardian reviews, safety; **no chat, no Network** | DR-ZYRA-252, DR-ZYRA-268 | **Different** — same as above |
| Seeker One | £29.99 / month | DR-ZYRA-252, DR-ZYRA-243 | **Built** — `subscriptions.plan_type = 'seeker_premium'` |
| Guardian One | £19.99 / month | DR-ZYRA-252, DR-ZYRA-243 | **Built** — `'wali_premium'` |
| Joining fee waived | No £4.99 if a membership was paid before; trials and Unlock purchases do not count | DR-ZYRA-252 | **Missing** — needs payment history |
| Prices shown | The App Store's local price, rounded up to a supported price point, once purchases exist | — | **Missing** |

## 2. Trial

| Rule | Decision | Server |
|---|---|---|
| Seeker One: **one 14-day trial per verified person, for life**, then monthly unless cancelled | DR-ZYRA-252 | **Built** — `zyra_start_verified_seeker_trial` (server only, ledger per verified person) |
| Taking a Family Seeker place ends the trial | — | **Built** — trigger `zyra_forfeit_seeker_trial_on_family_seat` |
| Basic has no trial | DR-ZYRA-252 | — |

## 3. Family places

| Rule | Decision | Server |
|---|---|---|
| 0–10 Seeker One and 0–10 Guardian One places, billed monthly; zero places cannot be bought | DR-ZYRA-252 (Family formula kept) | **Built** — `family_subscriptions`, `family_seat_assignments` |
| Price: one or two places at individual prices; from three places the saving grows 5 points per place, up to 40% at ten places | DR-ZYRA-252 | **Built** — `zyra_family_formula_monthly_pence` |
| Include a place for your own role; a place gives One access for its role; giving a place never links anyone | — | **Built** — seat guards |
| A family member must have passed the identity check to take a place | DR-ZYRA-221 | **Built** — `zyra_require_verified_family_seat` |

## 4. Compatibility Unlocks

| Rule | Decision | Server |
|---|---|---|
| £2.99 for one, £6.99 for three, £9.99 for five; separate from membership | DR-ZYRA-250, DR-ZYRA-252 | prices **Missing** (no purchases); credits **Built** — `unlock_credits`, `unlock_balance` |
| Seeker One includes **3** Unlocks | — | **Built** — trigger `grant_zyra_one_credits` |
| An Unlock shows a browsed person's compatibility; scoring follows the six approved policies (twelve categories, strict answers) | DR-ZYRA-250, DR-ZYRA-135 | **Built** — `zyra_unlock_profile`, unlock guards |
| An earlier Unlock stays active for that person later (e.g. in a Journey Bio) | DR-ZYRA-250 | **Built** |

## 5. Who has paid, cancelling and billing grace

| Rule | Decision | Server |
|---|---|---|
| Paid = an active One subscription, or a funded Family place for that role | DR-ZYRA-243, DR-ZYRA-248 | **Built** — `zyra_has_paid_role` |
| Cancelling keeps access until the paid period ends | DR-ZYRA-248 | **Built** — `coverage_ends_at` |
| A failed payment gives up to **16 days** of billing grace | DR-ZYRA-248 | **Built** — `billing_grace_until` (max 16 days) |
| Monthly billing only | DR-ZYRA-248 | **Built** — check constraint |
| A Seeker's subscription never proves their Guardian paid | DR-ZYRA-268 | **Built** |

## 6. What each Seeker plan includes — DECIDED 26 Oct (DR-ZYRA-282)

| | Seeker Basic | Seeker One |
|---|---|---|
| Journey places | 1 | 3 |
| Browsing | 25 profiles every 4 hours | unlimited; also when all places are full |
| Pending requests | 3 | 25 (DR-ZYRA-283) |
| End a Journey to accept a new request | no | yes |
| Request restart | no | from the 5 most recent ended Journeys |
| Revisit declined profiles | no | up to 10 |
| Guardians | 1 | up to 10 (including Main) |
| Compatibility Unlocks included | 0 | 3 |
| Trial | none | 14 days, once per verified person |

Retired from every plan: Potential Journeys, Paused Journeys, Saved profiles, Considers. The plan text and limit files
(`zyra_seeker_plan_limits.dart`, `zyra_entitlements.dart`) still show the old list until they are rewritten after the freeze;
server limits are in the OA-ZYRA-317 design.

## 7. Payments — what must exist before anything can be bought (OA-ZYRA-317 item 7)

| Need | Today |
|---|---|
| App Store products for Seeker/Guardian Basic, Seeker/Guardian One, Family places, Unlock packs | Not created |
| In-app purchase code (StoreKit) | None — no package in the app |
| Server check of every purchase receipt before access is granted | None — plans set by developer functions (`zyra_dev_set_seeker_plan`, `mock_set_wali_plan`) |
| Payment history (for the joining-fee waiver) | None |
| Release switch `paidOnlyMembershipEnforced` | Off |

## 8. Decided 26 Oct (DR-ZYRA-282)

| # | Question | Decision |
|---|---|---|
| Q1 | Guardians per Seeker | **By plan: Basic 1, One up to 10**; a Guardian supports at most 10 Seekers (replaces DR-ZYRA-281's "5") |
| Q2 | What each plan includes | **The table in §6** |

## Change log

| Date | Version | Change |
|---|---|---|
| 2026-10-26 | V1 | First draft (OA-ZYRA-309) |
| 2026-10-26 | V1 | §6 and §8 decided (DR-ZYRA-282) |
