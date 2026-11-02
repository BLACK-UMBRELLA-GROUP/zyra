---
id: DOC-ZYRA-0385
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 19 - Seeker Guardian tab Monogram cards and Guardian Basic chat sheet
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — GUARDIAN CARD — 31 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Build after queue lines 42 (Ivory) and 46 (unread bubble); before lines 68 (page dots, LOCK 18 V2 — this line's masters already show the dots at the top, so build them there) and 44. (Order fixed 31 Oct: line 49 was withdrawn; Codex question 3.)

**Correction 31 Oct (Codex question 5):** the invited card (k07) — **Send invitation again** opens the unchanged LOCK 9 Add a Guardian page (no resend exists, do not create one); seed one preview-only invited Guardian exactly as k07 (Omar · Brother, "Waiting for Omar"), like other preview sample data. No server, no named-invitation model.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (LOCK record + spec **V2**) and all 19 `../MASTERS/`. Today's page for comparison: `BASELINE/SCREENSHOTS/seeker/guardians/` and `seeker_basic/` |
| 2 | Replace the Seeker Guardian tab main page with the card layout (spec §2–§5): header with Circle button (LOCK 17 bubble) and +, LOCK 18 dots, one card per Guardian in the stated order, ‹ › pill + swipe, flip on tap, Add card last. Seeker Basic: one Guardian + locked Add card |
| 3 | Access side (spec §4): one tile per Journey place filling the height; View/Chat pill switches using the **existing** per-Guardian Journey permission data; Chat only while View is on; Main = Chat on by default, Additional = off; free places dashed; Make/Remove Main and Remove use the **existing** confirm flows |
| 4 | Past Journey summaries switch on the card front uses the **existing** per-Guardian sharing setting (LOCK 3 V2 §3b). Do not add a second setting |
| 5 | Guardian Basic chat sheet (spec §6) with the three Family states, price step and invite-sent step. Prices from the existing Family formula (`zyra_family_formula_monthly_pence` or its app mirror) — never typed in. If the app cannot tell which Family state the Seeker is in, use "No Family" and say so in the task note |
| 6 | Spec §8: purchase, give-place and cancel are **local preview only** — no store call, no server write, no new database field. Locked pill shows "Invited" while a local invite exists |
| 7 | Remove the old Guardian tab layout code it replaces (no dead code left behind); keep Add a Guardian (LOCK 9), What Guardians can do (LOCK 3) and the Circle untouched |
| 8 | Tests: card order; ‹ › ends at 35 %; flip; Basic one Guardian; Chat disabled for Basic; sheet in 3 states; price numbers 2 → £49.98 and 3 → £66.47 from the formula; Done / Cancel invite; Larger Text keeps tiles readable (grow, no clipping). Analyser clean |
| 9 | Render k01–k19 into `GUARDIAN_CARD/BUILT/` with master-beside-build; task note listing anything not matched; commit within core rule 2; mark queue line 48 BUILT or FAILED |
