---
id: DOC-ZYRA-0365
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 11 - Location for distance (app part)
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — LOCATION (APP PART) — 30 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Build after the Filters line (LOCK 10 **V4**, queue line 37). Updated 30 Oct: the origin line now sits in the Where card under Near me (spec **V2**, masters re-rendered).

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (spec **V2**) and the four `../MASTERS/` |
| 2 | Founder preview: origin line + Change, the choose sheet and the explain sheet. In the preview, distances are measured from the sample home town, or from the device's approximate location if allowed; sample people use their sample cities. Nothing is sent to a server |
| 3 | iOS: add `NSLocationWhenInUseUsageDescription` with the exact purpose string and request reduced accuracy (no precise location, no "Always"). Use an existing, maintained location package if one is already in the project; otherwise stop and report before adding a dependency |
| 4 | No distance numbers on cards or profiles; never store or log exact coordinates |
| 5 | Tests: default home town; choose sheet; explain → prompt path (mocked); allow → "your current area"; deny → stays home town + toast; nothing shown on cards. Analyser clean |
| 6 | Render the three ZYRA-drawn master states into `LOCATION/BUILT/`; task note; commit within core rule 2; mark the queue line BUILT or FAILED |
