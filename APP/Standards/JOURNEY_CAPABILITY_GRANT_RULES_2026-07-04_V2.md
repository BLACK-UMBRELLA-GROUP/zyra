# ZYRA — Journey Capability Grant Rules

**Version:** V2
**Status:** CURRENT_VERSION
**Date:** 2026-07-04
**Owner:** ZYRA Product Governance
**Supersedes:** JOURNEY_CAPABILITY_GRANT_RULES_2026-07-04_V1.md
**Governing Standards:**
  AD-081 — Capability Independence Principle
  AIOS Capability Resolution Rules V1

Change from V1:
  — Entitlement model revised. ZYRA One is an account-level
    entitlement, not a Seeker-specific subscription.
  — Any ZYRA account holder (Seeker or Guardian) may hold ZYRA One.
  — Entitlement source for Guardian capabilities changed from
    "linked Seeker's subscription" to "Guardian's own account
    entitlement."
  — Capability Grant Model table revised to reflect Guardian
    entitlement as the determining axis.
  — Language Standard updated to add "Seeker subscription"
    and "Seeker's subscription" to prohibited terms.

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

## Entitlement Model

ZYRA One is an account-level entitlement. It is not a Seeker subscription or a Guardian subscription. Any ZYRA account holder — whether their account operates as a Seeker or a Guardian — may hold a ZYRA One entitlement.

After onboarding, an account operates in its chosen role. AIOS resolves the capabilities granted to that account based on:
- Its account entitlement (ZYRA Basic or ZYRA One)
- Its current role (Seeker or Guardian)
- The relationship in which it is operating
- The operational context

The same ZYRA One entitlement grants different capabilities to a Seeker account than to a Guardian account. This is the expected and correct behaviour under AD-081.

```
Account entitlement (ZYRA Basic or One)
      ↓
AIOS reads entitlement record
      ↓
AIOS resolves capability grant per: role + relationship + context
      ↓
Capability grant scoped to: the operational context
Account identity: unchanged
```

---

## Entitlement Source

The entitlement source for Guardian Journey capabilities is the **Guardian's own account entitlement**.

A Guardian whose account holds ZYRA One receives extended Guardian capabilities for their Journey relationships. This is independent of the linked Seeker's entitlement.

Each Seeker's own entitlement determines that Seeker's Seeker capabilities independently.

---

## Capability Grant Model

The capabilities available to a Guardian for their Journey relationships are determined by the Guardian's own account entitlement.

| Guardian's Account Entitlement | Guardian capabilities |
|---------------------------|------------------|
| ZYRA Basic (default) | Journey observation, Family Review Period participation |
| ZYRA One | Journey observation, Family Review Period participation, Guardian Network access, Family Introduction flow, AI Guardian Summary delivery |

The full capability schedule is defined in Guardian Architecture V4. The table above states the governing rule.

---

## Relationship Scope Rule

Capability state is associated with the Guardian–Seeker Journey relationship, as resolved from the Guardian's account entitlement. The same Guardian account may hold different capability grants for different Journey relationships only if those relationships have different operational contexts.

Typically, a Guardian with ZYRA One receives the extended capability set across all their Journey relationships. A Guardian with ZYRA Basic receives standard capabilities across all their Journey relationships.

**Example:**

```
Guardian: Ahmed — holds ZYRA One

Journey Relationship A — Daughter
  AIOS grant: Guardian Network access, AI Guardian Summary delivery,
              Family Introduction flow, Review Period participation

Journey Relationship B — Son
  AIOS grant: Guardian Network access, AI Guardian Summary delivery,
              Family Introduction flow, Review Period participation

Guardian account: unchanged.
Ahmed's ZYRA One entitlement applies across all his relationships.
```

**Contrast with Seeker entitlements (independent):**

```
Ahmed's Daughter — holds ZYRA Basic
  → Daughter's Seeker capabilities: ZYRA Basic Seeker capabilities
    (no Pause, no Priority Discovery, etc.)

Ahmed's Son — holds ZYRA One
  → Son's Seeker capabilities: ZYRA One Seeker capabilities
    (Pause, Priority Discovery, Recommendations, etc.)

These are entirely independent of Ahmed's Guardian capabilities.
```

---

## Entitlement Change Behaviour

**Grant:** When a Guardian upgrades their account from ZYRA Basic to ZYRA One, AIOS automatically grants the extended Guardian capability set across all the Guardian's Journey relationships.

**Revocation:** When a Guardian's account entitlement lapses or changes to ZYRA Basic, AIOS revokes the extended Guardian capability set across all the Guardian's Journey relationships. Standard capabilities remain active.

Revocation applies simultaneously across all of the Guardian's Journey relationships, because the entitlement source is the Guardian's account, not individual relationships.

Timing, grace periods, and in-flight activity handling during revocation are defined in the Subscription Transition Rules (separate document — to be specified).

---

## Path 3 — Guardian Account Created Before Seeker Links

When a Guardian creates an account before a Seeker joins (Path 3), the Guardian's capabilities for any future Journey relationships are determined by the entitlement the Guardian holds at the time of operation.

No tier selection is required or presented during Guardian account creation. The "Choose Tier: Basic / Pro" pattern does not apply under this model.

---

## Language Standard

The following language corrections apply to all ZYRA documentation produced from this date.

| Do not use | Use instead |
|------------|-------------|
| Guardian Premium | AIOS-granted Journey capabilities |
| Guardian Pro / Guardian Basic | Guardian with ZYRA One entitlement / Guardian with ZYRA Basic |
| Guardian account tier | Not a valid concept — Guardian accounts have no tier |
| The Guardian has Premium | The Guardian holds an AIOS-granted Journey capability set |
| Bundled Guardian capabilities | Journey-level capabilities granted by AIOS |
| Seeker subscription | Account entitlement |
| Seeker's subscription grants Guardian capabilities | Guardian's own account entitlement determines Guardian capabilities |
| ZYRA One is a Seeker subscription | ZYRA One is an account entitlement |
| Guardian becomes Premium when Seeker upgrades | Guardian holds ZYRA One → AIOS grants extended Guardian capabilities |
| Premium Seeker / Premium Guardian | Not valid — describe by capability, not by identity label |

---

## Documents Requiring Correction

The following existing ZYRA documents use language inconsistent with this standard. They must be updated at their next revision.

| Document | Issue |
|---------|-------|
| GUARDIAN PREMIUM/Summary.md | Predates this model; references independent Guardian Premium tier |
| SUBSCRIPTION TRANSPARENCY/TRANSPARENCY_CURRENT_VERSION_V1.md | "Linked Premium Guardian" language; entitlement model now account-level |
| Any document referencing "Seeker's subscription" as the source of Guardian capabilities | Entitlement source is now the Guardian's own account |

---

## References

- AD-081 — Capability Independence Principle
- AIOS Capability Resolution Rules V1
- ZYRA Master Product Specification V3
- WALI_ARCHITECTURE_CURRENT_VERSION_V4.md

---

*ZYRA Journey Capability Grant Rules — CURRENT_VERSION_V2 — Approved 2026-07-04*
