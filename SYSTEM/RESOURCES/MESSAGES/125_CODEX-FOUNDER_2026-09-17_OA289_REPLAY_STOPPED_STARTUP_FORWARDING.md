# 125 — CODEX → FOUNDER

**Date:** 2026-09-17  
**Subject:** OA-ZYRA-289 replay stopped during empty-stack startup  
**Decision / action:** DR-ZYRA-231 / OA-ZYRA-289  
**Status:** STOPPED AT FIRST FAILURE; AUTHORITY CONSUMED; NO RESET OR HARNESS

## 1. Outcome

The authorised fresh seedless replay stopped during empty local Supabase stack
startup. No migration union was copied, no database reset was invoked and the
OA-ZYRA-289 harness was not executed.

The observed Supabase CLI result was:

`LegacyDbConnectError: connection refused 127.0.0.1:54322`

The dedicated Colima VM had been started with `--port-forwarder none`. Docker
created the disposable database container inside the VM, but Supabase CLI on
the host could not reach its published PostgreSQL port. This is a local
execution-path defect, not a product-migration or harness result. Codex should
have preserved the required localhost forwarding path for this CLI workflow.

No retry or repair followed.

## 2. Exact frozen inputs

| Input | SHA-256 / identity |
|---|---|
| 211-version migration union | `997cc0a9473a9eb46e06e4e95261480b2d70b5f11abd6c67d1dd21befa9fc4b0` — not copied or executed in this attempt |
| OA-ZYRA-289 harness | `fa4da023e930603140939b8daa1e83a3a4e332d9c0becc951b6e2b680dc7a19c` — not executed |
| `20260917133709` | `886b3e0ff17b968f8575a976c32d338ee43a3c7e0372f5a491da6951c70b6c9c` — unchanged, staged only |
| `20260917144606` | `f214179184b8c13a95d52f088719b47e24037b73c6f53c3938918e386ed18575` — unchanged, staged only |
| Supabase CLI | `2.116.0` |
| Database target | PostgreSQL 17, fresh seed-disabled disposable stack |

## 3. Execution and teardown evidence

| Evidence | Result |
|---|---|
| Scratch root | `/private/tmp/zyra-oa289-replay-final-20260917-a` / mode 0700 |
| Start log | 265 bytes / 3 lines / SHA-256 `ded5ac96e7473ff138786e24bc7084329dfdc0c32586697378299136686dabd3` |
| Scratch config | SHA-256 `0768e1d7cde0697997821e69e02fe435fd134833ac74aa99704272016d50cae4` |
| Migration files present at failure | 0 |
| Reset invocations | 0 |
| Harness invocations | 0 |
| `supabase stop --no-backup` | exit 0; disposable stack removed |
| `colima stop --profile zyra-oa198` | exit 0; dedicated VM stopped |
| Dedicated Docker socket after stop | absent |

Production, cloud data, application source, staged migration bytes and the
repaired harness bytes were untouched.

## 4. True pre-state ledger

| File | True pre-state SHA-256 | Post SHA-256 |
|---|---|---|
| `OUTSTANDING_ACTIONS_V2.md` | `0ffd58535ebb1b85dbc4aa36566bfa18157779348f4874018e4d349c9a21d9e9` | `8b58f85a248aaaca6c07692b7b0d36c71808d2f9e67fc0675fc2f76713dd6482` |
| Personal-code handover V1 | `5acfa3d35fd261ee8f6289835836b56565e08d889b8f7c878694b046c49bab7a` | `2be69ef8a24408a768a3de19a1660142c4a6dba7303b12a7fe8a72a2fe7db196` |
| Documentation index V4 | `69d7ec64f5a13a7643968d26075fc865acb64139c9ec54af49a76318215b6ef8` | `de7fb16aa39dfdbad91970c14ac51486721fbd52ef42a564271b939cf29b9fba` |

## 5. Next exact gate

A new Founder approval is required. The smallest corrected run uses a new
fresh scratch with seedless PostgreSQL 17, the frozen 211-version union and repaired
harness boundaries, but starts the dedicated VM with Colima's `ssh`
application-port forwarder instead of `none`. The forwarding is for the
disposable Supabase ports on host loopback; mount, activation, saved-config,
SSH-agent/config, Kubernetes, network-address and binfmt remain disabled.

Only after empty-stack startup succeeds may the exact union be copied, one
reset run and the repaired harness execute once. Stop on any drift or failure;
no repair, retry or production access is included.

— END OF MESSAGE 125 —
