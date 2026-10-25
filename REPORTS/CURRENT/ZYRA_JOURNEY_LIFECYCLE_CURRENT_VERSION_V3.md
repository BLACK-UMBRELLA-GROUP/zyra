---
id: DOC-ZYRA-0256
type: REPORT
status: CURRENT
feature: REPORTS
purpose: ZYRA — Journey Lifecycle Architecture
links: []
owner: ZYRA chat
---

# ZYRA — Journey Lifecycle Architecture

**Document:** ZYRA_JOURNEY_LIFECYCLE_CURRENT_VERSION_V3.md
**Supersedes:** ZYRA_JOURNEY_LIFECYCLE_2026-08-06_V2.md and _V1.md *(archived — reference only)*
**From:** Fable (UX & Product Experience Lead) and ChatGPT (Strategic Review)
**Date:** 2026-08-06
**Status:** **APPROVED** — Founder approval recorded 2026-08-06, with one amendment (§7)
**Decision Record:** DR-ZYRA-121
**Operational Actions:** OA-ZYRA-154 through OA-ZYRA-165
**Method:** Every claim about current behaviour was read from the live database on 2026-08-06, not from the specifications. Where the two disagree, this document follows the database.

---

## What changed in V3

V2 was the proposal. V3 is the approved architecture, and differs in exactly two ways:

1. **§7 Pausing — the Founder did not approve making Pause free.** Pause remains a ZYRA One capability. That reverses our joint recommendation, and it has consequences V2 did not work through, because V2's pause rule assumed everyone could pause. §7 is rewritten and §7A adds the guardrails that premium gating now requires.
2. **§16 records what is approved, what is amended, and what remains open** — replacing V2's "decisions requested".

Everything else is carried forward unchanged and is now approved.

---

## Summary

1. **`restart_journey()` is unsafe today and is being fixed independently of everything else.** §0, OA-ZYRA-154.
2. **The Journey model moves from "a match that reopens" to "a pair that can have several attempts".** §2.
3. **All ten Journey tables contain zero rows, so this is a code migration with no data migration.** It will never be cheaper. §14.

---

## 0. Fixed independently of the redesign

**`restart_journey()` lets one person reopen an ended Journey alone, and deletes the history that justified ending it.**

It requires only: the match is ended, 24 hours have passed, and neither party has another active Journey. **It never asks the other person.** It then deletes from six tables — `journey_compatibility`, `journey_salams`, `journey_phase_answers`, `journey_phase_ratings`, `journey_phase_checkpoints`, `journey_family_answers` — before setting the Journey active again.

Someone who ended a Journey can find themselves back inside an Active Journey they never re-consented to, with the record wiped.

**Second defect in the same function**, found while verifying:

```sql
UPDATE conversations SET status = 'closed', closed_at = NULL WHERE match_id = p_match_id;
```

It marks the conversation *closed* while clearing the timestamp recording when it closed. Restarting a Journey should not close its conversation. `'active'` was almost certainly intended. Fix in the same pass.

---

## 1. What is actually built today

| Believed | Actually |
|---|---|
| Four lifecycle states | **Three.** `suspend_journey()` never sets `status='paused'` — it writes `suspended_by` and `suspended_at` and leaves the status `active`. The `paused` value is unreachable. |
| `status` is an enum | **A TEXT column with a CHECK constraint** (`potential · active · paused · ended`). |
| Pausing is a lifecycle stage | A flag on an Active Journey. The implementation already decided this; the documents had not caught up. |
| Ending records why | It records only `ended_at`. No `ended_by`, no reason. **A mutual, respectful ending and someone fleeing a frightening situation are indistinguishable in the data.** |
| One Active Journey per person is enforced by the schema | **Not by the schema.** `matches_seeker_a_active` and `matches_seeker_b_active` are separate partial indexes, so one person can be `seeker_a` on one active match and `seeker_b` on another without violating either. The rule holds today only because every write path checks it. |

