# ZYRA — Stage 4e: Journey RPC Layer Migration

**Status:** APPROVED 2026-08-08 (DR-ZYRA-122) — was PROPOSED — for Founder review. Nothing built.
**Date:** 2026-08-06 · **OA:** OA-ZYRA-156 (stage 4e) · **DR:** DR-ZYRA-121
**Method:** every claim read from the live database, not from spec.

---

## 1. Why this is a separate piece of work

V3 §14 costed the migration as *"nine tables key off `match_id`… they carry
15 RLS policies. That re-pointing is the real work — not the idea."*

Two things have since been measured and both were understated:

| V3 said | Actually |
|---|---|
| 15 RLS policies, one authorisation question | **19 policies, four distinct questions** |
| Nine tables re-pointed | **Plus 11 RPCs that read those tables by `match_id`** |

Neither was a careless estimate — both were made from the schema. The RPC
bodies were not read, and the Journey lifecycle lives inside them.

**This is not a migration. It is a rewrite of the Journey service layer.**

---

## 2. The hard dependency

**Stage 4d cannot complete without 4e.** Dropping `match_id` from the nine
tables breaks eleven functions:

| RPC | Reads by `match_id` |
|---|---|
| `create_match_on_mutual_like` | conversations, timelines |
| `create_conversation_started_milestone` | conversations, timelines |
| `notify_new_message` | conversations |
| `end_journey` | conversations, timelines |
| `suspend_journey` | conversations |
| `resume_journey` | conversations |
| `restart_journey` | conversations |
| `open_family_review` | journey_family_reviews |
| `reopen_family_review` | journey_family_reviews |
| `resolve_family_review_if_due` | conversations, journey_family_reviews |
| `wali_review_decision` | conversations, journey_family_reviews |

4a and 4b are complete and verified. **4c and 4d should be folded into 4e**
rather than executed against a schema the RPCs still depend on.

---

## 3. Every function requiring change

### 3a. Lifecycle owners — the substantive rewrites

These read or write `matches.status` / `journey_stage`, which move to
`journey_attempts`.

| RPC | Change | Risk |
|---|---|---|
| `promote_journey_to_active` | potential → active on the **attempt**. Must also enforce one-active-attempt **per person**, which the schema still does not do (§5) | **High** |
| `end_journey` | Set attempt ended. **Must start recording `ended_by` / `end_reason`** — the columns exist (OA-158) and nothing writes them | **High** |
| `suspend_journey` | `paused_by`/`paused_at` move to the attempt. Entitlement check CHANGED 2026-08-12 stewardship pass: both plans, per-plan cap 5/10 (`paused_limit_reached`, migration 20260811231149) — DR-ZYRA-138 supersedes V3 §7 | Medium |
| `resume_journey` | Already corrected in OA-164 (no auto-end). Re-point only | Low |
| `restart_journey` | Currently refuses (OA-154). Replaced wholesale by Request New Journey, OA-159 | — |

### 3b. Family Review — re-point only

`open_family_review` · `reopen_family_review` ·
`resolve_family_review_if_due` · `wali_review_decision`

Business rules unchanged. `resolve_family_review_if_due` also advances
`journey_stage`, so it moves with the lifecycle.

### 3c. Triggers — mechanical

`create_match_on_mutual_like` must now create the match **and** attempt 1.
The stage-2 trigger already does the second half; this needs to not fight
it. `create_conversation_started_milestone` and `notify_new_message`
re-point only.

---

## 4. Behavioural differences

**Intended:**

1. **Endings become attributable.** `ended_by` and `end_reason` are written
   for the first time. Today an ending records only a timestamp — V3 §1: *"A
   mutual, respectful ending and someone fleeing a frightening situation are
   indistinguishable in the data."*
2. **A pair can hold history from several attempts** without collision. This
   is the point of the whole change.
3. **`matches` stops carrying lifecycle.** One place holds Journey state.

**Not intended, and to be guarded against:**

4. Any change to who may see what. The four policy shapes are settled and
   verified; 4e must not disturb them.
5. Any change to Pause entitlement. It stays ZYRA One (V3 §7).
6. Any automatic ending. Approved item 12 — and `resume_journey` already had
   one that V3 did not list (OA-164).

---

## 5. A rule the schema still does not enforce

V3 §1 found that one-Active-Journey-per-person is **not** enforced by the
schema: `matches_seeker_a_active` and `matches_seeker_b_active` are separate
partial indexes, so one person can be `seeker_a` on one active match and
`seeker_b` on another.

