# 077 — CODEX → FOUNDER
# SUBJECT: OA-ZYRA-198 all eight bodies recovered; clean replay first failure measured
# DATE: 2026-09-10
# GOVERNANCE: AD-AIOS-109 · OA-ZYRA-198/283 · DR-ZYRA-227
# STATUS: EIGHT BODIES RECOVERED / CLEAN REPLAY FAILED / APPLY HOLD / PRODUCTION UNCHANGED

## 1 · Outcome

The Founder-approved OA-ZYRA-198 expansion completed both authorised actions:

1. The remaining six OA-193 record-only migrations now contain the exact
   retained production statement bodies, alongside the two already recovered.
   All eight delimited UTF-8 body hashes are pinned and pass 10/10.
2. Colima and the Docker CLI were installed and used for an isolated, unlinked,
   no-production zero-state Supabase replay.

The replay did not pass. It truthfully stopped at the first database error,
which is earlier than the eight recovered bodies:

- failing version: `20260811104500_dev_rewind_journey_to_stage_one.sql`;
- SQLSTATE: `42P13`;
- error: `cannot remove parameter defaults from existing function`;
- failing statement: `CREATE OR REPLACE FUNCTION
  public.zyra_dev_rewind_journey(p_match_id uuid)`.

No historical file outside the six authorised recoveries was altered to make
the test pass. Production, its migration history, staged migrations
`20260910184252` and `20260910195642`, and TestFlight are unchanged.
OA-ZYRA-198 and OA-ZYRA-283 remain open; no Apply GO or Upload GO is requested.

## 2 · Authority and boundaries

The Founder's direct `Approved continue` on 2026-09-10 approved the exact next
scope presented after message 076:

- restore versions `20260811152809`, `20260811153416`, `20260811153547`,
  `20260811153643`, `20260811172021` and `20260811173212` from their exact
  retained live-history statements; and
- install a local Docker-compatible runtime for an isolated clean reset.

That authority was not expanded into permission to delete, archive, reorder or
rewrite other historical migrations, alter production history, apply either
September migration, upload a build, regenerate approved pixels or close an
OA. No git command was used and no private credential store was accessed.

## 3 · Exact eight-body recovery

Each production version has exactly one retained statement. The executable
statement is between one begin/end provenance marker pair in the matching
historical file. The focused test extracts only those bytes, hashes them as
UTF-8, rejects the old `SELECT 1` record body and pins the governed frontier.

| Version | Chars | UTF-8 bytes | Retained body SHA-256 | Current repository file SHA-256 |
|---|---:|---:|---|---|
| `20260811152220` | 12,626 | 13,274 | `82fdc1d13db0564ddfa9aeeb09fde7eb3b0a509e678005536c17b03b703d24fa` | `a24b555b47cf01b0cf07f758145a8610b7979c9b2424e2618d57af2df5deaaf1` |
| `20260811152255` | 5,435 | 5,514 | `884de52af3e96ef92ce5427a9a8c69b7a0b4cb6257309e43f8a2140031cbc2ed` | `4953a19531b2c228e2cedfe7047f0ca352289771a729fbc35da9ca769ed45160` |
| `20260811152809` | 7,058 | 7,062 | `38a2a20e810895d1975d4ec27eaea5db0cd03e78d3a114848171343bb2b16366` | `94799280bc9edd760bd1566e8b65dd79f6271a95bf32475c96edc9a4df9382bd` |
| `20260811153416` | 9,277 | 10,006 | `0f9022853b97fa328940e15296e885e917d83842ee19ff9d469ebef88e42fcfc` | `832c4bdfcac2e622700458810768a995a058d7186933ea5fb6458ac4ac3f3d6d` |
| `20260811153547` | 5,977 | 6,657 | `0a4149339dfbddc7b18a1bbf9da59ff79ea8f5cf73c6a97607d65f47ad852f5f` | `d444fae054e263a535acb79ae9f6d409fcf4c93fafe7114adb6b403f1f602338` |
| `20260811153643` | 6,754 | 7,170 | `cc919cc511b71d3061dac6036687ad353cdb43fa39f33e6b9d6e3f4bfd2ac4cc` | `76a051fc4c690854524c08cd57824cdc9774154eefb6feafdcb8cd3d56ad077c` |
| `20260811172021` | 5,124 | 5,136 | `88eb598aab415c90338ddbb0fa58d567ba36890830086e6995ccb024b1dc9671` | `8256b4ceca8258c9147c4a757c8d6541e43523bc80f8de6af36610fbaa893970` |
| `20260811173212` | 11,792 | 12,104 | `2e814b5f9962429ca202721788c7a0ad1778b20e908ed5e1fda2603a89b3d558` | `c479605f49363a33d5468c60d375de595b5e3b2861a322dbbfc9eff92f793519` |

The six newly recovered whole-file hashes differ from the retained-body hashes
because each repository file adds non-executable provenance comments outside
the exact body markers. That distinction is deliberate and tested.

## 4 · Isolated runtime and replay evidence

Installed local tooling:

