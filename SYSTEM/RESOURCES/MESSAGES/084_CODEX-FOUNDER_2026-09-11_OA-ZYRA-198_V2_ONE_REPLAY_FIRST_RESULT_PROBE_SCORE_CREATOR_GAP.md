# 084 — CODEX → FOUNDER
# SUBJECT: OA-ZYRA-198 exact V2 one-replay result — V2 passes; probe-score creator gap measured; no retry
# DATE: 2026-09-11
# GOVERNANCE: AD-AIOS-109 · OA-ZYRA-198/283 · DR-ZYRA-227 · messages 081–083 · Founder exact V2 one-replay GO in Codex chat
# STATUS: EXECUTED ONCE / V2 PASSED / FIRST RESULT 11233813 STATEMENT 7 / SQLSTATE 42P01 / APPLY HOLD

## 1 · Outcome

The Founder authorised exactly one destructive reset of a fresh disposable,
seedless PostgreSQL 17 database using V2 bridge SHA-256
`337b342df347b7e902d8da32bafd0a2b21516550b9234213298079304ca66aa1`,
with no production access and an explicit stop-at-first-result / no-repair /
no-retry boundary.

That reset ran once and returned exit code `1`. The V2 bridge passed, and the
runner continued through all five recovered question-bank successors. It then
entered migration
`20260811233813_oa186c_function_execute_hygiene_and_probe_rls.sql` and stopped
at statement 7 with PostgreSQL SQLSTATE `42P01`:

> `ERROR: relation "public.zyra_probe_score" does not exist`

The failing statement was:

```sql
ALTER TABLE public.zyra_probe_score ENABLE ROW LEVEL SECURITY;
```

The last fully completed predecessor was
`20260811233755_fix_duplicate_journey_ended_milestone.sql`. Successor
`20260811233914` did not start. Neither staged September migration was reached.

This is the first measured V2 full-replay result. It converts the previously
static `public.zyra_probe_score` creator gap into OA-ZYRA-198's current measured
frontier. V2 itself is accepted by this run through its reached dependency
chain; the clean replay as a whole is not achieved.

No repair, retry, post-failure database query, production access, migration
apply, TestFlight action, git operation or private-credential access followed.
The disposable stack was torn down and its evidence directory retained.

## 2 · Exact input and isolation

| Control | Measured value |
|---|---|
| Scratch root | `/private/tmp/zyra-oa198-v2-replay.G1Gx1D` (mode `0700`) |
| Project id | `zyra-oa198-v2-replay.G1Gx1D` |
| Scratch config | 15,469 bytes / mode `0600` / SHA-256 `8ba83a762890deb57fd545b03bb59ab35497a0f716adf78890fbffccfb0e4e7d` |
| Credential home | scratch-local empty `home/` (mode `0700`); process launched through `env -i` |
| Docker network | `zyra-oa198-v2-g1gx1d`; bridge host binding `127.0.0.1` |
| Database image | `public.ecr.aws/supabase/postgres:17.6.1.165` |
| Image identity | `sha256:28f0e16a019e648089fc1a6d333549a55548f6019c15ae4bd7cd58b989027518` |
| PostgreSQL | `17.6`; `server_version_num = 170006` |
| Published database port | `127.0.0.1:54322 -> 5432/tcp` |
| Other started-service host ports | none |
| Supabase CLI | `2.116.0` |
| Active input | 207 timestamped SQL files; digest `8a36926aaca155493f16a731ee498204f0d0225e2a5b41cc66f89e1da39b8861` |
| Scratch input | 208 unique timestamp versions; digest `f7f4a909c8d40ecda451eae4eae501cd703d3472642908c1b342acb1bece7035` |
| Scratch delta | exactly V2 at artificial ordering version `20260811153415` |
| V2 bridge | 28,501 bytes / mode `0600` / SHA-256 `337b342df347b7e902d8da32bafd0a2b21516550b9234213298079304ca66aa1` |
| Seed | disabled; no `seed.sql` present |
| Link/remote target | no project-ref, database URL, access token or production credential present |
| Global Docker context | `default` before and after |

