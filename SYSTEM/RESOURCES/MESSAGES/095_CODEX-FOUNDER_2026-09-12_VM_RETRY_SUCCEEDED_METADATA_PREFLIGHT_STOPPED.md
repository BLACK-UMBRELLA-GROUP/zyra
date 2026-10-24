# CODEX → FOUNDER — VM RETRY SUCCEEDED; METADATA PREFLIGHT STOPPED

**Date:** 2026-09-12  
**Authority:** Founder answered “yes” to one VM-start retry with required local
permissions, the unchanged isolated check once, and cleanup  
**State:** STARTUP EXECUTED → METADATA PREFLIGHT FAILED → VM STOP POST-VERIFIED  
**Owner:** Codex / Astra; Founder sole approver  
**Action:** OA-ZYRA-286 remains open; no new identifier

## 1. Result

The permission blocker from 094 was avoided through command-scoped escalation
of the exact Colima start, not general filesystem permissions. The single
startup succeeded, exit 0, 14:15:28–14:15:38 BST. Generated config has no host
mounts and ignores application-port forwarding. Required VM-management SSH,
Unix control sockets and an internal DNS tunnel remain; no claim of a wholly
networkless VM is made. The prospective test container itself is pinned to
network none. No default-context activation was requested (`--activate=false`).

Read-only container inventory returned zero containers. Before consuming the
runner's one-use marker, its exact image-inspection template was run once:

```sh
/opt/homebrew/bin/docker --host unix:///Users/shakeelahmad/.colima/zyra-oa198/docker.sock image inspect sha256:28f0e16a019e648089fc1a6d333549a55548f6019c15ae4bd7cd58b989027518 --format '{"Id":{{json .Id}},"Volumes":{{json .Config.Volumes}}}'
```

Exit 1:

```text
template parsing error: template: :1:43: executing "" at <.Config.Volumes>: map has no entry for key "Volumes"
```

This is a defect in Codex's test tooling: the strict field lookup assumes an
optional image-config key exists. The same expression is in the pinned runner.
No image-identity/volume-validation pass is claimed from this failed template.
No execute-mode runner, container creation, initdb, SQL or image pull occurred.
The package `execution-v1` directory remains absent. No corrected template was
run against the daemon and no repair or retry followed.

## 2. Cleanup and scope

One approved `colima stop --profile zyra-oa198` completed, exit 0,
14:16:13–14:16:15 BST. At 14:16:29, status again reported not running; Docker
socket and host-agent PID were absent. No container needed deletion. The saved
profile, generated Lima config and global network-config hashes all match
their true pre-retry snapshots. Ordinary runtime logs/disk state are not
claimed byte-unchanged merely because configuration hashes match.

No Supabase, production, Apple, credential, signing, source, SQL, migration or
git action occurred in this turn. Both SQL harnesses remain UNRUN. Existing
ZYRA build 2 stays untouched; ZYRA Test is not yet delivered.

## 3. Evidence and hashes

Task-local paths below are relative to
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/`.

| Artifact | SHA-256 |
|---|---|
| Unchanged approved manifest | `9f3fc926dec059fd2035173ab235cb395365cb7832da02b0fc03a1ffc1ecfd9d` |
| Unchanged approved runner | `5882b29cf790f67234ffa1878f6b1e5609fb37f6eebb90b537abe8b9ae579484` |
| `evidence/oa286-persona-startup-retry-authority.md` | `d90030ce78d978d31553d85c9983a6a4d2117f812008a8a6899d5cacc8801fc8` |
| `evidence/oa286-persona-startup-retry-prestate.31FsxN/start-output.log` | `81b872768a7f2f5f4924fd94a11330f4efc0f285a8dd386bfd72eef6093ffe16` |
| Saved profile, pre = post | `069a21a0f329460327cfc6ced19a61e904a15dfa82e45dc4ebc6cf6b5f65902d` |
| Generated Lima config, pre = post | `39d7e7055d6a94df00ccbd70f2baa77eab8a55bc9effe56f36dbfa2764ba7309` |
| Global Lima networks config, pre = post | `7963c5d3a2e20c0edb713d2d16693c449f95e8a590bf90ba742af6d8d96fe7ad` |

True runtime configuration copies were captured before startup in the named
task-local prestate directory. Only existing canonical edit: append this result
to OA-ZYRA-286. True pre-file at edit time:
`SYSTEM/RESOURCES/TEMPORARY/OA-ZYRA-286_2026-09-12_METADATA_STOP_PRESTATE.gpNjqE/OUTSTANDING_ACTIONS_V2.md.pre`.

- OA register pre: `e647284a8e17d5e4b15a66a4850029a9ff2827df47c4a976729a3335bb98f410`.
- OA register post: `da003d489a442b3cf7390c36a268b908b02e687a08181aeb6c9866d85ab9530b`.
- Report 095 pre-state: ABSENT. Reports 093/094 and V1 package preserved.

## 4. Proposed correction — not implemented or authorised by this report

Use an optional-key-safe metadata reader while retaining strict image identity,
allowed-volume-path validation and failure-before-create behavior. A minimal
candidate is Go-template `index .Config "Volumes"`; internal review proposed
tests for missing/null/empty/allowed/unexpected volumes, malformed metadata,
and exact cleanup on later failures. No such successor tests are claimed run.

The wrapper should be corrected and internally tested in a separately hashed
successor, preserving V1 and its failure evidence. Do not retry the unchanged
broken wrapper. The current approval has reached its stop condition. Any new
runtime check needs its exact successor package and new Founder execution GO.