**What the schema already got right:** `matches` carries `CHECK (seeker_a_id < seeker_b_id)` and `UNIQUE (seeker_a_id, seeker_b_id)`. It is already a permanent, one-row-per-pair record. This architecture builds on that rather than replacing it.

---

## 2. The model

```
matches                    the pair. Permanent, one row per two people. Already exists.
  └── journey_attempts     one row per attempt. Potential → Active → Ended.
        ├── timelines
        ├── conversations
        └── journey_* tables
```

**Users never see the word "Relationship."** Internally the pair is the parent object. Two people who ended a Journey after four days do not have a "relationship", and in this community that word carries weight a Guardian would read very differently from how we mean it.

| On the pair (`matches`) | On the attempt (`journey_attempts`) |
|---|---|
| the two people, `created_at` | `status` — potential / active / ended |
| protection holds *(§3)* | `journey_stage` |
| block relationship | `started_at`, `ended_at`, `ended_by`, `end_reason` |
| | `paused_by`, `paused_at` |
| | `reference_code` *(§12)* |

**Every Journey is an attempt from the start.** Attempt 1 exists the moment a Journey does. If there is never a second attempt nothing is wasted; if there is, no data has to be migrated at that moment.

### The three states

- **Potential** — you have matched; neither of you has begun.
- **Active** — underway. It may be *paused*, which is a flag on this state, not a state of its own.
- **Ended** — over, permanently. A future attempt is a new attempt, never a resurrection.

### How users see history

**Not "Attempt 1, 2, 3."** Numbering is technical and quietly shaming — "attempt" presupposes failure, and showing someone "your third attempt with Ahmed" turns a private history into a scoreboard. Numbering is for the database.

Users see **time**: *Journey with Ahmed · June – August 2026*. In most places, **one line rather than a list**: *"You and Ahmed had a Journey together, ended August."* Expandable on request.

There is no "Successful" state. A Journey leading to nikah is *complete*, not scored. ZYRA does not grade marriages.

---

## 3. Protection: holds, not a state

Protection is the result of one or more active holds. A single value breaks the first time two coexist: B safety-locks after ending, *and* moderation locks the pair over an unrelated report against A. The moderator lock is overturned on appeal — a single enum must somehow fall back to `safety_locked`, meaning it was stored elsewhere anyway, or B's protection silently evaporates through an appeal she was never party to.

**`protection_holds`**, one row per hold:

| Column | |
|---|---|
| `match_id` | the pair |
| `hold_type` | `safety` · `moderator` |
| `held_by` | the person, or the moderator |
| `created_at`, `released_at` | `released_at IS NULL` means active |
| `reason_ref` | pointer to the ending or the moderation case |

Current protection = the strongest active hold, computed. Holds coexist; appeals release one without touching another; governance falls out of the model; **and the table is its own audit log.**

### Governance

| Hold | Placed by | Released by | Duration | Appealable |
|---|---|---|---|---|
| `safety` | the person who ended citing safety | **only that person**, or support at their request | until released | **No** |
| `moderator` | moderation | moderation | indefinite | Yes, defined route |

**A safety hold can never be appealed, because the barred person must never learn it exists.** They see no option to request a new Journey and no explanation. The moment an appeal route exists, the hold becomes visible — and a visible safety hold is a provocation aimed at the person it protects. Appeals belong to `moderator` holds only, where the platform, not a frightened user, is the counterparty.

**Blocking stays in `profile_blocks`.** It is mutual invisibility, not a Journey rule.

---

## 4. One visibility function

Fifteen RLS policies currently reach the pair through `match_id`, each re-deriving the same authorisation question. All fifteen are being touched by this migration anyway.

**Point them at `attempt_visible_to(attempt_id, auth.uid())` rather than at new inline SQL.**

Adding a mediator, family member or mosque representative later becomes one function change instead of fifteen policy rewrites. At five roles, inline SQL is seventy-five policies re-deriving the same logic.

