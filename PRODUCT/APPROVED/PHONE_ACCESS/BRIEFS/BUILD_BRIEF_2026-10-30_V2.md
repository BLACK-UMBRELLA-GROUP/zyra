---
id: DOC-ZYRA-0373
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 12 V2 - Phone access page (replaces queue line 27)
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — PHONE ACCESS — V2 — 30 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Line 26 (LOCK 11) is BUILT.
Replaces queue line 27 (FAILED preflight 30 Oct 18:56: LOCK12-PREFLIGHT-01 explain sheets not drawn; -02 two Location wordings). Both are settled in spec V2.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (spec **V2**) and the two `../MASTERS/` (`phone_access__normal.png` is V2) |
| 2 | Founder preview Settings: add the Phone access row (PRIVACY, after Hidden Profiles, NEW until opened) and the page |
| 3 | Status from the phone's real permission state where a package already in the project can read it; otherwise show "Ask first" and report it — do not add new dependencies without saying so in the task note |
| 4 | Tap: not yet asked → the iPhone prompt at once (**no ZYRA explain sheet** on this page); asked before → iPhone Settings → ZYRA |
| 5 | `Info.plist`: set the Camera, Photos and Face ID texts exactly as the spec table; **leave Location and PhotoLibraryAdd unchanged**; no Contacts, microphone, tracking or Always-location keys |
| 6 | Tests: row and NEW tag; page rows and texts (Location row "approximate area"); tap behaviour (mocked: not asked → prompt, asked → Settings); statuses; Info.plist texts. Analyser clean |
| 7 | Render both master states into `PHONE_ACCESS/BUILT/`; task note; commit within core rule 2; mark the queue line BUILT or FAILED |
