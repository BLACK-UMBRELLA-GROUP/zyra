---
id: DOC-ZYRA-0342
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 9 - ZYRA Code page, second attempt after queue line 24 stopped
links: [AD-AIOS-115, DR-ZYRA-231]
owner: ZYRA chat
---

# BUILD BRIEF — CODE PAGE — V2 — 30 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Replaces the brief for queue line 24
(`../ARCHIVE/BUILD_BRIEF_2026-10-30_LINE24.md`), which stopped because step 4 asked for the Main Guardian sheet after Check code.
Spec V2 fixes that; Founder LOCK 30 Oct ("LOCK all three").

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (spec **V2**) and the nine `../MASTERS/` pictures |
| 2 | Founder preview: replace the Scan page (Profiles ••• → Scan), the Seeker Add a Guardian page and the Guardian sign-up "Add a Seeker" code step with the locked layout. One shared widget for camera frame + code boxes + Check code + result card |
| 3 | Camera: use the existing guarded scanner path; in the preview with no camera, show the frame with its text (no crash, no permission prompt in tests). Keep every existing rule about what a code reveals |
| 4 | Add a Guardian / Add a Seeker: Check code → found card with **Send request** → sent state, as the masters. Local only: no invitation, request, link or Main Guardian sheet is created (`_checkLocal` / local `_send` stay local). Do not touch the Make Main action or its notice guard |
| 5 | Tests: five boxes fill as you type and on paste; only letters/numbers; under 20 characters → "Enter all 20 characters."; Scan Check code → found card / existing error; Add a Guardian and Add a Seeker: found → Send request → "Request sent" text, and **no** Main Guardian sheet; screen reader label; Larger Text no clipping. Analyser clean |
| 6 | Render the nine master states into `CODE_PAGE/BUILT/` (430 × 932 @3x) with the same names, plus one picture with each master beside its build |
| 7 | Task note, commit within core rule 2, mark the queue line BUILT or FAILED |
