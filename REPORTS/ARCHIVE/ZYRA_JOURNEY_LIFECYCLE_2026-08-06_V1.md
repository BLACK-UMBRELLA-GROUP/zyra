# ZYRA — Journey Lifecycle: Joint Recommendation

**Document:** ZYRA_JOURNEY_LIFECYCLE_RECOMMENDATION_2026-08-06_V1.md
**From:** Fable (UX & Product Experience Lead) and ChatGPT (Strategic Review) — agreed position, not competing proposals
**Date:** 2026-08-06
**Status:** PROPOSED — for Founder approval
**Method:** Worked out against the live schema and functions rather than the specifications, because the two have drifted. Every claim about current behaviour below was read from the database.

---

## 0. One thing to fix regardless of this proposal

**`restart_journey()` lets one person reopen an ended Journey alone, and deletes the history that justified ending it.**

Read from the live function today. It requires only: the match is ended, 24 hours have passed, and the caller has a free Journey slot. It does not ask the other person. It then deletes `journey_compatibility`, `journey_salams`, `journey_phase_answers`, `journey_phase_ratings`, `journey_phase_checkpoints` and `journey_family_answers` before setting the Journey active again.

So a person who ended a Journey — possibly because they felt unsafe — can find themselves back in an Active Journey they never re-consented to, with the record wiped.

We recommend treating this as a **standalone engineering fix, not part of the redesign**. It should be corrected whether or not the architecture below is approved. Minimum fix: require both parties to agree before an ended Journey reopens, and stop the deletions.

---

## 1. What is actually built today

| Believed | Actually |
|---|---|
| Four lifecycle states: potential / active / paused / ended | **Three.** `suspend_journey()` never sets `status='paused'` — it writes `suspended_by` and `suspended_at` and leaves the status `active`. The `paused` enum value is dead. |
| Pausing is a lifecycle stage | It is a flag on an Active Journey. The implementation already made this decision; the documents haven't caught up. |
| Ending records why | It records only `ended_at`. There is no `ended_by` and no reason. A mutual, respectful ending and someone fleeing a frightening situation are indistinguishable in the data. |
| One Active Journey per person is enforced | **It isn't.** `matches_seeker_a_active` and `matches_seeker_b_active` are two separate partial indexes, so one person can be `seeker_a` on one active match and `seeker_b` on another without violating either. |
| Pausing is a normal user action | It requires ZYRA One. `suspend_journey()` raises `suspension_requires_one` otherwise. |

One thing the schema already got right, which shapes everything below: `matches` carries `CHECK (seeker_a_id < seeker_b_id)` and `UNIQUE (seeker_a_id, seeker_b_id)`. **It is already a permanent, one-per-pair record.** The recommendation builds on that rather than replacing it.

---

## 2. The recommended model

```
matches                    the pair. Permanent, one row per two people. Already exists.
  └── journey_attempts     one row per attempt. Potential → Active → Ended.
        ├── timelines
        ├── conversations
        └── journey_* tables
```

**Users never see the word "Relationship."** Internally the pair record is the parent object; externally people see *Journey history: Attempt 1, Attempt 2, Attempt 3*. Two people who ended a Journey after four days do not have a "relationship", and in this community that word carries weight a Guardian would read quite differently from how we mean it.

### Where each fact lives

| On the pair (`matches`) | On the attempt (`journey_attempts`) |
|---|---|
| the two people, `created_at` | `status` — potential / active / ended |
| **`protection_state`** | `journey_stage` |
| block relationship | `started_at`, `ended_at` |
| moderator state | `ended_by`, `end_reason` |
| | `paused_by`, `paused_at` |

**`protection_state`, not a boolean.** An enum with room to grow: `normal · blocked · safety_locked · moderator_locked`. It lives at pair level because a safety ending must bar *every* future attempt with that person, not merely prevent reopening the one that ended — otherwise the barred party simply requests a fresh attempt and the protection evaporates.

**Every Journey is an attempt from the start.** Attempt 1 exists the moment a Journey does, not lazily on first restart. If there is never a second attempt, nothing is wasted; if there is, no data has to be migrated at that moment.

### The three states, plainly

- **Potential** — you have matched; neither of you has begun.
- **Active** — the Journey is underway. It may be *paused*, which is a flag on this state, not a state of its own.
- **Ended** — this attempt is over, permanently. A future attempt is a new attempt, never a resurrection of this one.

