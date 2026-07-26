# Summary Standard — APP and BUSINESS Documents
**Document:** SUMMARY_STANDARD_CURRENT_VERSION_V1
**Version:** V1
**Status:** Approved
**Owner:** Lead Architect
**Date:** 2026-06-27
**Source OA:** OA-018 (ZYRA), OA-018 (Black Umbrella Group)
**Governing:** DR-022
**Adoption:** Guideline-first — existing Summaries are not immediately updated.
              New Summaries follow this standard from publication date.

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

SUMMARY VERSION: [e.g. V1]
STATUS: [e.g. Approved Specification | Draft | In Review]
GROUP: [number] — [name]
LAST REVIEWED: [YYYY-MM-DD] (optional)
```

**Last Reviewed field (optional):** Records the date this Summary was last meaningfully reviewed. Enables health inspections, stale document detection, and future governance reporting. Omit if unknown — do not block adoption on filling this field. When a Summary is reviewed or updated, add or update this field at the same time.

**Group field:** The Group field declares which execution framework group this feature belongs to. It allows agents to batch features by group during inspection and reporting.

Format: `GROUP: [number] — [name]`

Example: `GROUP: 6 — UI/UX Design`

The Group field applies to APP and BUSINESS documents only. SYSTEM documents do not carry a Group field.

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

Include: Feature names and a one-line description of the relationship. Links to other Summaries where relevant.

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

**Existing Summaries:** Existing Summary.md files are not immediately required to update. When a Summary is being meaningfully edited for another reason, bring it into alignment with this standard at the same time. Do not create update sessions solely to reformat existing Summaries — other work takes priority.

**Incomplete sections:** If a section genuinely has no content at the time of writing, include the heading followed by: `Not yet defined.` This keeps the structure intact and signals the gap clearly.

---

## 5. Example Summary Header

```
FEATURE NAME
AUTHENTICATION

SUMMARY VERSION: V1
STATUS: Approved Specification
GROUP: 1 — Onboarding and Access
```

---

## 6. Version History

| Version | Date | Change |
|---------|------|--------|
| V1 | 2026-06-27 | Initial release. Approved by Architectural Reviewer (ChatGPT) 2026-06-27. Added optional LAST REVIEWED field per Reviewer recommendation. Source OA: OA-018. |

