---
id: DOC-ZYRA-0294
type: REPORT
status: CURRENT
feature: DATABASE
purpose: Read-only check of the live ZYRA database on 26 Oct 2026 - which migrations are applied, the live message rule, missing functions, test data, developer functions and Supabase's security advisor
links: [OA-ZYRA-312, OA-ZYRA-319, OA-ZYRA-317, DOC-ZYRA-0280, DOC-ZYRA-0293]
owner: Fable
---

# ZYRA — LIVE DATABASE CHECK — 26 OCT 2026

Founder GO 26 Oct ("a"). **Read only:** Supabase connector `list_migrations`, `get_advisors` and `SELECT` queries returning counts
and definitions — no personal data was read and nothing was changed. Project `sxoaxonzjqkgajmlagyk` (eu-west-1, Postgres 17,
healthy). Repository = `ZYRA/SOURCE/supabase/migrations/` (228 files).

**A snapshot of 26 Oct 2026.** Re-run the same read-only check before any production change, and before relying on it
after 9 Nov 2026.

## In five lines

1. **The safety problem is not live.** Production still has the safe 9 Aug message rule (blocks, active conversation, active
   Journey, Seekers only). The weaker rule exists only in an unapplied repository file.
2. **Production is about two months behind the repository:** 17 repository files from 25 Aug – 5 Oct were never applied.
3. **There are no real members yet:** 153 accounts, of which 149 are `@zyra.test` test accounts and 4 are not.
4. **Hide and Pause My Profile cannot work:** their 4 functions exist neither live nor in any file.
5. **The 13 developer functions are live** and callable by any signed-in account (each checks for a `@zyra.test` email). Low risk
   with no real members; they must go before launch.

## 1. Migrations

| | Count |
|---|---|
| Applied live | 211 |
| Repository files | 228 |
| Same change, different version number (applied by name with another timestamp) | 28 |
| Repository files **never applied** | **17** (below) |
| Applied live under a name no repository file has | 2 (`journey_timeline_milestones_and_rewind_all`, `rewind_keeps_journey_started_milestone` — earlier forms of two repository files) |

Never applied (date · file): 25 Aug shared pause decision · 18 Sep main-Guardian hold, known-person code matching, product
telemetry · 19 Sep Guardian Circle messaging, Journey return gate · 23 Sep retire legacy purchase functions · 24 Sep paid-only
contract · 25–26 Sep Circle participant list, Circle sender identity, message read receipts · 5 Oct f01 safety report retention,
f02 Guardian read boundary, f03 photo owner binding, f04 legacy score and Browse ranking, f05 private progress helpers, f06/f07
unlock hold and receipts.

**So production does not have:** the Main-Guardian Journey hold, the shared Pause decision, Guardian Circle messaging, read
receipts, Browse ranking (`zyra_browse_ranked_ids`), the verified trial (`zyra_start_verified_seeker_trial`), or the 5 Oct security
fixes. The blueprint data map (part 3) describes the **repository**, not production.

## 2. The message rule (OA-ZYRA-319)

Live `messages_insert`: sender is a Seeker in an **active** attempt, the conversation is **active**, and **no block** exists either
way. This is the 9 Aug rule — safe. The weaker 24 Sep rule is **not live**. The repository problem remains: replaying the files in
order would fail at 5 Oct, and the 24 Sep file would weaken the rule if ever applied.

## 3. Functions the app calls

| Function | Live? |
|---|---|
| `zyra_my_hidden_profile_ids`, `zyra_set_profile_hidden` (Hide) | **No** |
| `zyra_my_profile_pause_state`, `zyra_set_my_profile_pause` (Pause My Profile) | **No** |
| `wali_has_wali_one` (old app) | Yes |
| `transition_journey_pause`, `zyra_open_family_message_circle`, `zyra_start_verified_seeker_trial`, `zyra_browse_ranked_ids` | **No** (their files were never applied) |

## 4. Data (counts only)

| Item | Count |
|---|---|
| Accounts | 153 — **149 `@zyra.test`**, 4 others |
| Profiles | 149 (144 Seekers, 5 Guardians) |
| Journeys | 3 active, 2 ended |
| Messages | 2 |
| Subscription rows | 7 (Seeker Basic 2, Seeker One 3, Guardian One 2 — test) |
| Photo rows / distinct photo files | 597 / 99 (test photos reused across test accounts; every row has its file) |

## 5. Developer functions (OA-ZYRA-312)

All 13 (`zyra_dev_*`, `zyra_debug_grant_credits`) are live and executable by any signed-in account; each refuses unless the
caller's email ends `@zyra.test`. Sign-up settings (whether such an email can be registered) are not readable by SQL. With no real
members, risk is low today; they must be removed or moved out of production before launch.

`zyra_onboarding_questions`: row-level security **on**, no direct-access rules — reachable only through functions. **Safe** (the
other half of OA-ZYRA-312 is closed).

## 6. Supabase security advisor

| Level | Finding | Note |
|---|---|---|
| Error (1) | `zyra_my_attempt_participation` is a security-definer view | Intentional per its design (caller-scoped); to confirm in the server design |
| Warning (98) | Signed-in users can run security-definer functions | Expected — they check the caller themselves — but each must be reviewed (developer and mock ones first) |
| Warning (1) | Leaked-password protection is off | Members sign in with Google or Apple; switch on anyway (Founder setting) |
| Info (16) | Tables with row-level security and no rules | Intended: reached only through functions |

## 7. What this changes

| Item | Change |
|---|---|
| OA-ZYRA-319 | Not a live safety issue; stays HIGH as a repository problem (replay fails; weak rule waiting in a file) |
| OA-ZYRA-312 | Answered; remaining: remove developer and mock functions, and check sign-up settings, before launch |
| OA-ZYRA-317 | Starts from production as it is: 17 unapplied files to review — keep, rewrite or drop each — before anything new |
| Blueprint part 3 | Add a note: it describes the repository; production is behind (this report) |
