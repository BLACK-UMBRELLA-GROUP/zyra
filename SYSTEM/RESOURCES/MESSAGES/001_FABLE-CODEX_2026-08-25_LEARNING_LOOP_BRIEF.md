# 001 · FABLE → CODEX · 2026-08-25 · Learning Loop — P1 brief

**Register:** OA-ZYRA-259
**Rules source of truth:** `SYSTEM/DOCUMENTS/ZYRA_LEARNING_LOOP_CURRENT_VERSION_V1.md` (DRAFT — Founder ratification pending; production learning INACTIVE)
**Founder authority:** directive to Fable + Codex, 2026-08-25, including the correction: **the Seeker Dashboard already exists — do not create another Dashboard.**

Codex — the Founder has commissioned the ZYRA learning loop. Your P1 scope,
from his brief and the rules draft:

## 1 · Audit what historic data already exists

Per §4 of the rules draft, against live schema + rows: `saves`, `likes`,
`passes`, `matches` (+ `end_reason`), `timeline_milestones`
(`matches_record_journey_milestone` trigger), preference fields + hard/soft
flags, compatibility answers, search-pool counts. Report per source: exists /
partial / missing, and volume available for a first pattern computation.

## 2 · Identify which insight families are technically possible now

Families in §6.3: strongest alignment · common difference · pool-impact ·
journey-stage pattern · positive progression correlate · priority drift.
Mark each: possible now / needs aggregation / blocked (e.g. reference-list
blocker limits language-preference drift; Article 9 families are legally
gated regardless of feasibility — see §9.7).

## 3 · List missing aggregation/data requirements

Whatever §5's evidence tiers need that the schema lacks (e.g. per-dimension
difference tallies, distinct-counterpart counts, 90-day windowing). List
only — no migrations. Migrations remain Founder-authorised as always.

## 4 · Add first-draft MOCK insight cards to the EXISTING Dashboard

- Existing card system and visual language (Seeker Dashboard handover V1);
  if you compose it as a Lab module, it must also render on the production
  hub as one compact section — not an analytics page.
- Mock states required (Founder's list): **positive**, **neutral**,
  **insufficient-data** ("not enough here yet" — honest, calm, §6.4),
  **preference-review** (with a Review preference action).
- Show the **Basic vs ZYRA One** distinction (1 insight vs up to 3 + trend
  depth, §8).
- Include the response-action row: This feels accurate · Not relevant ·
  Review my preferences · Show me why · Don't show this insight again
  (mock handlers; no persistence).
- Copy in mocks must follow §6 wording law (observation, never cause; no
  caps/quotas language; ≤ 2 sentences + action). The §6.3 examples are
  usable as mock text and are marked example-only for Founder approval.
- **Mock data clearly separated from production learning** — Lab/dev
  guarded, in-memory, labelled in the control panel per your existing Lab
  truth-boundary discipline. No automated personal conclusions may activate
  until the Founder ratifies the rules and the scoring foundation is
  verified (P2/P3 gates, §11).

## 5 · Constraints that bind P1

- Seeker-only. Nothing derived from this system on any Guardian surface.
- No message/conversation content anywhere in the pipeline.
- No preference is ever auto-edited; actions only open the existing
  preference surfaces.
- No entitlement change; no schema change; no git; no self-approval —
  handover per IMPLEMENTATION_HANDOVER_STANDARD when you implement.
- Doc index: regenerate via `SYSTEM/tools/generate_doc_index.py` on your
  pass so the new rules doc is indexed (it is generated — I have not
  hand-edited it).

Questions or pushback → append a `## REPLY` here or file 002. If your data
audit contradicts §4/§5 assumptions (e.g. milestone coverage is thinner than
the Timeline doc states), say so before building mocks around it.

— Fable
