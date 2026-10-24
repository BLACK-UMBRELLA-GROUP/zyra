# 106 — CODEX → FOUNDER: V3 stopped before VM start; host parser defect

Date: 2026-09-12 · OA-ZYRA-286 · Owner: Codex · Authority: AD-AIOS-109

## 1. Actual outcome

The exact approved V3 invocation was run once. It stopped at the host listener
parser before any VM startup, Docker, database, SQL, migration or harness.
No retry or repair followed. ZYRA Test is not delivered; no Apple upload was
attempted. Production and both cloud projects remain untouched.

The missing-HOME fix worked: native Colima status exited0. The next read-only
TCP lsof command also exited0; our parser then rejected its output. This is
local test-tooling failure, not Apple processing or an app/database test result.

## 2. Exact authority, invocation and result

The Founder replied **DO ALL** directly to the report105-linked request for one
V3 local database test, fresh local resources, cleanup, first-failure stop,
no cloud change/upload. That is the GO for the exact presented operation;
separate live/credential/signing/upload gates remain unchanged.

Workspace:
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3`.

Packet: `evidence/oa286-full-replay-execution-proposal-v3/`.
Exact manifest:
`5d413b2bee67023d5777ac93f8ea7b6ac24c1295b7c622f956a59ef25dcda0de`.

Invocation, once from that packet:

```text
PYTHONDONTWRITEBYTECODE=1 /usr/bin/python3 run.py --execute --approve-manifest 5d413b2bee67023d5777ac93f8ea7b6ac24c1295b7c622f956a59ef25dcda0de
```

Process exit1: `STOP: listener output shape invalid`.

| Recorded command | Start/end Unix seconds | Exit |
|---|---|---|
| pinned Colima `list --json` | 1789229972.646243 / 1789229972.7564049 | 0 |
| `/usr/sbin/lsof -nP -iTCP -sTCP:LISTEN -Fpcn` | 1789229972.756565 / 1789229972.783972 | 0 |

Result `execution-v3/result.json`:

- status STOPPED; first_error `listener output shape invalid`;
- cleanup_errors empty; stages empty; image observations empty;
- lifecycle stage `no-vm-start-attempted-no-vm-stop-issued`;
- exactly the two commands above, no UDP query or later command.

Result SHA-256:
`806e15f08f1ddeb232cccdafbd07c5239ed1bfc9f05287aaeb0b7cd60e311e5e`.
Approval record `evidence/oa286-full-replay-approval-20260912-v3.md` SHA-256:
`7b213e3cc8f04286bda6f6624b989a4970ff48d9c5d58eb88eb1e77a015e3881`.

The exclusive V3 execution directory was created and is retained. This
approval is consumed; never delete the marker or reuse the packet for a run.

## 3. Source-confirmed defect and evidence limits

Frozen `lifecycle.py` lines184–199 accepts only leading `p`, `c`, `n` fields.
Line242 calls lsof with `-Fpcn`. The installed macOS lsof manual's **OUTPUT FOR
OTHER PROGRAMS** section describes file sets beginning with `f`, and labels
the `f` file-descriptor field **always selected**. The parser therefore rejects
documented host output even though lsof succeeds.

A pure in-memory sample `p123 / csynthetic / f7 / n127.0.0.1:12345` (newline
separated) passed to the frozen parser reproduced `LifecycleError: listener
output shape invalid`. No native command, VM or network call was made by that
synthetic diagnostic. Existing tests at test_lifecycle.py113/118 omit the `f`
field. Their94-test PASS was not proof of host-format compatibility.

This is a confirmed source/manual compatibility defect. The exact rejected
runtime line itself was not retained, so that line is not falsely quoted as
measured evidence. The new V3 diagnostics trigger on failed commands, but both
commands exited0: they do not capture downstream parser rejection. That gap
also belongs under OA-ZYRA-286. No arbitrary host command/environment/socket
output is added to evidence.

Read-only investigation was limited to retained result/source, installed man
page, file hashes/absence checks and the synthetic parser call. No second
lsof/Colima runtime probe, VM operation, SQL, repair or retry was performed.

## 4. Preservation and runtime boundary

All17 V3 manifest entries passed the post-attempt hash check. The same manifest
hash stands. V1/V2 packets and all prior markers/results remain untouched.
The current saved Colima profile is unchanged at
`069a21a0f329460327cfc6ced19a61e904a15dfa82e45dc4ebc6cf6b5f65902d`.
Named VM sockets and the host-agent PID file remain absent. The successful
status check was accepted as stopped before the listener baseline failed.

`VMLifecycle.start()` reaches `started_attempted=True` only after that baseline;
it did not reach it here. `Replay.run()` never ran and never owned resources.
Cleanup therefore issued no VM stop or resource deletion and correctly says so.
Prepared local copies are retained evidence, not a database or SQL execution.

No Flutter/visual/analyzer suite was rerun: there is no app-source change. No
claim of live-schema, managed Auth, Edge, fixture or TestFlight readiness follows.

## 5. True pre/post canonical record

Current Developer Control handover pre-file was copied at edit time to:
`evidence/oa286-v3-stop-prestate.Gl9ieP/ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V2.pre.md`.

True pre SHA-256:
`8530ff362edbe777ae1a1ebe4c5abe9473444b1b5d0d50ba169c52486353ccbf`.
Post SHA-256:
`d6a55af1a9f9ae5905af153c4aec1cffc8f56e4fdd9e04a99c5d52d59ad6c694`.
Only current status and new §10.4 changed; previous checkpoints remain history.
This106 path was absent before creation. Final106 hash is in the workspace
completion ledger. The master OA file is unchanged; no new identifier assigned.

## 6. Required correction / next scope

Recommend one bounded local parser correction and real read-only host-format
preflight, preserving consumed V3. Validate process/file ownership framing and
TCP/UDP records without weakening listener, collision or isolation guards;
cover actual native format rather than only invented fixtures. Retain safe
parser-failure evidence without raw secret/host-output dumps.

That repair and any successor execution require the appropriate new scope/GO;
none was performed under the consumed first-result-only approval. No next-run
hash is invented here. All live Test database/identity/role/fixture/Edge/pin and
Apple gates remain open. The manual-only credential instruction is unchanged.

— END 106 —
