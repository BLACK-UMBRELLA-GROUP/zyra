---
id: DOC-ZYRA-0284
type: REPORT
status: CURRENT
feature: CODE HEALTH
purpose: ZYRA code-size tracker - how much code the app has, how much is developer/preview code, and how many old-app files still carry retired features; one row per clean-up step
links: [OA-ZYRA-316, DR-ZYRA-274]
owner: Fable
---

# ZYRA — CODE SIZE TRACKER

Founder request, 25 Oct 2026: show this table whenever we report on cleaning the code. Numbers come from
`SYSTEM/tools/blueprint/code_size.py` (read-only; counts `SOURCE/lib`). "Save" is not counted because the word is too common
to measure honestly by search; it will be counted file by file in the deep review.

## Latest

| What | Size |
|---|---|
| All app code | 171,658 lines in 342 files |
| Developer and preview code inside it | 46,429 lines in 87 files |
| The Founder preview (planned app) | 24,701 lines in 31 files |
| Test code | 207,814 lines in 464 files |
| Test screenshots (goldens) | 3,984 images, 467 MB |
| Old-app files that still mention Pause | 40 |
| Old-app files that still mention Restart | 2 |

## History

| Date | Step | All app code | Developer + preview | Founder preview | Test code | Goldens | Pause files | Restart files |
|---|---|---|---|---|---|---|---|---|
| 2026-10-25 | Baseline, before any clean-up (OA-ZYRA-316) | 171,658 / 342 | 46,429 / 87 | 24,701 / 31 | 207,814 / 464 (counted 26 Oct) | 3,984 / 467 MB (counted 26 Oct) | 40 | 2 |

Note: the first count given to the Founder on 25 Oct said 45,620 lines / 84 files of developer code; it missed the three
developer screens in `screens/dev/`. The baseline above is the corrected figure.
