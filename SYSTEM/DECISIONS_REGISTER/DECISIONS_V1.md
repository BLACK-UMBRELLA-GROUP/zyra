============================================================
ZYRA PROJECT
============================================================
DECISIONS V1
ARCHITECTURAL DECISION RECORD
============================================================
Version: V1
Status: Approved — Active Baseline
Lead Architect: Claude
Architectural Reviewer: ChatGPT
Project Owner: Shakeel
============================================================

CONTENTS

  1.  Purpose
  2.  Scope
  3.  Relationship to Other Documents
  4.  Decision Record Template
  5.  Decision Lifecycle
  6.  Decision Identification
  7.  Decision Categories
  8.  Governance Boundaries
  9.  Future Evolution
  10. Version History
  11. Decision Register

============================================================


============================================================
1. PURPOSE
============================================================

The Decisions document is the permanent architectural
memory of the project.

Every significant decision that shapes the repository,
governance model, or technical architecture is recorded
here so that:

  • Future contributors understand why things are the
    way they are — not just what they are.
  • Decisions are traceable back to the context that
    produced them.
  • Old decisions can be revisited with full awareness
    of the original reasoning.
  • Repeated debates over the same ground are avoided.

Without Decision Records, the repository has structure
but no explanation of why that structure exists.

------------------------------------------------------------


============================================================
2. SCOPE
============================================================

This document records decisions that are:

  • Architectural — they shape how the repository or
    codebase is organised.
  • Governance — they shape how the project is run.
  • Significant — they were actively considered rather
    than simply assumed.
  • Approved — they have been confirmed by the Project
    Owner.

This document does not record:

  • Operational workflows (those belong to Execution).
  • Outstanding work (that belongs to Outstanding Actions).
  • Feature specifications (those belong to APP folders).
  • Ideas or proposals that were not approved.
  • Minor implementation details.

If a decision has lasting consequences for how the
project is organised or governed, it belongs here.

------------------------------------------------------------


============================================================
3. RELATIONSHIP TO OTHER DOCUMENTS
============================================================

Decision Records explain why — why structures were chosen,
why rules were written, why workflows were designed that way.
This is distinct from Governance (defines the rules),
Execution (defines the process), and Repository Architecture
(defines the structure).

Governance
  Defines the principles and rules of the project.
  Decisions records why those principles were chosen.
  Governance V3 will formally integrate Decision Records.

Execution
  Defines how work is performed.
  Decisions records why workflows were designed that way.

Repository Architecture
  Defines where everything lives.
  Decisions records why the structure was designed
  that way rather than an alternative.

Outstanding Actions
  Tracks approved work still to complete.
  Outstanding Actions may reference a Decision Record
  as the authority that created a piece of work.

Feature Documentation
  Defines individual features.
  Decisions may record why a significant feature
  design choice was made if it has architectural impact.

------------------------------------------------------------


============================================================
4. DECISION RECORD TEMPLATE
============================================================

Every Decision Record uses this template.

  ID:           DR-[sequential number]
  Title:        Short descriptive title
  Date:         YYYY-MM-DD
  Status:       Active / Superseded / Revoked
  Superseded By: DR-[n] or None
  Category:     Category from Section 7
  Owner:        Role that approved the decision
  Decision:     What was decided. One or two sentences.
  Context:      Why this decision was needed.
                What problem it was solving.
  Alternatives: Other options that were considered.
  Reasoning:    Why this option was chosen over others.
  Impact:       What this decision affects.
  Related:      DR-[numbers] or OA-[numbers] or None

------------------------------------------------------------


============================================================
5. DECISION LIFECYCLE
============================================================

  Proposed
    Decision is under discussion.
    Not yet recorded here.

  Active
    Decision has been approved and is currently in force.
    It governs the relevant area of the project.

  Superseded
    A newer decision has replaced this one.
    The original record is retained for historical context.
    The superseding DR-[number] is noted.

  Revoked
    The decision was removed without a replacement.
    Rare. Retained for historical accuracy.

Active is the normal state for most decisions.
Decisions are never deleted — only superseded or revoked.

------------------------------------------------------------
Immutability Principle
------------------------------------------------------------

Once a Decision Record reaches Active status, its historical
content is never rewritten.

If a decision changes, a new DR is created. The new DR
records what changed and why. The original DR is marked
Superseded with a reference to the new DR.

This preserves the original reasoning and context that
existed at the time the decision was made.

------------------------------------------------------------


============================================================
6. DECISION IDENTIFICATION
============================================================

Every Decision Record has a permanent ID.

Format: DR-[sequential number]

Examples: DR-001, DR-002, DR-003

IDs are never reused.

A superseded or revoked decision keeps its ID
permanently as part of the historical record.

------------------------------------------------------------


============================================================
7. DECISION CATEGORIES
============================================================

Current approved categories:

  Repository     — folder structure, placement, naming
  Governance     — governance model, roles, processes
  Execution      — operational workflows
  Architecture   — system or framework design
  Terminology    — approved language and naming
  Feature        — significant product design decisions
  Tooling        — tools, platforms, tech stack

Additional categories may be added through the normal
governance approval process.

------------------------------------------------------------


============================================================
8. GOVERNANCE BOUNDARIES
============================================================

This document records decisions.

It does not make them.

Only the Project Owner can approve a decision.

The Lead Architect and Architectural Reviewer may
propose and challenge decisions, but neither role
alone can create an Active Decision Record.

This document never:

  • Overrides approved governance.
  • Creates new operational workflows.
  • Replaces feature documentation.
  • Records unapproved proposals.

------------------------------------------------------------


============================================================
9. FUTURE EVOLUTION
============================================================

This document is the first step toward formal
Decision Records.

Governance V3 will:

  • Formally integrate Decision Records into the
    governance framework.
  • Clarify the relationship between Decision Records
    and Governance principles.
  • Define how decisions are proposed, reviewed,
    and approved going forward.

Until Governance V3 is published, this document
operates as the primary architectural memory.

The DECISIONS/ARCHITECTURE DISCUSSIONS/ subfolder
contains earlier-format discussions. Those records
are preserved as historical context. Over time,
significant decisions from that folder will be
formalised into Decision Records here.

Governance V3 is now published as the Active Baseline
(2026-06-20). It formally integrates Decision Records —
referred to as Decisions — into the governance framework;
see Governance V3 Section 7. This document remains the
authoritative register and template for Decisions.

------------------------------------------------------------


============================================================
10. VERSION HISTORY
============================================================

Version V1

Initial baseline. Approved Active Baseline.

Introduces:
  • Decision Record framework and template
  • Decision lifecycle (with Immutability Principle)
  • Decision identification (DR-[n] format)
  • Decision categories (current approved, extensible)
  • Governance boundaries
  • Relationship to other documents (why vs rules/process/structure)
  • Future evolution note (→ Governance V3)
  • Decision Register with all significant decisions
    made to date (DR-001 through DR-017)

Editorial fixes applied post-ChatGPT review:
  • DR-002: Role-based language (Project Owner, Lead Architect)
  • DR-008: Role-based language; ChatGPT noted as implementation
  • DR-015: Lead Architect replaces Claude
  • Template: Superseded By field added
  • Section 7: Current approved categories wording
  • Section 9: Governance V3 update note added

This document supersedes the informal Architecture
Discussions format for new decisions going forward.
Existing Architecture Discussions are preserved
for historical reference.

------------------------------------------------------------


============================================================
11. DECISION REGISTER
============================================================

Records are ordered by DR-ID (chronological).

------------------------------------------------------------

DR-001
Title:       Repository top-level structure
Date:        2026-06-20
Status:      Active
Category:    Repository
Owner:       Project Owner
Decision:    The repository uses five top-level sections:
             APP, BUSINESS, SYSTEM, SOURCE, ARCHIVE.
Context:     Needed a clear separation between product
             features, business decisions, governance
             framework, source code, and historical records.
             Without this, everything would accumulate in
             one unstructured folder.
Alternatives: Single flat structure. Feature-only folders
             with no separation of concerns.
Reasoning:   Each section has one clear responsibility.
             This prevents content from drifting into the
             wrong area as the project grows. SYSTEM can
             remain generic and reusable for future projects.
Impact:      All current and future content placement.
             Governs Repository Architecture Section 4.
Related:     DR-002, DR-003

------------------------------------------------------------

DR-002
Title:       APP feature folder standard structure
Date:        2026-06-20
Status:      Active
Category:    Repository
Owner:       Project Owner
Decision:    Every APP feature folder contains:
             Summary.md, Flow Diagram.md, References.md,
             and a Script/ subfolder.
Context:     Without a standard structure, each feature
             folder would look different, making the
             repository inconsistent and harder to navigate.
Alternatives: Free-form structure per feature.
             Summary only. Script only.
Reasoning:   Predictability. Anyone navigating the repo
             knows exactly what to expect in every feature
             folder. Ownership is clear — the Project
             Owner owns Summary.md, the Lead Architect
             manages the rest.
Impact:      All APP feature folders. Governs Execution V2
             Section 16 and Repository Architecture
             Section 6.
Related:     DR-001, DR-006

------------------------------------------------------------

DR-003
Title:       SYSTEM folder must remain generic
Date:        2026-06-20
Status:      Active
Category:    Repository
Owner:       Project Owner
Decision:    SYSTEM contains only governance, execution,
             and methodology documents. No ZYRA-specific
             content lives in SYSTEM.
Context:     If ZYRA-specific content accumulates in SYSTEM,
             the governance framework can no longer be
             reused for other projects without stripping
             it out first.
Alternatives: Allow ZYRA content in SYSTEM where relevant.
             Create a ZYRA subfolder inside SYSTEM.
Reasoning:   SYSTEM should work as a reusable governance
             layer for any project. Keeping it generic now
             avoids painful cleanup later.
Impact:      OA-010 (cleanup task). Future holding company
             restructure (OA-011). All SYSTEM documents.
Related:     DR-001, DR-016

------------------------------------------------------------

DR-004
Title:       Three foundational SYSTEM documents
Date:        2026-06-20
Status:      Active
Category:    Governance
Owner:       Project Owner
Decision:    The SYSTEM layer is built around three
             foundational documents: Governance,
             Execution, Repository Architecture.
             Each owns one clear responsibility.
Context:     Previously governance and operational rules
             lived in one document or in conversation.
             This created confusion about where to look
             for a specific rule.
Alternatives: Single governance document covering
             everything. Two documents (Governance
             and Execution only).
Reasoning:   Governance = what is allowed.
             Execution = how work is performed.
             Repository Architecture = where things live.
             One responsibility per document means each
             one stays focused and doesn't grow without
             limit.
Impact:      GOVERNANCE_V2, EXECUTION_V2,
             REPOSITORY_ARCHITECTURE_V1.
Related:     DR-005, DR-007

------------------------------------------------------------

DR-005
Title:       SYSTEM document authority hierarchy
Date:        2026-06-20
Status:      Active
Category:    Governance
Owner:       Project Owner
Decision:    Authority flows: Governance → Repository
             Architecture → Execution → Operational
             Documents.
Context:     When two documents conflict, there needs to
             be a clear rule for which one wins.
Alternatives: Flat authority (all documents equal).
             Execution above Repository Architecture.
Reasoning:   Governance sets the rules everything else
             follows. Repository Architecture defines
             structure before Execution can describe
             how to work within that structure.
Impact:      All SYSTEM documents. Conflict resolution.
Related:     DR-004

------------------------------------------------------------

DR-006
Title:       Script versioning — never overwrite
Date:        2026-06-20
Status:      Active
Category:    Repository
Owner:       Project Owner
Decision:    Script files are versioned sequentially
             (Script_V1.md, Script_V2.md). Existing
             Script files are never overwritten.
Context:     Overwriting scripts loses the history of
             what was implemented and when. Previous
             versions may need to be referenced or
             rolled back.
Alternatives: Overwrite in place. Use git history only.
Reasoning:   The repository should be self-contained.
             Version history visible in the folder itself
             without needing git knowledge.
Impact:      All Script/ subfolders across APP features.
Related:     DR-002

------------------------------------------------------------

DR-007
Title:       AI role model — permanent roles not
             named products
Date:        2026-06-20
Status:      Active
Category:    Governance
Owner:       Project Owner
Decision:    Governance documents use permanent role names:
             Lead Architect, Architectural Reviewer,
             Project Owner. Current implementations
             (Claude, ChatGPT, Shakeel) are noted
             but not embedded permanently.
Context:     If documents name specific AI products, they
             become outdated when tools change. The
             governance framework should outlive any
             specific tool.
Alternatives: Name Claude and ChatGPT directly throughout.
Reasoning:   Roles are permanent. Implementations change.
             This keeps the governance framework durable.
Impact:      All SYSTEM documents. EXECUTION_V2 Section 12.
Related:     DR-004, DR-008

------------------------------------------------------------

DR-008
Title:       ChatGPT as independent Architectural
             Reviewer
Date:        2026-06-20
Status:      Active
Category:    Governance
Owner:       Project Owner
Decision:    An independent Architectural Reviewer provides
             review of all SYSTEM document changes before
             the Project Owner approves. Disagreements
             escalate to the Project Owner.
             Current implementation: ChatGPT.
Context:     Without independent review, a single AI
             could introduce decisions that seem right
             in the moment but have long-term problems
             that aren't caught until later.
Alternatives: Claude reviews its own work. No formal
             review process for SYSTEM documents.
Reasoning:   Independent review from a different
             perspective catches assumptions, gaps, and
             architectural risks before they become
             permanent. The Architectural Reviewer covers
             governance, architecture, product, and
             risk angles.
Impact:      All SYSTEM document publications.
             EXECUTION_V2 Section 12.2.
Related:     DR-007

------------------------------------------------------------

DR-009
Title:       Two review types — Implementation and
             Architectural
Date:        2026-06-20
Status:      Active
Category:    Governance
Owner:       Project Owner
Decision:    Reviews are separated into two types.
             Implementation Review: is this correct,
             complete, and internally consistent?
             Architectural Review: should this exist,
             does it belong here, does it own the
             right responsibility?
Context:     Many projects review documents for
             correctness but forget to ask whether
             the document should exist in the first
             place or owns the right content.
Alternatives: Single review type covering everything.
Reasoning:   Keeping both perspectives separate ensures
             a document can pass one review and still
             be challenged on the other. This prevents
             well-written documents with the wrong
             responsibility from being approved unchecked.
Impact:      All SYSTEM document reviews.
             EXECUTION_V2 Section 8.
Related:     DR-008

------------------------------------------------------------

DR-010
Title:       SYSTEM document naming convention
Date:        2026-06-20
Status:      Active
Category:    Repository
Owner:       Project Owner
Decision:    Core SYSTEM documents use simple version
             naming: GOVERNANCE_V2.md, EXECUTION_V2.md.
             Operational/business documents use
             CURRENT_VERSION suffix:
             PRICING_CURRENT_VERSION_V4.md.
Context:     Applying CURRENT_VERSION to all documents
             adds noise to SYSTEM files that don't need
             it. SYSTEM documents are identified by
             version number — the highest is always active.
Alternatives: CURRENT_VERSION on all documents.
             No naming convention (rely on git).
Reasoning:   SYSTEM documents evolve slowly with clear
             version numbers. Operational documents
             change frequently and benefit from an
             obvious "live version" marker.
Impact:      All SYSTEM document filenames.
             Repository Architecture Section 9.
Related:     DR-001

------------------------------------------------------------

DR-011
Title:       Folder names in CAPITALS
Date:        2026-06-20
Status:      Active
Category:    Repository
Owner:       Project Owner
Decision:    All folder names in the repository use
             CAPITALS throughout. No mixed-case or
             lowercase folder names.
Context:     Inconsistent folder naming makes the
             repository harder to navigate and looks
             unprofessional. A single standard
             prevents drift.
Alternatives: Title Case. lowercase. camelCase.
Reasoning:   CAPITALS are immediately visually distinct
             from filenames (which use mixed case).
             This makes it easy to tell at a glance
             whether something is a folder or a file.
Impact:      All folders across APP, BUSINESS, SYSTEM.
Related:     DR-010

------------------------------------------------------------

DR-012
Title:       Script filing rule — Summary required first
Date:        2026-06-20
Status:      Active
Category:    Repository
Owner:       Project Owner
Decision:    A Script file may only be filed into a
             folder that already has a Summary.md.
             If no Summary exists, the script waits.
Context:     Filing a script into a folder with no
             Summary creates an orphan implementation
             with no governing intent document.
             The implementation has no approved context.
Alternatives: Allow scripts without summaries as
             temporary placeholders.
Reasoning:   Summary defines the approved intent.
             Implementation (Script) should always
             follow approved intent, never precede it.
Impact:      All Script filing operations.
             EXECUTION_V2 Section 18.
Related:     DR-002, DR-006

------------------------------------------------------------

DR-013
Title:       Developer Mode as superset of production
Date:        2026-06-20
Status:      Active
Category:    Feature
Owner:       Project Owner
Decision:    Developer Mode lives inside the production
             application and is a superset of the
             user experience. Developer features never
             override or break production features.
             Conflicts stop and are flagged.
Context:     A separate developer app would duplicate
             the entire codebase and create permanent
             divergence. Developer Mode needs to test
             production behaviour, not simulate it.
Alternatives: Separate developer app. Feature flags only.
Reasoning:   One codebase, one database. Developer Mode
             simply unlocks additional functionality for
             Admin users. Production always remains the
             source of truth.
Impact:      APP/Developer Mode. All feature Summaries
             (DEVELOPER MODE section).
Related:     None

------------------------------------------------------------

DR-014
Title:       Terminology — Decline / Review / Consider
Date:        2026-06-20
Status:      Superseded by DR-076 (2026-07-12) — see below
Category:    Terminology
Owner:       Project Owner
Decision:    The three approved profile decision terms
             are: Decline, Review, Consider.
             Review has a 50-profile cap. Consider
             has no cap.
Context:     Earlier scripts used inconsistent terms:
             Pass, Save, Like, Considering, Potentials.
             Inconsistent terminology confuses both
             the codebase and users.
Alternatives: Keep existing terms. Use Like/Pass/Save.
Reasoning:   Decline/Review/Consider are clear, neutral,
             and scalable. They communicate intent without
             implying commitment. ZYRA TERMINOLOGY is
             the source of truth for all approved terms.
Impact:      All features involving profile decisions.
             All scripts and summaries across the repo.
             BUSINESS/ZYRA TERMINOLOGY.
Related:     None

------------------------------------------------------------

DR-015
Title:       Connections content lives in SEEKER
             NAVIGATION temporarily
Date:        2026-06-20
Status:      Active
Category:    Repository
Owner:       Project Owner
Decision:    Until a dedicated Connections Summary and
             folder exist, Connections content lives
             in APP/Navigation/SEEKER NAVIGATION/Script/.
             During audits, the Lead Architect may
             recommend a split with reasoning but cannot
             create the folder unilaterally.
Context:     Connections content was ready to file but
             no Summary existed for a dedicated
             Connections folder. Filing it somewhere
             with no Summary would violate DR-012.
Alternatives: Create Connections folder without Summary.
             Leave content unfiled.
Reasoning:   SEEKER NAVIGATION is the closest logical
             home until Connections has its own Summary.
             The audit recommendation model keeps this
             visible for future action (OA-009).
Impact:      OA-009. SEEKER NAVIGATION Script/.
Related:     DR-012, OA-009

------------------------------------------------------------

DR-016
Title:       Future holding company / APPS/ structure
Date:        2026-06-20
Status:      Active
Category:    Architecture
Owner:       Project Owner
Decision:    In future, the repository will restructure
             to a holding company model. SYSTEM becomes
             shared infrastructure. Each app (ZYRA and
             future apps) sits inside an APPS/ folder
             as its own unit.
Context:     If the governance framework is reused for
             other apps, the current structure (with
             ZYRA at the root) becomes confusing. The
             SYSTEM folder needs to sit above all apps.
Alternatives: Separate repository per app.
             Keep ZYRA at root forever.
Reasoning:   Reusable governance framework at the top
             level. Clean separation per app underneath.
             This decision is recorded now but actioned
             only when a second app is being built.
Impact:      OA-010, OA-011. All current folder locations
             will change in the future restructure.
Related:     DR-003, OA-010, OA-011

------------------------------------------------------------

DR-017
Title:       DECISIONS area to evolve toward Decision
             Records through Governance V3
Date:        2026-06-20
Status:      Active
Category:    Governance
Owner:       Project Owner
Decision:    The DECISIONS area will evolve from informal
             Architecture Discussions to formal Decision
             Records. DECISIONS_V1 establishes the
             framework. Governance V3 will formally
             integrate Decision Records into the
             governance model.
Context:     Architecture Discussions recorded
             conversations but not decisions. As the
             repository matures, a more structured
             format that captures context, alternatives,
             and reasoning becomes more valuable.
Alternatives: Keep Architecture Discussions format.
             Skip Decision Records entirely.
Reasoning:   Decision Records answer "why" — not just
             "what". That context becomes critical as
             the team grows or the project is revisited
             after a long period. The format also
             prevents repeated debates over already-
             resolved decisions.
Impact:      OA-001 (Decisions V1 — done).
             OA-002 (Governance V3).
             DECISIONS folder long-term direction.
Related:     OA-001, OA-002

------------------------------------------------------------

DR-018
Title:       Governance update principles — auto-update
             and version batching
Date:        2026-06-20
Status:      Active
Superseded By: None
Category:    Governance
Owner:       Project Owner
Decision:    Two operational principles approved.
             First: Outstanding Actions status updates
             and Decision Record recordings are
             automatic consequences of approved work —
             no separate confirmation required.
             Second: changes needed to Governance,
             Execution, or Architecture are queued as
             Outstanding Actions and batched into the
             next version rather than triggering
             immediate new versions.
Context:     Previously every update — including
             mechanical status changes — required
             separate confirmation. This created
             unnecessary friction for routine
             bookkeeping. Separately, small rule
             changes were triggering full new document
             versions, creating version creep.
Alternatives: Continue requiring confirmation for
             all updates. Version documents immediately
             for every change.
Reasoning:   Status updates and DR recordings are not
             new decisions — they are mechanical
             consequences of decisions already approved.
             Requiring confirmation adds no governance
             value. Version batching keeps major
             documents stable and ensures each new
             version contains meaningful cumulative
             change rather than a single rule tweak.
Impact:      OUTSTANDING_ACTIONS_V2.md — auto-updated
             without confirmation from this point.
             DECISIONS_V1.md — DRs recorded without
             confirmation from this point.
             Governance, Execution, Architecture —
             changes queued until Project Owner signals
             readiness for next version.
             OA-012 — command redesign queued for V3.
Related:     OA-002, OA-012

------------------------------------------------------------

DR-019
Title:       Governance V3 participant model —
             Specialist Reviewer framework
Date:        2026-06-20
Status:      Active
Superseded By: None
Category:    Governance
Owner:       Project Owner
Decision:    Governance V3 adopts three permanent
             governance roles: Project Owner, Lead
             Architect, Architectural Reviewer.
             A Specialist Reviewer framework is
             defined in Governance and activated
             by Execution trigger criteria.
             No Specialist Reviewers are active
             at V3 launch. Gemini's Engineering
             Challenger role from V2 is retired —
             it was never invoked in practice and
             does not carry forward.
Context:     Governance V2 defined five named
             participants including Gemini as
             Engineering Challenger. Moving to
             role-based language (DR-007) required
             a decision on whether to carry forward
             additional participant roles or
             consolidate. Gemini was confirmed as
             never having been invoked. The
             Architectural Reviewer proposed and
             both reviewers agreed on a lean core
             model with an extensible specialist
             framework.
Alternatives: Three permanent roles only with no
             specialist framework. Four permanent
             roles with Engineering Reviewer always
             active. Optional specialist reviews
             with no trigger mechanism.
Reasoning:   Governance stays focused on principles.
             Execution defines operational triggers.
             Specialist Reviewers scale naturally as
             ZYRA grows without requiring Governance
             redesign. Roles that were never used in
             practice are not carried forward
             speculatively.
Impact:      GOVERNANCE_V3.md participant model.
             EXECUTION_V3.md will define active
             Specialist Reviewer trigger criteria
             when needed.
Related:     DR-007, OA-002

------------------------------------------------------------

DR-020
Title:       SOURCE/ code development follows
             plan-first workflow
Date:        2026-06-21
Status:      Active
Superseded By: None
Category:    Execution
Owner:       Project Owner
Decision:    All code written to SOURCE/ follows a
             plan-first workflow: Plan → Confirm →
             Tests → Confirm → Implement → Self-review.
             No code is written until a plan has been
             confirmed by the Project Owner.
