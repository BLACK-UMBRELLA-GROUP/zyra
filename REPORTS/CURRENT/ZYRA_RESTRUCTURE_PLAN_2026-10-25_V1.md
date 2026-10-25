---
id: DOC-ZYRA-0274
type: PLAN
status: DRAFT
feature: REPORTS
purpose: Where each folder in SYSTEM/RESOURCES should live under the app foundation layout, what reads it, and which moves need a code-path fix first
links: [OA-AIOS-406, OA-AIOS-397]
owner: Fable
---

# ZYRA RESTRUCTURE PLAN — SYSTEM/RESOURCES — 2026-10-25 — V1

**Why:** the Knowledge Routing Standard (DOC-BUG-0001 §9) says a repo has no `RESOURCES/` or
`TEMPORARY/` folder: anything without a home is a report, evidence, tool state or junk.
ZYRA's `SYSTEM/RESOURCES/` holds 11 folders, ~4 GB, ~28,600 files. It is left out of `MAP.md`
until it is rehomed. Nothing moves until the Founder approves this plan (lesson F1: check what
reads a folder before moving it — done below).

## The folders

| # | Folder | Size | Why it was made | What reads it today | Proposed home | Code fix needed? |
|---|---|---|---|---|---|---|
| 1 | `BRAND/` | 11 files, 1.5 MB (29 Aug) | Avatar/comet animation options for the app logo | Nothing | `BUSINESS/APP LOGO/ASSETS/` | No |
| 2 | `MARKETING_COMMAND_CENTER/` | `state.json` (25 Sep) | State file of the marketing command centre tool | `SYSTEM/tools/zyra_marketing_center.py` (DEFAULT_DATA_DIR) | `SYSTEM/tools/state/marketing_center/` | **Yes** — 1 path |
| 3 | `MEMORY/` | 2 JSON, 44 KB (Jun–Jul) | Run memory of the old AIOS agent runs | Nothing | `REPORTS/ARCHIVE/2026-07_AIOS_RUN_MEMORY/` | No |
| 4 | `MESSAGES/` | 170 files, 1.5 MB (Aug–Oct) | The Fable↔Codex↔Founder relay mailbox under the old model | 1 Flutter test (`zyra_oa198_replay_bridge_v2_artifact_test.dart`) and 3 manifests in #5 | `REPORTS/ARCHIVE/MESSAGES_2026-08_TO_10/` | **Yes** — 1 test path |
| 5 | `MIGRATION_HISTORY/` | 13 files, 144 KB (Aug–Sep) | OA-ZYRA-198 reconstructed replay-bridge evidence | 3 Flutter tests pin these files byte for byte | `REPORTS/EVIDENCE/OA-ZYRA-198_2026-09-11/` | **Yes** — 3 test paths (manifests keep their hashes) |
| 6 | `OVERNIGHT_GN_2026-08-23/` | 41 files, 1 MB | Overnight guardian-network debate and drafts | A code comment in `zyra_dev_scenario.dart`; AIOS overnight job record (history) | `REPORTS/ARCHIVE/OVERNIGHT_GN_2026-08-23/` | No (comment updated later) |
| 7 | `REPORTS/` | 7 files, 60 KB (Jun–Oct) | Schedule-run and escalation reports | **AIOS schedule hub** (`workspace_schedule_hub.py`), `workspace_clean.py` and their tests | June/July files → `REPORTS/ARCHIVE/`; the rest → `REPORTS/CURRENT/` | **Yes** — AIOS schedule hub + clean + 2 tests (the "schedule-hub fix" in OA-AIOS-397) |
| 8 | `REVIEWS/` | **415 runs, 3.9 GB, 28,181 files** (Sep–Oct; not in git) | Review evidence: screenshots, run receipts, verification JSON | 2 tooling scripts **write** here (`local_ios_overlay.mjs`, `verified_host_profile.mjs`); 3 Flutter tests hard-code `/Users/…/REVIEWS/…` | New runs → `REPORTS/EVIDENCE/`; runs older than 30 days → USB `ZYRA BACKUP` (Saving Standard) | **Yes** — 2 scripts + 3 tests |
| 9 | `SUBSCRIPTION_REVIEW_2026-08-26/` | 14 files, 296 KB | Fable/Codex subscription debate output | AIOS `subscription_review_engine.py` (OUT_DIR) | `REPORTS/ARCHIVE/SUBSCRIPTION_REVIEW_2026-08-26/` | **Yes** — 1 AIOS constant (engine is in the AIOS review) |
| 10 | `TEMPORARY/` | empty | Scratch space | Nothing (the doc-index test only uses the word in a fixture) | `_to_delete` | No |
| 11 | `UI_GATE/` | 145 files, 6.3 MB | State, baselines and reports of the UI consistency gate | 3 `SOURCE/tools` scripts, the visual regression test, AIOS `workspace_home.py` and its test; a code comment in `zyra_colors.dart` | `SYSTEM/tools/ui_gate/` (tool state lives with its tools) | **Yes** — 3 scripts, 1 test, AIOS home + test |
| — | `.DS_Store` | — | macOS | — | `_to_delete` | No |

## Order

| Step | What | Who | Needs |
|---|---|---|---|
| 1 | Move #1, #3, #6, #10 and `.DS_Store` (nothing reads them) | Fable | Founder GO |
| 2 | One Codex brief: change the paths for #2, #4, #5, #7, #8, #9, #11, run every affected test, then Fable moves the folders and re-runs the tests | Codex, then Fable | Founder GO on the brief (an approved fix under the build freeze) |
| 3 | REVIEWS runs older than 30 days → USB | Fable | USB plugged in |
| 4 | `SYSTEM/RESOURCES/` removed; `.mapignore` line dropped; the moved documents get headers; MAP regenerated | Fable | — |

After step 4 ZYRA matches the app foundation (`BLACK UMBRELLA GROUP/SYSTEM/TEMPLATES/APP_FOUNDATION`).
