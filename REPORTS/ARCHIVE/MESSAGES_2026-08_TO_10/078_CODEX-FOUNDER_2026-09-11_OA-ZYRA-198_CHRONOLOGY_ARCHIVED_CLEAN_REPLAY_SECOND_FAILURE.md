# 078 — CODEX → FOUNDER
# SUBJECT: OA-ZYRA-198 duplicate history archived; clean replay second failure measured
# DATE: 2026-09-11
# GOVERNANCE: AD-AIOS-109 · OA-ZYRA-198/283 · DR-ZYRA-227
# STATUS: CHRONOLOGY ARCHIVED / CLEAN REPLAY SECOND FAILURE / APPLY HOLD / PRODUCTION UNCHANGED

## 1 · Outcome

The Founder-approved action from message 077 §9 was executed exactly:

1. Active live-history duplicates `20260811102840` and `20260811103056`
   were preserved as governed evidence outside the Supabase CLI migration
   directory. Their filenames, bytes, SHA-256 values, modes and original
   modification times are preserved.
2. The active SQL inventory changed from 209 to 207, with those two versions
   as the complete SQL set difference.
3. One fresh, unlinked, seedless PostgreSQL 17 reset used the intended
   `20260811104500 -> 20260811110300 -> 20260811111500` sequence.

The earlier 42P13 default-parameter collision is gone. The replay advanced
through `20260811152809` and stopped at the first new result:

- failing version:
  `20260811153416_oa193c_onboarding_question_bank_and_completeness.sql`;
- SQLSTATE: `42P01`;
- error: `relation "zyra_onboarding_questions" does not exist`; and
- failing statement number: 1, the unconditional
  `ALTER TABLE zyra_onboarding_questions ADD COLUMN ...`.

There was no repair, retry or attempt to continue past this failure.
Production, production migration history, staged migrations
`20260910184252` and `20260910195642`, and TestFlight are unchanged.
OA-ZYRA-198 and OA-ZYRA-283 remain open and on apply hold.

## 2 · Authority and boundaries

The Founder replied **“Approved”** on 2026-09-11 to the exact next action
stated in message 077 §9:

> Preserve and archive migrations 20260811102840 and 20260811103056 outside
> the active migration directory, then rerun the isolated zero-state replay
> using the intended split sequence. Stop and report at the first result. Do
> not apply production migrations or upload TestFlight.

That authority did not permit recovery of the newly measured question-bank
provenance, alteration of any of the eight exact OA-ZYRA-193 bodies, production
queries as a repair tool, a second replay, migration apply, upload, git or
private-credential access.

Three read-only Codex subagent checks were used as internal verification, not
approval: archive governance, corrected chronology/static next blocker, and
isolated runtime/teardown design. Only the Founder approved execution.

## 3 · Governed archive and reversibility

Governed directory:

`SYSTEM/RESOURCES/MIGRATION_HISTORY/OA-ZYRA-198_2026-09-11_CHRONOLOGY_ARCHIVE/`

| Version | Archived file SHA-256 | Bytes | Mode | Original mtime |
|---|---|---:|---:|---|
| `20260811102840` | `897cd7ced829dd0844690c38501faca20da080e86cd6b78ebf34f0b7f8c327bc` | 12,519 | `0600` | `2026-08-21T14:06:46+0100` |
| `20260811103056` | `a101e019ba525e55dd97c2c98f3313d85b15ff94ee28f892f7dd4a06ea1be805` | 4,835 | `0600` | `2026-08-21T14:06:46+0100` |

Those hashes and metadata match the true pre-state snapshots. No stub,
symlink, renamed SQL file or nested archive remains under
`SOURCE/supabase/migrations/`.

Archive control identities:

- `README.md`:
  `44b40fe291297f108e646b113942e1b7b8bb9b3a802102948594cc4499177447`;
- `manifest.json`:
  `f90757a27e272dfd288916419704a2be2d63dbc4d20c2c457cf098cc7293f6ed`.

The manifest records authority, reason, classification, before/after
inventory, exact archive/original paths, hashes, byte lengths, active
successor sequence and reverse path map. Reverse is deliberately gated: under
a new Founder chronology ruling, copy each exact archived byte stream back to
its recorded original path and stop if a destination exists or any
length/hash differs. Production history is never edited by that reversal.

Comparison with message 077's byte-identical 209-file scratch input showed
exactly two missing SQL files and no changed common SQL file. The OA-193
README differs separately because this report updates its warning from the
first failure to the second.

## 4 · Static chronology verification

After the two-file exclusion:

1. `20260811104500` creates the first one-match
   `zyra_dev_rewind_journey(uuid)` without a default.
2. `20260811110300` adds the Timeline vocabulary, trigger and
   `zyra_record_journey_milestone()`.
