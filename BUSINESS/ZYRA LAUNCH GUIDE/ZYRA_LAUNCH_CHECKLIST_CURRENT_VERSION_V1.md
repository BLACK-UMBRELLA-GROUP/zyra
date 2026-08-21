# ZYRA — Launch Checklist

**Version:** V1
**Status:** CURRENT_VERSION
**Date:** 2026-08-13
**Owner:** Founder
**Governing Reference:** ZYRA_GOVERNANCE
**Supersedes:** nothing — BUSINESS/ZYRA LAUNCH GUIDE/Summary.md remains as background material

---

## What this document is, and what it is not

This is not a near-term plan. It is the complete list of what stands between the current build and a lawful public release, most of which has not been started.

Stated plainly, as at 2026-08-13:

- **No company exists.** ZYRA LTD is not registered. There is no business bank account. Without a registered controller, the Privacy Policy and Terms cannot name who the user is contracting with or who processes their data.
- **No payment processing exists.** "Upgrade" flips a local mock entitlement. Neither App Store IAP nor Stripe has been started. Every price in the pricing document is currently unchargeable.
- **The database is not production-clean.** 144 synthetic Chapter 3/4 profiles and twelve dev-only RPC functions are present and must be removed (OA-ZYRA-190, OA-ZYRA-184).
- **Core paths have never run against real data.** `matches`, `conversations`, `messages` and the ten `journey_*`/`timeline_*` tables are at zero rows. Notifications are at zero rows; the bell is a placeholder.
- **Nothing has been reviewed by a solicitor.** The Article 9 condition for religious and ethnicity data is undecided, and the lawful basis for sharing a Seeker's Journey data with her Guardian has no precedent anywhere in the category.
- **Safety capability is thinner than the product implies.** There is no moderation queue, no verification, and no photo moderation.

What *is* built is real and holds: the completeness gate (`profiles.onboarding_complete`, enforced by `zyra_can_view_profile` and `zyra_can_match`), Chapter 2 persistence with append-only Article 9 consent capture, blocking with mutual invisibility, private photo storage, production reference lists stored as codes, and a genuinely cascading `delete_own_account()`.

**Jurisdiction:** UK. The Consumer Contracts Regulations 2013 (14-day cancellation; the digital-content carve-out requires an explicit acknowledgement from the user) and the Consumer Protection from Unfair Trading Regulations both apply. Referred to below as **CCR 2013** and **CPUT**.

**Conventions.** Owners are: Founder; Founder + solicitor; Implementation Lead; UX Lead; Founder + accountant. Status uses the four permitted values (Not started / In progress / Done / Blocked). Where the true state has not been verified, the cell reads **Unknown — needs confirmation** rather than a guess. "Blocked" means blocked on another item in this list, named in the reason.

**Nothing in this document is legal advice.** Where an item needs a solicitor, it says so.

---

## Phase A — Legal & Company

