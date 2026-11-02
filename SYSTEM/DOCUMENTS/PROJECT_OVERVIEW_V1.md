---
id: DOC-ZYRA-0248
type: SPEC
status: CURRENT
feature: PRODUCT
purpose: ZYRA — Project Overview
links: []
owner: ZYRA chat
---

# ZYRA — Project Overview
**Version:** V1
**Status:** CURRENT_VERSION
**Date:** 2026-06-26
**Owner:** Black Umbrella Group

---

## 1. What is ZYRA?

ZYRA is a Flutter-based matrimonial mobile application for a faith community. It connects
Seekers from the community with compatible matches using a structured compatibility system,
with guardian (Guardian) involvement built into the journey.

---

## 2. Project Structure

```
BLACK UMBRELLA GROUP/PROJECTS/ZYRA/
├── SYSTEM/                    ← Project governance
│   ├── DOCUMENTS/
│   │   ├── MASTER_GOVERNANCE/ ← Governance contracts
│   │   ├── MASTER_CONTRACTS/  ← Agent & operational contracts
│   │   └── MASTER_STANDARDS/  ← Standards library
│   ├── AGENTS/                ← Agent system contracts
│   ├── OUTSTANDING_ACTIONS/   ← Open action items
│   ├── DECISIONS_REGISTER/    ← Approved decisions
│   ├── LOGS/                  ← Operational logs
│   └── RESOURCES/             ← Reports, memory, assets
├── APP/                       ← Feature specifications
├── BUSINESS/                  ← Business & brand documents
├── SOURCE/                    ← Flutter source code
└── ARCHIVE/                   ← Retired structures (reference only)
```

**Note (2026-07-26, OA-ZYRA-141):** `DEVELOPMENT_TEAM/` and
`LIVE_OPERATIONS/` — an earlier "AI Development Team" / "Live
Operations" scaffolding tried once on 2026-06-26 and never used
again — were archived under `ARCHIVE/` and no longer sit at repo
root. See `ARCHIVE/README.md`.

---

## 3. Technology

- **Framework:** Flutter (Dart)
- **Platforms:** iOS, Android
- **Backend:** TBD

---

## 4. Maturity Level

| Layer | Current Level |
|-------|--------------|
| Project System | Level 1 — Structure |
| Development Team | Not started |
| Live Operations | Not started |

---

## 5. Key User Roles

| Role | Description |
|------|-------------|
| Seeker | Person searching for a match |
| Guardian | Guardian (required for female Seekers) |
| Connector | Intermediary who introduces Seekers |
