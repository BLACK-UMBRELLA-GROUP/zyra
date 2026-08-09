# ZYRA — Guardian & Romantic Eligibility Rules

**Status:** APPROVED — Founder, 2026-08-07 · **Version:** V1
**Amended 2026-08-08** — Steps 0, 1 and 1b built; §0 invariants added.
**Amended 2026-08-08 (later)** — §7 release blocker CLOSED, see §7c.
**Amended 2026-08-08 (evening)** — Guardian surveillance closed, see §7d.
**Source of truth** for romantic eligibility, Guardian eligibility, and the
boundary between them.

Referenced from `accept_wali_invite()` and `profile_blocks` in the database.
Amended in place rather than versioned to V2 precisely because of those
references — the filename carries the version number, so a bump breaks every
comment pointing at it. **Worth fixing properly:** code should reference the
system name without a version, and the convention should say so.

---

## 0. The invariants

Three rules that outrank everything below them. A future feature is checked
against these, not against a table it may not have read.

### I1 · Permanent behaviour must derive from permanent data

> **Temporary records — blocks, invitations, sessions, toggles, publication
> flags — must never be the sole source of a permanent permission or
> restriction.**

Founder, 2026-08-08. **This principle has now caught two bugs of the same
shape, five days apart, in unrelated areas:**

| | Keyed on (temporary) | Should key on (permanent) |
|---|---|---|
| **Identity freeze** | `profile_complete` — which the user may switch off | `first_published_at` — written once, never cleared |
| **Block revocation** | a `profile_blocks` row — which the user may delete | `end_reason = 'safety_concern'` — recorded on the match forever |

In both cases the rule read correctly and was undone by a state the user
controlled. The un-publish loophole and the unblock-restores-visibility bug
are the same mistake wearing different clothes.

**The test:** for any permanent consequence, ask *"can the user clear the
thing this depends on?"* If yes, it is the wrong anchor.

### I2 · A block is a terminal safety boundary

> **Nothing in the product may automatically recreate or restore any
> relationship, visibility, conversation or Journey that existed before a
> block. Any future interaction must begin as an entirely new relationship
> under the normal rules.**

Note what this does **not** forbid: two people who unblock may find each
other in Browse again and start a fresh Journey. They are two eligible users,
not a restored pair. Ordinary browsing is not restoration.

### I3 · One path, or the paths will drift

> **Where two operations must be indistinguishable, they must share one
> implementation — not two implementations kept in step.**

Ordinary endings and safety endings both run through
`zyra_end_match_internal()`. Two code paths would diverge eventually, and
**the divergence would itself be the disclosure** the substitution exists to
prevent.

---

## 1. The two predicates

Romantic eligibility and Guardian eligibility are **two separate questions
with two separate functions**, and they are mutually exclusive by
construction.

| Function | Question | Enforced at |
|---|---|---|
| `zyra_can_match(a, b)` | May these two pursue each other? | RLS `WITH CHECK` on `likes` / `saves` / `passes`, plus `create_match_on_mutual_like()` |
| `zyra_can_guardian_link(a, b)` | May these two form a Guardian bond? | `BEFORE` trigger on `wali_links`, plus `accept_wali_invite()` |

Both are **symmetric** and **stateless** — durable facts only. Transient
state (already matched, already passed, currently suspended, subscription
tier) stays in the queries that need it. A predicate that knows about
workflow is a state machine, and a state machine inside an RLS check is
expensive, cache-hostile and occasionally wrong.

**A third concept is named but not built:** `can_introduce()` — mediated
Guardian facilitation, i.e. Guardian Introductions. A Guardian deliberately
putting a person in front of their Seeker is Guardian-derived visibility
producing a romantic outcome. That is legitimate and it already exists, so
it is a **third category rather than an exception to the second**. Recorded
here so the invariant is not quietly violated by a feature that predates it.

### `zyra_can_match(a, b)` — false if any of:

- same person
- either is not a Seeker
- genders are equal, or either is null
- a block exists **in either direction**
- an **active** `wali_links` edge exists in either direction

### `zyra_can_guardian_link(a, b)` — false if any of:

- same person
- a `matches` row exists between them, **in any status including `ended`**