| # | Item | Why it blocks launch | Owner | Status |
|---|---|---|---|---|
| A1 | Register ZYRA LTD at Companies House | No legal person to contract with users, hold the developer accounts, hold the bank account, or be named as data controller | Founder | Not started |
| A2 | Confirm registered name, company number, registered office, VAT status | Required in Terms, Privacy Policy and the website footer company line | Founder | Blocked — on A1 |
| A3 | Open business bank account | Money cannot be received; Stripe/store payouts have nowhere to land | Founder | Blocked — on A1 |
| A4 | Engage a solicitor with data-protection and consumer-tech experience | Article 9, the Guardian model, auto-renewal and OSA scope all need a ruling, not a draft | Founder | Not started — Founder has confirmed it will happen |
| A5 | Decide the Article 9 condition for religious belief and ethnicity | The values instrument is the product; "performance of a contract" is not an Article 9 condition. Route 2 (explicit consent to a separable optional feature) is the recommended first question to the solicitor | Founder + solicitor | In progress — consent capture built 2026-08-04, route undecided |
| A6 | Draft and review the Privacy Policy | Cannot be published without a named controller, retention numbers, the Article 9 route and a live contact address | Founder + solicitor | Blocked — on A2, A5, A11, A14, G3 |
| A7 | Draft and review the Terms of Service | Must carry the attention-drawing preamble, auto-renewal, cooling-off, verification disclaimers, liability cap and English governing law | Founder + solicitor | Blocked — on A2, A5, A15, B5, B6 |
| A8 | Write the Guardian privacy notice as its own navigable section | The Guardian is a full data subject with a full account and the power to block progression. No competitor precedent exists; it must be written from scratch | Founder + solicitor | Blocked — on A4 |
| A9 | Publish Community Guidelines (public face of SAFETY_RESPECT_SYSTEM V3) | Terms reference community rules; the public version must match actual enforcement capability, not intended capability | UX Lead | Not started |
| A10 | Cookie Policy, or a one-line "no cookies" statement | Determined by whether the marketing site ships analytics — a Founder decision that is still open | Founder | Blocked — on H9 |
| A11 | Decide retention periods (post-deletion, and inactivity auto-delete) | Vague retention is a common ICO finding; blocks the Privacy Policy, the Account Deletion page and the Help Centre deletion answer | Founder + solicitor | Not started |
| A12 | Set an age floor of 18 and enforce it in the database | Terms will state 18+; the database currently enforces no minimum age at all | Implementation Lead | Not started |
| A13 | Decide launch territories (UK only, or wider) | Changes international transfer wording and whether a separate US annex is needed | Founder | Not started |
| A14 | Name a privacy contact (person or role) | A formal DPO is not mandatory at this scale; a named contact route is | Founder | Not started |
| A15 | Write the verification and no-background-check disclaimers | Verification is not built at all while the FAQ discusses it — shipping without an equivalent disclaimer engages CPUT | Founder + solicitor | Not started |
| A16 | Purchase insurance: cyber, professional indemnity, directors & officers | Cannot be bought before the company exists; cost TBC | Founder | Blocked — on A1 |
| A17 | Register trademarks for the ZYRA name and logo | Recommended, not blocking. Cheaper before public exposure than after | Founder | Not started |
| A18 | Obtain written IP transfer from any freelancer who has contributed | Ownership of code and assets must sit with the company | Founder | Unknown — needs confirmation whether any third party has contributed |
| A19 | Engage an accountant; diarise Corporation Tax, Annual Accounts, Confirmation Statement | Statutory obligations begin at incorporation, not at launch | Founder + accountant | Blocked — on A1 |

---

## Phase B — Payments & Commercial