Context:     The existing confirmation before execution
             rule prevents unauthorised code writes
             but does not define what must be confirmed.
             Without a required plan structure, Claude
             could present a vague intent for approval
             and then write code with no test coverage
             or agreed approach. A plan-first rule
             extends confirmation with explicit
             structure for code work.
Alternatives: Confirmation before execution alone with
             no required plan structure. Install a
             third-party plugin (Superpowers) to
             enforce plan-first at the Claude Code
             terminal level. Free-form coding with
             post-implementation review only.
Reasoning:   Codifying plan-first as a governance rule
             means it applies in all sessions regardless
             of tool or interface. It closes the gap
             between "confirmed" and "well-planned" for
             code work. No external plugin is needed
             because the confirmation before execution
             rule already gives governance the mechanism
             to enforce it. Tests-first (TDD) ensures
             implementation is always verified against
             defined behaviour before code is accepted.
Impact:      EXECUTION_V4.md — new SOURCE/ development
             workflow section. All code writes to
             SOURCE/ across all APP features.
Related:     DR-018, OA-015

------------------------------------------------------------

DR-021
Title:       ZYRA UI development requires a design
             language brief
Date:        2026-06-21
Status:      Active
Superseded By: None
Category:    Execution
Owner:       Project Owner
Decision:    Before any UI code is written to SOURCE/,
             a ZYRA Design Language brief must exist.
             The brief defines at minimum: purpose,
             tone, constraints, and differentiation.
             All UI output is governed by this brief.
             No UI screen may be built without it.
Context:     Without a defined design language, each
             UI session produces output independently.
             The result is visual inconsistency across
             screens. The frontend design plugin
             (4-question framework) identified that
             committing to tone upfront is what
             separates production-quality UI from
             generic AI output. For ZYRA this is
             especially important given the platform's
             identity and audience.
Alternatives: Define design per screen at build time.
             Install frontend-design plugin in Claude
             Code and answer questions per session.
             No formal design language document.
Reasoning:   A governed design brief is the ZYRA-native
             equivalent of the plugin's 4-question
             framework. It becomes a source-of-truth
             document that every UI session references,
             rather than a per-session prompt. Exact
             rule wording to be confirmed with
             Architectural Reviewer input before
             writing into Execution V4.
Impact:      EXECUTION_V4.md — UI development workflow
             rule. All SOURCE/ UI writes across APP.
             Future ZYRA Design Language document.
Related:     DR-020, OA-016

------------------------------------------------------------

DR-022
Title:       ZYRA Project Execution Framework —
             approved methodology and Inspection
             priority rule
Date:        2026-06-21
Status:      Active
Superseded By: None
Category:    Execution
Owner:       Project Owner
Decision:    The eight-group ZYRA Project Execution
             Framework is the approved methodology
             for building the application. Execution
             framework group number is the primary
             priority sort key in all Inspection
             reports. Lower group number always means
             higher priority, regardless of completion
             percentage. Partially complete lower-group
             items are flagged with elevated concern
             when higher-group items are in progress.

             Approved Groups:
               1 — Business Rules
               2 — User Journeys
               3 — Page Inventory
               4 — Page Responsibilities
               5 — Application Architecture
               6 — Architecture Readiness Review
               7 — UI/UX Design
               8 — Development

             Framework updated from seven-group to
             eight-group on 2026-06-27 following
             approval of ADVANCEMENT_CONDITIONS_V1,
             which split the original combined
             "Business Rules & User Journeys" (Group 1)
             into two distinct sequential stages.
             Approved by Project Owner (Shakeel),
             2026-06-27.

Context:     ZYRA previously had no formal execution
             order — features were being designed
             individually without establishing
             behavioural foundations first. The
             framework was proposed, reviewed by both
             the Lead Architect and Architectural
             Reviewer across multiple rounds, and
             refined to its final form. The priority
             rule ensures Inspection reports surface
             foundational gaps before later-stage
             work is flagged.
Alternatives: Continue designing features individually.
             Use only completion % for priority ordering
             in Inspection reports.
             Treat all groups as equal priority.
Reasoning:   Business rules and application architecture
             are significantly more expensive to change
             than UI. The framework enforces the correct
             build sequence. The priority rule in
             Inspection ensures the sequence is visible
             and enforced throughout the project — if
             Group 1 work is incomplete while Group 6
             work has started, that is a higher concern
             than a finding in Group 6 alone.
             Reviewed and approved by both Lead Architect
             and Architectural Reviewer before
             recommendation to Project Owner.
Impact:      BUSINESS/PRODUCT PLANNING/Summary.md —
             official execution framework.
             EXECUTION_CURRENT_VERSION_V9.md — Inspection
             priority rule (OA-017).
             All feature Summaries — Group numbers
             migrated to 8-group model (2026-06-27).
             ADVANCEMENT_CONDITIONS_CURRENT_VERSION_V1.md
             — defines advancement evidence per group.
Related:     OA-017, DR-074, OA-120 (ZYRA register)

------------------------------------------------------------

DR-024
Title:       ZYRA operational documents separated from
             shared SYSTEM — APPS/ZYRA/SYSTEM/ created
Date:        2026-06-21
Status:      Active
Superseded By: None
Category:    Repository
Owner:       Project Owner
Decision:    DECISIONS/ and OUTSTANDING_ACTIONS/ have
             been moved from the shared SYSTEM/ folder
             into a new APPS/ZYRA/SYSTEM/ folder.
             SYSTEM/ at the holding level now contains
             only truly shared governance documents:
             GOVERNANCE, EXECUTION, ARCHITECTURE,
             DEVELOPMENT, REPORTS. Each app under
             APPS/ has its own SYSTEM/ subfolder for
             its operational documents (decisions,
             outstanding actions). REPORTS/ remains
             at APPS/ZYRA/ level (not inside ZYRA/SYSTEM/)
             — each REPORTS folder is single-purpose
             and requires no internal subfolders.
Context:     DECISIONS/ and OUTSTANDING_ACTIONS/ are
             ZYRA-specific operational tracking documents.
             They do not belong in the shared SYSTEM/
             layer alongside governance infrastructure
             that applies to all future apps. A future
             app would have its own decisions and
             outstanding actions entirely separate
             from ZYRA's.
Alternatives: Keep all operational documents in shared
             SYSTEM/. Create a ZYRA/ namespace inside
             SYSTEM/ without a dedicated SYSTEM/ under
             APPS/ZYRA/.
Reasoning:   True separation of concerns — shared
             governance infrastructure stays generic,
             app-specific operational tracking is
             scoped to its app. This pattern scales
             correctly when new apps are added to the
             holding structure.
Impact:      All path references to SYSTEM/DECISIONS/
             and SYSTEM/OUTSTANDING_ACTIONS/ are now
             APPS/ZYRA/SYSTEM/DECISIONS/ and
             APPS/ZYRA/SYSTEM/OUTSTANDING_ACTIONS/.
             OA-019 (Repository Architecture V2) scope
             expanded to include this change.
Related:     DR-023, OA-019

------------------------------------------------------------

DR-023
Title:       Holding company structure executed —
             REPORTS folder established
Date:        2026-06-21
Status:      Active
Superseded By: None
Category:    Repository
Owner:       Project Owner
Decision:    The repository has been restructured to
             the holding company model. The physical
             folder (ZYRA/) now functions as the
             HOLDING layer. SYSTEM/ remains at the
             top level as shared governance
             infrastructure. All app-specific content
             (APP/, BUSINESS/, SOURCE/, ARCHIVE/)
             has moved into APPS/ZYRA/. A REPORTS/
             INSPECTION/ folder has been created
             under both APPS/ZYRA/ (for APP reports)
             and SYSTEM/ (for SYSTEM reports).
             Each Inspection run creates a dated
             subfolder inside INSPECTION/ containing
             APP/ and SYSTEM/ subfolders respectively.
Context:     DR-016 and OA-011 established the holding
             company restructure as a future intent.
             The decision was made to execute it now
             rather than defer, establishing the correct
             structure before further content is added.
             The physical folder rename (ZYRA → HOLDING)
             is a Finder-level operation for the Project
             Owner to complete at their discretion —
             the internal structure is now correct
             regardless of the outer folder name.
Alternatives: Continue with flat ZYRA structure and
             migrate later. Create REPORTS/ without
             restructuring the app content.
Reasoning:   Executing the structure now prevents
             further content accumulation in the wrong
             locations. Every new feature, document,
             or report filed from this point lands in
             the correct long-term location. Deferring
             would create more migration work later.
Impact:      All file paths for APP/, BUSINESS/,
             SOURCE/, ARCHIVE/ now include APPS/ZYRA/
             prefix. REPOSITORY_ARCHITECTURE_V1.md
             requires updating to reflect new paths
             (OA-019). SYSTEM/ paths unchanged.
Related:     DR-001, DR-016, OA-011, OA-019

------------------------------------------------------------

DR-025
Title:       Two-tier SYSTEM model — shared governance
             layer vs app operational layer
Date:        2026-06-21
Status:      Active
Superseded By: None
Category:    Repository
Owner:       Project Owner
Decision:    The HOLDINGS structure contains two distinct
             types of SYSTEM folder with different
             responsibilities.

             Tier 1 — Shared SYSTEM (HOLDINGS/SYSTEM/)
             Contains governance infrastructure that
             applies to every app in the holding company.
             Documents here are generic and reusable.
             Contents: GOVERNANCE, EXECUTION,
             ARCHITECTURE, AI_ORGANISATION, DEVELOPMENT,
             REPORTS.
             Rule: if a document applies to ALL apps
             it belongs here.

             Tier 2 — App SYSTEM (HOLDINGS/APPS/[APP]/SYSTEM/)
             Contains operational tracking documents
             that are specific to one app only.
             Contents: DECISIONS, OUTSTANDING_ACTIONS.
             Rule: if a document tracks decisions,
             actions, or history for ONE app only,
             it belongs here.

             The rule for placement is:
               Applies to all apps → Shared SYSTEM/
               Specific to one app → App SYSTEM/

             This distinction must be documented in
             Governance V4 as a permanent rule so
             any future contributor or AI agent knows
             exactly where to file any document.
Context:     Three separate folder restructures this
             session exposed the absence of a clear
             written rule governing what belongs in
             each SYSTEM layer. Without this rule,
             documents were placed by instinct rather
             than governance. The AI Organisation folder
             was initially placed inside APPS/ZYRA/SYSTEM/
             before being corrected to SYSTEM/ — a direct
             consequence of this gap. The rule must be
             explicit and permanent.
Alternatives: Single SYSTEM/ folder for everything.
             No app-level SYSTEM/ folder — keep
             DECISIONS and OAs in shared SYSTEM/.
Reasoning:   The holding company model requires shared
             infrastructure to remain generic so it
             scales to new apps without modification.
             App-specific operational documents must
             be scoped to their app so they don't
             pollute the shared layer. The two-tier
             model enforces this cleanly.
Impact:      GOVERNANCE_V4.md must include this rule
             as a permanent, clearly written definition.
             REPOSITORY_ARCHITECTURE_V2.md must reflect
             both tiers with examples.
             All future document placement decisions
             follow this rule.
Related:     DR-001, DR-003, DR-023, DR-024, OA-019,
             OA-025

------------------------------------------------------------

DR-026
Title:       AI Organisation structure, Architecture
             Partner name, and agent contract template
             approved
Date:        2026-06-21
Status:      Active
Superseded By: None
Category:    Governance
Owner:       Project Owner
Decision:    Three items approved by Project Owner
             following full alignment between Lead
             Architect and Architectural Reviewer:

             1. Three-layer organisational model:
                Strategic Leadership — Project Owner,
                Lead Architect, Architecture Partner,
                Critical Thinking Agent.
                Operational Execution — Orchestrator
                and all operational agents.
                Independent Assurance — System Auditor,
                Master Reviewer.
                Outside Organisation — External Reviewer
                (currently ChatGPT), engaged by Project
                Owner on demand only.
                Layer principle: layers represent WHEN
                an agent participates, not only what
                it does.

             2. Internal second architect role named
                Architecture Partner. Name reflects
                a collaborative design-time relationship
                with the Lead Architect. Not Deputy or
                Associate — those imply hierarchy.

             3. Agent contract template approved.
                Standard fields for every agent:
                Identity (Name, Layer, Reporting Line,
                Status), Purpose (Mission, Purpose,
                When It Runs), Responsibilities,
                Authority & Boundaries (Authority,
                Cannot), Autonomous Operation Rules
                (Escalation Trigger, Escalates To,
                Iteration Ceiling, Rollback Rule),
                Interfaces (Inputs, Outputs, Interacts
                With), Quality (Success Criteria),
                Evolution (Future Expansion).
                Template stored at:
                SYSTEM/AI_ORGANISATION/CONTRACTS/
                TEMPLATE.md

Context:     Lead Architect and Architectural Reviewer
             conducted multiple review rounds covering
             agent structure, timing-based layer model,
             naming conflicts between internal and
             external reviewer roles, and contract
             field requirements. Full convergence
             reached before presenting to Project Owner.
Alternatives: Flat organisation with no layers.
             Deputy Architect or Associate Architect
             as naming. Separate contract formats
             per agent type.
Reasoning:   Layers based on timing create clean
             boundaries — agents know when they
             participate and when they do not.
             Architecture Partner reflects the actual
             relationship without implying subordination.
             A standard contract template ensures every
             agent is defined consistently and no
             mandatory field is omitted.
Impact:      AI_ORGANISATION_V1.md (OA-022) must
             follow this structure. All agent contracts
             use TEMPLATE.md as the base. Future
             agents are placed into the approved
             three-layer model.
Related:     OA-022, OA-023, OA-024

------------------------------------------------------------

DR-027
Title:       SYSTEM/ two-tier model — DOCS/ and SUPPORT/
Date:        2026-06-21
Status:      Active
Superseded By: None
Category:    Repository
Owner:       Project Owner
Decision:    The top-level SYSTEM/ folder is restructured
             into two tiers:
               SYSTEM/DOCS/ — all folders containing
               versioned governance documents. Each
               subfolder here follows the V doc
               publication workflow. Contents:
               GOVERNANCE/, EXECUTION/, ARCHITECTURE/,
               AI_ORGANISATION/.
               SYSTEM/SUPPORT/ — all operational and
               reference folders that do not follow
               the V doc publication workflow. Contents:
               DEVELOPMENT/, REPORTS/.
             Within DOCS/ folders that need support
             materials (e.g. AI_ORGANISATION/), support
             subfolders sit inside that folder alongside
             the V doc. Example: AI_ORGANISATION/
             contains AI_ORGANISATION_V1.md (V doc),
             CONTRACTS/ (support), ROADMAP/ (support).
Context:     AI_ORGANISATION/ was the first SYSTEM
             folder to require both a V doc and
             permanent support subfolders (CONTRACTS/,
             ROADMAP/). This exposed an inconsistency
             in the SYSTEM/ structure — V doc folders
             and operational folders were mixed at
             the same level with no clear distinction.
             The two-tier model enforces a permanent
             rule: if it has a V doc it belongs in
             DOCS/. If it is operational infrastructure
             it belongs in SUPPORT/.
Alternatives: Keep all SYSTEM folders at root level.
             Use a naming convention to distinguish
             types without subfolders.
Reasoning:   Clear structural separation prevents
             future misplacement. Any contributor or
             agent navigating SYSTEM/ immediately
             understands the two categories without
             needing to read governance documentation.
             Scales cleanly as new V doc systems
             or new support folders are added.
Impact:      All SYSTEM/ paths now include DOCS/ or
             SUPPORT/ prefix. OA-019 scope expanded
             again. Governance V4 must document this
             model. DR-025 two-tier SYSTEM rule
             should be updated to reference this.
Related:     DR-023, DR-024, DR-025, OA-019, OA-025

------------------------------------------------------------

DR-028
Title:       APPS/ renamed to PROJECTS/
Date:        2026-06-22
Status:      Active
Superseded By: None
Category:    Repository
Owner:       Project Owner
Decision:    The HOLDINGS/APPS/ folder is renamed to
             HOLDINGS/PROJECTS/. All projects within it
             move to HOLDINGS/PROJECTS/. Path references
             in active documents are updated accordingly.
Context:     APPS/ was named when ZYRA was the only
             project and was assumed to be a software
             application. As the Holdings grows to include
             an AI consultancy and potentially SaaS
             products, education businesses, and other
             ventures — not all of which are apps —
             APPS/ is no longer accurate or scalable.
Alternatives: BUSINESSES/ — too commercial, excludes
             technical projects. Keep APPS/ and document
             the naming limitation — avoids migration
             but the inaccuracy compounds as more
             non-app projects are added.
Reasoning:   PROJECTS/ is the most neutral and
             future-proof name. It correctly describes
             any structured initiative — software app,
             consultancy, SaaS product, education
             platform — without implying software-only.
             Renaming now, before more projects are
             added, is the lowest-effort migration point.
Impact:      All paths containing APPS/ become PROJECTS/.
             REPOSITORY_ARCHITECTURE_V2.md must use
             PROJECTS/ throughout (OA-019 scope expanded).
             Historical Decision Records referencing
             APPS/ paths (DR-023, DR-024, DR-025, DR-027)
             are preserved as-is per the immutability
             principle — DR-028 is the authoritative
             record of the rename.
Related:     DR-016, DR-023, DR-024, DR-025, OA-019,
             OA-030

------------------------------------------------------------

DR-029
Title:       Context Before Action — decision integrity
             principle
Date:        2026-06-22
Status:      Active
Superseded By: None
Category:    Governance
Owner:       Project Owner
Decision:    No governed decision shall rely solely on
             model memory where an authoritative document
             exists. Before any governed work begins, the
             responsible agent must identify every
             authoritative document governing the
             requested work and consult those documents
             before any decision is made. The first
             question before any execution is: what
             governs this task?
             This principle protects decision integrity.
             It sits alongside the existing Read Before
             Write rule (which protects document
             integrity) and does not replace it.
Context:     During a folder cleanup session the Lead
             Architect applied incorrect naming
             conventions and placed documents in the
             wrong locations. The rules governing both
             decisions were already written in GOVERNANCE
             and REPOSITORY ARCHITECTURE. The Lead
             Architect acted from memory rather than
             consulting the authoritative documents
             first. The Project Owner identified the
             errors. The Architectural Reviewer reviewed
             the incident and proposed the principle
             framing adopted here — distinguishing
             decision integrity from document integrity.
Alternatives: Require all agents to read GOVERNANCE
             before every run — too broad, does not
             scale as governing documents multiply.
             Rely on the existing Read Before Write
             rule — insufficient; that rule protects
             files, not decisions.
Reasoning:   Memory-driven execution is a systemic
             risk for autonomous operation. Requiring
             agents to identify and consult the
             documents governing each specific task
             ensures correct behaviour is the natural
             outcome of following the system, not a
             function of individual AI recall.
Impact:      GOVERNANCE and EXECUTION must add Context
             Before Action as a new operational
             principle (OA-035). Agent contract template
             must add an Authoritative References
             section (OA-036). Consultation must become
             auditable (OA-037).
Related:     OA-035, OA-036, OA-037

------------------------------------------------------------

DR-030
Title:       SYSTEM folder renames — DOCUMENTS,
             RESOURCES, AGENT_CONTRACTS
Date:        2026-06-22
Status:      Active
Superseded By: None
Category:    Repository
Owner:       Project Owner
Decision:    Three folders within HOLDINGS/SYSTEM/
             are renamed:
               DOCS/            → DOCUMENTS/
               SUPPORT/         → RESOURCES/
               AI_ORGANISATION/ → AGENT_CONTRACTS/
Context:     DOCS/ was too abbreviated and ambiguous.
             SUPPORT/ did not accurately describe its
             contents. AI_ORGANISATION/ was verbose and
             imprecise — the folder contains agent
             contracts specifically, not the organisation
             as a whole.
Alternatives: Keep existing names — avoids path updates
             but compounds inaccuracy as the system grows.
Reasoning:   DOCUMENTS/ clearly states the folder
             contains governing documents. RESOURCES/
             better describes working materials, reports,
             and support files. AGENT_CONTRACTS/ is
             precise and self-describing.
Impact:      All path references must be updated.
             REPOSITORY_ARCHITECTURE must reflect new
             names in next version (OA-041).
Related:     DR-027, OA-041

------------------------------------------------------------

DR-031
Title:       Separate DECISIONS and OUTSTANDING_ACTIONS
             at SYSTEM and project level
Date:        2026-06-22
Status:      Active
Superseded By: None
Category:    Repository
Owner:       Project Owner
Decision:    DECISIONS/ and OUTSTANDING_ACTIONS/ folders
             exist at two levels:
               HOLDINGS/SYSTEM/DECISIONS/
               HOLDINGS/SYSTEM/OUTSTANDING_ACTIONS/
               HOLDINGS/PROJECTS/ZYRA/SYSTEM/DECISIONS/
               HOLDINGS/PROJECTS/ZYRA/SYSTEM/OUTSTANDING_ACTIONS/
             System-level entries belong in
             HOLDINGS/SYSTEM/. Project-specific entries
             belong in the relevant project folder.
Context:     All decisions and outstanding actions were
             previously held in ZYRA/SYSTEM/ regardless
             of whether they were system-wide or ZYRA-
             specific. As HOLDINGS grows to include
             multiple projects, system-level governance
             records must not be owned by any single
             project.
Alternatives: Keep all records in ZYRA/SYSTEM/ — does
             not scale when a second project is added.
             Single register at HOLDINGS level — loses
             project-level granularity.
Reasoning:   Clear separation ensures system-level
             governance is not buried inside a project
             folder and is accessible to all projects
             equally. Mirrors the structural principle
             that HOLDINGS/SYSTEM/ governs the whole
             organisation, not any single project.
Impact:      Existing registers must be audited and
             entries migrated to the correct level
             (OA-040). SYSTEM-level folders created
             and empty pending migration.
Related:     OA-040

------------------------------------------------------------

DR-032
Title:       DECISIONS/ renamed to DECISIONS_REGISTER/
Date:        2026-06-22
Status:      Active
Superseded By: None
Category:    Repository
Owner:       Project Owner
Decision:    The DECISIONS/ folder is renamed to
             DECISIONS_REGISTER/ at all levels:
               HOLDINGS/SYSTEM/DECISIONS_REGISTER/
               HOLDINGS/PROJECTS/ZYRA/SYSTEM/DECISIONS_REGISTER/
             Communicates that the folder is an
             authoritative register, not simply a
             collection of files.
Context:     Recommended by Architectural Reviewer to
             reinforce the register nature of the
             folder, consistent with how OUTSTANDING_
             ACTIONS already implies a register.
Alternatives: Keep DECISIONS/ — simpler but less
             self-describing.
Reasoning:   DECISIONS_REGISTER/ is precise and
             self-describing.
Impact:      All path references to DECISIONS/ must
             be updated. Captured in OA-041 scope.
Related:     DR-031, OA-041

------------------------------------------------------------

DR-033
Title:       MASTER naming for HOLDINGS-level governing
             documents
Date:        2026-06-22
Status:      Active
Superseded By: None
Category:    Repository
Owner:       Project Owner
Decision:    Three foundational document folders within
             HOLDINGS/SYSTEM/DOCUMENTS/ are renamed:
               GOVERNANCE/   → MASTER_GOVERNANCE/
               EXECUTION/    → MASTER_EXECUTION/
               ARCHITECTURE/ → MASTER_ARCHITECTURE/
             AGENT_CONTRACTS/ is unchanged.
             Establishes an immediate visual distinction
             between HOLDINGS-level and project-level
             governance:
               HOLDINGS/SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/
               PROJECTS/ZYRA/SYSTEM/GOVERNANCE/
Context:     As HOLDINGS grows, the inheritance
             relationship between organisation-wide
             and project-specific governance must be
             legible from the folder structure alone.
Alternatives: HOLDINGS_ prefix — redundant given
             folder already sits in HOLDINGS/SYSTEM/.
             No prefix — loses visual distinction when
             project-level governance folders are added.
Reasoning:   MASTER_ is the clearest signal that a
             document governs the whole organisation.
             Scales cleanly as new projects are added.
Impact:      All path references within
             HOLDINGS/SYSTEM/DOCUMENTS/ must be
             updated to MASTER_ prefix. Captured in
             OA-041 scope.
Related:     DR-030, OA-041

------------------------------------------------------------

DR-034
Title:       Chief of Staff renamed to PA
             (Personal Assistant)
Date:        2026-06-22
Status:      Active
Superseded By: None
Category:    Governance
Owner:       Project Owner
Decision:    The Owner Interface Agent role previously
             referred to as Chief of Staff is renamed
             to PA (Personal Assistant). This is the
             approved conversational name for the role
             going forward.
