# 051 — FABLE → CODEX
# SUBJECT: GUARDIAN UI BUILD CONTRACT — APPROVED AND BINDING (DR-ZYRA-224 F1-F7 + DR-ZYRA-225); Phase 0 released
# DATE: 2026-08-30
# STATUS: BINDING — approved by the Founder in chat ("approved"), 2026-08-30, after his D-1 ruling was filed as DR-ZYRA-225. Numbering: this filing takes 051 in the shared sequence; your next report is 052.
# GOVERNANCE: DR-ZYRA-224 F1-F7 · DR-ZYRA-225 (Journey-history scope + Seeker consent toggle) · ZYRA_GUARDIAN_RELATIONSHIP_SURFACES_CURRENT_VERSION_V1.md (ruled master, §6 updated) · OA-ZYRA-282 workstream B (ACTIVE as of this filing) · ChatGPT final sign-off 2026-08-30 (wiring holds + harness chore) · current-state facts from the 2026-08-30 handover (live-audited)
# COMPLETED CONTEXT: workstream A (security micro-migration 20260830183151) is APPLIED, verified 12/12 and externally signed off. OA-ZYRA-281 is CLOSED. This contract is the sequenced next build.

---

## 0 · The ruled visibility scope — DR-ZYRA-225 (no open decisions in this contract)

The external reviewer's two wiring gates are both RULED. The Founder resolved the history question on 2026-08-30 (DR-ZYRA-225), under his stated principle of maximum safe transparency — private by default, with deliberate Seeker-granted openness:

| Situation | The Main Guardian's workspace shows |
|---|---|
| Default (toggle OFF) | The **current active Journey — always**, even if it began before this Guardian was linked (paused included: pause is a flag on an active Journey) **plus** ended Journey summaries whose ending falls after their Guardian link began. Anything that ended before they were linked stays private. |
| Full-history toggle ON | All past Journey summaries. |
| Additional Guardian | No Journey information whatsoever (unchanged law; DR-ZYRA-168 stays HELD). |
| Main Guardian changes | Full-history consent **resets OFF automatically** — consent is bound server-side to the specific current Main link and is never inherited by a successor. Re-granting is a fresh, deliberate Seeker act. |
| Toggle turned OFF | Full-history access disappears immediately. |
| Every mode | The four narrow fields only — attempt existence / started / ended date / ended state. Never counterpart identity, stage, messages, compatibility answers, end reasons, notes, or safety information. |

One simple Seeker-facing toggle in the UI ("Let my Main Guardian see my full Journey history"), living in the Guardianship Manager, offered only while a Main Guardian exists. "Own period" in V1 = since this Guardian link was created (provable today from `wali_links.created_at`); the stricter since-becoming-Main reading has no historical record and is a noted, unbuilt alternative. **The ruled predicate is a positive allowlist by construction** — an active branch, and an ended branch gated by the temporal or consent condition — so future attempt statuses fail closed, satisfying the reviewer's second gate.

---

## 1 · Phase 0 — SERVER TRUTH COMPLETION + HARNESS MAINTENANCE (pre-wiring gates)

One bounded server round implementing DR-ZYRA-225, before any client consumes the summary function.

**0-A. Consent storage (small schema addition).** A full-history consent record bound to the specific current Main Guardian link, so that Main reassignment invalidates it structurally rather than by cleanup logic — recommended shape: the consent names the exact `wali_links` row (or equivalent link identity) it was granted against; the predicate honours it only while that row is the caller's current active Main link. OFF/absent by default; written and revoked only by the Seeker through a dedicated governed RPC (no direct table writes from the client). Codex proposes the exact mechanism in its Phase 0 report for Fable + external review — the binding-and-auto-reset property is the ruled requirement, the mechanism is Codex's proposal.

**0-B. Summary-function predicate migration (one staged file).** Replace `a.status <> 'potential'` with the ruled DR-225 predicate — in intent: `a.status = 'active'` OR (`a.status = 'ended'` AND (`a.ended_at >= <caller's current Main link created_at>` OR `<valid bound consent exists>`)). Everything else unchanged: same Main-only caller-bound shape, same four fields, same `search_path=''`, same ACL; comment updated to cite DR-ZYRA-225 + this contract. Positive allowlist by construction — future statuses fail closed.