- Supabase CLI `2.116.0` (pre-existing; not upgraded);
- Colima `0.10.3`;
- Docker CLI `29.7.2`;
- Lima `2.2.0`; and
- Docker Engine `29.5.2` inside the named Colima VM.

Installation used Homebrew without auto-update or auto-cleanup. `brew services
list` reports both `colima` and `cloudflared` as `none`; no automatic Colima
service was enabled.

Isolation controls:

- scratch root: `/private/tmp/zyra-oa198-replay.sQGrdy`;
- scratch `supabase/config.toml` SHA-256:
  `f8dbd7eb06ac6397a5ef8f85129f5372aea8e833343d9ea2d176245491ef7310`;
- project id: `zyra-oa198-replay.sQGrdy`;
- PostgreSQL major: 17;
- seeding: disabled;
- 209 SQL files copied byte-for-byte (`diff -rq` returned no difference);
- no project reference, pooler URL, database password or production link;
- named Colima profile: `zyra-oa198`, macOS Virtualization.Framework,
  aarch64, 4 CPUs, 4 GiB memory, 40 GiB disk, Docker runtime, virtiofs;
- named Docker network: `zyra-oa198-local`, host binding forced to
  `127.0.0.1`; and
- `DO_NOT_TRACK=1` used for Supabase CLI operations.

`supabase db start` against the empty scratch database performed the first
zero-state initialization, successfully applied versions `20260718190011`
through `20260811103056`, then reached `20260811104500`. It raised
`LegacyMigrationApplyError` / SQLSTATE `42P13` on statement zero of that
version; a later `db reset` could not truthfully begin because the local stack
never completed startup.

The failed Supabase start stopped its containers. Verification found zero
containers and zero volumes in the named profile. The empty localhost-only
network was removed, the Colima profile was stopped, `colima status` now says
it is not running, and the global Docker context remains `default`. The
installed runtime and scratch evidence directory were retained for the next
governed round. Available disk after installation/image download is about
49 GiB.

## 5 · First-failure root cause

The failing chain is deterministic:

1. `20260811102840_journey_timeline_milestones_and_rewind_all.sql` drops any
   one-argument rewind and creates
   `zyra_dev_rewind_journey(uuid DEFAULT NULL)`.
2. `20260811103056_rewind_keeps_journey_started_milestone.sql` replaces the
   same function while retaining `DEFAULT NULL`.
3. `20260811104500_dev_rewind_journey_to_stage_one.sql` then runs
   `CREATE OR REPLACE` on the same signature without a default and without a
   preceding drop. PostgreSQL rejects removing an existing parameter default.

This collision was introduced by the 2026-08-21 OA-AIOS-329 file-presence
round, which added active files 102840 and 103056 despite the still-preserved
OA-ZYRA-198 target and export-helper rule that those two live rows were
deliberately **not wanted as files**. The repository already carried their
replay-oriented work as:

- `20260811104500_dev_rewind_journey_to_stage_one.sql` — original one-match
  rewind;
- `20260811110300_journey_timeline_milestones.sql` — timeline-only split; and
- `20260811111500_dev_rewind_journey_account_wide.sql` — explicit drop then
  account-wide/defaulted rewind.

Read-only production history confirms the asymmetry:

| Version | Production history | Repository |
|---|---|---|
| `20260811102840` | present: `journey_timeline_milestones_and_rewind_all` | active file added 2026-08-21 |
| `20260811103056` | present: `rewind_keeps_journey_started_milestone` | active file added 2026-08-21 |
| `20260811104500` | absent | active repo-only file |
| `20260811110300` | absent | active repo-only split file |
| `20260811111500` | absent | active repo-only split file |

This is not a reason to mutate production history or edit the six newly
recovered bodies. It requires a governed decision about which representation
is active for local replay while every historical byte remains preserved.

## 6 · Later static blockers, not measured replay results

The first-error rule prevented speculative patching or replaying past 104500.
Static audit nevertheless records two later prerequisites so they are not
rediscovered as surprises:

1. `20260811153416` conditionally renames `zyra_seed_ch4_questions`, then
   unconditionally alters `zyra_onboarding_questions`. No earlier active repo
   migration creates either table or its original 72 rows / 71 distinct qids.
   Version `20260811173212` adds only the later 33 rows. If chronology is fixed
   without restoring that direct-DDL provenance, expected failure is `42P01`.
2. `20260811233813` unconditionally enables RLS on
   `public.zyra_probe_score`. No active repo migration creates that live scratch
   table. If the earlier table gap is repaired, expected failure is also
   `42P01`.

These are static predictions, not claims that the database reached either
version. They need their own provenance evidence and Founder authority. The
eight exact recovered statements must remain exact.

## 7 · True pre-state and current identities

True pre-files were copied before editing to
`/private/tmp/zyra_oa198_full_pre_20260910.6JK42s`. New report 077 was absent.

