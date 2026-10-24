# ZYRA Insights System — Source of Truth

**Version:** V1
**Status:** CURRENT_VERSION — RATIFIED (DR-ZYRA-222, Founder rulings D1–D6, 2026-08-30)
**Date:** 2026-08-30
**Author:** Fable (from the Joint Fable × ChatGPT Dashboard Insights Position V1, co-signed 2026-08-30)
**Authority:** Founder rulings 2026-08-30 (chat) · DR-ZYRA-222 · AD-AIOS-106
**Programme:** OA-ZYRA-281
**Related:** DR-ZYRA-216 (resolver) · DR-ZYRA-217 (superseded in part — see §3) · DR-ZYRA-219 (server authority) · DR-ZYRA-220 (in-house compliance) · DR-ZYRA-221 (IDV mandatory) · OA-ZYRA-259 (honest-empty) · ZYRA_DASHBOARD_MODULE_INVENTORY_CURRENT_VERSION_V3.md (module contract) · ZYRA_LEARNING_LOOP_CURRENT_VERSION_V1.md (draft, reconciliation pending §15)

> **Compliance-wording standard (binding for this document set):** sensitive
> processing described here is **Founder-approved / risk-accepted under
> current governance** (DR-ZYRA-220 in-house path). It is never described as
> "legally proven safe". Engineering assumptions never fill legal gaps.

---

## 1 · What this document is

The single source of truth for the ZYRA Insights system: vocabulary, scope,
data architecture, privacy rules, boundaries and the V1 build contract. It
was produced by a structured Fable × ChatGPT debate (four rounds,
2026-08-30), co-signed by both, then ratified by the Founder as decisions
D1–D6 (DR-ZYRA-222 records the rulings, including the full verbatim D3 risk
acceptance). Presentation/content contracts for the Dashboard live in the
module inventory (V3); this document owns intelligence.

## 2 · Ratification record (D1–D6, 2026-08-30)

| # | Ruling | Outcome |
|---|---|---|
| D1 | Presentation | **B — supersede DR-ZYRA-217 presentation** with three-tab Dashboard: **Today · Updates · Insights**. Presentation/routing only; resolver, state authorities, update projection and insights architecture preserved. |
| D2 | V1 insight scope | **APPROVED** — validation before construction; Discovery Health sole candidate; honest-empty valid; no state cards as Insights; no speculative infrastructure. |
| D3 | Sensitive derivation | **APPROVED including formal Founder risk acceptance** — single Discovery Health exception; precedent lock absolute; strict fallback pre-agreed. Full wording: §6. |
| D4 | Authority | **APPROVED** — LEVEL 0 display-only; feedback quarantined from recommendations. |
| D5 | Data model | **APPROVED** — `insight_facts` + `insight_feedback` only; no event tables/behavioural logs/event sourcing/unused rollups; retention evidence-derived. |
| D6 | Guardian | **APPROVED** — zero Guardian insight families in V1; **process, never behaviour** is permanent. |

Resolved-disagreements log (recorded so future readers know where the debate
fought): (1) the three-tab claim was corrected from "converged" to "design
direction under discussion" and became D1; (2) V1 rollup infrastructure was
withdrawn under the infrastructure-follows-families rule; (3) status facts
were withdrawn from Insights (state ≠ insight); (4) Discovery Health vs
Article 9 resolved as the §6 exception — hardened storage language and the
differencing invariant came from ChatGPT's final review.

## 3 · Definitions and presentation

**State** = where things stand. **Changes** = what happened. **Insights** =
derived understanding computed from evidence. State is never rendered as
insight; the three source-of-truth classes are independent of presentation.

**Presentation (D1):** the Seeker Dashboard is three tabs — **TODAY**
(state: header, Right Now, Journey/Search, My ZYRA, Family, onboarding gate),
**UPDATES** (changes: the one capped, unread-backed recency stream +
milestones), **INSIGHTS** (derived understanding only). Mapping from the
superseded six-level Home and every surviving DR-ZYRA-217 content rule are
recorded in DR-ZYRA-222 Decision 2 and the module inventory V3. **Guardian presentation — RESOLVED (DR-ZYRA-223 item 1, 2026-08-30):** the
three-tab presentation applies to BOTH roles; the crossed instruction resolved
in favour of the Founder's direct design instruction. D6 is NOT reopened: zero
Guardian insight families in V1, no Seeker behavioural intelligence exposed to
Guardians, PROCESS NEVER BEHAVIOUR permanent. Guardian Insights renders
honestly empty — no filler because the tab exists. The Guardian
shared-resolver migration remains separately sequenced future work (inventory
G12).
The DR-ZYRA-216 resolver remains the single content-priority authority; the
insight system extends it and never builds a parallel brain.

