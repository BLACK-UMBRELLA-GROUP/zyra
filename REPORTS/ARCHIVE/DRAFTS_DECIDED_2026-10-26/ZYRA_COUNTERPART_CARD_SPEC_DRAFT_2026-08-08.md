---
id: DOC-ZYRA-0082
type: SPEC
status: DRAFT
feature: BROWSE AND MATCHING
purpose: ZYRA — Counterpart card: joint spec draft
links: []
owner: ZYRA chat
---

# ZYRA — Counterpart card: joint spec draft

**Status:** DRAFT — engineering constraints settled, product questions open.
**Nothing built.**
**Date:** 2026-08-08
**Authors:** Claude Opus (engineering) · open items for Fable (UX) and Founder
**Supersedes nothing.** Follows `ZYRA_DUAL_ROLE_SURVEILLANCE_RESPONSE` and
Fable's convergence note of the same date.

---

## 0. State of the disagreement

Nothing left in dispute between Opus and Fable.

| Item | Outcome |
|---|---|
| Item C — refuse link over Save/Consider | **Withdrawn by Fable.** §3 of the Guardian & Romantic Rules stands. Fable adds a UX rule I accept: the silent clear must not leak — never tell the saver *why* it cleared |
| Item 7 — subscription | Routing agreed: an AD-081 amendment, both options to Founder. Substance not withdrawn, and I don't think it should be |
| Q1 / Q2 mechanism / invariants | Converged |
| **Tier-1 blast radius** | **My figures were wrong. Fable's correction is right — measured below** |
| **Main-only card (Fable's new rule 5)** | **Accepted, and the codebase already agrees — evidence below** |

---

## 1. Correction: my Tier-1 math was wrong

I costed co-ward exclusions as **C(n,2)**. `zyra_can_match` already requires
`a.gender <> b.gender`, so same-gender co-wards are *already* unmatchable and
Tier-1 adds nothing for them. The real cost is **M × F**. Measured on the
live ward sets:

| Guardian | Wards | Male | Female | My claim C(n,2) | Actual M×F |
|---|---|---|---|---|---|
| Abdul | 10 | 10 | 0 | 45 | **0** |
| Hassan | 10 | 10 | 0 | 45 | **0** |

Both of the "alarming" 10-ward Guardians would lose **nothing** to Tier-1.
The father-with-three-daughters example I used to argue Tier-1 is desirable
is also 0, not 3 — segregation already covers it. The example did no work
and I should have checked it.

**Fable's reframing is better than mine and I'm adopting it.** The lever is
not a ward cap, it is **family vs institutional guardianship**:

- A **family** Guardian's co-wards are usually relatives → Tier-1's
  assumption (co-ward ⇒ exclude) is correct.
- An **institutional** Guardian's wards are unrelated strangers of both
  genders → Tier-1 wrongly excludes M×F pairs who have nothing to do with
  each other, and none of them is told why.

And the same distinction bounds the surveillance clique, because
institutional Guardians are simultaneously the Tier-1 harm and the blast
radius. One decision resolves both. That is a materially better frame than
"cap the wards", which I had been heading toward.

**Engineering position unchanged:** Tier-1 belongs in `zyra_can_match`, per
§5 — RLS, not a trigger. The index (`wali_links_wali`) already exists.
Whether it applies to institutional links is the Founder's call.

---

## 2. Main-only card — accepted, and the codebase already votes for it

Fable's rule: only the **Main** Guardian receives the counterpart card;
Additional Guardians get clause 2 (own ward) only.

I audited every object that reads `wali_links`. **13 honour `is_main`. 8
ignore it.** The split is not random:

| Honour `is_main` — deliberately designed | Ignore `is_main` |
|---|---|
| `wali_review_decision` · `resolve_family_review_if_due` · `reopen_family_review` · `guardians_for_unlocked` (the paid product) · `zyra_set_main_guardian` · `zyra_remove_guardian` · `zyra_clear_main_guardian` · `zyra_guardian_activity` · `auto_designate_main_wali` · `zyra_advance_stage` | **`zyra_attempt_participant_rows`** · **`zyra_can_view_profile`** · `zyra_attempt_summary_for_guardian` · `zyra_match_ending` · `accept_wali_invite` · `zyra_can_match` · `zyra_can_guardian_link` · `wali_has_wali_one` |

**Every layer someone sat down and designed honours `is_main`. The
visibility layer, which accreted, does not.** Family Review has treated Main
as a real privilege boundary since 2026-07-26. So rule 5 is less a new rule
than making visibility consistent with the four subsystems that already
assume it.

Two of the "ignore" entries are correct as-is and should not change:

- `zyra_attempt_summary_for_guardian` returns **own-ward dates only** — no
  counterpart identity. An Additional Guardian seeing their own ward's
  Journey dates is clause-2 legitimate. **No change needed** — one less
  thing in the build.
- `zyra_can_match` / `zyra_can_guardian_link` are about *romance*, where the
  Main/Additional distinction is irrelevant — any active link disqualifies.

---

## 3. 🔴 New finding: a Seeker can silently hand their family's Family Review vote to the other family

Found while checking rule 5's dependency on there always being a Main.

`zyra_remove_guardian` is well guarded — you **cannot** remove your Main
while other Guardians remain (`main_guardian_must_be_reassigned`), because
nothing would promote a replacement. Good, and it anticipated exactly this.

But **removing your *last* Guardian is deliberately allowed** — reasonably,
since an empty Guardian page is a recoverable state. Mid-Journey, it is not
recoverable, and nothing re-checks. `wali_review_decision` computes:

```sql
select count(distinct wali_id) into expected_count
  from wali_links where status='active' and is_main
    and seeker_id in (m.seeker_a_id, m.seeker_b_id);
...
if expected_count >= 1 and continued_count >= expected_count then  -- ADVANCE
```

With one side at zero Mains, `expected_count` becomes **1**, so **the other
family's Main Guardian alone advances the Journey on behalf of both
families.** The Guardian Gate checks both Mains once, at `wali_gate`; nothing
re-checks afterwards.

Under Fable's rule 5 this also silently removes that family's counterpart
card. The two failures compound.

This is adjacent to **OA-ZYRA-150 (Guardian-unavailable path)**, which is
parked. I'd argue this specific case is not the parked question — that one is
about a Guardian who is *unresponsive*; this is a Seeker unilaterally
removing their family from a review that is currently open. Needs its own
OA. **Not fixed here.**

---

## 4. Question (a) — the field list

Product decides the fields. Four engineering constraints shape what is
cheap, what is expensive, and what is a trap.

### 4.1 · A photo is not free

`zyra_can_read_photo_object()` delegates to `zyra_can_view_profile()`. The
moment Guardians leave clause 3 they lose counterpart photo access
**entirely** — which is the correct default. If the card is to carry a
photo, that is a **separate signed-URL path with its own predicate**, not a
field on a projection. Assume "card includes a photo" costs a second piece
of work, not a column.

### 4.2 · 🔴 Per-user configurable cards leak

Fable's note says *"the counterpart should consent to what it shows"*. If
that means each person chooses their own card fields, **the choice itself
becomes the signal** — a sparse card says something about the person, and
"hidden city" is information.

This is the Step 0 lesson exactly: *if the substitution is detectable, the
substitution is the disclosure.* Recommend **one uniform card for everyone,
plus disclosure** ("this is what the other family's Guardian sees"), rather
than per-user consent over fields. Simpler, and strictly more private.

If per-field consent is wanted anyway, it must be **all-or-nothing** —
either your card shows or no card shows — because that is the only variant
with no gradient to read.

### 4.3 · The `consents` table does not fit as-is

`consents(user_id, consent_type, granted, policy_version, recorded_at)` is
**per-user, per-type, global**. It cannot express "I consent to *this
attempt's* counterpart Guardian seeing X." A per-relationship consent needs
new storage. Another argument for uniform-plus-disclosure, which needs none.

### 4.4 · The test each field must pass

Fable is right that a wali assessing a family needs more than a first name.
The constraint I'd hold every candidate field to:

> **Does a Guardian need this to decide whether to let the families talk —
> or only to satisfy curiosity about the counterpart?**

| Field | My read |
|---|---|
| Counterpart Guardian's name + contact | **Yes.** This is the card's purpose — two families connecting |
| Counterpart Seeker's first name | **Yes.** You cannot discuss a person you cannot name |
| Age | **Probably** — a material suitability fact, already disclosed via `ages_for()` today |
| City | **Open.** Genuinely used in family assessment; also the single most useful field for locating someone in a community that hides being on the app |
| Photo | **Recommend no.** Not needed for the decision, and it is the field that turns a card into surveillance. See 4.1 |
| Chapter answers, full profile, all photos | **No.** Never |

---

## 5. Question (b) — directionality

**Recommend: build symmetric Main-only now; treat asymmetry as a later
narrowing.**

The reasoning is the same as Step 0's strict default. Asymmetry would have to
key on gender, and *the meaning of gender in the Guardian role is exactly
what is unresolved* (can a woman be a Guardian?). Keying a visibility rule on
an axis whose semantics are open is how a rule ends up enforcing something
nobody decided.

Symmetric Main-only is already a very large reduction — from "every Guardian
of both sides sees every participant's full profile" to "two Main Guardians
exchange a card". Narrowing it further later is easy. Widening later is a
disclosure. Take the reduction now, decide directionality with the female-
Guardian question, together.

---

## 6. Build order — confirmed

Fable's ordering, adopted, with §3 added as an OA rather than a build.

| | Work | Notes |
|---|---|---|
| 1 | Scope clause 3 — remove Guardians, add the counterpart card, **Main only** | Blocked on the §4 field list only. The *removal* half is not blocked and closes most of the exposure on its own |
| 2 | `is_main` into the participant model | Enforces 1, and gives Additional a meaning |
| 3 | Narrow `ages_for()` to a single id | Trivial; I10 |
| 4 | `can_match` re-base off `seeker_profiles`, delete `role` | Gates dual-role |
| — | **New OA: last-Guardian removal mid-Journey (§3)** | Not the parked OA-150 question |

**Splitting item 1 is worth considering.** Removing Guardians from clause 3
needs no product input and closes rows 2–8 of the surveillance measurement,
plus photos and ages. Adding the card needs §4 settled. Shipping the removal
first means a short window where Main Guardians have *less* than the final
design intends — which is the safe direction to be wrong in.

---

## 7. For the Founder

1. **Institutional vs family guardianship as a distinct class** — resolves
   Tier-1 scope *and* the surveillance blast radius in one decision (§1)
2. Tier-1 in `can_match` — engineering agreed, scope depends on 1
3. Counterpart card field list, and **uniform vs per-user** (§4.2 — I
   recommend uniform + disclosure)
4. Photo on the card — recommend no (§4.1)
5. Directionality — recommend deferring, ship symmetric (§5)
6. **AD-081 amendment**: *"no paid state on the Guardian's side may break the
   ward's Journey continuity"* — met by the ward's assignable Guardian+
   entitlement, or by making basic guardianship unconditional? Both to you
7. Female Guardians — still open, and now gating §5
8. New OA for §3
