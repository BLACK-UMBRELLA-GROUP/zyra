# ZYRA — Membership and Pricing

**Version:** V5
**Status:** CURRENT_VERSION — Founder-ratified model; client preview implemented; commercial activation incomplete
**Date:** 2026-09-18
**Owner / approval authority:** Founder
**Supersedes:** ZYRA_PRICING_CURRENT_VERSION_V4.md
**Decision:** DR-ZYRA-235
**Implementation actions:** OA-ZYRA-253; OA-ZYRA-293

## 1. Approved membership structure

| Membership | Price | Core proposition |
|---|---:|---|
| **ZYRA One — Seeker** | **£29.99/month** | Complete premium Seeker experience, including Insights. |
| **Seeker Basic** | **£9.99 one-time** | Limited Seeker access with one Active Journey, capped discovery and adverts. |
| **ZYRA One — Guardian** | **£19.99/month** | Active Guardian participation across permitted linked-Seeker Journeys. |
| **Guardian Basic** | **£9.99 one-time** | View a linked Seeker's Journey only. |
| **ZYRA Family** | Unchanged | Existing Family pricing and terms remain outside this change. |

Weekly plans, the former combined Seeker-plus-Guardian allocation and an
Additional Guardian subscription remain retired. Additional Guardian is a
relationship-authority role, not a payment tier.

Compatibility Unlock and Unlock Plus remain separate optional purchases at
£1.99 each or £7.99 for five, and £2.99 each or £9.99 for five respectively.
This decision does not activate their checkout.

## 2. Seeker Basic limits

Seeker Basic has all of the following limits:

- maximum **1 Active Journey**;
- maximum **50 active Likes**, displayed in the app as **Considers**;
- maximum **10 Saves**;
- maximum **5 Likes/Considers per calendar day**;
- maximum **25 committed profile swipes in each four-hour allowance window**;
- **no Insights access**; Now remains available as the notification centre;
- an advert is presented after each **5 committed profile swipes**.

The four-hour allowance starts with the first counted swipe after the previous
window expires. A rejected action does not consume a swipe. Limits do not
delete existing Journeys, connections, Saves or account history.

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

- ZYRA Family is unchanged.
- Membership changes never delete Guardian relationships, Journeys, messages,
  history or configuration.
- Main/Additional Guardian authority remains separate from membership.
- Compatibility purchases and already-held rights are unchanged.
- No production migration, payment product, advertising account or TestFlight
  upload is authorised solely by this pricing decision.
