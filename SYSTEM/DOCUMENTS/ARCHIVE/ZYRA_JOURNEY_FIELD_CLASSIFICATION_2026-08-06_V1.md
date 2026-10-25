# ZYRA — Journey Field Classification (Mine / Theirs / Joint)

**Status:** DRAFT — for Founder review. **Blocks OA-ZYRA-156.**
**Date:** 2026-08-06
**OA:** OA-ZYRA-155 · **DR:** DR-ZYRA-121 · **Source:** V3 §5
**Owner:** Founder, with Opus implementing
**Method:** every column read from `information_schema` on 2026-08-06, not from spec.

---

## Why this exists

A Journey attempt is a **shared** object. When one person files a subject
access request under Article 15, that object contains the other person's end
reason, their Guardian's identity, their phase answers.

Classifying now makes the export mechanical. Classifying later means a
solicitor reading nine tables line by line under a 30-day statutory clock.

**Not legal advice.** This is an engineering classification for a solicitor
to confirm.

## The three classes

| | Meaning | On a subject access request |
|---|---|---|
| **Mine** | Authored by, or solely about, the requester | Disclose in full |
| **Theirs** | Authored by, or solely about, the other party | **Withhold** |
| **Joint** | A fact about the pair; neither person's alone | Disclose — it is equally the requester's |

**The load-bearing distinction is authorship, not subject matter.** A row I
wrote about them is still Mine — the fact that I wrote it is my personal
data. That is why every `*_id` authorship column below is row-scoping rather
than a class in itself.

**Row-scoped tables.** Most tables carry an author column (`seeker_id`,
`answerer_id`, `rater_id`, `wali_id`, `sender_id`). For those, classification
is **per row, decided by that column** — not per column. Marked **ROW-SCOPED**.

---

## 1. `conversations` — JOINT

| Column | Class | Note |
|---|---|---|
| `id`, `match_id` | Joint | identifiers of a shared object |
| `status` | Joint | |
| `closed_at` | **Joint** | *see below* |
| `created_at` | Joint | |

**`closed_at` is debatable.** It is the moment one person ended things, so it
could be read as Theirs. Classified Joint because *the conversation closed*
is a fact the other person lived through and can plainly observe. **Who**
closed it is the sensitive part, and that lives on `matches.ended_by`.

---

## 2. `messages` — ROW-SCOPED by `sender_id`

| Column | Class |
|---|---|
| `id`, `conversation_id`, `created_at` | follows the row |
| `sender_id` | row scope |
| `content` | **Mine** if I sent it, **Theirs** if they did |
| `read_at` | **Theirs** — *see below* |
| `deleted_at` | follows the row |

**Two calls worth challenging.**

**Messages they sent me.** Classified **Theirs**, so withheld from an export
— but I have already read them in the app. That looks odd and is deliberate:
an export is a durable, forwardable artefact, and bulk-exporting one person's
words in a matrimonial context is a different act from having read them in
conversation. Softer alternative: disclose them but note the distinction.
**Founder decision.**

**`read_at` on my own message is Theirs.** It records *their* behaviour —
when they opened it. Whether I get a read receipt live in-app is a product
question; whether their reading times are exportable to me is a privacy one.

---

## 3. `journey_compatibility` — mostly JOINT, one exception

| Column | Class | Note |
|---|---|---|
| `match_id` | Joint | |
| `seeker_a_revealed` | Mine or Theirs | whichever side I am |
| `seeker_b_revealed` | Mine or Theirs | the other side |
| `overall_score` | Joint | computed from both; meaningless alone |
| `category_scores` | Joint | |
| `revealed_at` | Joint | |

**The reveal flags are per-person.** `seeker_a_revealed` is a record of what
one person chose to do. Mapping A/B to me/them at export time is mechanical
once `matches.seeker_a_id` is known.

**The scores are genuinely Joint** — derived from both people's answers,
about the pair. Withholding them from either would be withholding something
that is as much theirs as anyone's.

---

## 4. `journey_salams` — ROW-SCOPED by `seeker_id`

| Column | Class |
|---|---|
| `match_id` | Joint |
| `seeker_id` | row scope |
| `sent_at` | Mine or Theirs, following the row |

Trivial, and worth stating anyway: *that they sent a salam* is theirs.

---

## 5. `journey_phase_answers` — ROW-SCOPED by `seeker_id`

| Column | Class |
|---|---|
| `id`, `match_id`, `phase`, `question_id`, `created_at` | follow the row |
| `seeker_id` | row scope |
| `answer_text` | **Mine** if I wrote it, **Theirs** if they did |

**The highest-sensitivity table in the set.** Free text written during a
Journey. Their answers must never appear in my export.

---

## 6. `journey_phase_ratings` — ROW-SCOPED by `rater_id`

| Column | Class |
|---|---|
| `id`, `match_id`, `phase`, `question_id`, `created_at` | follow the row |
| `rater_id` | row scope |
| `rating` | **Mine** if I rated, **Theirs** if they did |

**A rating I gave of them is Mine.** My opinion is my personal data even
though its subject is another person. Their rating of me is Theirs and is
withheld — which will feel counter-intuitive to a requester asking "what did
they say about me". It is nonetheless correct: disclosing it would be
processing *their* opinion for *my* benefit.

**Flagging for the solicitor:** Article 15 has a limb about the *source* of
data. Whether "they rated you Amber" must be disclosed is exactly the sort of
question I should not answer alone.

---

## 7. `journey_phase_checkpoints` — ROW-SCOPED by `seeker_id`

| Column | Class |
|---|---|
| `match_id`, `phase`, `created_at` | follow the row |
| `seeker_id` | row scope |
| `decision` | Mine or Theirs |

