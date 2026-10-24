# 122 — CODEX → FOUNDER

**Date:** 2026-09-17  
**Subject:** OA-ZYRA-289 isolated replay stopped before reset  
**Decision / action:** DR-ZYRA-231 / OA-ZYRA-289  
**Status:** EXECUTION STOPPED AT FIRST FAILURE; AUTHORITY CONSUMED; NO RESET OR HARNESS

## 1. Outcome

The exact authorised run stopped at its first result. The Supabase CLI returned
exit 1 before creating or resetting a database:

`supabase start is not running.`

The reset command was invoked exactly once. No retry, repair, debug rerun,
database query, migration apply or OA-ZYRA-289 harness execution followed.
No production service or data was accessed.

## 2. Exact approved input

| Input | Verified identity |
|---|---|
| Current active migrations | 209 files / 209 unique versions |
| Active manifest | `75bf68f6802f0471cdca3b5325eedabbed014268fb6f462a73de85ec1ec9a6a8` |
| Question-bank V2 bridge | `337b342df347b7e902d8da32bafd0a2b21516550b9234213298079304ca66aa1` |
| Probe-score bridge | `9f9a818f3370b849ba1ff21f1d4ea9c3adb9ab866b22e15f6ba7a03454b46b46` |
| Scratch union | 211 files / 211 unique versions |
| Union manifest | `997cc0a9473a9eb46e06e4e95261480b2d70b5f11abd6c67d1dd21befa9fc4b0` |
| Staged `20260917133709` | `886b3e0ff17b968f8575a976c32d338ee43a3c7e0372f5a491da6951c70b6c9c` |
| Staged `20260917144606` | `f214179184b8c13a95d52f088719b47e24037b73c6f53c3938918e386ed18575` |
| OA-ZYRA-289 harness | `e1f04bc60b382dccbe36551ad7b506039e50eb336fd1c3320ac9f8f6dd971815` |

The scratch config selected PostgreSQL 17, disabled seed loading and had no
`seed.sql`. It used a fresh credential home and no project link, database URL,
access token or production credential.

## 3. Execution evidence

| Item | Evidence |
|---|---|
| Scratch root | `/private/tmp/zyra-oa289-replay.wBAftU` / mode 0700 |
| CLI | Supabase CLI 2.116.0 |
| Dedicated VM | `zyra-oa198`, started only for this run |
| Reset invocation | one |
| Reset exit | 1, before reset |
| Raw log | `/private/tmp/zyra-oa289-replay.wBAftU/reset.raw.log` |
| Raw log identity | 103 bytes / 2 lines / mode 0600 / `6732878aa4927bc7b2e0cd978fd0a9e9f7ab8139c3925d0a3d0dc71c174166e2` |
| Scratch config | 15,466 bytes / mode 0600 / `97a9e107c3bddb07b738e321c783bdfb9e1563778a2a7d811bcd0d0338c5a335` |

## 4. Teardown

The dedicated Docker socket showed no container carrying the scratch project
label and no network named `zyra-oa289-replay-wbaftu`. The named Colima VM was
then stopped successfully. Nothing listened on local database port 54322.
The scratch files and raw log are retained as evidence; no database exists.

## 5. Finding and next gate

The prior clean replay initialised an empty local Supabase stack **before**
copying the migration union, then ran one `db reset`. This run copied the
approved union first and called `db reset` against a stopped stack. Supabase
CLI 2.116.0 does not bootstrap that stopped stack through `db reset`.

A new single-use Founder GO is required. The corrected run must use a new
scratch root, initialise and start an empty isolated PostgreSQL 17 stack,
copy the exact approved 211-version union only after startup, invoke one reset,
then run the unchanged OA-ZYRA-289 harness once if reset succeeds. Any startup,
reset or harness failure stops the run with no retry or repair.

No app, migration, test or governed source byte changed during this attempt.

— END OF MESSAGE 122 —
