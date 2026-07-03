# ZYRA Development Team — Index
**Version:** V1
**Status:** CURRENT_VERSION
**Date:** 2026-06-26
**Governing Reference:** ZYRA_GOVERNANCE_V1, ZYRA_EXECUTION_V1

---

## Purpose

The ZYRA Development Team is an 8-agent AI team that executes
approved feature specifications into working Flutter code.
It operates within the bounds set by the Lead Architect and
reports progress through the ZYRA Project System.

---

## Team Structure

```
DEVELOPMENT_TEAM/
├── AGENTS/
│   ├── PRODUCT_MANAGER_AGENT/   ← Validates specs before build
│   ├── ARCHITECT_AGENT/         ← Reviews architecture decisions
│   ├── CODE_AGENT/              ← Writes Flutter/Dart code
│   ├── REVIEW_AGENT/            ← Reviews code quality
│   ├── QA_AGENT/                ← Writes and runs tests
│   ├── DOCUMENTATION_AGENT/     ← Keeps docs in sync with code
│   ├── IMPACT_ANALYSIS_AGENT/   ← Assesses change impact
│   └── DEPLOYMENT_AGENT/        ← Coordinates releases
├── SESSIONS/                    ← Per-session work logs
├── LOGS/                        ← Operational logs
└── RESOURCES/
    ├── REPORTS/                 ← Run reports
    └── MEMORY/                  ← Cross-session memory
```

---

## Agent Pipeline (standard feature build)

```
Spec Approved
     ↓
Product Manager Agent — validates spec is complete
     ↓
Architect Agent — reviews architecture fit
     ↓
Impact Analysis Agent — assesses what changes
     ↓
Code Agent — writes the code
     ↓
Review Agent — reviews code quality
     ↓
QA Agent — writes tests, verifies coverage
     ↓
Documentation Agent — updates docs
     ↓
Deployment Agent — coordinates release
     ↓
Feature DONE
```

---

## Maturity Level

| Layer | Current Level |
|-------|--------------|
| Development Team | Level 1 — Structure |

---

## Governing References

- ZYRA_GOVERNANCE_V1
- ZYRA_EXECUTION_V1
- ZYRA_AGENT_CONTRACTS_V1
- DEVELOPMENT_TEAM_GOVERNANCE_V1 (Level 2)
