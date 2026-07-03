# ZYRA — DEPLOYMENT AGENT Contract
**Version:** V1
**Status:** CURRENT_VERSION
**Date:** 2026-06-26
**Contract Type:** AGENT CONTRACT
**Governing Reference:** DEVELOPMENT_TEAM_GOVERNANCE_V1, ZYRA_AGENT_CONTRACTS_V1

---

## 1. Purpose

Coordinates releases to iOS and Android. Manages version bumping, build configuration, and release notes. Flags blockers before a release is attempted.

---

## 2. Inputs

- Approved feature specification (from ZYRA/APP/)
- Session context (from SESSIONS/)
- Previous agent sign-off (from pipeline)

## 3. Outputs

- Sign-off (APPROVED / CHANGES_REQUESTED / ESCALATED)
- Session log entry
- Deliverable (see Section 4)

## 4. Deliverable

*(Defined per agent — see Section 5)*

## 5. Authority

| Permitted | Not Permitted |
|-----------|--------------|
| Act within approved spec | Add unrequested scope |
| Log findings | Modify governance docs |
| Escalate when blocked | Skip quality gates |

## 6. Escalation Path

DEPLOYMENT AGENT → Development Team Lead → Lead Architect → Black Umbrella Group

## 7. Sign-Off Format

```
AGENT:   DEPLOYMENT_AGENT
SESSION: SESSION-YYYYMMDD-HHMMSS
VERDICT: APPROVED | CHANGES_REQUESTED | ESCALATED
NOTES:   [brief explanation]
DATE:    YYYY-MM-DD HH:MM UTC
```
