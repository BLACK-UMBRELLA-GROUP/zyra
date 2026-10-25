# 079 — CODEX → FOUNDER
# SUBJECT: OA-ZYRA-198 exact question-bank provenance absent; reconstruction ruling required
# DATE: 2026-09-11
# GOVERNANCE: AD-AIOS-109 · OA-ZYRA-198/283 · DR-ZYRA-227
# STATUS: RECOVERY EXHAUSTED / NO BRIDGE CREATED / NO REPLAY RUN / APPLY HOLD

## 1 · Founder outcome

The authorised provenance-recovery pass is complete. It did **not** recover an
original migration.

No retained source contains the original `CREATE TABLE` or 72-row `INSERT` for
`public.zyra_seed_ch4_questions` / `public.zyra_onboarding_questions`. No
original version, filename, statement-array boundary or pre-153416 catalog
snapshot survives. Retained migration `20260811153416` describes its predecessor
as ad-hoc SQL; production migration history has no separate creator/populator
row.

The next action would therefore be a **reconstructed replay bridge**, not
recovery of exact production history. That is a material scope change. I
stopped before creating it and did not run a third replay.

Production, staged migrations `20260910184252` and `20260910195642`, TestFlight,
git and the private credential store remain untouched.

## 2 · Recovery coverage

Read-only recovery covered:

- all 207 active timestamped SQL files and the governed chronology archive;
- 6,548 non-private DEVELOPMENT files, including 4,499 ZYRA files;
- five OA-ZYRA-198 pre-state/replay scratch areas and wider `/private/tmp`;
- four source-relevant archives, including the 393,155,662-byte extensionless
  ZIP, by exhaustive interior search;
- local Claude/Fable cache evidence and one focused Chrome-history/Claude-account
  search, which returned no matching retained conversation; and
- production `supabase_migrations.schema_migrations`, queried read-only by the
  two table identifiers.

Production migration history contains only the later consumers/transformers
`153416`, `153547`, `172021` and `173212`; it contains no earlier creator.
Selecting full `pg_stat_statements.query` text was rejected because unrelated
query literals could expose sensitive data. I did not work around that control.

Four archive identities independently searched:

| Archive | Bytes | SHA-256 | Result |
|---|---:|---|---|
| `_zyra_backup.tar.gz` | 1,800,089 | `90ed25f4f473e834feee07ac1079315024fa200ef1154a6af142567a4e9be479` | no identifier |
| `zyra_snapshot.zip` | 770,564 | `96031c69ed61eb1e297ff5b994e8e53f3c13d5e5bdda668837bfb27aec014c32` | README reference only |
| `steward_snapshot.zip` | 3,829,954 | `d1f8f3c9b5132944eff9269a382f66fe7de6f217df4fbfa00f523aafa13c9d9c` | register/README references only |
| `zigyyf2O` | 393,155,662 | `6d771683b2113b0f97ec7e4c44c21ce4987f8112312fa0cb6e0ccb8d01661592` | README reference only |

No prohibited private path was entered.

## 3 · Exact reconstruction anchors

The strongest retained source is `lib/data/chapter3_categories.dart`, present
byte-identically in three 10/11 August snapshots:

- 32,290 bytes / 681 lines;
- SHA-256
  `232cdf3e70f7e739fedda2a0004e57ffa346686347c86cc2b67e9c895a8677ce`;
- 105 declarations / 104 qids in total; and
- scored subset: 72 rows / 71 qids, with `ch3_q26` represented by separate
  men-only and women-only variants.

The deterministic scored projection over
`{qid, gender_visibility, is_multi, options}`, sorted by numeric qid then
visibility and encoded as compact sorted-key JSON, is:

- 12,927 UTF-8 bytes; and
- SHA-256
  `eb355693f50651c7090aeaa5e7eb15187eb9a37855a785aaa259991cb1b43f90`.

