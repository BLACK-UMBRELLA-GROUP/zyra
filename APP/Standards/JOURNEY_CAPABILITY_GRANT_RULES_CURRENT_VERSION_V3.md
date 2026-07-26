# ZYRA — Journey Capability Grant Rules

**Version:** V3
**Status:** CURRENT_VERSION
**Date:** 2026-07-04
**Owner:** ZYRA Product Governance
**Supersedes:** JOURNEY_CAPABILITY_GRANT_RULES_2026-07-04_V2.md
**Governing Standards:**
  AD-081 — Capability Independence Principle
  AIOS Capability Resolution Rules V1

Change from V2:
  — Dual-source entitlement model introduced. Extended Wali
    capabilities may be granted via either:
    (a) The Seeker's included entitlement (from Seeker's ZYRA One)
    (b) The Wali's own Extended Wali subscription (£9.99/month)
  — AIOS grants identical capabilities regardless of source.
    Capability source is irrelevant once the grant is made. (AD-081)
  — Primary Wali designation confirmed as authority only —
    no capability modifier. Supporting Extended Walis retain
    their capabilities independently.
  — Capability Grant Model table updated to reflect dual-source model.
  — Language Standard updated with Extended Wali terminology.

Change from V1:
  — Entitlement source changed from "linked Seeker's subscription"
    to account-level entitlement. Any account may hold ZYRA One.

---

## Purpose

This document defines how ZYRA applies AIOS capability resolution to the Wali experience within a Journey.

This document answers: **How does ZYRA apply AIOS capability resolution?**

It does not define the Capability Independence Principle (AD-081). It does not define AIOS resolution rules (AIOS Capability Resolution Rules). It defines ZYRA's specific entitlement model and the capabilities that flow from it.

---

## Foundational Rule

A Wali account carries identity only.

No capability tier, subscription status, or premium designation is stored on the Wali account record. The Wali does not become a different type of entity based on the capabilities currently granted to it. "Wali Basic", "Wali Premium", and "Wali Pro" are not valid architectural descriptions of a Wali account.

---

## Entitlement Model

ZYRA One is an account-level entitlement, purchasable by any ZYRA account holder. The account role (Seeker or Wali), chosen at onboarding, determines how the entitlement is applied by AIOS.

Extended Wali capabilities may be granted through **either** of two sources:

| Source | Description | Cost to Wali |
|--------|-------------|-------------|
| A — Seeker's included entitlement | Seeker holds ZYRA One; assigns their one included Extended Wali entitlement to this Wali | None |
| B — Wali's own subscription | Wali independently purchases the Extended Wali subscription | £9.99/month |

**The source does not affect the capability.** Once AIOS grants the Extended Wali capability set, behaviour is identical regardless of which source applied. This is a direct application of AD-081.

```
Entitlement source (A or B)
      ↓
AIOS reads entitlement record
      ↓
AIOS resolves: Extended Wali capabilities granted
      ↓
Capability scoped to: all Journey relationships for this Wali
Wali account identity: unchanged
```

---

## Capability Grant Model

| Wali's capability state | Capabilities |
|------------------------|-------------|
| Standard Wali (no Extended entitlement) | Journey observation, Family Review Period participation, safety alerts |
| Extended Wali (AIOS-granted, either source) | All standard capabilities + Wali Network access, Family Introduction flow, profile suggestions, Wali AI Summary |

The full capability schedule is defined in Wali Architecture V5.

---

## Included Entitlement Rule

When a Seeker holds ZYRA One, their subscription includes **one** Extended Wali entitlement.

- Assignable to any one linked Wali
- The included entitlement belongs to the Seeker's subscription, not permanently to one individual
- If the Seeker reassigns it, the previous holder's AIOS grant reverts to standard capabilities (unless the Wali holds their own independent subscription)
- Reassignment timing, cooldowns, and frequency limits: pending formal specification

---

## Primary Wali Rule

Primary Wali is an authority designation, not a capability modifier.

- Any Extended Wali may be designated Primary for a Journey
- Primary authority may change — subscriptions and capabilities do not change with it
- Supporting Extended Walis retain their full Extended Wali capabilities independently of whether they hold Primary designation
- The Primary designation is per Journey, not per Seeker account

AIOS does not modify capability grants based on Primary designation. The Primary distinction is a product-level authority concept only.

---

## Relationship Scope Rule

Extended Wali capabilities granted via Source A (included entitlement) are specific to the Seeker–Wali relationship where the entitlement is assigned.

Extended Wali capabilities granted via Source B (Wali's own subscription) apply across all of the Wali's Journey relationships.

**Example:**

```
Wali Ahmed — holds own Extended Wali subscription (Source B)

  Journey A — Daughter:
    AIOS grant: Extended Wali capabilities (own subscription)

  Journey B — Son:
    AIOS grant: Extended Wali capabilities (own subscription)

  Both relationships receive Extended capabilities simultaneously.
  Daughter's or Son's own entitlement does not affect Ahmed's grant.
```

```
Wali Dad — receives Shakeel's included entitlement (Source A)

  Journey — Shakeel:
    AIOS grant: Extended Wali capabilities (included entitlement)

  If Dad is also linked to another Seeker who is on ZYRA Basic:
    Journey — Other Seeker:
      AIOS grant: Standard Wali capabilities only
      (The included entitlement is scoped to Shakeel's relationship)
```

---

## Entitlement Change Behaviour

**Grant:** AIOS grants Extended Wali capabilities immediately when a qualifying entitlement becomes active.

**Revocation:** AIOS revokes Extended Wali capabilities when all applicable entitlement sources for a Wali's Journey relationship become inactive.

If a Wali loses Source A (included entitlement reassigned) but holds Source B (own subscription), capabilities are retained. Revocation only occurs when no qualifying source remains.

Timing, grace periods, and in-flight activity during revocation: defined in Subscription Transition Rules (to be specified).

---

## Language Standard

| Do not use | Use instead |
|------------|-------------|
| Wali Premium / Wali Pro / Wali Basic | Standard Wali / Extended Wali |
| Wali account tier | Not a valid concept |
| Seeker subscription grants Wali capabilities | Seeker's included entitlement grants Wali Extended capabilities |
| ZYRA One is a Seeker subscription | ZYRA One is an account entitlement |
| Premium Seeker / Premium Wali | Describe by capability set, not identity label |
| Bundled Wali capabilities | Extended Wali capabilities (AIOS-granted) |
| Primary Wali has more capabilities | Primary Wali has authority — capabilities are unchanged |

---

## Documents Requiring Correction

| Document | Issue |
|---------|-------|
| WALI PREMIUM/Summary.md | Predates this model |
| SUBSCRIPTION TRANSPARENCY/TRANSPARENCY_CURRENT_VERSION_V1.md | Entitlement model now dual-source |

---

## References

- AD-081 — Capability Independence Principle
- AIOS Capability Resolution Rules V1
- ZYRA Master Product Specification V3
- WALI_ARCHITECTURE_CURRENT_VERSION_V5.md

---

*ZYRA Journey Capability Grant Rules — CURRENT_VERSION_V3 — Approved 2026-07-04*
