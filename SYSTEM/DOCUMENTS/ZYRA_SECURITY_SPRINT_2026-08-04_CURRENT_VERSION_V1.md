---
id: DOC-ZYRA-0165
type: SPEC
status: CURRENT
feature: GENERAL
purpose: ZYRA — Security Sprint, 2026-08-04
links: []
owner: ZYRA chat
---

# ZYRA — Security Sprint, 2026-08-04

**Status:** COMPLETE — every finding closed and re-tested
**Authorised by:** Founder, 2026-08-04
**Trigger:** `ZYRA_INDEPENDENT_REVIEW_2026-08-04_V1.md` (Fable), reproduced
independently before any fix
**Method:** every exploit executed against the live database before the fix
and again after

---

## 1. What was closed

| # | Finding | Was | Now |
|---|---|---|---|
| C-1 | Free unlocks → Article 9 disclosure | Client `INSERT` on `profile_unlocks`; two HTTP requests returned a stranger's sect, revert status, ethnicity, birth country and nationality | `unlock_credits` ledger + `zyra_unlock_profile()` RPC. Client holds no write on `profile_unlocks` at all |
| C-3 | Privilege escalation | `authenticated` could `UPDATE` `role`, `date_of_birth`, `gender`, `profile_complete` — and the `role` CHECK explicitly permits `'admin'` | Creation and publication behind RPCs; column-level grants limit direct writes to name, city, bio, visibility |
| C-4 | No minimum age | Zero CHECK constraints on `date_of_birth` | `profiles_adult_only` + a 1900 sanity bound |
| H-1 | Gender segregation client-side | RLS allowed reading every active profile of either gender | In `profiles_select`, via `zyra_can_view_profile()` |
| H-2 | `ages_for()` unauthorised | Any UUID, no check — partially undid the July DOB fix | Same visibility predicate |
| H-3 | `score_candidates()` unauthorised | An inference oracle for another member's religious answers | Same visibility predicate |
| H-5 | Anonymous EXECUTE | 9 `SECURITY DEFINER` functions callable by `anon` | 0 |
| H-6 | Mock fallback | 5 `return mockProfiles` paths in `fetchCandidates` | Empty list, every path logged |

### Verification, after

| Attack | Result |
|---|---|
| Forge an unlock row → read Article 9 data | blocked |
| Mint own credits | blocked |
| Self-promote to `admin` | blocked |
| Falsify age to 11 | blocked |
| Read same-gender profiles | 0 visible |
| Age of a profile I cannot see | 0 rows |
| Score a profile I cannot see | 0 rows |
| Anon calls a `SECURITY DEFINER` function | 0 of 35 reachable |
| **Browse still works (opposite gender)** | **12 profiles — not broken** |

Supabase security advisor: `anon_security_definer_function_executable` 9 → 0,
`function_search_path_mutable` 2 → 0.

---

## 2. The entitlement ledger

Founder: *"the permanent entitlement system rather than a temporary
solution."*

`unlock_credits` is append-only. Balance is `sum(delta)` per user per tier,
never a stored integer — a column that goes up and down cannot answer *why*
someone has four credits, and a lost update silently destroys money.

| reason | meaning |
|---|---|
| `zyra_one_included` | bundled with ZYRA One, granted by trigger, one-time per user |
| `purchase` | real money, when payments exist — one more row, no architecture change |
| `debug_grant` | `@zyra.test` accounts only |
| `spend` | consumed by an unlock |
| `refund` / `adjustment` | corrections, as new rows |

A CHECK ties sign to reason, so a bug cannot write a positive `spend` and
mint credits.

**Permanence is server-side now.** Revisiting an unlocked profile returns
`already_unlocked, charged: false` — a double tap on a slow connection
cannot spend twice.

---

## 3. Three things worth recording

### 3.1 Why my own earlier verification missed C-1

Building `seeker_details` I proved RLS blocked *reading* the table, and it
did. I never tested whether the gate itself could be forged. Three
properties got conflated:

| | |
|---|---|
| **Uniqueness** | you cannot unlock the same profile twice — the index |
| **Integrity** | the row says what it claims — was true |
| **Entitlement** | you were allowed to create it — **nothing enforced this** |