The empty PostgreSQL stack was started before the 208 migration files were
copied. Only the cached PostgreSQL, Auth, Realtime and Storage images were
started; only PostgreSQL published a host port, bound to localhost.

### Pre-start isolation correction

An initial empty-stack preflight used a Docker network marked `internal=true`.
`supabase start` stopped before migrations were copied because the CLI could
not reach the required localhost PostgreSQL health port (`ECONNREFUSED
127.0.0.1:54322`). No `db reset` command had been invoked and no replay input
was present, so the single-use replay authority remained unconsumed. The empty
network was inspected at zero containers, removed, and replaced by the same
localhost-bound bridge model already proven in messages 078 and 081. The empty
stack then started successfully. This setup correction is disclosed; it was
not a database repair or replay retry.

The one reset was invoked once through macOS `script -q -e -F` solely to
preserve raw stdout/stderr and the child exit code. Its effective child command
was:

```text
env -i \
  HOME=/private/tmp/zyra-oa198-v2-replay.G1Gx1D/home \
  PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin \
  TMPDIR=/private/tmp \
  DOCKER_HOST=unix:///Users/shakeelahmad/.colima/zyra-oa198/docker.sock \
  DO_NOT_TRACK=1 \
  supabase db reset --local --no-seed \
    --workdir /private/tmp/zyra-oa198-v2-replay.G1Gx1D \
    --network-id zyra-oa198-v2-g1gx1d
```

The explicit `--local`, isolated Docker socket, scratch-only home and absent
link/database URL prevented selection of production. The reset command was not
invoked a second time.

## 3 · First-result evidence

| Evidence | Result |
|---|---|
| Completion time captured | `2026-09-11T21:01:04+0100` (`20:01:04Z`) |
| Reset exit code | `1` |
| V2 bridge | passed; runner advanced beyond `20260811153415` |
| Question-bank successors | `153416`, `153547`, `153643`, `172021`, `173212` all advanced past |
| Last fully completed migration | `20260811233755_fix_duplicate_journey_ended_milestone.sql` |
| Migration entered at failure | `20260811233813_oa186c_function_execute_hygiene_and_probe_rls.sql` |
| Failure location | statement 7 |
| SQLSTATE | `42P01` |
| Error | relation `public.zyra_probe_score` does not exist |
| Successor `11233914` | not started |
| OA-ZYRA-283 migration `20260910184252` | not reached |
| Request New Journey hold `20260910195642` | not reached |
| Raw log | `/private/tmp/zyra-oa198-v2-replay.G1Gx1D/replay.raw.log` |
| Raw-log identity | 14,568 bytes / 190 lines / mode `0600` / SHA-256 `61d31fbd9b09e79c31737b03d4faf3e4d62fe8991a829a6c3cae8da12b19c205` |

An independent read-only Codex subagent inspection of that raw log confirmed
the V2 pass, successor sequence, last completed predecessor, exact statement /
SQLSTATE and absence of either September migration from the executed output.

## 4 · Stop and teardown proof

- No database query was issued after the failure.
- `supabase stop --no-backup` removed only project
  `zyra-oa198-v2-replay.G1Gx1D`.
- The unique network was inspected at zero containers, then only
  `zyra-oa198-v2-g1gx1d` was removed.
- Named Colima profile `zyra-oa198` is stopped.
- No process listens on TCP ports `54320`–`54329`.
- Global Docker context remains `default`.
- The active source migration set remains 207 files at digest
  `8a36926aaca155493f16a731ee498204f0d0225e2a5b41cc66f89e1da39b8861`.
- No `20260811153415` file exists in `SOURCE/supabase/migrations`.
- V1, V2, both staged September artifacts and every active SQL migration
  remain byte-unchanged.

Production and TestFlight were never selected, queried or changed.

## 5 · Governance consequence and next gate

