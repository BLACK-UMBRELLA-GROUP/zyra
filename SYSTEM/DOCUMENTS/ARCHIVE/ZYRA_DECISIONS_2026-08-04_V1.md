# ZYRA — Decisions of 2026-08-01 to 2026-08-03

**Version:** V1
**Status:** RECORD — all items Founder approved and implemented
**Author:** Claude (Opus), Implementation Lead

Two days of decisions, several of which **reversed earlier ones**. Recorded
in one place because the reversals are the part most likely to be undone by
accident: each superseded decision was itself deliberate, argued in code
comments, and would otherwise look like a mistake to the next reader.

---

## 1. One state per profile — REVERSES 2026-08-01

| | |
|---|---|
| **1 Aug** | Saved was a **bookmark** on its own axis. Saved + Considering was valid and intended. |
| **3 Aug** | Saved, Considering and Declined are **mutually exclusive**. Most recent action wins. |

Founder, on seeing one profile under both CONSIDERED and SAVED: *"a user
can't be both saved and considered, so there's an error there."*

The two-axis model was coherent and the data was never wrong. It lost on
the only ground that matters — shown a person in two places, the Founder
read it as a bug every time. A model that needs explaining before a screen
makes sense is the wrong model.

**Enforced in three layers**, so a client that forgets cannot break it:

- `AppState._clearState()` runs before every transition
- Three database triggers: each insert into `saves`/`likes`/`passes` clears the other two
- `test/decision_model_test.dart` — every ordering asserts exactly one state

**Live data was migrated.** 30 pairs held both a save and a like; resolved
by most recent action. 60 rows became 30, zero conflicts remain.

**Consequences that followed automatically:** a saved profile now leaves
the Browse deck, and the Browse "Saved" badge became unreachable and was
removed.

---

## 2. Compatibility Unlock — renamed, repriced, permanent

Was "Profile Unlock". Full detail in
`APP/Premium/Profile Unlocks/Summary.md`; the short version:

| | |
|---|---|
| Name | Compatibility Unlock / Compatibility Unlock Plus |
| Button, unlocked | "View Compatibility", permanently |
| Price | £1.99 / £7.99 · £2.99 / £9.99 (was £0.99/£2.99 · £1.99/£4.99) |
| ZYRA One | 3 free Unlock Plus credits |
| Permanence | Once per profile per tier. Revisiting never charges again. |

The rename fixed a real inconsistency: `Profile Unlock → View
Compatibility` implied two features. `Compatibility Unlock → View
Compatibility` is one idea stated twice.

Permanence is enforced by a **unique index**, not by client checks — a
double tap on a slow connection would otherwise write twice and, once
payments are real, charge twice.

**Rejected:** a "each unlock is permanent" line beside the price. Founder:
*"the user will know."*

---

## 3. Connections structure

| Journeys tab | |
|---|---|
| Active Journey | Emphasised — full-white label, brighter card |
| **Journey Queue** | Was "Potential Journeys" |
| Paused Journeys | |
| **Ended Journeys** | New section, always visible |

"Potential" suggested uncertainty when these are **confirmed mutual
likes** waiting on the user. "Queue" also carries the
one-Active-Journey-at-a-time rule without stating it.

Ended Journeys previously appeared only once something had ended, so
nobody could discover it existed. Founder's stated purpose: *"gives users
closure instead of a Journey disappearing."*

**IMPORTANT — `matches.status` still uses `'potential'`.** Only the display
name changed. Renaming the status value would break RLS policies, service
queries and the promote RPC. Archived dated documents were also left
unchanged, as historical record.

---

## 4. Blocked Users → Settings

Blocked users never appeared in Connections — `profile_blocks` hides them
both ways through RLS. What was missing was anywhere to **see** them:
blocking was one-way, and `unblock()` existed in the service with no
caller.

So this was not a move. It was the missing half of a feature that shipped
with only its first half.

---

## 5. Limits

| | Was | Now |
|---|---|---|
| Save — ZYRA Basic | 10 | **5** |
| Save — ZYRA One | 50 | **15** |
| Consider — Basic | 25 | 25 (confirmed, not changed) |
| Consider — ZYRA One | unlimited | unlimited |

Founder: *"for ZYRA One Seeker 50 profile saves is a lot."* Agreed — a
shortlist of 50 is a second Browse queue, which contradicts the product's
own argument that you should leave, married, rather than accumulate
options.

Upgrade copy deliberately **does not name** ZYRA One's cap: naming it turns
a benefit into a ceiling.

---

## 6. Reference data — production lists

`mock_reference_lists.dart` held 30 countries, 20 languages, 12
ethnicities. A Seeker from Kenya, Kosovo, Uzbekistan or Sri Lanka could not
answer "which country were you born in".

Replaced with 197 countries (ISO 3166-1, each with a demonym), 184
languages (ISO 639-1) and 29 ethnicities.

**THE RULE THAT CAME WITH IT: store the code, never the label.** Relabel
"Turkey" to "Türkiye" and no user row changes, because the row says `TR`.

This was load-bearing immediately — ISO 639-1 names two of this audience's
most-spoken languages "Panjabi" and "Pushto", spellings nobody would
search for. The labels are corrected while the codes stay canonical. Had
the label been the stored value, fixing them would have orphaned every
affected user.

---

## 7. Persistence closed

| | |
|---|---|
| Declines | `passes` table, RLS, verified |
| Reset Search | `zyra_reset_search()`, clears Declined only |
| Decisions on launch | Hydrated in `ZyraSessionRouter` |
| Gender for first paint | Cached on device — no more purple-to-pink flash |

The gradient flash was **never a build-mode problem**. It was a network
round trip, and a real user on mobile data would have seen it longer than
the Founder did on wifi.

---

## 8. Still open

- **Chapter 2 persistence.** Onboarding asks 31 questions and discards 27. Nothing can be built on compatibility until this lands — see `ZYRA_ONBOARDING_PERSISTENCE_AUDIT_CURRENT_VERSION_V1.md`.
- **Payments.** No SDK in the project. Every price above is currently unchargeable.
- **Compatibility scoring.** Method undefined; `onboarding_answers` empty.
- **Article 9 consent step** for sect, revert status and ethnicity.
- **200 seeded Supabase profiles.** Colour-block versions exist behind a dev toggle; real rows still need 200 auth accounts.
