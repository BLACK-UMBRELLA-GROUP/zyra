# ZYRA — Membership and Pricing

**Version:** V6  
**Status:** CURRENT_VERSION — Founder-approved product contract; commerce activation remains gated  
**Date:** 2026-10-21 (Halo focus percentage savings; catalogue and earlier rulings retained)  
**Owner / approval authority:** Founder  
**Supersedes:** ZYRA_PRICING_CURRENT_VERSION_V5.md in full  
**Decision:** DR-ZYRA-248, amended by DR-ZYRA-252; protected design previews DR-ZYRA-254 and DR-ZYRA-263

**Unlocks savings presentation — Founder direct instruction, 2026-10-21:**
Show savings as percentages rather than pounds: three22%, five33%, compared
with the same number of singles. Derive from integer-pence totals and round
down to whole percentages:198/897≈22.0736%;496/1495≈33.1773%. Prices and unit
prices are unchanged; a single has no saving claim. The accepted Halo focus
store has a read-only positive balance and no Use action. Pack selection is
not payment; checkout/receipt activation remains held. This supersedes only
earlier pound-saving/store-use presentation requirements below, not history.

**Unlocks catalogue/store amendment — Founder direct instruction, 2026-10-20 (saving/use presentation superseded above):**
The product remains Unlocks: one£2.99, three£6.99, five£9.99. The three-pack
supports £2.33 each / Save £1.98 vs singles; five£2.00 each / Save £4.96 vs
singles and a quiet sentence-case Best value. These are catalogue-rounded unit
descriptions, not verified store-local quotations. Select a pack first; a tile
must never purchase. Continue remains unavailable until real store/receipt
activation, with the unavailable notice below it. Existing owned credits lead
before selling more. The Founder explicitly accepted the refund-safe line:
“One-off purchase. Refunds are subject to Apple’s terms and applicable law”.
This supersedes the old two-pack catalogue/layout below, not held activation,
historic ledger meanings or DR-ZYRA-250. The per-profile lifetime rule includes
ordinary Journey ending. Formal app Terms must still be supplied; the current
legal destination truthfully reports unavailable and records no acceptance.

**Basic joining-fee amendment — Founder direct instruction, 2026-10-18:**
Someone who has previously paid for a ZYRA membership does not pay another
£4.99 joining fee when choosing Basic, including a paid Seeker One downgrade.
The Founder explicitly clarified membership payments only: Compatibility
Unlock purchases do not waive this fee. An unpaid trial is not a membership
payment. The first joining fee remains for someone confirmed never to have
paid for membership. A current/selected/expired plan is not payment history;
unknown history is neither a confirmed fee nor a waiver. This amends the
repeated-fee implication of DR-ZYRA-252, not the retained monthly prices,
role limits, identity checks or access/privacy rules. Receipt/history and
Basic-access confirmation remain required; this is not live activation.

**Compatibility amendment — Founder direct instruction, 2026-10-11:**
Replace the two optional compatibility products with one Compatibility
Unlock, including the former Plus depth at its former prices: £2.99 each
or £9.99 for five. The lower-price overall-only offer and separate public
Plus name are superseded. Membership prices, allocations, trials and
automatic Journey grants are unchanged except public compatibility naming.
Historical Standard/Plus balances and permanent grants are preserved; no
conversion is selected. This does not approve a store product, receipt,
payment, real detailed disclosure, live migration or commerce activation.
Section 9 owns the current optional-purchase catalogue.

## 1. Membership choices

### Family first month onboarding preview requested 2026-10-04

The Founder explicitly adds ZYRA Family at **£4.99 per person for the first
month** to the protected onboarding comparison for both signup roles
(DR-ZYRA-263). The selected Family configuration shows its first-month total
separately from the unchanged monthly renewal formula in §2. The ordinary
renewal saving does not reduce the £4.99 introductory unit price. This is not
an extra joining fee or a free trial. The comparison retains the existing
no-checkout boundary; it does not activate a store offer or change ordinary
membership/trial terms.

The current configurator counts selected role places, with one person assumed
per place. It has no verified-person allocation or deduplication. Existing
dual-role policy still requires two places; unique-person eligibility and
commercial treatment of dual-role people must be resolved under OA-ZYRA-253
before checkout activation, not invented by this display. Onboarding Preview
handover §108 owns the measured client implementation and delivery state.

### First month design preview requested 2026-10-03

The Founder has now requested a protected onboarding preview of Seeker One at
£4.99 for its first month, then the unchanged £29.99 monthly renewal price,
including a gentle explicit Basic-to-One suggestion. This supersedes the
earlier rejection of that idea for this local design comparison only. It does
not activate an offer, take a second joining fee, change entitlement or confirm
store eligibility. The Founder is considering replacing the 14-day free trial;
that decision is pending. The existing trial terms below remain the ordinary
contract until explicitly amended. A standalone Guardian One introductory
price is not inferred from this Seeker screenshot. The later Family comparison
above is explicitly requested; Family's normal renewal formula is unchanged.
As-built scope and tests are recorded in the Onboarding Preview handover §96
and `SIGNUP_MEMBERSHIP_FIRST_MONTH_PREVIEW_2026-10-03_VERIFICATION.json`.

