# ZYRA — Step 0 migration plan: `safety_concern` disclosure

**Status:** PLAN ONLY — not applied. For approval before execution.
**Date:** 2026-08-08

---

## 0. A correction to what I told you

I said *"the system currently tells him, and tells his family."* **That
overstates it, and you were about to act on my framing.**

`end_journey(p_match_id)` — the only function that ends a Journey — sets
`status`, `ended_at`, and clears the suspension. **It never writes
`end_reason`, `ended_by` or `end_note`.** No other function writes them
either; a search for `end_reason` across all 56 functions returns nothing.

So the columns exist, the CHECK constraints exist, and the ownership
register documents them in careful detail — but **the ending-reason feature
is designed and unbuilt.** No user can currently produce a `safety_concern`
value. I produced one by hand to prove the read path.

**What is true:** the read path is already wrong, and the day someone builds
the write path the leak ships with it, fully formed, in a feature whose
entire purpose is safety.

**What is not true:** that anyone is exposed today.

This is still worth doing first — but as *"fix the foundation before the
feature lands on it"*, not as an incident. It also makes the fix free: with
no reader and no writer, nothing can break.

---

## 1. What the app reads today

All 13 references to these column names across `lib/` are to
**`suspended_by`**, a different column. Nothing in the client reads
`end_reason`, `ended_by` or `end_note`.

**Client impact of this migration: none.**

---

## 2. The migration, exactly as it would be applied

```sql
-- ── Revoke the two columns that carry the private value ───────────────
-- Same pattern as profiles.date_of_birth: the column stops being
-- client-readable and a controlled accessor is the only route.
revoke select (end_reason, end_note) on public.matches from anon, authenticated;

comment on column public.matches.end_reason is
  'OWNERSHIP: per-value. Joint for the five stated reasons (V3 §8 — a '
  'stated reason is kinder than silence). safety_concern is '
  'row-scoped(ended_by) and MUST NEVER reach the other party or either '
  'family. NOT CLIENT-READABLE as of 2026-08-08 — RLS decides rows, not '
  'values, so the rule cannot be expressed as a policy. Read it through '
  'zyra_match_ending(), which substitutes prefer_not_to_say for anyone '
  'not entitled to the truth. Do not re-grant.';

comment on column public.matches.end_note is
  'OWNERSHIP: joint — written TO the other person. Revoked alongside '
  'end_reason 2026-08-08 and returned by zyra_match_ending(), because a '
  'note present or absent is itself a signal about the reason.';
```

**`ended_by` is deliberately NOT revoked.** The register calls it joint —
*"who ended it is knowable to both"* — and it stays that way. Knowing who
ended a Journey without knowing why is exactly the state
`prefer_not_to_say` already describes, so leaving it visible is what makes
the substitution invisible.

### The accessor — written now, so the feature cannot be built around it

```sql
create or replace function public.zyra_match_ending(p_match_id uuid)
 returns table(ended_by uuid, end_reason text, end_note text, ended_at timestamptz)
 language sql stable security definer set search_path to 'public'
as $$
  select m.ended_by,
         case
           -- Only the person who raised it sees what they raised.
           when m.ended_by = (select auth.uid()) then m.end_reason
           -- Everyone else: the five joint reasons pass through unchanged;
           -- safety_concern is replaced by a reason that already exists,
           -- is already common, and carries no signal.
           when m.end_reason = 'safety_concern' then 'prefer_not_to_say'
           else m.end_reason
         end,
         case
           when m.ended_by = (select auth.uid()) then m.end_note
           when m.end_reason = 'safety_concern' then null
           else m.end_note
         end,
         m.ended_at
  from public.matches m
  where m.id = p_match_id
    and public.zyra_can_view_attempt(m.id);   -- existing participation check
$$;

revoke execute on function public.zyra_match_ending(uuid) from public, anon;
grant  execute on function public.zyra_match_ending(uuid) to authenticated;
```

---

## 3. Why the substitution is indistinguishable — the part that matters

You made the right condition: *"if someone can infer a substitution
happened, then we've still leaked."* Four ways it could be inferred, and why
each is closed:

| Tell | Why it is not one |
|---|---|
| **A missing note** | `matches_no_note_on_safety_ending` already forbids a note on a safety ending, and a note is optional on every other reason. A real `prefer_not_to_say` with no note is the common case |
| **A rare value** | `prefer_not_to_say` is a genuine user-facing option. Substituting into a rarely-used bucket would be a tell; substituting into a common one is not |
| **A different code path** | The accessor returns the same shape in both cases. The client cannot see which branch ran |
| **`ended_by` being present** | Unchanged, and present for every reason except `no_response` — which the constraint already forces to have `ended_by IS NULL` |

**The one that is NOT yet closed, and needs a rule before the feature is
built:** the UI must render `prefer_not_to_say` identically whether it is
real or substituted. No different tone, no extra sentence, no "this Journey
was ended for undisclosed reasons" variant. **One string, one layout.**

---

## 4. One product decision I should not make

**Does the ender's own Main Guardian see the true reason?**

- **Strict** — only `ended_by`, as the register literally says. A woman who
  reports a safety concern is not outed to her own family, which may be
  exactly the protection she needs.
- **Guardian-inclusive** — her Main Guardian sees it, because protecting her
  is the role's entire purpose, and a Guardian blind to a safety concern
  cannot act on it.

The plan above implements **strict**. It is the safer default and the
narrower one, and widening later is easy while narrowing later is a
disclosure.

I would not decide this on your behalf. It is a question about what a
Guardian is for.

---

## 5. What is deliberately NOT in this migration

- **The write path.** `end_journey()` is untouched. The ending-reason
  feature is unbuilt and building it is a separate piece with its own
  review — including the UI rule in §3.
- **`journey_attempts`.** It carries the same four columns with the same
  constraints, and its client grants were already revoked entirely on
  2026-08-07. Nothing to do; noted so it is not missed when the write path
  is built, because that is where the value will actually live.
- **Everything in the Guardian visibility matrix.** Unrelated and sequenced
  after.

---

## 6. Verification I would run, and roll back

| Check | Expected |
|---|---|
| Other Seeker reads `end_reason` directly | refused, no grant |
| Their Guardian reads `end_reason` directly | refused, no grant |
| `zyra_match_ending()` as the ender | `safety_concern` |
| `zyra_match_ending()` as the other Seeker | `prefer_not_to_say` |
| `zyra_match_ending()` as their Guardian | `prefer_not_to_say` |
| `zyra_match_ending()` with a genuine `not_compatible` | `not_compatible`, unchanged |
| `zyra_match_ending()` note on a substituted row | `null` |
| A non-participant calls it | 0 rows |
| `ended_by` still readable by both | yes |
| App still builds — no client reference to the revoked columns | 0 references |

---

## 7. Awaiting

Your approval to run §2, and your answer on §4. Nothing has been applied.
