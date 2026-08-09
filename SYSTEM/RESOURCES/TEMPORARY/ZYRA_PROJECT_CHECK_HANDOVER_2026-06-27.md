# ZYRA PROJECT CHECK — ARCHITECTURAL HANDOVER

**To:** Architectural Reviewer (ChatGPT)
**From:** Lead Architect (Claude)
**Date:** 2026-06-27
**Re:** ZYRA Project Check — Issues 1–7 for Review and Resolution

---

## CONTEXT

A Project Check was run against ZYRA today (2026-06-27).
Project Check = architectural quality review. Governing question:
"Is this project internally correct?"

Seven issues were identified. None are operational — all are
contradictions, terminology conflicts, or unresolved decisions
between ZYRA's documents.

The Project Owner (Shakeel) will liaise with you directly.
This handover gives you the full context for each issue.

---

## DOCUMENT REFERENCE MAP

| Document | Role | Status |
|---|---|---|
| ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V2.md | Master product specification | Approved — source of truth |
| ZYRA_ARCHITECTURE_CURRENT_VERSION_V2.md | Technical architecture | Approved |
| ZYRA_DATABASE_SCHEMA_CURRENT_VERSION_V1.md | Database schema | Approved — awaiting Supabase setup |
| APP/Matching/PROFILE DECISION SYSTEM/Summary.md | Feature spec | Stale — pre-dates Product Spec V2 |
| APP/Premium/GUARDIAN PREMIUM/Summary.md | Feature spec | Stale — pre-dates Product Spec V2 |
| APP/Matches/MATCHES PAGE/Summary.md | Feature spec | Partially stale |
| SYSTEM/DOCUMENTS/TERMINOLOGY_STANDARDS_V1.md | Approved vocabulary | Needs audit against Product Spec V2 |

---

## ISSUE 1 — Subscription Model Conflict
**Severity: Critical**

**What Product Spec V2 says:**
ZYRA has a 2-tier subscription model:
- Seeker Basic (Free) / Seeker Premium (£19.99/month)
- Guardian Basic (Free) / Guardian Premium (£9.99/month)

Product Spec V2 explicitly states:
> "The previous three-tier structure (Basic / Pro / Premium)
> has been removed in favour of a simpler Basic and Premium model."

**What the APP folders still say:**
- PROFILE DECISION SYSTEM Summary references: Seeker Basic, Seeker Pro,
  Seeker Premium as three separate tiers
- GUARDIAN PREMIUM Summary references: Guardian, Guardian Pro, Guardian Gold as
  the Guardian subscription names

**The conflict:**
The approved subscription model has 4 plans (2 Seeker + 2 Guardian).
Multiple feature documents still describe 6 plans across 3 tiers.
Any feature built from the APP folder Summaries will implement
the wrong subscription model.

**What needs resolving:**
Confirm Product Spec V2 is the approved model (2-tier).
Once confirmed, Lead Architect will update all affected APP
folder Summaries to remove all Pro tier references.

---

## ISSUE 2 — Terminology Conflict: Save/Like vs Review/Consider
**Severity: Critical**

**What Product Spec V2 uses:**
- **Save** — private action. "I want to come back to this profile."
  Does not indicate romantic interest. Only mutual saves (Premium)
  generate a notification.
- **Like** — interest signal. "I want to pursue this person."
  Mutual Likes create a Match.

**What APP folder PROFILE DECISION SYSTEM Summary uses:**
- **Review** — "I would like to review this profile later."
  (Private. 50 profile limit. No match intent.)
- **Consider** — "This profile may be suitable for marriage
  consideration." (Match intent. Mutual Consideration creates a Match.)

**The conflict:**
Two different vocabulary sets exist for what appear to be the
same two concepts. No document bridges them. Terminology
Standards V1 has not been audited — it may also use the old terms.

This is not just a naming issue. If Save ≠ Review or Like ≠ Consider,
then the concepts themselves differ — and both the database schema
and the feature specs describe different products.

**What needs resolving:**
Are Save/Like (Product Spec V2) the approved terms, replacing
Review/Consider? Or are these genuinely different actions?
This decision cascades into Issues 3 and 4.

---

## ISSUE 3 — Match Creation Rule Conflict
**Severity: Critical (resolves with Issue 2)**

