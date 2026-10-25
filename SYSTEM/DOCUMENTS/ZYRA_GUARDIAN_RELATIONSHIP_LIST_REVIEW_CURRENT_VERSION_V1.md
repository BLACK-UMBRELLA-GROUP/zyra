---
id: DOC-ZYRA-0187
type: REPORT
status: CURRENT
feature: GUARDIAN NETWORK
purpose: ZYRA — Guardian Relationship List: Review
links: []
owner: ZYRA chat
---

# ZYRA — Guardian Relationship List: Review

**Status:** FOR DECISION — do not lock the list yet
**Date:** 2026-08-07 · **Reviewing:** ChatGPT's 25-value proposal

---

## Agreed without reservation

- **Chips grouped by category**, not a dropdown. Correct at this length.
- **No free text.** Right, and for the reasons given: moderation, naming
  drift, and the fact that permissions and filtering must be able to read
  this value.
- **"Other" with no description field.** Right. It stops anyone being forced
  into a wrong answer without creating a text field to police.
- **New values added as official options after launch**, not by loosening it.
  Widening an enum is additive; removing a value orphans live rows.
- **The re-worded question.** *"What best describes their role in your
  marriage journey?"* is better than *"How are you related?"* because Imam,
  Legal Guardian and Family Friend are roles, not relations.

---

## Three reasons not to lock it today

### 1. It silently decides the Guardian gender question

The list adds **Mother, Sister, Aunt, Daughter, Niece, Wife, Mother-in-law,
Sister-in-law** — eight female values.

`ZyraProfileService.createWaliProfile` currently hardcodes `gender: 'male'`
for every Guardian, and `WALI_ARCHITECTURE_CURRENT_VERSION_V6` is the
approved source of truth on that. **The Founder ordered a separate
governance review of the male-Guardian model on 2026-08-06 and it has not
happened.**

Adopting this list answers that question by implication rather than by
decision. That is exactly the pattern we removed from the relationship
capture point this afternoon — a rule arrived at by implementation instead
of intent.

**The gender review must land first.** Not because the answer is obviously
no, but because it should be an answer.

### 2. Some values are religious questions, not product ones

The Guardian is the **wali**. In Islamic marriage law the wali for a woman
is a specific role with a defined order of entitlement — father, paternal
grandfather, son, brother, paternal uncle — and a defined fallback to
**wali al-hakim**, the judge or, in practice, an imam, when no family wali
exists.

Against that:

| Proposed | Concern |
|---|---|
| **Imam** | Has genuine standing as the fallback wali. Sound |
| **Legal Guardian** | Sound — a real civil relationship |
| **Family Friend** | No standing as a wali. What is this person's authority? |
| **Trusted Friend** | Same, and weaker |
| **Cousin** | A PATERNAL male cousin may qualify; a maternal one generally does not. "Cousin" loses exactly the distinction we deliberately kept when we chose "Paternal Uncle" over "Uncle" |
| **Husband / Wife** | **Incoherent.** A Seeker looking for marriage does not have a spouse. Remove |

**I am not qualified to rule on these and neither is the product team.**
This list needs the same scholarly review as the Guardian gender model, and
probably in the same session.

### 3. It reintroduces an ambiguity we already removed

We currently store `uncle` and display it as **"Paternal Uncle"** — a
deliberate decision on 2026-08-06, because the paternal distinction is
religiously meaningful. The proposed list has a bare **"Uncle"** and a bare
**"Cousin"**, which drops that distinction in two places.

Either the list keeps the paternal qualifier throughout, or the earlier
decision should be reversed knowingly. Not both.

---

## One structural point in its favour

The list mixes directions — **Father** and **Son** both appear — and that is
correct, but only because of the rule ratified this afternoon:

> The relationship is a statement about the **Guardian**, so the Guardian
> makes it.

Every value is read as *"I am her ___"*. A son acting as wali for his
widowed mother is a real and recognised case, so **Son** belongs. It only
works because the direction is fixed. **The list must be labelled with that
direction wherever it appears**, or the first person to add a value will add
it from the Seeker's point of view and nobody will notice.

---

## What I would do

1. **Hold the list.** It is close, and locking it now bakes in two decisions
   that belong elsewhere.
2. **Run the Guardian gender governance review** — already ordered, still
   outstanding.
3. **Put the religious questions to a scholar**, alongside the gender model:
   Family Friend, Trusted Friend, Cousin, and the paternal qualifiers.
4. **Remove Husband and Wife** regardless of the above. They cannot describe
   a Guardian of someone seeking marriage.
5. **Ship the acceptance UX against the CURRENT seven values.** The picker
   does not care how many chips it renders, so the UX is not blocked by
   this — and building it now means the list can be widened later without
   touching the screen.

The last point matters: **this does not block the invitation flow.** The
grouped-chip layout works with seven values or twenty-five, so the UX can be
built and reviewed while the list is settled properly.
