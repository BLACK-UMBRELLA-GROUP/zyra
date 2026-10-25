# 085 — CODEX → FOUNDER
# SUBJECT: OA-ZYRA-198 probe-score replay bridge internally verified; exact 209-version replay GO required
# DATE: 2026-09-11
# GOVERNANCE: AD-AIOS-109 · OA-ZYRA-198/257/274/283 · DR-ZYRA-227 · messages 081–084 · Founder direct TestFlight instruction
# STATUS: INTERNALLY VERIFIED / REPLAY NOT AUTHORISED / PRODUCTION APPLY PROHIBITED / UPLOAD PROHIBITED

## 1 · Outcome

The next clean-replay frontier is resolved as a frozen candidate, without
altering retained history or the active production migration path.

1. No retained creator statement, migration version or original statement
   boundary for `public.zyra_probe_score` survives.
2. Read-only live catalog inspection established its exact schema and security
   shape. No row value was read or copied.
3. A new replay-only bridge reconstructs only that catalog-proven three-column
   table, with zero rows, immediately before historical migration
   `20260811233813`.
4. The bridge and its post-target PostgreSQL 17 proof pass. A separate
   read-only Codex sub-review gives a clean pass.
5. The unchanged 207 active migrations and both quarantined replay bridges are
   now ready for one fresh, seedless 209-version replay, but that destructive
   reset requires a separate exact Founder one-use GO.

No full replay, production mutation, migration apply, signed archive, Apple
upload, git operation or private-credential access occurred.

---

## 2 · Why reconstruction is required

The one authorised V2 replay reported in message 084 passed the question-bank
bridge and all reached successors through
`20260811233755_fix_duplicate_journey_ended_milestone.sql`. It stopped at
statement 7 of unchanged migration `20260811233813`:

`ALTER TABLE public.zyra_probe_score ENABLE ROW LEVEL SECURITY`

PostgreSQL returned SQLSTATE `42P01` because the table creator was absent from
retained migration history. An exhaustive read-only search found references to
the table's historical scoring/stewardship use, but no creator SQL. The evidence
places its out-of-band creation on 2026-08-10/11, before the hardening migration.
The absence is recorded rather than presented as recovered history.

---

## 3 · Read-only production catalog evidence

Project inspected: `sxoaxonzjqkgajmlagyk`.

| Property | Live measured value |
|---|---|
| relation | ordinary permanent table, owner `postgres` |
| columns | `viewer text`, `rows_returned integer`, `score numeric` |
| column rules | all nullable; no defaults, identity or generated columns |
| RLS | enabled; FORCE RLS disabled |
| rows | 2 live; count only, no values read |
| constraints / indexes / policies | 0 / 0 / 0 |
| triggers / rules | 0 / 0 |
| table / column comments | none / none |
| ACL | `{postgres=arwdDxtm/postgres,service_role=arwdDxtm/postgres}` |

The bridge deliberately copies **zero** live rows. The clean replay remains
seedless.

---

## 4 · Frozen replay-only artifact

Directory:

`SYSTEM/RESOURCES/MIGRATION_HISTORY/OA-ZYRA-198_2026-09-11_RECONSTRUCTED_PROBE_SCORE_REPLAY_BRIDGE/`

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| `20260811233812_oa198_reconstructed_probe_score_replay_bridge.sql` | 7,302 | `9f9a818f3370b849ba1ff21f1d4ea9c3adb9ab866b22e15f6ba7a03454b46b46` |
| `README.md` | 5,792 | `6250dbb0723bd56de0325de07c9cc4ae945d7a8d4964f5557d0fc782b12e7a39` |
| `manifest.json` | 6,432 | `bcda455ae7ce12a39da3a3da8560079b8f5bcace23d6e7878b340e8c336b5a2e` |
| `SOURCE/supabase/tests/zyra_oa198_probe_score_replay_bridge_pg17_runtime.sql` | 4,676 | `bfbd13da58a12b9cacfdca79ab86f26b1484127171fb28e89106687547446997` |
| `SOURCE/test/zyra_oa198_probe_score_replay_bridge_artifact_test.dart` | 8,967 | `97de713fbbfd15680e8f909ec37ed987a2ac4636c36fcb56b5c7d3b5b9f89e19` |

