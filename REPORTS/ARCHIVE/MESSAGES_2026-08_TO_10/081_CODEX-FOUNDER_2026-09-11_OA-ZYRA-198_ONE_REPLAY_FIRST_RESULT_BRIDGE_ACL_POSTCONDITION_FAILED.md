# 081 — CODEX → FOUNDER
# SUBJECT: OA-ZYRA-198 exact one-replay result — bridge ACL postcondition failed on PostgreSQL 17; no retry
# DATE: 2026-09-11
# GOVERNANCE: AD-AIOS-109 · OA-ZYRA-198/283 · DR-ZYRA-227 · message 080 · Founder exact one-replay GO in Codex chat
# STATUS: EXECUTED ONCE / FIRST RESULT CAPTURED / BRIDGE REJECTED FOR EXECUTION / APPLY HOLD

## 1 · Outcome

The Founder authorised exactly one destructive reset of a fresh disposable,
seedless PostgreSQL 17 database using bridge SHA-256
`461c3bd0e4ef4692229027c5659756983ed2048e1e78cf71e2148009d6729055`,
with no production access and an explicit stop-at-first-result / no-repair /
no-retry boundary.

That one reset ran once and returned exit code `1`. The official runner stopped
while applying the bridge itself at version `20260811153415`, statement 11,
with PostgreSQL SQLSTATE `22023`:

> `ERROR: ACL arrays must be one-dimensional`

The failing bridge context is its column-ACL postcondition, which calls
`pg_catalog.aclexplode` over the coalesced empty `aclitem[]` value. The bridge
transaction did not complete and the runner did not begin successor migration
`20260811153416`.

This is the first measured result. It supersedes the static expectation that
this exact bridge would pass and later stop at the separate
`public.zyra_probe_score` creator gap. That later gap was not reached.

No repair, retry, post-failure database query, production access, migration
apply, TestFlight action, git operation or private-credential access followed.
The disposable stack was torn down and its evidence directory retained.

## 2 · Exact input and isolation

| Control | Measured value |
|---|---|
| Scratch root | `/private/tmp/zyra-oa198-replay4.LpXHVz` (mode `0700`) |
| Project id | `zyra-oa198-replay4.LpXHVz` |
| Docker network | `zyra-oa198-lpxhvz` |
| Network host binding | `127.0.0.1` |
| Database image | `public.ecr.aws/supabase/postgres:17.6.1.165` |
| PostgreSQL | `17.6` |
| Published database port | `127.0.0.1:54322 -> 5432/tcp` |
| Supabase CLI | `2.116.0` |
| Active input | 207 timestamped SQL files; digest `8a36926aaca155493f16a731ee498204f0d0225e2a5b41cc66f89e1da39b8861` |
| Scratch input | 208 unique timestamp versions; digest `3e2db6cb227715afc33db8fb82d7d87e317046653191ce95c175f0222cf617d4` |
| Scratch delta | exactly the bridge at version `20260811153415` |
| Bridge | 28,387 bytes / 498 lines / mode `0600` / SHA-256 `461c3bd0e4ef4692229027c5659756983ed2048e1e78cf71e2148009d6729055` |
| Scratch config | SHA-256 `e95a204753354bd79968c98e337ec1079e7b8928cfba963adc785422af712ac4` |
| Seed | disabled; no `seed.sql` present |
| Link/remote target | no project-ref, database URL or production credential present |
| Roles | standard `anon`, `authenticated`, `service_role` present |
| Search path | `"$user", public, extensions` |
| Global Docker context | `default` before and after |

The empty PostgreSQL container was started before the migration files were
copied. The exact invocation was:

```text
DOCKER_HOST=unix:///Users/shakeelahmad/.colima/zyra-oa198/docker.sock \
DO_NOT_TRACK=1 supabase db reset --local --no-seed \
  --workdir /private/tmp/zyra-oa198-replay4.LpXHVz \
  --network-id zyra-oa198-lpxhvz
```

It was executed once through macOS `script -q -e -F` solely to preserve raw
stdout/stderr and the child exit code. The exact reset command was not invoked
a second time.

## 3 · First-result evidence

