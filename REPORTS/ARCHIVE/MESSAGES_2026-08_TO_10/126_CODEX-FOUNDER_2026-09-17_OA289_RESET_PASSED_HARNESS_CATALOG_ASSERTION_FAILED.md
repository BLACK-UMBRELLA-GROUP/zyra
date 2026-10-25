# 126 — CODEX → FOUNDER

**Date:** 2026-09-17  
**Subject:** OA-ZYRA-289 reset passed; harness catalog assertion failed  
**Decision / action:** DR-ZYRA-231 / OA-ZYRA-289  
**Status:** RESET PASS 211/211; HARNESS FAILED; PRODUCTION UNCHANGED

## 1. Outcome

The corrected localhost-forwarded PostgreSQL 17 replay completed the one
authorised reset successfully. All 211 frozen migrations applied once, ending
with `20260917144606`.

The repaired OA-ZYRA-289 harness then executed exactly once. Its temporary
actors were created and it reached the final catalog exposure assertion, which
means the preceding permanent-code format, safe preview, request-without-link,
owner acceptance and governed `wali_links` assertions did not raise.

The final assertion failed because it queried a relation PostgreSQL does not
provide:

`relation "information_schema.routine_columns" does not exist`

The harness transaction aborted and was rolled back. No repair, retry,
post-failure database query or production access followed. The disposable
stack and dedicated VM were removed.

## 2. Exact inputs and results

| Item | Identity / result |
|---|---|
| Frozen union manifest | `997cc0a9473a9eb46e06e4e95261480b2d70b5f11abd6c67d1dd21befa9fc4b0` |
| Union copy | 211 SQL files; recursive byte comparison against the previously proven union returned no differences |
| Question-bank V2 bridge | `337b342df347b7e902d8da32bafd0a2b21516550b9234213298079304ca66aa1` |
| Probe-score bridge | `9f9a818f3370b849ba1ff21f1d4ea9c3adb9ab866b22e15f6ba7a03454b46b46` |
| `20260917133709` | `886b3e0ff17b968f8575a976c32d338ee43a3c7e0372f5a491da6951c70b6c9c` |
| `20260917144606` | `f214179184b8c13a95d52f088719b47e24037b73c6f53c3938918e386ed18575` |
| Harness | `fa4da023e930603140939b8daa1e83a3a4e332d9c0becc951b6e2b680dc7a19c` |
| Reset | exit 0; terminal `Finished supabase db reset on branch main.` |
| Harness | one execution; exit 3 at final catalog assertion |

## 3. Evidence and teardown

| Evidence | Identity |
|---|---|
| Scratch root | `/private/tmp/zyra-oa289-replay-final-20260917-b` / mode 0700 |
| Start log | 1,521 bytes / 6 lines / `4f5b6342257e2167e19948a01fd7e54200eb4d148b535239e24f09c9b070a30f` |
| Reset log | 16,674 bytes / 220 lines / `d12b8623a741b3b48d61fc32ba4b3d8010eb3514baed20872a08176facd90c9e` |
| Harness log | 469 bytes / 11 lines / `4cf1ff823d5f078cf3d3fea5ae64bf653ada1d95ecb4fefef1998e65dac755cb` |
| Scratch config | `bd976a75d1753730d20db3274d543e5bc4ad0a762a2680fbfe34181b6d591388` |
| Stack teardown | `supabase stop --no-backup`, exit 0 |
| VM teardown | `colima stop --profile zyra-oa198`, exit 0 |
| Dedicated Docker socket after stop | absent |

## 4. True pre-state ledger

| File | True pre-state SHA-256 | Post SHA-256 |
|---|---|---|
| `OUTSTANDING_ACTIONS_V2.md` | `8b58f85a248aaaca6c07692b7b0d36c71808d2f9e67fc0675fc2f76713dd6482` | `e0690a73e4184beff5a3778bb24a8d6cfd2c1657467bb160545a709dfb4c1a8a` |
| Personal-code handover V1 | `2be69ef8a24408a768a3de19a1660142c4a6dba7303b12a7fe8a72a2fe7db196` | `48d420ceb84c4bfbf849869814430917d622f81129fd41f02239ff8fd3a8b085` |
| Documentation index V4 | `de7fb16aa39dfdbad91970c14ac51486721fbd52ef42a564271b939cf29b9fba` | `91ffae19f60db78aaa5f257e5948fe8deedcdf91a8ee1b1613061af295d8ea85` |

## 5. Next exact gate

The smallest repair is harness-only: replace the unsupported
`information_schema.routine_columns` query with a supported catalog assertion
that proves the function exposes exactly two output fields,
`owner_first_name text` and `owner_role text`. Product assertions, migration,
application source and production remain untouched.

That edit needs a separate Founder approval and new harness SHA-256. A later
replay also needs its own exact approval; this result authorises neither.

— END OF MESSAGE 126 —