The bridge mode is `0600`. Artificial ordering version `20260811233812` is
explicitly labelled reconstruction-only, is absent from the active folder and
does not claim to be recovered production history.

Fail-closed preconditions require:

- PostgreSQL user `postgres`;
- an existing `supabase_migrations.schema_migrations` catalog;
- exact predecessor version `20260811233755`;
- no existing bridge version;
- no reached version at or beyond `20260811233813`; and
- an absent `public.zyra_probe_score` relation.

Postconditions assert the exact three columns, owner/relation properties,
zero rows, and absence of constraints, indexes, policies, comments, rules and
triggers before commit.

---

## 5 · PostgreSQL 17 proof

The bridge, followed by the two unchanged table-hardening statements from
historical migration `20260811233813`, executed in a fresh disposable container
using cached image `public.ecr.aws/supabase/postgres:17.6.1.165`
(`server_version_num = 170006`).

Isolation was network mode `none`, zero published ports, zero mounts, no
application migrations, no seed, no project reference, no database URL and no
production credential. The proof harness:

- embeds psql `ON_ERROR_STOP`;
- begins a read-only transaction and always rolls back;
- checks the final live-equivalent catalog shape and exact ACL;
- checks all effective table privileges denied to `anon` and `authenticated`,
  including PostgreSQL 17 `MAINTAIN`; and
- returns `OA-ZYRA-198 PROBE SCORE BRIDGE PG17 PASS`.

The disposable container was auto-removed and the named Colima profile stopped.

---

## 6 · Replay inventory

| Input | State |
|---|---|
| active migrations | 207 unique versions |
| active digest | `8a36926aaca155493f16a731ee498204f0d0225e2a5b41cc66f89e1da39b8861` |
| question-bank V2 bridge | 28,501 bytes; `337b342df347b7e902d8da32bafd0a2b21516550b9234213298079304ca66aa1` |
| probe-score bridge | 7,302 bytes; `9f9a818f3370b849ba1ff21f1d4ea9c3adb9ab866b22e15f6ba7a03454b46b46` |
| future scratch total | 209 unique versions |
| active-folder bridge copies | zero |

V1 and V2 must never coexist in a scratch replay. Both selected bridges remain
outside `SOURCE/supabase/migrations`.

---

## 7 · Apple and local release truth

Read-only live Apple verification is complete:

- App Store Connect record: **ZYRA Connect**, Apple ID `6810741513`;
- TestFlight: **No Builds** and no internal testing group;
- Developer App ID: explicit `app.zyraconnect.zyra`;
- Team: `9Y7Z8F36SJ`;
- enabled capabilities include Sign in with Apple and Push Notifications; and
- no Apple setting was changed.

OA-ZYRA-274 is completed. The source remains version `1.0.0+2`, display name
**ZYRA**, automatic signing on the paid team, and internal-only export options.
The retained build-1 IPA is still forbidden. A fresh build-2 archive will use
unique archive/export paths after the database cutover passes. A direct host-
keychain check finds two valid Apple Development identities and no Apple
Distribution identity, so Xcode's authenticated automatic/cloud distribution-
signing path must be proven by that fresh archive.

---

## 8 · Validation

| Check | Result |
|---|---|
| bridge artifact test | PASS — 4/4 |
| focused replay/migration/TestFlight pack | PASS — 41/41 |
| all non-visual Flutter tests | PASS — 564/564 |
| full `flutter analyze` | PASS — no issues found |
| `python3 tools/zyra_check.py` | PASS — 186 files, 0 findings; 5 baselined references, 0 new |
| checker unit test | PASS — 1/1 |
| internal Codex sub-review | CLEAN PASS |
| full Flutter run | 839 pass / 60 known visual comparison failures |

The same 60 visual failures are the already-recorded OA-ZYRA-257 debt from
later 2026-09-09 Dashboard changes: 15 Dashboard families × four variants.
They were present and expressly reported in message 073. No approved pixel was
regenerated, overwritten or promoted here. There is no functional-test failure
and no probe-bridge failure.

