# 080 — CODEX → FOUNDER
# SUBJECT: OA-ZYRA-198 replay-only reconstructed question-bank bridge internally verified; one-replay GO required
# DATE: 2026-09-11
# GOVERNANCE: AD-AIOS-109 · OA-ZYRA-198/283 · DR-ZYRA-227 · message 079 Founder GO
# STATUS: BRIDGE BUILT / INTERNALLY VERIFIED / REPLAY NOT AUTHORISED OR RUN / APPLY HOLD

## 1 · Outcome

The Founder approved message 079 §5's recommended route. I built and
internally verified one reconstructed question-bank bridge, quarantined outside
`SOURCE/supabase/migrations`.

The bridge has **not** been copied into a scratch migration set, executed,
replayed or applied. Production, the 207-file active migration inventory, both
staged September migrations, TestFlight, git and the private credential store
remain untouched. OA-ZYRA-198 and OA-ZYRA-283 remain open and on apply hold.

The next executable gate is a separate exact Founder one-replay GO.

## 2 · Frozen artifact identities

Artifact directory:

`SYSTEM/RESOURCES/MIGRATION_HISTORY/OA-ZYRA-198_2026-09-11_RECONSTRUCTED_REPLAY_BRIDGE/`

| Artifact | Bytes | Lines | Mode | SHA-256 |
|---|---:|---:|---:|---|
| `20260811153415_oa198_reconstructed_question_bank_replay_bridge.sql` | 28,387 | 498 | `0600` | `461c3bd0e4ef4692229027c5659756983ed2048e1e78cf71e2148009d6729055` |
| `README.md` | 5,521 | 125 | `0644` | `d883fe559f417d1ab8c5311cb7e521aeea1fdfe2b9262c0b7ef54567f5cbab21` |
| `manifest.json` | 7,237 | 186 | `0644` | `71678199bb76cf43d66f1d755f401767a72b209df1142cdf0dba77223d285c63` |
| `SOURCE/test/zyra_oa198_replay_bridge_artifact_test.dart` | 20,192 | 588 | `0644` | `11148da4d68ec8d63633a1a9db868b84451e65ebacc4810aa73bc9fb3b0bb975` |

The active migration set remains 207 SQL files, digest
`8a36926aaca155493f16a731ee498204f0d0225e2a5b41cc66f89e1da39b8861`,
with no `20260811153415` file. A future isolated scratch set would contain 208
files and differ by exactly this bridge.

## 3 · Reconstruction provenance and correction

The frozen source anchor remains archived `chapter3_categories.dart`:

- 32,290 bytes / 681 lines;
- SHA-256
  `232cdf3e70f7e739fedda2a0004e57ffa346686347c86cc2b67e9c895a8677ce`;
- exact reconstructed payload: 12,927 UTF-8 bytes, 72 rows / 71 qids,
  SHA-256
  `eb355693f50651c7090aeaa5e7eb15187eb9a37855a785aaa259991cb1b43f90`.

Message 079 remains preserved as the historical decision request. Two wording
qualifications are recorded here without rewriting it:

1. the same 10 August 17:23 source entry occurs in three snapshot archives;
   two archive containers are dated 11 August and `steward_snapshot.zip` is
   dated 12 August 00:19; and
2. q37/q97 are the only multi-select qids **within the reconstructed 72 scored
   rows**. Later retained migration 173212 adds 33 non-scored qids, including
   multi-select q62.

This is deterministic reconstruction evidence, not recovered database bytes,
DDL, catalog identity or migration history.

## 4 · Reconstructed catalog contract

The bridge deliberately chooses the smallest pre-153416 table needed by the
retained successor:

| Column | Type | Null | Default |
|---|---|---|---|
| `qid` | `text` | forbidden | none |
| `gender_visibility` | `text` | forbidden | none |
| `is_multi` | `boolean` | forbidden | none |
| `options` | `jsonb` | forbidden | none |

Persistent catalog shape:

- exactly one constraint and one index: named composite primary key
  `zyra_seed_ch4_questions_pkey (qid, gender_visibility)`;
- no persistent check constraints or defaults;
- owner is the migration executor (`current_user`), asserted after creation;
- the historical owner and broader historical catalog remain unknown.

The canonical catalog/security-contract digest is
`a929d23e5190ce238ef86a8786bdbaf0858337ae16a55cbf79572c6f2410850a`.

## 5 · Security contract

- RLS is enabled and `FORCE ROW LEVEL SECURITY` is off.
- The reconstructed table has zero policies.
- All table privileges are revoked from `PUBLIC`, `anon` and `authenticated`.
- No column ACL entry is permitted.
- Direct table ACLs are restricted to the owner and an optional pre-existing
  `service_role` entry; the bridge grants nothing to `service_role` and does
  not assume such a grant.
- Effective table and column privilege checks fail if `anon` or
  `authenticated` can exercise any checked privilege, including PostgreSQL 17
  `MAINTAIN`.