OA-ZYRA-198 remains **OPEN / APPLY HOLD**. The V2 question-bank reconstruction
is no longer the measured blocker; it passed. The clean replay now stops on the
missing creator for `public.zyra_probe_score` before either September staged
migration. OA-ZYRA-283 therefore receives no production Apply-GO request.

No new OA is raised: the missing creator is the next measured clean-replay
frontier inside OA-ZYRA-198.

The current single-use replay authority is consumed. It does not authorise a
repair or rerun. The next safe scope, if separately authorised, is to establish
the retained provenance of `public.zyra_probe_score` or return a reconstruction
ruling if provenance is absent, internally verify the exact resulting replay
input, and only then present a new exact one-replay GO. V1 remains permanently
rejected; V2 and the eight recovered historical bodies remain frozen.

No production migration apply or TestFlight upload is authorised by this
result.

## 6 · True pre-state and post-state ledger

True pre-files were captured immediately before governance edits under
`/private/tmp/zyra_oa198_v2_replay_result_pre.gD2LLR`.

| File | True pre-state SHA-256 | Post SHA-256 |
|---|---|---|
| `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` | `012976fa7831c65e2bd095e6488505b85f08e7eaeeb3edee5d179cab7fb8de61` | `57f479324007e4aa3514b3cfa3c40144f6a44da44594866ff252137402cad26b` |
| `SYSTEM/DOCUMENTS/ZYRA_JOURNEY_COMPATIBILITY_BOUNDARY_HANDOVER_CURRENT_VERSION_V1.md` | `ccaf7ad9f3e5027cfdfefa3dd186f3297f40f05f282d51f08883d5238e7e5fe2` | `345b73f6c31cae88d6b85d4d34f72f79e1ea60fd79295817112c8c8e395d4e94` |
| `CLAUDE.md` | `f20cd7061f8e3d371d6dba9a3d3ecf1ae7c199f2da7522c4887aabde7ab6b19f` | `276cfc2846ccd0bae666d1e744bd6bd7d7d5678544766873c672e06e99b0f4b3` |
| `SOURCE/supabase/migrations/README_20260811_OA193.md` | `7242a65b42669083a518928d8172ea542ff715be6f32553721ee289981ea2963` | `e64098322af1ad5de11d5f97c6308aa72310e09181ca87a0a3d1b5993f7759f4` |
| `SYSTEM/DOCUMENTS/ZYRA_APP_STORE_RUNBOOK_CURRENT_VERSION_V1.md` | `f024e35110bff0d9abb75c0b1ebd79774d7f20bb61b9da5b69c00708ae3f9d9c` | `6de7a68fbbd3cd818e8c2dbebbc5d7eb821037e9126bfe2bf579ae3db21cb4ac` |
| `SYSTEM/DOCUMENTS/ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V3.md` | `dcfa1ebd4df13f5b423861ef00b583aa1c177d6e17b57ff4ba231c7cee137e2b` | `2f238de994e069d182e779b4dbd589fc53aa70cd7e11996355064694d73efee8` |
| Message 084 | absent | returned at handoff; self-hash cannot be embedded without changing itself |

The V2 SQL/README/manifest remain unchanged at the frozen identities recorded
in message 082. Historical messages 081–083 were not edited.

## 7 · Validation

- exact V2 hash/mode: passed;
- active source count/digest and absence of version 153415: passed;
- scratch count/version uniqueness/digest and exact V2-only delta: passed;
- pinned image identity, PostgreSQL version and localhost binding: passed;
- one reset invocation: exit `1` at the first database result above;
- post-failure database queries: zero;
- targeted teardown and port/context checks: passed;
- independent read-only log review: passed;
- V2 artifact test: passed 4/4;
- repository checker: 186 files, 0 findings;
- checker unit test: passed 1/1;
- no Flutter/Dart/SQL implementation byte changed, so analyzer and Flutter
  suites are not repeated for this execution-record-only filing.

— END OF MESSAGE 084 —
