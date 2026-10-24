# ZYRA Guardian Relationship Surfaces — Source of Truth

**Version:** V2 · **Status:** CURRENT_VERSION — RATIFIED (DR-ZYRA-224 F1–F7; F2 amended by DR-ZYRA-226/231; Journey authority amended by **DR-ZYRA-230/232/233/236**) · **Author:** Fable, amended by Codex under the Founder's direct rulings · **Programme:** OA-ZYRA-282 / OA-ZYRA-289 / OA-ZYRA-290 / OA-ZYRA-291 / OA-ZYRA-294 · **Current-state evidence:** `ZYRA_GUARDIAN_RELATIONSHIP_SURFACES_CURRENT_STATE_HANDOVER_2026-08-30_V1.md` · **Related:** DR-ZYRA-104 (CLOSED) · DR-ZYRA-136/137/123 (relationship rules) · DR-ZYRA-224/225/226/230/231/232/233/236 · OA-ZYRA-263 (IDV remains separate) · OA-ZYRA-274 (deep links remain separate)

> **Build state (2026-09-17):** the Guardian surfaces programme was accepted.
> DR-ZYRA-231 activates the linking model in §2.1. Migration
> `20260917144606` is **LIVE AND POST-APPLY VERIFIED** under OA-ZYRA-289; the
> corrected shared profile build is installed on the Founder iPhone. Local
> Founder-preview personas use non-production-format demo codes only: they
> create no member, code or request row and cannot resolve through the live
> service.
>
> **Amended and deployed 2026-09-18:** DR-ZYRA-232 replaces the summary-only ceiling for
> an Additional Guardian whom their own Seeker explicitly includes in a
> specific active Journey. OA-ZYRA-290 migration `20260918075737` is **LIVE
> AND POST-APPLY VERIFIED**; the revised signed client is installed and
> launched on the Founder iPhone. Founder visual acceptance remains open.
>
> **Live and verified 2026-09-18:** DR-ZYRA-233 adds an individual,
> Seeker-controlled permission for each current Guardian to receive all past
> four-field Journey summaries. OA-ZYRA-291 migration `20260918094504` is
> **LIVE AND POST-APPLY VERIFIED**; the signed client is installed.
>
> **Staged 2026-09-18:** DR-ZYRA-236 permits a deliberate no-Main state. The
> Main Guardian becomes Additional rather than being unlinked; My ZYRA raises
> a "Choose a Main Guardian" action and ordinary Active Journey participation
> waits until both Seekers have Main leadership. Pause and End stay available.
> OA-ZYRA-294 client work is installed; migration `20260918140508` is
> **STAGED ONLY** and production remains unchanged pending replay and an exact
> Founder apply GO.

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

## 2 · Invitations and linking (F2, amended by DR-ZYRA-226)

Full lifecycle on the dedicated pages: create · preview/continue · pending ·
expiry · cancel/revoke · decline · detail. Dashboard keeps a compact
obligation summary + one Manage route, and loses cancellation controls when
the page ships. Supersedes the 2026-08-26 invitations-to-Dashboard
direction.

> **AMENDED 2026-09-01 (DR-ZYRA-226).** F2 originally closed with "Existing
> `wali_invites` + current RPCs only — no second store." **That sentence is
> superseded IN PART:** the existing `wali_invites` authority MAY EVOLVE into
> a recipient-bound request system carrying sender, recipient, direction/
> context, proposed relationship, the states pending/accepted/declined/
> cancelled/expired, and timestamps and provenance. Everything else in F2
> stands, and **F2's purpose is unchanged and binding** — one source of
> truth, no duplicate invitation systems, Dashboard summarises and routes,
> dedicated pages own the lifecycle. A second competing request store
> remains UNAPPROVED.

### 2.1 · The linking model (ACTIVATED by DR-ZYRA-231)

Every account has one reusable ZYRA Code for its current role. The schema is
role-context keyed so a future governed dual-role account can have distinct
Seeker and Guardian codes; today's single-role profile may mint only the
role in `profiles.role`.

```
A opens Add a Guardian/Seeker → permanent role-specific ZYRA Code
A copies, shows QR or shares  → raw code only; no provider and no deep link
B scans or enters             → safe first-name + role preview
B confirms                    → addressed 30-day PENDING request; NO LINK
A reviews                     → accept or decline
── ACCEPT ONLY ──             → wali_links written here
```

The code is a random opaque 80-bit discovery handle, never a credential.
Knowing it cannot link, sign in, prove identity or reveal a profile. Preview
is authenticated, rate limited and neutral for invalid, self, blocked,
romantically ineligible, same-role and already-linked cases. It returns
**first name and role only: no photo and no verification claim.**

The relationship statement always belongs to the Guardian. A Guardian who
enters a Seeker's code proposes it with the request; a Guardian whose own
code was entered supplies it while accepting. A Seeker never corrects or
invents the Guardian's relationship. This is the narrow DR-ZYRA-231
supersession of DR-ZYRA-226's earlier owner-correction wording.

