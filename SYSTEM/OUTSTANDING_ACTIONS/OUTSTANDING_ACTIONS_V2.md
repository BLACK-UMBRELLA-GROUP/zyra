============================================================
ZYRA PROJECT
============================================================
OUTSTANDING ACTIONS V2
APPROVED WORK REGISTER
============================================================
Version: V2
Status: Approved — Active Baseline
Lead Architect: Claude
Architectural Reviewer: ChatGPT
Project Owner: Shakeel
============================================================

CONTENTS

  1.  Purpose
  2.  Scope
  3.  Ownership
  4.  Document Principles
  5.  Action Template
  6.  Action Lifecycle
  7.  Action Identification
  8.  Action Categories
  9.  Priority
  10. Dependencies
  11. Target Publication
  12. Completion
  13. Reporting
  14. Governance Boundaries
  15. Relationship to Other Documents
  16. Synchronisation
  17. Document Maintenance
  18. Future Evolution
  19. Command Integration
  20. Design Principles
  21. Version History
  22. Action Register

============================================================


============================================================
1. PURPOSE
============================================================

Outstanding Actions is the single authoritative register
of all approved work that has not yet been completed.

It provides a central location for tracking implementation
work across the project while remaining independent from
Governance, Execution, Repository Architecture, Decision
Records, and feature documentation.

This document owns only outstanding work.

It does not own:
  • Governance decisions
  • Implementation specifications
  • Architectural reasoning
  • Feature documentation
  • Repository structure definitions

------------------------------------------------------------


============================================================
2. SCOPE
============================================================

This document records only work that has been approved
but has not yet reached completion.

Examples include:

  • Approved features awaiting implementation.
  • Approved documentation updates.
  • Approved architectural improvements.
  • Approved governance improvements.
  • Approved publication work.
  • Approved review work.
  • Approved migration work.
  • Approved maintenance work.
  • Approved cleanup work.
  • Approved repository restructuring.

Ideas, proposals and discussions are not recorded here
until they have completed the governance approval process.

------------------------------------------------------------


============================================================
3. OWNERSHIP
============================================================

Document Owner

This document is maintained by the Lead Architect as
part of the governance documentation suite.

The Project Owner approves additions, removals and
completion of actions.

The Architectural Reviewer provides independent review
for consistency, ownership, terminology and architectural
integrity.

Action Ownership

Each individual Outstanding Action contains its own
assigned owner.

The owner recorded against an action is responsible for
completing that specific action.

Document ownership and Action ownership are independent
and must never be confused.

------------------------------------------------------------


============================================================
4. DOCUMENT PRINCIPLES
============================================================

------------------------------------------------------------
4.1 Single Source of Outstanding Work
------------------------------------------------------------

This document is the only authoritative source for
approved work that remains outstanding.

Other governance documents may reference Outstanding
Actions, but must never duplicate or maintain
independent lists.

------------------------------------------------------------
4.2 Approval Required
------------------------------------------------------------

Only approved work may enter this document.

Ideas, discussions and proposals remain outside this
document until approved through the governance process.

------------------------------------------------------------
4.3 Living Document
------------------------------------------------------------

Outstanding Actions is a living document.

Actions are continually added, updated, completed,
cancelled or superseded through approved governance
processes.

------------------------------------------------------------
4.4 Historical Accuracy
------------------------------------------------------------

When an action reaches a terminal state it remains
recorded for historical accuracy until removed through
an approved publication.

Historical changes must remain traceable through the
normal publication workflow.

------------------------------------------------------------


============================================================
5. ACTION TEMPLATE
============================================================

Every Outstanding Action uses the following template.

  ID:           OA-[number]
  Title:        Short descriptive title
  Category:     Category from Section 8
  Priority:     Critical / High / Medium / Low
  Status:       Status from Section 6
  Owner:        Role responsible for completion
  Dependencies: OA-[numbers] or None
  Decision:     DR-[number] or None (optional)
  Automation:   Manual / Planned / Automated
  Description:  What needs to be done and why
  Target:       Which publication or milestone

Decision links this action to the Decision Record that
authorised the work, creating a direct audit trail:
  Decision → Outstanding Action → Execution → Completion

Automation defaults to Manual for all current actions.
Update to Planned or Automated when applicable.

------------------------------------------------------------


============================================================
6. ACTION LIFECYCLE
============================================================

An action enters this lifecycle only after successfully
completing the governance approval process.

------------------------------------------------------------
Operational States
------------------------------------------------------------

  Recorded     — Approved. Not yet started.
  In Progress  — Actively being worked on.
  On Hold      — Paused. Awaiting dependency or decision.
  Awaiting Review — Work complete. Awaiting verification.

------------------------------------------------------------
Terminal States
------------------------------------------------------------

  Completed    — Approved and verified. Successful end.
  Cancelled    — No longer required. Approved removal.
  Superseded   — Replaced by another action or decision.

------------------------------------------------------------
State Rules
------------------------------------------------------------

  • Recorded is the entry state for all new actions.
  • Completed is the only successful terminal state.
  • Cancelled and Superseded may occur from any state.
  • Terminal state records are retained until removed
    through an approved publication.

------------------------------------------------------------


============================================================
7. ACTION IDENTIFICATION
============================================================

Every Outstanding Action has a permanent Action ID.

Format: OA-[sequential number]

Examples: OA-001, OA-002, OA-003

Action IDs are never reused.

If an action is cancelled, superseded or completed,
its ID remains permanently associated with that record.

------------------------------------------------------------


============================================================
8. ACTION CATEGORIES
============================================================

  • Governance       — Governance document work
  • Execution        — Execution document work
  • Architecture     — Repository architecture work
  • Documentation    — Feature or SYSTEM document work
  • Repository       — Folder structure and filing work
  • Terminology      — ZYRA Terminology work
  • Cleanup          — Removal of outdated or misplaced content
  • Migration        — Moving content between locations
  • Feature          — APP feature work
  • Review           — Audit or review work

Categories describe the nature of the work only.

They do not affect priority, approval requirements
or lifecycle behaviour.

------------------------------------------------------------


============================================================
9. PRIORITY
============================================================

  Critical  — Blocks other approved work
  High      — Should be completed in the next session
  Medium    — Important but not immediately blocking
  Low       — Future work, no immediate dependency

Priority may change as project requirements evolve.

Changing priority does not require a new approval
provided the action itself remains unchanged.

------------------------------------------------------------


============================================================
10. DEPENDENCIES
============================================================

An Outstanding Action may depend upon one or more
other approved actions before work can begin.

Dependencies are recorded to improve planning and
prevent conflicts.

Dependencies never prevent an action from being
recorded. They explain why it may remain in the
Recorded state.

------------------------------------------------------------


============================================================
11. TARGET PUBLICATION
============================================================

Where applicable, each action identifies the publication
or milestone through which completion is expected.

Target Publication assists planning only.

It does not determine approval or completion.

------------------------------------------------------------


============================================================
12. COMPLETION
============================================================

An action is considered complete only when all of the
following have occurred:

  1. The approved work has been fully carried out.
  2. Required reviews have successfully completed.
  3. Any required publications have been approved and
     filed as the Active Baseline.
  4. The Project Owner confirms completion.

Implementation alone does not constitute completion.

An action that is technically finished but awaiting
publication approval remains in Awaiting Review, not
Completed.

Completed actions remain historically traceable until
removed through an approved publication process.

------------------------------------------------------------


============================================================
13. REPORTING
============================================================

Reports generated from this document may include:

  • Total Outstanding Actions
  • Actions by Category
  • Actions by Priority
  • Actions by Status
  • Actions by Owner
  • Actions by Target Publication
  • Dependency Summary
  • Recently Completed Actions
  • Recently Added Actions
  • Cancelled Actions
  • Superseded Actions

Reports present the current state of the register.

They do not create approvals or modify actions.

------------------------------------------------------------


============================================================
14. GOVERNANCE BOUNDARIES
============================================================

Outstanding Actions records work.

It does not determine whether work should exist.

Outstanding Actions never:

  • Approves work.
  • Rejects work.
  • Creates governance decisions.
  • Creates Decision Records.
  • Creates documentation.
  • Alters implementation specifications.
  • Records unapproved proposals.

Its responsibility begins only after approved work
enters the register.

------------------------------------------------------------


============================================================
15. RELATIONSHIP TO OTHER DOCUMENTS
============================================================

Governance
  Defines principles, approval processes, documentation
  standards, publication workflow, decision lifecycle.
  Outstanding Actions begins only after Governance
  has approved work.

Execution
  Defines how approved work is carried out.
  Outstanding Actions records that work exists and
  tracks its progress.

Repository Architecture
  Defines where everything in the repository lives.
  Outstanding Actions may reference structural work
  but never redefines repository structure.

Decision Records (formerly Architectural Discussions)
  Records the permanent reasoning behind approved
  architectural decisions.
  Outstanding Actions may reference those decisions
  but never duplicates them.
  The DECISIONS area will evolve toward formal
  Decision Records through Governance V3.

Feature Documentation
  Feature Summaries, Scripts, Flow Diagrams and
  References define individual features.
  Outstanding Actions may reference feature documents
  where approved work relates to those features.

------------------------------------------------------------


============================================================
16. SYNCHRONISATION
============================================================

Outstanding Actions participates in the standard
governance publication workflow.

Changes become operational only after:

  • Review.
  • Project Owner approval.
  • Publication.
  • Synchronisation.

Conversational memory never replaces the approved
published document.

The latest approved publication always remains the
active baseline.

------------------------------------------------------------


============================================================
17. DOCUMENT MAINTENANCE
============================================================

This document is maintained through the standard
governance publication workflow.

All additions, updates, cancellations, supersessions
and completions are performed through approved
publications.

Previous publications remain archived for historical
reference.

There is always exactly one active baseline for
this document.

------------------------------------------------------------


============================================================
18. FUTURE EVOLUTION
============================================================

Outstanding Actions is designed to scale alongside
the project.

Future improvements may introduce additional reporting,
automation or workflow enhancements provided they
remain consistent with Governance.

Any future changes must:

  • Preserve existing governance principles.
  • Preserve historical accuracy.
  • Preserve publication integrity.
  • Preserve the active baseline principle.
  • Follow the approved publication workflow.

------------------------------------------------------------


============================================================
19. COMMAND INTEGRATION
============================================================

Various governance commands interact with Outstanding
Actions.

Governance defines the purpose and ownership of each
command.

Execution defines the operational behaviour.

Outstanding Actions records the outcomes of approved
command execution where applicable.

Outstanding Actions never changes as the direct result
of a command alone.

Only approved outcomes produced through the governance
process may modify this register.

------------------------------------------------------------


============================================================
20. DESIGN PRINCIPLES
============================================================

Single Source
  One authoritative register for all approved
  outstanding work.

Traceability
  Every action remains historically traceable
  throughout its lifecycle.

Separation of Responsibility
  Governance approves.
  Execution performs.
  Outstanding Actions tracks.
  Decision Records explains why.

Publication Integrity
  Changes become operational only through approved
  publication and synchronisation.

------------------------------------------------------------


============================================================
21. VERSION HISTORY
============================================================

Version V1
  Initial baseline.
  Established purpose, scope, ownership, lifecycle,
  action template, categories, priority, dependencies,
  completion, reporting, and governance boundaries.
  Owner listed as ChatGPT (named product).

Version V2
  Supersedes V1 as Active Baseline.
  Changes from V1:
    • Ownership updated to role-based language
      (Lead Architect, Architectural Reviewer,
      Project Owner).
    • Repository Architecture added to document
      relationships (Section 15).
    • Decision Records transition note added
      (Section 15, Section 14).
    • Action Template formalised with Decision and
      Automation fields (Section 5).
    • On Hold state added to lifecycle (Section 6).
    • Action Register added (Section 22) with all
      current approved outstanding actions
      (OA-001 through OA-011).
    • Register ordered by OA-ID not Priority.
    • Completion clarified — requires publication
      approval, not just implementation (Section 12).
    • OA-011 architectural maturity note added.
    • Cleanup and Migration categories added
      (Section 8).

------------------------------------------------------------


============================================================
22. ACTION REGISTER
============================================================

This section is the live register of all approved
outstanding actions.

Actions are ordered by Action ID (OA-001, OA-002...).

Priority ordering is never used in the master register.
Priority-grouped views are available through reporting
(Section 13) without changing the register itself.
This keeps the register stable as priorities evolve.

OA-001
Title:       Write Decisions V1
Category:    Governance
Priority:    Critical
Status:      Completed
Owner:       Lead Architect
Dependencies: None
Decision:    None
Automation:  Manual
Description: Create DECISIONS_V1.md as the first
             formal Decision Records document.
             Next SYSTEM document in the agreed
             roadmap following Outstanding Actions V2.
Target:      DECISIONS_V1.md

------------------------------------------------------------

OA-002
Title:       Write Governance V3
Category:    Governance
Priority:    Critical
Status:      Completed
Owner:       Lead Architect
Dependencies: OA-001
Decision:    None
Automation:  Manual
Description: Governance V3 consolidates all rules
             established since Governance V2.
             Formally introduces Decision Records,
             updates AI role model, and references
             Repository Architecture and Execution V2.
             Must follow Decisions V1.
Target:      GOVERNANCE_V3.md

------------------------------------------------------------

OA-003
Title:       Audit SYSTEM/DEVELOPMENT/ folder
Category:    Review
Priority:    High
Status:      Completed
Completed:   2026-06-27
Owner:       Lead Architect
Dependencies: None
Decision:    None
Automation:  Manual
Description: Read all files in SYSTEM/DEVELOPMENT/.
             Identify content that should migrate to
             permanent locations. Flag anything that
             has become a de facto source of truth.
             Report findings before acting.
Target:      Repository audit session

------------------------------------------------------------

OA-004
Title:       Resolve APP/14_LEGAL empty folder
Category:    Repository
Priority:    High
Status:      Completed
Completed:   2026-06-27
Owner:       Lead Architect
Dependencies: None
Decision:    None
Automation:  Manual
Description: APP/14_LEGAL exists but is empty and
             unassigned. Either create a Summary for
             it or remove it. Requires Project Owner
             decision before action.
Target:      Repository cleanup session

------------------------------------------------------------

OA-005
Title:       Audit Authentication folder
Category:    Review
Priority:    High
Status:      Completed
Completed:   2026-06-27
Owner:       Lead Architect
Dependencies: None
Decision:    None
Automation:  Manual
Description: Read all files in APP/Authentication/.
             Check Major Folder declarations. Flag
             any content that is misplaced or needs
             updating.
Target:      Repository audit session

------------------------------------------------------------

OA-006
Title:       Add Operational Rules cross-reference
             to Governance V3
Category:    Governance
Priority:    High
Status:      Completed
Owner:       Lead Architect
Dependencies: OA-002
Decision:    None
Automation:  Manual
Description: Execution V2 Section 14 introduced key
             operational guarantees (Confirmation
             Before Execution, Read Before Write,
             Files Over Memory, Conflict Flag Before
             Edit). Governance V3 should reference
             these so they are discoverable from
             both documents.
Target:      GOVERNANCE_V3.md

------------------------------------------------------------

OA-007
Title:       Define pending ZYRA Terminology terms
Category:    Terminology
Priority:    Medium
Status:      Blocked
Owner:       Lead Architect
Dependencies: None
Decision:    None
Automation:  Manual
Description: ZYRA TERMINOLOGY has 20+ terms still
             to define including: Potential,
             Consideration, Connection, Match,
             Timeline, and others. Terms must be
             defined and approved before use in any
             document.
Target:      BUSINESS/ZYRA TERMINOLOGY/Summary.md

------------------------------------------------------------

OA-008
Title:       Create Wali Navigation folder
Category:    Documentation
Priority:    Medium
Status:      Blocked
Owner:       Lead Architect
Dependencies: None (awaiting Summary from Shakeel)
Decision:    None
Automation:  Manual
Description: Wali navigation content is temporarily
             held in SEEKER NAVIGATION. Once a Wali
             Navigation Summary exists, create the
             dedicated folder and migrate content.
Target:      APP/Navigation/WALI NAVIGATION/

------------------------------------------------------------

OA-009
Title:       Create Connections folder
Category:    Documentation
Priority:    Medium
Status:      Blocked
Owner:       Lead Architect
Dependencies: None (awaiting Summary from Shakeel)
Decision:    None
Automation:  Manual
Description: Connections content is temporarily held
             in SEEKER NAVIGATION Script/. Once a
             Connections Summary exists, create the
             dedicated folder and migrate the Script.
