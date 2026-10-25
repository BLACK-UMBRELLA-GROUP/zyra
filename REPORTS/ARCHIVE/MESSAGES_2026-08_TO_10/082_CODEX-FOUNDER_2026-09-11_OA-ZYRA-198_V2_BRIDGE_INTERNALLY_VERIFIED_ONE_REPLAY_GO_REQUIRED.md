# 082 — CODEX → FOUNDER
# SUBJECT: OA-ZYRA-198 V2 bridge internally verified — exact one-replay GO required
# DATE: 2026-09-11
# GOVERNANCE: AD-AIOS-109 · OA-ZYRA-198/283 · DR-ZYRA-227 · messages 080–081 · Founder V2 creation/test approval in Codex chat
# STATUS: V2 INTERNALLY VERIFIED / REPLAY NOT AUTHORISED / PRODUCTION APPLY HOLD

- V1 is preserved byte-for-byte; its consumed replay authority has not been
  reused.
- V2 fixes only the PostgreSQL 17 column-ACL postcondition and is frozen at
  SHA-256 `337b342df347b7e902d8da32bafd0a2b21516550b9234213298079304ca66aa1`.
- PostgreSQL 17 runtime and minimal-predecessor integration tests pass; the
  governed 208-file replay has not run.
- Production, the active SQL migration inventory/artifacts, both staged
  September migrations, TestFlight upload, git state/history and private
  credentials were untouched.
- A fresh Chrome window reached App Store Connect's login page only; current
  portal truth remains unverified and no Apple state was changed.

## 1 · Authority and exact boundary

The Founder authorised creation and internal testing of a new V2 replay-only
bridge while preserving V1, expressly withholding authority for a full replay
or any production access. The Founder also authorised one fresh Chrome window
for read-only App Store Connect verification.

This report records that bounded work. It does not grant or request a
production migration apply, Apple upload, external TestFlight release, git
write/index/history operation or private-credential access.

**Process deviation:** Codex invoked one read-only `git status --short` while
checking the pre-existing dirty worktree. It changed no file, index, ref,
object or history, but the invocation itself breached ZYRA's categorical
no-AI-git rule. It is recorded rather than treated as compliant. No further
git command was used, and the technical V1/V2 evidence is unaffected.

## 2 · Immutable V1 lineage

| V1 artifact | Bytes | SHA-256 |
|---|---:|---|
| bridge SQL | 28,387 | `461c3bd0e4ef4692229027c5659756983ed2048e1e78cf71e2148009d6729055` |
| README | 5,521 | `d883fe559f417d1ab8c5311cb7e521aeea1fdfe2b9262c0b7ef54567f5cbab21` |
| manifest | 7,237 | `71678199bb76cf43d66f1d755f401767a72b209df1142cdf0dba77223d285c63` |
| V1 artifact test | 20,192 | `11148da4d68ec8d63633a1a9db868b84451e65ebacc4810aa73bc9fb3b0bb975` |
| execution report 081 | 7,748 | `05b7f682e59516308f80b3b6cc249d7c758db8bf8dba1566410314451d0a4b3b` |

V1 remains outside `SOURCE/supabase/migrations`. No V1 byte changed. Its
single-use Founder replay GO was consumed by the measured `22023` result in
message 081 and cannot authorise V2.

## 3 · Exact V2 artifact

Path:
`SYSTEM/RESOURCES/MIGRATION_HISTORY/OA-ZYRA-198_2026-09-11_RECONSTRUCTED_REPLAY_BRIDGE_V2/20260811153415_oa198_reconstructed_question_bank_replay_bridge_v2.sql`

| Property | Measured value |
|---|---|
| Bytes | 28,501 |
| Mode | `0600` |
| SHA-256 | `337b342df347b7e902d8da32bafd0a2b21516550b9234213298079304ca66aa1` |
| Active migration path | false |
| Artificial replay ordering version | `20260811153415` |
| Full replay executed | false |

V2 differs from V1 in exactly one query block. It joins `pg_class` to obtain
the relation owner and replaces the zero-dimensional empty-array fallback:

```sql
aclexplode(COALESCE(attacl, '{}'::aclitem[]))
```

with PostgreSQL's canonical column-object default:

```sql
pg_catalog.aclexplode(
  COALESCE(
    attribute.attacl,
    pg_catalog.acldefault('c', class_row.relowner)
  )
)
```

