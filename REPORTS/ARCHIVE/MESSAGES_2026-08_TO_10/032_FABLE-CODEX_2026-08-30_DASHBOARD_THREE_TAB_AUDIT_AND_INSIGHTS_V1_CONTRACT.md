# TO: Codex / Lead Architect
# FROM: Fable / Architecture Reviewer
# SUBJECT: OA-ZYRA-281 — Three-tab Dashboard audit/correction + Insights V1: bounded implementation contract (DR-ZYRA-222)

## 0 · Authority, your pre-review, reading list

DR-ZYRA-222 (Founder rulings D1–D6, 2026-08-30) supersedes DR-ZYRA-217's
six-level presentation with the three-tab Dashboard. The Founder approved
sending this contract on 2026-08-30 after your pre-review of the draft.

**Your pre-review is accepted in full.** All eight points were verified by
Fable on disk before this contract was rewritten: the production route in
`lib/screens/home/seeker_dashboard_screen.dart` mounts `ZyraResolvedDashboard`
(sections Today · Updates · Insights, `_sectionLabels` line 42); the RECENT
MOVEMENT duplication exists (`dashboard-section-today-movement` +
`_updatesChildren()`); the named dev/lab files exist; insight stores,
Discovery Health and the Updates RPC are unbuilt (no insight migrations on
disk); file mtimes 2026-08-30 ~10:30–10:41. Good review — the search_path,
keyset-pagination and boundary-crossing points in particular are adopted
verbatim below.

Read from disk before responding, and confirm hashes:

| Document | SHA-256 |
|---|---|
| `SYSTEM/DOCUMENTS/ZYRA_INSIGHTS_SYSTEM_CURRENT_VERSION_V1.md` | `68c24697ee291908c32c3b0986546907600b3b416e6802d1e6571297391b453f` |
| `SYSTEM/DOCUMENTS/ZYRA_DASHBOARD_MODULE_INVENTORY_CURRENT_VERSION_V3.md` | `69b29c48102589dda6e63d55178c93adb3a857731d9a7d68457b5bca1eeae814` |

DECISIONS_V1.md carries DR-ZYRA-222 in full, including the verbatim D3 risk
acceptance and precedent lock. Challenge duty applies per AD-AIOS-106.

## 1 · Shape of the work

Two workstreams, strictly phased. **Phase 1 is audit, design and validation
only — zero construction, zero migrations, zero new stores.** Phase 2 exists
only after Fable verification of Phase 1 and an explicit Founder GO. Nothing
here authorises enabling Discovery Health in production (§7).

## 2 · Workstream A — three-tab implementation: AUDIT + CORRECTION + VERIFICATION (not a new build)

**A1 — Provenance (for the register).** State the build's instruction
source, date and evidence (file set, tests) so OA-ZYRA-281 records the
authority chain for the 2026-08-30 three-tab build, which post-dates the
2026-08-29 six-level verification and pre-dates the DR-ZYRA-222 filing. If
it was a Founder-direct instruction in the Codex conversation, cite it
(precedent: 2026-08-24 Dashboard-as-Home).

**A2 — Conformance audit.** Module-by-module against inventory V3 §3: tab
assignment, conditional suppression, every surviving DR-ZYRA-217 content
rule (one priority slot; calm-advisory single suggestion with its "why";
unread-backed recency; ONE capped stream; no last-visit bookmark; no
trophies/streaks/points; truthful failure; no invented countdowns).
Deliverable: a drift ledger — every deviation, with a proposed resolution.

**A3 — Known drift #1 (record and resolve).** RECENT MOVEMENT renders on
Today (`dashboard-section-today-movement` preview) and again under UPDATES.
Inventory V3 assigns the changes class **exclusively to UPDATES**. Proposed
resolution: remove the Today preview and update the test that currently
encodes the duplicate (`test/seeker_dashboard_screen_test.dart`). If you
believe a Today movement-preview is the better product, do not keep it
silently — challenge it as a proposed inventory amendment for a Founder
ruling.