Target:      APP/Connections/ or
             APP/Navigation/CONNECTIONS/

------------------------------------------------------------

OA-010
Title:       Remove ZYRA-specific content from
             SYSTEM documents
Category:    Cleanup
Priority:    Low
Status:      Recorded
Owner:       Lead Architect
Dependencies: None
Decision:    None
Automation:  Manual
Description: SYSTEM documents should be fully
             generic and reusable for any project.
             ZYRA-specific content (source of truth
             assignments, folder inventory, approved
             terms) should move to a ZYRA-specific
             implementation document outside SYSTEM.
             Handle as part of a future cleanup session.
Target:      Future cleanup session

------------------------------------------------------------

OA-011
Title:       Restructure to holding company / APPS/
             model
Category:    Migration
Priority:    Low
Status:      Completed
Owner:       Lead Architect
Dependencies: OA-010
Decision:    DR-016, DR-023
Automation:  Manual
Description: Restructure executed 2026-06-21. SYSTEM/
             remains at top level as shared governance
             infrastructure. APP/, BUSINESS/, SOURCE/,
             ARCHIVE/ moved into APPS/ZYRA/. REPORTS/
             INSPECTION/ created under both APPS/ZYRA/
             and SYSTEM/. Physical folder rename
             (ZYRA → HOLDING) is a Finder-level task
             for the Project Owner.
Target:      Completed — DR-023

------------------------------------------------------------

OA-012
Title:       Command principles for Governance V3
Category:    Governance
Priority:    High
Status:      Completed
Owner:       Lead Architect
Dependencies: OA-002
Decision:    DR-018, DR-019
Automation:  Manual
Description: Incorporate command PRINCIPLES into
             Governance V3 (DR-019 routing: Governance
             owns command principles; Execution owns
             command definitions). Delivered in V3:
               • Command principles — defined ownership,
                 documented responsibilities, no
                 duplication, governance review for
                 significant changes
               • SYSTEM/APP separation as a governance rule
               • Standardised severity levels
                 (Critical / High / Medium / Low)
             The detailed command definitions (removals,
             renames, Inspection stages, completion
             tracking) are tracked under OA-013 for
             Execution V3.
Target:      GOVERNANCE_V3.md

------------------------------------------------------------

OA-013
Title:       Author command definitions in Execution V3
Category:    Execution
Priority:    High
Status:      Completed
Owner:       Lead Architect
Dependencies: OA-012
Decision:    DR-018, DR-019
Automation:  Manual
Description: Author the detailed command definitions in
             Execution V3 — the definitions deferred from
             OA-012 under the DR-019 routing (Governance
             owns principles; Execution owns definitions):
               • Remove Command 1 (Retrieve) — redundant
                 now repository is established
               • Remove Command 8 (Assess) — absorbed
                 into Command 3 output
               • Command 9 renamed to Command 2 — Audit
                 (manual, one scope only, hard limit)
               • Command 3 renamed to Inspection —
                 repository-wide, automated weekly
               • Command 3 structure: Stage 0 (previous
                 unresolved findings, full detail),
                 Stage 1 (new findings per file with
                 cross-file checks and section ownership
                 check), Stage 2 (cross-system comparison),
                 % completion per file, trend, priority
                 order
               • Per-file completion tracking for APP
                 features (% per file within folder)
               • Terminology completion as % of terms
                 defined
               • BUSINESS files use status only —
                 Complete / In Progress / Not Started
               • SYSTEM files use status-based view —
                 Clean / Updates pending / Archived /
                 Not audited
Target:      EXECUTION_V3.md

------------------------------------------------------------

OA-014
Title:       Correct stale references in Execution V2
Category:    Execution
Priority:    Medium
Status:      Completed
Owner:       Lead Architect
Dependencies: None
Decision:    None
Automation:  Manual
Description: Two stale items to correct in Execution's
             next version (batched per DR-018):
               • Section 24.1 still specifies the old
                 "Command 9 — Implementation Validation
                 Review"; supersede under the OA-013 /
                 DR-019 command redesign.
               • Appendix E lists the active baseline as
                 EXECUTION_CURRENT_VERSION_V2.md; core
                 SYSTEM documents use simple naming
                 (DR-010) — should read EXECUTION_V2.md.
Target:      EXECUTION_V3.md

------------------------------------------------------------

OA-015
Title:       Add SOURCE/ code development workflow
             to Execution V4
Category:    Execution
Priority:    Medium
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: None
Decision:    DR-020
Automation:  Manual
Description: Add a new section to Execution V4 defining
             the SOURCE/ code development workflow
             approved in DR-020. The section must cover:
               • Plan-first requirement — plan produced
                 and confirmed before any code is written
               • Tests-first requirement — tests written
                 and confirmed before implementation
               • Self-review step after implementation
               • Applies to all writes to SOURCE/ across
                 all APP features
             This rule extends the existing confirmation
             before execution principle (Section 14)
             with explicit structure for code work.
Target:      EXECUTION_V4.md

------------------------------------------------------------

OA-016
Title:       Add ZYRA UI design language rule to
             Execution V4
Category:    Execution
Priority:    Medium
Status:      Recorded
Owner:       Lead Architect
Dependencies: None
Decision:    DR-021
Automation:  Manual
Description: Add a rule to Execution V4 requiring a
             ZYRA Design Language brief before any UI
             code is written to SOURCE/. The brief must
             define purpose, tone, constraints, and
             differentiation. No UI screen may be built
             without the brief in place.
             NOTE: Architectural Reviewer (ChatGPT)
             input required before this rule is written.
             Raise with ChatGPT when Execution V4 is
             being drafted.
Target:      EXECUTION_V4.md

------------------------------------------------------------

OA-017
Title:       Update Inspection report with execution
             framework group priority rule
Category:    Execution
Priority:    Medium
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: None
Decision:    DR-022
Automation:  Manual
Description: Update Execution V4 Inspection section to
             reflect the approved priority rule from
             DR-022. Changes required:
               • Execution framework group number
                 (1–7) becomes the primary sort key
                 for priority ordering in all Inspection
                 reports. Lower group = higher priority,
                 always.
               • Within the same group, lower completion
                 % indicates higher concern.
               • Partially complete lower-group items
                 must be flagged with elevated concern
                 when higher-group items are in progress
                 (sequential dependency risk).
               • Priority order section in Report Summary
                 must surface group membership alongside
                 existing severity levels.
             Group definitions follow DR-022:
               Group 1 — Business Rules
               Group 2 — User Journeys
               Group 3 — Complete Page Inventory
               Group 4 — Page Responsibilities
               Group 5 — Application Architecture
               Group 6 — Architecture Readiness Review
               Group 7 — UI/UX Design
               Group 8 — Development
Target:      EXECUTION_V4.md

------------------------------------------------------------

OA-018
Title:       Define and publish Summary standard
             for APP and BUSINESS documents
Category:    Documentation
Priority:    Medium
Status:      Completed
Completed:   2026-06-27
Owner:       Lead Architect
Dependencies: None
Decision:    DR-022
Automation:  Manual
Description: Define the standard Summary.md structure
             for all APP and BUSINESS feature folders.
             To be written as a guideline first, with
             gradual adoption across existing files.
             The standard must cover:
               • Eight standard sections:
                   1. Feature Overview
                   2. User Experience
                   3. Functional Specification
                   4. Business Rules
                   5. Related Features
                   6. Design Decisions
                      (rename from Approved Rules)
                   7. Current Status
                   8. Approved Future Work
               • Group metadata field in the Summary
                 header declaring which execution
                 framework group the feature belongs to.
                 Format: Group: [number] — [name]
                 Example: Group: 6 — UI/UX Design
                 Applies to APP and BUSINESS only.
                 SYSTEM documents do not carry a Group
                 field.
               • Guideline-first adoption — existing
                 Summaries are not immediately updated.
                 New Summaries follow the standard from
                 publication date.
             NOTE: Architectural Reviewer (ChatGPT)
             input required before this standard is
             written. Raise with ChatGPT when Execution
             V4 is being drafted.
Target:      EXECUTION_V4.md

------------------------------------------------------------

OA-019
Title:       Update Repository Architecture V1 to
             reflect holding company structure
Category:    Architecture
Priority:    High
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: None
Decision:    DR-023, DR-024
Automation:  Manual
Description: REPOSITORY_ARCHITECTURE_V1.md contains
             path references that predate two restructures.
             Scope covers both DR-023 and DR-024:
               DR-023 changes:
               • APP/, BUSINESS/, SOURCE/, ARCHIVE/
                 moved to APPS/ZYRA/
               • REPORTS/INSPECTION/ created under
                 APPS/ZYRA/ and SYSTEM/
               DR-024 changes:
               • DECISIONS/ moved from SYSTEM/ to
                 APPS/ZYRA/SYSTEM/
               • OUTSTANDING_ACTIONS/ moved from
                 SYSTEM/ to APPS/ZYRA/SYSTEM/
               • APPS/ZYRA/SYSTEM/ created as new
                 ZYRA operational layer
               • SYSTEM/ now contains only: GOVERNANCE,
                 EXECUTION, ARCHITECTURE, DEVELOPMENT,
                 REPORTS
             The document must reflect the full current
             structure and the SYSTEM/ as shared
             governance infrastructure only.
             Additional scope (DR-028): APPS/ renamed
             to PROJECTS/ — all paths in V2 must use
             PROJECTS/ throughout.
Target:      REPOSITORY_ARCHITECTURE_V2.md

------------------------------------------------------------

OA-020
Title:       Queue APP Inspection schedule change
             for Execution V4
Category:    Execution
Priority:    Medium
Status:      Recorded
Owner:       Lead Architect
Dependencies: None
Decision:    None
Automation:  Manual
Description: Proposed schedule change for Inspection
             command runs:
               • SYSTEM Inspection — weekly (unchanged,
                 already defined in Execution V3)
               • APP Inspection — daily (proposed new
                 cadence, currently weekly in V3)
             NOTE: This is a proposed idea only.
             Architectural Reviewer (ChatGPT) input
             required before confirming. Raise with
             ChatGPT when Execution V4 is drafted.
             Consider: daily APP Inspection may
             generate high report volume. Define
             what triggers a daily run vs a full
             weekly run (delta-only vs full report).
Target:      EXECUTION_V4.md

------------------------------------------------------------

OA-021
Title:       Separate ZYRA operational documents from
             shared SYSTEM — create APPS/ZYRA/SYSTEM/
Category:    Migration
Priority:    High
Status:      Completed
Owner:       Lead Architect
Dependencies: OA-011
Decision:    DR-024
Automation:  Manual
Description: Executed 2026-06-21. DECISIONS/ and
             OUTSTANDING_ACTIONS/ moved from shared
             SYSTEM/ into new APPS/ZYRA/SYSTEM/ folder.
             SYSTEM/ at holding level now contains only
             truly shared governance documents.
             REPORTS/ remains at APPS/ZYRA/ level —
             not inside APPS/ZYRA/SYSTEM/ — single-
             purpose, no internal subfolders needed.
Target:      Completed — DR-024

------------------------------------------------------------

OA-022
Title:       Complete AI Organisation V1 document
Category:    Documentation
Priority:    High
Status:      Completed
Owner:       Lead Architect
Dependencies: None
Decision:    DR-026
Automation:  Manual
Completed:   2026-06-22
Description: Produce SYSTEM/AI_ORGANISATION/AI_ORGANISATION_V1.md
             containing the finalised organisation diagram,
             complete agent inventory with layer placement,
             and individual agent contracts. Each contract
             must include: Mission, Responsibilities,
             Inputs, Outputs, Authority, Boundaries,
             Interactions, Success Criteria, Escalation
             Trigger, Rollback rule, and Iteration Ceiling.
             Architectural Reviewer (ChatGPT) input required
             throughout. Project Owner approves each stage:
             diagram → agent inventory → contracts.
             This document is the prerequisite for all
             Level 4 and Level 5 infrastructure work.
             Design requirements (approved additions):
               • SYSTEM AI vs Application AI separation —
                 AI_ORGANISATION_V1.md must define this as
                 a founding principle. SYSTEM AI agents
                 govern and improve the organisation itself.
                 Application AI agents operate the product.
                 The two categories must never be mixed.
               • System Auditor output format — the System
                 Auditor agent contract must specify that
                 audit reports include Strengths alongside
                 Risks and Opportunities. The report
                 provides an objective organisational
                 assessment, not only criticism.
             COMPLETION NOTE: All 29 agent contracts
             produced, reviewed by ChatGPT across 4
             batches, approved by Project Owner, and
             promoted to V1. Contract template V2
             locked as baseline (DR-036). Four-layer
             architecture locked (DR-036). Phase 1
             contract design complete (DR-037).
             Contracts live in:
               SYSTEM/DOCUMENTS/AGENTS/
               PROJECTS/ZYRA/SYSTEM/AGENTS/
Target:      SYSTEM/AI_ORGANISATION/AI_ORGANISATION_V1.md

------------------------------------------------------------

OA-023
Title:       Build Level 4 — Workflow-driven organisation
             with autonomous routing
Category:    Feature
Priority:    Medium
Status:      Recorded
Owner:       Lead Architect
Dependencies: OA-022
Decision:    None — pending
Automation:  Planned
Description: Implement the Level 4 AI Organisation
             infrastructure in SOURCE/. Requires:
               • Orchestrator agent — deterministic,
                 rule-based routing, reads agent contracts,
                 sequences work, collects outputs. Must
                 never use LLM judgment for routing.
               • Inspection Agent — automates Command 3
                 inspection runs on schedule.
               • Report Generation Agent — produces
                 executive morning report from inspection
                 and operational outputs.
               • Automated scheduled runs — overnight
                 governance workflow as approved in
                 Execution V4 (OA-020).
             Completion of OA-022 (agent contracts) is a
             hard prerequisite. No agent may be built
             without an approved contract.
             At completion ZYRA operates as a
             workflow-driven organisation with autonomous
             routing. Project Owner coordinates direction,
             not individual tasks.
Target:      SOURCE/ — Level 4 implementation

------------------------------------------------------------

OA-024
Title:       Build Level 5 — Event-driven autonomous
             organisation with memory, queues, rollback,
             monitoring and metrics
Category:    Feature
Priority:    Low
Status:      Recorded
Owner:       Lead Architect
Dependencies: OA-023
Decision:    None — pending
Automation:  Planned
Description: Implement the Level 5 AI Organisation
             infrastructure in SOURCE/. Requires five
             components:
               • Memory store — persistent database so
                 agents retain context between sessions.
                 Required for System Auditor trend
                 detection and pattern analysis.
               • Queue system — work items queued,
                 processed reliably, recoverable on
                 failure. Begin with file-based queue,
                 graduate to infrastructure as needed.
               • Rollback — every autonomous agent
                 change made as a discrete, individually
                 reversible Git commit. Connects agent
                 actions to repository version control.
               • Monitoring — real-time visibility into
                 agent activity. Minimum: structured logs.
                 Target: monitoring dashboard.
               • Metrics — defined measurements of agent
                 performance collected over time. Covers:
                 issues resolved, resolution accuracy,
                 time to completion, escalation rate.
             At completion ZYRA operates as a fully
             autonomous event-driven AI organisation.
             Project Owner receives morning reports,
             approves decisions, and sets direction.
             Routine governance runs without coordination.
Target:      SOURCE/ — Level 5 implementation

------------------------------------------------------------

OA-025
Title:       Write Governance V4 — holding company
             structure and two-tier SYSTEM rule
