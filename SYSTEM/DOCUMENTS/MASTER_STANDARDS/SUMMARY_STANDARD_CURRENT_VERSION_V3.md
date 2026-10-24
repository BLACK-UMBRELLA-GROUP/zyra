# Summary Standard — APP and BUSINESS Documents
**Document:** SUMMARY_STANDARD_CURRENT_VERSION_V3
**Version:** V3
**Status:** Approved
**Owner:** Lead Architect
**Date:** 2026-07-19
**Supersedes:** SUMMARY_STANDARD_2026-07-19_V2.md (archived:
SYSTEM/DOCUMENTS/ARCHIVE/SUMMARY_STANDARD_2026-07-19_V2.md)
**Source OA:** OA-018 (ZYRA), OA-018 (Black Umbrella Group)
**Governing:** DR-022; V2 ratified 2026-07-19 following joint architectural
review (Claude + ChatGPT) and independent review (Fable / Opus 4, two
cycles). V3 ratified 2026-07-19 (Founder decision, same day) following a
live test of the V2 workflow against the Colour Theme feature folder —
see §2.1 and Version History.
**Adoption:** Guideline-first — existing Summaries are not immediately
              updated or renamed to match this version. New Summaries
              follow this standard from publication date.

---

## 1. Purpose

This document defines the standard structure for `Summary.md` files within all APP and BUSINESS feature folders in the ZYRA repository.

A Summary.md is the primary reference document for any feature folder. It must be readable by any agent or Project Owner without requiring additional context from other files.

This standard applies to:
- `APP/` feature folders
- `BUSINESS/` feature folders

This standard does NOT apply to:
- `SYSTEM/` documents (which have their own document conventions)
- `SOURCE/` code files

---

## 2. Summary Header

Every Summary.md must begin with a standard header block before any section content.

```
FEATURE NAME
[Feature name in uppercase]

Group: [number] — [name]
Summary Version: [e.g. V1]
Status: [🟢 Finalised | 🟡 Under Review | 🔴 Founder Decision Required]
Last Reviewed: [YYYY-MM-DD] (optional)
Governed By: [Master Spec Part/section, if this feature is constrained
              by one — e.g. "Product Spec V3 Part 0"] (optional)
Depends On: [other feature Summaries this one depends on] (optional)
```

**Field case, corrected 2026-07-19 (Founder decision):** field labels use
mixed case (`Group:`, `Summary Version:`, `Status:`, `Last Reviewed:`),
matching the convention every live Summary.md in the repository already
uses — confirmed directly: 23 of 23 checked use `Group:`, zero use
`GROUP:`. V1 of this standard specified uppercase labels in its example,
which no live file had ever actually followed. The Founder's decision:
align the Standard with established practice rather than mark the whole
repository non-compliant against an example that was never adopted.
**`FEATURE NAME` remains uppercase** — that is the one part of the header
live practice does consistently follow; it functions as a title, not a
field label.

**Do not rename or reformat existing Summary.md files solely to adopt
this casing change.** Per the adoption model (§4), existing files are
brought into alignment only when meaningfully edited for another reason.

### 2.1 Status Field — Decision State (new, 2026-07-19)

**Replaces** the V2/V1 enum (`Draft | In Review | Approved Specification`)
with three states, each carrying a defined colour pair for future visual
tooling (badges, dashboards, Repository Explorer) — exact hex values
supplied by the Founder:

| State | Meaning | Primary hex | Accent hex |
|---|---|---|---|
| 🟢 Finalised | Locked. Safe to implement from. | `#00CC44` | `#1A7A2E` |
| 🟡 Under Review | Actively being drafted or reviewed. Not yet locked, but no unresolved Founder-level question is blocking it. | `#FFE020` | `#B89A00` |
| 🔴 Founder Decision Required | Contains unresolved options, open dependencies, or language such as "current favourite," "proposed," "pending decision" — a specific Founder decision is the blocker, not more drafting. | `#FF3B3B` | `#A61C1C` |

**Why three states, not four:** V2's `Draft` and `In Review` both meant
"not yet locked" without distinguishing *why* — still being actively
worked, or stalled waiting on a decision only the Founder can make. That
distinction is the one that actually matters for whether implementation
should proceed, so it replaces the two ambiguous states rather than
sitting alongside them as a fourth value.