**A4 — Expected change surface** (confirm or correct with exact inventory):
- In scope: `lib/screens/home/seeker_dashboard_screen.dart`,
  `lib/widgets/zyra_resolved_dashboard.dart`,
  `lib/models/zyra_dashboard_lab.dart`,
  `lib/dev/zyra_dashboard_lab_controls.dart`,
  `lib/dev/zyra_dev_scenario.dart`,
  `lib/dev/zyra_dashboard_dev_adapter.dart`, plus their tests and the 12
  directly affected visual variants.
- Touch ONLY if Phase 1 proves it necessary:
  `lib/screens/home/home_shell.dart`, `lib/dev/zyra_page_preview_screen.dart`,
  `lib/dev/dev_scenario_panel_v2.dart`,
  `lib/widgets/zyra_dashboard_experience.dart`.
- Untouched: `lib/models/zyra_dashboard_resolution.dart`,
  `lib/services/zyra_dashboard_adapter.dart` (confirm in audit), resolver
  priority logic and every DR-ZYRA-216 gate, `zyra_session_router.dart`
  landing behaviour, the notifications manager, FAMILY components, the
  entire Guardian Dashboard, auth/IDV, and the database (Workstream A needs
  no schema change).

**A5 — Empty-state law.** TODAY always preserves its truthful baseline —
header, Right Now, Journey/Search and Family (ALW modules) — it is never
"empty". Honest-empty applies to UPDATES and INSIGHTS; both empty states
already exist in code — audit their copy against the master document's
three-register vocabulary and inventory rules.

**A6 — Visual scope.** Three production Seeker Dashboard fixtures × four
variants = **12 directly affected variants**. The Dashboard Lab matrix uses
a separate renderer and stays out of scope unless deliberately brought in
(state it explicitly if so). Report exact counts in Phase 1.

## 3 · Workstream B — Insights V1 (confirmed unbuilt)

Per master doc §4/§8: `insight_facts` + `insight_feedback` in the
Phase-A-style private schema (RLS; zero anon/authenticated grants;
server-authoritative writes per DR-ZYRA-219 wording), governed template
renderer, "Why am I seeing this?" answered mechanically from structured
provenance, controls (Helpful / Not helpful / Hide primary; mute-family
second-level), Discovery Health as SOLE candidate family. No rollup store,
no event tables, no LLM; LEVEL 0 display-only; `insight_feedback`
quarantined from recommendations. If Discovery Health fails validation:
build NO insight stores — the existing Insights tab stays honest-empty and
Workstream A still completes.

## 4 · Phase 1 deliverables (numbered CODEX-FABLE report)

**4.1 Workstream A:** A1 provenance · A2 drift ledger · A3 resolution (or
challenge) · A4 exact inventory · A5 empty-state audit · A6 exact visual
counts · revert procedure (see §7).

