---
id: DOC-ZYRA-0222
type: PLAN
status: CURRENT
feature: JOURNEY
purpose: ZYRA — Step 1b plan: blocking ends the Journey
links: []
owner: ZYRA chat
---

# ZYRA — Step 1b plan: blocking ends the Journey

**Status:** PLAN ONLY — not applied. For approval.
**Date:** 2026-08-08

Your six decisions are taken as settled. This is how they land, plus **two
traps** the investigation found that would have defeated the Step 0 privacy
model if built naively.

---

## 1. Trap one · `ended_by` is the tell

Step 0 makes `end_reason` private and substitutes `prefer_not_to_say`. That
works only if a block-ending is otherwise **indistinguishable** from an
ordinary one.

It would not be. Here is what each writes today:

| | `status` | `ended_at` | `ended_by` | `end_reason` |
|---|---|---|---|---|
| Ordinary `end_journey()` | ended | set | **NULL** | **NULL** |
| Block-ending, as designed | ended | set | **the blocker** | safety_concern |

**`ended_by` is deliberately readable** — we kept it visible so the
substitution would look natural. But if ordinary endings leave it NULL and
block-endings populate it, then *"`ended_by` is not null"* means *"this was a
safety ending"*, and the substitution is worthless.

### Fix, and it is an improvement anyway

**`end_journey()` must also set `ended_by = caller`.** The ownership register
already says `ended_by` is joint — *"who ended it is knowable to both"* — so
it should always have been recorded. It simply never was, because the
ending-reason feature was never built.

After this, both kinds of ending populate `ended_by` and differ only in
`end_reason`, which is exactly the value the accessor conceals.

No constraint conflict: `matches_no_response_is_system` requires
`ended_by IS NULL` only when the reason is `no_response`, and neither path
writes that.

---

## 2. Trap two · Ending a Journey does NOT revoke Guardian visibility

You asked for *"all Journey-derived Guardian visibility revoked."*

After Step 1, clause 3 reads `me.attempt_status <> 'potential'`. An **ended**
attempt is not `potential`, so **Guardians keep seeing each other after a
Journey ends** — including after a block ends it.

### And the obvious block check does not fix it

The natural instinct is to add `not zyra_block_exists(p_target)` to clause 3.
That function compares `auth.uid()` against the target — so it catches the
two Seekers and **misses every Guardian**, because no Guardian is party to
the block row.

The block is between the two Seekers. The visibility being revoked belongs
to four people.

### The check has to be at the ATTEMPT level

> **If the two Seekers of an attempt have blocked each other, that attempt
> confers no visibility on anyone.**

```sql
and not exists (
  select 1
  from public.matches mm
  join public.profile_blocks b
    on (b.blocker_id = mm.seeker_a_id and b.blocked_id = mm.seeker_b_id)
    or (b.blocker_id = mm.seeker_b_id and b.blocked_id = mm.seeker_a_id)
  where mm.id = me.match_id
)
```

This is the half of Step 1b that actually delivers the revocation.

---

## 3. Blocking must become an RPC

`profile_blocks` currently grants **INSERT, UPDATE, DELETE to `anon` and
`authenticated`**, and the app writes it directly:

```dart
await supabase.from('profile_blocks').upsert(...)   // zyra_report_service.dart:109
```

If blocking stays a direct write, every atomic guarantee below is bypassable
by the code path the app already uses. Same lesson as `wali_links`.

---

## 4. The migration, as it would be applied

### 4.1 · `end_journey()` records who ended it

```sql
UPDATE matches SET status='ended', ended_at=NOW(), ended_by=caller,
                   suspended_by=NULL, suspended_at=NULL
 WHERE id = p_match_id;
```
Otherwise unchanged. Closes the conversation, writes the `journey_ended`
milestone, as today.

### 4.2 · `zyra_block_user(p_other uuid)` — atomic

In one transaction:

1. Refuse self-block, refuse unknown user.
2. `INSERT ... ON CONFLICT DO NOTHING` into `profile_blocks`.
3. For **every** non-ended match between the pair:
   - `status='ended'`, `ended_at=NOW()`, `ended_by=caller`,
     `end_reason='safety_concern'`, clear suspension
   - matching `journey_attempts` row ended the same way
   - `conversations.status='closed'`, `closed_at=NOW()`
   - `journey_ended` timeline milestone
4. Return a count of Journeys ended, so the UI can word the confirmation.

`end_note` stays NULL — `matches_no_note_on_safety_ending` forbids one, and
a note would be a second channel for the same disclosure.

### 4.3 · `zyra_unblock_user(p_other uuid)`