**Insights tab truth:** it renders only genuine derived understanding. It
never renders profile completeness, verification state, journey position or
any other status fact — those live on TODAY. An honestly empty Insights tab
is a valid, intended launch state. Filler is prohibited.

## 4 · V1 scope (D2)

**Build (conditional):** resolver extension · `insight_facts` +
`insight_feedback` stores · governed template renderer · explainability
("Why am I seeing this?" answered mechanically from structured provenance) ·
user controls (§10). **Build order: validation precedes construction** —
Codex must validate Discovery Health (definition + query cost) in its design
phase BEFORE any insight store is built; if validation fails, nothing
speculative is built and the matter returns to the Founder.

**Sole V1 candidate family: DISCOVERY HEALTH** — an honest, server-computed
eligible-pool count (e.g. "14 active, verified profiles meet your core
requirements"). Validation gates (all must pass):

1. Ruled server-side definition of "eligible"; **one-way** directionality
   (profiles meeting the Seeker's criteria); copy never implies mutuality.
2. Verified-only pool once DR-ZYRA-221 enforcement is live.
3. Full-criteria computation under the §6 exception only.
4. Low-count bucketing ("Fewer than 5"), no artificial precision.
5. **Differencing invariant:** the displayed aggregate must never become a
   practical mechanism for inferring that one identifiable profile appeared,
   disappeared, blocked, was blocked, verified or changed eligibility.
   Codex's validation must explicitly cover: bucketing, minimum display
   floor, recomputation cadence, safety of exact counts above the floor,
   suppression of individual-delta explanations, block-exclusion behaviour,
   deletion/deactivation, verification-state changes. Discovery Health is an
   aggregate orientation signal, never a one-person change detector.
6. Blocked-pair exclusion that can never function as a block detector.
7. Material-change batch recompute; never per profile action; never per open.
8. Query cost validated at design time against realistic distribution.
9. Carried forward from DR-ZYRA-217 item 6, still binding: **no narrowing
   attribution; never a location-narrowing claim.**

**Validation outcome — 2026-08-30 (Codex 033, Fable-verified 034):
FAILED/DEFERRED.** Two grounds: (a) no real verified onboarding-complete
population exists on the live project (149/150 test-domain accounts, 0
onboarding-complete, 0 verified — the eligible pool is zero for every
viewer); (b) the absolute differencing invariant cannot be proved by any
deterministic count/bucket output — every output with more than one visible
value has a boundary where one person's change flips it; fixed epochs and
hysteresis move the boundary, they do not remove it. The ruled fallback is
operating: no insight stores, no migration, no production insight card;
Insights renders honest-empty. Return path requires BOTH a real verified
population AND a new Founder ruling on a materially different mechanism
(e.g. formally calibrated noise, a governed cohort-release design with a
quantified threat model, or a non-count family) — not authorised by D2/D3.
**Founder acceptance (DR-ZYRA-223 item 5):** result accepted; the invariant
is not weakened to ship the feature; nothing insight-store-shaped is built
under the fallback; calibrated noise or another privacy-preserving approach
may be considered later but is NOT authorised now.

**Zero in V1:** LLM calls · Article 9 derivation beyond §6 · ranking or
matching impact · plan differences · Guardian families · generic event
tables · daily rollups · event sourcing · state cards in Insights · filler.

**Candidate family #2 (parked, not approved):** own-activity observation —
arrives, if ever, with the rollup infrastructure and its own ruling.

## 5 · Evidence, confidence, causation

Internal evidence classes (provenance/authority): **FACT · OBSERVATION ·
CORRELATION · INFERENCE · SUGGESTION · USER-CONFIRMED.** User-facing copy
collapses to three registers: **"What we know"** (FACT) · **"What we've
noticed"** (OBSERVATION / ESTABLISHED CORRELATION) · **"Worth considering"**
(SUGGESTION). Internal class names never appear in UI. USER-CONFIRMED is a
backend state via feedback, not a badge.

Confidence: FACTs carry freshness/source/calculation validity — no
confidence theatre. Correlation-class content requires ESTABLISHED
confidence and specific approval. **EMERGING renders nothing in V1.
INFERENCE renders nothing in V1.** Below threshold, a card does not render —
honest-empty, never hedged filler (OA-ZYRA-259 continuity).

**Causation invariant (permanent):** no ZYRA insight may attribute the cause
of a user, counterpart, Guardian or Journey outcome unless that causal fact
was explicitly and lawfully recorded for that purpose AND its derived
display is separately permitted. Collection authority ≠ display authority.
Correlation copy never implies causation.

## 6 · Sensitive derivation (D3) — full ruled wording

Insights V1 performs **no behavioural, correlational, explanatory or
inferential derivation from Article 9 data.**

**The single exception — Discovery Health.** Founder ruling 2026-08-30,
verbatim:

> I approve the narrowly scoped Discovery Health sensitive-data processing
> exception under the current in-house governance path. This approval is
> limited exactly to the jointly agreed exception:
> - the user's own existing search criteria may be executed in full;
> - output is only the approved aggregate orientation signal;
> - no sensitive-axis breakdown;
> - no religious/practice profiling;
> - no behavioural, correlational, explanatory or inferential Article 9
>   intelligence;
> - no raw or axis-specific sensitive attributes stored in Insight stores;
> - the resulting aggregate remains governed as the product of the
>   authorised sensitive-data processing;
> - it must never operate as a one-person change detector;
> - privacy policy and DPIA must document the processing and this
>   residual-risk acceptance;
> - the precedent lock is absolute.
>
> This approval does NOT authorise another Insight family to use sensitive
> inputs. Any additional family touching Article 9 inputs must return
> through the agreed consent/privacy/DPIA/Founder/DR process.

**Storage language (precise, jointly agreed):** no raw or axis-specific
Article 9 attributes, user filter values, counterpart attributes,
sensitive-category breakdowns, or per-person eligibility records are
persisted in the insight stores. The persisted Discovery Health fact
contains only the approved aggregate result and its non-sensitive
operational provenance. The aggregate remains governed as a result produced
using the narrowly authorised Article 9 processing described here — it is
not redefined as non-sensitive merely because it is a count.

**Precedent lock:** this exception is exhaustive and authorises exactly one
family. It may never be cited as precedent — including for "just another
count".

**Strict fallback (pre-agreed):** if the risk acceptance is withdrawn, no
Article 9 inputs enter Insights at all; the partial-criteria Discovery
Health variant is prohibited as misleading; the family does not ship;
Insights renders honest-empty; no speculative stores are built.

**Scope note:** Article 9 data may appear elsewhere in the product under its
existing governance (profile display, search, compatibility features).
This section governs derivation of new intelligence inside Insights only.

## 7 · Authority (D4)

Insights V1 operates at **LEVEL 0 — display-only**. No insight, confidence
value or feedback signal may affect matching, ranking, candidate
eligibility, profile visibility, preferences, Journey questions or Guardian
disclosure. `insight_feedback` is quarantined from recommendation and
learning systems. The LEVEL 0–4 authority ladder is documented as future
architecture only; any LEVEL 1+ move requires a new DR with its own
consent/privacy review, tests and Founder ratification.

## 8 · Data architecture (D5)

**Stores (V1):**

- **`insight_facts`** — current derived truth. Logical fields: user_id,
  family_key, rule_version, classification (internal evidence class),
  structured payload, evidence_window_start/end, evidence_count (where
  meaningful), provenance/source family, computed_at, valid_until (where
  relevant), state, confidence tier (where applicable), suppressed_reason,
  superseded_by. The structured payload is the source of truth; user-facing
  prose is rendered from governed templates and never stored as truth.
- **`insight_feedback`** — user actions on insights (helpful / not helpful /
  hide / mute-family), timestamped, sparse, user-triggered only.

**Deferred:** `insight_daily_rollups` — introduced only with the first
separately approved family that genuinely requires bounded historical
aggregation; arrives carrying its metric allowlist (allowlisted, bounded,
schema-versioned; a new metric is a governed change) and window-derived
retention. **Prohibited:** generic event tables, behavioural logs, full
event sourcing, arbitrary event bags.

**Physical schema:** this document fixes the logical contract; the physical
PostgreSQL representation (columns vs validated JSON, indexes, partitioning)
is a Codex design proposal, following the Phase A private-schema pattern
(private schema, RLS, no anon/authenticated grants, server-authoritative
writes — DR-ZYRA-219 wording applies).

**Updates projection:** UPDATES is a curated read projection over existing
authoritative timestamped domain records (one bounded server-side RPC,
UNION of allowlisted event classes; cursor+limit). A class exists only where
an authoritative timestamped source already exists — absent sources mean
absent classes, honest-empty, never synthesized or backfilled. No new event
store; zero additional write amplification. The V1 class list starts from
what RECENTLY renders today and is enumerated by Codex at design time.

**Lifecycle:** persisted states — active · superseded · expired · dismissed
· suppressed. Candidates exist transiently in computation memory only.
Transitions are auditable on the fact row (superseded_by, suppressed_reason).

**Retention:** bounded to the maximum evidence window required by ACTIVE
insight families plus a defined recomputation/audit margin. Facts: while
active plus a bounded superseded tail. Feedback: account lifetime. No
indefinite behavioural history. The concrete number is set when the
shipped-family registry is non-empty.

**Erasure and blocking:** account deletion removes personal rows from all
insight stores; only demonstrated-anonymous aggregates above the governance
threshold survive ("anonymous" is demonstrated, never asserted). Blocked
pairs are excluded from each other's computations without the exclusion
being detectable.

**Write ceiling:** ≤1–1.25 insight-system writes per active user per day on
average. Fact writes only on: first eligibility, material value change,
confidence-tier change affecting eligibility/state, expiry/supersession —
never on a no-change recompute. Measured during implementation verification.

**Refresh:** nightly for future rollup families; material-change controlled
batch for cheap current-state aggregates (Discovery Health); never per-open;
real-time belongs to TODAY (state), not Insights.

**Performance/failure:** first paint never depends on insight computation or
any AI/network call — Insights reads the last valid precomputed fact set in
one indexed query. On failure: Insights absent; TODAY and UPDATES remain
functional; no spinner waiting for intelligence; stale is never presented as
fresh. Ruled UI law (DR-ZYRA-223 item 2): EMPTY — the query succeeded and
there is genuinely nothing — is never conflated with FAILED — the source or
query failed and the app cannot truthfully determine. No silent
empty-on-error, in any tab, for either role. Dev fixtures flow through the REAL resolver (established practice).

## 9 · Cost model and LLM boundary

**V1: zero paid model calls.** All computation deterministic; all copy from
governed templates. Unit assumptions (product invariants, not provider
quotes): ≤1 rollup-write/user/day when rollups exist; ≤1 indexed insight
query per Dashboard load; 0 LLM calls; fact writes on material change only;
sparse feedback. Insight cost scales with bounded database storage/compute,
not generative AI. AIOS Finance computes real provider cost from live
pricing when needed. Guardrails: per-family config kill-switch; any paid API
entering the path becomes a named finance-ledger line; no per-open paid
calls, ever.

**Future LLM (if ever):** phrases pre-computed structured results only.
Never computes, scores, ranks, decides eligibility or assigns confidence;
receives no more personal history than phrasing requires; output cached per
(user, family, state-hash), regenerated on state change only. Templates may
make LLM unnecessary entirely — no LLM dependency is built in anticipation.

## 10 · User controls

Primary on every card: **Helpful · Not helpful · Hide · "Why am I seeing
this?"** (mechanical disclosure: family, payload, window, rule version).
Second-level (behind "…"): **"Don't show insights like this"** (mute
family). Dismiss-fact and mute-family stay distinct internally. Muted
families stay muted — no resurrection prompts. All actions write to
`insight_feedback` (quarantined per §7).

## 11 · Guardian boundary (D6)

Zero Guardian insight families in V1. **Permanent principle: Guardian
intelligence = PROCESS, NEVER BEHAVIOUR.** The Guardian may see states of
processes they are party to, pending actions, ruled safety flags, their own
activity. The Guardian never sees Seeker browsing patterns, activity times,
message frequency/content beyond ruled visibility, comparative desirability,
or verification detail beyond coarse state. Guardian current-state facts may
improve the Guardian Dashboard, but they are not "intelligence". Guardian
insights get their own governed design round after the Guardian presentation
is settled (its browse-activity question remains HELD under DR-ZYRA-217
item 7 pending the dedicated privacy review).

## 12 · Permanent NO-list

No success scores · no rejection counts · no desirability/popularity metrics
· no compatibility "risk score" · no marriage-success or divorce/failure
probability · no "people like you typically…" · no inferred religiosity
judgement · no ranking users by family quality · no Guardian score · no
Seeker obedience/cooperation score · no response-speed score · no "market
value" · no streaks, badges or points · no hidden preference rewriting · no
insight designed primarily to create upgrade anxiety · no "your results
could improve by X% if you upgrade" · no generated causal explanation
without explicit recorded evidence · no dark-pattern preference pressure ·
no Guardian behavioural surveillance · no full event sourcing · no demo or
fabricated production insight, ever.

## 13 · Plans (recorded principle, no V1 gating)

V1 ships identical insights on every plan (no Seeker entitlement read
exists; nothing is technically gateable). **FUTURE ENTITLEMENT PRINCIPLE —
PENDING RATIFICATION:** Basic = a complete honest home; One = deeper
understanding — depth (longer windows, trends, richer breakdowns), never
artificial card counts, and safety-class/factual content never paywalled
(precedent: verification free on every plan, DR-ZYRA-221). Future gating
requires the entitlement read plus its own DR.

## 14 · Documentation rules

This file is the single master. Split a family into its own CURRENT_VERSION
only if: it introduces its own significant processing purpose; or requires
independent consent; or carries substantial dedicated technical/privacy
rules; or the master becomes operationally difficult to consume. Never split
merely for length. Dashboard presentation/content remains governed by the
module inventory (V3) — no duplication. Changes to this document follow
AD-AIOS-106 (Founder ratification; register trace; no silent supersession).

## 15 · Pending items (recorded, no decision requested)

1. **Learning Loop V1 draft** — reconcile with §7's quarantine during
   implementation documentation; returns to the Founder only if a real
   conflict survives.
2. **Candidate family #2** (own-activity observation) — parked with rollup
   infrastructure.
3. **Privacy policy + DPIA insights sections** — Fable to draft the §6
   processing description and risk-acceptance record into
   ZYRA_PRIVACY_POLICY_IDV_SECTIONS / ZYRA_IDV_DPIA successors before
   enablement (OA-ZYRA-281 gate).
4. **Entitlement principle ratification** — when the entitlement read
   exists (§13).

## 16 · Execution state

2026-08-30: DR-ZYRA-222 filed; OA-ZYRA-281 opened; module inventory V3
issued (V2 archived); navigation source updated; Codex implementation
contract drafted and delivered to the Founder for review — **not sent to
Codex**. Same day, Codex pre-review (Fable disk-verified): the three-tab
renderer is already live in production code (built 2026-08-30, unrecorded —
authority to be stated in Phase 1); Insights stores/Discovery Health/
Updates RPC remain unbuilt; Workstream A recast as audit + correction +
verification; contract corrected per the eight review points and filed as
032. Codex Phase 1 (033) received and Fable-verified PASSED (034):
Founder-direct provenance recorded; drift ledger accepted; Discovery Health
FAILED/DEFERRED (§4 — honest-empty stands). Founder ruled all four questions
2026-08-30 → DR-ZYRA-223: Guardian three-tab confirmed both roles (D6
untouched); Updates projection authorised (empty≠failed ruled; migration
staged only); Phase 2 GO; calm advisory removed. Codex released via 035;
Phase 2 completed (036) and Fable-verified PASSED (037) — corrections live
in source, Updates projection staged only, one provenance question open to
Codex. SUBSEQUENT EXECUTION, all 2026-08-30: Founder apply GO given after
ChatGPT's clean second pass; migration applied byte-identical and post-apply
verified (ten-point matrix, all pass); client wiring completed by Codex and
Fable-verified (045/046) — both roles on the single live projection with the
last-known law implemented; FOUNDER ACCEPTED both Dashboards on device.
Remaining: baseline promotion confirmation, then OA-ZYRA-281 closes.
Insights remains honestly empty pending any future Founder ruling.

---

*V1 · 2026-08-30 · Fable. Produced from the co-signed Joint Fable × ChatGPT
position; ratified as DR-ZYRA-222. Nothing in this document is
implementation authority by itself — the Codex contract and its Founder
approval govern the build.*
