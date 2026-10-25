# 086 — CODEX → FOUNDER
# SUBJECT: OA-ZYRA-198 clean 209-version local replay passed
# DATE: 2026-09-11
# GOVERNANCE: AD-AIOS-109 · OA-ZYRA-198/283 · DR-ZYRA-227 · messages 078–085 · Founder exact single-use replay GO
# STATUS: POST-VERIFIED / FOUNDER ACCEPTANCE REQUIRED / PRODUCTION APPLY REQUIRES SEPARATE GO / APPLE UPLOAD REQUIRES SEPARATE GO

## 1 · Outcome

The exact authorised clean replay passed at its first result.

One fresh, seedless, unlinked PostgreSQL 17.6 local database was reset exactly
once from the unchanged 207-file active migration set plus the two named
replay-only bridges. The runner applied all 209 unique versions exactly once
and exited 0 with:

`Finished supabase db reset on branch main.`

Both reconstructed bridges ran in their required order, unchanged historical
migration `20260811233813` ran immediately after the probe-score bridge, and
both staged September migrations were reached. No repair or retry occurred.

Execution stopped at that result. No database query followed it. The local
stack, unique network and dedicated VM were then removed or stopped. No
production access, production mutation, Apple action, git operation or private
credential-store access occurred.

## 2 · Exact authority and input

The Founder authorised exactly one destructive reset using:

| Input | Measured identity |
|---|---|
| Active migrations | 207 files / 207 unique versions |
| Active-set digest | `8a36926aaca155493f16a731ee498204f0d0225e2a5b41cc66f89e1da39b8861` |
| Question-bank V2 bridge | 28,501 bytes / mode 0600 / `337b342df347b7e902d8da32bafd0a2b21516550b9234213298079304ca66aa1` |
| Probe-score bridge | 7,302 bytes / mode 0600 / `9f9a818f3370b849ba1ff21f1d4ea9c3adb9ab866b22e15f6ba7a03454b46b46` |
| Scratch union | 209 files / 209 unique versions |
| Scratch-set digest | `5bb9e76128b3f4bc9297cdefbf6feed63da9c226bf720de403478684c7f6901c` |
| V1 | absent |
| Seed | disabled by config and `--no-seed`; no `seed.sql` present |

A fresh internal read-only sub-review independently recomputed the 207 active
versions, active digest, both bridge hashes/modes/sizes, bridge absence from the
active path and exact 209-version union before execution. It reported PASS.

## 3 · Isolation

| Control | Measured value |
|---|---|
| Scratch root | `/private/tmp/zyra-oa198-v2-probe-replay.8Fky5C` / mode 0700 |
| Project id | `zyra-oa198-v2-probe-replay.8Fky5C` |
| Scratch config | 15,475 bytes / mode 0600 / `e1f46ff681a86fd2d56f9808a33eec35132281ae0d42257070bb75dc9ddca8de` |
| CLI | Supabase CLI 2.116.0 |
| Database | `public.ecr.aws/supabase/postgres:17.6.1.165`; `server_version_num = 170006` |
| Credential home | fresh scratch-local `home/`, mode 0700; reset launched through `env -i` |
| Link/remote target | no project ref, database URL, access token or production credential |
| Network | `zyra-oa198-v2-probe-8fky5c`; Docker bridge with host binding `127.0.0.1` |
| Published ports | database only: `127.0.0.1:54322 -> 5432/tcp` |
| Other services | Auth, Realtime and Storage had container-only ports; no host publication |
| Global Docker context | `default` before and after |

The database was initialised before the 209 files were copied. The single reset
was invoked through macOS `script -q -e -F` only to retain raw output and the
child exit status. Its effective database command was:

```text
env -i \
  HOME=/private/tmp/zyra-oa198-v2-probe-replay.8Fky5C/home \
  PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin \
  TMPDIR=/private/tmp \
  DOCKER_HOST=unix:///Users/shakeelahmad/.colima/zyra-oa198/docker.sock \
  DO_NOT_TRACK=1 \
  supabase db reset --local --no-seed \
    --workdir /private/tmp/zyra-oa198-v2-probe-replay.8Fky5C \
    --network-id zyra-oa198-v2-probe-8fky5c
```

## 4 · First-result evidence