Deletes the block row. **Nothing else.** The Journey stays ended; if the two
ever reconnect it starts fresh. Your decision, and it also avoids resurrecting
a conversation neither party expects to reopen.

### 4.4 · Revoke the direct writes

```sql
revoke insert, update, delete on public.profile_blocks from anon, authenticated;
```
SELECT stays — the Blocked Users screen reads its own rows.
`zyra_report_service.dart` moves to the two RPCs.

### 4.5 · Clause 3 gains the attempt-level block check

§2. Clauses 1, 2 and 4 untouched.

### 4.6 · Backfill

Every existing block with a non-ended Journey gets the same treatment.
**Currently 0 rows** — measured — so it is a no-op today, and written anyway
because it will not be a no-op the day it matters.

---

## 5. "Prevent any future resume" — already done

No new work. `zyra_can_match()` already includes a block check in both
directions, and:

- `resume_journey()` re-checks it → refuses
- `promote_journey_to_active()` re-checks it → refuses
- `restart_journey()` refuses unconditionally today
- `create_match_on_mutual_like()` re-checks it → no new match
- `likes` / `saves` / `passes` RLS → no new romantic edge

Worth stating because it means Step 1b adds no resume-prevention logic; the
Step 2 predicate already covers every path.

---

## 6. ⚠️ The notification question is a trap, and I need your call

You said the other party should *"only be told that the Journey has ended."*

**`end_journey()` sends no notification at all today.** The other party finds
out by opening the app.

So if a block-ending sends one and an ordinary ending does not, **the arrival
of a notification means "you were blocked"** — and we are back to a
distinguishable ending, having just spent Step 0 preventing exactly that.

Three coherent options:

| | |
|---|---|
| **A · Neither notifies** | Matches today. Block-ending stays silent, discovered on next open. Fully indistinguishable, zero work |
| **B · Both notify** | *"Your Journey with Fatima has ended."* Identical wording, identical trigger, both paths. Kinder, and still indistinguishable — but it is a new notification on the ordinary path too |
| **C · Only block-endings notify** | **Do not do this.** It is a disclosure channel wearing a courtesy |

I would take **B** if you want people told, **A** if you do not. Both are
defensible; C is the only wrong answer, and it is the one that looks most
considerate.

---

## 7. Knock-on effects, stated explicitly

| Area | Effect |
|---|---|
| **Guardian visibility** | Revoked for the blocked pair's attempts — via §2, not via ending. Guardians of both families lose the counterpart Seeker and each other |
| **Journey visibility** | The match row remains readable to the two Seekers (`matches_select` is not status-gated for them), showing `ended`. Guardians lose it, since §2 removes the attempt's grant |
| **Unlock+** | Unaffected. `guardians_for_unlocked` already refuses on a block in either direction — verified during the audit |
| **Conversation** | Closed. `messages_select` requires participation via the attempt; §2 removes it for Guardians. The two Seekers retain their own history |
| **Photos / ages** | Follow automatically, both delegate to `can_view` |
| **Introductions** | Unaffected — `can_match` already blocked, so no suggestion can be acted on |
| **Family Network** | Not built. Fewer edges to leak into it |
| **Reports** | Untouched. `profile_reports` is append-only and a block does not erase one |
| **`zyra_reset_profile`** | Deletes likes/saves/passes but keeps matches. An ended-by-block match survives a reset, correctly — the safety record should not be clearable by the person it concerns |

---

## 8. Verification I would run, and roll back

| Check | Expected |
|---|---|
| Block with a live Journey → match status | `ended` |
| → `ended_by` | the blocker |
| → `end_reason` read via accessor **as blocker** | `safety_concern` |
| → as the **blocked party** | `prefer_not_to_say` |
| → as **either Guardian** | `prefer_not_to_say` |
| → conversation status | `closed` |
| → timeline milestone | one `journey_ended` |
| **Ordinary `end_journey` also sets `ended_by`** | yes — the §1 tell is gone |
| Blocked party sees blocker's profile | **false** |
| **Blocker's Guardian sees blocked Seeker** | **false** |
| **Blocked party's Guardian sees blocker** | **false** |
| Guardian still sees their OWN Seeker | true |
| `resume_journey` afterwards | refused |
| `promote_journey_to_active` afterwards | refused |
| Unblock → Journey status | still `ended` |
| Unblock → visibility restored | no |
| Direct `INSERT` into `profile_blocks` | refused, no grant |
| An unrelated live Journey of either party | untouched |
| Backfill over existing blocks | 0 rows affected today |

---

## 9. Awaiting

Approval of §4, and your answer on §6 — A or B. Nothing applied.
