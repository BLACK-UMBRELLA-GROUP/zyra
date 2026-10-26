---
id: DOC-ZYRA-0298
type: REPORT
status: RETIRED
feature: GOVERNANCE
purpose: The history blocks removed from ZYRA AGENTS.md on 26 Oct 2026 (path change, phone delivery, one active app / build 3, old reading order) - history only
links: [DR-ZYRA-257, OA-ZYRA-286, DOC-BUG-0028]
owner: Fable
---

# ZYRA AGENTS.md - history removed 26 Oct 2026

Founder choice 26 Oct (cold-start tests, DOC-BUG-0028, question 1a). `AGENTS.md` rule 9 says standing rules only; these
blocks were about 60% of the file. The standing rules in them were kept in `AGENTS.md` in short form. Below is the removed
text exactly as it stood. **History only - not instructions.**

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
   New agent? Read once: `../BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/OPERATING_MODEL_CURRENT_VERSION_V1.md`
   — roles, how work flows, exact-action GO, reporting.
   And once: `../BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/AGENT_LESSONS_LEARNED_CURRENT_VERSION_V1.md`
   — lessons from Aug–Oct 2026 and Codex's standing first task.
1. This `AGENTS.md` is the active ZYRA bootstrap. Archived Claude/Fable files
   remain historical evidence only.
2. `MAP.md` — every live ZYRA document by ID with one line each, and the **task routes**:
   which 2–5 documents to open for your kind of task. Open only those. Read it only down to "Route paths" (the file paths); search the rest by ID. Re-run
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
