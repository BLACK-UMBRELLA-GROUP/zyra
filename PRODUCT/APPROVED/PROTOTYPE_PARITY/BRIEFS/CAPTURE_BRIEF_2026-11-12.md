---
id: DOC-ZYRA-0503
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex task - render every page of the Founder preview app so the ZYRA chat can make the prototype match the app
links: [AD-AIOS-115, AD-AIOS-146]
owner: ZYRA chat
---

# CAPTURE BRIEF — APP SCREENS FOR PROTOTYPE PARITY — 12 NOV 2026

**Copy exactly. No improvements.** Unclear → `QUESTIONS.md` row. ROADMAP row (charter rule 12): "Test baseline and final interface pass" (do not tick).
Founder, 12 Nov 09:28: "what i want you to do while you wait is ensure prototype is exactly same as the app". The ZYRA chat cannot run Flutter, so it needs pictures of the current app. **Read-only task: no product code changes.**

| Step | Detail |
|---|---|
| 1 | From the current `main` (after line 87 if BUILT, else as is), render **every tab and page** of the Founder preview app listed in `PRODUCT/BLUEPRINT/ZYRA_PLANNED_SCREEN_INVENTORY_GENERATED.md` (10 tabs, 61 pages; regenerate the inventory first if it is older than the code) plus the sign-up / onboarding flow, using the existing local render path (e.g. `tools/zyra_visual_gate.py --capture-candidates` fixtures or widget renders). Never approve a baseline |
| 2 | Size **430 × 932 @3x**, light (ivory) theme, default text size. For each page every state the code has (empty / filled / locked / error), and each role that sees it: **Seeker One, Seeker Basic, Guardian One, Guardian Basic**. Sheets and pop-ups open (••• menus, confirm sheets, upgrade sheets) as their own pictures |
| 3 | Placeholder people and photos only (fixtures), never a real member |
| 4 | Save as PNG to `BLACK UMBRELLA GROUP/BUSINESS/ZYRA/APP_SCREENS/2026-11-12/` (private — **not** in the ZYRA repo). File name `<role>__<page>__<state>.png` (e.g. `seeker_basic__compatibility__locked.png`) |
| 5 | Write `INDEX.md` in the same folder: one row per picture — file, role, page key, state, how it is opened (tab / button), and the Dart builder (e.g. `_journeyOptionsPage`). List any page that could not be rendered and why |
| 6 | Note in the task note any page whose code still uses the old dark (plum) colours, the old ‹ › request row, or `BoxFit.contain` letterboxing |
| 7 | Gate: nothing to analyse (no code change); confirm `git status` shows no product change |
| 8 | Task note; commit only the task note within core rule 2 (the pictures stay in the private folder); mark queue line 90 BUILT or FAILED |
