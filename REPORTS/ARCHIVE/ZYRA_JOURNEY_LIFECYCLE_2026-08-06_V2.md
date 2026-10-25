# ZYRA — Journey Lifecycle Architecture

**Document:** ZYRA_JOURNEY_LIFECYCLE_CURRENT_VERSION_V2.md
**Supersedes:** ZYRA_JOURNEY_LIFECYCLE_RECOMMENDATION_2026-08-06_V1.md *(archived — reference only)*
**From:** Fable (UX & Product Experience Lead) and ChatGPT (Strategic Review) — a single agreed position
**Date:** 2026-08-06
**Status:** PROPOSED — for Founder decision
**Method:** Every claim about current behaviour was read from the live database on 2026-08-06, not from the specifications. The two have drifted, and where they disagree this document follows the database.

---

## Summary for the Founder

Three things, in order of urgency:

1. **One function is unsafe today and should be fixed this week regardless of everything else below.** A person who ended a Journey — possibly because they felt unsafe — can be pulled back into it by the other party alone, with the evidence deleted. §0.
2. **The Journey model needs one structural change**, from "a match that reopens" to "a pair that can have several attempts". §2.
3. **That change is free right now and will never be this cheap again.** All ten Journey tables contain zero rows. This is a code migration with no data migration. §13.

Everything else is detail supporting those three.

---

## 0. Fix this regardless of the rest

**`restart_journey()` lets one person reopen an ended Journey alone, and deletes the history that justified ending it.**

Read from the live function today. It requires only: the match is ended, 24 hours have passed, and neither party has another active Journey. **It never asks the other person.** It then deletes from six tables — `journey_compatibility`, `journey_salams`, `journey_phase_answers`, `journey_phase_ratings`, `journey_phase_checkpoints`, `journey_family_answers` — before setting the Journey active again.

So someone who ended a Journey can find themselves back inside an Active Journey they never re-consented to, with the record wiped.

Treat this as a **standalone engineering fix, not part of the redesign.** Minimum: require both parties to agree, and stop the deletions.

**Also found while verifying, and worth a separate line:** the same function ends with

```sql
UPDATE conversations SET status = 'closed', closed_at = NULL WHERE match_id = p_match_id;
```

It marks the conversation *closed* while clearing the timestamp that records when it closed. Restarting a Journey should not close its conversation. This looks like `'active'` was intended. Small, but it is in the same function and should be fixed in the same pass.

---

## 1. What is actually built today

| Believed | Actually |
|---|---|
| Four lifecycle states: potential / active / paused / ended | **Three.** `suspend_journey()` never sets `status='paused'` — it writes `suspended_by` and `suspended_at` and leaves the status `active`. The `paused` value is unreachable. |
| `status` is an enum | **It is a TEXT column with a CHECK constraint** (`potential · active · paused · ended`). Minor, but it changes how the dead value is removed. *(V1 said "enum". Corrected.)* |
| Pausing is a lifecycle stage | It is a flag on an Active Journey. The implementation already decided this; the documents have not caught up. |
| Ending records why | It records only `ended_at`. There is no `ended_by` and no reason. **A mutual, respectful ending and someone fleeing a frightening situation are indistinguishable in the data.** |
| One Active Journey per person is enforced by the schema | **Not by the schema.** `matches_seeker_a_active` and `matches_seeker_b_active` are two separate partial indexes, so one person can be `seeker_a` on one active match and `seeker_b` on another without violating either. *(The rule is enforced correctly inside `restart_journey()` and `promote_journey_to_active()` — so it holds in practice today, but only because every write path happens to check it.)* |
| Pausing is a normal user action | It requires ZYRA One. `suspend_journey()` raises `suspension_requires_one` otherwise. |

**What the schema already got right**, and which shapes everything below: `matches` carries `CHECK (seeker_a_id < seeker_b_id)` and `UNIQUE (seeker_a_id, seeker_b_id)`. It is already a permanent, one-row-per-pair record. This proposal builds on that rather than replacing it.

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

### Where each fact lives

