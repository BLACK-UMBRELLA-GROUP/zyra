---
id: DOC-ZYRA-0221
type: PLAN
status: CURRENT
feature: JOURNEY
purpose: OA-ZYRA-159 — Request New Journey · Implementation Plan
links: []
owner: ZYRA chat
---

# OA-ZYRA-159 — Request New Journey · Implementation Plan

**Date:** 2026-08-10 · **Status:** PLAN — nothing built, nothing migrated
**Authority:** DR-ZYRA-121 item 8 (Founder-approved 2026-08-06), OA-ZYRA-159 (Open — approved)
**Trigger:** Founder, 2026-08-10 — chose "build OA-159 first, then Request New Journey"
in preference to a placeholder on the Ended Journeys row.

---

## 0. Read this part if you read nothing else

- **The zero-data window is still open.** Measured today: `matches` 0 rows,
  `journey_attempts` 0 rows, `conversations` 0, `messages` 0, `profiles` 149.
  This is still a DDL-only change with no data migration — the condition
  DR-121 called "the strongest argument for acting now", four days on.
- **The previous session left the accept path ready.** `restart_journey`'s
  live body carries the whole non-destructive reopen logic in comments,
  labelled *"Preserved for OA-ZYRA-159, which will run this AFTER the other
  party accepts"*, already stripped of every DELETE. That is most of stage 4.
- **Three things the approved design assumes, which do not exist.** Listed
  in §3. One of them will throw at runtime if it is not handled in the same
  migration.
- **One architectural fork needs your call before I write SQL** — §4.
- Estimated build: **five stages**, each independently verifiable and safe
  to stop after.

---

## 1. What is approved, verbatim

From OA-ZYRA-159 and DR-ZYRA-121 item 8. Not restated from memory — quoted
from the registers.

| Rule | Approved wording |
|---|---|
| Consent | One person requests; the other decides. **Never unilateral, never a resurrection** |
| Freshness | A new attempt starts fresh with its own timeline |
| Recipient options | **Accept · Decline · Decline and don't ask again** |
| Plain decline | 6-month cooldown |
| Don't ask again | Permanent |
| Asymmetry | **The requester is never told which.** Both render identically as no option to request |
| Expiry | Unanswered request expires after 14 days; **expiry counts as a decline** for cooldown |
| Decline notification | A decline **does** notify — "hiding it behind the expiry would mean fourteen days of hope for something already answered" |
| History | All Journey history preserved. Nothing deleted (DR-121 item 3) |
| Supersession | Supersedes `restart_journey()` entirely |

The 6-month and 14-day figures are recorded in DR-121 item 16 as
**deliberately unanswered guesses**, flagged for post-launch review
(V3 §16 items 14, 15). I am building them as configurable constants, not
scattered literals, so revisiting them is a one-line change.

---

## 2. Six-layer read — what I actually read

Per §3b of CLAUDE.md. Verified against the **live database** on 2026-08-10,
not against the repo, because the repo is ~78 migrations behind.

| Layer | Read? | What it showed |
|---|---|---|
| 1 · Schema | ✅ | `journey_attempts` (13 cols) exists with `attempt_number`, UNIQUE `(match_id, attempt_number)`. No request or cooldown table exists |
| 2 · RLS | ✅ | `journey_attempts`: **RLS on, ZERO policies**. `matches`: 1. `notifications`: 2 |
| 3 · RPC bodies | ✅ | `restart_journey` raises `restart_requires_mutual_consent` before doing anything; `zyra_end_match_internal` already maintains both `matches` and `journey_attempts` |
| 4 · Triggers / constraints | ✅ | 9 CHECKs on `journey_attempts`, 8 on `matches`, 1 on `notifications` — see §3 |
| 5 · Client | ✅ | **Zero Dart call sites for `restart_journey`.** The button was retired 2026-08-06 (`journey_flow_screen.dart:450`). `canRestart` survives only to write a subtitle |
| 6 · Documentation | ✅ | OA-159, DR-121, Lifecycle V3, contradiction audit 4.2 |

### Dependency trace — what points at this

| Object | Points at it | Consequence |
|---|---|---|
| `zyra_can_match(a,b)` | Blocks, Tier-0, Tier-1 shared-Guardian exclusion | A request must not create a path around it |
| `zyra_can_continue_journey(a,b)` | EXECUTE **revoked** from `authenticated` (OA-174 fix) | Must be called from inside SECURITY DEFINER, never the client |
| `create_notification(...)` | Not granted to `authenticated` | Same — server-side only |
| `matches_check` | `seeker_a_id < seeker_b_id` | Canonical pair ordering; a request row must respect it or joins silently miss |
| `zyra_my_attempt_participation` | The only readable route into attempts | Any policy joining `journey_attempts` directly is **false for everyone** |

---

## 3. 🔴 Three discoveries — raised before implementing, per CLAUDE.md §2