| # | Item | Why it blocks launch | Owner | Status |
|---|---|---|---|---|
| B1 | Decide the payment rail: App Store IAP or Stripe | The background launch guide assumes Stripe; the app sells digital entitlements through app stores. Neither has been started | Founder + solicitor | Not started — route Unknown, needs confirmation |
| B2 | Replace the local mock entitlement with a server-side entitlement | "Upgrade" currently grants ZYRA One without taking money and without a durable record. A paid surface that charges nothing is not shippable | Implementation Lead | Not started |
| B3 | Build purchase, receipt validation, restore and entitlement sync | No SDK is in the project. Every price is unchargeable | Implementation Lead | Blocked — on B1 |
| B4 | Build the buy page | It owns prices, the BEST VALUE badge and the free-vs-purchased credit itemisation — three things the spec requires and no screen currently shows | Implementation Lead | Not started |
| B5 | Disclose auto-renewal prominently, with advance notice of renewal and price | CMA-active area; required for the renewal term to be fair and enforceable | Founder + solicitor | Not started |
| B6 | Implement the 14-day cancellation right with the digital-content carve-out | CCR 2013. The carve-out only applies if the user explicitly acknowledges it at the point of purchase — that acknowledgement must be captured and stored | Implementation Lead | Not started |
| B7 | Document cancellation and refund routes, including the Apple/Google flows | Users must be told how to cancel through the store, not only through ZYRA | UX Lead | Not started |
| B8 | Implement Founder Members: first 1,000 purchasers, 50% off for 6 months then 25% off for 6 months | A capped offer stated publicly must be counted accurately or it is a misleading commercial practice under CPUT | Implementation Lead | Not started |
| B9 | Implement Early Adopters: next 5,000 purchasers, 25% off for 12 months | As B8 | Implementation Lead | Not started |
| B10 | Grant and itemise the 3 free Compatibility Unlock Plus credits for ZYRA One Seekers | Free and purchased credits must be distinguishable, or the balance shown is not honest | Implementation Lead | Not started |
| B11 | Present annual billing accurately as 10 months paid, 12 months received (£349.90) | Price presentation is CPUT territory; the saving must be described as it actually works | UX Lead | Not started |
| B12 | Review regional pricing before launch | Approved to-do in the pricing document | Founder | Not started |
| B13 | Validate pricing against competitor changes before public release | Approved to-do in the pricing document | Founder | Not started |
| B14 | Complete the Subscription & Billing Script Summary against the ZYRA One model | Approved to-do; the billing copy has no ratified source | UX Lead | Not started |
| B15 | Complete the Payments Flow Blueprint against the ZYRA One model | Approved to-do; the flow has no ratified source | Implementation Lead | Not started |
| B16 | Determine VAT treatment of displayed prices | Terms must state pricing and VAT correctly | Founder + accountant | Blocked — on A2 |

---

## Phase C — Product completeness

| # | Item | Why it blocks launch | Owner | Status |
|---|---|---|---|---|
| C1 | Execute Matches → Journey → Chat end to end against real data | `matches`, `conversations`, `messages` and the ten `journey_*`/`timeline_*` tables are all at zero rows. The core promise of the product has never run | Implementation Lead | Not started |
| C2 | Make notifications real | The notifications table has zero rows and the bell is a placeholder; Firebase push is not connected | Implementation Lead | Not started |
| C3 | Ship no verification, and say so everywhere | Verification is not built. Every surface that touches it must disclaim rather than imply. See A15 | UX Lead | Not started |
| C4 | Close the remaining compatibility scoring decisions: (d) how many categories and which, (e) `v_ch2_weight` | Scoring was ratified 2026-08-11 (green 1, amber 0.5, red 0, two asymmetric scores). These two parts are still open, and `v_ch2_weight` at 1 may understate sect and ethnicity for this audience | Founder | In progress |
| C5 | Mark compatibility figures as sample until they are real, or make them real | The SAMPLE banner was removed 2026-08-04. Nothing now marks "81% overall" as fabricated — a screenshot travels without a warning. Fine internally; a real risk at first demo or TestFlight | Implementation Lead | Not started |
| C6 | Verify Admin-only visibility of the developer system in a release build | The store build contains the developer system; only Admin accounts may see it | Implementation Lead | Unknown — needs confirmation |
| C7 | Obtain a clean `flutter analyze` run on the Founder's Mac | `tools/zyra_check.py` catches five known breakage classes but does not replace the analyser; a clean static run is necessary, not sufficient | Founder | Not started |
| C8 | Drop or use `profiles.bio` | Exists and is referenced nowhere. Housekeeping, not blocking | Implementation Lead | Not started |
| C9 | Completeness gate: `profiles.onboarding_complete`, enforced by `zyra_can_view_profile` and `zyra_can_match` | A partial profile is not matchable; applicability accounts for gender and conditional `showIf` rules | Implementation Lead | Done — 2026-08-11 |
| C10 | One state per profile (Saved / Considering / Declined mutually exclusive) | Enforced in three layers; live data migrated, zero conflicts remain | Implementation Lead | Done |
| C11 | Blocked users visible in Settings, with a working unblock | The missing half of a feature that shipped with only its first half | Implementation Lead | Done |
| C12 | Production reference lists: 197 countries, 184 languages, 29 ethnicities, stored as codes | CHECK constraints reject labels; relabelling never orphans a user row | Implementation Lead | Done |
| C13 | `profiles.location_text` written, not only read | Every genuinely-onboarded Seeker previously rendered an em-dash where their city belongs | Implementation Lead | Done |
| C14 | Chapter 2 persistence and Article 9 consent capture | Append-only consent, `policy_version` recorded, `has_article9_consent()` defaults false, decline is a real path | Implementation Lead | Done — wording still needs A5 |
| C15 | `delete_own_account()` cascade | Genuinely cascades; the Account Deletion page can describe it accurately today | Implementation Lead | Done |