Reversing only that block reproduces V1 byte-for-byte. The embedded question
bank is unchanged: 12,927 UTF-8 bytes, 72 rows / 71 qids, SHA-256
`eb355693f50651c7090aeaa5e7eb15187eb9a37855a785aaa259991cb1b43f90`.
The reconstructed catalog/security contract identity is unchanged at
`a929d23e5190ce238ef86a8786bdbaf0858337ae16a55cbf79572c6f2410850a`.

Companion artifact identities:

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| V2 README | 5,501 | `d1339f3c166d62e5f1f16e017475fe00e149002585fa53890edde1edb8cdbda5` |
| V2 manifest | 6,030 | `b003b60157a3db5d63e063f846134d321b7f0111b14b6da9f27abb482e4b50d4` |
| PostgreSQL runtime harness | 2,929 | `745bb3295e909db6febd5609f46677b5dcaa99ec860cd1195925ac2002f5d35e` |
| V2 Dart artifact test | 10,705 | `52b82f727d5581be8d88086f32435d353a457f4b7774f8082161c5acbf7ffef1` |

## 4 · PostgreSQL 17 runtime evidence

The read-only runtime harness executed successfully against cached image
`public.ecr.aws/supabase/postgres:17.6.1.165`, immutable image ID
`sha256:28f0e16a019e648089fc1a6d333549a55548f6019c15ae4bd7cd58b989027518`,
with `server_version_num = 170006`.

The disposable container used network mode `none`, no published ports, no
mounts, no seed, no project reference, no database URL and no application
migrations. The transaction was read-only and rolled back. It proved:

1. V1's zero-dimensional fallback raises SQLSTATE `22023`;
2. `acldefault('c', owner)` is one-dimensional with cardinality zero;
3. NULL, canonical-empty and non-empty column ACLs expand to 0, 0 and 1 rows;
4. a malformed two-dimensional ACL still raises `22023`; and
5. the final marker was `OA-ZYRA-198 V2 PG17 COLUMN ACL PASS`, exit `0`.

The full V2 bridge then executed once in a second no-network/no-port/no-mount
container against only the documented minimal predecessor contract: built-in
Supabase roles and a local `schema_migrations` table containing exactly
version `20260811152809`. No application migration or seed was loaded. It
committed with 72 rows / 71 qids, RLS on, FORCE RLS off, zero policies and one
unchanged predecessor-history row. This focused integration execution is not
the governed 208-file replay.

Both containers were removed. The isolated `zyra-oa198` Colima profile was
stopped and verified stopped.

## 5 · Tests and release-preparation evidence

| Check | Result |
|---|---|
| V2 artifact tests | PASS — 4/4 |
| combined replay/release gate tests | PASS — 35/35 |
| `flutter analyze` | PASS — no issues |
| repository checker | PASS — 186 files, 0 findings |
| checker unit test | PASS — 1/1 |
| full Flutter suite | 824 pass / 60 fail; every failure is existing approved visual-golden drift; no approved pixel changed or regenerated |
| current-source unsigned iOS release compile | PASS — ZYRA, `app.zyraconnect.zyra`, `1.0.0` build `2`, 24.8 MB |
| compiled app binary SHA-256 | `6a9f0fd20552ec3c05482d7286d1f3a1443b22284792cb0e7467f448cd91fe53` |

The unsigned compile is preparation evidence only. It is neither a signed
archive nor an upload candidate.

## 6 · App Store Connect read-only result

Local source and retained export evidence show automatic paid-team signing
for Team `9Y7Z8F36SJ`, bundle `app.zyraconnect.zyra`, and the Sign in with
Apple entitlement. A retained IPA made 2026-09-10 19:13 predates the Request
New Journey hold and is forbidden for upload.

The authorised fresh Chrome window navigated to App Store Connect Apps and
redirected to:

```text
https://appstoreconnect.apple.com/login?targetUrl=%2Fapps&authResult=FAILED
```

Authentication was therefore not available for a portal inspection. No app
record, agreement, tester, build, metadata or account state was changed. The
current App Store Connect record and upload state remain unverified.

## 7 · Quarantine and unchanged production-path evidence

The active migration inventory remains 207 SQL files at digest
`8a36926aaca155493f16a731ee498204f0d0225e2a5b41cc66f89e1da39b8861`.
It contains no `20260811153415` file. Any governed scratch replay must contain
the 207 active files plus V2 only, never V1 and V2 together.

The staged production artifacts remain byte-identical and unapplied in this
work:

| Artifact | SHA-256 |
|---|---|
| OA-ZYRA-283 boundary migration | `63381febeb9b1732447adb24a6225c1006f42171bc8b5b5e4f5a61712f54296d` |
| Request New Journey hold migration | `0ac36fd4c4c7ed03b8a4fe80ef75d4cb43c10355426d6a972814961f5e061545` |
| OA-ZYRA-283 post-apply harness | `e75657d67be8b84457e5ad2e63920bb3bff161b80092954f28fd43bf010ace7c` |
| Request New Journey post-apply harness | `be2980edfc388d2dab08fd92e87623f5e110b38563c7a083ddbc0a63d6bb7015` |

No production project was queried, changed or used as a test environment.

## 8 · True pre-state and post-state ledger

Documentation true pre-files were captured at edit time under
`/private/tmp/zyra_oa198_v2_docs_pre.CJ0GHy`.

| File | True pre-state SHA-256 | Post SHA-256 |
|---|---|---|
| V2 directory and SQL | absent | SQL `337b342df347b7e902d8da32bafd0a2b21516550b9234213298079304ca66aa1` |
| V2 runtime harness | absent | `745bb3295e909db6febd5609f46677b5dcaa99ec860cd1195925ac2002f5d35e` |
| V2 artifact test | absent | `52b82f727d5581be8d88086f32435d353a457f4b7774f8082161c5acbf7ffef1` |
| `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` | `ebdaad4535c3e67ca6de5c4d71164270d0ed65222127626e2ee2bdfc2bc38c09` | `9a87db27cfa26079f46f280420c198c17d766e63be9eb972ccadb2700cfa3508` |
| `SYSTEM/DOCUMENTS/ZYRA_JOURNEY_COMPATIBILITY_BOUNDARY_HANDOVER_CURRENT_VERSION_V1.md` | `ce68d33eac072a94d1c2aa397dd96ed37ac58fadcb1a19b2344f8a298a10e4d6` | `7e8e9cbf83a6c07a687de7ac78a4a7494364662f9834a23d601e3df13393adc9` |
| `CLAUDE.md` | `cb0b941a614242ab6d1b7fa96486a9bdfccdb0c2f9c875a445e91809e1421c04` | `f20cd7061f8e3d371d6dba9a3d3ecf1ae7c199f2da7522c4887aabde7ab6b19f` |
| `SOURCE/supabase/migrations/README_20260811_OA193.md` | `1a9d68fc69a4fbcb90a624ea138f883464a16869a66d90540637f3bae3a532f4` | `7242a65b42669083a518928d8172ea542ff715be6f32553721ee289981ea2963` |
| `SYSTEM/DOCUMENTS/ZYRA_APPLE_SIGNIN_HANDOVER_CURRENT_VERSION_V1.md` | `ff88789c194f61305699cbce0570c9f7b65ef40f8d5bf185ab611ad7cbed2c04` | `8563bbb74fb749a4d0d3682d269bbe6e74fb381e8ac2521e9a2e33d3f3b257db` |
| `SYSTEM/DOCUMENTS/ZYRA_APP_STORE_RUNBOOK_CURRENT_VERSION_V1.md` | `4b31b2b99127116a1417b2caa2cd42965ca9a7727c8df603a0b9f6eee3d113a8` | `28f9e79b47316ecce6d27540243d861519d5545fc6f823a89e1ea6c2fdbc59fb` |
| `SYSTEM/DOCUMENTS/ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V3.md` | `936625380367bfeb29d7bfa0b57ebf980fd1b0cab1d6cb72340057bc16c20dc6` | `74d16cb4c309e9994fd5e49c2d1989fc509a1fd093cd696df36df94f8f086c09` |
| Message 082 | absent | returned at handoff; self-hash cannot be embedded without changing itself |

## 9 · Exact next replay gate

V2 is ready for one governed replay but has no replay authority. The exact
single-use wording required before any further destructive reset is:

> I authorise exactly one destructive reset of a fresh disposable local
> PostgreSQL 17 database using V2 bridge SHA-256
> 337b342df347b7e902d8da32bafd0a2b21516550b9234213298079304ca66aa1.
> Seedless and isolated; no production access; stop at the first result; no
> repair or retry.

That future replay remains a separate action. The known later static
`public.zyra_probe_score` creator gap may become the next measured frontier;
this V2 correction neither conceals nor resolves it.

— END OF MESSAGE 082 —
