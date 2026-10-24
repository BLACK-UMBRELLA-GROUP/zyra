# 129 — CODEX → FOUNDER

**Date:** 2026-09-17  
**Subject:** OA-ZYRA-289 catalog array expansion repaired; replay gated  
**Decision / action:** DR-ZYRA-231 / OA-ZYRA-289  
**Status:** HARNESS REPAIRED; NOT RE-RUN; PRODUCTION UNCHANGED

## 1. Outcome

Under the Founder's bounded approval, Codex changed only the failed catalog
array expansion in the OA-ZYRA-289 harness. The unsupported qualified
three-array `unnest` call is gone.

The harness now uses the supported
`pg_catalog.generate_subscripts(proc.proallargtypes, 1)` function and indexes
`proallargtypes`, `proargmodes` and `proargnames` at each returned position.
It still targets exactly `public.zyra_preview_personal_code(text)`, filters only
output argument modes and requires the same exact ordered contract:

1. `owner_first_name text`
2. `owner_role text`

Every temporary-actor and product assertion remains byte-unchanged.

## 2. Exact artifact state

| Artifact | SHA-256 | State |
|---|---|---|
| Frozen 211-version union | `997cc0a9473a9eb46e06e4e95261480b2d70b5f11abd6c67d1dd21befa9fc4b0` | unchanged |
| `20260917133709` | `886b3e0ff17b968f8575a976c32d338ee43a3c7e0372f5a491da6951c70b6c9c` | unchanged; staged only |
| `20260917144606` | `f214179184b8c13a95d52f088719b47e24037b73c6f53c3938918e386ed18575` | unchanged; staged only |
| OA-ZYRA-289 harness | `7d429c4ad720eb6c8c22845d6203b55bfc8bb4f48bc6c10f103fd1acc760b73f` | array expansion repaired; not executed |

## 3. True pre-state ledger

| File | True pre-state SHA-256 | Post SHA-256 |
|---|---|---|
| OA-ZYRA-289 harness | `731936de8004c89767f0e9ac952619f1c46bb966d09960ff5df29458a0818018` | `7d429c4ad720eb6c8c22845d6203b55bfc8bb4f48bc6c10f103fd1acc760b73f` |
| `OUTSTANDING_ACTIONS_V2.md` | `0f1151b5e27bb2862580d02cb4b5295f5e7933f63d9986a9e3b6f3daca0ebcd5` | `5f833e6d31c491c8e02662ba3c89b1bab27646dc78ee0aa1a36e316d19736593` |
| Personal-code handover V1 | `acadf01664976283962828518cda10b2bd3a001c739f9529bb0ad84fae29c4da` | `e312875901202acb8d0db22223049d026c733eb35a7d00b27e8e6231853aa246` |
| Documentation index V4 | `eb00ef0bb1dcc96e2cbacf41e62b9a60a54fd032a9c9f824d69359eadb0bb15a` | `d2e7a27662623ca173ae000b02b707f84e8b49ca5f1ffe43d797cae03d950d37` |

## 4. Verification boundary

Static inspection confirms the failed `unnest` expression is absent, the
supported catalog function and explicit array indexing are present, the exact
ordered JSON contract is unchanged, and the whole harness remains enclosed by
`begin` / `rollback`.

No database, replay, production, cloud, application or git action occurred.

## 5. Next exact gate

A new Founder approval is required for one fresh seed-disabled PostgreSQL 17
replay using localhost-only Colima SSH forwarding, frozen union
`997cc0a9473a9eb46e06e4e95261480b2d70b5f11abd6c67d1dd21befa9fc4b0`
and revised harness
`7d429c4ad720eb6c8c22845d6203b55bfc8bb4f48bc6c10f103fd1acc760b73f`.
It permits one reset and one harness execution only, with no production access,
repair or retry. Stop on drift or failure and tear the environment down.

— END OF MESSAGE 129 —
