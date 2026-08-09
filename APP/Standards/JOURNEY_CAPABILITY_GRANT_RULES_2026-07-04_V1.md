# ZYRA — Journey Capability Grant Rules

**Status:** CURRENT_VERSION_V1
**Date:** 2026-07-04
**Owner:** ZYRA Product Governance
**Governing Standards:**
  AD-081 — Capability Independence Principle
  AIOS Capability Resolution Rules V1

---

## Purpose

This document defines how ZYRA applies AIOS capability resolution to the Guardian experience within a Journey.

This document answers one question: **How does ZYRA apply AIOS capability resolution?**

It does not define the Capability Independence Principle (that is AD-081). It does not define AIOS resolution rules (that is the AIOS Capability Resolution Rules). It defines ZYRA's specific entitlement model and the capabilities that flow from it.

---

## Foundational Rule

A Guardian account carries identity only.

No capability tier, subscription status, or premium designation is stored on the Guardian account record. The Guardian does not become a different type of entity based on the capabilities currently granted to it. The terms "Guardian Basic", "Guardian Premium", and "Guardian Pro" are not valid architectural descriptions of a Guardian account. They describe capability states, not identity.

---

## Entitlement Source

In ZYRA, the entitlement source for Journey-level Guardian capabilities is the linked Seeker's active subscription.

```
Seeker subscription → entitlement record
AIOS reads entitlement record → resolves capability grant
Capability grant scoped to: the Seeker–Guardian Journey relationship
Guardian account: unchanged
```

---

## Capability Grant Model

The capabilities available to a Guardian for a given Journey are determined by the linked Seeker's entitlement at the point of resolution.

| Seeker Subscription | Guardian capabilities for this Journey |
|--------------------|-------------------------------------|
| ZYRA Basic         | Journey observation, Family Review Period participation |
| ZYRA One           | Journey observation, Family Review Period participation, Guardian Network access, Family Introduction flow, AI Guardian Summary delivery |

The full capability schedule for each tier is defined in the ZYRA Master Product Specification. The table above states the governing rule; the specification states the complete capability list.

---

## Relationship Scope Rule

Capability state is associated with the Seeker–Guardian Journey relationship, not with the Guardian account or the Seeker account.

A Guardian linked to multiple Seekers may hold different capability grants for each relationship simultaneously. AIOS evaluates each relationship independently from its own entitlement source.

**Example:**

```
Guardian: Ahmed

Journey Relationship A — Daughter (ZYRA One)
  AIOS grant: Guardian Network access, AI Guardian Summary delivery,
              Family Introduction flow, Review Period participation

Journey Relationship B — Son (ZYRA Basic)
  AIOS grant: Review Period participation only

Guardian account: unchanged across both relationships.
Ahmed is not "half Premium" or "partially Basic."
Each relationship holds its own independent capability state.
```

---

## Entitlement Source Independence

Capability grants in ZYRA currently originate from Seeker subscriptions. Future entitlement sources may include partnership agreements, scholarship memberships, sponsored memberships, or organisational accounts.

No changes to the Guardian model or the AIOS resolution rules are required when a new entitlement source is introduced. Only the entitlement record and the capability schedule require updating. The Guardian account design is unaffected.

---

## Grant and Revocation

**Grant:** When a Seeker holds an active ZYRA One subscription, AIOS grants the corresponding Journey-level capabilities to the linked Guardian for that relationship.

**Revocation:** When a Seeker's entitlement lapses or changes to ZYRA Basic, AIOS revokes the corresponding Journey-level capabilities from the affected Seeker–Guardian relationship.

Revocation applies only to the relationship whose entitlement changed. Other relationships linked to the same Guardian with independent entitlement sources are unaffected.

Timing, grace periods, and in-flight activity handling during revocation are defined in the Subscription Transition Rules (separate document — to be specified).

---

## Path 3 — Guardian Account Created Before Seeker Links

When a Guardian creates an account before a Seeker joins (Path 3), the Guardian account starts with no active capability grants.

No tier selection is required or presented during Guardian account creation. The "Choose Tier: Basic / Pro" pattern does not apply under this model.

When the Seeker subsequently links to the Guardian and holds an active ZYRA One subscription, AIOS grants the Journey-level capabilities for that relationship at the point of linking. If the Seeker is on ZYRA Basic, no extended capabilities are granted.

---

## Language Standard

The following language corrections apply to all ZYRA documentation produced from this date.

| Do not use | Use instead |
|------------|-------------|
| Guardian Premium | AIOS-granted Journey capabilities |
| Guardian Pro / Guardian Basic | Guardian (capabilities derived from Seeker entitlement) |
| Guardian account tier | Not a valid concept — Guardian accounts have no tier |
| The Guardian has Premium | The Guardian holds AIOS-granted Journey capabilities for this relationship |
| Bundled Guardian capabilities | Journey-level capabilities granted by AIOS |
| Guardian becomes Premium when Seeker upgrades | AIOS grants extended Journey capabilities when Seeker's entitlement changes to ZYRA One |
| Guardian loses Premium on downgrade | AIOS revokes Journey capabilities when Seeker's entitlement changes |

---

## Documents Requiring Correction

The following existing ZYRA documents use language inconsistent with this standard. They must be updated at their next revision.

| Document | Issue |
|---------|-------|
| WALI_ARCHITECTURE_CURRENT_VERSION_V3.md | "Guardian Tier Rules" section; "Choose Tier: Basic / Pro" in Path 3; "Guardian Basic / Guardian Pro" terminology throughout |
| GUARDIAN PREMIUM/Summary.md | Predates this model; references independent Guardian Premium tier and "Seeker Pro" |
| SUBSCRIPTION TRANSPARENCY/TRANSPARENCY_CURRENT_VERSION_V1.md | "Linked Premium Guardian" language; entitlement source is Seeker subscription, not Guardian tier |

These are scheduled corrections. This document is the governing standard from the date of registration. The documents above remain valid for their other content; only the capability language requires correction.

---

## References

- AD-081 — Capability Independence Principle
- AIOS Capability Resolution Rules V1
- ZYRA Master Product Specification V2 (capability schedule by subscription tier)
- WALI_ARCHITECTURE_CURRENT_VERSION_V3.md

---

*ZYRA Journey Capability Grant Rules — CURRENT_VERSION_V1 — Approved 2026-07-04*