| File | True pre SHA-256 | Current SHA-256 at first filing |
|---|---|---|
| `20260811152809...sql` | `7a40157c3fe7eac28812a0b2dbc8e2c64aef00e566a133fb90473e35e95b6b6b` | `94799280bc9edd760bd1566e8b65dd79f6271a95bf32475c96edc9a4df9382bd` |
| `20260811153416...sql` | `12c792bc948a415f3713a3836e26072e7a82b50321ae3ad7098c24bea9c23d49` | `832c4bdfcac2e622700458810768a995a058d7186933ea5fb6458ac4ac3f3d6d` |
| `20260811153547...sql` | `32f49ed299c79b8bd75c1636e18bd29236d6b0273524b677a30bc7f5c3f82065` | `d444fae054e263a535acb79ae9f6d409fcf4c93fafe7114adb6b403f1f602338` |
| `20260811153643...sql` | `b29ccb216d0bd1fdad661a439e3acb2aafc22fe16c012ba8304844f5f3ad1f8d` | `76a051fc4c690854524c08cd57824cdc9774154eefb6feafdcb8cd3d56ad077c` |
| `20260811172021...sql` | `c3c1a5ddd44c2799023554002d5afc7726f11b2020e84d7038b4a5a2a9ba63f4` | `8256b4ceca8258c9147c4a757c8d6541e43523bc80f8de6af36610fbaa893970` |
| `20260811173212...sql` | `0377296c25e3d5f3562c3f706b672daf32b72a6b3f0b92a56756024f4e898bdc` | `c479605f49363a33d5468c60d375de595b5e3b2861a322dbbfc9eff92f793519` |
| recovery test | `cb2a9e4769ecab54dfb6f8a5372794ae96937eee024ca560e7e0c6b26110fac5` | `e686c1a6ce4124a6c3c0ed59a422721fee10bb42aef96ac0684d99ec99930e34` |
| OA-193 migration README | `755ed115d2f3d8d6483eaaaf0d204b0ed9d66f7ea18ce9a879031d2e98899ce9` | `0fe9ac323bb08768b78fe19886e04acdcd44797281f823e96f95a5fb24cc7a25` |
| export helper | `b296bda21761830654d4ec1ee81b37ee24836cfa7af960e67d8e1dc8b9331cf2` | `223b5bcd7bdf87727861dbdd431383694711d850625d1bd2d80c04cfa070097c` |
| `CLAUDE.md` | `c44a8a5ead67499c38da0452a2dc28e5641d51160b2d409025fca26bf3c46d2e` | `4020249ed781cbfd9c82c7604a1e053bbefa7c9e8b98fa28dc73f8dcad065b73` |
| OA register | `e229929639aec576644f592bde4db9d075f0f9da859ee122ea61a2d8bd6a1959` | `8ddcaeea2198994948561ae8bd1e7cfdf80584c67bd39313ed1118008770ba06` |
| Compatibility boundary handover | `f621039e0a4bdf56b68759a8d2fbf9d1c6b7b5ffd2b3bd50b6d7ab48bb7edfdc` | `9edeef8fd49d7a1d81858a89904c33b49bb8adea14e523b771eb7c97ee70aecc` |
| generated documentation index | `ecdd8430e3c820bba419768afcde804cad9e248c6b9f600ead8293ddb3c65bde` | `097a4d4b54ed711ce0040bed38159fb524d2d85530dd0710f3516ea178b62c69` |

The two staged production migrations remained byte-stable:

- OA-ZYRA-283 `20260910184252`:
  `63381febeb9b1732447adb24a6225c1006f42171bc8b5b5e4f5a61712f54296d`;
- Request New Journey hold `20260910195642`:
  `0ac36fd4c4c7ed03b8a4fe80ef75d4cb43c10355426d6a972814961f5e061545`.

## 8 · Verification

- exact recovered-body tests: 10 passed, 0 failed;
- combined recovery/OA-ZYRA-283/temporary-hold tests: 20 passed, 0 failed;
- full non-visual Flutter suite: 543 passed, 0 failed;
- `flutter analyze`: no issues;
- `python3 tools/zyra_check.py`: 186 files, 0 findings;
- checker unit test: 1 passed, 0 failed;
- full suite including approved goldens: 818 passed, 60 failed, all failures
  in the existing visual-regression file; no approved pixel was regenerated or
  edited. The run emitted 240 diagnostic images under
  `test/visual/failures/`;
- clean local migration replay: FAILED at first error 104500 / 42P13;
- production migration apply/history mutation: not run;
- TestFlight upload: not run;
- git: not used; and
- private credentials: not accessed.

The visual failures are recorded separately from the migration failure because
this round changed no Flutter UI or approved baseline. They do not convert a
failed database replay into a pass and were not "fixed" by regenerating pixels.

## 9 · Required next authority

Recommended next ruling, kept inside OA-ZYRA-198:

> Approved — preserve the exact 20260811102840 and 20260811103056 files in a
> governed evidence archive, remove only those two duplicate live-history
> copies from the active replay directory, and rerun the same isolated
> zero-state replay using the intended 20260811104500 → 20260811110300 →
> 20260811111500 repository sequence. Stop and report at the first result. Do
> not apply production migrations or upload TestFlight.

This is reversible and byte-preserving; it follows OA-ZYRA-198's original
exclusion rule and tests the existing split representation without deleting
historical evidence. The later question-bank and scratch-table bootstrap gaps
remain separate stop conditions if reached.

— Codex / Operating Partner, 2026-09-10
