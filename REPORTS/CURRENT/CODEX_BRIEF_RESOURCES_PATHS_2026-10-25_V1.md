---
id: DOC-ZYRA-0275
type: GUIDE
status: CURRENT
feature: REPORTS
purpose: Codex brief - change every code and test path that points into ZYRA SYSTEM/RESOURCES, move those folders to their new homes, run every affected test
links: [OA-AIOS-408, OA-AIOS-406, DOC-ZYRA-0274]
owner: Fable
---

# CODEX BRIEF — ZYRA `SYSTEM/RESOURCES` PATH FIXES — 2026-10-25 — V1

**OA:** OA-AIOS-408 (part of OA-AIOS-406 phase 4). **Plan:** DOC-ZYRA-0274
`ZYRA/REPORTS/CURRENT/ZYRA_RESTRUCTURE_PLAN_2026-10-25_V1.md`. **Brief by:** Fable.
**GO:** only when Shakeel pastes this brief to you. Build freeze applies: this is an approved
fix, **paths only — no behaviour, design or feature change**.

## Rules for this job

1. No git. Never delete — `mv` only; anything unwanted goes to `~/_to_delete/2026-10-25_codex_resources/`.
2. Change paths and the comments that name them. Nothing else. If a change needs more than a
   path, stop and report it instead.
3. Read first: `ZYRA/AGENTS.md`, then `ZYRA/MAP.md`, then the plan DOC-ZYRA-0274. Nothing else is needed.
4. Run the tests from outside the repo folders where a test makes temporary folders (lesson F9).

## 1. Where each folder goes

| From `ZYRA/SYSTEM/RESOURCES/` | To | |
|---|---|---|
| `UI_GATE/` | `ZYRA/SYSTEM/tools/ui_gate/` | tool state lives with its tools |
| `MARKETING_COMMAND_CENTER/` | `ZYRA/SYSTEM/tools/state/marketing_center/` | |
| `MIGRATION_HISTORY/` | `ZYRA/REPORTS/EVIDENCE/OA-ZYRA-198_2026-09-11/` | keep the sub-folders and every byte unchanged |
| `MESSAGES/` | `ZYRA/REPORTS/ARCHIVE/MESSAGES_2026-08_TO_10/` | |
| `REPORTS/` | June/July files → `ZYRA/REPORTS/ARCHIVE/`; the rest → `ZYRA/REPORTS/CURRENT/` | |
| `SUBSCRIPTION_REVIEW_2026-08-26/` | `ZYRA/REPORTS/ARCHIVE/SUBSCRIPTION_REVIEW_2026-08-26/` | |
| `REVIEWS/` (3.9 GB, not in git) | `ZYRA/REPORTS/EVIDENCE/` (each run folder keeps its name) | `.gitignore`: replace `SYSTEM/RESOURCES/REVIEWS/` with `REPORTS/EVIDENCE/` |

Then `SYSTEM/RESOURCES/` should be empty: move the empty folder to `~/_to_delete/…` and remove the
`SYSTEM/RESOURCES/TEMPORARY/` line from `.gitignore`.

## 2. Every place to change (found 25 Oct — re-search before you start)