| On the pair (`matches`) | On the attempt (`journey_attempts`) |
|---|---|
| the two people, `created_at` | `status` — potential / active / ended |
| protection holds *(§3)* | `journey_stage` |
| block relationship | `started_at`, `ended_at` |
| | `ended_by`, `end_reason` |
| | `paused_by`, `paused_at` |
| | `reference_code` *(§12)* |

**Every Journey is an attempt from the start.** Attempt 1 exists the moment a Journey does, not lazily on first restart. If there is never a second attempt, nothing is wasted. If there is, no data has to be migrated at that moment.

### The three states, plainly

- **Potential** — you have matched; neither of you has begun.
- **Active** — the Journey is underway. It may be *paused*, which is a flag on this state, not a state of its own.
- **Ended** — this attempt is over, permanently. A future attempt is a new attempt, never a resurrection of this one.

### How users see history

**Not "Attempt 1, 2, 3."** Numbering is technical and quietly shaming — "attempt" presupposes failure, and showing someone "your third attempt with Ahmed" turns a private history into a scoreboard. Numbering is for the database.

Users see **time**:

> Journey with Ahmed · June – August 2026
> Journey with Ahmed · began January 2027

And in most places, **one line rather than a list**: *"You and Ahmed had a Journey together, ended August."* Expandable if they want detail.

There is also no "Successful" state. A Journey that leads to nikah is *complete*, not scored. ZYRA does not grade marriages.

---

## 3. Protection: holds, not a state

Protection is **not a state**. It is the result of one or more active holds — and modelling it as a single value breaks the first time two holds coexist.

The failing case: B safety-locks after ending, *and* moderation locks the pair over an unrelated report against A. The moderator lock is overturned on appeal. A single enum must somehow fall back to `safety_locked` — meaning it was stored elsewhere anyway, or B's protection silently evaporates through an appeal she was never party to.

So: **`protection_holds`**, one row per hold.

| Column | |
|---|---|
| `match_id` | the pair |
| `hold_type` | `safety` · `moderator` |
| `held_by` | the person, or the moderator |
| `created_at`, `released_at` | `released_at IS NULL` means active |
| `reason_ref` | pointer to the ending or the moderation case |

Current protection = the strongest active hold, computed. This solves four things at once: holds coexist; appeals release one without touching another; governance falls out of the model (*"who can remove it"* is simply *"who holds it"*); and **the table is its own audit log**.

### Governance

| Hold | Placed by | Released by | Default duration | Appealable |
|---|---|---|---|---|
| `safety` | the person who ended citing safety | **only that person**, or support at their request | until released | **No — see below** |
| `moderator` | moderation | moderation | indefinite | Yes, defined route |

**A safety hold can never be appealed, because the barred person must never learn it exists.** They see no option to request a new Journey and no explanation. The moment an appeal route exists, the hold becomes visible, and a visible safety hold is a provocation aimed at the person it protects. Appeals belong to `moderator` holds only, where the platform — not a frightened user — is the counterparty.

**Blocking stays where it is,** in `profile_blocks`. It is mutual invisibility, not a Journey rule, and it already has its own table. *(V1 put `blocked` in the protection enum. Corrected.)*

---

## 4. One visibility function, decided now

Fifteen RLS policies currently reach the pair through `match_id`, each re-deriving the same authorisation question independently. All fifteen are being touched by this migration anyway.

**Point them at a helper — `attempt_visible_to(attempt_id, auth.uid())` — rather than at new inline SQL.**

Adding a mediator, a family member or a mosque representative in 2029 then becomes one function change instead of fifteen policy rewrites. At five roles, inline SQL is seventy-five policies each re-deriving the same logic.

This is **free only if done during this migration**, which makes it the highest-leverage decision in the document.

*(There is a live precedent for getting this wrong. The `profile-photos` storage read policy resolved visibility through an RLS-bound subquery on `profiles`, so photo readability silently inherited the gender rule of whoever uploaded the file. It emptied Browse for weeks and was diagnosed on 2026-08-05. Duplicated authorisation logic fails quietly.)*

---

## 5. Data classification — do it before the migration, not after

