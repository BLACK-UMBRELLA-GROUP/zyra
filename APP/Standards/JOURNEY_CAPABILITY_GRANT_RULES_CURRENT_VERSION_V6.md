> **SUPERSEDED — NOT CURRENT. DO NOT USE AS A SOURCE OF TRUTH.**
> Superseded on 2026-09-18 by `JOURNEY_CAPABILITY_GRANT_RULES_CURRENT_VERSION_V7.md`, in this folder, which is current.
> This file keeps its `CURRENT_VERSION` filename deliberately. Renaming it
> would break references held in the registers and in sealed mailbox messages,
> which are never edited after filing. Recorded under **OA-AIOS-384**.
> Banner added by Fable 2026-09-23 under AD-AIOS-110. **The body below is
> unchanged** and remains the truthful record of what was current at the time.

---

# ZYRA — Journey Capability Grant Rules

**Version:** V6
**Status:** CURRENT_VERSION
**Date:** 2026-09-18
**Owner:** ZYRA Product Governance
**Supersedes:** JOURNEY_CAPABILITY_GRANT_RULES_CURRENT_VERSION_V5.md
**Decision:** DR-ZYRA-235

## Purpose

This version introduces Seeker Basic and renames Guardian Free to Guardian
Basic while preserving the separation between membership, identity,
relationships and Journey authority.

## Foundational rules

1. Main and Additional Guardian are relationship-authority roles, not payment
   tiers.
2. Membership unlocks capabilities; it never creates a link, transfers
   identity or changes Main authority.
3. Seeker and Guardian memberships are separate products.
4. A Seeker membership does not prove a linked Guardian's membership.
5. Capability loss never deletes a relationship, Journey or history.

## Seeker matrix

| State | Capabilities |
|---|---|
| **Seeker Basic** | One Active Journey; 50 active Considers; 10 Saves; 5 Considers/day; 25 profile swipes/four-hour window; Now access; no Insights; advert after each 5 swipes. |
| **ZYRA One — Seeker** | Existing premium Seeker limits and Insights; no Basic discovery advert cadence. |

The existing canonical Journey entitlement matrix remains the owner of Journey
counts: Basic allows one Active Journey and One allows three. This version does
not duplicate or loosen its server enforcement.

## Guardian matrix

| State | Capabilities |
|---|---|
| **Guardian Basic** | View a linked Seeker's permitted Journey; invitation, consent, reporting, blocking, privacy and essential safety controls. No Journey comments, Journey-conversation entry or Guardian Network page. |
| **ZYRA One — Guardian** | Guardian Basic capabilities plus Journey-wide commenting, permitted Journey-conversation entry, Guardian Network discovery and Seeker recommendations. |

All Guardian access remains subject to an accepted link, Seeker permission,
per-Journey Additional-Guardian assignment, privacy boundaries and Main-only
decisions. Paid membership does not make an Additional Guardian Main.

## Current implementation boundary

The client now distinguishes the four memberships and provides testable Basic
Seeker counters. Swipe-window and daily-Consider counters persist per account
on the device. Total Saves and Considers use the hydrated account decision
state. Client enforcement and hidden navigation are not sufficient production
security.

Production requires server-authoritative quota checks, verified purchase
entitlements, cross-device counters and server-enforced Guardian capability
boundaries. The current Guardian resolver also retains a superseded bundled
Seeker-entitlement path. The advert shown by this build is explicitly a preview
until a provider, consent/privacy model and store-compliant configuration are
approved.

## Language standard

| Retired | Current |
|---|---|
| ZYRA Basic / Access not confirmed | Seeker Basic |
| Standard Guardian / Guardian Free | Guardian Basic |
| Guardian+ / Guardian access | ZYRA One — Guardian |
| Like (member action) | Consider, with Like used only to clarify legacy/business wording |