Context:     Chief of Staff felt too formal and did not
             reflect the day-to-day personal assistance
             nature of the role. PA is clearer and more
             intuitive for how the Project Owner will
             interact with the agent.
Alternatives: Keep Chief of Staff. Use Owner Assistant.
Reasoning:   PA is direct and self-describing. It
             accurately reflects the agent's purpose —
             serving the Project Owner's needs within
             the organisation rather than a strategic
             leadership function.
Impact:      OA-032 title updated. All future references
             to this agent use PA. Contract to be written
             using PA as the agent name.
Related:     OA-032

------------------------------------------------------------

DR-035
Title:       Operational records use daily logs not
             V docs
Date:        2026-06-22
Status:      Active
Superseded By: None
Category:    Governance
Owner:       Project Owner
Decision:    Operational records — specifically
             OUTSTANDING_ACTIONS and DECISIONS registers
             at both SYSTEM level and PROJECT level —
             are maintained as daily log files, not V
             docs. One file per day, named by date.
             Format: [DOCUMENT_NAME]_[YYYY-MM-DD].md
             Example:
               OUTSTANDING_ACTIONS_2026-06-22.md
               DECISIONS_2026-06-22.md
             Applies to: HOLDINGS/SYSTEM/ operational
             records and HOLDINGS/PROJECTS/ZYRA/SYSTEM/
             operational records. Applies to all future
             projects.
Context:     Operational records are written to daily
             and do not represent a governed baseline
             that requires versioning. V docs are for
             governing documents (governance, contracts,
             architecture). Operational records are
             living logs — treating them as V docs adds
             unnecessary overhead and versioning
             complexity. Daily logs are more transparent,
             easier to audit, and align with how agents
             will write to them autonomously at Level 4.
Alternatives: Keep as V docs with frequent publication.
             Use a single rolling file appended daily.
Reasoning:   Daily logs match the operational nature
             of the content. The Reporting Agent writes
             a daily entry; the Repository Agent creates
             the file. No approval cycle needed for
             operational log entries. Audit is by date,
             not by version.
Impact:      OA-040 updated — SYSTEM-level migration
             produces daily log files not V1 documents.
             Existing ZYRA OUTSTANDING_ACTIONS_V2.md
             and DECISIONS_V1.md to be migrated to
             daily log format as part of OA-040.
             Reporting Agent and Repository Agent
             contracts to be updated to reflect daily
             log responsibility.
             OA-065 raised to cover this work.
Related:     OA-040, OA-065

------------------------------------------------------------

DR-036
Title:       Four-layer contract architecture
             considered locked
Date:        2026-06-22
Status:      Approved
Category:    Architecture
Decision:
  The four-layer contract inheritance model is
  formally locked as an architectural constant:
    Base Role — defines capability
    Organisation — defines who holds responsibility
    SYSTEM — defines how the agent behaves in
              HOLDINGS/SYSTEM/ scope
    PROJECT — defines how the agent behaves in
              a specific project scope
  No structural redesign of this model is permitted
  without a superseding DR approved by the Project
  Owner. New agents inherit this model. New projects
  create PROJECT-layer implementations only —
  they do not alter Base Roles or Organisation
  contracts.
  This decision consolidates and locks all
  architectural work performed in Phase 1.
Rationale:
  ChatGPT architectural review (all four batches,
  2026-06-22) confirmed the model is working as
  intended. Each layer introduces only information
  unique to that level. No cross-layer leakage was
  found. The model is now reusable without
  modification.
Implications:
  CONTRACT_TEMPLATE V2 is the locked baseline for
  this layer model. V3 may add sections but may
  not change the layer structure.
  All future project implementations follow the
  same pattern as PROJECT:ZYRA.
Decided By:   Lead Architect (Claude)
              Architectural Reviewer (ChatGPT)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-037
Title:       Phase 1 contract design review complete
             — ChatGPT four-batch architectural review
             concluded
Date:        2026-06-22
Status:      Approved
Category:    Milestone
Decision:
  Phase 1 agent contract design review is considered
  complete following the four-batch ChatGPT
  architectural review covering:
    Batch 1 — Base Role contracts (7 contracts)
    Batch 2 — Organisation contracts (7 contracts)
    Batch 3 — SYSTEM implementation contracts
               (7 contracts)
    Batch 4 — PROJECT:ZYRA contracts (8 contracts)
  All 29 contracts reviewed. No structural redesign
  recommended. Reviewer confirmed contracts are
  "approximately 90–95% architecturally complete"
  and rated progress as Excellent across all batches.
  Outstanding refinements are captured in the OA
  register (OA-066 through OA-092) and are carried
  forward as backlog items, not blockers.
  CONTRACT_TEMPLATE V2 remains the active standard.
  CONTRACT_TEMPLATE V3 design begins via OA-090
  once V2 has been used for at least one approval
  cycle.
Rationale:
  The review confirmed the contracts read as
  organisational design documents, not AI prompts.
  That was the stated architectural goal.
Implications:
  Phase 1 design is complete. Remaining work moves
  into refinement and testing preparation.
  OA-022 (complete all agent contracts) will be
  updated to reflect review completion.
  The next phase of the build may now be considered.
Decided By:   Lead Architect (Claude)
              Architectural Reviewer (ChatGPT)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-038
Title:       Agent contract folders renamed from
             AGENT_CONTRACTS to AGENTS
Date:        2026-06-22
Status:      Approved
Category:    Repository
Decision:
  Both agent contract folders are renamed:
    HOLDINGS/SYSTEM/DOCUMENTS/AGENT_CONTRACTS/
    → HOLDINGS/SYSTEM/DOCUMENTS/AGENTS/
    HOLDINGS/PROJECTS/ZYRA/SYSTEM/AGENT_CONTRACTS/
    → HOLDINGS/PROJECTS/ZYRA/SYSTEM/AGENTS/
  AGENTS is the approved folder name going forward.
  All future project implementations use AGENTS/
  not AGENT_CONTRACTS/ when creating the equivalent
  folder.
Rationale:
  Shorter, cleaner name. The folder already implies
  contracts by context of its contents.
Implications:
  Any OA items or governance documents referencing
  AGENT_CONTRACTS/ as a path should be updated
  to AGENTS/ at the next update batch.
  CHATGPT_REVIEW_HANDOVER_2026-06-22.md references
  the old path — this is an archived document and
  does not require correction.
Decided By:   Project Owner (Shakeel)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-039
Title:       Impact Analysis is a mandatory gate
             before any structural change
Date:        2026-06-22
Status:      Approved
Category:    Governance
Decision:
  Any structural change to the repository requires
  a completed Impact Report before execution is
  approved. This is a hard gate, not advisory.
  Structural changes covered:
    Folder restructures.
    Document moves or renames.
    Governance rule changes.
    Repository Architecture changes.
    Any change affecting multiple files or
    cross-references.
  The Impact Report must identify all directly
  affected files and all cross-references requiring
  update. No structural change proceeds without it.
  Exception: emergency changes approved by Project
  Owner with Impact Report produced retrospectively
  within the same session.
Rationale:
  Structural changes without impact analysis have
  caused downstream reference failures. The gate
  makes consequences visible before they happen.
Implications:
  Impact Analysis Agent is a mandatory pre-step
  in the Orchestrator routing for all structural
  change requests. Governance V4 documents this
  as a formal rule.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-040
Title:       Decision provenance logging is mandatory
             for all AI Organisation decisions
Date:        2026-06-22
Status:      Approved
Category:    Governance
Decision:
  Every decision made within the AI Organisation
  must be logged with full provenance. Applies to
  both human and autonomous decisions.
  Every log entry must capture:
    Who — Project Owner by name, or the specific
    agent (Orchestrator, Resolution Classifier, etc.)
    When — timestamp of the decision.
    What — the decision made and what it acted on.
    Why — the rule or V doc that authorised it.
    Outcome — what changed as a result.
    Reversible — yes or no, and how if yes.
  Autonomous agents log to their assigned log file.
  The PA logs Project Owner decisions to the
  DECISIONS register within the same session.
Rationale:
  Without provenance, decisions cannot be audited,
  reversed, or used to explain agent behaviour.
  This is the foundation of the action traceability
  rule (OA-064, DR-046).
Implications:
  All agent contracts must reference this rule.
  Governance V4 documents this as a formal rule.
  Logging Standard (OA-068) defines the log format.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-041
Title:       Standard SYSTEM document lifecycle defined
Date:        2026-06-22
Status:      Approved
Category:    Governance
Decision:
  Every SYSTEM document follows this lifecycle:
    Proposal — idea raised, not yet drafted.
    Draft — document under construction. Not active.
    Review — submitted to Architectural Reviewer
    and/or Master Reviewer. Not active.
    Approved — Project Owner approved. Active baseline.
    Published as V[N].
    Archived — superseded by a newer version.
    Renamed with date. Reference only.
  No document may be used as authoritative until
  it reaches Approved status.
  No document skips stages without explicit Project
  Owner instruction and a logged DR explaining why.
Rationale:
  Without a formal lifecycle, documents are used
  before they are ready and retired without a record.
Implications:
  Governance V4 and Execution V4 document this
  lifecycle as a formal standard.
  All agent contracts reference this lifecycle
  when describing document handling.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-042
Title:       Real-time logging discipline is mandatory
             within every session
Date:        2026-06-22
Status:      Approved
Category:    Governance
Decision:
  All approved decisions and outstanding actions
  are logged in the same session they are made.
  Where a loggable item arises and has not yet been
  logged, the Lead Architect carries it forward in
  the response chain until it is logged. No session
  ends with unlogged approved decisions or actions.
  This applies to the Lead Architect in Phase 1.
  At Level 4 this transfers to the PA (decisions
  register) and Reporting Agent (OA register).
Rationale:
  Unlogged decisions accumulate across sessions and
  create gaps in the authoritative record. Real-time
  logging keeps the repository accurate at all times.
Implications:
  Governance V4 and Execution V4 document this rule.
  PA contract references this as a core responsibility.
  Reporting Agent contract references this for OA
  and daily log responsibilities.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-043
Title:       Strategic Leadership layer has a four-
             member upper limit
Date:        2026-06-22
Status:      Approved
Category:    Architecture
Decision:
  The Strategic Leadership layer has an upper limit
  of four active members. Expansion beyond four
  requires explicit justification and Project Owner
  approval via the normal governance process.
  Current Strategic Leadership members (five, above
  limit — noted as an open architectural question):
    Lead Architect
    Architecture Partner
    Critical Thinking Agent
    PA
    Master Reviewer
  The five-vs-four question was raised in the ChatGPT
  review and remains open. Resolution options:
    Reduce to four by reassigning one agent to
    another layer.
    Formally approve five as the limit for this
    organisation with a DR explaining why.
  This must be resolved before Governance V4 is
  written so V4 documents the correct limit.
  Adding to OA register as a blocking item for V4.
Rationale:
  Layer limits prevent authority dilution. Without
  a formal limit the layer grows without governance.
Implications:
  Governance V4 documents the approved limit.
  OA-045 resolved — limit is confirmed as a
  governance rule. The specific count (4 vs 5)
  requires a separate decision before V4.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-044
Title:       Every V doc must live in its own
             dedicated folder
Date:        2026-06-22
Status:      Approved
Category:    Repository
Decision:
  Every V doc must live in its own dedicated folder.
  A V doc must never sit loose inside a parent folder
  alongside unrelated files.
  Accepted exception: master folders containing
  dedicated subfolders (e.g. AGENTS/ with one
  subfolder per agent) — provided every V doc has
  its own subfolder.
  No V doc may share a folder with another V doc
  unless they are in separate subfolders.
Rationale:
  Loose V docs in shared folders create naming
  collisions, make auditing harder, and break the
  one-document-per-folder model that repository
  agents rely on for deterministic filing.
Implications:
  Governance V4 documents this as a formal
  repository structure rule.
  Repository Agent contract enforces this on
  every filing operation.
  System Auditor checks compliance each cycle.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-045
Title:       Review and handover documents go in
             RESOURCES/TEMPORARY/ with dated filenames
Date:        2026-06-22
Status:      Approved
Category:    Repository
Decision:
  Any document produced for external review or
  handover (ChatGPT review briefs, handover notes,
  review summaries) must be filed in:
    SYSTEM/RESOURCES/TEMPORARY/
  Naming convention:
    [DOCUMENT_NAME]_[YYYY-MM-DD].md
  If more than one review or handover document is
  produced on the same day:
    [DOCUMENT_NAME]_[YYYY-MM-DD]_Part1.md
    [DOCUMENT_NAME]_[YYYY-MM-DD]_Part2.md
  These documents are never V docs. They must never
  be filed in DOCUMENTS/ or alongside governed
  documents such as agent contracts.
Rationale:
  Handover documents placed in governed folders
  pollute the document store and confuse agents
  that scan for authoritative documents.
Implications:
  Governance V4 documents this as a formal rule.
  Repository Agent contract enforces this placement.
  Documentation Agent contract notes this as
  explicitly out of scope for its filing operations.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-046
Title:       Action traceability rule — every agent
             action must be traceable to a V doc
Date:        2026-06-22
Status:      Approved
Category:    Governance
Decision:
  Every action taken by any agent must be traceable
  to a specific V doc and rule. When the Project
  Owner questions why an agent did something, the
  agent (or PA at Level 4) must respond with one
  of two answers only:
    Answer A — Governing document exists:
      "This action was taken because [V doc],
      [version], [section/rule]."
    Answer B — No governing document exists:
      "There is no governing document that covers
      this action."
  Answer B is not an admission of error. The agent
  may have acted correctly on reasonable inference.
  Answer B is a signal that a governance rule may
  need to be written.
  This rule applies to any "why did it do that?"
  question — not only when a mistake is suspected.
Rationale:
  Without traceability, governance gaps are
  invisible. Answer B creates a direct pipeline
  from agent behaviour to governance improvement.
  Depends on DR-040 (decision provenance logging).
Implications:
  All agent contracts must include this rule.
  Governance V4 documents this as a formal rule.
  PA contract references this as a core function.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-047
Title:       System Auditor to evolve from compliance
             auditing to effectiveness auditing
Date:        2026-06-22
Status:      Approved
Category:    Architecture
Decision:
  The System Auditor will evolve in two stages:
  Stage 1 (current) — Compliance auditing:
    Are agents following governance rules?
    Are documents named correctly?
    Are V doc rules respected?
  Stage 2 (before Level 5) — Effectiveness auditing
  added alongside compliance:
    Is this governance still producing the desired
    outcome?
    Have previously approved rules become unnecessary?
    Are multiple agents solving the same problem?
    Has bureaucracy increased unnecessarily?
    Is complexity increasing faster than value?
  Stage 2 does not replace Stage 1. Both run.
  Effectiveness findings are observations, not
  breach findings. They are reported to the Project
  Owner as organisational health intelligence.
  The boundary between compliance (breach or not)
  and effectiveness (healthy or not) must be a
  distinct section in the System Auditor contract.
Rationale:
  A system that only checks compliance will follow
  rules correctly while becoming less useful. The
  System Auditor is the natural owner of
  organisational health questions.
Implications:
  System Auditor contract updated in next batch.
  Organisation Health Framework (OA-079) is the
  structured tool for effectiveness reporting.
  Governance V4 documents this dual mandate.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-048
Title:       Pre-V-doc OA sweep is mandatory before
             any scheduled V doc production
Date:        2026-06-22
Status:      Approved
Category:    Governance
Decision:
  Before any scheduled V doc production, the system
  must sweep the OA register for items that:
    Target the document being produced.
    Are currently unblocked (dependencies met).
    Are not Low priority or Level 5 Evolution items.
  Those OAs are actioned first. Only when the sweep
  is complete — or no eligible OAs remain — does
  the Documentation Agent produce the V doc.
  The sweep result is logged:
    Either: "[N] OAs cleared before production."
    Or: "Sweep complete — no eligible OAs found."
  Emergency or unscheduled V docs are exempt. The
  Lead Architect must note the exemption in the
  session log.
Rationale:
  Writing a V doc before clearing eligible OAs
  creates an immediate need for a follow-up version.
  The sweep rule prevents avoidable version churn
  and keeps documents complete on first production.
Implications:
  Orchestrator routing must include the sweep as a
  mandatory pre-step for scheduled V doc tasks.
  Governance V4 documents this as a formal rule.
  OA-094 is resolved by this DR.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-049
Title:       Strategic Leadership layer has no fixed
             upper limit — DR-043 superseded
Date:        2026-06-22
Status:      Approved
Category:    Architecture
Supersedes:  DR-043
Decision:
  DR-043 (Strategic Leadership 4-member upper limit)
  is superseded and no longer applies.
  The Strategic Leadership layer has no fixed
  upper limit. The current membership of five is
  approved:
    Lead Architect
    Architecture Partner
    Critical Thinking Agent
    PA
    Master Reviewer
  New Strategic Leadership agents may be added when
  justified by organisational need and approved by
  the Project Owner via the standard governance
  process. No numerical cap applies.
Rationale:
  A fixed cap creates an artificial constraint that
  forces layer reassignment when the real question
  is whether an agent belongs in Strategic Leadership
  by function. Functional fit is the correct test,
  not headcount. All five current members clearly
  perform strategic functions.
Implications:
  Governance V4 documents Strategic Leadership
  membership by functional criteria only — no cap.
  OA-045 was completed against DR-043 — the
  governance rule it sought is now updated by
  this DR. The rule in V4 will reflect DR-049,
  not DR-043.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-050
Title:       Auditable consultation logging is a
             mandatory workflow pre-step
Date:        2026-06-22
Status:      Approved
Category:    Governance
Decision:
  Every workflow run must log the following before
  any governed work begins:
    Governing documents consulted.
    Document versions at time of consultation.
    Consultation timestamp.
  This log is the primary evidence the System
  Auditor uses to verify Context Before Action
  compliance. It is produced by the agent executing
  the workflow, not by the Reporting Agent.
  Defined in Execution V4 as a mandatory pre-step
  for every workflow run.
Rationale:
  Without consultation logging, Context Before
  Action (DR-029) cannot be audited. The rule
  exists but leaves no evidence of compliance.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-051
Title:       Decision Records sit below Governance
             in the authority hierarchy
Date:        2026-06-22
Status:      Approved
Category:    Governance
Decision:
  Decision Records (DRs) are authoritative
  explanatory records. They sit below Governance
  in the authority hierarchy:
    Project Owner
    ↓
    Governance (V doc)
    ↓
    Decision Records
    ↓
    Execution (V doc)
    ↓
    Agent Contracts
  DRs explain why a governance rule exists and
  record the reasoning behind a decision. They
  inform future implementation but do not override
  Governance. If a DR conflicts with Governance,
  Governance takes precedence unless a new
  Governance version is produced to incorporate
  the DR's intent.
  DRs may not be used to bypass or override
  Governance rules without a new Governance version.
Rationale:
  Without a defined position, DRs risk being used
  to override Governance informally. The hierarchy
  makes the boundary explicit.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-052
Title:       Auto-logging and conflict detection
             are mandatory operational rules
Date:        2026-06-22
Status:      Approved
Category:    Governance
Decision:
  Two rules are confirmed as mandatory operational
  rules for Governance V4 Section 10:
  Rule 1 — Auto-logging:
    The Lead Architect logs all decisions and
    actions as DRs and OAs the moment they are
    agreed in conversation. Logging does not
    require a prompt and does not wait for
    Project Owner confirmation. At Level 4 this
    transfers to the PA (DRs) and Reporting Agent
    (OAs).
  Rule 2 — Conflict detection:
    If two logged items conflict — whether
    auto-logged or previously approved — the
    conflict is flagged immediately. The conflict
    is never resolved unilaterally. Resolution
    authority by level:
      Level 3: Lead Architect flags, Project
      Owner resolves.
      Level 4+: System Auditor detects, PA
      surfaces to Project Owner, Project Owner
      resolves.
    The conflicting items remain in their logged
    state until resolution is approved.
Rationale:
  Depends on DR-042 (real-time logging discipline).
  Extends it with automatic triggering and conflict
  detection to make logging fully governed.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-053
Title:       Operational rules confirmed for
             Governance V4 Section 10
Date:        2026-06-22
Status:      Approved
Category:    Governance
Decision:
  The following operational rules are confirmed
  for inclusion in Governance V4 Section 10.
  They are not held in a separate document — they
  belong in Governance as the single source of truth.
  The PA surfaces relevant Section 10 rules as
  part of the session briefing.
  Confirmed rules:
    Auto-log all OAs and DRs immediately without
    waiting for confirmation (DR-052).
    Typos and minor errors are corrected directly
    — no OA or approval required.
    When a ChatGPT recommendation is accepted,
    do not reply — log and continue.
    Any agreed operational preference that must
    persist across sessions is logged as a DR
    or OA immediately, not deferred.
    Context Before Action applies before any
    governed work begins (DR-029).
    Real-time logging discipline applies within
    every session (DR-042).
    Action traceability — every agent action must
    be traceable to a V doc (DR-046).
    Pre-V-doc OA sweep before any scheduled V
    doc production (DR-048).
    Pre-production cut-off rule — OAs added after
    the 24-hour cut-off are deferred to the next
    cycle (OA-095).
Rationale:
  Operational rules scattered across session history
  are invisible to agents. Section 10 of Governance
  is the authoritative location for all rules that
  govern how sessions and workflows run.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-054
Title:       PA session briefing components confirmed
Date:        2026-06-22
Status:      Approved
Category:    Governance
Decision:
  The PA session briefing pack is confirmed as:
    1. Current Outstanding Actions — open items
       relevant to the session scope.
    2. Decisions relevant to session — DRs that
       govern the work planned for this session.
    3. Active operational rules — Section 10
       rules from Governance currently in effect.
    4. Required governing references — V docs
       the Lead Architect must consult before
       beginning work.
    5. Session context and declared purpose —
       what this session is intended to achieve.
  The Lead Architect begins every session from
  documented context, not reconstructed memory.
  This is the architectural implementation of
  Context Before Action (DR-029) at session level.
  At Level 3 the Lead Architect self-briefs using
  this structure. At Level 4 the PA produces
  and delivers this briefing automatically.
Rationale:
  Session context reconstructed from memory
  creates drift. A structured briefing pack
  eliminates this and makes every session
  auditable.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-055
Title:       Numbered draft status convention
             confirmed as formal standard
Date:        2026-06-22
Status:      Approved
Category:    Governance
Decision:
  When producing a draft document, the status
  field must include a sequential number to
  identify which iteration it is.
  Format: Draft 1, Draft 2, Draft 3, etc.
  Applies to all draft documents across the
  project. Prevents ambiguity when multiple
  draft rounds occur before approval.
  Upon approval, the document is promoted to
  V1 regardless of how many draft iterations
  preceded it. Draft numbers do not carry
  forward into version numbers.
Rationale:
  Without numbered drafts, "Draft" is ambiguous
  — it is impossible to tell whether a document
  is on its first or fifth iteration.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-056
Title:       Templates use Draft numbering until
             approved — first approval is V1
Date:        2026-06-22
Status:      Approved
Category:    Governance
Decision:
  Templates must not receive a version number
  (V1, V2, etc.) until they are confirmed and
  approved. Pre-approval iterations use Draft
  numbering only (Draft 1, Draft 2, etc.).
  Upon approval, the first confirmed version
  becomes V1. This rule applies to all templates
  across the project.
  A template on its fourth draft iteration is
  still Draft 4, not V4. On approval it becomes
  V1.
Rationale:
  Version numbers on unapproved templates imply
  authority they do not have. Draft numbering
  makes the unapproved status unambiguous.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-057
Title:       Evidence Vocabulary V1 approved as
             the standard evidence type reference
Date:        2026-06-22
Status:      Approved
Category:    Governance
Decision:
  EVIDENCE_VOCABULARY_CURRENT_VERSION_V1.md is approved as the
  authoritative reference for all evidence types
  used across the AI Organisation.
  Location: SYSTEM/DOCUMENTS/EVIDENCE_VOCABULARY/
  All contracts that reference findings, reports,
  logs, impact reports, audit reports, review
  findings, dependency maps, or run summaries
  must use the definitions in this document.
  The evidence hierarchy defined in Section 3
  governs precedence when evidence types conflict.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-058
Title:       Logging Standard V1 approved as the
             mandatory logging reference
Date:        2026-06-22
Status:      Approved
Category:    Governance
Decision:
  LOGGING_STANDARD_CURRENT_VERSION_V1.md is approved as the
  mandatory logging standard for all agents.
  Location: SYSTEM/DOCUMENTS/LOGGING_STANDARD/
  All agent contracts must reference this document
  for logging behaviour. Contracts that currently
  define their own logging rules are retrofitted
  in the next contract update batch to reference
  LOGGING_STANDARD_V1 instead.
  The mandatory log entry fields defined in
  Section 3 (Timestamp, Agent, Action, Governing
  Reference, Outcome, Reversible) apply to every
  log entry across every agent.
  Logs are append-only. No agent may modify or
  delete a log entry once written.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-059
