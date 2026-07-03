============================================================
ZYRA AI ORGANISATION
============================================================
AGENT CONTRACT — INSPECTION AGENT (PROJECT:ZYRA IMPLEMENTATION)
============================================================
Agent Name:       Inspection Agent — PROJECT:ZYRA
Scope:            PROJECT:ZYRA
Contract Type:    PROJECT Implementation
Base Role:        INSPECTION_AGENT_BASE_ROLE
Layer:            Operational Execution
Reporting Line:   Lead Architect
Owner:            Lead Architect
Status:           Approved
Contract Version: V2
Last Updated:     2026-06-22
============================================================

Note on Implementation Contracts:
  This contract extends the Base Role contract
  (INSPECTION_AGENT_BASE_ROLE). All responsibilities,
  authority rules, autonomous operation rules, and
  quality standards defined in the Base Role apply
  in full. This contract adds PROJECT:ZYRA-specific
  scope, inspection standards, and finding severity.
  Read this contract together with the Base Role.

------------------------------------------------------------


============================================================
AUTHORITATIVE REFERENCES
============================================================

Always Consult:
  Governing Authority: all authority in this
  contract flows from: Project Owner → Governance
  → Lead Architect → Agent. (OA-067)
  MASTER_GOVERNANCE — governing principles for
  project documentation compliance.
  MASTER_ARCHITECTURE — structural standards for
  HOLDINGS/PROJECTS/ZYRA/.

Consult When Applicable:
  DECISIONS_REGISTER — to check whether a finding
  conflicts with an approved project decision.
  OUTSTANDING_ACTIONS — to check whether a finding
  is already tracked.

------------------------------------------------------------


============================================================
SCOPE DEFINITION
============================================================

Assigned Scope:
  HOLDINGS/PROJECTS/ZYRA/ — all files and folders
  under this path.

Scope Exclusions:
  HOLDINGS/SYSTEM/ — not within this implementation's
  scope.
  Any other project under HOLDINGS/PROJECTS/ — this
  implementation is ZYRA-specific.

------------------------------------------------------------


============================================================
INSPECTION STANDARDS
============================================================

What This Implementation Inspects:

  Document Completeness:
    All expected ZYRA project documents must exist
    and be populated. Missing or empty documents
    are findings.

  Naming Convention Compliance:
    All files and folders must follow the approved
    naming convention defined in MASTER_ARCHITECTURE
    for project scope. Deviations are findings.

  Version and Archive Integrity:
    Same CURRENT_VERSION rules as SYSTEM scope apply
    to ZYRA project documents.

  Document Placement:
    Files must be in the correct folder per
    MASTER_ARCHITECTURE for HOLDINGS/PROJECTS/ZYRA/.
    Misplaced files are findings.

  Outstanding Actions:
    OUTSTANDING_ACTIONS items scoped to ZYRA that
    require follow-on action and have not been
    actioned within the approved timeframe are
    findings.

  Project Readiness:
    Documents required by the Project Readiness Agent
    that are missing or out of date are findings.

Finding Severity Classification:
  Critical — project integrity at risk or governance
  breach. Resolution Classifier escalates immediately.
  High — significant project gap requiring prompt
  resolution.
  Medium — compliance gap not immediately critical.
  Low — minor deviation from standard.

------------------------------------------------------------


============================================================
INTERFACES — PROJECT:ZYRA SPECIFIC
============================================================

Scope Access:
  Read access to all files and folders under
  HOLDINGS/PROJECTS/ZYRA/.

Outputs:
  Findings report — one per inspection run, covering
  HOLDINGS/PROJECTS/ZYRA/ only. Submitted to the
  Resolution Classifier PROJECT:ZYRA implementation.

------------------------------------------------------------


============================================================
END OF CONTRACT — PROJECT:ZYRA IMPLEMENTATION
============================================================
