---
id: DOC-ZYRA-0507
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex brief - build a clean production server baseline for ZYRA from the repository (no test data, no test shortcuts), proven on throw-away databases, with an apply runbook. Today's Supabase project becomes the lab
links: [AD-AIOS-114, AD-AIOS-142, AD-AIOS-149, OA-ZYRA-317, DOC-BUG-0060]
owner: Fable
---

# BRIEF — CLEAN PRODUCTION SERVER BASELINE — 13 NOV 2026

**Founder-named task.** Founder 13 Nov (ZYRA audit, clickable): **"Yes, clean new server (Recommended)"** - "Codex builds a
clean production Supabase project from the repository, with no test data or shortcuts; today's project becomes the lab;
the Founder applies it live." Also "Before the first real member (Recommended)": paid Supabase plan when the clean server
goes live for real people. Fits AD-AIOS-149 (ZYRA fixes only, connect first).
**Throw-away databases only - no live apply, no project creation, no function deploy.** No downloads, no installs (F33):
if the Postgres 17 image or any tool is missing, stop as QUESTION. Never read `~/.supabase/` (a sign-in token lives there).
Allowed in quiet mode (21 Nov - 14 Dec): needs no approvals.

| Step | Detail |
|---|---|
| 1 | Replay every file in `SOURCE/supabase/migrations/` in order on a throw-away Postgres 17 (as for SERVER 0 and lines 85-107), including the server lines built only on throw-away (85, 89, 94, 100, 106, 107 when BUILT). List any file that does not replay and stop as QUESTION |
| 2 | Produce a **clean baseline** in `SOURCE/supabase/production/` (new folder; the old migrations stay as history): schema, functions, grants, access rules, storage buckets and their policies, in a small number of ordered files (target under 10), each with a header saying what it holds |
| 3 | **Leave out everything that is test-only:** every `zyra_dev_*` function; the tables `zyra_dev_probe`, `zyra_seed_answers`, `zyra_probe_score`, `zyra_guard_results`; every seed and fake-photo script; anything that checks an `@zyra.test` email; `zyra_dev_set_compatibility_score_for_testing` and the like. **No data rows**, except fixed reference rows the app needs (list each one and why) |
| 4 | **Fix at baseline:** the view `zyra_my_attempt_participation` runs with the caller's rights over a private caller-only helper (QUESTIONS 143); no `authenticated` EXECUTE on any function meant for the service role only (list all owner-rights functions callable by signed-in users, each with one line on why it is safe); every public table has access rules switched on |
| 5 | Copy the two server helpers (`functions/zyra-photo-cleanup`, `functions/zyra-profile-video-submit`) next to the baseline as deploy-ready files; do not deploy |
| 6 | **Tests on throw-away:** apply the baseline to an empty Postgres 17 from nothing; run every SQL assertion file in `SOURCE/supabase/tests/` against it (record pass / fail per file; a test that needs dev data gets its own fixture inside the test, never in the baseline); add `production_no_test_shortcuts.sql` that fails if any function or table name contains `dev`, `probe`, `seed` or `guard_results`, or any function body mentions `@zyra.test`; add a check that every public table has access rules |
| 7 | Write `SOURCE/supabase/production/RUNBOOK.md` (no keys, no ids, no addresses): **(a)** the Founder creates a new project in the existing Supabase organisation (name "ZYRA production"; region is his choice - London is closest to members); **(b)** applying the baseline - preferred: Fable applies it through the Supabase connector on the Founder's words "apply the clean server", so nobody handles a database password; or the Founder runs one CLI command; **(c)** settings the Founder sets in the dashboard: Confirm email ON, leaked-password protection ON, sign-in providers (Apple, Google), redirect URLs; **(d)** move to the paid plan before the first real member; **(e)** deploy the two helpers; **(f)** what stays on the lab project |
| 8 | The app keeps pointing at the lab project; switching it to production is a later, separate line |
| 9 | Task note (under 4 KB); commit within core rule 2; mark this line BUILT, FAILED or QUESTION. Server-design questions go to Fable (charters V9 rule 14) |

## Not in this line
Creating the project · applying anything to any real project · Auth settings · the paid plan · switching the app ·
deleting the lab's test data.
