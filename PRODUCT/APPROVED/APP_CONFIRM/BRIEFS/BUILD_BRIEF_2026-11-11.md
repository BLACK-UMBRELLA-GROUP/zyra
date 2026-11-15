---
id: DOC-ZYRA-0449
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief - one confirm sheet (LOCK 28), no darker fills (APP COLOURS V8), Preview = Profiles card (LOCK 21 V3)
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — CONFIRM SHEET · IVORY FILLS · PREVIEW — 11 NOV 2026

**Copy exactly. No improvements.** Unclear → `QUESTIONS.md` row. ROADMAP row (charter rule 12): "Test baseline and final interface pass" (do not tick).
Founder iPhone pass, 11 Nov 21:46–21:49: full-height Cancel invitation dialog ("This design isnt nice" + "the buttons dont even work"), darker Settings cards ("Remove this darker colour everywhere it is in app"), Preview ("Preview profile old style, needs fixing").
Reference: prototype copy `PRODUCT/APPROVED/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V187.html`.

| Step | Detail |
|---|---|
| 1 | **Confirm sheet — LOCK 28** (`APP_CONFIRM/RECORD/APP_CONFIRM_SPEC_CURRENT_VERSION_V1.md`). Build one shared confirm sheet (hugs content; monogram, question title, 1–2 lines, danger row, ivory Keep pill; dim layer = keep). Replace **every** confirm dialog in the app with it (search the code for every dialog / alert / confirm). First find why the Cancel invitation buttons did nothing and fix it; every confirm's action must run and the sheet close |
| 2 | **No darker fills — APP COLOURS V8** (`APP_COLOURS/RECORD/APP_COLOURS_SPEC_CURRENT_VERSION_V8.md`). Find every surface filled darker than the background (e.g. Settings cards, Profile list cards, search boxes, inputs, code boxes, selected segment / tab pill, icon circles, quiet "Keep / Cancel" buttons, Basic monogram fill) and use the ivory floating fill + soft shadow. Dark tints stay only for dividers, the dim layer, grab handles, slider / progress tracks, inactive dots. Prefer fixing the shared colour token so no page can keep the old fill |
| 3 | **Preview — LOCK 21 V3** (`PROFILE_TAB/RECORD/PROFILE_TAB_SPEC_CURRENT_VERSION_V3.md` "Preview (V3)"). Profile → Preview shows the **same card component as Profiles** (tiles, request button in the card, photo pages), header "Preview" + "This is how others see your profile.", current tab bar; no ‹ › row; request button only shows a toast |
| 4 | Visual check against the prototype copy on 430 × 932 and 375 × 667 (Guardian → Omar → Cancel invitation; Guardian ••• → Remove; Profiles ••• → Hide; Settings; Filters; Profile → Preview); note results in the task note |
| 5 | Tests: no confirm uses a dialog taller than its content; each confirm's action and keep both work; no widget uses the old darker fill token (search test); Preview uses the Profiles card component and has no ‹ › buttons |
| 6 | Gate: `flutter analyze` clean; no new failures against line 82 |
| 7 | iPhone: protected route only, on Shakeel's GO with the phone connected, telling him the build first |
| 8 | Task note; commit within core rule 2; mark queue line 83 BUILT or FAILED |
