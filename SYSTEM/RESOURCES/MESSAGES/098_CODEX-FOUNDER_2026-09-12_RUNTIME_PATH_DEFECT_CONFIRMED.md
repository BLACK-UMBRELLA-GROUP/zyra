# CODEX → FOUNDER — LOCAL RUNTIME PATH DEFECT CONFIRMED

**Date:** 2026-09-12  
**Authority:** Founder “proceed” to the read-only image diagnostic in097 §4  
**State:** DIAGNOSTIC EXECUTED → POST-VERIFIED; DATABASE TEST STILL UNPROVEN  
**Owner:** Codex / Astra; Founder sole approver  
**Action:** OA-ZYRA-286 remains open; no new identifier

## 1. Finding and responsibility

The local harness entrypoint assumes Debian-style binaries at
`/usr/lib/postgresql/17/bin/`. The pinned image instead exposes PostgreSQL17.6
through `/nix/var/nix/profiles/default/bin/`. This is a Codex-authored local
runner defect, not evidence of a product, Apple or live database failure.

One fresh diagnostic container on image
`sha256:28f0e16a019e648089fc1a6d333549a55548f6019c15ae4bd7cd58b989027518`
measured the following:

| Prerequisite | Observed evidence |
|---|---|
| Effective user | uid100 postgres; expected-user PASS |
| V2 fixed initdb, pg_ctl, psql and postgres paths | All ABSENT_OR_NOT_EXECUTABLE |
| PATH initdb, pg_ctl, psql and postgres | All resolve through `/nix/var/nix/profiles/default/bin/`; all report17.6 |
| pg_config --bindir | `/nix/var/nix/profiles/default/bin` |
| /tmp | root-owned mode1777; directory/writable/searchable PASS |
| /tmp/oa286-persona-pg | Absent, PASS |

Resolved initdb/psql store prefix:
`/nix/store/axzw4y8zm4i1q6kay5rgkqavn2p1lzll-postgresql-17.6/bin/`.
Resolved pg_ctl/postgres store prefix:
`/nix/store/shgvzk1xmsqc472mhcwc64jgncax5fkx-postgresql-and-plugins-17.6/bin/`.

V2's unchanged shell tests the username first, then runs
`test -x /usr/lib/postgresql/17/bin/initdb` under `set -e`. The first check
passes and that executable check fails. This identifies the silent early
exit reported in097. Database initialization and SQL were never reached.
Later runtime prerequisites and SQL correctness remain unproven; fixing this
path is not a claim that the full database test will pass.

The earlier41 wrapper tests exercised metadata/runner behaviour, not binaries
inside the real image. Their reported coverage stands; it did not cover this
entrypoint prerequisite. Future preparation should include explicit labelled
prerequisite checks, not another silent failure.

## 2. Exact bounded execution and cleanup

VM `zyra-oa198` was confirmed stopped before one start at14:41:56 BST.
Startup completed14:42:06 with the same isolation overrides: mount none,
application-port forwarding none, SSH-agent/config off, activation off,
save-config false, Kubernetes/binfmt/network-address settings off. Required
VM-management SSH/control sockets/internal DNS remain; the VM itself is not
claimed networkless.

The diagnostic runner verified an empty container inventory and exact image
with Volumes:null. It created and started exactly one container:

- Name: `zyra-oa286-diagnostic-v1-571b1b49c3fb`.
- ID: `26780a14155656a3596c2d28193c0d18ddc78b51207d0012dbb6d5365f5d302b`.
- Before start: exact ID/name/ownership label, postgres, created, network none,
  no binds/ports, read-only root, unprivileged, Mounts:[] verified.
- Entrypoint: only identity/path/permission inspection and executable version
  queries. No environment dump, database initialization/start, SQL or stdin.
- Result: exit0, one `DIAGNOSTIC_COMPLETE_NO_DATABASE_STARTED` marker.
  “Completed” means collection completed, not that all prerequisites passed.
- Fresh exact ID/name/label check before removal; only this disposable
  diagnostic container removed. Post-cleanup inventory empty. Its temporary
  filesystem is discarded; all diagnostic output is preserved.
- VM stop14:42:21–14:42:23, exit0;14:42:35 status not running, socket and
  host-agent PID absent. No existing database or unrelated container removed.

No retry, repair, migration, cloud/production/Apple action, image pull, source
edit or git command occurred. Internal source/evidence review corroborated
containment and the measured diagnosis; it is not external approval.