**I reproduced this on 2026-08-06** — building an unrelated fixture, I had to
deliberately order three ids `a < b < c` to get one person active on two
matches without either index objecting. It is real, not theoretical.

`journey_attempts` now has `journey_attempts_one_active_per_match`, which is
per **pair**, not per **person**. The per-person rule still lives only in
whatever each write path remembers to check.

**Recommendation:** 4e is the moment to enforce it properly — an exclusion
constraint or a participant-based unique index over
`zyra_attempt_participant_rows` where `attempt_status = 'active'`. That
makes it structural rather than remembered, and it is the second of the
"two fixes that come free" V3 §14 promised.

---

## 6. Security implications

| | |
|---|---|
| All 11 are `SECURITY DEFINER` | They bypass RLS by design. Every re-pointed query must re-derive authorisation itself — the policies will not protect them |
| Caller checks must survive | Several already check `caller = m.suspended_by` or party-to-match. Re-pointing must not lose these |
| `zyra_attempt_participants()` should be used | Rather than each RPC re-deriving who is party. Same reasoning that produced the participant projection |
| `safety_concern` | Once `end_reason` is written, the withholding rule becomes live. A safety ending must not reach the other party through any RPC return value |

---

## 7. Testing strategy

**Behaviour-preserving by default.** Every test below exists to prove
nothing changed except the three intended differences in §4.

1. **Re-run the authorisation suite** — the 16 checks from 4b, unchanged.
   Four policy shapes, main vs non-main Guardian, potential vs active.
2. **Lifecycle state machine, per RPC.** potential → active → paused →
   resumed → ended, asserting both the attempt row and the caller checks.
3. **The negative cases that already caught real defects:**
   - resume does not end (OA-164)
   - restart refuses (OA-154)
   - no history is deleted (V3 item 13)
   - `ended_at` is never cleared
4. **Two attempts on one pair** — the case the architecture exists for.
   Rows on both, no collision, each visible to its own participants.
5. **One-active-per-person**, constructed as `a < b < c` so it actually
   exercises the gap in §5.
6. **Before/after diff** on the standing baseline (Browse counts, ages_for,
   score_candidates spread).

---

## 8. Opportunities to simplify

**8.1 Several RPCs re-derive "is the caller party to this match".** That is
now `zyra_attempt_participants()`. Consolidating removes eleven copies of a
question with one answer.

**8.2 `restart_journey` should be dropped, not migrated.** It refuses
already; OA-159 replaces it. Migrating a function that only raises is work
with no product behind it.

**8.3 `resolve_family_review_if_due` is called lazily from the client** on
every screen open. With attempts it could become a trigger on read of the
review — but that is a behaviour change and is **not** proposed here.
Flagged only so it is not mistaken for an oversight.

**8.4 Consider whether `matches` should keep `status` at all.** V3 §2 gives
it only the pair, `created_at`, protection holds and the block relationship.
A denormalised "does this pair have an active attempt" flag would be a
second source of truth, and this whole exercise exists to remove one.
**Recommendation: no.** Derive it.

---

## 9. Proposed sequence

| # | Step | Verify |
|---|---|---|
| 1 | Fold 4c/4d in: Dart resolves attempt via the service layer, screens keep passing `matchId` | Static check + baseline |
| 2 | Re-point the 4 Family Review RPCs (no rule changes) | Suite §7.1, §7.2 |
| 3 | Re-point the 3 trigger functions | §7.2 |
| 4 | Rewrite `suspend`/`resume` onto the attempt | §7.2, §7.3 |
| 5 | Rewrite `promote` and `end` — the two that change behaviour | §7.2–§7.5 |
| 6 | Enforce one-active-per-person (§5) | §7.5 |
| 7 | Drop `match_id` from the nine tables; drop lifecycle from `matches` | Full suite |
| 8 | Drop `restart_journey` | — |

Steps 5 and 6 are where behaviour genuinely changes and deserve their own
review before merging.

---

## 10. What I need from you