V1 claimed that shared attempt objects make GDPR easier. **That is true for erasure and false for access, and we did not notice because we only thought about Article 17.**

An attempt is a *shared* object. When Person A files a subject access request, that object contains B's end reason, B's Guardian's identity, B's phase answers. Shared objects make SARs **harder** — someone must read nine tables and decide line by line what belongs to whom, under a 30-day statutory clock.

**Classify every column on the attempt tables as `mine` / `theirs` / `joint` at migration time.** The SAR export then becomes mechanical. Done later, it is a solicitor doing it by hand.

This is governance, not implementation, and should be settled **before** the migration begins.

---

## 6. Audit logging — scoped deliberately

Full event sourcing is not justified for a pre-launch app and we both resist it. But `ended_by` and `end_reason` are *state*, not history, and some changes cannot be reconstructed after the fact.

**The discipline: log what you would need to defend, not everything.** Append-only, four event types:

- protection holds placed and released *(already covered by `protection_holds` in §3)*
- moderator actions
- appeal outcomes
- safety-flagged endings

Anything that could end up in front of a solicitor or Ofcom. Everything else remains current state.

---

## 7. Pausing

**Free for everyone.** This is the one recommendation that reverses a previously approved decision, and we both think it should change.

Pausing exists for exams, istikharah, family discussions, illness and travel. Charging someone to step back from a marriage process during illness or istikharah is a values problem before it is a pricing one — and it creates the wrong incentive: someone who cannot pay ends the Journey instead, or ghosts. Premium should differ on **capacity** — additional Journey capacity, longer retention, priority workflow — not on the right to step away.

**Either person may pause. The Journey is paused while anyone has it paused, and resumes when everyone has resumed.** That one sentence replaces the current Peer-Suspended / Full Suspension matrix, whose sub-states derive from plan combinations. Same outcomes; users can hold this version in their heads.

**No automatic expiry, ever.** ZYRA should never decide that a marriage prospect is over. A gentle check-in at 30 days (*"Are you still intentionally paused?"*) and again at 90 (*"Would you like to resume or end this?"*), then leave it paused indefinitely. The platform reminds; the people decide. Expected return dates optional and never binding — a date you cannot meet becomes a second failure.

---

## 8. Ending

**Every ending records who, when and why.**

Reasons offered: *not compatible · circumstances changed · marrying elsewhere · family decision · safety concern · I'd rather not say* — plus an optional free-text *"Anything you'd like them to know?"*

Six, deliberately. **Long lists at painful moments produce whichever option is least awkward, not the true one.** The optional sentence will outperform a twelve-item taxonomy for both kindness and data quality.

### What we considered and rejected

| Proposed | Why not |
|---|---|
| No response / ghosting | The person who ghosts never opens the dropdown. This is a **system-detected** ending — `ended_by: system` after N days — not a reason someone chooses. Real, but a different field. |
| Mutual decision | Unverifiable from one person's tap, and it invites the ender to soften their own account. Either both confirm — making it a flow, not a reason — or it isn't offered. |
| Personal readiness / life priorities | Both are "circumstances changed" wearing different coats. |
| Religious incompatibility | Analytically ZYRA's most valuable reason, and still no. Offering it as a button invites one Muslim to formally record a judgement about another's deen — a heavier act in this community than a product taxonomy should casually enable. It stays inside "not compatible". |

**The principle: do not tax a person at an emotional moment for insight you can compute.** Stage-at-end, duration, who ended, and whether a report exists give most of the analytics for free.

### Two rules

1. **Only "safety concern" is hidden from the other party.** The rest are shown — a stated reason is kinder than silence, and this audience deserves that.
2. **A safety ending places a `safety` hold on the pair.** The other party is never told why a new Journey is unavailable; they simply never see the option.

---

## 9. Starting again

**"Request New Journey", not "Restart".** One person requests; the other decides. Never unilateral, never a resurrection — a new attempt starts fresh with its own timeline.

