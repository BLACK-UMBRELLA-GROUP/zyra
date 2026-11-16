# AGENTS.md — ZYRA

<!-- BLACK-UMBRELLA-CORE-RULES v4 START — master copy: BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/AGENT_CORE_RULES_CURRENT_VERSION_V4.md. Edit the master, then re-sync every copy. -->
## Core rules — every AI agent, every Black Umbrella Group project

These rules sit above every other instruction in this tree. Where any older
document, overlay or AD says otherwise, this block wins.

> **BUILD FREEZE — Founder, 24 Oct 2026; updated 13 Nov 2026.** Builds come only from LOCKed
> designs (rule 11) and work Shakeel names. **Building: THE FOUR GATES and WAFA** (WAFA unfrozen
> 8 Nov, AD-AIOS-131; THE FOUR GATES at night, AD-AIOS-141). **ZYRA: fixes only** - lines already
> WAITING finish; no new feature LOCKs until the app is connected to its server (AD-AIOS-149).
> **SELAH paused** after its checks (AD-AIOS-131, -145). **AZMARA stays frozen** until Shakeel lifts
> it in writing. Quiet mode 21 Nov-14 Dec (AD-AIOS-149). At most two businesses are worked at a time
> (Mac memory, Founder 3 Nov). Allowed while frozen: review, documentation, and fixes Shakeel
> approves one by one. Tracked as OA-AIOS-406, AD-AIOS-123.

1. **Only the Founder (Shakeel) approves.** Agreement between AIs is never
   approval. His direct instruction in conversation is approval.
2. **Only Codex runs git, and only within these limits** (AD-AIOS-114). Allowed:
   `git status`, `git add`, `git commit`, and `git push` to `origin` on the current
   branch - in the repo of the project he is working in, at the end of a task whose
   tests passed; plus the 01:00 job's sweep, which commits and pushes what is left in
   every repo. Never: force-push, reset, rebase, amend or rewrite pushed history,
   `git clean`, checkout/restore over working files, delete branches, change remotes or
   git config, or commit a file over 50 MB or anything from the keys folder.
   `ZYRA/SITE`: commit, but never push until Shakeel's Cloudflare check (OA-AIOS-407).
   Read-only commands are always allowed (`git log`, `git rev-list`, `git show`, `git diff`,
   `git ls-files`, `git branch -a`) and so are read-only scanners such as gitleaks; the
   limits above are about writing (Founder, 1 Nov 2026: "Yes, permanently" - AD-AIOS-120).
   Claude chats (Fable and the business chats) never run git.
3. **Never touch `PRIVATE — API KEYS — DO NOT SYNC`** — never open, list,
   copy or quote it, wherever it lives. Never put keys, tokens or
   credentials in a conversation.
4. **Never delete.** Move unwanted files to `~/_to_delete/<WHAT>_<date>/` on the Mac -
   the ONE delete folder (Founder, 10 Nov: "I DONT WANNA HAVE TO DELETE 2 FODLERS");
   **never a `_to_delete` or `tmp/_to_delete` inside any repo** (S22, S25). The Founder
   empties it. If the folder is missing, create it.
5. **Findings become actions** — every finding gets an OA number or a
   written refusal.
6. **One CURRENT_VERSION per document system.** Register entries append
   above the metadata block and bump the live NEXT IDENTIFIER.
7. **BUILD → DOCUMENT → TRACE → HANDOVER.** Code-complete is not
   handover-complete.
8. **Evidence is not a build store.** Review evidence = screenshots, JSON
   and a text BUILD.json (commit SHA, Flutter version, build mode,
   timestamp). Never copy compiled apps (`Runner.app`, build products) or
   source trees into registers or evidence folders.
9. **`AGENTS.md` holds standing rules only.** Progress, round status and
   decisions go in the registers. Keep every `AGENTS.md` under 16 KB —
   Codex stops reading at 32 KiB.