- There are no functions, definer bodies, policies or client grants in this
  artifact.

## 6 · Fail-closed execution boundary

The single transaction aborts unless all of these remain true:

1. `supabase_migrations.schema_migrations` exists;
2. predecessor `20260811152809` exists exactly once;
3. artificial bridge version `20260811153415` is absent;
4. neither old nor canonical question-bank relation exists;
5. no migration version at or after `20260811153416` has run;
6. no unexpected version lies between 152809 and 153416;
7. the embedded payload's byte length and PostgreSQL SHA-256 match;
8. all 72 reconstructed rows match in both directions with `EXCEPT ALL`; and
9. the final catalog, owner, RLS, policy and ACL contract matches exactly.

It intentionally contains no `IF NOT EXISTS`, `ON CONFLICT`, owner change,
role switch, canonical-table creation, persistent destructive DML or weakening
of the eight retained OA-ZYRA-193 bodies.

## 7 · Internal review and verification

Three separate internal static passes reviewed the final exact SQL hash for
payload provenance, chronology, successor compatibility, SQL shape and
security. All three returned no blocker. They are one Codex trust domain and
are not external approval.

Measured results:

| Check | Result |
|---|---|
| Bridge artifact tests | 6/6 pass |
| Combined exact-history + bridge tests | 16/16 pass |
| All non-visual Flutter tests | 549/549 pass |
| `flutter analyze` | pass, no issues |
| `tools/zyra_check.py` | pass, 0 findings |
| Checker unit test | 1/1 pass |
| Full Flutter suite | 824 pass / 60 fail |

All 60 full-suite failures are visual-golden comparisons outside this bridge's
non-UI surface. No approved pixel was regenerated or changed. They remain
visible evidence, not silently converted to a pass.

The counts above were observed in transient command output and recorded here;
no separate stdout-log artifact was created. The pinned test source and
manifest are the durable replayable evidence.

One attempted parallel final rerun collided with Flutter's global startup lock
and could not clean an ephemeral iOS package path. The immediate serial rerun
passed 16/16; analyzer passed independently. This was a tooling-concurrency
event, not an artifact failure.

No database execution was used for internal verification. Static verification is
not replay evidence.

## 8 · Governance reconciliation and true pre-state

True pre-files were captured immediately before work under
`/private/tmp/zyra_oa198_bridge_pre_k1MXtF`.

| File | True pre-state / SHA-256 | Post SHA-256 |
|---|---|---|
| Bridge artifact directory | absent | identities in §2 |
| Bridge test | absent | `11148da4d68ec8d63633a1a9db868b84451e65ebacc4810aa73bc9fb3b0bb975` |
| Message 080 | absent | returned at handoff; self-hash cannot be embedded without changing itself |
| Message 079 | `ee8df0d58e6c851d8eab96fa228071e178b8eb562e5c0dbc80435198b40291b9` | unchanged, same hash |
| OA register | `a711570df74173fc42c9a747ac3ddb2cc88f759b64e2bc69fd884008b6e75782` | `0b9d6edd1cabf9a03a9e3cc21510e3847e7b457cdaf74a489420e2a7d771426a` |
| Compatibility handover | `74e6179134a454e88cec8a523e5a8b2ad015ea1e07ea1828e1ee8589ee29db1f` | `5fc402f95e4b554179c082d78f216a4bd5e27b2638b9c80848146a6635ecb3cf` |
| `CLAUDE.md` | `13dbd956c97b80fdec67a236f7858f8657bb174320270619cff9e03f2c1f9c12` | `74625a3265bde3c943ce80f5a0075973b11b26d23d52fb760cee003c1d7f9d05` |

The documentation-index generator treats `--help` as a generation request. An
early diagnostic invocation therefore refreshed only the generated index
before a pre-copy was taken. I do not fabricate that missing first pre-hash.
The resulting file at
`d1e433620e438b0efb03a7be4f31af8c8b14d5d086c39d16b73781a406a3a98c`
was then captured byte-for-byte before the final intentional regeneration that
adds this report; its final hash is returned at handoff.

## 9 · Next exact gate

Nothing executable is authorised by this report. A future one-replay GO must
name SQL SHA-256
`461c3bd0e4ef4692229027c5659756983ed2048e1e78cf71e2148009d6729055`
and authorise exactly one isolated, seedless PostgreSQL 17 replay using:

- the 207 byte-pinned active files plus this one bridge at ordering version
  153415;
- the official runner that records a migration only after its statements
  complete;
- one consistent migration executor, standard Supabase roles/search path and
  an isolated destination with no seed data; and
- stop-and-report at the first result or any hash, inventory, frontier,
  destination or assertion drift.

Failure does not authorise a repair or retry. The bridge never enters the
active production migration path. Production apply, TestFlight and the later
OA-ZYRA-283 release gates each remain separately governed.