> ### ✅ STEPS 2, 3, 4, 5 and 6 BUILT AND VERIFIED — 2026-08-08
>
> | Step | Result |
> |---|---|
> | 2 · Family Review RPCs | ✅ 18/18 |
> | 3 · the three trigger functions | ✅ 12/12, through two real mutual Likes |
> | 4 · suspend/resume | ✅ 9/9 — completed after step 5 removed its blocker |
> | 5 · promote and end | ✅ 20/20 — the linchpin |
> | 6 · one Active Journey per person | ✅ 5/5 |
>
> **Step 5 resolved the blocker it created.** promote_journey_to_active()
> now maintains journey_attempts, so: the attempt pause CHECK accepts a
> write (step 4 finished), journey_attempts_one_active_per_person is live
> rather than inert, and step 7 has a consistent attempt row to move onto.
>
> Two behaviour changes worth knowing: `end_journey` gained a
> two-argument form that records a reason (the one-argument form is
> untouched, so the Dart is unaffected), and `no_response` is refused from
> the user path because the constraint reserves it for the system.
>
> **REMAINING: steps 1, 7 and 8.** Step 1 needs `flutter analyze`. Step 7
> is destructive and still should not run until the schema is in files and
> the repo is pushed.
>
> ### superseded summary — 2026-08-08 (steps 2, 3, 4-partial, 6)
>
> | Step | Result |
> |---|---|
> | 2 · Family Review RPCs | ✅ 18/18 |
> | 3 · the three trigger functions | ✅ 12/12, exercised through two real mutual Likes |
> | 4 · suspend/resume | ⚠️ **PARTIAL** — conversation writes re-pointed; pause mirroring blocked, see below |
> | 6 · one Active Journey per person | ✅ 5/5, enforced on `matches` |
>
> ### 🔴 BLOCKER FOUND — step 5 is bigger than the plan implies
>
> **`promote_journey_to_active()` does not touch `journey_attempts` at
> all.** An attempt is created 'potential' and promote only moves
> `matches`. Measured on the real path, 6/6. Two consequences:
>
> 1. `journey_attempts.paused_by` cannot be written — `attempts_pause_needs_active`
>    rejects it — so half of step 4 is impossible until step 5 lands.
> 2. `journey_attempts_one_active_per_person` **cannot fire**. It was
>    described as scaffolding when DR-ZYRA-122 was approved; it is inert.
>    Step 6 therefore put the invariant on `matches`, which promote does
>    write. It moves to attempts at step 7.
>
> Step 5 is now the linchpin of the whole stage, not just "the one that
> changes behaviour". It must make promote maintain attempt status.
>
> ### ✅ STEP 2 BUILT AND VERIFIED — 2026-08-08, 18/18
>
> The four Family Review RPCs now navigate by `attempt_id`. Signatures
> unchanged, so no client change was needed and the step stands alone.
> Authorisation logic is character-for-character what it replaced.
>
> Two things worth knowing:
> - The READ path was **already** attempt-based — both family-review
>   policies join on `attempt_id`. The policies had been re-pointed and
>   the functions had not. This closed that gap rather than opening a new
>   one.
> - The `journey_attempts` stage drift is **fixed for these three write
>   paths**. `promote_journey_to_active()` still writes `matches` only —
>   that is step 5's.
> - Added `journey_family_reviews_one_pending_per_attempt`. The
>   match-keyed index stays until step 7.
>
> Remaining in stage 4e: steps 1, 3, 4, 5, 6, 7, 8.
>
> **✅ ALL FIVE APPROVED — Founder, 2026-08-08. Recorded as DR-ZYRA-122.**
> Build authorised for stage 4e.
>
> Two items had moved since this plan was written, and were re-verified
> against the live database before being put to the Founder:
>
> - **Item 2** — a correct per-person constraint trigger already exists on
>   `journey_attempts`, but `matches` is still authoritative and the write
>   path does not pass through it. Scaffolded, not load-bearing.
> - **Item 3** — half built. `ended_by` has been written since Step 1b
>   (2026-08-08 morning); `end_reason` has not.
>
> **Sequencing condition recorded with the approval:** steps 2, 3, 4 and 6
> are SQL and independently verifiable and may proceed. **Step 1 (Dart) and
> step 7 (dropping `match_id`) must not land** while `flutter analyze`
> cannot be run and the 84 live-only migrations are unrecovered — a
> destructive drop with no schema in version control has no rollback
> artefact.


1. **Approve folding 4c and 4d into 4e**, given the hard dependency in §2.
2. **Approve §5** — enforce one-active-Journey-per-person structurally.
3. **Approve §4.1** — `end_journey` starts writing `ended_by`/`end_reason`.
   This is the first time an ending becomes attributable and it is a real
   behaviour change, approved in principle by DR-ZYRA-121 item 6 but not yet
   built.
4. **Confirm §8.4** — `matches` keeps no lifecycle state at all.
5. **Confirm §8.3 is out of scope** — the lazy family-review resolution
   stays as it is.