**Free only if done during this migration.**

> **Live precedent.** The `profile-photos` storage read policy resolved visibility through an RLS-bound subquery on `profiles`, so photo readability silently inherited the gender rule of whoever *uploaded* each file. It emptied Browse, broke Guardian Suggestion photos, and white-screened "View profile" — diagnosed and fixed 2026-08-05. Duplicated authorisation logic fails quietly and expensively.

---

## 5. Data classification — before the migration

V2's predecessor claimed shared attempt objects make GDPR easier. **True for erasure, false for access.**

An attempt is a *shared* object. When Person A files a subject access request, that object contains B's end reason, B's Guardian's identity, B's phase answers. Someone must read nine tables and decide line by line what belongs to whom, under a 30-day statutory clock.

**Classify every column on the attempt tables as `mine` / `theirs` / `joint` at migration time.** The export then becomes mechanical. Done later, it is a solicitor doing it by hand.

Governance, not implementation. Settle it **before** the migration begins.

---

## 6. Audit logging — scoped deliberately

Full event sourcing is not justified. But `ended_by` and `end_reason` are *state*, not history.

**Log what you would need to defend, not everything.** Append-only, four event types: protection holds placed and released; moderator actions; appeal outcomes; safety-flagged endings. Anything that could reach a solicitor or Ofcom. Everything else remains current state.

---

## 7. Pausing — **Founder amendment, 2026-08-06**

> **Founder decision:** *"I do not approve making Pause free. I understand and respect the reasoning presented, but at this stage I want Pause to remain a premium capability. We can revisit that decision after beta if real user behaviour suggests it should change."*

Pause remains a **ZYRA One** capability. Our joint recommendation to make it free is not carried forward.

This is recorded as a reversal of a joint recommendation, not as a disagreement — but it does change the rule, because V2 §7 read *"either person may pause"*, and that only holds if everyone can. The corrected rule:

### The rule

**Anyone may be affected by a pause. Only ZYRA One may initiate one.**

> ⚠️ **SUPERSEDED 2026-08-11 (DR-ZYRA-138).** The Founder reversed this
> amendment: BOTH plans may initiate a pause; the differentiator is the cap
> (5 Basic / 10 One, per the 2026-08-09 entitlements matrix), counted over
> pauses the caller initiated and enforced server-side
> (`paused_limit_reached`; `suspension_requires_one` retired). The paragraph
> above is preserved as the historical record of the earlier amendment.
> Authority: JOURNEY_SUSPENSION_CURRENT_VERSION_V2.md.

- A ZYRA One Seeker may pause an Active Journey at any time.
- A ZYRA Basic Seeker cannot initiate a pause, but is fully subject to one placed by the other party.
- **The Journey is paused while any pause is active, and resumes when every pause has been lifted.**
- **Only the person who placed a pause may lift it.** Nobody can lift someone else's.

The existing slot behaviour in `JOURNEY_SUSPENSION_CURRENT_VERSION_V1` §5.1–5.3 is sound and carries forward unchanged — a Basic Seeker's slot is freed immediately when the other party pauses, so they are never locked out by a decision they could not have taken. That reasoning is correct and this document does not disturb it.

### One conflict that must be resolved

`JOURNEY_SUSPENSION_CURRENT_VERSION_V1` §5.3 specifies a **30-day Full Suspension auto-End timer**. That contradicts the approved principle that **ZYRA never automatically ends a Journey** (§16, item 12). The approved model is: reminders at 30 and 90 days, then leave it paused indefinitely. The platform reminds; the people decide.

**The auto-End timer must be removed.** Recorded as OA-ZYRA-164.

### No automatic expiry, ever

A check-in at 30 days (*"Are you still intentionally paused?"*) and again at 90 (*"Would you like to resume or end this?"*), then indefinite. Expected return dates optional and never binding — a date you cannot meet becomes a second failure.

---

## 7A. Guardrails that premium gating now requires

