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
| All app code | 161,734 lines in 320 files |
| Developer and preview code inside it | 43,364 lines in 81 files |
| The Founder preview (planned app) | 24,336 lines in 31 files |
| Test code | 205,402 lines in 461 files |
| Test screenshots (goldens) | 2,638 images, 313 MB |
| Old-app files that still mention Pause | 39 |
| Old-app files that still mention Restart | 1 |

## History

| Date | Step | All app code | Developer + preview | Founder preview | Test code | Goldens | Pause files | Restart files |
|---|---|---|---|---|---|---|---|---|
| 2026-10-25 | Baseline, before any clean-up (OA-ZYRA-316) | 171,658 / 342 | 46,429 / 87 | 24,701 / 31 | 207,814 / 464 (counted 26 Oct) | 3,984 / 467 MB (counted 26 Oct) | 40 | 2 |
| 2026-10-29 | OA-ZYRA-316 Tier 1: 16 unused files removed; 6 retained by scope/dependencies | 167,819 / 326 | 46,118 / 86 | 24,701 / 31 | 206,100 / 459 | 3,349 / 401 MB | 39 | 2 |
| 2026-10-29 | OA-ZYRA-316 Tier 1 remainder: 5 named files removed; onboarding bank retained | 165,953 / 321 | 44,446 / 82 | 24,701 / 31 | 205,716 / 458 | 3,337 / 399 MB | 39 | 2 |
| 2026-10-29 | OA-ZYRA-316 Tier 2: app-side Journey Pause/Save and obsolete restart stub removed | 165,631 / 321 | 44,178 / 82 | 24,433 / 31 | 205,291 / 458 | 3,337 / 399 MB | 39 | 1 |
| 2026-10-29 | Queued baseline capture: four test files; app source unchanged | 165,631 / 321 | 44,178 / 82 | 24,433 / 31 | 207,177 / 462 | 3,337 / 399 MB | 39 | 1 |
| 2026-10-29 | OA-ZYRA-316 Tier 4: 92 unchosen options removed; selected design retained | 161,734 / 320 | 43,364 / 81 | 24,336 / 31 | 205,723 / 461 | 3,337 / 399 MB | 39 | 1 |
| 2026-10-29 | OA-ZYRA-316 matching tests/screenshots: 28 obsolete cases and 699 old captures retired | 161,734 / 320 | 43,364 / 81 | 24,336 / 31 | 205,402 / 461 | 2,638 / 313 MB | 39 | 1 |

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

## Note 29 Oct 2026 (Fable, from the ZYRA chat note (h))

The historical golden baseline in this tracker (3,984 files / 467 MB) differs from the figure Codex measured before Tier 1 of OA-ZYRA-316 (3,380 files / 403 MB). The difference is the evidence copies moved to `_to_delete` on 27 Oct (OA-AIOS-405) and git-ignored build output; neither is app code. From Tier 1 onwards the tracker uses Codex's measured figures, with the code-size table in each task note (standard §3).


## Tier 1 remainder — 29 Oct 2026

Founder clarified that the protection covers the Founder preview, and explicitly named five further removals: the four
previously retained developer labs/gallery files plus `services/zyra_dev_app_icon.dart`. They and their matching
test/gallery captures moved to `~/_to_delete/OA-ZYRA-316_TIER1_REMAINDER_2026-10-29/`. Removed 1,866 source lines,
one visual suite and 12 candidate PNGs (2,358,031 bytes), plus obsolete cases in six mixed suites. All seven native
icon/asset checks, HomeTools and live splash-motion coverage remain. Native assets/configuration and the icon artwork
generator are unchanged. Only `onboarding_bank_contract.dart` remains from the original 22-file list because active
tooling uses it. Founder preview and old member routes are byte-identical. Analyser clean; 71 focused tests pass.

## Tier 2 — 29 Oct 2026