The later exact `173212` body adds 33 non-scored qids, producing 105 rows / 104
qids. OA-ZYRA-190 is the only retained security statement: the old scaffold had
RLS enabled and grants revoked.

These facts are sufficient anchors for deterministic reconstruction. They are
not the original SQL or a database dump. Original nullability, defaults, keys,
checks, indexes, owner, policies, role-by-role ACL, execution time and statement
boundaries remain unknowable.

## 4 · Dependency-safe reconstruction boundary

The only dependency-safe replay slot is after `20260811152809` and before
`20260811153416`. A scratch filename may use version `20260811153415`, which is
unused in the active repository/scratch namespace, but that number would be a
new replay ordering device—not a recovered historical version.

A faithful bridge would:

1. create the old name `public.zyra_seed_ch4_questions` so exact `153416`
   performs its retained rename;
2. define only the four pre-153416 evidenced data columns, while labelling every
   chosen constraint/default as reconstruction;
3. insert and verify the byte-pinned 72-row projection, including ordered JSON
   options, q26 variants, q39 men-only scope, and multi-select only on q37/q97;
4. enable RLS and revoke all table privileges from `PUBLIC`, `anon` and
   `authenticated`;
5. fail closed unless both the old and canonical table names are absent;
6. assert the exact scratch migration-history frontier: `152809` is present and
   no version `>=153416` has run;
7. prohibit drift-hiding `CREATE TABLE IF NOT EXISTS` and
   `ON CONFLICT DO NOTHING` bootstrap semantics;
8. prove the scratch migration set differs from the 207-file active set by
   exactly this one bridge, yielding 208 SQL files; and
9. pin the whole bridge file, executable-content shape, chosen catalog/security
   representation and full ordered-row digest.

Counts alone are not acceptance evidence.

## 5 · Recommended Founder ruling

Recommended route: keep the reconstructed bridge as a governed replay-only
artifact **outside** the active Supabase CLI migration path. For the next
isolated test, copy it into the scratch migration set at version `153415`. This
lets zero-state replay exercise the exact retained chronology without creating
a backdated migration that could appear pending against production.

If the Founder instead wants it inside the active migration directory, that
needs a separate permanent rule for its production fail-closed behaviour and
forbidding accidental retroactive apply.

The concise GO for the recommended route is:

> Approved: build and internally verify the OA-ZYRA-198 replay-only
> reconstructed question-bank bridge described in message 079 §§3–5, outside
> the active production migration path. Do not apply it or run a replay yet.
> Return its hashes, schema/security contract and review evidence for a separate
> one-replay GO.

This is not a migration apply GO, replay GO, TestFlight upload GO or production
change.

## 6 · True pre-state

True pre-files were copied immediately before reconciliation to
`/private/tmp/zyra_oa198_provenance_pre_0rFNpV`.

| File | True pre SHA-256 | Current SHA-256 / state |
|---|---|---|
| ZYRA OA register | `9a481fffc6cf6e59d6f44a51ae1130e4cd80e35ea0e22852db90951f5cd6427b` | `a711570df74173fc42c9a747ac3ddb2cc88f759b64e2bc69fd884008b6e75782` |
| Compatibility boundary handover | `855daff41a517934962a401d761a27bab6bb1fda5ab8e3f176bf5dbfc7c042de` | `74e6179134a454e88cec8a523e5a8b2ad015ea1e07ea1828e1ee8589ee29db1f` |
| `CLAUDE.md` bootstrap | `319c5977f82f8f6d95679bf2373254f12c90e38300d376052ef9121b31eeaebd` | `13dbd956c97b80fdec67a236f7858f8657bb174320270619cff9e03f2c1f9c12` |
| Message 079 | absent | this report; final hash recorded at handoff |

## 7 · Current gate

OA-ZYRA-198 and OA-ZYRA-283 remain open and on apply hold. No clean replay is
claimed. No reconstruction exists. The next executable step requires the exact
Founder ruling in §5 or another explicit treatment chosen by the Founder.
