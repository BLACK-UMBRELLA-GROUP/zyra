# ZYRA — Subscription Continuity Principle

**Version:** V1
**Status:** CURRENT_VERSION
**Date:** 2026-07-27
**Owner:** ZYRA Product Governance
**Supersedes:** None (new document)
**Governing Standards:**
  DR-ZYRA-118 — Subscription Continuity Ratified as Product Principle
  JOURNEY_CAPABILITY_GRANT_RULES_CURRENT_VERSION_V4.md

---

## Purpose

This document defines Subscription Continuity: a cross-cutting product principle governing what happens to relationships, history, and configuration when a subscription's state changes.

It does not define entitlement resolution mechanics (see JOURNEY_CAPABILITY_GRANT_RULES) or AIOS capability resolution (AD-081, AIOS Capability Resolution Rules). It defines what must NOT change when a subscription changes.

---

## The Principle

> Subscriptions determine access to capabilities, not ownership of relationships or data.

A subscription unlocks currently-available capabilities. It is not a container that owns the relationships, history, or configuration built while it was active. When entitlement changes hands, lapses, or is replaced, the relationship it enabled does not disappear — only what can currently be done with it changes.

---

## Scope

This principle applies to every named subscription-state transition:

| Transition | Meaning |
|---|---|
| Expiry | Subscription lapses at end of billing period, not renewed |
| Cancellation | Holder actively cancels before period end |
| Payer change | A different account/person takes over paying for the same entitlement |
| Upgrade | Holder moves to a higher entitlement tier |
| Downgrade | Holder moves to a lower entitlement tier |
| Temporary lapse | Payment failure or other transient gap, later resolved |

It applies consistently across both the Seeker and Guardian experiences. It is not to be implemented differently for each — one rule, two applications.

---

## What Persists (unconditionally)

Regardless of any transition above, the following are never deleted, reset, or altered as a side effect of a subscription change:

| Preserved | Examples |
|---|---|
| Relationships | wali_links, Seeker–Guardian connections, Guardian Network entries |
| History | Journey Timeline, conversation history, match history |
| Configuration | Notification preferences, Primary Guardian designation, saved filters/settings |

Only currently-available capabilities change. The underlying data and relationships are entitlement-blind.

---

## Worked Example

```
Niece holds ZYRA One, purchases Guardian+ for her uncle (Source A,
included entitlement) → uncle becomes her Guardian, Journey begins,
relationship history accumulates over time.

Niece's ZYRA One lapses (stops paying) →
  AIOS revokes the included Guardian+ entitlement (per JOURNEY_
  CAPABILITY_GRANT_RULES Entitlement Change Behaviour)
  → Uncle's capabilities drop to Standard Guardian.
  → Relationship, Journey Timeline, history, and configuration:
    UNCHANGED. Nothing is deleted or reset.

Uncle purchases Guardian+ directly (Source B, own subscription) →
  AIOS grants Guardian+ capabilities again, same Journey, same
  relationship, same history — continuing exactly where it left
  off. No re-linking, no data migration, no new relationship
  record.
```

This is the concrete case that established the principle (see DR-ZYRA-118).

---

## Relationship to Entitlement Resolution

This principle governs what persists. JOURNEY_CAPABILITY_GRANT_RULES governs what capabilities are currently granted, and by which source. The two are deliberately separate concerns:

- Entitlement resolution answers: "What can this account do right now?"
- Subscription Continuity answers: "What still exists regardless of the answer to that question?"

JOURNEY_CAPABILITY_GRANT_RULES_CURRENT_VERSION_V4.md's Entitlement Change Behaviour section defers exact timing, grace periods, and in-flight-activity handling during revocation to this principle at the policy level. The precise mechanics (grace period lengths, in-flight activity handling) remain to be specified when real subscription backend work begins (see Task #20 — blocked on payment processing credentials).

---

## What This Principle Does NOT Cover

- Billing mechanics — how or when a payment is actually charged, prorated, or refunded (payment-provider concern: Stripe/RevenueCat).
- Whether multiple subscriptions can be billed together on one renewal date (see Co-Termed Billing — parked, OA-ZYRA-144).
- Multi-role or multi-account architecture (separate, unresolved discussion — see CHATGPT_REPLY_MULTIROLE_ACCOUNTS_2026-07-27.md).

---

## Language Standard

| Do not use | Use instead |
|---|---|
| "Losing the subscription loses the Guardian" | "Losing the subscription loses Guardian+ capabilities; the Guardian relationship continues" |
| "Re-link the Guardian" (after a payer change) | "Re-establish entitlement" — no new relationship record is created |
| "Subscription owns the relationship" | "Subscription determines capability access to the relationship" |

---

## References

- DR-ZYRA-118 — ratifying decision
- JOURNEY_CAPABILITY_GRANT_RULES_CURRENT_VERSION_V4.md
- WALI_ARCHITECTURE_CURRENT_VERSION_V6.md
- SYSTEM/RESOURCES/TEMPORARY/CHATGPT_REPLY_MULTIROLE_ACCOUNTS_2026-07-27.md (origin discussion)

---

*ZYRA Subscription Continuity Principle — CURRENT_VERSION_V1 — Approved 2026-07-27*
