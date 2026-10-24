# CODEX → FOUNDER — V2 STOPPED / CLEANUP VERIFIED

**Date:** 2026-09-12  
**Authority:** Founder “ok proceed” to the exact one-use V2 isolated check in
096 §5; one named VM start, one run, cleanup and stop; no reset/cloud/retry  
**State:** EXECUTED → STOPPED; CLEANUP POST-VERIFIED; NO DATABASE PASS  
**Owner:** Codex / Astra; Founder sole approver  
**Action:** OA-ZYRA-286 remains open; no new identifier

## 1. Measured outcome

V2 manifest `2f84c5e286c39bbeace7f105862e77536077b48fdacd13013a57614f984f486f`
was checked before execution and is unchanged afterwards. The named VM was
stopped before the one authorised start. Start succeeded, exit0,
14:31:05–14:31:18 BST, with no host mounts/application-port forwarding, no
SSH-agent forwarding, no context activation, Kubernetes or binfmt setup.
The required management SSH/Unix sockets/internal DNS tunnel remain as in 096.
Read-only container inventory was empty before execution.

The exact runner was invoked **once**. Its sequence was:

| Stage / log | Observed result |
|---|---|
| 01 image inspection | Pinned image ID matched; Volumes:null; corrected reader passed |
| 02 create | One new container ID returned |
| 03 pre-start inspect | Exact ID/name/label; created; postgres; network none; no binds/ports; read-only; not privileged; Mounts:[] |
| 04 start + immutable input | Exit1; captured output is zero bytes |
| 05 cleanup inspect | Same exact ID/name/label; exited1 |
| 06 exact removal | Returned the exact created container ID |

Container: `zyra-oa286-persona-v2-6a1d2c10a99e`.
ID: `9f6596eccd7cff7d2460ab056fb14fa0fc0d8f8405e7f8c40531682b39498a00`.

Runner result: STOPPED, reason **Docker command 4 failed (1); no retry**,
cleanup **exact_owned_container_removed**. No PostgreSQL/initdb/psql/harness
output or PASS marker was produced. No SQL test is reported passed or failed.
An early silent shell prerequisite failure is consistent with the empty output,
but it does not identify which prerequisite failed. The hard-coded binary paths,
effective-user check and temporary-directory guard were not independently
measured inside the image. Do not assert an exact cause from this evidence.

## 2. Cleanup and preserved boundaries

A separate read-only container inventory returned empty after removal. One
VM stop completed exit0, 14:31:59–14:32:01 BST. At14:32:18, status reported not
running; Docker socket and host-agent PID were absent. No unrelated container
or existing database was removed or reset.

The real execution-v2 marker and all six raw logs/result remain retained and
consumed. No retry, modified SQL, repaired entrypoint, diagnostic container,
image pull, production/cloud/Apple operation, source edit or git command occurred.
The original V1 package/failure records remain preserved. Internal filesystem
review corroborated the reached stages and cleanup; it is not external approval.

## 3. Evidence identities

Task-local root:
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/`.
Execution evidence: `evidence/oa286-persona-offline-v2/execution-v2/`.

| Artifact | SHA-256 |
|---|---|
| 01.log | `fe521571d271d506314826043fdb9fe432fe777bfe598275555651213ad4107b` |
| 02.log | `f3dca2c4e996f1d9663ccc5cad2baf8aae6c88aff28e6b0075d52cd0d5100a37` |
| 03.log | `8f9ec25f59c1d7908772ad3e6c01110d7b37b0e0bb51f3980cdcc4a89b1bcec3` |
| 04.log (empty) | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| 05.log | `337b98537e9237a7242b2b818cdb9a8f12ff529db49231cc96178e92929accdc` |
| 06.log | `f3dca2c4e996f1d9663ccc5cad2baf8aae6c88aff28e6b0075d52cd0d5100a37` |
| result.json | `665658e0de4d94e4cb30794c50d0c22a08d5c18143331c46e49a6bc2d3047e6c` |
| ../V2 run.py, unchanged | `133892b03f8d7b4ed96d224799a864ceef6e2692489c4f812f1ed9606f1e9068` |

Outer evidence file `evidence/oa286-persona-v2-execution-authority.md`:
`d3881660b2c9766e006f95ce4f3ac9060e05f78a2abf261829f88d6ec9625a8d`.
True runtime pre-copies and full start/stop output:
`evidence/oa286-persona-v2-execution-prestate.3obUTX/`.

- start-output.log: `7da5fb597ab44938a5a0a0a78cedd650ba11cd5ac37a786c89b136b476bdacf9`.
- stop-output.log: `8a235900800fe1cb0bb5db2028991353fcbffbc30674a1b9e11cb3ebdcf7ff09`.
- Saved profile pre=post: `069a21a0f329460327cfc6ced19a61e904a15dfa82e45dc4ebc6cf6b5f65902d`.
- Generated Lima pre=post: `39d7e7055d6a94df00ccbd70f2baa77eab8a55bc9effe56f36dbfa2764ba7309`.
- Networks config pre=post: `7963c5d3a2e20c0edb713d2d16693c449f95e8a590bf90ba742af6d8d96fe7ad`.

Runtime disks/logs are not claimed byte-unchanged merely because config matches.
Only existing canonical edit: appended OA-ZYRA-286 result. True pre-file:
`SYSTEM/RESOURCES/TEMPORARY/OA-ZYRA-286_2026-09-12_V2_EXECUTION_PRESTATE.bXqJGk/OUTSTANDING_ACTIONS_V2.md.pre`.

- Register pre: `0afa75e6344d06b913325c17c2dd9b1e99aece4f4ac9c360e690cc06ff244574`.
- Register post: `b2a47a04427950803f10893672cb77a52ba839ea016a38c9b9602849219ff9a6`.
- Report 097 and this execution's evidence had pre-state ABSENT.

## 4. Next bounded proposal — held for new Founder authority

Inspect the same pinned local image's effective user, PostgreSQL executable
locations/version and temporary-directory prerequisites without starting
PostgreSQL or executing SQL. This may use one fresh read-only/network-disabled
diagnostic container on the same named VM, then exact-owned removal and VM stop.
No secrets/env dump, host mounts, cloud connection, reset, migration or Apple
action. Emit explicit diagnostic results rather than silent shell tests.

This proposal is not another database run and does not authorise one. Any
subsequent corrected runtime package must preserve consumed V2 evidence and
receive its own exact execution GO. The 41 local wrapper tests remain valid,
but do not prove binary paths or database startup. ZYRA Test is not delivered;
the existing ZYRA TestFlight build remains untouched.