Title:       Organisation Health Framework V1
             approved — System Auditor reports
             against eight categories each cycle
Date:        2026-06-22
Status:      Approved
Category:    Architecture
Decision:
  ORGANISATION_HEALTH_FRAMEWORK_V1.md is approved.
  Location: SYSTEM/DOCUMENTS/ORGANISATION_HEALTH/
  The eight health categories are confirmed:
    Governance, Architecture, Execution, Quality,
    Operational, Agent, Repository, Capability.
  The System Auditor rates each category GREEN,
  AMBER, or RED every audit cycle based on
  observable evidence only.
  RED items are reported directly to the Project
  Owner. AMBER items are reported to the Lead
  Architect.
  The first audit cycle using this framework
  establishes the baseline. Trend comparison
  begins from the second cycle.
  The System Auditor contract is updated in the
  next contract update batch to reference this
  framework.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-060
Title:       Standards Library Draft 1 produced —
             to be approved as V1 after Governance V4
Date:        2026-06-22
Status:      Approved
Category:    Governance
Decision:
  STANDARDS_LIBRARY_Draft1.md is produced and
  reviewed. It is not yet V1 because Governance V4
  (OA-025) may define additional standards that
  belong here. Once V4 is written, the Standards
  Library is finalised and approved as V1.
  Location: SYSTEM/DOCUMENTS/MASTER_STANDARDS/
  The Standards Library consolidates: Naming
  Standards, Placement Standards, Versioning
  Standards, Review Standards, Classification
  Standards, and Reporting Standards.
  Sections 8 and 9 are pointer-only sections —
  they direct to LOGGING_STANDARD_V1 and
  EVIDENCE_VOCABULARY_V1 rather than duplicating
  content.
  Implementation contracts reference the Standards
  Library V1 once it is approved, rather than
  embedding standards independently.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-061
Date:         2026-06-22
Title:        Stage 4 contract batch complete — all
              contracts promoted to V2 (Orchestrator V3)
Context:
  Stage 4 of the Governance V4 roadmap executed
  a batch update of all 29 agent contracts.
  Updates applied:
    OA-067: Governing authority chain note added to
    all contracts (Project Owner → Governance →
    Lead Architect → Agent).
    OA-074: Critical Thinking Agent V2 — forward-look
    question added as responsibility 6.
    OA-075: Master Reviewer V2 — five-level severity
    classification (Critical/Major/Minor/Observation/
    Recommendation) replacing old Compliant/Gaps/
    Recommended Revisions categorisation.
    OA-081: Inspection Agent Base Role, SYSTEM,
    PROJECT:ZYRA all V2 — finding type classification
    (Structural/Documentation/Governance/Operational)
    made explicit with both dimensions mandatory.
    OA-084: Impact Analysis Agent Base Role, SYSTEM,
    PROJECT:ZYRA all V2 — seven impact categories
    (Technical/Governance/Operational/Repository/
    Agent/Documentation/Execution) added.
    OA-069: System Auditor V2 — Inspection history
    added as primary evidence source. Inspection
    Agent V2 — history retention for System Auditor
    noted in Evolution section.
    OA-093: Repository Agent Base Role, SYSTEM,
    PROJECT:ZYRA all V2 — Draft-to-V1 promotion
    added as responsibility 9. Orchestrator V3 —
    Draft promotion routing added as responsibility 8.
    DR-058: All contracts' internal logging lines
    replaced with LOGGING_STANDARD_V1 reference.
    DR-059: System Auditor V2 references
    ORGANISATION_HEALTH_FRAMEWORK_V1 as mandatory
    input; audit report restructured into Part 1
    (health summary) and Part 2 (compliance findings).
  All V1 contracts archived with date:
  [NAME]_2026-06-22_V1.md.
  Orchestrator V2 archived as ORCHESTRATOR_
  2026-06-22_V2.md.
Decision:
  All 29 contracts are now at V2. Orchestrator is
  at V3. V1 originals are archived. This closes
  Stage 4 of the Governance V4 roadmap.
  OAs closed: OA-067, OA-069, OA-074, OA-075,
  OA-081, OA-084, OA-093.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-062
Date:         2026-06-22
Title:        Governance updates trigger companion V doc
              batch; non-update pattern triggers
              reclassification review
Context:
  Governance V4 production raised the question of
  whether EXECUTION_V3 and REPOSITORY_ARCHITECTURE_V1
  need updating when Governance is updated. Analysis
  confirmed they do — both have stale version
  references and substantive sections that predate
  the AI Organisation model. This identified a
  systemic gap: no rule existed requiring V docs to
  be reviewed as a batch when a master V doc changes.
  A second gap was identified: no rule existed to
  flag V docs that consistently do not update across
  governance cycles — raising the question of whether
  they are correctly classified as V docs.
Decision:
  Two rules are adopted:
  RULE 1 — CASCADE DETECTION: When a master V doc is
  updated, the Impact Analysis Agent maps all V docs
  that reference it. Dependent V docs are included
  in the current update batch or explicitly deferred
  with a logged reason. No V doc update is complete
  without the cascade check. (OA-098)
  RULE 2 — NON-UPDATE PATTERN: The System Auditor
  tracks V doc update frequency each governance
  cycle. Any V doc not updated across two or more
  consecutive cycles is flagged to the Lead Architect:
  "Is this still correctly classified as a V doc?"
  The Lead Architect decides: reclassify, keep with
  logged reason, or convert. (OA-098)
  These rules enter Governance V4 as V doc lifecycle
  principles. The operational workflow enters
  Execution V4. OA-096 (Execution V4) and OA-097
  (Repository Architecture V2) are raised as Stage
  5b and 5c of the Governance V4 roadmap.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-063
Date:         2026-06-22
Title:        GOVERNANCE_V4 approved — active baseline
Context:
  Governance V3 governed ZYRA as a single project.
  V4 expands scope to HOLDINGS — all projects.
  All decisions since V3 absorbed. New sections:
  Holding Company Structure (Section 2), Two-Tier
  SYSTEM Model (Section 4), AI Organisation (Section 5),
  V Doc Lifecycle Rules (Section 13). Authority hierarchy
  updated to include Agent Contracts below Execution and
  confirms Decision Records below Governance (DR-051).
  Action Traceability added as Principle 10 (DR-046).
  Draft-to-V1 promotion rule added (Section 12.4).
  Agent Output Review added to Review Model (Section 15.4).
  Severity levels expanded with finding type, impact
  category, and review severity dimensions (Section 16).
  Four reference standards added to Referenced Documents.
Decision:
  GOVERNANCE_V3 archived as GOVERNANCE_2026-06-22_V3.md.
  GOVERNANCE_V4 is the active baseline.
  OA-025 completed.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-064
Date:         2026-06-22
Title:        EXECUTION_V4 approved — active baseline
Context:
  Execution V3 predated the AI Organisation model.
  Section 12 (AI Collaboration Workflow) rewrote to
  reflect the Orchestrator-mediated operational flow,
  pre-V-doc production workflow, and updated role
  descriptions including AI Organisation oversight.
  New Section 26: Automation Schedule — daily run
  cadence, per-run outputs, morning briefing format,
  V doc production scheduling, audit cycle cadence.
  Appendix E updated: all current documents and
  reference standards listed. Relationship to Governance
  updated to reference V4.
Decision:
  EXECUTION_V3 archived as EXECUTION_2026-06-22_V3.md.
  EXECUTION_V4 is the active baseline.
  OA-096 completed.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-065
Date:         2026-06-22
Title:        REPOSITORY_ARCHITECTURE_V2 approved —
              active baseline
Context:
  Repository Architecture V1 predated the Holdings
  structure, the two-tier SYSTEM model, and the AI
  Organisation. V2 adds:
  Section 4: Holdings Repository Structure (replaces
  single-project flat structure). SYSTEM/ and PROJECTS/
  layout defined.
  Section 5: Two-Tier SYSTEM Model folder detail.
  Tier 1 (HOLDINGS/SYSTEM/) and Tier 2
  (PROJECTS/[PROJECT]/SYSTEM/) with full paths.
  Section 6: AI Organisation folder structure — four-layer
  contract model paths, naming rules, contract version rule.
  Section 7: Reference Standards placement — all four
  reference standard documents with locations.
  Old sections renumbered (5→8 through 11→14).
  Appendix A updated to HOLDINGS/ tree as of V2.
  Appendix B updated with agent contract types,
  daily log type, and Draft document type.
Decision:
  REPOSITORY_ARCHITECTURE_V1 archived as
  REPOSITORY_ARCHITECTURE_2026-06-22_V1.md.
  REPOSITORY_ARCHITECTURE_V2 is the active baseline.
  OA-097 completed.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-066
Date:         2026-06-22
Title:        CONTRACT_TEMPLATE_V3 approved —
              active baseline
Context:
  CONTRACT_TEMPLATE_V2 was the baseline used for all
  29 contracts produced in Stage 4. V3 incorporates
  four template enhancements raised in the ChatGPT
  architectural review (Round 4) and consolidated
  under OA-090:
    ASSUMPTIONS section (OA-087) — what the agent
    presupposes to be true before execution.
    OUT OF SCOPE section (OA-088) — responsibility
    boundaries distinct from authority boundaries.
    Agent Maturity field in IDENTITY (OA-089) —
    Experimental / Stable / Deprecated.
    COMPLETION CRITERIA section (OA-071) — observable
    binary conditions confirming a specific run is done.
  V3 also bakes in at template level:
    Authority chain (OA-067) in AUTHORITATIVE REFERENCES
    and AUTHORITY & BOUNDARIES — no longer retrofit-only.
    Draft-to-V1 promotion rule (OA-093) in the template
    preamble — mandatory for all agents.
    LOGGING_STANDARD_V1 as a mandatory Always Consult
    entry — no per-responsibility logging rules needed.
    COMPLETION CRITERIA — SYSTEM AUDITOR CHECK subsection
    — defines what the System Auditor inspects against
    each agent's completion criteria.
    VERSION HISTORY section added — all contracts must
    now record version changes.
    Governing Doc field in template header pointing to
    GOVERNANCE_V4.
  V2 archived as CONTRACT_TEMPLATE_2026-06-22_V2.md.
Decision:
  CONTRACT_TEMPLATE_V2 archived.
  CONTRACT_TEMPLATE_V3 is the active baseline.
  All 29 agent contracts to be retrofitted to V3 in
  Stage 7 (the next contract update batch).
  OA-090 completed.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

DR-067
Date:         2026-06-22
Title:        Stage 7 contract batch complete — all 29
              contracts retrofitted to CONTRACT_TEMPLATE V3
Context:
  CONTRACT_TEMPLATE V3 (DR-066) added four new sections
  and three structural improvements over V2. This batch
  retrofits all 29 agent contracts to the new template.
  Contracts updated:
    Base Roles (7): Documentation Agent, Impact Analysis
    Agent, Inspection Agent, Output Review Agent, Reporting
    Agent, Repository Agent, Resolution Classifier.
    Organisation (7): Architecture Partner, Critical
    Thinking Agent, Lead Architect, Master Reviewer,
    Orchestrator (V3→V4), PA, System Auditor.
    SYSTEM Implementations (7): Documentation Agent,
    Impact Analysis Agent, Inspection Agent, Output Review
    Agent, Reporting Agent, Repository Agent, Resolution
    Classifier.
    PROJECT:ZYRA Implementations (8): Documentation Agent,
    Impact Analysis Agent, Inspection Agent, Output Review
    Agent, Project Readiness Agent, Reporting Agent,
    Repository Agent, Resolution Classifier.
  Changes applied to every contract:
    Header: ZYRA AI ORGANISATION → HOLDINGS AI ORGANISATION.
    Agent Maturity: Experimental added to identity header.
    Contract Version: V2 → V3 (Orchestrator V3 → V4).
    ASSUMPTIONS section added.
    OUT OF SCOPE section added.
    COMPLETION CRITERIA section added.
    COMPLETION CRITERIA — SYSTEM AUDITOR CHECK added to
    full contracts (base roles and organisation).
    VERSION HISTORY section added.
    LOGGING_STANDARD_V1 added to Always Consult where
    not already present.
  All V2 contracts archived with 2026-06-22 date prefix.
Decision:
  All 29 prior contracts archived.
  All 29 new V3 contracts (Orchestrator V4) are the active
  baseline. CONTRACT_TEMPLATE V3 is now in active use.
Decided By:   Lead Architect (Claude)
Approved By:  Project Owner (Shakeel) — 2026-06-22

------------------------------------------------------------

END OF DECISION REGISTER
============================================================


============================================================
END OF DOCUMENT
============================================================
------------------------------------------------------------

DR-068
Title:       Stage 8 — OA housekeeping + cascade
             detection (OA-098)
Date:        2026-06-22
Status:      Approved
Owner:       Lead Architect
Decision:
  Stage 8 governance housekeeping batch approved:

  OA Closures (completed in prior stages, now formally
  closed):
    OA-019 — Superseded by REPOSITORY_ARCHITECTURE_V2
    OA-041 — Superseded by REPOSITORY_ARCHITECTURE_V2
    OA-071 — COMPLETION CRITERIA section added (V3)
    OA-087 — ASSUMPTIONS section added (V3)
    OA-088 — OUT OF SCOPE section added (V3)
    OA-089 — Agent Maturity field added (V3)
    OA-095 — Pre-production cut-off rule (GOVERNANCE_V4)
    OA-099 — Automation schedule (EXECUTION_V4)

  OA-098 — V doc cascade detection:
    IMPACT_ANALYSIS_AGENT_BASE_ROLE_V3 → V4:
      Responsibility 7 added. When a V doc is updated,
      the Impact Analysis Agent maps all dependent V docs
      and flags any not included in the update batch.
      COMPLETION CRITERIA updated to require cascade
      check before batch is filed.
    SYSTEM_AUDITOR_V3 → V4:
      Responsibility 9 added. System Auditor tracks
      V doc update patterns across governance cycles.
      Any V doc not updated across 2+ consecutive cycles
      is flagged to Lead Architect and Project Owner.
      Flags — does not reclassify. COMPLETION CRITERIA
      updated to include pattern review.

Rationale:
  Cascade detection prevents silently outdated V docs
  accumulating across governance cycles. The two-rule
  split (IA Agent: per-batch; System Auditor: per-cycle)
  provides both immediate and longitudinal detection.

Consequences:
  All new V doc update batches require IA Agent cascade
  check before they are filed as complete.
  System Auditor cycle report now includes V doc
  non-update pattern section.

Raised:      2026-06-22
------------------------------------------------------------

DR-069
Title:       Stage 9 — Evolution section batch update
             (OA-070/072/073/076/077/080/082/083)
Date:        2026-06-22
Status:      Approved
Owner:       Lead Architect
Decision:
  Stage 9 contract batch approved. All changes are
  Evolution section additions only — no current
  operational behavior changed. Contracts updated:

  OA-070 — Reporting Agent (Base Role, SYSTEM, ZYRA → V4):
    5-class report classification added: Governance,
    Operational, Project, Audit, System Health.

  OA-072 — Lead Architect (V3 → V4):
    Level 5 design/operational separation: Orchestrator
    handles routine execution; Lead Architect returns
    for novel problems and architectural decisions.

  OA-073 — Architecture Partner (V3 → V4):
    Recurring weakness recognition: tracks and surfaces
    repeated correction patterns from Lead Architect
    proposals.

  OA-076 — PA (V3 → V4):
    Working preference awareness: PA maintains Project
    Owner communication and preference record to
    pre-filter outputs at Level 5.

  OA-077 — Orchestrator (V4 → V5):
    Workflow State / Execution State distinction:
    governance lifecycle state and agent execution
    state tracked independently.

  OA-080 — Documentation Agent (Base Role, SYSTEM, ZYRA → V4):
    Independently versioned document schemas: per
    document type schema versioning, decoupled from
    contract versioning.

  OA-082 — Resolution Classifier (Base Role, SYSTEM, ZYRA → V4):
    Routing matrix extraction trigger: when rule count
    exceeds 15 (or spans multiple scopes), routing
    matrix moves to standalone governed document.

  OA-083 — Repository Agent (Base Role, SYSTEM, ZYRA → V4):
    Archive classification: Logical Archive (still
    referenced, live dependency) vs Historical Archive
    (unreferenced, record-only) with different handling.

Rationale:
  All Stage 9 OAs were ChatGPT Round 3/4 recommendations
  targeting future Level 4/5 capabilities. Adding them
  as Evolution section text now preserves the intent
  without changing current operation, and keeps the
  contracts aligned with the approved organisational
  direction.

Consequences:
  16 contracts updated (V3→V4 or V4→V5).
  Orchestrator is now V5. All others moved from V3 to V4.
  V3 versions archived with date prefix 2026-06-22.
  OAs 070/072/073/076/077/080/082/083 closed.

Raised:      2026-06-22
------------------------------------------------------------

DR-070
Title:       REPOSITORY_ARCHITECTURE V2 → V3 — MASTER_
             naming convention documented (OA-049)
Date:        2026-06-22
Status:      Approved
Owner:       Lead Architect
Decision:
  REPOSITORY_ARCHITECTURE_V2 archived as
  REPOSITORY_ARCHITECTURE_2026-06-22_V2.md.
  REPOSITORY_ARCHITECTURE_V3.md produced with:
    Section 9.9 added — MASTER_ Governing Folder Names.
    Documents the MASTER_ prefix convention for all
    governing document folders under SYSTEM/DOCUMENTS/.
    Documents folder rename history:
      GOVERNANCE/     → MASTER_GOVERNANCE/
      EXECUTION/      → MASTER_EXECUTION/
      ARCHITECTURE/   → MASTER_ARCHITECTURE/
      DECISIONS/      → DECISIONS_REGISTER/
    Establishes MASTER_ as the approved standard for
    all future HOLDINGS-level governing document folders.
Rationale:
  OA-049 required the DECISIONS_REGISTER rename and
  MASTER_ naming convention to be formally documented
  in Repository Architecture rather than remaining only
  in session history.
Consequences:
  REPOSITORY_ARCHITECTURE is now V3.
  All agents that consult MASTER_ARCHITECTURE must now
  include Section 9.9 in their authoritative reference.
Raised:      2026-06-22

------------------------------------------------------------

DR-071
Title:       Stage 10 — Governance infrastructure batch
             (OA-026/040/048/049)
Date:        2026-06-22
Status:      Approved
Owner:       Lead Architect
Decision:
  Stage 10 governance infrastructure batch approved:

  OA-026 — External Reviewer engagement protocol:
    EXTERNAL_REVIEWER_PROTOCOL_V1.md written and filed
    in HOLDINGS/SYSTEM/DOCUMENTS/ORGANISATION/.
    Covers: who can trigger (Project Owner only),
    what warrants engagement, how outputs enter
    governance, what happens to recommendations
    (all must be disposed: Accept/Modify/Decline/Defer),
    and frequency limit (exception, not standard step).

  OA-040 — DECISIONS/OA register migration:
    HOLDINGS/SYSTEM/OUTSTANDING_ACTIONS/
    OUTSTANDING_ACTIONS_V1.md created with 85
    system-level OAs. ZYRA-specific OAs (14) remain
    in PROJECTS/ZYRA/SYSTEM/OUTSTANDING_ACTIONS/.
    Classification criteria: ZYRA-specific = OAs about
    ZYRA app folders (APP/, BUSINESS/, SOURCE/,
    Authentication, Wali, Connections, UI language,
    APP Inspection, ZYRA Terminology, session mgmt).
    Note: DRs are all system-level; SYSTEM/DECISIONS_
    REGISTER/ seeded in follow-on step.

  OA-048 — SYSTEM/LOGS/ area created:
    HOLDINGS/SYSTEM/LOGS/ subfolders created for:
    ORCHESTRATOR/, REPOSITORY_AGENT/,
    DOCUMENTATION_AGENT/, INSPECTION_AGENT/,
    SYSTEM_AUDITOR/. Ready to receive agent logs
    when autonomous operation begins.

  OA-049 — MASTER_ naming and DECISIONS_REGISTER
    rename documented in REPOSITORY_ARCHITECTURE_V3
    (see DR-070).

Raised:      2026-06-22
------------------------------------------------------------

DR-072
Title:       Stage 11 — ZYRA project OA assessment
             and EXECUTION_V5
Date:        2026-06-22
Status:      Approved
Owner:       Lead Architect
Decision:
  Stage 11 ZYRA project OA assessment complete.

  EXECUTION_V4 → V5 (OA-015/017/029):
    V4 header discrepancy fixed (ZYRA PROJECT header,
    Version V3 label corrected to V5).
    Section 27 added: SOURCE Code Development Workflow.
      Plan-first → tests-first → implementation →
      self-review → output-review. Mandatory for all
      writes to SOURCE/. (OA-015, DR-020)
    Inspection section updated: Priority Ordering by
      Execution Framework Group. Groups 1–8 documented.
      Lower group = higher priority. Group membership
      shown in every Inspection report. (OA-017, DR-022)
    Section 26.6 added: Command Cadence Reference.
      SYSTEM Inspection (weekly), SYSTEM doc updates
      (weekly), AI Organisation work (per session).
      APP Inspection cadence pending OA-020. (OA-029)

  OA-031 closed: PROJECT_READINESS_AGENT_V3 contract
    already satisfies the per-project forward blocker
    reporting requirement.

  Blocked OAs (require Project Owner or ChatGPT):
    OA-003: ZYRA SYSTEM/DEVELOPMENT/ audit — target
      folder not found in current structure.
    OA-004: APP/14_LEGAL — PO decision needed.
    OA-005: APP/Authentication/ audit — deferred to
      dedicated audit session.
    OA-007: ZYRA Terminology — PO must supply terms.
    OA-008/009: Wali Navigation, Connections — blocked
      on PO Summaries.
    OA-016: UI design language rule — ChatGPT required.
    OA-018: Summary standard — ChatGPT required.
    OA-020: APP Inspection cadence — ChatGPT required.
    OA-033/034: Deferred to Level 4 / Level 3 steady-state.

Raised:      2026-06-22

------------------------------------------------------------

DR-073
Title:       Supabase as ZYRA Backend
Date:        2026-06-26
Status:      Approved
Owner:       Lead Architect
Decision:
  Supabase is confirmed as the backend for ZYRA.

  Components in use:
    Supabase PostgreSQL — primary database
    Supabase Auth       — user authentication
    Supabase Storage    — profile images and documents
    Supabase Realtime   — live data subscriptions (future)

  This replaces the legacy Firebase assumption present
  in early project documentation (pre-HOLDINGS migration).
  Firebase was never implemented; Supabase was the
  implicit direction throughout all architecture
  discussions post-migration.

  Rationale:
    PostgreSQL foundation provides a relational model
    appropriate for ZYRA's journey state machine, user
    relationships, and guardian (Wali) permission model.

    Row-level security (RLS) in Supabase PostgreSQL
    aligns with ZYRA's trust and privacy requirements:
    users should never access data they are not
    authorised to see, enforced at the database layer.

    Supabase avoids proprietary query language lock-in.
    All data remains accessible via standard SQL.
    Migration path out of Supabase, if ever required,
    is significantly simpler than Firebase.

    Supabase Auth supports the authentication patterns
    ZYRA requires (email/password, social, phone)
    without requiring a separate auth provider.

    Supabase Storage provides governed file access with
    the same RLS model as the database, keeping the
    permission model consistent across data types.

  Alternatives considered:
    Firebase — rejected. Proprietary document model
    creates long-term query and migration friction.
    Legacy assumption only; never implemented.

    Custom backend — rejected. Premature given current
    stage. Supabase provides the necessary capability
    with substantially lower implementation overhead.

  ZYRA_ARCHITECTURE_V1.md updated accordingly.
  README.md updated accordingly.
  CLAUDE.md reflects Supabase stack.

Raised:      2026-06-26

------------------------------------------------------------

DR-074
ID:           DR-074
Title:        Group Field — Execution Stage Indicator with
              Evidence-Based Advancement
Date:         2026-06-27
Status:       Active
Superseded By: None
Category:     Execution
Owner:        Lead Architect
Approved by:  Architectural Reviewer (ChatGPT)

Decision:
  The Group field on every APP and BUSINESS Summary.md
  represents the feature's current execution stage, not
  simply the category of work most recently edited.

  A feature at Group N has completed all governing
  conditions for Groups 1 through N-1. All prior groups
  are satisfied before a feature advances.

  The Group field advances only when the governing
  conditions for the current group are satisfied — not
  when the field is manually changed. The Group field
  is an outcome of evidence, not an editable status label.