The code is rotatable. Retired codes and codes removed with an account are
represented only by SHA-256 in a no-owner non-reuse ledger and are never
issued again. QR rendering/scanning and native sharing are on-device and
free. Deep links remain out of scope.

The existing `wali_invites` table remains the one lifecycle authority,
extended with `source`, `personal_code_id`, `recipient_id`,
`request_expires_at` and cancellation state. Its legacy `expires_at` remains
unchanged for old seven-day bearer codes. Those existing rows may complete
their natural overlap, but new clients do not mint them.

The personal-code implementation migration is live and post-apply verified
under OA-ZYRA-289. This document does not authorise any future production
apply.

## 3 · Seeker page (F3)

MAIN GUARDIAN first, ADDITIONAL GUARDIANS below; vertical hierarchy scaling
to any count (no governed cap exists — live-verified). Cards: identity,
relationship, role, linked date, concise role copy, detail entry. No
movement/activity copy on roster cards — movement belongs to Dashboard
Updates; relationship history (`linked`, per-Guardian `suggested`,
`review_answered`) lives in Guardian detail; `review_waiting` is
current-obligation logic, never history. "What can my Guardians see and
do?" is server-driven: when a Main is assigned, Main is always included;
each Additional Guardian has
one collapsed "Active Journey access" group with a confirmed switch per
active Journey plus factual Can View and Main Guardian Leads sections. Every
Guardian has a separate "Share past Journey summaries" permission; FAILED
never renders as OFF. Guardian Pulse retires
as production default; Pulse + the four sibling designs are cleaned only
after the replacement passes Founder device acceptance. Detail keeps: Make
Main · Remove as Main · Remove Guardian · Report · role/access explanation.
Demotion and unlink are distinct. Every destructive/authority-changing action
uses the same in-place Cancel/Confirm pill pair rather than a dialog or an
expanding warning. If there is no Main, no existing Additional is silently
promoted.

## 4 · Guardian page & per-Seeker workspace (F4)

Every Seeker card is tappable → a **thin, role-aware per-Seeker workspace**:
identity, relationship, linked date, my role, permitted current context,
authorised actions, routes into the EXISTING Journey detail, Family Review /
Guardian Gate, and Guardian Network context surfaces. Assembly and routing
only. **Main-Guardian grouping:** NEEDS YOU → IN A JOURNEY → PAUSED OR
WAITING → OTHER SEEKERS; oldest-waiting-first within NEEDS YOU (no governed
due-times exist yet); stable alphabetical elsewhere. **Additional-Guardian
relationships sit in a neutral ADDITIONAL GUARDIANSHIPS section.** An
Additional card/workspace may show current Journey context only when the
caller-scoped server participation row proves this Seeker included that
Guardian. It never inherits Main-only NEEDS YOU grouping, priority, badges or
decision actions. Without an assignment, current context is omitted and only
the DR-ZYRA-230 narrow summary remains, widened to older ended summaries only
when that Guardian's own DR-ZYRA-233 permission is live and valid. The
permission never grants a current route. No behavioural scoring or engagement
ranking, ever.

## 5 · Dashboard thinning (F5 — sequenced last)