| Evidence | Result |
|---|---|
| Log interval | `2026-09-11T22:01:47+0100` → `2026-09-11T22:02:28+0100` |
| Invoking process exit | `0` |
| Applying markers | 209 |
| Unique applied filenames | 209 |
| First migration | `20260718190011_initial_schema.sql` |
| Question-bank V2 | ordinal 173; applied |
| Probe-score bridge | ordinal 181; applied |
| Historical target `11233813` | ordinal 182; applied after probe bridge |
| OA-ZYRA-283 `20260910184252` | ordinal 208; applied in scratch |
| Request New Journey hold `20260910195642` | ordinal 209; final migration applied in scratch |
| Terminal result | `Finished supabase db reset on branch main.` |
| Error/failure text | none |
| Raw log | `/private/tmp/zyra-oa198-v2-probe-replay.8Fky5C/replay.raw.log` |
| Raw-log identity | 16,419 bytes / 215 lines / mode 0600 / `42f948b8d44d4167be001db8267fc01fc6af72ab2b17630bcbd9673fa455a813` |

The raw log has no numeric child-status footer; exit 0 comes from the invoking
`script -e` process evidence. An internal read-only sub-review parsed every
migration marker, confirmed 209/209 uniqueness and ordering, confirmed both
September migrations, confirmed the terminal success text and found no
case-insensitive error/failure marker.

## 5 · Stop and teardown proof

- No database query was issued after the first result.
- `supabase stop --no-backup` removed only project
  `zyra-oa198-v2-probe-replay.8Fky5C`.
- The unique network was inspected at zero attached containers, then only
  `zyra-oa198-v2-probe-8fky5c` was removed.
- Named Colima profile `zyra-oa198` is stopped.
- No process listens on TCP ports 54320–54329.
- Global Docker context remains `default`.
- The active source migration set remains 207 files at digest
  `8a36926aaca155493f16a731ee498204f0d0225e2a5b41cc66f89e1da39b8861`.
- The scratch directory and raw log are retained as local evidence; no database
  container or volume from the project remains.

## 6 · Governance consequence

The migration-runner clean-replay target in OA-ZYRA-198 is now met and
post-verified. The OA remains open only for the Founder's acceptance/closure;
Codex does not self-approve or self-close it.

This local result does not apply either September migration to production.
OA-ZYRA-283 and the Request New Journey hold remain staged in production terms.
A production apply requires a new exact single-use Founder GO naming the
production project and final artifact identities. Apple archive/upload is also
a separate gate. This replay authority is consumed and cannot be reused.

## 7 · True pre-state and post-state ledger

True pre-files were captured before governance edits under
`/private/tmp/zyra_oa198_209_replay_pre.5DYRXG`.

| File | True pre-state SHA-256 | Post SHA-256 |
|---|---|---|
| `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` | `9b55f7cb5556ed4218570e09e7a85a84e3c166865c66ca57f280513643c20965` | `fe561a1735a17ad2c205a287207374634b4329b2d6878a1c21c29776b8b64136` |
| `CLAUDE.md` | `a7b0be75d09affb3b108629dcf083894d87f0bdd7447886ba1cc98ea90db9506` | `ed351204bbb20fda460323b479163585adc6c75c5eb9fb871f3c6b54c65321c4` |
| compatibility boundary handover | `40d1ac94273dec6b075081311bedc61c880b701bc93dcebbdc9ffaa4a727e70e` | `8bd206dbaa3c3ae1ae542d48f18960291f53eb9d53280c35af2a2a2cf8dc81ba` |
| App Store runbook | `1828e92d495b7da2cfdd10fa90c2b851caa010ab8d363886dd0570e2dc7c1e81` | `c76795d163c758443327b36d3dd3234958189d28a38fd9e2a9a10a26551c8e1c` |
| migration README | `883b24a9ad288b6d6927441479748d44ebdcd3dccb3299d327d86d905c48cc65` | `b6046245457251c79b13a238144b99518f2e182dfc1eb13f16b2a0b7a8cbb854` |
| documentation index | `860f42a70c194dcd69798ac50cd5f4613fb0f4dd53742fac5c7490695b0dba9e` | `bd1f9309d8593953c98aa6d26e35610e0b73881f8e62f5e0c0edd931e0fef98a` |
| this message 086 | **ABSENT** | new filing; self-hash cannot be embedded without changing itself |

No SQL migration, bridge, Flutter/Dart source or approved visual baseline was
edited.

## 8 · Filing validation

- exact scratch inventory verification: PASS — 209 files / 209 unique
  versions / exact two-bridge delta;
- reset invocation count: one; invoking process exit: 0;
- raw-log internal read-only sub-review: PASS — 209/209 unique markers,
  correct order, both September migrations, terminal success, no error text;
- documentation index regenerated: 609 documents / 95 current-version;
- repository checker: PASS — 186 files, 0 findings, 5 baselined references,
  0 new;
- repository-checker unit test: PASS — 1/1; and
- no implementation or SQL byte changed, so Flutter/analyzer suites were not
  repeated for this execution-record-only filing.

— END OF MESSAGE 086 —
