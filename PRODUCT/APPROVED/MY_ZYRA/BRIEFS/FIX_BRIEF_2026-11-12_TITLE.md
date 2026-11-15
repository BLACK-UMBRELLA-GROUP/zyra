---
id: DOC-ZYRA-0490
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex fix brief - the My ZYRA page title must use the same title style and position as the other four tabs (MY_ZYRA spec V6 "same title style as every tab")
links: [AD-AIOS-115]
owner: ZYRA chat
---

# FIX BRIEF — MY ZYRA TITLE MATCHES THE OTHER TABS — 12 NOV 2026

**Copy exactly. No improvements.** Unclear → `QUESTIONS.md` row. ROADMAP row (charter rule 12): "Test baseline and final interface pass" (do not tick).
Founder, 12 Nov 21:07 (iPhone): "my zyra title isnt same as other 4 title check that". Spec: `MY_ZYRA/RECORD/MY_ZYRA_SPEC_CURRENT_VERSION_V6.md` §1 row
Title — **"My ZYRA" (same title style as every tab)**. This is a build defect, not a new design.

ZYRA chat read the code (no changes made): Profiles, Journey and Profile use `_mainHeading()` in `lib/dev/zyra_one_journey_concept_shell.dart`
→ `ZyraText.pageTitle()` (**26 pt, weight w200**), left-aligned, page margin 20, top 16. `lib/widgets/zyra_focus_dashboard.dart` (My ZYRA, and the
Guardian home that reuses it) draws its own title with `ZyraText.heading(size: 28)` **weight w300, height 1.2** — bigger and heavier.

| Step | Detail |
|---|---|
| 1 | In `ZyraFocusDashboard`, draw the title with `ZyraText.pageTitle()` exactly as `_mainHeading()` does (same size, weight, line height, colour, alignment). Better: move the tab title into one shared widget and use it on all five tabs (Seeker and Guardian), so they can never drift again |
| 2 | Same **position**: the title's top edge and left edge on My ZYRA must equal Profiles / Journey / Guardian / Profile on 430 × 932 and 375 × 667 (title baseline within 1 pt). Page dots and the Guardian greeting keep their current gap below the title |
| 3 | Check every other tab title in the Seeker and Guardian apps (Guardian side tabs too) and list any other one that does not use the shared style in the task note; fix them the same way |
| 4 | Test: one golden/position test that renders all five tab titles and asserts identical style and top/left offsets |
| 5 | Gate: `flutter analyze` clean; no new failures. Task note; commit within core rule 2; mark the queue line BUILT or FAILED |
