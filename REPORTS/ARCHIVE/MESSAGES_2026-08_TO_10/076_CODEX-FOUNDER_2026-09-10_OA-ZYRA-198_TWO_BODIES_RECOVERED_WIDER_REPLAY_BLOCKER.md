# 076 — CODEX → FOUNDER
# SUBJECT: OA-ZYRA-198 two prerequisite bodies recovered exactly; six-file replay blocker discovered
# DATE: 2026-09-10
# GOVERNANCE: AD-AIOS-109 · OA-ZYRA-198/283 · DR-ZYRA-227
# STATUS: RECOVERY PARTIAL / APPLY HOLD / PRODUCTION UNCHANGED

## 1 · Outcome

The Founder-approved OA-ZYRA-198 recovery round has safely restored the two
historical migration bodies directly required by OA-ZYRA-283, but it has also
corrected the scope of the replay defect.

1. Versions `20260811152220` and `20260811152255` now contain their exact
   retained production migration-history statement bytes in their original
   chronological files. Their extracted-body SHA-256 values match the live
   source independently.
2. No new migration version was invented. The repository wrappers are SQL
   comments carrying provenance markers; the executable bytes between those
   markers are exact. The whole repository files are therefore not described
   as byte-identical to the retained statements.
3. Focused recovery, OA-ZYRA-283 and temporary-hold tests pass 13/13. Analyzer
   and repository checks pass.
4. A complete migration audit found six further substantive OA-ZYRA-193
   `SELECT 1` placeholders. They prevent a truthful zero-state replay and were
   not silently replaced under the narrower two-file authority.
5. A genuine local reset did not run because the source has no local Supabase
   configuration and this Mac has no Docker-compatible database runtime.
6. Production, its migration-history rows, both staged September migrations
   and TestFlight are unchanged. OA-ZYRA-198 remains open and no Apply GO is
   requested.

## 2 · Authority and boundaries

The Founder's direct `Proceed and approved` reply on 2026-09-10 authorised the
governed history recovery and clean-replay preparation described after message
075. The governing defect then on record named the two OA-ZYRA-283 prerequisite
files. That authority was used to restore those two exact retained bodies and
to perform read-only discovery and local static verification.

It was not treated as authority to:

- replace six additional historical files newly discovered during the audit;
- install Docker, Colima, PostgreSQL or another host runtime;
- create a costed Supabase branch;
- link the source tree to production, use production as a replay sandbox, or
  run `db push`, `db pull`, migration repair or `db reset --linked`;
- apply migration `20260910184252` or `20260910195642`;
- upload a TestFlight build; or
- close OA-ZYRA-198 or OA-ZYRA-283.

No git command was used and no private credential store was accessed.

## 3 · Exact provenance recovery

The retained production rows were inspected read-only from
`supabase_migrations.schema_migrations`. Each affected version has one retained
statement. That statement was placed between explicit begin/end provenance
markers in the same historical versioned file and its UTF-8 SHA-256 was pinned
in a new focused test.

| Version | Retained text length | Retained body SHA-256 | Repository file SHA-256 |
|---|---:|---|---|
| `20260811152220` | 12,626 | `82fdc1d13db0564ddfa9aeeb09fde7eb3b0a509e678005536c17b03b703d24fa` | `a24b555b47cf01b0cf07f758145a8610b7979c9b2424e2618d57af2df5deaaf1` |
| `20260811152255` | 5,435 | `884de52af3e96ef92ce5427a9a8c69b7a0b4cb6257309e43f8a2140031cbc2ed` | `4953a19531b2c228e2cedfe7047f0ca352289771a729fbc35da9ca769ed45160` |

The focused test extracts only the bytes between the markers, verifies both
hashes, rejects the old record-only body, and asserts the immediate two-score,
`score_candidates`, Plus and developer-function prerequisites.

Restoring the original files is safer than appending a new recovery migration:
an appended version would execute after its dependants, appear pending against
production even though production already has the state, and leave historical
replay broken.

## 4 · Corrected wider blocker

The audit found six more substantive applied migrations that are still local
record-only placeholders:

| Version | Retained text length | Retained body SHA-256 |
|---|---:|---|
| `20260811152809` | 7,058 | `38a2a20e810895d1975d4ec27eaea5db0cd03e78d3a114848171343bb2b16366` |
| `20260811153416` | 9,277 | `0f9022853b97fa328940e15296e885e917d83842ee19ff9d469ebef88e42fcfc` |
| `20260811153547` | 5,977 | `0a4149339dfbddc7b18a1bbf9da59ff79ea8f5cf73c6a97607d65f47ad852f5f` |
| `20260811153643` | 6,754 | `cc919cc511b71d3061dac6036687ad353cdb43fa39f33e6b9d6e3f4bfd2ac4cc` |
| `20260811172021` | 5,124 | `88eb598aab415c90338ddbb0fa58d567ba36890830086e6995ccb024b1dc9671` |
| `20260811173212` | 11,792 | `2e814b5f9962429ca202721788c7a0ad1778b20e908ed5e1fda2603a89b3d558` |