**Database schema (built to Product Spec V2):**
A Match is created when two Seekers have both sent a **Like**
to each other.

**PROFILE DECISION SYSTEM Summary:**
A Match is created when two Seekers have both **Considered**
each other (Mutual Consideration).

**The conflict:**
If Like and Consider are the same action under different names
(which is the probable interpretation), this resolves automatically
once Issue 2 is settled and the APP folder is updated.

If Like and Consider are architecturally distinct actions, the
database schema is built to the wrong rule and must be revised
before implementation.

**What needs resolving:**
Resolves with Issue 2. No separate decision required unless
Consider and Like are confirmed as different actions.

---

## ISSUE 4 — Basic Seeker Match Intent Access
**Severity: High**

**What Product Spec V2 says:**
Seeker Basic can Like up to 10 profiles per day (match-intent action).
Basic Seekers can initiate match intent on the free plan.

**What PROFILE DECISION SYSTEM Summary says:**
Seeker Basic: Decline and Review only.
Consider (match-intent) is Pro and above only.
Basic Seekers cannot initiate a match.

**The conflict:**
This is a fundamental business rule disagreement, not a terminology
issue. Under the old model, Basic Seekers cannot create matches.
Under the new model, they can. This affects the entire matching
funnel, conversion strategy, and monetisation model.

**What needs resolving:**
Can Basic Seekers Like (initiate match intent) on the free plan?
Product Spec V2 says yes. Needs explicit confirmation before any
matching feature is implemented.

---

## ISSUE 5 — Connector User Role Undefined
**Severity: High**

**What Architecture V2 says:**
Three user roles: Seeker, Guardian, and Connector (Introduces Seekers,
limited profile access).

**What Product Spec V2 says:**
Two user roles: Seeker and Guardian. Connector does not appear.

**The conflict:**
A user role is defined in the architecture with no product
specification, no feature scope, and no subscription plan.
Unknown whether Connector is a future role, an abandoned concept,
or something else entirely.

**What needs resolving:**
Is Connector a future user role (deferred) or retired?
Determines whether Architecture V2 gets a deferred note or
Connector is removed.

---

## ISSUE 6 — State Management Approach Unresolved
**Severity: Medium**

**What Architecture V2 says:**
State Management: TBD — Pending architectural decision.

State management in Flutter governs how every screen manages
and shares data. The choice (Provider, Riverpod, Bloc, etc.)
affects the structural pattern of every feature file. Starting
development without this decision leads to inconsistent code.

Not a blocker for design or specification work, but must be
resolved before any Flutter feature development begins.

**What needs resolving:**
A state management decision. Lead Architect will raise a formal
recommendation once Supabase is connected (per OA-101/102).

---

## ISSUE 7 — "Journey" Terminology Undefined
**Severity: Medium**

**What MATCHES PAGE Summary uses:**
"Journey" as the UI term for a user's relationship progression
(Active Journey, Pinned Journeys, Ended Journeys).

**What Product Spec V2 uses:**
"Marriage Workflow" for the same concept.
Browse → Potential → Match → Conversation → Family Stage →
Meeting → Nikah.

"Journey" does not appear in Product Spec V2 or Terminology
Standards V1.

**What needs resolving:**
Is "Journey" the approved UI-facing term for the marriage
workflow? Yes or no. If yes, it gets added to Terminology
Standards V1 and Product Spec V2. If no, MATCHES PAGE
Summary is updated.

---

## RESOLUTION PRIORITY

| Issue | Severity | Note |
|---|---|---|
| 2 — Save/Like vs Review/Consider | Critical | Resolves Issues 3 and 4 |
| 1 — Subscription model | Critical | Unblocks all APP folder rewrites |
| 4 — Basic Seeker Like access | High | Depends on Issue 2 |
| 3 — Match creation rule | Critical | Resolves with Issue 2 |
| 5 — Connector role | High | Independent |
| 7 — Journey terminology | Medium | Independent |
| 6 — State management | Medium | Independent |

Recommended order: Issue 2 first, then Issue 1, then 4, 5, 7, 6.

---

## ONCE RESOLVED

Lead Architect will:
- Update all affected APP folder Summaries
- Audit and update Terminology Standards V1
- Update Architecture V2 (Connector note or removal)
- Raise Decision Records for any product decisions made
- Close Project Check findings
