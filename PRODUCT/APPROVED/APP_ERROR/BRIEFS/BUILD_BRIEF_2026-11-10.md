---
id: TBC (Fable assigns)
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 23 - one app-error page with help, then install the build on the Founder's iPhone
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — ONE APP-ERROR PAGE (LOCK 23) + iPHONE — 10 NOV 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop, file a QUESTIONS.md row, continue other work.
ROADMAP row (charter rule 12): "Onboarding tour" — this line covers its error paths only; write progress in the task note, do not tick the row.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (LOCK record + spec V1) and masters e01–e05. Today: `lib/models/zyra_error_state.dart`, `lib/widgets/zyra_full_screen_error.dart`, `lib/dev/zyra_founder_launch_screen.dart` (`ZyraCompactRecoverySurface` card) |
| 2 | One full-screen error page for every `ZyraErrorKind`, laid out and worded exactly as spec §3–§4 (wordmark, mark, title, line, WHAT YOU CAN TRY card, countdown, Try again / Sign in again, Contact support, reference). Reuse the shared floating card and info-row widgets |
| 3 | Founder-preview launch failure: remove the compact card; route straight to the one page with the right kind (`previewAccess` → session words). Never show two error pages in a row |
| 4 | Auto-retry every 15 s with the countdown (retry kinds); success continues to the intended screen. Contact support opens the existing Help & support page |
| 5 | Remove the old secondary labels and the compact card code (no dead code). Tests: each kind's words; one page only on preview launch failure (no card first); countdown and retry; Contact support target; Larger Text. Analyser clean; no new failures against the current suite |
| 6 | Render e01–e05 into `APP_ERROR/BUILT/V1/` with master-beside-build; task note; commit within core rule 2 |
| 7 | **iPhone (Founder 10 Nov: "ensure app is on ihpone also pelase"):** install this build on the Founder's iPhone through the protected install route (cable or Wi-Fi, phone unlocked). If the protected route still fails, do **not** use the old installer: file a QUESTIONS.md row saying exactly what failed, so the Founder can decide; the build itself still counts as done |
| 8 | Mark queue line 74 BUILT or FAILED |
