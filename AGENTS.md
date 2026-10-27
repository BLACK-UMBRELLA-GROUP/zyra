# AGENTS.md — ZYRA

<!-- BLACK-UMBRELLA-CORE-RULES v4 START — master copy: BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/AGENT_CORE_RULES_CURRENT_VERSION_V4.md. Edit the master, then re-sync every copy. -->
## Core rules — every AI agent, every Black Umbrella Group project

These rules sit above every other instruction in this tree. Where any older
document, overlay or AD says otherwise, this block wins.

> **BUILD FREEZE — Founder, 24 Oct 2026.** No app feature building in any business
> until Shakeel lifts it in writing. Allowed meanwhile: review, documentation, and
> fixes Shakeel approves one by one. Tracked as OA-AIOS-406.

1. **Only the Founder (Shakeel) approves.** Agreement between AIs is never
   approval. His direct instruction in conversation is approval.
2. **Only Codex runs git, and only within these limits** (AD-AIOS-114). Allowed:
   `git status`, `git add`, `git commit`, and `git push` to `origin` on the current
   branch - in the repo of the project he is working in, at the end of a task whose
   tests passed; plus the 04:00 job's sweep, which commits and pushes what is left in
   every repo. Never: force-push, reset, rebase, amend or rewrite pushed history,
   `git clean`, checkout/restore over working files, delete branches, change remotes or
   git config, or commit a file over 50 MB or anything from the keys folder.
   `ZYRA/SITE`: commit, but never push until Shakeel's Cloudflare check (OA-AIOS-407).
   Claude chats (Fable and the business chats) never run git.
3. **Never touch `PRIVATE — API KEYS — DO NOT SYNC`** — never open, list,
   copy or quote it, wherever it lives. Never put keys, tokens or
   credentials in a conversation.
4. **Never delete.** Move unwanted files into a `_to_delete` folder; the
   Founder empties it. If `_to_delete` is missing, create it.
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
    commit in his task note. The 04:00 sweep commits what Fable and the business chats
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
| Implementation | Codex | Builds from locked designs only (rule 11): code, tests, as-built handovers. No design of his own, no admin, governance, mailbox or schedules. Exceptions: the 04:00 daily report job with its commit sweep (DOC-BUG-0027), and git within rule 2 |
| Admin | Fable (Claude), from the Black Umbrella Group chat | Admin for every business: registers, schedules, clean-ups, reporting, the daily review |

Fable holds an active seat. Any line elsewhere saying "Fable/Claude is
retired" or "no Claude/Fable bootstrap is active" is superseded.
<!-- BLACK-UMBRELLA-CORE-RULES v4 END -->

## What we are building (read before any ZYRA work)

**The planned ZYRA is the Founder preview** — the latest design built with Codex, which opens when the Founder signs in
(`SOURCE/lib/dev/zyra_founder_launch_screen.dart` → `ViewRequestDraftScreen` / `ZyraOneJourneyConceptShell`). It runs on sample
people today. The ordinary member app (`HomeShell`, `journey_flow_screen.dart`) is the **old app being replaced**. Features the
preview retired — Pause and Save — are retired for ZYRA ("Request restart" after an ending is planned, not retired). Decision DR-ZYRA-274 (25 Oct 2026); work tracked in OA-ZYRA-316; deep review DOC-ZYRA-0285.
**The rules are the blueprint** (CURRENT, Founder-approved 26 Oct): part 1 screen map DOC-ZYRA-0278, the part 2 rule pages
(Journey, Guardians, Membership, Browse, Messages, Profile, Onboarding, Safety), parts 3-7 - routes in `MAP.md`. Building
anything that breaks a blueprint page needs a new Founder decision first; update the page in the same change.
Update this paragraph the same day the direction changes (lesson S13).

## Locked design workflow (core rule 11, AD-AIOS-115)