---

## Phase D — Data & Privacy

| # | Item | Why it blocks launch | Owner | Status |
|---|---|---|---|---|
| D1 | Remove the 144 synthetic Chapter 3/4 profiles (OA-ZYRA-190) | Real users would browse and attempt to match with fabricated people. Misleading under CPUT and indefensible in this community | Implementation Lead | Not started |
| D2 | Remove the twelve dev-only RPC functions (OA-ZYRA-184) | Dev RPCs in a production database are an open privilege surface against real personal and special-category data | Implementation Lead | Not started |
| D3 | Remove or invalidate seeded consent rows carrying `policy_version = '2026-08-04-seed'` | Seeded consent must never be mistaken for genuine agreement. They are deliberately greppable | Implementation Lead | Not started |
| D4 | Disclose automated processing | `score_candidates()` orders who a user sees and excludes candidates outright on Hard Requirements. That is automated processing with a real effect and must be disclosed | Founder + solicitor | Not started |
| D5 | Name processors in the Privacy Policy: Supabase (AWS eu-west-1), Apple and Google auth | Required disclosure; the list must be complete at the point of publication | Founder + solicitor | Not started |
| D6 | State international transfers | Supabase eu-west-1 is Ireland; adequacy applies. Widens if A13 goes beyond the UK | Founder + solicitor | Blocked — on A13 |
| D7 | State the declared-location-only commitment | ZYRA already uses a `location_text` field and collects no device geolocation. That is a differentiator and should be a stated commitment, not an implementation detail | UX Lead | Not started |
| D8 | Build the data subject rights routes: access, rectification, erasure, restriction, objection, portability, withdrawal | Erasure exists via `delete_own_account()`. The other routes have no confirmed mechanism | Implementation Lead | Unknown — needs confirmation |
| D9 | Name the ICO as the complaint route | Required in the Privacy Policy | Founder + solicitor | Not started |
| D10 | Confirm which registrations or notifications apply to ZYRA as a UK controller | Not addressed in any current source | Founder + solicitor | Unknown — needs confirmation |
| D11 | Give the Guardian their own rights, notice and retention schedule | ZYRA is the controller of the Guardian's data. A Guardian is a data subject in their own right, not an email address | Founder + solicitor | Blocked — on A8 |
| D12 | Verify backups and rehearse a restore | Supabase manages backups; that they restore has not been demonstrated | Implementation Lead | Unknown — needs confirmation |

---

## Phase E — Safety & Moderation

| # | Item | Why it blocks launch | Owner | Status |
|---|---|---|---|---|
| E1 | Build the moderation queue | Nothing exists behind the report button. Offering reporting without review is both unsafe and a misleading claim | Implementation Lead | Not started |
| E2 | Word the report flow to match actual capability | No implied moderation team until E1 ships. "We may, not must" language on moderation rights | UX Lead | Blocked — on E1 |
| E3 | Define the report and appeals process | Users must be told what happens after a report and how to appeal a removal | Founder | Blocked — on E1 |
| E4 | Provide an escalation route for a coercive Guardian, and a stated right to end the relationship | ZYRA has built a mechanism giving one person visibility and veto over another's marriage process. The audience includes young women in controlling households | Founder + solicitor | Not started |
| E5 | Set an eligibility bar beyond age (no relevant convictions for hate, terrorism, violent or sexual offences) | Precedent exists in the category and is worth adopting given the audience | Founder + solicitor | Not started |
| E6 | Publish UK helplines, each number verified at draft time | Category standard, and the audience expects Muslim-specific lines alongside the general ones | UX Lead | Not started |
| E7 | Make clear that photo moderation does not exist | Not built. The Terms and Safety page must not imply otherwise | UX Lead | Not started |
| E8 | Obtain a solicitor's view on Online Safety Act scope | ZYRA is user-to-user through messaging; duties apply even without a feed | Founder + solicitor | Not started |
| E9 | Blocking: instant, private, mutual invisibility via `profile_blocks` RLS | Real today and can be described honestly | Implementation Lead | Done |
| E10 | Photo privacy: private storage with signed, expiring URLs | Real today and can be described honestly | Implementation Lead | Done |