| | |
|---|---|
| Options | **Accept · Decline · Decline and don't ask again** |
| After a plain decline | 6-month cooldown *(number to revisit post-launch — §15)* |
| After "don't ask again" | Permanent |
| **What the requester sees** | **Identical in both cases: no option to request.** They are never told which. |
| Unanswered | Expires after 14 days; expiry counts as a decline for cooldown purposes |

The hidden distinction matters. If "don't ask again" were visible, it would become information about the recipient's feelings and an invitation to react. And silence is an answer — forcing a response is its own small coercion.

**Nothing is ever deleted.** Previous attempts remain in full. Deletion destroys exactly the evidence a Guardian or moderator would need if a pattern emerges, and it makes GDPR erasure *harder*, not easier — erasing one whole attempt object is cleaner than half-wiping shared rows.

---

## 10. Guardians

The Guardian **must** know it is a repeat. Not telling them makes the role decorative, and *"you supported this Journey before"* is exactly the context a guardian needs.

But **the Guardian may not be the same person.** The first attempt's Guardian could be her father; the second's could be her brother. So:

- Guardian involvement is recorded **per attempt**, not per pair.
- A **new** Guardian sees *that* a previous Journey existed and how it ended — but **never inherits the previous Guardian's notes or conversations.** Those were one person's private observations; handing them to a different family member is a disclosure nobody consented to.
- The **same** Guardian returning keeps their own history, because it is theirs.
- **Family Review runs fresh every attempt.** A family's blessing for the first Journey is not blessing for the second. We treat this as non-negotiable.

---

## 11. Notifications

Two structural rules first.

**Separate "visible in-app" from "pushes."** Almost everything here should be visible; very few should push. Without that distinction one Journey generates ten notifications and people disable all of them, including the ones that matter.

**Guardians get a digest, not a stream.** Push only for endings and accepted requests. A Guardian receiving live pings as a Journey moves is surveillance regardless of what the permission model calls it — this is *"guidance, not surveillance"* made operational.

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

**Two rows need defending.**

**Safety endings are disclosed to nobody automatically — including the ender's own Guardian.** If a woman ends a Journey because she felt unsafe, that is hers to tell her family, in her words, at her timing. Automatically routing *"she reported feeling unsafe"* to a male relative is fine in most households and dangerous in a minority, and ZYRA cannot tell which one it is looking at. Her Guardian is told the Journey ended. Moderation sees the reason. Nobody else does.

**Decline gets a real notification.** We considered hiding it behind the 14-day expiry to protect the plain/permanent distinction, and rejected that: it means fourteen days of hope for something already answered. What needs protecting is *which kind* of decline, not *that* one happened. Being declined is survivable; being strung along is not.

---

## 12. Reference codes

A per-attempt reference for support and moderation is worth building. Two constraints, both load-bearing.

**Opaque, never sequential.** "Journey Attempt #3" reintroduces through the back door exactly the numbering §2 rejects — and a support agent reading "#3" forms a judgement before reading the case. Use a short opaque code, avoiding characters that collapse when typed or read aloud (`0/O`, `1/I/l`).

**One code per person, per attempt — not one shared code.** An attempt is a shared object; a shared code is not. If both parties hold the same reference:

- either can quote the other's case identifier,
- a code shared with a third party becomes evidence of a connection,
- and in a safety case, the protected person's report and the barred person's enquiry share a key — which risks the barred person learning something.

Two codes resolving to the same attempt server-side gives moderation everything it needs and gives neither party a handle on the other.

**Generate at attempt creation**, so it exists in the audit trail from the first moment. **Show it on request, not by default** — a reference code sitting permanently on a Journey card is a quiet reminder that this is a case file.

---

## 13. What this costs — and why now is the cheapest it will ever be

**Nine tables key off `match_id` today** and would move to `attempt_id`:

`conversations · journey_compatibility · journey_family_answers · journey_family_reviews · journey_phase_answers · journey_phase_checkpoints · journey_phase_ratings · journey_salams · timelines`

They carry **15 RLS policies** between them, each reaching the pair through `match_id`. That re-pointing is the real work in this proposal — not the idea.

**And every one of those tables is currently empty.**