It deliberately says nothing about **who may be a Guardian** — role, gender,
the male-Guardian model. That is the outstanding governance review and lives
in `accept_wali_invite()` until it concludes.

---

## 2. Why `ended` counts

An ended Journey can be revived by `restart_journey()`. Permitting a
Guardian link over one would create a pair the system can resurrect into a
state `zyra_can_match()` forbids.

Beyond consistency: a past romance between a Guardian and their Seeker is
precisely the conflict of interest the Guardian role exists to prevent. The
Founder's word for this rule was **absolute**.

---

## 3. RULE — Forming a Guardian bond extinguishes one-sided romantic intent

> **When a Guardian relationship is successfully created, any Like, Save or
> Pass between those two people is deleted, in both directions, silently and
> permanently.**

**This is intended product behaviour, not implementation housekeeping.**
Written down at the Founder's request so a future developer does not
discover it by wondering why a Save disappeared on its own.

### Why cleared rather than refused

Refusing a Guardian link because a Like exists would let **anyone veto a
Guardian relationship they are not part of**, simply by Liking one of the
parties. That trades one denial-of-service for another.

A **match** is different — mutual, stateful, with a conversation and a
timeline behind it — and is refused (§4).

### Why silently

Telling Alice *"your Save of Bob was removed"* discloses that she had saved
him, on a screen her new Guardian may well be looking at. The disclosure is
worse than the surprise.

### Why permanently

Removing the Guardian link later does **not** restore them. Interest is a
present-tense act; resurrecting a year-old Like would be inventing intent
nobody expressed.

### Why it is safe to delete another user's row

A Like by Bob of Alice is Bob's row. It is deleted without his knowledge.
That is justified because the edge is already inert — `zyra_can_match()` is
false the moment the link exists, so it can never lead anywhere — and
leaving it means every future feature has to reason about pairs that look
interested and are not eligible.

---

## 4. RULE — A Guardian bond never invalidates an existing romantic one

> **Where a Guardian link and a romantic relationship conflict, the
> Guardian link gives way. Never the reverse.**

A Journey represents two people, two families, a conversation and shared
history. A Guardian relationship requested afterwards must not retrospectively
void any of it.

So `accept_wali_invite()` **refuses** with `romantic_edge_exists`, and the
Journey is untouched. Verified: the match row survives the refusal.

### And the reverse direction — the rule as a weapon

The moment "Guardian edge ⇒ never match" exists, a Guardian edge becomes a
way to make two people permanently unmatchable, or to void a live Journey.

Closed on three fronts:

1. Client `INSERT` on `wali_links` is **revoked** — creating a link needs a
   real invite and a real acceptance, so it is no longer unilateral.
2. `zyra_can_guardian_link()` refuses over any existing match.
3. A `BEFORE INSERT OR UPDATE` trigger on `wali_links` enforces it for
   **every** path, including `SECURITY DEFINER` functions and any written in
   future. Verified by attempting a direct write as the table owner: refused.

**Retiring a link is always permitted** (`status = 'removed'`). The rule
guards the creation of a bond, not its ending — blocking removal would
strand people.

---

## 5. RULE — Every path, not every caller

> **A rule that lives inside one function applies to whoever happens to call
> that function.**

`zyra_can_guardian_link()` began as an inline `EXISTS` inside
`accept_wali_invite()`. That was correct for the only write path that
existed and invisible to the next one. It is now a predicate plus a trigger.

The same principle put `zyra_can_match()` in the **RLS `WITH CHECK`** rather
than only in the match trigger: a trigger can be disabled for a transaction
— this project disabled one twice on 2026-08-07 to run backfills — and a
disabled trigger enforces nothing. **RLS is the authoritative enforcement
layer for romantic eligibility. Founder-ratified.**

Direct `INSERT` grants on `likes`, `saves` and `passes` are deliberately
**retained**, with `auth.uid()` **AND** `zyra_can_match()` in the policy.
They are not to be moved behind RPCs.

---

## 6. State transitions count as eligibility events

`zyra_can_match()` is consulted when an edge is **created**. Two functions
change the *status* of an edge that already exists and so never triggered
it:

| Function | Route it opened |
|---|---|
| `promote_journey_to_active()` | idle potential match → Guardian link forms → promoted to active |
| `resume_journey()` | paused Journey → Guardian link forms → resumed |

