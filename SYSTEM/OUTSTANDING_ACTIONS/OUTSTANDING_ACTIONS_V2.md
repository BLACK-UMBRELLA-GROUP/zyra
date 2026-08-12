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
Title:       Create Guardian Navigation folder
Category:    Documentation
Priority:    Medium
Status:      Blocked
Owner:       Lead Architect
Dependencies: None (awaiting Summary from Shakeel)
Decision:    None
Automation:  Manual
Description: Guardian navigation content is temporarily
             held in SEEKER NAVIGATION. Once a Guardian
             Navigation Summary exists, create the
             dedicated folder and migrate content.
Target:      APP/Navigation/GUARDIAN NAVIGATION/

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
                   - Guardian onboarding missing →
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
Status:      Actioned — confirmed 2026-07-25 (DR-ZYRA-101 audit).
             Live Supabase project genuinely working today: real
             RLS-backed accounts, real auth sessions, real
             profiles/subscriptions rows (see Developer Mode
             Script_V2.md, DR-ZYRA-100). Status was never updated
             when this was completed — closed here on evidence
             from live code, not from a new build step.
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
Status:      RESOLVED 2026-07-25 (OA-ZYRA-140 item 13, Founder
             decision: "Google/Apple-only is correct"). Scope
             below rewritten to match live code and the confirmed
             direction; the pivot itself is now formally ratified
             as DR-ZYRA-102 (see Decisions Register) rather than
             left undocumented.
Owner:       Lead Architect
Raised:      2026-06-27
Source:      Development Environment Review 2026-06-27
Description: Implement Supabase Auth in the ZYRA Flutter
             app. Authentication is the prerequisite for
             all other features — no feature can be built
             without a confirmed authenticated user.

             Scope (rewritten 2026-07-25 to match ratified
             direction, DR-ZYRA-102):
               — Google sign-in (user-facing)
               — Apple sign-in (user-facing)
               — Session persistence across app restarts
               — Auth state listener wired into app state
               — Sign-out
               — Email + password retained ONLY as a hidden
                 Developer Mode test-account path — not exposed
                 to real users, not part of the Welcome screen
                 flow.

             Explicitly out of scope:
               — User-facing email + password sign-up/sign-in
               — Phone auth
               — Magic links

             Depended on OA-101 (Supabase project) being
             complete before implementation began — satisfied.
Target:      Working auth flow in Flutter (Google sign-in,
             Apple sign-in, sign out, session persistence) —
             ACHIEVED, live in `zyra_auth.dart` / `welcome_
             screen.dart`.