10. **Every finished task ends in a commit.** Codex commits and pushes his own work
    at the end of each task (message: what changed, with the OA/DR IDs) and lists the
    commit in his task note. The 01:00 sweep commits what Fable and the business chats
    changed ("Admin changes <date>"). Until Codex is onboarded, the Founder commits
    from one line per changed repo. Never copy files as a backup instead — git and
    the USB are the backups.
11. **Nothing is built until it is LOCKed** (AD-AIOS-115). Each business's Claude chat is
    its lead designer. A design is a draft until Shakeel says `LOCK` and the chat records
    it in that business's approved folder: picture(s) at real screen size with the real
    navigation on top, every state (empty, loading, error), a written spec with numbers,
    and his words. Codex builds only from locked files - he checks them first and
    reports problems, and never invents, redraws or "improves" a design.

### Roles — Founder direction, 2026-10-24 (AD-AIOS-112, filed 2026-10-24; supersedes AD-AIOS-111)

| Seat | Holder | Scope |
|---|---|---|
| Founder | Shakeel | Sole approver |
| Lead Architect | Fable (Claude) | Architecture, governance, registers, schedules, review and verification |
| Lead designer, per business | That business's Claude chat (ZYRA, AZMARA, WAFA…) | Product, rules, UX, layout, wording, look, master pictures and specs; records each LOCK (rule 11); writes build briefs for Codex. Never code, never git |
| Implementation | Codex | Builds from locked designs only (rule 11): code, tests, as-built handovers. No design of his own, no admin, governance, mailbox or schedules. Exceptions: the 01:00 daily report job with its commit sweep (DOC-BUG-0027), and git within rule 2 |
| Admin | Fable (Claude), from the Black Umbrella Group chat | Admin for every business: registers, schedules, clean-ups, reporting, the daily review |

Fable holds an active seat. Any line elsewhere saying "Fable/Claude is
retired" or "no Claude/Fable bootstrap is active" is superseded.
<!-- BLACK-UMBRELLA-CORE-RULES v4 END -->

## Backend readiness (AD-AIOS-142)

Read `BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_STANDARDS/BACKEND_READINESS_STANDARD_CURRENT_VERSION_V1.md` (DOC-BUG-0057) when your trigger in its §2 may be met. ZYRA's Supabase project is ZYRA's only: no other business may use its server, keys or data. One server per business, never shared. AIs write plans only; every account, cost, key and live connection waits for the Founder's own yes.

## Public repository (AD-AIOS-121, Founder 2 Nov 2026)

This repository is public on GitHub under Apache 2.0. Every push is visible to anyone. Before and after each push:

| Step | When | What |
|---|---|---|
| A. Secret scan | Before every push | Run `gitleaks detect --source . --log-opts="origin/main..HEAD"` (read-only scanner, AD-AIOS-120). Any finding that is not the Supabase public anon key: do not push; file it in QUESTIONS.md and mark the line QUESTION. Never print the secret in a report. |
| B. Private material | Before every push | No business, pricing, legal, finance or personal documents in this repo - they live in BLACK UMBRELLA GROUP/BUSINESS/ZYRA/. If a task creates one here, move it there and leave nothing behind. Never anything from the keys folder. |
| C. Roadmap | After a task that finishes a ROADMAP.md row | Tick the row (add "Done <date>" in its Intended result cell), close the matching GitHub roadmap issue with `gh issue close <n> --comment "Done in <commit>"`, and push. Never add new rows or change hours - that is Fable's job on the Founder's word. |
| D. Release | When the app version in pubspec.yaml (or the repo's version file) changes | Create a GitHub pre-release with `gh release create v<version>-build<n> --target main --prerelease --notes "<one line per finished queue line>"`. No local git tag commands. |
| E. Wording | Every document you write or edit | Neutral community wording only - never "Muslim" or "Islamic" (DOC-BUG-0038 table). App text members see is design: list it for the business chat, do not change it. |
| F. README | When a task changes what the app does or how to run it | Update the README in the same push. |

Record A-F in the task note's Commit line ("public checks: A ok, B ok, C row n / none, D none, E ok, F none").


## What we are building (read before any ZYRA work)

**The planned app is the Founder preview** (`SOURCE/lib/dev/zyra_founder_launch_screen.dart` → `ViewRequestDraftScreen` /
`ZyraOneJourneyConceptShell`). Founder sign-in opens it with sample people. Other accounts still open the retired member
app (`HomeShell`, `journey_flow_screen.dart`), which must never reach members. Pause and Save are retired. Request restart
after Ending is planned (DR-ZYRA-274, OA-ZYRA-316, DOC-ZYRA-0285).
**Follow the Founder-approved blueprint** (26 Oct), including screen map DOC-ZYRA-0278 and the rule pages routed by `MAP.md`.
A departure first requires a Founder decision and a blueprint update in the same change. Update this summary the day direction changes (S13).

## Locked design workflow (core rule 11, AD-AIOS-115)

| Step | Who | Where |
|---|---|---|
| Queue dispatch | Codex | GO and 01:00 receivers only dispatch to one fresh normal chat per eligible WAITING line. If creation fails, file QUESTION and continue independent work. The owner runs `python3 "../BLACK UMBRELLA GROUP/SYSTEM/TOOLS/start_pack.py" "ZYRA" "<DEVELOPMENT-relative brief path>"`, then reads only brief-named files. Note start-pack bytes, named reads, `Conversation: new (started HH:MM)` and actual count-only usage. Verify the note and commit before archival (OA-AIOS-426) |
| Brief | Shakeel | ZYRA chat (Claude) - the **lead designer** |
| 2-5 options, one picture at a time, each with "what changed" | ZYRA chat | Chat |
| Pick and tweak, then `LOCK` | Shakeel | Chat |
| Record the LOCK with full-size phone pictures showing real bars and every state, numeric spec, rules, data, and the Founder's words and date in `LOCK_RECORD.md` | ZYRA chat | `PRODUCT/APPROVED/<FEATURE>/`. Keep one `<NAME>_CURRENT_VERSION_V<n>.<ext>` and date older versions in `ARCHIVE/` |
| Give every LOCKed build or Founder-named task a brief naming inputs, scope and checks, plus one WAITING row in `PRODUCT/APPROVED/BUILD_QUEUE.md` | ZYRA chat | `PRODUCT/APPROVED/<FEATURE>/BUILD_BRIEF_<YYYY-MM-DD>.md`. Queue runs at 01:00 or on Shakeel's GO in the ZYRA Codex chat (charter rule 9, Founder 29 Oct) |
| Check the locked files first, report problems, then build exactly | Codex | Task note: "Built from: <paths>" plus a screenshot of the built screen beside the master |
| Compare the build with the master | ZYRA chat | Its chat note; Fable files the decision (DR-ZYRA) at 04:15 |
| At 05:36 compare the newest app screenshots and `BUILT/` folders with the masters and prototype, then update the prototype to match the app | ZYRA chat | In the "Morning check" note, list every difference for Shakeel. Fable files OAs (Founder 29 Oct) |

Include a picture of expected behaviour. Review data, navigation and states at phone size before `LOCK`. Keep locked sources
in the repo. Design changes need a new `LOCK` and version. Blueprint rule changes need Shakeel's decision first.

## Standing ZYRA rules

| Rule | Source |
|---|---|
| `SUB BUSINESS/` was removed 24 Oct: older documents saying `SUB BUSINESS/<venture>` mean `DEVELOPMENT/<venture>`. Never recreate it | Knowledge routing standard §10 |
| **One app.** `SOURCE/` is one Flutter product, ZYRA. The separate ZYRA Test app is cancelled - never recreate it. Unsupported or retired build variants must fail closed, never fall back to production | OA-ZYRA-286 |
| **Developer access** needs all of: the compile-time opt-in (off by default), the pinned company Founder account ID, the main database and the Founder role. An email address alone never grants it. Public builds stay locked | OA-ZYRA-286 |
| **Gate.** A red ZYRA CI check fails the gate for every ZYRA queue line | DOC-ZYRA-0508 |
| **Phone delivery.** After a Founder-requested routine change is built and checked, Codex may build, install and open the PROFILE app on the paired Founder iPhone while he says he is home - no second approval for that same change. When he says he is away, wait. Stop on any failure or drift. This never covers TestFlight uploads, signing, backend, payment or migration changes. Paused by the build freeze | DR-ZYRA-257, OA-AIOS-406 |
| **Uploads.** Every TestFlight upload needs the Founder's exact GO for that build number; there is no standing upload authority | Runbook DOC-ZYRA-0254 §3 |

History (build 3, mailboxes 110-116, the Test-app retirement): `REPORTS/ARCHIVE/AGENTS_HISTORY/ZYRA_AGENTS_HISTORY_2026-10-26.md`.

## Read in this order

0. The core rules at the top of this file - they win on any conflict. Master copy:
   `../BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/AGENT_CORE_RULES_CURRENT_VERSION_V4.md`.
   New agent (an AI's first ever session in this repo - not a fresh Codex queue chat, which reads only what charters rule 9 lists; Founder, 1 Nov 2026)? Read once: `../BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/OPERATING_MODEL_CURRENT_VERSION_V1.md`
   (roles, how work flows, GO, reporting) and `../BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/AGENT_LESSONS_LEARNED_CURRENT_VERSION_V2.md`.
1. `MAP.md` - the **task routes** say which 2-5 documents to open for your kind of task. Open only those. Read the map
   only down to "Route paths" (the file paths); search the rest by ID. Re-run
   `python3 "../BLACK UMBRELLA GROUP/SYSTEM/TOOLS/generate_map.py" .` after adding, renaming or retiring a document.
2. `SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md` and `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` are **never read
   whole.** Start from `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2_INDEX.md` and
   `SYSTEM/DECISIONS_REGISTER/DECISIONS_V1_INDEX.md`, then search by ID. Check the live NEXT IDENTIFIER before drafting entries.
3. Building or changing the app: `SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/ZYRA_RULES_CURRENT_VERSION_V1.md` (DOC-ZYRA-0277) and
   `../BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_STANDARDS/IMPLEMENTATION_HANDOVER_STANDARD_CURRENT_VERSION_V4.md`.

## Public check before you finish (AD-AIOS-146)
This is a public repo. Before ending any session (business chat or Codex line owner), run
`BLACK UMBRELLA GROUP/SYSTEM/TOOLS/fable_public_check.py` on every file you wrote or changed here, and move or reword any
hit first (private material goes to `BLACK UMBRELLA GROUP/BUSINESS/<BUSINESS>/`). Founder, 12 Nov 2026: "Yes, make it
required (Recommended)".

## Blockers found mid-run: hand them to Claude at once (AD-AIOS-147)
Founder, 12 Nov 2026: "all codex chats ... if they find issues that block anything mid process ... show me what to paste
to claude so they can continue working ... rather than showing at end of the run. i want every codex chat to learn this."
1. The moment you find something that blocks, or will block, any line (a gap or clash in a brief or LOCK, a missing server
   contract, an unclear design detail), **stop only that part** and at once show Shakeel, in the chat, a ready-to-paste
   message headed **"Paste this to <name> Claude chat"**: **ZYRA Claude chat** for design, LOCK, spec, app-brief and
   wording questions; **Fable - BLACK UMBRELLA GROUP Claude chat** for server-design questions (scoring, storage, data
   protection, server briefs) - Founder 12 Nov "Fable answers server (Recommended)". Plain words, exact questions, the file and line it is about.
2. Also file the `QUESTIONS.md` row as usual, then **keep working** on every line and step that is not blocked. Never wait
   for the end of the run to report a blocker.
3. When the Claude chat's answer lands (row ANSWERED, brief updated), pick the blocked part back up in the same run.
4. Unattended runs (01:00, nobody watching): put every paste message in the first lines of the report, under
   "Paste to Claude", before anything else.

**Disk and trip (AD-AIOS-149, Founder 13 Nov):** start no new queue line when the Mac has under 15 GB free - report and stop. 21 Nov - 14 Dec is quiet mode: only work that needs no approvals and no downloads.
**ZYRA fixes only (AD-AIOS-149):** no new feature LOCKs until the planned app is connected to the server; queued lines and fixes continue.
