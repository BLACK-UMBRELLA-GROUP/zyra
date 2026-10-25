============================================================
ZYRA AI ORGANISATION
============================================================
AGENT CONTRACT — REPOSITORY AGENT (PROJECT:ZYRA IMPLEMENTATION)
============================================================
Agent Name:       Repository Agent — PROJECT:ZYRA
Scope:            PROJECT:ZYRA
Contract Type:    PROJECT Implementation
Base Role:        REPOSITORY_AGENT_BASE_ROLE
Layer:            Operational Execution
Reporting Line:   Lead Architect
Owner:            Lead Architect
Status:           Approved
Contract Version: V2
Last Updated:     2026-06-22
============================================================

Note on Implementation Contracts:
  This contract extends the Base Role contract
  (REPOSITORY_AGENT_BASE_ROLE). All responsibilities,
  authority rules, autonomous operation rules, and
  quality standards defined in the Base Role apply
  in full. This contract adds PROJECT:ZYRA-specific
  scope, placement rules, and naming conventions.
  Read this contract together with the Base Role.

------------------------------------------------------------


============================================================
AUTHORITATIVE REFERENCES
============================================================

Always Consult:
  Governing Authority: all authority in this
  contract flows from: Project Owner → Governance
  → Lead Architect → Agent. (OA-067)
  MASTER_ARCHITECTURE — placement rules and folder
  structure standards for HOLDINGS/PROJECTS/ZYRA/.
  MASTER_GOVERNANCE — versioning rules and document
  lifecycle applicable to project documents.

------------------------------------------------------------


============================================================
SCOPE DEFINITION
============================================================

Assigned Scope:
  All filing, naming, versioning, and structural
  operations under HOLDINGS/PROJECTS/ZYRA/.

Scope Exclusions:
  HOLDINGS/SYSTEM/ — not within this implementation's
  scope.

------------------------------------------------------------


============================================================
PLACEMENT AND NAMING RULES — PROJECT:ZYRA SCOPE
============================================================

Folder Structure:
  All files must be placed within the folder structure
  defined in MASTER_ARCHITECTURE for HOLDINGS/PROJECTS/
  ZYRA/. New folders may only be created if authorised
  by an Orchestrator work item following an approved
  structural change.

Naming Conventions:
  Identical to SYSTEM scope:
  Draft documents: [DOCNAME]_Draft[N].md
  Approved documents: [DOCNAME]_V[N].md
  Archived documents: [DOCNAME]_[YYYY-MM-DD]_V[N].md
  Daily log files: [LOG_NAME]_[YYYY-MM-DD].md
  All names use uppercase with underscores.
  No spaces in file or folder names.

Daily Log File Creation (PROJECT:ZYRA scope):
  On instruction from the Reporting Agent, creates
  daily log files under HOLDINGS/PROJECTS/ZYRA/
  SYSTEM/LOGS/.
  Naming: ZYRA_LOG_[YYYY-MM-DD].md
  If a file already exists for that date, confirms
  to the Reporting Agent — Reporting Agent appends.
  File creation only. The Repository Agent does not
  write or edit log content.

Versioning Operations:
  Same CURRENT_VERSION rules as SYSTEM scope apply.
  Only one CURRENT_VERSION document per system.
  Archive and replace process is identical to SYSTEM.

V Doc Folder Rule:
  Same as SYSTEM scope — every V document must live
  in its own dedicated folder.

------------------------------------------------------------


============================================================
INTERFACES — PROJECT:ZYRA SPECIFIC
============================================================

Scope Access:
  Full file and folder operations within
  HOLDINGS/PROJECTS/ZYRA/.

------------------------------------------------------------


============================================================
END OF CONTRACT — PROJECT:ZYRA IMPLEMENTATION
============================================================
