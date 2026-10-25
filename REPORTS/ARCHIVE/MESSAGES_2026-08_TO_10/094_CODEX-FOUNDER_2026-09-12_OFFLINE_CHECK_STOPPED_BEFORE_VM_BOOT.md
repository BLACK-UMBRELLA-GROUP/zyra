# CODEX → FOUNDER — ISOLATED CHECK STOPPED BEFORE VM BOOT

**Date:** 2026-09-12  
**State:** FOUNDER GO → STARTUP ATTEMPTED → STOPPED; SQL NOT EXECUTED  
**Owner:** Codex / Astra; Founder sole approver  
**Action:** OA-ZYRA-286 remains open; no new OA or decision identifier

## 1. Outcome and exact authority

Founder answered **Approve isolated database check** to the exact proposal for
package `9f3fc926…`: start only the existing `zyra-oa198` VM with host mounts
and port forwarding disabled, run one fresh network-disabled test container,
remove it, and stop the VM; no existing database reset, cloud change,
production data, Apple upload or retry.

Exactly one VM-start command was attempted. It failed on local sandbox
permissions before VM boot. No SQL execution, container creation or database
reset occurred. No retry or repair followed. This is an environment failure,
not a SQL test result or a TestFlight completion.

## 2. Evidence

Input validation before start returned `PACKAGE_HASHES_PASS; runtime not
contacted`. The VM was stopped; its runner `execution-v1` directory was absent.
Installed Colima 0.10.3 help and matching source were internally reviewed to
confirm explicit no-mount/no-forwarding flags override the old saved profile
before resuming an existing VM. Native-only execution disables binfmt setup.

Single invocation at 14:12:33–14:12:34 BST:

```sh
/opt/homebrew/bin/colima start --profile zyra-oa198 --activate=false --mount none --ssh-agent=false --ssh-config=false --port-forwarder none --save-config=false --kubernetes=false --network-address=false --network-host-addresses=false --binfmt=false
```

Exit 1. A sandbox warning denied `sysctl.proc_translated`. Startup then warned
that it could not clear the local Lima network's `leases.json` and stopped on:

```text
error starting vm: error writing Lima network config file: open /Users/shakeelahmad/.colima/_lima/_config/networks.yaml: operation not permitted
```

Read-only follow-up at 14:12:52 BST: VM **not running**. The explicit Docker
socket, instance host-agent PID and package `execution-v1` directory were all
absent. The execute-once runner was not invoked. No container needed removal;
no VM needed stopping. Nothing was deleted by Codex cleanup.

Generated runtime `lima.yaml` changed before startup failed: mounts are absent,
the port rule ignores all application forwarding, and required local Docker/
containerd control sockets remain. `--save-config=false` does not freeze this
generated file. Saved user profile and hash-pinned package remain unchanged.

| Artifact | Before SHA-256 | After SHA-256 |
|---|---|---|
| Saved `~/.colima/zyra-oa198/colima.yaml` | `069a21a0f329460327cfc6ced19a61e904a15dfa82e45dc4ebc6cf6b5f65902d` | same |
| Generated instance `lima.yaml` | `e032a5dc758eec1bb55f4bebdd7d2b55451917ecccf84bb3cae84a65b77f1559` | `39d7e7055d6a94df00ccbd70f2baa77eab8a55bc9effe56f36dbfa2764ba7309` |
| Approved package manifest | `9f3fc926dec059fd2035173ab235cb395365cb7832da02b0fc03a1ffc1ecfd9d` | same |
| Approved runner | `5882b29cf790f67234ffa1878f6b1e5609fb37f6eebb90b537abe8b9ae579484` | same |

Runtime pre-hashes were read before start; generated files are not represented
as byte-preserved snapshots. No hand-edited runtime repair was made.

## 3. Record change / true pre-state

Only existing canonical edit: append the failed-start result to OA-ZYRA-286.
True pre-file captured at edit time:
`SYSTEM/RESOURCES/TEMPORARY/OA-ZYRA-286_2026-09-12_OFFLINE_STOP_PRESTATE.aqF2af/OUTSTANDING_ACTIONS_V2.md.pre`.

- OA register pre SHA-256:
  `f1ec22d4e618ef0fedeb509dc705085de70463c586545f76860bc6b044dc0af8`.
- OA register post SHA-256:
  `e647284a8e17d5e4b15a66a4850029a9ff2827df47c4a976729a3335bb98f410`.
- New task-local outer-workflow evidence:
  `evidence/oa286-persona-offline-v1-vm-authority.md`, SHA-256
  `cc2c813d968d114f6c5c247138f2216182de5ca4364922ac6c01bcd1fcb2ef54`.
  This file is outside the immutable package and records the attempted start.
- Message 093 is preserved, SHA-256
  `8aa8c98b3752310951893d7e8aa625e2acc112b28c34eafb87c37bc8de7ebc7d`.
- This report is new, pre-state ABSENT.

## 4. Stop boundary and next authorization

The one-start authority reached its failure stop. The absent runner tombstone
does not reopen that outer workflow authority. Any startup retry requires new
Founder GO and appropriate local runtime permissions; it must keep this exact
package and all isolation/no-retry conditions. No new SQL repair is indicated
by this failure. Both SQL runtime harnesses remain unrun.

No Supabase or Apple call occurred during this check stage. Earlier message 093
records the separately authorized empty Test-project creation. Production and
existing Founder Internal build 2 remain untouched. ZYRA Test is not yet on
TestFlight. No source, migration, credential, signing, image or git change was
made during this check stage. No tests are reported as passing by inference.
