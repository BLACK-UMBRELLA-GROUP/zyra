# ZYRA Guardian Relationship Surfaces — Source of Truth

**Version:** V1 · **Status:** CURRENT_VERSION — RATIFIED (DR-ZYRA-224, Founder rulings F1–F7, 2026-08-30) · **Author:** Fable (from the co-signed Joint Fable × ChatGPT position) · **Programme:** OA-ZYRA-282 · **Current-state evidence:** `ZYRA_GUARDIAN_RELATIONSHIP_SURFACES_CURRENT_STATE_HANDOVER_2026-08-30_V1.md` · **Related:** DR-ZYRA-104 (CLOSED) · DR-ZYRA-136/137/123 (relationship rules) · DR-ZYRA-152/166/171 (dev/loading/card family) · DR-ZYRA-168 (HELD batch) · DR-ZYRA-222/223 + OA-ZYRA-281 (Dashboard programme, sequencing dependency)

> **Build state:** RULED, NOT BUILT. The Guardian UI rebuild is HELD until
> OA-ZYRA-281 fully closes. The ONLY active work is the F6 early security
> batch (044_FABLE-CODEX). Dashboard thinning is sequenced LAST.

## 1 · Page contracts (F1)

**Seeker Guardian tab = GUARDIANSHIP MANAGER** — see, understand and manage
the people who act as my Guardians. **Guardian Seekers tab = SEEKER
WORKSPACE ROSTER** — see and manage the people I support, understand my role
for each person, and enter their workspace in one tap. **Permanent
principle: Dashboard summarises and routes; dedicated relationship pages own
management and detail.** Necessary identity/current-state context may appear
on both surfaces; controls, full rosters and role detail have exactly one
canonical dedicated owner. Neither page may become a second Dashboard,
Updates feed, Journey page, Network page, analytics page or upsell surface.

## 2 · Invitations (F2)

Full lifecycle on the dedicated pages: create · preview/continue · pending ·
expiry · cancel/revoke · decline · detail. Dashboard keeps a compact
obligation summary + one Manage route, and loses cancellation controls when
the page ships. Supersedes the 2026-08-26 invitations-to-Dashboard
direction. Existing `wali_invites` + current RPCs only — no second store.

## 3 · Seeker page (F3)

MAIN GUARDIAN first, ADDITIONAL GUARDIANS below; vertical hierarchy scaling
to any count (no governed cap exists — live-verified). Cards: identity,
relationship, role, linked date, concise role copy, detail entry. No
movement/activity copy on roster cards — movement belongs to Dashboard
Updates; relationship history (`linked`, per-Guardian `suggested`,
`review_answered`) lives in Guardian detail; `review_waiting` is
current-obligation logic, never history. "What can my Guardians see and
do?" ships only when driven by the governed permissions matrix reconciled
against live server authority — never static copy. Guardian Pulse retires
as production default; Pulse + the four sibling designs are cleaned only
after the replacement passes Founder device acceptance. Detail keeps: Make
Main · Remove (DR-ZYRA-136 guards) · Report · role/access explanation.

## 4 · Guardian page & per-Seeker workspace (F4)

Every Seeker card is tappable → a **thin, role-aware per-Seeker workspace**:
identity, relationship, linked date, my role, permitted current context,
authorised actions, routes into the EXISTING Journey detail, Family Review /
Guardian Gate, and Guardian Network context surfaces. Assembly and routing
only. **Main-Guardian grouping:** NEEDS YOU → IN A JOURNEY → PAUSED OR
WAITING → OTHER SEEKERS; oldest-waiting-first within NEEDS YOU (no governed
due-times exist yet); stable alphabetical elsewhere. **Additional-Guardian
relationships sit in a neutral ADDITIONAL GUARDIANSHIPS section** and must
not reveal Journey state through headings, ordering, badges, counts, card
position, aggregates, or disabled/locked modules — unauthorised sections are
omitted entirely. Additional-Guardian workspace in V1: identity,
relationship, role, linked date, proven Role & Access, separately authorised
non-Journey actions only. No behavioural scoring or engagement ranking, ever.

## 5 · Dashboard thinning (F5 — sequenced last)

