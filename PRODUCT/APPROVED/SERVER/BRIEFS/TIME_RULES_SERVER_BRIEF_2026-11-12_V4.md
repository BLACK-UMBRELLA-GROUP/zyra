---
id: DOC-ZYRA-0473
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex server brief V4 - Founder 12 Nov time rules and account deletion (Q134) on the server, throw-away databases only
links: [AD-AIOS-115, AD-AIOS-142, OA-ZYRA-317, DOC-ZYRA-0329]
owner: Fable
---

# SERVER BRIEF — TIME RULES — 12 NOV 2026 — V4

**Founder-named task**, reissued by Fable 12 Nov 18:10 for **QUESTIONS 134** (deletion removes the Journey for the other Seeker at
once). Detail lives in the **Answer** cells of QUESTIONS **117-120, 123-128, 130, 131, 133, 134** - build exactly those; where
they differ, **the higher row number wins** (134 replaces the survivor parts of 120/123/126). Blueprint 2: JOURNEY V3,
GUARDIAN V5, MEMBERSHIP V3, MESSAGING V2, PROFILE V3. App side: lines 93, 97. **Throw-away databases only - no live apply,
no deploy, no store setting, no downloads.** V1-V3 in `../ARCHIVE/`. Reuse the V3 candidate where it still matches.

| Step | Detail |
|---|---|
| 1 | Times: Guardian invitation and ZYRA Code link request **14 days** (new rows; `zyra_create_guardian_invitation`, Q125); restart **24 h + 30 days** (replace SERVER 0's 7 days and its guard); billing grace **max 3 days**; Guardian One trial **14 days once per verified person** |
| 2 | **Account deletion (Q134):** every Journey attempt with the deleted person - active or ended - is **removed for the other Seeker at once**, with its Timeline, messages and Circle; their requests (received, sent, Past) and introductions involving them go; the other Seeker's place is freed. **No survivor record, no `left_zyra` state, no name.** Each affected Seeker gets one `notifications` row, type `journey_ended_profile_inactive`, payload `{}` (no name, user id, match or attempt id) for the My ZYRA item "One of your Journeys has ended" / "This profile is no longer active. Your place is free for a new Journey." |
| 3 | **Sealed safety copy** before removal: the whole conversation of each affected Journey and Circle (both sides) into `safety_sealed_messages` (service role only, no `authenticated` policy), purged after **365 days**. Data under an open report or protection hold (Q130 `report_protected_attempts`) is hidden from everyone and kept until it closes. Safety reports survive (FK SET NULL); Family owner refused until transfer (Q123); trial ledger keeps only the verified-person key (Q123) |
| 4 | **Ended Journeys:** no time limit; `zyra_remove_ended_journey(p_attempt_id)`; both removed → delete (except holds / reports, tombstone for an active restart, Q126/Q130); block hides for both, unblock lifts only the block (Q126) |
| 5 | **Inactivity (Q124, Q127, Q133):** `zyra_touch_activity()`; backfill without telemetry; only accounts with Ended Journeys; five `email_outbox` rows at -14, -7, 0, +7, +14 days; removal at 2 years + 14 days; a return cancels and sets `zyra_my_welcome_back()` once; `zyra_run_inactivity_job()` |
| 6 | **Photo links (Q131 + 18:10):** see "Photo link enforcement" below |
| 7 | **SERVER 1 record** `SERVER/RECORD/TIME_RULES_FOR_SERVER_1_2026-11-12.md`: ready reminder 48 h, close 72 h, ask-again 7 / 14 / 30 days per direction (Q128) |
| 8 | Tests on a throw-away database for every rule above; deletion: the other Seeker's lists show nothing of that person, the notice payload is `{}`, the sealed copy is service-only and purged after 365 days, reports and holds keep their data |
| 9 | Gate: replay clean, tests pass, `flutter analyze` unchanged. Task note; commit within core rule 2; BUILT, FAILED or QUESTION |

## Photo link enforcement (Fable 18:10)
Supabase Storage cannot cap the lifetime a client asks for, so for now: **(a)** the app signs every photo URL with
`expiresIn` **3600** seconds or less and a test pins it (app side, current code path); **(b)** deletion removes the photo rows
first, so no new URL can be signed; **(c)** `zyra-photo-cleanup` (service role) removes queued files; on live it is called
**every hour** (pg_cron + pg_net, part of the Founder's live apply), so the 24-hour target holds with up to 10 retries;
failures stay in `photo_object_deletions` with `last_error` for review. A server-side signing function with a fixed
lifetime is recorded for SERVER 1 (not this line).
