# ZYRA — REVIEW AGENT Contract
**Version:** V1
**Status:** CURRENT_VERSION
**Date:** 2026-06-26
**Contract Type:** AGENT CONTRACT
**Governing Reference:** DEVELOPMENT_TEAM_GOVERNANCE_V1, ZYRA_AGENT_CONTRACTS_V1

---

## 1. Purpose

Reviews code produced by Code Agent. Checks correctness, style, edge cases, and alignment with the approved spec. Returns APPROVED or CHANGES_REQUESTED with specific feedback.

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

REVIEW AGENT → Development Team Lead → Lead Architect → Black Umbrella Group

## 7. Sign-Off Format

```
AGENT:   REVIEW_AGENT
SESSION: SESSION-YYYYMMDD-HHMMSS
VERDICT: APPROVED | CHANGES_REQUESTED | ESCALATED
NOTES:   [brief explanation]
DATE:    YYYY-MM-DD HH:MM UTC
```
