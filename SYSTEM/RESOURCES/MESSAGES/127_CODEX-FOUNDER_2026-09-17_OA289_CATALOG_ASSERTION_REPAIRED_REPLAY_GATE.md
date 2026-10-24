# 127 — CODEX → FOUNDER

**Date:** 2026-09-17  
**Subject:** OA-ZYRA-289 catalog assertion repaired; replay gated  
**Decision / action:** DR-ZYRA-231 / OA-ZYRA-289  
**Status:** HARNESS REPAIRED; NOT RE-RUN; PRODUCTION UNCHANGED

## 1. Outcome

Under the Founder's bounded approval, Codex changed only the final output-shape
assertion in
`SOURCE/supabase/tests/zyra_oa289_personal_code_guardian_requests_suite.sql`.

The nonexistent `information_schema.routine_columns` reference is gone. The
replacement targets the exact
`public.zyra_preview_personal_code(text)` function through
`pg_catalog.pg_proc`, expands all arguments through supported
`pg_catalog.unnest`, filters output modes and requires this exact ordered
contract:

1. `owner_first_name text`
2. `owner_role text`

Zero, extra, renamed, reordered or differently typed outputs now fail closed.
The temporary-actor fixture and every product assertion remain unchanged.

## 2. Exact artifact state

| Artifact | SHA-256 | State |
|---|---|---|
| Frozen 211-version union | `997cc0a9473a9eb46e06e4e95261480b2d70b5f11abd6c67d1dd21befa9fc4b0` | unchanged |
| `20260917133709` | `886b3e0ff17b968f8575a976c32d338ee43a3c7e0372f5a491da6951c70b6c9c` | unchanged; staged only |
| `20260917144606` | `f214179184b8c13a95d52f088719b47e24037b73c6f53c3938918e386ed18575` | unchanged; staged only |
| OA-ZYRA-289 harness | `731936de8004c89767f0e9ac952619f1c46bb966d09960ff5df29458a0818018` | catalog assertion repaired; not executed |

## 3. True pre-state ledger

| File | True pre-state SHA-256 | Post SHA-256 |
|---|---|---|
| OA-ZYRA-289 harness | `fa4da023e930603140939b8daa1e83a3a4e332d9c0becc951b6e2b680dc7a19c` | `731936de8004c89767f0e9ac952619f1c46bb966d09960ff5df29458a0818018` |
| `OUTSTANDING_ACTIONS_V2.md` | `e0690a73e4184beff5a3778bb24a8d6cfd2c1657467bb160545a709dfb4c1a8a` | `f1082d582fc7df78d6e4b94cd1dd98330c87bf324924ba0ed856017fdcd8d591` |
| Personal-code handover V1 | `48d420ceb84c4bfbf849869814430917d622f81129fd41f02239ff8fd3a8b085` | `de7368aed68b0606e7fe1932dd79dec9f668273c1581816cdd24e86e2f835961` |
| Documentation index V4 | `91ffae19f60db78aaa5f257e5948fe8deedcdf91a8ee1b1613061af295d8ea85` | `49c20805c1bfd2f3ec38d6b98ff05843786177e6f0aff8cd2ee156b71a98a805` |

## 4. Verification boundary

Static inspection confirms:

- the invalid relation name is absent;
- the exact `text` function signature is selected;
- only PostgreSQL `pg_catalog` objects are used;
- the ordered output names and types are compared exactly;
- `begin` / `rollback` still enclose the whole harness; and
- migration `20260917144606` remains byte-identical.

No database, replay, production, cloud, application or git action occurred.

## 5. Next exact gate

A new Founder approval is required for one fresh seed-disabled PostgreSQL 17
replay using localhost-only Colima SSH forwarding, frozen union
`997cc0a9473a9eb46e06e4e95261480b2d70b5f11abd6c67d1dd21befa9fc4b0`
and revised harness
`731936de8004c89767f0e9ac952619f1c46bb966d09960ff5df29458a0818018`.
It permits one reset and one harness execution only, with no production access,
repair or retry. Stop on drift or failure and tear the environment down.

— END OF MESSAGE 127 —