Founder amendment, 2026-10-03, qualified by the payment-history amendment above:
Basic returns for each role at **£4.99 once for a first membership payment**,
covering the joining/verification charge, with **no monthly subscription**.
It is not universally free; confirmed previous membership payers owe no new
joining fee when choosing Basic. This replaces the earlier no-Basic rule only; it does
not activate checkout or certify that a default/legacy Basic account paid.
At that amendment, the preceding idea about a £4.99 premium first month was
not adopted. The later protected design preview above does not change the
ordinary contract below.

New signup chooses membership after required account details, before the real
identity check. The selection is private intent, never purchase/access proof.
A signed-in person without confirmed paid-role or eligible Basic access retains
restore/resubscribe, billing, safety/support, privacy and data controls,
download/deletion, legal information and sign out.

| Membership | Monthly UK base price | Trial |
|---|---:|---:|
| **Seeker One** | **£29.99** | One 14-day trial per verified person for life |
| **Guardian One** | **£19.99** | None |
| **ZYRA Family** | Configurable formula below | None |

| Basic membership | One-time joining fee | Monthly subscription |
|---|---:|---|
| **Seeker Basic** | **£4.99 only if never paid for membership** | None |
| **Guardian Basic** | **£4.99 only if never paid for membership** | None |

With confirmed previous membership payment, either Basic choice has **no
joining fee** and no monthly subscription. Unknown history must be resolved
before a personal fee quote or checkout; it must not silently become £4.99
or £0. This price exception does not itself activate either role or create
any Guardian relationship authority.

- Monthly billing only. No weekly or yearly plan.
- Every Family place carries the same role features as its corresponding
  individual One membership.
- A person may have separate Seeker and Guardian role accounts. Each role
  requires its own confirmed membership or Family place; identity verification occurs
  once where the verified-person binding proves both accounts belong to them.
- Payment never creates a Guardian link, changes Main authority, grants Journey
  permission or bypasses safety/privacy rules.

## 2. ZYRA Family formula

The owner independently chooses **0–10 Seeker places** and **0–10 Guardian
places**. Either role can be zero; 0 + 0 cannot be purchased.

`gross = (Seeker places × £29.99) + (Guardian places × £19.99)`

`discount = min(40%, max(0%, (total places − 2) × 5%))`

- 1–2 places: 0% saving; 3: 5%; 4: 10%; then +5 percentage points per
  place, capped at 40% from 10 places onward.
- Unused purchased places are charged and count toward the discount.
- Calculate in integer pence and round once, half up. App Store products use
  the nearest supported price point **at or above** the formula. The app must
  show the verified local store charge and effective saving, not present the
  formula estimate as a guaranteed charge.
- The Seeker component always costs more than the same number of Guardian
  places because £29.99 > £19.99 and both receive the same percentage.

Examples before store-price-point rounding:

| Seekers | Guardians | Saving | Formula total |
|---:|---:|---:|---:|
| 1 | 0 | 0% | £29.99 |
| 0 | 1 | 0% | £19.99 |
| 1 | 1 | 0% | £49.98 |
| 2 | 1 | 5% | £75.97 |
| 2 | 2 | 10% | £89.96 |
| 5 | 5 | 40% | £149.94 |
| 10 | 10 | 40% | £299.88 |

## 3. Trial and identity

- Seeker One's trial starts only after identity verification and payment
  authorisation both succeed.
- Trial eligibility is one per verified person for life, not one per email,
  account or device.
- Cancelling during trial keeps access through the trial end. Joining Family
  ends any unused individual trial entitlement.
- Guardian One and ZYRA Family have no trial.

## 4. Family ownership and places

- The Family owner is verified and occupies a purchased place for the role of
  the account they use. If the same person covers both roles, two places are
  required.
- Invitations require recipient consent, must match the verified role and
  expire after seven days. A member's permanent ZYRA Code does not expire.
- Added places take effect immediately with store-authoritative proration.
  Decreases/removals take effect for billing at renewal.
- A removed or leaving member loses Family association immediately but keeps
  already funded access through the renewal boundary. That funded place cannot
  be reused before then. Safety restrictions remain immediate.
- Ownership transfer is only to a verified existing Family member and becomes
  effective at renewal after the replacement owner accepts and establishes the
  replacement purchase.
- If the owner cancels, the whole Family continues to renewal, every member is
  notified and replacement coverage may begin exactly at expiry without double
  billing.

## 5. Billing lifecycle

- Individual and Family cancellation retain paid access to the confirmed
  coverage end. Refund, fraud or chargeback termination is immediate.
- Apple billing grace is 16 days for paid-to-paid renewal failure. After grace,
  paid features lock and data is preserved.
- A previous confirmed membership payer may choose Basic without another
  joining fee. Paid access still lasts through its confirmed coverage end;
  Basic access must then be confirmed through the authoritative lifecycle.
  Expiry alone proves neither previous payment nor Basic activation. Without
  confirmed membership access, only the restricted controls in §1 remain.