Removed dormant Journey Pause/Resume state, Save model/storage and hidden UI paths from the Founder preview and shared
presentation files; removed the unreferenced always-throwing restartJourney stub and its unused exception. Live callers
already hid Save. Planned Request restart, End/history, ownership guards, account/profile Pause and ordinary member
sign-in routes remain. No old-app-only file or backend changed. Nine source files lose 322 lines; minimal API fixture
adaptations retain active coverage. Historical photo-dismiss fixtures expecting a direct vertical drag predate this task
and are carried to the separate matching-tests cleanup under OA-ZYRA-316; current edge/back behavior is unchanged.
Preview Timeline examples also exclude the retired Pause/continue events; canonical old-app history vocabulary stays.
Analyser clean (3.7s); 42 focused suites, 21 Timeline cases and two retained photo/delegate cases were checked.
Count correction: the historical 1,055 total included 94 hidden harness events (961 visible cases). The final combined
Tier 4 run below supplies saved passing evidence for the affected Tier 2 suites as well.
No screenshot regenerated. Exact paths/checks are in local Tier2 JSON evidence and the daily task note.

## Queued baseline capture — 29 Oct 2026

Capture-only queue line 2 adds four visual harness/test files (1,886 lines); app source is unchanged. The 301 full-phone
PNG review inputs live in PRODUCT/APPROVED/BASELINE/SCREENSHOTS (260,375,095 bytes), outside this tool's SOURCE/test
golden count. Actual production theme, iOS target, local portraits and platform glyph fallback were verified. The
generated index accounts for all 49 page IDs in both roles and all nine root tabs; legacy Notifications has no opener,
and Saved/Paused are retired. No LOCK or product design is created by this capture.
## Tier 4 — 29 Oct 2026

Kept the selected design in each of 17 sets: 49 of 141 choices, removing 92 unchosen choices. Founder explicitly chose
current Glass Signals over the stale Classic Glass line in DR-ZYRA-276. All ten dark backgrounds, eighteen fonts and
seven navigation styles remain in developer tools. All 31 Founder preview files remain, including the current Portrait
split large-text fallback. Ordinary member routing, account Pause, services and backend are unchanged.

Thirty-one source paths lose 3,897 lines (one retired menu module moved to ~/_to_delete). Required fixture adaptations
and its dedicated visual suite move close removed APIs; PNG retirement follows as a separate task. Full analyser clean
(4.2s). Across 96 affected suites, 1,798 visible cases pass after replacing the stale Browse-label suite with its passing
retry; hidden harness events are excluded. Another 26 manifest/navigation cases pass. All 261 compared chosen PNGs
match the pre-cleanup baseline exactly; 20 changed developer panels are intentionally excluded. All 303 baseline
artifacts remain byte-identical. Source hashes and counts are in local Tier4 evidence. No screenshot regeneration,
backend, Blueprint or Tier3 change. Tier3 still waits for OA-ZYRA-317.

## Matching test and screenshot retirement — 29 Oct 2026

Removed 28 obsolete direct-vertical-drag/Transform photo-dismiss cases and their unused helpers (321 test lines),
retaining both valid photo/delegate cases and current owned-edge/back-route coverage. Moved 699 positively mapped
unchosen captures (90,249,038 bytes): 343 non-Luma onboarding, 21 retired splash, 166 Classic Glass, 78 menu/role/network,
and 91 old light-only outputs. Ambiguous screenshots stay. All 2,638 surviving test PNGs retain their original hashes;
112 active and 36 archived approved baselines and both approval manifests are untouched.

Also moved 20 explicitly unchosen Circle captures from the queued review packet: 301 original, 281 retained. INDEX and
BUILD record retirement while preserving the capture commit and original evidence rows; all retained PNG bytes stay.
The 20 developer-panel pictures are marked historical before the option lists shortened. Total 719 moved PNGs,
102,090,028 bytes, under ~/_to_delete/OA-ZYRA-316_TIER4_TESTS_2026-10-29/. No image regenerated, design approved or
app source changed. Full analyser clean (4.1s); 186 cases across five photo/back-route suites and five approval-manifest
cases pass. Exact inventories, move hashes and audits are in local Tier4_TESTS evidence. Tier3 waits for OA-ZYRA-317.

Historical candidate-only manifest SYSTEM/tools/ui_gate/CANDIDATES/manifest.json still records 87 moved outputs
(66 Classic Glass and 21 light navigation). It is not an active approval record and remains unchanged. The exact
original-path-to-destination mapping and hashes are in
REPORTS/EVIDENCE/OA-ZYRA-316_TIER4_TESTS_2026-10-29/png_move_receipt.json; the candidate-reference audit records these
87 references. This preserves promotion history without presenting retired pictures as active baselines.