| Table | Rows |
|---|---|
| `matches` | 0 |
| `conversations` · `timelines` · `journey_compatibility` · `journey_salams` | 0 |
| `journey_phase_answers` · `journey_phase_ratings` · `journey_phase_checkpoints` | 0 |
| `journey_family_answers` · `journey_family_reviews` | 0 |

**There is no data migration. Only DDL and code.** Every day of real usage after launch adds rows, live sessions, and backfill risk to a change whose cost today is bounded and testable. This is the single strongest argument for deciding now rather than after beta.

**Two things the restructure fixes for free**, worth counting as benefits rather than scope:

- The one-Active-Journey rule becomes enforceable in the schema, instead of depending on every write path remembering to check.
- The unreachable `paused` value disappears from the CHECK constraint, so the schema stops describing a state that never occurs.

---

## 14. Recommended sequence

1. **Now, independent of everything else:** fix `restart_journey()` — mutual consent, no deletions, and the `conversations` status bug. *(§0)*
2. **Before the migration begins:** classify attempt-table columns `mine` / `theirs` / `joint`. *(§5)*
3. **Small and independently valuable:** add `ended_by` and `end_reason`; remove the dead `paused` value; make Pause free.
4. **The restructure:** `journey_attempts`, `protection_holds`, `attempt_visible_to()`, reference codes, "Request New Journey". One considered piece of work with its own Decision Record.

---

## 15. Decisions, in three tiers

### Must decide before build

| # | Decision |
|---|---|
| 1 | Fix `restart_journey()` — mutual consent, no deletions. **We recommend yes regardless of everything else.** |
| 2 | Approve `journey_attempts` beneath `matches`, accepting the nine-table, fifteen-policy re-pointing — while all ten tables are still empty. |
| 3 | Approve `protection_holds` as a table rather than a status field, with the governance in §3. |
| 4 | Approve `attempt_visible_to()` as the single authorisation helper. Free now; five times the work later. |
| 5 | Approve field classification `mine` / `theirs` / `joint` before migration. |
| 6 | **Reverses an approved decision:** make Pause free for all Seekers; move the premium difference to capacity. |
| 7 | Approve per-person opaque reference codes, generated at attempt creation. |

### Should decide before beta

| # | Decision |
|---|---|
| 8 | The six end reasons and the rule that only "safety concern" is hidden. |
| 9 | The notification map — in-app vs push, and the two safety rules in §11. |
| 10 | Guardian rules: per-attempt history, no inheritance of a previous Guardian's notes, fresh Family Review every attempt. |
| 11 | Append-only audit scope: protection, moderation, appeals, safety endings. |
| 12 | Reminders at 30 and 90 days, and no automatic ending, ever. |

### Better answered by real usage — do not force now

| # | Open question |
|---|---|
| 13 | Cooldown length after a plain decline. 6 months is a guess. |
| 14 | Request expiry window. 14 days is a guess. |
| 15 | Pause reminder cadence. 30/90 is a guess. |
| 16 | Guardian digest frequency — daily or weekly. |
| 17 | Whether "don't ask again" is used enough to justify maintaining it separately from a long cooldown. |

Items 13–17 are cheap to change once real people are using the product and expensive to get right by argument. We would rather mark them honestly as unanswered than present guesses as design.

---

## What we are NOT recommending

- **Mosque representative accounts.** The participant *scope* in §4 makes them possible later. Designing the role now puts an institution inside a private matrimonial process and raises questions nobody has answered: who accredits them, what happens when one behaves badly, whether ZYRA then carries that mosque's reputation. A business decision with architectural consequences, not a feature to build speculatively.
- **Family accounts without a cap.** Four relatives each holding Guardian-level visibility is surveillance by volume, even where every individual permission is legitimate. If built: cap it, and make the Seeker the only person who can grant access. A family member must never be able to add another family member.
- **Full event sourcing.** §6.

---

*Agreed jointly by Fable and ChatGPT, 2026-08-06, after four rounds of review. No dissent between us on any point above. Where V1 and this document disagree, V1 is wrong — the corrections are marked in §1, §3 and §5.*

*End of Document*
