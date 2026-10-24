# OA-ZYRA-198 reconstructed question-bank replay bridge V2

**Status:** CODEX INTERNALLY VERIFIED / REPLAY NOT AUTHORISED / PRODUCTION APPLY PROHIBITED  
**Authority:** Founder's exact V2 creation and internal-test approval, 2026-09-11  
**Owner:** Codex under AD-AIOS-109  
**Outstanding action:** OA-ZYRA-198

## Outcome

V2 corrects the single PostgreSQL 17 column-ACL postcondition defect measured
during the one authorised V1 replay. The V1 replay stopped inside bridge
statement 11 with SQLSTATE `22023` because
`aclexplode('{}'::aclitem[])` rejects a zero-dimensional ACL array. Migration
`20260811153416` never started.

V1 remains immutable. Its consumed execution authority does not transfer to
V2, and V2 has not been placed in `SOURCE/supabase/migrations`, used in a full
replay, applied to production, or uploaded to Apple.

## Immutable V1 lineage

| File | Bytes | SHA-256 |
|---|---:|---|
| V1 bridge SQL | 28,387 | `461c3bd0e4ef4692229027c5659756983ed2048e1e78cf71e2148009d6729055` |
| V1 README | 5,521 | `d883fe559f417d1ab8c5311cb7e521aeea1fdfe2b9262c0b7ef54567f5cbab21` |
| V1 manifest | 7,237 | `71678199bb76cf43d66f1d755f401767a72b209df1142cdf0dba77223d285c63` |
| V1 artifact test | 20,192 | `11148da4d68ec8d63633a1a9db868b84451e65ebacc4810aa73bc9fb3b0bb975` |
| execution report 081 | 7,748 | `05b7f682e59516308f80b3b6cc249d7c758db8bf8dba1566410314451d0a4b3b` |

## Exact V2 correction

Bridge file:
`20260811153415_oa198_reconstructed_question_bank_replay_bridge_v2.sql`

- 28,501 bytes;
- SHA-256
  `337b342df347b7e902d8da32bafd0a2b21516550b9234213298079304ca66aa1`;
- artificial replay ordering version `20260811153415`, unchanged; and
- active migration path: false.

The SQL differs from V1 in one query only. It joins `pg_class` for the actual
relation owner and replaces the invalid dimensionless empty ACL fallback with
PostgreSQL's canonical column-object default:

```sql
pg_catalog.aclexplode(
  COALESCE(
    attribute.attacl,
    pg_catalog.acldefault('c', class_row.relowner)
  )
)
```

`acldefault('c', owner)` is a valid one-dimensional, zero-entry ACL. Real
column privileges still expand and fail the zero-column-ACL postcondition;
malformed ACL arrays still fail closed inside `aclexplode`.

Everything else is byte-equivalent after reversing that one block. The
embedded question-bank projection remains 12,927 UTF-8 bytes, 72 rows / 71
qids, SHA-256
`eb355693f50651c7090aeaa5e7eb15187eb9a37855a785aaa259991cb1b43f90`.
The reconstructed catalog/security contract identity remains
`a929d23e5190ce238ef86a8786bdbaf0858337ae16a55cbf79572c6f2410850a`.

## PostgreSQL 17 runtime PASS

Focused runtime test:
`SOURCE/supabase/tests/zyra_oa198_replay_bridge_v2_column_acl_pg17_runtime.sql`

- 2,929 bytes;
- SHA-256
  `745bb3295e909db6febd5609f46677b5dcaa99ec860cd1195925ac2002f5d35e`;
- read-only transaction, ending in rollback; and
- application migrations, seed, project reference and database URL: absent.

It executed successfully against cached image
`public.ecr.aws/supabase/postgres:17.6.1.165`, immutable image ID
`sha256:28f0e16a019e648089fc1a6d333549a55548f6019c15ae4bd7cd58b989027518`,
with PostgreSQL `server_version_num = 170006`. The container had network mode
`none`, no published ports, no mounts and no production connection. It proved:

- V1's `aclexplode('{}'::aclitem[])` control raises `22023`;
- the canonical column default is one-dimensional with cardinality zero;
- NULL and canonical-empty column ACLs expand to zero privilege rows;
- a non-empty ACL expands to one privilege row; and
- a two-dimensional ACL remains rejected with `22023`.

Result marker: `OA-ZYRA-198 V2 PG17 COLUMN ACL PASS`.

The full V2 bridge then executed once in a second container of the same image
against only its minimal documented predecessor contract: Supabase's built-in
roles plus a local `schema_migrations` table containing exactly version
`20260811152809`. No application migration or seed was loaded. The bridge
reached `COMMIT`; its post-state was 72 rows / 71 qids, RLS on, FORCE RLS off,
zero policies and one unchanged predecessor-history row. That focused bridge
integration is not the governed 208-file replay.

Both disposable containers were removed and the isolated Colima profile was
stopped after the tests.

## Quarantine and future gate

The active production-path inventory remains 207 SQL files at digest
`8a36926aaca155493f16a731ee498204f0d0225e2a5b41cc66f89e1da39b8861`.
It contains no `20260811153415` file. A future governed scratch inventory must
contain the unchanged 207 active files plus V2 only—never V1 and V2 together.

A separate exact Founder one-replay GO must name the final V2 SQL hash before
any destructive full reset. That future replay must remain seedless, unlinked,
localhost-contained and disposable, and must stop at its first result. The
known later static `public.zyra_probe_score` creator gap may become the next
measured frontier; this V2 proof does not conceal or resolve it.

Production apply remains prohibited. The two staged September migrations,
production data/history, TestFlight and the private credential store were not
touched by this V2 test. No git write, index or history operation occurred; a
single read-only `git status --short` inspection was used when checking the
pre-existing dirty worktree and changed no repository state. That invocation
was nevertheless a process deviation from ZYRA's categorical no-AI-git rule;
it is disclosed in message 082 and no further git command was used.
