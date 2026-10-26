# AGENTS.md — ZYRA

<!-- BLACK-UMBRELLA-CORE-RULES v2 START — master copy: BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/AGENT_CORE_RULES_CURRENT_VERSION_V2.md. Edit the master, then re-sync every copy. -->
## Core rules — every AI agent, every Black Umbrella Group project

These rules sit above every other instruction in this tree. Where any older
document, overlay or AD says otherwise, this block wins.

> **BUILD FREEZE — Founder, 24 Oct 2026.** No app feature building in any business
> until Shakeel lifts it in writing. Allowed meanwhile: review, documentation, and
> fixes Shakeel approves one by one. Tracked as OA-AIOS-406.

1. **Only the Founder (Shakeel) approves.** Agreement between AIs is never
   approval. His direct instruction in conversation is approval.
2. **No AI runs git. Ever.** The Founder commits in his own Terminal.
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
10. **End every working session with a commit.** Agents never run git; they
    end each session by giving the Founder one commit line per changed repo.
    Never copy files as a backup instead — git and the USB are the backups.

### Roles — Founder direction, 2026-10-24 (AD-AIOS-112, filed 2026-10-24; supersedes AD-AIOS-111)

| Seat | Holder | Scope |
|---|---|---|
| Founder | Shakeel | Sole approver |
| Lead Architect | Fable (Claude) | Architecture, governance, registers, schedules, review and verification |
| Design & Implementation | Codex | Product design and code execution only — no admin, governance, mailbox or schedules (one exception: the 04:00 daily report job, DOC-BUG-0027) |
| Admin | Fable (Claude), from the Black Umbrella Group chat | Admin for every business: registers, schedules, clean-ups, reporting. One Claude chat per business handles that business's design and product work |

Fable holds an active seat. Any line elsewhere saying "Fable/Claude is
retired" or "no Claude/Fable bootstrap is active" is superseded.
<!-- BLACK-UMBRELLA-CORE-RULES v2 END -->

## What we are building (read before any ZYRA work)

**The planned ZYRA is the Founder preview** — the latest design built with Codex, which opens when the Founder signs in
(`SOURCE/lib/dev/zyra_founder_launch_screen.dart` → `ViewRequestDraftScreen` / `ZyraOneJourneyConceptShell`). It runs on sample
people today. The ordinary member app (`HomeShell`, `journey_flow_screen.dart`) is the **old app being replaced**. Features the
preview retired — Pause and Save — are retired for ZYRA ("Request restart" after an ending is planned, not retired). Decision DR-ZYRA-274 (25 Oct 2026); work tracked in OA-ZYRA-316; deep review DOC-ZYRA-0285.
**The rules are the blueprint** (CURRENT, Founder-approved 26 Oct): part 1 screen map DOC-ZYRA-0278, the part 2 rule pages
(Journey, Guardians, Membership, Browse, Messages, Profile, Onboarding, Safety), parts 3-7 - routes in `MAP.md`. Building
anything that breaks a blueprint page needs a new Founder decision first; update the page in the same change.
Update this paragraph the same day the direction changes (lesson S13).

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
   `../BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/AGENT_CORE_RULES_CURRENT_VERSION_V2.md`.
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

Roles are in the core rules (V2, 24 Oct). Older role models (AD-AIOS-097 to 111) are history in the AD register.
