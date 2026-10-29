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
| All app code | 167,819 lines in 326 files |
| Developer and preview code inside it | 46,118 lines in 86 files |
| The Founder preview (planned app) | 24,701 lines in 31 files |
| Test code | 206,100 lines in 459 files |
| Test screenshots (goldens) | 3,349 images, 401 MB |
| Old-app files that still mention Pause | 39 |
| Old-app files that still mention Restart | 2 |

## History

| Date | Step | All app code | Developer + preview | Founder preview | Test code | Goldens | Pause files | Restart files |
|---|---|---|---|---|---|---|---|---|
| 2026-10-25 | Baseline, before any clean-up (OA-ZYRA-316) | 171,658 / 342 | 46,429 / 87 | 24,701 / 31 | 207,814 / 464 (counted 26 Oct) | 3,984 / 467 MB (counted 26 Oct) | 40 | 2 |

| 2026-10-29 | OA-ZYRA-316 Tier 1: 16 unused files removed; 6 retained by scope/dependencies | 167,819 / 326 | 46,118 / 86 | 24,701 / 31 | 206,100 / 459 | 3,349 / 401 MB | 39 | 2 |

Note: the first count given to the Founder on 25 Oct said 45,620 lines / 84 files of developer code; it missed the three
developer screens in `screens/dev/`. The baseline above is the corrected figure.


## Tier 1 — 29 Oct 2026 (OA-ZYRA-316 / DR-ZYRA-274)

Removed 16 unreachable source files (3,839 lines), their dedicated tests and only their cases in shared suites. Moved all
retired files into `~/_to_delete/OA-ZYRA-316_TIER1_2026-10-29/`, preserving paths; nothing permanently deleted. Retired
12 active Guardian Detail screenshot baselines and the matching 12 promoted captures, plus 7 unapproved Notifications
captures. The 112 surviving active baselines and all 36 historical baselines retain their original bytes. No screenshot
was regenerated or re-approved. Five visual fixtures (19 render variants) belonged to the removed screens.

Six entries from the original 22-file list remain:

- `SOURCE/lib/dev/journey_experience_lab.dart`, `wali_dashboard_preview.dart`, `dev_app_icon_directions.dart` and
  `dev_splash_lab.dart`: Shakeel explicitly protected `SOURCE/lib/dev/` from Tier 1 changes.
- `SOURCE/lib/services/zyra_dev_app_icon.dart`: imported by the protected app-icon directions screen.
- `SOURCE/lib/data/onboarding_bank_contract.dart`: used by `SOURCE/tool/generate_onboarding_bank_sql_values.dart`,
  which regenerates the onboarding-bank SQL parity suite (OA-ZYRA-196). It is not unused tooling.

The old Seeker/Guardian shells, sign-in/onboarding/recovery routes, the Founder-only sample preview and
`PRODUCT/BLUEPRINT/` are unchanged. Tier 3 waits for OA-ZYRA-317. No server, migration, Tier 2 or Tier 4 change was made.
The developer-code reduction is the unused `screens/dev/moderation_review_queue_screen.dart`; no `lib/dev/` file changed.

Before this step the measured screenshot inventory was 3,380 / 403 MB, rather than the historical 3,984 / 467 MB above.
This step moved exactly 31 images. Pause/Restart counts use the existing broad non-developer-file search; they are not a
feature audit, and legitimate profile Pause may be included. Planned Request restart stays in the Founder preview.

Checks and commit are recorded in the 29 Oct daily task note. The exact source move inventory and hashes are in
`REPORTS/EVIDENCE/OA-ZYRA-316_TIER1_2026-10-29/removed_sources.json` (local evidence, not a source/build copy).
Remaining Tier 1 entries stay under OA-ZYRA-316 for Fable's review; no decision or action register was changed.