---

## Phase F — Store submission

| # | Item | Why it blocks launch | Owner | Status |
|---|---|---|---|---|
| F1 | Apple Developer account | Nothing can be submitted to the App Store without it | Founder | Unknown — needs confirmation |
| F2 | Google Play Developer account | Nothing can be submitted to Play without it | Founder | Unknown — needs confirmation |
| F3 | Hold both developer accounts in the company's name | Transferring a published app out of an individual's account later is avoidable friction | Founder | Blocked — on A1; whether an account already exists in a personal name is Unknown — needs confirmation |
| F4 | Configure store products matching the pricing document (£34.99 / £349.90 / £9.99 / £1.99 / £7.99 / £2.99 / £9.99) | Prices shown in-app must match the products actually charged | Implementation Lead | Blocked — on B1 |
| F5 | Publish a reachable web account-deletion path | Apple and Google both require it; also basic GDPR hygiene | UX Lead | Blocked — on A11 for the retention wording |
| F6 | Include the Apple-required Terms wording | Apple mandates specific wording in the app's terms | Founder + solicitor | Blocked — on A7 |
| F7 | Complete store data disclosures consistently with the Privacy Policy | The forms cannot be filled before the policy is final; the exact current requirements of each store are Unknown — needs confirmation | Founder | Blocked — on A6 |
| F8 | Set the age rating consistently with the 18+ floor | Store rating and Terms must not contradict each other | Founder | Blocked — on A12 |
| F9 | Cut the release build from MAIN | DEV must never reach users; merging DEV → MAIN does not itself update anyone | Implementation Lead | Not started |
| F10 | Submit to Apple | Terminal step; depends on every hard gate | Founder | Blocked |
| F11 | Submit to Google | Terminal step; depends on every hard gate | Founder | Blocked |

---

## Phase G — Infrastructure & Operations

| # | Item | Why it blocks launch | Owner | Status |
|---|---|---|---|---|
| G1 | Own zyra.app and point it at the site | Every document assumes this domain; ownership is not confirmed anywhere | Founder | Unknown — needs confirmation |
| G2 | Acquire zyra.co.uk, zyra.uk, zyra.com and redirect them to zyra.app | Defensive, not blocking. Cheaper before any public attention | Founder | Not started |
| G3 | Stand up Google Workspace with live support@, legal@ and hello@ mailboxes | The Privacy Policy, Terms and Contact page all publish an address that must reach a real person | Founder | Unknown — needs confirmation whether the mailboxes exist |
| G4 | Commit to a support response window and publish it honestly | The Contact page states one; there is no team behind a live chat, so email with an honest window is the only truthful option | Founder | Not started |
| G5 | Separate a production Supabase project from development, and size the plan | Dev artefacts reaching production is exactly the D1/D2 failure mode; cost moves from free to roughly £20+/month | Implementation Lead | Unknown — needs confirmation |
| G6 | Configure Firebase for push notifications | Prerequisite for C2 | Implementation Lead | Not started |
| G7 | Confirm auth hygiene: email verification, password rules, account recovery | Listed as essential security in the background guide; implementation state not verified | Implementation Lead | Unknown — needs confirmation |
| G8 | Define a personal-data breach response route: who is told, by whom, within what period | Cyber insurance covers the loss; it does not discharge the duty | Founder + solicitor | Not started |
| G9 | Confirm the release discipline holds: users receive updates only through a store release | Protects against a DEV build reaching users during launch week | Implementation Lead | Not started |
| G10 | Accept a running-cost baseline (~£30–£75/month at small launch, before marketing) | Infrastructure must be funded from the business account, not personally, once A1 and A3 exist | Founder | Blocked — on A3 |