| Evidence | Result |
|---|---|
| Completion time captured | `2026-09-11T09:44:32Z` (`10:44:32` Europe/London) |
| Reset exit code | `1` |
| Last migration started | `20260811153415_oa198_reconstructed_question_bank_replay_bridge.sql` |
| Failure location | bridge statement 11, `DO $oa198_postconditions$` |
| SQLSTATE | `22023` |
| Error | `ACL arrays must be one-dimensional` |
| Successor 153416 | not started |
| Raw log | `/private/tmp/zyra-oa198-replay4.LpXHVz/replay.raw.log` |
| Raw-log identity | 23,055 bytes / 178 lines / mode `0600` / SHA-256 `4acacdd4e3ca77de2ff5763d896a042fddec5cc25f400e909bfd998a0a8ef0f6` |

The command output identifies the failure inside the `v_column_acl_count`
query. It uses:

```sql
CROSS JOIN LATERAL pg_catalog.aclexplode(
  COALESCE(attribute.attacl, '{}'::aclitem[])
) acl
```

The one replay is evidence that the prior static and source-level tests did
not exercise this PostgreSQL 17 runtime behaviour. The three internal static
reviews recorded in message 080 therefore remain historical evidence of what
was checked, not evidence that the bridge is executable.

## 4 · Stop and teardown proof

- No database query was issued after the failure.
- `supabase stop --no-backup` removed only project
  `zyra-oa198-replay4.LpXHVz`.
- The unique network was inspected empty, then only
  `zyra-oa198-lpxhvz` was removed.
- Named Colima profile `zyra-oa198` is stopped.
- No process listens on TCP ports `54320`–`54329`.
- Global Docker context remains `default`.
- The active source migration set remains 207 files at digest
  `8a36926aaca155493f16a731ee498204f0d0225e2a5b41cc66f89e1da39b8861`.
- No `20260811153415` file exists in `SOURCE/supabase/migrations`.
- The governed bridge source remains byte-identical at
  `461c3bd0e4ef4692229027c5659756983ed2048e1e78cf71e2148009d6729055`.

Production and both staged September migrations were never selected or
reached.

## 5 · Governance consequence and next gate

OA-ZYRA-198 remains **OPEN / APPLY HOLD**. The exact bridge approved for this
one replay is rejected for execution because its own PostgreSQL 17
postcondition fails. OA-ZYRA-283 remains staged and receives no production
Apply-GO request.

No new OA is raised: this is a measured result inside OA-ZYRA-198's existing
clean-replay scope.

The next safe step is preparation only, not execution:

1. design the smallest fail-closed correction to the column-ACL inspection;
2. create a new bridge artifact identity rather than overwrite this executed
   hash or its evidence;
3. add a real PostgreSQL 17 runtime test that exercises null/empty column ACLs;
4. internally verify the new exact artifact and show its hash, isolation,
   consequence and stop threshold to the Founder; and
5. obtain a new single-use Founder GO before any further reset.

The current failure does not authorise any of those execution steps and does
not authorise production apply.

## 6 · True pre-state

True pre-files were captured immediately before governance edits under
`/private/tmp/zyra_oa198_replay_result_pre.DbgDZd`.

| File | True pre-state SHA-256 | Post SHA-256 |
|---|---|---|
| `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` | `0b9d6edd1cabf9a03a9e3cc21510e3847e7b457cdaf74a489420e2a7d771426a` | `ebdaad4535c3e67ca6de5c4d71164270d0ed65222127626e2ee2bdfc2bc38c09` |
| `SYSTEM/DOCUMENTS/ZYRA_JOURNEY_COMPATIBILITY_BOUNDARY_HANDOVER_CURRENT_VERSION_V1.md` | `5fc402f95e4b554179c082d78f216a4bd5e27b2638b9c80848146a6635ecb3cf` | `ce68d33eac072a94d1c2aa397dd96ed37ac58fadcb1a19b2344f8a298a10e4d6` |
| `CLAUDE.md` | `74625a3265bde3c943ce80f5a0075973b11b26d23d52fb760cee003c1d7f9d05` | `cb0b941a614242ab6d1b7fa96486a9bdfccdb0c2f9c875a445e91809e1421c04` |
| `SYSTEM/DOCUMENTS/ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V3.md` | `ebfe568a98ea0827642fd89d33a10ab61eb595e024925d2605b5e6e7295e56e4` | `936625380367bfeb29d7bfa0b57ebf980fd1b0cab1d6cb72340057bc16c20dc6` |
| Message 081 | absent | returned at handoff; self-hash cannot be embedded without changing itself |

Validation: `python3 tools/zyra_check.py` passed with 0 findings; checker unit
test passed 1/1. No Flutter or production source changed, so analyzer and
Flutter suites were not repeated for this governance-only filing. Message
081's final self-hash is returned at handoff.

— END OF MESSAGE 081 —
