# ZYRA — Membership and Pricing

> **SUPERSEDED — 2026-09-24.** The clean controlling commercial contract is
> `ZYRA_PRICING_CURRENT_VERSION_V6.md`. This V5 file is retained as decision
> history and must not be used for product copy, billing or implementation.

> **Controlling Founder instruction — 2026-09-23 full app health check:**
> ZYRA One is £49.99/month with one Seeker and one Guardian allocation;
> ZYRA Family is **£99.99/month**; Additional Guardian is £19.99/month.
> No permanent consumer Free/Basic membership. This supersedes the variable
> Family calculator below. Family seat count, allocation mechanics, trial and
> billing activation are not defined by this price instruction and remain held.
> Client repair evidence: `SYSTEM/DOCUMENTS/ZYRA_FULL_HEALTH_CHECK_HANDOVER_CURRENT_VERSION_V1.md`.

**Version:** V5
**Status:** CURRENT_VERSION — 2026-09-21 paid-only Founder override controls; commercial activation incomplete
**Date:** 2026-09-21
**Owner / approval authority:** Founder
**Supersedes:** ZYRA_PRICING_2026-09-21_V4.md
**Decision:** DR-ZYRA-243 (supersedes DR-ZYRA-235 where inconsistent)
**Implementation actions:** OA-ZYRA-253; OA-ZYRA-293

## 0. Current paid-only override — controlling commercial truth

This section supersedes every Basic/free-plan price, allowance, advertisement
and public-offer statement later in this historical working document. Those
details remain below only as an audit trail until the next full clean version.

| Membership | Current monthly price | What it includes |
|---|---:|---|
| **ZYRA One** | **£49.99/month** | Seeker and Guardian account access for the account holder, subject to all role and relationship rules. |
| **Additional Guardian** | **£19.99/month** | One additional paid Guardian account; it creates no link or Journey authority by itself. |
| **ZYRA Family** | **£99.99/month** | Fixed monthly price; allocation and checkout remain unavailable pending defined terms. |

- ZYRA has no public free or Basic membership offer.
- ZYRA One retains the planned fourteen-day trial after verification.
- Monthly billing remains the only approved subscription period.
- The former Family discount ladder and calculator are retired by the
  23 September instruction; no seat-count promise is inferred from the price.
- Compatibility Unlock and Unlock Plus remain separate optional purchases.
- Store products, receipt verification and paid activation are not live. This
  document and the client presentation never grant an entitlement.
- Legacy Basic enums/data may remain temporarily for safe migration and
  developer boundary testing only. They are not current products.

Historical Family examples under the superseded formula: 1 ZYRA One + 1 Additional
Guardian = **£69.98/month**; 2 + 1 = **£113.97/month** after 5%; 2 + 2 =
**£125.96/month** after 10%; 5 + 5 = **£209.94/month** after 40%. Calculate in
integer pence and round the discounted total once, half up.

**2026-09-18 pricing reconciliation:** The Founder's current instruction to
check and implement the configurable Family model supersedes this document's
previous, incomplete "Family unchanged" placeholder. The agreed calculator
was recovered from the `ZYRA APP BUILD` discussion (turns
`01a0b408-16cc-79f3-bdd9-edda178383ad`,
`01a0b40b-ce65-7fa2-824b-f0057acf37c0`, and
`01a0b40f-02ee-7251-97f9-d17cd55ed160`). Older fixed-price Family examples
are historical, not current offers. The four standalone prices below remain
unchanged. This correction authorises client pricing information, not billing.

**2026-09-18 Founder allowance revision:** The later direct instruction tightens
Seeker Basic and expands One's recent-history display as recorded in §2. The
website comparison names are **ZYRA Basic** and **ZYRA One**, within a clearly
identified Seeker or Guardian view. Existing product identities and all prices
remain unchanged. This instruction is not a production migration or billing GO.

## 1. Approved membership structure

| Membership | Price | Core proposition |
|---|---:|---|
| **ZYRA One — Seeker** | **£29.99/month** | Complete premium Seeker experience, including Insights. |
| **Seeker Basic** | **£9.99 one-time** | Limited Seeker access with one Active Journey, capped discovery and adverts. |
| **ZYRA One — Guardian** | **£19.99/month** | Active Guardian participation across permitted linked-Seeker Journeys. |
| **Guardian Basic** | **£9.99 one-time** | View a linked Seeker's Journey only. |
| **ZYRA Family** | Configurable monthly total — see §1.1 | Independently choose Seeker One and Guardian One memberships, with savings capped at 40%. |

**Monthly-only billing — explicit Founder ruling, 2026-09-18:** ZYRA One
and configurable ZYRA Family have monthly subscription pricing only. There
is no yearly/annual option, annual discount, annualised monthly equivalent
or billing-period selector. The fixed role rates above and Family formula
are unchanged. This does not turn Basic's joining fee or optional
Compatibility purchases into subscriptions, remove the approved trial,
or promise a lifetime price guarantee.

Weekly plans, the former combined Seeker-plus-Guardian allocation and an
Additional Guardian subscription remain retired. Additional Guardian is a
relationship-authority role, not a payment tier.

Compatibility Unlock and Unlock Plus remain separate optional purchases at
£1.99 each or £7.99 for five, and £2.99 each or £9.99 for five respectively.
This decision does not activate their checkout.

### 1.1 Configurable ZYRA Family

- Independently choose **0–10 Seeker One** and **0–10 Guardian One**
  memberships, maximum 20 total. Either role may be zero; 0 + 0 is not a
  purchasable selection. The previous fixed five-person bundle is superseded.
