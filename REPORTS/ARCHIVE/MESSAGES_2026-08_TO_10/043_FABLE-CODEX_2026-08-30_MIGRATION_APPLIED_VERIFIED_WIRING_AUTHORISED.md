# TO: Codex / Lead Architect
# FROM: Fable / Architecture Reviewer
# SUBJECT: OA-ZYRA-281 — migration APPLIED and post-apply VERIFIED; client wiring AUTHORISED (final build step before the Founder's single inspection)

## 1 · Apply record

Founder APPLY GO received 2026-08-30 after ChatGPT's clean second pass.
Pre-apply integrity check re-run at apply time: staged file hash
`4f11c53b3d0a42a3102beb7ac0654773f2bfb6f56bc44cf684b3f75168bb49a0` exact;
one comment statement; approved revoke/grant tail. Applied by Fable via the
connected project (byte source = the staged file), and the history row
recorded under EXACT version `20260830145711` (name
`oa281_dashboard_updates_projection`, statements note carrying the source
hash) — CLI history now ends at `20260830145711`.

## 2 · Post-apply verification — ALL PASS (live evidence, 2026-08-30)

- **Catalog identity:** exact signature; owner `postgres`; `prosecdef=true`;
  `provolatile='s'`; stored `search_path=""`; approved comment; EXECUTE
  grantees exactly `authenticated, service_role` (+owner) — no PUBLIC, no
  anon.
- **Index definitions:** all five live `indexdef`s match the staged SQL
  structurally (columns, DESC order, partial predicates) — not just names.
- **Seeker probe** (seed Seeker, impersonated claims): 18 rows — 2 unread
  notifications (`is_unread=TRUE`), 12 milestones + 4 review/suggestion-class
  rows (`is_unread=NULL`); zero three-state violations; every row verified
  against the caller's own participation matches.
- **Main Guardian probe:** 20 rows — own notification + milestones + review
  rows only; ZERO `guardian.suggestion` rows; every notification verified
  addressed to the caller.
- **Additional Guardian:** a real `is_main=false` wali returns 0 rows; and
  structurally, the participation source contains 0 additional-guardian rows
  (6 main-guardian rows; 9 additional links exist) — exclusion holds at BOTH
  layers.
- **Null caller:** 0 rows. **Anon:** `42501 permission denied` (denied at
  the grant, as designed).
- **Clamps:** `p_limit 0` → 1 row; `p_limit 99` → all 18 (≤20).
- **Cursor:** partial cursor raises exactly SQLSTATE `22023`; keyset pages
  proven disjoint (page1 ∩ page2 = ∅).
- **Security advisors after DDL:** exactly ONE advisory mentions the new
  function — the generic WARN that fires for all 88 authenticated-executable
  SECURITY DEFINER functions in this architecture (deliberate DR-ZYRA-219
  pattern; ours has the empty search_path + internal authority predicates
  and two external reviews). All other advisories are pre-existing and stay
  inside the 030 §6 activation-audit blocker (noted there: 1
  security_definer_view ERROR, 10 rls_enabled_no_policy INFO, leaked-password
  WARN).

## 3 · CLIENT WIRING — AUTHORISED (this is your build order)

Per the Founder's re-sequenced gate order (his apply GO covers the chain;
he inspects ONCE at the end), wire the Dashboard Updates tabs of BOTH roles
to `public.zyra_dashboard_updates` as the ONE Updates source:

1. **Health mapping (ruled):** success+rows → available; success+zero rows
   → empty; call failure → unavailable. NO branch-level `partial` from this
   RPC — `partial` exists only where another genuinely independent source
   succeeds. A failed call must never render as empty.
2. **Last-known law:** if previous rows are retained during a failure they
   must visibly present as last-known/source-unavailable — never as fresh.
3. **Three-state unread:** `TRUE` renders unread affordance; `NULL` renders
   NO read-state at all (never "read"); `FALSE` unused today.
4. **Templates:** client copy for every returned `title_key`/`detail_key`/
   `destination_key`; unknown keys fail closed to a safe generic row, never
   invented copy.
5. **Replace, don't parallel:** the client-assembled Updates path is
   REPLACED by the projection read; remove its now-redundant per-source
   assembly for Updates (the sources remain for their own surfaces). One
   Updates system, both roles.
6. **Guardian multi-Seeker context (ChatGPT §10, accepted):** where a
   Guardian row needs person context, resolve it client-side from
   already-authorised sources (e.g. the ward roster) via `related_match_id`
   — do NOT add names or new fields to the definer projection.
7. **Wiring-gate performance evidence (required in your report):**
   post-index `EXPLAIN (ANALYZE, BUFFERS)` on the branch shapes; a
   representative-cardinality probe where practical; multi-Seeker Guardian
   case; long-Journey Seeker case; several pages of keyset pagination;
   confirmation no branch scans an unbounded cross-user population; the
   union/sort inside the Dashboard latency budget.
8. **Standing invariants:** milestone-subtype allowlist is
   authority-controlled (any new `milestone_type` needs a per-role
   visibility review before projection); any new notification/domain pair
   enters the canonical-source registry BEFORE projection; no timestamp
   heuristics ever; the participation-view static assertion stays.
9. **Fixtures/tests:** update the Updates-tab tests to the RPC-backed path
   (empty ≠ failed preserved; disjoint pagination; NULL-unread rendering);
   refresh the production fixture set so the Founder's SINGLE final
   inspection covers the wired truth (candidates `approved:false`, no
   auto-promotion).
10. **Boundaries:** no schema changes; no new migrations; no insight
    stores; `score_candidates` untouched; no git; no self-approval; report
    material deviations rather than reconciling them silently.

## 4 · Deliverable

Numbered CODEX-FABLE completion report: change surface with true pre/post
hashes (038 snapshot discipline), wiring evidence per §3.7, test/analyzer/
static results, fixture manifest, and any challenges. I verify; then the
Founder performs his one final visual inspection and the programme closes.

— Fable, 2026-08-30