Category:    Governance
Priority:    High
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: OA-019, OA-022
Decision:    DR-025
Automation:  Manual
Description: Write GOVERNANCE_V4.md incorporating all
             governance rules established since V3.
             Minimum required content:
               • Two-tier SYSTEM model (DR-025) —
                 clearly written rule defining:
                 - Shared SYSTEM/ (BLACK UMBRELLA GROUP/SYSTEM/):
                   generic documents applying to all
                   projects. Rule: if it applies to
                   all projects, it belongs here.
                 - Project SYSTEM/ (PROJECTS/[PROJECT]/SYSTEM/):
                   operational documents specific to
                   one project. Rule: if it tracks
                   decisions or actions for one project
                   only, it belongs here.
                 - Examples of each tier with correct
                   paths.
               • SYSTEM AI vs Application AI separation
                 principle — formally define and name
                 the two agent categories:
                 - SYSTEM AI: agents that govern and
                   improve the AI organisation itself
                   (Lead Architect, Architecture Partner,
                   Orchestrator, System Auditor, etc.).
                   These agents never operate the product.
                 - Application AI: agents that operate
                   and grow the product (Marketing,
                   Support, Moderation, Analytics, etc.).
                   These agents never govern the org.
                 - Rule: the two categories must never
                   be mixed. SYSTEM AI agents belong in
                   BLACK UMBRELLA GROUP/SYSTEM/. Application AI
                   agents belong in PROJECTS/[PROJECT]/.
               • AI Organisation governance principles
                 (agent authority, autonomous operation
                 rules, rollback, iteration ceiling) —
                 once OA-022 is complete.
               • Holding company structure reference
                 (DR-023, DR-024, DR-028).
               • V doc cascade detection rule (OA-098):
                 when a master V doc is updated, all
                 dependent V docs are reviewed as a
                 batch. The Impact Analysis Agent maps
                 dependencies; no V doc update is
                 complete without the cascade check.
               • V doc non-update pattern rule (OA-098):
                 the System Auditor flags any V doc
                 not updated across two or more
                 consecutive governance cycles for
                 reclassification review.
               • Pre-production cut-off rule (OA-095):
                 24-hour cut-off before V doc production
                 run; OAs added after cut-off deferred
                 to next cycle unless overridden by
                 Project Owner, Lead Architect, or
                 relevant agent.
             NOTE: OA-022 (AI Organisation V1) must
             be complete before the AI Organisation
             governance section can be written.
             Two-tier SYSTEM rule and SYSTEM AI vs
             Application AI principle can be written
             independently of OA-022.
Target:      SYSTEM/GOVERNANCE/GOVERNANCE_V4.md

------------------------------------------------------------

OA-026
Title:       Define External Reviewer engagement
             protocol
Category:    Governance
Priority:    Medium
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: OA-022
Decision:    DR-026
Automation:  Manual
Description: The External Reviewer (currently ChatGPT)
             sits outside the AI Organisation but has
             no formal engagement protocol. Define and
             document:
               • Who can trigger engagement — Project
                 Owner only, never the Orchestrator
                 or other agents.
               • What triggers engagement — specific
                 conditions that warrant external
                 independent opinion.
               • How outputs enter the governance
                 workflow — External Reviewer outputs
                 are not automatically approved.
                 They enter as proposals requiring
                 Lead Architect assessment and
                 Project Owner approval.
               • What happens to recommendations —
                 each recommendation must either
                 become a Decision Record or be
                 formally declined with reasoning.
               • Frequency limit — External Reviewer
                 must remain an exception, not a
                 standard workflow step.
             Protocol to be written as a section
             within AI_ORGANISATION_V1.md or as a
             standalone document in AI_ORGANISATION/.
Target:      SYSTEM/AI_ORGANISATION/AI_ORGANISATION_V1.md

------------------------------------------------------------

OA-027
Title:       Add Impact Analysis mandatory gate as
             governance rule
Category:    Governance
Priority:    High
Status:      Completed
Owner:       Lead Architect
Dependencies: None
Decision:    None — pending DR
Automation:  Manual
Description: Any significant structural change to the
             repository must produce an Impact Report
             identifying downstream consequences before
             execution is approved. This rule must be
             written into Governance V4 as a mandatory
             gate — not optional, not advisory.
             The rule covers:
               • Folder restructures
               • Document moves or renames
               • Governance rule changes
               • Repository Architecture changes
               • Any change affecting multiple files
                 or cross-references
             The Impact Report must identify:
               • All files affected directly
               • All cross-references that require
                 updating
               • All OAs or DRs that reference
                 changed paths or names
               • Downstream ownership changes
             In the current manual phase this report
             is produced by the Lead Architect before
             execution. At Level 4 the Impact Analysis
             Agent automates it. The governance rule
             applies at both levels.
             NOTE: A Decision Record is required
             before this rule is written into
             Governance V4. Raise with Architectural
             Reviewer (ChatGPT) before drafting.
Target:      SYSTEM/GOVERNANCE/GOVERNANCE_V4.md

------------------------------------------------------------

OA-028
Title:       Define decision provenance logging
             requirement for AI Organisation
Category:    Governance
Priority:    High
Status:      Completed
Owner:       Lead Architect
Dependencies: OA-022
Decision:    None — pending DR
Automation:  Planned
Description: Every decision made within the AI
             Organisation must be logged with full
             provenance. This applies to both human
             and autonomous decisions.
             Every log entry must capture:
               • Who made the decision — Project Owner
                 by name, or the specific agent
                 (e.g. Orchestrator, Inspection Agent,
                 Resolution Classifier)
               • When — timestamp of the decision
               • What — the decision made and what
                 it acted on
               • Why — the rule or basis that
                 authorised the action
               • Outcome — what changed as a result
               • Reversible — yes or no, and how
             This log serves four purposes:
               1. Accountability — every action is
                  traceable to a decision maker
               2. Rollback — trace back to the exact
                  decision to reverse if needed
               3. Audit — Project Owner can review
                  what the AI org decided vs what
                  they approved personally
               4. Pattern analysis — System Auditor
                  uses decision history to detect
                  trends and systemic issues
             In the manual phase the Decision Records
             document partially serves this purpose.
             At Level 4 and beyond, the log must be
             automated and structured.
             This requirement must appear in:
               • Governance V4 — as a mandatory rule
               • Every agent contract — as a logging
                 obligation in the Authority section
               • Level 4 infrastructure — as a built
                 component (OA-023)
             NOTE: Decision Record and ChatGPT input
             required before writing into Governance V4.
Target:      SYSTEM/GOVERNANCE/GOVERNANCE_V4.md
             SYSTEM/AI_ORGANISATION/CONTRACTS/ (all)
             OA-023 (Level 4 build scope)

------------------------------------------------------------

OA-029
Title:       Define command cadence schedule
Category:    Execution
Priority:    High
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: None
Decision:    None — pending
Automation:  Manual
Description: Define a formal schedule specifying which
             commands run at what cadence and who
             triggers them. This schedule must cover
             every active governance command and
             classify each as:
               • Daily / Weekly / Monthly / On-demand
               • Manual (Project Owner triggers) or
                 Automated (runs without intervention)
             Known cadences to formalise:
               • SYSTEM Inspection (Command 3) —
                 weekly. Project Owner runs at start
                 of weekly system session.
               • APP Inspection (Command 3) —
                 daily proposed (OA-020, ChatGPT
                 input required before confirming).
               • SYSTEM document updates — weekly.
                 OA-019, OA-025 and other system
                 document changes are batched and
                 executed in weekly sessions only.
               • AI Organisation work — ongoing,
                 per session as needed.
               • All other commands — define cadence
                 or confirm on-demand only.
             At Level 4 the schedule becomes the
             Orchestrator's run configuration.
             At Level 3 it is a reference document
             the Project Owner follows manually.
             NOTE: Architectural Reviewer (ChatGPT)
             input required before finalising APP
             Inspection cadence (see OA-020).
             Produce as a section in Execution V4.
Target:      SYSTEM/EXECUTION/EXECUTION_V4.md

------------------------------------------------------------

OA-030
Title:       Rename APPS/ to PROJECTS/ — execute
             and update path references
Category:    Repository
Priority:    High
Status:      Completed
Owner:       Lead Architect
Dependencies: None
Decision:    DR-028
Automation:  Manual
Description: Rename BLACK UMBRELLA GROUP/APPS/ to BLACK UMBRELLA GROUP/PROJECTS/.
             Update path references in active documents:
               • OUTSTANDING_ACTIONS_V2.md — OA-022
                 description path corrected (already done
                 as part of this session).
               • REPOSITORY_ARCHITECTURE_V2.md — all
                 APPS/ paths to become PROJECTS/ (scoped
                 to OA-019, not this action).
             Historical Decision Records (DR-023, DR-024,
             DR-025, DR-027) retain APPS/ paths per the
             immutability principle. DR-028 is the
             authoritative record of the rename.
             Folder rename executed 2026-06-22.
Target:      Completed — DR-028

------------------------------------------------------------

OA-031
Title:       Design Project Readiness Agent — per-project
             forward blocker reporting
Category:    Documentation
Priority:    Medium
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: OA-022
Decision:    None — pending DR
Automation:  Manual
Description: Design and contract a new SYSTEM AI agent
             that monitors project momentum and surfaces
             forward blockers to the Project Owner.
             Distinct from the System Auditor (which
             assesses governance health) — this agent
             assesses what each project needs next to
             move forward.
             The agent has two output types:
               • Internal — routine gaps, missing files,
                 documentation debt. Handled autonomously
                 or via the standard workflow. Project
                 Owner never sees this noise.
               • Project Owner report — forward blockers
                 only. Causal, sequential, decision-
                 dependent items that require Project
                 Owner input to unblock. Framed as:
                 "To continue this project, X must be
                 defined/decided." Example:
                   - Pricing not defined →
                     blocks Premium flow, Profile Unlocks
                   - Wali onboarding missing →
                     blocks Matching flow
                   - Homepage not designed →
                     blocks UI build phase
             Scope: runs per project, produces one
             report section per active project in
             BLACK UMBRELLA GROUP/PROJECTS/. One agent covers all
             projects.
             Naming TBC — candidate: Project Readiness
             Agent or Next Step Reporter.
             Contract to be written as part of OA-022.
Target:      SYSTEM/AI_ORGANISATION/AI_ORGANISATION_V1.md

------------------------------------------------------------

OA-032
Title:       Define PA (Personal Assistant) — Owner
             Interface Agent role for Level 4
Category:    Governance
Priority:    Medium
Status:      Completed
Owner:       Lead Architect
Dependencies: OA-022
Decision:    None — pending DR
Automation:  Planned
Description: Define the Chief of Staff as a Level 4
             agent role. At Level 3 the distinction
             between an interface agent and the Lead
             Architect is conceptual only — both are
             the same underlying AI instance with no
             real routing between them. The role becomes
             genuinely valuable at Level 4 when separate
             agent instances exist.
             Role definition to cover:
               • Communicates Project Owner intent to
                 the Lead Architect and agents. Does
                 not design or propose architecture.
               • Detects whether a conversation is
                 SYSTEM or APP in scope and flags
                 cross-context drift to the Project Owner.
               • When Project Owner ends a session,
                 briefs the Lead Architect on what was
                 discussed and what needs actioning.
               • Holds no independent authority —
                 exists to communicate, not to decide.
             Authority boundaries vs Lead Architect
             must be explicitly defined in the contract
             before adoption. Requires ChatGPT review
             and a DR before the role is formally
             introduced into the governance model.
             Preparation phase (approved addition):
               • Before execution begins each session,
                 the Chief of Staff prepares context by
                 identifying affected systems, affected
                 documents, relevant Decisions, Outstanding
                 Actions, and governing references.
               • The Lead Architect begins each execution
                 session with verified context rather than
                 reconstructed memory. This is the
                 architectural implementation of the
                 Context Before Action principle (DR-029).
             NOTE: This is a Level 4 implementation.
             Do not activate at Level 3.
Target:      SYSTEM/DOCUMENTS/AGENT_CONTRACTS/

------------------------------------------------------------

OA-033
Title:       Define End-of-Input Command — agent
             shift briefing trigger
Category:    Execution
Priority:    Medium
Status:      Recorded
Owner:       Lead Architect
Dependencies: OA-022, OA-025
Decision:    None — pending DR
Automation:  Planned
Description: Define a command the Project Owner uses
             to signal end of their input for a session.
             When triggered, agents begin their shift —
             coordinating and working through current
             OAs without further Project Owner input.
             Behaviour:
               • Any day (no scheduled commands):
                 agents coordinate and work through
                 current outstanding actions relevant
                 to that session.
               • Scheduled days: same coordination
                 plus the scheduled commands for that
                 day are included in the shift (e.g.
                 Inspection on scheduled inspection days).
               • Modelled as a pre-shift managers
                 briefing — agents align on current
                 state before work begins.
             Command number and name TBC. To be defined
             in Execution V4 alongside the full command
             cadence schedule (OA-029).
             NOTE: Requires Level 4 infrastructure to
             function autonomously. At Level 3 this
             would be a manual trigger with the Lead
             Architect coordinating the shift.
Target:      SYSTEM/EXECUTION/EXECUTION_V4.md

------------------------------------------------------------

OA-034
Title:       Define split-chat trigger criteria and
             reminder mechanism
Category:    Governance
Priority:    Low
Status:      Recorded
Owner:       Lead Architect
Dependencies: OA-032
Decision:    None — pending DR
Automation:  Manual
Description: Define the conditions that signal it is
             time for the Project Owner to create
             separate SYSTEM and ZYRA Cowork sessions
             rather than operating from one session.
             Trigger criteria (proposed — to be
             confirmed with Architectural Reviewer):
               • Sessions regularly involve both
                 active product work (ZYRA features,
                 code) and active governance work
                 (agent contracts, architecture docs)
                 creating context overload.
               • Level 4 infrastructure is operational
                 so the Chief of Staff (OA-032) can
                 handle real routing between sessions.
               • A second active project exists under
                 BLACK UMBRELLA GROUP/PROJECTS/ requiring its own
                 session scope.
             Reminder mechanism: Lead Architect flags
             the trigger to the Project Owner when
             session patterns indicate the criteria
             are being met. Project Owner decides
             whether to split at that point.
             Scope of each session when split:
               • SYSTEM session — touches only
                 BLACK UMBRELLA GROUP/SYSTEM/. No project folders.
               • ZYRA session — touches only
                 BLACK UMBRELLA GROUP/PROJECTS/ZYRA/. No SYSTEM
                 folders.
             Cross-context detection: if Project Owner
             raises a SYSTEM topic in a ZYRA session,
             the agent flags it, logs it as an OA,
             and routes it for the SYSTEM session.
Target:      SYSTEM/GOVERNANCE/GOVERNANCE_V4.md

------------------------------------------------------------

OA-035
Title:       Add Context Before Action as operational
             principle to GOVERNANCE and EXECUTION
Category:    Governance
Priority:    High
Status:      Completed
Owner:       Lead Architect
Dependencies: DR-029
Decision:    DR-029
Automation:  Manual
Description: Add Context Before Action as a new
             operational principle to GOVERNANCE V4
             and EXECUTION V4. The principle:
             Before any governed work begins, the
             responsible agent shall identify every
             authoritative document governing the
             requested work and consult those documents
             before any decision is made. The first
             question is always: what governs this task?
             This protects decision integrity and sits
             alongside Read Before Write (document
             integrity). Queued for next version batch.
Target:      SYSTEM/DOCUMENTS/GOVERNANCE/GOVERNANCE_V4.md
             SYSTEM/DOCUMENTS/EXECUTION/EXECUTION_V4.md

------------------------------------------------------------

OA-036
Title:       Add Authoritative References section to
             agent contract template; retrofit existing
             contracts
Category:    Governance
Priority:    High
Status:      Completed
Owner:       Lead Architect
Dependencies: DR-029, OA-035
Decision:    DR-029
Automation:  Manual
Description: Add mandatory Authoritative References
             section to the agent contract template.
             Two tiers:
               Always Consult — documents required
               before every execution of this agent.
               Consult When Applicable — domain-specific
               documents required only when the task
               enters that governed area.
             Retrofit to ORCHESTRATOR_V2.md and
             SYSTEM_AUDITOR_V1.md. All future contracts
             must include this section at time of writing.
Target:      SYSTEM/RESOURCES/TEMPORARY FOLDER/CONTRACT_TEMPLATE_V1.md
             SYSTEM/DOCUMENTS/AGENT_CONTRACTS/ORCHESTRATOR/ORCHESTRATOR_V2.md
             SYSTEM/DOCUMENTS/AGENT_CONTRACTS/SYSTEM_AUDITOR/SYSTEM_AUDITOR_V1.md

------------------------------------------------------------

OA-037
Title:       Add auditable consultation logging to
             execution workflow
Category:    Execution
Priority:    High
Status:      Completed
Owner:       Lead Architect
Dependencies: DR-029, OA-035
Decision:    DR-029
Automation:  Planned
Description: Each workflow run must log: governing
             documents consulted, document versions at
             time of consultation, and consultation
             timestamp. Provides objective evidence for
             the System Auditor. To be defined in
             EXECUTION V4 as a mandatory workflow
             pre-step.
Target:      SYSTEM/DOCUMENTS/EXECUTION/EXECUTION_V4.md

------------------------------------------------------------

OA-038
Title:       Clarify position of Decision Records in
             the authority hierarchy
Category:    Governance
Priority:    Medium
Status:      Completed
Owner:       Lead Architect
Dependencies: None
Decision:    None — pending DR
Automation:  Manual
Description: The current authority hierarchy does not
             explicitly position Decision Records. DRs
             are authoritative explanatory records that
             influence future implementation but do not
             override GOVERNANCE. Their relationship to
             the hierarchy must be documented to prevent
             ambiguity. To be added to GOVERNANCE V4.
