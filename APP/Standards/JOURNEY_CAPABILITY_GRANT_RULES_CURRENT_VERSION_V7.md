# ZYRA — Journey Capability Grant Rules

> **2026-10-20 controlling amendment — Founder direct instruction and reply:**
> Additional Guardian Basic is View-only: View remains Seeker-controlled and
> there is no Chat column/control for a known Basic Guardian. For NEW Journeys
> only, a linked paid Additional Guardian has fixed View and plan-enabled Chat
> after the Seeker explicitly agrees for that new Journey. The Founder chose
> “Only new Journeys after the Seeker agrees,” not retroactive access. Existing
> Journey permissions remain unchanged; upgrading alone never unlocks old chats.
> Paid is not Main authority and does not bypass an accepted link, lifecycle,
> blocking, conversation eligibility, private-answer or Network/photo consent.
> Plan loss/unlink revoke eligibility; upgrading does not silently restore it.
> The protected local preview must record exact per-Journey agreement before
> deliberate Begin. Live attempt-bound consent, both-participant disclosure,
> verified entitlement and server/RLS enforcement remain HELD under OA296/305;
> this instruction does not deploy those producers or mutate live permissions.
> This amends the blanket Additional toggles below only for explicitly agreed
> new Journeys. Legacy/unagreed Journey rows retain their existing controls.

> **2026-10-03 controlling amendment — DR-ZYRA-252:** Basic returns at £4.99
> once, not £0, with its last pre-retirement client boundary. The commercial
> source owns the prices and current limits. The corrected Basic quantities
> below replace the older 50-Consider/10-Save wording. Membership selection is
> private intent, not funded access. Main authority, relationship/privacy and
> safety controls remain independent; store/receipt/server activation is held.

**Version:** V7
**Status:** CURRENT_VERSION
**Date:** 2026-09-18
**Owner:** ZYRA Product Governance
**Supersedes:** JOURNEY_CAPABILITY_GRANT_RULES_2026-09-18_V6.md
**Decisions:** DR-ZYRA-235; DR-ZYRA-238

## Purpose

This version preserves the four membership products and Basic limits while
clarifying that Guardian membership creates capability eligibility, not
guaranteed Journey access. Additional-Guardian View and Chat are separate
Seeker-owned permissions; Main Guardian access remains protected.

## Foundational rules

1. Main and Additional Guardian are relationship-authority roles, not payment
   tiers.
2. Membership unlocks capability eligibility; it never creates a link,
   transfers identity or independently grants Journey authority.
3. Seeker and Guardian memberships are separate products.
4. A Seeker membership does not prove a linked Guardian's membership.
5. Capability loss never deletes a relationship, Journey or history.
6. Client visibility is not authority. Live access must be server-confirmed
   and enforced at every data boundary.

## Seeker matrix

| State | Capabilities |
|---|---|
| **Seeker Basic** | One Active / ten Potential / one Paused Journey; 25 active Considers; 5 Saves; 5 Considers/day; 25 profile swipes/four-hour window; one linked Guardian; Now access; no Insights or initiating history returns. Adverts remain non-live. |
| **ZYRA One — Seeker** | Existing premium Seeker limits and Insights; no Basic discovery advert cadence. |

The canonical Journey entitlement matrix owns Journey counts: Basic allows one
Active Journey and One allows three. This document does not duplicate or
loosen server enforcement.

## Guardian matrix

| State | Capabilities |
|---|---|
| **Guardian Basic** | Eligible to view a linked Seeker's permitted Journey; invitation, consent, reporting, blocking, privacy and essential safety controls. No Journey comments, Journey-conversation entry or Guardian Network page. |
| **ZYRA One — Guardian** | Guardian Basic capabilities plus eligibility for Journey-wide commenting, permitted Journey-conversation entry, Guardian Network discovery and Seeker recommendations. |

All Guardian access remains subject to an accepted link, Guardian membership,
Seeker permission, Journey state, privacy boundaries and Main-only decisions.
Paid membership does not make an Additional Guardian Main and does not
guarantee access to a Journey.

## View and Chat authority

1. For every active Journey, the Seeker controls View and Chat separately for
   each own Additional Guardian.
2. Chat depends on View. View OFF atomically means Chat OFF; Chat cannot be ON
   while View is OFF.
3. Guardian Basic is never Chat-eligible. ZYRA One — Guardian makes Chat
   eligible but the Seeker still decides whether an Additional Guardian may
   enter that Journey's conversation.
4. A current Main Guardian's View and plan-enabled Chat cannot be switched off
   while they remain Main.
5. Removing someone as Main changes the relationship-authority role; it is not
   a hidden permission toggle and follows its own governed confirmation flow.
6. These limits must be disclosed before purchase, when linking and wherever
   access is managed in-product.

## Current implementation boundary

The client distinguishes the four memberships and provides testable Basic
Seeker counters. It also previews separate Additional-Guardian View and Chat
controls: View OFF clears and disables Chat, while Main renders both protected
permissions as Required.

The live server currently stores one combined Additional-Guardian Journey
inclusion decision. Separate live Chat authority, verified membership
eligibility and conversation/message RLS enforcement remain OA-ZYRA-296 work.
Until that closes, the client must not present local Chat state as a live
server-confirmed permission.

Production also requires server-authoritative Basic quotas, verified purchase
entitlements, cross-device counters and an approved advertising provider,
privacy and consent model.

## Language standard

| Retired or misleading | Current |
|---|---|
| Calling a default/legacy Basic enum a confirmed purchase | No active membership; use Seeker Basic only for confirmed access or a labelled protected sample |
| Standard Guardian / Guardian Free | Guardian Basic |
| Guardian+ / Guardian access | ZYRA One — Guardian |
| Chat included | Chat eligible; Seeker permission required for Additional Guardian |
| Like (member action) | Consider, with Like used only to clarify legacy/business wording |