**Why this exists — the Colour Theme test case, 2026-07-19:** this
standard's V2 checklist (`ZYRA_EXECUTION` §3.2, see also) was
ratified, then tested the same evening against `BUSINESS/COLOUR THEME/`.
The Summary's own prose ("Current preferred direction: OPTION 1") and
`References.md`'s Open Dependencies section ("Option 1 vs Option 2
decision not yet formally approved") both already signalled this
correctly — but nothing forced a reader (human or AI) to notice the
signal before implementation had already used Option 1's values. A
single required Status field removes the need to interpret prose for
this signal at all: if it isn't 🟢, implementation stops and a Founder
decision is requested before proceeding, full stop, no exceptions the
reader has to reason their way to.

**Behavioural rule, cross-referenced in `ZYRA_EXECUTION` §3.2:** if
a Summary's Status is 🔴 or 🟡, or has no Status field at all, treat it
as 🔴 by default — implementation does not proceed from an unstatused
document. The one exception is an explicit, in-the-moment Founder
authorisation to build provisionally (as happened earlier tonight with
the Luxury Dark Purple removal) — that authorises the specific change
discussed, not a blanket "this Summary is now Finalised."

**Last Reviewed field (optional):** Records the date this Summary was last meaningfully reviewed. Enables health inspections, stale document detection, and future governance reporting. Omit if unknown — do not block adoption on filling this field. When a Summary is reviewed or updated, add or update this field at the same time.

**Group field:** The Group field declares which execution framework group this feature belongs to. It allows agents to batch features by group during inspection and reporting.

Format: `Group: [number] — [name]`

Example: `Group: 6 — UI/UX Design`

The Group field applies to APP and BUSINESS documents only. SYSTEM documents do not carry a Group field.

**Governed By field (2026-07-19):** Names the Master Product Spec
Part/section that constrains this feature, if one exists — e.g. a feature
touching relationship states cites the State Integrity Principle (AD-082),
Product Spec Part 0 §0.1. Exists to make explicit, at a glance, when a
Summary's content is bounded by a higher-layer canonical document, closing
the gap that allowed OA-ZYRA-133 (2026-07-19) to re-derive already-ratified
states without checking the Master Spec first. Omit if no such governing
relationship exists — most features will not need it.

**Depends On field (2026-07-19):** Names other feature Summaries this
one depends on. Makes feature dependencies structurally traversable rather
than only discoverable via Section 5 (Related Features) prose. **Before
relying on this field programmatically, reconcile it against
`repository_intelligence_engine.py`'s existing `get_dependency_graph()` /
transitive-dependency capability** — undecided whether this field is the
authoritative input the engine should read, or a human-facing summary of
what the engine already derives independently. Flagged by Fable's review,
2026-07-19; not yet resolved. Until resolved, treat this field as
descriptive only, not as a second source of truth for automated tooling.

---

## 3. Eight Standard Sections

Every Summary.md must contain these eight sections in this order. Sections may contain subsections but must not be reordered or omitted. If a section has no content yet, include the heading with a placeholder note.

---

### Section 1 — Feature Overview

**Purpose:** One paragraph describing what this feature is and why it exists in the product.

Should answer: What does this feature do? What user need does it serve?

Example content: A high-level description of the feature's purpose, its scope, and its relationship to the overall product philosophy.

---

### Section 2 — User Experience

**Purpose:** Describe the user-facing experience — screens, flows, interactions.

Should answer: What does the user see and do? What is the intended experience?

Include: Navigation flows, screen names, key interactions, and UX principles that govern this feature.

---

### Section 3 — Functional Specification

**Purpose:** Define what the feature must do. This is the detailed behaviour specification.

Should answer: What must this feature do? What are the rules governing its behaviour?

Include: Functional requirements, business logic, state transitions, conditions and rules.

---

### Section 4 — Business Rules

**Purpose:** Record explicit rules that constrain the feature's behaviour and must not be violated.

Should answer: What constraints apply? What is explicitly not permitted?

Include: Subscription gating, privacy rules, platform philosophy constraints, data rules, and any explicitly forbidden behaviours.

---

### Section 5 — Related Features

**Purpose:** Identify other features this one depends on, integrates with, or influences.

Should answer: What does this feature connect to?

Include: Feature names and a one-line description of the relationship. Links to other Summaries where relevant. See also the `Depends On` header field (§2) for structured dependency declarations.

---

### Section 6 — Design Decisions

**Purpose:** Record decisions that have been formally made about this feature. Replaces the former "Approved Rules" section name.

Should answer: What decisions have been made and why? What was explicitly ruled out?