Context:
  DR-022 established the 8-group execution framework and
  the Group metadata field on Summary documents (via
  OA-018). The Group field was defined as "which execution
  framework group the feature belongs to" but no
  advancement rule was specified. This left the field
  as a manually maintained label with no governing
  condition for when it should change.

  During ZYRA Project Check (2026-06-27), the Architectural
  Reviewer identified this as the remaining gap in the
  maturity model: the Group field had no definition of
  what it means to be "at" a group, and no governed
  process for advancing.

  This decision closes that gap. The Group field now
  has a formal meaning: current execution stage, with
  all prior stages complete.

Alternatives:
  Keep the Group field as a manually maintained category
  label with no advancement rule. This preserves
  flexibility but produces an unreliable maturity signal.

  Define a single project-level group position rather
  than per-feature tracking. This was the original
  interpretation of DR-022 and is simpler, but does not
  support the full maturity view the Project Check requires.

Reasoning:
  The evidence-first philosophy applied throughout the
  organisation (metrics paired with quality signals,
  completion criteria on agent contracts, etc.) should
  apply equally to feature maturity. A Group field that
  advances on evidence is a reliable signal. A Group field
  that advances on manual update is an opinion.

  Per-feature group tracking enables the Project Check
  to answer questions that a single project-level position
  cannot: which features are out of sequence, which are
  blocked in early groups while later work has started,
  which features should be prioritised next.

Impact:
  Summary Standard — Group field definition updated to
    reflect "current execution stage" semantics.
  Project Check — must read Group fields and produce
    maturity output per feature and overall.
  Summary.md files — Group field values must reflect
    actual stage reached, not work in progress.

Related:
  DR-022 (ZYRA Project Execution Framework — 8-group model)
  OA-018 (Summary Standard — Group field definition)
  OA-117 (Project Check implementation)
  OA-120 (Per-group advancement conditions — to be defined)

------------------------------------------------------------

DR-075
Title:       Pricing Model Simplification — Retire Per-Wali
             Billing and Family Payment Model, Confirm Launch
             Promotion Terms Under ZYRA One
Date:        2026-07-12
Status:      Active
Category:    Pricing / Commercial
Owner:       Founder (Shakeel)
Approved by: Founder, following Research Office (ChatGPT)
             repository alignment review

Decision:
  1. Founder Members: first 1,000 people to purchase ZYRA One
     (any account — Seeker or Wali; not gender- or role-
     restricted, headcount only) receive 50% off ZYRA One for
     6 months, then 25% off for the following 6 months.
  2. Early Adopters: next 5,000 people to purchase ZYRA One
     (same eligibility basis) receive 25% off ZYRA One for
     12 months.
  3. Per-Wali-relationship billing is retired completely. A
     Seeker no longer manages multiple priced Wali
     subscriptions. A ZYRA One Seeker's bundled Extended Wali
     entitlement goes to one linked Wali; any other Wali
     wanting Extended capabilities purchases independently
     (£9.99/month, AD-081).
  4. Family / multi-account billing (one individual paying for
     several Seeker or Wali accounts) is removed from the
     current product. Every account manages its own
     subscription. May be reconsidered in a future version if
     genuine demand exists.
  5. Profile Unlock pricing confirmed unchanged and already
     consistent with ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V3, Part
     1, Section 8: Profile Unlock £0.99/1, £2.99/5; Profile
     Unlock Plus £1.99/1, £4.99/5.

