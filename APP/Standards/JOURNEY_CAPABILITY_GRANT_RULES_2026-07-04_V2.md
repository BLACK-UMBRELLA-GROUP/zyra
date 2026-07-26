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
  — Any ZYRA account holder (Seeker or Wali) may hold ZYRA One.
  — Entitlement source for Wali capabilities changed from
    "linked Seeker's subscription" to "Wali's own account
    entitlement."
  — Capability Grant Model table revised to reflect Wali
    entitlement as the determining axis.
  — Language Standard updated to add "Seeker subscription"
    and "Seeker's subscription" to prohibited terms.

---

## Purpose

This document defines how ZYRA applies AIOS capability resolution to the Wali experience within a Journey.

This document answers one question: **How does ZYRA apply AIOS capability resolution?**

It does not define the Capability Independence Principle (that is AD-081). It does not define AIOS resolution rules (that is the AIOS Capability Resolution Rules). It defines ZYRA's specific entitlement model and the capabilities that flow from it.

---

## Foundational Rule

A Wali account carries identity only.

No capability tier, subscription status, or premium designation is stored on the Wali account record. The Wali does not become a different type of entity based on the capabilities currently granted to it. The terms "Wali Basic", "Wali Premium", and "Wali Pro" are not valid architectural descriptions of a Wali account. They describe capability states, not identity.

---

## Entitlement Model

ZYRA One is an account-level entitlement. It is not a Seeker subscription or a Wali subscription. Any ZYRA account holder — whether their account operates as a Seeker or a Wali — may hold a ZYRA One entitlement.

After onboarding, an account operates in its chosen role. AIOS resolves the capabilities granted to that account based on:
- Its account entitlement (ZYRA Basic or ZYRA One)
- Its current role (Seeker or Wali)
- The relationship in which it is operating
- The operational context

The same ZYRA One entitlement grants different capabilities to a Seeker account than to a Wali account. This is the expected and correct behaviour under AD-081.

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

The entitlement source for Wali Journey capabilities is the **Wali's own account entitlement**.

A Wali whose account holds ZYRA One receives extended Wali capabilities for their Journey relationships. This is independent of the linked Seeker's entitlement.

Each Seeker's own entitlement determines that Seeker's Seeker capabilities independently.

---

## Capability Grant Model

The capabilities available to a Wali for their Journey relationships are determined by the Wali's own account entitlement.

| Wali's Account Entitlement | Wali capabilities |
|---------------------------|------------------|
| ZYRA Basic (default) | Journey observation, Family Review Period participation |
| ZYRA One | Journey observation, Family Review Period participation, Wali Network access, Family Introduction flow, AI Wali Summary delivery |

The full capability schedule is defined in Wali Architecture V4. The table above states the governing rule.

---

## Relationship Scope Rule

Capability state is associated with the Wali–Seeker Journey relationship, as resolved from the Wali's account entitlement. The same Wali account may hold different capability grants for different Journey relationships only if those relationships have different operational contexts.

Typically, a Wali with ZYRA One receives the extended capability set across all their Journey relationships. A Wali with ZYRA Basic receives standard capabilities across all their Journey relationships.

**Example:**

```
Wali: Ahmed — holds ZYRA One

Journey Relationship A — Daughter
  AIOS grant: Wali Network access, AI Wali Summary delivery,
              Family Introduction flow, Review Period participation

Journey Relationship B — Son
  AIOS grant: Wali Network access, AI Wali Summary delivery,
              Family Introduction flow, Review Period participation

Wali account: unchanged.
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

These are entirely independent of Ahmed's Wali capabilities.
```

---

## Entitlement Change Behaviour

**Grant:** When a Wali upgrades their account from ZYRA Basic to ZYRA One, AIOS automatically grants the extended Wali capability set across all the Wali's Journey relationships.

**Revocation:** When a Wali's account entitlement lapses or changes to ZYRA Basic, AIOS revokes the extended Wali capability set across all the Wali's Journey relationships. Standard capabilities remain active.

Revocation applies simultaneously across all of the Wali's Journey relationships, because the entitlement source is the Wali's account, not individual relationships.

Timing, grace periods, and in-flight activity handling during revocation are defined in the Subscription Transition Rules (separate document — to be specified).

---

## Path 3 — Wali Account Created Before Seeker Links

When a Wali creates an account before a Seeker joins (Path 3), the Wali's capabilities for any future Journey relationships are determined by the entitlement the Wali holds at the time of operation.

No tier selection is required or presented during Wali account creation. The "Choose Tier: Basic / Pro" pattern does not apply under this model.

---

## Language Standard

The following language corrections apply to all ZYRA documentation produced from this date.

| Do not use | Use instead |
|------------|-------------|
| Wali Premium | AIOS-granted Journey capabilities |
| Wali Pro / Wali Basic | Wali with ZYRA One entitlement / Wali with ZYRA Basic |
| Wali account tier | Not a valid concept — Wali accounts have no tier |
| The Wali has Premium | The Wali holds an AIOS-granted Journey capability set |
| Bundled Wali capabilities | Journey-level capabilities granted by AIOS |
| Seeker subscription | Account entitlement |
| Seeker's subscription grants Wali capabilities | Wali's own account entitlement determines Wali capabilities |
| ZYRA One is a Seeker subscription | ZYRA One is an account entitlement |
| Wali becomes Premium when Seeker upgrades | Wali holds ZYRA One → AIOS grants extended Wali capabilities |
| Premium Seeker / Premium Wali | Not valid — describe by capability, not by identity label |

---

## Documents Requiring Correction

The following existing ZYRA documents use language inconsistent with this standard. They must be updated at their next revision.

| Document | Issue |
|---------|-------|
| WALI PREMIUM/Summary.md | Predates this model; references independent Wali Premium tier |
| SUBSCRIPTION TRANSPARENCY/TRANSPARENCY_CURRENT_VERSION_V1.md | "Linked Premium Wali" language; entitlement model now account-level |
| Any document referencing "Seeker's subscription" as the source of Wali capabilities | Entitlement source is now the Wali's own account |

---

## References

- AD-081 — Capability Independence Principle
- AIOS Capability Resolution Rules V1
- ZYRA Master Product Specification V3
- WALI_ARCHITECTURE_CURRENT_VERSION_V4.md

---

*ZYRA Journey Capability Grant Rules — CURRENT_VERSION_V2 — Approved 2026-07-04*