3. `20260811111500` explicitly drops the one-match function before creating
   the account-wide `uuid DEFAULT NULL` version.

The timeline executable section in 110300 is byte-identical to its archived
102840 counterpart. The corrected rewind body in 111500 is semantically
identical after comments/blank lines to archived 103056 and retains the later
anchor required by `20260811233914`. Whole-file identities remain:

- 104500: `b70b347aeb903609b32a8e8bc6725cce5ac23cf2f9723c69f982a317817ce783`;
- 110300: `3cabc5c9222987157be0b869fe4621ddd00802ab2a2e8ebc25dca13a4f60e755`;
- 111500: `e40fb83e4a345cd59ab0ae23f311bdecd73aa53a29b0f9e12e527b91810cf890`.

## 5 · Isolated replay controls

- scratch root: `/private/tmp/zyra-oa198-replay2.zXoAIN`;
- scratch project id: `zyra-oa198-replay2.zXoAIN`;
- scratch config SHA-256:
  `5b2d79c61bc1c3dab36ee5fdce0a5594284872e309dd5d2c59772e30c1436e85`;
- PostgreSQL major: 17;
- `[db.seed].enabled = false`, no `seed.sql`;
- no `.temp/project-ref`, database URL or production link;
- exactly 207 active timestamped SQL files copied with `ditto`;
- source/scratch `diff -rq`: silent before replay;
- Supabase CLI `2.116.0` (not upgraded despite 2.117.0 notice);
- Colima `0.10.3`, Docker CLI `29.7.2`, Docker Engine `29.5.2`;
- named profile `zyra-oa198`, aarch64/VZ, 4 CPUs, 4 GiB memory, 40 GiB
  disk, Docker runtime, global Docker context not activated;
- unique Docker network `zyra-oa198-zXoAIN`, bridge host binding verified
  exactly `127.0.0.1`; and
- `DO_NOT_TRACK=1` used on every Supabase command.

The empty local database was started before the migration files were copied.
The one replay command was:

```text
DOCKER_HOST=unix:///Users/shakeelahmad/.colima/zyra-oa198/docker.sock \
DO_NOT_TRACK=1 supabase db reset --local --no-seed \
  --workdir /private/tmp/zyra-oa198-replay2.zXoAIN \
  --network-id zyra-oa198-zXoAIN
```

The explicit `--local`, absent link/DB URL and isolated Docker socket
prevented the Supabase CLI from selecting production as the reset target.

## 6 · Second-failure evidence

The reset applied every active version from `20260718190011` through:

- the corrected 104500/110300/111500 chronology;
- recovered OA-ZYRA-193 versions `20260811152220`,
  `20260811152255`; and
- recovered version `20260811152809`.

It then entered recovered version `20260811153416`. Its conditional first
statement looks for `zyra_seed_ch4_questions`; if absent it does nothing.
Statement 1 then unconditionally executes:

```sql
ALTER TABLE zyra_onboarding_questions
  ADD COLUMN IF NOT EXISTS show_if_qid         text,
  ADD COLUMN IF NOT EXISTS show_if_not_any_of  jsonb;
```

No earlier active repository migration creates
`public.zyra_seed_ch4_questions` or
`public.zyra_onboarding_questions`. The error is therefore deterministic
on a zero-state database.

The later retained 173212 body proves this is not merely a missing empty table:
it expects 72 existing rows and 71 distinct qids before adding 33 later rows.
The next recovery must preserve the original populated-table provenance and
statement-array boundaries. Creating an inferred empty shell or modifying the
exact 153416 body would hide history and is not authorised.

`20260811233813`'s missing `public.zyra_probe_score` creator remains a
static later finding. This replay did not reach it, so it is not reported as a
measured database failure.

## 7 · Stop and teardown

After exit code 1, no SQL repair, database query or reset retry ran.

Teardown was exact and targeted:

- `supabase stop --no-backup --workdir
  /private/tmp/zyra-oa198-replay2.zXoAIN` succeeded;
- Docker network `zyra-oa198-zXoAIN` was removed;
- Colima profile `zyra-oa198` was stopped;
- `colima list` reports the profile `Stopped`;
- global Docker context reports `default`;
- no process listens on TCP ports 54321–54327; and
- approximately 51 GiB remained free.

The scratch directory is retained as local evidence. No local container is
running; the targeted data volume and unique network were removed before the
named profile was stopped.

## 8 · True pre-state and current identities

Project true pre-files were copied before the archive edit to
`/private/tmp/zyra_oa198_archive_pre_20260911.d9BvF1`. The Group OA register
was copied immediately before its final reconciliation to
`GROUP_OUTSTANDING_ACTIONS_V1.md.pre` in that same directory. Report 078, the
governed archive README and manifest were absent.

