# TO: Codex / Lead Architect
# FROM: Fable / Architecture Reviewer
# SUBJECT: OA-ZYRA-281 — staged Updates migration: REVISE before apply (external review dispositions). Patch unaffected; device acceptance proceeding.

## 0 · Context

The Founder routed the Phase 2 package through ChatGPT as external reviewer
before the apply GO (AD-AIOS-106 role). Its verdict: source patch raises no
blocker; HOLD on applying `20260830145711_oa281_dashboard_updates_projection
.sql` as written. I dispositioned the findings: two HIGHs and the
medium/low items are accepted as revision requirements; one HIGH was
rejected as re-litigating ruled law (unread-backed recency — DR-ZYRA-216
gate 2, DR-ZYRA-217 item 4, DR-ZYRA-222 map; the Notifications manager is
the history surface). Revise the staged file IN PLACE (it was never
applied), report the new hash.

## 1 · Revision requirements

**R1 — Explicit per-role, per-class audience.** Every domain branch carries
an explicit audience predicate per class per role. Guardian-visible classes
must be DERIVED FROM AND EVIDENCED AGAINST current ruled app behaviour
(name the service/view/screen that already exposes each class to guardians
today — e.g. the wali timeline fetch, the guardian-activity path). Any
class whose guardian visibility cannot be proven from existing behaviour is
EXCLUDED for guardian callers pending a Founder ruling — listed, not
silently dropped. Seeker-side classes likewise explicit. No branch may rely
on attempt participation alone as the audience rule.

**R2 — Canonical-source registry replaces the dedup heuristic.** Audit the
write paths: for every event class, establish whether its writes ALWAYS
create an authoritative domain row. If yes (expected: journey_paused,
journey_continued, journey_ended, confirmed meeting/nikah), the domain row
is the SOLE Updates representation and the notification class is REMOVED
from the projection allowlist. Notification-only classes remain (expected:
milestone_proposed, journey_also_paused, invites, requests, decisions —
verify each). DELETE the match-level `NOT EXISTS` heuristic entirely.
Deliverable: a per-class canonical-source table with write-path evidence
(file/function references), not assertions.

**R3 — `is_unread` semantics.** NULL for domain rows (null = read-state not
tracked); real `read_at is null` boolean for notification rows only. The
future client contract may never render null as "read".

**R4 — Reviews index path.** `review_opened_rows` joins by `attempt_id`;
the staged index leads on `match_id`. Correct the index to the actual
access path or evidence that an existing index covers it; include
`EXPLAIN (ANALYZE, BUFFERS)` for the projection's branches at seed scale.

**R5 — Integrity guards.** Evidence NOT NULL on every projected timestamp
column or add explicit `is not null` filters; add the attempt+match
double-join defence on timeline/review branches where both keys exist.

**R6 — Participation-view contract.** Keep `zyra_my_attempt_participation`
but add a static migration test asserting its caller predicate
(`user_id = (select auth.uid())`) and role semantics, so a future view edit
cannot silently widen this RPC. Extend the post-apply verification list:
function owner, `prosecdef`, stored search_path, ACL, anon execution
denial, cross-user isolation probe.

**R7 — Contract wording.** Header comment states the ruled contract
precisely: "meaningful-movement projection — unread-backed notifications +
authoritative domain events; NOT an inbox or history; the Notifications
manager is the history surface." The md5 key comment becomes "deterministic
pseudonymous key" (it is not a confidentiality primitive; no new extension
for UUIDv5).

## 2 · Wiring contract notes (recorded now, built later)

The RPC is ONE source: success+rows → available; success+empty → empty
(genuinely nothing); call failure → unavailable. `partial` exists only
across independent sources. Retained last-known rows during a failure must
visibly present as last-known, never as fresh. Multi-Seeker Guardian
subject context (which ward an item concerns) is a wiring-phase item — add
safe subject context only with proven entitlement, not in this revision.

## 3 · Unchanged

The Phase 2 source patch stands VERIFIED — no code changes in this round.
Founder device acceptance proceeds in parallel; prepare/install the device
build for him on request in your conversation. No apply, no client wiring,
no insight stores, no git, no self-approval. Staged-only rule unchanged.

## 4 · Deliverable

Numbered CODEX-FABLE report: revised migration hash, R1 audience-evidence
table, R2 canonical-source table with write-path evidence, R4 plans, R5/R6
test additions, updated migration-test results, full suite/analyzer green.
I verify; ChatGPT gets a second pass on the revised SQL; the Founder then
rules the apply GO.

— Fable, 2026-08-30
