---
id: TBC (Fable assigns)
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Founder-named task - clean up the app tests that already failed before line 44 (649 at app source 60b1ab9), so the full suite can be green again
links: [AD-AIOS-116]
owner: ZYRA chat
---

# TEST CLEAN-UP — 2 NOV 2026

**Founder, 2 Nov 2026 (clickable):** "A · Remove now, clean tests after (Recommended)" — line 44 removes the developer
toggles with a no-new-failures gate; this line then cleans the old failing tests.

**ROADMAP row (charter rule 12):** "Test baseline and final interface pass" in `ZYRA/ROADMAP.md`. When this line and line 44 are both BUILT, tick that row and close its GitHub issue; if failures remain, leave the row open and write the remaining count in the task note. Only Fable changes ROADMAP rows or hours.

**No app behaviour changes in this line.** Tests, test fixtures and golden images only. No upgrades (standing rule,
strict 21 Nov – 14 Dec). Unclear → file a question in `QUESTIONS.md` and continue with the next group.

| Step | Detail |
|---|---|
| 0 | **First:** the nine LOCK 2 / LOCK 5 cases in `DEV_TOGGLES/BUILT/QUEUE44_NINE_LOCK_GATE_CONFLICTS.json` (Main Guardian notice and My ZYRA tab-attention tests that fail in their old harness before reaching their assertions). Repair their harness so each reaches and checks its real LOCK requirement; if a requirement fails against the app, that is a Finding (step 2), not an app change |
| 1 | Start from line 44's task-note failure list (or re-run the suite at the current commit) and group failures by file |
| 2 | For each failing test decide one of: **Update** — it checks a screen or rule that a later LOCK changed: update it to the current LOCK spec/masters (cite the LOCK and master in a comment); **Retire** — the feature or screen no longer exists in the app: move the test file to `~/_to_delete/ZYRA_TESTS_RETIRED_<date>/` (never delete); **Fixture** — a missing or stale fixture (e.g. the absent `20260924100231_…guardian_circle_contract.sql`): point the test at the current file if one exists, else retire it; **Finding** — the app itself looks wrong against a LOCK: do NOT change app code; add a `QUESTIONS.md` row for the ZYRA chat |
| 3 | Visual goldens (e.g. `zyra_visual_regression_test.dart`): regenerate only for screens whose current build matches its LOCK masters (the ZYRA chat's BUILT checks); otherwise list as a finding |
| 4 | Pass = full suite green, or every remaining failure listed with its reason and question number. No new skips without a reason in the code |
| 5 | Task note: table per file (Update / Retire / Fixture / Finding, count), before/after totals (baseline 649), files moved; commit within core rule 2; mark queue line 73 BUILT or FAILED |