The first predictable failure after only the two-file repair is migration
`20260811233813`: it revokes onboarding functions that the unrecovered
`20260811153416`/`20260811153547` bodies should have created. Later migrations
also depend on the missing question-bank, completion-gate and scoring state.

The earlier OA-ZYRA-198 file-presence reconciliation therefore remains useful
historical evidence, but it did not prove a clean rebuild. The OA register now
names all eight substantive files and keeps the action open until an actual
isolated zero-state replay passes.

## 5 · Replay environment audit

Measured local facts:

- Supabase CLI: `2.116.0`;
- migration inventory: 209 SQL files with unique 14-digit versions, ordered
  from `20260718190011` through `20260910195642`;
- `SOURCE/supabase/config.toml`: absent;
- Docker-compatible runtime: absent;
- host PostgreSQL tools/runtime: absent;
- local project link: absent;
- default Supabase ports `54321`–`54327`: free; and
- available disk at inspection: approximately 57 GiB.

The correct future proof is an isolated scratch directory containing only a
byte-for-byte copy of the migration directory, a unique local project id,
PostgreSQL 17 and seeding disabled. After all eight bodies are restored, it
must run `supabase db reset --local --no-seed` and stop on the first error.
Schema replay and deterministic fixture parity are separate gates; the current
developer seed does not reproduce every fixed-id SQL harness scene.

Production must never be used as the replay target. `supabase db push` is also
unsafe here because production history contains known version/name drift and
the repository contains two intentional split timeline versions.

## 6 · True pre-state and current file identity

True pre-files were copied before editing to
`/private/tmp/zyra_oa198_recovery_pre_20260910.qM5r63`. New artifacts were
recorded as absent.

| File | True pre state / SHA-256 | Current SHA-256 |
|---|---|---|
| `SOURCE/supabase/migrations/20260811152220_oa193_scoring_method_ratified_plain_count_two_scores.sql` | `91195477387e480782d6935f9f4cec2f30ccbcafa9a9a71fa5eef9c872a8e1f8` | `a24b555b47cf01b0cf07f758145a8610b7979c9b2424e2618d57af2df5deaaf1` |
| `SOURCE/supabase/migrations/20260811152255_oa193_two_scores_plus_and_dev_functions.sql` | `9999151199cf4f8191f854e6c98d4e212933c1e1d581f04109ad920444bed7bf` | `4953a19531b2c228e2cedfe7047f0ca352289771a729fbc35da9ca769ed45160` |
| `SOURCE/test/zyra_oa198_migration_history_recovery_test.dart` | absent | `cb2a9e4769ecab54dfb6f8a5372794ae96937eee024ca560e7e0c6b26110fac5` |
| OA register | `5d36ba2adac8caec9ba483631c8aa886efc4255da9a90873ee888bc05936eb79` | `e229929639aec576644f592bde4db9d075f0f9da859ee122ea61a2d8bd6a1959` |
| Compatibility boundary handover | `17343655fd7e275fbf1f5c408958f8406b7e7c98910fc4d33dae5bd7c27e95aa` | `f621039e0a4bdf56b68759a8d2fbf9d1c6b7b5ffd2b3bd50b6d7ab48bb7edfdc` |
| generated documentation index | `8d864bc3ace7b6cb19158be3994212e2936dbc0525456c2c5d11ff128645d9cd` | `ecdd8430e3c820bba419768afcde804cad9e248c6b9f600ead8293ddb3c65bde` |
| this message | absent | measured after filing; not a self-authenticating field |

The staged release artifacts remained byte-stable:

- OA-ZYRA-283 migration `20260910184252`:
  `63381febeb9b1732447adb24a6225c1006f42171bc8b5b5e4f5a61712f54296d`;
- temporary hold migration `20260910195642`:
  `0ac36fd4c4c7ed03b8a4fe80ef75d4cb43c10355426d6a972814961f5e061545`.

## 7 · Verification

- recovered-body hash tests: 3 passed, 0 failed;
- combined recovery/OA-ZYRA-283/temporary-hold tests: 13 passed, 0 failed;
- independent SQL/provenance review: PASS for the two-file partial recovery;
- independent governance/replay review: six-file blocker confirmed;
- `flutter analyze`: no issues;
- `python3 tools/zyra_check.py`: 186 files, 0 findings;
- checker unit test: 1 passed;
- clean local database reset: not run and not claimed;
- production migration apply: not run;
- production migration-history mutation: not run;
- signed archive/TestFlight upload: not run;
- git: not used; and
- private credentials: not accessed.

The new focused test is deliberately partial evidence. It proves the two
restored body identities and their immediate OA-ZYRA-283 prerequisites; it
cannot close OA-ZYRA-198 while the six named placeholders remain.

## 8 · Required next authority

The next safe round needs explicit Founder authority for both newly expanded
actions:

1. restore the six named historical files from their exact retained live
   statements, using the same true-pre-state, marker and hash discipline; and
2. install and use a local Docker-compatible runtime solely for an isolated
   scratch Supabase reset, with no link, reference, data or command pointed at
   production.

Only after all eight bodies and the clean replay pass can Codex present the
exact two-migration production Apply GO package. Applying either staged
migration or uploading TestFlight remains a separate Founder decision.

— Codex / Operating Partner, 2026-09-10