Only after the dedicated pages ship + tests + Fable verification + Founder
device acceptance: Guardian Today keeps one priority, a compact family
snapshot, a highlighted actionable Seeker only where necessary, and a View
Seekers route; Seeker Today keeps compact Guardian status, invitation
summary, and a Manage Guardians route. Dashboards no longer own rosters,
invitation cancellation, role management, removal/reassignment, or full
per-person Journey context. **All Dashboard counts/summaries must respect
caller authority — no aggregate may reveal hidden Additional-Guardian
Journey state** (safe fallback copy: "3 linked Seekers · 1 needs you").

## 6 · Privacy & visibility (F6)

DR-ZYRA-104 **CLOSED**: passive Guardian visibility of Saved/Considering/
Passed is REJECTED (process, never behaviour). Untouched separate
mechanisms: Guardian Suggestions, Guardian Network, Family Review, Guardian
Gate. Future option (separate design, Founder-gated): Seeker-initiated
"Share this profile with my Guardian". No cross-Guardian visibility without
a future ruling. No reciprocal verification badges in V1 (verification is an
access prerequisite, not social status; owner-facing state lives in the
owner's account surface). Additional-Guardian Journey visibility remains
HELD (DR-ZYRA-168); Main-only Journey summary in V1.

**RULED 2026-08-30 (DR-ZYRA-225) — Journey-history scope + consent toggle:**
default (toggle OFF) = the current active Journey is ALWAYS visible to the
current active Main Guardian even if it began before their link (paused
included), plus ended Journey summaries whose ending falls after their
Guardian link began; ended-before-link stays private. ONE Seeker-facing
toggle — AMENDED 2026-08-31 by Founder-direct build: labelled "Share full
Journey history", living on the MAIN GUARDIAN DETAIL page (the roster makes
zero consent reads; the explanation is collapsed behind a disclosure that
never changes consent): ON = all past summaries; OFF = immediate revert;
consent is bound server-side to the specific current Main link and RESETS
OFF automatically whenever the Main changes — never inherited. Additional
Guardians: no Journey information, unchanged. Four-field cap in every mode.
The ruled predicate is a positive allowlist by construction (future attempt
statuses fail closed). Implemented via the build contract's Phase 0 under
the full security gate chain; no client wiring before those gates pass.
AMENDED 2026-08-30 (N1, Founder-ruled): the default ended-history boundary
is the Guardian's CURRENT CONTINUOUS ACTIVE PERIOD (active-since semantics —
fresh on every reactivation; preserved across Main/Additional switches),
NOT wali_links.created_at, which is never repurposed. A removed-then-
relinked Guardian's away period is therefore excluded by default; full
pre-period history still requires the Seeker's consent toggle. See the
DR-ZYRA-225 annotation.

**Verified server defect (live evidence 2026-08-30):**
`zyra_attempt_summary_for_guardian` — owner postgres, SECURITY DEFINER,
`authenticated` holds EXECUTE, predicate admits ANY active guardian; 8
active Additional links exist, currently 0 with attempts (unexercised by
data, not by control). Fixed via the early security batch (§8).

## 7 · Permanent truth & interaction laws (F7)

EMPTY ≠ FAILED · STALE ≠ CURRENT (last-known marked last-known) · no no-op
primary person cards (interactive-looking = valid destination) · management
has one canonical owner · movement has one canonical owner · role claims
must match server authority · **authority applies to fields, copy,
grouping, ordering, badges and aggregate counts** · release builds contain
no dev fixtures. Bounded V1 work also includes the `WaliSeekersScreen`
typed-Result fix (blast radius: the screen only — live-verified) and the
hint correction via §8. V1 excludes: Guardian Insights, passive Browse
visibility, Network redesign, Journey redesign, verification badges,
premium differentiation, shell-navigation redesign, resignation rules,
behavioural analytics, sub-navigation, roster search/filtering, new AI,
new recommendation systems.

## 8 · F6 early security batch (ACTIVE — the only pre-Dashboard-close work)