Target:      SYSTEM/DOCUMENTS/GOVERNANCE/GOVERNANCE_V4.md

------------------------------------------------------------

OA-039
Title:       Document standard SYSTEM document lifecycle
             in EXECUTION
Category:    Execution
Priority:    Medium
Status:      Completed
Owner:       Lead Architect
Dependencies: None
Decision:    None — pending DR
Automation:  Manual
Description: No formal lifecycle exists for a SYSTEM
             document progressing from idea to active
             baseline. Define in EXECUTION V4:
               Proposal → Draft → Independent Review
               → Project Owner Approval → Published
               Baseline → Archived Version
Target:      SYSTEM/DOCUMENTS/EXECUTION/EXECUTION_V4.md

------------------------------------------------------------

OA-040
Title:       Migrate DECISIONS and OUTSTANDING_ACTIONS
             entries to correct SYSTEM or project level
Category:    Governance
Priority:    High
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: DR-031
Decision:    DR-031
Automation:  Manual
Description: Audit all entries in DECISIONS_V1.md and
             OUTSTANDING_ACTIONS_V2.md. Classify each
             as system-level or ZYRA-specific.
             System-level entries move to new documents
             in BLACK UMBRELLA GROUP/SYSTEM/DECISIONS/ and
             BLACK UMBRELLA GROUP/SYSTEM/OUTSTANDING_ACTIONS/.
             ZYRA-specific entries remain in
             PROJECTS/ZYRA/SYSTEM/. Both sets created
             as new V1 files. Existing documents archived
             once migration is complete.
Target:      SYSTEM/DECISIONS/
             SYSTEM/OUTSTANDING_ACTIONS/
             PROJECTS/ZYRA/SYSTEM/DECISIONS/
             PROJECTS/ZYRA/SYSTEM/OUTSTANDING_ACTIONS/

------------------------------------------------------------

OA-041
Title:       Update REPOSITORY_ARCHITECTURE to reflect
             SYSTEM folder renames and DOCUMENTS rule
Category:    Architecture
Priority:    High
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: DR-030
Decision:    DR-030
Automation:  Manual
Description: REPOSITORY_ARCHITECTURE V2 must reflect:
               DOCS/            → DOCUMENTS/
               SUPPORT/         → RESOURCES/
               AI_ORGANISATION/ → AGENT_CONTRACTS/
             New rule: DOCUMENTS/ contains foundational
             system documents only — no planning docs,
             working files, or ideas.
             New structure: DECISIONS/ and
             OUTSTANDING_ACTIONS/ at SYSTEM level.
Target:      SYSTEM/DOCUMENTS/ARCHITECTURE/REPOSITORY_ARCHITECTURE_V2.md

------------------------------------------------------------

OA-042
Title:       Add co-work session temporary principle
             to GOVERNANCE
Category:    Governance
Priority:    High
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: None
Decision:    None — pending DR
Automation:  Manual
Description: Add the following principle to GOVERNANCE V4:
             A co-work session is temporary. Authoritative
             knowledge belongs in the repository, not the
             conversation. When a project reaches a
             significant milestone or conversation quality
             degrades, a new co-work session should be
             started using the latest approved SYSTEM
             documents as the initial context.
             This reinforces that no session is a source
             of truth and prevents knowledge loss at
             session boundaries.
Target:      SYSTEM/DOCUMENTS/GOVERNANCE/GOVERNANCE_V4.md

------------------------------------------------------------

OA-043
Title:       Add real-time logging discipline to
             GOVERNANCE and EXECUTION
Category:    Governance
Priority:    High
Status:      Completed
Owner:       Lead Architect
Dependencies: None
Decision:    None — pending DR
Automation:  Manual
Description: Add the following rule to GOVERNANCE V4
             and EXECUTION V4:
             The Lead Architect logs all approved
             decisions and outstanding actions in the
             same session they are made. Where a
             loggable item arises and the Project Owner
             has not confirmed logging, the Lead Architect
             carries the item forward to the next
             response until it is logged. No session
             ends with unlogged approved decisions or
             actions.
             This prevents the accumulation of unlogged
             decisions across sessions and ensures the
             repository remains the authoritative record.
Target:      SYSTEM/DOCUMENTS/GOVERNANCE/GOVERNANCE_V4.md
             SYSTEM/DOCUMENTS/EXECUTION/EXECUTION_V4.md

------------------------------------------------------------

OA-044
Title:       Confirm QA Agent rename before contract
             is written
Category:    Governance
Priority:    Medium
Status:      Completed
Owner:       Project Owner
Dependencies: OA-022
Decision:    None
Automation:  Manual
Description: The QA Agent name is under review.
             Leading candidate is Output Review Agent,
             which more precisely describes the function.
             Project Owner must confirm the name before
             the contract is written. No contract is
             drafted until the name is approved.
             COMPLETED: Project Owner confirmed
             Output Review Agent as the name 2026-06-22.
             Contracts written under this name.
Target:      SYSTEM/DOCUMENTS/AGENT_CONTRACTS/

------------------------------------------------------------

OA-045
Title:       Add Strategic Leadership 4-member upper
             limit to governance
Category:    Governance
Priority:    Medium
Status:      Completed
Owner:       Lead Architect
Dependencies: None
Decision:    None — pending DR
Automation:  Manual
Description: The Strategic Leadership layer has an
             approved upper limit of four members.
             Expansion beyond four requires clear
             justification and goes through the normal
             governance process. This must be formally
             documented in GOVERNANCE V4 rather than
             remaining only in session history.
Target:      SYSTEM/DOCUMENTS/GOVERNANCE/GOVERNANCE_V4.md

------------------------------------------------------------

OA-046
Title:       Confirm rename of AGENT_CONTRACTS folder
Category:    Repository
Priority:    Low
Status:      Completed
Owner:       Project Owner
Dependencies: DR-030
Decision:    DR-030
Automation:  Manual
Description: The AI_ORGANISATION folder was renamed to
             AGENT_CONTRACTS (DR-030). Project Owner
             deferred a further rename in the same
             session. Revisit whether AGENT_CONTRACTS
             is the final name or whether a different
             name is preferred before Repository
             Architecture V2 is written.
Target:      SYSTEM/DOCUMENTS/ARCHITECTURE/REPOSITORY_ARCHITECTURE_V2.md

------------------------------------------------------------

OA-047
Title:       Add auto-logging rule and conflict
             detection to GOVERNANCE and EXECUTION
Category:    Governance
Priority:    High
Status:      Completed
Owner:       Lead Architect
Dependencies: OA-043
Decision:    None — pending DR
Automation:  Planned
Description: Extend the logging discipline (OA-043)
             with two additional rules to be added
             to GOVERNANCE V4 and EXECUTION V4:

             Rule 1 — Auto-logging:
             The Lead Architect logs all decisions and
             actions as DRs and OAs the moment they are
             agreed in conversation, without waiting for
             Project Owner confirmation. Logging is not
             optional and does not require a prompt.

             Rule 2 — Conflict detection and flagging:
             If two logged items conflict — whether
             auto-logged or previously approved — the
             conflict is flagged immediately by the
             appropriate governance agent (initially
             the System Auditor, at Level 3 by the
             Lead Architect). The conflict is never
             resolved unilaterally.

             Resolution model by level:
               Level 3 (current): Project Owner
               confirms which item takes precedence.
               Level 4+: a designated agent may propose
               resolution autonomously, subject to
               Project Owner approval before execution.

             This ensures the repository remains
             conflict-free and that errors caught in
             conversation are still recorded, flagged,
             and properly resolved — even if they were
             logged before the error was identified.
Target:      SYSTEM/DOCUMENTS/GOVERNANCE/GOVERNANCE_V4.md
             SYSTEM/DOCUMENTS/EXECUTION/EXECUTION_V4.md

------------------------------------------------------------

OA-048
Title:       Create SYSTEM/LOGS/ area for autonomous
             execution records
Category:    Architecture
Priority:    Medium
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: OA-022
Decision:    None — pending DR
Automation:  Planned
Description: Introduce BLACK UMBRELLA GROUP/SYSTEM/LOGS/ as a
             dedicated area for execution records
             produced by agents during autonomous
             operation. Distinct from RESOURCES/REPORTS/
             (governance findings) and DOCUMENTS/
             (governing documents).
             Each agent owns its own log subfolder:
               LOGS/ORCHESTRATOR/
               LOGS/REPOSITORY_AGENT/
               LOGS/DOCUMENTATION_AGENT/
               LOGS/INSPECTION_AGENT/
               LOGS/SYSTEM_AUDITOR/
             Logs contain: routing decisions, read/write
             history, execution timestamps, and document
             versions consulted. Purpose is governance,
             traceability, and accountability — not
             debugging. Enables the System Auditor to
             audit execution objectively.
             Logging responsibilities must be defined
             in each agent contract before the LOGS/
             structure is finalised. Consider while
             remaining contracts are being designed.
Target:      SYSTEM/LOGS/
             All remaining agent contracts

------------------------------------------------------------

OA-049
Title:       Log DECISIONS_REGISTER and MASTER naming
             renames in Repository Architecture V2
Category:    Architecture
Priority:    High
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: DR-032, DR-033, OA-041
Decision:    DR-032, DR-033
Automation:  Manual
Description: OA-041 scope extended. Repository
             Architecture V2 must also document:
               DECISIONS/ → DECISIONS_REGISTER/
               GOVERNANCE/ → MASTER_GOVERNANCE/
               EXECUTION/ → MASTER_EXECUTION/
               ARCHITECTURE/ → MASTER_ARCHITECTURE/
             And establish the MASTER_ naming convention
             as the standard for all future Black Umbrella Group-
             level governing document folders.
Target:      SYSTEM/DOCUMENTS/MASTER_ARCHITECTURE/REPOSITORY_ARCHITECTURE_V2.md

------------------------------------------------------------

OA-050
Title:       Add Scope field to agent contract template
             and retrofit existing contracts
Category:    Governance
Priority:    High
Status:      Completed
Owner:       Lead Architect
Dependencies: OA-036
Decision:    None — pending DR
Automation:  Manual
Description: The agent contract template does not
             currently declare whether an agent
             operates at SYSTEM level, PROJECT level,
             or is restricted to a specific project.
             Add a mandatory Scope field to the
             template header:
               Scope: SYSTEM / PROJECT:[name] / BOTH
             BOTH is not a valid scope — it is a
             trigger to split into two separate agents
             (see OA-051). Retrofit to ORCHESTRATOR_V2
             and SYSTEM_AUDITOR_V1.
Target:      SYSTEM/RESOURCES/TEMPORARY/CONTRACT_TEMPLATE_V1.md
             SYSTEM/DOCUMENTS/AGENT_CONTRACTS/ORCHESTRATOR/ORCHESTRATOR_V2.md
             SYSTEM/DOCUMENTS/AGENT_CONTRACTS/SYSTEM_AUDITOR/SYSTEM_AUDITOR_V1.md

------------------------------------------------------------

OA-051
Title:       Establish two-agent rule for functions
             spanning SYSTEM and PROJECT scope
Category:    Governance
Priority:    High
Status:      Completed
Owner:       Lead Architect
Dependencies: OA-050
Decision:    None — pending DR
Automation:  Manual
Description: Where an agent function is needed at both
             SYSTEM and PROJECT level, two separate
             agents must be contracted — one per scope.
             They may share the same pattern but are
             distinct agents with distinct access,
             authority, and escalation paths.
             Rationale:
               • SYSTEM AI and Application AI must
                 never be mixed (DR-025).
               • Authority differs — SYSTEM agents
                 may access MASTER_ documents; PROJECT
                 agents must not.
               • Escalation differs — SYSTEM failures
                 and PROJECT failures route differently.
               • Audit trail — the System Auditor
                 must distinguish SYSTEM from PROJECT
                 changes cleanly.
             Agents affected (contracts not yet written):
               Documentation Agent → SYSTEM + PROJECT
               Repository Agent → SYSTEM + PROJECT
               Inspection Agent → SYSTEM + PROJECT
               Reporting Agent → SYSTEM + PROJECT
             Each must be written as two contracts.
             This rule must be added to GOVERNANCE V4.
Target:      SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/GOVERNANCE_V4.md
             All future agent contracts

------------------------------------------------------------

OA-052
Title:       Define agent scope tiers and add to
             contract template and GOVERNANCE
Category:    Governance
Priority:    High
Status:      Completed
Owner:       Lead Architect
Dependencies: OA-050, OA-051
Decision:    None — pending DR
Automation:  Manual
Description: Two distinct scope tiers exist for agents:

             ORGANISATION scope:
               Governance and strategic roles that
               operate across the entire Black Umbrella Group
               organisation by design. Cannot be split
               per project. One contract only.
               Examples: Lead Architect, Chief of Staff,
               System Auditor.

             SYSTEM / PROJECT scope:
               Operational and processing roles that
               execute work within a defined scope.
               Authority and access must be constrained
               to that scope. One contract per scope.
               A PROJECT-scoped version is written per
               project as that project comes online.
               Examples: Documentation Agent, Repository
               Agent, Inspection Agent, Reporting Agent.

             Add the Scope field to the contract
             template with three valid values:
               ORGANISATION
               SYSTEM
               PROJECT:[project name]

             BOTH is not valid — it is a trigger to
             split into two separate contracts.

             This distinction and the Scope field must
             be added to GOVERNANCE V4 as a governing
             rule for all agent contracts.
Target:      SYSTEM/RESOURCES/TEMPORARY/CONTRACT_TEMPLATE_V1.md
             SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/GOVERNANCE_V4.md

------------------------------------------------------------

OA-053
Title:       Update OA-051 and OA-052 — two separate
             agents confirmed over dual-mode
Category:    Governance
Priority:    High
Status:      Completed
Owner:       Lead Architect
Dependencies: OA-051, OA-052
Decision:    None — pending DR
Automation:  Manual
Description: Dual-mode agent concept rejected.
             Confirmed decision: operational agents
             that work across both SYSTEM and PROJECT
             scope are built as two separate agents,
             one per scope. Rationale:
               • SYSTEM AI vs Application AI principle
                 (DR-025) — the two categories must
                 not be mixed in a single agent.
               • Access — a SYSTEM agent cannot
                 physically access PROJECT documents
                 and vice versa. Dual-mode removes
                 this protection.
               • Blast radius — a failure in PROJECT
                 scope cannot affect SYSTEM documents
                 if they are separate agents.
               • Audit trail — System Auditor
                 distinguishes SYSTEM from PROJECT
                 activity cleanly.
               • Divergence — PROJECT agents will
                 accumulate project-specific rules
                 over time; SYSTEM agents will not.
             Updated agent count:
               5 ORGANISATION agents (1 contract each)
               6 operational functions requiring both
               SYSTEM and PROJECT agents (2 contracts
               each — 1 SYSTEM written once, 1 PROJECT
               written per project)
               1 PROJECT-only agent (1 per project)
             Total for ZYRA: 18 contracts.
             Each new project adds 7 contracts.
             OA-051 and OA-052 superseded by this entry.
Target:      All remaining agent contracts

------------------------------------------------------------

OA-054
Title:       Add missing operational rules to
             GOVERNANCE V4 Section 10
Category:    Governance
Priority:    High
Status:      Completed
Owner:       Lead Architect
Dependencies: OA-043, OA-047
Decision:    None — pending DR
Automation:  Manual
Description: Recurring operational behaviours agreed
             during sessions belong in GOVERNANCE
             Section 10 (Operational Rules), not in
             a separate document. A separate document
             would duplicate GOVERNANCE and violate
             the Single Source of Truth principle.
             The Chief of Staff surfaces the relevant
             GOVERNANCE sections as part of the session
             briefing — it does not own a separate
             agreements document.
             Rules to be added to GOVERNANCE V4
             Section 10:
               • Auto-log all OAs and DRs immediately
                 without waiting for confirmation.
               • Typos are fixed directly without
                 raising an OA or seeking approval.
               • When a ChatGPT recommendation is
                 accepted, do not reply — log and
                 continue.
               • Any agreed operational preference
                 that must persist across sessions is
                 added to GOVERNANCE, not held in
                 conversational memory.
Target:      SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/GOVERNANCE_V4.md

------------------------------------------------------------

OA-055
Title:       Add operational agreements surfacing to
             Chief of Staff session briefing
