

# OUTSTANDING ACTIONS

Version: V1
Status: Approved Baseline (Draft for Review)

============================================================
1. PURPOSE
============================================================

The Outstanding Actions document is the project's single
authoritative register of all approved work that has not yet
been completed.

It provides a central location for tracking implementation
work across the project while remaining independent from
Governance, Execution, Architectural Discussions and feature
documentation.

This document owns only outstanding work.

It does not own:
• Governance decisions
• Implementation specifications
• Architectural reasoning
• Feature documentation

============================================================
2. SCOPE
============================================================

This document records only work that has been approved but
has not yet reached completion.

Examples include:

• Approved features awaiting implementation.
• Approved documentation updates.
• Approved architectural improvements.
• Approved governance improvements.
• Approved publication work.
• Approved review work.
• Approved migration work.
• Approved maintenance work.

Ideas, proposals and discussions are not recorded here until
they have completed the Governance Approval and Decision
Lifecycle.

============================================================
3. OWNERSHIP
============================================================

Document Owner

This document is maintained by ChatGPT as part of the
governance documentation suite.

The Project Owner approves additions, removals and
completion of actions.

Claude provides independent review of the document for
consistency, ownership, terminology and architectural
integrity.

Action Ownership

Each individual Outstanding Action contains its own assigned
owner.

The owner recorded against an action is responsible for
completing that specific action.

Document ownership and Action ownership are independent and
must never be confused.

============================================================
4. DOCUMENT PRINCIPLES
============================================================

4.1 Single Source of Outstanding Work

This document is the only authoritative source for approved
work that remains outstanding.

Other governance documents may reference Outstanding
Actions, but must never duplicate or maintain independent
lists.

This applies the Single Source of Truth and Reference Over
Duplication principles established within Governance.

4.2 Approval Required

Only approved work may enter this document.

Ideas, discussions and proposals remain outside this
document until approved through the Governance Approval and
Decision Lifecycle.

4.3 Living Document

Outstanding Actions is a living document.

Actions are continually added, updated, completed,
cancelled or superseded through approved governance
processes.

4.4 Historical Accuracy

When an action reaches a terminal state it remains recorded
for historical accuracy until removed through an approved
publication.

Historical changes must remain traceable through the normal
publication workflow.

============================================================
5. ACTION TEMPLATE
============================================================

Every Outstanding Action follows the standard Outstanding
Action Template defined within Governance.

This document references that template rather than
duplicating it.

Any future changes to the template are made within
Governance and automatically apply here through reference.

============================================================
6. ACTION LIFECYCLE
============================================================

An action enters this lifecycle only after successfully
completing the Governance Approval and Decision Lifecycle.

Outstanding Actions owns the tracking lifecycle from this
point onwards.

Operational States

Recorded
⇄
In Progress
⇄
Awaiting Review

Review Outcome

Awaiting Review
→ Completed (review successful)

Awaiting Review
→ In Progress (review unsuccessful)

Pause / Resume

In Progress
⇄
Recorded

Governance Terminal Outcomes

Recorded
→ Cancelled

In Progress
→ Cancelled

Awaiting Review
→ Cancelled

Recorded
→ Superseded

In Progress
→ Superseded

Awaiting Review
→ Superseded

Lifecycle Notes

• Recorded represents approved work that has not yet begun,
  or has been intentionally returned to a waiting state.

• In Progress represents active implementation.

• Awaiting Review represents completed work awaiting formal
  verification.

• Completed is the only successful terminal state.

• Cancelled and Superseded are governance terminal states
  and may occur from any active operational state.

• Priority, Dependencies, Owner and Target Publication are
  action metadata and do not represent lifecycle states.


============================================================
7. ACTION IDENTIFICATION
============================================================

Every Outstanding Action shall possess a permanent Action ID.

The Action ID uniquely identifies the action throughout its
entire lifecycle regardless of future status changes.

Action IDs are never reused.

If an action is cancelled, superseded or completed, its ID
remains permanently associated with that historical record.

============================================================
8. ACTION CATEGORIES
============================================================

Outstanding Actions may belong to one or more categories to
assist organisation and reporting.

Typical categories include:

• Feature Implementation
• Documentation
• Governance
• Architecture
• Review
• Migration
• Publication
• Maintenance

Categories describe the nature of the work only.

They do not affect priority, approval requirements or
lifecycle behaviour.

============================================================
9. PRIORITY
============================================================

Priority indicates the relative importance of completing an
approved action.

Priority assists planning but does not determine approval.

Suggested priority levels:

• Critical
• High
• Medium
• Low

Priority may change throughout the lifecycle as project
requirements evolve.

Changing priority does not require a new approval provided
the action itself remains unchanged.

============================================================
10. DEPENDENCIES
============================================================

An Outstanding Action may depend upon one or more other
approved actions before work can begin or continue.