Only after the dedicated pages ship + tests + Fable verification + Founder
device acceptance: Guardian Today keeps one priority, a compact family
snapshot, a highlighted actionable Seeker only where necessary, and a View
Seekers route; Seeker Today keeps compact Guardian status, invitation
summary, and a Manage Guardians route. Dashboards no longer own rosters,
invitation cancellation, role management, removal/reassignment, or full
per-person Journey context. **All Dashboard counts/summaries must respect
caller authority — no aggregate may reveal unauthorised Additional-Guardian
Journey state**; an assigned Additional may receive their own context but
never Main-only attention counts (safe fallback copy: "3 linked Seekers · 1
needs you").

## 6 · Privacy & visibility (F6)

DR-ZYRA-104 **CLOSED**: passive Guardian visibility of Saved/Considering/
Passed is REJECTED (process, never behaviour). Untouched separate
mechanisms: Guardian Suggestions, Guardian Network, Family Review, Guardian
Gate. Future option (separate design, Founder-gated): Seeker-initiated
"Share this profile with my Guardian". No cross-Guardian visibility without
a future ruling. No reciprocal verification badges in V1 (verification is an
access prerequisite, not social status; owner-facing state lives in the
owner's account surface). Additional-Guardian visibility is now controlled by
DR-ZYRA-230 and DR-ZYRA-232; passive Browse visibility remains rejected.

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
OFF automatically whenever the Main changes — never inherited. DR-ZYRA-230
later granted the four-field summary to every active Guardian. DR-ZYRA-232
now permits richer current-Journey read surfaces only while the owning Seeker
includes that Additional Guardian for that exact active attempt.
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

**AMENDED 2026-09-18 (DR-ZYRA-233) — per-Guardian past summaries:** the
past-summary permission is no longer Main-only. Every current Guardian has an
individual Seeker-controlled permission labelled **"Share past Journey
summaries"**. A new Guardian begins OFF; a valid existing Main permission is
preserved. Permission is bound to that person's current continuous active-link
epoch, survives a continuous Main/Additional role switch for the same person,
never transfers and resets across removal/reactivation. ON widens only the
existing four-field ended-summary set; it never grants names, stage, messages,
answers, reasons, notes or safety data. Current-Journey access remains wholly
separate under DR-ZYRA-232. Paid Guardian capacity is not Journey authority and
this limitation is disclosed before purchase, at link acceptance and in-app.

**AMENDED 2026-09-18 (DR-ZYRA-236) — deliberate no-Main state:** a Seeker may
demote the Main Guardian to Additional or unlink them without first assigning
a replacement. My ZYRA Now raises a Needs You action. Ordinary participation
and resumption in a shared Active Journey are held whenever either Seeker has
no active Main Guardian. Pause and End remain available. Main-only leadership
rules continue unchanged whenever a Main is assigned; Additional permissions
never become Main authority.

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

## 8 · F6 early security batch (CLOSED 2026-08-30 — retained as the applied record)

> **Closed.** Applied 2026-08-30 as migration `20260830183151`, post-apply
> verified 12/12 on Fable's corrected instrument, ChatGPT FINAL SIGN-OFF
> PASS. Retained because it is the applied record, not because work remains.

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
potential/active/paused/ended attempts). Its original no-Additional invariant
was superseded first by DR-ZYRA-230's summary and then narrowly by
DR-ZYRA-232's per-active-Journey assignment. The permanent invariant remains:
no client hiding substitutes for server authority.

## 9 · Future items (recorded, not implemented)

Guardian-initiated resignation/unlink (genuine missing product rule — no
RPC, no UI, no DR); Guardian-side Guardian Gate execution primitive (the
gate is truthfully presented as routed context, but the only live
stage-advance path is Seeker-owned — a Guardian decision action needs its
own ruled server/client contract; recorded 2026-08-31, 062 C1/063);
Additional-Guardian cap; Seeker-initiated profile sharing; Guardian-facing
verification display; ward-list search/filtering; Guardian Insights; premium
workspace tools; navigation-shell redesign; **Guardian Notes** as a separate
auditable non-chat feature; **reciprocal Journey-access transparency** showing
both Seekers which Guardians can access their shared Journey. The last two are
owned by OA-ZYRA-292 and are not implemented by DR-ZYRA-233.

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
Pulse + siblings authorised for cleanup. OA-ZYRA-282 closes on the promotion round's
verification. SUBSEQUENT, 2026-08-31: the post-067 Founder-directed delta was filed and the Phase 1 v2 successor candidates staged (069), Fable-verified (070), and the second device look released; AD-AIOS-107 changed the team's role titles (071). SUBSEQUENT, 2026-09-01: the Founder accepted the second look; Fable re-verified the staged artefacts against disk (manifest c354d8fa, harness 49e2b668 — both unchanged overnight) and RELEASED the promotion round as **072**. Codex reports as 073; Fable verifies; OA-ZYRA-282 then CLOSES. Also 2026-09-01: **DR-ZYRA-226** filed — the Guardian linking model (§2.1), amending F2 in part; documents reconciled the same day (this V2 and the DR-ZYRA-224 amendment note). SUBSEQUENT, 2026-09-17: DR-ZYRA-230 made the four-field Journey summary available to every active Guardian and OA-ZYRA-288 applied it. SUBSEQUENT, 2026-09-18: DR-ZYRA-232 made Main participation non-optional and allowed each Seeker to include their own Additional Guardians per active Journey. OA-ZYRA-290 migration `20260918075737` was applied under exact-hash Founder GO, post-apply verified, and the signed client was installed and launched for Founder visual acceptance.

SUBSEQUENT, 2026-09-18: DR-ZYRA-233 generalised the past-summary permission
to each current Guardian while retaining the four-field cap and separating it
from DR-ZYRA-232 current participation. OA-ZYRA-291 migration
`20260918094504` is live and post-apply verified; its signed client is
installed. Guardian Notes and reciprocal access transparency remain held
under OA-ZYRA-292.

SUBSEQUENT, 2026-09-18: DR-ZYRA-236 superseded the forced-replacement rule in
DR-ZYRA-136. OA-ZYRA-294 client work is built, tested, installed and launched.
Migration `20260918140508` is staged only; production still enforces the prior
rule until the isolated replay, review and separate exact-hash apply GO.

---

*V2 · 2026-09-01 · Fable. V1 archived as `ZYRA_GUARDIAN_RELATIONSHIP_SURFACES_2026-09-01_V1.md` (reference only). Rulings trace to DR-ZYRA-224; current-state facts
trace to the 2026-08-30 handover; live evidence re-verified this day.
Nothing here is implementation authority by itself — the Codex contracts and
their gates govern the build.*
