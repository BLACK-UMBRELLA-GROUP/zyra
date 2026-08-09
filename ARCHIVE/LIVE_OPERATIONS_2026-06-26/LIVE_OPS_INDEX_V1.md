# ZYRA Live Operations — Index
**Version:** V1
**Status:** CURRENT_VERSION
**Date:** 2026-06-26
**Governing Reference:** ZYRA_GOVERNANCE_V1

---

## Purpose

Governs the operational health of the ZYRA app once deployed.
Monitors availability, detects incidents, manages releases,
and reports health up to the ZYRA Project System and Black Umbrella Group.

---

## Structure

```
LIVE_OPERATIONS/
├── MONITORING/
│   └── CHECKS/          ← Health check definitions
├── INCIDENTS/
│   ├── OPEN/            ← Active incidents
│   ├── CLOSED/          ← Resolved incidents
│   └── POSTMORTEMS/     ← Post-incident reviews
├── RELEASES/            ← Release records
├── RUNBOOKS/            ← Incident response playbooks
├── LOGS/                ← Operational logs
└── RESOURCES/
    ├── REPORTS/         ← Health check reports
    └── MEMORY/          ← Cross-run memory
```

---

## Health Checks (Level 4)

| Check | What it monitors | Frequency |
|-------|-----------------|-----------|
| BUILD_HEALTH | Flutter build status | Per run |
| DOCS_HEALTH | Documentation coverage | Per run |
| TEST_HEALTH | Test file existence | Per run |
| RELEASE_HEALTH | Release readiness | Per run |
| INCIDENT_HEALTH | Open incident count | Per run |

---

## Maturity Level

| Layer | Current Level |
|-------|--------------|
| Live Operations | Level 1 — Structure |

---

## Governing References

- ZYRA_GOVERNANCE_V1
- LIVE_OPS_GOVERNANCE_V1 (Level 2)
- LIVE_OPS_RUNBOOK_V1 (Level 3)