Dependencies: OA-101 (Supabase project setup), DR-ZYRA-102
Automation:  None — implemented directly.

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
                                  documents, Guardian docs)

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
Title:       Define Google Ads Placement for ZYRA Basic Seeker Tier
Status:      Resolved 2026-07-26 — see DR-ZYRA-109. 4 of 5 sub-
             questions were already answered by ADVERTISING_
             STANDARD_CURRENT_VERSION_V1.md (cited below as its own
             dependency); DR-109 settles the 5th (ad-free upgrade
             prompt mechanic) and adds a design-placeholder
             sponsored card in Browse (no real ad network yet —
             that's Phase 1, still open).
Priority:    Medium
Owner:       Lead Architect
Raised:      2026-06-28
Completed:   2026-07-26

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
             — Ad-free upgrade prompt (ZYRA One upsell)

             Ads must not appear for ZYRA One Seeker accounts
             or any Guardian account (Standard or Extended).

             Platform policy reference:
             ADVERTISING_STANDARD_CURRENT_VERSION_V1.md

Dependencies: ADVERTISING_STANDARD_CURRENT_VERSION_V1.md
              ZYRA Seeker subscription entitlements
              ZYRA One upsell design

Notes:       Raised from session 2026-06-28.
             Guardian accounts (Standard and Extended) are excluded
             from ads entirely — ads are a Seeker-tier
             monetisation mechanism only.
             Corrected 2026-07-12: title and body updated from
             "Basic Seeker Tier"/"Basic and Pro" (stale — no
             Pro tier under ZYRA One) to ZYRA Basic/ZYRA One and
             Standard Guardian/Extended Guardian, per the Phase 3-5
             documentation alignment pass.

------------------------------------------------------------

OA-ZYRA-122
Title:       Login / Welcome Screen — UX Review (Typography,
             Layout, Platform-Native Sign-In Priority)
Status:      Awaiting Review — implemented 2026-07-19 per
             Founder instruction ("fix and run all"). See
             DR-ZYRA-088 (PROPOSED, not yet ratified). Not yet
             visually verified on device.
Priority:    Medium
Owner:       Founder (Shakeel) — source: ChatGPT UX review
Raised:      2026-07-19
Completed:   —

Description: Founder is walking through the app with ChatGPT,
             which is producing UX review items in document
             form. Logged verbatim below, batch-style, per
             Founder instruction 2026-07-19 — no action taken,
             to be discussed individually in a future session.

             --- Source document begins ---

             # ZYRA OA – Login / Welcome Screen Review

             ## Status
             APPROVED

             ## Background
             Initial UX review of the ZYRA login/welcome screen
             identified several areas where the first impression
             could be improved. The goal is to create a cleaner,
             more premium, and platform-native experience.

             ## Agreed Improvements

             ### 1. ZYRA Typography
             The current ZYRA logo/font does not feel premium
             enough.
             Action:
             — Explore alternative typography for the ZYRA
               wordmark.
             — Aim for a more elegant, modern, premium identity
               while remaining simple and readable.

             ### 2. Screen Layout
             The welcome screen feels too open with excessive
             empty vertical space.
             Action:
             — Reduce unnecessary whitespace.
             — Improve vertical balance.
             — Bring the logo, slogan, and sign-in buttons
               closer together to create a more polished and
               intentional layout.

             ### 3. Platform-Native Sign-In Priority
             The primary sign-in option should match the user's
             device.
             Apple Devices (iPhone/iPad):
             — "Continue with Apple" should be the primary and
               largest sign-in button.
             — "Continue with Google" should be secondary.
             Android Devices:
             — "Continue with Google" should be the primary and
               largest sign-in button.
             — "Continue with Apple" should be secondary.
             This follows each platform's user expectations and
             creates a more natural onboarding experience.

             ## Design Goals
             — More premium first impression.
             — Better use of screen space.
             — Native platform feel.
             — Cleaner visual hierarchy.
             — Stronger ZYRA branding.

             --- Source document ends ---

Dependencies: SOURCE/lib/screens/welcome_screen.dart
              ZYRA wordmark / brand typography
              (BUSINESS/BRAND MESSAGING, BUSINESS/COLOUR THEME)

Notes:       Logged per Founder instruction 2026-07-19: a
             series of ChatGPT-authored UX review items is
             being batch-logged during a live app walkthrough.
             Each is filed as Open/Discussion only — none are
             to be actioned, scoped, or ratified until the
             Founder reviews them individually in a future
             session. Item 1 of an open-ended series (OA-ZYRA-123
             onward reserved for subsequent items in this same
             review pass).

------------------------------------------------------------

OA-ZYRA-123
Title:       Theme Consistency During Onboarding — Light Purple
             Default, Gender Accents Reserved for Profile Only
Status:      Awaiting Review — implemented 2026-07-19 per
             Founder instruction, with expanded scope: Founder
             directed that Luxury Dark Purple be removed from
             active use app-wide (not just onboarding), Royal
             Purple as primary. See DR-ZYRA-090 (PROPOSED, not
             yet ratified) — also directly overrides BUSINESS/
             COLOUR THEME/Summary.md and Onboarding Rules & UX
             §COLOUR SYSTEM, flagged there. Not yet visually
             verified on device.
Priority:    Medium
Owner:       Founder (Shakeel) — source: ChatGPT UX review
Raised:      2026-07-19
Completed:   —

Description: Founder is walking through the app with ChatGPT,
             which is producing UX review items in document
             form. Logged verbatim below, batch-style, per
             Founder instruction 2026-07-19 — no action taken,
             to be discussed individually in a future session.

             --- Source document begins ---

             # ZYRA OA – Theme Consistency During Onboarding

             ## Status
             APPROVED

             ## Background
             During the onboarding flow, the background colour
             changes from the ZYRA home screen's signature
             light purple to a much darker purple.
             This creates an inconsistent visual experience and
             makes onboarding feel disconnected from the
             Welcome screen.

             ## Approved Design Rule
             The default background colour throughout onboarding
             should remain the same signature ZYRA light purple
             used on the Welcome screen.
             Users should feel like they are progressing through
             one continuous experience, not moving between
             different themes.

             ## Theme Behaviour

             ### Default Screens
             Use the standard ZYRA light purple background
             throughout:
             — Welcome
             — Sign In
             — Sign Up
             — Onboarding
             — Profile Creation
             — General setup screens
             This should become the default ZYRA brand colour.

             ### Profile Context Only
             The profile accent colours should only appear once
             the user is viewing profile-related content.
             Examples:
             Male Profile Context — Blue accent theme.
             Female Profile Context — Pink accent theme.
             These colours should represent profile identity
             only and should not replace the main ZYRA brand
             colour during onboarding or general navigation.

             ## Design Goal
             Maintain one consistent premium brand identity
             across the onboarding journey while reserving
             gender accent colours for profile experiences only.
             The user should always feel they are inside the
             ZYRA ecosystem rather than moving between different
             colour themes.

             --- Source document ends ---

Dependencies: BUSINESS/COLOUR THEME/Summary.md
              SOURCE/lib/theme/zyra_colors.dart
              Onboarding screens (SOURCE/lib/screens/onboarding/)
              main.dart scaffoldBackgroundColor
              (currently 0xFF3D2A4A — matches the "much darker
              purple" this item flags)

Notes:       Logged per Founder instruction 2026-07-19 — item 2
             of an open-ended series of ChatGPT-authored UX
             review items being batch-logged during a live app
             walkthrough. Open/Discussion only, not actioned.
             Potential tension to flag for the future discussion
             (not resolved now): this item asks for one light
             purple across onboarding + general nav with gender
             accents reserved for profile screens, which may
             interact with existing gendered theming already
             live elsewhere (e.g. ZyraColors.brandGradientMale
             used on WaliProfileScreen, per zyra_auth.dart-
             adjacent files read this session) — worth checking
             during ratification whether "profile-related
             content" is meant to include Guardian screens too.

------------------------------------------------------------

OA-ZYRA-124
Title:       Account Types & UX Review — Per-Account Review Plan
             + Open Question on "Extended Guardian"
Status:      Resolved 2026-07-26 — see SYSTEM/DOCUMENTS/
             ZYRA_ACCOUNT_TYPE_UX_REVIEW_CURRENT_VERSION_V1.md
             (full review against all 10 criteria) and
             DR-ZYRA-107 (fixes implemented). The "Outstanding
             Question" on "Extended Guardian" below is separately
             resolved by DR-ZYRA-106 (renamed "Guardian+",
             2026-07-26, same day).
Priority:    Medium
Owner:       Founder (Shakeel) — source: ChatGPT UX review
Raised:      2026-07-19
Completed:   2026-07-26

Description: Founder is walking through the app with ChatGPT,
             which is producing UX review items in document
             form. Logged verbatim below, batch-style, per
             Founder instruction 2026-07-19 — no action taken,
             to be discussed individually in a future session.

             --- Source document begins ---

             # ZYRA OA – Account Types & UX Review

             ## Status
             APPROVED

             ## Background
             Before continuing the UI review, every account
             type should have its own dedicated review.
             Each account has different permissions,
             navigation, and user journeys, so they should be
             reviewed independently.

             ## Account Types to Review
             Seeker Basic — Male, Female
             Seeker One — Male, Female
             Guardian Basic — Male, Female
             Guardian+ — Male, Female

             ## Review Process
             Each account should be reviewed individually to
             confirm:
             — Navigation
             — Available tabs
             — Feature access
             — Upgrade prompts
             — User journey
             — Permissions
             — UI consistency
             — Empty states
             — Settings
             — Profile behaviour
             The goal is to ensure every account type feels
             complete and intentional.

             ## Outstanding Question
             The current build includes a navigation/tab
             labelled:
             — Guardian
             — Extended Guardian
             Before any design decisions are made, clarification
             is required on the intended purpose of "Extended
             Guardian."
             Please explain:
             — What is Extended Guardian?
             — How does it differ from the primary Guardian?
             — What permissions does it have?
             — Who can become an Extended Guardian?
             — Is this intended to support multiple family
               members?
             — Is the naming final, or should it be
               reconsidered?
             No UX changes should be made to this area until
             its purpose has been clarified and agreed.

             --- Source document ends ---

Dependencies: WALI_ARCHITECTURE_CURRENT_VERSION_V5.md
              (governs Extended Guardian already — see Notes)
              DeveloperAccessScreen presets (Seeker Basic/One
              m/f, Guardian, Guardian+Extended Guardian) — DR-ZYRA-087

Notes:       Logged per Founder instruction 2026-07-19 — item 3
             of an open-ended series of ChatGPT-authored UX
             review items being batch-logged during a live app
             walkthrough. Open/Discussion only, not actioned.
             Flagging for the future discussion (not resolved
             now, per batch-logging instruction): the "Outstanding
             Question" on Extended Guardian already has an answer on
             record — WALI_ARCHITECTURE_CURRENT_VERSION_V5.md is
             cited as governing it directly in DR-ZYRA-087, and
             DeveloperAccessScreen already ships a distinct
             "Guardian + Extended Guardian" preset built against that
             spec. When this item comes up for discussion, the
             fastest path may be pointing ChatGPT/Shakeel at
             that existing document rather than treating it as
             an open design question from scratch — worth
             checking whether the naming/scope there still
             matches what's live in the account-type review
             once that happens.

------------------------------------------------------------

OA-ZYRA-125
Title:       Browse Screen UI Refinements — Full-Screen Photos,
             Floating Glassmorphism Nav, Remove Swipe Counter
Status:      Awaiting Review — implemented 2026-07-19 per
             Founder instruction ("fix and run all"). See
             DR-ZYRA-089 (PROPOSED, not yet ratified). Not yet
             visually verified on device.
Priority:    Medium
Owner:       Founder (Shakeel) — source: ChatGPT UX review
Raised:      2026-07-19
Completed:   —

Description: Founder is walking through the app with ChatGPT,
             which is producing UX review items in document
             form. Logged verbatim below, batch-style, per
             Founder instruction 2026-07-19 — no action taken,
             to be discussed individually in a future session.

             --- Source document begins ---

             # ZYRA OA – Browse Screen UI Refinements

             ## Status
             APPROVED

             ## Background
             Following the Browse screen review, several UI
             refinements have been agreed to create a more
             immersive, premium experience.

             ## 1. Full-Screen Profile Images
             Profile photos should occupy the full screen. The
             image should extend behind the navigation controls
             rather than stopping above a coloured background.
             The profile image should become the primary visual
             focus.

             ## 2. Remove Bottom Purple Bar
             The solid purple bar currently shown at the bottom
             of the Browse screen should be removed. The image
             should continue to the bottom edge of the display.

             ## 3. Floating Navigation Bar
             Replace the current fixed navigation bar with a
             floating navigation bar.
             Design goals:
             — Glassmorphism / transparent appearance.
             — Rounded container.
             — Floating above the profile image.
             — Similar design language to Instagram's modern
               floating navigation.
             — Premium and lightweight.
             Navigation States —
             Selected: slightly larger icon, higher opacity,
             clear active state.
             Not Selected: slightly smaller icon, lower opacity,
             more subtle appearance.
             Navigation should remain visible while allowing the
             profile image to remain the main focus.

             ## 4. Action Buttons
             For now: Like, Save, Decline (where applicable)
             should sit directly above the floating navigation
             bar. These buttons should also use the same
             transparent glassmorphism styling. Final placement
             can be revisited during a later UX review.

             ## 5. Remove Swipe Counter
             The persistent display showing "0/50 Profiles •
             Reset in 2h" should not appear during normal
             browsing.
             Instead: hide this information completely during
             normal use; only display it if the user reaches
             their swipe/profile limit. At that point, present a
             clear modal or popup explaining the daily limit has
             been reached, when it resets, and available upgrade
             options (if applicable). The user should not be
             constantly reminded of remaining limits while
             browsing.

             ## Design Goals
             — Full-screen immersive browsing.
             — Cleaner interface.
             — Less visual clutter.
             — Premium glassmorphism styling.
             — Greater emphasis on profile photography.
             — Limits communicated only when relevant.

             --- Source document ends ---

Dependencies: SOURCE/lib/screens/ (Browse screen)
              BUSINESS/COLOUR THEME/Summary.md
              Swipe/profile daily limit logic (ZYRA Basic vs
              ZYRA One entitlement — ties to OA-121 Google Ads
              placement work, same Basic-tier surface)

Notes:       Logged per Founder instruction 2026-07-19 — item 4
             of an open-ended series of ChatGPT-authored UX
             review items being batch-logged during a live app
             walkthrough. Open/Discussion only, not actioned.

------------------------------------------------------------

OA-ZYRA-126
Title:       Additional Note — Navigation Structure Must Align
             With Existing Approved Architecture, Not Redesign
Status:      Open — Discussion Item (source document is a
             clarifying note, not itself an OA; logged here for
             Founder review only — not yet ratified in ZYRA
             governance, not yet actioned)
Priority:    Medium
Owner:       Founder (Shakeel) — source: ChatGPT UX review
Raised:      2026-07-19
Completed:   —

Description: Founder is walking through the app with ChatGPT,
             which is producing UX review items in document
             form. Logged verbatim below, batch-style, per
             Founder instruction 2026-07-19 — no action taken,
             to be discussed individually in a future session.

             --- Source document begins ---

             # Additional Note – Navigation Structure

             ## Existing OA Decision
             The bottom navigation has already been designed and
             agreed previously.
             Before making any navigation changes, please review
             the existing OA documentation and previous design
             documents to ensure this implementation remains
             consistent.
             The agreed navigation structure already exists
             within the project documentation.

             ### Current Navigation
             For Seeker accounts, the bottom navigation consists
             of:
             — Browse
             — Connections
             — Guardian
             — Profile

             Please refer to the previous OA documents for the
             complete behaviour, permissions, and account-specific
             variations.
             If anything in the current implementation differs
             from the previously approved design, please
             highlight the differences rather than creating a new
             navigation structure.
             The goal is to align the current UI with the
             existing approved architecture, not redesign it from
             scratch.

             --- Source document ends ---

Dependencies: OA-008 (Create Guardian Navigation folder), OA-009
              (Create Connections folder) — both prior OAs on
              this exact nav structure, status Blocked as of
              last read
              APP/Navigation/ (SEEKER NAVIGATION and related)
              SOURCE/lib/screens/ (Home/tab shell)

Notes:       Logged per Founder instruction 2026-07-19 — item 5
             of an open-ended series of ChatGPT-authored UX
             review items being batch-logged during a live app
             walkthrough. Open/Discussion only, not actioned —
             per instruction, not cross-checking this against
             OA-008/OA-009 or the live nav shell right now; that
             review is exactly what this item is asking for and
             belongs in the future discussion session, not this
             logging pass.

------------------------------------------------------------

OA-ZYRA-127
Title:       Developer Access Improvements — Male/Female Guardian
             Presets, Test Sign Up Flow, Skip Payment
Status:      Resolved 2026-07-26 — see DR-ZYRA-108 for what was
             built and, importantly, what was deliberately scoped
             out (8-way tier/gender picker, Skip Payment screen)
             with reasoning. §1 (Male/Female Guardian presets) was
             already done 2026-07-25, predating this pass.
Priority:    Medium
Owner:       Founder (Shakeel) — source: ChatGPT UX review
Raised:      2026-07-19
Completed:   2026-07-26

Description: Founder is walking through the app with ChatGPT,
             which is producing UX review items in document
             form. Logged verbatim below, batch-style, per
             Founder instruction 2026-07-19 — no action taken,
             to be discussed individually in a future session.

             --- Source document begins ---

             # ZYRA OA – Developer Access Improvements

             ## Status
             APPROVED

             ## Background
             The Developer Access area should better reflect
             the real user journeys available within ZYRA. This
             allows every account type and onboarding path to
             be tested without manually creating accounts or
             modifying the database.

             # 1. Expand Guardian Account Options
             The current Developer Access only provides a
             generic Guardian account. This should be split into
             two distinct account types.
             Add: Male Guardian, Female Guardian.
             Reason: Guardian accounts inherit the same visual
             identity rules as Seeker accounts — Male Guardian ->
             Male colour theme, Female Guardian -> Female colour
             theme. This allows the UI, profile layouts, accent
             colours, and navigation to be tested correctly for
             both experiences.

             # 2. Test Sign Up
             Add a new Developer Tool called "Test Sign Up."
             This should simulate a brand new user creating an
             account from scratch. The goal is to test the
             complete onboarding flow without needing to create
             real accounts repeatedly.

             ## Available Options
             The developer should be able to choose any account
             type. Examples: Seeker Basic (Male), Seeker Basic
             (Female), Seeker One (Male), Seeker One (Female),
             Guardian Basic (Male), Guardian Basic (Female), Guardian+
             (Male), Guardian+ (Female).

             # 3. Simulate Real User Journey
             Selecting an account should launch the normal
             production onboarding flow exactly as a real user
             would experience it. This includes: Welcome
             screens, Account creation, Onboarding, Compatibility
             questions, Profile creation. The only exception is
             payment.

             # 4. Subscription Testing
             If the selected account requires a subscription
             (e.g. Seeker One or Guardian+): display the normal
             subscription/payment screen. Within Developer Mode
             only, provide a Skip Payment option. Selecting Skip
             Payment should bypass payment, grant the chosen
             subscription, and continue onboarding normally.
             This allows the full premium onboarding experience
             to be tested without requiring live payments.

             # 5. Existing Developer Tools
             The following Developer Mode features should
             remain available alongside the new additions: Test
             Accounts, Jump To Screen, Test Sign Up. These serve
             different purposes — Test Accounts: instantly
             access preconfigured accounts. Jump To Screen:
             quickly navigate to any screen for UI testing. Test
             Sign Up: simulate the complete first-time user
             experience from account selection through
             onboarding.

             ## Goal
             Developer Mode should support both rapid UI testing
             and complete end-to-end onboarding testing while
             closely mirroring the production user experience.

             --- Source document ends ---

Dependencies: SOURCE/lib/screens/dev/developer_access_screen.dart
              SOURCE/supabase/seed_dev_accounts.sql (would need
              Male/Female Guardian seed rows added)
              DR-ZYRA-087 (existing dev switcher this extends)
              Subscription/payment screen + entitlement plumbing
              (Skip Payment needs somewhere real to hook into)

Notes:       Logged per Founder instruction 2026-07-19 — item 6
             of an open-ended series of ChatGPT-authored UX
             review items being batch-logged during a live app
             walkthrough. Open/Discussion only, not actioned.
             Flagging for the future discussion (not resolved
             now): §1's "generic Guardian account" is already stale
             relative to DR-ZYRA-087 — the current dev switcher
             already has 6 presets including a dedicated "Guardian +
             Extended Guardian" preset, not just one generic Guardian.
             §2/§3/§4 (Test Sign Up + Skip Payment) describe new
             functionality, not a fix to something existing.

------------------------------------------------------------

OA-ZYRA-128
Title:       Fix Theme Selection for Test Accounts — Blue/Purple
             and Pink/Purple Profile Gradients Not Applying
Status:      RESOLVED (#23, 2026-07-26) — see Resolution note below
Priority:    Medium
Owner:       Founder (Shakeel) — source: ChatGPT UX review
Raised:      2026-07-19
Completed:   2026-07-26

Description: Founder is walking through the app with ChatGPT,
             which is producing UX review items in document
             form. Logged verbatim below, batch-style, per
             Founder instruction 2026-07-19 — no action taken,
             to be discussed individually in a future session.

             --- Source document begins ---

             # ZYRA OA – Fix Theme Selection for Test Accounts

             ## Status
             APPROVED

             ## Background
             The Test Accounts within Developer Mode are not
             loading the correct colour themes. The
             application's theme system has already been
             defined and documented. Please review the existing
             theme configuration files before making any
             changes to ensure the implementation matches the
             approved design.

             ## Expected Theme Behaviour

             ### Default ZYRA Theme
             The default application theme is the ZYRA light
             purple theme. This should be used throughout the
             app unless a profile-specific theme is required.

             ### Male Profile Theme
             When the active profile is Male (Seeker or Guardian),
             the interface should use the approved Blue -> Purple
             gradient/theme. Applies to: Seeker Basic (Male),
             Seeker One (Male), Guardian Basic (Male), Guardian+
             (Male).

             ### Female Profile Theme
             When the active profile is Female (Seeker or Guardian),
             the interface should use the approved Pink -> Purple
             gradient/theme. Applies to: Seeker Basic (Female),
             Seeker One (Female), Guardian Basic (Female), Guardian+
             (Female).

             ## Current Issue
             The Test Accounts are not correctly applying the
             profile theme after loading. Instead, they appear
             to be using an incorrect or fallback colour scheme.

             ## Required Action
             Please review the existing: Theme files, Colour
             definitions, Design system, Theme provider,
             Developer Mode account loading logic. The approved
             colour system already exists within the project
             documentation and should be used as the source of
             truth. Do not create a new colour palette unless an
             issue is identified with the existing implementation.
             Instead, ensure the correct theme is selected
             automatically based on: Account type, Profile
             gender.

             ## Theme Rules
             Purple = Default ZYRA application theme.
             Blue -> Purple = Male profile theme.
             Pink -> Purple = Female profile theme.
             These themes should be applied consistently across
             both production accounts and Developer Mode test
             accounts.

             ## Goal
             Developer Mode should accurately reflect the visual
             experience of real user accounts so that UI testing
             is performed against the correct theme for every
             account type.

             --- Source document ends ---

Dependencies: SOURCE/lib/theme/zyra_colors.dart
              SOURCE/lib/screens/dev/developer_access_screen.dart
              DR-ZYRA-090

Notes:       Logged per Founder instruction 2026-07-19 — item 7
             of an open-ended series of ChatGPT-authored UX
             review items being batch-logged during a live app
             walkthrough. Open/Discussion only, not actioned.
             DIRECT CONFLICT to flag for the future discussion:
             this item's "Theme Rules" (Blue -> Purple for Male,
             Pink -> Purple for Female, gradients ending in
             Purple) describe the system as it existed BEFORE
             DR-ZYRA-090 (2026-07-19), not after. DR-ZYRA-090 —
             applied that same session — changed brandGradientMale/
             brandGradientFemale from Blue/Pink fading to (Luxury
             Dark) Purple into flat Blue / flat Pink with no Purple
             endpoint at all, creating the DIRECT CONFLICT this note
             originally flagged.

Resolution (2026-07-26, #23): the conflict is moot — DR-ZYRA-094
             (2026-07-25, ratified, see zyra_colors.dart header and
             DECISIONS_V1.md) superseded DR-090 and restored the
             fade-to-Luxury-Dark-Purple design for exactly this
             reason. The live implementation today (genderGradient()
             in zyra_colors.dart) matches this OA's original "Theme
             Rules" exactly: Blue -> Purple for Male, Pink -> Purple
             for Female, neutral Purple as the default/fallback.
             Verified via a full grep of every `gradient:` usage in
             SOURCE/lib (2026-07-26): every profile-context screen
             (Seeker: Browse, Connections, Profile, Journey, Chat,
             Timeline, Upgrade, Notifications, Settings; Guardian:
             Dashboard, Profile, Network, Seekers, Journey Detail,
             Link/Invite flows) calls genderGradient(gender) — no
             lingering hardcoded brandGradientMale/Female calls
             anywhere. developer_access_screen.dart's dev-preset
             gender-passing gap (the actual mechanism this OA's
             "Developer Mode account loading logic" dependency
             pointed at) was already fixed 2026-07-25 (gender is
             passed into applyDevPreset for both Seeker and Guardian
             presets). One fresh gap found and fixed in the same
             pass: the newly-built Help & Support screen
             (screens/settings/help_support_screen.dart, #22) used
             the neutral brandGradient instead of genderGradient() —
             corrected. One inert, out-of-scope quirk noted but not
             touched: wali_onboarding_flow.dart hardcodes
             ZyraBackgroundVariant.male into backgroundFor(), which
             currently has no visible effect (DR-ZYRA-090/OA-ZYRA-123:
             onboarding stays flat/non-gendered for every variant by
             deliberate decision) — would only become a real bug if
             OA-ZYRA-123 is later resolved to make onboarding
             gender-derived, which is that OA's scope, not this one's.

------------------------------------------------------------

OA-ZYRA-129
Title:       Browse Navigation Bar Structure — 5-Tab Order
             (Browse/Connections/Guardian/Network/Profile), Network
             Premium Lock State
Status:      Open — Discussion Item (source document
             self-labelled "APPROVED" by ChatGPT; logged here
             for Founder review only — not yet ratified in ZYRA
             governance, not yet actioned)
Priority:    Medium
Owner:       Founder (Shakeel) — source: ChatGPT UX review
Raised:      2026-07-19
Completed:   —

Description: Founder is walking through the app with ChatGPT,
             which is producing UX review items in document
             form. Logged verbatim below, batch-style, per
             Founder instruction 2026-07-19 — no action taken,
             to be discussed individually in a future session.

             --- Source document begins ---

             # ZYRA OA – Browse Navigation Bar Structure

             ## Status
             APPROVED

             ## Background
             The new floating navigation bar is moving in the
             right direction. However, the navigation items do
             not yet match the approved ZYRA navigation
             architecture. Please refer to the existing OA
             documentation before making changes, as the
             navigation structure has already been defined.

             ## Approved Navigation Order
             The Browse navigation bar should contain the
             following tabs in this order:
             1. Browse
             2. Connections
             3. Guardian
             4. Network
             5. Profile
             This should become the standard navigation for
             Seeker accounts.

             ## Network Tab Behaviour
             The Network tab is a premium feature.

             ### ZYRA Basic
             The Network tab should remain visible but appear
             locked. Examples of acceptable behaviour include:
             locked icon, reduced opacity, premium badge
             (optional). Tapping the locked tab should present
             the normal premium upgrade flow. The tab should not
             disappear, as its presence helps users discover
             premium features.

             ### ZYRA One
             Users with a ZYRA One subscription should have full
             access to the Network tab. No lock icon should be
             shown.

             ## Existing Documentation
             Before implementing these changes, please review
             the existing OA documents and navigation files. If
             the current implementation differs from the
             approved navigation architecture, update it to
             match the documented behaviour rather than creating
             a new navigation structure.

             ## Goal
             Ensure all Seeker accounts use the approved
             navigation architecture while clearly distinguishing
             premium features through a consistent locked-state
             experience for ZYRA Basic users.

             --- Source document ends ---

Dependencies: OA-008 (Create Guardian Navigation folder, Blocked),
              OA-009 (Create Connections folder, Blocked)
              OA-ZYRA-126 (same topic, logged earlier this batch)
              SOURCE/lib/screens/home/home_shell.dart
              ZYRA Seeker subscription entitlements (Network
              lock state needs to read plan somehow)

Notes:       Logged per Founder instruction 2026-07-19 — item 8
             of an open-ended series of ChatGPT-authored UX
             review items being batch-logged during a live app
             walkthrough. Open/Discussion only, not actioned.
             Flagging for the future discussion: the live
             HomeShell today has only 3 tabs (Browse, Matches,
             Profile) — no Connections, Guardian, or Network tab
             exists in the running app at all, so this isn't a
             re-order of existing tabs, it's building 2 new tabs
             from scratch (Connections, Network) plus moving Guardian
             from its own top-level shell (WaliHomeShell) into a
             tab inside the Seeker shell — a bigger structural
             question than the wording ("do not yet match")
             implies. Also inconsistent with OA-ZYRA-126 (logged
             earlier in this same batch), which described the
             "current navigation" as 4 tabs (Browse, Connections,
             Guardian, Profile) — no Network. Neither description
             matches the live 3-tab build, and the two ChatGPT
             items don't fully agree with each other either.
             OA-008/OA-009 (this exact Connections/Guardian folder
             work) have been Blocked "awaiting Summary from
             Shakeel" since before this session — worth resolving
             those first, since they're prerequisites, not just
             related.

------------------------------------------------------------

OA-ZYRA-130
Title:       Profile Photo Display & Cropping — BoxFit.cover,
             crop editor, safe-area overlay
Status:      Actioned 2026-07-25 — resolved via DR-ZYRA-096. Manual
             crop editor filed as an exception path only (low AI
             crop confidence, or explicit user-initiated adjustment
             after the fact), not the default flow, per Founder
             decision. Filed into APP/Standards/IMAGE_HANDLING_
             CURRENT_VERSION_V2.md §MANUAL CROP ADJUSTMENT.
Completed:   2026-07-25
Priority:    Medium
Owner:       Founder (Shakeel) — source: ChatGPT UX review
Raised:      2026-07-19
Completed:   —

Description: Founder is walking through the app with ChatGPT,
             which is producing UX review items in document
             form. Logged verbatim below, batch-style, per
             Founder instruction 2026-07-19 — no action taken,
             to be discussed in a future session, before the
             ZYRA app-build phase of this session begins.

             --- Source document begins ---

             ## Profile Photo Display & Cropping (Approved
             Recommendation)

             ### Objective
             Ensure every uploaded profile photo looks clean,
             professional, and consistent within ZYRA's full-
             screen Browse experience, regardless of the device
             or photo dimensions.

             ### Display Behaviour
             - Profile photos should always fill the entire
               Browse screen.
             - Images must never be stretched or distorted.
             - Use BoxFit.cover (or equivalent) to maintain the
               original aspect ratio while filling the available
               space.
             - Any excess image outside the display area should
               be cropped automatically.

             ### Upload & Cropping Flow
             When a user uploads a profile photo:
             1. Select photo from device.
             2. Open a crop editor before saving.
             3. Display the crop using the exact same aspect
                ratio as the Browse screen.
             4. Allow users to:
                - Pinch to zoom.
                - Drag the image to reposition it.
                - Preview exactly how it will appear on their
                  profile.
             5. Save the crop settings rather than permanently
                cropping the original image.

             ### Crop Data
             Retain the original image and store crop metadata,
             including:
             - Zoom level
             - Horizontal position (X)
             - Vertical position (Y)
             This allows the same crop to be recreated whenever
             the photo is displayed while preserving the original
             image quality.

             ### Safe Area Overlay
             The crop editor should include a visual "safe area"
             indicating where the user's face should ideally be
             positioned. This accounts for UI elements that
             overlay the image, such as:
             - Status bar
             - Navigation controls
             - Profile name and age
             - Action buttons
             - Bottom navigation bar
             Users should be able to clearly see which parts of
             the image are likely to remain visible during
             browsing.

             ### Benefits
             - Consistent appearance across all devices.
             - No stretched or distorted photos.
             - Users know exactly how their profile will appear
               before saving.
             - Maintains a premium, polished browsing experience.
             - Works seamlessly with photos from iPhone, Android,
               and other camera sources.

             --- Source document ends ---

Notes:       Logged per Founder instruction 2026-07-19. Open/
             Discussion only, not actioned.

------------------------------------------------------------

OA-ZYRA-131
Title:       Profile Photo Moderation & Safety — AI screening,
             authenticity checks, face detection, manual review
Status:      Actioned 2026-07-25 — resolved via DR-ZYRA-096. Safety
             & Authenticity Screening merged into IMAGE_HANDLING_
             CURRENT_VERSION_V2.md as a new pipeline stage, alongside
             the existing AI Quality Evaluation; the two previously-
             parallel review flows merged into one Moderation
             Decision & Manual Review section. Cost Considerations
             also filed there.
Completed:   2026-07-25
Priority:    Medium
Owner:       Founder (Shakeel) — source: ChatGPT UX review
Raised:      2026-07-19
Completed:   —

Description: Founder is walking through the app with ChatGPT,
             which is producing UX review items in document
             form. Logged verbatim below, batch-style, per
             Founder instruction 2026-07-19 — no action taken,
             to be discussed in a future session, before the
             ZYRA app-build phase of this session begins.

             --- Source document begins ---

             ## Profile Photo Moderation & Safety (Approved
             Recommendation)

             ### Objective
             Ensure all profile photos are safe, authentic,
             respectful, and appropriate before becoming visible
             on ZYRA.

             ## Moderation Pipeline
             Every uploaded photo should pass through an
             automated moderation pipeline before approval.

             ### Stage 1 – AI Safety Screening
             Immediately after upload, an AI moderation service
             checks for:
             - Nudity or sexually explicit content
             - Partial nudity
             - Pornographic material
             - Suggestive content
             - Violence or gore
             - Weapons
             - Drugs or drug use
             - Hate symbols or extremist imagery
             - Illegal content
             - Offensive gestures
             - Graphic injuries
             - Text embedded within images (optional)
             - Low-quality or corrupted images
             Photos that clearly violate policy are automatically
             rejected.

             ### Stage 2 – Authenticity Checks
             The system should detect whether the uploaded image
             is likely to be:
             - AI-generated
             - A meme
             - A screenshot
             - A celebrity
             - A stock image
             - A logo
             - A landscape with no person
             - A pet-only photo
             - A cartoon or illustration
             - Multiple unrelated people
             - Excessively edited or filtered
             Depending on confidence, these photos can either:
             - Be rejected automatically.
             - Be sent for manual review.
             - Request the user to upload another photo.

             ### Stage 3 – Face Detection
             Ensure the primary profile photo contains:
             - At least one clearly visible human face.
             - Good image quality.
             - Adequate lighting.
             - Face not excessively obscured.
             - Face occupies a reasonable portion of the image.
             If no suitable face is detected, prompt the user to
             upload a different photo.

             ### Stage 4 – Manual Review (Exception Queue)
             Only uncertain or borderline cases should be
             reviewed by a human moderator. Examples:
             - AI confidence below approval threshold.
             - Possible cultural clothing confusion.
             - Borderline suggestive images.
             - Potential impersonation.
             - User appeals after rejection.
             This keeps moderation costs low while improving
             accuracy.

             ## User Experience
             Users should see a simple status after uploading:
             - Uploading...
             - Checking photo...
             - Approved
             - Needs another photo
             - Under review (if required)
             Most users should receive an approval within a few
             seconds.

             ## Reporting
             Even after approval, users should be able to report
             inappropriate photos. Reported photos can:
             - Be temporarily hidden.
             - Enter the moderation queue.
             - Lead to warnings or account restrictions for
               repeated violations.

             ## Cost Considerations
             Modern AI image moderation is relatively
             inexpensive. Typical commercial moderation APIs
             generally cost around:
             - Approximately $0.001–$0.01 USD per image depending
               on the provider and features used.
             Example:
             - 10,000 photo uploads ≈ $10–$100 USD
             - 100,000 photo uploads ≈ $100–$1,000 USD
             - 1,000,000 photo uploads ≈ $1,000–$10,000 USD
             Because only a small percentage of uploads should
             require human review, the ongoing moderation cost
             remains manageable even as the platform grows.

             ## Recommended Architecture
             1. User uploads photo.
             2. Store the original image securely.
             3. Run AI moderation.
             4. Run authenticity detection.
             5. Run face detection.
             6. If all checks pass:
                - Approve automatically.
                - Save crop metadata.
                - Make photo visible.
             7. If confidence is low:
                - Queue for manual review.
             8. If policy is violated:
                - Reject the upload and request a replacement.
             This layered approach provides strong protection
             against inappropriate content while keeping
             operational costs low and maintaining a fast user
             experience.

             --- Source document ends ---

Notes:       Logged per Founder instruction 2026-07-19. Open/
             Discussion only, not actioned.

------------------------------------------------------------

OA-ZYRA-132
Title:       Browse Screen Reporting & Safety Actions — three-
             dot menu (Report / Hide / Block)
Status:      Actioned 2026-07-25 — filed into APP/Browse/
             BROWSE_UX_SPEC_CURRENT_VERSION_V2.md §Profile Actions
             (DR-ZYRA-095). Checked against existing docs first, no
             conflicts found. Resolves the Browse-screen/Seeker-to-
             Seeker portion only of JOURNEY MANAGEMENT/Summary.md's
             Safety & Moderation Open Discussion — Guardian blocking and
             Active-Journey-stage effects remain open there.
Completed:   2026-07-25
Priority:    Medium
Owner:       Founder (Shakeel) — source: ChatGPT UX review
Raised:      2026-07-19
Completed:   —

Description: Founder is walking through the app with ChatGPT,
             which is producing UX review items in document
             form. Logged verbatim below, batch-style, per
             Founder instruction 2026-07-19 — no action taken,
             to be discussed in a future session, before the
             ZYRA app-build phase of this session begins.

             --- Source document begins ---

             # ZYRA – Browse Screen Reporting & Safety Actions
             Version: V1
             Status: Approved

             # Objective
             Provide users with a simple, discoverable, and
             scalable way to report, hide, or block profiles
             without interfering with the primary swipe
             experience. The reporting system should remain
             easily accessible while maintaining a clean, premium
             Browse interface.

             # Recommended UI
             A small three-dot (•••) menu should be permanently
             visible in the top-right corner of every Browse
             profile.
             This approach is preferred over a dedicated flag
             icon or hidden long-press gesture.

             # Why Not Long Press?
             Although a long-press gesture keeps the interface
             visually cleaner, it introduces several usability
             issues:
             - Poor discoverability (many users may never know it
               exists).
             - Can conflict with swipe gestures.
             - Users may accidentally trigger it while pausing
               before swiping.
             - Hidden interactions are generally discouraged for
               critical safety features.
             For these reasons, reporting should remain a visible
             action.

             # Why Not a Flag Icon?
             A flag icon is recognisable for reporting, but has
             limitations:
             - Suggests reporting is the only available action.
             - Leaves no room for future options.
             - Appears more aggressive on every profile.
             - Less flexible as the platform evolves.

             # Recommended Action Menu
             Selecting the three-dot menu should display a bottom
             sheet or action menu containing:
             - Report Profile
             - Hide Profile
             - Block User
             - Cancel
             This design is familiar to users while remaining
             minimal and scalable.

             # Action Definitions

             ## Report Profile
             Used when a user believes a profile violates ZYRA's
             Community Guidelines. Examples include:
             - Fake profile
             - Impersonation
             - Nudity
             - Violence
             - Underage user
             - Harassment
             - Other policy violations
             Reports enter the moderation pipeline for automated
             and/or manual review.

             ## Hide Profile
             Purpose: "I don't want to see this profile again."
             Characteristics:
             - No penalty applied to the reported user.
             - Removes the profile from future recommendations.
             - Does not notify the other user.
             - Reversible via account settings (optional).
             This option should be encouraged instead of
             reporting when the user simply is not interested.

             ## Block User
             Purpose: Prevent any future interaction between two
             users. Effects:
             - Both users become invisible to each other.
             - Existing likes or matches are removed (if
               applicable).
             - Messaging is disabled.
             - No notification is sent.
             This is intended for unwanted contact rather than
             policy violations.

             # Report Flow
             1. User taps the three-dot menu.
             2. Selects Report Profile.
             3. Chooses a reporting reason.
             4. Optionally provides additional details.
             5. Submits the report.
             6. The report enters ZYRA's moderation system.
             7. User receives confirmation that the report has
                been submitted.

             # Design Principles
             The reporting system should:
             - Never interfere with swiping.
             - Always remain discoverable.
             - Require as few taps as possible.
             - Clearly distinguish between: Hide / Block / Report
             - Scale easily as additional profile actions are
               introduced.

             # Future Expansion
             The three-dot menu provides flexibility to introduce
             additional profile actions without redesigning the
             Browse screen. Potential future additions include:
             - Share Profile
             - Copy Profile Link
             - Save for Later
             - Report Specific Photo
             - Report Specific Prompt
             - Mute Profile
             - Export Conversation (where applicable)

             # Approved Recommendation
             Adopt a permanently visible three-dot (•••) menu in
             the top-right corner of every Browse profile. This
             solution offers the best balance of: Discoverability,
             User safety, Clean UI, Gesture compatibility, Future
             scalability. It also clearly separates Hide, Block,
             and Report, reducing false reports while providing
             users with the appropriate action for each situation.

             --- Source document ends ---

Notes:       Logged per Founder instruction 2026-07-19. Open/
             Discussion only, not actioned.

------------------------------------------------------------

OA-ZYRA-133
Title:       Active Journey System Proposal — "One Active
             Journey" rule retained, Journey Queue section,
             availability statuses
Status:      Actioned 2026-07-25 (partial — see note below) —
             resolved via DR-ZYRA-097. "One Active Journey" required
             no new decision (already established). "Potential
             Journey Statuses" filed as a new "Availability Status"
             section in APP/Journey/JOURNEY AVAILABILITY/Summary.md,
             extending the existing Journey Eligibility concept —
             not a new architecture document. Colour model reduced
             from 4 statuses to 3, reusing existing traffic-light
             colours (DR-ZYRA-093). **Not resolved by this action:**
             whether the source document was genuinely truncated and
             more content exists — still an open question for the
             Founder to confirm if/when relevant.
Priority:    Medium
Completed:   2026-07-25 (partial, see Status)
Owner:       Founder (Shakeel) — source: ChatGPT UX review
Raised:      2026-07-19
Completed:   —

Description: Founder is walking through the app with ChatGPT,
             which is producing UX review items in document
             form. Logged verbatim below, batch-style, per
             Founder instruction 2026-07-19 — no action taken,
             to be discussed in a future session, before the
             ZYRA app-build phase of this session begins.

             **Update, 2026-07-19:** this item's content (the
             Active Journey proposal itself) remains undiscussed
             and unactioned — that has not changed. But this OA
             was the triggering incident for a separate,
             now-resolved architectural discussion: the proposal
             re-derived relationship states (Potential Journey /
             Active Journey / etc.) already ratified in
             ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V3.md Part 0,
             because the Master Spec wasn't checked first. That
             finding led to DR-ZYRA-092 (implementation checklist,
             citation discipline, ownership test — see Decisions
             Register), Founder-ratified 2026-07-19 following
             independent review by Fable (Opus 4). When this OA's
             actual content is eventually discussed, it should be
             the first real test of DR-ZYRA-092's checklist:
             check Product Spec V3 Part 0 against this proposal
             before treating any of it as new.

             **Logging note:** the pasted source text ends mid-
             sentence, inside the "Potential Journey Statuses" /
             example UX mock-up section, after "🟡 Maryam /
             Currently in an Active Journey" — no closing
             "Approved Recommendation" or summary section was
             received, unlike the other three items in this
             batch. Logged verbatim as received, not completed
             or paraphrased. Flag for Founder: confirm whether
             the rest of this document exists and should be
             pasted separately before this item is discussed.

             **Update, 2026-07-25:** checked against
             `APP/Journey/JOURNEY AVAILABILITY/Summary.md` per
             ZYRA_EXECUTION_V3.md §3.2 — that document already
             covers this ground in more depth (Core Principle
             matches exactly; "Journey Eligibility" section already
             expresses eligible/not-eligible per matched user, with
             reasons). This proposal's 🟢/🟡/⚪/⚫ status-badge model
             is a plausible user-facing presentation of that
             existing eligibility concept, not a new architectural
             state (no Feature-State Covenant conflict, Product
             Spec V3 Part 0 checked). But it isn't a simple filing:
             the document is truncated (see Logging note above) and
             the 4-status model needs reconciling against Journey
             Availability's existing eligibility language before
             either is treated as canonical. Raised to ChatGPT
             2026-07-25 rather than filed unilaterally.

             --- Source document begins (as received, appears
             incomplete) ---

             # ZYRA – Active Journey System Proposal
             **Status:** Proposal for Review

             # Overview
             The current ZYRA philosophy is that users may
             receive and maintain multiple matches, but can only
             have one Active Journey at any given time. The
             intention behind this design is to encourage
             meaningful, intentional relationships rather than
             allowing users to divide their attention across
             multiple conversations. This document evaluates
             whether that philosophy should remain and proposes
             improvements to the user experience.

             # Recommendation
             Retain the "One Active Journey" rule. While users
             may have many matches, they should only be able to
             actively pursue one relationship at a time. This
             should remain one of ZYRA's core differentiators.

             # Why One Active Journey?
             Unlike traditional dating apps, ZYRA is designed
             around intentional relationship building. Allowing
             multiple simultaneous journeys would naturally
             encourage users to:
             - Compare multiple people simultaneously.
             - Split their attention between several
               conversations.
             - Treat other matches as backup options.
             - Create an experience similar to mainstream dating
               apps.
             Restricting users to a single Active Journey instead
             encourages:
             - Full attention on one potential spouse.
             - Faster and more meaningful progression.
             - Greater trust between both individuals.
             - A clearer signal that both people are genuinely
               invested.
             - Greater confidence for families and Guardians that the
               process is serious.
             The underlying message becomes: "If someone has
             chosen to begin a Journey with you, they have paused
             pursuing everyone else." This reinforces ZYRA's
             identity as a serious marriage platform rather than
             a dating application.

             # Multiple Matches Should Still Exist
             Having only one Active Journey does not mean hiding
             all other matches. Instead, matched users who are
             not currently in an Active Journey should appear in
             a dedicated section. Suggested name: Potential
             Journeys. This allows users to:
             - See who they have matched with.
             - Understand who is currently available.
             - Know who may become available in the future.
             - Begin another Journey immediately if their current
               Journey ends.
             This avoids the feeling that other matches have
             disappeared.

             # Potential Journey Statuses
             Rather than using progress bars or percentages, each
             matched user should display a simple availability
             status.

             🟢 Available — The user is not currently in an
             Active Journey. A Journey can be started immediately.

             🟡 In Active Journey — The matched user is currently
             pursuing another Journey. A new Journey cannot begin
             until theirs ends.

             ⚪ Paused — The matched user has temporarily paused
             their account or is otherwise unavailable.

             ⚫ Hidden / Inactive — The account has been hidden,
             removed or is no longer available.

             # Privacy Considerations
             Users should never be shown private information
             regarding another person's Journey. Examples of
             information that should not be displayed include:
             - How long they have been in a Journey.
             - Their Journey stage.
             - Compatibility progress.
             - Family discussions.
             - Proposal status.
             - Estimated completion.
             The only information required is whether they are
             currently available. This preserves privacy while
             still giving users useful visibility.

             # User Experience
             Example:
             Journey Queue (9)
             🟢 Aisha — Available
             🟡 Maryam — Currently in an Active Journey

             --- Source document ends (received text stops here)
             ---

Notes:       Logged per Founder instruction 2026-07-19. Open/
             Discussion only, not actioned. Appears truncated —
             see Logging note above.

------------------------------------------------------------

OA-ZYRA-134
Title:       ZYRA git repository — no commit since 2026-07-03,
             91 uncommitted files, no rollback point
Status:      Open
Priority:    High
Owner:       Founder (Shakeel) / Lead Architect
Raised:      2026-07-19
Completed:   —

Description: Found 2026-07-19 during Fable (Opus 4)'s final
             text-check of the ZYRA Documentation Architecture
             package (DR-ZYRA-092) — flagged as a separate
             finding, not a defect in that package. Verified
             directly: `git log` shows a single commit ("Initial
             commit — independent repository for ZYRA",
             2026-07-03); `git status --porcelain` shows 91
             modified/untracked files (excluding .DS_Store) as
             of 2026-07-19, including 9 modified Summary.md
             files dating back to at least 2026-07-12 (e.g. the
             ZYRA PRICING rewrite, 233 deletions).

             This means the ZYRA repository currently has no
             rollback point and no per-change traceability at
             the version-control layer for over three weeks of
             real work — in tension with the project's own
             Files-Over-Memory discipline and the Level 5
             rollback intent (OA-024). All governance-register
             discipline (DR/OA logging, single-current-version
             archiving) has continued correctly throughout this
             period — the gap is specifically that none of it is
             backed by git commits, only by the working-tree
             files themselves.

             Recommend: commit current state as a checkpoint,
             then establish a commit cadence (e.g. after each
             ratified DR, or daily) going forward. Not scoped or
             actioned here — Founder decision on cadence and
             whether prior history should be reconstructed or
             simply start clean from a checkpoint commit.

Related:     DR-ZYRA-092, OA-024 (Level 5 rollback intent),
             OA-AIOS-274 (BLK-level equivalent finding — no
             backup mechanism for AIOS operational data — same
             failure class: real data, zero recovery path)

------------------------------------------------------------

OA-ZYRA-135
Title:       Browse Page — Gesture-Based Profile Actions (swipe
             left=Consider, right=Pass, down=Save; removes action
             buttons)
Status:      Actioned 2026-07-25 — resolved via DR-ZYRA-099. Founder
             confirmed directly: swipe gestures adopted, overriding
             the prior tap-only rule, with terminology renamed
             Decline→Pass, Like→Consider (Save unchanged). Filed into
             APP/Navigation/SEEKER NAVIGATION/Summary.md §BROWSE,
             APP/Matching/PROFILE DECISION SYSTEM/Summary.md, and
             APP/Browse/BROWSE_UX_SPEC_CURRENT_VERSION_V3.md.
Priority:    Medium
Owner:       Founder (Shakeel) — source: ChatGPT UX review
Raised:      2026-07-25
Completed:   2026-07-25

Description: --- Source document begins ---

             FEATURE NAME
             BROWSE PAGE – GESTURE-BASED PROFILE ACTIONS

             Change Type: UX Enhancement
             Status: Draft

             BACKGROUND
             The current Browse page displays action buttons
             (Decline, Save and Like) positioned above the bottom
             navigation bar. This creates unnecessary visual
             clutter and occupies valuable screen space that
             should remain focused on the profile itself. ZYRA
             already uses gesture-first interactions throughout
             its premium UX philosophy. The Browse experience
             should follow the same approach.

             DECISION
             Remove the floating action buttons above the bottom
             navigation bar. The primary profile actions will now
             be performed using swipe gestures.

             GESTURE ACTIONS
             Swipe Left → Like
             Swipe Right → Decline
             Swipe Down → Save

             USER EXPERIENCE
             The profile should remain clean and distraction-free.
             The user naturally performs gestures directly on the
             profile card rather than reaching for separate
             buttons. Each gesture should include smooth animation
             and clear visual feedback so the user immediately
             understands what action has occurred.

             DESIGN GOALS
             Modern, Natural, Fast, Minimal, Premium. The user's
             focus should remain on the profile rather than
             interface controls.

             BOTTOM NAVIGATION
             The bottom navigation bar must remain dedicated solely
             to application navigation. No profile-action buttons
             should appear above or overlap the navigation bar. The
             navigation bar should continue supporting both tap
             navigation and horizontal slide navigation (recently
             approved UX enhancement). These navigation gestures
             are completely separate from the profile swipe
             gestures.

             IMPLEMENTATION NOTES
             Before implementing this change, review all existing
             Browse documentation within the repository. In
             particular: Browse feature documentation, Profile
             Decision System, Journey-related documentation, any
             specifications governing profile interactions and
             swipe behaviour. Do not introduce new interaction
             behaviour if an existing specification already governs
             it. If any conflict or unresolved decision is
             identified, stop implementation and raise it before
             making assumptions. This enhancement should extend the
             existing Browse architecture rather than replace it.

             EXPECTED RESULT
             The Browse screen becomes significantly cleaner. Users
             interact directly with profiles through intuitive
             gestures. The bottom navigation bar remains exclusively
             for navigating between application pages.

             --- Source document ends ---

Notes:       Related, non-conflicting existing spec found for
             completeness: `APP/Navigation/SEEKER NAVIGATION/
             Script/Script_V2.md` line 257 has "Preferred
             transition: Swipe Right → Left" for the *animation*
             shown after a tap-decision (Tinder/Bumble/Instagram-
             Stories-styled card transition) — this is visual
             output, not gesture input, and does not conflict with
             or resolve the tap-vs-swipe-input question above.
             Also surfaced a smaller, separate, pre-existing
             terminology drift while checking: BROWSE_UX_SPEC_
             CURRENT_VERSION_V2.md's User Actions table has no
             explicit "Decline" action (uses "Skip / Scroll past —
             implicit dismissal" instead), while PROFILE DECISION
             SYSTEM/Summary.md and SEEKER NAVIGATION/Summary.md both
             treat Decline as an explicit, named button/action. Not
             blocking this item; logged separately below as
             OA-ZYRA-137.

------------------------------------------------------------

OA-ZYRA-136
Title:       Bottom Navigation Bar — Slide Gesture Support (drag
             across nav bar, release to navigate, alongside
             existing tap navigation)
Status:      Actioned 2026-07-25 — filed into APP/Navigation/
             SEEKER NAVIGATION/Summary.md §NAVIGATION UI. Checked
             against existing documentation: no conflict found —
             SEEKER NAVIGATION's "tap-only" rule is explicitly
             scoped to Browse's Decline/Save/Like actions, not
             bottom-navigation. Complements the already-approved
             DR-ZYRA-091 Instagram-style motion behaviour (sliding
             circular highlight between tabs) rather than
             conflicting with it. Inherits, but does not resolve,
             SEEKER NAVIGATION's already-flagged 2026-07-19
             tab-count/naming inconsistency (3 vs 4 tabs; Guardian vs
             Safety) — that remains open, unrelated to this filing.
Priority:    Medium
Owner:       Founder (Shakeel) — source: ChatGPT UX review
Raised:      2026-07-25
Completed:   2026-07-25

Description: --- Source document begins ---

             FEATURE NAME
             BOTTOM NAVIGATION BAR – SLIDE GESTURE SUPPORT

             Change Type: UX Enhancement
             Status: Draft

             BACKGROUND
             The current bottom navigation bar supports page
             changes by tapping navigation items only. This
             enhancement improves usability without changing the
             existing navigation structure.

             DECISION
             The bottom navigation bar shall support two navigation
             methods: Tap Navigation (existing) and Slide Navigation
             (new). Users should be able to place their finger
             anywhere on the navigation bar and slide horizontally
             across the navigation items. As the finger moves, the
             highlighted navigation item moves in real time with
             continuous visual feedback and a smoothly animating
             floating indicator. When the user releases their
             finger, the currently highlighted item becomes
             selected and navigation changes immediately.

             BUSINESS RULES
             The new gesture does not replace tap navigation — both
             must remain available. Navigation should only occur on
             release; while sliding, only the visual selection
             changes.

             IMPLEMENTATION NOTES
             Detect horizontal drag input; continuously determine
             which navigation item is beneath the finger; animate
             the active indicator smoothly; trigger navigation only
             on release. Must not interfere with vertical scrolling,
             page swipe gestures, or other application interactions.

             --- Source document ends ---

Notes:       Filed same-day. See APP/Navigation/SEEKER NAVIGATION/
             Summary.md §NAVIGATION UI for the filed content.

------------------------------------------------------------

OA-ZYRA-137
Title:       Terminology drift — BROWSE_UX_SPEC_CURRENT_VERSION_V2
             has no explicit "Decline" action (uses implicit
             "Skip / Scroll past"), while PROFILE DECISION SYSTEM
             and SEEKER NAVIGATION both treat Decline as an
             explicit named action
Status:      Resolved 2026-07-25 — superseded by DR-ZYRA-099's
             terminology overhaul (Decline→Pass) and mechanism
             change (BROWSE_UX_SPEC V2→V3), filed the same day as a
             side effect of resolving OA-ZYRA-135. Pass is now an
             explicit swipe-right action in the User Actions table,
             not an implicit "Skip/Scroll past" — the gap this item
             identified no longer exists.
Priority:    Low
Owner:       Lead Architect
Raised:      2026-07-25
Completed:   2026-07-25

Description: Found while checking OA-ZYRA-135 against existing
             Browse documentation. `BROWSE_UX_SPEC_
             CURRENT_VERSION_V2.md`'s User Actions table lists
             Save, Like, and "Skip / Scroll past" (implicit
             dismissal, no record) — no explicit Decline row.
             `APP/Matching/PROFILE DECISION SYSTEM/Summary.md`
             (rewritten 2026-07-12 against Product Spec V3, the
             canonical owner of this fact per Group 4 — Page
             Responsibilities) and `APP/Navigation/SEEKER
             NAVIGATION/Summary.md` both treat 🔴 Decline as an
             explicit, named, tap-only button — not an implicit
             scroll-past. Live code (browse_screen.dart) also has
             an explicit `_onDecline` handler, matching the
             Decline-as-button model. `BROWSE_UX_SPEC` predates
             the 2026-07-12 terminology correction (it's dated
             2026-07-04) and appears to have been missed by that
             pass. Low priority — doesn't block anything currently
             filed, but BROWSE_UX_SPEC's Final UI Decisions table
             should be corrected to show Decline as an explicit
             button/action, matching the two owning documents,
             next time that file is meaningfully edited.

Related:     OA-ZYRA-135, APP/Matching/PROFILE DECISION SYSTEM/
             Summary.md, APP/Navigation/SEEKER NAVIGATION/
             Summary.md, BROWSE_UX_SPEC_CURRENT_VERSION_V2.md

------------------------------------------------------------

OA-ZYRA-138
Title:       Master Product Spec still uses "Like" terminology —
             not updated to Pass/Save/Consider (DR-ZYRA-099)
Status:      RESOLVED (2026-07-26, #25) — see Resolution note below
Priority:    Low
Owner:       Lead Architect
Raised:      2026-07-25
Completed:   2026-07-26

Description: `ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V3.md` Part 2
             ("Like Rules") uses the pre-2026-07-25 "Like"
             terminology. DR-ZYRA-099 renamed Decline→Pass and
             Like→Consider across `PROFILE DECISION SYSTEM/
             Summary.md`, `SEEKER NAVIGATION/Summary.md`, and
             `BROWSE_UX_SPEC_CURRENT_VERSION_V3.md`, but the Master
             Spec itself — the highest-precedence document, per this
             project's own ownership rules — was deliberately not
             edited as part of that filing, since editing the Master
             Spec is a bigger-consequence action than updating the
             documents that cite it. `PROFILE DECISION SYSTEM/
             Summary.md` currently carried a note flagging this
             gap inline (its Incoming Potentials section). Low
             priority — doesn't block anything currently filed,
             the terminology is unambiguous in context either way,
             but the Master Spec should be updated to match next
             time it's meaningfully touched, to avoid this being
             the seed of a future drift finding.

Resolution (2026-07-26, #25): Applied DR-ZYRA-099's terminology
             (Decline→Pass, Like→Consider; Save unchanged) throughout
             the Master Spec's Parts 0–3 — this was in fact the
             document's own "meaningfully touched" trigger condition.
             Per this project's single-current-version convention,
             this was filed as a version bump rather than a silent
             in-place edit: previous content archived unmodified as
             `ZYRA_PRODUCT_SPEC_2026-07-26_V3.md`; new
             `ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V4.md` carries the
             corrected terminology plus a Version History entry
             documenting the change as terminology-only (no
             architectural, lifecycle, rule, or numeric content
             changed). All other live documents citing the Master
             Spec by filename were updated to the new V4 filename;
             dated historical records (Decisions Register entries,
             the CHANGELOG, the 2026-07-12 terminology/pricing audit
             snapshot) were deliberately left referencing V3, since
             they describe actions that genuinely happened against
             V3 at the time. The inline flag in `PROFILE DECISION
             SYSTEM/Summary.md`'s Incoming Potentials section is
             removed as part of this resolution.

Related:     DR-ZYRA-099, ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V4.md
             Part 2, APP/Matching/PROFILE DECISION SYSTEM/Summary.md

------------------------------------------------------------

OA-ZYRA-154
Title:       restart_journey() Reopens an Ended Journey Without the Other
             Party's Consent, and Deletes the Record
Category:    Engineering / Safety / Data Integrity
Priority:    CRITICAL — fix independently of the wider redesign. Do not
             wait for the journey_attempts migration.
Status:      CLOSED — implemented and verified against the live database
             2026-08-06.
Owner:       Opus (Implementation Lead)
Raised:      2026-08-06
Completed:   2026-08-06

Resolution:  Migration oa154_restart_journey_safety_fix.

             restart_journey() now REFUSES. It raises
             restart_requires_mutual_consent for a party to the match,
             after the existing identity checks so the error never
             confirms a match the caller is not part of.

             All six DELETEs removed (V3 item 13 — no Journey history is
             ever deleted). The conversations status bug is corrected in
             the preserved body. Two further defects were found while
             verifying and are also fixed:

               ended_at = NULL — not named in V3. Erased the fact that
               the Journey had ended at all, so a pattern of endings
               became invisible to a Guardian or moderator.

               Orphaned family reviews — journey_family_answers was
               deleted while journey_family_reviews was not, leaving a
               review whose answers no longer existed. Resolved by
               removing the deletes.

             INTERPRETATION, flagged for the Founder: V3 §16 item 1 says
             "mutual consent"; V3 §9 and OA-ZYRA-159 define what that
             consent is (Request New Journey, Accept / Decline / Decline-
             and-don't-ask-again, 6-month cooldown, 14-day expiry, hidden
             decline type). Building an interim handshake here would have
             meant writing a consent mechanism with different semantics
             days before the approved one replaced it. With `matches` at
             0 rows and 0 ended matches, removing the path costs no user
             anything and closes the defect completely today. Reversible
             in one edit — the guarded, non-destructive body is preserved
             commented inside the function for OA-ZYRA-159.

             UI: the "Restart Journey" button and its 24-hour countdown
             are removed from journey_flow_screen. _EndedView is
             stateless again (one Timer.periodic fewer per ended
             Journey). ZyraJourneyService.restartJourney is @Deprecated
             and throws.

Verified:    Built a real ended match with history, then as the party —
             refused, mutual_consent; as a signed-in non-party — refused,
             not a party; anonymous — refused, not_signed_in. History
             survived, ended_at intact, status still 'ended'. Fixtures
             removed; matches back to 0 rows.
Source:      DR-ZYRA-121 / ZYRA_JOURNEY_LIFECYCLE_CURRENT_VERSION_V3.md
             (Fable + ChatGPT joint architecture, Founder-approved
             2026-08-06). Read from the live function 2026-08-06, not
             from spec.
Description: restart_journey() requires only that the match is ended, 24
             hours have passed, and neither party holds another active
             Journey. It NEVER asks the other person. It then DELETEs
             from six tables — journey_compatibility, journey_salams,
             journey_phase_answers, journey_phase_ratings,
             journey_phase_checkpoints, journey_family_answers — before
             setting status back to 'active'. A person who ended a
             Journey because they felt unsafe can therefore be returned
             to an Active Journey they never re-consented to, with the
             evidence wiped. SECOND DEFECT in the same function: it runs
             UPDATE conversations SET status = 'closed', closed_at = NULL
             — marking the conversation closed while clearing the
             timestamp recording when it closed. Restarting a Journey
             should not close its conversation; 'active' was almost
             certainly intended.
Target:      Minimum fix: require both parties to consent before an ended
             Journey reopens, and remove all six DELETE statements.
             Correct the conversations status in the same pass. This
             function is superseded entirely by Request New Journey (OA-
             ZYRA-159) but must not be left unsafe in the interim.
Dependencies: SOURCE/supabase — restart_journey(); OA-ZYRA-159; DR-
             ZYRA-121.
Automation:  None.

------------------------------------------------------------

OA-ZYRA-155
Title:       Classify Every Journey Column as Mine / Theirs / Joint
             Before the Migration Begins
Category:    Governance / Legal / Data Protection
Priority:    High — BLOCKED OA-ZYRA-156. Now complete.
Status:      CLOSED — Founder approved 2026-08-06 with amendments. Two
             items remain OPEN pending solicitor (see below); they do not
             block OA-ZYRA-156 because they are encoded as
             'pending-legal' and an export refuses anything not
             explicitly cleared.
Owner:       Founder, with Opus implementing the classification
Raised:      2026-08-06
Completed:   2026-08-06

Resolution:  ZYRA_JOURNEY_FIELD_CLASSIFICATION_CURRENT_VERSION_V2.md.
             Migrations oa155_data_ownership_classification and
             oa155_close_classification_gaps.

             47 columns across 14 tables now carry an OWNERSHIP: comment
             IN THE DATABASE, not only in documentation — Founder
             requirement, so the classification travels with the schema
             and an export routine can read it rather than a developer
             re-deriving it under a 30-day statutory clock.

             Vocabulary: joint | mine/theirs | row-scoped(<col>) |
             third-party(<who>) | non-exportable | pending-legal.

             public.zyra_data_ownership resolves every classified column
             and flags anything uncommented as UNCLASSIFIED. It caught
             four columns the hand-written pass had missed within seconds
             of creation. Currently: 0 unclassified, 3 pending-legal.

             FOUNDER AMENDMENTS:
             - Guardian decisions private to the Guardian; Seekers get
               the Family Review OUTCOME only, never individual
               decisions or comments. Enforced as
               third-party(guardian) on the whole table.
             - timeline_milestones.metadata non-exportable until it has
               a defined schema. "Loosen later if appropriate, not the
               other way around."
             - safety_concern approved exactly as proposed: never
               visible to the other party by export or indirect route.
             - NEW REQUIREMENT: the ownership model explicitly covers
               attachment data from the outset — documents, evidence,
               voice notes, photos, future file attachments. §15 of the
               V2 document. profile_photos classified now so the rule
               exists before there are more tables. The Storage object
               inherits its row's class, and an export must include the
               FILE, not the path.

OPEN — SOLICITOR (do not settle by engineering assumption):
             1. Whether messages sent BY THE OTHER PARTY appear in a
                subject access export. Encoded pending-legal on
                messages.content and messages.read_at.
             2. Whether another person's opinion ("they rated you
                Amber") must be disclosed under Art.15's source limb.
                Encoded pending-legal on journey_phase_ratings.rating.
             3. RAISED BY OPUS, same referral: evidence attachments
                supporting a report or safety concern must be
                non-exportable to the subject of that report. An export
                handing someone the evidence filed against them defeats
                V3 §3's rule that a barred person must never learn a
                safety hold exists.
Source:      DR-ZYRA-121 / ZYRA_JOURNEY_LIFECYCLE_CURRENT_VERSION_V3.md
             (Fable + ChatGPT joint architecture, Founder-approved
             2026-08-06).
Description: A journey attempt is a SHARED object between two people.
             Earlier versions of this architecture claimed shared objects
             simplify GDPR; that is true for erasure (Art. 17) and FALSE
             for access (Art. 15). When Person A files a subject access
             request, the attempt object contains B's end reason, B's
             Guardian's identity and B's phase answers. Without a field-
             level classification, someone must read nine tables and
             decide line by line what belongs to whom, under a 30-day
             statutory clock. Classifying at migration time makes the
             export mechanical; classifying later means a solicitor doing
             it by hand.
Target:      Produce a column-by-column classification (mine / theirs /
             joint) for all nine attempt-scoped tables before any DDL is
             written. Record it as an approved document.
Dependencies: OA-ZYRA-156 (blocked by this); WEBSITE_IA_AND_LEGAL_PAGES
             CURRENT_VERSION_V1.md; DR-ZYRA-121.
Automation:  None.

------------------------------------------------------------

OA-ZYRA-156
Title:       Introduce journey_attempts Beneath matches, and
             attempt_visible_to() as the Single Authorisation Helper
Category:    Engineering / Architecture
Priority:    High — the core migration. Cheapest now; all ten tables are
             empty.
Status:      Open — approved. Blocked by OA-ZYRA-155.
Owner:       Opus (Implementation Lead)
Raised:      2026-08-06
Completed:   —
Source:      DR-ZYRA-121 / ZYRA_JOURNEY_LIFECYCLE_CURRENT_VERSION_V3.md
             (Fable + ChatGPT joint architecture, Founder-approved
             2026-08-06).
Description: Move from 'a match that reopens' to 'a pair that can have
             several attempts'. matches remains the permanent one-row-
             per-pair record (it already carries CHECK (seeker_a_id <
             seeker_b_id) and UNIQUE (seeker_a_id, seeker_b_id)). Nine
             tables currently key off match_id and move to attempt_id:
             conversations, journey_compatibility,
             journey_family_answers, journey_family_reviews,
             journey_phase_answers, journey_phase_checkpoints,
             journey_phase_ratings, journey_salams, timelines. They carry
             15 RLS policies between them. CRITICAL: re-point those
             policies at a helper function attempt_visible_to(attempt_id,
             auth.uid()) rather than at new inline SQL. Adding a mediator
             or family member later then costs one function change
             instead of fifteen policy rewrites; at five roles, inline
             SQL becomes seventy-five policies re-deriving the same
             logic. This is free ONLY if done during this migration.
             Nothing is ever deleted when a new attempt begins. VERIFIED
             2026-08-06: matches holds 0 rows and all nine dependants
             hold 0 rows, so this is DDL and code only — no data
             migration.
Target:      Build after OA-ZYRA-155 completes. One Decision Record of
             its own for the migration mechanics. Two fixes come free:
             the one-Active-Journey rule becomes schema-enforceable
             rather than depending on every write path checking it, and
             the unreachable 'paused' value leaves the CHECK constraint.
Dependencies: OA-ZYRA-155 (blocking); OA-ZYRA-157; DR-ZYRA-121; the
             2026-08-05 profile-photos storage policy defect, which is
             the live precedent for duplicated authorisation logic
             failing quietly.
Automation:  None.

------------------------------------------------------------

OA-ZYRA-157
Title:       Introduce protection_holds as a Table, Not a Single
             Protection State
Category:    Engineering / Safety / Moderation
Priority:    High — safety-bearing.
Status:      COMPLETED 2026-08-10, verified not assumed.
             protection_holds built, with zyra_hold_blocks() as its
             only reader. 16 checks passing: safety holds cannot be
             appealable, cooldowns must expire, permanent holds must
             not, no self-holds, releases are all-or-nothing, released
             rows are RETAINED as audit, and the hold is DIRECTIONAL —
             the person who declines is not restricted in return.
             RLS on with zero policies DELIBERATELY: a hold must be
             unreadable by the person it restricts, or a safety hold
             announces itself (DR-ZYRA-121 item 5).
             ONE DEFECT FOUND AND FIXED THE SAME SITTING: the first
             release constraint passed a HALF-released row — released,
             with a reason, no actor. It ran cleanly and did nothing,
             which is the failure mode the 2026-07-26 audit named, and
             it surfaced only because the release path was tested
             rather than re-read.
             Migrations 20260810091517 and 20260810091643.
Owner:       Opus (Implementation Lead)
Raised:      2026-08-06
Completed:   2026-08-10
Source:      DR-ZYRA-121 / ZYRA_JOURNEY_LIFECYCLE_CURRENT_VERSION_V3.md
             (Fable + ChatGPT joint architecture, Founder-approved
             2026-08-06).
Description: Protection is the result of one or more active holds, not a
             single value. Failing case for an enum: B safety-locks after
             ending, AND moderation locks the pair over an unrelated
             report against A; the moderator lock is overturned on
             appeal. A single enum must fall back to 'safety_locked' —
             meaning it was stored elsewhere anyway, or B's protection
             silently evaporates through an appeal she was never party
             to. Table columns: match_id, hold_type ('safety' |
             'moderator'), held_by, created_at, released_at (NULL =
             active), reason_ref. Current protection = strongest active
             hold, computed. GOVERNANCE: a safety hold is placed by the
             person who ended citing safety and released ONLY by that
             person or by support at their request; a moderator hold is
             placed and released by moderation only. A SAFETY HOLD IS
             NEVER APPEALABLE, because the barred person must never learn
             it exists — they simply never see the option to request a
             new Journey. Appeals apply to moderator holds only. Blocking
             stays in profile_blocks; it is mutual invisibility, not a
             Journey rule.
Target:      Build with OA-ZYRA-156. The table doubles as the audit log
             for protection, satisfying part of OA-ZYRA-163.
Dependencies: OA-ZYRA-156; OA-ZYRA-163; profile_blocks; DR-ZYRA-121.
Automation:  None.

------------------------------------------------------------

OA-ZYRA-158
Title:       Record ended_by, ended_at and end_reason on Every Journey
             Ending
Category:    Engineering / Product / Safety
Priority:    High — independently valuable; can ship before the full
             restructure.
Status:      Open — approved.
Owner:       Opus (Implementation Lead)
Raised:      2026-08-06
Completed:   —
Source:      DR-ZYRA-121 / ZYRA_JOURNEY_LIFECYCLE_CURRENT_VERSION_V3.md
             (Fable + ChatGPT joint architecture, Founder-approved
             2026-08-06).
Description: Endings currently record only ended_at. There is no ended_by
             and no reason, so a mutual respectful ending and someone
             fleeing a frightening situation are indistinguishable in the
             data. Six reasons, deliberately not more: not compatible;
             circumstances changed; marrying elsewhere; family decision;
             safety concern; I'd rather not say — plus one optional free-
             text field ('Anything you'd like them to know?'). Long lists
             at painful moments produce whichever option is least
             awkward, not the true one. REJECTED and recorded so they are
             not re-proposed: ghosting (the ghost never opens the
             dropdown — this is system-detected, ended_by 'system', a
             different field); mutual decision (unverifiable from one
             person's tap); personal readiness and life priorities (both
             are 'circumstances changed'); religious incompatibility
             (invites one Muslim to formally record a judgement about
             another's deen — stays inside 'not compatible'). TWO RULES:
             only 'safety concern' is hidden from the other party; a
             safety ending places a safety hold on the pair.
Target:      Ship early — this is small, independently valuable, and
             every later feature (moderation, Guardian history, support
             cases, analytics) depends on knowing how a Journey ended.
Dependencies: OA-ZYRA-157 (safety hold); OA-ZYRA-161; DR-ZYRA-121.
Automation:  None.

------------------------------------------------------------

OA-ZYRA-159
Title:       Replace Restart With Request New Journey (Mutual Consent,
             Cooldowns, Hidden Decline Type)
Category:    Product / Engineering / Safety
Priority:    High.
Status:      COMPLETED 2026-08-10, verified not assumed. FIVE
             STAGES, 62 checks, all passing.
             1  notification types extended BEFORE the first write —
                the CHECK permitted four and would have thrown. Same
                shape as contradiction-audit finding 4.9.
             2  protection_holds (OA-ZYRA-157).
             3  journey_requests + RLS, one pending request per pair.
                Status is COARSE on purpose: which kind of decline,
                and whether it was a decision or an expiry, lives only
                in protection_holds, which the requester cannot read.
             4a conversations and timelines moved from UNIQUE(match_id)
                to UNIQUE(attempt_id). THE blocker — attempt #2 had
                nowhere to put its conversation. Both tables were
                empty, so a constraint swap with nothing to migrate.
             4b four Dart lookups re-pointed. One was a privacy bug
                waiting: a GUARDIAN reading by match_id would have been
                shown the PREVIOUS attempt's messages.
             4c request_new_journey / respond_to_journey_request /
                zyra_may_request_new_journey.
             5  14-day expiry treated as a decline. Notification body
                asserted BYTE-IDENTICAL to a real decline — if a
                decline notified while an expiry stayed silent, the
                requester could tell them apart by watching for
                silence. An expiry hold is never permanent: silence is
                not "don't ask again".
             5b batched may-request lookup — per-row is the N+1 this
                project has a written rule against.
             ACCEPT PRESERVES EVERYTHING. Attempt #1 keeps its ending
             record, matches.ended_at is NOT cleared, the old
             conversation and its messages survive untouched, and the
             new conversation is empty. A fresh start is fresh because
             the NEW conversation is empty, not because the old one was
             destroyed — precisely where restart_journey went wrong
             (OA-ZYRA-154).
             COPY CORRECTED: "Ended — Restart available" removed. It
             promised from 2026-08-07 a capability that had refused
             since the 6th (audit 4.2). The row now reads "Ended" and
             the offer lives in a button that appears only when the
             server says you may ask.
             Migrations 20260810091414, 091517, 091643, 092650, 092734,
             143519, 144418, 150000, 150500.
             OUTSTANDING: no flutter analyze has run on any of the
             Dart. That is the one thing not verified.
Owner:       Opus (Implementation Lead), UX by Fable
Raised:      2026-08-06
Completed:   2026-08-10
Source:      DR-ZYRA-121 / ZYRA_JOURNEY_LIFECYCLE_CURRENT_VERSION_V3.md
             (Fable + ChatGPT joint architecture, Founder-approved
             2026-08-06).
Description: One person requests; the other decides. Never unilateral,
             never a resurrection — a new attempt starts fresh with its
             own timeline. Recipient options: Accept, Decline, or Decline
             and don't ask again. A plain decline sets a 6-month
             cooldown; 'don't ask again' is permanent. THE REQUESTER IS
             NEVER TOLD WHICH — both render identically as no option to
             request. If the distinction were visible it would become
             information about the recipient's feelings and an invitation
             to react. An unanswered request expires after 14 days, and
             expiry counts as a decline for cooldown purposes, because
             silence is an answer and forcing a response is its own small
             coercion. A decline DOES generate a notification — hiding it
             behind the expiry would mean fourteen days of hope for
             something already answered.
Target:      Supersedes restart_journey() entirely. The 6-month and
             14-day numbers are guesses and are flagged for post-launch
             review — see V3 §16 items 14 and 15.
Dependencies: OA-ZYRA-154 (interim fix); OA-ZYRA-156; DR-ZYRA-121.
Automation:  None.

------------------------------------------------------------

OA-ZYRA-160
Title:       Per-Person Opaque Reference Codes for Journey Attempts
Category:    Product / Support / Moderation
Priority:    Medium — must be decided before journey_attempts is created,
             since codes generate at attempt creation.
Status:      Open — approved.
Owner:       Opus (Implementation Lead)
Raised:      2026-08-06
Completed:   —
Source:      DR-ZYRA-121 / ZYRA_JOURNEY_LIFECYCLE_CURRENT_VERSION_V3.md
             (Fable + ChatGPT joint architecture, Founder-approved
             2026-08-06).
Description: A reference for support and moderation conversations, under
             two constraints. (1) OPAQUE, NEVER SEQUENTIAL. 'Journey
             Attempt #3' reintroduces the numbering the UX model
             deliberately rejects, and a support agent reading '#3' forms
             a judgement before reading the case. Avoid characters that
             collapse when typed or read aloud (0/O, 1/I/l). (2) ONE CODE
             PER PERSON PER ATTEMPT, NOT ONE SHARED CODE. An attempt is a
             shared object; a reference to it must not be. With a single
             shared code, either party can quote the other's case
             identifier, a code shown to a third party becomes evidence
             of a connection, and in a safety case the protected person's
             report and the barred person's enquiry share a key. Two
             codes resolving to the same attempt server-side give
             moderation everything and give neither party a handle on the
             other.
Target:      Generate at attempt creation so the code exists in the audit
             trail from the first moment. Show on request, not by default
             — a reference code sitting permanently on a Journey card is
             a quiet reminder that this is a case file.
Dependencies: OA-ZYRA-156; OA-ZYRA-163; DR-ZYRA-121.
Automation:  None.

------------------------------------------------------------

OA-ZYRA-161
Title:       Implement the Journey Notification Map, Including the Two
             Safety Rules
Category:    Product / UX / Safety
Priority:    High — contains two safety-bearing rules.
Status:      Open — approved.
Owner:       Opus (Implementation Lead), UX by Fable
Raised:      2026-08-06
Completed:   —
Source:      DR-ZYRA-121 / ZYRA_JOURNEY_LIFECYCLE_CURRENT_VERSION_V3.md
             (Fable + ChatGPT joint architecture, Founder-approved
             2026-08-06).
Description: Two structural principles first. (A) SEPARATE 'visible in-
             app' FROM 'pushes'. Almost everything should be visible;
             very few should push. Without that distinction one Journey
             generates ten notifications and people disable all of them,
             including the ones that matter. (B) GUARDIANS GET A DIGEST,
             NOT A STREAM — push only for endings and accepted requests.
             A Guardian receiving live pings as a Journey moves is
             surveillance regardless of what the permission model calls
             it. TWO SAFETY RULES: (1) A safety ending must be worded
             IDENTICALLY to an ordinary ending for the other party — if
             the notification differs even slightly, the protection hold
             announces itself. (2) Safety reasons are disclosed to nobody
             automatically, INCLUDING THE ENDER'S OWN GUARDIAN. If a
             woman ends a Journey because she felt unsafe, that is hers
             to tell her family, in her words, at her timing;
             automatically routing it to a male relative is fine in most
             households and dangerous in a minority, and ZYRA cannot tell
             which it is looking at. Her Guardian is told the Journey
             ended. Moderation sees the reason. A protection hold being
             placed generates NO notification to anyone, ever.
Target:      Full map in ZYRA_JOURNEY_LIFECYCLE_CURRENT_VERSION_V3.md
             §11. Guardian digest frequency (daily vs weekly) is
             deliberately left open — V3 §16 item 17.
Dependencies: OA-ZYRA-157; OA-ZYRA-158; OA-ZYRA-162;
             WALI_ARCHITECTURE_CURRENT_VERSION_V6.md; DR-ZYRA-121.
Automation:  None.

------------------------------------------------------------

OA-ZYRA-162
Title:       Guardian Involvement Becomes Per-Attempt, With Fresh Family
             Review Each Attempt
Category:    Product / Wali Architecture
Priority:    High.
Status:      Open — approved.
Owner:       Opus (Implementation Lead), UX by Fable
Raised:      2026-08-06
Completed:   —
Source:      DR-ZYRA-121 / ZYRA_JOURNEY_LIFECYCLE_CURRENT_VERSION_V3.md
             (Fable + ChatGPT joint architecture, Founder-approved
             2026-08-06).
Description: The Guardian must know a Journey is a repeat — not telling
             them makes the role decorative, and 'you supported this
             Journey before' is exactly the context the role needs. BUT
             the Guardian may not be the same person: the first attempt's
             Guardian could be her father, the second's her brother.
             Therefore Guardian involvement is recorded PER ATTEMPT, not
             per pair. A NEW Guardian sees that a previous Journey
             existed and how it ended (unless safety), but NEVER inherits
             the previous Guardian's notes or conversations — those were
             one person's private observations, and handing them to a
             different family member is a disclosure nobody consented to.
             The SAME Guardian returning keeps their own history. FAMILY
             REVIEW RUNS FRESH EVERY ATTEMPT, without exception: a
             family's blessing for the first Journey is not blessing for
             the second.
Target:      Update WALI_ARCHITECTURE_CURRENT_VERSION_V6.md alongside the
             build — it currently describes Guardian involvement per
             pair.
Dependencies: OA-ZYRA-156; OA-ZYRA-161;
             WALI_ARCHITECTURE_CURRENT_VERSION_V6.md; DR-ZYRA-121.
Automation:  None.

------------------------------------------------------------

OA-ZYRA-163
Title:       Append-Only Audit Log, Scoped to Protection, Moderation,
             Appeals and Safety Endings
Category:    Engineering / Governance / Legal
Priority:    Medium-High.
Status:      Open — approved.
Owner:       Opus (Implementation Lead)
Raised:      2026-08-06
Completed:   —
Source:      DR-ZYRA-121 / ZYRA_JOURNEY_LIFECYCLE_CURRENT_VERSION_V3.md
             (Fable + ChatGPT joint architecture, Founder-approved
             2026-08-06).
Description: Full event sourcing is NOT approved and was deliberately
             rejected as over-engineering for a pre-launch app. But
             ended_by and end_reason are state, not history, and some
             changes cannot be reconstructed after the fact. The
             discipline is: log what you would need to defend, not
             everything. Four append-only event types — protection holds
             placed and released (largely satisfied by the
             protection_holds table itself); moderator actions; appeal
             outcomes; safety-flagged endings. Anything that could reach
             a solicitor or Ofcom. Everything else remains current state.
Target:      Build with OA-ZYRA-157, which supplies most of it.
Dependencies: OA-ZYRA-157; OA-ZYRA-158; OA-ZYRA-160; DR-ZYRA-121.
Automation:  None.

------------------------------------------------------------

OA-ZYRA-164
Title:       Pause Remains Premium — Define the Gated Rule, Remove the
             Auto-End Timer, Apply the Guardrails
Category:    Product / Premium / Safety
Priority:    High — contains a direct conflict with an approved document.
Status:      Open — approved as amended by the Founder.
Owner:       Opus (Implementation Lead), UX by Fable
Raised:      2026-08-06
Completed:   —
Source:      DR-ZYRA-121 / ZYRA_JOURNEY_LIFECYCLE_CURRENT_VERSION_V3.md
             (Fable + ChatGPT joint architecture, Founder-approved
             2026-08-06). Founder amendment 2026-08-06: Pause is NOT made
             free.
Description: The joint recommendation to make Pause free was NOT
             approved; Pause remains a ZYRA One capability, to be
             revisited after beta on evidence (OA-ZYRA-165). That
             amendment changes the rule, because the approved
             architecture read 'either person may pause', which only
             holds if everyone can. CORRECTED RULE: anyone may be
             AFFECTED by a pause; only ZYRA One may INITIATE one. The
             Journey is paused while any pause is active and resumes when
             every pause has been lifted. Only the person who placed a
             pause may lift it. Existing slot behaviour in
             JOURNEY_SUSPENSION_CURRENT_VERSION_V1 §5.1-5.3 is sound and
             carries forward — a Basic Seeker's slot frees immediately
             when the other party pauses, so they are never locked out by
             a decision they could not have taken. CONFLICT TO RESOLVE:
             that same document §5.3 specifies a 30-DAY FULL SUSPENSION
             AUTO-END TIMER, which contradicts the approved principle
             that ZYRA never automatically ends a Journey. The timer must
             be REMOVED and replaced with reminders at 30 and 90 days,
             then indefinite. GUARDRAILS (V3 §7A): (1) ending a Journey
             is always free, for everyone, always — nobody may ever need
             to pay to leave; (2) no upgrade prompt on the received-pause
             screen, because upgrading would not let a Basic Seeker lift
             the other person's pause, so the prompt sells nothing it can
             deliver, and monetising the moment someone else acted on you
             is the pattern OA-ZYRA-152 already flags; (3) the received-
             pause screen offers exactly two actions, wait or end, both
             free; (4) Pause is never marketed as a way to hold or
             reserve a person.
Target:      Remove the auto-End timer and reissue JOURNEY_SUSPENSION as
             a new CURRENT_VERSION reflecting Pause terminology and the
             gated rule.
Dependencies: APP/Journey/JOURNEY
             SUSPENSION/JOURNEY_SUSPENSION_CURRENT_VERSION_V1.md; OA-
             ZYRA-152 (DR-I test); OA-ZYRA-165; DR-ZYRA-121.
Automation:  None.

------------------------------------------------------------

OA-ZYRA-165
Title:       Instrument the Pause Decision So It Can Be Revisited on
             Evidence After Beta
Category:    Product / Analytics / Governance
Priority:    Medium — must ship WITH beta, not after, or the evidence
             will not exist when the question is asked.
Status:      Open — approved.
Owner:       Opus (Implementation Lead), measurement design by Fable
Raised:      2026-08-06
Completed:   —
Source:      DR-ZYRA-121 / ZYRA_JOURNEY_LIFECYCLE_CURRENT_VERSION_V3.md
             (Fable + ChatGPT joint architecture, Founder-approved
             2026-08-06). Founder: 'We can revisit that decision after
             beta if real user behaviour suggests it should change.'
Description: The Founder has deferred the Pause pricing question to beta
             evidence. That deferral is only meaningful if the evidence
             is collected, so the instrumentation must ship with beta
             rather than be retrofitted. Three measures, in order of
             usefulness. (1) DIRECT: on the ending flow, for ZYRA Basic
             Seekers only, one optional question — 'Would you have
             preferred to pause this Journey instead?'. This converts a
             values argument into data and is by far the cheapest
             instrument. (2) GHOST RATE BY PLAN: compare system-detected
             endings (ended_by 'system') for Basic vs One Seekers. If
             Basic Seekers ghost materially more, that is the predicted
             failure mode appearing. (3) REASON MIX BY PLAN: the share of
             endings citing 'circumstances changed' among Basic vs One
             Seekers, as a proxy for people who would have stepped back
             if they could. Report at the end of beta as a single figure
             against each measure, with no recommendation attached — the
             Founder asked for evidence, not another argument.
Target:      Ship with beta. Review at beta close.
Dependencies: OA-ZYRA-158 (end reasons); OA-ZYRA-164; DR-ZYRA-121.
Automation:  None.

------------------------------------------------------------


------------------------------------------------------------

OA-ZYRA-139
Title:       Developer Mode — Test Accounts & Test Sign-Up
             (formalises existing Test Accounts build, adds new
             Test Sign-Up capability)
Status:      Actioned 2026-07-25 — resolved via DR-ZYRA-100. No
             conflict found. Checked against APP/Developer Mode/
             Script/Script_V1.md (stale terminology, predates the
             2026-07-19 live rebuild), live code
             (developer_access_screen.dart — Test Accounts already
             substantially built), and upgrade_screen.dart (no real
             payment integration exists yet — flagged as a caveat on
             the Payment section, not a blocker). Filed as
             Script_V2.md.
Priority:    Medium
Owner:       Founder (Shakeel) — source: ChatGPT UX review
Raised:      2026-07-25
Completed:   2026-07-25

Description: --- Source document begins ---

             FEATURE NAME
             DEVELOPER MODE – TEST ACCOUNTS & TEST SIGN-UP

             Change Type: Developer Tool Enhancement
             Status: Draft

             BACKGROUND
             Developer Mode currently provides quick access to
             testing tools. Developer Mode should support both
             instant access through predefined accounts and
             end-to-end testing through the real sign-up flow.

             DECISION
             Developer Mode shall provide two separate testing
             methods: Test Accounts and Test Sign-Up. These serve
             different purposes and should remain independent.

             TEST ACCOUNTS
             Seekers: Male–Basic, Female–Basic, Male–One,
             Female–One. Guardians: Male–Basic, Female–Basic,
             Male–One, Female–One. Selecting an account
             immediately logs the developer in with realistic
             demo data and correct permissions/navigation/
             restrictions for that type.

             TEST SIGN-UP
             A separate Developer Mode option launching the real
             onboarding flow used by actual users — not a
             simulation. Uses real validation, required fields,
             error messages, input checking, navigation, progress
             tracking, conditional questions, and account creation
             flow throughout, so developers can verify all of the
             above plus success states.

             PAYMENT
             If a One account is selected during Test Sign-Up,
             show the normal payment step, then provide a
             developer bypass option — to verify the payment flow
             appears correctly while still allowing efficient
             development.

             IMPLEMENTATION NOTES
             Review existing repository documentation relating to
             Authentication, Developer Mode, Account Types,
             Onboarding, Premium subscriptions, and Payment flow
             before implementing. Do not duplicate existing
             functionality. If any conflicts or unresolved
             specifications are found, pause and raise them.

             EXPECTED RESULT
             Developer Mode provides two powerful testing
             workflows: Test Accounts (8 predefined account
             combinations) and Test Sign-Up (full real onboarding
             journey with developer payment bypass where
             appropriate).

             --- Source document ends ---

Notes:       Filed same-day. See APP/Developer Mode/Script/
             Script_V2.md for the filed content, including the
             Guardian-side coverage gap and payment-integration caveat
             found during filing.

------------------------------------------------------------

OA-ZYRA-140
Title:       DR-ZYRA-101 Repository Audit — Findings Requiring
             Founder Decision
Category:    Governance / Cross-Cutting
Priority:    Mixed (see items)
Status:      RESOLVED 2026-07-25 — all 15 items walked through
             individually with the Founder and closed (items
             1/2 documentation fixes; 3/4/5/6/7 built for real,
             "rEAL FULL V1 NOW" — Pre-Journey Ritual, Pause/
             Resume, End Journey, One-Active-Journey enforcement,
             doc reconciliation; 8/9/11/14/15 documentation
             corrections; 12/13 formal ratifications, DR-ZYRA-102
             logged for item 13).
Owner:       Founder (Shakeel)
Raised:      2026-07-25
Source:      Full repository-vs-code audit run under DR-ZYRA-101
             ("review all the files for app building and
             update/change/add anything needed"), six parallel
             sweeps across Branding/Theme, Auth/Onboarding,
             Browse/Matching/Navigation, Matches/Journey/
             Messaging, Profiles/Guardian/Standards, and Premium/
             Developer Mode/remaining areas.

Description: The straightforward findings (stale status notes,
             terminology sweep-misses, one confirmed-wrong claim)
             were fixed directly as documentation corrections —
             see the corrected files themselves for detail. The
             items below are genuine product/architecture
             decisions, not documentation accuracy fixes, and are
             listed here rather than resolved unilaterally, per
             DR-ZYRA-101's "raise scope, don't assume it" clause.

             1. RESOLVED 2026-07-25 — Founder decision: "switch to
                gradient." `main.dart` now applies
                `ZyraColors.brandGradient` app-wide via a wrapper
                in `builder:` (neutral, not gender-matched — this
                layer is reached before gender is known);
                `auth_gate.dart`'s splash state does the same, same
                reasoning; `browse_screen.dart`'s fallback now uses
                `ZyraColors.genderGradient(AppState.instance.gender)`
                since Browse is only ever reached by a signed-in,
                gender-known Seeker, consistent with every other
                profile-context screen fixed under DR-ZYRA-101.

             2. RESOLVED 2026-07-25 — Founder decision: keep code's
                larger sizes. `Onboarding Rules & UX.md §TYPOGRAPHY`
                rewritten to match `zyra_text.dart` exactly; the
                unbuilt "Progress %" style removed from spec (the
                counter it would apply to no longer exists per
                OA-ZYRA-125 §5) rather than left as a phantom
                requirement.

             3. RESOLVED 2026-07-25 — Founder decision: "build all
                three now" (full v1 scope, "rEAL FULL V1 NOW").
                Pause/Resume Journey built for real: `suspend_
                journey`/`resume_journey`/`end_journey` Postgres
                RPCs (migration `20260725183724_pre_journey_ritual_
                tables`), `ZyraJourneyService.suspendJourney/
                resumeJourney/endJourney`, and UI in
                `matches_screen.dart` (Suspended Journeys section)
                and `journey_flow_screen.dart` (Pause/End app bar
                actions). Suspension gated on ZYRA One
                (`seeker_premium`) server-side; Auto-End handled
                (see item 7's note for detail).

             4. RESOLVED 2026-07-25 — same Founder decision. The
                Pre-Journey Ritual is built for real in
                `journey_flow_screen.dart`: Compatibility Reveal,
                Salam Exchange, Guardian Gate, Phases 1-3 (fixed-order
                questions per `journey_questions.dart`, private
                ratings, Continue/End checkpoint), and Family Stage
                (Guardian->Seeker direction only — see the file's own
                header comment for the full, deliberate v1-scope
                list: no AI-adaptive questions, no push
                notifications, no 30-day auto-end timer, no
                Guardian-side answering UI). The old stand-in
                confirmation dialog in `matches_screen.dart:
                _startJourney` now calls the real `promote_journey_
                to_active` RPC instead of just navigating straight
                to Chat.

             5. RESOLVED 2026-07-25 — enforced server-side as part
                of the same build. `promote_journey_to_active` RPC
                raises `one_active_journey_limit` if the caller
                already holds an Active Journey; `MatchesScreen._
                promote` catches this and shows a blocking message
                rather than starting a second Active Journey. The
                old client-side `AppState.startJourney` (no guard)
                was deleted entirely as part of this fix, not left
                alongside the new path.

             6. RESOLVED 2026-07-25 — same Founder decision. End
                Journey is built: `end_journey` RPC, `ZyraJourney
                Service.endJourney`, wired into `journey_flow_
                screen.dart`'s app bar with a confirmation dialog.
                The 24-hour cooling period from JOURNEY
                AVAILABILITY is not implemented — no code enforces
                a wait before a new Journey can start with the same
                or another person; flagged as a real gap, not
                silently assumed done.

             7. RESOLVED 2026-07-25 — Founder decision confirmed
                SUSPENSION as the governing document.
                `JOURNEY MANAGEMENT/Summary.md`'s Pause section
                rewritten to cite `JOURNEY_SUSPENSION_CURRENT_
                VERSION_V1.md` directly and point at the real
                implementation; the redundant "STEP BACK / HOLD"
                naming proposal removed rather than left dangling
                alongside a now-built feature.

             8. Direct contradiction: Premium/Profile Unlocks
                `References.md` states "Guardian Account — Can
                purchase and view unlocks... shares unlock with
                connected Seeker." `Summary.md` and
                `Flow Diagram.md` both say "Guardian cannot purchase or
                use Profile Unlocks — Seeker only."
                `References.md` also still uses pre-2026-07-12
                Basic/Pro/Premium terminology and 8 compatibility
                categories vs. Summary.md's corrected 6 — missed
                in that terminology pass. Which rule is correct:
                can a Guardian purchase Profile Unlocks or not?

             9. Direct contradiction: Chapter 3/4 question
                structure. `SEEKER ONBOARDING QUESTIONS/Summary.md`
                and `Flow Diagram.md` (both dated 2026-06-28)
                describe ~69 questions across a 10-category (5
                Core + 5 Extended) structure. `Chapter 3
                Classification — Ch4 Mapping.md` (same date,
                marked "V3 APPROVED") specifies 174 questions
                across 9 differently-named categories. Live code
                (`chapter3_categories.dart`, 105+ question
                literals, category names matching the
                Classification doc) implements the Classification
                doc's structure, not Summary/Flow Diagram's. Is
                Classification the authoritative version — should
                Summary.md and Flow Diagram.md be rewritten to
                match it?

             10. RESOLVED 2026-07-25 — Founder decision: "add it
                 now." Touchpoint 2 dependency notice built into
                 `upgrade_screen.dart` (`_WaliDependencyNotice`),
                 shown immediately before the purchase button
                 while the user isn't yet on ZYRA One, using the
                 Transparency Standard's own example wording
                 verbatim ("Before you subscribe... unlocks
                 automatically").

             11. RESOLVED 2026-07-25 — Founder decision: "rename
                 doc folder to 'iOS Widgets'." `APP/WIDGETS/`
                 renamed to `APP/iOS Widgets/` (content unchanged);
                 the folder's own Summary.md header updated to
                 note the rename and its reason. `ZYRA_
                 DOCUMENTATION_INDEX_V1.md`'s table entry updated
                 to the new path. `SOURCE/lib/widgets/` (the
                 Flutter shared-component library) still has no
                 documentation of its own — not addressed here,
                 as it wasn't part of the decision asked.

             12. RESOLVED 2026-07-25 — Founder decision: "ratify
                 as-is." DR-ZYRA-079 (Compatibility Scoring v1)
                 and DR-ZYRA-084 (its live wiring into Browse) both
                 formally ratified — bundled together since
                 ratifying only the algorithm and not its wiring
                 would leave the same "unratified draft governing
                 real behaviour" contradiction one level down. No
                 code changed; the running behaviour is unchanged,
                 only its ratification status.

             13. RESOLVED 2026-07-25 — Founder decision:
                 "Google/Apple-only is correct." Logged as
                 DR-ZYRA-102 (formal ratification of the pivot);
                 OA-102 rewritten to match live scope.

             14. RESOLVED 2026-07-25 — Founder decision: "Ratify
                 'ZYRA' now." APP NAME CREATION/Summary.md's
                 Approval Status and to-do list updated to reflect
                 formal approval.

             15. RESOLVED 2026-07-25 — Founder decision: "Yes,
                 rewrite it now." BUSINESS/ZYRA TERMINOLOGY/
                 Summary.md — the canonical glossary — fully
                 rewritten: "TERM: Decline" → "TERM: Pass",
                 "TERM: Like" → "TERM: Consider", plus every
                 other Decline/Like reference in the same document
                 (Related Systems lists, Decision Permissions,
                 Discovery Relationships, Decision Relationships).
                 Companion References.md also updated to match,
                 preserving the historical note about the earlier
                 retired Decline/Review/Consider (pre-2026-07-12)
                 model.

Target:      ACHIEVED — all 15 items resolved 2026-07-25.
Dependencies: DR-ZYRA-101, DR-ZYRA-094, DR-ZYRA-099, DR-ZYRA-079,
             DR-ZYRA-084, DR-ZYRA-088, DR-ZYRA-102, OA-102.
Automation:  None — resolved directly with the Founder.

------------------------------------------------------------

OA-ZYRA-141
Title:       Legacy parallel root folders — DEVELOPMENT_TEAM/ and
             LIVE_OPERATIONS/ duplicate SYSTEM/ structures
Category:    Repository
Priority:    Low — flagged, not blocking
Status:      RESOLVED (2026-07-26, #26) — see Resolution note below
Owner:       Founder (Shakeel)
Raised:      2026-07-25
Completed:   2026-07-26
Source:      Discovered while generating SYSTEM/DOCUMENTS/
             TREEVIEW.md (DR-ZYRA-103) — a literal directory
             listing surfaced two repo-root folders that were not
             previously documented anywhere.

Description: `DEVELOPMENT_TEAM/` and `LIVE_OPERATIONS/` sit at
             repo root alongside `SYSTEM/`. Both contain their own
             agent contracts, logs, and registers that overlap in
             purpose with `SYSTEM/AGENTS/`, `SYSTEM/LOGS/`, and
             `SYSTEM/OUTSTANDING_ACTIONS/`:
               DEVELOPMENT_TEAM/AGENTS/ — 8 agent contracts
                 (Architect, Code, Deployment, Documentation,
                 Impact Analysis, Product Manager, QA, Review)
               DEVELOPMENT_TEAM/LOGS/OPERATIONAL_LOG_2026-06.md
               LIVE_OPERATIONS/ — its own governance, index,
                 incident/release registers, monitoring checks
             Neither folder is referenced from
             ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V2.md or any
             governing SYSTEM/ document found so far.

             Not resolved here because the right answer isn't
             obvious without Founder input: this could be (a) a
             genuinely separate, intentional structure (e.g. a
             different AI-organisation model tried earlier and
             not yet retired), (b) dead scaffolding from an
             earlier structural iteration that should be archived,
             or (c) content that should be consolidated into
             SYSTEM/ properly. Consolidating or deleting either
             folder without knowing which of these is true risks
             losing real content or real intent.

Target:      Founder decision: consolidate into SYSTEM/, formally
             retire and archive, or confirm both serve a distinct
             ongoing purpose and document that purpose.
Dependencies: DR-ZYRA-103, SYSTEM/DOCUMENTS/TREEVIEW.md.
Automation:  None — awaiting Founder review.

Resolution (2026-07-26, #26): Founder confirmed option (b) — dead
             scaffolding from an earlier structural iteration, not a
             distinct ongoing purpose. Every file in both folders
             carried the same 2026-06-26 timestamp and neither was
             touched again after that single session, while SYSTEM/
             has been in continuous daily use since — consistent with
             a tried-once, not-adopted "autonomous AI team" structure.
             Both folders moved to `ARCHIVE/DEVELOPMENT_TEAM_2026-06-26/`
             and `ARCHIVE/LIVE_OPERATIONS_2026-06-26/` (archived, not
             deleted, in case any agent contract or runbook content is
             worth mining later). See ARCHIVE/README.md for the full
             note. Repo root now contains only APP/, ARCHIVE/,
             BUSINESS/, REPORTS/, SOURCE/, SYSTEM/.

------------------------------------------------------------

OA-ZYRA-142
Title:       Build Entitlement-vs-Participation Messaging (DR-ZYRA-111)
Category:    Product / UX
Priority:    Medium
Status:      Open
Owner:       Founder (Shakeel)
Raised:      2026-07-26
Completed:   —
Source:      Founder follow-up question on DR-ZYRA-105, ratified as
             DR-ZYRA-111 the same day.

Description: DR-ZYRA-111 ratifies the rule; this OA tracks the
             actual build. Two concrete pieces of work, not one:

             1. Seeker side — surface the ZYRA One Seeker's bundled
                Guardian+ entitlement somewhere reachable (most
                naturally profile_screen.dart, near the plan badge or
                Connections section), stating plainly whether it's
                been assigned to a linked Guardian or is still unassigned
                because no Guardian is linked yet. Do NOT alter
                _WaliGateView's own copy (journey_flow_screen.dart) —
                linking a Guardian is a baseline requirement for every
                Seeker regardless of tier; making that screen
                ZYRA-One-specific would misleadingly imply Basic-tier
                Seekers are exempt.

             2. Guardian side — wali_network_screen.dart's locked-state
                gate currently checks ONLY `hasWaliOne()`, so a Guardian
                who already owns Guardian+ but has zero linked Seekers
                sees an upsell to buy something they already own. Fix:
                split the gate into three real states — not entitled
                (show the existing purchase CTA), entitled but no
                linked Seeker (show "Your Guardian+ subscription is
                active — features activate once you're linked to a
                Seeker," with a CTA to Invite/Link, not to purchase),
                and entitled with a linked Seeker (current unlocked
                view). This is a real bug fix, not just a copy
                addition — the boolean gate can't currently represent
                the middle state at all.

Target:      Founder to prioritise against #20/#33 and the rest of
             the standing build list.
Dependencies: DR-ZYRA-111, DR-ZYRA-105, SOURCE/lib/screens/profile/
             profile_screen.dart, SOURCE/lib/screens/journey/
             journey_flow_screen.dart, SOURCE/lib/screens/guardian/
             wali_network_screen.dart.
Automation:  None — awaiting Founder go-ahead to build.

------------------------------------------------------------

OA-ZYRA-143
Title:       Build Report / Hide / Block Menu (DR-ZYRA-095, DR-ZYRA-112)
Category:    Product / Safety
Priority:    Medium
Status:      Open
Owner:       Founder (Shakeel)
Raised:      2026-07-26
Completed:   —
Source:      DR-ZYRA-095 (2026-07-25, Browse-stage baseline) +
             DR-ZYRA-112 (2026-07-26, cross-context standard
             resolving Block confirmation, Block-vs-End-Journey,
             per-stage contents).

Description: Both DRs are fully specified design, zero code — grepped
             `SOURCE/lib/` for Report/Block/Hide, zero hits. Build
             scope, per the ratified standard:

             1. Three-dot (⋮) affordance, top-right of every Browse
                card, opening Report Profile / Hide Profile / Block
                User / Cancel — per BROWSE_UX_SPEC_CURRENT_VERSION_
                V4.md §Profile Actions.
             2. Report flow: reason picker → optional detail → submit
                → moderation pipeline entry → confirmation.
             3. Block flow: confirmation dialog every time, wording
                varies by stage (plain "you won't be able to see or
                contact each other again" pre-Journey; "...this will
                also end your Journey together" during Active
                Journey/Family Stage, per PROFILE_ACTIONS_MENU_
                STANDARD_CURRENT_VERSION_V1.md's resolved gap 2).
             4. Menu contents gated per relationship stage per that
                standard's table — NOT a single fixed menu everywhere.
             5. Hide flow: silent, no confirmation, removes from
                future Browse recommendations only.

             Not in scope: Guardian-facing block/report (still entirely
             unspecified — separate future design item, per JOURNEY
             MANAGEMENT/Summary.md).

Target:      Founder to prioritise against #20/#33/OA-ZYRA-142 and
             the rest of the standing build list.
Dependencies: DR-ZYRA-095, DR-ZYRA-112, APP/Browse/BROWSE_UX_SPEC_
             CURRENT_VERSION_V4.md, APP/Standards/
             PROFILE_ACTIONS_MENU_STANDARD_CURRENT_VERSION_V1.md,
             SOURCE/lib/screens/browse/browse_screen.dart,
             SOURCE/lib/screens/journey/journey_flow_screen.dart
             (_JourneyAppBar, for the Block-forces-End-Journey wiring).
Automation:  None — awaiting Founder go-ahead to build.

------------------------------------------------------------

OA-ZYRA-144
Title:       Co-Termed Billing — Parked Pending Platform Verification
             (DR-ZYRA-118)
Category:    Product / Billing
Priority:    Low
Status:      Parked — not rejected. Reopen only once all conditions
             below are met.
Owner:       Founder (Shakeel)
Raised:      2026-07-27
Completed:   —
Source:      Founder's "Response to Round 3" on the multi-role-
             accounts / subscription discussion thread, ratified as
             DR-ZYRA-118.

Description: Proposal: align multiple subscriptions held under one
             identity to a single renewal date via proration (e.g.
             existing subscription renews on the 31st; a second
             subscription bought on the 15th is charged a pro-rated
             amount for the 15th-31st, then both renew together on
             the 31st thereafter).

             Parked because it reopens DR-075 (2026-07-12), which
             explicitly retired per-Guardian-relationship billing and
             family/multi-account billing — "may be reconsidered in a
             future version if genuine demand exists" — and because
             platform capability is not yet confirmed first-hand.
             WebSearch at review time found no Apple mechanism for
             merging independently-purchased subscriptions' renewal
             dates; Google Play's "Subscriptions with Add-ons" does
             support this, with constraints (same billing period,
             base/add-on product modelling); Stripe supports it
             natively. That research was secondhand (documentation
             search), not a direct platform confirmation.

             Founder's exact reopening conditions, verbatim: "Let's
             leave co-termed billing as a future discussion until
             we've confirmed: Platform capabilities. RevenueCat
             support. Apple and Google billing limitations. Whether
             there is sufficient real-world demand to justify
             revisiting DR-075."

Target:      Founder to confirm the four conditions above before this
             is reopened as a live decision. Not a build item — no
             real subscription backend exists yet (Task #20 blocked),
             so there is nothing to implement even if reopened today.
Dependencies: DR-075, DR-ZYRA-118, RevenueCat platform support,
             Apple/Google billing platform capabilities, Task #20.
Automation:  None — parked, awaiting Founder-confirmed conditions.

------------------------------------------------------------

OA-ZYRA-145
Title:       Build Surname Capture UI (Onboarding / Profile Settings)
Category:    Product / Onboarding
Priority:    Low
Status:      Open
Owner:       Founder (Shakeel)
Raised:      2026-07-27
Completed:   —
Source:      Founder's 3rd report that surnames "still aren't showing"
             on the Browse identity block.

Description: Root cause of the repeated report: Browse renders whatever
             ZyraDiscoveryService.fetchCandidates() returns, and once 26
             real seeded `profiles` rows existed (Amina, Noor, etc.),
             those — not SOURCE/lib/models/seeker_profile.dart's
             `mockProfiles` — were what actually rendered. Editing
             mockProfiles' surnames therefore never had a visible
             effect. Fixed this pass: added `profiles.surname_line`
             (migration add_surname_line_to_profiles) and backfilled
             all 26 seeded rows; zyra_discovery_service.dart now
             selects and passes it through.

             What's still missing, and what this OA tracks: no
             onboarding step or profile-settings screen lets a real NEW
             user enter their own surname — checked, confirmed no such
             field exists anywhere in SOURCE/lib/screens/onboarding/ or
             settings/. The column exists and is readable/writable;
             nothing currently writes to it except this one-time
             backfill of known seed accounts.

Target:      Founder to prioritise against #20/#33 and the rest of the
             standing build list. Low priority — cosmetic/display field,
             not blocking any relationship-state or safety behaviour.
Dependencies: SOURCE/lib/models/seeker_profile.dart (surnameLine),
             SOURCE/lib/services/zyra_discovery_service.dart, `profiles.
             surname_line` column, SOURCE/lib/screens/onboarding/,
             SOURCE/lib/screens/settings/ (likely destinations for the
             capture field).
Automation:  None — awaiting Founder go-ahead to build.

------------------------------------------------------------

OA-ZYRA-146
Title:       Build ZYRA Notification Specification Document
             (Full Event Taxonomy, Read/Unread UX, Categories,
             Priority, Retention, Safeguarding Edge Cases)
Category:    Product / Notifications
Priority:    Medium
Status:      Parked — deliberately, per Founder: to be resumed
             after the Active Journey / ZYRA One tiering
             discussion goes deeper, since that discussion may
             reshape the Journey-event portion of this scope
             (see Dependencies).
Owner:       Founder (Shakeel)
Raised:      2026-07-28
Completed:   —
Source:      Two linked discussion threads: "Discussion Proposal
             — Active Journey Limits & Upgrade Opportunities"
             (surfaced that JOURNEY_SUSPENSION_CURRENT_VERSION_
             V1.md §11 already names a "ZYRA Notification
             Specification (separate document — to be
             specified)" placeholder that has never been
             written) and the Founder's follow-up "Discussion
             Proposal — Notification System Review". Founder's
             instruction: "add the notification specification
             document as a oa and we will come back to that as
             we will discuss this zyra one active journey more
             deeper in depth."

Description: A full discussion-only review was already
             conducted (this thread) covering: complete
             notification event taxonomy across Matches/
             Journey/Guardian/Subscription/Security/Account/System;
             essential-vs-optional judgement per event (notably
             recommending AGAINST an instant per-Like
             notification, given ZYRA's own "engagement metrics
             are not the goal" philosophy — mainstream dating
             apps use exactly that mechanic to drive compulsive
             re-opening); read/unread UX (tap-to-navigate +
             auto-mark-read, closing the existing logged
             deep-link gap); single chronological feed with
             category filter chips plus pinned time-sensitive
             items, rather than full category tabs; a two-tier
             priority model (Standard / Time-Sensitive) reusing
             the app's existing traffic-light system rather than
             a new visual language; retention (no urgent gap —
             schema already cascade-deletes correctly, no
             time-based pruning policy exists but isn't urgent);
             and safeguarding edge cases (never identify a
             reporter to the reported party; never leak private
             Ritual answers/ratings — private-rating visibility
             per PRE-JOURNEY RITUAL/Summary.md's Privacy Model —
             into a notification body; label every Guardian-facing
             notification with which linked Seeker it concerns).

             Two prerequisite fixes were flagged as needing to
             land before the event list grows, independent of
             this OA's resolution: (1) the 3 existing Settings
             notification toggles are session-only (AppState)
             and do not actually gate server-side notification
             creation — already logged in APP/Notifications/
             SUMMARY.md; (2) tapping a notification marks it
             read but does not navigate to the related Journey/
             Match — also already logged there.

             This OA tracks turning the reviewed discussion into
             an actual CURRENT_VERSION document once resumed —
             not the discussion itself, which is already
             complete and available in this thread's history.

Target:      Founder to resume once the Active Journey / ZYRA
             One direction is settled enough that the Journey-
             stage-advancement and Family Review Period portions
             of the event list won't need re-deriving. Then:
             formalise into a proper Notification Specification
             document (resolving the placeholder named in
             JOURNEY_SUSPENSION_CURRENT_VERSION_V1.md §11), widen
             the `notifications` table's CHECK constraint and add
             category/priority columns, and build the new trigger
             functions for whichever events are approved.
Dependencies: JOURNEY_SUSPENSION_CURRENT_VERSION_V1.md §11 (the
             placeholder this resolves), the Active Journey/ZYRA
             One tiering discussion (sequencing — may reshape
             Journey-event scope), APP/Notifications/SUMMARY.md
             (current known gaps), SOURCE/supabase/migrations/
             20260726140000_notifications.sql (current schema),
             SOURCE/lib/services/zyra_notification_service.dart,
             SOURCE/lib/screens/notifications/notifications_
             screen.dart.
Automation:  None — awaiting Founder to resume this discussion.

------------------------------------------------------------

OA-ZYRA-147
Title:       Build Monthly Profile Unlock+ Credit Allowance
             (ZYRA One)
Category:    Product / Premium / Monetisation
Priority:    Medium
Status:      Open — approved direction, not designed or built
Owner:       Founder (Shakeel)
Raised:      2026-07-28
Completed:   —
Source:      DR-ZYRA-119 ("Premium Differentiation — Current
             Direction"), Decision item 4.

Description: Approved direction: ZYRA One accounts receive 3
             Profile Unlock+ credits included each calendar month
             at no extra cost; ZYRA Basic receives 0 included.
             Additional credits remain separately purchasable by
             either plan at existing pricing (Profile Unlock
             £0.99/1, £2.99/5; Profile Unlock+ £1.99/1, £4.99/5 —
             APP/Premium/Profile Unlocks/Summary.md). Included
             credits reset each billing cycle and do not roll
             over.

             Not yet designed in detail: how the 3-credit balance
             is tracked/decremented alongside purchased credits
             (single pooled balance vs. separate included/
             purchased counters — matters for the "does not roll
             over" rule, since purchased credits' own expiry
             policy is itself still an open question per Profile
             Unlocks/Summary.md's own to-do list), and how this
             interacts with mid-cycle upgrade/downgrade (see
             SUBSCRIPTION_CONTINUITY_PRINCIPLE_CURRENT_VERSION_
             V1.md — capabilities change, relationships/history
             don't; an included-credit balance is arguably closer
             to a capability than owned data, but this hasn't been
             explicitly decided).

Target:      Founder's stated intent: formalise fully during a
             dedicated subscription-system review (real billing
             backend is Task #20, blocked on payment processing
             credentials) — not to be built ahead of that review.
Dependencies: APP/Premium/Profile Unlocks/Summary.md (existing
             a-la-carte pricing/rules this extends), Task #20
             (real subscription backend), SUBSCRIPTION_CONTINUITY_
             PRINCIPLE_CURRENT_VERSION_V1.md (upgrade/downgrade
             behaviour).
Automation:  None — awaiting the dedicated subscription review.

------------------------------------------------------------

OA-ZYRA-148
Title:       Design & Build Family Conversation Guide (ZYRA One)
Category:    Product / Premium / Family Stage
Priority:    Medium
Status:      Open — approved direction only, no design work done
Owner:       Founder (Shakeel)
Raised:      2026-07-28
Completed:   —
Source:      DR-ZYRA-119 ("Premium Differentiation — Current
             Direction"), Decision item 4.

Description: Approved direction: a ZYRA One capability that
             helps a Seeker prepare their own family for Family
             Compatibility Stage conversations — e.g. suggested
             questions or talking points for the family to raise,
             tailored to what's already been established in the
             Journey so far. Distinct from the existing Guardian+
             "Guardian AI Summary" (Journey Capability Grant Rules
             V4 / AI Tiering V1), which is delivered TO the Guardian
             about the couple's alignment — this would be a
             Seeker-facing prep tool, aimed at the Seeker's family
             generally, not just their linked Guardian.

             Rated during discussion as the strongest fit against
             ZYRA's own stated differentiator (family involvement)
             of any candidate considered, since it deepens that
             mechanic rather than substituting for it. No design
             work exists yet: unclear how it's surfaced in the
             Family Compatibility Stage flow (PRE-JOURNEY RITUAL/
             Summary.md), what it draws on (Phase 1-3 answers?
             Guardian AI Summary content?), or how it fits AI TIERING
             CURRENT_VERSION_V1.md's "System intelligence vs ZYRA
             intelligence" test.

Target:      Founder has asked to hold all AI-adjacent
             differentiation (this includes an AI-generated
             guide) for a dedicated end-of-build AI discussion —
             see OA-ZYRA-149. Do not design or build in isolation
             before that discussion, even though this OA is
             logged separately from it.
Dependencies: OA-ZYRA-149 (the dedicated AI discussion this should
             likely be folded into or sequenced after),
             APP/Premium/AI TIERING/TIERING_CURRENT_VERSION_V1.md,
             PRE-JOURNEY RITUAL/Summary.md (Family Compatibility
             Stage), WALI_ARCHITECTURE_CURRENT_VERSION_V6.md
             (Guardian AI Summary — the adjacent, already-approved
             feature this must stay distinct from).
Automation:  None — awaiting the dedicated AI discussion.

------------------------------------------------------------

OA-ZYRA-149
Title:       Dedicated Product Discussion — AI Differentiation
             (ZYRA Coach, ZYRA Insight, ZYRA Recommendation, AI
             Guidance Generally)
Category:    Product / Premium / AI
Priority:    Medium — deliberately deferred, not urgent
Status:      Parked — deliberately, per Founder instruction. Not
             to be actioned piecemeal.
Owner:       Founder (Shakeel)
Raised:      2026-07-28
Completed:   —
Source:      DR-ZYRA-119 ("Premium Differentiation — Current
             Direction"), Decision item 5.

Description: During the premium-differentiation discussion,
             several AI-guidance ideas came up (an always-
             available "ZYRA Coach" beyond fixed checkpoints,
             expanding existing ZYRA Insight/Recommendation/
             Summary depth per AI TIERING CURRENT_VERSION_V1.md).
             Founder explicitly declined to decide any of these
             now: AI is expected to become one of ZYRA's biggest
             differentiators, and the Founder does not want
             isolated AI decisions made while the rest of the
             platform is still evolving. Instead, a single,
             dedicated product discussion — covering how AI
             should fit naturally into the complete user journey —
             is wanted, timed closer to the end of the build, once
             that complete picture actually exists.

             This OA exists so the intent to have that discussion
             isn't lost across a long build, not to track any
             specific AI feature — the specific ideas raised this
             pass (ZYRA Coach, deeper Insights) are examples for
             that future discussion to reconsider fresh, not a
             pre-committed shortlist.
Target:      Founder to resume near the end of the build, once
             the complete user journey is well understood. Do not
             raise piecemeal AI-tiering questions before then
             unless one arises unavoidably while implementing an
             already-approved, non-AI feature.
Dependencies: APP/Premium/AI TIERING/TIERING_CURRENT_VERSION_V1.md
             (existing ratified AI philosophy this discussion
             would extend, not replace), OA-ZYRA-148 (Family
             Conversation Guide — likely folds into this
             discussion).
Automation:  None — deliberately parked.

------------------------------------------------------------

OA-ZYRA-150
Title:       Dedicated Product Discussions — Guardian-Unavailable
             Path (DR-G) and Published Outcomes Metric (DR-N)
Category:    Product / Safeguarding / Premium
Priority:    Medium — both raised as proposals, deliberately not
             resolved
Status:      Parked — deliberately, per Founder instruction. Not
             to be actioned piecemeal.
Owner:       Founder (Shakeel)
Raised:      2026-08-01
Completed:   —
Source:      DR-ZYRA-120 ("Muzz Teardown Cross-Review"), Decision
             item 4; originally proposed in MUZZ_TEARDOWN_
             CURRENT_VERSION_V1.md as DR-G and DR-N.

Description: Two proposals from the Muzz teardown need their own
             dedicated discussion rather than being folded into
             the wider cross-review:
             (a) Guardian-unavailable path — grace periods, a
             nominated alternate Guardian, and a stated auto-continue
             default when a Guardian doesn't respond. Flagged risk:
             any auto-continue-after-timeout mechanism is
             potentially gameable by a Seeker who wants to avoid
             genuine Guardian oversight (deliberately making their
             Guardian "unreachable" to trigger auto-continuation) —
             this needs to be designed against directly, not
             assumed away.
             (b) Publishing an outcomes metric (e.g. a Nikah/
             marriage-success rate) as a public differentiator.
             Flagged risk: this could create pressure to optimise
             the published number itself rather than the
             underlying unhurried, deliberate experience ZYRA is
             built around (a measurement/incentive concern, not a
             feasibility one).
Target:      Founder to schedule both as separate, dedicated
             discussions — treat with the same weight as the
             Active Journey tiering discussion (DR-ZYRA-119),
             not resolved in a single pass.
Dependencies: WALI_ARCHITECTURE_CURRENT_VERSION_V6.md (for DR-G),
             MUZZ_TEARDOWN_CURRENT_VERSION_V1.md §6 and §11.7
             (both proposals' original framing).
Automation:  None — awaiting dedicated Founder discussions.

------------------------------------------------------------

OA-ZYRA-151
Title:       Browse Interaction-Mechanic Review — Should the
             Swipe Layer Evolve, Separately from Candidate
             Selection
Category:    Product / UX
Priority:    Low — unscoped, no urgency stated
Status:      Parked — open question, not yet scoped
Owner:       Founder (Shakeel)
Raised:      2026-08-01
Completed:   —
Source:      DR-ZYRA-120 ("Muzz Teardown Cross-Review"), Decision
             item 6; originally raised via MUZZ_TEARDOWN_CURRENT_
             VERSION_V1.md §11.1's swipe-deck critique.

Description: The Muzz teardown argued ZYRA's Browse swipe deck is
             "legacy inherited from a competitor's 2012
             constraint." Cross-review found this conflates two
             separate questions: candidate selection (already
             values/Hard-Requirement-driven server-side via
             score_candidates(), DR-ZYRA-079 — candidates who fail
             a Hard Requirement are excluded, the rest silently
             ordered by compatibility score) versus the swipe
             interaction layer itself (gesture-based, three-way
             Consider/Save/Pass decision). Candidate selection is
             not in question. Whether the interaction layer
             should evolve (and into what) is a distinct, smaller,
             more tractable design question than replacing
             discovery entirely with curated introductions.
Target:      No timeline — logged so the narrower question isn't
             lost, not to prompt near-term redesign work. Revisit
             only if raised again or if it naturally comes up
             while touching Browse for another reason.
Dependencies: SOURCE/lib/screens/browse/browse_screen.dart,
             SOURCE/lib/services/zyra_discovery_service.dart,
             DR-ZYRA-079 (compatibility scoring).
Automation:  None.

------------------------------------------------------------

OA-ZYRA-152
Title:       Profile Unlock+ Conflicts With "Compatibility % Hidden
             Until Active Journey" — Needs Resolution Before Build
Category:    Product / Premium / Privacy-Values
Priority:    High — blocks Profile Unlock+ from being built as
             currently spec'd
Status:      RESOLVED 2026-08-10 by DR-ZYRA-135. Founder decided
             Profile Unlock+ DOES show the percentage before the
             other Seeker reveals. Build unblocked; see DR-ZYRA-135
             for the three consequences that come with it, the first
             of which (a third state on the Reveal screen) must ship
             with it, not after.
Owner:       Founder (Shakeel)
Raised:      2026-08-01
Completed:   —
Source:      DR-ZYRA-120 cross-review follow-up (Claude/Opus's
             proposed fifth DR-I test — "a purchase may not sell
             relief from a restriction ZYRA imposes for stated
             principled reasons"), verified by Claude/Sonnet
             against the actual specifications.

Description: APP/Premium/Profile Unlocks/Summary.md specifies
             Profile Unlock (£0.99) as displaying "Overall
             Compatibility %" (e.g. "Overall Compatibility: 81%")
             the moment a profile has been Saved or Considered —
             well before any Active Journey exists. This directly
             contradicts BROWSE_UX_SPEC_CURRENT_VERSION_V1.md /
             MATCH_UX_SPEC_CURRENT_VERSION_V1.md, both of which
             state Compatibility % is "not shown anywhere until
             Active Journey begins" (anti-gamification principle,
             also reflected in zyra_discovery_service.dart's own
             code comments). DR-ZYRA-120 (Decision item 2)
             confirmed Profile Unlock+ against a four-part
             consumable test and called it compliant; it was not
             checked against this fifth angle, and on that angle
             it fails. Two resolution paths, neither chosen yet:
             (a) redesign Profile Unlock/Unlock+ to stop short of
             the literal compatibility %, e.g. Green/Yellow/Red
             counts only, no headline percentage; (b) revisit or
             relax the "hidden until Active Journey" rule itself.
Target:      Founder to resolve before Profile Unlock+ is designed
             or built in any form. DR-ZYRA-120 should get a
             follow-up entry recording whichever path is chosen,
             once chosen — not edited retroactively.
Dependencies: APP/Premium/Profile Unlocks/Summary.md, BROWSE_UX_
             SPEC_CURRENT_VERSION_V1.md, MATCH_UX_SPEC_CURRENT_
             VERSION_V1.md, DR-ZYRA-119, DR-ZYRA-120.
Automation:  None — awaiting Founder decision.

------------------------------------------------------------

OA-ZYRA-153
Title:       Compatibility-Based Browse Curation Does Not Execute
             in Production — onboarding_answers Empty
Category:    Engineering / Data
Priority:    Medium — blocks nothing today (no real Seekers
             browsing yet), but must be closed before Browse
             curation can be relied on as a working capability
Status:      Open — pending real onboarding_answers data and
             re-verification
Owner:       Founder (Shakeel)
Raised:      2026-08-01
Completed:   —
Source:      DR-ZYRA-120 cross-review follow-up (Claude/Opus's
             §11.1 runtime check), verified live by Claude/Sonnet.

Description: score_candidates() (DR-ZYRA-079/084, ratified
             2026-07-25) excludes Hard-Requirement failures and
             orders remaining candidates by compatibility score —
             but only when the calling user has ch4_preferences
             recorded in onboarding_answers. Verified live
             2026-08-01: onboarding_answers has zero rows. Every
             call therefore takes the function's own "no Ch4
             preferences recorded yet" branch and returns a flat
             score of 50.0 for every candidate, with no exclusion
             and no real ordering. Combined with the existing
             engineering-audit finding C3 (profile_complete never
             written, so no real Seeker enters the Browse deck at
             all), the compatibility-based curation this session
             has repeatedly cited as "already solved" is real,
             correctly-written code that has never once executed
             against real data in production. Not a bug to fix —
             there is no real onboarding data yet for it to act
             on — but a fact that should stop anyone (including
             Claude) from treating Browse curation as a settled,
             working capability until it's re-verified against
             real users.
Target:      Re-verify once real Seekers have completed onboarding
             and populated onboarding_answers. No action needed
             until then.
Dependencies: SOURCE/supabase/migrations/20260726120200_
             compatibility_scoring_security_definer.sql, SOURCE/
             lib/services/zyra_discovery_service.dart, DR-ZYRA-079,
             DR-ZYRA-084 (engineering audit finding C3).
Automation:  None.

------------------------------------------------------------

OA-ZYRA-166
Title:       Upgrade Screen À-La-Carte Pricing and Product Names
             Reflect Superseded Spec V3
Category:    Product / Commercial
Priority:    High — must be closed before paid tiers launch. No
             revenue impact today: no payment processing exists
Status:      Open — blocked on Founder commercial decision
Owner:       Founder (Shakeel)
Raised:      2026-08-08
Completed:   —
Source:      DANGLING DOC REF check (SOURCE/tools/zyra_check.py),
             first production run

Description: upgrade_screen.dart renders an à-la-carte table
             transcribed from ZYRA_PRODUCT_SPEC V3. The approved
             spec is now V5. All four rows are superseded — both
             products were renamed and every price raised:
             Unlock Profile 1/£0.99 -> Compatibility Unlock
             1/£1.99; Unlock Profile 5/£2.99 -> Compatibility
             Unlock 5/£7.99; Unlock Profile Plus 1/£1.99 ->
             Compatibility Unlock Plus 1/£2.99; Unlock Profile
             Plus 5/£4.99 -> Compatibility Unlock Plus 5/£9.99.
             The screen under-quotes the approved spec by £1-£5
             per item. ZYRA One is unaffected — £34.99 / month
             and £349.90 / year are identical in V3 and V5. A
             related rename is also unpropagated: the £9.99 /
             month Guardian add-on is "Extended Guardian" in V3
             and "Guardian+" in V5; other occurrences of that
             string have not been searched.

             Found because the file header cited
             ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V3.md — a filename
             the archive rule had already renamed out of
             existence. The header asserted the figures were
             "transcribed verbatim ... nothing on this screen is
             invented". That was true when written and became
             unverifiable at the moment the file was renamed: no
             reviewer could open the cited document to see the
             numbers had moved. This is the concrete cost of
             Naming Conventions rule 5.

             Prices deliberately NOT changed. Commercial pricing
             is a Founder decision, not an engineering one. The
             source file now carries a "STALE" header naming the
             discrepancy so it cannot be read as verbatim again.
Target:      Founder to confirm whether V5 pricing is the
             commercial decision — in which case the UI is
             updated to match — or whether the spec should be
             revised back toward V3. Implementation blocked
             until that is settled.
Dependencies: SOURCE/lib/screens/subscription/upgrade_screen.dart;
             ZYRA_PRODUCT_SPEC §4-8 (V3 vs V5);
             ZYRA_PRICING_DRIFT_FINDING_2026-08-08.md;
             NAMING_CONVENTIONS rule 5.
Automation:  Detected by SOURCE/tools/zyra_check.py (DANGLING DOC
             REF). Note the limit: the check catches the broken
             reference, not the price drift. No automated guard
             exists for UI figures diverging from spec figures —
             this was found by a human following the reference
             the check exposed.

------------------------------------------------------------

OA-ZYRA-167
Title:       advanceStage() Was a Silent No-Op — Journey Ritual
             Transitions Did Not Persist
Category:    Engineering / Data Integrity
Priority:    RELEASE BLOCKER — Founder-designated 2026-08-07
Status:      Actioned 2026-08-08 — resolved by the
             zyra_advance_stage() RPC. Registered retrospectively;
             see Correction below
Owner:       Founder (Shakeel)
Raised:      2026-08-07 (registered 2026-08-08, already fixed)
Completed:   2026-08-08
Source:      Founder directive during the write-path security
             review: "I'd like it recorded as a release blocker"

Description: THE DEFECT (now fixed). ZyraJourneyService.
             advanceStage() issued two direct table UPDATEs
             wrapped in "catch (_) {}". Neither did anything, and
             the two failed for DIFFERENT reasons — which is why
             it survived roughly a month:

             1. UPDATE matches SET journey_stage — 'authenticated'
                holds no UPDATE grant on public.matches (grants
                are REFERENCES, TRIGGER only, after the
                close_direct_write_paths migration). Postgres
                raised 42501 permission denied. The bare catch
                swallowed it.
             2. UPDATE conversations SET status='active' — the
                grant DOES exist here, so the grant check passed.
                RLS is on with zero UPDATE policies, so the
                statement matched no rows and returned success.
                0 rows affected, no error raised, nothing to
                catch.

             Effect while live: the single-action ritual steps
             (compatibility_reveal -> salam_exchange -> wali_gate
             -> phase_1) never persisted. The UI advanced locally
             and the database did not follow. The four Family-
             Review-gated transitions were never affected — those
             route through open_family_review() and other
             SECURITY DEFINER functions.

             THE FIX (applied 2026-08-08, migrations
             20260808101646_journey_stage_checkpoints.sql and
             20260808101800_zyra_advance_stage_rpc.sql). A
             SECURITY DEFINER RPC, zyra_advance_stage(p_match_id,
             p_from_stage), returning (advanced, stage, reason).
             It authenticates the caller, locks the match row FOR
             UPDATE, verifies the caller is a party, rejects
             inactive/paused/moved-on Journeys, permits exactly
             the three ungated transitions, and RAISES
             'gated_transition' on the four Family-Review ones.
             Per-stage preconditions are enforced server-side:
             both Seekers revealed and both continued
             (compatibility_reveal), both salaams exchanged
             (salam_exchange), both Seekers holding an active
             Main Guardian (wali_gate). EXECUTE granted to
             'authenticated', denied to 'anon' — verified.

             Client rewritten to match: advanceStage() now returns
             ZyraStageAdvance(advanced, stage, reason) and logs on
             failure. The bare catch at this call site is gone.
             No Dart code writes to public.matches any more —
             verified, zero direct update/insert/delete calls.

Correction:  This entry was first written on 2026-08-08 as OPEN,
             describing the pre-fix code as current and claiming
             it was "verified against the live database". The
             grant and policy findings were verified and are
             accurate. The claim that advanceStage() still issued
             those UPDATEs was NOT — the fix had already been
             applied earlier the same day, at 10:16 and 10:18.
             The error: a stale read of the Dart file was trusted,
             and no check was made for an existing RPC despite a
             live database connection being open at the time.
             Invariant I5 — a match tells you a string is present,
             not what it means — applies to reading source as much
             as to grep. Corrected within the hour, before any
             work was scheduled against it.
Target:      None. Closed.
Dependencies: SOURCE/supabase/migrations/20260808101800_zyra_
             advance_stage_rpc.sql; SOURCE/lib/services/zyra_
             journey_service.dart; SOURCE/lib/screens/journey/
             journey_flow_screen.dart; ZYRA_ENGINEERING_INVARIANTS
             I4 (enforcement moved to the unskippable layer). See
             also OA-ZYRA-168 (conversations grants) and
             OA-ZYRA-169 (remaining silent catch blocks), both
             discovered here but deliberately out of scope —
             Founder decision 2026-08-08, invariant I7.
Automation:  None. No check detects a write that silently affects
             zero rows; tools/zyra_check.py does not, and was not
             extended to — invariant I7.

------------------------------------------------------------

OA-ZYRA-168
Title:       Write Grants to 'authenticated' Without Matching RLS
             Policies — 22 Tables
Category:    Security / Hardening
Priority:    Medium — nothing is exploitable today. RLS denies
             where no policy exists, so every one of these is
             currently inert
Status:      Actioned 2026-08-08 — Stages 1-3 applied and
             verified (migration oa168_grant_sweep_stages_1_to_3).
             Stage 4 carried to OA-ZYRA-170
Owner:       Founder (Shakeel)
Raised:      2026-08-08
Completed:   2026-08-08
Source:      Founder decision 2026-08-08 to scope the
             public.conversations grant separately from
             OA-ZYRA-167 (invariant I7)

Description: Raised as a single observation about public.
             conversations. Measuring it showed conversations is
             one of 22 tables, not a special case.

             22 public tables grant INSERT, UPDATE or DELETE to
             'authenticated' with no permissive policy for that
             command. All 22 have RLS enabled, so all are denied
             today. Six carry all three unmatched: app_feedback,
             conversations, journey_family_reviews, journey_
             family_review_responses, timelines, timeline_
             milestones. The rest carry one or two, most commonly
             DELETE.

             Only the absence of a policy is holding the line.
             Adding a permissive policy to any of these tables for
             an unrelated reason silently activates the standing
             grant — the I4 shape: a rule holding at a layer that
             was not chosen deliberately.

             Live write paths checked, 2026-08-08: none of the 22
             unmatched grants is exercised by client code. Every
             Dart reference to these tables is a SELECT, except
             notifications.update (which has a matching UPDATE
             policy and works) and app_feedback (written via the
             zyra_submit_feedback RPC, not directly — the feedback
             feature is unaffected). This is hardening, not a bug
             fix. The one live write path that WAS broken by this
             pattern is OA-ZYRA-167, now closed.
Outcome:     Founder approved Stages 1-3 together on 2026-08-08;
             Stage 4 kept separate. Applied and verified same
             day:

             Stage 1 — 75 anon write grants revoked. anon now
                       holds ZERO write privileges anywhere in
                       public.
             Stage 2 — 46 unmatched authenticated write grants
                       revoked. The 29 MATCHED grants are
                       untouched and verified still present
                       (likes/messages INSERT, profile_photos
                       UPDATE, wali_invites UPDATE, notifications
                       UPDATE, onboarding_answers INSERT,
                       seeker_details UPDATE, and others).
             Stage 3 — default privileges for role postgres in
                       schema public changed from anon/
                       authenticated = arwdxtm to rxtm. New
                       tables now arrive with SELECT but no
                       write grants.

             Unchanged as required: 65 policies, 148 service_role
             grants, zyra_advance_stage still executable by
             authenticated.

             NEGATIVE TEST (the point of the exercise): as anon,
             INSERT into public.likes now fails with 42501
             "permission denied for table likes" — refused at the
             GRANT layer, before RLS is consulted. Previously the
             grant existed and only the policy stopped it. The
             protection is now two layers, not one.

             KNOWN GAP: the supabase_admin default ACL could not
             be altered (postgres lacks the privilege) and still
             reads arwdDxtm. Tables created BY supabase_admin in
             public would still inherit write grants. ZYRA
             migrations run as postgres, so Stage 3a is the
             operative change — but if a table is ever created
             outside that path, this will not cover it.
Target:      None. Closed. Stage 4 continues as OA-ZYRA-170.
Dependencies: OA-ZYRA-167 (origin); ZYRA_ENGINEERING_INVARIANTS
             I4 and its grants corollary — PUBLIC, anon and
             authenticated are independent, and this project has
             been caught by that three times. Overlaps the
             pending broad 'anon' grant sweep; sequence them
             together.
Automation:  The measuring query is a single pg_policies /
             information_schema join and is worth re-running
             after any policy change. Not automated — see
             invariant I7.

------------------------------------------------------------

OA-ZYRA-169
Title:       Silent catch (_) {} Blocks Remain in the Journey
             Service
Category:    Engineering / Observability
Priority:    Medium — no known defect behind any of them, but
             this is the exact construct that concealed a release
             blocker for a month
Status:      Open
Owner:       Founder (Shakeel)
Raised:      2026-08-08
Completed:   —
Source:      Observed while closing OA-ZYRA-167

Description: zyra_journey_service.dart still contains eight bare
             "catch (_) {}" blocks (lines 216, 322, 367, 409,
             423, 546, 562, 614). OA-ZYRA-167's root cause was
             not the failed write — it was that the failure
             produced no signal. A permission error and a
             successful write were indistinguishable to the
             caller.

             Each remaining block should be reviewed for the same
             property: can the operation fail in a way the user or
             the logs would never see? The advanceStage() rewrite
             is the reference pattern — return a typed result
             carrying the server's own reason vocabulary, and log
             on failure.

             Not asserting these are defects. Asserting they are
             unlit rooms.
Target:      Review each of the eight; convert to logged or typed
             failure where the operation can fail meaningfully.
             Not a bulk find-and-replace — some may be correct as
             written.
Dependencies: OA-ZYRA-167 (the precedent and the pattern);
             SOURCE/lib/services/zyra_journey_service.dart.
Automation:  A grep for "catch (_) {}" is trivial but would flag
             legitimate uses too. Not added to tools/zyra_check.py
             — new checks need explicit approval, invariant I7.

------------------------------------------------------------

OA-ZYRA-170
Title:       Function EXECUTE Privileges for 'anon' — Audit and
             Sweep
Category:    Security / Hardening
Priority:    Medium — same shape as OA-ZYRA-168 but for functions
             rather than tables, and unlike tables there is no
             RLS backstop behind a function grant
Status:      PARTIALLY APPLIED — Stages A/A' done and verified.
             Stage B' INCOMPLETE. Acceptance test still red.
             Parked 2026-08-08 pending Founder decision
Owner:       Founder (Shakeel)
Raised:      2026-08-08
Completed:   —
Source:      OA-ZYRA-168 Stage 4, deliberately excluded from that
             migration by Founder decision (invariant I7)

Outcome so far: two migrations applied, both Founder-approved —
             oa170_function_execute_sweep_stages_a_and_b and
             oa170_function_execute_sweep_stages_a_prime_b_prime.

             DONE: anon EXECUTE on every function that exists
             today is 0. authenticated unchanged at 56. All three
             policy-dependent functions (zyra_can_match,
             zyra_can_view_profile, zyra_can_read_photo_object —
             the last used by a storage.objects policy) verified
             still executable.

             NOT DONE: new functions still arrive anon-executable.
             Probe evidence: a function created after Stage B'
             carried '{=X/postgres, ...}' — the leading '=X' is
             PUBLIC, which anon inherits.

             Two revokes were required, not one. Stage A/B removed
             anon's EXPLICIT grant and removed anon from the
             default ACL; both worked and neither mattered while
             PUBLIC still granted it. Stage A' removed PUBLIC from
             the two existing functions and worked. Stage B'
             attempted the same on the default ACL and changed
             nothing, because there was no PUBLIC entry in the
             array to remove — PostgreSQL's built-in EXECUTE-to-
             PUBLIC default appears to be applied ON TOP of
             pg_default_acl rather than replaced by it.

             Fourth time this project has been caught by the
             PUBLIC/anon/authenticated relationship, and the first
             in this direction. Effective privilege is the UNION
             of a role's own grant, PUBLIC's grant and anything
             inherited; has_function_privilege() reports the union
             and is the only reliable check.

             CURRENT RISK: none today. anon executes nothing that
             exists and writes nothing anywhere. The gap applies
             from the next function-creating migration onward.

Description: The default ACL grants EXECUTE on every new function
             in schema public to 'anon'. OA-ZYRA-168 removed
             anon's table write grants and changed the table
             default ACL; the FUNCTION default ACL was left alone
             because it needs a different judgement per function.

             This is not a straight sweep. Some functions may
             legitimately need to be callable before
             authentication — preview_wali_invite() is the obvious
             candidate, since a Guardian follows an invite link
             before holding an account. Revoking indiscriminately
             would break that; leaving it indiscriminately leaves
             every future function open to unauthenticated
             callers.

             Note the asymmetry with OA-168: a table grant to anon
             still had RLS behind it, which is why those 75 grants
             were inert. A FUNCTION grant has no equivalent
             backstop — a SECURITY DEFINER function executable by
             anon runs as its owner with no policy layer in the
             way. This is therefore the more consequential of the
             two sweeps, despite being the smaller one.

             This project has been caught three times by the fact
             that REVOKE EXECUTE ... FROM public does not touch
             anon's explicit grant. Any plan here must revoke from
             anon by name and verify with
             has_function_privilege() — invariant I4 corollary.
Target:      AWAITING FOUNDER DECISION — one experiment, not yet
             approved, not applied:

               alter default privileges for role postgres
                 in schema public grant execute on functions to public;
               -- confirm '=X' now appears in the default ACL
               alter default privileges for role postgres
                 in schema public revoke execute on functions from public;
               -- confirm it disappears, then re-run the probe

             If the array can hold a PUBLIC entry and then drop
             it, the revoke sticks and B' is achievable. If it
             cannot, there is no durable default-privileges fix
             for functions and the fallback is (a) every
             function-creating migration ends with an explicit
             'revoke execute ... from public', plus (b) a detector
             flagging any public function carrying a PUBLIC
             EXECUTE grant. (b) is a new check and needs approval
             under invariant I7.

             ACCEPTANCE TEST for closing this OA: a throwaway
             function created after the change is NOT
             anon-executable. Founder-defined 2026-08-08. Do not
             mark complete on catalogue evidence alone — the
             catalogue read correctly while the probe was red.
Dependencies: OA-ZYRA-168 (precedent, method and verification
             pattern); ZYRA_ENGINEERING_INVARIANTS I4.
Automation:  The enumerating query is catalogue-only and cheap.
             Not added to tools/zyra_check.py — invariant I7.

------------------------------------------------------------

OA-ZYRA-171
Title:       Dev/Mock RPC Guard Depends on the '@zyra.test' Email
             Domain — Auth Configuration Dependency
Category:    Operational / Pre-Launch Dependency
Priority:    HIGH before real signups open. Zero risk today
Status:      Open — must be confirmed before the first real
             account is created
Owner:       Founder (Shakeel)
Raised:      2026-08-08
Completed:   —
Source:      OA-ZYRA-170 investigation. Founder decision to track
             separately: this is an authentication-configuration
             dependency, not a database permission issue

Description: Six SECURITY DEFINER RPCs grant paid entitlements:
             mock_purchase_wali_premium, mock_set_wali_plan,
             zyra_debug_grant_credits, zyra_dev_reset_account,
             zyra_dev_set_guardian_suggestions, zyra_dev_set_
             guardians_on_decided. Between them they can set a
             Wali premium plan and mint unlock credits.

             All six are correctly guarded inside the function
             body (added 2026-08-01, C4b):

               if not exists (select 1 from auth.users u
                   where u.id = caller
                     and u.email like '%@zyra.test')
               then raise exception 'mock_purchase_disabled' ...

             That is invariant I4 applied properly — the check is
             in the SECURITY DEFINER body, the layer an RPC caller
             cannot skip.

             THE DEPENDENCY: the guard trusts an email domain.
             It holds only while no attacker can register an
             address ending '@zyra.test'. Measured 2026-08-08:
             149 accounts, ALL '@zyra.test', all confirmed, seeded
             2026-07-19 to 2026-08-05, and ZERO real accounts.
             So the risk today is nil.

             '.test' is an IANA-reserved TLD that cannot receive
             mail, so the guard holds wherever email confirmation
             is enforced. That makes this safe IF AND ONLY IF
             Supabase Auth requires email confirmation at signup.
             That is a dashboard setting, not a database fact, and
             cannot be verified from SQL.

             If confirmation is ever disabled — or a provider is
             added that does not verify addresses — anyone could
             register attacker@zyra.test and grant themselves paid
             entitlements.
Target:      Before real signups open, either:
             (a) confirm email confirmation is enforced and record
                 it as a launch precondition; or
             (b) replace the domain check with something that does
                 not depend on Auth config — an explicit
                 dev_accounts allowlist table, or a role flag on
                 profiles; or
             (c) drop the six functions in production entirely.
             (b) is the stronger fix: it removes the dependency
             rather than documenting it. Per invariant I1, a guard
             resting on a setting someone can toggle is a
             permanent control anchored to temporary state.
Dependencies: OA-ZYRA-170 (origin); Supabase Auth configuration;
             ZYRA_ENGINEERING_INVARIANTS I1 and I4.
Automation:  A query counting non-'@zyra.test' accounts would turn
             this from a remembered check into a detected one.
             Not built — invariant I7.


             UPDATE 2026-08-10: a SEVENTH consumer was added —
             zyra_dev_set_journey_stage, the Active Journey stage
             jumper, built at Founder request so a section can be
             reached for testing without walking the whole Journey
             to get there.

             It rests on this same guard and does NOT weaken it.
             What it changes is the cost of the guard being wrong.
             The other six grant paid entitlements: someone past
             the guard gets a subscription they did not buy. This
             one moves an Active Journey to any stage, so someone
             past the guard walks through the Pre-Journey Ritual,
             the Guardian Gate and the 48-hour Family Review
             Period into another person's conversation, with
             neither family having agreed. The failure stops being
             commercial and becomes a safety failure.

             Removal of all seven is tracked as OA-ZYRA-184.
             DO NOT CLOSE THIS OA WITHOUT RE-READING THAT ONE.

------------------------------------------------------------

OA-ZYRA-172
Title:       Audit the 62 SECURITY DEFINER Functions Executable by
             'authenticated'
Category:    Security / Review
Priority:    Medium
Status:      Open — not started, by Founder instruction
Owner:       Founder (Shakeel)
Raised:      2026-08-08
Completed:   —
Source:      OA-ZYRA-170 Stage C, kept separate by Founder
             decision 2026-08-08 (invariant I7)

Description: 62 SECURITY DEFINER functions in public are
             executable by 'authenticated'. A SECURITY DEFINER
             function runs as its owner, so RLS is not a backstop
             — each function's own internal checks ARE the
             security boundary.

             Every function sampled during OA-170 enforced its own
             caller checks: auth.uid() null-checks, party checks
             on matches, '@zyra.test' guards on the dev functions,
             zyra_can_view_profile() visibility checks before
             returning or charging. The pattern is sound where it
             was examined.

             But "every one I sampled" is not "all 62". This item
             exists so that distinction is not quietly lost.
Target:      Line-by-line review of all 62. For each: does it
             authenticate the caller, authorise the caller against
             the specific object, and refuse cleanly? Produce a
             table of function, guard, and verdict. No changes
             without a separate plan.
Dependencies: OA-ZYRA-170; ZYRA_ENGINEERING_INVARIANTS I4.
Automation:  None possible — this is a reading exercise.

------------------------------------------------------------

OA-ZYRA-173
Title:       Removing Your Last Guardian Mid-Journey Hands Your
             Family's Family Review Vote to the Other Family
Category:    Correctness / Safety
Priority:    High
Status:      DECIDED 2026-08-10 by DR-ZYRA-136 — removal of your
             last Guardian is BLOCKED while a Journey is live.
             Build not started. Four consequences listed in the
             DR, including a Guardian REPLACEMENT flow that may
             not exist and would need its own OA.
             [superseded] Open — TRACKED ONLY, fix not started. The intended
             behaviour is a Founder decision, not an engineering one
Owner:       Founder (Shakeel)
Raised:      2026-08-08
Completed:   -
Source:      Found by Claude Opus while checking the Main-only
             counterpart-card rule's dependency on a Main Guardian
             always existing (autonomous build set, 2026-08-08)

Description: zyra_remove_guardian() is correctly guarded against
             removing your MAIN Guardian while others remain - it
             raises 'main_guardian_must_be_reassigned', because
             nothing would promote a replacement and Family Review
             reads is_main. That guard anticipated this exactly.

             But removing your LAST Guardian is deliberately
             allowed, and reasonably so: an empty Guardian page is
             a real and recoverable state.

             Mid-Journey it is not recoverable, and nothing
             re-checks. The Guardian Gate verifies both Seekers
             hold an active Main Guardian ONCE, at wali_gate
             (zyra_advance_stage, 2026-08-08). Nothing verifies it
             again afterwards.

             wali_review_decision() computes:

               select count(distinct wali_id) into expected_count
                 from wali_links where status='active' and is_main
                   and seeker_id in (m.seeker_a_id, m.seeker_b_id);
               ...
               if expected_count >= 1
                  and continued_count >= expected_count then ADVANCE

             With one side at zero Mains, expected_count becomes 1
             - so the OTHER family's Main Guardian alone advances
             the Journey on behalf of both families. The Seeker who
             removed their Guardian has silently removed their own
             family from a review that is currently open.

             Under the Main-only counterpart card (built
             2026-08-08) the same act also removes that family's
             card. The two failures compound.

             NOT the parked OA-ZYRA-150. That one concerns a
             Guardian who is unresponsive. This is a Seeker
             unilaterally removing their family from a live review.
Target:      A Founder decision on the intended behaviour first.
             Candidates, none built:
               (a) refuse the removal while a Journey is active -
                   consistent with the existing Main-reassignment
                   guard, but strands a Seeker who needs to remove
                   a Guardian behaving badly, which is the case the
                   removal path exists for;
               (b) allow it, and pause the Journey or hold the
                   review until a Main is linked;
               (c) allow it, and record the family as having
                   abstained, so expected_count reflects who was
                   entitled to vote rather than who happens to
                   exist now.
             (a) conflicts with safety, so (b) or (c) is likely -
             but that is a product judgement about what a Guardian
             is for, and per the standing rule it is not mine.
Dependencies: wali_review_decision(); zyra_remove_guardian();
             zyra_advance_stage() wali_gate check; the Main-only
             counterpart card; OA-ZYRA-150 (adjacent, distinct).
Automation:  A constraint cannot express it - the rule spans a
             removal, an open review and a Journey stage. A
             re-check inside wali_review_decision() is the likely
             enforcement point once the behaviour is decided.

------------------------------------------------------------

OA-ZYRA-174
Title:       Tier-1 Is Enforced at Four Gates, and "Already in an
             Unpaused Journey" Is Not One of Them - So a Pause
             Traps the Journey Permanently
Category:    Correctness / Invariants (I3, I4)
Priority:    High
Status:      CLOSED 2026-08-08 — Founder chose reading (a),
             GRANDFATHER. Built, verified live, regression-covered
Owner:       Founder (Shakeel) — decided same day
Raised:      2026-08-08
Completed:   2026-08-08
Source:      Found by Claude Opus running zyra_journey_suite.sql
             end to end for the first time. The suite threw at
             assertion 29 with 'not_eligible_to_match' out of
             resume_journey(). The immediate cause was a defect in
             the SUITE - its Main Guardian for fem1 already guarded
             male1 (fixed; assertion 0 now guards the premise). But
             the mechanism it tripped belongs to the product, not
             the test.

Description: Tier-1 (DR-ZYRA-123, shipped 2026-08-08) lives inside
             zyra_can_match(). Measured 2026-08-08, that predicate
             is consulted at exactly four places:

               - RLS insert policies on likes, passes, saves
               - create_match_on_mutual_like()
               - promote_journey_to_active()
               - resume_journey()

             Nothing consults it on a Journey that is already
             active and has not been paused. There is no re-check
             at stage advance, at Family Review, or on a trigger
             over wali_links.

             So if two Seekers acquire a shared Guardian AFTER
             their Journey started - a parent invited by both, a
             community figure taking on a second ward - the
             outcome depends entirely on whether they happen to
             press pause:

               never pause -> the Journey runs to completion,
                              Tier-1 notwithstanding.
               pause once  -> resume_journey() raises
                              not_eligible_to_match and there is no
                              path back. The Journey is stuck
                              paused; the only exit is
                              end_journey(). The Seeker is told
                              "Something has changed while this was
                              paused - a Guardian relationship or a
                              block now exists between you", which
                              is accurate and entirely
                              unactionable.

             That is an I3 violation (one path) and an I4 violation
             (enforce at the unskippable layer). Pausing is
             skippable, so enforcement is effectively arbitrary.

             This was NOT part of the DR-ZYRA-123 decision, which
             was about who may be MATCHED. Placing the rule inside
             zyra_can_match() silently extended it to resume,
             because resume_journey() re-checks the same predicate.
             The extension may well be right - but it was not
             decided, and it is written down nowhere.

             LIVE EXPOSURE TODAY: none. Measured 2026-08-08 - zero
             matches in status potential or active, so no pair can
             currently be trapped. Fix before beta, not now.

Target:      A Founder decision between two coherent readings.
             Neither is built.

             (a) GRANDFATHER. Tier-1 is a matching rule, not a
                 dissolution rule; a Journey that already exists
                 predates the Guardian bond and is unaffected.
                 Then resume_journey() is wrong to apply it, and
                 the fix is to narrow the resume re-check to what
                 resume actually protects against - blocks, and
                 Tier-0 - excluding Tier-1.

             (b) DISSOLVE. The pair is now known to be excluded,
                 and I1 says permanent behaviour follows permanent
                 data. Then the Journey should end, or at minimum
                 halt, at the moment the shared link is created -
                 not when someone happens to pause. The fix is a
                 trigger on wali_links, and it needs a decision
                 about what the two Seekers are told.

             What cannot be right is the present state, where the
             rule bites only if you pause. Either way the resume
             error needs an actionable exit: today it names a
             condition the Seeker has no way to clear.

Dependencies: zyra_can_match() Tier-1 clause (DR-ZYRA-123);
             resume_journey(); promote_journey_to_active();
             create_match_on_mutual_like(); likes / passes / saves
             insert policies; invariants I1, I3, I4;
             SOURCE/supabase/tests/zyra_journey_suite.sql
             assertion 0 and section F.
Automation:  Enforcement point depends on the reading: (a) is an
             edit to resume_journey(); (b) is an AFTER INSERT
             trigger on wali_links. A regression assertion is
             needed either way - the current suite proves Tier-1
             blocks NEW matches and proves nothing about existing
             ones.

RESOLUTION (2026-08-08, reading (a) GRANDFATHER):
             Migration 20260808190911_grandfather_tier1_out_of_
             resume_journey.sql. New internal predicate
             zyra_can_continue_journey(a,b) - blocks and Tier-0
             only, EXECUTE revoked from public/anon/authenticated.
             resume_journey() calls it instead of zyra_can_match()
             and raises 'not_eligible_to_continue' (was
             'not_eligible_to_match'). zyra_can_match() itself is
             untouched: Tier-1 still blocks new Likes, new matches
             and promotion.

             Client: the Dart matched only on
             'other_party_in_active_journey', so the rename broke
             nothing - but resumeJourney() would have rethrown the
             new code raw to the UI. Added
             NotEligibleToContinueException in
             SOURCE/lib/services/zyra_journey_service.dart.

             Role and gender deliberately NOT re-checked at resume.
             Re-checking role would rebuild this exact trap once
             the dual-role work deletes profiles.role.

             MEASURED WHILE BUILDING: Tier-0 cannot arise
             mid-Journey at all - zyra_enforce_guardian_link_
             allowed() refuses a Guardian link over a live Journey
             with 'romantic_edge_exists'. The Tier-0 branch is
             defence in depth, not the primary guard. See
             OA-ZYRA-175 for the separate Tier-0 finding this
             surfaced.

             Regression: zyra_journey_suite.sql section I,
             assertions 59-66, plus teardown 67. Whole suite run
             end to end 2026-08-08: 63/63, no residue.

------------------------------------------------------------

OA-ZYRA-175
Title:       Tier-0 Is Clearable By Retiring the Link and Tier-1 Is
             Not - The Closer Relationship Is the More Permissive
             One. Latent Until profiles.role Is Deleted
Category:    Correctness / Invariants (I1)
Priority:    High — but CONDITIONAL. Unreachable today; becomes
             reachable the moment the dual-role work lands
Status:      Open — TRACKED ONLY, fix not started
Owner:       Founder (Shakeel)
Raised:      2026-08-08
Completed:   -
Source:      Found by Claude Opus while reading zyra_can_match()
             in full to build OA-ZYRA-174's narrower predicate

Description: The two exclusion tiers inside zyra_can_match()
             disagree about whether ending a Guardian link ends the
             bond, and they disagree in the wrong direction.

               TIER-0 (one guards the other), written earlier:
                 where w.status = 'active'

               TIER-1 (they share a Guardian), written 2026-08-08:
                 where wa.status in ('active','removed')
                   and wb.status in ('active','removed')

             Tier-1 is I1-correct and there is an assertion proving
             it: suite check 48, "retiring the shared Guardian does
             NOT unlock it". Tier-0 has no such protection. Set the
             link to 'removed' and the Tier-0 clause stops matching.

             So a Guardian may retire from guarding his ward and
             then, on the face of the predicate, match her - while
             two people who merely once shared a Guardian stay
             excluded forever. The closer, more sensitive
             relationship is the more permissive one. That is
             backwards, and it is the exact I1 failure Tier-1 was
             written to avoid.

             WHY IT CANNOT FIRE TODAY. zyra_can_match() also
             requires a.role='seeker' AND b.role='seeker'. Measured
             2026-08-08: all 4 Guardians in the database are
             role='wali' and all 11 wards are role='seeker', so
             every Guardian/ward pair is refused on role alone and
             the Tier-0 clause is belt-and-braces that has never
             been load-bearing.

             WHY THAT IS NOT REASSURING. Deleting profiles.role is
             item 4 of the agreed dual-role build order
             ("can_match re-base off seeker_profiles, delete
             role"). The day that lands, the role check disappears
             and the Tier-0 clause becomes the ONLY thing standing
             between an ex-Guardian and his former ward - and it is
             clearable by the Guardian's own removal. There are
             already 2 removed opposite-gender ward/Guardian links
             in the database.

             This is not a bug report about today. It is a
             precondition on the dual-role work.

Target:      Decide whether a retired Guardian link is a permanent
             disqualification, exactly as Tier-1 already assumes.
             If yes - and consistency with Tier-1 and I1 both point
             that way - the change is one clause:

               where w.status in ('active','removed')

             with an assertion mirroring suite check 48. The
             counter-argument worth hearing first: a link may be
             'removed' because it was created in error, and a
             permanent romantic disqualification from an admin
             mistake is its own harm. If that case is real, it
             needs a distinct status ('withdrawn'?) rather than
             softening Tier-0 - and Tier-1 has the same problem
             today.

             MUST be settled BEFORE profiles.role is deleted.
Dependencies: zyra_can_match() Tier-0 clause; DR-ZYRA-123 (Tier-1);
             the dual-role / seeker_profiles work (item 4 of the
             agreed build order); invariant I1;
             zyra_journey_suite.sql check 48 (the Tier-1 mirror of
             this assertion, which exists) and check 51.
Automation:  One-clause change to zyra_can_match(), plus a
             regression assertion. The real work is the decision
             about what 'removed' means, which is shared with
             Tier-1.

------------------------------------------------------------

OA-ZYRA-176
Title:       Tier-1 Evaporates If the Shared Guardian Deletes His
             Account — FK CASCADE Hard-Deletes the Rows the Rule
             Depends On
Category:    Correctness / Invariants (I1)
Priority:    High
Status:      Open — TRACKED ONLY, fix not started
Owner:       Founder (Shakeel)
Raised:      2026-08-08
Completed:   -
Source:      Found by Claude Opus while measuring, for the Founder,
             what happens when a counterpart appoints your Guardian
             mid-Journey. The measurement's last step - "she later
             drops that Guardian, can you match again?" - returned
             TRUE, which contradicts suite assertion 48.

Description: Both results are correct; they exercise different
             paths, and only one of them is the one users have.

               zyra_remove_guardian()  -> UPDATE status='removed'
                                          Tier-1 HOLDS (check 48)
               account deletion        -> row is GONE
                                          Tier-1 EVAPORATES

             Verified chain, 2026-08-08:
               delete_own_account() deletes the auth.users row
                 -> profiles FK ON DELETE CASCADE
                 -> wali_links.wali_id FK ON DELETE CASCADE
                 -> every link naming that Guardian is hard-deleted

             Tier-1 asks whether a wali_links row exists with status
             in ('active','removed'). After a cascade there is no
             row in any status, so the predicate passes and the two
             wards become matchable.

             DR-ZYRA-123 named this risk precisely and guarded the
             wrong half of it: "Active-only would be I1-vulnerable -
             anchoring a permanent consequence on a row the user can
             retire." The WARD cannot retire the row. The GUARDIAN
             can destroy it, through a supported product action, and
             the soft-delete convention that makes 'removed' work is
             defeated by a hard delete two tables away.

             Reachable without collusion: a Guardian who simply
             leaves the app silently un-protects every pair of wards
             he held. Nobody is told.

             Also confirmed while checking, both FINE, recorded so
             the next person does not re-investigate:
               - No RLS DELETE policy on wali_links and no DELETE
                 privilege for `authenticated`. A client cannot
                 delete a link directly.
               - zyra_dev_set_guardians_on_decided() does DELETE
                 from wali_links and IS callable by authenticated,
                 but it is gated on the caller's email ending
                 @zyra.test and only touches the three dev-pool
                 Guardians. Correctly scoped. Worth knowing that it
                 CAN clear Tier-1 between two dev accounts, which
                 could make a future test look green wrongly.

Target:      A Founder decision on what a Guardian's departure means
             for the wards he linked. Candidates, none built:
               (a) don't cascade - change wali_links.wali_id to
                   ON DELETE SET NULL or RESTRICT and keep a
                   tombstone, so the bond outlives the account. Most
                   faithful to I1; needs a nullable wali_id and a
                   review of everything that joins on it;
               (b) record the exclusion independently of
                   wali_links - a co-ward pair table written when
                   the second link is created and never deleted.
                   Costs a table, immune to cascade;
               (c) accept it, and say so in DR-ZYRA-123, on the
                   grounds that a departed Guardian's wards are no
                   longer a family under his care. Coherent, but it
                   is the opposite of what assertion 48 currently
                   claims the system does.
             Whatever is chosen, suite assertion 48 must be extended
             to cover the cascade path, because it currently proves
             I1 holds while a supported path breaks it.
Dependencies: zyra_can_match() Tier-1 and Tier-0 clauses;
             delete_own_account(); wali_links_wali_id_fkey and
             wali_links_seeker_id_fkey (both CASCADE); profiles FK
             to auth.users (CASCADE); zyra_remove_guardian();
             DR-ZYRA-123; OA-ZYRA-175 (same family of problem, the
             Tier-0 half); zyra_journey_suite.sql check 48.
Automation:  (a) is a schema migration. (b) is a table plus a
             trigger. Either way a regression assertion that deletes
             a Guardian account and re-checks zyra_can_match.

------------------------------------------------------------

OA-ZYRA-177
Title:       Two Seekers Sharing a Main Guardian Collapse the Family
             Review to a Single Vote — One Person Approves on Behalf
             of Both Families
Category:    Correctness / Product
Priority:    Medium — depends entirely on whether this is judged
             correct behaviour, which it may well be
Status:      OPEN — SCOPE NARROWED 2026-08-10 by DR-ZYRA-137.
             A Guardian MAY hold many wards (Founder, explicit).
             The two Seekers in a match may not share one — that
             is Tier-1, already built. STILL OPEN: the pair who
             come to share a Guardian AFTER matching, which
             DR-ZYRA-124 permits by design. Founder deferred the
             fix behind DR-ZYRA-136.
             [superseded] Open — TRACKED ONLY. Genuinely may need no fix
Owner:       Founder (Shakeel)
Raised:      2026-08-08
Completed:   -
Source:      Measured by Claude Opus answering the Founder's
             question "what happens if we match and halfway through
             they change their Guardian to the same as mine".

Description: wali_review_decision() computes how many approvals a
             stage transition needs as:

               select count(DISTINCT wali_id) into expected_count
                 from wali_links where status='active' and is_main
                   and seeker_id in (m.seeker_a_id, m.seeker_b_id);

             DISTINCT. When the two Seekers share a Main Guardian,
             two families collapse to one row and expected_count
             becomes 1. Measured end to end 2026-08-08: one person
             voted 'continue' once, the review went straight to
             'continued', and the Journey advanced phase_1 ->
             phase_2 with no second approval sought.

             Whether that is wrong is a real question, not a
             rhetorical one. If one man genuinely is Guardian to
             both families, his single judgement IS both families'
             judgement, and asking him twice is theatre. The Family
             Review is described as a two-FAMILY safeguard, and on
             that reading nothing is broken.

             What makes it worth recording is that the state is now
             reachable and persistent. Tier-1 was supposed to stop
             two people who share a Guardian from being paired at
             all — but Tier-1 only gates matching, and per
             DR-ZYRA-124 an existing Journey is grandfathered. So
             the pairing Tier-1 exists to prevent can now run to
             completion with a single person holding both votes.
             Before DR-ZYRA-124 the same state was reachable too,
             just unreliably — it depended on the pair never pausing.

             Mechanically identical to OA-ZYRA-173, which reaches
             expected_count=1 by one side having ZERO Mains rather
             than both sides sharing one. Same line of SQL, two ways
             in. Worth fixing together if either is fixed.

Target:      A Founder decision. Candidates:
               (a) accept, and write it down as intended - a shared
                   Guardian is one voice because he is one person;
               (b) count SEEKERS with a Main rather than distinct
                   Guardians, so a shared Guardian is asked to
                   record a decision per ward. Closes OA-173 by the
                   same change;
               (c) refuse to open a Family Review at all when the
                   two Seekers share a Main, and surface it - which
                   effectively means ending the Journey, and so
                   reopens DR-ZYRA-124.
Dependencies: wali_review_decision(); resolve_family_review_if_due();
             OA-ZYRA-173 (same expression, different cause);
             DR-ZYRA-123 (Tier-1); DR-ZYRA-124 (grandfather).
Automation:  One expression in wali_review_decision(), plus the
             matching change in resolve_family_review_if_due() if
             it computes the same count. A regression assertion in
             zyra_journey_suite.sql section C.

------------------------------------------------------------

OA-ZYRA-178
Title:       Browse Selects Every Matching Profile With No Limit —
             Add Paging To fetchCandidates()
Category:    Performance / Enumeration surface
Priority:    Medium now, High before any real user volume
Status:      Open — Founder deferred 2026-08-09: "add paging to an
             OA and we do it later." Not started
Owner:       Founder (Shakeel)
Raised:      2026-08-09
Completed:   -
Source:      Found while fixing the ages-showing-as-0 bug. The age
             bug was a consequence of this one and has been fixed
             separately; the unbounded query underneath has not.

Description: ZyraDiscoveryService.fetchCandidates() runs:

               .from('profiles')
               .select('id, first_name, surname_line, location_text,
                        gender, profile_photos(...)')
               .eq('role','seeker')
               .eq('gender', targetGender)
               .eq('is_active', true)
               .eq('profile_complete', true)
               .neq('id', user.id)

             There is NO .limit() and NO .range(). Every matching
             Seeker in the database is fetched, with their photo
             rows joined, on every Browse load.

             Measured 2026-08-09: 72 candidates per gender. Fine.
             At 10,000 active Seekers it is a full-table read plus a
             join, on a screen the user opens constantly.

             IT IS ALSO AN ENUMERATION SURFACE. One Browse call
             hands the client the id, first name, surname line and
             city of every active member of the opposite gender.
             That is the exact shape of harm OA-ZYRA-175 and the
             ages_for cap (I10) were written against — capped in
             one place, wide open in another.

             ALREADY BITTEN ONCE. The ages_for() 50-id cap added
             2026-08-08 assumed a page size that does not exist —
             its own migration comment reads "50 = Browse's page
             size, so every legitimate caller fits". 72 > 50, so
             ages_for raised on every load and, because all four
             callers swallowed the error, every age in the app
             rendered as 0 for a day. Fixed by paging the CLIENT
             (ZyraAgesService) rather than by raising the cap — but
             the reason the mismatch existed is this entry.

Target:      Page fetchCandidates(). Design decisions, none taken:
               (a) page size — 50 aligns with the ages_for cap and
                   with what the deck can plausibly show in a
                   session, and would make the existing comment
                   true;
               (b) how the next page is triggered — on approaching
                   the end of the deck, or on a refresh;
               (c) ordering must be STABLE across pages, or paging
                   will duplicate and skip candidates. Today the
                   order is whatever Postgres returns, then
                   re-sorted client-side by score_candidates().
                   Scoring across a page boundary is not the same
                   as scoring across the whole set, and that is a
                   product question, not just a technical one;
               (d) whether the shuffle/ordering seen by a given
                   Seeker should be stable between app launches.

             (c) is the one that needs thought. Everything else is
             mechanical.
Dependencies: SOURCE/lib/services/zyra_discovery_service.dart
             (fetchCandidates, _applyCompatibility);
             score_candidates(); ages_for() 50-id cap;
             SOURCE/lib/services/zyra_ages_service.dart;
             invariant I10; OA-ZYRA-175.
Automation:  A .range() plus a scroll/deck trigger. The stable-sort
             question needs a decision before any of it is written.

------------------------------------------------------------

OA-ZYRA-179
Title:       Build "Block My Phone Contacts" — Optional Verified
             Number, Honest Coverage Copy, and Do Not Believe the
             Hashing Solves Privacy
Category:    Feature / Safety / Privacy
Priority:    High value, not urgent. Nothing is broken; this is the
             feature the competitor research rates highest
Status:      Open — direction approved (DR-ZYRA-128), NOT started
Owner:       Founder (Shakeel)
Raised:      2026-08-09
Completed:   -
Source:      Founder question about Muzz's Settings. Direction taken
             the same day as DR-ZYRA-128.

Description: Four pieces, none of which exist:

               1. OPTIONAL PHONE VERIFICATION. A number on the
                  account, verified by OTP. Supabase Auth supports
                  phone as a second identity on an existing user.
                  Also unlocks 2FA, which is why a member might add
                  one even if they never use contact blocking.
               2. CONTACTS PERMISSION on device, with the iOS
                  limited-access path handled.
               3. MATCHING, server-side.
               4. THE BLOCK ITSELF — reuses profile_blocks, or a
                  sibling table if contact-blocks need to behave
                  differently (see the open questions).

🔴 THE HASHING TRAP — read this before designing the matching.
             The standard pattern is: hash the contacts on device,
             send hashes, compare against hashed member numbers,
             never store the address book. Correct as far as it
             goes, and it is NOT anonymisation.

             Phone numbers are a tiny keyspace. A UK mobile is
             about 10^9 possibilities; every one can be hashed in
             seconds. A plain or globally-salted hash of a phone
             number is therefore reversible by anyone holding the
             hash and the salt — which is us. Per-user salts do not
             help, because matching requires both sides to hash the
             same way.

             So do not claim the server "never learns" the member's
             contacts. It does learn which of them are on ZYRA —
             that is inherent to the feature. What the design can
             honestly promise:
               - the address book is never persisted, only the
                 resulting block edges;
               - hashes are discarded within the request;
               - the match result is never shown as a list
                 ("3 of your contacts are on ZYRA" is itself a
                 disclosure about those people).
             State that accurately in the Privacy & data screen
             (DR-ZYRA-127) rather than overclaiming.

🔴 THE COVERAGE COPY IS A SHIP CONDITION, not a nicety.
             Per DR-ZYRA-128: the control must say, in its own
             copy at the point of switching on, that it hides the
             member only from contacts who have also added a
             number. Not in help, not in a tooltip. A member who
             believes they are hidden from a specific person and is
             not is worse off than one who never had the switch —
             they stopped worrying.

             Do NOT display a coverage count or percentage. It
             sounds like honesty and it leaks: "12 of your contacts
             are on ZYRA" tells the member something about twelve
             people who did not consent to being told about.

Target:      Founder decisions still open before build:
               (a) is a contact-block TERMINAL (I1/I2, like a
                   profile block), or does it lift when the number
                   leaves the phone's address book? Terminal is
                   consistent with I2 but surprising — the member
                   thinks of it as a live sync;
               (b) does the blocked party learn anything? Profile
                   blocks today are silent, and this should almost
                   certainly match;
               (c) is the same number reusable for 2FA, or is a
                   number added for blocking held separately;
               (d) retention — is the number kept if the member
                   later turns contact blocking off.

             ALSO WORTH DOING FIRST, and independent of all of the
             above: "Discovery & visibility" currently has exactly
             ONE toggle, "Visible in Browse" — all or nothing.
             MUZZ_TEARDOWN records the graduated version:
             "invisible to people you haven't liked, or hidden
             entirely". That needs no phone number, no permission
             and no matching, and it covers part of the same fear.
             Cheap, and shippable now.
Dependencies: Supabase Auth phone identities; profiles;
             profile_blocks; privacy_settings_screen.dart;
             privacy_and_data_screen.dart (its "does not ask for
             your phone number" line becomes wrong the day this
             ships and must change with it); DR-ZYRA-128;
             DR-ZYRA-127; MUZZ_TEARDOWN; invariants I1, I2.
Automation:  OTP verification is Supabase's. The matching is one
             SECURITY DEFINER function. The genuinely hard parts
             are the four decisions above and the copy.

------------------------------------------------------------

OA-ZYRA-180
Title:       Commit the 424 Uncommitted Files. Two Weeks of Work
             Exists in One Place, in a Working Tree, With No Remote
Category:    Governance / Continuity
Priority:    🔴 DO THIS FIRST. Everything else in this register is
             work to be done; this one is work already done that can
             still be lost
Status:      Open — the command is written and safety-checked, and it
             needs 30 seconds in Terminal
Owner:       Founder (Shakeel) — NOBODY ELSE CAN DO IT (see below)
Raised:      2026-08-09
Completed:   -
Source:      Founder, 2026-08-09: "You need to remind me to write it
             in terminal otherwise ill forget so maybe add to oa"

Description: Last commit is a6806ad, 26 July 2026. 424 files have
             changed since. That includes everything from the
             2026-08-09 session — the three release blockers, three
             audit findings, the canonical Journey stage map, 37
             migrations, the splash and loading rebuild, the app
             icon, and the Settings Legal section.

             None of it is in git history. It exists as a working
             tree on one Mac.

WHY ONLY THE FOUNDER CAN DO IT
             Git cannot write through the Cowork device bridge. The
             mounted filesystem refuses unlink(), so git creates
             .git/index.lock, cannot remove it, and every subsequent
             git write fails — git add exits 0 and stages nothing.
             Measured 2026-08-08 and unchanged. It must be run by
             hand in Terminal, or from a Cowork task started with
             "On your computer" rather than "In the cloud".

THE COMMAND — one line, paste as-is
             Stored verbatim in the reminder attached to this OA and
             in the handover note. It does three things:
               rm -f .git/index.lock   (this mount leaves locks
                                        behind; one dated 2026-08-08
                                        was cleared on 2026-08-09,
                                        and any git read can make a
                                        new one)
               git add -A
               git commit with a seven-paragraph message covering the
                                        whole 26 Jul - 9 Aug period

SAFETY CHECK ALREADY DONE, 2026-08-09
             Every file git add -A would stage was scanned for
             JWT-shaped strings, sk- keys and PEM private keys.
             ZERO hits. Seven files match the word service_role; all
             are grant documentation naming the Postgres role, which
             is what those documents are about.
             supabase_config.dart, oauth_config.dart and
             SOURCE/build/ are all correctly ignored. Git identity is
             configured, so the commit will complete.

🔴 A COMMIT IS NOT A BACKUP HERE
             There is NO git remote configured. Committing protects
             the work from edits, mistakes and confusion about what
             changed. It does not protect it from losing the machine.
             Both copies would still be on the same disk.

             Setting up a private remote is a SEPARATE and arguably
             more important job, and it is not covered by this OA.
             Until it exists, TOOLS/zyra_backup.sh is the only thing
             standing between this project and a single disk failure.

Reminder:    A daily scheduled task fires at 09:00 UK
             (trig_01GAqnsNhhk91qDhBR9rWCc6, created 2026-08-09). It
             checks whether the commit has landed and DELETES ITSELF
             once it has, so it stops on its own rather than becoming
             noise. Ask to cancel it any time.

Blocks:      Nothing technically. But every further session adds to
             the pile, and the longer the gap the less useful the
             history is — 424 files in one commit is already a poor
             record of two weeks of decisions.
Dependencies: CLAUDE.md §5 "git cannot write through the Cowork
             device bridge"; OA-ZYRA-134 (which records a DIFFERENT
             last-commit date, 2026-07-03 — see audit finding 5.11;
             one of the two is wrong and this OA supersedes both);
             SYSTEM/RESOURCES/TEMPORARY/SESSION_HANDOVER_2026-08-09.md;
             DR-ZYRA-129, 130, 131, 132.

------------------------------------------------------------

OA-ZYRA-181
Title:       Verify OA-168 Stage 3 With a Live Table Probe —
             Catalogue Evidence Has Since Proved Insufficient
Category:    Security / Verification
Priority:    Medium — OA-168 is marked Actioned on evidence of a
             kind that later failed for functions
Status:      Open — awaiting Founder approval for the probe
Owner:       Founder (Shakeel)
Raised:      2026-08-08
Completed:   —
Source:      Raised unprompted during OA-170. Same class of error,
             one object type across

Description: OA-ZYRA-168 Stage 3 was reported successful because
             the table default ACL read 'anon=rxtm' — no write
             bits. NO TEST TABLE WAS EVER CREATED to confirm a new
             table actually arrives without write grants.

             OA-170 then showed a correct-looking pg_default_acl
             does not guarantee the resulting object: the function
             default ACL read correctly while a newly created
             function was still anon-executable via PUBLIC.

             Tables may genuinely be fine — PostgreSQL's built-in
             default grants nothing to PUBLIC for tables, so there
             is no equivalent hidden inheritance. But that is the
             same reasoning that produced confidence about
             functions an hour earlier.
Target:      Create a throwaway table, check anon/authenticated
             write privileges with has_table_privilege(), drop it.
             If it arrives writable, reopen OA-168. Approval
             required before running it.
Dependencies: OA-ZYRA-168 (claim under test); OA-ZYRA-170
             (precedent); ZYRA_ENGINEERING_INVARIANTS I5.
Automation:  None.

------------------------------------------------------------

OA-ZYRA-182
Title:       Rewrite the I4 Grants Corollary as a Union Statement
Category:    Governance / Documentation
Priority:    Medium
Status:      Open — PARKED by Founder instruction until OA-170 and
             OA-181 settle, so the invariant is updated once with
             final wording rather than twice
Owner:       Founder (Shakeel)
Raised:      2026-08-08
Completed:   —
Source:      OA-ZYRA-170 Stage B/B' failure

Description: The I4 grants corollary says PUBLIC, anon and
             authenticated are independent and that Supabase
             grants anon explicitly. True — and it points the
             reader at revoking from anon, which is how OA-170
             walked into the mirror-image failure.

             Not wrong; incomplete in a way that caused a failure.
             Proposed replacement:

               A role's effective privilege is the UNION of its
               own grant, PUBLIC's grant, and anything it
               inherits. Revoking one path leaves the others
               standing. Revoke every path, then verify with
               has_*_privilege(), which reports the union and is
               the only thing that answers the real question.

             Four incidents support it — three in the 'revoked
             PUBLIC, anon still had it' direction, one in reverse.
Target:      Fold into the next invariants version alongside any
             wording OA-170 produces. Do not cut V4 for this
             alone.
Dependencies: OA-ZYRA-170; OA-ZYRA-181; ZYRA_ENGINEERING_
             INVARIANTS (current version).
Automation:  None.

------------------------------------------------------------

OA-ZYRA-183
Title:       Relationship-State Master Matrix V2 — Consolidation
             and Dimensional Completeness
Category:    Product Architecture
Priority:    HIGH — Founder has gated further Guardian
             functionality on this
Status:      Open — Founder-led. Completeness before
             implementation
Owner:       Founder (Shakeel)
Raised:      2026-08-08
Completed:   —
Source:      Fable's matrix V1 + Opus completeness audit +
             ChatGPT review (pending)

Description: V1 models relationship STATES well. The completeness
             audit found it incomplete on DIMENSIONS rather than
             rows — 15 named: multiplicity, lateral ward-to-ward
             edges, transitivity and cycles, principals beyond the
             four identities, discovery as distinct from
             visibility, indistinguishability, copies and derived
             artefacts, joint objects, provenance, concurrency and
             timers, weaponisation of exclusion rules, legal
             compulsion (erasure), age and jurisdiction,
             entitlement state, and the model's own governance.

             Six of the Founder's ten proposed additions are
             symptoms of missing dimensions, so adding rows alone
             would leave the model equally incomplete. OA-ZYRA-177
             is one such case already logged independently
             (two Seekers sharing a Main Guardian) — evidence the
             lateral dimension is real and currently handled
             case-by-case.

             THREE STRUCTURAL FINDINGS for V2:
             1. V1 mixes architectural intent, current
                implementation and verified live behaviour in the
                same cells. The factual half decayed within hours
                — G-5 was true when written and false when
                measured the same day. Founder has agreed these
                must be separated.
             2. No permanent cell identifiers. Features will cite
                'G-5'; inserting a row shifts every citation. Same
                defect class this project closed for document
                filenames (Naming Conventions rule 5).
             3. The completeness test cannot fail, and no rule
                exists for composing two cells that both apply.

             CONSOLIDATION RISK, flagged: agreement between Fable,
             ChatGPT and Opus is weak evidence of completeness —
             same class of reasoner, same sources, same priming.
             Convergent cells pass unexamined; single-source
             findings are the ones worth arguing. 'Cross-AI
             agreement is not build authorisation' applies to
             completeness too.
Target:      Founder-led consolidation of the three reviews into
             one master model. No implementation or redesign until
             the problem space is agreed complete.
Dependencies: ZYRA_RELATIONSHIP_STATE_MASTER_MATRIX V1 (Fable);
             ZYRA_RELATIONSHIP_MATRIX_COMPLETENESS_AUDIT_2026-08-08;
             ChatGPT review (pending); OA-ZYRA-173 to OA-ZYRA-177
             (Guardian tier findings, same problem space);
             ZYRA_ENGINEERING_INVARIANTS I1 and the
             deployed-system-outranks-source corollary.
Automation:  Factual 'today' claims in any version can be verified
             against the live database mechanically. Offered, not
             built — invariant I7.

------------------------------------------------------------

OA-ZYRA-184
Title:       Drop the Developer/Mock RPCs Before Public Launch —
             Now TEN Functions, Including the Stage Jumper
Category:    Pre-Launch / Security
Priority:    BLOCKING for public launch. Zero risk while the
             database holds only seeded accounts
Status:      Open — raised 2026-08-10, not started
Owner:       Opus (Implementation Lead); Founder confirms the
             launch gate
Raised:      2026-08-10
Completed:   —
Source:      Engineering audit item #20, extended 2026-08-10 when
             zyra_dev_set_journey_stage was added at Founder
             request (Active Journey stage jumper)

Description: "Drop the mock RPCs before launch" is now recorded in
             three places with three different lists. The audit
             named two. OA-ZYRA-171 enumerated six. There are now
             seven. A pre-launch checklist that disagrees with
             itself is the exact failure mode catalogued in
             contradiction-audit section 5, and it fails in the
             worst possible week. THIS ENTRY IS THE LIST.

             THE NINE (it was seven when this OA was raised, the same
             morning — see the note below):
               1. mock_purchase_wali_premium
               2. mock_set_wali_plan
               3. zyra_debug_grant_credits
               4. zyra_dev_reset_account
               5. zyra_dev_set_guardian_suggestions
               6. zyra_dev_set_guardians_on_decided
               7. zyra_dev_set_journey_stage         <- added 2026-08-10
               8. zyra_dev_set_counterpart_reveal    <- added 2026-08-10
               9. zyra_dev_set_plus_unlock           <- added 2026-08-10
              10. zyra_dev_set_compatibility        <- added 2026-08-10
                  Forces a Reveal result (both flags + a chosen score) so
                  the mutual screen can be seen at both ends. Needed because
                  after the backfills every seeded profile scores 77-100
                  against every other, so a LOW result was unreachable by
                  playing the product properly.

             SEVEN AT 09:00, EIGHT BY 10:30, NINE BY 15:00 — all on one
             day. That is not a criticism of the tools; it is the whole
             reason this OA exists in one place rather than as a line in
             three documents. The next person to add one must add it
             HERE.

             Number eight sets the OTHER Seeker's Compatibility Reveal
             flag, so one tester can exercise both sides of a two-sided
             gate. It writes a column that contradiction-audit finding
             2.5 exists to protect — "either Seeker can set both flags:
             consent given on someone else's behalf" — and it must not
             be mistaken for a decision that 2.5 is acceptable. It sits
             BESIDE that policy behind the @zyra.test guard, so the fix
             for 2.5 can still be a WITH CHECK. Migration 20260810102417.

             Number nine simulates buying Compatibility Unlock+
             (DR-ZYRA-135). It writes a profile_unlocks row, which is a
             record of MONEY — so unlike the others it removes only the
             simulated 'paid_plus_single' it created, never a real
             unlock of another type. Migration 20260810150114.

             ALSO DROP, and easy to miss because it is not a dev
             function: zyra_compatibility_for_plus is production code
             and STAYS. Do not sweep it out with the nine.

             Number seven is the most consequential of the set and
             the only one that has nothing to do with money. It
             moves an Active Journey to any of the eight stages,
             which means it walks past the Pre-Journey Ritual, the
             Guardian Gate and the 48-hour Family Review Period.
             Those three are what make ZYRA a marriage process
             rather than a chat app.

             It also creates the conversation row on a jump to
             'conversation', so the destination is usable. That is
             correct for a dev tool and unacceptable in a shipped
             one: it manufactures the object the whole Journey
             exists to earn.

             The tool is worth having WHILE the database holds
             seed data only — measured 2026-08-10, 149 accounts,
             all @zyra.test, zero real. It stops being worth
             having the day that is no longer true, and that day
             will not announce itself.

Target:      All nine DROPped and their Dart callers removed, in
             one migration, before the first real signup.
             VERIFY BY ASSERTION, not by reading this list back:
             each name absent from pg_proc, and absent from lib/.
             "The migration ran" is not evidence — 2026-07-26
             engineering audit.
Dependencies: OA-ZYRA-171 (the @zyra.test guard, which is what
             holds until this is done — and which now carries a
             2026-08-10 note pointing here); engineering audit
             item #20; ZYRA_ENGINEERING_INVARIANTS I4;
             migration 20260810093756
Automation:  One SQL assertion proves all nine are gone. Belongs
             in the launch checklist, not a scheduled job — there
             is nothing to watch until launch, and then it is
             checked once.

------------------------------------------------------------

OA-ZYRA-185
Title:       Chapter 2's Sect Hard Requirement Is Still
             Per-Question While Chapter 4 Is Per-Option
Category:    Onboarding / Compatibility Engine
Priority:    Medium — nothing is wrong today. The screen and the
             engine agree. It is consistency debt with a closing
             cost window
Status:      ACTIONED 2026-08-10 — Founder said converge. Done
             and verified 16/16, server and client
Owner:       Founder (Shakeel) decides scope; Opus implements
Raised:      2026-08-10
Completed:   —
Source:      Found 2026-08-10 while implementing Onboarding
             Direction B stage 1. TrafficLightQuestionScreen is
             shared by Chapter 2 and Chapter 4; only Chapter 4
             moved

Description: Chapter 4's Hard Requirements became per-OPTION on
             2026-08-10, so a Seeker can now say "Currently
             Married — never" while leaving "Divorced" a soft
             red. Chapter 2's sect matrix cannot. It still stores
             {sect: {hard_requirement: bool}} in
             seeker_details.preferences and score_candidates()
             reads it that way: ANY red sect excludes.

             So on the most sensitive question in the app —
             Islamic sect, UK GDPR Article 9 data — the Seeker
             gets the coarse control Chapter 4 just retired.

             WHY NOT IN THE SAME PASS. Two reasons, both
             deliberate:

             1. SCOPE. The Founder approved Direction B for
                ch4_hard_requirements. The options paper put the
                Chapter 2 question review explicitly out of
                scope. Widening a schema change past its
                authorisation is how registers stop being true.

             2. IT IS NOT FREE THE WAY CHAPTER 4 WAS.
                onboarding_answers had ZERO rows, so that
                reshape cost one migration and no backfill.
                seeker_details has 24 rows, every one carrying a
                sect preference block, 8 with hard_requirement
                set. Measured 2026-08-10. They are seeded, so
                re-seeding is cheap — but it is a decision, not
                a free move, and it stops being cheap at first
                real signup exactly as Chapter 4's did.

             WHAT WAS DONE INSTEAD. TrafficLightQuestionScreen
             gained an explicit HardRequirementScope. Chapter 4
             passes perOption; Chapter 2 passes perQuestion and
             keeps its single checkbox and original wording. The
             alternative — showing the per-option control and
             collapsing it to a bool on the way out — was
             rejected: it would let someone exclude Ibadi but not
             Shia while the engine still excluded both, so the
             screen would promise precision the server cannot
             honour. A coarse control is worse than a precise
             one; a lying control is worse than both.

             FOUNDER DECISION 2026-08-10: converge. Done the same
             day, migration
             oa185_chapter2_sect_exclusion_becomes_per_option.

             CONVERTED, NOT RE-SEEDED. All 144 rows moved from
             boolean to array. A set flag became the list of
             sects that Seeker had actually marked red — which is
             exactly what the flag meant — so nothing was
             invented and nothing lost. Asserted: 0 exclusions
             name a sect that was not red.

             THE ENGINE now tests the sect exclusion BEFORE the
             light and independently of it, matching Chapter 4.
             A CHECK (seeker_details_sect_hard_shape) rejects the
             boolean form so a stale client cannot silently write
             an exclusion that reads as "none" — which on Article
             9 data would fail OPEN on a promise.

             HardRequirementScope IS GONE. It existed for a few
             hours and had one job: stop Chapter 2 showing a
             per-option control over per-question storage. With
             the storage converged it would have been a dormant
             fork nobody would later remember the reason for, so
             it was deleted rather than left. A tombstone comment
             in traffic_light_question_screen.dart records why it
             ever existed.

             VERIFIED 16/16. Two of those checks are worth noting
             because the first attempt at them was wrong:

               * "red-but-not-hard survives" could not be tested
                 against the seeded data at all — the conversion
                 makes every red sect an exclusion, so no such
                 pair exists. The first run PASSED TRIVIALLY on a
                 tautology. Rebuilt by hand: Shia excluded, Other
                 red but not. Excluded one vanishes, soft one
                 survives.
               * "the soft red still penalises" asserted score
                 < 50 and FAILED — correctly. With ~70 Chapter
                 3/4 questions now seeded, one red sect moves the
                 total by 1.71 points, not below the midpoint.
                 The assertion was written for this morning, when
                 Chapter 2 was the only scoring input. Re-tested
                 relatively — same candidate, sect light flipped
                 — and the red does cost them, by exactly the
                 ~4% share measured in the backfill findings.

------------------------------------------------------------

OA-ZYRA-186
Title:       'anon' Holds Table SELECT on 29 Public Tables —
             the Read-Side Twin of OA-ZYRA-168
Category:    Security / Hardening
Priority:    Medium — nothing is exploitable today. All 29 have
             RLS enabled with policies evaluating
             user_id = auth.uid(), which is NULL for anon, so
             every row is already denied
Status:      ACTIONED 2026-08-10 — swept and verified.
             0 tables and 0 functions now reachable by anon
Owner:       Founder (Shakeel)
Raised:      2026-08-10
Completed:   2026-08-10
Source:      Found 2026-08-10 during the six-layer read for
             Onboarding Direction B stage 1, on noticing
             onboarding_answers granted SELECT to anon

RESULT:      Migrations oa186_revoke_anon_table_select_sweep and
             oa186b_revoke_shape_fn_from_public.

             AFTER: anon holds SELECT on 0 tables and EXECUTE on
             0 functions. `authenticated` untouched — 33 tables,
             and a 6-check regression confirmed it still reads
             its own profile, seeker_details, onboarding_answers,
             photos and notifications, and that score_candidates()
             still returns a score.

             TWO THINGS THE FIRST MIGRATION GOT WRONG, both found
             by verifying rather than trusting the success code:

             1. REVOKE EXECUTE ... FROM anon did NOTHING. The
                function's proacl was NULL, so anon held EXECUTE
                through PUBLIC rather than directly. Revoking from
                a role that inherits via PUBLIC succeeds and
                changes nothing. Fixed in 186b with FROM PUBLIC.

             2. The first verification query reported the default
                privileges as still broken. It was matching
                SEQUENCE acls (anon=rwU) rather than table ones.
                Re-checked against objtype 'r' only: migrations
                run as `postgres` and that default now excludes
                anon.

             RESIDUAL, ACCEPTED: supabase_admin keeps its own
             default ACL granting anon SELECT on tables it
             creates. That role is not ours to alter. Migrations
             run as postgres so it does not bite in practice, but
             anything created as supabase_admin needs revoking by
             hand.

Description: OA-ZYRA-168 swept WRITE grants to 'authenticated'
             with no matching policy. OA-ZYRA-170 swept function
             EXECUTE for 'anon'. Neither covers TABLE SELECT for
             'anon', and 29 public tables hold it — among them
             onboarding_answers, seeker_details, messages,
             notifications, profile_reports and wali_links.

             This is Supabase's default `grant select on all
             tables in public to anon`, not something anyone
             wrote deliberately. RLS denies underneath it, so the
             privilege is inert — the same "currently inert"
             finding as OA-168, on the read side.

             RAISED, NOT FIXED, AND THE REASON MATTERS. The same
             pattern WAS fixed in isolation on journey_requests
             earlier the same day. Correct there: that was
             completing an incomplete revoke on a table created
             minutes before. Doing the same one-off here would be
             wrong — fixing 1 of 29 identical cases makes the
             register read as resolved while 28 remain. It is one
             sweep or it is nothing.

             TO CLOSE: revoke in one migration, then assert it.
             The guard suite already has the right shape for this
             (checks 48-53). Any table that genuinely needs anon
             read — none identified — must be named explicitly.

------------------------------------------------------------

OA-ZYRA-187
Title:       The Guard Regression Suite Could Not Run For Two
             Days, and CLAUDE.md Told Everyone To Run It
Category:    Governance / Testing
Priority:    High when discovered — the suite is named in
             CLAUDE.md as the gate before and after every
             migration
Status:      Actioned 2026-08-10 — both suites fixed and re-run
             the same day
Owner:       Opus (Implementation Lead)
Raised:      2026-08-10
Completed:   2026-08-10
Source:      Found 2026-08-10 running the pre-migration baseline
             for Onboarding Direction B stage 1

Description: zyra_guard_suite.sql failed at check 17 with
             "permission denied for table zyra_guard_results".

             CAUSE. AREA 4 measures Guardian visibility THROUGH
             RLS, which requires set_config('role',
             'authenticated'). Under that role the DO block is no
             longer the table owner, so its inserts into the
             results table were refused. The 2026-08-08 hardening
             pass enabled RLS on that results table and removed
             the grant as "left over from a set role the suite no
             longer does" — but the suite does still switch role,
             in the one area that cannot work any other way.

             The grant was not the fix either. With RLS enabled
             and zero policies the insert is refused on the
             policy check regardless of privilege. Verified
             empirically rather than argued: grant restored,
             0 rows written.

             So the 55/55 recorded on 2026-08-08 predates the
             hardening in the same file, and every migration
             since — thirteen on 2026-08-10 alone — was applied
             without the gate CLAUDE.md requires. Those thirteen
             have now been checked retrospectively: both suites
             pass, so nothing was actually broken. That is luck
             confirmed, not a reason to relax the gate.

             FIX. AREA 4 measures under the role into local
             variables and writes results after restoring
             role=postgres. Same assertions, same roles, same
             coverage; only the write moves.

             SECOND DEFECT, SAME RUN. Teardown checks asserted
             whole tables were empty — guard 54/55, journey
             57/58. So a suite reported failure whenever ANY
             unrelated row existed, including a developer's own
             test Journey. They measured the database, not the
             suite. Now scoped: guard 54 to its own match id, the
             rest against a baseline captured before the scenario
             is built.

             RESULT AFTER FIX, 2026-08-10:
               zyra_guard_suite    52/52
               zyra_journey_suite  63/63

             LESSON, RECORDED BECAUSE IT WILL RECUR: a hardening
             pass that touches a test's own scaffolding needs the
             test RE-RUN, not just re-read. The comment left
             behind asserted the opposite of what the file did,
             and it was believed for two days because it was
             plausible.

------------------------------------------------------------

OA-ZYRA-188
Title:       H4 Conditional Branching Saves Almost Nothing — All
             Four Proposed Rules Describe Questions That Do Not
             Exist
Category:    Onboarding / Product
Priority:    Low as a defect, Medium as a decision — it changes
             what Direction B is worth
Status:      CLOSED 2026-08-10 — Founder decision: one branch is
             enough. The two candidate rules are REJECTED, and
             the reasoning below stands as the record of why
Owner:       Founder (Shakeel)
Raised:      2026-08-10
Completed:   —
Source:      Found 2026-08-10 implementing Direction B stage 3,
             on checking the UX review's branching rules against
             the real 104 questions rather than against the
             review's description of them

Description: ZYRA_ONBOARDING_UX_REVIEW_2026-08-05_V1.md §H4
             claimed conditional branching would remove "15-25%
             of items per user with zero information loss", and
             listed four rules as "available immediately in the
             existing data". Checked against
             chapter3_categories.dart, all four are wrong:

             1. "ch3_q1 = Never Married -> skip divorce/widow
                follow-ups." THERE ARE NO SUCH FOLLOW-UPS. No
                question in the set depends on marriage status.

             2. "ch3_q2 = No children -> skip custody and
                living-arrangement follow-ups." Custody and
                living arrangement are OPTIONS OF ch3_q2 ITSELF
                ('Yes, shared custody', 'Yes, living
                elsewhere'), not separate questions.

             3. "ch3_q17 = Not studying -> skip study-related
                items." Nothing in Education & Finances depends
                on ch3_q17.

             4. "ch3_q6 = No preference / Same country ->
                suppress the in-law proximity follow-up."
                ch3_q6 is about YOUR parents; ch3_q9 is about
                living with YOUR IN-LAWS. Different people.
                Suppressing q9 would lose real signal.

             The review was written against an assumed question
             set. Its structural argument still stands; this
             particular saving does not exist.

             WHAT IS ACTUALLY THERE. One rule meets the bar
             ("asking this would be nonsense"):

               ch3_q3 = No (wants no children)
                 -> skip ch3_q24, "when would you ideally like
                    to start a family?"

             Built and shipped 2026-08-10. Saves 2 screens (Ch3
             + its Ch4 counterpart) for the subset who answer
             No. Not 15-25%.

             ALSO REJECTED, AND WHY, so nobody re-proposes them:
             - ch3_q20 'No debt' -> skip ch3_q21 'mortgage?'.
               Looks implied, is not: q21's third option is
               'Planning to in the future', which is perfectly
               compatible with having no debt today.
             - ch3_q3 = No -> skip ch3_q29 (homeschooling) and
               ch3_q48 (children's Islamic education). Defensible
               but NOT mechanical — someone who wants no children
               of their own may marry someone who has them, and
               the Chapter 4 counterparts ask what they want in a
               PARTNER. This is a product judgement, so it is
               here rather than in the code.

             WHAT WAS BUILT ANYWAY. ShowIf on OnboardingQuestion
             — declarative (a question id plus the answers that
             hide it), deliberately not a predicate function, so
             rules can be listed and argued about without running
             the app. The flow rebuilds its step list on every
             Chapter 3 answer and DISCARDS answers, preferences
             and hard requirements belonging to questions that
             are no longer visible; otherwise a changed mind
             leaves a stored preference on a screen the Seeker
             can no longer see, and score_candidates() goes on
             matching against it.

             FOUNDER DECISION 2026-08-10: neither rule is added.
             One branch is all this question set supports. A
             Seeker who wants no children of their own may still
             marry someone who has them, and the Chapter 4 side
             of both questions asks what they want in a PARTNER —
             so skipping them loses real signal to save four
             screens. ShowIf stays in place for any future rule
             that clears the bar in its doc comment.

             HOUSEKEEPING DONE IN THE SAME PASS:
             OnboardingCategory.ch4Questions was deleted. It had
             no callers and filtered on ch4Status alone — the
             moment showIf existed it would have shown women the
             men-only Masjid question and asked people who want
             no children when they plan to start a family.

------------------------------------------------------------

OA-ZYRA-189
Title:       Direction B Quick Wins — Two Built, One Already
             True, Two Recommended Against With Numbers
Category:    Onboarding / Product
Priority:    Low — closes out Direction B. Two items need a
             Founder yes/no or the list stays half-open
Status:      Open — awaiting Founder decision on items 3 and 5
Owner:       Founder (Shakeel)
Raised:      2026-08-10
Completed:   —
Source:      ZYRA_ONBOARDING_UX_REVIEW_2026-08-05_V1.md §4
             "Quick Wins", worked through 2026-08-10

Description: The review listed five quick wins. Measured against
             the live flow, they are not five pieces of work.

             1. ENABLE CONTINUE WITH PARTIAL PREFERENCES — DONE,
                as part of H1. The `allAnswered` gate is gone and
                all-red warns instead of blocking.

             2. CATEGORY-LEVEL PROGRESS — DONE. The subtext under
                the question now reads "Family · 4 of 10" rather
                than "Family". Counted from the VISIBLE list, so
                a branched-away question neither leaves a gap in
                the numbering nor inflates the total. Categories
                run 8 to 19 questions, so the next finish line is
                always in sight — which is the point, because
                chapter-level progress alone tells someone they
                are 30% through 175 questions.

             3. BATCH 4-5 SHORT FACTUAL ITEMS PER SCREEN —
                RECOMMENDED AGAINST. The review estimated "~40
                fewer Continue taps". Measured, the real figure
                is about 8.

                Batching only works within a category, because
                each category ends in its own summary. The
                contiguous administrative facts are: Education &
                Finances 7 (education, income, savings, studying,
                Mahr, debt, mortgage) -> 2 screens, saves 5;
                Health 3 (dietary, medical, disabilities) -> 1
                screen, saves 2; Umrah + Hajj -> 1 screen, saves
                1. Everything else the review named is a values
                or attitude question, which it agrees should stay
                one per screen. Siblings and Mahr sit alone in
                their categories and batch with nothing.

                Eight taps out of the 193 that remain after H1.
                Against that: _FlowStep becomes one-to-many, a
                new batched-question widget appears, and three
                things in the approved screen anatomy break — the
                per-screen privacy indicator, the help sheet
                (which builds "Why do we ask for your
                {question}?" from the single heading), and the
                category summary's tap-to-edit, which would land
                the Seeker on a screen holding four questions
                instead of the one they wanted to change.

                The taps were worth removing when there were 325
                of them. At 8, the structural cost is higher than
                the win. RAISED RATHER THAN BUILT — if the
                Founder wants it anyway, the Education & Finances
                block alone is the defensible subset (5 taps, one
                widget, one call site).

             4. ORDER CATEGORIES CONCRETE-FIRST — ALREADY TRUE.
                The live order is Family, Education & Finances,
                Marriage Goals, Faith, Lifestyle, Household
                Roles, Communication, Technology, Health. The
                review's recommendation ("Family, Education,
                Marriage Goals first") is exactly what is built.
                Its §7 also states that Faith "sits in the back
                half"; Faith is 4th of 9. No change made, and
                none needed.

             5. PRE-POPULATE INCOME/EDUCATION PREFERENCE FROM THE
                OWN ANSWER — RECOMMENDED AGAINST, ON SCOPE. This
                is H2 in miniature, and H2 is explicitly not
                approved. It also now conflicts with what shipped:
                under tap-to-exclude every option rests at 🟢, so
                pre-populating means machine-authoring 🟡 on
                bands the Seeker never touched — a stated
                preference nobody stated. That is the exact
                dishonesty H1 was built to remove, reintroduced
                one question later.

                If derive-and-confirm is wanted, it should arrive
                as H2 with its own spec and DR, where the
                deviation signal is the point and the pre-fill is
                presented as ZYRA's proposal rather than as the
                Seeker's answer.

             TO CLOSE: a yes/no on 3 and 5.

------------------------------------------------------------

OA-ZYRA-190
Title:       Delete Every is_synthetic Row Before Public Launch
Category:    Pre-Launch / Data Integrity
Priority:    BLOCKING for public launch. Harmless while the
             database holds only seeded accounts
Status:      Open — raised 2026-08-10
Owner:       Founder (Shakeel) confirms the launch gate; Opus
             executes
Raised:      2026-08-10
Completed:   —
Source:      Founder decision 2026-08-10 to seed Chapter 3/4
             "full synthetic, clearly labelled". This is the
             other half of that instruction

Description: The database now contains 144 Seekers with complete
             but INVENTED Chapter 3 and Chapter 4 answers, and
             144 with invented Chapter 2 details.

             Chapter 2 can at least be checked: it was built to
             Census 2021 and the Techne/IIFL denominational
             survey. CHAPTER 3 CANNOT. Those are values — there
             is no census for "how involved should your parents
             be during your marriage". The answers and the
             preference maps came from a deterministic hash and
             an assortative decay rule that I chose.

             THE RISK IS NOT THE DATA, IT IS WHAT GETS BUILT ON
             IT. A compatibility engine tuned until these scores
             "look right" is tuned to an invention. The measured
             spread — 77 to 100, mean 86.3 — is a property of my
             decay rule, not of any real population.

             WHAT MARKS IT:
               onboarding_answers.is_synthetic   (144 rows)
               seeker_details.is_synthetic       (144 rows)
             Both default FALSE, so a real Seeker can never be
             caught by the sweep. Partial index on each.

             ALSO TO DROP: zyra_seed_ch4_questions and
             zyra_seed_answers — scaffolding tables holding the
             question catalogue transcribed from
             chapter3_categories.dart and the intermediate
             answer picks. Both RLS-enabled with grants revoked.

             NOTE THE STALENESS HAZARD: zyra_seed_ch4_questions
             is a TRANSCRIPTION of a Dart file. If the questions
             change and the seed is re-run, it will write answers
             against option strings that no longer exist, and
             score_candidates() will silently match nothing —
             absent answers are neutral, so it fails quiet.
             Regenerate the catalogue before any re-seed.

             TO CLOSE: delete where is_synthetic, drop the two
             scaffolding tables, then assert both tables are
             empty of synthetic rows. Do it in the same sweep as
             OA-ZYRA-184's nine dev RPCs — same gate, same day.

------------------------------------------------------------

OA-ZYRA-191
Title:       Build and Verify Direction B on Device — A Full Day
             of Dart Has Never Been Compiled
Category:    Verification / Build
Priority:    HIGH. Nothing after this can be trusted until it is
             done. Not urgent in the sense of risk to live users
             — there are none — but every hour of further work
             stacks on an unverified base
Status:      Open — raised 2026-08-10, Founder to run
Owner:       Founder (Shakeel). CANNOT be delegated to Opus —
             see "why" below
Raised:      2026-08-10
Completed:   —
Source:      Founder request 2026-08-10 to record the build as an
             action after the tooling proved unreachable

Description: Onboarding Direction B shipped across six Dart files
             on 2026-08-10 and NONE of it has been through a
             compiler.

             THE COMMAND (one line, profile mode, per the
             standing rule — never plain `flutter run`):

               cd "/Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE" && ./run.sh

             WHY OPUS CANNOT DO THIS, recorded so it is not
             re-litigated every session:
               * `device_bash` is an isolated Linux VM with the
                 DEVELOPMENT folder mounted. No macOS, no Xcode,
                 no Flutter, no iPhone.
               * The cloud container has no Flutter and its
                 network is locked down — storage.googleapis.com,
                 pub.dev and github all return 403, so the SDK
                 cannot be installed.
               * Computer-use resolves Terminal at 'click' tier:
                 it can see and left-click, but CANNOT type,
                 press keys or paste. That restriction covers all
                 terminals and IDEs and is deliberate.
             Every route to a shell on the Mac is closed. The
             build is a Founder action, permanently.

             WHAT WAS DONE INSTEAD. A 30-point static
             cross-check of the six changed files: every
             construction site of TrafficLightQuestionScreen
             passes the new API; the Set-typed hard-requirement
             callback is never handed a bool; Chapter 2's
             adapter is present and Chapter 2 correctly does NOT
             opt into tap-to-exclude; the persistence service
             signature matches what the flow passes; ShowIf is
             reachable from the question catalogue; the deleted
             ch4Questions getter has no live callers. 30/30.
             That is not a compiler and does not claim to be.

             THE TWO LIKELY FAILURE POINTS:
               1. chapter3_categories.dart ~line 174 —
                  `showIf: const ShowIf('ch3_q3', notAnyOf:
                  ['No'])` sits inside a const List. If Dart
                  objects to the const construction it fails
                  here, at compile time.
               2. traffic_light_question_screen.dart ~line 143 —
                  the addPostFrameCallback that seeds the resting
                  greens. This will NOT fail to compile; it would
                  fail at runtime on the first Chapter 4 screen
                  if the deferral is wrong.

             MANUAL CHECKS ONCE IT RUNS — each maps to something
             built today that no test covers:
               a. Walk one Chapter 4 question. Every option
                  should already be 🟢 and Continue should be
                  live without touching anything.
               b. Mark two options 🔴 on the same question. Each
                  should grow its OWN "Never introduce anyone
                  who answered X" checkbox. Tick one only. That
                  pair — one hard, one soft — was impossible
                  before today and is the whole point of the
                  reshape.
               c. Mark EVERY option 🔴. It should warn and still
                  let you continue. It used to silently disable
                  the button.
               d. Answer "No" to wanting children, then look for
                  the family-timing question. It should be gone,
                  and the category counter should read one lower.
               e. SUPERSEDED THE SAME EVENING. This said Chapter
                  2's sect matrix should still show ONE checkbox,
                  because the difference was deliberate. OA-ZYRA-185
                  was then approved and built, so Chapter 2 now
                  matches Chapter 4: the sect matrix should show
                  one "Never introduce anyone who answered X" per
                  🔴 sect, NOT a single question-wide checkbox.
                  If you see one checkbox, the build is stale.
               f. Profile Unlock, after unlocking: an amber dot
                  and "Example figures. The same for every profile
                  until real scoring is switched on." sits under
                  the 81% (OA-ZYRA-192).
               g. Category progress: the line under each question
                  should read "Family · 4 of 10", not just
                  "Family" (OA-ZYRA-189).

             THEN COMMIT. Roughly 45 changed files plus three
             migrations, two documents and seven register
             entries, none of it under version control.

             NOTE ON GIT, found the hard way 2026-08-10: git run
             through the Cowork device bridge cannot unlink its
             own lock files, because the mount forbids deletion.
             A `git status` from that side leaves a
             .git/index.lock that blocks every later git command.
             One sat there from 08:44 to 16:32 and silently broke
             all committing for eight hours. RUN GIT FROM THE MAC
             TERMINAL, never through Claude. Two stale locks were
             moved to `_to_delete/` and that folder can be binned.

------------------------------------------------------------

OA-ZYRA-192
Title:       Compatibility Unlock Charges a Real Credit and
             Shows Everyone the Same Invented 81%
Category:    Product Integrity / Premium
Priority:    HIGH. No real users today, so no one has been
             charged for it yet — but this is a PAID screen
             showing a made-up number with nothing saying so,
             and the reason it was acceptable expired on
             2026-08-10
Status:      Open — step 4 done 2026-08-10 (marker restored),
             steps 1-3 outstanding
Owner:       Founder (Shakeel) rules on presentation; Opus wires
             the number
Raised:      2026-08-10
Completed:   —
Source:      Found 2026-08-10 checking what the Chapter 2/3/4
             backfill had unblocked, per the persistence audit's
             dependency list

Description: profile_unlock_screen.dart shows a hardcoded
             `_Sample.overall = 81` and six hardcoded category
             bars — Lifestyle 74, Work & Education 78, Family
             Values 85, Marriage Goals 88, Personality 69,
             Deen 92 — for EVERY profile, every time. The file
             never calls score_candidates(); its only async work
             is balances, Guardian info, and the unlock
             transaction itself.

             The transaction IS real. zyra_unlock_profile() runs,
             a credit is spent, a profile_unlocks row is written.
             So a Seeker pays, and is shown a number that is the
             same for every person they will ever unlock.

             The on-screen SAMPLE banner was removed 2026-08-03
             at Founder instruction ("remove the yellow sample
             banner"). At the time that was reasonable — it was a
             mockup being reviewed. Nothing now marks it.

             WHY THIS IS NEW TODAY, AND NOT AN OLD KNOWN GAP.
             ZYRA_ONBOARDING_PERSISTENCE_AUDIT §5 listed Profile
             Unlock as "cannot produce a real number. Currently
             shows sample data, marked. KEEP PAUSED." That was
             correct: onboarding_answers had zero rows. As of
             2026-08-10 it has 144, seeker_details has 144, and
             score_candidates() returns real per-pair numbers —
             ALREADY CONSUMED by two live call sites:
               zyra_discovery_service.dart:215   (Browse)
               zyra_journey_service.dart:350     (Journey reveal)
             So the app computes a real score in two places and
             shows a constant in the one the Seeker pays for.
             The pause condition is gone; the pause remains.

             A SECOND MISMATCH, WORTH FIXING IN THE SAME PASS.
             The sample's own header documents the weighting it
             was built to satisfy: green=1, amber=0.5, red=0,
             over 88 counted items. The live engine uses
             green=2, yellow=1, red=-3, scaled so the output
             CENTRES ON 50 and runs 0-100. Those are different
             scales, not just different numbers. Before the
             screen shows a real figure, someone has to answer
             what a percentage MEANS to the Seeker — 81% on a
             0-100 count basis reads very differently from 81%
             on a scale where 50 is "we know nothing about you".

             Related: the measured distribution after seeding
             puts real scores between 77 and 100 with a mean of
             86.3 (see ZYRA_CHAPTER2_BACKFILL_AND_WEIGHT_
             FINDINGS_2026-08-10.md §6a). If that holds for real
             users, almost every unlock will read 80-95, and a
             Seeker who pays twice will see near-identical
             numbers. That is a pricing and expectation problem
             as much as an engineering one — but note the caveat
             in that document: the spread is a property of
             synthetic preference data, not of real people.

             ALSO STILL UNBUILT: the category breakdown. The six
             bars are the whole value proposition of Unlock+, and
             score_candidates() does not expose per-category
             detail at all — journey_flow_screen.dart:38 already
             records this. Unlock+ cannot be honest until the
             function returns a breakdown.

             TO CLOSE, in order:
               1. Founder rules on what a % means to the Seeker.
               2. Extend score_candidates() to return per-category
                  totals (Unlock+ depends on it; Unlock does not).
               3. Wire the screen to the real number.
               4. DONE 2026-08-10 — marker restored, Founder chose
                  option A of three shown.

             STEP 4 AS BUILT. `_SampleMarker` in
             profile_unlock_screen.dart, rendered inside
             _OverallResult directly beneath the figure so the
             number cannot be read without the qualifier:

               "Example figures. The same for every profile until
                real scoring is switched on."

             The second sentence is the one that matters.
             "Example figures" alone reads as "not final"; the
             actual defect is that 81% is IDENTICAL FOR EVERY
             PROFILE, so without saying so a Seeker takes it as a
             fact about this particular person.

             Not a banner — the same idiom as the onboarding
             privacy indicator (6px dot, plain text, no card, no
             box), reusing ZyraColors.unlockDot / unlockText and
             ZyraText.privacyText so it moves with the palette.
             That answers the 2026-08-03 objection to the yellow
             banner without leaving the screen unmarked.

             STILL OPEN AND NOT COVERED BY THE MARKER: the
             _Detail section (three tallies + six category rows)
             is a separate widget further down the page and
             carries no marker of its own. One marker under the
             headline was what was approved; if the detail can be
             scrolled to without the headline in view, it needs
             its own. Worth checking on device during OA-ZYRA-191.

             THE MARKER IS A HOLDING MEASURE. Delete _SampleMarker
             when step 3 lands.

------------------------------------------------------------

OA-ZYRA-193
Title:       The Compatibility Scoring METHOD Has Never Been
             Agreed — Two Different Ones Are Already Live
Category:    Product / Compatibility Engine
Priority:    HIGH as a decision. Nothing is broken, but every
             number the product shows rests on a method nobody
             ratified, and two parts of the app disagree about
             what it is
Status:      PARTIALLY RESOLVED (a)(a2)(b)(c) 2026-08-11 —
             Founder decided from his phone. (d) and (e) remain
             Open. Originally raised because the Founder called
             for it 2026-08-10: "if you're setting a score system
             we gotta talk about that soon"
Owner:       Founder (Shakeel) — this is a product decision, not
             an implementation one
Raised:      2026-08-10
Completed:   —
Source:      Founder declined to set v_ch2_weight on 2026-08-10,
             correctly, on the grounds that the weight is a dial
             on a machine that was never agreed

Description: THE FOUNDER IS RIGHT AND THIS SHOULD HAVE BEEN
             RAISED FIRST. v_ch2_weight was offered as a
             decision. It is a parameter of a scoring method
             that has never been approved — tuning it would have
             ratified the method by the back door.

             ZYRA_DECISIONS_CURRENT_VERSION_V2 §10 has said
             "Compatibility scoring. Method undefined." since it
             was written. That is still true, and meanwhile TWO
             DIFFERENT METHODS have appeared in the product:

             1. score_candidates(), live and consumed by Browse
                curation and the Journey reveal:
                  green +2, yellow +1, red -3
                  score = (total / max) x 50 + 50
                So the scale runs 0-100 but CENTRES ON 50, and 50
                means "we know nothing about you", not "half
                compatible". A red answer costs more than a green
                one earns — deliberate, never ratified.

             2. profile_unlock_screen.dart's sample figures,
                whose own header documents the weighting they
                were built to satisfy:
                  green 1, amber 0.5, red 0, over 88 items
                A plain 0-100 count. No centring, no penalty.

             These are not different numbers, they are different
             SCALES. 81% under (2) and 81% under (1) describe
             quite different pairs of people.

             WHAT NEEDS DECIDING, roughly in order:

             a. WHAT DOES THE PERCENTAGE MEAN to a Seeker? Is 50
                the floor of the scale or its middle? Should a
                number below 50 be possible at all?
             a2. WHOSE NUMBER IS IT? Found 2026-08-10 while
                testing the Reveal on the live seeded pair:
                score_candidates() is ASYMMETRIC, because each
                person is scored against the OTHER's
                preferences. Yusuf scores Aisha 84.5%; Aisha
                scores Yusuf 88.2%. Same two people, same data,
                two different numbers.

                The Reveal shows ONE. Which one is an accident
                of sequence: revealCompatibility() computes and
                stores the score when the SECOND person reveals,
                from that person's perspective. So the "shared"
                compatibility of a couple depends on who happened
                to press the button last, and the pair sees a
                number that is true for one of them and not the
                other.

                Options: show each Seeker their own figure (two
                private numbers, no shared one); average them;
                take the lower; or define a genuinely symmetric
                measure. This is not a bug to patch — it is the
                same question as (a), asked about a pair rather
                than a person, and it should be answered with the
                rest of the method.
             b. SHOULD A RED COST MORE THAN A GREEN EARNS?
                Currently -3 against +2. That is a moral position
                about how much a dealbreaker-adjacent mismatch
                should hurt, expressed as a constant.
             c. WHAT COUNTS AS 100%? Today it means every scored
                answer was green — achievable and, on the seeded
                data, achieved by 48% of pairs. If nearly half of
                everyone is "100% compatible", the number stops
                meaning anything.
             d. HOW MANY CATEGORIES, AND WHICH? The Unlock+
                screen shows six (Lifestyle, Work & Education,
                Family Values, Marriage Goals, Personality, Deen)
                and onboarding has nine, and they do not map onto
                each other. score_candidates() returns no
                category detail at all.
             e. ONLY THEN v_ch2_weight — how much sect and
                ethnicity should move a number whose meaning is
                settled.

             DO NOT TUNE ANY OF THIS ON THE SEEDED DATA. The 144
             Chapter 3/4 rows are synthetic (OA-ZYRA-190) and the
             measured spread — 77 to 100, mean 86.3 — is a
             property of the assortative decay rule used to
             generate them, not of any real population. Point (c)
             above is exactly the kind of question that data
             CANNOT answer.

             BLOCKED (now cleared for a/a2/b/c): OA-ZYRA-192
             steps 1-3 (wiring the real number into the paid
             Unlock screen) and the open v_ch2_weight decision in
             CLAUDE.md.

RESOLVED (a)(a2)(b)(c) 2026-08-11 — Founder, by phone.

             (a) 0-100 PLAIN COUNT. green 1, amber 0.5, red 0,
                 over the items actually scored. The +50 centring
                 is retired. It computed something defensible and
                 communicated something false: nobody reads "50%"
                 as "no data". This also ends the two-methods
                 problem in the Founder's favour — the Unlock
                 screen's figures were always built on exactly
                 this weighting.

             (b) NO. Settled by (a) rather than decided
                 separately: a plain count has no penalty term.
                 The -3 is gone. The moral position it encoded is
                 not abandoned — it moves to Hard Requirements,
                 which exclude outright and are already tested
                 before and independently of the lights. An
                 exclusion is a promise; a light is a preference.

             (a2) TWO SCORES, ONE EACH. Founder's own words: "I
                 see my compatibility with her, and she sees her
                 compatibility with me." No shared number.
                 Removes the sequencing defect as a side effect:
                 the single figure used to be computed by
                 whichever party revealed SECOND, so a couple's
                 "shared" compatibility depended on who tapped
                 last.

             (c) NO MINIMUM-ITEMS RULE — the premise was
                 rejected, correctly. Founder: "No answer is
                 optional." There is no thin profile to design
                 around, because a thin profile should not be
                 matchable. Becomes an ONBOARDING COMPLETENESS
                 GATE on entering the pool, which composes with
                 Direction B rather than fighting it: Direction B
                 says do not invent preferences for screens the
                 Seeker never saw; this says they must see every
                 screen. Together — every question is answered,
                 and every answer is real.

                 THE GATE WAS BUILT THE SAME DAY. See below.

             THE GATE, BUILT 2026-08-11:

               profiles.onboarding_complete, maintained by three
               triggers and backfilled, required by
               zyra_can_view_profile clause 4 (browsing, BOTH
               parties) and zyra_can_match.

               Clauses 1-3 are deliberately NOT gated: yourself
               (you must be able to see your own profile while
               fixing it), your Guardian or ward (a family
               relationship does not lapse over three questions),
               and the other Seeker in a shared attempt (a
               running Journey must not half-disappear because a
               profile changed underneath it).

               MATERIALISED, not computed in the policy:
               zyra_can_view_profile is the USING clause of
               profiles_select and runs per row on every profile
               read in the app. Walking the 72-row question bank
               there would have been a cost nobody found until
               Browse got slow for no visible reason.

             ⚠️ THE FIRST ATTEMPT WAS WRONG AND WAS CAUGHT BY
             MEASURING BEFORE ENFORCING. "Every question in the
             bank" excluded 38 of 144 seeded Seekers. They were
             not incomplete: all 38 had answered "No" to ch3_q3
             (do you want children) and had correctly never been
             shown ch3_q24 (when). Enforcing it would have
             removed 26% of the population from Browse for
             answering honestly.

               ch3_q3 = 'Yes'             68 seekers, 68 answered q24
               ch3_q3 = 'No'              38 seekers,  0 answered q24
               ch3_q3 = 'If Allah wills'  30 seekers, 30 answered q24
               ch3_q3 = 'Unsure'           8 seekers,  8 answered q24

             The cause: applicability is gender AND a conditional
             rule, and the conditional half (showIf) lived only in
             Dart. The server held half a rule and did not know
             it. Both halves are now in
             zyra_onboarding_questions.

             AFTER THE FIX: 144 of 144 pass, all six dev accounts
             pass, nobody is locked out. Verified live that an
             incomplete Seeker drops from 69 browsable men to 1 —
             their Journey partner, via the clause-3 exemption —
             and can neither view nor match, while still seeing
             themselves and their Journey partner.

             BUILT THE SAME DAY (2026-08-11):
               - zyra_light_weight() replaces zyra_light_points(),
                 which was dropped rather than left dormant
               - score_candidates() rewritten to the plain count;
                 returns NULL rather than a neutral 50 when it
                 cannot score, and NULL-array guarded
               - journey_compatibility: seeker_a_score /
                 seeker_b_score / _categories added,
                 overall_score and category_scores DROPPED so a
                 stale client fails closed rather than showing a
                 retired-scale number
               - zyra_compatibility_for_plus() and
                 zyra_dev_set_compatibility() rewritten
               - revealCompatibility() computes only the caller's
                 own figure, on their own reveal
               - Compatibility Unlock shows the real number; the
                 sample marker MOVED to the category breakdown,
                 which is still a constant pending (d)
               - Browse ordering made NULL-tolerant: unscored
                 candidates rank last rather than crashing the
                 sort into its catch block

             MEASURED AFTER THE CHANGE, same seeded pool:
               Yusuf->Aisha  84.5 -> 75.0
               Aisha->Yusuf  88.2 -> 78.3
               population    77-100 mean 86.3 -> 70.7-82.7 mean 76.4
               at 100%       48% of pairs -> NONE
               unscoreable   0

             The 48%-score-100% worry in (c) above did not
             survive contact with the real question bank, exactly
             as predicted: it was an artefact of only ~8 questions
             being scored. With ~70 Chapter 4 questions in play,
             no pair in the seeded population is all-green.

             STILL OPEN: (d) categories, (e) v_ch2_weight.

------------------------------------------------------------

OA-ZYRA-194
Title:       Active Journey — Put "View Full Profile" Inside the
             Journey Too, and Rename the Enter Pill
Category:    UX / Active Journey
Priority:    Medium — small build, but the rename touches a
             vocabulary that is becoming a set and should be
             decided as one
Status:      ACTIONED 2026-08-10 — Founder ruled and it was built
             the same evening. ONE OBSERVATION LEFT OPEN, below
Owner:       Founder (Shakeel) rules on wording; Opus builds
Raised:      2026-08-10
Completed:   —
Source:      Founder, 2026-08-10: "in active journey where we put
             view profile at top timeline put it in the enter
             section also, and change enter into enter journey or
             continue journey"

Description: TWO CHANGES, one mechanical and one that needs a
             wording decision.

             1 · VIEW FULL PROFILE INSIDE THE JOURNEY.
             journey_timeline_screen.dart line 117 renders a
             _TimelineBubble labelled "View full profile" that
             pushes SeekerProfileScreen. It exists only there.
             journey_flow_screen.dart — the Enter destination —
             already holds the same SeekerProfile object and
             passes it to _JourneyAppBar, so the route is a few
             lines; nothing new needs fetching.

             The open question is WHERE it sits. The Journey flow
             is a staged ritual and the app bar is the only
             persistent furniture on it, so the natural home is
             the app bar rather than a bubble competing with the
             stage content. That is a judgement, not a
             requirement — Founder to confirm placement when it
             is built.

             2 · RENAME THE ENTER PILL.
             connections_screen.dart line 2332 renders
             `label: 'Enter'` on the Active Journey card, beside
             "View timeline" (line 2339). Founder asked for
             "Enter Journey" or "Continue Journey".

             THIS IS NOT A ONE-WORD CHOICE, and it is why this is
             an OA rather than a two-minute edit. The pill is one
             of a set that now reads:

               Potential Journey  ->  "Start Journey"
               Active Journey     ->  "Enter"
               Paused Journey     ->  "Resume"
               Peer-paused        ->  "Waiting"
               Ended Journey      ->  "Request New Journey"

             Adding "Continue Journey" puts it next to "Resume",
             and those two are close enough to blur: Resume means
             un-pause, Continue would mean carry on. A Seeker
             glancing at Connections should not have to work out
             the difference.

             OPTIONS:
               a. "Enter Journey" always. Consistent with "Start
                  Journey", keeps Resume unambiguous, one string.
               b. Contextual — "Enter Journey" the first time,
                  "Continue Journey" afterwards. Warmer, and the
                  card already carries the stage as a sublabel so
                  there is precedent for context. Needs a rule
                  for "first time" — cheapest honest proxy is
                  whether the Journey has moved past its opening
                  stage, since there is no per-user "have they
                  opened this" flag today.
               c. "Continue Journey" always. Simplest, but wrong
                  on the very first entry and adjacent to Resume.

             OPUS'S READ, offered not decided: (a). The set gains
             more from Start/Enter/Resume staying three distinct
             words than it loses from missing a warmer second
             label — and (b) buys that warmth with a new piece of
             state to keep true.

             FOUNDER DECISION 2026-08-10, and it went further
             than the question asked. As built:

               * Primary pill is CONTEXTUAL — "Begin Journey"
                 until the Journey moves, "Continue Journey"
                 after. Neither of the two wordings offered; the
                 Founder picked "Begin", and contextual over
                 fixed. No new state: a Journey still on its
                 opening stage has not begun, so the label reads
                 off journey_stage and there is no
                 has-been-opened flag to drift.
               * The stage SUBLABEL is gone — "I don't want enter
                 open conversation in smaller text". This
                 reverses the Timeline spec §12 option C ruling
                 from earlier the same day, which had put the
                 stage on the control leading to it. stageLabel
                 came off _ActiveJourneyCard and sublabel off
                 _CardPill rather than being left unread.
               * "View timeline" -> "Timeline".
               * Pills are 2 : 1, Journey to Timeline. Equal
                 widths claimed they were equal choices.
               * THE WHOLE-CARD TAP IS REMOVED. Founder:
                 "wherever I click goes into enter journey but
                 that ruins the enter journey button." Correct —
                 a card-wide tap makes the primary pill
                 decorative and the secondary one a trap, because
                 everything around "Timeline" silently does
                 something else. Only the two pills act now.
               * View profile sits in the Journey's 3-dot menu,
                 first, above Pause and End.

             STILL OPEN — A VOCABULARY COLLISION, raised not
             fixed. The Journey action words now read:

               Potential  ->  "Start Journey"
               Active, not yet moved  ->  "Begin Journey"
               Active, moving         ->  "Continue Journey"
               Paused                 ->  "Resume"

             Start and Begin are synonyms doing two different
             jobs one section apart. The original worry was that
             "Continue" would blur with "Resume"; it does not —
             but Start/Begin does. Options: rename Potential to
             "Request Journey" or similar, or drop "Begin" and
             let an unmoved Active Journey say "Enter Journey".
             Founder's call, and nothing is broken meanwhile.

             VERIFY ON DEVICE (add to OA-ZYRA-191): tapping the
             card body does nothing; the two pills are the only
             actions; the primary reads Begin before the Journey
             moves and Continue after; the 3-dot menu opens the
             full profile.

------------------------------------------------------------

OA-ZYRA-195
Title:       ZYRA One Should Allow Three Active Journeys — Which
             Contradicts a Named Product Principle and Six
             Enforcement Points
Category:    Product / Journey Architecture
Priority:    HIGH as a decision. Nothing is broken; the request
             simply cannot be built as a data change and must not
             be done as a quiet loosening
Status:      Open — Founder stated the intent 2026-08-10 while
             setting up test accounts
Owner:       Founder (Shakeel) — product decision; then Opus
Raised:      2026-08-10
Completed:   —
Source:      Founder, 2026-08-10: "1 for basic, one for male one
             for female, and 3 for ZYRA One, 3 male 3 female",
             then confirmed when asked: "ZYRA One should allow 3
             Active"

Description: ONE ACTIVE JOURNEY IS NOT A LIMIT SITTING IN ONE
             PLACE. It is a named product principle — OA-ZYRA-133,
             "Active Journey System Proposal: One Active Journey"
             — and it is enforced in SIX independent places, none
             of which check the plan:

               promote_journey_to_active
               zyra_enforce_one_active_match      (trigger)
               zyra_enforce_one_active_attempt    (trigger)
               request_new_journey
               respond_to_journey_request
               restart_journey                    (retired, but
                                                   carries the rule
                                                   in comments)

             The journey regression suite asserts the refusal
             twice — checks 11 and 12, one for the RPC route and
             one for a direct UPDATE, because audit R7 found that
             with ids ordered a < b < c one person could be
             seeker_a on one Journey and seeker_b on another.

             So this is not a config value. Making it three is a
             change to what ZYRA IS, and the questions it opens
             are product ones, not engineering ones:

             a. WHAT IS THE PRINCIPLE NOW? "One Active Journey"
                was the answer to a real problem: a matrimonial
                app where people talk to five prospects at once
                is the thing ZYRA was positioned against. Three
                is still a cap, but it is a different promise and
                the marketing and onboarding copy both state the
                current one.
             b. WHAT HAPPENS ON DOWNGRADE? A ZYRA One member with
                three Active Journeys who stops paying. Which two
                end? Do they choose? Does anyone tell the other
                party, and what are they told — a downgrade is
                nobody else's business.
             c. THE GUARDIAN LOAD. A Main Guardian already sits in
                the Family Review gate for each Journey, with a
                48-hour window. Three concurrent Journeys per ward
                is three times the review burden, and a Guardian
                with two wards could face six.
             d. TIER-1 AND THE MATCHING EXCLUSIONS. zyra_can_match
                and the shared-Guardian rules assume a single
                live Journey per person in places. Each needs
                re-reading before the cap moves.
             e. PAUSE. Journey Suspension is a ZYRA One feature
                and pauses "the" Journey. With three, pause needs
                to name one.

             DELIBERATELY NOT DONE TONIGHT. The Founder's actual
             need was to test the Journey, and that is unblocked
             another way: all four test accounts now have one real
             Active Journey each (see below). Loosening a
             six-point invariant at the end of a long session, to
             make test data match an expectation, is how a
             principle gets lost by accident.

             TO CLOSE: answer (a) first — it decides whether the
             rest is worth costing. If yes, this needs a DR and a
             staged plan, and the journey suite's checks 11/12
             must be rewritten to assert the NEW rule rather than
             deleted.

             WHAT WAS DONE INSTEAD, 2026-08-10: the two Basic test
             accounts had NO real match at all — dev.seeker.basic.f
             and dev.seeker.basic.m each had zero rows in
             `matches`. The Active Journey the Founder was looking
             at was local AppState mock data, which is why Reveal
             Compatibility appeared to do nothing:
             revealCompatibility() resolves the match row, gets
             null, and returns silently. Real Journeys were created
             for both, at compatibility_reveal, paired with browse
             profiles so the four test accounts do not consume each
             other. All four now have exactly one.

------------------------------------------------------------

OA-ZYRA-196
Title:       The Chapter 3/4 Question Bank Now Exists Twice
Category:    Architecture / Onboarding
Priority:    MEDIUM — nothing is broken, and it will break
             quietly when it breaks
Status:      Open
Owner:       Engineering
Raised:      2026-08-11
Source:      Building the OA-ZYRA-193(c) completeness gate

Description: The question bank now lives in BOTH
             data/chapter3_categories.dart and the
             zyra_onboarding_questions table. That is the price
             of a server-side gate — the server cannot enforce
             "every question answered" without knowing what the
             questions are.

             THE FAILURE MODE IS SILENT. A question added to
             Dart and not to the table is a question the gate
             stops requiring: onboarding asks it, nobody has to
             answer it, and the pool quietly admits people who
             skipped it. Nothing errors.

             The same is true of showIf. The gate got this wrong
             on its first attempt precisely because the condition
             existed in one place and not the other.

             OPTIONS: (a) generate the Dart from the table at
             build time; (b) generate the table from the Dart in
             a migration; (c) a test that fails when the two
             disagree — cheapest, and catches it at the right
             moment. (c) is probably the answer, and it needs the
             Dart bank to be readable from a test harness.

------------------------------------------------------------

OA-ZYRA-197
Title:       No Way Back Into Onboarding Once You Have Left It
Category:    Onboarding / UX
Priority:    MEDIUM, rising to HIGH the day a real user is gated
Status:      Open
Owner:       Founder / Engineering
Raised:      2026-08-11
Source:      Building the OA-ZYRA-193(c) completeness gate

Description: Browse now tells a gated Seeker how many questions
             are still unanswered. It offers no way to go and
             answer them, because there is no resume entry point
             into the onboarding flow to send them to.

             A button was deliberately NOT added: one that went
             nowhere would be worse than none.

             Until this exists, a Seeker who leaves onboarding
             early is told what is wrong and cannot fix it. That
             is survivable in testing, where the flow is always
             run start to finish, and it is not survivable with
             real members.

             NEEDS: an entry point that resumes at the first
             unanswered question. zyra_onboarding_missing()
             already returns exactly that list, in bank order,
             and it is already exposed to the client through
             zyra_my_onboarding_progress().

------------------------------------------------------------

OA-ZYRA-198
Title:       Repo/Live Migration Reconciliation — 87 Applied
             Migrations Have No Repo File
Category:    Engineering / Governance
Priority:    HIGH (pairs with OA-ZYRA-134's no-git-remote risk)
Status:      Open — partially discharged 2026-08-12
Owner:       Engineering
Raised:      2026-08-12
Source:      Stewardship pass. CLAUDE.md §5 recorded "78 migrations
             exist only in the live database... needs an OA" — this
             is that OA, re-measured.

Description: The live database holds 178 applied migrations, every
             one with verbatim statements preserved in
             supabase_migrations.schema_migrations. The repo holds
             files for ~91 of them by NAME (several under different
             version numbers than the live rows — hand-written back
             on 2026-08-08/11; name is therefore the join key).

             Discharged tonight: the 3 stewardship migrations are in
             the repo verbatim; the 8-file OA-193 frontier cluster is
             in the repo as applied-in-remote record files (house
             precedent: 20260811094513); and
             tools/export_missing_migrations.sql regenerates any or
             all missing files verbatim from the schema_migrations
             rows via the SQL editor.

             Remaining: run the export for the ~84 older rows
             (2026-07-27 → 2026-08-08 span) and commit. Two live
             rows are deliberately NOT wanted as files —
             20260811102840/20260811103056 — the repo carries them
             hand-split as 20260811110300 + 20260811111500.

Target:      Repo replays the full schema; supabase db reset works
             from a clean clone.
Dependencies: OA-ZYRA-134 (git remote); tools/
             export_missing_migrations.sql

------------------------------------------------------------

OA-ZYRA-199
Title:       seeker_details.is_synthetic Was Set On Every Row —
             Scope the Launch Sweep by Account, Not Flag Alone
Category:    Data Integrity / Launch Blocker
Priority:    HIGH before launch, harmless today
Status:      Open
Owner:       Engineering
Raised:      2026-08-12
Source:      Stewardship SQL audit of migration
             20260810170000_onboarding_answers_mark_synthetic_rows

Description: That migration's UPDATE on seeker_details has NO WHERE
             clause — all 144 rows are flagged is_synthetic=true,
             including any dev-entered rows, while the file's own
             header claims "a real Seeker can never be caught by the
             launch sweep". Measured 2026-08-12: every flagged row
             belongs to an @zyra.test account and zero non-test
             users exist, so nothing is harmed TODAY.

             But the OA-ZYRA-190 pre-launch deletion sweep must not
             trust this flag alone. Required: the sweep deletes only
             rows whose OWNING ACCOUNT is @zyra.test (join
             auth.users), with the flag as a secondary check; and
             the 20260810170000 header claim needs a correction
             note.

Target:      Sweep spec updated before OA-ZYRA-190 executes.
Dependencies: OA-ZYRA-190

------------------------------------------------------------

OA-ZYRA-200
Title:       Remaining zyra_dev_set_* Functions Still Guard Only
             the Caller
Category:    Security / Dev Tooling
Priority:    MEDIUM (destructive pair already fixed)
Status:      Open
Owner:       Engineering
Raised:      2026-08-12
Source:      Stewardship pass. Companion to migration
             20260811233914_dev_functions_guard_all_parties, which
             fixed the two DESTRUCTIVE functions
             (zyra_dev_counterpart_complete writes AS the other
             party; zyra_dev_rewind_journey DELETEs their rows) —
             both now assert every party of the match is
             @zyra.test.

Description: zyra_dev_set_journey_stage, zyra_dev_set_compatibility
             and zyra_dev_set_counterpart_reveal still verify only
             the CALLER. They mutate only the shared match /
             journey_compatibility row (no per-person writes, no
             deletes), so exposure is lower — but the same
             both-parties guard belongs on them for consistency.
             The anchor-surgery pattern in 20260811233914 applies
             directly.

Target:      All zyra_dev_* functions assert every affected party
             is a seeded account.
Dependencies: 20260811233914

------------------------------------------------------------

OA-ZYRA-201
Title:       Reference Stability — Every CURRENT_VERSION Promotion
             Breaks Every Inbound Link
Category:    Governance / Documentation
Priority:    MEDIUM
Status:      Open
Owner:       Founder decision on the proposal, then Documentation
Raised:      2026-08-12
Source:      Stewardship docs audit: ten dead references fixed by
             hand tonight, and the same defect class was already
             diagnosed IN FULL by
             ZYRA_DOCUMENT_REFERENCE_STABILITY_PROPOSAL_2026-08-08
             and its implementation plan — neither implemented, no
             as-applied record.

Description: Live docs cite the mutable CURRENT_VERSION filename,
             so each promotion orphans every inbound reference
             (BROWSE V3→V4 and WALI V5→V6 alone accounted for 7 of
             the 10 fixed tonight). The 2026-08-08 proposal already
             sets out the fix; it needs a Founder yes/no rather
             than re-diagnosis. Until then, each promotion should
             grep for the old filename as a checklist step.

Target:      Proposal decided; references stop rotting.
Dependencies: ZYRA_DOCUMENT_REFERENCE_STABILITY_PROPOSAL_2026-08-08

------------------------------------------------------------

# Register Metadata (added 2026-07-12)

TOTAL REGISTERED (this file): 202 (OA-001 through OA-ZYRA-201,
  Historical Identifiers, permanent — plus this note)
NEXT IDENTIFIER: OA-ZYRA-202 (Enterprise format, active
  2026-07-12 — see BLACK UMBRELLA GROUP/SYSTEM/OUTSTANDING_
  ACTIONS/OUTSTANDING_ACTIONS_V1.md, OA-127)
GOVERNING STANDARD: ENTERPRISE_OBJECT_IDENTITY_STANDARD_
  CURRENT_VERSION_V1.md (BLACK UMBRELLA GROUP/SYSTEM/
  ARCHITECTURE/), active 2026-07-12