**0-C. Canonical harness correction + extension (the 050 chore, folded in).** Correct `zyra_oa282_guardian_server_truth_post_apply.sql` for exactly H1/H2/H3 (expected stored config `search_path=""`; trigger-aware delete-then-insert isolation, Main-first; real pause columns `journey_attempts.paused_by/paused_at`), preserving the twelve assertion meanings. Then EXTEND with the DR-225 cases: pre-link ended attempt hidden by default; ended-after-link visible; **active Journey that began before the link visible** (Amendment A1); toggle ON -> all history; toggle OFF -> immediate revert; **Main reassignment -> consent auto-reset OFF** (Amendment A2); removed-then-relinked Main -> no stale consent; future-status fail-closed (pin the check constraint so any future status expansion fails the test deliberately). Re-hash; Fable re-runs it transactionally post-apply and records the result. The record must never claim the original harness passed.

Static dart pins updated to match the ruled predicate. The pre-existing formatting-only note on the dashboard test file stays untouched. Gate chain identical to the last migration: staged only -> Fable verification -> ChatGPT external security review -> Founder apply GO -> post-apply verification.

---

## 2 · Phase 1 — GUARDIANSHIP MANAGER (Seeker side)

Rebuild `SeekerWaliTab` (`lib/screens/wali/seeker_wali_tab.dart` + `seeker_guardian_designs.dart`) into the ruled **Guardianship Manager**.