These are not a re-argument of the Founder's decision. They are the conditions under which gating Pause stays safe and stays consistent with rules ZYRA has already approved elsewhere.

**1. Ending is always free, for everyone, always.**
Nobody may ever need to pay to leave a Journey. This is the load-bearing one. The concern behind our original recommendation was that someone who cannot pause will end or ghost instead — and if ending is free, dignified, and clearly offered, that outcome is survivable. If ending were ever gated, it would not be.

**2. No upgrade prompt on the received-pause screen.**
A Basic Seeker whose Journey has been paused by the other party must not be shown *"Upgrade to ZYRA One"* on that screen. Upgrading would not let them lift the other person's pause, so the prompt sells nothing it can deliver — and monetising the moment someone else acted on you is the precise pattern OA-ZYRA-152 and the DR-I test already flag ("a purchase may not sell relief from a restriction ZYRA imposes"). The screen states what happened, what their options are, and stops.

**3. The received-pause screen offers exactly two actions: wait, or end.**
Both free. Both plainly worded. No third path that costs money.

**4. Pause is never described as a way to hold someone.**
Marketing copy for ZYRA One may describe Pause as stepping back for exams, istikharah, family discussion, illness or travel. It must not be positioned as reserving a person or securing a slot.

---

## 8. Ending

**Every ending records who, when and why.**

Reasons: *not compatible · circumstances changed · marrying elsewhere · family decision · safety concern · I'd rather not say* — plus an optional free-text *"Anything you'd like them to know?"*

Six, deliberately. **Long lists at painful moments produce whichever option is least awkward, not the true one.**

### Considered and rejected

| Proposed | Why not |
|---|---|
| No response / ghosting | The person who ghosts never opens the dropdown. **System-detected** — `ended_by: system` after N days — not a chosen reason. |
| Mutual decision | Unverifiable from one person's tap, and it invites the ender to soften their own account. |
| Personal readiness / life priorities | Both are "circumstances changed" wearing different coats. |
| Religious incompatibility | Analytically the most valuable, and still no. It invites one Muslim to formally record a judgement about another's deen — heavier than a product taxonomy should casually enable. It stays inside "not compatible". |

**Do not tax a person at an emotional moment for insight you can compute.** Stage-at-end, duration, who ended, and whether a report exists give most of the analytics for free.

### Two rules

1. **Only "safety concern" is hidden from the other party.** A stated reason is kinder than silence.
2. **A safety ending places a `safety` hold on the pair.** The other party is never told why a new Journey is unavailable; they simply never see the option.

---

## 9. Starting again

**"Request New Journey", not "Restart".** One person requests; the other decides. Never unilateral, never a resurrection.

| | |
|---|---|
| Options | **Accept · Decline · Decline and don't ask again** |
| After a plain decline | 6-month cooldown *(number to revisit post-launch — §16)* |
| After "don't ask again" | Permanent |
| **What the requester sees** | **Identical in both cases: no option to request.** Never told which. |
| Unanswered | Expires after 14 days; expiry counts as a decline for cooldown |

If "don't ask again" were visible it would become information about the recipient's feelings and an invitation to react. And silence is an answer — forcing a response is its own small coercion.

**Nothing is ever deleted.** Deletion destroys exactly the evidence a Guardian or moderator would need if a pattern emerges, and makes GDPR erasure *harder* — erasing one whole attempt object is cleaner than half-wiping shared rows.

---

## 10. Guardians

The Guardian **must** know it is a repeat. Not telling them makes the role decorative.

But **the Guardian may not be the same person** — the first attempt's Guardian could be her father, the second's her brother. So:

- Guardian involvement is recorded **per attempt**, not per pair.
- A **new** Guardian sees *that* a previous Journey existed and how it ended — but **never inherits the previous Guardian's notes or conversations.** Those were one person's private observations; handing them to a different family member is a disclosure nobody consented to.
- The **same** Guardian returning keeps their own history.
- **Family Review runs fresh every attempt.** A family's blessing for the first Journey is not blessing for the second.