---

## 9 · True pre-state and post-state ledger

True existing-file pre-states were captured before editing under
`/private/tmp/zyra_probe_bridge_pre.UZxdmB`.

| File | True pre-state SHA-256 | Post SHA-256 |
|---|---|---|
| `CLAUDE.md` | `276cfc2846ccd0bae666d1e744bd6bd7d7d5678544766873c672e06e99b0f4b3` | `a7b0be75d09affb3b108629dcf083894d87f0bdd7447886ba1cc98ea90db9506` |
| OA register | `57f479324007e4aa3514b3cfa3c40144f6a44da44594866ff252137402cad26b` | `9b55f7cb5556ed4218570e09e7a85a84e3c166865c66ca57f280513643c20965` |
| compatibility boundary handover | `345b73f6c31cae88d6b85d4d34f72f79e1ea60fd79295817112c8c8e395d4e94` | `40d1ac94273dec6b075081311bedc61c880b701bc93dcebbdc9ffaa4a727e70e` |
| App Store runbook | `6de7a68fbbd3cd818e8c2dbebbc5d7eb821037e9126bfe2bf579ae3db21cb4ac` | `1828e92d495b7da2cfdd10fa90c2b851caa010ab8d363886dd0570e2dc7c1e81` |
| documentation index | `2f238de994e069d182e779b4dbd589fc53aa70cd7e11996355064694d73efee8` | `860f42a70c194dcd69798ac50cd5f4613fb0f4dd53742fac5c7490695b0dba9e` |
| migration README | `e64098322af1ad5de11d5f97c6308aa72310e09181ca87a0a3d1b5993f7759f4` | `883b24a9ad288b6d6927441479748d44ebdcd3dccb3299d327d86d905c48cc65` |
| probe bridge SQL | **ABSENT** | `9f9a818f3370b849ba1ff21f1d4ea9c3adb9ab866b22e15f6ba7a03454b46b46` |
| probe bridge README | **ABSENT** | `6250dbb0723bd56de0325de07c9cc4ae945d7a8d4964f5557d0fc782b12e7a39` |
| probe bridge manifest | **ABSENT** | `bcda455ae7ce12a39da3a3da8560079b8f5bcace23d6e7878b340e8c336b5a2e` |
| `SOURCE/supabase/tests/zyra_oa198_probe_score_replay_bridge_pg17_runtime.sql` | **ABSENT** | `bfbd13da58a12b9cacfdca79ab86f26b1484127171fb28e89106687547446997` |
| `SOURCE/test/zyra_oa198_probe_score_replay_bridge_artifact_test.dart` | **ABSENT** | `97de713fbbfd15680e8f909ec37ed987a2ac4636c36fcb56b5c7d3b5b9f89e19` |
| this message 085 | **ABSENT** | new filing; self-hash cannot be embedded without changing itself |

The first runtime draft exposed one ambiguous catalog-character concatenation;
it was corrected before the bridge was frozen. Independent review then caught
two proof-harness safeguards—psql failure-stop and PostgreSQL 17 `MAINTAIN`.
Both were corrected, pinned and rerun before this filing. The bridge SQL hash
never changed during those harness corrections.

---

## 10 · Exact next gate

The current replay authority was consumed by message 084's first-result run.
General approval does not authorize another destructive reset. The required
single-use Founder wording is:

> I authorise exactly one destructive reset of a fresh disposable local
> PostgreSQL 17 database using question-bank V2 bridge SHA-256
> 337b342df347b7e902d8da32bafd0a2b21516550b9234213298079304ca66aa1
> and probe-score bridge SHA-256
> 9f9a818f3370b849ba1ff21f1d4ea9c3adb9ab866b22e15f6ba7a03454b46b46.
> Use the unchanged 207-file active migration set plus those two bridges only
> (209 unique versions), seedless and isolated; no production access; stop at
> the first result; no repair or retry.

After that replay returns its first result, production apply and Apple upload
remain separate exact Founder gates. This message authorises neither.

— END OF MESSAGE 085 —