Either produced the forbidden state without a single Like being written.
Both now re-check `zyra_can_match()` and refuse with `not_eligible_to_match`.

**The general rule: any function that creates OR revives a romantic state
must consult the predicate.** A pause is exactly the window in which a
Guardian link is likely to appear.

---

## 7. ~~🔴 RELEASE BLOCKER~~ — `advanceStage()` was a silent no-op

**CLOSED 2026-08-08. Kept in full because the diagnosis is the record;
§7c below is what was built.**

**Founder-classified 2026-08-07: a release blocker for the Journey
lifecycle, not a backlog bug.**

`ZyraJourneyService.advanceStage()` writes directly:

```dart
await supabase.from('matches').update({'journey_stage': newStage}).eq('id', matchId);
```

`matches` has **no UPDATE policy**. RLS therefore denies it, which affects
**0 rows and raises nothing**. The call is wrapped in `catch (_) {}`, so
even the absence of an error is invisible.

Verified live: `phase_1 → phase_1`, 0 rows affected, no exception.

It is called from `journey_flow_screen.dart:117` — the live Journey ritual
flow. **Journey stages have not been advancing through this path.** The
same applies to the `conversations.status = 'active'` write beside it, which
is what unlocks messaging when a Journey reaches the conversation stage.

**Why it is a release blocker rather than a bug:** the Journey is the
marriage process. A ritual the user completes, that the database does not
record, means the app shows progress it cannot honour — and the user
discovers it on the next launch, having told their family otherwise.

**Fixed 2026-08-08 — see §7c.** The fix is an RPC that validates the
transition, checks the caller is a party, and returns a result the client
acts on instead of swallowing. The allowed stage transitions were put to
the Founder as a product question first, as this paragraph asked.

**One thing this paragraph got wrong, found by measuring rather than
reading:** it reads as "stages sometimes fail to save". The three
transitions `advanceStage()` served are the FIRST three, so a Journey
could never leave `compatibility_reveal` at all. `phase_1` onward do work
— they go through `open_family_review()`, a SECURITY DEFINER path — but
were unreachable. The entire ritual was dead at step one, which is why no
end-to-end Journey has ever run.

**Related, same cause:** the Family Review RPCs (`open_family_review`,
`wali_review_decision`, `resolve_family_review_if_due`) are `SECURITY
DEFINER` and unaffected. Only the direct-write path is broken.

---

## 7b. Built 2026-08-08 — Steps 0, 1 and 1b

Recorded here because §1–§6 predate them.

### Step 0 · `safety_concern` is private

`matches.end_reason` and `end_note` are **no longer client-readable** — table
SELECT revoked, ten permitted columns granted back, the
`profiles.date_of_birth` pattern followed exactly. `zyra_match_ending()` is
the only route, and substitutes `prefer_not_to_say` for everyone except the
person who raised it.

**STRICT, Founder-decided:** no Guardian sees it, including the reporter's
own. Someone may trust ZYRA with this and not be ready to tell their family.
If a Guardian should know, that must be the reporter choosing — never the
system assuming.

**Governance rule for callers:** `prefer_not_to_say` renders identically
whether genuine or substituted. One string, one layout, one behaviour.

`ended_by` stays readable — it is joint, and knowing *who* without *why* is
exactly what `prefer_not_to_say` already means. Its visibility is what makes
the substitution natural rather than a second side channel.

### Step 1 · Clause 3 status guard

A mutual Like no longer exposes both families. Anything involving a Guardian
now waits for the Journey to start; Seeker↔Seeker is exempt so a **paused**
counterpart does not vanish from Potential Journeys — clause 4 requires
`is_active`, so clause 3 is the only thing carrying that case.

**This is a delay, not the privacy model.** From the moment a Journey goes
active, the counterpart's Guardian roster is still free. Closing that needs
the gate-level matrix.

**The Unlock+ bypass was never Guardian-specific** — clause 3 ignores roles,
so a Seeker got the roster free too.

### Step 1b · Blocking ends the Journey

`zyra_block_user()` atomically blocks, ends every live Journey with
`safety_concern`, closes the conversation, writes the milestone and notifies
the other party. Direct writes to `profile_blocks` revoked.