---

## 11. Notifications

**Separate "visible in-app" from "pushes."** Almost everything should be visible; very few should push. Without that distinction one Journey generates ten notifications and people disable all of them, including the ones that matter.

**Guardians get a digest, not a stream.** Push only for endings and accepted requests. A Guardian receiving live pings is surveillance regardless of what the permission model calls it.

| Event | Other Seeker | Own Guardian | Their Guardian |
|---|---|---|---|
| Pause | in-app, no push | digest | — |
| Resume | push | digest | — |
| End — ordinary | push, with reason | push | push |
| End — safety | push, **worded identically to ordinary** | push, **no reason** | push, no reason |
| Request New Journey | push | digest | — |
| Accept | push | push | push |
| Decline | push | — | — |
| Protection hold placed | **nothing, ever** | — | — |
| Moderator action | affected party only | — | — |
| Family Review begins | push | push | push |

**Safety endings are disclosed to nobody automatically — including the ender's own Guardian.** If a woman ends a Journey because she felt unsafe, that is hers to tell her family, in her words, at her timing. Automatically routing *"she reported feeling unsafe"* to a male relative is fine in most households and dangerous in a minority, and ZYRA cannot tell which it is looking at. Her Guardian is told the Journey ended. Moderation sees the reason.

**Decline gets a real notification.** Hiding it behind the 14-day expiry would mean fourteen days of hope for something already answered. What needs protecting is *which kind* of decline, not *that* one happened.

---

## 12. Reference codes

**Opaque, never sequential.** "Journey Attempt #3" reintroduces the numbering §2 rejects, and a support agent reading "#3" forms a judgement before reading the case. Use a short opaque code, avoiding characters that collapse when typed or read aloud (`0/O`, `1/I/l`).

**One code per person, per attempt — not one shared code.** An attempt is a shared object; a reference to it must not be. With a single shared code, either party can quote the other's case identifier, a code shown to a third party becomes evidence of a connection, and in a safety case the protected person's report and the barred person's enquiry share a key.

Two codes resolving to the same attempt server-side give moderation everything and give neither party a handle on the other.

**Generate at attempt creation.** **Show on request, not by default** — a reference code sitting permanently on a Journey card is a quiet reminder that this is a case file.

---

## 13. Guardian and Seeker documentation impact

The following approved documents are contradicted by this architecture and must be updated before or alongside the build. Listed so the conflicts are recorded rather than discovered mid-implementation.

| Document | Conflict |
|---|---|
| `APP/Journey/JOURNEY SUSPENSION/JOURNEY_SUSPENSION_CURRENT_VERSION_V1.md` | §5.3 30-day Full Suspension **auto-End timer** contradicts "no automatic ending, ever". Terminology throughout is Suspension, not Pause. |
| `APP/Journey/JOURNEY MANAGEMENT/Summary.md` | Describes Restart, not Request New Journey. |
| `APP/Journey/JOURNEY AVAILABILITY/Summary.md` | Slot semantics need restating against `journey_attempts`. |
| `APP/Standards/WALI_ARCHITECTURE_CURRENT_VERSION_V6.md` | Guardian involvement is now per-attempt, with no inheritance of a previous Guardian's notes. |
| `SYSTEM/DOCUMENTS/ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V5.md` | Journey lifecycle section describes the four-state model. |

---

## 14. What this costs — and why now

**Nine tables key off `match_id`** and move to `attempt_id`:

`conversations · journey_compatibility · journey_family_answers · journey_family_reviews · journey_phase_answers · journey_phase_checkpoints · journey_phase_ratings · journey_salams · timelines`

They carry **15 RLS policies**, each reaching the pair through `match_id`. That re-pointing is the real work — not the idea.

**And every one of those tables is empty.** Verified 2026-08-06: `matches` 0 rows, and 0 rows in all nine dependants.