Dependencies are recorded to improve planning and prevent
implementation conflicts.

Dependencies never prevent an action from being recorded.

Instead they explain why an action may remain in the
Recorded state until prerequisite work has been completed.

============================================================
11. TARGET PUBLICATION
============================================================

Where applicable, each action identifies the publication
through which completion is expected.

Examples include:

• GOVERNANCE_V1
• EXECUTION_V1
• OUTSTANDING_ACTIONS_V1
• ARCHITECTURAL_DISCUSSIONS_V1

Feature-specific publications may also be recorded where
appropriate.

Target Publication assists planning only.

It does not determine approval or completion.

============================================================
12. COMPLETION
============================================================

An action is considered complete only when:

• The approved work has been fully carried out.
• Required reviews have successfully completed.
• The Project Owner confirms completion.
• Any required publications have been approved.

Completion records the successful end of the action's
lifecycle.

Completed actions remain historically traceable through the
publication history until removed through an approved
publication process.


============================================================
13. REPORTING
============================================================

Outstanding Actions provides a consolidated view of approved
work that remains outstanding across the project.

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

============================================================
14. GOVERNANCE BOUNDARIES
============================================================

Outstanding Actions records work.

It does not determine whether work should exist.

That responsibility belongs to Governance through the
Approval and Decision Lifecycle.

Outstanding Actions never:

• Approves work.
• Rejects work.
• Creates governance decisions.
• Creates Architectural Discussions.
• Creates documentation.
• Alters implementation specifications.
• Records unapproved proposals.

Its responsibility begins only after approved work enters
the register.

============================================================
15. RELATIONSHIP TO OTHER DOCUMENTS
============================================================

Governance

Defines:

• Governance principles.
• Approval processes.
• Documentation standards.
• Publication workflow.
• Decision lifecycle.

Outstanding Actions begins only after Governance has
approved work.

Execution

Defines how approved work is carried out.

Outstanding Actions records that the work exists and tracks
its progress.

Execution explains how the work is performed.

Architectural Discussions

Records the permanent reasoning behind approved
architectural decisions.

Outstanding Actions may reference those decisions but never
duplicates them.

Feature Documentation

Feature Summaries, Script Summaries, Flow Blueprints and
References define individual features.

Outstanding Actions may reference feature documents where
approved work relates to those features.

============================================================
16. SYNCHRONISATION
============================================================

Outstanding Actions participates in the standard governance
publication workflow.

Changes become operational only after:

• Review.
• Project Owner approval.
• Publication.
• Synchronisation.

Conversational memory never replaces the approved published
document.

The latest approved publication always remains the active
baseline.

============================================================
17. DOCUMENT MAINTENANCE
============================================================

This document is maintained through the standard governance
publication workflow.

All additions, updates, cancellations, supersessions and
completions are performed through approved publications.

Previous publications remain archived for historical
reference.

There is always exactly one active baseline for this
document.

The latest approved publication replaces all previous
approved baselines.


============================================================
18. FUTURE EVOLUTION
============================================================

Outstanding Actions is designed to scale alongside the
project.

Future improvements may introduce additional reporting,
automation or workflow enhancements provided they remain
consistent with Governance.

Any future changes must:

• Preserve existing governance principles.
• Preserve historical accuracy.
• Preserve publication integrity.
• Preserve the active baseline principle.
• Follow the approved publication workflow.

No enhancement may compromise the document's role as the
single authoritative register of approved outstanding work.

============================================================
19. COMMAND INTEGRATION
============================================================

Various governance commands interact with Outstanding
Actions.

Governance defines the purpose and ownership of each
command.

Execution defines the operational behaviour of each command.

Outstanding Actions records the outcomes of approved command
execution where applicable.

Examples include:

• Approved work identified during project reviews.
• Approved documentation updates.
• Approved governance improvements.
• Approved implementation work.
• Approved migration activities.

Outstanding Actions never changes as the direct result of a
command alone.

Only approved outcomes produced through the governance
process may modify this register.

============================================================
20. DESIGN PRINCIPLES
============================================================

The design of Outstanding Actions follows four core
principles.

Single Source

There is one authoritative register for all approved
outstanding work.

Traceability

Every action remains historically traceable throughout its
lifecycle.

Separation of Responsibility

Governance approves.

Execution performs.

Outstanding Actions tracks.

Architectural Discussions explain why.

Publication Integrity

Changes become operational only through approved
publication and synchronisation.

============================================================
21. DOCUMENT STATUS
============================================================

Document:
OUTSTANDING_ACTIONS_V1

Version:
V1

Current Status:
Approved Baseline (Draft for Review)

Purpose:
Establish the permanent operational register of all approved
outstanding work across the project.

This document becomes operational once it completes the
approved governance review and publication process.

Until then, it represents the proposed V1 baseline under
architectural review.