---

## 3. Pausing

**Free for everyone.** This is our one recommendation that reverses an approved decision, and we both think it should change. Pausing exists for exams, istikharah, family discussions, illness and travel. Charging someone to step back from a marriage process during illness or istikharah is a values problem before it is a pricing one — and it creates the wrong incentive: someone who cannot pay simply ends the Journey instead, or ghosts.

Premium should differ on **capacity**, not on the right to step away: additional Journey capacity, longer retention, priority workflow.

**Either person may pause. The Journey is paused while anyone has it paused, and resumes when everyone has resumed.** That one sentence replaces the current Peer-Suspended / Full Suspension matrix, whose three sub-states derive from plan combinations. The outcomes are the same; users can actually hold this version in their heads.

**No automatic expiry.** ZYRA should never decide that a marriage prospect is over. Instead: a gentle check-in at 30 days (*"Are you still intentionally paused?"*) and again at 90 (*"Would you like to resume or end this?"*), then leave it paused indefinitely. The platform reminds; the people decide. Expected return dates optional and never binding — a date you can't meet becomes a second failure.

---

## 4. Ending

**Every ending records who, when and why.** Reasons offered to whoever ends it: *not compatible · circumstances changed · marrying elsewhere · family decision · I'd rather not say · safety concern*.

Two rules:

1. **Only "safety concern" is hidden from the other party.** The rest are shown, because a stated reason is kinder than silence and this audience deserves that.
2. **A safety ending sets the pair's `protection_state` to `safety_locked`, permanently.** The other party is never told why a new attempt is unavailable — they simply never see the option.

Without this, almost every future feature loses its footing: moderation, Guardian history, support cases, analytics and safety all depend on knowing how a Journey ended.

---

## 5. Starting again

**"Request New Journey", not "Restart".** One person requests; the other accepts or declines; the request expires if unanswered. Never unilateral, and never a resurrection — a new attempt starts fresh, with its own timeline.

**Nothing is ever deleted.** Previous attempts remain in full. Deletion destroys exactly the evidence a Guardian or a moderator would need if a pattern emerges, and it makes GDPR erasure harder rather than easier — erasing one whole attempt object is far cleaner than half-wiping shared rows.

Guardians see attempt history, because "this is the second attempt" is genuinely meaningful context for the role they hold.

---

## 6. What this costs to build

Honest, so the decision is made with open eyes. **Nine tables currently key off `match_id`** and would move to `attempt_id`:

`conversations · journey_compatibility · journey_family_answers · journey_family_reviews · journey_phase_answers · journey_phase_checkpoints · journey_phase_ratings · journey_salams · timelines`

Those carry **15 RLS policies** between them, each of which reaches the pair through `match_id` today and would need re-pointing. That is the real work in this proposal — not the idea, the re-pointing. `timelines.match_id` is also `UNIQUE`, so one timeline per pair today; it becomes one per attempt, which is what makes "Attempt 1, 2, 3" legible rather than one smeared history.

**Two things the restructure fixes for free**, worth counting as benefits rather than extra scope:

- The one-Active-Journey rule becomes genuinely enforceable, per person, instead of the two half-indexes that don't currently work.
- The dead `paused` enum value disappears, so the schema stops describing a state that never occurs.

---

## 7. Recommended sequence

1. **Now, independent of everything else:** fix `restart_journey()` — mutual consent, no deletions. *§0.*
2. **Small and independently valuable:** add `ended_by` and `end_reason`; drop the dead `paused` enum value; make Pause free.
3. **The restructure:** `journey_attempts`, `protection_state`, "Request New Journey". A considered piece of work with its own Decision Record.

---

## 8. What we are asking the Founder to decide

| # | Decision |
|---|---|
| 1 | Approve the fix to `restart_journey()` — mutual consent, no deletions. *(We recommend yes regardless of the rest.)* |
| 2 | Approve `journey_attempts` beneath `matches`, accepting the nine-table, fifteen-policy migration. |
| 3 | **Reverses an approved decision:** make Pause free for all Seekers; move the premium difference to capacity. |
| 4 | Approve the end reasons list and the rule that only "safety concern" is hidden. |
| 5 | Approve reminders at 30 and 90 days, and no automatic ending, ever. |

---

*Agreed jointly by Fable and ChatGPT, 2026-08-06. No dissent between us on any point above.*

*End of Document*
