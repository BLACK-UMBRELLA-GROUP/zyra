---
id: DOC-ZYRA-0247
type: SPEC
status: CURRENT
feature: PRODUCT
purpose: ADVANCEMENT CONDITIONS: This document defines the evidence that must exist before a feature can advance from one execution Group to the next.
links: []
owner: ZYRA chat
---

# ADVANCEMENT CONDITIONS
## CURRENT_VERSION_V1

**Project:**   ZYRA
**Status:**    Approved
**Approved:**  2026-06-27
**Approvers:** Lead Architect + Architectural Reviewer (ChatGPT)
**Governs:**   DR-022 (8-Group Execution Framework) — DR-074 (Group Field)

---

## Purpose

This document defines the evidence that must exist before a feature
can advance from one execution Group to the next.

These conditions do not redesign the execution framework (DR-022)
or the Summary Standard. Both already exist and are not changed here.

This document answers one question, eight times:

> "What evidence must exist before a feature can move from Group N
> to Group N+1?"

---

## Governing Principle

Completion is not measured by the presence of documents.
It is measured by readiness to hand work to the next execution stage.

If the next Group cannot proceed confidently, the current Group is
not yet complete. Each Group hands a complete, approved output to
the next Group.

*Confirmed by Architectural Reviewer, 2026-06-27.*

---

## Advancement Conditions

### Group 1 → 2 — Business Rules Complete

All business rules governing the feature's behaviour are documented,
internally consistent, and sufficiently complete that User Journey
design can begin without requiring additional behavioural decisions
or assumptions.

**Handover test:** Can User Journey design begin for this feature
without needing to make or request any behavioural decisions?

---

### Group 2 → 3 — User Journeys Complete

User journeys for this feature are documented from entry to exit and
are sufficiently complete that the full set of pages required by the
feature can be identified without requiring additional journey
decisions or assumptions.

**Handover test:** Can the Page Inventory be produced for this
feature using only the approved User Journey outputs?

---

### Group 3 → 4 — Page Inventory Complete

Every page required by this feature is listed in the approved Page
Inventory with its name and purpose confirmed, such that Page
Responsibilities can begin without needing to identify, rename, or
introduce additional pages.

**Handover test:** Can Page Responsibilities work begin for this
feature without adding, removing, or renaming any pages?

---

### Group 4 → 5 — Page Responsibilities Complete

Every page within the feature has its responsibilities fully defined
in accordance with the approved Page Responsibilities standard, such
that Application Architecture can begin without requiring
clarification of what any page does, what it requires, or what it
produces.

**Handover test:** Can Application Architecture begin for this
feature without requiring clarification of what any page does, what
it requires, or what it produces?

---

### Group 5 → 6 — Application Architecture Complete

The feature's Application Architecture is documented in accordance
with the approved Architecture standard and is sufficiently complete
that an Architecture Readiness Review can evaluate it without first
defining missing architectural decisions, resolving unspecified
components, or making assumptions about how the feature is structured
or integrated.

**Handover test:** Can the Architecture Readiness Review evaluate
this feature's architecture as presented, without first filling in
missing decisions or resolving unspecified components?

---

### Group 6 → 7 — Architecture Readiness Review Passed

An Architecture Readiness Review has been completed for this feature
and all findings have been resolved or formally accepted, such that
UI/UX Design can begin without known unresolved architectural
blockers requiring significant redesign during the design phase.

**Handover test:** Can UI/UX Design begin for this feature without
known unresolved architectural issues requiring significant redesign
during the design phase?

---

### Group 7 → 8 — UI/UX Design Approved

UI/UX Design for this feature is complete in accordance with the
approved UI/UX Design standard and all required design outputs have
been reviewed and approved, such that Development can begin
implementation without needing to resolve missing design decisions,
interpret ambiguous behaviour, or make assumptions about the intended
user experience.

**Handover test:** Can Development begin implementation using only
the approved UI/UX Design outputs, without pausing to request
clarification of the intended user experience?

---

### Group 8 → Complete — Development Complete

Development for this feature is complete in accordance with the
approved Development standard and all required development outputs
have been reviewed, tested, and approved, such that the feature is
ready for release without requiring further development work,
unresolved technical decisions, or outstanding development quality
gates.

**Handover test:** Can this feature enter the release process
without requiring further development effort or technical
decision-making?

---

## Notes

- Each condition references its governed standard by name rather than
  enumerating its contents. The standards evolve independently; this
  document governs only the readiness threshold for advancement.

- "Formally accepted" in Group 6 → 7 preserves engineering
  judgement: not every finding must be resolved. Some may be
  consciously accepted decisions. The condition requires resolution
  or formal acceptance — not elimination of all findings.

- The final transition (Group 8 → Complete) hands work to the
  release process, not necessarily to production. Whether and when
  a release occurs is a separate operational decision governed
  outside the execution framework.

- Auto-discovery rule (per OA-120): The Project Check discovers
  participating features automatically by reading all Summary.md
  files within APP/ and BUSINESS/ and extracting their Group field.
  No manual feature nomination is required or permitted.

---

## Feature Status Classification

The Project Check classifies every APP/ and BUSINESS/ feature
folder using the following rules:

| Status      | Condition                                              |
|-------------|--------------------------------------------------------|
| Not Started | Feature folder exists but has no Summary.md. This is  |
|             | not a finding. Features not yet in execution are not  |
|             | expected to have a Summary or Group field.             |
| Group N     | Summary.md exists and carries a valid Group field.     |
|             | Feature is at the declared execution stage.            |
| Unclassified| Summary.md exists but carries no Group field and       |
|             | content indicates execution has commenced. This IS a   |
|             | finding — Group field must be set.                     |

**Rule: a missing Group field is only reported as a finding
if a Summary.md exists AND content indicates the feature has
entered execution.**

A feature folder with no Summary.md is classified as
Not Started and is not reported as an issue. It does not
require a placeholder Summary for the Project Check to
treat it as healthy.

**Rule: features progress independently.**
BUSINESS and APP features operate on separate work tracks
and will naturally be at different Group stages. The Project
Check assesses each feature independently. Differences in
Group stage across unrelated features are not findings.

---

*Raised under OA-120. Approved 2026-06-27.*
*Feature Status Classification added 2026-06-27 (Project Owner correction).*