| File | True pre SHA-256 | Current SHA-256 / state |
|---|---|---|
| active 102840 SQL | `897cd7ced829dd0844690c38501faca20da080e86cd6b78ebf34f0b7f8c327bc` | active absent; archive same hash |
| active 103056 SQL | `a101e019ba525e55dd97c2c98f3313d85b15ff94ee28f892f7dd4a06ea1be805` | active absent; archive same hash |
| archive README | absent | `44b40fe291297f108e646b113942e1b7b8bb9b3a802102948594cc4499177447` |
| archive manifest | absent | `f90757a27e272dfd288916419704a2be2d63dbc4d20c2c457cf098cc7293f6ed` |
| ZYRA OA register | `8ddcaeea2198994948561ae8bd1e7cfdf80584c67bd39313ed1118008770ba06` | `9a481fffc6cf6e59d6f44a51ae1130e4cd80e35ea0e22852db90951f5cd6427b` |
| Group OA register | `64fd5b0435e7980d1bab683c76d27ca17bdaede099315edb76f44fb0cf09cdac` | `12feae36656d52f2aa49743f145f47c4ce54a15f2272f2dc76850013beeb32ee` |
| Compatibility boundary handover | `9edeef8fd49d7a1d81858a89904c33b49bb8adea14e523b771eb7c97ee70aecc` | `855daff41a517934962a401d761a27bab6bb1fda5ab8e3f176bf5dbfc7c042de` |
| `CLAUDE.md` bootstrap | `4020249ed781cbfd9c82c7604a1e053bbefa7c9e8b98fa28dc73f8dcad065b73` | `319c5977f82f8f6d95679bf2373254f12c90e38300d376052ef9121b31eeaebd` |
| OA-193 migration README | `0fe9ac323bb08768b78fe19886e04acdcd44797281f823e96f95a5fb24cc7a25` | `1a9d68fc69a4fbcb90a624ea138f883464a16869a66d90540637f3bae3a532f4` |
| export helper | `223b5bcd7bdf87727861dbdd431383694711d850625d1bd2d80c04cfa070097c` | `d6a01b9fa4bf77216d98b8ccddea15866980e8bc458abf93aecbf8bb62cb8ddf` |
| generated documentation index | `097a4d4b54ed711ce0040bed38159fb524d2d85530dd0710f3516ea178b62c69` | `62fc1106be196bdf8303a995ca9cfe82ba93551c0aec3c23026429b930945710` |

The group register keeps OA-AIOS-329 completed for its actual 2026-08-21
solo round, but now dates and corrects its historical “OA-ZYRA-198 CLOSED”
statement so it cannot be mistaken for current replay truth. OA-ZYRA-283 and
this handover now name the measured 153416 / 42P01 blocker directly.

The two staged production artifacts remain byte-stable:

- OA-ZYRA-283 `20260910184252`:
  `63381febeb9b1732447adb24a6225c1006f42171bc8b5b5e4f5a61712f54296d`;
- Request New Journey hold `20260910195642`:
  `0ac36fd4c4c7ed03b8a4fe80ef75d4cb43c10355426d6a972814961f5e061545`.

## 9 · Verification

- archive SQL filename/byte/SHA-256 identities: exact, 2/2;
- archive modes and original mtimes: exact, 2/2;
- archive manifest JSON parse: passed;
- active SQL count: 209 -> 207;
- active SQL set difference: exactly 102840 and 103056;
- new scratch/source migration diff: silent;
- one clean local reset: failed at first new result 153416 / 42P01;
- focused OA-ZYRA-198/OA-ZYRA-283/temporary-hold tests: 20 passed, 0
  failed;
- `flutter analyze`: no issues;
- `python3 tools/zyra_check.py`: 186 files, 0 findings;
- checker unit test: 1 passed, 0 failed;
- current Group/ZYRA OA and handover closure language reconciled to the
  measured second replay while preserving the dated historical record;
- full Flutter/visual suite: not rerun because no Flutter source or approved
  pixel changed; no new claim is made from the earlier run;
- production migration apply/history mutation: not run;
- TestFlight upload: not run;
- git: not used; and
- private credentials: not accessed.

## 10 · Required next authority

The chronology correction is complete, but clean replay is still red. The
next recommended ruling stays inside OA-ZYRA-198:

> Approved — recover the exact retained production migration-history
> provenance that creates and populates the onboarding-question table before
> 20260811153416, preserving statement-array boundaries and proving the
> 72-row/71-distinct-qid precondition. Add only the minimum byte-pinned active
> replay representation, then rerun the same unlinked, seedless, localhost-
> bound zero-state reset once and stop at the first result. Do not alter any of
> the eight exact recovered bodies, apply a production migration, upload
> TestFlight or use git.

No production Apply GO or TestFlight Upload GO is requested.

— Codex / Operating Partner, 2026-09-11
