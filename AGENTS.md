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
Update this paragraph the same day the direction changes (lesson S13).


Bootstrap pointer for AI agent sessions working in `ZYRA/`.

> **Path change, 2026-10-24:** the `SUB BUSINESS/` folder was removed. Each venture now sits
> directly in `DEVELOPMENT/` — `ZYRA`, `AZMARA`, `SELAH`, `WAFA`, `AI CONSULTANCY TBC`. Older documents
> and registers still say `SUB BUSINESS/<venture>`: read that as `DEVELOPMENT/<venture>`.
> Never recreate `SUB BUSINESS/`. Folder guide:
> `BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_STANDARDS/KNOWLEDGE_ROUTING_STANDARD_CURRENT_VERSION_V2.md`
Rules live in the documents below, not here. Read them in this order:

> **LOCAL PHONE DELIVERY DEFAULT — Founder direct instruction, 2026-10-04 /
> DR-ZYRA-257:** after implementing and checking a Founder-requested routine
> app change, build/install/native-launch the existing main PROFILE app on the
> existing paired Founder iPhone while his latest stated availability is home.
> Do not ask for a second install approval for that same scoped change. The
> Founder will say when away (including a later correction); then defer local
> delivery until he says home again. Check connected/unlocked state, existing
> identity/signature and exact installed process; stop on failure or scope drift.
> Never infer a remote/TestFlight upload, new signing/registration authority,
> backend/payment/provider/migration change or physical acceptance. Developer
> Control handover §37 and One-App Internal Delivery Runbook §3 own this rule.

> **OPERATING MODEL:** see Core rules at the top of this file (Founder
> direction 2026-10-24, supersedes AD-AIOS-111).

> **ONE ACTIVE APP — Founder direct instruction, 2026-09-12 / OA-ZYRA-286:**
> `SOURCE/` remains one shared Flutter product, **ZYRA**. The separate ZYRA Test
> delivery is CANCELLED, not waiting for another replay. Main internal builds
> require explicit default-OFF compile opt-in, the pinned company Founder UUID,
> exact main endpoint and refreshed protected role for local developer previews.
> Personal accounts retain ordinary member onboarding/backend permissions;
> email text alone never grants developer authority. Default/public builds
> remain locked. `./run.sh` now selects the main app; old Test modes refuse.
> Founder approved retiring the separate Test setup with historical records
> preserved. Active native/runtime/server retirement is complete and its fresh
> verification is recorded in mailbox 112. Mailbox 113 records POST-VERIFIED
> deletion of the empty Test Supabase project and both Test Google clients.
> One Test domain listing remains after Google's contradictory dependency
> warning; no main login configuration was changed. OA-ZYRA-286 stays open.
> Do not bulk-delete shared tests/security code or historical approvals and
> consumed one-use evidence. Read the narrowed one-app Developer Control
> handover, App Store runbook and mailbox 110–116 before proceeding.
> DR-ZYRA-228/229 remain historical decisions beneath this named override.
> Explicit unsupported/retired variants must fail closed, never become an
> implicit production fallback. The Founder approved one complete main build-3
> delivery, including necessary managed signing assets. The first restricted-
> environment signature failure and stop remain preserved in 114. The Founder
> then approved one normal-keychain check/resume: that check PASSED, without
> rebuild or trust changes. Internal-only build 3 was exported and its final
> distribution signature/identity verified in 115. Mailbox 116 records the
> successful one-use upload and Apple post-verification on 2026-09-13:
> main 1.0.0 (3) is internal Testing in Founder Internal, with only
> admin@zyraconnect.app and automatic distribution OFF. Build 2 is retained.
> The upload authority is consumed; no retry. Founder device acceptance of
> build 3 is pending. Use the company Google identity for the pinned Founder
> preview route; the same email through Apple is not assumed to be that UUID.
> Founder accepted local Terminal for quick tweaks and batched TestFlight
> releases for remote testing. No persistent upload credential was authorized
> or created, and this cadence is not standing future-build upload authority.

0. Core rules at the top of this file — roles and non-negotiables; they win on
   any conflict. Master copy:
   `../BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/AGENT_CORE_RULES_CURRENT_VERSION_V2.md`.
   Then `../BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/OPERATING_MODEL_CURRENT_VERSION_V1.md`
   — roles, how work flows, exact-action GO, reporting.
   Then read `../BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/AGENT_LESSONS_LEARNED_CURRENT_VERSION_V1.md`
   — lessons from Aug–Oct 2026 and Codex's standing first task.
1. This `AGENTS.md` is the active ZYRA bootstrap. Archived Claude/Fable files
   remain historical evidence only.
2. `MAP.md` — every live ZYRA document by ID with one line each, and the **task routes**:
   which 2–5 documents to open for your kind of task. Open only those. Re-run
   `python3 "../BLACK UMBRELLA GROUP/SYSTEM/TOOLS/generate_map.py" .` after adding, renaming
   or retiring a document.
3. `SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md` (827 KB) and
   `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` (1.4 MB) — **never read whole.**
   Start from `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2_INDEX.md` (open actions) and
   `SYSTEM/DECISIONS_REGISTER/DECISIONS_V1_INDEX.md` (every decision on one line), then search by ID. Check the live NEXT IDENTIFIER before drafting entries.
4. Building or changing the app: `SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/ZYRA_RULES_CURRENT_VERSION_V1.md`
   (DOC-ZYRA-0277 — what needs approval, the check before building, which document owns a fact), and `../BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_STANDARDS/IMPLEMENTATION_HANDOVER_STANDARD_CURRENT_VERSION_V4.md`
   — required as-built repository memory for meaningful work.

Roles: the Core rules at the top of this file (V2). AD-AIOS-097 → 099 → 100 → 105 →
106 → 107 → 111 are historical — read them in the AD register. The long historical
role and routing text that sat here was removed on 2026-10-24; git keeps it.

Current operating state: the Founder replaced the AD-AIOS-111 / OA-AIOS-379
model on 2026-10-24 — see Core rules at the top of this file. Fable is Lead
Architect and admin; Codex is design and implementation only. Preparation, internal
read-only verification, Founder GO, execution, post-verification and Founder
acceptance remain separate; no agent self-approves.
Group-wide non-negotiables: Core rules at the top of this file (master:
`../BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/AGENT_CORE_RULES_CURRENT_VERSION_V2.md`).
