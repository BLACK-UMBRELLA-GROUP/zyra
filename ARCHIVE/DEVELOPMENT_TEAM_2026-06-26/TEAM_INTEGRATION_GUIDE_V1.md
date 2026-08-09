# ZYRA Development Team — Integration Guide
**Version:** V1
**Status:** CURRENT_VERSION
**Date:** 2026-06-26
**Governing Reference:** DEVELOPMENT_TEAM_GOVERNANCE_V1, ZYRA_EXECUTION_V1

---

## 1. How the Development Team fits into ZYRA

```
Black Umbrella Group (Level 5)
         ↕  inspects nightly
ZYRA Project System (Level 5)
         ↕  governs
ZYRA Development Team (Level 5)
         ↕  builds
ZYRA SOURCE/ (Flutter codebase)
```

---

## 2. Inputs the Development Team consumes

| Input | Source | Where |
|-------|--------|-------|
| Approved feature specs | Lead Architect | ZYRA/APP/[FEATURE]/Summary.md |
| Architecture decisions | Architect Agent | ZYRA/SYSTEM/DECISIONS_REGISTER/ |
| Standards | Black Umbrella Group + ZYRA | SYSTEM/DOCUMENTS/MASTER_STANDARDS/ |
| Outstanding Actions | Lead Architect | SYSTEM/OUTSTANDING_ACTIONS/ |

---

## 3. Outputs the Development Team produces

| Output | Destination |
|--------|-------------|
| Flutter code | ZYRA/SOURCE/lib/ |
| Tests | ZYRA/SOURCE/test/ |
| Updated feature docs | ZYRA/APP/[FEATURE]/ |
| Session logs | DEVELOPMENT_TEAM/LOGS/ |
| Run reports | DEVELOPMENT_TEAM/RESOURCES/REPORTS/ |
| Session memory | DEVELOPMENT_TEAM/RESOURCES/MEMORY/ |

---

## 4. How Black Umbrella Group inspects the Development Team

The Black Umbrella Group Level 4 pipeline inspects:
- ZYRA/SYSTEM/ — project governance
- ZYRA/DEVELOPMENT_TEAM/ — team governance and logs

The project_runner.py handles this automatically nightly.

---

## 5. How to connect Claude Code to the Development Team

When working in Claude Code on a ZYRA feature:

1. Reference the approved spec: `ZYRA/APP/[FEATURE]/Summary.md`
2. Reference the architecture: `ZYRA/SYSTEM/DOCUMENTS/ZYRA_ARCHITECTURE_V1.md`
3. Reference the playbook: `ZYRA/DEVELOPMENT_TEAM/TEAM_PLAYBOOK_V1.md`
4. Log the session: `ZYRA/DEVELOPMENT_TEAM/SESSIONS/`

The dev_team_runner.py automates this entire flow.
