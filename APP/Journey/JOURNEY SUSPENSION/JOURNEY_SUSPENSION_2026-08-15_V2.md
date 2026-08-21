# ZYRA — Journey Suspension Specification

**Version:** V2
**Status:** CURRENT_VERSION — pending Founder ratification (produced in the 2026-08-12 stewardship pass; every change below implements a decision the Founder has already taken, dates cited inline)
**Date:** 2026-08-12
**Owner:** ZYRA Product Governance
**Governing Documents:**
  ZYRA Product Specification (canonical relationship lifecycle)
  DR-ZYRA-121 — Journey Lifecycle redesign (journey_attempts, no automatic endings)
  Entitlements matrix, Founder-approved 2026-08-09 (`SOURCE/lib/data/zyra_entitlements.dart`)
  Pause-for-both-plans decision, Founder 2026-08-11 (DR-ZYRA-138)
  AD-081 — Capability Independence Principle
  AD-082 — State Integrity Principle
**Supersedes:** JOURNEY_SUSPENSION_2026-08-12_V1.md (archived; was dated 2026-07-04)

---

## 0. What changed since V1, and why

V1 was written 2026-07-04, before three Founder decisions that each invalidated part of it:

1. **Pause belongs to both plans** (Founder, 2026-08-11: "in zyra basic you can also
   pause a journey its just how much you pause is different"). V1 §3 made Pause a
   ZYRA One capability. Superseded — the differentiator is now the CAP, not the
   capability. DR-ZYRA-138.
2. **The platform never ends a Journey automatically** (DR-ZYRA-121 item 12,
   OA-ZYRA-164, 2026-08-06). V1 §5.1, §5.3, §12.2 and §13.3 specified auto-End on
   blocked resume and a 30-day Full Suspension timer. All automatic endings are
   removed: a blocked resume leaves the Journey paused and intact, and the copy
   must say "nothing has been lost".
3. **The 2026-08-09 entitlements matrix** fixed the paused allowances (Basic 5,
   One 10) and decided a paused Journey does not consume an Active slot. V1 §6.3
   ("unlimited") is superseded, and V1 §5's per-combination slot tables collapse
   into one rule.

---

## 1. Architectural Framing (unchanged from V1)

Journey Suspension is a **behavioural sub-state of Active Journey** (AD-082). The
relationship remains in the Active Journey canonical state while suspended; the
suspended Journey may resume into full activity or transition to Ended.

```
Active Journey
  ├── Full Activity (conversation open, stages advance)
  └── Paused (conversation paused, stages frozen)
        ├── Resume → Full Activity        (initiator only)
        └── End    → Ended                (either party, always free)
```

---

## 2. Terminology

| Product term | Architectural / storage term |
|-------------|------------------------------|
| Pause Journey | Journey Suspension — entry (`suspend_journey`) |
| Paused Journey | `matches.suspended_by` set (attempt: `paused_by`) |
| Resume Journey | Journey Suspension — exit (`resume_journey`) |
| Paused Journeys (Connections section) | Suspended Journeys, both plans |

"Pause" is the product-facing term everywhere. Note the storage layer still says
`suspended_*` on `matches` and `paused_*` on `journey_attempts` — a naming split
raised in the 2026-08-12 stewardship report, not a distinction of meaning.

## 3. Suspension Entitlement — SUPERSEDES V1 §3

**Both plans may pause.** The differentiator is the cap:

| Plan | Paused Journeys held (initiated by this Seeker) |
|------|--------------------------------------------------|
| ZYRA Basic | 5 |
| ZYRA One | 10 |

- The cap counts pauses **this Seeker initiated** (`suspended_by = caller`).
  Journeys the other party paused never consume it.
- Enforced **server-side** in `suspend_journey` (migration 20260811231149):
  at the cap it raises `paused_limit_reached`. The old `suspension_requires_one`
  error is retired; nothing raises it.
- The other Seeker's entitlement never affects whether a pause can be initiated.
- Client behaviour at the cap: Basic sees the upgrade offer (One holds 10);
  One sees the honest ceiling with no upsell.

## 4. Suspension Entry

Either Seeker may pause their Active Journey at any time from within the Journey
view (⋮ menu, and the stage-foot action per the Founder's 2026-08-10 "gotta be at
bottom" decision). Pause is immediate — there is no confirmation dialog in the
built flow; V1 §4.2's pre-suspension summary screen was never built and is not
currently specified.

On pause: `matches.suspended_by/suspended_at` and the attempt's `paused_by/
paused_at` are set, the conversation status becomes `paused`, and stages cannot
advance.

## 5. Slot Behaviour — SUPERSEDES V1 §5 entirely

One rule, both plans, per the 2026-08-09 matrix: **a paused Journey does not
consume an Active Journey slot** — for either party. V1's per-combination tables
(Basic slot freed / One peer-slot occupied) are gone; plan mix no longer changes
slot behaviour.

**⚠️ Implementation status, stated honestly:** the database's one-Active-Journey
rule (`zyra_enforce_one_active_match` and the partial unique indexes) still counts
a paused row against the single active slot, so today nobody can hold an active
Journey alongside a paused one. Excluding suspended rows from that rule — and
making the active caps (1 Basic / 3 One) plan-aware — is raised, unbuilt work
recorded in `zyra_entitlements.dart`'s header. This section documents the ratified
target; the interim behaviour is "paused still occupies the slot".

There is no Auto-End in any branch. If a resume is blocked (other party now in an
Active Journey), the Journey **stays paused, intact, resumable later** — see §12.

## 6. Suspension State

- Visible to both Seekers in Connections → Paused Journeys ("Paused by you" /
  "Paused by them — waiting").
- Conversation paused; history preserved.
- Stages frozen; no Family Review windows open while paused.
- Journey progress preserved exactly.
- **Caps, not unlimited** (supersedes V1 §6.3): 5 (Basic) / 10 (One) pauses a
  Seeker may have initiated at once.

## 7. Timeline Behaviour

Timeline milestones are written by the database trigger
`matches_record_journey_milestone` (2026-08-11) on stage advances, Journey start
and Journey end. A paused Journey advances no stages, so its Timeline gains no
milestones while paused — freezing falls out of the model rather than needing a
separate mechanism. On resume, milestones continue as stages advance. On end, the
Timeline is preserved as a read-only record ("Your Timeline with X is preserved
as historical record").

## 8. Conversation Behaviour

| Phase | Conversation |
|-------|-------------|
| Full Activity | Open |
| Paused | `status = 'paused'` — no new messages |
| Resumed | Reopened, history intact |
| Ended | Closed (`status = 'closed'`), archive preserved |

## 9. Guardian Behaviour During Suspension

Guardian capabilities are not revoked by a pause (Capability Independence,
AD-081). Family Review actions are N/A while paused — no stage is moving.

**Notifications (V1 §9.1/9.3/9.4) are specified but the notification programme
is OA-ZYRA-161/162, not yet built.** The Auto-End warnings of V1 §9.4 are gone
with Auto-End itself.

## 10. ZYRA Intelligence During Suspension

Unchanged in intent from V1: no recommendations, insights, summaries or adaptive
content generated for a paused Journey; full operation resumes with the Journey.

## 11. Notification Summary

As V1 §11, minus every Auto-End row (removed with Auto-End), plus: a refused
resume notifies only the resuming Seeker, in-screen, with copy that states the
Journey is intact ("Nothing has been lost. You can resume when they're ready.").

## 12. Resume Behaviour — SUPERSEDES V1 §12

**12.1 Who may resume — unchanged:** only the Seeker who initiated the pause
(`resume_journey` refuses others). The non-initiator may wait or End.

**12.2 Resume flow — no Auto-End (OA-ZYRA-164):**
1. `resume_journey` re-checks eligibility.
2. Other party now holds an Active Journey → **refused**, error
   `other_party_in_active_journey`. The Journey **stays paused**. Copy: "They're
   in another Journey right now, so this one stays paused. Nothing has been
   lost."
3. A block now exists, or one party became the other's Guardian (Tier-0) →
   **refused**, error `not_eligible_to_continue` — terminal; waiting will not
   help; the only exit is End. (Tier-1 shared-Guardian is grandfathered for
   in-flight Journeys — DR-ZYRA-124.)
4. Otherwise the Journey reinstates: pause cleared on both rows, conversation
   reopened.

## 13. End While Paused

Either Seeker may End a paused Journey at any time. **Endings are always free**
(DR-ZYRA-121) — no entitlement, no cooling timer. Ending clears the pause,
closes the conversation, sets the attempt to ended, writes the `journey_ended`
Timeline milestone (exactly one — dedupe fix 2026-08-12), and notifies the other
Seeker. V1 §13.3 (30-day Auto-End) is removed.

## 14. Interaction Summary — REPLACES V1 §14

| Situation | Result |
|-----------|--------|
| Any Seeker pauses, under their cap | Journey paused for both; initiator may resume |
| At the cap (5 Basic / 10 One) | `paused_limit_reached`; resume or end one first; Basic is offered the upgrade |
| Non-initiator, while paused | Wait, or End (free) |
| Initiator resumes, other party free | Journey reinstates |
| Initiator resumes, other party in an Active Journey | Refused; stays paused; nothing lost |
| Initiator resumes, block/Tier-0 arisen | Refused, terminal; End is the only exit |
| Nobody acts, indefinitely | Journey stays paused indefinitely — no timer, no auto-end |

## 15. Version History

| Version | Date | Changes |
|---------|------|---------|
| V1 | 2026-07-04 | Initial specification. One-only entitlement; per-combination slot behaviour; Auto-End on blocked resume; 30-day Full Suspension timer. |
| V2 | 2026-08-12 | Both plans pause, caps 5/10 (Founder 2026-08-11, DR-ZYRA-138). All automatic endings removed (DR-ZYRA-121 item 12 / OA-ZYRA-164). Slot model unified per the 2026-08-09 matrix, with implementation status stated. Timeline section aligned to the milestones trigger. Produced in the 2026-08-12 stewardship pass. |

---

*ZYRA Journey Suspension Specification — CURRENT_VERSION_V2 — 2026-08-12*
