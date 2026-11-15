---
id: DOC-ZYRA-0476
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 26 V3 - smooth swipe settle that follows the finger and one iPhone-bounce scroll feel everywhere
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — SMOOTH SWIPE AND SCROLL (APP SWIPE V3) — 12 NOV 2026

**Copy exactly. No improvements.** Unclear → `QUESTIONS.md` row. ROADMAP row (charter rule 12): "Test baseline and final interface pass" (do not tick).
Reference: prototype V222 (private copy `BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V224.html`). Layout from the app's existing components.

Spec: `APP_SWIPE/RECORD/APP_SWIPE_SPEC_CURRENT_VERSION_V3.md` (LOCK 26 V3).

| Step | Detail |
|---|---|
| 1 | Add one motion token file `lib/theme/zyra_motion.dart`: swipe base 420 ms, curve `Cubic(0.22, 1, 0.36, 1)`, min 60 % of base, page threshold 22 % of the page width, flick 0.45 pt/ms (after 12 pt) |
| 2 | `lib/widgets/zyra_swipe_track.dart` (and any other sideways track — Profiles, Guardian, Journey places, Filters, My ZYRA): replace the 240 ms / Cubic(.2,.8,.2,1) settle with the tokens; settle time follows the release speed (remaining distance ÷ speed × 1.6, clamped 252–420 ms); start from the finger's position and speed (no jump); spring-back the same; dots, edge taps and programmatic page changes use the same tokens. Reduce Motion: no slide |
| 3 | **Scrolling:** one app-wide scroll behaviour = `BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())`; remove every `ClampingScrollPhysics` (36 today) unless a LOCK says otherwise; `NeverScrollable` only where a page must not scroll by design (list each kept one in the task note). Programmatic scrolls animate 420 ms with the same curve |
| 4 | Pull-down-to-close (`zyra_pull_down_back_scope.dart`) keeps working on every page after the physics change (bounce must not steal the pull) |
| 5 | Tests: token values; a slow drag past 22 % moves on, a flick moves on, a short slow drag springs back; no ClampingScrollPhysics left (search test) |
| 6 | Gate: `flutter analyze` clean; no new failures. iPhone check on Shakeel's GO. Task note; commit within core rule 2; mark the queue line BUILT or FAILED |
