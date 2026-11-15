---
id: DOC-ZYRA-0473
type: PLAN
status: SUPERSEDED
feature: PRODUCT BLUEPRINT
purpose: Codex server brief - the Founder's 12 Nov time rules (QUESTIONS 117-119) on the server, throw-away databases only
links: [AD-AIOS-115, AD-AIOS-142, OA-ZYRA-317, DOC-ZYRA-0329]
owner: Fable
---

> **SUPERSEDED 12 Nov 2026 by `../BRIEFS/TIME_RULES_SERVER_BRIEF_2026-11-12_V3.md`.**

# SERVER BRIEF — TIME RULES — 12 NOV 2026 — V2

**Founder-named task.** Founder 12 Nov (ZYRA chat time-rules review, clickable and typed answers): QUESTIONS rows **117, 118,
119** - their Answer cells are the rules; Blueprint 2 pages updated by Fable: JOURNEY V3, GUARDIAN V5, MEMBERSHIP V3,
MESSAGING V2, PROFILE V3. App side is queue line 93. **V2 (16:30): QUESTIONS 120, 123, 124, 125, 126 (Fable) are part of this brief and win where they differ** - survivor record and deletion detail (123), activity / warning / job (124), `zyra_create_guardian_invitation` (125), block and per-attempt removal (126). V1 in `../ARCHIVE/`. **Copy exactly. No improvements.** Unclear → `QUESTIONS.md` row
(server-design questions go to Fable, AD-AIOS-147). **Throw-away databases only - no live apply, no deploy, no store
setting.** No downloads, no installs (F33). ROADMAP row (charter rule 12): "Test baseline and final interface pass".

| Step | Detail |
|---|---|
| 1 | Find every server constant for these times in the migrations (expiry, grace, trial, wait) and list each with its file in the task note before changing anything |
| 2 | **Guardian invitation** expiry 7 → **14 days**; **ZYRA Code link request** expiry 30 → **14 days** (`zyra_request_guardian_link` and its expiry job). Existing rows keep the expiry they were created with |
| 3 | **Request restart** (`request_new_journey`) - **corrected 12 Nov 16:45:** SERVER 0 (`20261030151052_server0_ended_restart_preparation.sql`) sets and enforces **7 days** (insert `now() + interval '7 days'` and the guard `restart_expiry_must_be_seven_days`). A new migration after SERVER 0 changes both to **30 days** (guard renamed `restart_expiry_must_be_thirty_days`); the **24-hour wait stays** unchanged. Requests already created keep their expiry. Tests pin 24 h and 30 days (locked: Founder 12 Nov, QUESTIONS 118 item 2; JOURNEY V3 §7) |
| 4 | **Billing grace:** `billing_grace_until` at most **3 days** after `billing_grace_started_at` (constraint and every function that sets it; was 16) |
| 5 | **Guardian One trial:** a server-only start function like `zyra_start_verified_seeker_trial`, role Guardian, **14 days, once per verified person** (same ledger idea); no purchase path (nothing can be bought yet) |
| 6 | **Account deletion** (`delete_own_account`): instead of deleting the shared Journey for both, the other Seeker's Journey ends as **"This member has left ZYRA"** and **none of the deleted person's messages, Bio, photos or answers stay readable** to anyone. Before removal, the deleted person's messages in shared Journeys and the Circle are copied into a **sealed safety table** (`safety_sealed_messages`: service role only, no app read, no policy for `authenticated`), purged after `safety_copy_retention_days` = **365** (Founder 12 Nov 16:35, clickable "12 months (Recommended)"; to be confirmed before launch). Guardian links end; safety reports kept as today. **One state everywhere (aligned with line 93, 12 Nov 16:45):** every read that returns the deleted person as a participant - Journey, Timeline and **Guardian Circle** - returns `member_state = 'left_zyra'` with **no name, photo or other data** (`display_name` null); the app shows "This member has left ZYRA". The old "Former member" wording is retired |
| 7 | **Ended Journeys - no time limit:** no 3-month purge anywhere. Per-Seeker **Remove from my Journeys**: `zyra_remove_ended_journey(p_attempt_id)` (participant only, ended attempt only; Q126) sets that Seeker's `removed_at`; reads exclude it for that Seeker only; cannot be undone. When **both** Seekers have removed it, delete the shared Journey data (Timeline, messages, Bio snapshot) in the same transaction. **Block:** while either has blocked the other, the ended Journey is hidden for both; unblock shows it again (nothing deleted by a block) |
| 7b | **Inactive accounts** (Founder 12 Nov 16:35, clickable "Yes, after 2 years inactive (Recommended)"): record `last_active_at` per account; a daily job finds accounts with no app use for **2 years**, writes a warning item for them (the app and email wording is the ZYRA Claude chat's design), and **30 days** after the warning, if still inactive, removes that member's ended Journeys the same way as Remove from my Journeys (shared data deleted when both have removed). Active members keep everything with no limit |
| 8 | **Not in this line - recorded for SERVER 1** (journey requests do not exist yet, DOC-ZYRA-0329 area 1): the ready window (one reminder at **48 h**, close as "Not taken up" at **72 h**, both places freed) and the **7-day** ask-again wait after "Not taken up". Add a line to `SERVER/RECORD/` note `TIME_RULES_FOR_SERVER_1_2026-11-12.md` with these numbers so SERVER 1 builds them |
| 9 | Tests on a throw-away database: each number above; deletion leaves the other Seeker with the "left" Journey and no messages, the sealed copy readable only by the service role and purged after 365 days; an account inactive 2 years is warned and its ended Journeys removed 30 days later, an active one never; remove by one Seeker hides only theirs, by both deletes; block hides for both and unblock restores; trial once per verified person |
| 10 | Gate: whole replay clean; tests pass; `flutter analyze` unchanged. Task note; commit within core rule 2; mark this line BUILT, FAILED or QUESTION. **No live apply** |

## Not in this line
Live apply · the App Store Connect billing grace setting (Shakeel, in App Store Connect) · terms and privacy notice wording (legal, private) · SERVER 1 request flow.