**There is no data migration. Only DDL and code.** Every day of real usage after launch adds rows, live sessions and backfill risk to a change whose cost today is bounded and testable.

**Two fixes that come free:** the one-Active-Journey rule becomes enforceable in the schema rather than depending on every write path remembering; and the unreachable `paused` value leaves the CHECK constraint.

---

## 15. Sequence

1. **Now, independent of everything:** fix `restart_journey()` — mutual consent, no deletions, and the `conversations` status bug. *(OA-ZYRA-154)*
2. **Before the migration begins:** classify attempt-table columns `mine` / `theirs` / `joint`. *(OA-ZYRA-155)*
3. **Small and independently valuable:** add `ended_by` / `end_reason`; remove the dead `paused` value; remove the auto-End timer. *(OA-ZYRA-158, OA-ZYRA-164)*
4. **The restructure:** `journey_attempts`, `protection_holds`, `attempt_visible_to()`, reference codes, Request New Journey. *(OA-ZYRA-156, 157, 159, 160)*
5. **Behaviour:** notifications, Guardian rules, audit log. *(OA-ZYRA-161, 162, 163)*
6. **Beta instrumentation** for the Pause revisit. *(OA-ZYRA-165)*

---

## 16. Approval status

### Approved — build

| # | Item | OA |
|---|---|---|
| 1 | Fix `restart_journey()` — mutual consent, no deletions | 154 |
| 2 | Field classification `mine` / `theirs` / `joint` before migration | 155 |
| 3 | `journey_attempts` beneath `matches` | 156 |
| 4 | `attempt_visible_to()` as the single authorisation helper | 156 |
| 5 | `protection_holds` as a table, with §3 governance | 157 |
| 6 | `ended_by`, `ended_at`, `end_reason` + the six reasons | 158 |
| 7 | Request New Journey — mutual consent, cooldowns, hidden decline type | 159 |
| 8 | Per-person opaque reference codes | 160 |
| 9 | Notification principles, including the two safety rules | 161 |
| 10 | Guardian per-attempt behaviour; fresh Family Review each attempt | 162 |
| 11 | Append-only audit log — protection, moderation, appeals, safety endings | 163 |
| 12 | No automatic ending, ever; reminders at 30 and 90 days | 164 |
| 13 | Preserve all Journey history — nothing deleted on a new attempt | 156 |

### Amended by the Founder

| Item | Our recommendation | Founder decision |
|---|---|---|
| Pause pricing | Free for all Seekers | **Remains a ZYRA One capability.** Revisit after beta on evidence. §7, guardrails §7A, instrumentation OA-ZYRA-165. |

### Open — better answered by real usage

| # | Question |
|---|---|
| 14 | Cooldown length after a plain decline. 6 months is a guess. |
| 15 | Request expiry window. 14 days is a guess. |
| 16 | Pause reminder cadence. 30/90 is a guess. |
| 17 | Guardian digest frequency — daily or weekly. |
| 18 | Whether "don't ask again" is used enough to justify maintaining it separately from a long cooldown. |
| 19 | **Whether Pause should become free.** Instrumented, not argued — OA-ZYRA-165. |

These are cheap to change once real people are using the product and expensive to get right by argument. Recorded honestly as unanswered rather than presented as design.

---

## What we are NOT recommending

- **Mosque representative accounts.** The participant scope in §4 makes them possible later. Designing the role now puts an institution inside a private matrimonial process and raises questions nobody has answered: who accredits them, what happens when one behaves badly, whether ZYRA then carries that mosque's reputation.
- **Family accounts without a cap.** Four relatives each holding Guardian-level visibility is surveillance by volume. If built: cap it, and make the Seeker the only person who can grant access. A family member must never be able to add another.
- **Full event sourcing.** §6.

---

*Agreed jointly by Fable and ChatGPT after four rounds of review; approved by the Founder 2026-08-06 with the Pause amendment at §7. Where V1 or V2 disagree with this document, this document governs.*

*End of Document*
