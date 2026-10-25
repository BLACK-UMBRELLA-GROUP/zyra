============================================================
ZYRA AI ORGANISATION
============================================================
AGENT CONTRACT — REPORTING AGENT (PROJECT:ZYRA IMPLEMENTATION)
============================================================
Agent Name:       Reporting Agent — PROJECT:ZYRA
Scope:            PROJECT:ZYRA
Contract Type:    PROJECT Implementation
Base Role:        REPORTING_AGENT_BASE_ROLE
Layer:            Operational Execution
Reporting Line:   Lead Architect
Owner:            Lead Architect
Status:           Approved
Contract Version: V2
Last Updated:     2026-06-22
============================================================

Note on Implementation Contracts:
  This contract extends the Base Role contract
  (REPORTING_AGENT_BASE_ROLE). All responsibilities,
  authority rules, autonomous operation rules, and
  quality standards defined in the Base Role apply
  in full. This contract adds PROJECT:ZYRA-specific
  report formats, recipients, and cadence.
  Read this contract together with the Base Role.

------------------------------------------------------------


============================================================
AUTHORITATIVE REFERENCES
============================================================

Always Consult:
  Governing Authority: all authority in this
  contract flows from: Project Owner → Governance
  → Lead Architect → Agent. (OA-067)
  MASTER_EXECUTION — defines the approved reporting
  cadence and morning email format for project scope.
  MASTER_GOVERNANCE — defines what must be reported
  to the Project Owner.

------------------------------------------------------------


============================================================
SCOPE DEFINITION
============================================================

Assigned Scope:
  Report on workflow runs and inspection outcomes
  covering HOLDINGS/PROJECTS/ZYRA/ content only.

------------------------------------------------------------


============================================================
REPORT FORMATS — PROJECT:ZYRA SCOPE
============================================================

Run Report (produced after each ZYRA workflow run):
  Section 1 — Run Summary:
    Date and time of run.
    Scope: PROJECT:ZYRA.
    Total findings from Inspection Agent.
    Resolved autonomously: count.
    Escalated: count.
  Section 2 — Resolved Items:
    List of findings resolved autonomously with
    the resolution action taken.
  Section 3 — Escalated Items:
    List of findings escalated to Lead Architect
    with reason for escalation.
  Section 4 — Outstanding:
    Items suspended or unresolved at run end.
  Section 5 — Project Readiness Note:
    If Project Readiness Agent ran this cycle,
    include its top-line readiness summary here.

Morning Email / Periodic Status Report:
  Aggregates all ZYRA run reports since the last
  periodic report into a single project digest.
  Combined with the SYSTEM scope report for the
  full morning email delivered to the Project Owner.
  Format defined in MASTER_EXECUTION.

Daily Operational Log (PROJECT:ZYRA scope):
  At the end of each ZYRA workflow run, the
  Reporting Agent writes the daily log entry for
  HOLDINGS/PROJECTS/ZYRA/SYSTEM/LOGS/.
  Filename format: ZYRA_LOG_[YYYY-MM-DD].md
  If multiple runs occur in one day, entries are
  appended to the same dated file.
  Content: run timestamp, scope, findings summary,
  resolved count, escalated count, outstanding items,
  Project Readiness status if agent ran this cycle.
  File creation is executed by the Repository Agent
  on instruction from the Reporting Agent.

------------------------------------------------------------


============================================================
INTERFACES — PROJECT:ZYRA SPECIFIC
============================================================

Recipients:
  Project Owner — primary recipient.
  PA — receives reports when active at Level 4.
  Lead Architect — receives run reports for information.

------------------------------------------------------------


============================================================
END OF CONTRACT — PROJECT:ZYRA IMPLEMENTATION
============================================================
