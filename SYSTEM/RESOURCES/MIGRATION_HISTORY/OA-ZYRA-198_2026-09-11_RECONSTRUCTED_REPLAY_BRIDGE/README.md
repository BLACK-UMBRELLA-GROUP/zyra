# OA-ZYRA-198 reconstructed question-bank replay bridge

**Status:** CODEX INTERNALLY VERIFIED / REPLAY NOT AUTHORISED / PRODUCTION APPLY PROHIBITED  
**Authority:** Founder approval of message 079 §§3–5, 2026-09-11  
**Owner:** Codex under AD-AIOS-109  
**Outstanding action:** OA-ZYRA-198

## What this is

This directory holds one deterministic compatibility bridge for a future,
separately authorised, isolated zero-state replay. The retained chronology
stops after migration `20260811152809` because the exact
`20260811153416` migration expects an earlier
`public.zyra_seed_ch4_questions` table whose ad-hoc creation and population
SQL was never retained.

The bridge reconstructs that predecessor from the strongest surviving data
source: the byte-pinned 2026-08-10 Dart question bank. It creates the old table
name so the exact retained `20260811153416` statement performs its own rename.

## What this is not

This is not recovered production history, an active migration, a production
patch, an apply package, or permission to run a replay. Version
`20260811153415` is an artificial dependency-order slot, not a recovered
historical version.

The SQL stays outside `SOURCE/supabase/migrations`, so the normal Supabase CLI
migration inventory cannot discover or apply it. The exact-history chronology
archive remains separate and untouched.

## Pinned reconstruction evidence

- archived `chapter3_categories.dart`: 32,290 bytes / 681 lines /
  SHA-256
  `232cdf3e70f7e739fedda2a0004e57ffa346686347c86cc2b67e9c895a8677ce`;
- archived onboarding model: SHA-256
  `0a87d252dc2f2b2895ea058defb92683949669f01dd9bee12ccc628c6bb525f4`;
- reconstructed scored four-field projection: 12,927 UTF-8 bytes,
  72 rows / 71 qids, SHA-256
  `eb355693f50651c7090aeaa5e7eb15187eb9a37855a785aaa259991cb1b43f90`;
- predecessor active file `20260811152809`: SHA-256
  `94799280bc9edd760bd1566e8b65dd79f6271a95bf32475c96edc9a4df9382bd`;
- successor active file `20260811153416`: SHA-256
  `832c4bdfcac2e622700458810768a995a058d7186933ea5fb6458ac4ac3f3d6d`;
- active migration inventory: 207 SQL files, digest
  `8a36926aaca155493f16a731ee498204f0d0225e2a5b41cc66f89e1da39b8861`.

The projection digest is reconstruction evidence only. It is not evidence of
the lost DDL, catalog, ACL, migration version, execution time, or statement
boundaries.

## Chosen reconstructed catalog and security contract

The persistent table has exactly four columns in order:

| Column | Type | Nullability | Default |
|---|---|---|---|
| `qid` | `text` | NOT NULL | none |
| `gender_visibility` | `text` | NOT NULL | none |
| `is_multi` | `boolean` | NOT NULL | none |
| `options` | `jsonb` | NOT NULL | none |

The only persistent constraint/index is the named composite primary key
`zyra_seed_ch4_questions_pkey (qid, gender_visibility)`. No persistent CHECK
constraint is invented. The migration executor owns the relation; this is a
compatibility choice, not a claim about the historical owner.

RLS is enabled and explicitly not forced, with zero policies.
`PUBLIC`, `anon`, and `authenticated` receive no table or column
privileges, including inherited/effective PostgreSQL 17 `MAINTAIN` authority.
No client-visible policy or grant is created. No service-role ACL is assumed.

No-FORCE RLS is deliberate: the exact later SECURITY DEFINER functions are
created by the same migration executor and must be able to read the bank as its
owner while clients remain denied.

## Fail-closed execution contract

The bridge runs in one transaction and refuses execution unless:

1. `supabase_migrations.schema_migrations` exists;
2. version `20260811152809` exists exactly once;
3. neither the old nor canonical table name exists;
4. no version `>= 20260811153416` has run;
5. no unexpected version lies between `152809` and `153416`; and
6. the current `153415` history row is absent before the bridge body runs.

Before permanent DDL it verifies the embedded payload byte length, core
PostgreSQL SHA-256, JSON shape and value contract. After insertion it verifies
bidirectional full-row equality, counts, the two q26 variants, q39 scope, the
scored multi-select set q37/q97, zero overlap with the 33 later `173212`
rows, the exact catalog, RLS/policy state, and direct plus effective client ACL
denial. Any failure aborts and rolls back the transaction.

## Identity and placement

Bridge file:
`20260811153415_oa198_reconstructed_question_bank_replay_bridge.sql`

Final internally reviewed identity:

- 28,387 bytes;
- SHA-256
  `461c3bd0e4ef4692229027c5659756983ed2048e1e78cf71e2148009d6729055`.

The canonical payload exists only once, inside that SQL file. The static test
extracts it directly; no second JSON authority or mutable bridge generator is
kept.

## Future replay protocol — still gated

A separate exact Founder one-replay GO must name this artifact and its final
hash.
Only then may an isolated scratch copy be assembled from the unchanged
207-file active set plus this exact file at `153415`, yielding 208 SQL files.

Stop before execution if any pinned file, payload, inventory, destination,
frontier guard, or artifact hash differs. The scratch environment must be
seedless, unlinked, localhost-bound, and disposable. Production must never be
used as a repair source or target. A failed replay is one measured result, not
permission to edit exact retained history or retry.

Rollback for the bridge itself is transaction rollback in the isolated scratch
database. The governed source artifact remains outside the active path.