Category:    Governance
Priority:    High
Status:      Completed
Owner:       Lead Architect
Dependencies: OA-054, OA-032
Decision:    None — pending DR
Automation:  Planned
Description: The Chief of Staff session briefing
             (OA-032) must include active operational
             agreements as a mandatory component.
             Full session briefing pack:
               • Current Outstanding Actions
               • Current Decisions relevant to session
               • Active operational agreements
               • Required governing references
               • Session context and declared purpose
             The Lead Architect begins every session
             from documented context, not reconstructed
             memory. This is the architectural
             implementation of Context Before Action
             (DR-029) at the session level.
Target:      SYSTEM/DOCUMENTS/AGENT_CONTRACTS/
             (Chief of Staff contract when written)

------------------------------------------------------------

OA-056
Title:       Define base role + scoped implementation
             model for operational agent contracts
Category:    Governance
Priority:    High
Status:      Completed
Owner:       Lead Architect
Dependencies: OA-053
Decision:    None — pending DR
Automation:  Manual
Description: Operational agents that exist across
             multiple scopes (SYSTEM + PROJECT) must
             follow a three-tier contract model:

             Base Role:
               Defines the agent's common mission,
               core principles, and core responsibilities.
               Written once. Applies to all scoped
               implementations. Lives in AGENT_CONTRACTS/
               under a BASE_ROLES/ subfolder.

             SYSTEM Implementation:
               Extends the base role with SYSTEM-specific
               access, authority, escalation rules, and
               success criteria.

             PROJECT Implementation:
               Extends the base role with project-specific
               access, permissions, and behaviour.
               Written per project.

             This preserves the separation between SYSTEM
             and PROJECT agents while preventing duplication
             of core mission and responsibilities. If the
             core function of an agent changes, only the
             base role is updated — all implementations
             inherit the change automatically.

             Must be defined before any operational
             agent contracts are written. The contract
             template must be updated to reflect this
             three-tier structure (OA-036 scope extended).

             Agents affected:
               Inspection Agent
               Documentation Agent
               Repository Agent
               Reporting Agent
               Impact Analysis Agent
               Resolution Classifier
Target:      SYSTEM/DOCUMENTS/AGENT_CONTRACTS/BASE_ROLES/
             SYSTEM/RESOURCES/TEMPORARY/CONTRACT_TEMPLATE_V1.md

------------------------------------------------------------

OA-057
Title:       Add numbered draft status convention to
             Governance V4
Category:    Governance
Priority:    Low
Status:      Completed
Owner:       Lead Architect
Dependencies: None
Decision:    None — pending DR
Automation:  Manual
Description: When producing a draft document, the status
             field must include a sequential number to
             identify which iteration of the draft it is.
             Format: Draft 1, Draft 2, Draft 3, etc.
             This applies to all draft documents across
             the project. Prevents ambiguity when multiple
             draft rounds occur before approval.
             To be added to Governance V4 as a formal
             naming convention rule.
Target:      SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/GOVERNANCE_V4.md

------------------------------------------------------------

OA-058
Title:       Add document placement guidance to
             Architecture Partner contract
Category:    Governance
Priority:    Medium
Status:      Recorded
Owner:       Lead Architect
Dependencies: OA-022
Decision:    None — pending DR
Automation:  Manual
Description: The Architecture Partner contract must
             include a responsibility to flag when the
             Project Owner directs work to the wrong
             document or location. When this occurs,
             the Architecture Partner proactively states
             where the content actually belongs and why,
             before any filing occurs. Example: Project
             Owner says "add to Governance" — Architecture
             Partner flags that it belongs in an OA
             instead, with a brief explanation.
             This keeps the Project Owner informed without
             requiring them to recall document boundaries
             from memory in every session.
Target:      SYSTEM/DOCUMENTS/AGENT_CONTRACTS/
             (Architecture Partner contract — OA-022)

------------------------------------------------------------

OA-059
Title:       PA to present ChatGPT review responses
             with accept/reject indicators
Category:    Governance
Priority:    Medium
Status:      Recorded
Owner:       Lead Architect
Dependencies: OA-032
Decision:    None — pending DR
Automation:  Planned
Description: When a ChatGPT review response is received,
             each point must be presented to the Project
             Owner with a visible ✓ (accepted) or ✗
             (rejected) indicator alongside the Lead
             Architect's assessment. This makes it
             faster for the Project Owner to scan and
             confirm without reading full prose for
             each point.
             At Level 3 this is the Lead Architect's
             responsibility. At Level 4 the PA owns
             the ChatGPT liaison workflow — receiving
             the review, presenting it with indicators,
             and surfacing the Project Owner's
             confirmation back to the Lead Architect.
             Three-state indicator system:
               ✓  Accepted — full agreement
               -  Partial — accepted with modification
               ✗  Rejected — not accepted, with reason
             OA-032 (PA contract) must include this
             liaison responsibility explicitly.
Target:      OA-032 (PA contract)
             SYSTEM/DOCUMENTS/AGENT_CONTRACTS/
             (PA contract when written)

------------------------------------------------------------

OA-060
Title:       Add template versioning rule to Governance V4
Category:    Governance
Priority:    Medium
Status:      Completed
Owner:       Lead Architect
Dependencies: None
Decision:    None — pending DR
Automation:  Manual
Description: Templates must not receive a version number
             (V1, V2, etc.) until they are confirmed and
             approved. Pre-approval iterations use Draft
             numbering only (Draft 1, Draft 2, etc.).
             Upon approval, the first confirmed version
             becomes V1. This rule applies to all
             templates across the project.
             To be added to Governance V4 as a formal
             naming and versioning rule.
Target:      SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/GOVERNANCE_V4.md

------------------------------------------------------------

OA-061
Title:       Move CONTRACT_TEMPLATE to
             AGENT_CONTRACTS/ folder
Category:    Repository
Priority:    Medium
Status:      Completed
Owner:       Lead Architect
Dependencies: None
Decision:    None
Automation:  Manual
Description: CONTRACT_TEMPLATE_V2.md is currently filed
             in SYSTEM/RESOURCES/TEMPORARY/. Its permanent
             home should be SYSTEM/DOCUMENTS/AGENT_CONTRACTS/
             alongside the contracts it governs.
             Move the file and update any path references.
Target:      SYSTEM/DOCUMENTS/AGENT_CONTRACTS/
             CONTRACT_TEMPLATE_V2.md

------------------------------------------------------------

OA-062
Title:       Add V doc dedicated folder rule to
             Governance V4
Category:    Governance
Priority:    Medium
Status:      Completed
Owner:       Lead Architect
Dependencies: None
Decision:    None — pending DR
Automation:  Manual
Description: Every V doc must live in its own dedicated
             folder. A V doc must never sit loose inside
             a parent folder alongside unrelated files.
             Exception: where a master folder contains
             dedicated subfolders (e.g. AGENT_CONTRACTS/
             with one subfolder per agent), that
             structure is accepted provided every V doc
             has its own subfolder. No V doc may share
             a folder with another V doc unless they
             are in separate subfolders.
             To be added to Governance V4 as a formal
             repository structure rule.
Target:      SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/GOVERNANCE_V4.md

------------------------------------------------------------

OA-063
Title:       Add review and handover document placement
             rule to Governance V4
Category:    Governance
Priority:    Medium
Status:      Completed
Owner:       Lead Architect
Dependencies: None
Decision:    None — pending DR
Automation:  Manual
Description: Any document produced for external review
             or handover (e.g. ChatGPT review briefs,
             handover notes, review summaries) must be
             filed in SYSTEM/RESOURCES/TEMPORARY/ with
             a date in the filename. These are never V
             docs. Naming convention:
               [DOCUMENT_NAME]_[YYYY-MM-DD].md
             If more than one review or handover document
             is produced on the same day, each file is
             suffixed with a part number:
               [DOCUMENT_NAME]_[YYYY-MM-DD]_Part1.md
               [DOCUMENT_NAME]_[YYYY-MM-DD]_Part2.md
             These documents must never be filed in
             DOCUMENTS/ or alongside governed documents
             such as agent contracts.
             To be added to Governance V4 as a formal
             document placement rule.
Target:      SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/GOVERNANCE_V4.md

------------------------------------------------------------

OA-064
Title:       Add action traceability rule to Governance V4
             and all agent contracts
Category:    Governance
Priority:    High
Status:      Completed
Owner:       Lead Architect
Dependencies: OA-028
Decision:    None — pending DR
Automation:  Planned
Description: Every action taken by any agent must be
             traceable to a specific V doc and rule.
             When the Project Owner questions why an agent
             did something — regardless of whether they
             believe it was a mistake — the agent or the
             PA (at Level 4) must respond with one of
             two answers only:

             Answer A — Governing document exists:
               "This action was taken because [V doc name],
               [version], [section/rule]."

             Answer B — No governing document exists:
               "There is no governing document that covers
               this action."

             The trigger is any question of the form
             "why did it do that?" — not only suspected
             errors. The agent may have acted correctly.
             The Project Owner still needs to know the
             rule so they can decide whether the rule
             itself is right.

             This distinction matters because the fix
             differs:
               Answer A — Project Owner reviews the rule.
               If they agree with it, no action needed.
               If they disagree, the V doc is updated.
               The agent followed the rule correctly.
               Answer B — No rule governed the action.
               An OA is raised to add the missing rule
               to the appropriate V doc so the gap is
               closed for future runs.

             This principle must be added to Governance V4
             as a mandatory rule. It must also appear in
             every agent contract as a traceability
             obligation — agents must log which V doc
             and which rule authorised every action.

             At Level 3: the Lead Architect holds this
             traceability obligation and responds directly
             when questioned.
             At Level 4: the PA owns the question-response
             workflow — receives the Project Owner's
             question, identifies the governing V doc
             reference (or confirms none exists), and
             presents the finding to the Project Owner.

             This rule is the audit-facing complement to
             the Context Before Action principle (DR-029)
             — Context Before Action governs what agents
             must consult before acting; this rule governs
             what they must be able to reference after
             acting.

Target:      SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/GOVERNANCE_V4.md
             All agent contracts (as traceability obligation)
             PA contract (question-response workflow)

------------------------------------------------------------

OA-065
Title:       Migrate operational records to daily log
             format and update Reporting Agent and
             Repository Agent contracts
Category:    Governance
Priority:    High
Status:      Completed
Owner:       Lead Architect
Dependencies: OA-040, DR-035
Decision:    DR-035
Automation:  Planned
Description: DR-035 confirms operational records
             (OUTSTANDING_ACTIONS and DECISIONS) are
             daily logs, not V docs. This OA covers
             the work required:

             1. Update OA-040 scope:
                SYSTEM-level migration produces daily
                log files named by date, not V1 docs.
                Format: [NAME]_[YYYY-MM-DD].md

             2. Migrate existing ZYRA documents:
                OUTSTANDING_ACTIONS_V2.md and
                DECISIONS_V1.md to be split into
                dated daily log files as part of the
                OA-040 migration. Archive the existing
                V docs once migration is complete.

             3. Update Reporting Agent contracts
                (Base Role, SYSTEM, PROJECT:ZYRA):
                Add daily log writing as a core
                responsibility. The Reporting Agent
                creates and populates one log entry
                per day covering decisions made and
                actions raised that day.

             4. Update Repository Agent contracts
                (Base Role, SYSTEM, PROJECT:ZYRA):
                Add daily log file creation as a
                responsibility. The Repository Agent
                creates the dated file; the Reporting
                Agent writes the content.

             5. Add daily log rule to Governance V4:
                Operational records are daily logs.
                V docs are for governed baseline
                documents only. No operational record
                may be filed as a V doc.

             6. Lead Architect to be aware:
                At Level 3 the Lead Architect is
                responsible for daily log entries
                until the Reporting Agent is active.

Target:      OA-040 (scope update)
             Base Role contracts — Reporting Agent
             Base Role contracts — Repository Agent
             SYSTEM contracts — Reporting Agent
             SYSTEM contracts — Repository Agent
             PROJECT:ZYRA contracts — Reporting Agent
             PROJECT:ZYRA contracts — Repository Agent
             SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/GOVERNANCE_V4.md

------------------------------------------------------------

OA-066
Title:       Create Evidence Vocabulary standard
             document before Level 4
Category:    Governance
Priority:    Medium
Status:      Completed
Owner:       Lead Architect
Dependencies: OA-022
Decision:    None — pending DR
Automation:  Manual
Description: Contracts reference execution logs,
             findings, reports, dependency maps,
             history, and patterns without a shared
             vocabulary defining what each is.
             Before Level 4, produce a standard
             Evidence Vocabulary document defining
             each evidence type, its format, its
             producer, and its consumer. Without
             this, contracts will gradually diverge
             in terminology making audit and agent
             coordination harder at scale.
             Raised from ChatGPT Base Role review,
             Round 1.
Target:      SYSTEM/DOCUMENTS/ (new document, location TBC)

------------------------------------------------------------

OA-067
Title:       Standardise approval chain reference
             across all agent contracts
Category:    Governance
Priority:    Medium
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: None
Decision:    None — pending DR
Automation:  Manual
Description: Several contracts reference "approved
             rules" without specifying the approval
             chain. Every contract should reference
             the chain explicitly:
               Project Owner → Governance →
               Lead Architect → Agent
             Rather than simply stating "approved."
             This improves traceability and makes
             the authority source explicit for every
             rule an agent acts on.
             To be applied in the next contract
             update batch across all contracts.
             Raised from ChatGPT Base Role review,
             Round 1.
Target:      All agent contracts — next update batch

------------------------------------------------------------

OA-068
Title:       Define Logging Standard before Level 4
Category:    Governance
Priority:    High
Status:      Completed
Owner:       Lead Architect
Dependencies: DR-035, OA-065
Decision:    None — pending DR
Automation:  Planned
Description: All agent contracts independently define
             logging behaviour. Without a Logging
             Standard, logging diverges across agents
             making System Auditor audit and cross-agent
             pattern detection harder.
             Before Level 4, produce a Logging Standard
             defining:
               Log format — consistent structure
               Log content — what every entry must
               contain (action, timestamp, V doc
               referenced, outcome)
               Log location — which agent logs where
               Log retention — how long logs are kept
               Log access — which agents can read
               which logs
             This standard becomes mandatory for all
             agent contracts. Existing logging sections
             in contracts are retrofitted to reference
             the standard rather than defining their
             own rules.
             Closely related to OA-065 (daily log
             format) and OA-048 (LOGS/ folder).
             Raised from ChatGPT Base Role review,
             Round 1.
Target:      SYSTEM/DOCUMENTS/ (new document)
             All agent contracts (retrofit references)

------------------------------------------------------------

OA-069
Title:       Add Inspection history as primary evidence
             source for System Auditor
Category:    Governance
Priority:    Medium
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: OA-022
Decision:    None — pending DR
Automation:  Manual
Description: The System Auditor currently references
             routing logs and workflow outputs as its
             primary audit inputs. Inspection Agent
             history — findings over time across all
             runs — should be added as a primary
             evidence source for the System Auditor.
             This enables the System Auditor to detect
             patterns in what the Inspection Agent
             finds repeatedly, not just audit
             individual run compliance.
             Update: System Auditor contract to add
             Inspection history as a primary input.
             Update: Inspection Agent contracts (Base
             Role, SYSTEM, PROJECT:ZYRA) to explicitly
             note that history is retained and made
             available to the System Auditor.
             Raised from ChatGPT Base Role review,
             Round 1.
Target:      SYSTEM_AUDITOR contract
             INSPECTION_AGENT Base Role contract
             INSPECTION_AGENT SYSTEM contract
             INSPECTION_AGENT PROJECT:ZYRA contract

------------------------------------------------------------

OA-070
Title:       Add report classification to Reporting
             Agent Evolution section
Category:    Governance
Priority:    Low
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: None
Decision:    None — pending DR
Automation:  Planned
Description: Currently all reports are grouped
             together without classification. At
             Level 5 introduce formal report classes:
               Operational — daily run outcomes
               Architectural — structural changes
               Executive — Project Owner digest
               Audit — System Auditor findings
               Trend — patterns over time
             Each class has its own format, recipient,
             and cadence. Update the Reporting Agent
             Base Role, SYSTEM, and PROJECT:ZYRA
             Evolution sections to reference this
             classification as a Level 5 capability.
             Raised from ChatGPT Base Role review,
             Round 1.
Target:      REPORTING_AGENT Base Role contract
             REPORTING_AGENT SYSTEM contract
             REPORTING_AGENT PROJECT:ZYRA contract

------------------------------------------------------------

OA-071
Title:       Add Completion Criteria to CONTRACT_TEMPLATE
             V3 consideration
