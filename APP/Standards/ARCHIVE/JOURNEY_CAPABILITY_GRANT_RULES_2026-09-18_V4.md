> **SUPERSEDED — NOT CURRENT. DO NOT USE AS A SOURCE OF TRUTH.**
> Superseded on 2026-09-18 by `JOURNEY_CAPABILITY_GRANT_RULES_2026-09-18_V5.md`.
> The current version is `JOURNEY_CAPABILITY_GRANT_RULES_CURRENT_VERSION_V7.md`, in this folder.
> This file keeps its `CURRENT_VERSION` filename deliberately. Renaming it
> would break references held in the registers and in sealed mailbox messages,
> which are never edited after filing. Recorded under **OA-AIOS-384**.
> Banner added by Fable 2026-09-23 under AD-AIOS-110. **The body below is
> unchanged** and remains the truthful record of what was current at the time.

---

# ZYRA — Journey Capability Grant Rules

**Version:** V4
**Status:** CURRENT_VERSION
**Date:** 2026-07-27
**Owner:** ZYRA Product Governance
**Supersedes:** JOURNEY_CAPABILITY_GRANT_RULES_2026-07-27_V3.md
**Governing Standards:**
  AD-081 — Capability Independence Principle
  AIOS Capability Resolution Rules V1
  SUBSCRIPTION_CONTINUITY_PRINCIPLE_CURRENT_VERSION_V1.md

Change from V3:
  — Resolves the "Subscription Transition Rules (to be specified)"
    placeholder in Entitlement Change Behaviour, below. Timing and
    in-flight-activity policy during revocation are now governed by
    SUBSCRIPTION_CONTINUITY_PRINCIPLE_CURRENT_VERSION_V1.md (DR-ZYRA-118).
  — No change to the entitlement model, capability grant model, or
    any other section — this is an additive reference, not a redesign.
  — Exact mechanics (grace period lengths, in-flight activity
    handling at the code level) remain pending until real subscription
    backend work begins (Task #20).

Change from V2:
  — Dual-source entitlement model introduced. Guardian+
    capabilities may be granted via either:
    (a) The Seeker's included entitlement (from Seeker's ZYRA One)
    (b) The Guardian's own Guardian+ subscription (£9.99/month)
  — AIOS grants identical capabilities regardless of source.
    Capability source is irrelevant once the grant is made. (AD-081)
  — Primary Guardian designation confirmed as authority only —
    no capability modifier. Supporting Guardian+ holders retain
    their capabilities independently.
  — Capability Grant Model table updated to reflect dual-source model.
  — Language Standard updated with Guardian+ terminology.

Change from V1:
  — Entitlement source changed from "linked Seeker's subscription"
    to account-level entitlement. Any account may hold ZYRA One.

---

## Purpose

This document defines how ZYRA applies AIOS capability resolution to the Guardian experience within a Journey.

This document answers: **How does ZYRA apply AIOS capability resolution?**

It does not define the Capability Independence Principle (AD-081). It does not define AIOS resolution rules (AIOS Capability Resolution Rules). It defines ZYRA's specific entitlement model and the capabilities that flow from it.

---

## Foundational Rule

A Guardian account carries identity only.

No capability tier, subscription status, or premium designation is stored on the Guardian account record. The Guardian does not become a different type of entity based on the capabilities currently granted to it. "Guardian Basic", "Guardian Premium", and "Guardian Pro" are not valid architectural descriptions of a Guardian account.

---

## Entitlement Model

ZYRA One is an account-level entitlement, purchasable by any ZYRA account holder. The account role (Seeker or Guardian), chosen at onboarding, determines how the entitlement is applied by AIOS.

Guardian+ capabilities may be granted through **either** of two sources:

| Source | Description | Cost to Guardian |
|--------|-------------|-------------|
| A — Seeker's included entitlement | Seeker holds ZYRA One; assigns their one included Guardian+ entitlement to this Guardian | None |
| B — Guardian's own subscription | Guardian independently purchases the Guardian+ subscription | £9.99/month |

**The source does not affect the capability.** Once AIOS grants the Guardian+ capability set, behaviour is identical regardless of which source applied. This is a direct application of AD-081.

```
Entitlement source (A or B)
      ↓
AIOS reads entitlement record
      ↓
AIOS resolves: Guardian+ capabilities granted
      ↓
Capability scoped to: all Journey relationships for this Guardian
Guardian account identity: unchanged
```

---

## Capability Grant Model

| Guardian's capability state | Capabilities |
|------------------------|-------------|
| Standard Guardian (no Guardian+ entitlement) | Journey observation, Family Review Period participation, safety alerts |
| Guardian+ (AIOS-granted, either source) | All standard capabilities + Guardian Network access, Family Introduction flow, profile suggestions, Guardian AI Summary |

