---
id: DOC-ZYRA-0346
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex brief - remove every developer toggle and developer control from the ZYRA app, completely
links: [OA-ZYRA-325]
owner: ZYRA chat
---

# REMOVE ALL DEVELOPER TOGGLES — BRIEF — 30 OCT 2026

**Founder, 30 Oct 2026 (ZYRA chat):** "can we get codex to remove the toggle completetly in the app. meaning toggle no longer exist
at all" → which toggle: **"Developer toggles"** → what goes: **"Absolutely everything"** (the alternative, keeping one account
switch for checking builds, was offered and declined). Founder-named task, not a LOCK.

## What "developer toggle" means here
Every control that exists only for the Founder or a developer, not for members: the developer control rail and its sections
(Home / Preview / Actions), scenario panels (e.g. `wali_dev_scenario_panel.dart`), page and design option pickers
(`zyra_dev_page_options.dart`, `zyra_one_journey_options.dart`), comparison switches (`dev_app_gold_toggle`,
`dev_opening_quote_toggle`, onboarding style pickers, splash comparisons), account / role / plan / wallet switchers used to preview
another role, developer reset buttons and developer sign-up shortcuts.

**Not** developer toggles — keep them: member settings (Notifications, App lock, Appearance & haptics, Gold accents and other
Personalisation choices), and **anything drawn in a LOCK master** (e.g. "⇄ Switch" on the Guardian Profile, g13) — those stay and
work as drawn.

**ROADMAP row (charter rule 12, added 2 Nov):** "Test baseline and final interface pass" in `ZYRA/ROADMAP.md` (its last sentence: "Remove Developer Access controls…"). This line does that part; the row is ticked and its GitHub issue closed only when line 73 (test clean-up) is also BUILT.

| Step | Detail |
|---|---|
| 1 | Build after every earlier WAITING line in `BUILD_QUEUE.md` that touches the Founder preview (they rely on today's code) |
| 2 | **Inventory first:** list every developer toggle/control with file, line, what it changes, and what removing it means (table in the task note). Stop only for a real conflict with a LOCK; "the Founder can no longer preview another role" is expected and accepted, not a conflict |
| 3 | Remove them all from the app: the controls, their state, their routes and their code. Whole files that become unused are **moved** to `~/_to_delete/DEV_TOGGLES_2026-10-30/` (never deleted), listed in the task note. `main.dart`'s `ZyraDevControlsRouteObserver` goes if only the rail used it |
| 4 | Start of the app: the Founder's iPhone build opens where it opens today. If that start depended on a developer control, it opens the planned app on the Seeker side (sample Adam, Seeker One). Other roles and plans stay in the code for later real accounts but have no developer switch |
| 5 | Captures and tests: the capture/baseline tools and widget tests reach other roles and states **from code only** (test fixtures, test-only parameters), never through a control compiled into the app. Update tests that drove the removed controls; keep every LOCK test passing |
| 6 | Release safety: nothing developer-only may remain reachable in any build. Add one test that fails if a known developer key (`dev_` value keys, the rail) is present in the widget tree |
| 7 | Analyser clean. **Test gate (Founder 2 Nov, Codex question 10, option C):** run the full suite and compare with the baseline `DEV_TOGGLES/BUILT/QUEUE44_BASELINE_QA.json` (app source 60b1ab9: 649 visible failed/error in 91 files). Pass = no test that passed in the baseline fails; total failed/error ≤ 649; every LOCK test passes **except the nine LOCK 2 / LOCK 5 cases that already failed in the baseline** (listed in `DEV_TOGGLES/BUILT/QUEUE44_NINE_LOCK_GATE_CONFLICTS.json`; they are repaired in line 73, not here); the new release-safety test passes. The five baseline assertions that checked the removed developer controls (`QUEUE44_BASELINE_ASSERTION_MIGRATIONS.json`, `QUEUE44_FIFTH_BASELINE_IMPROVEMENT.json`) are accepted as updated under step 5 (Codex question 12, ZYRA chat 4 Nov). Do not repair, skip or delete baseline-failing tests in this line (that is line 73). List every remaining failure by file in the task note. Task note: inventory table, files moved, before/after code-size table, what the Founder can no longer do on the phone. Rollback: revert the commit; moved files are in `~/_to_delete/` |
| 8 | Commit within core rule 2, mark the queue line BUILT or FAILED |