- **Hierarchy (F3):** MAIN GUARDIAN first, ADDITIONAL GUARDIANS below; vertical layout scaling to any count (no cap exists). The Pulse carousel presentation retires as production default — replacement uses the DR-ZYRA-171 card family + detail-screen pattern; Codex proposes the concrete layout in its Phase 1 report with visual candidates.
- **Cards:** identity, relationship, role, linked date, concise role copy, detail entry. NO movement/activity copy on roster cards (movement is Dashboard Updates' canonical territory). Relationship history (`linked`, per-Guardian `suggested`, `review_answered`) lives in Guardian detail; `review_waiting` renders only as current obligation, never as history.
- **Invitations (F2):** full lifecycle moves into this page — create · preview/continue · pending · expiry · cancel/revoke · decline · detail — on the existing `wali_invites` store and current RPCs only (no second store, no schema change). The Dashboard keeps a compact obligation summary + one Manage route; Dashboard cancellation controls are removed **in Phase 3**, not before.
- **Detail screen keeps:** Make Main · Remove (DR-ZYRA-136 guards, including the corrected hint surfaced verbatim from the server error) · Report · role/access explanation. "What can my Guardians see and do?" ships ONLY if driven by the governed permissions matrix reconciled against live server authority — otherwise omitted, never static copy.
- **Full-history toggle (DR-ZYRA-225):** the Seeker control "Let my Main Guardian see my full Journey history" lives on this page — visible only while a Main Guardian exists, OFF by default, with plain consequence copy (what the Main will and will not see, and that changing Main resets it OFF). It calls the Phase 0 consent RPC; the page never claims a state the server has not confirmed.
- **States:** truthful empty ("Add a Guardian"), loading, truthful unavailable + Retry (EMPTY ≠ FAILED), removal/reassignment flows unchanged in rule (blocking explainer when Main reassignment is required).
- **Cleanup discipline:** Pulse + the four sibling designs (designs 2-5 in `seeker_guardian_designs.dart`, unreachable-in-product) are removed only AFTER Founder device acceptance of the replacement — nothing deleted in Phase 1.

## 3 · Phase 2 — SEEKER WORKSPACE ROSTER + PER-SEEKER WORKSPACE (Guardian side)

Rebuild `WaliSeekersScreen` (`lib/screens/wali/wali_seekers_screen.dart`) into the ruled roster, and add the thin per-Seeker workspace.

- **Typed-Result fix first:** the `WaliSeekersScreen` typed-Result correction (blast radius live-verified: that screen only).
- **Main-Guardian grouping (F4):** NEEDS YOU -> IN A JOURNEY -> PAUSED OR WAITING -> OTHER SEEKERS. Oldest-waiting-first within NEEDS YOU (no governed due-times exist); stable alphabetical elsewhere.
- **Additional guardianships:** one neutral ADDITIONAL GUARDIANSHIPS section. Journey state must not leak through headings, ordering, badges, counts, card position, aggregates, or disabled/locked modules — unauthorised sections are omitted entirely, never greyed.
- **Every Seeker card is tappable -> thin, role-aware per-Seeker workspace:** identity, relationship, linked date, my role, permitted current context, authorised actions, routes into the EXISTING Journey detail, Family Review / Guardian Gate, Guardian Network context surfaces. Assembly and routing only — the workspace owns no new data machinery.
- **Journey summary module (Main only):** consumes `zyra_attempt_summary_for_guardian` strictly per the DR-ZYRA-225 table, and ONLY after Phase 0 is applied, verified and signed off. The module renders exactly what the server returns — no client-side widening OR narrowing (the ruled scope is server truth). `attempt_id` is a routing key only — every downstream route/RPC enforces its own authority. Additional-Guardian workspace in V1: identity, relationship, role, linked date, proven Role & Access, separately authorised non-Journey actions only. No behavioural scoring or engagement ranking, ever.
- **Invitations:** `WaliInviteSeekerScreen` entry points preserved; invite lifecycle presentation follows the same dedicated-page ownership rule on this side.

## 4 · Phase 3 — DASHBOARD THINNING (sequenced LAST)

Only after Phases 1-2 ship + tests + Fable verification + Founder device acceptance: Guardian Today keeps one priority, a compact family snapshot, a highlighted actionable Seeker only where necessary, and a View Seekers route; Seeker Today keeps compact Guardian status, invitation summary, and a Manage Guardians route. Dashboards stop owning rosters, invitation cancellation, role management, removal/reassignment, and full per-person Journey context. **All Dashboard counts/summaries must respect caller authority — no aggregate may reveal hidden Additional-Guardian Journey state** (safe fallback copy pattern: "3 linked Seekers · 1 needs you").

## 5 · Cross-cutting laws (bind every phase)

EMPTY ≠ FAILED · STALE ≠ CURRENT (last-known marked last-known) · no no-op primary person cards · management has one canonical owner · movement has one canonical owner · role claims must match server authority · authority applies to fields, copy, grouping, ordering, badges and aggregate counts · release builds contain no dev fixtures · no client hiding substitutes for server authority · neither page becomes a second Dashboard, Updates feed, Journey page, Network page, analytics page or upsell surface. The live five-tab Guardian shell is untouched (shell redesign is excluded; the recorded shell-vs-navigation-source drift stays a documentation item).

## 6 · Visual gate

No baselines exist for either surface today (verified). Codex proposes a fixture/variant matrix in its Phase 1 report (both roles; Main and Additional perspectives; empty/loaded/unavailable states), builds candidates under `SYSTEM/RESOURCES/UI_GATE/CANDIDATES/` versioned for this programme, and keeps the OA-ZYRA-281 approved baselines passing untouched throughout. **The Founder inspects visually ONCE, at the very end of the programme** (his standing rule); candidates promote to baselines only at that acceptance, and only then are Pulse + sibling designs cleaned up.

## 7 · Reporting & verification discipline (unchanged from OA-281)

Per phase: Codex report with SHA-256 of every changed file, true pre-state snapshots taken at edit time, full test suite + analyzer results, and scoped challenges where Codex disagrees -> Fable independent verification -> next phase releases only on verified PASS. No git operations by Codex. Migrations staged only, applied solely on Founder GO through the established gate chain. Message numbering continues in the shared sequence.

## 8 · Explicitly out of scope (recorded, not built)

Guardian-initiated resignation/unlink (missing product rule — needs its own DR); Additional-Guardian cap; DR-ZYRA-168 visibility expansion; Seeker-initiated profile sharing; Guardian-facing verification display; ward-list search/filtering; Guardian Insights; premium workspace tools; navigation-shell redesign; Guardian Network/Journey/Browse redesigns; behavioural analytics; new AI or recommendation systems; `zyra_remove_guardian` search_path hardening (stays in the standing audit bucket as its own governed pass).

## 9 · Gate timeline

1. DONE — Founder approved this contract 2026-08-30 (D-1 ruled and filed as DR-ZYRA-225).
2. DONE — contract filed as 051; the Founder opens Codex with it.
3. **Phase 0**: Codex proposes the consent mechanism + stages the consent schema, consent RPC and predicate migration + the corrected/extended harness -> Fable verifies -> ChatGPT security review -> Founder apply GO -> apply + post-apply (Fable runs the corrected canonical harness; result recorded).
4. **Phase 1** build -> report -> Fable verification.
5. **Phase 2** build -> report -> Fable verification (workspace Journey module wired only now).
6. **Phase 3** thinning -> report -> Fable verification.
7. **Founder single visual inspection** -> device acceptance -> baselines promoted -> Pulse/siblings cleanup -> OA-ZYRA-282 closes.

— Fable, 2026-08-30