One staged "guardian server truth" micro-migration: (a)
`zyra_attempt_summary_for_guardian` tightened to Main-Guardian authority
only, aligned with the governed Main boundary (potential attempts excluded;
returned fields listed and justified; definer hardening: empty search_path,
schema-qualified, PUBLIC/anon revoked); (b) the final-Guardian-removal hint
corrected — an active OR PAUSED Journey requires the Seeker to retain a
Guardian; assign another Guardian, or end the Journey through the governed
flow; pausing does NOT permit removal. Enforcement logic unchanged. Gated:
Fable brief (044) → Codex staged migration → Fable verification → ChatGPT
external security review → Founder apply GO → post-apply verification with
the twelve direct-call cases (unauthenticated; unrelated authenticated;
Seeker; Main; Additional; dual-role; removed Guardian; inactive link;
potential/active/paused/ended attempts). Invariant: Additional Guardians
receive no Journey summary; no client hiding substitutes for server
authority.

## 9 · Future items (recorded, not implemented)

Guardian-initiated resignation/unlink (genuine missing product rule — no
RPC, no UI, no DR); Guardian-side Guardian Gate execution primitive (the
gate is truthfully presented as routed context, but the only live
stage-advance path is Seeker-owned — a Guardian decision action needs its
own ruled server/client contract; recorded 2026-08-31, 062 C1/063);
Additional-Guardian cap; DR-ZYRA-168 visibility
expansion; Seeker-initiated profile sharing; Guardian-facing verification
display; ward-list search/filtering; Guardian Insights; premium workspace
tools; navigation-shell redesign.

## 10 · Execution state

2026-08-30: DR-ZYRA-224 filed; DR-ZYRA-104 closed; OA-ZYRA-282 opened;
044_FABLE-CODEX security contract filed; documents reconciled (module
inventory V3 notes, navigation source correction, handover banner). Guardian
UI build brief NOT sent — held until OA-ZYRA-281 closes. SUBSEQUENT, all
2026-08-30: the §8 security batch completed end to end — staged (048),
Fable-verified (049), ChatGPT conditional APPLY GO, Founder apply GO,
20260830183151 APPLIED, post-apply verified 12/12 on Fable's corrected
instrument (the Codex harness had three defects, H1-H3 — fix ordered in
050, non-gating), ChatGPT FINAL SIGN-OFF PASS; workstream A CLOSED.
OA-ZYRA-281 closed the same day; Founder said "start" on the UI build.
DR-ZYRA-225 ruled the Journey-history scope + Seeker consent toggle (see
§6); both external wiring gates are now ruled, pending Phase 0
implementation. The build contract was approved by the Founder the same day and filed as
051_FABLE-CODEX (binding); workstream B is ACTIVE. SUBSEQUENT: Phase 0
completed the full gate chain — staged (052), verified (053), external
review with one Founder-ruled refinement (N1 -> active_since, DR-225
annotation, 054/055/056), delta CLEAN PASS, Founder apply GO, APPLIED
2026-08-30 as 20260830200416, post-apply verified end to end including the
corrected canonical harness's first complete clean pass (057-059), and
EXTERNALLY SIGNED OFF 2026-08-31. PHASE 0 IS CLOSED; the ended-history
wiring hold is LIFTED; the DR-225 Journey-summary model (current
active/paused + ended-in-current-period by default; full history under
link-bound Seeker consent; Additional at zero; future statuses denied) is
live server truth. SUBSEQUENT, 2026-08-31: Phases 1-3 built and
Fable-verified (060-065) — Guardianship Manager with the DR-225 consent
toggle, Guardian roster + role-aware per-Seeker workspaces with the live
Main-only Journey summary, both Dashboards thinned per F5, and the C2
Journey-detail truth correction. FOUNDER ACCEPTED on device (verbatim
"Accepted", 2026-08-31) after his single visual inspection: 96 candidates
promoting, the twelve superseded OA-281 Seeker-Today variants archiving,
Pulse + siblings authorised for cleanup. OA-ZYRA-282 closes on the
promotion round's verification (066/067).

---

*V1 · 2026-08-30 · Fable. Rulings trace to DR-ZYRA-224; current-state facts
trace to the 2026-08-30 handover; live evidence re-verified this day.
Nothing here is implementation authority by itself — the Codex contracts and
their gates govern the build.*
