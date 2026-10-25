# OA-ZYRA-198 reconstructed probe-score replay bridge

**Status:** CODEX INTERNALLY VERIFIED / REPLAY NOT AUTHORISED / PRODUCTION APPLY PROHIBITED  
**Authority:** Founder's 2026-09-11 direction to complete every safe TestFlight prerequisite  
**Owner:** Codex under AD-AIOS-109  
**Outstanding action:** OA-ZYRA-198

## Outcome

The V2 question-bank bridge passed its one authorised full replay. The next
measured frontier was historical migration `20260811233813`, which expects
`public.zyra_probe_score` to exist but contains no creator for it. This
quarantined artifact reconstructs that missing relation immediately before the
unchanged historical migration.

It has not been placed in `SOURCE/supabase/migrations`, used in a full replay,
applied to production or uploaded to Apple. The consumed V2 replay authority
does not authorise another reset.

## Provenance result

An exhaustive read-only retained-record search found no original creator SQL,
migration version, filename or `schema_migrations` statement for
`public.zyra_probe_score`. The surviving 2026-08-12 stewardship record proves
that it was a two-row, RLS-off scratch table from the 2026-08-10/11 scoring
analysis, retained and hardened rather than dropped.

A bounded read-only production catalog inspection on 2026-09-11 recovered the
current structural identity without reading row values:

- ordinary permanent table, owner `postgres`;
- columns, in order: nullable `viewer text`, nullable
  `rows_returned integer`, nullable `score numeric`;
- no defaults, identities, generated columns, constraints, indexes, policies,
  triggers, rules, table comment or column comments;
- default replica identity, RLS on and FORCE RLS off after the historical
  hardener;
- table ACL exactly `postgres` + `service_role`, with `anon` and
  `authenticated` denied; and
- two live scratch rows, whose values were not queried or copied.

Those catalog facts establish the reconstruction schema. They do not recover
the original creator statement, its timestamp, statement boundary or the two
ephemeral analysis rows. The bridge deliberately creates an empty table
because the governed clean replay is seedless and inventing or copying scratch
results would be false provenance.

## Exact artifact

Bridge file:
`20260811233812_oa198_reconstructed_probe_score_replay_bridge.sql`

- 7,302 bytes;
- mode `0600`;
- SHA-256
  `9f9a818f3370b849ba1ff21f1d4ea9c3adb9ab866b22e15f6ba7a03454b46b46`;
- artificial replay ordering version `20260811233812`; and
- active migration path: false.

The bridge fails closed unless migration history exists, execution is by
`postgres`, predecessor `20260811233755` is the exact frontier, neither the
bridge nor target/later versions are recorded, and the relation is absent. It
then creates only the three catalog-proven nullable columns and verifies the
pre-hardening relation contract. It adds no rows, key, default, index, policy,
grant or product behavior.

The unchanged next migration is 2,421 bytes at SHA-256
`3934282f2b2d97c3bac7b6cac42c4044942d69c5a59111ffb2e672d360e73c95`.
Its exact table statements remain:

```sql
ALTER TABLE public.zyra_probe_score ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.zyra_probe_score FROM anon, authenticated;
```

The unchanged V2 question-bank bridge remains 28,501 bytes at SHA-256
`337b342df347b7e902d8da32bafd0a2b21516550b9234213298079304ca66aa1`.

## PostgreSQL 17 runtime PASS

Focused runtime proof:
`SOURCE/supabase/tests/zyra_oa198_probe_score_replay_bridge_pg17_runtime.sql`

- 4,676 bytes;
- SHA-256
  `bfbd13da58a12b9cacfdca79ab86f26b1484127171fb28e89106687547446997`;
- pins psql `ON_ERROR_STOP`, including PostgreSQL 17 `MAINTAIN` in the
  denied-privilege matrix;
- read-only transaction ending in rollback; and
- no project reference, database URL, seed or production credential.

The bridge and the two unchanged historical table statements executed against
cached image `public.ecr.aws/supabase/postgres:17.6.1.165`, immutable image ID
`sha256:28f0e16a019e648089fc1a6d333549a55548f6019c15ae4bd7cd58b989027518`,
with `server_version_num = 170006`. The container had network mode `none`, no
published ports and no mounts. The proof matched the production catalog shape,
confirmed zero rows in the seedless reconstruction, RLS on, FORCE RLS off,
zero policies, the exact final ACL and no effective table privilege for
`anon` or `authenticated`.

Result marker: `OA-ZYRA-198 PROBE SCORE BRIDGE PG17 PASS`.

The first pre-freeze draft execution exposed an ambiguous PostgreSQL
`text || "char"` concatenation in its own postcondition. Both catalog chars
were explicitly cast to text, the draft was recopied, and the corrected bridge
then reached `COMMIT`. No full application replay was involved. The final hash
above is the only candidate for future execution.

Artifact test:
`SOURCE/test/zyra_oa198_probe_score_replay_bridge_artifact_test.dart`

- 8,967 bytes;
- SHA-256
  `97de713fbbfd15680e8f909ec37ed987a2ac4636c36fcb56b5c7d3b5b9f89e19`.

## Quarantine and future gate

The active production-path inventory remains 207 SQL files at digest
`8a36926aaca155493f16a731ee498204f0d0225e2a5b41cc66f89e1da39b8861`.
It contains neither replay-only bridge version. A future scratch inventory must
contain the unchanged 207 active files plus V2 at `20260811153415` and this
probe bridge at `20260811233812`—never V1 and V2 together.

A separate exact Founder one-replay GO must name both final bridge SQL hashes
before a destructive 209-version reset. That replay must be fresh, seedless,
unlinked, localhost-contained and disposable, and stop at its first result.

Production apply remains prohibited. Both staged September migrations,
production data/history, TestFlight and the private credential store were not
changed. No git command was used.