| Step | Who | Where |
|---|---|---|
| Brief | Shakeel | ZYRA chat (Claude) - the **lead designer** |
| 2-5 options, one picture at a time, each with "what changed" | ZYRA chat | Chat |
| Pick and tweak, then `LOCK` | Shakeel | Chat |
| Record the LOCK: screen pictures at **real phone size with the real tabs/bars on top**, every state (empty, loading, error), a spec with numbers (sizes, positions, rules, data), and a `LOCK_RECORD.md` line with Shakeel's words and the date | ZYRA chat | `PRODUCT/APPROVED/<FEATURE>/` - one live copy `<NAME>_CURRENT_VERSION_V<n>.<ext>`, old ones `<NAME>_<date>_V<n>` in `ARCHIVE/` |
| Build brief: locked file paths, "copy exactly, no improvements", what not to touch, checks | ZYRA chat | `PRODUCT/APPROVED/<FEATURE>/BUILD_BRIEF_<YYYY-MM-DD>.md` - Shakeel only tells Codex "Build <that path>" |
| Check the locked files first, report problems, then build exactly | Codex | Task note: "Built from: <paths>" plus a screenshot of the built screen beside the master |
| Compare the build with the master | ZYRA chat | Its chat note; Fable files the decision (DR-ZYRA) at 04:15 |

Lessons from AZMARA: never specify a behaviour in words only - add a picture of the expected result; never lock art before the
screen's data, navigation and states; review at real phone size before `LOCK`; locked design sources live in the repo, not only
in a chat's workspace. A change to a locked design = a new `LOCK` and a new version. The blueprint stays the rulebook: a design
that would change a rule needs Shakeel's decision first.

## Standing ZYRA rules

| Rule | Source |
|---|---|
| `SUB BUSINESS/` was removed 24 Oct: older documents saying `SUB BUSINESS/<venture>` mean `DEVELOPMENT/<venture>`. Never recreate it | Knowledge routing standard §10 |
| **One app.** `SOURCE/` is one Flutter product, ZYRA. The separate ZYRA Test app is cancelled - never recreate it. Unsupported or retired build variants must fail closed, never fall back to production | OA-ZYRA-286 |
| **Developer access** needs all of: the compile-time opt-in (off by default), the pinned company Founder account ID, the main database and the Founder role. An email address alone never grants it. Public builds stay locked | OA-ZYRA-286 |
| **Phone delivery.** After a Founder-requested routine change is built and checked, Codex may build, install and open the PROFILE app on the paired Founder iPhone while he says he is home - no second approval for that same change. When he says he is away, wait. Stop on any failure or drift. This never covers TestFlight uploads, signing, backend, payment or migration changes. Paused by the build freeze | DR-ZYRA-257, OA-AIOS-406 |
| **Uploads.** Every TestFlight upload needs the Founder's exact GO for that build number; there is no standing upload authority | Runbook DOC-ZYRA-0254 §3 |

History (build 3, mailboxes 110-116, the Test-app retirement): `REPORTS/ARCHIVE/AGENTS_HISTORY/ZYRA_AGENTS_HISTORY_2026-10-26.md`.

## Read in this order

0. The core rules at the top of this file - they win on any conflict. Master copy:
   `../BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/AGENT_CORE_RULES_CURRENT_VERSION_V4.md`.
   New agent? Read once: `../BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/OPERATING_MODEL_CURRENT_VERSION_V1.md`
   (roles, how work flows, GO, reporting) and `../BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/AGENT_LESSONS_LEARNED_CURRENT_VERSION_V2.md`.
1. `MAP.md` - the **task routes** say which 2-5 documents to open for your kind of task. Open only those. Read the map
   only down to "Route paths" (the file paths); search the rest by ID. Re-run
   `python3 "../BLACK UMBRELLA GROUP/SYSTEM/TOOLS/generate_map.py" .` after adding, renaming or retiring a document.
2. `SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md` and `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` are **never read
   whole.** Start from `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2_INDEX.md` and
   `SYSTEM/DECISIONS_REGISTER/DECISIONS_V1_INDEX.md`, then search by ID. Check the live NEXT IDENTIFIER before drafting entries.
3. Building or changing the app: `SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/ZYRA_RULES_CURRENT_VERSION_V1.md` (DOC-ZYRA-0277) and
   `../BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_STANDARDS/IMPLEMENTATION_HANDOVER_STANDARD_CURRENT_VERSION_V4.md`.

Roles are in the core rules (V4, 27 Oct). Older role models (AD-AIOS-097 to 111) are history in the AD register.
