---
id: DOC-ZYRA-0508
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex brief - make the ZYRA test suite fully pass (fix or remove the 37 accepted failures, each with a written reason) and switch on automatic checks on every push
links: [AD-AIOS-114, AD-AIOS-149, DOC-BUG-0060]
owner: Fable
---

# BRIEF — GREEN TEST SUITE AND AUTOMATIC CHECKS — 13 NOV 2026

**Founder-named task.** Founder 13 Nov (ZYRA audit, clickable): **"Yes, while I'm away (Recommended)"** - "Codex fixes
or removes the 37 failing tests, each with a written reason, then switches on automatic checks on every push; this runs
during 21 Nov - 14 Dec." **Start on or after 21 Nov.** Quiet mode: no approvals, no downloads on the Mac (packages are
already cached; the automatic checks run on GitHub's own machines).

| Step | Detail |
|---|---|
| 1 | Run the whole suite once and list every failing test (suite and test name) - expected 37 to 38 - in `SOURCE/test/FAILURE_DECISIONS_2026-11.md` |
| 2 | For each one decide and write one line: **fix** (the test is right, the code is wrong - fix the code within its LOCK), **update** (the test checks a superseded design - point to the LOCK or decision that replaced it), or **remove** (it tests the retired old member app or a retired feature - name what retired it). Never weaken or remove a test of a safety, privacy, access or payment rule: stop that one as QUESTION |
| 3 | List the 122 skipped tests with their reasons in the same file; change none unless its reason no longer exists (then fix or remove as in step 2) |
| 4 | Gate: the whole suite passes with **zero failures**; `flutter analyze` clean; record the before / after counts |
| 5 | Add `.github/workflows/zyra-ci.yml`: on every push to `main` and on pull requests; Ubuntu; Flutter pinned to the exact version the Mac uses; every third-party action pinned to a full commit id; steps `flutter pub get`, `flutter analyze`, `flutter test`; cancel an older run when a newer push arrives; 30-minute timeout; no secrets used |
| 6 | Cost: the repo is going private (AD-AIOS-149), and private repos get a limited number of free GitHub minutes a month. Time one run; if the full suite takes over 15 minutes, keep `flutter analyze` plus the tests of the changed folders on every push and run the full suite once a night (02:30 UK). Write the minutes per run and per month in the task note |
| 7 | If the push of the workflow file is refused (it needs extra GitHub permission), stop that step as QUESTION - do not change any GitHub sign-in |
| 8 | From then on a red automatic check counts as a failed gate for every ZYRA line (add one line to ZYRA's AGENTS.md "Gate" rule; replace, do not add, if a gate line exists) |
| 9 | Task note (under 4 KB); commit within core rule 2; mark this line BUILT, FAILED or QUESTION |
