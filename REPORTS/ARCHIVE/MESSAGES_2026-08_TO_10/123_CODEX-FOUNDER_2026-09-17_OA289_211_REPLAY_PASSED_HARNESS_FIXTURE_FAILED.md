# 123 — CODEX → FOUNDER

**Date:** 2026-09-17  
**Subject:** OA-ZYRA-289 211-version replay passed; harness fixture failed  
**Decision / action:** DR-ZYRA-231 / OA-ZYRA-289  
**Status:** RESET POST-VERIFIED; HARNESS FAILED; PRODUCTION REMAINS UNCHANGED

## 1. Outcome

The corrected isolated PostgreSQL 17 run reached both authorised stages:

1. the exact 211-version reset passed and applied every version once; and
2. the unchanged OA-ZYRA-289 harness was executed exactly once, then failed
   before its product assertions because the seedless database contained no
   eligible Seeker/Guardian pair.

The harness error was:

`OA289 suite needs one eligible Seeker/Guardian pair`

No SQL repair, harness edit, retry, post-failure database query, production
access, production mutation, app install, TestFlight action or git operation
followed. The scratch stack and VM were torn down.

## 2. Exact input and reset result

| Input | Verified identity |
|---|---|
| Current active migrations | 209 files / 209 unique versions |
| Question-bank V2 bridge | `337b342df347b7e902d8da32bafd0a2b21516550b9234213298079304ca66aa1` |
| Probe-score bridge | `9f9a818f3370b849ba1ff21f1d4ea9c3adb9ab866b22e15f6ba7a03454b46b46` |
| Scratch union | 211 files / 211 unique versions |
| Union manifest | `997cc0a9473a9eb46e06e4e95261480b2d70b5f11abd6c67d1dd21befa9fc4b0` |
| `20260917133709` | `886b3e0ff17b968f8575a976c32d338ee43a3c7e0372f5a491da6951c70b6c9c` |
| `20260917144606` | `f214179184b8c13a95d52f088719b47e24037b73c6f53c3938918e386ed18575` |
| OA-ZYRA-289 harness | `e1f04bc60b382dccbe36551ad7b506039e50eb336fd1c3320ac9f8f6dd971815` |
| Database image | `public.ecr.aws/supabase/postgres:17.6.1.165` |
| Reset result | exit 0; 211 apply markers; terminal success |

The stack was initialised with zero ZYRA migrations, PostgreSQL major version
17 and seed disabled. Only after startup succeeded was the exact union copied
in. The single reset ended with:

`Finished supabase db reset on branch main.`

The final six applied versions included both bridges' successor chain, both
September 10 migrations and the two September 17 staged migrations. The
permanent-code migration was the 211th and final applied version.

## 3. Harness result

The harness began a transaction and stopped at line 93 while selecting its
pre-existing eligible pair. A seedless replay does not guarantee profile rows,
so the harness never reached code minting, preview, request or acceptance
assertions. This is a harness-fixture defect; the successful reset proves SQL
application and ordering, but it does not prove the new behaviour.

The correct next change is bounded: make the harness create and roll back its
own eligible Seeker/Guardian actors, without changing the migration. That
revision and any new replay require a new hash and new Founder GO.

## 4. Execution evidence

| Evidence | Identity |
|---|---|
| Scratch root | `/private/tmp/zyra-oa289-replay-corrected.NJ03vH` / mode 0700 |
| Start log | 11,157 bytes / 230 lines / mode 0600 / `0ba9fe84a441c56b1adf29070b7b2837d2744ba25e20c8d3c549042aca28d1de` |
| Reset log | 16,602 bytes / 217 lines / mode 0600 / `88d802535cb5375a3410ed719be85c44825b16ef055b321b894db497c8adbe9c` |
| Harness log | 171 bytes / 3 lines / mode 0600 / `182199d9cfc175aab343ba5fccb5a437104753f3e89718ec0f100108b1a7f246` |
| Scratch config | 15,476 bytes / `1df9325b971158ffe71c818927c364a33781d73ed91f8b86c110a6c70891e3c3` |

The start log contains only disposable local-development credentials and is
retained mode 0600. No credential value is copied into governed records.

## 5. Teardown and gate state

`supabase stop --no-backup` removed the scratch stack. Docker then returned no
container carrying the scratch project label and no matching disposable
network. The dedicated `zyra-oa198` Colima VM stopped successfully.

The single-use authority is consumed. Migration `20260917144606` remains
staged and unapplied in production. OA-ZYRA-289 remains open; Codex does not
self-approve it.

## 6. Governance file ledger

| File | True pre-state SHA-256 | Post SHA-256 |
|---|---|---|
| `OUTSTANDING_ACTIONS_V2.md` | `38f67ca1794aa2dadf7bc8257fefd10fc344251136774dacf8f03bf799a63d78` | `0dcb7786e6c30c56572c945640f7c16ae0ae87819b9dd1aca7be08860ece9adf` |
| Personal-code handover V1 | `354bb3ce8cb223165f7684f6c1707090effbbf5d9f74fdb5d29035281815d63a` | `89e5f6ce8e737d9fa69ca8211fdebd5e87268d14d8e4b97fc8162fc83052b252` |
| Documentation index V4 | `ddca175e2df377129e2dedcf29ffeddb6fe77c6156aeb726908688f81910b576` | `0de0d5ac13a212a79997e1ceb2e0787c1c731d8de6392af3cdf8e71212a92790` |
| This message 123 | absent | new filing; self-hash is recorded externally |

— END OF MESSAGE 123 —
