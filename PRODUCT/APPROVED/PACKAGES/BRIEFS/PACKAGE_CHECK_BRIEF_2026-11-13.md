---
id: DOC-ZYRA-0509
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex brief - first monthly package check (read-only report of outdated and flagged packages) and pin the Flutter version in a file
links: [AD-AIOS-149, DOC-BUG-0060]
owner: Fable
---

# BRIEF — MONTHLY PACKAGE CHECK (FIRST RUN) — 13 NOV 2026

**Why.** ZYRA audit F-30 (Founder 13 Nov, "Yes, file them all"; OA-ZYRA-386): 171 packages and no update
routine, so security fixes can be missed. This line is the first monthly check. Later months get a new
dated brief and line from Fable's 04:15 review on the 1st; this brief is never reused.

**Rules.** No package is upgraded, added or removed. No install or download beyond what the two commands
below fetch to compare versions (F33). If a command would change `pubspec.lock` or install anything, stop
and file a QUESTION. Disk stop line 15 GB free (AD-AIOS-149).

## Steps

1. In `SOURCE/`: `flutter --version` and `flutter pub outdated --json`. Keep `pubspec.yaml` and
   `pubspec.lock` unchanged (`git diff --quiet` on both).
2. Write `SOURCE/.flutter-version` containing only the Flutter version in use (for example `3.38.1`).
   Nothing reads it yet; it records which Flutter the app is built with.
3. Write the report `REPORTS/CURRENT/PACKAGE_CHECK_2026-11.md`, one table: package · in use · newest ·
   discontinued or retracted (yes/no) · direct or transitive. Top lines: Flutter version, count of
   outdated direct packages, every discontinued or retracted package named.
4. For each discontinued, retracted or security-flagged direct package, file one QUESTION row
   (owner Fable) with the package and what replaces it. Do not fix it in this line.

## Done when

`.flutter-version` exists; the report exists; `pubspec.yaml` and `pubspec.lock` are unchanged; any flagged
package has a QUESTION row. Task note: start_pack bytes, the two command outputs' summary lines, files written.