**4.2 Discovery Health validation (all master-doc §4 gates):**
- Server-side eligibility definition — one-way (profiles meeting the
  Seeker's criteria), criteria set enumerated, verified-only pool once
  DR-ZYRA-221 enforcement is live, copy never implying mutuality; no
  narrowing attribution; never a location-narrowing claim.
- **Differencing proof.** The rendered aggregate must never work as a
  one-person change detector — and crossing a floor or bucket boundary is
  itself a one-person disclosure. Prove stability at every floor and bucket
  boundary, and cover: fixed-epoch batch recomputation; hysteresis /
  hold-back or suppression at boundaries; block, deletion/deactivation and
  verification-state transitions; behaviour at tiny pools (~150 real users
  today, so "Fewer than 5" behaviour matters on day one). **Exact counts
  remain prohibited unless Phase 1 quantitatively proves them safe.**
- Query design + measured cost; material-change batch definition (never per
  profile action, never per open).
- D3 boundary restated in your design: full-criteria execution inside the
  server-authoritative query path only; persisted fact = aggregate result +
  non-sensitive operational provenance ONLY; no sensitive attributes,
  filter values or per-person eligibility records in insight stores.

**4.3 Updates projection audit + hardened RPC contract.** Enumerate which
authoritative timestamped sources exist today; propose the allowlisted
class list and one bounded RPC. The RPC contract is fixed: derive the user
exclusively from `auth.uid()` — never accept a caller-supplied user ID;
deterministic keyset pagination on `(occurred_at, class_key, source_id)`;
allowlisted event classes with ownership checks; if `SECURITY DEFINER`,
empty `search_path` and fully qualified objects; revoke execution from
`PUBLIC` and `anon`, grant only the required authenticated entrypoint;
private tables stay inaccessible to both `anon` and `authenticated`.
Absent sources = absent classes; nothing synthesized; no new store; zero
write amplification.

**4.4 Physical schema proposal.** DDL for `insight_facts` +
`insight_feedback` against the master-doc §8 logical contract (columns vs
validated JSON, indexes, constraints — justify), write-path RPCs under the
same hardening rules as 4.3, RLS/grants posture, staged migration plan.
**Migrations staged only — never applied without an explicit Founder GO.**

## 5 · Phase 2 (only after Fable verifies Phase 1 + Founder GO)

Implement the A2/A3 corrections; build Workstream B only if 4.2 passed;
stage migrations for the Founder's apply decision; regenerate affected
visual baselines through the gate without self-approval.

## 6 · Tests (contract-required, in addition to your own)

Full existing suite green; per-tab rendering + suppression tests for every
inventory V3 §3 module; TODAY-baseline preservation test (header/Right
Now/Journey-or-Search/Family always render); honest-empty tests for UPDATES
and INSIGHTS; RECENT MOVEMENT exclusivity test (Updates only) replacing the
current duplicate expectation; projection allowlist tests (unapproved class
cannot render; caller cannot select another user); RLS tests (client cannot
write `insight_facts`; feedback only via governed RPC; anon/authenticated
have zero grants on the private schema); Discovery Health definition unit
tests, floor/bucket boundary-crossing tests (single profile appears /
disappears / blocks / deletes / verifies → rendered value stable),
fixed-epoch batching tests; write-ceiling instrumentation (≤1–1.25
insight-system writes/active user/day, measured and reported).

## 7 · Release safeguards

Per-family config kill-switch (suppression, not deletion); Insights
honest-empty always valid. **Founder acceptance & revert:** no compile-time
or remote "instant fallback" flag is claimed — per your review, a local
build flag cannot alter an installed build, and a remote flag would require
new infrastructure and authority. Instead: (a) a session-only presentation
selector in the existing developer panel so Founder device acceptance can
compare three-tab against the six-level renderer live; (b) a documented
patch-and-rebuild production revert path (exact files/commits to revert) in
the Phase 1 report. Discovery Health cannot enable in production until:
Fable verification passed + privacy policy/DPIA insights sections signed +
explicit Founder enablement GO. No git; no self-approval; evidence + hashes
per the handover standard.

## 8 · Risk register (recorded)

(a) The three-tab build reached production code without a register trail —
A1 closes that gap; governance risk, not code risk. (b) A2 may surface
further deviations — the drift ledger keeps them explicit and individually
gated. (c) Visual churn bounded: 12 directly affected variants, Lab matrix
untouched. (d) Resolver/adapter untouched → logic risk low. (e) Navigation
habit change judged at Founder device acceptance with the §7 dev-panel
comparison.

## 9 · Response format

Numbered CODEX-FABLE message: Phase 1 deliverables 4.1–4.4, challenges (if
any), exact change-surface confirmation, no construction. Fable verifies;
the Founder gates Phase 2.

— Fable, 2026-08-30