`zyra_unblock_user()` deletes the block row and **nothing else** — I2.

Both ending types notify identically (Founder, Option B). **Seekers only:**
the body carries a name the Guardian may not be entitled to after Step 1, and
notifications are a push channel the visibility rules do not govern.

**The block check is at the ATTEMPT level**, not viewer-to-target.
`zyra_block_exists()` compares `auth.uid()` to the target, which catches the
two Seekers and misses all four Guardians — the block is between two people,
the visibility belongs to four.

---

## 7c. Built 2026-08-08 — `zyra_advance_stage()`

Three Founder decisions taken first, because none was mechanical:

| Question | Decision |
|---|---|
| Guardian Gate — whose Guardian? | **Both Seekers.** Previously the client read only the ACTING Seeker's own Guardian and advanced the SHARED stage, so one party dragged the pair through a gate the other never saw. The Family Review Period expects a Main Guardian on both sides to function at all |
| What unlocks Salam? | **Both revealed AND both pressed Continue** — "every checkpoint is a shared decision". Pressing Continue was previously recorded nowhere |
| `journey_attempts` stage drift | **Synced by this RPC**, and the missing CHECK constraint added to `journey_attempts.journey_stage` |

**Signature takes `from_stage`, not `to_stage`.** The caller says what it
has completed; the server owns the map. A client cannot name a
destination, so there is no skip-ahead to validate — and it doubles as a
compare-and-swap token, so a stale screen gets `stage_moved` rather than
rewinding the Journey.

**It REFUSES the four Family-Review-gated transitions.** Accepting them
would have made it a way to skip the 48-hour review period, which is the
one thing the Guardian side of the ritual rests on. `gated_transition` is
raised, not returned — a caller reaching it has a bug, and swallowing it
is how the original defect survived a month.

**Gates, all provable from tables that already existed:**

| Transition | Condition | Source of truth |
|---|---|---|
| `compatibility_reveal` → `salam_exchange` | both revealed AND both continued | `journey_compatibility` + new `journey_stage_checkpoints` |
| `salam_exchange` → `wali_gate` | both Salams sent | `journey_salams` |
| `wali_gate` → `phase_1` | both Seekers hold an active Main Guardian | `wali_links` |

`journey_stage_checkpoints` has **no client write grant** — the row is
written only by the RPC, so a checkpoint cannot be forged or recorded on
the other person's behalf (I4). That is deliberately tighter than its
sibling tables, whose blanket write grants are §8 item 4 below.

**Verified empirically, 17/17**, against two real seeded Seekers and a
real match, then torn down: every waiting reason, both Guardian branches,
the stale-client path, the paused and ended paths, gated refusal,
non-party refusal, attempt-row sync, and a clean teardown. The suite also
caught a real bug before first use — the OUT parameter `stage` collided
with `journey_stage_checkpoints.stage` and raised 42702. The function had
created cleanly and granted cleanly, and was broken. §3 of CLAUDE.md,
demonstrated again.

**Client:** `advanceStage()` now returns `ZyraStageAdvance(advanced,
stage, reason)` and logs on failure. `_WaliGateView` no longer reads or
advances anything — it renders which side is outstanding. The `wali_gate`
retry moved onto the screen's existing poll, beside
`resolveFamilyReviewIfDue`, because that stage has no user action left.

**Raised, not silently fixed:** `promote_journey_to_active()`,
`resolve_family_review_if_due()` and `wali_review_decision()` all still
write `matches` only, so the attempt copy drifts through those three
paths. This RPC owns its own writes, not theirs. Needs an OA.

**Also out of scope, deliberately:** the Timeline milestones the ritual
spec asks for ("✓ Salam Exchanged", the compatibility reveal entry).
`timeline_milestones.milestone_type` has no values for them, and adding
them is a product decision about what the timeline is for.

---

## 7d. Built 2026-08-08 — Guardian visibility closed

Authorised autonomously by the Founder via Fable as a **strict
reduction**: no viewer gains anything, on 149 seeded test accounts and
zero real users.

### What was wrong, measured not assumed

One active Journey, two Guardians a side. Every cell was `true`:

| Viewer | Could see |
|---|---|
| Main Guardian of A | B (**opposite gender**, which Browse refuses), B's Main Guardian, B's **Additional** Guardian, A's own co-Guardian |
| **Additional** Guardian of A | B, B's Main Guardian, B's Additional Guardian |

Mutually. A six-person clique per Journey, of whom four appointed nobody
and were appointed by nobody in it. Photos and ages followed, because
`zyra_can_read_photo_object()` and `ages_for()` both delegate to
`zyra_can_view_profile()`.

The paid product refused what the free path allowed:
`guardians_for_unlocked()` honours blocks and disclosure rules. Clause 3,
which nobody designed, honoured neither.

### The four changes

| | Change | Verified |
|---|---|---|
| 1 | **Clause 3 is Seeker↔Seeker only.** Guardians derive nothing from attempt participation. Clause 2 — own ward — untouched, and is the whole legitimate basis of Guardian visibility | 18/18 |
| 2 | **`is_main` is now a privilege boundary.** Five policies that admitted any Guardian now admit only the Main | 14/14 |
| 3 | **`ages_for()`** — singular form added, batch hard-capped at 50 | 6/6 |
| 4 | **`zyra_counterpart_card()`** — Main Guardians only, uniform fields, no city, no photo | 15/15 |

### Two things found while doing it

**`zyra_attempt_participants()` had no caller check at all.** SECURITY
DEFINER, granted to `authenticated`, and it returned *any* attempt's full
participant roster — both Seekers and every Guardian of both families,
with their `is_main` — to whoever passed the id. It bypassed clause 3
entirely, so fixing clause 3 alone would have left the enumeration surface
wide open. Zero Dart callers; revoked.

**The Guardian's Journey list would have broken silently.**
`_fetchPartnerProfile()` read the counterpart straight off `profiles`, and
its caller did `if (partner == null) continue;` — so after change 1 every
Journey would have vanished from the Guardian's list with no error. It now
builds from the card. Its `picsum.photos` fallback, which rendered a
stranger's face as a real user's photo (audit R8), is gone with it.

### `is_main` — the codebase already agreed

Audit of every object reading `wali_links`: **13 honour `is_main`, 8
ignore it**, and the split is not random. Family Review, Guardian
management and the paid `guardians_for_unlocked()` all treat Main as a
boundary. The visibility layer, which accreted rather than being designed,
did not. Change 2 is less a new rule than making visibility consistent
with the four subsystems that already assumed it.

### Two deliberate deviations, flagged not improvised

**"Contact" is not on the card.** The brief said *"Main Guardian name +
contact"*. No contact field exists — `profiles` has no phone or email, and
the only identifier available is `auth.users.email`. A personal email was
never reachable through clause 3 even at its most permissive, so exposing
one would be a **new** disclosure, which is the one thing the operating
rule says to stop for. The column returns NULL and awaits a decision on
what the channel should be.

**`ages_for()` was capped, not reduced to a single id.** Six Dart call
sites pass genuine batches; single-id-only would turn one Browse call into
up to fifty sequential round trips. Unbounded → 50 is a large reduction,
`ages_for_one()` exists for the two callers that only ever passed one, and
change 1 shrank the oracle far more than either. Say the word if you want
the literal version and I'll take the round-trip cost.

### Raised, not fixed — OA-ZYRA-173

Removing your **last** Guardian mid-Journey hands your family's Family
Review vote to the other family. The Guardian Gate checks once, at
`wali_gate`; nothing re-checks. `expected_count` drops to 1 and the other
side's Main advances alone. Tracked; the intended behaviour is a Founder
call.

---

## 8. Open, and not decided here

1. **Guardian gender governance** — ordered 2026-08-06, outstanding. Gates
   opening dual-context. Does **not** gate the predicates.
2. **`can_introduce()`** — named in §1, unbuilt.
3. **Edge-semantics declaration** — a checkable view listing every table
   with a pair of user references and flagging any that has not declared
   whether it grants visibility and whether it affects matching. Modelled on
   `zyra_data_ownership`, which already does this for ownership. Unbuilt.
4. **The broad `anon` grant sweep** across the remaining ~28 tables. RLS
   holds them today; the grants are noise that would become dangerous
   alongside one careless policy.
