# TO: Codex / Lead Architect
# FROM: Fable / Architecture Reviewer
# SUBJECT: OA-ZYRA-281 — addenda to 039: external reviewer accepted the dispositions; implementation conditions attached

## 0 · Round outcome

ChatGPT accepted all dispositions and **withdrew the read-notification
history requirement** after the ruled unread-backed citations (it asked that
the contract comment make the rule explicit "so a future reviewer does not
'fix' it into an inbox again" — that is 039 R7, unchanged; the unread
partial index stands as staged). The migration HOLD remains until 039
R1/R2 plus the accepted medium/low items are resolved. The second pass on
your revised SQL will be narrow: authorization, canonical-source semantics,
SQL correctness, indexing, security-definer verification. These addenda are
accepted conditions — treat them as part of 039.

## A1 · Extends R1 — participation authority dimensions

The current `caller_participation` CTE collapses to
`select distinct attempt_id, match_id`, discarding the role information the
per-role rules need. The revised structure must RETAIN the authority
dimensions through to each branch's audience predicate: caller role,
Main/Additional status where relevant, attempt, match, and any other
already-ruled visibility capability. For dual-role accounts or unexpected
data states, visibility must flow from the SPECIFIC authorised
participation, never from the mere existence of some participation row.

Evidence-table format is fixed:

`class | Seeker visible? | Main Guardian visible? | Additional Guardian visible? | authoritative current behaviour/rule | SQL predicate`

Anything without evidence stays out.

## A2 · Extends R2 — semantic duplication, not just name duplication

The canonical-source audit must test SEMANTIC pairs, not only identical
enum names. Explicitly test at least: `new_match` vs `match_created`;
journey-request acceptance vs journey-start domain movement; Guardian/
family-review notifications vs corresponding review domain rows. The
governing question per pair: "would a user understand these two rows as the
same thing happening?" — not "do the enums match". Where exact equivalence
cannot be proven, keep classes separate ONLY if they genuinely represent
different meaningful movements. No timestamp-guess dedup anywhere.

## A3 · Extends R2 deliverable — unread-fate columns

For every notification class removed because a domain row becomes
canonical, the canonical-source table adds, per class: (a) what happened to
its unread indication; (b) whether the Dashboard ever relied on that unread
indication; (c) whether the Notifications manager still carries the unread
notification independently; (d) whether using the domain row changes any
user-visible semantics beyond removing the duplicate. Domain rows do NOT
inherit notification unread state. The change must be documented and
understood, never accidental.

## A4 · Extends R3 — three-state `is_unread` contract (verbatim)

`true` = notification with unread support, currently unread. `false` =
notification with read-state support that is read, if such rows are ever
projected. `NULL` = the source does not participate in notification
read-state. Under the ruled unread-only notification rule the RPC returns
mostly `true` or `NULL`. The client contract may never render `NULL` as
"read".

## A5 · Extends R6 — post-apply verification additions

Add to the post-apply list: null/unauthenticated caller returns no rows;
user A cannot retrieve user B data; and explicit role-case probes — Seeker
vs Main Guardian vs Additional Guardian callers against the same attempt.

## 1 · Sequence and boundaries (unchanged)

Revised staged SQL (in place, new hash) + the two evidence tables → Fable
verification → ChatGPT second pass → Founder apply GO. The Phase 2 source
patch stands; Founder device acceptance proceeds in parallel; staged-only,
no wiring, no insight stores, no git, no self-approval.

— Fable, 2026-08-30
