---
id: TBC (Fable assigns)
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 4 - profile photo in the Profiles details card circle
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — PROFILES DETAILS CARD PHOTO — 29 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (LOCK record and spec) and both pictures in `../MASTERS/` |
| 2 | Change `ZyraProfileDetailsPage` so the circle shows the first photo via the caller's existing photo builder (the file header says it holds no photos — pass the photo in from `zyra_browse_designs.dart`; keep it free of services). Fallback icon for no photo, loading and error |
| 3 | Tests: photo shown when the person has photos; icon when none; icon on load error; sizes unchanged. Analyser clean |
| 4 | Render `profiles_tab__details_card_photo.png` (with a real sample photo) and `profiles_tab__details_card_no_photo.png` into `PROFILES_DETAILS_CARD/BUILT/` (430 × 932 @3x) |
| 5 | Task note, commit within core rule 2, mark the queue line BUILT or FAILED |