| File | Lines (25 Oct) | Points at |
|---|---|---|
| `ZYRA/SOURCE/tools/zyra_ui_gate.py` | 18, 39 | UI_GATE |
| `ZYRA/SOURCE/tools/zyra_visual_gate.py` | 34 | UI_GATE |
| `ZYRA/SOURCE/tools/zyra_ui_inventory.py` | 6, 28 | UI_GATE |
| `ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart` | 1481, 1632, 1724 | UI_GATE |
| `ZYRA/SOURCE/lib/theme/zyra_colors.dart` | 218 (comment) | UI_GATE |
| `ZYRA/SOURCE/lib/dev/zyra_dev_scenario.dart` | 2220 (comment) | OVERNIGHT_GN — **already moved** by Fable to `ZYRA/REPORTS/ARCHIVE/OVERNIGHT_GN_2026-08-23/` |
| `ZYRA/SYSTEM/tools/zyra_marketing_center.py` | 32 | MARKETING_COMMAND_CENTER |
| `ZYRA/SOURCE/test/zyra_oa198_replay_bridge_artifact_test.dart` | 10 | MIGRATION_HISTORY |
| `ZYRA/SOURCE/test/zyra_oa198_probe_score_replay_bridge_artifact_test.dart` | 9 | MIGRATION_HISTORY |
| `ZYRA/SOURCE/test/zyra_oa198_replay_bridge_v2_artifact_test.dart` | 9, 24 | MIGRATION_HISTORY, MESSAGES |
| `MIGRATION_HISTORY/*/manifest.json` (3) | message paths inside | MESSAGES — if a test checks these paths exist, report it; do not edit a file whose hash a test pins |
| `ZYRA/SOURCE/tooling/local_ios_overlay.mjs` | 70, 177 | REVIEWS (writes) |
| `ZYRA/SOURCE/tooling/verified_host_profile.mjs` | 12 | REVIEWS |
| `ZYRA/SOURCE/test/membership_wallet_visual_test.dart` | 23 | REVIEWS — absolute `/Users/…` path |
| `ZYRA/SOURCE/test/zyra_subscription_wallet_preview_test.dart` | 1080 | REVIEWS — absolute path to one run |
| `ZYRA/SOURCE/test/zyra_profile_details_first_test.dart` | 183 | REVIEWS — absolute path pattern |
| `ZYRA/SYSTEM/tools/test_generate_doc_index.py` | 145, 157 | REVIEWS in a fixture string — update to `REPORTS/EVIDENCE` only if the test meaning stays the same |
| `BLACK UMBRELLA GROUP/AIOS/workspace_home.py` | 66 | UI_GATE |
| `BLACK UMBRELLA GROUP/AIOS/test_ui_consistency_dashboard.py` | 29 | UI_GATE |
| `BLACK UMBRELLA GROUP/AIOS/workspace_schedule_hub.py` | 191–198 | ZYRA and group `RESOURCES/REPORTS` — read the new homes (`ZYRA/REPORTS/CURRENT`, `ZYRA/REPORTS/ARCHIVE`); **keep the old prefixes resolving** to the new places so saved schedule records still open |
| `BLACK UMBRELLA GROUP/AIOS/test_workspace_schedule_hub.py` | 593–594 | as above |
| `BLACK UMBRELLA GROUP/AIOS/workspace_clean.py` | 130, 136 | ZYRA RESOURCES/REPORTS → ZYRA/REPORTS |
| `BLACK UMBRELLA GROUP/AIOS/test_workspace_clean.py` | 361 | as above |
| `BLACK UMBRELLA GROUP/AIOS/subscription_review_engine.py` | 36, 85 | SUBSCRIPTION_REVIEW → future runs write `ZYRA/REPORTS/CURRENT/SUBSCRIPTION_REVIEW_<date>/` |
| `BLACK UMBRELLA GROUP/AIOS/subscription_review_harness.py` | 67 | as above |
| `BLACK UMBRELLA GROUP/AIOS/overnight_engine.py` | 653, 1323 | future runs write `ZYRA/REPORTS/CURRENT/<NAME>_<date>/` |
| `BLACK UMBRELLA GROUP/AIOS/overnight_engine_harness.py` | 275 | as above |

**Tests that read evidence by absolute path** (the three REVIEWS tests): evidence leaves the Mac
for the USB after 30 days (Saving Standard), so these will fail by late November. Use a path
relative to `SOURCE/` (`../REPORTS/EVIDENCE/…`) now, and **report** — do not fix — what each test
would need to stop depending on evidence (e.g. a small fixture in `SOURCE/test/fixtures/`).
Shakeel decides that separately.

The group folder's own `BLACK UMBRELLA GROUP/SYSTEM/RESOURCES/REPORTS/` (31 ZYRA reports) is **not**
part of this job — it belongs to OA-AIOS-397. Only keep `workspace_schedule_hub.py` able to read it.

## 3. Checks you run and report (exact command, result)

| Check | Expected |
|---|---|
| `grep -rn "SYSTEM/RESOURCES" ZYRA/SOURCE ZYRA/SYSTEM/tools "BLACK UMBRELLA GROUP/AIOS"` (excluding WORKSPACE_DATA records) | only the deliberate old-prefix mapping in the schedule hub |
| AIOS: `python3 -m unittest discover -s . -p "test_*.py"` in `AIOS/` | 126 pass |
| ZYRA `SYSTEM/tools` tests | 37 pass |
| ZYRA `SOURCE/tools` tests (from a scratch folder) | 6 pass |
| `flutter analyze` via the project's own tooling | no new issues |
| `flutter test` for the 7 Dart test files named above | pass, or report exactly which and why |
| The OA-ZYRA-198 replay-bridge tests | pass with **unchanged** hashes |
| `ls ZYRA/SYSTEM/` | no `RESOURCES/` |

## 4. Hand back

One handover message to Fable: every file changed (path, old → new), every folder moved, every
check with its output line, anything you stopped on. Then Fable verifies, updates the map and
.mapignore, and Shakeel commits ZYRA and BLACK UMBRELLA GROUP.
