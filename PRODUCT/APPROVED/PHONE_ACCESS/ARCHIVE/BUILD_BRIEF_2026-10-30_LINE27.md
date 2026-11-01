---
id: DOC-ZYRA-0371
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 12 - Phone access page
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — PHONE ACCESS — 30 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Build after LOCK 11 (location).

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` and the two `../MASTERS/` |
| 2 | Founder preview Settings: add the Phone access row (PRIVACY, after Hidden Profiles, NEW until opened) and the page |
| 3 | Status from the phone's real permission state where a package already in the project can read it; otherwise show "Ask first" and report it — do not add new dependencies without saying so in the task note |
| 4 | iOS purpose strings in `Info.plist` for location, camera, photos and Face ID with the exact "why" texts; no Contacts, microphone, tracking or Always-location keys |
| 5 | Tests: row and NEW tag; page rows and texts; tap behaviour (mocked); statuses. Analyser clean |
| 6 | Render both master states into `PHONE_ACCESS/BUILT/`; task note; commit within core rule 2; mark the queue line BUILT or FAILED |
