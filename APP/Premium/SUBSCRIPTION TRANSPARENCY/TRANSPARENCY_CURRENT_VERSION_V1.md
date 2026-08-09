# ZYRA Subscription Transparency Standard
**CURRENT_VERSION_V1** | Status: Approved | Authors: Lead Architect + Architectural Reviewer

**Terminology corrected 2026-07-12** against
ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V5 — "Basic/Premium" tier
names and "Guardian Premium" replaced with ZYRA Basic/ZYRA One and
Guardian+. The four-touchpoint framework and design rules
below are unaffected by this correction — only the examples
used old terminology, not the standard itself.

---

## Governing Question

> Was the user clearly informed of any feature prerequisites **before** making a purchase?

This standard applies to every paid feature across the platform. It is not specific to Guardian+.

---

## The Four-Touchpoint Model

### Touchpoint 1 — Feature Comparison Screen
When users compare ZYRA Basic vs ZYRA One, any feature with a prerequisite must state that prerequisite clearly as a secondary line beneath the feature name — not in a footnote at the bottom of the page.

**Examples:**
- AI Journey Summaries *(Requires a linked Guardian)*
- Guided Guardian Conversations *(Requires a linked Guardian)*
- Incoming Potentials shown immediately *(ZYRA One only)*

### Touchpoint 2 — Subscription Purchase Screen
Immediately before the purchase confirmation button, include a dependency notice with positive resolution framing.

**Example:**
> **Before you subscribe**
> Some features require a linked Guardian. Once your Guardian accepts their invitation, everything unlocks automatically.

The positive framing ("unlocks automatically") reduces anxiety without concealing the dependency. This is the most critical touchpoint — it appears at the moment of financial commitment.

### Touchpoint 3 — Store Listing
App Store and Google Play descriptions should include a simple disclosure statement where space allows.

**Example:**
> Certain ZYRA One features require a linked Guardian account. Features become available once linking is complete.

This touchpoint is owned by the copywriting and marketing brief.

### Touchpoint 4 — Subscription Terms & Conditions
The same dependency language must appear in the formal subscription terms.

**Example:**
> Some subscription features depend on account configuration, including linking a Guardian. Features become available once those requirements have been met.

---

## Applied Examples

| Feature | Dependency | Touchpoints |
|---------|-----------|------------|
| AI Journey Summaries | Linked Guardian+ | 1, 2, 4 |
| Guided Guardian Conversations | Linked Guardian+ | 1, 2, 4 |
| Incoming Potentials shown immediately | ZYRA One | 1 only |
| Family Involvement Stage | Linked Guardian (Standard or Extended) | 1 |
| Guardian+ Questions | Guardian+ entitlement active | 1, 2, 4 |

---

## Design Rules

- Prerequisites appear **under the feature name** — never in footnotes or small print.
- Disclosure notices must include a **positive resolution statement** alongside the constraint.
- Language must be consistent across all touchpoints — no contradictions between purchase screen, T&Cs, and store listing.

---

## Related Standard

For runtime behaviour when a user encounters a dependency **after** purchase, see:
**Dependency Communication Principle** (separate document)

---

*Document status: Approved V1. Platform-wide standard.*
