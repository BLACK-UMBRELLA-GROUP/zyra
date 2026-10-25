# TO: Codex / Lead Architect
# FROM: Fable / Architecture Reviewer
# SUBJECT: OA-ZYRA-281 — PHASE 2 GO (DR-ZYRA-223): bounded correction patch + authorised Updates projection

## 1 · Founder rulings (DR-ZYRA-223, filed today — read it in DECISIONS_V1.md)

1. **Guardian three-tab CONFIRMED** for both roles — your C1 resolves in
   favour of the Founder's direct instruction; the records are amended. D6 is
   explicitly NOT reopened: zero Guardian insight families in V1; no Seeker
   behavioural intelligence to Guardians; PROCESS, NEVER BEHAVIOUR; Guardian
   Insights stays honestly empty — no filler because the tab exists.
2. **Updates projection AUTHORISED** (your C3 → independent conformance work).
3. **Phase 2 GO** for the accepted correction patch (your §9.3 surface).
4. **Calm advisory REMOVED** (S4 option (a)).
   Plus: Discovery Health FAILED/DEFERRED is accepted — the invariant is not
   weakened; nothing insight-store-shaped is built (your C5 fallback stands).
   Scope discipline: `score_candidates` stays inside the 030 §6 audit blocker
   unless this patch genuinely needs that function — flag first if so.

## 2 · Scope A — Seeker correction patch (as accepted in 034 §3)

1. Remove `dashboard-section-today-movement` and the Today preview; replace
   the duplicate test expectation with an exclusivity assertion (movement
   exists under Updates and never under Today).
2. Labels: `AT A GLANCE` → `MY ZYRA`; section heading `GUARDIAN` → `FAMILY`
   (Guardian stays the content identity).
3. Per-tab truthful state: UPDATES and INSIGHTS must distinguish EMPTY
   (successful query, genuinely nothing) from FAILED (source/query failed) —
   ruled UI law, no silent empty-on-error. The smallest typed extension to
   `zyra_dashboard_resolution.dart` / `zyra_dashboard_adapter.dart` is
   authorised for this (your C2, accepted in 034).
4. S4: remove the production "Review your preferences" calm advisory. Calm
   state renders the approved equivalent of "Nothing needs your attention
   right now." — no behavioural suggestion, no preference implication, no
   upgrade/engagement filler. (Dev/Lab mock advisories may remain dev-only
   and honestly labelled.)
5. S20 empty copy: eyebrow `INSIGHTS`, title `No insights available yet`,
   detail `ZYRA will only show an insight when real, governed evidence
   supports it.` (your §4.2 wording).
6. Fixtures/tests: the accepted A3 pixel change (2×4 existing images) plus
   your proposed three new production fixture states — Updates populated,
   Updates honest-empty, Insights honest-empty — toward the 24-variant
   production matrix. Lab matrix untouched. Tests per 032 §6 as amended by
   033/034, including the TODAY-baseline preservation test.

## 3 · Scope B — Updates projection (one system, both roles)

Implement per your §6.3 design EXACTLY: `stable security definer set
search_path = ''`, fully qualified objects; caller derived only from
`(select auth.uid())`, null → no rows; limit clamped 1–20; per-branch
ownership predicates; controlled template/destination keys only (no raw
detail, no counterpart sensitive data); real `read_at is null` unread; keyset
order and next-page predicate on `(occurred_at, class_key, source_id)`; no
total count; no writes; `revoke ... from public, anon`, grant authenticated +
service_role. Class allowlist per your §6.2, including the milestone
dedup rule (never both the domain row and its mirror notification; fail
closed to the notification representation). **One Updates system serves both
roles** — the guardian.* branches serve a Guardian caller under the same
allowlist governance; never a second projection.

**Sequencing (staged-only rule):** the migration containing the RPC and
supporting indexes is STAGED, NOT APPLIED — apply requires a separate Founder
GO after my verification. Propose the client sequencing honestly in your
report: either (a) patch now keeps the client-assembled path but adds the
ruled empty≠failed distinction, with RPC wiring landing after the apply GO,
or (b) another arrangement you can defend — the fixed requirements are: no
broken interim state, and at no point does any tab silently claim empty on
error.

## 4 · Guardian same-law conformance (bounded)

Guardian's three-tab surface is now confirmed, so the SAME ruled laws apply
where the identical drift exists there: empty≠failed on Guardian Updates and
Insights; honest-empty copy; no filler. List every Guardian-side change in
your report. Anything beyond same-law conformance is out of scope — flag it,
do not build it (Founder: the batch is not casually broadened). The Guardian
shared-resolver migration (G12) remains future work — do not start it.

## 5 · Boundaries (unchanged)

No insight stores, no Discovery Health work, no dormant tables created; no
git; no self-approval; migrations staged only; `score_candidates` untouched
unless genuinely required (flag first); challenge duty per AD-AIOS-106;
report material deviations rather than silently reconciling them.

## 6 · Deliverable

Numbered CODEX-FABLE completion report: change surface with pre/post hashes,
forward/reverse patch evidence (your §4.4 procedure), staged migration file
(not applied), Guardian delta list, fixture manifest and counts, full test
results, analyzer/static results, and any challenges. I verify independently
on return; the Founder then gives device acceptance and the migration apply
GO.

— Fable, 2026-08-30
