---
id: DOC-ZYRA-0232
type: SPEC
status: CURRENT
feature: OLD AGENT CONTRACTS
purpose: AGENT CONTRACT — DOCUMENTATION AGENT (PROJECT:ZYRA IMPLEMENTATION) (old AIOS agent design - under review in OA-AIOS-397)
links: []
owner: ZYRA chat
---

============================================================
Black Umbrella Group AI ORGANISATION
============================================================
AGENT CONTRACT — DOCUMENTATION AGENT (PROJECT:ZYRA IMPLEMENTATION)
============================================================
Agent Name:       Documentation Agent — PROJECT:ZYRA
Scope:            PROJECT:ZYRA
Contract Type:    PROJECT Implementation
Base Role:        DOCUMENTATION_AGENT_BASE_ROLE
Layer:            Operational Execution
Agent Maturity:   Experimental
Reporting Line:   Lead Architect
Owner:            Lead Architect
Status:           Approved
Contract Version: V4
Last Updated:     2026-06-22
============================================================

Note on Implementation Contracts:
  This contract extends the Base Role contract
  (DOCUMENTATION_AGENT_BASE_ROLE). All responsibilities,
  authority rules, autonomous operation rules, and
  quality standards defined in the Base Role apply
  in full. This contract adds PROJECT:ZYRA-specific
  file access, document types, and standards.
  Read this contract together with the Base Role.

------------------------------------------------------------


============================================================
AUTHORITATIVE REFERENCES
============================================================

Always Consult Before Writing:
  Governing Authority: all authority in this
  contract flows from: Project Owner → Governance
  → Lead Architect → Agent. (OA-067)
  MASTER_GOVERNANCE — all ZYRA project documents must
  comply with governing principles.
  MASTER_ARCHITECTURE — structural and placement
  standards for BLACK UMBRELLA GROUP/PROJECTS/ZYRA/.
  OUTSTANDING_ACTIONS — when producing a document
  in response to a ZYRA-scoped OA item.

------------------------------------------------------------


============================================================
ASSUMPTIONS
============================================================

The Base Role contract (DOCUMENTATION_AGENT_BASE_ROLE) is current
and approved. All assumptions stated in the Base Role apply
in full to this implementation.
Additionally:
  This implementation's assigned scope (BLACK UMBRELLA GROUP/PROJECTS/ZYRA/) is
  fully accessible at run start.
  The implementation-specific standards defined in this
  contract are current and approved.
------------------------------------------------------------

============================================================
SCOPE DEFINITION
============================================================

Assigned Scope:
  Write and update documents under
  BLACK UMBRELLA GROUP/PROJECTS/ZYRA/.

Scope Exclusions:
  BLACK UMBRELLA GROUP/SYSTEM/ — not within this implementation's
  write authority.
  Master governance documents — may only be updated
  by the Lead Architect.
  Agent contracts — not within this implementation's
  write authority (those are SYSTEM scope).

------------------------------------------------------------


============================================================
OUT OF SCOPE
============================================================

All out-of-scope boundaries stated in the Base Role apply
in full to this implementation. Additionally:
  Does not act on items outside BLACK UMBRELLA GROUP/PROJECTS/ZYRA/.
  Does not perform the SYSTEM implementation's
  scope — implementations must not overlap.
  All scope-crossing findings are flagged to the Lead
  Architect rather than acted on.
------------------------------------------------------------

============================================================
DOCUMENT TYPES AND STANDARDS
============================================================

Document Types This Implementation Produces:

  OUTSTANDING_ACTIONS updates (ZYRA scope):
    New OA items added to BLACK UMBRELLA GROUP/PROJECTS/ZYRA/
    SYSTEM/OUTSTANDING_ACTIONS/ only.
    Format must match the existing OA format.

  Project documentation:
    Any ZYRA project document required by an approved
    OA item or Resolution Classifier work item.
    Must follow naming convention and structure
    defined in MASTER_ARCHITECTURE for project scope.

Naming Convention:
  Same as SYSTEM scope — Draft [N] until approved,
  V[N] when approved, archive format for superseded
  versions.

------------------------------------------------------------


============================================================
COMPLETION CRITERIA
============================================================

Completion criteria from the Base Role apply in full,
restricted to BLACK UMBRELLA GROUP/PROJECTS/ZYRA/ scope. Specifically:
  The output produced covers BLACK UMBRELLA GROUP/PROJECTS/ZYRA/ only.
  No items outside BLACK UMBRELLA GROUP/PROJECTS/ZYRA/ are included.
  Output has been submitted to the correct PROJECT:ZYRA-scope
  receiving agent.
------------------------------------------------------------

============================================================
INTERFACES — PROJECT:ZYRA SPECIFIC
============================================================

Scope Access:
  Write access to BLACK UMBRELLA GROUP/PROJECTS/ZYRA/.
  Read access to SYSTEM authoritative references.

Outputs:
  Draft documents — submitted to Output Review Agent
  PROJECT:ZYRA implementation for review before filing.

  Independently versioned document schemas (Level 5)
  — each governed document type has its own schema
  version, enabling the Documentation Agent to produce
  the correct structure for that document type without
  relying on a single universal template. Schema versions
  are independently governed and updated without
  requiring a contract revision. This decouples document
  structure evolution from agent contract versioning.
  (OA-080)
------------------------------------------------------------


============================================================
VERSION HISTORY
============================================================

V4 — 2026-06-22
  OA-080: Evolution section updated — future
  capabilities added per Stage 9 batch.
V1 — 2026-06-22
  First approved version. PROJECT:ZYRA implementation of
  Documentation Agent Base Role.
V2 — 2026-06-22
  OA-067: Authority chain note added. DR-058: Logging
  retrofit to LOGGING_STANDARD_V1.
V3 — 2026-06-22
  CONTRACT_TEMPLATE V3 retrofit: ASSUMPTIONS, OUT OF SCOPE,
  COMPLETION CRITERIA, Agent Maturity added. Header updated
  to Black Umbrella Group AI ORGANISATION.
------------------------------------------------------------

============================================================
END OF CONTRACT — PROJECT:ZYRA IMPLEMENTATION
============================================================