## 3. Evidence and true pre-states

Task root:
`/Users/shakeelahmad/Documents/Codex/2026-08-29/supabase-plugin-supabase-openai-curated-remote-3/`.
New diagnostic package: `evidence/oa286-runtime-diagnostic-v1/`.
New consumed marker/logs: its `execution-v1/` subdirectory.
Runtime true pre-copies/start/stop logs:
`evidence/oa286-runtime-diagnostic-prestate.RJmKwK/`.

| Artifact | SHA-256 |
|---|---|
| diagnostic.sh | `6d8cfe6396110816fc3624dcad882a07a3c3af43328108ffb43f38673829f5d0` |
| diagnose.py | `860bb3f5ef2f1b1e79486181f862d4ea779c7ccd9dfd88748bd179040530adfa` |
| AUTHORITY.md | `8cf37af162dd63375863cc30d05bccda944357ec4b632a0e04fac456ce77836f` |
| 01.log / 09.log, empty inventories | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| 02.log, image | `fe521571d271d506314826043fdb9fe432fe777bfe598275555651213ad4107b` |
| 03.log / 08.log, created/removed ID | `e83551923f649a0311edb794cafff8dd7cd87a045e368b726d1a05a4090044d7` |
| 04.log, created isolation | `794da3352b814a6f00a6da8bb200df68fb3bff0e9063e506075ce6daadd2d92f` |
| 05.log, measured diagnostics | `88ed140b50867bcb8f0474e8f9a88716d85af8b8b69de1a3ccbeff6f86899e72` |
| 06.log / 07.log, exited/cleanup ownership | `2e5e4ff1c4a609dbad6bcc909d684af65656b38f3f0e197e599ff40a6671be1b` |
| commands.json | `5da07c6985ee2a5fa4451e1b2cc32941ffea42a24d3de069b5cf524dbc11a65f` |
| result.json | `044a8f34a653c3a427585f495e21d5511f5b54a55ccd03afbcdb03f7ac3e4278` |
| start-output.log | `7278b580d175684b0ce2a8f10aee59951f888dd30852068c37f27fa256e0aed1` |
| stop-output.log | `aa37c0223ba84fc6fc3af1ff55a6c0dbd21d5789a8f982cddcd41ddb4dd29165` |

Saved profile pre=post:
`069a21a0f329460327cfc6ced19a61e904a15dfa82e45dc4ebc6cf6b5f65902d`.
Generated Lima pre=post:
`39d7e7055d6a94df00ccbd70f2baa77eab8a55bc9effe56f36dbfa2764ba7309`.
Networks config pre=post:
`7963c5d3a2e20c0edb713d2d16693c449f95e8a590bf90ba742af6d8d96fe7ad`.
Runtime disk/log changes from boot are not claimed absent.

V2 package hash-only verification passed after diagnosis (no runtime contact),
manifest `2f84c5e286c39bbeace7f105862e77536077b48fdacd13013a57614f984f486f`.
All six consumed V2 logs and result hash still match097.
V1 manifest remains
`9f3fc926dec059fd2035173ab235cb395365cb7832da02b0fc03a1ffc1ecfd9d`.
Neither old attempt marker was removed, altered or reused.

Only existing canonical edit: appended measured result to OA-ZYRA-286.
True pre-file:
`SYSTEM/RESOURCES/TEMPORARY/OA-ZYRA-286_2026-09-12_RUNTIME_DIAGNOSTIC_PRESTATE.Fde0wp/OUTSTANDING_ACTIONS_V2.md.pre`.
Register pre:
`b2a47a04427950803f10893672cb77a52ba839ea016a38c9b9602849219ff9a6`.
Register post:
`cb6c7d50c909d5aab18a109a5cd27c90aaa59c84a721504f098f7353e361455f`.
Report098 and new diagnostic evidence pre-state: ABSENT.

## 4. Next bounded work, not performed

Prepare a separately versioned local runner using the measured executable
paths, explicit prerequisite/version diagnostics and unchanged SQL payloads.
Internally validate it without starting a database. Preserve V1/V2 and this
diagnostic evidence. Only then present the exact package for a new single-use
database execution GO; this diagnostic approval authorises no database retry.

ZYRA Test is still not delivered. Existing ZYRA TestFlight remains untouched.
