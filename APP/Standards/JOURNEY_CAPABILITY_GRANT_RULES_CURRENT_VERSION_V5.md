> **SUPERSEDED — NOT CURRENT. DO NOT USE AS A SOURCE OF TRUTH.**
> Superseded on 2026-09-18 by `JOURNEY_CAPABILITY_GRANT_RULES_CURRENT_VERSION_V6.md`.
> The current version is `JOURNEY_CAPABILITY_GRANT_RULES_CURRENT_VERSION_V7.md`, in this folder.
> This file keeps its `CURRENT_VERSION` filename deliberately. Renaming it
> would break references held in the registers and in sealed mailbox messages,
> which are never edited after filing. Recorded under **OA-AIOS-384**.
> Banner added by Fable 2026-09-23 under AD-AIOS-110. **The body below is
> unchanged** and remains the truthful record of what was current at the time.

---

# ZYRA — Journey Capability Grant Rules

**Version:** V5
**Status:** CURRENT_VERSION
**Date:** 2026-09-18
**Owner:** ZYRA Product Governance
**Supersedes:** JOURNEY_CAPABILITY_GRANT_RULES_CURRENT_VERSION_V4.md
**Decision:** DR-ZYRA-234

## Purpose

This version aligns Guardian capabilities with the separate Guardian Free and
ZYRA One — Guardian memberships. It supersedes V4's bundled Guardian+
entitlement and independent Additional Guardian subscription model.

## Foundational rules

1. Main and Additional Guardian are relationship-authority roles, not payment
   tiers.
2. Membership unlocks capabilities; it never creates a link, transfers identity
   or changes Main authority.
3. ZYRA One — Seeker and ZYRA One — Guardian are separate memberships.
4. A Seeker membership does not itself prove a linked Guardian's paid
   entitlement. ZYRA Family remains unchanged and is resolved under its own
   existing terms.
5. Subscription continuity remains controlling: capability loss never deletes
   the relationship, Journey or history.

## Capability matrix

| Guardian state | Capabilities |
|---|---|
| **Guardian Free** | View a linked Seeker's permitted Journey; invitation, consent, reporting, blocking, privacy and essential safety controls. No Journey comments, no Journey-conversation entry and no Guardian Network page. |
| **ZYRA One — Guardian** | Guardian Free capabilities plus Journey-wide commenting, entry to permitted Journey conversations, Guardian Network discovery and Seeker recommendations. |

All access remains subject to an accepted link, Seeker permission,
per-Journey Additional-Guardian assignment, privacy boundaries and Main-only
decisions. Paid membership does not give an Additional Guardian Main authority.

The current conversation surface is read-only. This decision does not create
Guardian message sending. Journey-wide comments require a future governed
server implementation before they can be activated in production.

## Current implementation boundary

The client may fail closed by hiding paid navigation and conversation surfaces
when paid entitlement is absent. That presentation is not sufficient security.
The current `wali_has_wali_one()` resolver still carries the superseded bundled
Seeker-entitlement path and returns a boolean that conflates denial with fetch
failure. It must be replaced by an authoritative paid-Guardian resolver before
live commercial activation, with matching server enforcement for comments,
conversation entry and Guardian Network.

## Language standard

| Retired | Current |
|---|---|
| Standard Guardian | Guardian Free |
| Guardian+ / Guardian access | ZYRA One — Guardian |
| Additional Guardian subscription | ZYRA One — Guardian membership |
| ZYRA One includes a Guardian allocation | ZYRA One — Seeker and ZYRA One — Guardian are separate memberships |