- Seeker expiry puts active Journeys into Membership Paused. Guardian expiry
  keeps the link inactive: an Additional Guardian loses Journey/Circle access;
  a missing paid Main Guardian creates Guardian Required and blocks active
  Journey progress until resolved.
- Immediate account deletion ends app/Family access now and does not promise a
  refund; the user must be warned that Apple billing continues until cancelled.
  Scheduled deletion at coverage end must also be offered.

## 6. Launch markets and local pricing

Phase-one markets are the UK, United States, Canada, Australia, New Zealand and
the UAE. Use country-specific purchasing-power pricing with a documented
profitability floor; do not use exchange-rate conversion alone. Wider Middle
East and global expansion follow measured launch evidence and store/legal
readiness.

## 7. Feature limits tied to paid access

- Restored Seeker Basic client boundary: one Active, ten Potential and one
  Paused Journey; five Saves; 25 active Considers; five Considers/day; 25
  committed profile swipes per four-hour window; one linked Guardian. No
  Insights or initiating Paused/Ended returns; declined/ended sections stay
  locked rather than deleting history. Existing over-cap records/links survive.
- Restored Guardian Basic: view permitted linked Journeys and Timeline; retain
  essential link, consent, Main-Guardian review and safety controls. Paid
  conversation, compatibility answering and Network access remain One features.
  Payment never creates relationship authority. Guardian Circle sending remains
  subject to its existing paid-role participant rule.
- Basic is intended to be ad-supported, but the current labelled local advert
  rehearsal is not a live ad provider or approved consent implementation.
- Seeker One: three Active Journeys, unlimited Potential Journeys, ten Paused
  Journeys, and initiation from the five most recent Paused and five most
  recent Ended Journeys.
- An Ended return creates a new Journey attempt; the old one remains ended.
- Guardian One authority remains link- and permission-based. Main Guardian has
  View and Chat for every Active Journey. Additional Guardian begins with both
  on per Active Journey; the linked Seeker may disable them and Chat requires
  View.
- Guardian Circle sending requires every current participant to hold their own
  paid role entitlement.

## 8. Activation boundary

App copy, calculations and staged database code are not purchase authority.
Public activation requires verified store products/receipts, regional prices,
the reviewed server migration, webhook lifecycle handling, restore testing and
the Founder's separate exact production migration/release approvals.
The staged paid-only server contract must be reconciled with DR-ZYRA-252 before
activation. Choosing Basic, One or Family cannot change server entitlement or
prove the £4.99 fee, trial or subscription was completed.

OA-ZYRA-253 also owns the authoritative, owner-bound previous-membership-
payment history required by the 18 October amendment. Current access,
allocated Guardian access, signup intent, compatibility credits and a client
fixture are not substitutes. The reader, restore/account replacement rules,
verified-person/role/Family attribution and treatment of refunded/charged-back
transactions must be reconciled before checkout; no unresolved case may be
guessed into a charge or waiver. This client change does not author or apply
a migration, backfill payments or expose a new live billing action.

## 9. Compatibility Unlock optional purchases

Compatibility Unlock is one optional Seeker product, separate from membership.
It includes the feature depth formerly called Compatibility Unlock Plus;
there is no separate overall-only or Plus purchase option.

| Product | Quantity | UK catalogue price |
|---|---:|---:|
| Unlocks | 1 | £2.99 |
| Unlocks | 3 | £6.99 |
| Unlocks | 5 | £9.99 |

Three singles total£8.97; the three-pack saves£1.98 (display22%), with£2.33 each rounded
to two decimals. Five singles total£14.95; the five-pack saves£4.96, or33.2%
(33% when displayed as a whole percentage), with£2.00 each rounded to two
decimals. Best value may quietly identify that pack, not a competing product
tier. Prices remain catalogue terms until
verified store-local prices and receipt authority are activated.

The former £1.99 single / £7.99 five overall-only offer is historical, as is
the separate Compatibility Unlock Plus name. Existing permanent Standard/Plus
access, stored type identifiers and balances are not rewritten or silently
converted. Existing included former Plus credits adopt the public
Compatibility Unlock name without a quantity or lifecycle change; automatic
Journey triggers are not changed by this commercial amendment.

ZYRA_PRODUCT_SPEC Part 1 section 8 owns cross-surface result and entitlement
behaviour; APP/Premium/Profile Unlocks owns its feature presentation. DR-ZYRA-250
still requires future twelve-category reduced disclosure, the saved directional
result, privacy/retention decisions and the real full-depth spending hold.
The protected six-row sample is not that production contract. The single
current manual action uses the retained Plus-compatible path; checkout and
real full-depth spending remain held under existing activation gates.
OA-ZYRA-151 owns scoped client consolidation; existing OA-ZYRA-193 scoring
and OA-ZYRA-198 migration boundaries remain separate. No migration or live
activation follows from this price/naming amendment.
