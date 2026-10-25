# 107 — Host-format repair V4 prepared; actual read-only preflight passed

TO: Founder (Shakeel)  
FROM: Codex  
DATE: 2026-09-12  
TRACKING: OA-ZYRA-286 · DR-ZYRA-228/229 · AD-AIOS-109  
STATUS: Bounded local repair complete; full replay NOT authorised or executed

## 1. Founder summary and authority

The launcher now accepts the actual macOS listener format. Its corrected
pre-start checks passed on this Mac, not just in mocks. All105 local runner
regression tests passed. No VM, database, SQL, cloud or Apple action occurred.
ZYRA production1.0.0(2) remains the existing private Founder TestFlight app;
ZYRA Test is still not uploaded or ready.

The Founder's **tRY AGAIN** answered the specific parser-fix/read-only-host-check
request. It authorises this repair, not reuse of consumed V3 or a new replay.
This report proposes one new exact operation in §5. Only the Founder may
approve it; internal review below is neither independent external verification
nor self-approval. No new OA, master OA edit, git or private-key folder access.

## 2. What changed, including the withdrawn candidate

V3 stopped before VM start because `lsof -Fpcn` also emits file descriptor `f`
fields. Real TCP and UDP output reproduced that parser failure. New V4 parses
strict process/file sets p,c,(f,n)+, retaining ownership and endpoint values.
Unknown, malformed, missing, duplicate and incomplete records fail closed.
Safe parser diagnostics preserve only fixed classifications, counts and hashes,
not raw processes or endpoints. The original stopped pre-start prefix is now
callable on its own and still used by start(); no runtime guard was removed.

Final internal review caught an additional ambiguity before execution approval:
the installed lsof manual says exit1 can mean an error, not just no matches.
Initial V4 was copied byte-for-byte before editing and withdrawn. Final V4
requires exit0 AND nonempty output. Exit1-empty is a command failure;
exit0-empty is a fixed empty-output parser failure. Both stop before UDP or VM
startup. A genuine no-match result is deliberately unavailable, not silently
accepted, because the command cannot reliably distinguish it from an error.

SQL, image pins, snapshot contract, native HOME handling, SSH arguments,
ownership/isolation policy and cleanup policy are unchanged. V4 has distinct
project/path/one-use marker names. No V3 or older attempt was repaired/retried.

## 3. Validation and limits

Root ran the final actual preflight on exact run.py/lifecycle.py hashes below,
verified before and after. Its native allowlist permitted only these3 commands:

| Native check | Unix start / end | Result |
|---|---|---|
| Pinned Colima list --json | 1789230911.848352 / 1789230911.964561 | exit0; named profile stopped |
| lsof TCP LISTEN -Fpcn | 1789230911.964739 / 1789230911.986917 | exit0;348bytes;p9/c9/f13/n13 |
| lsof UDP -Fpcn | 1789230911.9872131 / 1789230912.0028648 | exit0;1058bytes;p9/c9/f51/n51 |

The complete stopped prefix passed: executable/profile pins, socket/PID absence,
TCP/UDP parser and baseline, reserved-port check and existing log offsets.
32unique tuples; started_attempted=false; cleanup_called=false; no tunnel;
execution-v4 absent. Raw output stayed in memory. Counts/hashes/events are in
the evidence file in §4. Earlier native ps fields and historical generated
VM/SSH configs also parsed. Diagnostic self-tree ps UID/path mismatches were
explained without relaxing the actual VM ancestry guard.

Root command:
`PYTHONDONTWRITEBYTECODE=1 /usr/bin/python3 -m unittest -v test_runner test_activation test_launcher test_lifecycle test_docker_guard test_snapshot_contract`
→105PASS in0.334s. These are local runner mock/pure tests, not Flutter tests
or a database run. Writer separately105PASS; bounded internal peer recheck
closed the exit-status finding with no further finding in this delta.
Root verified final17/17 manifest entries and file-only `run.py`:
LOCAL_FILES_VALID,213 SQL inputs,execution_ready=false,exact_approval_required=true.

This does NOT prove fresh post-start configuration, running host-agent identity,
owned listeners/tunnel, cached images, official CLI bootstrap, SQL replay,
harness rollback, cleanup, cloud Auth/Edge or TestFlight readiness. Those remain
future runtime results. No broad app test/pixel regeneration was needed here.

