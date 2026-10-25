# 124 — CODEX → FOUNDER

**Date:** 2026-09-17  
**Subject:** OA-ZYRA-289 harness repaired; functional replay remains gated  
**Decision / action:** DR-ZYRA-231 / OA-ZYRA-289  
**Status:** HARNESS REPAIRED; NOT EXECUTED; PRODUCTION UNCHANGED

## 1. Outcome

Under the Founder's bounded repair approval, Codex changed only
`SOURCE/supabase/tests/zyra_oa289_personal_code_guardian_requests_suite.sql`.
The harness no longer assumes seeded profiles. It creates one unique temporary
Seeker and one unique temporary Guardian in `auth.users` and `public.profiles`
inside the existing transaction. The existing product assertions are
unchanged, and the existing final `rollback` removes the actors and every row
created by the tested flow.

No migration, application source, production database, cloud service or replay
environment was changed or executed.

## 2. Exact artifact state

| Artifact | SHA-256 | State |
|---|---|---|
| 211-version union manifest | `997cc0a9473a9eb46e06e4e95261480b2d70b5f11abd6c67d1dd21befa9fc4b0` | unchanged evidence from Message 123 |
| `20260917133709_guardian_journey_summary_for_all_active_guardians.sql` | `886b3e0ff17b968f8575a976c32d338ee43a3c7e0372f5a491da6951c70b6c9c` | unchanged; staged only |
| `20260917144606_oa289_permanent_personal_codes_guardian_requests.sql` | `f214179184b8c13a95d52f088719b47e24037b73c6f53c3938918e386ed18575` | unchanged; staged only |
| OA-ZYRA-289 harness | `fa4da023e930603140939b8daa1e83a3a4e332d9c0becc951b6e2b680dc7a19c` | repaired; not executed |

## 3. Repair boundary

The removed code searched existing `profiles` rows and failed in a valid
seedless replay. The replacement:

1. generates two fresh UUIDs and unique `@zyra.test` addresses;
2. inserts Supabase-compatible authenticated user rows with randomly generated
   non-reusable password hashes;
3. inserts an eligible Seeker profile and Guardian profile; and
4. continues into the same code-format, safe-preview, request-without-link,
   owner-acceptance, relationship and exposure assertions.

The harness still begins with `begin;` and ends with `rollback;`. No fixture
can survive a successful run. The repair was reviewed against the current
`auth.users` seed shape and all current `profiles` constraints/triggers.

## 4. True pre-state ledger

| File | True pre-state SHA-256 | Post SHA-256 |
|---|---|---|
| OA-ZYRA-289 harness | `e1f04bc60b382dccbe36551ad7b506039e50eb336fd1c3320ac9f8f6dd971815` | `fa4da023e930603140939b8daa1e83a3a4e332d9c0becc951b6e2b680dc7a19c` |
| `OUTSTANDING_ACTIONS_V2.md` | `0dcb7786e6c30c56572c945640f7c16ae0ae87819b9dd1aca7be08860ece9adf` | `0ffd58535ebb1b85dbc4aa36566bfa18157779348f4874018e4d349c9a21d9e9` |
| Personal-code handover V1 | `89e5f6ce8e737d9fa69ca8211fdebd5e87268d14d8e4b97fc8162fc83052b252` | `5acfa3d35fd261ee8f6289835836b56565e08d889b8f7c878694b046c49bab7a` |
| Documentation index V4 | `0de0d5ac13a212a79997e1ceb2e0787c1c731d8de6392af3cdf8e71212a92790` | `69d7ec64f5a13a7643968d26075fc865acb64139c9ec54af49a76318215b6ef8` |

## 5. Next exact gate

A new Founder approval is required before execution. The bounded next action is
one fresh, seed-disabled, disposable PostgreSQL 17 replay using the unchanged
211-version union manifest
`997cc0a9473a9eb46e06e4e95261480b2d70b5f11abd6c67d1dd21befa9fc4b0`,
followed by exactly one execution of harness
`fa4da023e930603140939b8daa1e83a3a4e332d9c0becc951b6e2b680dc7a19c`.
No production access, repair or retry is included. Stop on the first drift or
failure and tear the disposable environment down.

This report is evidence, not self-approval and not an apply instruction.
