---
id: DOC-ZYRA-0408
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 16 V2 - blocking or hiding someone you are in a Journey with ends that Journey after a warning sheet; reporting stays a draft. Reissue: the line 50 brief file was empty
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — BLOCK / HIDE DURING A JOURNEY (LOCK 16 V2) — 31 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Build after queue line 42; before line 44. Seeker One and Seeker Basic, Founder preview.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (LOCK record + spec **V2**) and masters b01–b03 |
| 2 | At every Block or Hide entry point for a person (Report profile's Hide / Block links from Journey options, View profile and Profiles •••, and any other person-level Hide/Block button): if you are in a current Journey with that person, show the confirm sheet (spec "Confirm sheet", words exactly). Not in a Journey → unchanged, no sheet |
| 3 | Confirm → existing end-Journey action, then the existing block / hide action → Journey tab (b03) with the spec toast. Keep → sheet closes, nothing changes |
| 4 | **Reporting is unchanged:** the report screen stays the draft it is today (Submit off). Blocking or hiding never creates or sends a report. No server work |
| 5 | Hidden Profiles texts: change the two texts **only where they already exist** (older member Hidden Profiles screen). Do not add a Hidden Profiles screen to the Founder preview |
| 6 | Guardian-connection block (Guardian app chat) is **not** in this line and keeps its own behaviour |
| 7 | Tests: Block and Hide with and without a Journey; Keep; toasts; no report created; Larger Text. Analyser clean |
| 8 | Render b01–b03 into `JOURNEY_BLOCK_HIDE/BUILT/V2/` with master-beside-build; task note; commit within core rule 2; mark queue line 69 BUILT or FAILED |