Category:    Governance
Priority:    Medium
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: None
Decision:    None — pending DR
Automation:  Manual
Description: Success Criteria measures whether an
             agent is performing effectively over
             time. Completion Criteria is a distinct
             concept — it defines when a specific
             run or task is considered finished and
             the agent should stop.
             For autonomous execution, Completion
             Criteria makes agent behaviour more
             deterministic — agents know exactly
             when to stop rather than inferring it.
             Examples:
               Inspection Agent — finished when
               entire assigned scope is scanned.
               Reporting Agent — finished when
               delivery is confirmed.
               Repository Agent — finished when
               operation is confirmed.
             Before the next significant contract
             update batch, evaluate adding Completion
             Criteria as a mandatory section to
             CONTRACT_TEMPLATE V3. It may be added
             as a sub-field within Success Criteria
             or as a standalone section.
             Raised from ChatGPT Base Role review,
             Round 1.
Target:      CONTRACT_TEMPLATE V3 (future version)
             All agent contracts (when template updates)

------------------------------------------------------------

OA-072
Title:       Lead Architect — separate Architectural
             Design from Operational Coordination
             at Level 5
Category:    Governance
Priority:    Low
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: OA-022
Decision:    None — pending DR
Automation:  Manual
Description: The Lead Architect currently handles both
             architectural design and significant
             operational coordination work. As specialist
             agents mature at Level 5 and absorb
             operational tasks, the Lead Architect role
             should be reviewed to separate:
               Architectural Design — proposing,
               designing, and governing structure.
               Operational Coordination — managing
               workflow, session setup, agent direction.
             Operational Coordination should gradually
             transfer to agents (Orchestrator, PA,
             Reporting Agent) leaving the Lead Architect
             focused on design and governance.
             No contract change required today.
             Review at Level 5 transition.
             Raised from ChatGPT Organisation review,
             Round 2.
Target:      Lead Architect contract (Level 5 review)

------------------------------------------------------------

OA-073
Title:       Architecture Partner — add recurring
             proposal weakness recognition
Category:    Governance
Priority:    Low
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: None
Decision:    None — pending DR
Automation:  Manual
Description: Currently the Architecture Partner reviews
             each proposal independently. At a future
             maturity level it should maintain awareness
             of recurring weaknesses across multiple
             reviews — patterns that keep appearing in
             proposals from the Lead Architect over time.
             This is not to criticise the Lead Architect
             but to accelerate proposal quality by
             identifying systematic gaps rather than
             one-off omissions. Add to Evolution section
             of the Architecture Partner contract.
             Raised from ChatGPT Organisation review,
             Round 2.
Target:      ARCHITECTURE_PARTNER contract
             (Evolution section — next update batch)

------------------------------------------------------------

OA-074
Title:       Critical Thinking Agent — add forward-
             looking capability prevention question
Category:    Governance
Priority:    Medium
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: None
Decision:    None — pending DR
Automation:  Manual
Description: Currently the Critical Thinking Agent asks
             "What could go wrong?" — a failure-detection
             lens. Add a second mandatory lens:
               "What future capability does this
               accidentally prevent?"
             This turns the agent from a failure hunter
             into a strategic forward-looker as well.
             It catches architectural decisions that are
             locally sound but foreclose later options.
             Update the Critical Thinking Agent Base Role
             contract to add this as a required
             challenge question alongside the existing
             failure and assumption challenges.
             Update SYSTEM and PROJECT:ZYRA contracts
             when Base Role is updated.
             Raised from ChatGPT Organisation review,
             Round 2.
Target:      CRITICAL_THINKING_AGENT contract
             (next contract update batch)

------------------------------------------------------------

OA-075
Title:       Master Reviewer — add severity
             classification to review findings
Category:    Governance
Priority:    Medium
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: None
Decision:    None — pending DR
Automation:  Manual
Description: Currently the Master Reviewer produces
             review findings without a severity scale.
             Add a mandatory severity classification to
             all Master Reviewer findings:
               Critical — must be resolved before
               approval may proceed.
               Major — significant issue requiring
               attention before implementation.
               Minor — should be addressed but does
               not block.
               Observation — noted for awareness,
               no action required.
               Recommendation — suggested improvement,
               Lead Architect discretion.
             This makes findings actionable and
             prioritisable without changing the role
             itself. The Master Reviewer still decides
             Approved or Revisions Required — the
             severity classification adds granularity
             to the Revisions Required outcome.
             Raised from ChatGPT Organisation review,
             Round 2.
Target:      MASTER_REVIEWER contract
             (next contract update batch)

------------------------------------------------------------

OA-076
Title:       PA — add Project Owner working
             preferences awareness at Level 5
Category:    Governance
Priority:    Low
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: None
Decision:    None — pending DR
Automation:  Manual
Description: Currently the PA is the Project Owner's
             operational interface — session briefs,
             document guidance, ChatGPT liaison,
             OA and Decisions logging. At Level 5
             the PA should evolve to maintain awareness
             of Project Owner working preferences:
               Communication preferences.
               Review preferences.
               Reporting preferences.
               Meeting and session preferences.
             This is not governance — it is working
             style intelligence. The PA uses it to
             tailor how it structures session briefs,
             reports, and responses, not to change
             any governance rule.
             Add to PA Evolution section.
             Raised from ChatGPT Organisation review,
             Round 2.
Target:      PA contract (Evolution section —
             next update batch)

------------------------------------------------------------

OA-077
Title:       Orchestrator — distinguish Workflow State
             from Execution State for resumable runs
Category:    Governance
Priority:    Low
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: None
Decision:    None — pending DR
Automation:  Planned
Description: Currently the Orchestrator tracks run
             state without distinguishing:
               Workflow State — overall run status
               (started, running, completed, failed).
               Execution State — individual work item
               status within the run.
             This distinction becomes critical when
             runs become resumable — a failed run
             should be resumable from the last
             successfully completed work item rather
             than restarting from scratch.
             At Level 5, define Workflow State and
             Execution State formally in the
             Orchestrator contract and specify how
             state is persisted to support resumable
             execution.
             Add to Orchestrator Evolution section.
             Raised from ChatGPT Organisation review,
             Round 2.
Target:      ORCHESTRATOR contract
             (Evolution section — next update batch)

------------------------------------------------------------

OA-078
Title:       System Auditor — evolve from compliance
             auditing to organisational effectiveness
             auditing
Category:    Governance
Priority:    High
Status:      Completed
Owner:       Lead Architect
Dependencies: OA-022
Decision:    None — pending DR
Automation:  Manual
Description: Currently the System Auditor primarily
             checks compliance — are agents following
             governance rules, are documents named
             correctly, are V doc rules respected.
             This is necessary but insufficient at
             maturity. The System Auditor should
             evolve to audit organisational
             effectiveness — whether the organisation
             is working as intended, not just whether
             rules are being followed.
             Effectiveness questions include:
               Is this governance still producing the
               desired outcome?
               Have previously approved rules become
               unnecessary or counterproductive?
               Are multiple agents solving the same
               problem (duplicated effort)?
               Has bureaucracy increased unnecessarily?
               Is complexity increasing faster than
               organisational value?
             These are not breach findings — they are
             organisational health observations.
             The System Auditor is the correct owner.
             Design the boundary between:
               Compliance audit (breach or not)
               Effectiveness audit (health or not)
             as a distinct section in the System
             Auditor contract at the next update.
             This may be achievable before Level 5.
             Raised from ChatGPT Organisation review,
             Round 2.
Target:      SYSTEM_AUDITOR contract
             (next major contract update)

------------------------------------------------------------

OA-079
Title:       Design Organisation Health Framework
             for System Auditor reporting
Category:    Governance
Priority:    High
Status:      Completed
Owner:       Lead Architect
Dependencies: OA-078
Decision:    None — pending DR
Automation:  Planned
Description: Rather than descriptive health commentary,
             the System Auditor should report against
             a defined set of health categories each
             cycle — making long-term trends measurable.
             Proposed framework categories (to be
             reviewed and formally approved):
               Governance Health — are rules clear,
               current, and being followed?
               Architecture Health — is the structure
               sound and not accruing technical debt?
               Execution Health — are workflows running
               reliably and completely?
               Quality Health — are quality gates
               effective and not routinely bypassed?
               Operational Health — are daily operations
               running without escalation pressure?
               Agent Health — are agents performing
               within their contracts?
               Repository Health — is the document
               store correct, complete, and well-named?
               Capability Health — is the organisation
               able to take on the next phase?
             The Organisation Health Framework is a
             design document, not a new agent. The
             System Auditor reports against it; it
             does not create a new role.
             Design work should begin before Level 4
             so the System Auditor can report against
             it from the start of Level 4 operations.
             Linked to OA-078 — effectiveness auditing
             and health framework are companion items.
             Raised from ChatGPT Organisation review,
             Round 2.
Target:      New document: ORGANISATION_HEALTH_
             FRAMEWORK_V1.md (SYSTEM/DOCUMENTS/)
             SYSTEM_AUDITOR contract (reference
             to framework added at next update)

------------------------------------------------------------

OA-080
Title:       Documentation Agent — independently
             versioned document schemas
Category:    Governance
Priority:    Low
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: OA-066
Decision:    None — pending DR
Automation:  Planned
Description: Currently the Documentation Agent embeds
             formatting and structure rules directly
             in its contract. As document types
             grow, these rules will diverge by type
             and become difficult to maintain.
             At a future maturity level, each document
             type (agent contract, governance doc,
             daily log, run report, etc.) should have
             an independently versioned schema.
             The Documentation Agent references the
             schema version rather than embedding the
             rules, allowing schemas to be updated
             without changing the agent contract.
             Schema versioning also enables the Output
             Review Agent to verify compliance against
             a specific schema version rather than
             inferring rules from context.
             Add to Documentation Agent Evolution
             section across Base Role, SYSTEM, and
             PROJECT:ZYRA contracts.
             Raised from ChatGPT SYSTEM review,
             Round 3.
Target:      DOCUMENTATION_AGENT contracts
             (Evolution section — next update batch)

------------------------------------------------------------

OA-081
Title:       Inspection Agent — add finding type
             classification alongside severity
Category:    Governance
Priority:    Medium
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: None
Decision:    None — pending DR
Automation:  Manual
Description: Currently the Inspection Agent classifies
             findings by severity only. Add a second
             classification dimension: finding type.
               Structural — folder structure, file
               placement, naming violations.
               Documentation — content, formatting,
               template compliance, version integrity.
               Governance — rule violations, missing
               required documents, contract gaps.
               Operational — OA status issues,
               DECISIONS register gaps, daily log
               format violations.
             Finding type + severity together enable
             the Reporting Agent and System Auditor
             to consume findings more precisely —
             e.g. all Governance findings regardless
             of severity, or all Critical findings
             regardless of type.
             Update Inspection Agent Base Role,
             SYSTEM, and PROJECT:ZYRA contracts to
             include finding type as a mandatory
             classification field alongside severity.
             Raised from ChatGPT SYSTEM review,
             Round 3.
Target:      INSPECTION_AGENT contracts — all three
             (next contract update batch)

------------------------------------------------------------

OA-082
Title:       Resolution Classifier — move routing
             matrix to standalone governed document
             when rules exceed manageable threshold
Category:    Governance
Priority:    Low
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: None
Decision:    None — pending DR
Automation:  Manual
Description: Currently classification rules and the
             routing matrix are embedded in the
             Resolution Classifier implementation
             contracts. As autonomous behaviours
             grow the routing matrix will expand
             rapidly, making the contract difficult
             to maintain.
             When the routing matrix grows beyond
             a manageable threshold (suggested
             trigger: more than 15 classification
             rules in any single implementation,
             or when rules begin to span multiple
             scopes), extract the routing matrix into
             a standalone governed reference document.
             The Resolution Classifier contract then
             references the document rather than
             embedding rules.
             Benefits: contract remains stable,
             rules can be updated without a contract
             revision, System Auditor can audit the
             rule document independently.
             The threshold trigger should be formally
             defined in Governance V4 so the decision
             is not made on judgment alone.
             Raised from ChatGPT SYSTEM review,
             Round 3.
Target:      RESOLUTION_CLASSIFIER contracts
             (trigger-based future action)
             GOVERNANCE V4 (define trigger threshold)

------------------------------------------------------------

OA-083
Title:       Repository Agent — distinguish Logical
             Archive from Historical Archive
Category:    Governance
Priority:    Low
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: None
Decision:    None — pending DR
Automation:  Planned
Description: Currently all archived documents are
             treated equivalently. As the repository
             grows, two distinct archive categories
             will emerge:
               Logical Archive — superseded documents
               still referenced by other documents,
               agents, or OA items. Retained for
               traceability. May still be read.
               Historical Archive — documents no
               longer referenced anywhere. Retained
               for record only. Read-only, low
               priority for retrieval.
             The distinction matters for:
               Impact Analysis — Logical Archives
               may still appear in dependency maps.
               System Auditor — can identify
               Historical Archives that are safe
               to compress or consolidate.
               Repository Agent — different handling
               rules for each archive type.
             Add to Repository Agent Evolution section
             across Base Role, SYSTEM, and
             PROJECT:ZYRA contracts.
             Raised from ChatGPT SYSTEM review,
             Round 3.
Target:      REPOSITORY_AGENT contracts
             (Evolution section — next update batch)

------------------------------------------------------------

OA-084
Title:       Impact Analysis Agent — add impact
             category classification
Category:    Governance
Priority:    Medium
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: None
Decision:    None — pending DR
Automation:  Planned
Description: Currently the Impact Analysis Agent
             produces a flat dependency list.
             Classify identified impacts into
             categories to make the impact report
             more actionable:
               Technical — code, tooling, integration.
               Governance — rule documents, contracts,
               decision register, OA items.
               Operational — daily logs, run reports,
               workflow routing.
               Repository — folder structure, file
               naming, CURRENT_VERSION integrity.
               Agent — contracts that reference the
               changed resource.
               Documentation — governed documents
               that depend on the changed structure.
               Execution — Orchestrator routing rules
               affected by the change.
             Lead Architect reviews impact report
             by category rather than a single list.
             This makes the Pre-execution safety
             analysis more actionable and reduces
             the risk of missing a category.
             Update Impact Analysis Agent Base Role,
             SYSTEM, and PROJECT:ZYRA contracts.
             Raised from ChatGPT SYSTEM review,
             Round 3.
Target:      IMPACT_ANALYSIS_AGENT contracts — all
             three (next contract update batch)

------------------------------------------------------------

OA-085
Title:       Design Standards Library governed
             document before Level 4
Category:    Governance
Priority:    High
Status:      Completed
Owner:       Lead Architect
Dependencies: OA-066, OA-068, OA-025
Decision:    None — pending DR
Automation:  Manual
Description: Currently standards are distributed and
             embedded:
               Naming standards in Repository Agent
               and MASTER_ARCHITECTURE.
               Placement standards in Repository Agent
               and MASTER_GOVERNANCE.
               Reporting standards in Reporting Agent
               implementation contracts.
               Review standards in Output Review Agent
               and Master Reviewer contracts.
               Classification standards in Resolution
               Classifier contracts.
               Versioning standards in Repository
               Agent and MASTER_GOVERNANCE.
             As Black Umbrella Group grows and new projects are
             added, these standards become shared
             assets referenced by many implementation
             contracts. Without a central document,
             standards drift between scopes.
             Before Level 4, produce a governed
             Standards Library containing:
               Naming Standards
               Placement Standards
               Reporting Standards
               Review Standards
               Classification Standards
               Versioning Standards
             Implementation contracts reference the
             Standards Library rather than embedding
             rules. Standards Library has its own
             version — when a standard changes, one
             document updates rather than multiple
             contracts.
             Companion items: Evidence Vocabulary
             (OA-066) and Logging Standard (OA-068)
             may be incorporated into or referenced
             from the Standards Library.
             Raised from ChatGPT SYSTEM review,
             Round 3.
Target:      New document: STANDARDS_LIBRARY_CURRENT_VERSION_V1.md
             (SYSTEM/DOCUMENTS/)
             All implementation contracts
             (reference update at next batch)

------------------------------------------------------------

OA-086
Title:       Standardise "Always Consult Before
             Writing" wording across all
             implementation contracts