Include: Decision references (DR numbers where applicable), rationale for key choices, and alternatives that were considered and rejected.

---

### Section 7 — Current Status

**Purpose:** Record the current implementation state of this feature.

Should answer: What is built? What is approved but not built? What is pending?

Include: Implementation phase, what exists in SOURCE/, outstanding dependencies, and any known blockers.

---

### Section 8 — Approved Future Work

**Purpose:** Record approved future additions to this feature that are not yet being built.

Should answer: What has been approved to add to this feature in a future phase?

Include: Approved items deferred from current scope, with reference to OAs or decisions where they were approved.

Do NOT include speculative or unapproved ideas here. Only formally approved future items belong in this section.

---

## 4. Adoption Guidance

**New Summaries:** All new Summary.md files created after this standard is published must follow this format from day one.

**Existing Summaries:** Existing Summary.md files are not immediately required to update. When a Summary is being meaningfully edited for another reason, bring it into alignment with this standard at the same time. Do not create update sessions solely to reformat existing Summaries — other work takes priority. This applies to the V2 casing change and the V3 Status field exactly as it applied to every other part of this standard: do not rename or reformat existing files solely to adopt them. **Exception, V3:** because an absent or non-🟢 Status field is now the trigger for stopping before implementation (§2.1), a Summary should have its Status field populated honestly the first time `ZYRA_EXECUTION` §3.2's checklist is run against it, even if no other content changes that day. Populating the field is not "reformatting" for the purposes of this exception — it is closing exactly the gap this version exists to close.

**Incomplete sections:** If a section genuinely has no content at the time of writing, include the heading followed by: `Not yet defined.` This keeps the structure intact and signals the gap clearly.

---

## 5. Documentation Principles

### 5.1 Cite, Don't Restate

Canonical cross-cutting facts (e.g. subscription tiers, relationship
states) belong in the Master Product Spec or the owning BUSINESS Summary
(see §5.2, the ownership test) and get **cited** by other Summaries —
never restated inline. Restating a fact that belongs to a higher layer is
what allowed the 2026-06-27 Project Check drift (Guardian Premium / Profile
Decision System vs. Product Spec V2) and OA-ZYRA-133 (2026-07-19) to
happen: each restated a fact instead of citing the document that actually
owned it, and both drifted out of sync with the source when it changed.

### 5.2 Ownership Boundaries — The Decision Test

Which document owns a given fact is decided by a test, not a fixed topic
list — a fixed list (e.g. "BUSINESS = Pricing, Terminology, Colour Theme")
goes stale the first time a genuinely new kind of content appears. This
test mirrors AD-087 §1.3 (the Irreducible Question Test) and AD-082 (the
State Integrity Principle) — the same family of durable decision tests,
not an independently invented pattern:

- **Master Product Spec** owns a fact if changing it would require more
  than one BUSINESS or APP document to change to stay consistent.
- **BUSINESS** owns a fact if more than one APP feature would need to
  reference it.
- **APP** owns only what applies within one feature's own screens and
  flows — everything else is cited, not restated (§5.1).

---

## 6. Example Summary Header

```
FEATURE NAME
AUTHENTICATION

Group: 1 — Onboarding and Access
Summary Version: V1
Status: 🟢 Finalised
```

---

## 7. Version History

| Version | Date | Change |
|---------|------|--------|
| V1 | 2026-06-27 | Initial release. Approved by Architectural Reviewer (ChatGPT) 2026-06-27. Added optional LAST REVIEWED field per Reviewer recommendation. Source OA: OA-018. |
| V2 | 2026-07-19 | Header field casing corrected from uppercase to mixed case to match established practice (Founder decision, confirmed against 23/23 live files). Added `Governed By` and `Depends On` header fields. Added §5, Documentation Principles (Cite Don't Restate; Ownership Boundaries decision test). Source: Consolidated Governance Review Package, Subject 4. Independently reviewed by Fable (Opus 4), two cycles, before Founder ratification. |
| V3 | 2026-07-19 | Status field replaced: `Draft \| In Review \| Approved Specification` → `🟢 Finalised \| 🟡 Under Review \| 🔴 Founder Decision Required`, with hex values supplied by the Founder. Triggered same-day by testing V2's workflow against `BUSINESS/COLOUR THEME/` — a real Founder Decision Required situation that implementation had proceeded through before the Status field existed to catch it. Removes the need to interpret prose ("current favourite," "proposed") for this signal. |
