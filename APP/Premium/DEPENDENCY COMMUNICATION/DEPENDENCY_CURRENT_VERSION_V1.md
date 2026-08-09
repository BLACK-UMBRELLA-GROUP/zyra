# ZYRA Dependency Communication Principle
**CURRENT_VERSION_V1** | Status: Approved | Authors: Lead Architect + Architectural Reviewer

---

## Governing Question

> How should the product behave when a user encounters a feature dependency **after** purchase — at runtime?

This is a runtime UX principle, separate from the Subscription Transparency Standard which governs pre-purchase disclosure.

---

## Core Principle

Whenever a feature is unavailable because a dependency has not yet been satisfied, the interface must clearly explain:

1. **Why** the feature is not currently available.
2. **What action** is required to satisfy the dependency.
3. **That the feature is already included** in the user's plan and will become available automatically once the dependency is met.

The user must never encounter a broken state, a blank screen, or a silently disabled feature without context.

---

## Standard Message Format

> This feature is included with your subscription.
> It'll become available automatically once [dependency is satisfied].

**Examples:**

> This feature is included with your subscription.
> It'll become available automatically once your Guardian accepts their invitation.

> This feature is included with your plan.
> It becomes available when you reach the Family Involvement stage.

> This is a Premium feature.
> Upgrade to unlock it — your current journey progress won't be affected.

---

## Design Rules

- Never silently grey out or hide a feature without explanation.
- Always confirm the feature **is** included in the user's plan — do not let the interface imply they need to pay again.
- Always specify the **exact action** required, not a vague "check your settings" message.
- Where relevant, link directly to the action required (e.g., link to the Guardians tab if the dependency is a missing Guardian).

---

## Dependency Types

| Dependency Type | Example Feature | Suggested Message Trigger |
|----------------|----------------|--------------------------|
| Linked Guardian (any tier) | Family Involvement Stage | Guardian tab → no Guardian connected |
| Linked Premium Guardian | AI Journey Summaries | Guardian tab → Guardian is Basic |
| Active journey | Conversation stage features | Journeys tab → no active journey |
| Journey stage reached | Stage-specific features | Journey screen → stage not yet unlocked |
| Subscription tier | Premium-only features | Shown to Basic users |

---

## Relationship to Subscription Transparency Standard

| Standard | Governing Question | When it applies |
|----------|--------------------|----------------|
| Subscription Transparency Standard | Was the user informed before purchase? | Pre-purchase: comparison, checkout, store, T&Cs |
| Dependency Communication Principle | How does the product behave after purchase? | Runtime: when a dependency is not yet satisfied |

Both standards must be applied together. Pre-purchase disclosure reduces surprise; runtime communication resolves it when it still occurs.

---

*Document status: Approved V1. Platform-wide principle.*