Category:    Governance
Priority:    Low
Status:      Recorded
Owner:       Lead Architect
Dependencies: None
Decision:    None — pending DR
Automation:  Manual
Description: Across the SYSTEM and PROJECT:ZYRA
             implementation contracts, the consult
             instruction appears in three variations:
               "Always Consult Before Writing"
               "Always Consult"
               "Always Consult Before [action]"
             All are semantically correct but
             inconsistency creates friction for
             agents reading multiple contracts and
             for System Auditor compliance checks.
             Standardise to a single approved phrasing
             across all implementation contracts in
             the next update batch. Suggested standard:
               "Always Consult Before [specific
               action]" — making the trigger explicit.
             Lead Architect to confirm preferred
             wording before the update batch runs.
             Raised from ChatGPT SYSTEM review,
             Round 3.
Target:      All implementation contracts — SYSTEM
             and PROJECT:ZYRA (next update batch)

------------------------------------------------------------

OA-087
Title:       CONTRACT_TEMPLATE V3 — add Assumptions
             section
Category:    Governance
Priority:    High
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: OA-025
Decision:    None — pending DR
Automation:  Manual
Description: Add a mandatory Assumptions section to
             CONTRACT_TEMPLATE V3. This section
             documents what the agent presupposes to
             be true before it begins execution —
             distinct from "Cannot" (authority
             boundary) and "Out of Scope"
             (responsibility boundary).
             Example content for Documentation Agent:
               This contract assumes:
               — Repository follows the approved
                 folder structure.
               — Governance documents are current.
               — Dependencies listed are available.
               — Output Review Agent is active.
             Assumptions become critical during
             debugging — if an agent behaves
             unexpectedly, checking whether its
             assumptions were met is the first
             diagnostic step. Without documented
             assumptions this check is guesswork.
             When CONTRACT_TEMPLATE V3 is produced
             (OA-090), Assumptions is a mandatory
             section. All existing contracts are
             retrofitted in the same update batch.
             Raised from ChatGPT final architecture
             review, Round 4.
Target:      CONTRACT_TEMPLATE V3 (OA-090)
             All agent contracts (retrofit)

------------------------------------------------------------

OA-088
Title:       CONTRACT_TEMPLATE V3 — add Out of Scope
             section distinct from Cannot
Category:    Governance
Priority:    High
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: OA-025, OA-087
Decision:    None — pending DR
Automation:  Manual
Description: Add a mandatory Out of Scope section to
             CONTRACT_TEMPLATE V3. This is distinct
             from the existing Cannot section:
               Cannot — what the agent is not
               permitted to do (authority boundary).
               Out of Scope — what is not this
               agent's function at all (responsibility
               boundary, belongs to another agent).
             Example for Documentation Agent:
               Out of Scope:
               — Deciding architecture.
               — Changing governance rules.
               — Approving output.
               — Filing or moving documents
                 (Repository Agent function).
             This distinction prevents boundary
             confusion between agents when a task
             could plausibly belong to more than one.
             It also makes the contract faster to
             scan when debugging responsibility gaps.
             When CONTRACT_TEMPLATE V3 is produced
             (OA-090), Out of Scope is a mandatory
             section. All existing contracts are
             retrofitted in the same update batch.
             Raised from ChatGPT final architecture
             review, Round 4.
Target:      CONTRACT_TEMPLATE V3 (OA-090)
             All agent contracts (retrofit)

------------------------------------------------------------

OA-089
Title:       CONTRACT_TEMPLATE V3 — add Agent
             Maturity field
Category:    Governance
Priority:    Medium
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: OA-025, OA-087
Decision:    None — pending DR
Automation:  Manual
Description: Add an Agent Maturity field to the
             contract header in CONTRACT_TEMPLATE V3.
             Allowed values:
               Experimental — concept validated,
               not yet tested in live operation.
               Stable — tested and operating within
               defined parameters.
               Core Infrastructure — essential to
               organisation function; failure has
               High or Critical Failure Impact.
               Legacy — being superseded; still
               operating, replacement in progress.
             Agent Maturity gives the Lead Architect
             and Project Owner immediate visibility
             into organisational confidence for each
             agent. It also helps prioritise testing
             during Phase 2 — Experimental agents
             require more supervision than Stable ones.
             All current contracts start as:
             Experimental at time of first approval.
             Promoted to Stable after a defined
             testing period and Lead Architect review.
             The promotion criteria should be defined
             in Governance V4 (OA-025).
             When CONTRACT_TEMPLATE V3 is produced
             (OA-090), Agent Maturity is added to
             the header. All existing contracts are
             retrofitted in the same update batch.
             Raised from ChatGPT final architecture
             review, Round 4.
Target:      CONTRACT_TEMPLATE V3 (OA-090)
             GOVERNANCE V4 (maturity promotion
             criteria — OA-025)
             All agent contracts (retrofit)

------------------------------------------------------------

OA-090
Title:       Design and produce CONTRACT_TEMPLATE V3
Category:    Governance
Priority:    High
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: OA-071, OA-087, OA-088, OA-089
Decision:    DR-066
Automation:  Manual
Description: CONTRACT_TEMPLATE V2 is now the locked
             baseline (DR-036). V3 design begins once
             V2 has been formally used for the first
             approved contract. V3 consolidates all
             template enhancements identified across
             the four-batch architectural review.
             V3 additions over V2:
               Assumptions section (OA-087)
               — what the agent presupposes is true.
               Out of Scope section (OA-088)
               — responsibility boundary vs authority
               boundary.
               Agent Maturity field (OA-089)
               — Experimental / Stable / Core
               Infrastructure / Legacy.
               Completion Criteria (OA-071)
               — when a specific run is finished,
               distinct from Success Criteria.
               Capability Evolution format (this OA)
               — structured as: Current → Next
               Version → Long-Term Vision within the
               existing Evolution section.
             When V3 is produced:
               V2 is archived with today's date.
               All existing contracts are retrofitted
               to V3 in a single update batch.
               Retrofitting is a Repository Agent
               operation led by the Lead Architect.
             V3 should not be produced until V2 has
             been used for at least one approval cycle
             so its gaps are known from practice, not
             theory.
             Raised from ChatGPT final architecture
             review, Round 4. Consolidates OA-071,
             OA-087, OA-088, OA-089.
Target:      CONTRACT_TEMPLATE V3 (new document)
             CONTRACT_TEMPLATE V2 (archive when V3
             approved)
             All agent contracts (V3 retrofit batch)

------------------------------------------------------------

OA-091
Title:       Design KPI and Metrics section for
             agent contracts before Level 4
Category:    Governance
Priority:    Medium
Status:      Recorded
Owner:       Lead Architect
Dependencies: OA-079, OA-090
Decision:    None — pending DR
Automation:  Planned
Description: Each agent should eventually expose
             measurable KPIs that feed into the
             Organisation Health Framework (OA-079).
             Example KPIs by agent:
               System Auditor:
               — audits completed per cycle.
               — recommendations accepted rate.
               — recurring issues trend (up/down).
               Inspection Agent:
               — issues detected per run.
               — false positive rate.
               — average inspection duration.
               Documentation Agent:
               — documents updated per cycle.
               — contradictions prevented.
               Resolution Classifier:
               — autonomous resolution rate.
               — escalation rate.
               — misclassification rate (if audited).
             These become the operational health
             inputs that the System Auditor reports
             against the Organisation Health Framework
             each cycle. Without KPIs, health
             reporting is descriptive not measurable.
             Before Level 4, design the KPI model:
               Which agents expose KPIs.
               Which KPIs are mandatory vs optional.
               How KPIs are recorded (log format).
               How the System Auditor consumes them.
             The KPI section may be added to
             CONTRACT_TEMPLATE V3 (OA-090) or as a
             separate referenced document depending
             on design decision.
             Raised from ChatGPT final architecture
             review, Round 4.
Target:      CONTRACT_TEMPLATE V3 (OA-090) or
             standalone KPI standard
             All agent contracts (when KPI model
             is approved)
             SYSTEM_AUDITOR contract (consumption
             rules)

------------------------------------------------------------

OA-092
Title:       Design Resource Ownership model
             for agent contracts
Category:    Governance
Priority:    Low
Status:      Recorded
Owner:       Lead Architect
Dependencies: OA-090, OA-085
Decision:    None — pending DR
Automation:  Manual
Description: As Black Umbrella Group scales, some agents will
             formally own specific resources:
               Repositories — folders or document
               stores an agent is responsible for.
               Indexes — maintained lists or
               registers an agent keeps current.
               Decision Records — DECISIONS logs an
               agent owns content for.
               Knowledge Stores — reference documents
               an agent is responsible for keeping
               accurate.
               Logs — specific log files an agent
               owns and maintains.
             Without formal resource ownership,
             multiple agents may attempt to maintain
             the same resource, or a resource may
             have no clear owner when something
             goes wrong.
             At a future maturity level, add a
             Resource Ownership section to agent
             contracts listing the specific resources
             each agent owns. The Impact Analysis
             Agent uses resource ownership records
             as part of dependency mapping.
             This may be incorporated into
             CONTRACT_TEMPLATE V3 (OA-090) or
             introduced in V4 depending on when
             the need becomes practical.
             Raised from ChatGPT final architecture
             review, Round 4.
Target:      CONTRACT_TEMPLATE V3 or V4
             All agent contracts (when model approved)
             IMPACT_ANALYSIS_AGENT contracts
             (resource ownership as dependency input)

------------------------------------------------------------

OA-093
Title:       Define Draft-to-V1 promotion rule
             across CONTRACT_TEMPLATE, Repository
             Agent, and Orchestrator
Category:    Governance
Priority:    High
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: OA-025, OA-090
Decision:    None — pending DR
Automation:  Planned
Description: No rule currently exists defining what
             happens when a Draft contract is approved
             by the Project Owner. The promotion step
             — renaming the file, updating Status,
             updating Contract Version — is not
             governed anywhere. This means the step
             can be missed without any agent catching
             it. Gap identified after Draft 1 contracts
             were approved via DR-037 but not promoted
             to V1 until manually caught in session.
             The rule must be defined in three places:
             1. CONTRACT_TEMPLATE — Status lifecycle
                section must state explicitly:
                  Draft — contract under construction.
                  Review — submitted for review.
                  Approved — Project Owner has approved.
                  On Approved: Repository Agent
                  promotes to V1 immediately.
                  Promotion = rename file from
                  [NAME]_Draft[N].md to [NAME]_V1.md,
                  update Status field to Approved,
                  update Contract Version field to V1.
             2. Repository Agent — Base Role, SYSTEM,
                and PROJECT:ZYRA contracts must include
                Draft Promotion as a named operation:
                  Trigger: Project Owner approval of
                  a Draft contract.
                  Action: rename file, update Status,
                  update Contract Version.
                  Log: promotion logged as a
                  versioning operation.
             3. Orchestrator — routing table must
                include:
                  Project Owner approval of Draft
                  contract → route to Repository
                  Agent for promotion.
                  No promotion proceeds without an
                  Orchestrator work item.
             Until this rule is live in all three
             places, Draft promotion remains a manual
             step that depends on session memory
             rather than system governance.
             To be incorporated into CONTRACT_TEMPLATE
             V3 (OA-090) and the next Repository
             Agent and Orchestrator contract update.
             Raised from session gap identification
             2026-06-22.
Target:      CONTRACT_TEMPLATE V3 (OA-090)
             REPOSITORY_AGENT contracts — all three
             ORCHESTRATOR_V2 contract
             GOVERNANCE V4 (OA-025) — lifecycle rule

------------------------------------------------------------

OA-094
Title:       Add pre-V-doc OA sweep rule to
             Orchestrator and Governance V4
Category:    Governance
Priority:    High
Status:      Completed
Owner:       Lead Architect
Dependencies: None — must be resolved BEFORE OA-025
Decision:    None — pending DR
Automation:  Planned
Description: Before any scheduled V doc production,
             the system must sweep the OA register
             for items that target that document and
             are currently unblocked. Those OAs are
             actioned first. Only then is the V doc
             produced.
             Without this rule the system produces
             a V doc, discovers outstanding OAs that
             could have been incorporated, and is
             forced into an immediate subsequent
             version. The rule prevents avoidable
             version churn.
             Example:
               Governance V4 is scheduled.
               OA register contains OA-062, OA-063,
               OA-064 — all target Governance V4,
               all unblocked.
               Without the rule: V4 is written,
               those OAs remain, V5 is needed soon.
               With the rule: OA-062, OA-063,
               OA-064 are cleared first, V4 is
               written once and is complete.
             The rule must be defined in two places:
             1. Orchestrator contract — before
                routing any V doc production task
                to the Documentation Agent, the
                Orchestrator must first route a
                pre-production OA sweep:
                  Identify the target document.
                  Check OA register for items whose
                  Target field references this
                  document and whose Status is
                  Recorded or In Progress and whose
                  Dependencies are met.
                  If any exist: route those OAs
                  for execution before the V doc.
                  Only when sweep is complete or
                  no eligible OAs remain: route to
                  Documentation Agent to produce
                  the V doc.
             2. Governance V4 — formal rule:
                  No V doc may be produced on its
                  scheduled cycle without a
                  completed pre-production OA sweep.
                  The sweep result is logged — either
                  OAs cleared, or confirmation that
                  no eligible OAs existed.
             The sweep applies to scheduled V doc
             production only. Emergency or
             unscheduled V docs are exempt but the
             Lead Architect must note the exemption.
             Raised from Project Owner architectural
             observation 2026-06-22.
Target:      ORCHESTRATOR_V2 contract
             GOVERNANCE V4 (OA-025)

------------------------------------------------------------

OA-095
Title:       Define pre-production cut-off rule for
             scheduled V doc cycles
Category:    Governance
Priority:    High
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: DR-048, OA-025
Decision:    None — pending DR
Automation:  Planned
Description: Every V doc on a scheduled production
             cycle operates under a cut-off rule
             that controls which OAs are incorporated
             into that cycle and which are deferred.
             The rule works as follows:
             1. CUT-OFF POINT
                Defined as 24 hours before the
                scheduled production date.
                Example: V doc scheduled for 30th.
                Cut-off is 29th at the same time
                of day.
             2. PRE-PRODUCTION SWEEP
                Runs at cut-off (per DR-048).
                Identifies all eligible OAs:
                  — Target field references this
                    V doc.
                  — Dependencies are met.
                  — Not Low priority or Level 5
                    Evolution items.
                Those OAs are executed before the
                V doc is produced.
             3. MORNING REPORT
                On the morning of the production
                day (e.g. 29th morning if production
                is 30th), the Reporting Agent
                produces a pre-production summary:
                  — OAs cleared in the sweep.
                  — Content being incorporated.
                  — Confirmation the V doc is
                    ready to produce.
                Project Owner reviews this before
                production proceeds.
             4. CUT-OFF DEFERRAL RULE
                Any OA added after the cut-off
                is automatically deferred to the
                next scheduled production cycle.
                It is not incorporated into the
                current cycle regardless of content.
             5. DEFERRAL OVERRIDE
                Cut-off deferral can only be
                overridden by:
                  — Project Owner — unconditional
                    override authority.
                  — Lead Architect — may override
                    based on priority and downstream
                    impact assessment. Must log the
                    reason for override.
                  — Relevant governing agent (future)
                    — e.g. Resolution Classifier or
                    Impact Analysis Agent assessing
                    urgency. Must log the reason.
                Override is the exception, not the
                default. No override without a
                logged reason.
             TIMING NOTE:
             Execution scheduling cadence is not
             yet defined — this is post-V4 work.
             This OA is raised now so the rule
             exists in the register. The rule is
             documented in the governance V doc
             that covers the scheduling system,
             which is produced after Governance V4.
             It does not go into Governance V4
             itself since V4 precedes the scheduling
             definition.
             Raised from Project Owner architectural
             observation 2026-06-22.
Target:      Governance V doc covering execution
             scheduling (post-V4)
             ORCHESTRATOR contract (scheduling
             and cut-off logic)
             REPORTING_AGENT contracts (morning
             pre-production report)

------------------------------------------------------------

OA-096
Title:       Write Execution V4 — AI Organisation
             operational workflow and automation
             schedule
Category:    Governance
Priority:    High
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: OA-025 (Governance V4 must be written first)
Decision:    None — pending execution
Automation:  Manual
Description: EXECUTION_V3 predates the AI Organisation.
             Three sections need significant updates:
               Section 12 (AI Collaboration Workflow)
               — rewrite to reflect agent-based model.
               The manual Lead Architect → Architectural
               Reviewer → Project Owner flow is no
               longer the complete picture. The
               Orchestrator routes work; agents execute;
               the review chain is agent-mediated.
               The roles (Lead Architect, Architectural
               Reviewer, Project Owner) remain permanent
               but how they interact with the AI
               Organisation must be defined.
               Appendix current documents list
               — update GOVERNANCE_V3.md → V4,
               and add all new reference documents
               (LOGGING_STANDARD_V1, EVIDENCE_
               VOCABULARY_V1, ORGANISATION_HEALTH_
               FRAMEWORK_V1, STANDARDS_LIBRARY_V1).
               New Section: Automation Schedule
               (see OA-099) — the scheduled run
               cadence for all agent workflows.
             Execution V4 must not be written before
             Governance V4, as V4 defines the
             principles Execution operationalises.
             This is Stage 5b of the Governance V4
             roadmap.