---

## Phase H — Marketing & Website

| # | Item | Why it blocks launch | Owner | Status |
|---|---|---|---|---|
| H1 | Build the Tier 1 pages: Home, How ZYRA Works, For Guardians & Families, Safety, Privacy Policy, Terms, Community Guidelines, Help Centre, Contact, Account Deletion, Accessibility Statement, cookie statement | Defined as blocking at public launch in the website IA blueprint | UX Lead | Not started |
| H2 | Hold the Home page to what exists: no user-count claims, no success claims, no screenshots of features that are not built | There are no users and no successes yet. Inventing either engages CPUT and would be fatal in this community | UX Lead | Not started |
| H3 | Publish the Help Centre only after the FAQ review fixes land | The four fiction answers must not reach the open web | UX Lead | Blocked — on the FAQ review fixes |
| H4 | Publish Report & Appeals only after the moderation queue exists | The page must not describe a process that does not run | UX Lead | Blocked — on E1 |
| H5 | Obtain line-by-line Founder sign-off on "What ZYRA Will Never Do" | Each line is a permanent, quotable, testable public commitment. Only include commitments the product keeps today | Founder | Not started |
| H6 | Publish "How ZYRA Decides Who You See" | Doubles as the plain-English home of the D4 automated-processing disclosure | UX Lead | Blocked — on D4 |
| H7 | Publish "For Guardians & Families" | The highest-value page on the site and the reason a household chooses ZYRA; must not exceed what WALI_ARCHITECTURE V6 describes | UX Lead | Not started |
| H8 | Add the footer company line: registered name, England and Wales, company number | Cannot be written before incorporation | UX Lead | Blocked — on A2 |
| H9 | Decide whether the site ships analytics at all | Determines cookie banner versus a "no cookies" statement, which is itself a trust win | Founder | Not started |
| H10 | Publish an honest Accessibility Statement | Do not claim WCAG conformance that does not exist; "building toward it, here is where we are" is the only truthful version | UX Lead | Not started |
| H11 | Publish the Contact page: email, a real person, an expected response window, no fake form | Blocked on the mailbox actually existing | UX Lead | Blocked — on G3, G4 |
| H12 | Add app store badges only once listings are live; no social icons until the accounts exist | An empty shelf signals a small company pretending, which is worse than a short footer | UX Lead | Not started |
| H13 | Review every marketing claim against CPUT before any paid, organic or influencer activity begins | Founder Members and Early Adopters caps, pricing savings, safety claims and matching claims are all testable statements | Founder | Not started |

---

## Hard gates

These make launch unlawful or unsafe rather than merely unpolished. Everything else can ship rough; none of these can ship at all.

