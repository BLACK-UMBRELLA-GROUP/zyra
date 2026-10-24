# TO: Codex / Lead Architect
# FROM: Fable / Architecture Reviewer
# SUBJECT: OA-ZYRA-282 — F6 early security batch: "guardian server truth" micro-migration (STAGED ONLY). The only Guardian work authorised before OA-ZYRA-281 closes.

## 0 · Authority and scope

DR-ZYRA-224 (Founder rulings F1–F7, 2026-08-30) ratified the Guardian
Relationship Surfaces position and authorised THIS batch early, as its own
security gate. Read DR-ZYRA-224 and
`ZYRA_GUARDIAN_RELATIONSHIP_SURFACES_CURRENT_VERSION_V1.md` (§6/§8) from
disk. **Everything else Guardian-related is HELD** — no Flutter changes, no
page redesign, no Dashboard thinning, no design cleanup. This contract is
one staged migration + tests. Challenge duty applies (AD-AIOS-106).

## 1 · The verified defect (Fable live evidence, 2026-08-30)

`public.zyra_attempt_summary_for_guardian(p_seeker uuid)` — owner
`postgres`; SECURITY DEFINER; `SET search_path TO 'public'` (not empty);
**`authenticated` holds EXECUTE; `anon` does not**; predicate requires only
an ACTIVE `wali_links` relationship — `is_main` is never checked; no
attempt-status filter (potential attempts included). Zero app callers.
8 active Additional links exist; 0 of their Seekers currently have attempts
— the exposure is unexercised by data, not by control. Any Additional
Guardian could invoke it directly today and would receive attempt
existence/start/end/ended the moment their Seeker has attempts.

## 2 · The migration (exactly two changes; enforcement logic otherwise unchanged)

**Change A — tighten `zyra_attempt_summary_for_guardian` to Main-only,
aligned with the governed Main-Guardian boundary:**
- caller derived only from `(select auth.uid())`; null caller → no rows;
- require `wali_links` row: `seeker_id = p_seeker AND wali_id = caller AND
  status = 'active' AND is_main = true`;
- exclude potential attempts (align with the ruled participation boundary
  `attempt_status <> 'potential'` — Main Guardians' governed scope);
- returned fields: list and JUSTIFY each in your report (current:
  attempt_id, started_at, ended_at, ended). Trim anything the future
  workspace does not require; do not add anything;
- SECURITY DEFINER hardening while you are in the function: `set
  search_path = ''`, fully schema-qualified relations, no dynamic SQL, no
  writes, STABLE; revoke PUBLIC and anon EXECUTE explicitly (keep
  authenticated + service_role);
- no caller-supplied identity may substitute another Guardian (p_seeker
  selects the WARD, never the caller).

**Change B — correct the false final-Guardian-removal hint** in
`zyra_remove_guardian` (hint text ONLY; logic untouched). Current hint
falsely offers pausing. Corrected meaning (exact copy yours to word,
meaning fixed by the Founder): "An active or paused Journey requires you to
keep a Guardian. Assign another Guardian where possible, or end the Journey
through the governed flow before removing this one." Where other Guardians
exist, the separate main_guardian_must_be_reassigned path stays as is.

## 3 · Package requirements (Founder-mandated)

Staged file only — NEVER applied; apply is a separate Founder GO after my
verification AND a ChatGPT external security review. Your report must
include: exact pre-state definition + exact post-state definition (full
SQL both); byte-exact staged-file SHA-256; function owner / SECURITY
DEFINER status / stored search_path / execute ACL, pre and post; returned
fields with per-field justification; the exact Main predicate; the hint
diff; rollback/correction strategy (a reverse migration or documented
restore path); and static tests pinning: Main-only predicate,
potential-attempt exclusion, empty search_path, grants, no writes, and
that the hint no longer contains any pausing-permits-removal claim.

## 4 · Direct-call test matrix (post-apply verification will execute these live)

Design your staged tests so these twelve cases are provable:
unauthenticated caller; unrelated authenticated user; the Seeker
themselves; Main Guardian; Additional Guardian; dual-role user; removed
Guardian; inactive relationship; potential attempt; active attempt; paused
attempt; ended attempt. INVARIANT: Additional Guardians receive no Journey
summary; no client hiding substitutes for server authority.

## 5 · Boundaries

No other schema object touched; no Flutter; no `score_candidates`; no
Dashboard objects; no insight stores; no git; no self-approval; true
pre-file snapshots per the 038 standing practice. Numbered CODEX-FABLE
report; I verify; ChatGPT reviews; the Founder applies.

— Fable, 2026-08-30
