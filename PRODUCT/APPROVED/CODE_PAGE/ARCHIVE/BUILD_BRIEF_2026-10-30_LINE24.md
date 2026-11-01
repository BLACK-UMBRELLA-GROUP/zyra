---
id: DOC-ZYRA-0340
type: PLAN
status: ARCHIVED (2026-10-30)
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 9 - ZYRA Code page
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — CODE PAGE — 30 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` and the five `../MASTERS/` pictures |
| 2 | Founder preview: replace the Scan page (Profiles ••• → Scan), the Seeker Add a Guardian page and the Guardian sign-up "Add a Seeker" code step with the locked layout. One shared widget for camera frame + code boxes + Check code |
| 3 | Camera: use the existing scanner path if one exists; in the preview with no camera, show the frame with its text (no crash, no permission prompt in tests). Keep every existing rule about what a code reveals |
| 4 | Tests: five boxes fill as you type and on paste; only letters/numbers; Check code → found card / existing error; Add a Guardian Check code → existing Main Guardian sheet; screen reader label; Larger Text no clipping. Analyser clean |
| 5 | Render the five master states into `CODE_PAGE/BUILT/` (430 × 932 @3x) |
| 6 | Task note, commit within core rule 2, mark the queue line BUILT or FAILED |