1. **No registered company.** UK GDPR requires the controller be identified, and users must know who they are contracting with. The Privacy Policy and Terms cannot be published at all until ZYRA LTD exists. *Clears with A1–A2.*
2. **Article 9 condition undecided.** Religious belief and ethnicity are special-category data and sit at the centre of the matching engine. Performance of a contract is not a valid condition. *Clears with a solicitor's ruling on A5.*
3. **Guardian lawful basis undecided.** ZYRA shares a Seeker's Journey data with a third party who holds a veto over her progression. Consent must be freely given and as easy to withdraw as to give; a gate that halts her Journey puts that in question. No precedent exists. *Clears with A8 and E4.*
4. **Synthetic data and dev RPCs in the live database.** 144 fabricated profiles that real users could browse and match with, and twelve dev-only RPC functions exposed against real special-category data. *Clears with D1–D3 (OA-ZYRA-190, OA-ZYRA-184).*
5. **No enforced age floor.** The Terms will say 18+; the database enforces nothing. A marriage platform that cannot exclude minors is unsafe before it is non-compliant. *Clears with A12.*
6. **Reporting with no moderation queue.** A report button that leads nowhere is both a safety failure and a misleading claim under CPUT. Either build the queue or state plainly that reports are not actively reviewed. *Clears with E1–E2.*
7. **Verification implied but not built.** There is no identity, selfie or age verification and no background checks. Shipping without explicit disclaimers, while the FAQ discusses verification, is indefensible. *Clears with A15 and C3.*
8. **Taking money without the consumer machinery.** No payment processing exists; "Upgrade" flips a local mock entitlement. Before any charge is possible ZYRA needs a real entitlement, prominent auto-renewal disclosure with advance notice of renewal and price, and the CCR 2013 14-day cancellation right with an explicitly acknowledged digital-content carve-out. *Clears with B1–B6.*
9. **Fabricated compatibility figures shown without a marker.** The SAMPLE banner was removed; "81% overall" now travels in a screenshot with nothing saying it is not real. *Clears with C5.*

---

## Deliberately out of scope for v1

Recorded so they are not rediscovered as gaps.

**Retired by Founder decision, 2026-07-12 — not merely renamed:**
- Per-Guardian-relationship billing and proration.
- Family and multi-account billing, and payment ownership rules.
- Any Basic/Pro/Premium tiered subscription structure.

**Deliberate future features, to arrive by decision rather than by accident:**
- Shared Compatibility Unlocks between a Seeker and her Guardian. Guardian scope stays narrow (own Seeker's Chapter 2 data only), confirmed 2026-08-04.
- Two-factor authentication, AI moderation, fraud detection, device monitoring.
- Identity, selfie and age verification. Not built for v1, and therefore disclaimed rather than implied — see hard gate 7.
- Photo moderation. Same treatment: absent, and must not be implied.

**Website — not built on faith:**
- Success Stories. Requires real couples; fabricated or borrowed stories would be fatal in this community.
- Blog and Guides, Press, Careers. Only with a real cadence, real coverage and real roles. An empty shelf is worse than no shelf.
- A religious-rulings page. ZYRA describes its approach and defines its terms; it does not issue or imply fatwas, endorse a madhhab, or arbitrate fiqh. If scholarly endorsement is ever secured, name the scholars and let them speak.
- Live chat or a ticket portal. There is no team behind it; the Contact page says email, honestly.

**Legal shape:**
- US-style arbitration clauses. UK launch, English governing law.
- A formal DPO appointment. Not mandatory at this scale; a named contact is (A14).
- A UK GDPR representative. Applies only if incorporating outside the UK, which is not the plan.

**Deferred, non-blocking:**
- Trademark registration for the name and logo (A17) — recommended, not a gate.
- Additional domains (G2).
- `profiles.bio` (C8).

---

## Open questions carried into this checklist

Recorded because each one is currently answerable only as **Unknown — needs confirmation**:

- Payment rail: App Store IAP or Stripe (B1).
- Apple and Google Play developer account existence and ownership (F1–F3).
- Whether zyra.app is owned, and whether support@, legal@ and hello@ are live mailboxes (G1, G3).
- Whether a production Supabase project exists separately from development (G5).
- Whether email verification, password rules and account recovery are implemented (G7).
- Whether backups restore (D12).
- Whether any third party holds IP in ZYRA's code or assets (A18).
- Launch territories (A13) and retention periods (A11) — Founder decisions, not unknowns, but both block drafting.

---

## Version History

| Version | Date | Change |
|---|---|---|
| V1 | 2026-08-13 | Initial governed checklist. Supersedes nothing; BUSINESS/ZYRA LAUNCH GUIDE/Summary.md is retained as ungoverned background material and its status table is known to be outdated. |

*End of Document*
