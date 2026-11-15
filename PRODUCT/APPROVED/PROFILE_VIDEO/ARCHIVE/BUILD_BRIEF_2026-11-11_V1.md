---
id: DOC-ZYRA-0448
type: PLAN
status: SUPERSEDED
feature: PRODUCT BLUEPRINT
purpose: Codex build brief - silent profile video for Seeker One (LOCK 29), app side
links: [AD-AIOS-115]
owner: ZYRA chat
---

> **SUPERSEDED 11 Nov 2026 by `BRIEFS/BUILD_BRIEF_2026-11-11_V2.md`. Do not build from this file.**

# BUILD BRIEF — PROFILE VIDEO — 11 NOV 2026

**Copy exactly. No improvements.** Unclear → `QUESTIONS.md` row. ROADMAP row (charter rule 12): "Test baseline and final interface pass" (do not tick).
**Start only when the server side exists** (Fable, OA-ZYRA-317: storage, sound removal, 10 s limit, checking, approved state, hide on downgrade). If it does not, mark this line **BLOCKED** with a QUESTIONS row and stop.
Reference: `PROFILE_VIDEO/RECORD/PROFILE_VIDEO_SPEC_CURRENT_VERSION_V1.md` and the prototype copy `PRODUCT/APPROVED/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V187.html`.

| Step | Detail |
|---|---|
| 1 | Manage photos: video space as the last tile (states Add / Being checked / Live / rejected; Seeker Basic locked tile → Seeker One page); grid fills the height; remove uses the LOCK 28 confirm sheet |
| 2 | Picker: video only, trim to 10 s, upload; never play sound anywhere |
| 3 | Profiles card, Preview and Journey Bio: approved video = last photo page, muted loop autoplay while open, badge "Video · no sound", extra page dot; Reduce Motion / Low Power = still + tap to play |
| 4 | Seeker One upgrade table row "Profile video · — · 1 silent video" (LOCK 25 V3) once this ships |
| 5 | Visual check against the prototype copy on 430 × 932 and 375 × 667 |
| 6 | Tests: Basic cannot add (button locked, server refuses); unapproved video never shown to others; no audio track played; 10 s limit; page count and dots include the video; remove works |
| 7 | Gate: `flutter analyze` clean; no new failures |
| 8 | iPhone: protected route only, on Shakeel's GO, telling him the build first |
| 9 | Task note; commit within core rule 2; mark queue line 84 BUILT, FAILED or BLOCKED |