Only the third matters for payment.

### 3.2 The same permissions trap, three times in one day

| | Revoked from | Left behind |
|---|---|---|
| morning | `PUBLIC` | anon's explicit grant |
| afternoon | `anon` | the `PUBLIC` grant |
| evening | `public, anon` | the `authenticated` grant |

`PUBLIC`, `anon` and `authenticated` are three independent grants. The only
reliable idiom is `REVOKE ALL FROM public, anon, authenticated` then grant
back exactly what is needed. Each was caught by checking
`has_function_privilege` rather than trusting the statement.

### 3.3 Two traps in H-1 that the seed data hides

A naive opposite-gender policy passes every test here and breaks in
production:

1. **Same-gender Guardian.** A wali is typically male — father, brother,
   paternal uncle. A male Seeker with a male Guardian is ordinary, and the
   naive rule stops that Guardian reading his own Seeker. **Zero such pairs
   exist in seed data.**
2. **Guardian reading a match partner.** A male Guardian of a female Seeker
   must read her *male* partner. The naive rule breaks the Guardian journey
   view — the feature the Founder calls the moat.

Both have explicit clauses. The rule is not "opposite gender"; it is
"opposite gender **when browsing**", with every other relationship named.

---

## 4. Documentation needing updates

| Document | Change |
|---|---|
| `ZYRA_DATABASE_SCHEMA_CURRENT_VERSION_V1.md` | Add `unlock_credits`, `consents`, `seeker_details`; record the `profiles` column-grant change |
| `ZYRA_ENGINEERING_AUDIT_CURRENT_VERSION_V1.md` | July C4 (privilege escalation) is now **closed** |
| `ZYRA_ARCHITECTURE_CURRENT_VERSION_V2.md` | Still says "State Management: TBD" — five weeks. Add the enforcement principle below |
| `APP/Premium/Profile Unlocks/Summary.md` | Unlocks now require a credit; document the ledger and the ZYRA One grant |
| `APP/Browse/...` | Browse shows a genuine empty state; there is no mock fallback |

**Proposed engineering principle, from ChatGPT's framing:**
> If a document promises a guarantee, a database object must enforce it.

Every critical finding in this review was one instance of that rule being
absent.

---

## 5. Still open

| Item | Note |
|---|---|
| **C-2** | Unlock returns raw attributes, not derived insights. Founder decision, deliberately excluded from this sprint, needed before the solicitor is briefed |
| **Payments** | No SDK. The ledger is ready — a receipt becomes a `purchase` row |
| **C-5 end-to-end** | `matches` = 0. Nothing past matching has ever executed |
| **Leaked-password protection** | Disabled. Dashboard toggle, Auth → Policies. Cannot be set via SQL |
| **75 silent `catch (_)`** | Against 37 `debugPrint`. Reduced today, not solved |
| **`v_ch2_weight = 1`** | Chapter 2 currently moves the score by a few percent. Founder decision |
| **ZYRA One credits: once or monthly?** | Granted **once**. Monthly needs a scheduled job that does not exist |

---

## 6. Is another independent review recommended before beta?

**Yes — but not yet. After the end-to-end walkthrough, not before.**

Reasoning:

- **This sprint should not be reviewed by its author.** I verified every fix
  against the live database, and I also wrote them. C-1 is the proof that
  matters: I had already "verified" that area and missed it, because I
  tested the property I had thought about rather than the one that counted.
- **A review now would review the wrong thing.** The most valuable target is
  the half of the product that has never executed — Journey, Family Review,
  chat, the Guardian view. Reviewing it before it has run once means
  reviewing source code, not behaviour.
- **Suggested order:** two real accounts complete onboarding, match, and
  walk a Journey end to end → *then* an independent review covering both the
  security changes and the newly-exercised flows.

One narrower review is worth doing sooner: **the RLS policy set**, by
someone who did not write it. `zyra_can_view_profile()` is now load-bearing
for `profiles_select`, `ages_for` and `score_candidates` — a single function
whose logic three separate protections depend on. That concentration is
good design and a single point of failure at the same time.
