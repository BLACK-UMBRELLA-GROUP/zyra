# ZYRA — Step 1 migration plan: the clause 3 status guard

**Status:** PLAN ONLY — not applied. For approval.
**Date:** 2026-08-08

---

## 1. What clause 3 actually does

```sql
or exists (
  select 1
  from zyra_attempt_participant_rows me
  join zyra_attempt_participant_rows them on them.attempt_id = me.attempt_id
  where me.user_id = auth.uid() and them.user_id = p_target
)
```

**Any participant may see any other participant.** Four pairs, all measured
live at `potential` — a mutual Like, no Journey started, nothing purchased:

| | |
|---|---|
| Seeker A → Seeker B | `true` |
| **Seeker A → B's GUARDIAN** | **`true`** |
| Guardian A → Seeker B | `true` |
| Guardian A → Guardian B | `true` |

### Row 2 corrects something I told you

I described the Unlock+ bypass as a Guardian problem. It is not. **A Seeker
gets the counterpart's Guardian roster free**, which is precisely what
Unlock+ sells. The clause does not care what role you are — only that you
are both attached to the same attempt.

---

## 2. Why a blanket status guard would break Connections

The obvious change — bolt `attempt_status <> 'potential'` onto the whole
clause — has a regression, found by testing rather than reading:

| | |
|---|---|
| A → B at `potential`, B's profile **paused** | **`true` today** |

Clause 4 (browsing) requires `is_active`, so when a matched counterpart
pauses their profile, **clause 3 is the only thing keeping them visible.**
Guard the whole clause and a paused counterpart vanishes from the other
person's Potential Journeys list.

So the guard has to spare Seeker↔Seeker.

---

## 3. The migration, exactly as it would be applied

Only clause 3 changes. Clauses 1, 2 and 4 are untouched.

```sql
  -- CLAUSE 3 — participants of a shared attempt.
  --
  -- GUARDED ON STATUS 2026-08-08. Previously "any participant sees any
  -- participant", with no regard for what stage the Journey had reached.
  -- A mutual Like therefore exposed both families' Guardians to each other
  -- before a Journey existed — treating consent to be CONSIDERED as consent
  -- for families to MEET.
  --
  -- Seeker <-> Seeker is deliberately exempt. When a matched counterpart
  -- pauses their profile, clause 4 stops applying (it requires is_active)
  -- and this clause is the only thing keeping them visible in Potential
  -- Journeys. Guarding it wholesale would make a paused match disappear.
  --
  -- matches_select already gates Guardians on status <> 'potential'. This
  -- brings profile visibility into line with the row visibility that has
  -- been correct for two weeks.
  or exists (
    select 1
    from public.zyra_attempt_participant_rows me
    join public.zyra_attempt_participant_rows them
      on them.attempt_id = me.attempt_id
    where me.user_id = (select auth.uid())
      and them.user_id = p_target
      and (
            (me.role = 'seeker' and them.role = 'seeker')
         or me.attempt_status <> 'potential'
      )
  )
```

---

## 4. Effect on each area — as requested, explicitly

### Unlock+ · IMPROVED, NOT FIXED

| | Before | After Step 1 | After the full matrix |
|---|---|---|---|
| Guardian roster, free | from `potential` | from Journey start | never free pre-`wali_gate` |

**Step 1 delays the bypass; it does not close it.** From the moment a
Journey goes active, a Seeker and their Guardians still see the counterpart's
full Guardian roster for nothing. Closing that needs the gate-level rules in
Step 4/5.

Stated plainly so the sequence is not mistaken for a fix.

### Guardian visibility · REDUCED, no UI regression

Guardians lose the counterpart Seeker and the counterpart's Guardians while
a match sits at `potential`.

**Nothing renders that today.** `zyra_wali_journey_service` already filters
`.neq('status','potential')`, with a comment noting RLS does the same. The
Guardian side has never displayed potential-stage Journeys. This is a
data-layer over-permission with no consumer.

### Journey visibility · UNAFFECTED

`matches_select` already carries `status <> 'potential'` for Guardians, so
the match row was never visible pre-Journey. Only the *profile* leaked. This
aligns the two.

### Introductions · UNAFFECTED

Checked. Suggestions are read by the **Seeker**, and the suggested profiles
resolve through clause 4 (opposite gender, active, published). Nothing
depends on clause 3. The Guardian has no browse surface at all, and the only
writer of `wali_suggestions` is a dev-only function gated to `@zyra.test`.

### Family Network · NOT YET EXISTS

205 lines of UI shell, no backend. The change reduces what the substrate
leaks before it is built, which is the direction agreed.

### Knock-ons that follow automatically

`zyra_can_read_photo_object()` and `ages_for()` both delegate to
`zyra_can_view_profile()`. **Photos and ages tighten with it, at no extra
cost** — worth stating because it means the change is broader than its
one clause suggests, in the right direction.

---

## 5. A second defect in the same clause — decision needed

**Clause 3 has no block check, and clause 4 does.**

Measured, with an active Journey and A having blocked B:

| | |
|---|---|
| **Blocked B can still see A** | **`true`** |
| Blocker A can still see B | `true` |
| **B's Guardian can see A** | **`true`** |
| The **paid** route, `guardians_for_unlocked` | **0 rows — correctly refuses** |

The paid accessor respects the block. Clause 4 respects the block. **Clause
3 is the only place that ignores it** — so a woman who blocks a man mid-
Journey remains visible to him and to his family, which is the situation
blocking exists for.

**I have not folded this into §3, because it raises a question I should not
answer alone:**

> **Should blocking end an active Journey?**

- If **yes**, the block check belongs with that change, and the Journey ends
  cleanly with both parties losing sight of each other.
- If **no**, adding a block check here leaves two people in a live Journey
  who cannot see each other — a broken screen rather than a safety fix.

Adding the check without deciding this trades a privacy defect for a
correctness one. Recommend deciding it, then shipping the block check
alongside — probably as Step 1b.

---

## 6. Verification I would run, and roll back

| Check | Expected |
|---|---|
| Guardian → counterpart Seeker at `potential` | **false** |
| Guardian → counterpart Guardian at `potential` | **false** |
| Seeker → counterpart's Guardian at `potential` | **false** |
| Seeker → Seeker at `potential` | true |
| **Seeker → Seeker at `potential`, counterpart paused** | **true — the regression guard** |
| Guardian → counterpart Seeker at `active` | true |
| Guardian → own Seeker at `potential` | true (clause 2) |
| Photos of the counterpart's Guardian at `potential` | 0 rows |
| `ages_for` on the counterpart's Guardian at `potential` | 0 rows |
| `guardians_for_unlocked` with a real purchase | unchanged |
| Guardian journey list — `.neq('status','potential')` path | unchanged |

---

## 7. Awaiting

Approval for §3, and a decision on §5 — whether blocking should end an
active Journey. Nothing applied.