- Individual monthly total: `(Seekers × £29.99) + (Guardians × £19.99)`.
- One or two memberships: **0% saving**. Three: **5%**, four: **10%**, then
  five percentage points per additional membership, reaching **40% at ten**
  and staying at 40% through twenty. The counts need not be balanced.
- Formula: `discount = min(40, max(0, (total memberships − 2) × 5))`.
- Calculate in integer pence. Round the discounted monthly total once to the
  nearest penny (half up); displayed saving is the individual total minus
  that rounded total so the figures reconcile.
- This calculator bundles **One memberships only**. The two Basic one-time
  products remain separate, not monthly seats and not included in its discount.
- Examples: 1 + 1 = **£49.98/month** (0%); 2 + 1 = **£75.97/month** (5%);
  2 + 2 = **£89.96/month** (10%); 5 + 5 = **£149.94/month** (40%);
  10 + 10 = **£299.88/month** (40%).
- The current app exposes an informational calculator only. No checkout or
  Continue action, paid activation, invitation/allocation, proration, receipt
  or server entitlement is created. Family trial and store billing details
  remain unimplemented and are not implied by the Seeker One trial.
- Paying for a membership never creates Guardian authority or overrides
  permission, consent, self-guarding or romantic exclusions.

## 2. Seeker membership allowances

The Founder's later 18 September instruction supersedes the previous Basic
25 Potential / 5 Paused / 1 Ended / 10 Saves / 50 Considers values and One's
previous 5-ended display limit. Prices and the active/swipe allowances are unchanged.

| Feature | ZYRA Basic | ZYRA One |
|---|---:|---:|
| Active Journeys | 1 | 3 |
| Potential Journeys | 10 | Unlimited |
| Paused Journeys | 1 | 10 |
| Recent ended Journeys shown | 0 — locked section | Last 10 |
| Saved profiles | 5 | 50 |
| Considers held active | 25 | Unlimited |
| Considers sent per calendar day | 5 | Unlimited |
| Recent declined profiles revisitable | 0 — locked section | Last 10 |
| Linked Guardians, including Main | 1 | 10 |
| Committed profile swipes | 25 per four-hour window | Unlimited |
| Insights | No | Included when available |
| Ad-free experience | No | Yes |

Use **Unlimited** in public comparison copy where a plan has no quota; this
never overrides safety, authorisation, privacy or abuse controls. Declines means
profiles the user declined, not private decisions by other people. Show the
existing declined-profile section on Basic with a lock and a truthful route to
membership information; do not silently remove the section or show protected rows.
Apply that presentation pattern to existing paid-only surfaces when touched,
without locking essential safety, consent, reporting or account controls.

The current concrete Guardian allowance is **1 / 10**, not zero on Basic. The
Founder also asked about a no-free-Guardian alternative; that is not an instruction
to remove Basic's one link. Wording is **Linked Guardians: 1 / 10**. Each Guardian
has a separate account/membership; link capacity is not a free paid Guardian seat.
Do not remove existing links, switch Main, revoke consent, or delete records on
downgrade; apply capacity to new additions and keep removal/safety paths available.

The advert testing cadence remains every **5 committed profile swipes**. The
Founder removed this implementation detail from the membership comparison only;
do not remove the truthful preview label from an actual non-live advert surface.

The four-hour allowance starts with the first counted swipe after the previous
window expires. A rejected action does not consume a swipe. Limits do not
delete existing Journeys, connections, Saves or account history. Recent-list
caps are display/action limits, never retention/deletion instructions. Lower
allowances must not silently destroy over-cap existing data. Server enforcement
must be reconciled before launch; client-only checks are not a security boundary.

## 3. Guardian capability boundary

**Guardian Basic observes.** It may accept and retain a valid Guardian
relationship and view the linked Seeker's permitted Journey. It has no Journey
commenting, no Journey-conversation entry and no Guardian Network page.

**ZYRA One — Guardian participates.** Subject to accepted-link, Seeker
permission, Journey privacy and Main-Guardian authority rules, it includes
Journey-wide commenting, permitted Journey-conversation entry and Guardian
Network discovery/recommendations. The present conversation surface remains
read-only; message sending and a live comment service are not inferred.

Invitation acceptance, consent, reporting, blocking, privacy and essential
safety controls remain available on Basic. Payment never creates a link,
promotes a Guardian to Main or bypasses privacy or romantic exclusions.

## 4. Trial, adverts and billing boundary

The planned fourteen-day trial remains for ZYRA One — Seeker only. The Basic
one-time fees do not start a trial. No Guardian trial, weekly plan or annual
offer is approved here.

The current app has no live StoreKit/Play purchase adapter, verified receipt
pipeline or paid-access activation. It also has no live advertising provider,
ad-unit configuration or approved advertising consent/privacy implementation.
The client therefore presents a clearly labelled advert preview for cadence
testing; it does not claim that a paid advert was served.

Device-side quota state makes the current build testable but is not a security
boundary. Production launch requires account-authoritative server enforcement
so reinstalling the app or changing devices cannot bypass limits.

## 5. Continuity

- ZYRA Family uses the configurable model in §1.1, not an old fixed price.
- Membership changes never delete Guardian relationships, Journeys, messages,
  history or configuration.
- Main/Additional Guardian authority remains separate from membership.
- Compatibility purchases and already-held rights are unchanged.
- No production migration, payment product, advertising account or TestFlight
  upload is authorised solely by this pricing decision.
