---
id: DOC-ZYRA-0475
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex server brief - ZYRA Code check limit with a clear "too many tries" error (LOCK 9 V3, QUESTIONS 137), throw-away databases only
links: [AD-AIOS-115, OA-ZYRA-317]
owner: Fable
---

# SERVER BRIEF — ZYRA CODE CHECK LIMIT — 12 NOV 2026

**Founder-named task.** Founder 12 Nov ~21:55 (clickable "Limit code checks (Recommended)", LOCK 9 V3, QUESTIONS 137).
**Throw-away databases only - no live apply.** No downloads, no installs.

| Step | Detail |
|---|---|
| 1 | The limit already exists in `20260917144606_oa289_permanent_personal_codes_guardian_requests.sql`: **10 checks an hour and 30 a day per account**, shared by `zyra_preview_personal_code`, `zyra_preview_match_code` and `zyra_consider_match_code`. Keep those numbers |
| 2 | Change only what happens **at** the limit: instead of the silent empty result, raise `too_many_code_checks` (an over-limit check is not stored as another attempt). A wrong or unknown code still returns the same empty result as today, so nobody can learn whether a code exists |
| 3 | New read `zyra_my_code_check_budget()` (authenticated, own rows): `checks_left_this_hour`, `checks_left_today`, `next_check_at` (null when checks are left) so the app can say "Too many tries. Try again at 21:40." |
| 4 | Tests: the 11th check in an hour and the 31st in a day raise `too_many_code_checks`; the error never depends on whether the code exists; budget read matches; another account's budget is unaffected |
| 5 | Task note; commit within core rule 2; BUILT, FAILED or QUESTION |