**D1 · `attempt_visible_to()` does not exist.**
DR-121 item 4 declares it *"the SINGLE SOURCE OF TRUTH for authorisation …
every RLS policy, service and future role asks that one question."* It was
approved on 2026-08-06 and never built. So the new request table has nothing
to defer to. Either it is built now (scope grows, and OA-156 stage 7 gets
easier), or the request policies are written inline — creating exactly the
duplication item 4 exists to prevent.

**D2 · `notifications_type_check` permits four types only.**
`new_match · new_message · wali_request · journey_ended`. OA-159 requires at
least `journey_request` and `journey_request_declined`. **An INSERT of any
other type throws.** This is the same shape as audit finding 4.9 — the
Guardian prompt that could never fire because the code wrote a status the
CHECK forbade. The constraint must be extended in the same migration as the
first notification write, or the feature ships broken in exactly the way this
project has already been bitten by twice.

**D3 · `journey_attempts` has RLS enabled and zero policies.**
Every row is invisible to `authenticated`. Joining it inside any new policy
makes that policy false for everyone and *silently* breaks the feature. All
lifecycle reads go through `zyra_my_attempt_participation` or a SECURITY
DEFINER function. Recorded so nobody re-finds it.

---

## 4. ⚠️ The one decision I need before writing SQL

**Where does the decline cooldown live?**

DR-121 item 5 approves `protection_holds` (OA-ZYRA-157) as the general
mechanism: *"Protection is the result of one or more active holds… A SAFETY
HOLD IS NEVER APPEALABLE, because the barred person must never learn it
exists."* **`protection_holds` does not exist either.**

A decline cooldown has the identical shape — the requester must never learn
which decline occurred. That is an argument they are one primitive, not two.

| | **A · Cooldown on the request row** | **B · Build OA-157 first, cooldown is a hold** |
|---|---|---|
| Scope | OA-159 alone | OA-157 + OA-159 |
| Schema | One table, `journey_requests` | Two: `protection_holds` + `journey_requests` |
| Truer to DR-121 | Partially — item 8 only | Yes — items 5 and 8 together |
| Later cost | A migration when OA-157 lands, on live data | None |
| Risk | Two mechanisms answering "may I request?" | Larger single change |

**My recommendation: B.** Not because it is tidier — because the zero-data
window closes the day the first real match happens, and A knowingly schedules
a second migration for after that point. The whole reason DR-121 said act now
was to avoid exactly that. The extra work is one table and one predicate.

**If you want the Ended row working sooner, A is defensible** and I will say
so plainly rather than pretend otherwise. It is a real trade, not a wrong
answer.

---

## 5. Staged build — after your answer to §4

Per CLAUDE.md §3c. Every stage is additive and leaves the system whole; if a
stage cannot be left unfinished safely, it is too big.

| # | Stage | Verification before moving on |
|---|---|---|
| 1 | Extend `notifications_type_check`; add the two new types (D2) | Insert each new type as `authenticated`, roll back |
| 2 | `protection_holds` + `attempt_visible_to()` *(only if §4 = B; D1)* | Policy returns true for participants, false for a third party — by impersonation, not by reading |
| 3 | `journey_requests` table + RLS. No RPCs yet | Requester and recipient each see their own row; a third party sees none |
| 4 | `request_new_journey()` · `respond_to_journey_request()` · reuse the preserved accept logic from `restart_journey`'s comment block | Accept creates attempt #2 with a fresh timeline and **zero deletions**; both decline types render identically to the requester |
| 5 | Expiry sweep (14 days → counts as decline) + Dart: replace the Ended chevron with **Request New Journey** | Full `zyra_journey_suite.sql` before and after; `flutter analyze` on the Mac |

**Not in scope, deliberately:** OA-161 notification map, OA-160 reference
codes, OA-163 audit log. Each is its own OA and none blocks this.

---

## 6. What I did not review, and the risk that carries

- **The Guardian view of a new attempt.** OA-162 makes Guardian involvement
  per-attempt with a fresh Family Review. I have not traced what a Guardian
  sees while a request is pending. Risk: a Guardian may see a stale card for
  the ended attempt. Named, not measured.
- **Push delivery.** There is no push infrastructure; notifications are rows.
  The decline notification will be in-app only.
- **`zyra_journey_suite.sql` assertions 35 and 48** both pin current
  notification and Tier-1 behaviour. Stage 5 must re-run the whole file, not
  fragments — assertion counts are not the max assertion number.

---

## 7. Register entries this will need

| Register | Entry |
|---|---|
| Decisions | `DR-ZYRA-135` — the §4 choice, once made |
| Outstanding Actions | OA-ZYRA-159 → In Progress; OA-ZYRA-157 → In Progress if §4 = B |
| New OA | `OA-ZYRA-184` — `attempt_visible_to()` was approved in DR-121 item 4 and never built (D1), if §4 = A leaves it unbuilt |

Nothing above is written to a register yet. Registers are appended after the
Founder decides, not before — and re-read immediately before appending,
because concurrent sessions have twice moved them between two reads.
