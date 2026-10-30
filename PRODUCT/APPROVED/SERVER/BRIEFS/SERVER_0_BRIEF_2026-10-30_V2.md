---
id: TBC (Fable assigns)
type: PLAN
status: CURRENT
feature: ZYRA SERVER
purpose: SERVER 0 second attempt - corrections R1-R4 from the 30 Oct NOT READY record; throw-away database only
links: [DOC-ZYRA-0329, OA-ZYRA-317, OA-ZYRA-319, OA-ZYRA-198]
owner: ZYRA chat
---

# SERVER 0 — CATCH-UP PROOF — BRIEF V2 — 30 OCT 2026

Replaces `SERVER_0_BRIEF_2026-10-30.md` (queue line 28, FAILED → `../ARCHIVE/`). Codex's record
`../RECORD/SERVER_0_READY_2026-10-30.md` (NOT READY) found four conflicts. This brief settles each one.
**This line never changes the live database.** Step 2 of V1 (the live read-only pass) is done — reuse
`REPORTS/CURRENT/ZYRA_LIVE_DATABASE_CHECK_2026-10-30_V1.md`; re-run only the migration-list comparison at the end.

## Founder decisions, 30 Oct 2026 (ZYRA chat, clickable)
| # | Question | Answer |
|---|---|---|
| D1 | Use the locked-away August repair files to rebuild a throw-away copy? | **"Yes, throw-away only (Recommended)"** |
| D2 | The kept Main-Guardian hold still uses retired Pause columns — how to fix? | **"Rewrite the hold (Recommended)"** |

## Corrections
| # | Conflict | What to do |
|---|---|---|
| R1 | Full replay needs the historical question-bank creator | **Replay authority (D1):** for this line, on **isolated, network-none, throw-away** PostgreSQL 17 databases only, you may run full replays as many times as needed using the unchanged active files **plus** the two quarantined bridges exactly as `SOURCE/supabase/migrations/README_20260811_OA193.md` names them: OA-ZYRA-198 reconstructed bridge **V2** (SHA-256 `337b342df347b7e902d8da32bafd0a2b21516550b9234213298079304ca66aa1`) and the probe-score bridge (SHA-256 `9f9a818f3370b849ba1ff21f1d4ea9c3adb9ab866b22e15f6ba7a03454b46b46`). Check both hashes before use. Never V1. Never copy them into the active directory, never use them on a linked or production database. The authority ends when this line is marked |
| R2 | Kept 18 Sep Main-Guardian hold references `pause_state` from the dropped 25 Aug Pause file | **Rewrite (D2):** add a new dated migration that replaces the hold's trigger/function with one that does not read or write `pause_state` (the hold's own behaviour otherwise unchanged); the original 18 Sep file moves to `~/_to_delete/SERVER0_V2_2026-10-30/` with a note, like the other rewrites. No inert Pause columns. The 25 Aug shared-Pause file stays dropped |
| R3 | Kept f04 is preparation-only by design | **Exclude f04 from the production payload.** Keep it in the repo, run its synthetic fixture locally as today, list it in the READY record under "not for live — needs its own reviewed cutover (client wiring, saved results, privacy)". Do not remove its guard or fake its GUC |
| R4 | "All suites pass" includes the retired Pause suite | Retire `zyra_pause_decision_state_machine_suite.sql` and the Pause-only assertions (move to `~/_to_delete/SERVER0_V2_2026-10-30/` with a note; Journey D/J/L/M sections already archive old Pause). The gate is: **every applicable suite passes**, run in this order — independent minimal-schema harnesses, then full-schema suites, then fixtures (f02, f04), then the two-worker concurrency suites. List each file with PASS / RETIRED / NOT APPLICABLE and why; a blocked suite is never counted as passed |
| f02 | The 24 Sep rewrite changes a view and an RPC that f02 pins | The rewritten 24 Sep file must keep f02's pinned participant view (six columns) and Guardian RPC return shape, or add a compatible helper so f02's preflight passes **unchanged**. Never weaken f02 |

## Steps
| Step | Detail |
|---|---|
| 1 | Read DOC-ZYRA-0329 (§3.2, §3.4, §3.6, §4, §5), the NOT READY record, this brief, and `SOURCE/supabase/tests/`. Never open the keys folder; never print, log or copy a key, URL secret or token |
| 2 | Throw-away full replay (R1) from empty, in order. Record it |
| 3 | Apply the unapplied files as DOC-0329 §4 decided, with R2, R3 and f02 above: drop 25 Aug Pause; keep 18 Sep code matching and telemetry (off), 19 Sep Circle messaging, 23 Sep retire legacy purchases, 25–26 Sep Circle participants/sender/read receipts, 5 Oct f01–f07 (f04 local only); rewrite 24 Sep paid-only contract (Basic 1 place, safe send rule kept, view replay fixed), 19 Sep Journey return gate (ended-then-restart) and the 18 Sep hold. Each new file does one thing |
| 4 | Suites before and after step 3 as R4; an impersonation test for every rule a kept or rewritten file changes |
| 5 | Re-run the live read-only migration-list comparison (BEGIN READ ONLY / ROLLBACK). Stop on any drift |
| 6 | **Stop.** Write `../RECORD/SERVER_0_READY_<date>_V2.md`: READY or NOT READY at the top; exact ordered production file list with SHA-256 each (f04 excluded); replay and suite results; backup plan (point-in-time backup and restore path to confirm before any apply; no drops in the same change that stops writes) |
| 7 | No app code change, no production write, no dependency added. Task note (plain words), commit within core rule 2, mark this line BUILT (= READY record written) or FAILED |

Applying to production stays a separate line that needs the Founder's words **"apply SERVER 0 to live"** after a confirmed backup.