Context:
  A repository alignment audit (2026-07-12) found
  BUSINESS/ZYRA PRICING/Summary.md still described the retired
  Basic/Pro/Premium tiered model — Founder/Early-Adopter
  programmes built around per-Wali subscriptions, a 9-row
  family pricing matrix, and proration across multiple linked
  Walis — none of which maps onto the ZYRA One model in
  ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V3 (single flat membership,
  one bundled Extended Wali entitlement). This decision
  confirms the correct terms so the documentation could be
  brought into alignment rather than guessed.

  Original launch-promotion draft restricted eligibility to
  Seeker accounts only and split pools by gender ("first 1,000
  men / first 1,000 women"); Founder corrected this during
  review to a single headcount-based pool open to any account
  role, since ZYRA One is already purchasable by either role
  (Product Spec V3, Part 1, Section 4).

Alternatives:
  Keep the old per-Wali-relationship billing and family pricing
  matrix, restructured with new prices. Rejected — adds back
  the complexity the ZYRA One model was designed to remove, for
  no clear benefit at this stage.

  Restrict Founder Members / Early Adopters to Seeker accounts
  only, as originally drafted. Rejected by Founder — since
  ZYRA One is available to either role, restricting the launch
  incentive to one role was an unintended carry-over from the
  old model rather than an intentional design choice.

Reasoning:
  One flat membership, one clear set of launch incentives, no
  role- or gender-based eligibility rules, no per-relationship
  billing — keeps the commercial model as simple as the product
  model it needs to match.

Impact:
  BUSINESS/ZYRA PRICING/Summary.md — rewritten 2026-07-12.
  BUSINESS/ZYRA PRICING/Flow Diagram.md — rewritten 2026-07-12.
  Any other document referencing Wali Pro/Premium pricing,
  family billing, or gender-restricted launch promotions is
  stale as of this decision — see
  ZYRA_TERMINOLOGY_PRICING_AUDIT_2026-07-12_V1.md for the full
  list and correction status.

Related:
  ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V3.md (Part 1, Sections 4-5,
    8)
  AD-081 (Capability Independence Principle)
  ZYRA_TERMINOLOGY_PRICING_AUDIT_2026-07-12_V1.md

------------------------------------------------------------

DR-076
Title:       Terminology — Decline / Save / Like (supersedes
             DR-014's Decline / Review / Consider)
Date:        2026-07-12
Status:      Active
Superseded By: None
Category:    Terminology
Owner:       Founder (Shakeel)
Approved by: Founder, following Research Office (ChatGPT) and
             Founder Office (Claude) joint investigation

Decision:
  The three approved profile-decision terms on Browse are:
  Decline, Save, Like. This confirms and formalises what
  ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V3 (2026-07-04) already
  specified in Part 2, Sections 3-4, and supersedes DR-014's
  Decline/Review/Consider model, which had never been formally
  retired despite Product Spec V3 already using different terms.

  Save is a private action — "I would like to come back to
  this profile later." Does not indicate romantic interest.
  Like is an interest signal — "I would like to pursue this
  person." Mutual Like is the Match event, creating a Potential
  Journey. Wali accounts do not participate in Browse profile
  decisions — Browse is Seeker-only (Product Spec V3, Part 1,
  Section 3).

Context:
  A repository audit (2026-07-12) found DR-014 (2026-06-20,
  still Active) and Product Spec V3 (2026-07-04) defining two
  different, structurally incompatible decision models — three
  actions with a 50-profile Review cap and Mutual Consideration
  match rule (DR-014) versus two actions with unlimited private
  Saves and a Mutual Like match rule (Product Spec V3). No
  Decision Record had ever closed this gap; DR-014 simply sat
  Active alongside a newer spec that silently used different
  terms. Founder confirmed Save/Like (Product Spec V3) as
  correct, 2026-07-12.

Alternatives:
  Keep Decline/Review/Consider and correct Product Spec V3
  back to match DR-014. Rejected — Product Spec V3 is the
  actively maintained master specification; DR-014 was the
  document that had gone stale.

Reasoning:
  Two terms (Save/Like) map more directly onto the Match-is-an-
  event architecture already ratified in Product Spec V3 Part 0
  than the three-term Review/Consider split did. Consolidating
  onto one active decision record removes the contradiction
  rather than leaving two "Active" records disagreeing.

Impact:
  BUSINESS/ZYRA TERMINOLOGY/Summary.md and References.md —
  updated 2026-07-12.
  APP/Matching/PROFILE DECISION SYSTEM/Summary.md,
  References.md, Flow Diagram.md — superseded, to be archived
  and replaced against Product Spec V3 Part 2.
  Any other document still referencing Decline/Review/Consider
  is stale as of this decision — see
  ZYRA_TERMINOLOGY_PRICING_AUDIT_2026-07-12_V1.md.

Related:
  DR-014 (superseded by this decision)
  ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V3.md (Part 0 Section 0.5,
    Part 2 Sections 3-4)
  ZYRA_TERMINOLOGY_PRICING_AUDIT_2026-07-12_V1.md

------------------------------------------------------------

DR-077
Title:       Connector User Role — Retired
Date:        2026-07-12
Status:      Active
Superseded By: None
Category:    Architecture
Owner:       Founder (Shakeel)
Approved by: Founder

Decision:
  The "Connector" user role (introduces Seekers, limited
  profile access) is retired. Only Seeker and Wali are valid
  ZYRA user roles.

Context:
  ZYRA_ARCHITECTURE_CURRENT_VERSION_V2.md defines Connector as
  a third role; Product Spec V3 does not mention it at all. A
  repository audit (2026-07-12) flagged this as an unresolved
  gap dating to the 2026-06-27 Project Check. Founder confirmed
  retirement rather than deferral.

Alternatives:
  Keep Connector as a documented future role, deferred but not
  built. Rejected by Founder — no current plan to build it, and
  an undocumented-in-Product-Spec role sitting in the
  architecture creates exactly the kind of drift this audit was
  meant to catch.

Reasoning:
  Simpler role model, matches what Product Spec V3 already
  assumes.

Impact:
  SYSTEM/DOCUMENTS/ZYRA_ARCHITECTURE_CURRENT_VERSION_V2.md —
  Connector row and capability note to be removed.

Related:
  ZYRA_TERMINOLOGY_PRICING_AUDIT_2026-07-12_V1.md

------------------------------------------------------------

DR-ZYRA-078
Title:       Frontend Framework — Flutter Confirmed (resolves
             conflict with Infrastructure Stack V1)
Date:        2026-07-18
Status:      Active
Superseded By: None
Category:    Architecture
Owner:       Founder (Shakeel)
Approved by: Founder

Decision:
  ZYRA's app frontend is Flutter (Dart), single codebase for
  iOS, Android, and web. ZYRA_INFRASTRUCTURE_STACK_V1.md's
  "Expo + EAS / React Native" line is superseded — corrected
  in place, not archived as a separate version, since it was
  a drafting inconsistency rather than a deliberate reversal
  (see Context).

Context:
  Found during AIOS-side work resuming ZYRA (OA-AIOS-289):
  ZYRA_ARCHITECTURE_CURRENT_VERSION_V2.md (2026-06-26) and
  ZYRA_DOCUMENTATION_INDEX_V1.md (2026-06-26) both specify
  Flutter, and a real Flutter project already exists at
  SOURCE/ (iOS/Android/web/macos/linux/windows targets
  scaffolded, pubspec.lock present — has been built at least
  once). ZYRA_INFRASTRUCTURE_STACK_V1.md (2026-07-04, later)
  independently states "Expo + EAS — React Native" for app
  delivery, with no note that this changes or supersedes the
  Architecture doc's Flutter decision. Two CURRENT_VERSION
  documents disagreeing with no resolution recorded — surfaced
  to the Founder rather than silently picking one.

Alternatives:
  Switch to React Native/Expo per the more recent
  Infrastructure Stack doc. Rejected — no evidence this was a
  deliberate decision to move away from Flutter (no DR exists
  for it, unlike DR-077's retirement of the Connector role,
  which WAS a recorded deliberate change); the existing Flutter
  scaffold would be discarded for no stated reason.

Reasoning:
  The working scaffold and two independent, earlier documents
  agree on Flutter. The one document naming React Native gives
  no rationale and isn't itself a Decision Record. Simplest
  explanation is a drafting error in the Infrastructure Stack
  doc, not an intentional pivot.

Impact:
  ZYRA_INFRASTRUCTURE_STACK_V1.md — "Expo + EAS" row corrected
  to Flutter. Flutter app development resumes on the existing
  SOURCE/ scaffold, starting with Authentication, Onboarding,
  and Browse screens.

Related:
  ZYRA_ARCHITECTURE_CURRENT_VERSION_V2.md,
  ZYRA_DOCUMENTATION_INDEX_V1.md, OA-AIOS-289 (BLACK UMBRELLA
  GROUP OA register — ZYRA resumption)

------------------------------------------------------------

DR-ZYRA-079
Title:       Compatibility Scoring Algorithm — v1 Draft Proposal
Date:        2026-07-18
Status:      RATIFIED 2026-07-25 (OA-ZYRA-140 item 12, Founder
             decision: "ratify as-is"). Bundled with DR-ZYRA-084
             (its live wiring into Browse) since the two were
             raised together as one real-world gap — an
             unratified draft was actively governing candidate
             visibility today; ratifying only the algorithm and
             not its wiring would leave the same contradiction
             one level down.
Superseded By: None
Category:    Product / Matching
Owner:       Founder (Shakeel)
Approved by: Founder (Shakeel), 2026-07-25

Decision (proposed, not yet accepted):
  A first-draft scoring model, implemented at
  SOURCE/lib/services/compatibility_scoring.dart: for each
  Chapter 4 preference question, a candidate's matching
  Chapter 3 answer scores +2 if the Seeker marked it 🟢, +1 if
  🟡, -3 if 🔴 (with a 🔴 + Hard Requirement combination
  excluding the candidate outright rather than penalising).
  Summed across all mutually-answered questions and normalised
  to a 0-100 display score. Unidirectional (Seeker's
  preferences scored against candidate's answers only, not yet
  combined with the reverse direction).

Context:
  References.md (SEEKER ONBOARDING QUESTIONS) explicitly flags
  this as an open dependency: "Compatibility scoring algorithm
  not yet designed" and "Green / Amber / Red compatibility
  rating system not yet built." No existing spec to transcribe
  faithfully, unlike the rest of this build. Built anyway so
  Matches/Browse have a real (if provisional) way to rank
  candidates, per Founder instruction to keep building until
  a genuine decision point is reached — this is that decision
  point, surfaced rather than silently treated as final.

Alternatives considered:
  (1) Leave unscored until Founder designs it — rejected, since
  the Founder asked to keep building and an unscored Matches
  tab is a bigger gap than a provisional model. (2) Bidirectional
  scoring (average both Seekers' scores of each other) — likely
  the more correct long-term model, deferred to v2 pending
  Founder input on how ties/asymmetric scores should be shown.

Reasoning:
  A visible, explainable, easily-adjusted starting point (three
  weighted buckets plus a hard exclusion) is preferable to either
  blocking on design or shipping a black-box score. Every
  constant in the model is isolated in one function for easy
  tuning once reviewed.

Impact:
  UPDATED 2026-07-25: now wired into real Browse candidates per
  DR-ZYRA-084 (also ratified 2026-07-25) — no longer just a
  documented, unwired function.

Related:
  SEEKER ONBOARDING QUESTIONS/References.md (open dependency),
  MATCH_UX_SPEC_CURRENT_VERSION_V1.md ("Compatibility % ... not
  shown anywhere until Active Journey begins" — display timing
  still governs even once this scoring exists),
  SOURCE/lib/services/compatibility_scoring.dart

------------------------------------------------------------

DR-ZYRA-080
Title:       Error & Empty State Language Standard — v1 Proposal
Date:        2026-07-18
Status:      PROPOSED — awaiting Founder review, NOT ratified
Superseded By: None
Category:    Product / UX Writing
Owner:       Founder (Shakeel)
Approved by: Not yet approved

Decision (proposed, not yet accepted):
  A written standard for how ZYRA shows validation errors,
  simulated backend/auth errors, empty states, and disabled
  states, at APP/UX Writing/ERROR_AND_EMPTY_STATE_STANDARD_
  CURRENT_VERSION_V1.md. Applies the existing warm/human tone
  rules (Summary.md) to error and empty copy specifically, and
  defines visual treatment (inline field errors vs. banner vs.
  full empty-state layout).

Context:
  UX Writing/Summary.md's own Approved To-Do List names this
  gap explicitly: "Define approach for error messages (currently
  not covered)." Founder asked to complete "all screens done,
  all icons, all navigation, all error states" as the next
  build phase, independent of backend work — this document is
  the design layer that phase is built against, applied as
  mocked/simulated states ahead of Supabase (OA-101/OA-102)
  actually existing.

Alternatives considered:
  (1) Leave error copy ad hoc per screen — rejected, produces
  inconsistent tone and risks reverting to clinical software
  language the rest of the app deliberately avoids. (2) Wait
  until Supabase is connected to write real error copy — rejected
  per Founder's explicit instruction to build all frontend/UI
  completeness now, independent of backend timing.

Reasoning:
  Same discipline as DR-ZYRA-079: a visible, documented, easily
  adjusted starting point beats either blocking or shipping
  inconsistent copy. Isolating the categories (validation /
  simulated backend / empty / disabled / unknown) makes it easy
  to re-check against real backend error codes later.

Impact:
  Applied across auth, onboarding, Browse, Matches, Chat, and
  Profile screens in this build pass via shared widgets
  (lib/widgets/ — error/empty state components) rather than
  one-off copy per screen.

Related:
  APP/UX Writing/Summary.md, APP/UX Writing/ERROR_AND_EMPTY_
  STATE_STANDARD_CURRENT_VERSION_V1.md, SYSTEM/OUTSTANDING_
  ACTIONS/OUTSTANDING_ACTIONS_V2.md (OA-102)

------------------------------------------------------------

DR-ZYRA-081
Title:       Wali Onboarding Content — v1 Draft Proposal
Date:        2026-07-18
Status:      PROPOSED — awaiting Founder review, NOT ratified
Superseded By: None
Category:    Product / Onboarding
Owner:       Founder (Shakeel)
Approved by: Not yet approved

Decision (proposed, not yet accepted):
  A first-draft Wali onboarding flow, implemented at SOURCE/
  lib/screens/wali/: name, relationship-to-Seeker selection
  (Father / Grandfather / Brother / Paternal Uncle / Other, per
  WALI ARCHITECTURE V5's WHO IS A WALI list), a "support and
  guidance, not surveillance" purpose screen (paraphrasing that
  document's DESIGN PRINCIPLE section), then a mocked Invite
  Seeker step (Path 3 — Wali Starts First). Also built: a 4-tab
  Wali home shell (Dashboard / Seekers / Network / Profile, per
  WALI NAVIGATION), with the Network tab correctly gated behind
  Extended Wali capabilities and a mocked £9.99/month purchase
  path per Path 2A.

Context:
  WALI_ARCHITECTURE_CURRENT_VERSION_V5.md is a fully approved,
  detailed architecture — account model, capability grants,
  three entry paths, screen flow diagram, navigation structure —
  but the actual onboarding QUESTION CONTENT is never specified
  anywhere in it. The WALI SCREEN FLOW section only references a
  black-box "[ Wali Onboarding ]" node between account creation
  and the Dashboard. No dedicated "Wali Onboarding Questions"
  document exists (unlike the Seeker's SEEKER ONBOARDING
  QUESTIONS folder). This also surfaced a real bug: Role
  Selection's "Wali (Guardian)" card was routing into the
  Seeker's OnboardingFlow (name/gender/DOB, photos, location,
  etc.) — an entirely wrong persona — which is fixed as part of
  this change.

Alternatives considered:
  (1) Leave Wali selection broken/pointing at Seeker onboarding
  until content is specified — rejected, it's a live bug, not a
  neutral gap. (2) Build all three entry paths (Seeker invites
  Wali, Wali purchases independently, Wali starts first) —
  rejected for v1; only Path 3 is reachable from this app's
  current Role Selection screen, so Paths 1/2 (which need a
  Seeker-sent invite landing page) are deferred rather than
  built against nothing to link to.

Reasoning:
  Same discipline as DR-ZYRA-079/080: a small, honestly-scoped
  v1 beats either leaving a known-wrong flow in place or
  inventing a large, confident-looking Wali onboarding question
  set with no spec basis. Kept intentionally short (2 questions)
  rather than mirroring the Seeker's ~200-question depth, since
  WALI ARCHITECTURE V5 itself describes Wali accounts as
  "identity only" — there's no browsable profile to build
  toward.

Impact:
  Role Selection now correctly branches Seeker vs Wali. Wali
  Network correctly reflects the Extended Wali gate from spec.
  Wali Dashboard/Seekers tabs are real screens but functionally
  empty (no linking backend exists yet, so "0 linked Seekers" is
  permanent until Supabase — OA-101/102 — is connected).

Related:
  APP/Standards/WALI_ARCHITECTURE_CURRENT_VERSION_V5.md,
  SOURCE/lib/screens/wali/, SOURCE/lib/screens/auth/
  role_selection_screen.dart

------------------------------------------------------------

DR-ZYRA-082
Title:       Chapter 3/4 Onboarding Answers — JSONB storage,
             not per-question rows
Date:        2026-07-18
Status:      PROPOSED — awaiting Founder review, NOT ratified
Superseded By: None
Category:    Architecture / Product
Owner:       Founder (Shakeel)
Approved by: Not yet approved

Decision (proposed, not yet accepted):
  A new table, onboarding_answers, stores each Seeker's Chapter 3
  (Your Values) and Chapter 4 (Your Preferences) answers as three
  JSONB columns keyed by question ID: ch3_answers (single/multi
  select answer per question), ch4_preferences (per-option traffic
  light per question), ch4_hard_requirements (bool per question).
  One row per user, upserted on each answer change. This table is
  not present in ZYRA_DATABASE_SCHEMA_CURRENT_VERSION_V1.md — it
  is a genuine gap in that document, not an implementation of an
  existing spec.

Context:
  The approved schema (13 tables, OA-103) covers profiles,
  subscriptions, photos, wali_links, saves, likes, unlocks,
  matches, conversations, messages, timelines, and wali_suggestions
  — but never accounts for where the ~174 Chapter 3/4 question
  answers actually live. ValuesPreferencesFlow (SOURCE/lib/screens/
  onboarding/values_preferences_flow.dart) has held these entirely
  in local widget state (_ch3Answers, _ch4Preferences,
  _ch4HardRequirement) since it was built — never written to
  AppState, let alone Supabase. Every Chapter 3/4 answer a user
  gives is currently lost the moment the flow's widget is disposed.

Alternatives considered:
  (1) One row per question per user (~174 rows/user in a
  chapter3_answers table plus a matching chapter4_preferences
  table) — rejected for v1: no matching engine exists yet to query
  individual answers relationally, questions/options are code-
  defined constants (not user data), and 174 narrow rows per user
  adds real schema surface for zero present benefit. (2) Store
  answers as a blob inside profiles — rejected: profiles is a
  Founder-approved table with a fixed, spec'd column list: adding
  an unspec'd JSONB column there mixes an unratified decision into
  ratified schema. A dedicated table keeps the gap visibly isolated
  and easy to revisit or migrate to per-question rows later without
  touching profiles.

Reasoning:
  Same discipline as DR-ZYRA-079/080/081: fill a real gap with the
  smallest honest structure rather than either leaving answers
  unpersisted or over-designing a relational shape the app doesn't
  need yet. JSONB keyed by question ID mirrors timeline_milestones.
  metadata JSONB, an already-approved pattern in the same schema
  doc. If/when a matching algorithm needs to query individual
  answers, this is the natural migration point to normalize.

Impact:
  New migration (onboarding_answers table + own-row RLS). New
  ZyraOnboardingService (or equivalent) call from
  ValuesPreferencesFlow on each answer change / chapter completion.
  ZYRA_DATABASE_SCHEMA_CURRENT_VERSION_V1.md needs a V2 to formally
  add this table once ratified — currently undocumented there.

Related:
  SYSTEM/DOCUMENTS/ZYRA_DATABASE_SCHEMA_CURRENT_VERSION_V1.md,
  SOURCE/lib/screens/onboarding/values_preferences_flow.dart,
  SOURCE/supabase/migrations/, DR-ZYRA-081

------------------------------------------------------------

DR-ZYRA-083
Title:       Wali Account Linking Mechanism — invite-token table
             + SECURITY DEFINER accept/preview functions
Date:        2026-07-18
Status:      PROPOSED — awaiting Founder review, NOT ratified
Superseded By: None
Category:    Architecture / Product
Owner:       Founder (Shakeel)
Approved by: Not yet approved

Decision (proposed, not yet accepted):
  A new wali_invites table plus two SECURITY DEFINER functions —
  preview_wali_invite() and accept_wali_invite() — implement the
  actual linking mechanism behind wali_links. Either a Seeker or a
  Wali generates an invite (an 8-character shareable code); the
  other party enters it and accept_wali_invite() creates the
  wali_links row regardless of which side is signed in. One
  symmetric mechanism covers Path 1/2 (Seeker invites Wali) and
  Path 3 (Wali invites Seeker) per WALI_ARCHITECTURE_CURRENT_
  VERSION_V5.md. Wired into the app as: a shared "Link a Wali" /
  "Link a Seeker" screen (Seeker Profile and Wali Profile settings),
  a shared invite-code entry screen, and a real code generator on
  the existing Wali-onboarding "Invite your Seeker" step (previously
  a mocked placeholder link).

Context:
  WALI_ARCHITECTURE_CURRENT_VERSION_V5.md specifies three entry
  paths and states accounts link via "Internal invitation token
  (generated per invite)" but never specifies that token's schema.
  ZYRA_DATABASE_SCHEMA_CURRENT_VERSION_V1.md only defines wali_links
  (the RESULT of linking) with an INSERT policy scoped to
  seeker_id = auth.uid() — which only covers a Seeker creating the
  row while signed in as themselves, and cannot support a
  Wali-initiated link (Path 3) where the Wali isn't the one the
  policy authorizes. This was flagged as an open gap in the original
  schema migration's comments ("wali_links_insert only covers Path
  1/2, explicitly not Path 3") and re-stated to the Founder in this
  session's own status report before being addressed here.

Alternatives considered:
  (1) Loosen wali_links_insert to also allow wali_id = auth.uid() —
  rejected: this was explicitly flagged as needing Founder
  confirmation before touching, since it changes who can
  unilaterally create a family-relationship record naming someone
  else. (2) Build the full Extended Wali capability/entitlement
  resolution engine (Primary Wali, Path A/B grants) alongside
  linking — rejected for v1: no schema representation exists for it
  anywhere yet (subscriptions.plan_type has no per-relationship
  entitlement concept), it's materially larger scope than "can two
  accounts find and link to each other", and Extended Wali gating
  already has its own mocked purchase flow elsewhere in the app that
  this doesn't need to disturb. (3) Real deep links (tap a link, code
  auto-fills) — rejected for v1: requires iOS/Android universal-link
  platform configuration that cannot be verified in this build
  environment (no device/simulator access); manual code entry is a
  fully real, testable substitute.

Reasoning:
  Same discipline as DR-ZYRA-078/079/080/081/082: fill the actual
  gap (linking) with the smallest honest, symmetric mechanism, and
  explicitly do not reach into the larger unbuilt entitlement system
  or the Founder-reserved RLS-policy question. A SECURITY DEFINER
  accept function resolves the Path 3 authorization problem without
  loosening the client-facing wali_links_insert policy at all —
  the function is the only path through which a Wali-initiated link
  is created, mirroring the same pattern already used for match
  creation (create_match_on_mutual_like).

Impact:
  New table wali_invites + two RPC-callable functions (deliberately
  exposed to anon/authenticated — reviewed, not a defect, see
  Supabase advisor notes in this session). Seeker Profile screen
  gains "Link a Wali"; Wali Profile screen gains "Link a Seeker" and
  a real linked-Seeker count; Wali Dashboard/Seekers tabs show real
  linked names instead of a permanent empty state. Journey/Timeline
  visibility for a Wali remains unbuilt — linking only confirms the
  relationship exists, per this DR's explicit scope boundary.

Related:
  APP/Standards/WALI_ARCHITECTURE_CURRENT_VERSION_V5.md,
  SYSTEM/DOCUMENTS/ZYRA_DATABASE_SCHEMA_CURRENT_VERSION_V1.md,
  SOURCE/lib/services/zyra_wali_link_service.dart,
  SOURCE/supabase/migrations/, DR-ZYRA-081, DR-ZYRA-082

------------------------------------------------------------

DR-ZYRA-084
Title:       Compatibility Scoring (DR-ZYRA-079) wired into real
             Browse candidates
Date:        2026-07-18
Status:      RATIFIED 2026-07-25 (OA-ZYRA-140 item 12, Founder
             decision: "ratify as-is" — bundled with DR-ZYRA-079,
             see that entry for reasoning)
Superseded By: None
Category:    Product / Matching
Owner:       Founder (Shakeel)
Approved by: Founder (Shakeel), 2026-07-25

Decision (proposed, not yet accepted):
  ZyraDiscoveryService.fetchCandidates() now calls DR-ZYRA-079's
  scoreCandidate() against real onboarding_answers data: candidates
  who fail one of the signed-in user's Hard Requirements are excluded
  outright; the remainder are silently ordered by score, highest
  first. The numeric score is never attached to SeekerProfile or
  exposed anywhere in the UI — it lives and dies inside the service
  function that computes candidate order.

Context:
  DR-079 itself already named this as the intended next step
  ("Impact: ...ready to wire in once...a real backend supplies it")
  — Chapter 3/4 answers now persist to onboarding_answers (DR-082),
  so the backend DR-079 was waiting on now exists. Left un-actioned,
  Chapter 3/4 would be genuinely pointless: 105 questions collected
  and stored, never once read back to affect anything a Seeker sees.

Alternatives considered:
  (1) Show the numeric score on Browse cards or Matches — rejected,
  hard blocked by both BROWSE_UX_SPEC_CURRENT_VERSION_V1.md ("Not
  shown on Browse cards. Not visible anywhere until Active Journey
  begins.") and MATCH_UX_SPEC_CURRENT_VERSION_V1.md (identical rule
  at Match time). This DR does not touch that rule — ordering by an
  unseen number isn't the same as showing the number, but showing it
  anywhere would need its own explicit decision to override the
  existing spec. (2) Wait for DR-079's formula itself to be ratified
  before wiring anything — considered, but DR-079 already frames
  itself as build-now/refine-later ("every constant... isolated...
  for easy tuning once reviewed"), and Hard Requirement exclusion
  specifically isn't really part of the "provisional weights" — it's
  a binary rule stated plainly in this build's own onboarding copy
  ("Marking anything red lets you add it as a Hard Requirement — ZYRA
  will never show you a match on that basis").

Reasoning:
  Silent ordering/exclusion carries much lower risk than surfacing an
  unreviewed number to real users, and is explicitly compatible with
  the existing display-timing spec. If the DR-079 formula's weights
  turn out to need adjustment, only this one function changes —
  nothing downstream depends on the score's exact value, only its
  relative ordering and the Hard Requirement null-exclusion.

Impact:
  SOURCE/lib/services/zyra_discovery_service.dart — new
  _applyCompatibility() private method. Best-effort: a Seeker who
  hasn't completed Chapter 3/4 yet (no onboarding_answers row) sees
  candidates in unscored, unfiltered order — no crash, no exclusion.
  Matches tab is deliberately NOT re-filtered by this — once two
  people have already mutually Liked and matched, a later Hard
  Requirement check does not retroactively unmatch them.

Related:
  DR-ZYRA-079, DR-ZYRA-082, BROWSE_UX_SPEC_CURRENT_VERSION_V1.md,
  MATCH_UX_SPEC_CURRENT_VERSION_V1.md,
  SOURCE/lib/services/compatibility_scoring.dart,
  SOURCE/lib/services/zyra_discovery_service.dart

------------------------------------------------------------

DR-ZYRA-085
Title:       Profile photo bucket made private; all display URLs
             become signed URLs
Date:        2026-07-19
Status:      PROPOSED — applied to keep spec compliance, awaiting
             Founder ratification
Superseded By: None
Category:    Security / Privacy / Storage
Owner:       Founder (Shakeel)
Approved by: Not yet approved

Decision (proposed, applied 2026-07-19):
  The profile-photos Storage bucket is now PRIVATE. All photo display
  URLs (own profile, Browse candidates, Matches) are 7-day signed
  URLs generated per fetch. Storage read RLS broadened from
  own-folder-only to "own photos, or photos of an active + complete
  profile" — exactly mirroring the already-approved profile_photos
  table SELECT policy.

Context:
  The bucket was created public on 2026-07-18. Public Supabase
  buckets serve objects by URL with no auth or RLS check at all, so
  the own-folder read policy added the same day restricted only API
  listing, not actual photo access — any photo was fetchable by
  anyone holding the URL, signed out. IMAGE_HANDLING_CURRENT_
  VERSION_V1.md states plainly: "Originals never publicly
  accessible." A public bucket cannot satisfy that sentence.

Alternatives considered:
  (1) Keep the bucket public and rely on unguessable UUID paths —
  rejected: violates the approved spec on its face, and URLs leak
  (chat apps, logs, screenshots). (2) Private bucket with per-photo
  access checks via an edge function — rejected for v1: signed URLs
  achieve the same boundary with zero new infrastructure.

Impact:
  Migration 20260719080749_private_profile_photos_bucket.sql
  (applied). Code: zyra_photo_service.dart (createSignedUrl on
  upload; new signedUrlsFor() batch helper; syncPhotos parses both
  signed and legacy public URL shapes), zyra_discovery_service.dart
  and zyra_match_service.dart now use signedUrlsFor(). NEEDS RUNTIME
  VERIFICATION on first compiled build — photo display everywhere is
  the test.

Related:
  IMAGE_HANDLING_CURRENT_VERSION_V1.md, DR-ZYRA-086,
  20260719080749_private_profile_photos_bucket.sql

------------------------------------------------------------

DR-ZYRA-086
Title:       Wali-linking security hardening (column-scoped updates,
             anon revocation, secure invite tokens)
Date:        2026-07-19
Status:      PROPOSED — applied as security fixes, awaiting Founder
             ratification
Superseded By: None
Category:    Security / Wali System
Owner:       Founder (Shakeel)
Approved by: Not yet approved

Decision (proposed, applied 2026-07-19):
  Three fixes in migration 20260719080735_security_hardening_wali_
  and_invites.sql (applied): (1) client UPDATE on wali_links
  restricted to the status column only, wali_suggestions to
  status + responded_at; (2) anon EXECUTE revoked on
  accept_wali_invite and preview_wali_invite; (3) wali_invites.token
  default switched from md5(random()) to pgcrypto gen_random_bytes.

Context:
  The wali_links UPDATE policy had no WITH CHECK and full-row column
  scope. Because the updated row only had to satisfy (seeker_id = me
  OR wali_id = me), a signed-in Wali could rewrite an existing
  link's seeker_id to point at ANY Seeker — creating an active
  guardianship link nobody consented to, bypassing the invite
  mechanism entirely. Separately, preview_wali_invite was callable
  signed-out and returns the inviter's first name for any valid
  token, and tokens were generated from a non-cryptographic source.

Reasoning:
  (1) closes a genuine privilege escalation inside the app's most
  sensitive relationship. (2) reverses a deliberate 2026-07-18 anon
  grant ("someone may open an invite before creating their
  account") — but no pre-auth invite flow exists anywhere in the
  app, so today the grant was only an anonymous probing surface. If
  a pre-auth deep-link invite flow is built later, re-grant anon on
  preview_wali_invite deliberately at that point. (3) is
  uncontroversial: same 8-char hex UX, secure source.

Impact:
  No app code change required (the app never updated wali_links
  columns directly; invite screens sit behind sign-in). Live
  advisors: the two remaining SECURITY DEFINER WARNs for the invite
  functions drop to authenticated-only.

Related:
  DR-ZYRA-083, 20260719080735_security_hardening_wali_and_invites.sql

------------------------------------------------------------

DR-ZYRA-087
Title:       Developer Mode test-scenario switcher with seeded real
             Supabase test accounts (hybrid)
Date:        2026-07-19
Status:      PROPOSED — Founder requested the feature and approved
             the hybrid approach 2026-07-19; implementation details
             awaiting ratification
Superseded By: None
Category:    Developer Tooling
Owner:       Founder (Shakeel)
Approved by: Hybrid approach approved by Founder 2026-07-19

Decision (proposed, applied 2026-07-19):
  DeveloperAccessScreen upgraded from a jump-menu into a
  test-scenario switcher. Six presets (Seeker Basic male/female,
  Seeker One male/female, Wali, Wali + Extended Wali) sign into
  seeded REAL Supabase test accounts (password auth, dev.*@zyra.test,
  seeded via SOURCE/supabase/seed_dev_accounts.sql) and apply the
  matching AppState preset, landing directly on a fully-onboarded
  Home/WaliHome. The original jump-menu remains below, unchanged.

Context:
  Founder request relayed via the 2026-07-18 handoff §5. Hybrid
  (real accounts + local AppState for what has no schema) chosen by
  Founder over pure-mock and pure-real on 2026-07-19.

Reasoning:
  Real sessions exercise real RLS, triggers and backend paths — the
  point of everything built on 2026-07-18. Plan gating and Extended
  Wali remain local AppState because subscriptions drive no UI yet
  and the entitlement engine has no schema. Password sign-in exists
  ONLY for these test accounts via ZyraAuth.signInWithTestAccount —
  Google + Apple remain the only user-facing auth (Founder
  instruction 2026-07-18 unchanged). Depends on the email provider
  remaining enabled server-side in Supabase Auth settings.

Impact:
  developer_access_screen.dart (rebuilt), zyra_auth.dart
  (signInWithTestAccount), app_state.dart (applyDevPreset),
  seed_dev_accounts.sql (new; already applied to live dev project).
  Test accounts have no photos, so they never appear in each other's
  Browse (photo requirement) — Browse still falls back to mock
  profiles. Delete all dev.*@zyra.test accounts before any real
  launch.

Related:
  DR-ZYRA-083, WALI_ARCHITECTURE_CURRENT_VERSION_V5.md,
  seed_dev_accounts.sql, ZYRA_FABLE_BUILD_REVIEW_2026-07-19_V1.md

------------------------------------------------------------

DR-ZYRA-088
Title:       Welcome Screen Refinements — Typography, Layout,
             Platform-Native Sign-In Priority
Date:        2026-07-19
Status:      PROPOSED — implemented per Founder instruction
             ("fix and run all"), awaiting Founder review/
             ratification, NOT ratified
Superseded By: None
Category:    Product / UX
Owner:       Founder (Shakeel) — source: ChatGPT UX review
Approved by: Implementation authorised by Founder 2026-07-19;
             design content not yet individually ratified

Decision (proposed, applied 2026-07-19):
  Implements OA-ZYRA-122. ZYRA wordmark letterSpacing widened
  1 -> 3 (zyra_text.dart) for a more premium feel — the
  underlying typeface (Playfair Display) was already changed
  2026-07-18, so this refines that choice rather than
  reopening it. Welcome screen vertical layout tightened
  (Spacer flex 3/4 -> 2/2) to reduce excess whitespace.
  Sign-in button order and sizing now platform-native:
  defaultTargetPlatform selects which provider is primary
  (larger, filled, leads) vs secondary (smaller, outline,
  follows) — Apple primary on iOS, Google primary elsewhere.

Context:
  ChatGPT-authored UX review, relayed by Founder, logged as
  OA-ZYRA-122, then authorised for implementation same session
  ("OK NOW FIX AND RUN ALL OAS WE JUST SPOKE ABOUT").

Alternatives considered:
  Typography: a full font swap was considered but rejected —
  the wordmark typeface was a deliberate Founder decision made
  the previous day (2026-07-18); widening letter-spacing
  improves premium feel without relitigating that choice or
  requiring a new licensed font asset neither party has yet.

Reasoning:
  Platform-native sign-in priority follows each OS's own
  convention (Apple emphasised on iOS, Google elsewhere) per
  the source review's explicit rationale. Layout tightening is
  a straightforward whitespace/balance fix with no structural
  risk.

Impact:
  screens/welcome_screen.dart, theme/zyra_text.dart. No schema,
  auth, or navigation changes. Not yet visually verified on
  device — no compiler/simulator available in this environment;
  verified only via manual brace/paren balance checks.

Related:
  OA-ZYRA-122

------------------------------------------------------------

DR-ZYRA-089
Title:       Browse Screen & Bottom Navigation Refinements —
             Floating Glassmorphic Nav, Swipe-Limit Modal
Date:        2026-07-19
Status:      PROPOSED — implemented per Founder instruction
             ("fix and run all"), awaiting Founder review/
             ratification, NOT ratified
Superseded By: None
Category:    Product / UX
Owner:       Founder (Shakeel) — source: ChatGPT UX review
Approved by: Implementation authorised by Founder 2026-07-19;
             design content not yet individually ratified

Decision (proposed, applied 2026-07-19):
  Implements OA-ZYRA-125. HomeShell's (Seeker) fixed solid
  dark-purple bottomNavigationBar replaced with a floating
  glassmorphic pill (BackdropFilter blur, rounded, inset 24px
  from each side, 14px above the safe area) rendered inside the
  body Stack instead of Scaffold's bottomNavigationBar slot, so
  photo content genuinely continues behind it (extendBody was
  already true — Browse's full-bleed photo already reached the
  screen edge; what changed is what floats on top). Nav item
  selected state now larger + full opacity, unselected smaller
  + dimmed, per the source review's spec. WaliHomeShell given
  the same treatment — its own code comment already called this
  out as a known deviation from WALI ARCHITECTURE's spec
  ("floating glass pill: same design as Seeker nav... both
  should move to the floating-pill treatment together if that
  gets confirmed"), confirmed today.

  Browse screen: the permanent "X/50 profiles" counter chip
  removed entirely from normal browsing. A daily limit
  (_dailyProfileLimit = 50) is now actually enforced — previously
  the counter was cosmetic only and never blocked further
  browsing. On reaching the limit, a glass modal explains the
  limit, reset time, and offers Upgrade to ZYRA One (pushes the
  existing UpgradeScreen) or Not now. Action buttons (Decline/
  Save/Like) repositioned from bottom:18 to bottom:96 to clear
  the new floating nav.

Context:
  ChatGPT-authored UX review, relayed by Founder, logged as
  OA-ZYRA-125, then authorised for implementation same session.

Alternatives considered:
  Left the swipe counter as a cosmetic-only display (no real
  enforcement) — rejected: the source review explicitly wants
  the limit to mean something ("present a clear modal... when
  it resets... upgrade options"), which requires actually
  blocking further actions once reached, not just hiding a
  number.

Reasoning:
  Matching Wali's nav to Seeker's, rather than just recolouring
  Wali's existing solid bar, resolves both this item and a
  pre-existing documented spec deviation in one change instead
  of two separate ones.

Impact:
  screens/home/home_shell.dart, screens/wali/wali_home_shell.dart,
  screens/browse/browse_screen.dart. New dependency on
  screens/subscription/upgrade_screen.dart from browse_screen.dart
  (already existed, now also referenced here). No schema changes.
  Not yet visually verified on device.

Related:
  OA-ZYRA-125, WALI_ARCHITECTURE_CURRENT_VERSION_V5.md

------------------------------------------------------------

DR-ZYRA-090
Title:       Remove Luxury Dark Purple From Active Use —
             Royal Purple as Primary Background App-Wide
Date:        2026-07-19
Status:      SUPERSEDED 2026-07-25 by DR-ZYRA-094 — the flat/
             no-fade override recorded below is no longer the
             ratified specification. Left in full below as
             historical record of what was live in the app and
             why, per this register's append-only convention.
Superseded By: DR-ZYRA-094 (2026-07-25) — final palette
             ratification restores gradient-into-Luxury-Dark-
             Purple as the specification. SOURCE/lib/theme/
             zyra_colors.dart still implements this entry's
             flat override as of 2026-07-25 and requires a code
             update to match DR-ZYRA-094 — not yet done, flagged
             for next build phase.
Category:    Product / UX — Brand Colour
Owner:       Founder (Shakeel)
Approved by: Founder, explicit instruction 2026-07-19 (see
             Context)

Decision (proposed, applied 2026-07-19):
  Luxury Dark Purple (#3D2A4A) removed from every active
  gradient/background in the app. Royal Purple (#8A6A9E) — an
  already-approved palette entry, not a new colour — becomes
  the flat default background used everywhere except gendered
  profile-context screens. Specifically:
    - ThemeData.scaffoldBackgroundColor (main.dart): Luxury
      Dark Purple -> Royal Purple.
    - ZyraColors.brandGradient: was #8A6A9E -> #3D2A4A,
      now flat #8A6A9E -> #8A6A9E.
    - ZyraColors.brandGradientMale: was #3D5A80 -> #3D2A4A,
      now flat #3D5A80 -> #3D5A80 (Royal Blue).
    - ZyraColors.brandGradientFemale: was #D4868F -> #3D2A4A,
      now flat #D4868F -> #D4868F (Rose Pink).
    - ZyraColors.backgroundFor() (the three onboarding
      gradients from Onboarding Rules & UX §COLOUR SYSTEM,
      previously dark near-black hues varying by gender) now
      returns brandGradient (flat Royal Purple) for all three
      variants — onboarding no longer varies by gender, per
      OA-ZYRA-123's "Default Screens" list explicitly including
      Onboarding.
    - auth_gate.dart splash background, browse_screen.dart
      fallback background: Luxury Dark Purple -> Royal Purple.
  `luxuryDarkPurple` remains defined as a constant in
  zyra_colors.dart, deliberately unused rather than deleted.

Context:
  This directly overrides two previously-approved documents:
  BUSINESS/COLOUR THEME/Summary.md ("The shared Luxury Dark
  Purple ties every theme together, creating a cohesive,
  premium experience") and Onboarding Rules & UX §COLOUR
  SYSTEM (gender-derived dark onboarding backgrounds, which
  explicitly rejected a proposed 4th variant as recently as
  the decision that produced it). Raised as a direct conflict
  with OA-ZYRA-123 (light-purple-everywhere UX review item)
  before any code was touched — see chat log 2026-07-19. Founder
  resolved it explicitly: "do option 2 [override with ChatGPT's
  version] but remember the colour we're removing might become
  primary colour in future as I'm testing, but for now the
  light purple is main colour and to be used and the darker
  shade is not to be present in the app."

Alternatives considered:
  (1) Keep the existing approved dark-purple-anchored system —
  rejected, Founder explicitly overrode it. (2) Introduce a new,
  never-before-approved lighter hex value — rejected in favour
  of reusing Royal Purple, which is already an approved palette
  entry (BUSINESS/COLOUR THEME/Summary.md), consistent with
  zyra_colors.dart's own stated rule not to invent colours.
  (3) Delete `luxuryDarkPurple` entirely — rejected per Founder's
  explicit note that it may return as primary later; left
  defined and unused instead.

Reasoning:
  Founder authority is sufficient to override a previously
  approved document, but the override should be recorded
  rather than silently applied, and should reuse an existing
  approved colour rather than invent a new one where possible.
  Both conditions are met here.

Impact:
  theme/zyra_colors.dart, main.dart, screens/auth_gate.dart,
  screens/browse/browse_screen.dart, screens/home/home_shell.dart
  (already touched by DR-089), screens/wali/wali_home_shell.dart
  (already touched by DR-089). Every onboarding screen changes
  appearance without individual code changes, since they all
  route through ZyraColors.backgroundFor() via
  widgets/onboarding_scaffold.dart. BUSINESS/COLOUR THEME/
  Summary.md and Onboarding Rules & UX §COLOUR SYSTEM are now
  stale relative to the live app and should be updated (or
  explicitly marked superseded) in a future documentation pass
  — not done as part of this change. Not yet visually verified
  on device; readability/contrast of existing white text against
  the lighter Royal Purple background has not been checked and
  should be part of Founder's on-device review.

Related:
  OA-ZYRA-123, DR-ZYRA-089, BUSINESS/COLOUR THEME/Summary.md,
  Onboarding Rules & UX.md §COLOUR SYSTEM

------------------------------------------------------------

DR-ZYRA-091
Title:       Floating Nav Bar Rebuilt to Match Instagram +
             Lovable Reference Recordings — Shared FloatingNavBar
             Widget
Date:        2026-07-19
Status:      PROPOSED — implemented per Founder instruction,
             awaiting Founder review/ratification, NOT ratified
Superseded By: None
Category:    Product / UX
Owner:       Founder (Shakeel)
Approved by: Founder supplied two reference screen recordings
             and asked for this treatment directly; not yet
             seen running on device

Decision (proposed, applied 2026-07-19):
  Extracted frames from two Founder-supplied screen recordings
  (Instagram's own nav bar; an earlier Lovable-built ZYRA
  prototype) and rebuilt the DR-ZYRA-089 floating nav bar to
  match both: a single circular highlight "blob" that slides
  between tab positions (AnimatedPositioned, 260ms, easeOutCubic)
  rather than each tab carrying its own static background — this
  is the Lovable reference's behaviour — combined with the
  Instagram reference's icon-grows-when-selected animation
  (AnimatedScale, 0.82x -> 1.0x). Extracted into a new shared
  widget, widgets/floating_nav_bar.dart, used by both HomeShell
  and WaliHomeShell so they can never visually drift apart again.
  Text labels kept under the icons for now — Founder has not yet
  decided labels vs no-labels (neither reference video shows
  labels); `showLabels` param makes removing them later a one-
  line change.

Context:
  Founder: "see how instrgram make the nav tab bigger when
  lciked and smaller when unlicked... copy its ui. see video 2..
  see how lovable built it. its better then what we have and i
  want it like that." Frames extracted via ffmpeg (already in
  the sandbox) since video can't be viewed directly.

Alternatives considered:
  Kept each tab's own AnimatedScale-only approach from DR-089 —
  rejected once the Lovable reference showed a single sliding
  highlight is the actual visual language wanted, which a
  per-item static background can't replicate.

Reasoning:
  Consolidating into one shared widget (rather than duplicating
  the animation logic in both shell files, as DR-089 had done)
  directly serves the Founder's own standing instruction that
  shared UI patterns should live in one place so nothing drifts
  or gets lost across files.

Impact:
  New file widgets/floating_nav_bar.dart. screens/home/home_shell.dart
  and screens/wali/wali_home_shell.dart both simplified to call
  it instead of carrying their own copy of the bar + _NavItem
  class. No behaviour change to which tabs exist or what they do,
  purely visual/animation. Not yet visually verified on device —
  no compiler/simulator available in this environment; verified
  only via manual brace/paren balance checks and by reading
  extracted video frames directly.

Related:
  DR-ZYRA-089, OA-ZYRA-125

------------------------------------------------------------

DR-ZYRA-092
Title:       ZYRA APP/BUSINESS Documentation Architecture —
             Implementation Checklist, Citation Discipline,
             Ownership Test, and Summary Header Update
Date:        2026-07-19
Status:      Approved
Owner:       Lead Architect
Approved by: Founder (Shakeel), 2026-07-19, following joint
             architectural review (Claude + ChatGPT, standing
             in for Codex while offline) and independent review
             (Fable / Opus 4, two review cycles, both errors and
             corrections on both sides verified against primary
             sources before acceptance).

Decision:
  1. ZYRA_EXECUTION_V2.md §3.2: before writing or approving a
     feature Summary, check the Master Product Spec, the
     relevant BUSINESS Summary, the relevant APP Summary, the
     Decisions Register, and Outstanding Actions; stop and
     raise any conflict before implementation. Absence of a
     Summary is itself a finding, not permission to proceed.
     State-touching ideas are additionally checked against the
     State Integrity Principle (AD-082), Product Spec V3 §0.1.
  2. "Cite, don't restate": canonical cross-cutting facts belong
     in the layer that owns them and are cited, never restated,
     by other layers.
  3. Ownership between Master Spec / BUSINESS / APP is decided
     by a test, not a fixed topic list — mirrors AD-087 §1.3
     (Irreducible Question Test) and AD-082 (State Integrity).
  4. ZYRA_EXECUTION_V2.md §3.3 corrected: SPEC → APPROVED
     requires Founder sign-off, not "Lead Architect signs off"
     as V1 read. Drafting a Summary remains Claude's direct
     role; only the Draft → Approved transition is gated.
  5. SUMMARY_STANDARD_CURRENT_VERSION_V2.md: header field labels
     changed from uppercase to mixed case (`Group:`, `Summary
     Version:`, `Status:`, `Last Reviewed:`) to match established
     practice, confirmed against all 23 live Summary.md files
     (23/23 use `Group:`, 0 use `GROUP:`). `FEATURE NAME` remains
     uppercase — the one part of the header live practice does
     follow. Two new optional fields added in the same
     convention: `Governed By:` and `Depends On:`.

Context:
  Triggered by OA-ZYRA-133 (2026-07-19): a ChatGPT-authored
  "Active Journey" proposal, from a separate thread, re-derived
  relationship states already ratified in
  ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V3.md Part 0, because the
  Master Spec wasn't checked before the proposal was written.
  Investigation (Claude, verified directly against the
  repository) found the underlying philosophy, document
  hierarchy, and Summary Standard already existed and were
  sound — the gap was operational, not architectural.

  Full proposal drafted jointly with ChatGPT, then independently
  reviewed by Fable (Opus 4) across two cycles. Fable's first
  pass found one real ambiguity (Package vs. Report placement
  for a related BLK-level item, resolved by splitting prospective
  instruction from retrospective evidence) and raised citation
  concerns against the request. On counter-verification, two of
  those concerns were themselves shown to rest on misremembered
  citations rather than the source text (a §14.4/14.5 mix-up
  that turned out to be genuine duplication in BLK governance,
  not a Claude error; a "Feature Integration Test" name that
  does not appear anywhere in Product Spec V3 — the real name is
  the State Integrity Principle, AD-082). Fable revised its
  review accordingly. The pattern — restating a fact from memory
  instead of citing the source — recurred on both sides of the
  review, which is itself the strongest evidence for adopting
  items 1 and 2.

Alternatives:
  Generic YAML/machine-readable metadata for Summary headers —
    considered and rejected in favour of two narrowly-scoped
    fields, after confirming AIOS's Context Resolver is
    explicitly out of scope for generic artefact resolution and
    would not consume such a schema regardless.
  Fixed topic list per layer (e.g. "BUSINESS = Pricing,
    Terminology, Colour Theme") for ownership boundaries —
    rejected in favour of a decision test, since a topic list
    goes stale the first time a new kind of content appears.
  Keep the Summary Standard's original uppercase header example
    and bring all 23 live files into compliance — rejected;
    Founder decision was to correct the Standard to match
    established practice rather than mark the whole repository
    non-compliant against an example nothing had ever followed.

Reasoning:
  The repository's documentation architecture (Master Spec /
  BUSINESS / APP, the Summary Standard, the IDEA→SPEC→APPROVED
  lifecycle) was already correctly designed. The failure mode
  found tonight — twice, once in the original incident and once
  inside the review process itself — is citing from memory
  instead of checking the source. Every item in this decision is
  either an existing principle applied at a new point in the
  workflow (the checklist, citing BLK's own Conflict Flag Before
  Edit) or a documentation rule already partially practised being
  made explicit and enforceable (cite-don't-restate, the
  ownership test, correcting the header to match reality).
  Nothing here is new governance; all of it operationalises
  governance that already existed.

Impact:
  SYSTEM/DOCUMENTS/MASTER_CONTRACTS/ZYRA_EXECUTION_V2.md
    (supersedes V1, archived).
  SYSTEM/DOCUMENTS/MASTER_STANDARDS/SUMMARY_STANDARD_
    CURRENT_VERSION_V2.md (supersedes V1, archived).
  SYSTEM/DOCUMENTS/MASTER_STANDARDS/ZYRA_STANDARDS_LIBRARY_V1.md
    (cross-reference updated to V2).
  All future Summary.md creation and approval. No existing
    Summary.md file is renamed or reformatted by this decision.
  A related BLK-level item (Repository Review addition to AD-089)
    and a related BLK governance duplication (Conflict Flag
    Before Edit stated independently in both
    EXECUTION_CURRENT_VERSION_V10.md §14.5 and
    GOVERNANCE_CURRENT_VERSION_V8.md §14.4) are tracked separately
    at the Black Umbrella Group level, not part of this decision.

Related:
  OA-ZYRA-133 (triggering incident)
  OA-018, DR-022 (original Summary Standard)
  AD-087 §1.3, AD-082 (decision-test lineage)
  Consolidated Governance Review Package, 2026-07-19, Subject 4

------------------------------------------------------------

# Register Metadata (added 2026-07-12)

DR-ZYRA-093
Title:       Summary Status Field — Traffic-Light Decision States
             (🟢 Finalised / 🟡 Under Review / 🔴 Founder Decision
             Required), and Checklist Extension
Date:        2026-07-19
Status:      Approved
Owner:       Lead Architect
Approved by: Founder (Shakeel), 2026-07-19, same day as DR-ZYRA-092,
             triggered by testing that decision's checklist against
             a real feature folder within the hour.

Decision:
  1. SUMMARY_STANDARD_CURRENT_VERSION_V3.md §2.1: the Status field's
     enum (`Draft | In Review | Approved Specification`) is replaced
     with three states — 🟢 Finalised, 🟡 Under Review, 🔴 Founder
     Decision Required — each carrying a defined hex pair supplied
     by the Founder (green #00CC44/#1A7A2E, amber #FFE020/#B89A00,
     red #FF3B3B/#A61C1C) for future visual tooling.
  2. ZYRA_EXECUTION_V3.md §3.2: the pre-implementation checklist
     (DR-ZYRA-092) gains two items — (f) explicitly check the
     Summary's References.md Open Dependencies section; (g)
     explicitly check the Status field and stop unless it reads 🟢
     Finalised, asking the Founder directly rather than selecting
     the most likely option.
  3. BUSINESS/COLOUR THEME/Summary.md becomes the first live Summary
     to carry the new field, set honestly to 🔴 — this records the
     document's own pre-existing unresolved state, not a new
     finding and not the new three-gradient palette decision, which
     remains explicitly unfiled pending separate Founder instruction.

Context:
  DR-ZYRA-092 (this same evening) ratified a pre-implementation
  checklist requiring specific documents to be checked before a
  feature is built from. Tested against BUSINESS/COLOUR THEME/
  within the hour: the Founder had noticed that implementation
  earlier this session had used Option 1's palette values from
  that folder while its own References.md explicitly stated
  "Option 1 vs Option 2 decision not yet formally approved." Two
  gaps were found by this real test: the checklist did not name
  References.md at all, and the existing Status field's three
  values (Draft/In Review/Approved Specification) did not
  distinguish "still being drafted" from "specifically blocked on
  a Founder decision" — the distinction that actually determines
  whether implementation should stop.

  Both AI participants (Claude, ChatGPT) independently proposed
  extending the existing Status mechanism rather than introducing
  a parallel one; the Founder supplied the exact three-state model
  and hex values to close the decision same-day.

Alternatives:
  Add "Founder Decision Required" as a fourth value alongside the
    existing three — considered; rejected in favour of replacing
    Draft/In Review with a single Under Review state, since the
    distinction that matters operationally is "locked or not
    locked, and if not locked, is a Founder decision the blocker,"
    not the finer editorial distinction between drafting and review.
  A new, separate status-tracking mechanism outside the existing
    Summary header — rejected for the same reason DR-ZYRA-092
    rejected generic metadata: reuse an existing mechanism rather
    than build a parallel one.

Reasoning:
  Consistent with the whole evening's governing principle: this is
  not new governance, it is an existing mechanism (the Status field,
  ratified V1/V2 hours earlier) closing a gap that a real test case
  found within the hour. The field removes the specific failure
  mode the Colour Theme incident demonstrated — a reader (human or
  AI) having to interpret phrases like "current favourite" or
  "proposed" to infer whether a decision is locked, when a single
  required field can make that unambiguous.

Impact:
  SYSTEM/DOCUMENTS/MASTER_STANDARDS/SUMMARY_STANDARD_
    CURRENT_VERSION_V3.md (supersedes V2, archived).
  SYSTEM/DOCUMENTS/MASTER_CONTRACTS/ZYRA_EXECUTION_V3.md
    (supersedes V2, archived).
  SYSTEM/DOCUMENTS/MASTER_STANDARDS/ZYRA_STANDARDS_LIBRARY_V1.md
    (cross-reference updated to V3).
  BUSINESS/COLOUR THEME/Summary.md (Status field added, set to 🔴).
  No other existing Summary.md file is required to add this field
    immediately — per the Adoption Guidance exception in
    SUMMARY_STANDARD_CURRENT_VERSION_V3.md §4, it is populated the
    next time ZYRA_EXECUTION_V3.md §3.2's checklist is actually run
    against a given feature, not retrofitted in bulk.
  The three-gradient colour decision itself (Purple = Global Brand
    / Default, Blue = Male Seeker + Male Wali, Pink = Female Seeker
    + Female Wali) remains discussion only — not recorded by this
    decision, awaiting separate explicit Founder instruction to file.

Related:
  DR-ZYRA-092 (same-day, the checklist this decision extends)
  BUSINESS/COLOUR THEME/Summary.md, References.md (triggering
    incident)
  AD-087 §1.3 (decision-test lineage, indirectly — same reuse
    discipline)

------------------------------------------------------------

DR-ZYRA-094
Title:       Colour Theme — Final Palette Ratified (Purple
             Default / Blue Male / Pink Female, into Luxury
             Dark Purple)
Date:        2026-07-25
Status:      Approved
Owner:       Lead Architect
Approved by: Founder (Shakeel), 2026-07-25. Preceded by a
             2026-07-19 multi-model confirmation round (Claude,
             ChatGPT) establishing mutual understanding of the
             Founder's three reference gradients before filing
             was authorised; filing itself authorised 2026-07-25
             ("YEH DO IT").

Decision:
  1. `BUSINESS/COLOUR THEME/Summary.md`'s "Option 1" is ratified
     as the final, locked colour palette:
       Global Brand / Default: #8A6A9E → #3D2A4A
       Male Theme (Male Seeker + Male Wali): #3D5A80 → #3D2A4A
       Female Theme (Female Seeker + Female Wali): #D4868F → #3D2A4A
     matching the Founder's verbal confirmation ("blue to purple
     for male seekers and wali, pink to purple for female seekers
     and wali, purple is default for everything else") and
     `Flow Diagram.md`'s COLOUR APPLICATION LOGIC, which already
     specified these exact values.
  2. "Option 2" (no dedicated brand colour, flat two-colour
     system) is rejected.
  3. `Summary.md` Status field set to 🟢 Finalised.
     `References.md`'s Open Dependencies entry for this decision
     marked resolved.
  4. This supersedes DR-ZYRA-090's flat/no-fade override (Luxury
     Dark Purple removed from active gradients, live-testing-
     phase, explicitly not ratified). The ratified specification
     restores the gradient behaviour — every theme fades into
     Luxury Dark Purple as originally documented.

Context:
  The Founder noticed implementation earlier in the session had
  used Option 1's values while `References.md` explicitly flagged
  the choice as unresolved ("Option 1 vs Option 2 decision not
  yet formally approved") — the incident that produced DR-ZYRA-092
  and DR-ZYRA-093 (checklist and Status-field extensions,
  2026-07-19). The Founder separately confirmed, via three
  uploaded gradient reference images, that the three colours ARE
  final, but explicitly withheld filing until mutual understanding
  was confirmed between Claude and ChatGPT first (2026-07-19,
  workflow-confirmation round, traffic-light Status system
  proposal). Filing authorised today, 2026-07-25, on direct
  Founder instruction after independently reviewing the live
  Summary.md and confirming the 🔴 flag and Option 1/2 framing
  were both still accurately describing the pre-ratification state.

Alternatives:
  Option 2 (no dedicated brand colour) — rejected; see Summary.md
    REJECTED ALTERNATIVE section and original OPTION 2 concerns
    (unclear default/splash colour, weaker brand identity).

Reasoning:
  The three reference gradients the Founder supplied match Option
  1's already-documented hex values and `Flow Diagram.md`'s
  existing COLOUR APPLICATION LOGIC exactly — no new hex values
  were introduced, only the decision to lock in what was already
  the documented "current favourite." Locking it removes the
  ambiguity that caused the original miss.

Impact:
  BUSINESS/COLOUR THEME/Summary.md (Status → 🟢 Finalised, Option
    1/2 framing replaced with a single ratified palette, Option 2
    content trimmed to a rejected-alternative note).
  BUSINESS/COLOUR THEME/References.md (Open Dependencies entry
    resolved).
  DR-ZYRA-090 (SUPERSEDED — flat/no-fade override no longer the
    ratified spec; entry left intact as historical record per
    this register's append-only convention).
  **Built 2026-07-25, same day** (Founder build authorisation given
    later this session): `SOURCE/lib/theme/zyra_colors.dart` now
    implements this decision (`brandGradient`, `brandGradientMale`,
    `brandGradientFemale`), and `ZyraColors.genderGradient()` (added
    under DR-ZYRA-101) applies Male/Female gradients across
    profile-context screens app-wide.
  OA-ZYRA-123 (Theme Consistency During Onboarding, ChatGPT UX
    review item, ratification still pending) is NOT resolved by
    this decision — it concerns onboarding flow behaviour and
    whether gender accents are reserved for profile screens only,
    a distinct question from the palette hex values ratified here.

Related:
  DR-ZYRA-090 (superseded by this decision), DR-ZYRA-092,
  DR-ZYRA-093 (same incident chain), OA-ZYRA-123 (related, not
  resolved), BUSINESS/COLOUR THEME/Summary.md, References.md,
  Flow Diagram.md.

------------------------------------------------------------

DR-ZYRA-095
Title:       Browse Screen Reporting & Safety Actions — Report /
             Hide / Block (three-dot menu)
Date:        2026-07-25
Status:      Approved
Owner:       Lead Architect
Approved by: Founder (Shakeel), 2026-07-25 ("work though [OA-130
             through 133], any questions ask ChatGPT otherwise
             update docs").

Decision:
  1. `APP/Browse/BROWSE_UX_SPEC_CURRENT_VERSION_V1.md` superseded
     by V2 — adds a "Profile Actions — Report / Hide / Block"
     section: permanent three-dot (•••) menu, top-right of every
     Browse card, opening Report Profile / Hide Profile / Block
     User / Cancel. Full definitions, report flow, and design
     principles per OA-ZYRA-132's source content.
  2. This resolves the Browse-screen, pre-Journey, Seeker-to-
     Seeker portion of the "Full Safety & Moderation design"
     item flagged as an Open Discussion in `APP/Journey/JOURNEY
     MANAGEMENT/Summary.md`. It does NOT resolve: Block/Report
     Wali, blocking effects on an existing Active Journey/
     Timeline, or post-Journey-end privacy — `JOURNEY MANAGEMENT/
     Summary.md` updated 2026-07-25 to reflect partial, not full,
     resolution.
  3. OA-ZYRA-132 marked Actioned in `OUTSTANDING_ACTIONS_V2.md`.

Context:
  Founder instructed working through four ChatGPT UX review items
  logged 2026-07-19 (OA-ZYRA-130 through 133), asking ChatGPT for
  anything genuinely open and filing directly otherwise. Checked
  first against `BROWSE_UX_SPEC_CURRENT_VERSION_V1.md` (no
  existing report/hide/block mechanism) and `JOURNEY MANAGEMENT/
  Summary.md` (explicitly listed this as unspecified) per
  ZYRA_EXECUTION_V3.md §3.2 — no conflicts found, additive only.

Alternatives:
  Long-press gesture — rejected, poor discoverability, conflicts
    with swipe gestures, discouraged for safety-critical actions.
  Dedicated flag icon — rejected, implies reporting is the only
    action, no room for future options, unnecessarily aggressive
    on every profile.

Reasoning:
  As proposed in OA-ZYRA-132's source content (ChatGPT UX review,
  2026-07-19) — reasoning reproduced in full in
  BROWSE_UX_SPEC_CURRENT_VERSION_V2.md §Profile Actions.

Impact:
  APP/Browse/BROWSE_UX_SPEC_CURRENT_VERSION_V2.md (new, supersedes
    V1, archived as BROWSE_UX_SPEC_2026-07-25_V1.md, same folder —
    no ARCHIVE subfolder convention exists under APP/).
  APP/Journey/JOURNEY MANAGEMENT/Summary.md (Open Discussions
    updated to reflect partial resolution).
  Not yet built — SOURCE/ has no three-dot menu or report/hide/
    block flow yet. Documentation filing only.

Related:
  OA-ZYRA-132, JOURNEY MANAGEMENT/Summary.md, APP/Profiles/
  Summary.md (photo-report path this feeds into — the conflict
  flagged there at filing time was resolved same-day, see
  DR-ZYRA-096).

------------------------------------------------------------

DR-ZYRA-096
Title:       Image Handling Standard V2 — Merges Photo Cropping
             (OA-ZYRA-130) and Photo Moderation (OA-ZYRA-131) Into
             One Canonical Pipeline, Resolves Conflict With V1
Date:        2026-07-25
Status:      Approved
Owner:       Lead Architect
Approved by: Founder (Shakeel), 2026-07-25, following convergent
             recommendations from ChatGPT and the Founder
             independently, in response to the conflict raised in
             `APP/Profiles/Summary.md`.

Decision:
  1. `APP/Standards/IMAGE_HANDLING_CURRENT_VERSION_V1.md` superseded
     by V2. Core Philosophy unchanged: automatic processing remains
     the default and primary workflow — "the user uploads one
     photo, ZYRA does everything else."
  2. Manual crop adjustment (OA-ZYRA-130) is added as an **exception
     path only**, triggered by exactly two conditions: (a) Step 6's
     automatic smart-crop has low confidence, or (b) the user
     explicitly chooses to adjust their photo afterwards, from
     profile settings. Never presented as a required or default step
     during upload.
  3. A new "Safety & Authenticity Screening" stage (OA-ZYRA-131
     Stages 1–2) is merged into the pipeline, running alongside the
     existing AI Quality Evaluation. The previous "Photo Review &
     Approval Flow" and OA-131's "Manual Review" are merged into one
     "Moderation Decision & Manual Review" section — one canonical
     pipeline, not two parallel ones.
  4. Canonical pipeline order: Upload → AI Quality → Safety &
     Authenticity → Face Detection & Smart Crop → Moderation
     Decision.
  5. `APP/Profiles/Summary.md` rewritten to cite this document
     rather than restate the pipeline (per Cite Don't Restate,
     SUMMARY_STANDARD_CURRENT_VERSION_V3 §5.1) — Status changed from
     🔴 back to 🟢 Finalised.

Context:
  Filing OA-ZYRA-130/131 directly into a new Profiles/Summary.md
  surfaced a direct contradiction with the already-ratified
  IMAGE_HANDLING_CURRENT_VERSION_V1.md (2026-06-28): V1's Core
  Philosophy states cropping is fully automatic, with the only user
  interaction being "Upload Photo"; OA-130 proposed a manual crop
  editor as the primary flow. Raised to ChatGPT and the Founder
  together rather than resolved unilaterally. Both independently
  recommended keeping the automatic pipeline as the default and
  treating manual cropping as a narrow exception — the Founder's
  exact words: *"I would not introduce a manual crop editor as the
  default behaviour... The only situation I'd consider allowing
  manual adjustment is if the AI cannot confidently produce a good
  crop or the user explicitly chooses to adjust it afterwards."*
  ChatGPT independently proposed the same merged-pipeline structure
  before seeing the Founder's message.

Alternatives:
  Treat OA-130's manual crop editor as the default flow, discard
    IMAGE_HANDLING's automatic-only philosophy — rejected by both
    ChatGPT and the Founder as worse UX (more friction, less
    "intelligent" feel) and a direct reversal of an already-ratified
    principle without cause.
  Keep two separate, parallel moderation pipelines (IMAGE_HANDLING's
    AI Quality Evaluation and OA-131's 4-stage safety/authenticity
    pipeline) — rejected; both ChatGPT and the Founder wanted one
    canonical pipeline, consistent with this session's repeated
    "one source of truth" discipline.

Reasoning:
  This is the same lesson the session's governing principle keeps
  producing: when a new proposal overlaps an existing specification,
  the question is whether it is genuinely new architecture or a
  better implementation/presentation of what already exists. Here,
  OA-130/131 were a better *implementation* of image handling in
  places (safety/authenticity screening was a real gap) but a worse
  *default UX* in one place (manual cropping as primary flow) — the
  resolution keeps what was genuinely additive and rejects what would
  have reversed a already-good, already-ratified decision.

Impact:
  APP/Standards/IMAGE_HANDLING_CURRENT_VERSION_V2.md (new, supersedes
    V1, archived as IMAGE_HANDLING_2026-07-25_V1.md, same folder).
  APP/Profiles/Summary.md (V2 — rewritten to cite rather than
    restate; Status 🔴 → 🟢 Finalised).
  OA-ZYRA-130, OA-ZYRA-131 marked Actioned in OUTSTANDING_ACTIONS_V2.md.
  Not yet built — SOURCE/ has no crop editor, safety/authenticity
  screening, or merged moderation flow yet. Documentation filing
  only; vendor selection and confidence thresholds deferred to build
  phase.

Related:
  OA-ZYRA-130, OA-ZYRA-131, APP/Profiles/Summary.md, APP/Browse/
  BROWSE_UX_SPEC_CURRENT_VERSION_V2.md (DR-ZYRA-095, the post-
  approval report path this pipeline feeds into).

------------------------------------------------------------

DR-ZYRA-097
Title:       Active Journey Availability Status — UX Presentation
             Layer Over Existing Journey Eligibility, No New
             Architecture
Date:        2026-07-25
Status:      Approved
Owner:       Lead Architect
Approved by: Founder (Shakeel), 2026-07-25, following convergent
             recommendations from ChatGPT and the Founder.

Decision:
  1. OA-ZYRA-133's Active Journey System Proposal is **not** filed as
     a new architecture document. Its "One Active Journey" recommendation
     was already established (Product Spec V3 Part 0, Journey
     Philosophy, Journey Availability) and required no new decision.
  2. Its "Potential Journey Statuses" idea is filed as a new
     "Availability Status" section within the existing `APP/Journey/
     JOURNEY AVAILABILITY/Summary.md`, extending that document's
     existing "Journey Eligibility" concept rather than replacing or
     duplicating it.
  3. Terminology split: backend/business logic keeps "Journey
     Eligibility" (unchanged); frontend/UI introduces "Availability
     Status" as the user-facing presentation of the same value.
  4. Colour model reduced from OA-133's original four statuses
     (🟢🟡⚪⚫) to three, reusing ZYRA's existing traffic-light colours
     only — Paused and Hidden/Inactive both collapse to 🔴
     Unavailable. No new colours (white, black, blue, grey)
     introduced.
  5. Privacy constraint carried over unchanged: no Journey duration,
     stage, compatibility progress, family discussion, proposal
     status, or estimated completion is ever shown about another
     user — Availability Status is the only Journey-related
     information ever surfaced.

Context:
  OA-ZYRA-133 was flagged at filing time (2026-07-19) as needing to
  be checked against Product Spec V3 Part 0 before being treated as
  new — it was also received truncated, cutting off mid-example.
  Checked 2026-07-25 against Product Spec V3 Part 0 (Feature-State
  Covenant — no new relationship state introduced, so no conflict)
  and against `JOURNEY AVAILABILITY/Summary.md` (already covers "one
  Active Journey, many Potential Journeys" and an existing
  eligible/not-eligible concept with reasons). Raised to ChatGPT and
  the Founder rather than resolved unilaterally, given the overlap.
  Both independently concluded this is a UX refinement of existing
  architecture, not a new proposal — ChatGPT additionally supplied
  the exact terminology split and the three-colour reduction (its
  own recommendation, reasoning that ZYRA's existing traffic-light
  language already means 🟢 = yes, 🟡 = maybe/depends, 🔴 = no, and
  that introducing new colours would break that consistency).
  Truncation question (whether more of OA-133's source document
  exists) not resolved by this decision — remains open.

Alternatives:
  New standalone "Active Journey System" document — rejected by both
    reviewers; would duplicate JOURNEY AVAILABILITY/Summary.md and
    risk the same kind of drift DR-ZYRA-092 was created to prevent.
  Four-colour status system as originally proposed — rejected in
    favour of reusing the existing three-colour traffic-light
    language already established platform-wide (DR-ZYRA-093).

Reasoning:
  Consistent with this session's repeated finding: the right
  response to an overlapping proposal is to ask whether it is new
  architecture or a better presentation of existing architecture,
  and merge accordingly rather than default to a new document.

Impact:
  APP/Journey/JOURNEY AVAILABILITY/Summary.md (new "Availability
    Status" section added — no other file changed).
  OA-ZYRA-133 marked Actioned (partially — see Context re:
    truncation) in OUTSTANDING_ACTIONS_V2.md.
  Not yet built — SOURCE/ has no Availability Status UI yet.

Related:
  OA-ZYRA-133, ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V3.md Part 0,
  DR-ZYRA-093 (traffic-light colour system this reuses).

------------------------------------------------------------

DR-ZYRA-098
Title:       Bottom Navigation Bar — Slide Gesture Support
             (drag-to-navigate alongside existing tap navigation)
Date:        2026-07-25
Status:      Approved
Owner:       Lead Architect
Approved by: Founder (Shakeel), 2026-07-25.

Decision:
  `APP/Navigation/SEEKER NAVIGATION/Summary.md` §NAVIGATION UI
  extended: the bottom navigation bar supports Slide Navigation
  (drag horizontally across the bar, live-follows the finger,
  navigates on release) alongside existing Tap Navigation. Neither
  replaces the other.

Context:
  Source: ChatGPT UX proposal, 2026-07-25 (OA-ZYRA-136). Checked
  first against this document's explicit "tap-only" rule (Approved
  Rules) before filing — that rule is scoped specifically to
  Browse's Decline/Save/Like actions ("swiping feels casual and
  conflicts with ZYRA's serious marriage philosophy"), not to
  bottom-navigation, so no conflict. Also checked against the
  already-approved DR-ZYRA-091 Instagram-style motion behaviour
  (sliding circular highlight between tabs) — complementary, not
  duplicative.

Alternatives:
  None proposed — this is a straightforward additive interaction
  enhancement with no competing approach raised.

Reasoning:
  Extends an already-approved motion language (DR-ZYRA-091) rather
  than introducing a new one; does not touch the tap-only rule that
  governs a philosophically different part of the product (Browse
  decisions).

Impact:
  APP/Navigation/SEEKER NAVIGATION/Summary.md (§NAVIGATION UI
    extended).
  OA-ZYRA-136 marked Actioned in OUTSTANDING_ACTIONS_V2.md.
  Not yet built — SOURCE/ has no slide-navigation gesture handling
  yet.

Related:
  OA-ZYRA-136, DR-ZYRA-091, OA-ZYRA-135 (companion proposal from the
  same batch — NOT filed at the time, see DR-ZYRA-099, filed same
  session once the Founder resolved the conflict directly).

------------------------------------------------------------

DR-ZYRA-099
Title:       Browse Profile Actions Renamed Pass/Save/Consider;
             Swipe Gestures Adopted, Overriding Prior Tap-Only Rule
Date:        2026-07-25
Status:      Approved
Owner:       Lead Architect
Approved by: Founder (Shakeel), 2026-07-25 — direct instruction, not
             routed through ChatGPT: *"I want it to be Pass/Save/
             Consider. Pass being red, Save being yellow and Consider
             being green. And no we will stick with swiping actions
             for cleaner UI."*

Decision:
  1. Terminology renamed across all owning and citing documents:
     Decline → **Pass**, Like → **Consider**. Save is unchanged.
     Colours unchanged (🔴 Pass, 🟡 Save, 🟢 Consider) — this is a
     label change onto the existing colour assignment, not a new
     taxonomy.
  2. `APP/Navigation/SEEKER NAVIGATION/Summary.md`'s explicit
     "Browse actions are tap-only — no swipe gestures" rule (written
     with the stated rationale "swiping feels casual and conflicts
     with ZYRA's serious marriage philosophy") is reversed. Swipe
     gestures are adopted as the primary interaction mechanism,
     resolving OA-ZYRA-135:
       Swipe Left  → 🟢 Consider
       Swipe Right → 🔴 Pass
       Swipe Down  → 🟡 Save
     Floating action buttons above the bottom navigation bar are
     removed.
  3. `APP/Matching/PROFILE DECISION SYSTEM/Summary.md` (owns the
     terminology/data-model) updated: Actions section, Philosophy
     section, all cross-references throughout.
  4. `APP/Browse/BROWSE_UX_SPEC_CURRENT_VERSION_V2.md` superseded by
     V3 (archived: BROWSE_UX_SPEC_2026-07-25_V2.md) — User Actions
     and Final UI Decisions tables rewritten for the swipe mechanism
     and new terminology; also resolves OA-ZYRA-137 (Pass is now an
     explicit action, not an implicit "Skip/Scroll past").
  5. OA-ZYRA-135 marked Actioned. OA-ZYRA-137 marked Resolved
     (superseded by this terminology change).

Context:
  OA-ZYRA-135 (the swipe-gesture proposal) was raised earlier the
  same day and NOT filed — it directly contradicted an explicit,
  philosophy-grounded, already-built rule, and was judged to be a
  Founder-level positioning question rather than something to send
  to ChatGPT for reconciliation. The Founder answered directly,
  overriding that prior rule knowingly rather than by oversight, and
  supplied the exact replacement terminology (Pass/Save/Consider)
  and colour mapping in the same instruction.

Alternatives:
  Keep tap-only, reject OA-ZYRA-135 — this was the standing position
    until this decision; superseded by direct Founder instruction.
  Keep Decline/Like terminology, adopt swipe gestures only — not
    what was instructed; the Founder specified new terminology
    alongside the gesture change in the same breath.

Reasoning:
  Founder-level product/brand positioning call, supplied directly
  rather than derived from documentation precedent. `PROFILE
  DECISION SYSTEM/Summary.md` §PHILOSOPHY updated to record the
  reasoning: the underlying philosophy (deliberate, one-decision-at-
  a-time progression toward marriage) is judged unchanged; only the
  "no swipe gestures, ever" implementation rule is reversed.

Impact:
  APP/Navigation/SEEKER NAVIGATION/Summary.md (§BROWSE actions
    section rewritten with reversal note; Connections section list
    labels renamed Declined→Passed, Likes→Considered; Approved
    Rules and Current Status updated with superseded-markers, not
    silently rewritten).
  APP/Matching/PROFILE DECISION SYSTEM/Summary.md (terminology
    renamed throughout — Actions, Philosophy, Timeline Events, etc).
  APP/Browse/BROWSE_UX_SPEC_CURRENT_VERSION_V3.md (new, supersedes
    V2, archived as BROWSE_UX_SPEC_2026-07-25_V2.md).
  Cross-references updated in APP/Profiles/Summary.md, APP/
    Standards/IMAGE_HANDLING_CURRENT_VERSION_V2.md, APP/Journey/
    JOURNEY MANAGEMENT/Summary.md (pointer only — content in those
    documents otherwise unaffected).
  OA-ZYRA-135 → Actioned. OA-ZYRA-137 → Resolved.
  **Built 2026-07-25, same day** (Founder build authorisation given
  later this session): `SOURCE/lib/screens/browse/browse_screen.dart`
  now implements Pass/Save/Consider via swipe gestures, floating
  buttons removed, matching this decision exactly. The gap between
  SEEKER NAVIGATION/Summary.md's 2026-07-19 FLAGGED section and live
  code is closed for the interaction mechanism; that section's
  underlying code/doc terminology note (OA-ZYRA-138, `AppState`'s
  `decline()`/`like()` method names) remains open and unaffected.
  `ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V3.md` Part 2 still uses "Like"
  terminology internally ("Like Rules") — not updated by this
  decision; flagged in PROFILE DECISION SYSTEM/Summary.md as a
  cross-reference note, not resolved here, since the Master Spec is
  a higher-precedence document this filing should not edit
  unilaterally.

Related:
  OA-ZYRA-135, OA-ZYRA-137, DR-ZYRA-095 (Browse Report/Hide/Block,
  unaffected — still functions identically under new terminology).

------------------------------------------------------------

DR-ZYRA-100
Title:       Developer Mode — Test Accounts Formalised, Test
             Sign-Up Added
Date:        2026-07-25
Status:      Approved
Owner:       Lead Architect
Approved by: Founder (Shakeel), 2026-07-25 ("work through, questions
             to ChatGPT otherwise update docs" — no conflict found,
             so filed directly).

Decision:
  1. `APP/Developer Mode/Script/Script_V1.md` (stale — Basic/Pro/
     Premium terminology, no record of the 2026-07-19 live rebuild)
     is not deleted (per the Script versioning convention already
     used in `SEEKER NAVIGATION/Script/`, old versions sit alongside
     new, not archived out) but superseded in practice by
     `Script_V2.md`.
  2. Test Accounts section rewritten to correctly describe what
     already exists in code (`developer_access_screen.dart`, built
     2026-07-19 per direct Founder request): real Supabase-backed
     Seeker presets (Basic/One × male/female) and Wali presets
     (currently one persona, Extended Wali as a mock toggle).
  3. Test Sign-Up (OA-ZYRA-139) added as a new, distinct capability
     — full real onboarding flow, real validation throughout,
     distinct from the existing "Jump to Screen" mock-state flow.
  4. Payment bypass section retained from the source proposal but
     flagged: no real payment integration exists in the codebase
     yet (`upgrade_screen.dart` is entirely mock), so this section
     is forward-looking specification, not something buildable
     today.

Context:
  Checked against `APP/Authentication/`, `APP/Premium/`, and
  `APP/Onboarding/` documentation, and against live code
  (`developer_access_screen.dart`, `upgrade_screen.dart`) per the
  source proposal's own "review existing documentation, do not
  duplicate" instruction. No conflicts found — Test Accounts
  overlaps heavily with already-built code (a documentation gap, not
  a disagreement), and Test Sign-Up is genuinely new. The payment
  caveat was surfaced rather than silently built into the spec as if
  ready to implement.

Alternatives:
  None — no competing approach was found or proposed; this was a
  documentation-catch-up plus one genuinely new addition, not a
  contested design decision.

Reasoning:
  Consistent with this session's checklist discipline (DR-ZYRA-092):
  check existing documentation and live code before treating a
  proposal as new, and be explicit about what's already built versus
  what's actually new versus what's not yet buildable.

Impact:
  APP/Developer Mode/Script/Script_V2.md (new).
  OA-ZYRA-139 marked Actioned.
  Not yet built: Test Sign-Up itself, the completed Wali-side Test
  Accounts matrix, and (necessarily) the real payment integration
  the Payment section depends on.

Related:
  OA-ZYRA-139, OA-ZYRA-128 (unresolved Test Account theme bug,
  cross-referenced not resolved).

------------------------------------------------------------

DR-ZYRA-101
Title:       Implementation Review — Mandatory Pre-Code Repository
             Sweep
Date:        2026-07-25
Status:      Approved
Owner:       Lead Architect
Approved by: Founder (Shakeel), 2026-07-25, ratifying a joint
             Claude/ChatGPT process-alignment exchange triggered by
             a real implementation gap the Founder caught the same
             day (see Context).

Decision:
  A mandatory "Implementation Review" step is established, distinct
  from and additional to the existing Repository Review used before
  filing documentation (DR-ZYRA-092). Before writing any code for a
  feature, identify and review:
  1. The owning Summary.md.
  2. Every DR/OA that affects the feature.
  3. Every document referenced by the owning Summary.
  4. Every document that references the owning Summary.
  5. Any shared UI, design, navigation, or behavioural
     specifications that may influence the implementation.
  Then explicitly answer: which screens, account types, roles,
  themes/colours, and shared components are affected, and which
  existing files require updating. A feature is not "done" because
  its primary file was updated — completeness across the identified
  scope must be a deliberate, stated judgment, not an assumption.
  If full scope confidence isn't reached, say so explicitly, in the
  form: "Repository reviewed. Primary implementation complete.
  Potentially affected areas identified: [...]. Please confirm scope
  before I continue." — rather than presenting partial coverage as
  finished.

Context:
  Triggered directly by a real gap earlier this same session:
  DR-ZYRA-094 ratified gender-based Blue/Pink/Purple gradients, and
  `zyra_colors.dart` was updated with the correct hex constants —
  but they were not correctly wired into most of the screens that
  same ratified document said they should govern. Wali screens had
  Male hardcoded regardless of the signed-in Wali's actual gender,
  the Female gradient was defined but referenced nowhere in the
  app, and the Seeker's own Profile screen stayed on the neutral
  gradient. The primary document (`BUSINESS/COLOUR THEME/
  Summary.md`) was read and correctly implemented for its literal
  content (hex values, fade direction); the implication sweep across
  the rest of the codebase — which screens the ratified rule was
  meant to reach — was not completed before the work was considered
  done. Founder raised this directly ("I DONT UNDERSTAND WHEN
  BUILDING THE APP DONT YOU LOOK AT THE FILES?"), then relayed two
  ChatGPT process-review messages proposing this Implementation
  Review step; ratified as a permanent expectation for the build
  stage.

Alternatives:
  Rely on judgement/memory alone to decide implementation scope each
    time — rejected: this is exactly the failure mode that produced
    the gender-colour gap.
  Treat the existing Repository Review (used before filing
    documentation, DR-ZYRA-092) as sufficient for code too —
    rejected: that discipline was consistently applied to
    documentation filing this session, but did not automatically
    carry through to the later, separate code-writing step. The two
    need to be explicit and separate, run at different points in the
    workflow.

Reasoning:
  A direct extension of DR-ZYRA-092's existing checklist discipline
  (check documentation before treating a proposal as settled) — but
  DR-092 governed documentation filing. This decision closes the gap
  by requiring the identical discipline to be re-applied, explicitly,
  at the point code is actually written, rather than assumed to
  already be covered by an earlier documentation pass.

Impact:
  Governs all future ZYRA implementation work in this repository —
  process-only, no code changed by this decision itself.
  Applied retroactively the same session as a worked example: the
  gender-gradient gap that prompted this decision was itself found
  and fixed by running exactly this sweep — `ZyraColors.
  genderGradient()` added, and wired into Profile, Matches, Match
  Notification, Journey Timeline, Chat, Upgrade/Subscription, and
  both Wali link screens (previously hardcoded Male or left
  neutral). Welcome, Role Selection, Developer Access, and the
  Profile Ready onboarding screen were deliberately left neutral,
  with reasons stated at the time, rather than swept in by default.

Related:
  DR-ZYRA-092 (Repository Review / checklist discipline this
  decision extends), DR-ZYRA-094 (the ratified decision whose
  incomplete implementation prompted this).

Clarification (2026-07-25, same day, Founder + ChatGPT follow-up —
not a new decision, refines DR-ZYRA-101 above):
  Reframes the governing question from "which files do I need to
  change?" to "what is the full impact of this change across the
  application?" — screens, shared widgets, themes/colours,
  navigation, permissions, user roles, account types, animations,
  validation, existing user journeys, documentation, Developer Mode,
  and future maintainability are all explicitly in scope for that
  question, not just the file the request literally names.
  Adds a "raise scope, don't assume it" requirement: where the
  Implementation Review surfaces areas plausibly affected but not
  named in the Founder's request, state them and ask before
  building, in this form: "Implementing X will also affect Y and Z.
  Shall I update all affected areas as part of this implementation?"
  — rather than silently deciding to include or exclude them.
  Six-point summary of the resulting process, restated here for
  quick reference: repository-first; documentation before
  implementation; mandatory Implementation Review before coding;
  full impact assessment, not just file selection; raise uncertainty
  rather than assume; treat every implementation as part of the
  wider application, not an isolated task.

------------------------------------------------------------

DR-ZYRA-102
Title:       Authentication scope pivot — Google + Apple sign-in
             only, email/password reduced to Developer Mode backdoor
Date:        2026-07-25
Status:      RATIFIED — Founder decision, OA-ZYRA-140 item 13:
             "Google/Apple-only is correct."
Superseded By: None
Category:    Product / Authentication
Owner:       Founder (Shakeel)
Approved by: Founder (Shakeel), 2026-07-25

Decision:
  User-facing authentication is Google sign-in and Apple sign-in
  only. Email + password exists solely as a hidden Developer Mode
  test-account path (`developer_access_screen.dart`) — never a
  user-facing option on the Welcome screen or anywhere else.

Context:
  OA-102 (Supabase authentication setup) originally scoped the
  reverse: email+password in-scope, Google/Apple explicitly named
  "out of scope... V2 features." Live code
  (`zyra_auth.dart`/`welcome_screen.dart`) has always implemented
  Google+Apple-only, and DR-ZYRA-088 (sign-in button
  ordering/sizing) assumed this without a Decision Record
  actually ratifying the underlying pivot. Surfaced under
  DR-ZYRA-101's repository audit as OA-ZYRA-140 item 13, rather
  than left as an undocumented divergence between spec and code.

Alternatives considered:
  Add a real, user-facing email+password flow alongside
  Google/Apple, matching OA-102's original scope — rejected by
  the Founder in favour of ratifying the existing, working
  Google+Apple-only direction.

Reasoning:
  The pivot was already built, working, and presumably deliberate
  — this closes the gap between ratified documentation and actual
  shipped behaviour without changing anything a user experiences.

Impact:
  OA-102 rewritten to match (see Outstanding Actions Register).
  No code changes — this ratifies existing, already-live
  behaviour.

Related:
  OA-ZYRA-140 (item 13), OA-102, DR-ZYRA-088,
  SOURCE/lib/services/zyra_auth.dart,
  SOURCE/lib/screens/auth/welcome_screen.dart,
  SOURCE/lib/screens/dev/developer_access_screen.dart

------------------------------------------------------------

DR-ZYRA-103
Title:       Repository navigation standards — TREEVIEW.md,
             Documentation Index schema extension, monthly Changelog
Date:        2026-07-25
Status:      RATIFIED — Founder decision
Superseded By: None
Category:    Repository
Owner:       Founder (Shakeel)
Approved by: Founder (Shakeel), 2026-07-25

Decision:
  Three repository navigation improvements are adopted:
  (1) TREEVIEW.md — a literal, regenerated-not-hand-typed structural
  folder listing at SYSTEM/DOCUMENTS/TREEVIEW.md.
  (2) ZYRA_DOCUMENTATION_INDEX extended, not replaced — its schema
  gains Purpose/Owner/Source of Truth/Dependencies/Related fields
  per document, moved to the CURRENT_VERSION naming convention
  (V1 archived, V2 is current), and given a full content refresh.
  (3) SYSTEM/LOGS/CHANGELOG_2026-07.md — a monthly, human-readable
  Added/Changed/Fixed/Removed changelog, separate from the
  dormant audit-style OPERATIONAL_LOG.

Context:
  ChatGPT (Research Agent) proposed a TREEVIEW.md, a new INDEX.md,
  and a Change Log in the Black Umbrella/AIOS chat. Architecture
  Agent (Claude) reviewed against the Architectural Extension
  Principle before agreeing to build anything new — see
  SYSTEM/RESOURCES/TEMPORARY/CHATGPT_REPLY_REPO_NAVIGATION_2026-07-25.md
  for the full review. Two of the three proposals landed differently
  than originally pitched once checked against what already existed:
  a second INDEX.md would have duplicated ZYRA_DOCUMENTATION_INDEX
  (already doing the same job, just thinner); the Change Log
  proposal was strengthened by concrete evidence that the existing
  OPERATIONAL_LOG had gone dark exactly when the most development
  activity happened (zero entries since 2026-06-26 despite the
  entire Journey/Ritual/Suspension build and the OA-ZYRA-140 audit).
  ChatGPT confirmed all three recommendations; Founder ratified.

Alternatives considered:
  Ship a second INDEX.md alongside the existing Documentation Index
  (ChatGPT's original proposal) — rejected: creates the exact
  two-sources-of-truth problem OA-ZYRA-140 spent significant effort
  resolving elsewhere. Merge the new Changelog into OPERATIONAL_LOG's
  run-entry format — rejected: genuinely different audiences and
  structures (audit trail vs. human-readable feature log).

Reasoning:
  Extending an existing artefact that already does 80% of the job
  is lower-risk and higher-clarity than introducing a competing one,
  per the Architectural Extension Principle (CHAT_ARCHITECTURE_
  CURRENT_VERSION_V1.md, Black Umbrella). TREEVIEW.md and the
  Changelog are genuinely new needs with no existing equivalent, so
  adopted as proposed.

Impact:
  SYSTEM/DOCUMENTS/TREEVIEW.md created.
  ZYRA_DOCUMENTATION_INDEX_V1.md archived to
  SYSTEM/DOCUMENTS/ARCHIVE/ZYRA_DOCUMENTATION_INDEX_2026-07-25_V1.md;
  ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V2.md is now current.
  SYSTEM/LOGS/CHANGELOG_2026-07.md created, backfilled for July.
  SYSTEM/SESSION_HANDOVER (relocated to SYSTEM/RESOURCES/TEMPORARY/
  SESSION_HANDOVER_2026-07-25.md during this pass — a pre-existing
  naming/placement defect against STANDARDS_LIBRARY §2.5/§3.7,
  fixed while in this area, not part of the ratified proposals
  themselves).

Related:
  SYSTEM/RESOURCES/TEMPORARY/CHATGPT_REPLY_REPO_NAVIGATION_2026-07-25.md,
  CHAT_ARCHITECTURE_CURRENT_VERSION_V1.md (Black Umbrella),
  STANDARDS_LIBRARY_CURRENT_VERSION_V1.md (Black Umbrella)

------------------------------------------------------------

# Register Metadata (added 2026-07-12)

TOTAL REGISTERED (this file): DR-001 through DR-ZYRA-103,
  Historical Identifiers, permanent
NEXT IDENTIFIER: DR-ZYRA-104 (Enterprise format, active
  2026-07-12 — continues this sequence, does not reset;
  sequential identifiers are global and never reset per AIOS
  Package Specification Standard Part 5. See BLACK UMBRELLA
  GROUP/SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V1.md,
  OA-127.)
GOVERNING STANDARD: ENTERPRISE_OBJECT_IDENTITY_STANDARD_
  CURRENT_VERSION_V1.md (BLACK UMBRELLA GROUP/SYSTEM/
  ARCHITECTURE/), active 2026-07-12