**Their decision to continue or end is Theirs** — even though the outcome
plainly affected me. Same reasoning as ratings.

---

## 8. `journey_family_answers` — ROW-SCOPED by `answerer_id`

| Column | Class |
|---|---|
| `id`, `match_id`, `direction`, `question_id`, `created_at` | follow the row |
| `answerer_id` | row scope |
| `answer_text` | Mine or Theirs |

**`answerer_id` may be a Guardian, not a Seeker.** So a row here can be
*Theirs* in a third sense — belonging to a person who is not party to the
Journey at all. A Guardian's written answers must not reach either Seeker's
export.

**This is the table most likely to be got wrong**, because "the answer is
about my Journey" feels like it makes it mine. It does not.

---

## 9. `journey_family_reviews` — JOINT

| Column | Class |
|---|---|
| `id`, `match_id`, `from_stage`, `to_stage` | Joint |
| `opened_at`, `deadline_at`, `status`, `resolved_at`, `created_at` | Joint |

The review is a process event about the pair. Both parties experienced it.

---

## 10. `journey_family_review_responses` — ROW-SCOPED by `wali_id`

| Column | Class | Note |
|---|---|---|
| `review_id`, `responded_at` | follow the row | |
| `wali_id` | row scope | |
| `decision` | **Third-party** | *see below* |

**Neither Mine nor Theirs — a fourth case.** This is a **Guardian's**
decision. The natural reading is that my own Guardian's decision is Mine,
and it is not: it is my Guardian's personal data. They are a data subject in
their own right.

**Recommendation:** disclose to the requester only that a review occurred and
its outcome (Joint, §9), never which Guardian decided what. A Guardian
pausing a Journey and that being exportable to the Seeker they paused is a
family-safety problem, not merely a privacy one — the same reasoning as V3
§11's rule that safety endings are not routed to a Guardian automatically.

**This is the single most important line in this document.** I would not
ship the export without a solicitor confirming it.

---

## 11. `timelines` / `timeline_milestones` — JOINT

| Column | Class |
|---|---|
| `timelines.*` | Joint |
| `timeline_milestones.id`, `timeline_id`, `milestone_type`, `occurred_at` | Joint |
| `timeline_milestones.metadata` | **Joint, with a caveat** |

**`metadata` is `jsonb` and currently unconstrained** — anything a future
milestone writer puts in it inherits a Joint classification it may not
deserve. **Recommendation:** either constrain what may be written, or
classify `metadata` as non-exportable until its contents are specified.
Raised as a follow-on, not resolved here.

---

## 12. `matches` and `journey_attempts` — the parent

Not in V3's list of nine, but the classification is meaningless without it.

| Column | Class | Note |
|---|---|---|
| `seeker_a_id`, `seeker_b_id`, `created_at`, `status`, `journey_stage` | Joint | |
| `ended_at` | Joint | the ending happened to both |
| `ended_by` | Joint | **who** ended it is knowable to both |
| `end_reason` | **Theirs**, with one exception | *below* |
| `end_note` | Joint | written *to* the other person |
| `suspended_by`, `suspended_at` | Joint | the other party is told |

**`end_reason` is the hardest call in the document.**

V3 §8 rule 1: *"Only 'safety concern' is hidden from the other party. A
stated reason is kinder than silence."* So five of the six reasons are
already shown in-app and are therefore Joint in practice.

**`safety_concern` must be Theirs and must never appear in the other party's
export.** If it did, the export would become the disclosure route that V3 §3
and §11 spend considerable effort closing — and it would reach exactly the
person the protection exists to guard against.

**Recommendation:** classify `end_reason` **per value**, not per column.
Mechanically: export it unless it is `safety_concern`, in which case export
it only to its author.

Same for `protection_holds` when built (V3 §3): a `safety` hold must be
**invisible in both directions** — the barred person must never learn it
exists, including through a subject access request.

---

## 13. Summary

| Table | Shape |
|---|---|
| `conversations` | Joint |
| `messages` | Row-scoped by `sender_id` |
| `journey_compatibility` | Joint, except the two reveal flags |
| `journey_salams` | Row-scoped by `seeker_id` |
| `journey_phase_answers` | Row-scoped by `seeker_id` |
| `journey_phase_ratings` | Row-scoped by `rater_id` |
| `journey_phase_checkpoints` | Row-scoped by `seeker_id` |
| `journey_family_answers` | Row-scoped by `answerer_id` — **may be a Guardian** |
| `journey_family_reviews` | Joint |
| `journey_family_review_responses` | **Third-party (Guardian)** |
| `timelines` / `timeline_milestones` | Joint, `metadata` caveated |
| `matches` / `journey_attempts` | Joint, except `end_reason = safety_concern` |

**Eight of twelve are row-scoped or have exceptions.** The migration should
therefore carry the classification as **column comments in the database**,
not only in this document — so it travels with the schema and an export
routine can read it rather than a developer re-deriving it.

---

## 14. What I need from you

| # | Question | My recommendation |
|---|---|---|
| 1 | Approve the classification as a whole | — |
| 2 | **§2** — export messages they sent me, or withhold them? | Withhold; note the alternative is defensible |
| 3 | **§6** — must "they rated you Amber" be disclosed? | Solicitor question, not mine |
| 4 | **§10** — Guardian decisions withheld entirely? | **Yes.** Strongest recommendation in this document |
| 5 | **§11** — constrain `metadata`, or mark it non-exportable? | Non-exportable until specified |
| 6 | **§12** — `end_reason` classified per value? | Yes. `safety_concern` never leaves its author |
| 7 | Store the classification as column comments too? | Yes — it must travel with the schema |

Once approved, OA-ZYRA-155 closes and OA-ZYRA-156 is unblocked.
