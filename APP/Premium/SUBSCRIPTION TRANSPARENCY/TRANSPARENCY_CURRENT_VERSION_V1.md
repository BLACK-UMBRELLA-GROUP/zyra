# ZYRA Subscription Transparency Standard
**CURRENT_VERSION_V1** | Status: Approved | Authors: Lead Architect + Architectural Reviewer

---

## Governing Question

> Was the user clearly informed of any feature prerequisites **before** making a purchase?

This standard applies to every paid feature across the platform. It is not specific to Wali Premium.

---

## The Four-Touchpoint Model

### Touchpoint 1 — Feature Comparison Screen
When users compare Basic vs Premium plans, any feature with a prerequisite must state that prerequisite clearly as a secondary line beneath the feature name — not in a footnote at the bottom of the page.

**Examples:**
- AI Journey Summaries *(Requires a linked Wali)*
- Guided Wali Conversations *(Requires a linked Wali)*
- Incoming Considerations *(Seeker Premium only)*

### Touchpoint 2 — Subscription Purchase Screen
Immediately before the purchase confirmation button, include a dependency notice with positive resolution framing.

**Example:**
> **Before you subscribe**
> Some features require a linked Wali. Once your Wali accepts their invitation, everything unlocks automatically.

The positive framing ("unlocks automatically") reduces anxiety without concealing the dependency. This is the most critical touchpoint — it appears at the moment of financial commitment.

### Touchpoint 3 — Store Listing
App Store and Google Play descriptions should include a simple disclosure statement where space allows.

**Example:**
> Certain Premium features require a linked Wali account. Features become available once linking is complete.

This touchpoint is owned by the copywriting and marketing brief.

### Touchpoint 4 — Subscription Terms & Conditions
The same dependency language must appear in the formal subscription terms.

**Example:**
> Some subscription features depend on account configuration, including linking a Wali. Features become available once those requirements have been met.

---

## Applied Examples

| Feature | Dependency | Touchpoints |
|---------|-----------|------------|
| AI Journey Summaries | Linked Premium Wali | 1, 2, 4 |
| Guided Wali Conversations | Linked Premium Wali | 1, 2, 4 |
| Incoming Considerations | Seeker Premium | 1 only |
| Family Involvement Stage | Linked Wali (any tier) | 1 |
| Wali Premium Questions | Wali Premium subscription assigned | 1, 2, 4 |

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
