# 128 — CODEX → FOUNDER

**Date:** 2026-09-17  
**Subject:** OA-ZYRA-289 reset passed; harness array expansion failed  
**Decision / action:** DR-ZYRA-231 / OA-ZYRA-289  
**Status:** RESET PASS 211/211; HARNESS FAILED; PRODUCTION UNCHANGED

## 1. Outcome

The authorised fresh PostgreSQL 17 replay passed its one reset with all 211
frozen migrations. The revised harness then executed exactly once and again
reached the final output-contract assertion after the temporary actors and core
code/request/link assertions completed without raising.

The final assertion failed because this qualified function overload does not
exist in PostgreSQL:

`pg_catalog.unnest(oid[], "char"[], text[])`

PostgreSQL's multiple-array `unnest` form is special FROM-clause syntax rather
than that three-argument `pg_catalog` function. Codex should not have qualified
it as though the overload were a normal catalog function.

The transaction aborted and rolled back. No repair, retry, post-failure
database query or production access followed. The disposable stack and VM were
removed.

## 2. Exact inputs and results

| Item | Identity / result |
|---|---|
| Frozen union | `997cc0a9473a9eb46e06e4e95261480b2d70b5f11abd6c67d1dd21befa9fc4b0`; 211 files; byte comparison clean |
| `20260917133709` | `886b3e0ff17b968f8575a976c32d338ee43a3c7e0372f5a491da6951c70b6c9c` |
| `20260917144606` | `f214179184b8c13a95d52f088719b47e24037b73c6f53c3938918e386ed18575` |
| Harness | `731936de8004c89767f0e9ac952619f1c46bb966d09960ff5df29458a0818018` |
| Reset | exit 0; 211/211; terminal success |
| Harness | one execution; exit 3 at final catalog array expansion |

## 3. Evidence and teardown

| Evidence | Identity |
|---|---|
| Scratch root | `/private/tmp/zyra-oa289-replay-final-20260917-c` / mode 0700 |
| Start log | 1,521 bytes / 6 lines / `4f5b6342257e2167e19948a01fd7e54200eb4d148b535239e24f09c9b070a30f` |
| Reset log | 16,674 bytes / 220 lines / `d12b8623a741b3b48d61fc32ba4b3d8010eb3514baed20872a08176facd90c9e` |
| Harness log | 1,019 bytes / 30 lines / `eef0201763591d0b57656b7b2ccaca522dd276482c751bf5d8e50dabbc24806b` |
| Scratch config | `cd91f017c20e4d47da5cadb7ae4d73ad109a73c535d596b83175dcd10bb87cbf` |
| Stack teardown | exit 0 |
| VM teardown | exit 0 |
| Dedicated Docker socket after stop | absent |

## 4. True pre-state ledger

| File | True pre-state SHA-256 | Post SHA-256 |
|---|---|---|
| `OUTSTANDING_ACTIONS_V2.md` | `f1082d582fc7df78d6e4b94cd1dd98330c87bf324924ba0ed856017fdcd8d591` | `0f1151b5e27bb2862580d02cb4b5295f5e7933f63d9986a9e3b6f3daca0ebcd5` |
| Personal-code handover V1 | `de7368aed68b0606e7fe1932dd79dec9f668273c1581816cdd24e86e2f835961` | `acadf01664976283962828518cda10b2bd3a001c739f9529bb0ad84fae29c4da` |
| Documentation index V4 | `49c20805c1bfd2f3ec38d6b98ff05843786177e6f0aff8cd2ee156b71a98a805` | `eb00ef0bb1dcc96e2cbacf41e62b9a60a54fd032a9c9f824d69359eadb0bb15a` |

## 5. Next exact gate

The smallest repair is harness-only: replace the three-array `unnest` call
with `pg_catalog.generate_subscripts(proc.proallargtypes, 1)` and index the
existing `proallargtypes`, `proargmodes` and `proargnames` arrays at each
returned position. The exact ordered two-text-output comparison remains.

That edit requires a separate Founder approval and new harness hash. A later
replay requires a further exact approval; this report authorises neither.

— END OF MESSAGE 128 —