## 4. Exact evidence and true pre/post state

Workspace evidence root:
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/evidence/`

| Item relative to evidence root | SHA-256 / state |
|---|---|
| oa286-full-replay-execution-proposal-v4/EXECUTION_MANIFEST.sha256 | ec1c39f5732f958131323d04cd38aac70bf344674a48625f470b126c72efe82c |
| final V4 run.py | fe0317d114157a31dda017e1f57376039d0f07149d0d5ce7f024f6e84c619a97 |
| final V4 lifecycle.py | d662b3b6f351604d9cda0caa249953ba40af54be223bb547510b19da0c4353a4 |
| oa286-full-replay-execution-proposal-v4-preempty-8ca26a/EXECUTION_MANIFEST.sha256 | 8ca26a4430ad33c9bbe50d61a8cc8d78a567821cafa3cda3c2a3bbdb7e8667dc; withdrawn;17/17 preserved |
| oa286-full-replay-execution-proposal-v3/EXECUTION_MANIFEST.sha256 | 5d413b2bee67023d5777ac93f8ea7b6ac24c1295b7c622f956a59ef25dcda0de; consumed;17/17 unchanged |
| V3 execution-v3/result.json | 806e15f08f1ddeb232cccdafbd07c5239ed1bfc9f05287aaeb0b7cd60e311e5e; unchanged |
| oa286-host-format-diagnostic.6Nte5l/READ_ONLY_HOST_FORMATS.md | 7be917bf46785739f20634c6b16bf509b62e8760c278a68ca421ff44a06eba39 |
| oa286-full-replay-preparation/ordered-213-sql-inputs.tsv | 82c8cf293c81d08feb28e19b8369b3bc2a9fffebefc28531ab0ad77a4f858c25 |

The V4 directory was absent before preparation. All17 first-candidate files
and their manifest were copied before final repair into the withdrawn snapshot
directory; all17 still match. PRESTATE.md retains preparation/test history.
Final V4 has no actual execution directory. Mock temporary directories are not
real execution markers. The V3 marker and result remain untouched.

Canonical file changed:
`SYSTEM/DOCUMENTS/ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V2.md`
true pre d6a55af1a9f9ae5905af153c4aec1cffc8f56e4fdd9e04a99c5d52d59ad6c694;
post c62e441e6cbb7a820f8ef45cd6543edcbb24fa86843c461320ab86f7cf369925.
True pre copied at edit time to
`oa286-v4-repair-prestate.pyu1eT/ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V2.pre.md`.
Only status/§10.5 updated this turn. This107 file was confirmed absent at edit
time; its post hash is filed separately in the same prestate directory ledger
to avoid a self-hash cycle. Message106 and earlier evidence remain historical.

## 5. Proposed next exact GO — not executed

Approve ONE use of final V4 package manifest
`ec1c39f5732f958131323d04cd38aac70bf344674a48625f470b126c72efe82c`
under its frozen README/runtime checks:

- Start only the existing stopped zyra-oa198 local VM once with no host mounts,
  automatic forwarding, SSH-agent forwarding or saved configuration rewrite.
- Use only exact approved cached linux/arm64 images, an internal fresh Docker
  bridge and fresh named database volume. No existing database reset, no image
  fetch. Public VM-host-key bootstrap followed by the strictly pinned owned
  loopback127.0.0.1:55432 tunnel; no company credentials.
- Official pinned CLI/PG17 platform bootstrap,209 exact migration versions,
  unchanged persona+overlay inputs210–211, then harness212 and213 once each.
  Seeds off; stop on first failure; S0/S1/S2 validated with rollback equality.
- Inspect and remove only exact owned temporary project resources, stop own
  tunnel and named VM once, and verify cleanup. Preserve execution-v4 marker
  and result permanently. No reset, repair, retry, force stop or broad cleanup.

Exact new project is zyra-oa286-full-replay-final-v4-b827da. Internal bridge
does not mean blanket VM/daemon egress disablement; the no-download policy is
the frozen cached-image/CLI guard. Health polling is not SQL retry. Power loss
can prevent cleanup; an incomplete marker never authorises automatic rerun.
No production or Test cloud change, account/credential change, Apple record,
certificate, signing, build or upload is included. Later live stages still
require their exact scoped Founder approvals. Do not treat this local pass
as permission to shortcut into production or deliver a locked dummy Test app.
