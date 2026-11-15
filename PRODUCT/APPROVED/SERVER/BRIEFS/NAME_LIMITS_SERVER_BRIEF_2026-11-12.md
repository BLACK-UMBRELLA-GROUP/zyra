---
id: DOC-ZYRA-0474
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex server brief - name length limits first 30 / surname 40 for new or edited names (LOCK 33, QUESTIONS 135), throw-away databases only
links: [AD-AIOS-115, OA-ZYRA-317]
owner: Fable
---

# SERVER BRIEF — NAME LIMITS — 12 NOV 2026

**Founder-named task.** Founder 12 Nov ~17:40 (clickable "First 30 · Surname 40 (Recommended)", LOCK 33, QUESTIONS 135).
**Throw-away databases only - no live apply.** No downloads, no installs.

| Step | Detail |
|---|---|
| 1 | New migration after SERVER 0: a BEFORE INSERT OR UPDATE trigger on `profiles` that checks only a **new or changed** value: `first_name` 1-30 characters (`char_length`, trimmed, as today's shape rule), `surname_line` at most 40 characters (null allowed as today). Raise `first_name_too_long` / `surname_too_long` |
| 2 | Keep the existing `char_length(first_name) between 1 and 60` check from `20260807184618_profiles_first_name_shape.sql` as it is, so saved longer names stay valid; an unchanged long name never fails an update of another field |
| 3 | Tests: new 30 passes, 31 fails; surname 40 passes, 41 fails; existing 45-character name survives an unrelated update; editing it to another long name fails; Arabic and accented names counted by characters |
| 4 | Task note; commit within core rule 2; BUILT, FAILED or QUESTION |