Target:      SYSTEM/DOCUMENTS/MASTER_EXECUTION/
             EXECUTION_V4.md

------------------------------------------------------------

OA-097
Title:       Write Repository Architecture V2 —
             two-tier SYSTEM model and AGENTS
             folder structure
Category:    Architecture
Priority:    High
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: OA-025 (Governance V4 defines the
             two-tier SYSTEM model)
Decision:    None — pending execution
Automation:  Manual
Description: REPOSITORY_ARCHITECTURE_V1 predates:
               — The two-tier SYSTEM model (DR-025):
                 BLACK UMBRELLA GROUP/SYSTEM/ (shared, applies to
                 all projects) vs PROJECTS/[PROJECT]/
                 SYSTEM/ (project-specific operational
                 records). This structural split must
                 be formally documented in Architecture.
               — The AGENTS/ folder structure (DR-038,
                 DR-044): BASE_ROLES/, CONTRACTS/
                 ORGANISATION/, CONTRACTS/SYSTEM/,
                 and PROJECTS/[PROJECT]/SYSTEM/AGENTS/
                 with the four-layer inheritance model.
               — New reference document folders:
                 LOGGING_STANDARD/, EVIDENCE_VOCABULARY/,
                 ORGANISATION_HEALTH/, MASTER_STANDARDS/
                 all need placement rules defined.
               — LOGS/ folders at SYSTEM and PROJECT
                 scope (DR-035).
             The current documents list in V1 also
             references GOVERNANCE_V3.md, which
             becomes stale on V4 publication.
             Repository Architecture V2 must not be
             written before Governance V4, as V4
             defines the two-tier SYSTEM model.
             This is Stage 5c of the Governance V4
             roadmap.
Target:      SYSTEM/DOCUMENTS/MASTER_ARCHITECTURE/
             REPOSITORY_ARCHITECTURE_V2.md

------------------------------------------------------------

OA-098
Title:       V doc cascade detection — agent rule
             for batch V doc updates and non-update
             pattern flagging
Category:    Governance / Architecture
Priority:    Medium
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: OA-025 (principle goes into Governance V4)
             OA-096 (workflow goes into Execution V4)
Decision:    None — pending DR
Automation:  Future (agent-executed)
Description: When a master V doc is updated, companion
             V docs that reference it must be reviewed
             as a batch. No single V doc update should
             be filed in isolation without checking
             what else needs to move with it.
             Two rules are required:
             RULE 1 — CASCADE DETECTION:
               When a master V doc is updated, the
               Impact Analysis Agent maps all V docs
               that reference it. Any dependent V doc
               is added to the current update batch
               unless explicitly deferred with a
               logged reason. No V doc update is
               considered complete until the cascade
               check is done. (Impact Analysis Agent
               responsibility — see contract.)
             RULE 2 — NON-UPDATE PATTERN DETECTION:
               The System Auditor tracks which V docs
               are updated in each governance cycle
               and which are not. If a V doc is not
               updated across two or more consecutive
               governance cycles, the System Auditor
               flags it with the question:
               "Is this document still correctly
               classified as a V doc? If it does not
               change when governance changes, it may
               be better classified as a reference
               standard, a baseline, or a one-time
               structural document."
               The Lead Architect reviews the flag and
               decides: reclassify, keep as-is with
               logged reason, or convert to a different
               document type.
             EXECUTION: The principle (Rule 1 and 2
             above) is added to Governance V4 as a
             V doc lifecycle rule. The operational
             workflow (how the cascade check runs,
             how the pattern flag is surfaced) goes
             into Execution V4. This OA feeds into
             both OA-025 and OA-096.
             The cascade detection principle is
             added to OA-025's required content
             immediately so it is not missed when
             V4 is written.
Target:      Principle → GOVERNANCE_V4 (OA-025)
             Workflow → EXECUTION_V4 (OA-096)
             Agent contract additions → next contract
             batch after V4

------------------------------------------------------------

OA-099
Title:       Define automation schedule — which
             agent runs are scheduled, at what
             cadence, and what they produce
Category:    Governance / Execution
Priority:    Medium
Status:      Completed
Resolved:    2026-06-22
Owner:       Lead Architect
Dependencies: OA-096 (Execution V4 — goes in as a
             new section)
Decision:    None — pending execution
Automation:  Future (agent-executed once defined)
Description: The AI Organisation will run on a
             defined schedule. That schedule does
             not yet exist as a formal document or
             section. This OA defines what needs
             to be produced:
               — Which agent workflows run on a
                 scheduled basis (Inspection Agent,
                 Reporting Agent, System Auditor,
                 Orchestrator nightly run, etc.)
               — The cadence for each: daily, weekly,
                 monthly, per-trigger.
               — What each scheduled run produces
                 and who receives the output.
               — The pre-production cut-off rules
                 (OA-095/DR-053): when a V doc is
                 due, the 24-hour cut-off applies.
               — The morning briefing cadence for
                 the Project Owner.
             The automation schedule is a section
             in EXECUTION_V4, not a standalone V doc.
             It becomes the operational source of
             truth for what runs automatically and
             when. Cannot be written until the
             agents and their cadences are settled
             in practice — this is therefore a V4
             input subject to what is known at
             the time of writing.
             Deferred to OA-096 (Execution V4).
Target:      EXECUTION_V4, new Automation Schedule
             section

------------------------------------------------------------

OA-100
Title:       Anthropic API key — configure and connect
Category:    Infrastructure / Setup
Priority:    Critical
Status:      Open
Owner:       Shakeel
Raised:      2026-06-27
Source:      Development Environment Review 2026-06-27
Description: The AI Organisation cannot run autonomously
             without the Anthropic API key configured.
             All LLM-dependent agent runs currently
             require --no-llm mode as a workaround.

             Steps required:
               1. Create API key at console.anthropic.com
               2. Add to run_config.json:
                    { "anthropic_api_key": "sk-..." }
               3. Verify with a test run (without --no-llm)
               4. Confirm daily scheduler picks up the key

             run_config.json is gitignored — the key
             never enters version control.
Target:      AI Organisation running in full LLM mode
Dependencies: None
Automation:  Manual (Shakeel — requires account access)

------------------------------------------------------------

OA-101
Title:       Supabase project setup
Category:    Infrastructure / Setup
Priority:    Critical
Status:      Open
Owner:       Shakeel
Raised:      2026-06-27
Source:      Development Environment Review 2026-06-27
Description: Create and configure the Supabase project
             that will serve as the ZYRA backend.

             Steps required:
               1. Create project at supabase.com
                    Organisation: ZYRA-APP-LAB (or new)
                    Project name: zyra-production
                    Region: closest to target market
                    Database password: strong, stored
                    in password manager
               2. Note project URL and anon/service keys
               3. Create supabase/.env (gitignored):
                    SUPABASE_URL=https://[ref].supabase.co
                    SUPABASE_ANON_KEY=...
                    SUPABASE_SERVICE_KEY=...
               4. Add supabase packages to pubspec.yaml:
                    supabase_flutter: ^2.x
               5. Initialise Supabase in main.dart
               6. Confirm Flutter app can reach Supabase
                  with a test connection

             .env file must be gitignored before adding keys.
             Verify with: git check-ignore -v supabase/.env
Target:      Flutter app connected to Supabase project
Dependencies: DR-073 (Supabase decision confirmed)
Automation:  Manual (Shakeel — requires account access)

------------------------------------------------------------

OA-102
Title:       Supabase authentication setup
Category:    Implementation / Authentication
Priority:    Critical
Status:      Open
Owner:       Lead Architect
Raised:      2026-06-27
Source:      Development Environment Review 2026-06-27
Description: Implement Supabase Auth in the ZYRA Flutter
             app. Authentication is the prerequisite for
             all other features — no feature can be built
             without a confirmed authenticated user.

             Scope:
               — Email + password sign-up and sign-in
               — Session persistence across app restarts
               — Auth state listener wired into app state
               — Sign-out
               — Basic error handling (wrong password,
                 email not confirmed, network error)

             Explicitly out of scope for this OA:
               — Social auth (Google, Apple)
               — Phone auth
               — Magic links
               These are V2 auth features added after
               the core flow is working.

             Depends on OA-101 (Supabase project) being
             complete before implementation begins.
Target:      Working auth flow in Flutter (sign up,
             sign in, sign out, session persistence)
Dependencies: OA-101 (Supabase project setup)
Automation:  Future (Development Team agent)

------------------------------------------------------------

OA-103
Title:       Supabase database schema — initial design
Category:    Implementation / Database
Priority:    High
Status:      Completed
Completed:   2026-06-27
Owner:       Lead Architect
Raised:      2026-06-27
Source:      Development Environment Review 2026-06-27
Description: Design and implement the initial Supabase
             PostgreSQL schema for ZYRA.

             Core tables required for MVP:
               profiles      — user profile data
               journeys      — matchmaking journey state
               matches       — confirmed match records
               wali_links    — guardian relationships

             Each table requires:
               — Row-level security (RLS) enabled
               — RLS policies defined before any data
                 is written (DR-073)
               — created_at / updated_at timestamps
               — UUID primary keys

             Schema to be approved by Lead Architect
             before migration is applied to Supabase.
             Migration files live in:
             PROJECTS/ZYRA/SOURCE/supabase/migrations/

Target:      Initial schema applied to Supabase with
             RLS policies active on all tables
Dependencies: OA-101 (Supabase project setup)
              OA-102 (Auth — user ID required for RLS)
Automation:  Future (Development Team agent)

------------------------------------------------------------

OA-104
Title:       Supabase Storage setup — profile images
Category:    Implementation / Storage
Priority:    Medium
Status:      Open
Owner:       Lead Architect
Raised:      2026-06-27
Source:      Development Environment Review 2026-06-27
Description: Configure Supabase Storage for ZYRA profile
             images and documents.

             Buckets required:
               profile-images   — user profile photos
               documents        — future (verification
                                  documents, Wali docs)

             Each bucket requires:
               — Access policies (who can read/write)
               — File size limits
               — Allowed MIME types

             Profile images: authenticated read for
             matched users only (aligns with ZYRA
             privacy model). Public read is not
             appropriate for this application.

Target:      Storage buckets configured with correct
             access policies. Flutter can upload and
             retrieve profile images.
Dependencies: OA-101 (Supabase project setup)
              OA-102 (Auth — required for storage policies)
              OA-103 (Schema — profile ID required)
Automation:  Future (Development Team agent)

------------------------------------------------------------

END OF ACTION REGISTER
============================================================


============================================================
END OF DOCUMENT
============================================================


------------------------------------------------------------

OA-120
Title:       Define Per-Group Advancement Conditions for
             the Execution Stage Model
Status:      Closed
Priority:    High
Owner:       Lead Architect
Raised:      2026-06-27
Completed:   2026-06-27

Description: DR-074 establishes that the Group field
             represents a feature's current execution
             stage and that advancement is evidence-based.
             This OA governed the definition of the
             specific conditions that must be satisfied
             before a feature advances from each Group
             to the next.

             SCOPE BOUNDARY (confirmed by Architectural
             Reviewer, 2026-06-27):
             This OA does not redesign the execution
             framework (DR-022) or the Summary Standard.
             Both already exist and are not changed here.
             This OA answered one question only, eight
             times:
               "What evidence must exist before a feature
               can move from Group N to Group N+1?"

             GOVERNING PRINCIPLE (confirmed by Architectural
             Reviewer, 2026-06-27):
             Completion is not measured by the presence of
             documents. It is measured by readiness to hand
             work to the next execution stage. If the next
             Group cannot proceed confidently, the current
             Group is not yet complete. Each Group hands a
             complete, approved output to the next Group.

Outcome:     All 8 advancement conditions confirmed by
             Lead Architect and Architectural Reviewer
             (2026-06-27). Published as:
             ADVANCEMENT_CONDITIONS_CURRENT_VERSION_V1.md
             Location: ZYRA/SYSTEM/DOCUMENTS/

             AUTO-DISCOVERY RULE (confirmed by Architectural
             Reviewer, 2026-06-27): The Project Check must
             discover participating features automatically
             by reading all Summary.md files within APP/
             and BUSINESS/ and extracting their Group field.
             No manual feature nomination is required or
             permitted. Every Summary carrying a Group field
             participates in the maturity report.

Confirmed Conditions:

  G1 → G2 (Business Rules complete):
  All business rules governing the feature's behaviour
  are documented, internally consistent, and sufficiently
  complete that User Journey design can begin without
  requiring additional behavioural decisions or
  assumptions.

  G2 → G3 (User Journeys complete):
  User journeys for this feature are documented from
  entry to exit and are sufficiently complete that the
  full set of pages required by the feature can be
  identified without requiring additional journey
  decisions or assumptions.

  G3 → G4 (Page Inventory complete):
  Every page required by this feature is listed in the
  approved Page Inventory with its name and purpose
  confirmed, such that Page Responsibilities can begin
  without needing to identify, rename, or introduce
  additional pages.

  G4 → G5 (Page Responsibilities complete):
  Every page within the feature has its responsibilities
  fully defined in accordance with the approved Page
  Responsibilities standard, such that Application
  Architecture can begin without requiring clarification
  of what any page does, what it requires, or what it
  produces.

  G5 → G6 (Application Architecture complete):
  The feature's Application Architecture is documented
  in accordance with the approved Architecture standard
  and is sufficiently complete that an Architecture
  Readiness Review can evaluate it without first defining
  missing architectural decisions, resolving unspecified
  components, or making assumptions about how the feature
  is structured or integrated.

  G6 → G7 (Architecture Readiness Review passed):
  An Architecture Readiness Review has been completed
  for this feature and all findings have been resolved
  or formally accepted, such that UI/UX Design can begin
  without known unresolved architectural blockers
  requiring significant redesign during the design phase.

  G7 → G8 (UI/UX Design approved):
  UI/UX Design for this feature is complete in accordance
  with the approved UI/UX Design standard and all required
  design outputs have been reviewed and approved, such
  that Development can begin implementation without
  needing to resolve missing design decisions, interpret
  ambiguous behaviour, or make assumptions about the
  intended user experience.

  G8 → Complete (Development complete):
  Development for this feature is complete in accordance
  with the approved Development standard and all required
  development outputs have been reviewed, tested, and
  approved, such that the feature is ready for release
  without requiring further development work, unresolved
  technical decisions, or outstanding development quality
  gates.

Dependencies: DR-074 (Group field — stage indicator)
              DR-022 (8-group framework)
              SUMMARY_STANDARD_CURRENT_VERSION_V1.md
              OA-117 (Project Check implementation)

Notes:       Conditions approved by Architectural Reviewer
             (ChatGPT), 2026-06-27, across 8 sequential
             review messages — one per transition.
             Each condition references governed standards
             rather than enumerating their contents.
             Conditions are handover-driven: each answers
             whether the next Group can begin confidently
             without reopening the previous Group.

============================================================

OA-121
Title:       Define Google Ads Placement for Basic Seeker Tier
Status:      Open
Priority:    Medium
Owner:       Lead Architect
Raised:      2026-06-28
Completed:   —

Description: Basic Seeker accounts should display Google
             Ads as part of the free tier experience.
             This OA covers the design and placement
             decisions required before implementation:

             — Where ads appear within the Basic Seeker UI
               (e.g. Browse, Home, between profiles, etc.)
             — Ad format (banner, interstitial, native card)
             — Frequency and capping rules
             — Surfaces that are ad-free regardless of tier
               (e.g. active Journey/messaging screens)
             — Ad-free upgrade prompt (Premium upsell)

             Ads must not appear for Premium Seeker accounts
             or any Wali account (Basic or Pro).

             Platform policy reference:
             ADVERTISING_STANDARD_CURRENT_VERSION_V1.md

Dependencies: ADVERTISING_STANDARD_CURRENT_VERSION_V1.md
              ZYRA Seeker subscription tiers
              Premium upsell design

Notes:       Raised from session 2026-06-28.
             Wali accounts (Basic and Pro) are excluded
             from ads entirely — ads are a Seeker-tier
             monetisation mechanism only.