The full capability schedule is defined in Guardian Architecture V6.

---

## Included Entitlement Rule

When a Seeker holds ZYRA One, their subscription includes **one** Guardian+ entitlement.

- Assignable to any one linked Guardian
- The included entitlement belongs to the Seeker's subscription, not permanently to one individual
- If the Seeker reassigns it, the previous holder's AIOS grant reverts to standard capabilities (unless the Guardian holds their own independent subscription)
- Reassignment timing, cooldowns, and frequency limits: pending formal specification

---

## Primary Guardian Rule

Primary Guardian is an authority designation, not a capability modifier.

- Any Guardian+ may be designated Primary for a Journey
- Primary authority may change — subscriptions and capabilities do not change with it
- Supporting Guardian+ holders retain their full Guardian+ capabilities independently of whether they hold Primary designation
- The Primary designation is per Journey, not per Seeker account

AIOS does not modify capability grants based on Primary designation. The Primary distinction is a product-level authority concept only.

---

## Relationship Scope Rule

Guardian+ capabilities granted via Source A (included entitlement) are specific to the Seeker–Guardian relationship where the entitlement is assigned.

Guardian+ capabilities granted via Source B (Guardian's own subscription) apply across all of the Guardian's Journey relationships.

**Example:**

```
Guardian Ahmed — holds own Guardian+ subscription (Source B)

  Journey A — Daughter:
    AIOS grant: Guardian+ capabilities (own subscription)

  Journey B — Son:
    AIOS grant: Guardian+ capabilities (own subscription)

  Both relationships receive Guardian+ capabilities simultaneously.
  Daughter's or Son's own entitlement does not affect Ahmed's grant.
```

```
Guardian Dad — receives Shakeel's included entitlement (Source A)

  Journey — Shakeel:
    AIOS grant: Guardian+ capabilities (included entitlement)

  If Dad is also linked to another Seeker who is on ZYRA Basic:
    Journey — Other Seeker:
      AIOS grant: Standard Guardian capabilities only
      (The included entitlement is scoped to Shakeel's relationship)
```

---

## Entitlement Change Behaviour

**Grant:** AIOS grants Guardian+ capabilities immediately when a qualifying entitlement becomes active.

**Revocation:** AIOS revokes Guardian+ capabilities when all applicable entitlement sources for a Guardian's Journey relationship become inactive.

If a Guardian loses Source A (included entitlement reassigned) but holds Source B (own subscription), capabilities are retained. Revocation only occurs when no qualifying source remains.

**Timing, grace periods, and in-flight activity during revocation** are governed at the policy level by SUBSCRIPTION_CONTINUITY_PRINCIPLE_CURRENT_VERSION_V1.md: relationships, Journey history, and configuration are never deleted or reset by a capability revocation — only currently-available capabilities change. Exact mechanics (grace period lengths, precise in-flight-activity handling at the code level) remain to be specified when real subscription backend work begins (Task #20, blocked on payment processing credentials). This replaces V3's "to be specified" placeholder with a resolved policy plus a named, scoped remainder.

---

## Language Standard

| Do not use | Use instead |
|------------|-------------|
| Guardian Premium / Guardian Pro / Guardian Basic | Standard Guardian / Guardian+ |
| Guardian account tier | Not a valid concept |
| Seeker subscription grants Guardian capabilities | Seeker's included entitlement grants Guardian+ capabilities |
| ZYRA One is a Seeker subscription | ZYRA One is an account entitlement |
| Premium Seeker / Premium Guardian | Describe by capability set, not identity label |
| Bundled Guardian capabilities | Guardian+ capabilities (AIOS-granted) |
| Primary Guardian has more capabilities | Primary Guardian has authority — capabilities are unchanged |

---

## Documents Requiring Correction

| Document | Issue |
|---------|-------|
| GUARDIAN PREMIUM/Summary.md | Predates this model |
| SUBSCRIPTION TRANSPARENCY/TRANSPARENCY_CURRENT_VERSION_V1.md | Entitlement model now dual-source |

---

## References

- AD-081 — Capability Independence Principle
- AIOS Capability Resolution Rules V1
- ZYRA Master Product Specification V3
- WALI_ARCHITECTURE_CURRENT_VERSION_V6.md
- SUBSCRIPTION_CONTINUITY_PRINCIPLE_CURRENT_VERSION_V1.md
- DR-ZYRA-118

---

*ZYRA Journey Capability Grant Rules — CURRENT_VERSION_V4 — Approved 2026-07-27*
